
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mobile-chat-001 | render-transcript | Session with 5 messages | All 5 messages appear in transcript in chronological order. |
| mobile-chat-002 | render-active-drafts | Session with 1 draft with text="hello" | Draft appears in transcript styled identically to committed messages. |
| mobile-chat-003 | render-active-drafts | Session with 1 draft with text="" (empty) | Draft is not rendered. |
| mobile-chat-004 | align-messages-by-sender | Message from localParticipantID | Message bubble aligns to right with spacer on left. |
| mobile-chat-005 | align-messages-by-sender | Message from remote participant | Message bubble aligns to left. |
| mobile-chat-006 | auto-scroll-on-new-content | Transcript at bottom; new message arrives | Scroll automatically moves to bottom to show new message. |
| mobile-chat-007 | auto-scroll-on-new-content | Transcript scrolled up so distance from bottom is 39pt; new message arrives | Scroll auto-scrolls to bottom (39pt is within the 40pt threshold). |
| mobile-chat-008 | auto-scroll-on-new-content | Transcript scrolled up so distance from bottom is 41pt; new message arrives | Scroll remains where the user positioned it (41pt is beyond the 40pt threshold). |
| mobile-chat-009 | focus-input-on-open | Surface becomes visible | Input field receives focus after ~350ms; native keyboard is presented (tappable). |
| mobile-chat-010 | display-thinking-indicator | Remote participant has active status (not nil) | Status line shows the remote participant's status text/animation. |
| mobile-chat-011 | display-thinking-indicator | No remote status; typing indicators exist | Status line shows default pulsing dots. |
| mobile-chat-012 | display-thinking-indicator | No remote status; no typing indicators | Status line is hidden or shows nothing. |
| mobile-chat-013 | validate-message-before-send | User enters "   " (whitespace only); taps send | Message is not sent; input field is not cleared. |
| mobile-chat-014 | validate-message-before-send | User enters "" (empty); taps send | Message is not sent. |
| mobile-chat-015 | validate-message-before-send | User enters "hello"; taps send | Message is sent and input field is cleared. |
| mobile-chat-016 | clear-input-after-send | Input field has text "hello"; user sends | Input field text becomes empty. |
| mobile-chat-017 | send-on-return-key | Input field focused with text "hello"; user presses Return | Message is sent; input field is cleared. |
| mobile-chat-018 | validate-message-before-send, send-on-return-key | Input field focused with text "   " (whitespace only); user presses Return | Message is not sent; input field retains its text. |
| mobile-chat-019 | send-on-button-tap | Input field has text "hello"; user taps send button | Message is sent; input field is cleared. |
| mobile-chat-020 | support-close-button | User activates the close affordance | `onClose` callback is invoked (web); on iOS, the host calls `close(animated:)`. |
| mobile-chat-021 | custom-close-label | closeLabel prop set to "dismiss" (web) | Close button displays "dismiss" text. |
| mobile-chat-022 | theme-color-reapplication | Surface open; active theme changes | Chat surface background and divider colors update immediately, without requiring the surface to close and reopen. |
| mobile-chat-023 | send-on-button-tap | User taps send with "first", then immediately taps send again with "second" | Both messages are submitted independently; the second send does not wait for the first, and no debouncing occurs. |
| mobile-chat-024 | render-transcript | Scroll view width changes (rotation/resize) while scrolled away from the bottom | Transcript rebuilds with a recalculated max bubble width; scroll position is preserved since the surface was not at the bottom. |

