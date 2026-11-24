
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `maxWidth` | number (pt/px) | required, caller-provided | Maximum bubble width; content wraps and the bubble sizes down to fit within it (see **size-to-content**) |
| `showDetailArrow` | boolean | `false` | Whether to render the optional detail-indicator button (see **detail-indicator**) |
| `onDetailArrowClick` | callback | none | Invoked when the caller activates the detail-indicator button |
| `isSelected` | boolean (web only) | `false` | Applies the `.pc-message-selected` visual state (see **selected-state**) |
| `onClick` | callback (web only) | none | Invoked when the message container is clicked or tapped (see **container-click-handler**) |
| `index` | number (web only) | none | Message's position in the transcript; required to render a connector anchor when `message.popover` is set (see **connector-anchor**) |

The message the bubble renders (Web `ChatMessage` in `packages/web/packages/chat/src/types.ts`; Apple `any Message` from the [chat contract](cookbook:1f14e4d7-07ea-4f59-8365-5a15eb162def)):

| Field | Type | Description |
|-------|------|-------------|
| `sender` / `senderID` | `ChatParticipant` (`name`, optional `avatar`) on Web; `String` on Apple | Who sent the message |
| `isPersona` (Web) / `isLocalUser` (Apple) | boolean | Selects the persona or user theme role (see **theme-by-sender-role**) |
| `text` | string | Message text, rendered as markdown |
| `timestamp` | `Date` (required on Web), optional on Apple | See **timestamp-display** |
| `isStreaming` (Web) / `deliveryStatus == .composing` (Apple) | boolean / enum | Appends the streaming caret |
| `failure` (Web) / `deliveryStatus == .failed(reason)` (Apple) | optional string / enum | The failure reason; presence means failed |
| `deliveryStatus` (Apple) | enum | One of `composing`, `sending`, `sent`, `delivered`, `failed(reason:)`, `received` |
| `content` (Web) | `ContentItem[]`, each a link or an image | Rich content rendered after the text |
| `toolCalls` (Web) | `ToolCallInfo[]` (`name`, `arguments`, `status` of `started`, `completed` or `failed`) | One pill per call |
| `popover` (Web) | `PopoverData` | Enables the connector anchor in three-pane mode |

