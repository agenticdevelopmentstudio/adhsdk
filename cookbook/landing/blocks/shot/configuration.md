
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `string` | — (required) | Window title text drawn in the frame's title bar. |
| `caption` | `string` | — (required) | Text rendered as the placeholder's caption when `media` is absent; also the string the host should reuse for `media`'s alt/aria text. |
| `pendingLabel` | `ReactNode` | `undefined` | Status line rendered above the caption in the placeholder; omitted (or falsy), the placeholder shows only the caption. |
| `media` | `ReactNode` | `undefined` | Content (e.g. an `<img>`, `<video>`, or this package's `Clip`) rendered in place of the placeholder, exactly as given with no transformation. |

