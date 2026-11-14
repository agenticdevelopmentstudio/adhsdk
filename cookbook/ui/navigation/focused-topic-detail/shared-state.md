
| State | Source | Consumer | Direction | Mechanism |
|-------|--------|----------|-----------|-----------|
| Focused item id | Consumer | Block (selector, header, pane) | two-way | `focusedId` in, `onFocus` out |
| Active topic id | Consumer | Block (rail selection, derived header) | two-way | `activeTopicId` in, `onTopicSelect` out |
| Items | Consumer | Selector entries, All cards | one-way | `items` prop |
| Topics | Consumer | Rail rows, derived header | one-way | `topics` prop |

The block holds no state of its own.

