# Vendored front-end assets

The two minified JS bundles and the stylesheet in this directory are
inlined into the generated `index.html` by `lib/tasks/mermaid_erd.rake`
so the output works offline and is unaffected by upstream CDN outages
(see issue #85).

Each one is redistributed under its own MIT license; see
`LICENSES.md` for the full notices.

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

Then update both the version column above and `CHECKSUMS.txt`. Bumping
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

Then update `CHECKSUMS.txt`. The CLI finds a class only when it appears
in the template as a complete string. A class name assembled at runtime
(`'bg-' + color`) is not found, so write the whole class out or add it to
`safelist` in `tailwind.config.js`. Every class the template builds in a
`:class` binding is already written out in full.

After a refresh, regenerate `docs/example.html` per `RELEASE.md`.
