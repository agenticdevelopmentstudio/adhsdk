
| State | Appearance change |
|-------|------------------|
| Default | Segments in the track; none selected until `selectedID` names an item |
| Selected | The chosen segment's bezel is the palette's accent colour |
| No selection | `selectedID` is `nil` or unknown; no segment drawn as selected |
| Pressed | Drawn by AppKit's segmented control; the component adds nothing |
| Dark theme | Track drawn in the dark appearance when the window background brightness is below 0.5 |
| Light theme | Track drawn in the light appearance otherwise |
| Disabled | Not applicable: the component never sets the control's enabled state, so it has no disabled appearance of its own |
| Focused | Not applicable: the control refuses first responder and its focus ring is off, so it never shows focus |
| Loading | Not applicable: the bar is static and has no asynchronous work |

