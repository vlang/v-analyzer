import * as lc from "vscode-languageclient/node";
import * as ra from "./lsp_ext";
import * as vscode from "vscode";
import * as fs from "fs";
import * as https from "https";
import * as path from "path";
import * as cp from "child_process";
import {
	getWorkspaceConfig,
	getWorkspaceFolder,
	isVlangDocument,
	isVlangEditor,
	VlangEditor,
} from "./utils";
import { Progress } from "vscode";
import { createClient } from "./client";
import { bootstrap } from "./bootstrap";
import { connectAnalyzerViaTcp } from "./tcp";
import { log } from "./log";
import { runVCommandCallback } from "./exec";

// Most of the file taken from `rust-analyzer/editors/code/src/ctx.ts` <3

export type Workspace =
	| { kind: "Empty" }
	| { kind: "Workspace Folder" }
	| { kind: "Detached Files"; files: vscode.TextDocument[] };

export function fetchWorkspace(): Workspace {
	const folders = (vscode.workspace.workspaceFolders || []).filter(
		(folder) => folder.uri.scheme === "file",
	);
	const vlangDocuments = vscode.workspace.textDocuments.filter((document) =>
		isVlangDocument(document),
	);

	if (folders.length !== 0) {
		return { kind: "Workspace Folder" };
	}

	if (vlangDocuments.length === 0) {
		return { kind: "Empty" };
	}

	return { kind: "Detached Files", files: vlangDocuments };
}

export type Command = (...args: any[]) => unknown;

export type CommandFactory = {
	enabled: (ctx: ContextInit) => Command;
	disabled?: (ctx: Context) => Command;
};

export type ContextInit = Context & {
	readonly client: lc.LanguageClient;
};

export class AnalyzerNotInstalledError implements Error {
	constructor(additionalMessage?: string) {
		this.message = "v-analyzer is not installed";
		if (additionalMessage) {
			this.message += `: ${additionalMessage}`;
		}
		this.name = "AnalyzerNotInstalled";
	}

	message: string;
	name: string;
}

export class Context {
	readonly statusBar: vscode.StatusBarItem;
	readonly langStatusBar: vscode.StatusBarItem;
	private _client: lc.LanguageClient | undefined;
	private _serverPath: string | undefined;
	private outputChannel: vscode.OutputChannel | undefined;
	private clientSubscriptions: Disposable[];
	private commandDisposables: Disposable[];

	get client() {
		return this._client;
	}

	get subscriptions(): Disposable[] {
		return this.extCtx.subscriptions;
	}

	get serverPath(): string | undefined {
		return this._serverPath;
	}

	get activeVlangEditor(): VlangEditor | undefined {
		const editor = vscode.window.activeTextEditor;
		return editor && isVlangEditor(editor) ? editor : undefined;
	}

	constructor(
		readonly extCtx: vscode.ExtensionContext,
		readonly commandFactories: Record<string, CommandFactory>,
		readonly workspace: Workspace,
	) {
		extCtx.subscriptions.push(this);

		this.statusBar = vscode.window.createStatusBarItem(
			"v-analyzer-status",
			vscode.StatusBarAlignment.Left,
			50,
		);
		this.langStatusBar = vscode.window.createStatusBarItem(
			"v-version",
			vscode.StatusBarAlignment.Left,
			60,
		);

		this.clientSubscriptions = [];
		this.commandDisposables = [];

		this.showLanguageStatusBar();
		this.updateCommands("disable");
		this.setServerStatus({
			health: "stopped",
		});
	}

	dispose() {
		this.statusBar.dispose();
		this.langStatusBar.dispose();
		void this.disposeClient();
		this.commandDisposables.forEach((disposable) => disposable.dispose());
	}

	async start() {
		log.info("Starting language client");
		const client = await this.getOrCreateClient();
		if (!client) {
			return;
		}
		await client.start();
		this.updateCommands();
	}

	private async getOrCreateClient() {
		if (this.workspace.kind === "Empty") {
			return undefined;
		}

		if (!this.outputChannel) {
			this.outputChannel = vscode.window.createOutputChannel(
				"V Analyzer Language Server",
			);
			this.pushExtCleanup(this.outputChannel);
		}

		if (!this._client) {
			this._serverPath = await bootstrap().catch((err) => {
				if (err instanceof AnalyzerNotInstalledError) {
					log.info("v-analyzer is not installed");

					const msg = "v-analyzer is not installed. Do you want to install it?";
					void vscode.window
						.showInformationMessage(msg, "Yes", "No")
						.then((selected) => {
							if (selected == "Yes") {
								this.installAnalyzerWithProgress();
							}
						});
				}

				throw new AnalyzerNotInstalledError();
			});
			const newEnv = Object.assign({}, process.env);
			const folder = getWorkspaceFolder();
			log.debug("cwd: ", folder.uri.fsPath);
			const run: lc.Executable = {
				command: this._serverPath,
				options: { env: newEnv, cwd: folder.uri.fsPath },
			};

			const config = getWorkspaceConfig();
			const connMode = config.get<string>("connectionMode");
			const tcpPort = config.get<number>("tcpMode.port");

			if (connMode === "tcp") {
				log.info(`Connecting to analyzer via TCP on port ${tcpPort}`);
				log.info("Make sure to start the analyzer with the --socket flag");
				log.info("Use it only for debugging purposes!");
			}

			const serverOptions =
				connMode === "tcp"
					? () => connectAnalyzerViaTcp(tcpPort)
					: {
							run,
							debug: run,
						};

			this._client = await createClient(this.outputChannel, serverOptions);

			this.pushClientCleanup(
				this._client.onNotification(ra.serverStatus, (params) =>
					this.setServerStatus(params),
				),
			);
		}
		return this._client;
	}

	async restart() {
		await this.stopAndDispose();
		await this.start();
	}

	async stopAndDispose() {
		if (!this._client) {
			return;
		}
		log.info("Disposing language client");
		this.updateCommands("disable");
		await this.disposeClient();
	}

	private async disposeClient() {
		this.clientSubscriptions?.forEach((disposable) => disposable.dispose());
		this.clientSubscriptions = [];
		try {
			await this._client?.dispose();
		} catch (e) {
			// for some reasons dispose() always throws an error
			// when restarting analyzer, ignore for now
			// log.error('client stop error', e)
		}
		this._serverPath = undefined;
		this._client = undefined;
	}

	private updateCommands(forceDisable?: "disable") {
		this.commandDisposables.forEach((disposable) => disposable.dispose());
		this.commandDisposables = [];

		const clientRunning = (!forceDisable && this._client?.isRunning()) ?? false;
		const isClientRunning = (_ctx: Context): _ctx is ContextInit => {
			return clientRunning;
		};

		for (const [name, factory] of Object.entries(this.commandFactories)) {
			const fullName = `v-analyzer.${name}`;
			let callback;
			if (isClientRunning(this)) {
				// we asserted that `client` is defined
				callback = factory.enabled(this);
			} else if (factory.disabled) {
				callback = factory.disabled(this);
			} else {
				callback = () =>
					vscode.window.showErrorMessage(
						`command ${fullName} failed: v-analyzer server is not running`,
					);
			}

			this.commandDisposables.push(
				vscode.commands.registerCommand(fullName, callback),
			);
		}
	}

	showLanguageStatusBar() {
		const statusBar = this.langStatusBar;
		statusBar.text = "V";
		statusBar.show();
		runVCommandCallback(["-version"], (err, stdout) => {
			if (err) {
				return;
			}
			const version = stdout.trim().replace("V ", "");
			statusBar.text = `V ${version}`;
		});
	}

	setServerStatus(status: ra.ServerStatusParams | { health: "stopped" }) {
		if (status.health === "error" && status.message) {
			const msg = status.message ?? "v-analyzer server error";
			const openConfig = "Open Config";
			vscode.window.showErrorMessage(msg, openConfig).then((selected) => {
				if (selected === openConfig) {
					vscode.commands.executeCommand("v-analyzer.openGlobalConfig");
				}
			});
		}

		let icon = "";
		const statusBar = this.statusBar;
		statusBar.show();
		statusBar.tooltip = new vscode.MarkdownString("", true);
		statusBar.tooltip.isTrusted = true;
		switch (status.health) {
			case "ok":
				statusBar.tooltip.appendText(status.message ?? "Ready");
				statusBar.color = undefined;
				statusBar.backgroundColor = undefined;
				statusBar.command = "v-analyzer.stopServer";
				icon = "$(zap) ";
				break;
			case "warning":
				if (status.message) {
					statusBar.tooltip.appendText(status.message);
				}
				statusBar.color = new vscode.ThemeColor(
					"statusBarItem.warningForeground",
				);
				statusBar.backgroundColor = new vscode.ThemeColor(
					"statusBarItem.warningBackground",
				);
				statusBar.command = "v-analyzer.openLogs";
				icon = "$(warning) ";
				break;
			case "error":
				if (status.message) {
					statusBar.tooltip.appendText(status.message);
				}
				statusBar.color = new vscode.ThemeColor("statusBarItem.errorForeground");
				statusBar.backgroundColor = new vscode.ThemeColor(
					"statusBarItem.errorBackground",
				);
				statusBar.command = "v-analyzer.openGlobalConfig";
				icon = "$(error) ";
				break;
			case "stopped":
				statusBar.tooltip.appendText("Server is stopped");
				statusBar.tooltip.appendMarkdown(
					"\n\n[Start server](command:v-analyzer.startServer)",
				);
				statusBar.color = undefined;
				statusBar.backgroundColor = undefined;
				statusBar.command = "v-analyzer.startServer";
				statusBar.text = `$(stop-circle) v-analyzer`;
				return;
		}
		if (statusBar.tooltip.value) {
			statusBar.tooltip.appendText("\n\n");
		}
		statusBar.tooltip.appendMarkdown(
			"\n\n[Restart server](command:v-analyzer.restartServer)",
		);
		statusBar.tooltip.appendMarkdown(
			"\n\n[Stop server](command:v-analyzer.stopServer)",
		);
		if (!status.quiescent) icon = "$(sync~spin) ";
		statusBar.text = `${icon}v-analyzer`;
	}

	pushExtCleanup(d: Disposable) {
		this.extCtx.subscriptions.push(d);
	}

	private pushClientCleanup(d: Disposable) {
		this.clientSubscriptions.push(d);
	}

	private getScriptPath(): string {
		const globalFolder = this.extCtx.globalStorageUri.fsPath;
		if (!fs.existsSync(globalFolder)) {
			fs.mkdirSync(globalFolder);
		}

		return path.join(globalFolder, "install.vsh");
	}

	private installAnalyzerWithProgress() {
		return vscode.window.withProgress(
			{
				title: "Installing v-analyzer...",
				location: vscode.ProgressLocation.Notification,
			},
			async (progress) => {
				return this.installAnalyzer(progress);
			},
		);
	}

	private cleanOutput(value: string): string {
		if (!value) {
			return "";
		}

		return value.replace(/\u001b\[[0-9;]*m/g, "");
	}

	private async startInstallation(
		progress: Progress<{
			message?: string;
			increment?: number;
		}>,
		fromSources: boolean,
	) {
		const progressMessage = fromSources
			? "Installing v-analyzer from sources..."
			: "Installing v-analyzer binary...";
		progress.report({ message: progressMessage });

		const scriptPath = this.getScriptPath();
		const buf = cp.spawnSync(`v`, ["run", scriptPath, "--no-interaction"], {
			encoding: "utf-8",
		});

		log.debug(this.cleanOutput(buf.stdout));
		log.debug(this.cleanOutput(buf.stderr));

		if (buf.error) {
			log.error(buf.error);
			return;
		}

		void vscode.window.showInformationMessage(
			"v-analyzer binary has been installed successfully",
		);

		progress.report({ message: "v-analyzer binary has been installed successfully" });

		const config = vscode.workspace.getConfiguration();
		config
			.update(
				"v-analyzer.serverPath",
				"~/.config/v-analyzer/bin/v-analyzer",
				vscode.ConfigurationTarget.Global,
			)
			.then(() => {
				log.info(
					"v-analyzer.serverPath has been updated to ~/.config/v-analyzer/bin/v-analyzer",
				);
			});
	}

	private async installAnalyzer(
		progress: Progress<{
			message?: string;
			increment?: number;
		}>,
	) {
		await this.downloadScriptIfNeeded();

		progress.report({ message: "Check prebuilt binary availability..." });

		const scriptPath = this.getScriptPath();

		const result = cp.execSync(`v run '${scriptPath}' check-availability`, {
			encoding: "utf-8",
		});
		if (result.trim().includes("v-analyzer binary is available for your platform")) {
			progress.report({
				message:
					"Found prebuilt binary for your platform, starting downloading...",
			});
			return this.startInstallation(progress, false);
		}

		return vscode.window
			.showInformationMessage(
				"v-analyzer binary is not available for your platform. Do you want to build it from source?",
				"Yes",
				"No",
			)
			.then(async (selected) => {
				if (selected == "Yes") {
					await this.startInstallation(progress, true);
				}
			});
	}

	private async downloadScriptIfNeeded() {
		return new Promise<void>((resolve, reject) => {
			const destinationPath = this.getScriptPath();
			if (fs.existsSync(destinationPath)) {
				// Do nothing if a script already exists
				resolve();
				return;
			}

			log.info("Downloading install script...");

			const file = fs.createWriteStream(destinationPath);

			https
				.get(
					"https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh",
					(response) => {
						response.pipe(file);
						file.on("finish", () => {
							file.close();
							log.info("Install script has been downloaded successfully");
							resolve();
						});
					},
				)
				.on("error", (err) => {
					fs.unlink(destinationPath, () => {
						log.error(`Failed to download install script: ${err}`);
						reject(err);
					});
				});
		});
	}
}

export interface Disposable {
	dispose(): void;
}
