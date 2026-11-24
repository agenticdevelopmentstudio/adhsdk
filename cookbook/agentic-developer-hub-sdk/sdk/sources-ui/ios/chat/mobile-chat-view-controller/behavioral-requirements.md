
- **render-transcript**: Component MUST render all messages from the chat session's message array in a scrolling transcript, ordered chronologically from oldest to newest.
- **render-active-drafts**: Component MUST render non-empty active drafts from the session's `activeDrafts` array inline within the transcript, styled identically to committed messages.
- **align-messages-by-sender**: Component MUST align messages from the local participant to the right side of the screen and messages from remote participants to the left side.
- **auto-scroll-on-new-content**: Component MUST scroll the transcript to the bottom when new messages or drafts arrive, provided the user's scroll position is less than 40pt from the bottom at the moment of arrival; a scroll position at or beyond that 40pt threshold suppresses auto-scroll so the user can keep reading history.
- **focus-input-on-open**: Component MUST focus the text input field after ~350ms once the component becomes visible on screen, to trigger the native keyboard presentation.
- **display-thinking-indicator**: Component MUST display a status line above the composer showing the current status of all remote participants; when no remote status exists but typing indicators are present, the component MUST display a default thinking animation (three pulsing dots).
- **validate-message-before-send**: Component MUST reject (not send) any message input that contains only whitespace or is empty.
- **clear-input-after-send**: Component MUST clear the text input field immediately after the user successfully sends a message.
- **send-on-return-key**: Component MUST submit the current input message when the user presses the Return key while focused on the text input.
- **send-on-button-tap**: Component MUST submit the current input message when the user taps the send button.
- **theme-color-reapplication**: Component MUST reflect the active theme's chat surface and divider colors, reapplying them whenever the theme changes while the surface is visible — not only once, at the moment it opens.
- **support-close-button**: Component MUST provide a close affordance that triggers the `onClose` callback when activated. Web renders this as a button in the surface's own header; iOS delegates the affordance to the presenting host, which calls `close(animated:)` (see Platform Notes).
- **custom-close-label**: Component SHOULD allow the host to customize the text label of the close affordance via a `closeLabel` prop (default: "← back"). This applies where the component owns the affordance — web's header button; iOS has no equivalent affordance in this source.

