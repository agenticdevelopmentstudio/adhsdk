
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Fixed source list | list of source values | `["dns", "http", "glitchtip", "vercel", "vercel-runtime", "cloudflare-pages", "railway", "crunchy"]` | The default selection and its initial iteration order. Mirrors the server's own issue-source list. |
| Source type | closed enumeration | same 8 values | The type-checked domain of the toggle operation's argument. |
| Storage key | string | none (required) | The local-storage key the selection is kept under. The activity panel passes `adh-status-sources-<kind>`, one key per pane. |

Source Filter reads no environment variables or settings keys.

