// Render Mermaid files to SVG with Pele. Write each SVG next to its .mmd file.
// Usage: node render.mjs [--png] FILE.mmd...
// --png also writes FILE.svg.png with Quick Look on macOS, so that an agent can look at the layout.
// The first run installs pele@1.9.0 in the cache folder, outside each repo. It needs the network.
// Exit code: 0 when each file renders, 1 when a file does not parse, 2 for a usage or install error.
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const version = "1.9.0";
const args = process.argv.slice(2);
const png = args.includes("--png");
const files = args.filter((arg) => arg !== "--png");
if (files.length === 0) {
    console.error("usage: node render.mjs [--png] FILE.mmd...");
    process.exit(2);
}
const missing = files.filter((file) => !fs.existsSync(file));
if (missing.length > 0) {
    console.error(`error: these files do not exist: ${missing.join(", ")}`);
    process.exit(2);
}

const cache = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache"), `pele-${version}`);
const entry = path.join(cache, "node_modules", "pele", "dist", "pele.js");
if (!fs.existsSync(entry)) {
    try {
        execFileSync("npm", ["install", "--silent", "--no-audit", "--no-fund", "--prefix", cache, `pele@${version}`], {
            stdio: "inherit",
        });
    } catch {
        console.error(`error: npm could not install pele@${version} in ${cache}.`);
        process.exit(2);
    }
}
const { render } = await import(pathToFileURL(entry).href);

// Pele's default limits are smaller than a large chart. These are the limits of the statechart skill.
const options = { limit: 1_000_000, outputLimit: 8_000_000, maxEdges: 10_000 };
let failed = false;
for (const file of files) {
    const svgFile = file.replace(/\.mmd$/, "") + ".svg";
    try {
        const result = await render(fs.readFileSync(file, "utf8"), options);
        fs.writeFileSync(svgFile, String(result.svg ?? result));
        console.log(`ok    ${svgFile}`);
    } catch (error) {
        failed = true;
        console.log(`error ${file}: ${error.message.split("\n")[0]}`);
        continue;
    }
    // A PNG is only for a look at the layout. If Quick Look fails, the SVG is still correct.
    if (png && process.platform === "darwin") {
        try {
            execFileSync("qlmanage", ["-t", "-s", "1600", "-o", path.dirname(svgFile), svgFile], { stdio: "ignore" });
            console.log(`ok    ${svgFile}.png`);
        } catch {
            console.log(`skip  ${svgFile}.png (qlmanage failed)`);
        }
    }
}
process.exit(failed ? 1 : 0);
