
| Event | Properties | When |
|-------|-----------|------|
| `search-dialog.opened` | `{}` | Dialog `open` prop transitions from `false` to `true`. |
| `search-dialog.closed` | `{ reason: "escape" \| "backdrop" }` | Dialog closes via Escape or backdrop click. |
| `search-dialog.query_changed` | `{ query: string, length: number }` | User types in the input field; `state.setQuery()` is called. |
| `search-dialog.results_shown` | `{ result_count: number, top_k: number }` | Results are rendered (top 20 are sliced); triggered when query is truthy. |
| `search-dialog.result_selected` | `{ slug: string, section: string, index: number }` | User selects a result via click or Enter. |
| `search-dialog.selection_navigated` | `{ from_index: number, to_index: number }` | User presses arrow key and `state.handleKey()` changes `selectedIndex`. |

Analytics emission is not implemented in the component source. The events above describe integration points a call site MAY wire up around `onClose`, `onSelect`, and `state` mutations — they document a possible data collection contract, not one the component enforces.

