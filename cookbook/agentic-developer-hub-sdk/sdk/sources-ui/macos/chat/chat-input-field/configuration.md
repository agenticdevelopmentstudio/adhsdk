
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| onSend | function(text) | (required) | Callback invoked when a message is sent; receives trimmed message text |
| placeholder | string | "Type a message..." | Text displayed in input when empty |
| autoFocus | boolean | false | Whether to automatically focus the input on mount |
| inputRef | platform ref type | undefined | External ref to access the underlying input element; see Platform Notes for the concrete type per platform (web: `RefObject<HTMLInputElement \| null>`; AppKit: a direct reference to the `NSTextField`/`ChatInputField` instance) |
| disabled | boolean | false | Whether the input is disabled and send is blocked |
| cornerRadius | number (points) | 6 | (macOS AppKit only) Corner radius of input field; 0 for terminal themes |
| showsBorder | boolean | true | (macOS AppKit only) Whether to draw the one-pixel border; false for terminal themes |
| usesBlockCaret | boolean | false | (macOS AppKit only) Whether to use a block caret (terminal style) instead of blinking bar |
| caretBlinks | boolean | true | (macOS AppKit only) Whether the caret (block or bar) blinks or remains solid |

