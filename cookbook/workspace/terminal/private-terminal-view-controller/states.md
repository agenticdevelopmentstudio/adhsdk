
| State | Appearance change |
|-------|------------------|
| Default (screen up, shell not started) | Privacy screen over the pane, crossed-out eye, message "Click the eye to start this private terminal."; terminal view hidden. |
| Screen up, shell started | The same, with the message "Click the eye to show this terminal." |
| Authenticating | No visible change; a second reveal or edit press does nothing until the first ends. |
| Revealed | Privacy screen hidden, terminal view visible and first responder, window excluded from screen capture; the accessory shows an open eye titled "Hide the private terminal". |
| Failed (authentication or silent load) | Screen stays up; the message shows the error description. |
| Shell exited | Terminal remains as it was; the connectable offer is nil because the session is no longer running. |
| Pressed | Not applicable: the eye and the Edit button use the system button press feedback with no custom state. |
| Disabled | Not applicable: no control is disabled by this class. |
| Focused | The terminal view takes focus on reveal; the controller adds no focus ring of its own. |
| Loading | Not applicable: the class shows no loading indication during authentication. |

