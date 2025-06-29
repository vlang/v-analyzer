import cp from "child_process";
import os from "os";
import fs from "fs";
import { log } from "./log";
import { getWorkspaceConfig } from "./utils";
import { AnalyzerNotInstalledError } from "./ctx";

/**
 * bootstrap returns the path to the v-analyzer binary.
 * It will throw an error if the binary is not available.
 *
 * @returns {Promise<string>} The path to the v-analyzer binary.
 */
export async function bootstrap(): Promise<string> {
	const path = getAnalyzerPath();

	if (!isAnalyzerExecutableValid(path)) {
		const config = getWorkspaceConfig();
		const explicitPath = config.get<string>("serverPath");
		if (explicitPath) {
			throw new Error(`Failed to execute ${path} -v. \`config.serverPath\`has been set explicitly.\
            Consider removing this config or making a valid server binary available at that path.`);
		}

		throw new AnalyzerNotInstalledError(
			`Failed to execute ${path} -v, make sure the v-analyzer is installed and available in the PATH`,
		);
	}

	log.info("Using server binary at", path);
	try {
		const rpath = fs.realpathSync(path);
		log.info("Server binary realpath:", rpath);
	} catch (err) {
		try {
			const command =
				process.platform === "win32" ? `where ${path}` : `which ${path}`;
			const rpath = cp.execSync(command).toString().trim().split("\n")[0];
			log.info("Server binary realpath:", rpath);
		} catch (err) {
			log.error("Error:", err.message);
		}
	}

	return path;
}

function getAnalyzerPath(): string {
	const config = getWorkspaceConfig();
	const explicitPath = config.get<string>("serverPath");
	const path = explicitPath ? explicitPath : "v-analyzer";

	if (path.startsWith("~/") || path.startsWith("~\\")) {
		return path.replace("~", os.homedir());
	}

	return path;
}

function isAnalyzerExecutableValid(path: string): boolean {
	const location = path === "v-analyzer" ? "PATH" : path;
	log.debug("Checking availability of a binary at", location);
	const res = cp.spawnSync(`${path}`, ["-v"]);
	return res.status === 0;
}
