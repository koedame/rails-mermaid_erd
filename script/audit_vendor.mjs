// Checks the JS bundles in lib/templates/vendor/ against npm's advisory
// database. They are plain files, so bundler-audit and `npm audit` on the
// Tailwind lock file never see them and Dependabot does not either.
//
//   node script/audit_vendor.mjs        # Node 20.11+, needs network
//
// script/licenses/bundles.json is the one place that names the bundled
// versions. This script first checks that each file really is that version
// (otherwise the audit would be about a file that is not shipped), then
// installs exactly those versions into a throwaway project and runs
// `npm audit --audit-level=moderate`. The exit status is npm's.

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const vendor = path.join(root, "lib/templates/vendor");
const bundles = JSON.parse(fs.readFileSync(path.join(root, "script/licenses/bundles.json"), "utf8"));

// What each bundle prints about itself. Mermaid carries `version:"x.y.z"`,
// Vue's production build carries the version as a string constant.
const embedded = {
  mermaid: (v) => `version:"${v}"`,
  vue: (v) => `"${v}"`,
};

let stale = false;
for (const [name, mark] of Object.entries(embedded)) {
  const { version, file } = bundles[name];
  if (!fs.readFileSync(path.join(vendor, file), "utf8").includes(mark(version))) {
    console.error(`${file} is not ${name} ${version}, the version script/licenses/bundles.json names`);
    stale = true;
  }
}
if (stale) process.exit(1);

const dir = fs.mkdtempSync(path.join(os.tmpdir(), "audit-vendor-"));
const dependencies = Object.fromEntries(Object.keys(embedded).map((name) => [name, bundles[name].version]));
fs.writeFileSync(path.join(dir, "package.json"), JSON.stringify({ name: "audit-vendor", private: true, dependencies }));

const npm = (...args) => spawnSync("npm", args, { cwd: dir, stdio: "inherit" });
try {
  const install = npm("install", "--package-lock-only", "--ignore-scripts", "--no-fund");
  if (install.status !== 0) process.exit(install.status ?? 1);
  console.log(`Auditing ${Object.entries(dependencies).map(([n, v]) => `${n}@${v}`).join(" and ")}`);
  process.exitCode = npm("audit", "--audit-level=moderate").status ?? 1;
} finally {
  fs.rmSync(dir, { recursive: true, force: true });
}
