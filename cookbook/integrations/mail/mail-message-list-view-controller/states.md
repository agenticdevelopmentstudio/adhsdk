
| State | Appearance change |
|-------|------------------|
| Default | Rows shown, empty label hidden. |
| Pressed | Not applicable: the list has no pressed styling of its own; the table's standard row highlight applies. |
| Disabled | Not applicable: the source has no disabled state for the list. |
| Focused | The selected row uses the table's standard selection look; the source sets no custom focus styling. |
| Loading | With no messages, the centered label reads `Loading…`. With messages present the label is hidden and rows stay visible. |
| Empty | With no messages and not loading, the centered label reads `No messages`. |
| Unread row | Accent dot visible, sender bold, subject semibold. |
| Read row | Dot hidden, sender and subject regular. |
| Selected row | The row matching the model's `selectedMessageId` is selected in the table. |

