
| Option | Type | Default | Description |
|---|---|---|---|
| `page` | `number` | required | Current 1-based page; drives the caption and which edge is disabled. |
| `totalPages` | `number` | required | Total page count; `<= 1` renders nothing. |
| `onPageChange` | `(page: number) => void` | required | Called with the requested page (`page ± 1`) when `Prev`/`Next` is clicked. |
| `className` | `string` | — | Extra classes merged onto the `nav` via `cn()`. |

