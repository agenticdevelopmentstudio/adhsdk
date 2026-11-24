
- **render-activity-name**: The component MUST display the command's name from `activity.invocation.commandName` as the pill's text content.
- **display-error-on-failure**: When `activity.result` exists and `result.ok` is `false`, the component MUST append the error message in the format `"<name> — <message>"` where `<name>` is the command name and `<message>` is `result.errorMessage`, or display only the name if `errorMessage` is `nil` or empty.
- **truncate-overflow-text**: Text longer than the available width MUST be truncated at the tail with an ellipsis (`…`).
- **apply-status-color**: The component MUST color its label text and border according to the activity state: `.info` (neutral blue) while `activity.result` is `nil`, `.success` (green) when `result.ok` is `true`, and `.danger` (red) when `result.ok` is `false`.
- **observe-theme-changes**: The component MUST observe theme palette changes on initialization and recolor itself live, without requiring a view hierarchy rebuild. See **Platform Notes** for the observer used on Apple platforms.
- **use-caption-font**: The component MUST render text using the semantic palette's `caption` text style.
- **render-border**: The component MUST display a 1-point border around the pill.
- **apply-corner-radius**: The component MUST have a corner radius of 9 points.
- **apply-padding**: The component MUST apply 4 points of vertical padding and 10 points of horizontal padding between the text and the pill's edges.
- **use-elevated-surface**: The component MUST use the semantic palette's `elevated-surface` background role.

