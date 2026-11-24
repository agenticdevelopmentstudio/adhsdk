
| State | Appearance change |
|---|---|
| Closed | not rendered |
| Open, `allowRoot` unset, no `initialSelectedId` | confirm disabled; no row shows `bg-apt-gold/15` (there is no root row to highlight) |
| Open, `allowRoot` set, no `initialSelectedId` | `null` selection is the root row: "Top level" shows `bg-apt-gold/15` from open; confirm enabled while the filter is empty, disabled once it isn't |
| Row selected (allowed) | `bg-apt-gold/15`; confirm enabled |
| Row selected (forbidden) | cannot occur — a forbidden row cannot be clicked into selection |
| Node collapsed | `ChevronRight`; children not in the DOM or the keyboard order |
| Node expanded | `ChevronDown`; children rendered and reachable by ArrowDown |
| Filtering | tree replaced by a flat `listbox` of trail-annotated matches |
| No categories | "No categories yet." (browse mode only) |
| No filter match | `No categories match "<text>".` |
| `busy=true` | field disabled; Cancel and Confirm both replaced by a `role="status"` loading spinner (no buttons in the DOM) |
| `error` set | `ErrorText` renders above the button bar |

