
Vectors 001 to 004 come from `agent.test.tsx` in `packages/web/packages/landing/src/__tests__/`; the rest follow from the source. `site` is a name, a URL and a description, with the URL `https://x.example` in the tests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| json-ld-001 | add-website, website-id, website-fields, graph-context, graph-array, preserve-order (test: adds a WebSite ahead of the site's own entities) | `withWebSite(site, { "@context": "https://schema.org", "@graph": [{ "@type": "Organization", name: "O" }] })` | `{ "@context": "https://schema.org", "@graph": [ { "@type": "WebSite", "@id": "https://x.example/#website", ...site }, { "@type": "Organization", name: "O" } ] }` |
| json-ld-002 | keep-own-website, strip-context (test: keeps a WebSite the site already declares) | `withWebSite(site, { "@context": "https://schema.org", "@type": "WebSite", name: "Mine" })` | `@graph` equals `[ { "@type": "WebSite", name: "Mine" } ]`; no entity is added |
| json-ld-003 | escape-less-than, render-script-element, serialize-data (test: escapes `<` so the data cannot close its script) | `JsonLd` rendered with `data={{ name: "</script><b>" }}` | The markup is `<script type="application/ld+json">{"name":"\u003c/script>\u003cb>"}</script>` |
| json-ld-004 | no-other-escaping (test: the same assertion) | The `data` of json-ld-003 | The `>` characters appear unescaped in the output |
| json-ld-005 | extra-optional | `withWebSite(site)` and `withWebSite(site, null)` | `@graph` holds one entity, the added `WebSite` |
| json-ld-006 | website-id, website-fields | `site.url` of `https://x.example///` | `@id` is `https://x.example/#website` and `url` is still `https://x.example///` |
| json-ld-007 | extra-forms, preserve-order | `extra` is a single entity `A` | `@graph` is the `WebSite`, then `A` |
| json-ld-008 | flatten-nested, preserve-order | `extra` is `[A, { "@graph": [B, [C]] }, D]` | `@graph` is the `WebSite`, `A`, `B`, `C`, `D` in that order |
| json-ld-009 | strip-context | `extra` is an entity carrying its own `@context` | The entity in `@graph` has no `@context` key |
| json-ld-010 | no-mutation | `extra` is an entity carrying an `@context` | After the call the original object still has its `@context` |
| json-ld-011 | website-type-exact | `extra` is an entity whose `@type` is `["WebSite", "Thing"]` | A `WebSite` is still added first, because the array is not equal to the string |
| json-ld-012 | extra-optional, flatten-nested | `extra` is `{ "@graph": [] }` | `@graph` holds only the added `WebSite` |
| json-ld-013 | pure-functions | `withWebSite` called twice with equal arguments | Both results are deeply equal and no call has an observable side effect |

