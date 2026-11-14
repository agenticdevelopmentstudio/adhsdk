
- **render-messages**: Component MUST render all messages in the `messages` array, with each message passed to a `MessageBubble` child component.
- **scroll-to-bottom-on-message-arrival**: When the message count changes, component MUST scroll the container to the bottom — but only when the reader is already at (or within a small threshold of) the bottom. If the reader has scrolled up to read earlier messages, new arrivals MUST NOT force the view back down.
- **scroll-to-bottom-on-typing-change**: Component MUST scroll the container to the bottom whenever `isTyping` changes, in either direction, subject to the same near-bottom condition as **scroll-to-bottom-on-message-arrival**.
- **render-typing-indicator**: Component MUST render a `TypingIndicator` child component when `isTyping` is `true`, unless suppressed by the `suppressTypingIndicator` prop.
- **keyboard-focusable**: Component container MUST be keyboard-focusable to enable arrow-key scrolling when no visible scrollbar affordance is present.
- **announce-as-region**: Component container MUST be exposed to assistive technology as a named landmark region with a non-empty accessible name, so screen reader users can navigate directly to the scrollback area.
- **accessible-label**: Component MUST accept an optional `label` prop that sets the container's accessible name; if omitted, MUST default to `"Conversation transcript"`.
- **message-selection**: Component MUST pass an `isSelected` flag to each `MessageBubble` based on whether the message's index matches the optional `selectedIndex` prop.
- **click-callback-passthrough**: Component MUST pass the `onMessageClick` callback to `MessageBubble` if provided; if not provided, `MessageBubble` MUST receive no click callback.
- **popover-rendering**: Component MUST render the result of `renderPopover(message)` immediately after the corresponding `MessageBubble` if both `renderPopover` and `message.popover` are truthy.
- **detail-arrows**: When `showDetailArrows` is `true`, component MUST show the detail arrow on a `MessageBubble` only when that message's `popover` is truthy (no arrow otherwise, and never when `showDetailArrows` is `false`). If `onDetailArrowClick` is provided, it MUST be passed through to every `MessageBubble` regardless of whether that message has a `popover`.
- **thinking-props-passthrough**: Component MUST forward `thinkingLabels`, `thinkingFrames`, `thinkingDoneGlyph`, `thinkingColorful`, and `thinkingTint` to the `TypingIndicator` child unchanged. `TypingIndicator` owns the resulting behavior (default dot pattern, default animation, default settled glyph, colorful flashing, tint targeting) — see [adhsdk.ingredient.agentic-developer-hub-sdk.sdk.sources-ui.typing-indicator](cookbook:7d2b41f0-63aa-47d1-94f8-19a06caedc6a).
- **fade-older**: Component SHOULD apply a fade gradient/mask via the `pc-transcript--fade` class when `fadeOlder` is `true`.
- **fade-anchor-viewport**: When the fade is applied, it MUST anchor to the viewport bottom: the newest (lowest) message stays fully opaque while older messages become increasingly transparent as they rise toward the top of the visible area.
- **fade-restores-on-scroll**: Scrolling any message back into the readable (bottom) zone MUST restore that message to full opacity.
- **custom-class**: Component MUST append the `className` prop to the container's class list if provided, allowing external style overrides.
- **message-identity-stability**: Component MUST preserve each message's view identity across re-renders, keyed by `message.id` (on Web, React's `key` prop — see Platform Notes).

