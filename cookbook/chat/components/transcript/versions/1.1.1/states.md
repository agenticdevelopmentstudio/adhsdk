
| State | Appearance change |
|-------|------------------|
| Default (messages, no typing) | All messages visible at full opacity; no typing indicator; scrolled to bottom. |
| Typing | All messages visible; TypingIndicator rendered below messages; scrolled to bottom. |
| Typing suppressed | Messages visible; no typing indicator even though `isTyping` is true (via `suppressTypingIndicator` prop). |
| Message selected | Corresponding MessageBubble receives `isSelected={true}` and applies its selected-state styling. |
| Fade mode active | Older messages progressively fade toward top; bottom messages remain opaque; fade is viewport-anchored, not message-relative. |
| Empty messages array | Container renders with no child bubbles; typing indicator may still be visible if `isTyping` is true. |

