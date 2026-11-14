
| State | Appearance change |
|-------|------------------|
| Default (not begun) | Panel off screen; no monitor; no outline. |
| Waiting | Panel up; message "Click on a terminal to connect to."; button "Cancel". |
| Wrong pick | Message "That isn't a terminal. Click on a terminal to connect to."; still waiting. |
| Picked | Pane outlined; message "Connected to <pane title>."; button "OK" with Return as its key equivalent; clicks in the host window pass through. |
| Finished | Panel off screen; monitor and outline removed; callbacks cleared. |
| Pressed / Focused | Not applicable: the button is a standard rounded system button and the source sets no custom pressed or focused appearance. |
| Disabled | Not applicable: the source never disables the button. |
| Loading | Not applicable: the picker does no asynchronous work. |

