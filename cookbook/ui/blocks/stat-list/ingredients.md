
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| StatusDot | [adhsdk.ingredient.ui.components.display.status-dot](cookbook:1a044d34-d585-46b4-b703-dea3fb9b9642) | The leading tone dot on each row (size 7), decorative (no aria label — the row's text carries the meaning) | yes | `tone` per row from `StatListRow.tone`; fixed `size={7}` |

In this toolkit, leaf UI components are themselves recipes rather than a
separate `ingredient` type, so `StatusDot` is cited here by its recipe domain.

`StatListRow`'s label and trailing content are caller-supplied `ReactNode`s, not
components this block owns; `StatList` is a bare wrapper element.

