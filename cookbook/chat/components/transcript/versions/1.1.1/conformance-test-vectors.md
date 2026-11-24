
| ID | Requirements | Input | Expected |
|----|----|----|----|
| transcript-001 | render-messages | `messages=[{id: "1", ...}, {id: "2", ...}]` | Both messages render as MessageBubble children in order. |
| transcript-002 | scroll-to-bottom-on-message-arrival | Reader is at the bottom. Initial render with 3 messages, then append a 4th message. | Scroll position moves to bottom; new message is in view. |
| transcript-003 | scroll-to-bottom-on-typing-change | Reader is at the bottom. 5 messages rendered, `isTyping` changes from `false` to `true`. | Scroll position moves to bottom; TypingIndicator becomes visible. |
| transcript-004 | render-typing-indicator | `isTyping={true}`, `suppressTypingIndicator={false}` | TypingIndicator is rendered in the DOM. |
| transcript-005 | render-typing-indicator | `isTyping={true}`, `suppressTypingIndicator={true}` | TypingIndicator is not rendered in the DOM. |
| transcript-006 | keyboard-focusable | User presses Tab to navigate; transcript container is in tab order. | Container receives keyboard focus. |
| transcript-007 | announce-as-region | Container renders; screen reader reads the DOM. | Screen reader announces a region landmark with the accessible-name text. |
| transcript-008 | accessible-label | `label` prop not provided. | Default label "Conversation transcript" is set as the accessible name. |
| transcript-009 | accessible-label | `label="Chat history"` | Accessible name is set to "Chat history". |
| transcript-010 | message-selection | `selectedIndex={1}`, messages array has 3 items. | MessageBubble at index 1 receives `isSelected={true}`; others receive `isSelected={false}`. |
| transcript-011 | click-callback-passthrough | `onMessageClick={callback}` provided. | Click events on MessageBubbles are passed to the callback with the message index. |
| transcript-012 | click-callback-passthrough | `onMessageClick` not provided. | MessageBubble receives no click callback; clicks have no effect. |
| transcript-013 | popover-rendering | Message has `popover` truthy and `renderPopover` provided. | Popover is rendered immediately after the MessageBubble. |
| transcript-014 | popover-rendering | Message has `popover` falsy or `renderPopover` not provided. | No popover is rendered. |
| transcript-015 | detail-arrows | `showDetailArrows={true}`, message has `popover` truthy. | MessageBubble receives `showDetailArrow={true}` and detail arrow is visible. |
| transcript-016 | detail-arrows | `showDetailArrows={false}` or message has no `popover`; `onDetailArrowClick` provided. | MessageBubble receives `showDetailArrow={false}` (arrow not shown); the `onDetailArrowClick` callback is still passed through, it is simply never triggered. |
| transcript-017 | thinking-props-passthrough | `thinkingLabels` array provided. | TypingIndicator receives the labels and renders them instead of default dots. |
| transcript-018 | thinking-props-passthrough | `thinkingFrames` array provided. | TypingIndicator receives the frames and cycles through them for animation. |
| transcript-019 | thinking-props-passthrough | `thinkingDoneGlyph` string provided. | TypingIndicator uses the glyph when `isTyping` becomes false. |
| transcript-020 | thinking-props-passthrough | `thinkingColorful={true}` and `isTyping={true}` | TypingIndicator flashes non-green colors during thinking. |
| transcript-021 | thinking-props-passthrough | `thinkingTint` object provided. | TypingIndicator applies tint to the specified elements (glyph, words, or both). |
| transcript-022 | fade-older | `fadeOlder={true}`, messages visible in viewport. | Fade is applied: the oldest visible message is more transparent than the newest (on Web, signaled by the `pc-transcript--fade` class — see Platform Notes). |
| transcript-023 | fade-older | `fadeOlder={false}` | No fade is applied; all messages render at full opacity (on Web, the `pc-transcript--fade` class is absent). |
| transcript-024 | custom-class | `className="custom-class"` | The container includes `custom-class` in its class list. |
| transcript-025 | message-identity-stability | Messages re-render with same IDs. | Each message retains its view identity across the re-render (no unnecessary remount); on Web this is React's `key={message.id}` (see Platform Notes). |
| transcript-026 | scroll-to-bottom-on-message-arrival | Reader has scrolled up away from the bottom (outside the near-bottom threshold); a new message arrives. | Scroll position remains where the reader left it; the view does not jump to the new message. |
| transcript-027 | fade-anchor-viewport | `fadeOlder={true}`; multiple messages; reader scrolls so an older message sits near the top of the viewport. | The older message near the top is more transparent than the newest message at the bottom; opacity tracks position in the viewport, not position in the message stack. |
| transcript-028 | fade-restores-on-scroll | `fadeOlder={true}`; a faded (older) message is scrolled down into the bottom of the viewport. | That message's opacity returns to fully opaque once it is within the readable (bottom) zone. |
| transcript-029 | message-selection | `selectedIndex={-5}` (out of range, negative), messages array has 3 items. | No message receives `isSelected={true}`; component does not error. |

