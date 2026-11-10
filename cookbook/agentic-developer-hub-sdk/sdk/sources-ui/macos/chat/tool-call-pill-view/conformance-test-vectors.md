
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pill-001 | render-activity-name | CommandActivity with `invocation.commandName = "fetch_data"`, `result = nil` | Text reads "fetch_data" |
| pill-002 | apply-status-color, render-border | CommandActivity with `result = nil` | Label text and border colored `.info` |
| pill-003 | apply-status-color, render-border | CommandActivity with `result.ok = true` | Label text and border colored `.success` |
| pill-004 | apply-status-color, render-border | CommandActivity with `result.ok = false` | Label text and border colored `.danger` |
| pill-005 | display-error-on-failure | CommandActivity with `result.ok = false`, `result.errorMessage = "Connection timeout"` | Text reads "fetch_data — Connection timeout" |
| pill-006 | display-error-on-failure | CommandActivity with `result.ok = false`, `result.errorMessage = ""` or `nil` | Text reads "fetch_data" (name only) |
| pill-007 | truncate-overflow-text | CommandActivity with command name exceeding available width | Text ends with ellipsis; does not overflow pill boundary |
| pill-008 | observe-theme-changes | Pill on screen; theme palette changes | The same pill view instance updates its border and text colors in place; no new instance is created |
| pill-009 | use-caption-font | Pill rendered | Rendered font matches the semantic palette's `caption` text style (`palette.font(.caption)` in the reference implementation) |
| pill-010 | apply-padding, apply-corner-radius | Pill rendered | Vertical padding 4pt, horizontal 10pt, corner radius 9pt |
| pill-011 | use-elevated-surface | Pill rendered | Background color matches the semantic palette's `elevated-surface` role (`palette.nsColor(.elevatedSurface)` in the reference implementation) |
| pill-012 | render-border | Pill rendered | 1-point border present and colored per status |

