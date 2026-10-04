# Vendored front-end assets

The two minified JS bundles and the stylesheet in this directory are
inlined into the generated `index.html` by `lib/tasks/mermaid_erd.rake`
so the output works offline and is unaffected by upstream CDN outages
(see issue #85).

What is inside them is redistributed under the licenses listed in
`LICENSES.md` (MIT, ISC, BSD-3-Clause, Apache-2.0 and a few others). That
file carries the copyright notices and permission texts these licenses ask
for. It is generated, and `lib/tasks/mermaid_erd.rake` copies it into the
head of every generated `index.html`; see "Licenses" below.

## JS bundles

| File | Upstream URL | Version |
| ---- | ------------ | ------- |
| `mermaid.min.js` | `https://unpkg.com/mermaid@11.15.0/dist/mermaid.min.js` | Mermaid 11.15.0 |
| `vue.global.prod.min.js` | `https://cdnjs.cloudflare.com/ajax/libs/vue/3.2.40/vue.global.prod.min.js` | Vue 3.2.40 (production build) |

To refresh, re-run the equivalent of:

```sh
cd lib/templates/vendor
curl -sSfL -o mermaid.min.js          'https://unpkg.com/mermaid@11.15.0/dist/mermaid.min.js'
curl -sSfL -o vue.global.prod.min.js  'https://cdnjs.cloudflare.com/ajax/libs/vue/3.2.40/vue.global.prod.min.js'
sha256sum *.js
```

Then update both the version column above and `CHECKSUMS.txt`, and
regenerate the license list (see "Licenses" below). Bumping
Mermaid across a major version (9 → 10 → 11) requires updating
`lib/templates/index.html.erb` because the render API became async in
Mermaid 10. Bumping Vue across a major may require Composition API
adjustments.

## Stylesheet (`tailwind.css`)

`tailwind.css` is not downloaded. It is built from the viewer's markup
with the official Tailwind CSS command-line tool, and the result is
checked in so that gem users never need Node. The inputs live outside the
gem, in `script/tailwind/`:

| File | Purpose |
| ---- | ------- |
| `package.json` / `package-lock.json` | Pins `tailwindcss` 3.1.8, `@tailwindcss/forms` 0.5.2 and `@tailwindcss/typography` 0.5.4 (all MIT) |
| `tailwind.config.js` | Scans `lib/templates/index.html.erb` and `lib/assets/logo.svg` for class names and enables the two plugins |
| `input.css` | The three `@tailwind` directives |

To rebuild after changing a class in the template (or a pinned version):

```sh
cd script/tailwind
npm ci
npm run build          # writes lib/templates/vendor/tailwind.css
sha256sum ../../lib/templates/vendor/tailwind.css
```

Then update `CHECKSUMS.txt` and regenerate the license list. The CLI finds a class only when it appears
in the template as a complete string. A class name assembled at runtime
(`'bg-' + color`) is not found, so write the whole class out or add it to
`safelist` in `tailwind.config.js`. Every class the template builds in a
`:class` binding is already written out in full.

After a refresh, regenerate `docs/example.html` per `RELEASE.md`.

## Licenses (`LICENSES.md`)

`LICENSES.md` is not written by hand. After any change to `mermaid.min.js`,
`vue.global.prod.min.js`, `tailwind.css` (including a new Tailwind package
version), or the inline Heroicons icons in the template, rebuild it:

```sh
node script/licenses/generate.mjs     # Node 18+, needs network
```

It downloads the packages into a temporary directory and writes the name,
version, license, copyright notice and permission text of each. What it
treats as "in the bundle":

| File | Source of the package list |
| ---- | -------------------------- |
| `mermaid.min.js` | `dist/mermaid.min.js.map` of the npm package, after checking that npm's `dist/mermaid.min.js` is byte-for-byte the vendored file. The parser that Mermaid bundles from a sibling package is found by its chunk file names, and its own third-party code (langium, chevrotain, ...) is read from the chunks' maps |
| `vue.global.prod.min.js` | The `vue` package and the `@vue/*` packages of the global build, listed in `script/licenses/bundles.json` |
| `tailwind.css` | `tailwindcss` and `@tailwindcss/forms` from `script/tailwind/package.json` |
| the template | Heroicons (inline SVG), version in `bundles.json` |

`script/licenses/bundles.json` also holds the two choices a package cannot
tell us: which license we take from a dual-licensed package
(`licenseChoice`; DOMPurify is MPL-2.0 OR Apache-2.0 and we take
Apache-2.0), and the license of a package that declares none
(`declaredLicense`; set it only after reading its license file). The script
stops when a package is GPL, LGPL or AGPL, declares no license that is
known, or has no license file. If it stops for GPL, LGPL or AGPL, report it
instead of working around it.

Update the Mermaid or Vue version in `bundles.json` together with the table
above. `spec/rails-mermaid_erd/rake_task_spec.rb` fails when the SHA-256
values in `LICENSES.md` differ from `CHECKSUMS.txt` or from the files, so a
bundle that was replaced without regenerating the list is caught.
