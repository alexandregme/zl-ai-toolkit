// Runs from the "version" script of `npm version`: copies the version of package.json
// to the plugin manifest, which is what Claude Code reads to find an update.
import { readFileSync, writeFileSync } from "node:fs";

const MANIFEST = "plugins/zl/.claude-plugin/plugin.json";

const { version } = JSON.parse(readFileSync("package.json", "utf8"));
const manifest = JSON.parse(readFileSync(MANIFEST, "utf8"));

writeFileSync(MANIFEST, `${JSON.stringify({ ...manifest, version }, null, 2)}\n`);
