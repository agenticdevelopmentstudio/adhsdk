
| State | Appearance change |
|-------|------------------|
| Default | Three panes shown in order; polling runs only while the view is on screen. |
| Pressed | Not applicable: the controller is a container with no pressed state; presses occur in the panes. |
| Disabled | Not applicable: the controller has no disabled state in source. |
| Focused | Not applicable: the controller sets no focus behavior of its own. |
| Loading | Not applicable on the controller: the model publishes a loading flag, and the controller does not read it. |
| Polling | View on screen: a refresh task is waiting or refreshing. No visual change. |
| Idle | View off screen: no refresh task exists. |
| Error | An alert sheet (or modal alert when there is no window) is up with the model's message until the user clicks OK. |

