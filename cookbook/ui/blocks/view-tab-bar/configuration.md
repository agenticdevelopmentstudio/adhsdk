
| Option | Type | Default | Required | Description |
|--------|------|---------|----------|-------------|
| `tabs` | `ViewTabItem[]` | — | Yes | Array of tab items, each with `value`, `label`, and optional `title` |
| `value` | `string` | — | Yes | The currently active tab value. It MUST match one of the `tabs[].value` entries for a tab to render as active; if none match, no tab is marked active (see Edge Cases) |
| `onChange` | `(value: string) => void` | — | Yes | Callback invoked when a tab button is clicked, receiving the clicked tab's value |
| `links` | `ViewTabLink[]` | `[]` | No | Array of link items, each with `href`, `label`, and optional `active` boolean |
| `className` | `string` | — | No | Additional CSS class(es) to apply to the outer container via `cn()` |

