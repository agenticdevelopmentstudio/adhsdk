
| State | Behaviour |
|---|---|
| Loading | A plain "Loading…" line in the list, the log and the viewer (for each page). |
| Empty | "No one has asked to see your content" on the person's pane; "No grants yet." for a product admin, "No grants." for an operator, "Nothing has been viewed yet." for a log, "No rows." for a table. |
| Error | The backend's message as error text ("Couldn't load support access: ..." on the person's pane), with no retry control. A 403 `step_up_required` is not an error on the product admin's pane. |
| Switch off | The person's pane renders nothing; its settings tab is hidden. A product admin's or operator's pane says support access is not turned on. |
| Pending, live, ended | The card's badge and the actions it offers. |

