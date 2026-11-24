
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data` | `JsonLdValue` | required | The schema.org entity or `{ "@context", "@graph" }` document `JsonLd` serializes. |
| `site.name` | string | required | The name placed on the added `WebSite`. |
| `site.url` | string | required | The origin placed on the added `WebSite`; trailing slashes are trimmed for the `@id` only. |
| `site.description` | string | required | The description placed on the added `WebSite`. |
| `extra` | unknown | omitted | A document, an entity or a list of them, whose entities follow the `WebSite`. |

