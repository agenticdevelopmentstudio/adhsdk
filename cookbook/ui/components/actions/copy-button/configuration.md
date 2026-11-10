
| Option | Type | Default | Description |
|---|---|---|---|
| `getText` | `() => string` | required | Produces the text to copy, evaluated at click time; return `""` to copy nothing. |
| `label` | `string` | required | Accessible name (`aria-label`) and the idle hover `title`. |
| `className` | `string` | — | Extra classes merged onto the button via `cn()` (e.g. spacing). |

The 1200 ms success window and the outline/icon/`size-6` chrome are fixed by the
component and are not exposed as props — see Design Decisions.

