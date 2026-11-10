
Only the placeholder is caller-configurable today, via the `placeholder` option — it MUST be localizable by the caller (or a localization framework upstream of this component). On web, the "Message" and "Send" accessible labels are presently hardcoded English string literals in source with no override option (`aria-label="Message"`, `aria-label="Send"`); on macOS, only the send button gets a hardcoded label (`accessibilityDescription: "Send"`) — the input has no accessible label to localize at all. See **provide-accessible-label** and **provide-send-button-label**. The table below documents the intended default value and context for each string for a future localization layer or extraction tool; it does not reflect a runtime lookup by key in the current source.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| chat_input_placeholder | "Type a message..." | Placeholder text shown in empty input |
| aria_label_message_input | "Message" | Accessible label for input field on web (source hardcodes the English literal; not yet keyed). AppKit has no equivalent — the input sets no accessibility label at all |
| aria_label_send_button | "Send" | Accessible label for send button (source hardcodes the English literal on both web and AppKit; not yet keyed) |

