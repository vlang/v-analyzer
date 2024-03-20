import vscode from "vscode";
import path from "path";
import semver from "semver";
import { Command, ContextInit } from "./ctx";
import { getFromGlobalState, updateGlobalState } from "./stateUtils";

// Most of this code is copied from the Go extension's welcome.ts file. <3

export class WelcomePanel {
	public static showWelcome(ctx: ContextInit): Command {
		return WelcomePanel.createOrShow(ctx);
	}

	public static activate(ctx: ContextInit) {
		if (vscode.window.registerWebviewPanelSerializer) {
			// Make sure we register a serializer in activation event
			vscode.window.registerWebviewPanelSerializer(WelcomePanel.viewType, {
				async deserializeWebviewPanel(webviewPanel: vscode.WebviewPanel) {
					WelcomePanel.revive(webviewPanel, ctx.extCtx.extensionUri);
				},
			});
		}

		showGoWelcomePage();
	}

	public static currentPanel: WelcomePanel | undefined;

	public static readonly viewType = "welcomeV";

	public static createOrShow(ctx: ContextInit) {
		return () => {
			const extensionUri = ctx.extCtx.extensionUri;
			const column = vscode.window.activeTextEditor
				? vscode.window.activeTextEditor.viewColumn
				: undefined;

			// If we already have a panel, show it.
			if (WelcomePanel.currentPanel) {
				WelcomePanel.currentPanel.panel.reveal(column);
				return;
			}

			// Otherwise, create a new panel.
			const panel = vscode.window.createWebviewPanel(
				WelcomePanel.viewType,
				"V for VS Code",
				column || vscode.ViewColumn.One,
				{
					// And restrict the webview to only loading content from our extension's directory.
					localResourceRoots: [joinPath(extensionUri)],
				},
			);
			panel.iconPath = joinPath(extensionUri, "media", "logo.png");

			WelcomePanel.currentPanel = new WelcomePanel(panel, extensionUri);
		};
	}

	public static revive(panel: vscode.WebviewPanel, extensionUri: vscode.Uri) {
		WelcomePanel.currentPanel = new WelcomePanel(panel, extensionUri);
	}

	public readonly dataroot: vscode.Uri; // exported for testing.
	private readonly panel: vscode.WebviewPanel;
	private readonly extensionUri: vscode.Uri;
	private disposables: vscode.Disposable[] = [];

	private constructor(panel: vscode.WebviewPanel, extensionUri: vscode.Uri) {
		this.panel = panel;
		this.extensionUri = extensionUri;
		this.dataroot = joinPath(this.extensionUri, "media");

		// Set the webview's initial html content
		this.update();

		// Listen for when the panel is disposed
		// This happens when the user closes the panel or when the panel is closed programmatically
		this.panel.onDidDispose(() => this.dispose(), null, this.disposables);
	}

	public dispose() {
		WelcomePanel.currentPanel = undefined;

		// Clean up our resources
		this.panel.dispose();

		while (this.disposables.length) {
			const x = this.disposables.pop();
			if (x) {
				x.dispose();
			}
		}
	}

	private update() {
		const webview = this.panel.webview;
		this.panel.webview.html = this.getHtmlForWebview(webview);
	}

	private getHtmlForWebview(webview: vscode.Webview) {
		const vAnalyzerExtension = vscode.extensions.getExtension(
			"VOSCA.vscode-v-analyzer",
		)!;
		const vAnalyzerExtensionVersion = vAnalyzerExtension.packageJSON.version;

		const stylePath = joinPath(this.dataroot, "welcome.css");
		const logoPath = joinPath(this.dataroot, "logo.png");
		const stylesURI = webview.asWebviewUri(stylePath);
		const logoURI = webview.asWebviewUri(logoPath);

		return `<!DOCTYPE html>
			<html lang="en">
			<head>
				<meta charset="UTF-8">
				<!--
					Use a content security policy to only allow loading images from https or from our extension directory,
					and only allow scripts that have a specific nonce.
				-->
				<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource}; img-src ${webview.cspSource} https:;">
				<meta name="viewport" content="width=device-width, initial-scale=1.0">
				<link href="${stylesURI}" rel="stylesheet">
				<title>V for VS Code</title>
			</head>
			<body>
			<main class="Content">
				<div class="Header">
					<img src="${logoURI}" alt="v-analyzer logo" class="Header-logo"/>
					<div class="Header-details">
						<h1 class="Header-title">V for VS Code v${vAnalyzerExtensionVersion}</h1>
						<p>The v-analyzer extension for Visual Studio Code, providing rich language support for V projects.</p>
						<ul class="Header-links">
							<li><a href="https://github.com/vlang/v-analyzer/blob/main/editors/code/CHANGELOG.md">Release notes</a></li>
							<li><a href="https://github.com/vlang/v-analyzer">GitHub</a></li>
							<li><a href="https://discord.gg/vlang">Discord</a></li>
						</ul>
					</div>
				</div>

				<div class="Cards">
					<div class="Card">
						<div class="Card-inner">
							<p class="Card-title">Getting started</p>
							<p class="Card-content">Learn about the v-analyzer extension in
								<a href="https://github.com/vlang/v-analyzer/tree/main/editors/code/README.md">README</a>.
							</p>
						</div>
					</div>

					<div class="Card">
						<div class="Card-inner">
							<p class="Card-title">Learning V</p>
							<p class="Card-content">If you're new to the V programming language,
								<a href="https://github.com/vlang/v/blob/master/doc/docs.md</a> is a great place to get started.</a>
							</p>
						</div>
					</div>

					<div class="Card">
						<div class="Card-inner">
							<p class="Card-title">Troubleshooting</p>
							<p class="Card-content">Experiencing problems? Start with
								<a href="https://github.com/vlang/v-analyzer/blob/main/editors/code/docs/troubleshooting.md">troubleshooting guide</a>.
							</p>
						</div>
					</div>
				</div>
			</main>
			</body>
			</html>`;
	}
}

function joinPath(uri: vscode.Uri, ...pathFragment: string[]): vscode.Uri {
	// Reimplementation of
	// https://github.com/microsoft/vscode/blob/b251bd952b84a3bdf68dad0141c37137dac55d64/src/vs/base/common/uri.ts#L346-L357
	// with Node.JS path. This is a temporary workaround for https://github.com/eclipse-theia/theia/issues/8752.
	if (!uri.path) {
		throw new Error("[UriError]: cannot call joinPaths on URI without path");
	}
	return uri.with({
		path: vscode.Uri.file(path.join(uri.fsPath, ...pathFragment)).path,
	});
}

function showGoWelcomePage() {
	// Update this list of versions when there is a new version where we want to
	// show the welcome page on update.
	const showVersions: string[] = ["0.0.2"];
	let vExtensionVersion = "0.0.2";
	let vExtensionVersionKey = "v-analyzer.extensionVersion111";

	const savedVExtensionVersion = getFromGlobalState(vExtensionVersionKey, "0.0.0");

	if (
		shouldShowGoWelcomePage(showVersions, vExtensionVersion, savedVExtensionVersion)
	) {
		vscode.commands.executeCommand("v-analyzer.showWelcome");
	}
	if (vExtensionVersion !== savedVExtensionVersion) {
		updateGlobalState(vExtensionVersionKey, vExtensionVersion);
	}
}

export function shouldShowGoWelcomePage(
	showVersions: string[],
	newVersion: string,
	oldVersion: string,
): boolean {
	if (newVersion === oldVersion) {
		return false;
	}
	const coercedNew = semver.coerce(newVersion);
	const coercedOld = semver.coerce(oldVersion);
	if (!coercedNew || !coercedOld) {
		return true;
	}
	// Both semver.coerce(0.22.0) and semver.coerce(0.22.0-rc.1) will be 0.22.0.
	return (
		semver.gte(coercedNew, coercedOld) && showVersions.includes(coercedNew.toString())
	);
}
