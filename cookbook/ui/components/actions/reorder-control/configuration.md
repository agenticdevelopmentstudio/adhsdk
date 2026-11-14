
| Prop | Type | Required | Default | Description |
|---|---|---|---|---|
| `onMoveUp` | `() => void` | yes | — | Move the row one place toward the start of its list. |
| `onMoveDown` | `() => void` | yes | — | Move the row one place toward the end of its list. |
| `canMoveUp` | `boolean` | yes | — | False on the first row; the up button renders disabled rather than disappearing. |
| `canMoveDown` | `boolean` | yes | — | False on the last row. |
| `busy` | `boolean` | no | `false` | A move for this row is in flight: the pair dims and ignores clicks. |
| `subject` | `string` | no | `undefined` | Accessible subject appended to the labels, e.g. `"work item Ship it"`. |
| `className` | `string` | no | `undefined` | Extra classes for the outer container. |

Styling beyond `className` is controlled by the shared Button component.
