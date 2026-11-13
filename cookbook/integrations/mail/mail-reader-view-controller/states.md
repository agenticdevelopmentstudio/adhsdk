
| State | Appearance change |
|-------|------------------|
| Default | Same as Empty until the model publishes a message. |
| Pressed | Not applicable: the controller has no pressed state of its own; the "Load Remote Images" button uses the system pressed look. |
| Disabled | Not applicable: no control in the controller is ever disabled in source. |
| Focused | Not applicable: the controller sets no focus styling; focus drawing is the system's for the button and web view. |
| Loading | Not applicable: the controller shows no loading indicator while the body loads. |
| Empty | No message open: header, separator and body hidden; "No message selected" centered. |
| Message, remote blocked | Headers and body shown; remote-content bar shown when the message has an HTML body. |
| Message, remote allowed | Headers and body shown; the remote-content bar hidden; the body loaded without the policy or rules. |
| Message, text only | Headers and the text fallback page shown; the remote-content bar hidden. |

