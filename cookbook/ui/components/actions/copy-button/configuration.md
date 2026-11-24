
| Option | Type | Default | Description |
|---|---|---|---|
| `getText` | `() => string` | required | Produces the text to copy, evaluated at click time; return `""` to copy nothing. |
| `label` | `string` | required | Accessible name (`aria-label`) and the idle hover `title`. |
| `className` | `string` | — | Extra classes merged onto the button via `cn()` (e.g. spacing). |
| `onCopied` | `() => void` | — | Called after the clipboard write succeeds, never after a refused write or an empty `getText()`. A host that must know the text really reached the clipboard (a once-shown secret) listens here rather than to the click. |

The 1200 ms success window and the outline/icon/`size-6` chrome are fixed by the
component and are not exposed as props — see Design Decisions.

