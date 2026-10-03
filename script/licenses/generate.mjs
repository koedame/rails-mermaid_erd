#!/usr/bin/env node
// Writes lib/templates/vendor/LICENSES.md: the name, version, license,
// copyright notice and permission text of everything that ends up in the
// vendored front-end files, so the gem and every generated index.html can
// carry them.
//
//   node script/licenses/generate.mjs
//
// Needs Node 18+ and network access (it downloads the npm tarballs into a
// throw-away directory). See lib/templates/vendor/README.md.
//
// What counts as "in the bundle":
//   mermaid.min.js         the packages named in dist/mermaid.min.js.map, after
//                          checking that the npm file is byte-for-byte the
//                          vendored one
//   vue.global.prod.min.js the packages of the vuejs/core repository that the
//                          global build is made of
//   tailwind.css           tailwindcss and @tailwindcss/forms from
//                          script/tailwind/package.json
//   index.html.erb         Heroicons, copied into the template as inline SVG
// bundles.json holds the versions and the choices that cannot be read from a
// package (which license of a dual-licensed package we take).

import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { promisify } from "node:util";

const run = promisify(execFile);
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const vendor = path.join(root, "lib/templates/vendor");
const config = JSON.parse(fs.readFileSync(path.join(root, "script/licenses/bundles.json"), "utf8"));
const tailwind = JSON.parse(fs.readFileSync(path.join(root, "script/tailwind/package.json"), "utf8"));

const work = fs.mkdtempSync(path.join(os.tmpdir(), "licenses-"));
const cache = new Map();

function sha256(file) {
  return createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

// `npm pack name@spec`, unpacked; the version that was resolved is in package.json.
function fetchPackage(name, spec) {
  const key = `${name}@${spec}`;
  if (!cache.has(key)) {
    cache.set(
      key,
      (async () => {
        const dir = path.join(work, key.replace(/[/@]/g, "_"));
        fs.mkdirSync(dir, { recursive: true });
        const { stdout } = await run("npm", ["pack", key, "--silent", "--pack-destination", dir], { cwd: dir });
        const tarball = stdout.trim().split("\n").pop();
        await run("tar", ["-xzf", path.join(dir, tarball), "-C", dir]);
        return path.join(dir, "package");
      })()
    );
  }
  return cache.get(key);
}

async function inBatches(items, size, fn) {
  const out = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(...(await Promise.all(items.slice(i, i + size).map(fn))));
  }
  return out;
}

// "../../../node_modules/.pnpm/@iconify+utils@3.0.2/node_modules/@iconify/utils/lib/x.js"
// -> { name: "@iconify/utils", version: "3.0.2" }
function packagesInSourceMap(map) {
  const found = new Map();
  for (const source of map.sources) {
    const pattern = /\.pnpm\/([^/]+)\/node_modules\/((?:@[^/]+\/)?[^/]+)\//g;
    let last = null;
    for (let m; (m = pattern.exec(source)); ) last = m;
    if (!last) continue;
    const name = last[2];
    const version = last[1].replace(/_.*$/, "").slice(`${name.replace("/", "+")}@`.length);
    found.set(`${name}@${version}`, { name, version });
  }
  return [...found.values()];
}

async function mermaidPackages() {
  const { version, file } = config.mermaid;
  const dir = await fetchPackage("mermaid", version);
  const vendored = path.join(vendor, file);
  if (sha256(path.join(dir, "dist/mermaid.min.js")) !== sha256(vendored)) {
    throw new Error(`${file} is not the dist/mermaid.min.js of mermaid@${version}; fix lib/templates/vendor/README.md and bundles.json first`);
  }
  const map = JSON.parse(fs.readFileSync(path.join(dir, "dist/mermaid.min.js.map"), "utf8"));
  const packages = packagesInSourceMap(map);

  // The parser is bundled from a sibling package of the monorepo, so its own
  // third-party code (langium, chevrotain, ...) is only named in its maps.
  // Find the published parser whose chunks are the ones in the map.
  const chunks = map.sources
    .filter((s) => s.startsWith("../../parser/dist/chunks/"))
    .map((s) => s.replace("../../parser/dist/", ""));
  const range = JSON.parse(fs.readFileSync(path.join(dir, "package.json"), "utf8")).dependencies["@mermaid-js/parser"];
  const { stdout } = await run("npm", ["view", `@mermaid-js/parser@${range}`, "version", "--json"]);
  const candidates = [].concat(JSON.parse(stdout)).reverse();
  let parserDir = null;
  for (const candidate of candidates) {
    const candidateDir = await fetchPackage("@mermaid-js/parser", candidate);
    if (chunks.every((c) => fs.existsSync(path.join(candidateDir, "dist", c)))) {
      parserDir = candidateDir;
      break;
    }
  }
  if (!parserDir) throw new Error(`no published @mermaid-js/parser ${range} contains the chunks bundled into ${file}`);
  const parserMaps = fs
    .readdirSync(path.join(parserDir, "dist/chunks/mermaid-parser.core"))
    .filter((f) => f.endsWith(".mjs.map"));
  const bundledChunkMaps = new Set(chunks.map((c) => `${c}.map`.replace("chunks/mermaid-parser.core/", "")));
  for (const f of parserMaps.filter((f) => bundledChunkMaps.has(f))) {
    const chunkMap = JSON.parse(fs.readFileSync(path.join(parserDir, "dist/chunks/mermaid-parser.core", f), "utf8"));
    packages.push(...packagesInSourceMap(chunkMap));
  }
  const parser = JSON.parse(fs.readFileSync(path.join(parserDir, "package.json"), "utf8"));
  packages.push({ name: "mermaid", version }, { name: parser.name, version: parser.version });
  return packages;
}

function vuePackages() {
  // The packages of vuejs/core are released in lockstep. compiler-sfc and
  // server-renderer are not part of the global build.
  const { version, globalBuildPackages } = config.vue;
  return [{ name: "vue", version }, ...globalBuildPackages.map((name) => ({ name, version }))];
}

function tailwindPackages() {
  return config.tailwind.packages.map((name) => ({ name, version: tailwind.devDependencies[name] }));
}

function heroiconsPackages() {
  return [{ name: "heroicons", version: config.heroicons.version }];
}

const LICENSE_FILE = /^(licen[sc]e|copying|unlicen[sc]e)([-._].*)?$/i;
const NOTICE_FILE = /^notice([-._].*)?$/i;
const COPYRIGHT_LINE = /^\s*(Copyright\b(?!\s+(licen[sc]e|notice|owner|holder))|©|\(c\)\s*\d|All [Rr]ights [Rr]eserved)/;
const TITLE_LINE = /^\s*(the )?[\w. -]*licen[sc]e( \([\w.-]+\))?:?\s*$/i;

async function describe({ name, version }) {
  const dir = await fetchPackage(name, version);
  const pkg = JSON.parse(fs.readFileSync(path.join(dir, "package.json"), "utf8"));
  const files = fs.readdirSync(dir);
  const licenseFiles = files.filter((f) => LICENSE_FILE.test(f) && fs.statSync(path.join(dir, f)).isFile());
  const noticeFiles = files.filter((f) => NOTICE_FILE.test(f));
  const choice = config.licenseChoice[name];
  const declared = typeof pkg.license === "string" ? pkg.license : pkg.license?.type;
  const spdx = choice ?? declared ?? config.declaredLicense[name];
  if (!spdx) throw new Error(`${name}@${version} declares no license; add it to declaredLicense in bundles.json (after reading its license file)`);
  if (/GPL/i.test(spdx)) throw new Error(`${name}@${version} is ${spdx}: stop and report instead of shipping it`);
  if (licenseFiles.length === 0) throw new Error(`${name}@${version} has no license file`);
  const text = licenseFiles
    .map((f) => fs.readFileSync(path.join(dir, f), "utf8").replace(/\r\n/g, "\n").trim())
    .join("\n\n");
  const copyright = text
    .split("\n")
    .filter((line) => COPYRIGHT_LINE.test(line) && !/\[(yyyy|name)/i.test(line))
    .map((line) => line.trim());
  const author = typeof pkg.author === "string" ? pkg.author : pkg.author?.name;
  const notice = noticeFiles.map((f) => fs.readFileSync(path.join(dir, f), "utf8").replace(/\r\n/g, "\n").trim()).join("\n\n");
  const repository = typeof pkg.repository === "string" ? pkg.repository : pkg.repository?.url ?? pkg.homepage ?? "";
  return {
    name,
    version,
    spdx,
    declared,
    chosen: Boolean(choice),
    text,
    copyright: copyright.filter((l) => !/^all rights reserved\.?$/i.test(l)),
    author,
    notice,
    url: repository.replace(/^git\+/, "").replace(/\.git$/, "").replace(/^git:/, "https:"),
  };
}

// The permission text with the copyright lines taken out, so that "the same
// license, different owner" compares equal.
function body(text) {
  return withoutCopyright(text)
    .replace(/^\s*[^\n]*\n/, (first) => (TITLE_LINE.test(first) ? "" : first))
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();
}

function withoutCopyright(text) {
  return text
    .split("\n")
    .filter((line) => !COPYRIGHT_LINE.test(line))
    .join("\n");
}

function bodyOf(entry) {
  return entry.chosen ? null : body(entry.text);
}

const bundles = [
  { file: config.mermaid.file, title: `Mermaid ${config.mermaid.version}`, packages: await mermaidPackages() },
  { file: config.vue.file, title: `Vue ${config.vue.version} (global production build)`, packages: vuePackages() },
  { file: "tailwind.css", title: "Tailwind CSS (built from script/tailwind/)", packages: tailwindPackages() },
  { file: "lib/templates/index.html.erb", title: "Inline icons", packages: heroiconsPackages() },
];

for (const bundle of bundles) {
  const unique = new Map(bundle.packages.map((p) => [`${p.name}@${p.version}`, p]));
  bundle.entries = (
    await inBatches([...unique.values()], 8, describe)
  ).sort((a, b) => a.name.localeCompare(b.name) || a.version.localeCompare(b.version, undefined, { numeric: true }));
}

const all = new Map();
for (const bundle of bundles) {
  for (const entry of bundle.entries) all.set(`${entry.name}@${entry.version}`, entry);
}

// Group the license texts: a package whose text is the same as the most
// common text of its license (apart from the copyright lines) shares it; one
// whose text differs keeps its own, verbatim.
const bySpdx = new Map();
for (const entry of all.values()) {
  if (!bySpdx.has(entry.spdx)) bySpdx.set(entry.spdx, []);
  bySpdx.get(entry.spdx).push(entry);
}
const shared = new Map();
const verbatim = [];
for (const [spdx, entries] of bySpdx) {
  const counts = new Map();
  for (const e of entries) {
    const b = bodyOf(e);
    if (b) counts.set(b, (counts.get(b) ?? 0) + 1);
  }
  const canonical = [...counts].sort((a, b) => b[1] - a[1])[0]?.[0];
  const source = entries.find((e) => !e.chosen && body(e.text) === canonical);
  shared.set(spdx, source ? withoutCopyright(source.text).replace(/\n{3,}/g, "\n\n").trim() : null);
  for (const e of entries) {
    if (!e.chosen && body(e.text) !== canonical) verbatim.push(e);
  }
}
for (const [spdx, text] of shared) {
  if (!text) throw new Error(`no package states the ${spdx} text itself (only dual-licensed ones); add a package that does or write the text into bundles.json`);
}

const lines = [];
const out = (s = "") => lines.push(s);
const fenced = (text) => {
  const fence = text.includes("```") ? "~~~~" : "```";
  out(fence);
  out(text);
  out(fence);
};
const owners = (e) =>
  e.copyright.length ? e.copyright.join("; ") : `no copyright line in its license file${e.author ? ` (author in package.json: ${e.author})` : ""}`;

out("# Third-party licenses");
out();
out("This file is generated by `script/licenses/generate.mjs`; do not edit it by hand.");
out("It lists everything that is inside the front-end files shipped with this gem and");
out("copied into every `index.html` it generates, with the license and the copyright");
out("notice of each. The text of each license follows the lists.");
out();
out("| File | SHA-256 | What is in it |");
out("| ---- | ------- | ------------- |");
for (const bundle of bundles) {
  const file = path.join(vendor, bundle.file);
  const sum = bundle.file.startsWith("lib/") || !fs.existsSync(file) ? "—" : `\`${sha256(file)}\``;
  out(`| \`${bundle.file}\` | ${sum} | ${bundle.title}: ${bundle.entries.length} package${bundle.entries.length === 1 ? "" : "s"} |`);
}
out();
out("The SHA-256 values are those of `CHECKSUMS.txt`. The test suite fails when they");
out("differ, which means a file was replaced without regenerating this list.");
for (const bundle of bundles) {
  out();
  out(`## ${bundle.title}`);
  out();
  out(`In \`${bundle.file}\`.`);
  out();
  for (const e of bundle.entries) {
    const license = e.chosen ? `${e.spdx} (this package is ${e.declared.replace(/^\(|\)$/g, "")}; the Apache License is the one taken)` : e.spdx;
    out(`- **${e.name}** ${e.version} — ${license} — ${owners(e)}${e.url ? ` — <${e.url}>` : ""}`);
  }
}
out();
out("## License texts");
for (const [spdx, text] of [...shared].sort((a, b) => a[0].localeCompare(b[0]))) {
  const members = bySpdx.get(spdx).filter((e) => e.chosen || !verbatim.includes(e));
  out();
  out(`### ${spdx}`);
  out();
  out(`Applies to: ${[...new Set(members.map((e) => `${e.name} ${e.version}`))].sort().join(", ")}.`);
  out("The copyright notice of each is the one given in the lists above.");
  out();
  fenced(text);
  const notices = members.filter((e) => e.notice);
  for (const e of notices) {
    out();
    out(`NOTICE of ${e.name}:`);
    out();
    fenced(e.notice);
  }
}
if (verbatim.length) {
  out();
  out("### Licenses with their own wording");
  out();
  out("These packages' license files differ from the standard text, so they are given as they are.");
  const seen = new Set();
  for (const e of verbatim.sort((a, b) => a.name.localeCompare(b.name))) {
    if (seen.has(`${e.name}\n${e.text}`)) continue;
    seen.add(`${e.name}\n${e.text}`);
    const versions = verbatim.filter((v) => v.name === e.name && v.text === e.text).map((v) => v.version);
    out();
    out(`#### ${e.name} ${versions.join(", ")}`);
    out();
    fenced(e.text);
    if (e.notice) {
      out();
      fenced(e.notice);
    }
  }
}

const result = `${lines.join("\n")}\n`;
for (const bad of ["-->", "--!>", "<!--", "</script"]) {
  if (result.includes(bad)) throw new Error(`the text contains "${bad}", which cannot be embedded in the generated HTML as it is`);
}
fs.writeFileSync(path.join(vendor, "LICENSES.md"), result);
fs.rmSync(work, { recursive: true, force: true });
console.log(`wrote lib/templates/vendor/LICENSES.md: ${all.size} packages, ${result.length} bytes`);
