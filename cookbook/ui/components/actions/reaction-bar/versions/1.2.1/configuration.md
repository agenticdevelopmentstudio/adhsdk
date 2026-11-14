
| Option | Type | Default | Description |
|---|---|---|---|
| `reactions` | `ReactionBarItem[]` | — | The subject's tallies, in the order they should read. Required. |
| `onToggle` | `(emoji: string) => void` | — | Add the emoji when the viewer has not reacted with it, take it back when they have. Required. |
| `subjectLabel` | `string` | — | Names the subject in every control's accessible name. Required. |
| `choices` | `readonly string[]` | `DEFAULT_REACTIONS` | What the palette offers. |
| `busy` | `boolean` | `false` | A write is in flight: everything is inert, nothing is hidden or re-ordered. |
| `disabled` | `boolean` | `false` | The viewer may not react; counts still show, the palette trigger is not rendered. |
| `className` | `string` | — | Extra classes for the row; merged via `cn()`. |

`ReactionBarItem` is `{ emoji: string; count: number; mine: boolean }`.

`DEFAULT_REACTIONS` is `["👍", "🎉", "👀", "🙏", "😄", "❤️"]`, in that order.

