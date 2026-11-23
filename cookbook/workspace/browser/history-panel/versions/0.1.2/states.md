
| State | Appearance change |
|-------|------------------|
| Recent (empty filter) | The list shows the most recent visits, newest first. |
| Filtered | The list shows only visits whose title or address contains the trimmed filter, newest first. |
| Empty | The list shows no rows and no text — no "No history" label or other empty-state message. |
| Row selected | The row draws in the list's selection colors; the remove button acts on the selection. |
| Nothing selected | The remove button removes nothing when pressed (whether it also draws disabled is the builder's choice — see Design Decisions). |
| Confirming clear | A confirmation sheet is shown over the window that hosts the panel; nothing has been removed yet. |
| Loading | Not applicable: no loading indicator is shown; the list keeps its previous rows until the latest reload answers and then replaces them. |
| Window already open | Show History brings the existing window up; no second window appears. |

