# Vendored front-end assets

The three minified JS bundles in this directory are inlined into the
generated `index.html` by `lib/rails-mermaid_erd.rb` so the output works
offline and is unaffected by upstream CDN outages (see issue #85).

Each bundle is redistributed under its own MIT license; see
`LICENSES.md` for the full notices.

## How to refresh

| File | Upstream URL | Version |
| ---- | ------------ | ------- |
| `tailwindcss.js` | `https://cdn.tailwindcss.com/3.1.8?plugins=forms@0.5.2,typography@0.5.4` | Tailwind Play CDN 3.1.8 (with `forms` 0.5.2 + `typography` 0.5.4 plugins) |
| `mermaid.min.js` | `https://unpkg.com/mermaid@11.15.0/dist/mermaid.min.js` | Mermaid 11.15.0 |
| `vue.global.prod.min.js` | `https://cdnjs.cloudflare.com/ajax/libs/vue/3.2.40/vue.global.prod.min.js` | Vue 3.2.40 (production build) |

The `tailwindcss.js` URL is the Tailwind Play CDN endpoint, not a
versioned dist file. The query string pins the Tailwind core and
plugin versions; refresh the URL when bumping any of them.

To refresh, re-run the equivalent of:

```sh
cd lib/templates/vendor
curl -sSfL -o tailwindcss.js          'https://cdn.tailwindcss.com/3.1.8?plugins=forms@0.5.2,typography@0.5.4'
curl -sSfL -o mermaid.min.js          'https://unpkg.com/mermaid@11.15.0/dist/mermaid.min.js'
curl -sSfL -o vue.global.prod.min.js  'https://cdnjs.cloudflare.com/ajax/libs/vue/3.2.40/vue.global.prod.min.js'
sha256sum *.js
```

Then update both the version column above and `CHECKSUMS.txt`. Bumping
Mermaid across a major version (9 → 10 → 11) requires updating
`lib/templates/index.html.erb` because the render API became async in
Mermaid 10. Bumping Vue across a major may require Composition API
adjustments. Tailwind plugin versions only affect generated utility
class output.

After a refresh, regenerate `docs/example.html` per `RELEASE.md` and
re-run the offline `chromium --headless` check in
`tmp/blue-green/run-offline.sh` to confirm the new bundle still
renders without network access.
