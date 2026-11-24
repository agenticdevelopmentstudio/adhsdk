
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `maxWidth` | number (pt/px) | required, caller-provided | Maximum bubble width; content wraps and the bubble sizes down to fit within it (see **size-to-content**) |
| `showDetailArrow` | boolean | `false` | Whether to render the optional detail-indicator button (see **detail-indicator**) |
| `onDetailArrowClick` | callback | none | Invoked when the caller activates the detail-indicator button |
| `isSelected` | boolean (web only) | `false` | Applies the `.pc-message-selected` visual state (see **selected-state**) |
| `onClick` | callback (web only) | none | Invoked when the message container is clicked or tapped (see **container-click-handler**) |
| `index` | number (web only) | none | Message's position in the transcript; required to render a connector anchor when `message.popover` is set (see **connector-anchor**) |

