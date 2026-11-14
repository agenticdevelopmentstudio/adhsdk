
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `messages` | `ChatMessage[]` | required | Array of message objects to render. |
| `isTyping` | `boolean` | required | Whether the remote participant is currently typing. |
| `selectedIndex` | `number` | `-1` | Index of the message to mark as selected; optional. |
| `onMessageClick` | `(index: number) => void` | `undefined` | Callback fired when a message is clicked; optional. |
| `renderPopover` | `(message: ChatMessage) => ReactNode` | `undefined` | Function to render a popover for each message; optional. |
| `showDetailArrows` | `boolean` | `false` | Whether to show detail arrows on messages that have a popover. |
| `onDetailArrowClick` | `(index: number) => void` | `undefined` | Callback fired when a detail arrow is clicked; optional. |
| `className` | `string` | `undefined` | Custom CSS class to append to the container. |
| `thinkingLabels` | `readonly StatusWordPair[]` | `undefined` | Word pairs for the typing indicator (falls back to dots if not provided). |
| `thinkingFrames` | `readonly string[]` | `undefined` | Animation frames for the typing indicator glyph. |
| `thinkingDoneGlyph` | `string` | `undefined` | Settled glyph to render when typing completes. |
| `thinkingColorful` | `boolean` | `false` | Whether to flash random non-green colors while typing. |
| `thinkingTint` | `StatusTintSpec` | `undefined` | Specification for which elements (glyph, words, both) receive tint while typing. |
| `suppressTypingIndicator` | `boolean` | `false` | If `true`, do not render the typing indicator even when `isTyping` is true. |
| `label` | `string` | `"Conversation transcript"` | Accessible name for the scroll region. |
| `fadeOlder` | `boolean` | `false` | Whether to apply a viewport-anchored fade gradient to older messages. |

