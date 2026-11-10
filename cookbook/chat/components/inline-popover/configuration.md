
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data` | `PopoverData` | required | Object containing `title`, `description`, and `links` properties |
| `data.title` | `string` (declared required by `PopoverData`; TypeScript rejects an object literal that omits it) | (required) | Title text displayed in the toggle button. The component itself tolerates a falsy value at runtime and skips rendering it — see **render-title-when-provided** — but the declared type does not make it optional. |
| `data.description` | `string \| undefined` | undefined | Optional description text displayed in the disclosure body |
| `data.links` | `Array<{ label: string; url: string }> \| undefined` | undefined | Optional array of link objects. `PopoverData` declares both `label` and `url` as required per item; the component tolerates a falsy `label` at runtime and falls back to displaying the `url` — see **Link with missing label** — but the declared type does not make `label` optional. |
| `defaultOpen` | `boolean` | `true` | Initial open/closed state of the disclosure |

