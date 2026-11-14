
| State | Appearance change |
|-------|------------------|
| Default | Bar above (when shown), body below with the editor in editable mode. |
| Pressed | Not applicable: the pane is a layout container with no pressable surface of its own; the bar's buttons own pressed styling. |
| Disabled | Read-only: `editable` is false, the editor is given `readOnly`, and the bar is absent unless a draft or conflict is pending. |
| Focused | Not applicable: the pane takes no focus itself; focus lives in the bar's buttons and the editor's controls. |
| Loading | `document.value` is null: the body shows only the host's children and no editor. |
| Draft pending, not editable | The bar stays visible and the editor is read-only. |
| Conflict pending, not editable | The bar stays visible, including the bar's conflict warning with Reload theirs and Overwrite. |

