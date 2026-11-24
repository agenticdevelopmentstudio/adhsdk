
- **Empty message array**: When the session has no messages and no active drafts, the transcript is empty but renders without error. The status line still shows thinking/typing indicators if remote participants have them.
- **Null or missing localParticipantID**: If `localParticipantID` does not match any message sender, all messages align to the left (treated as remote).
- **Concurrent message and status updates**: If a message arrives simultaneously with a typing status change, both the transcript rebuild and status refresh occur without visual flicker or dropped updates.
- **Keyboard interruption (iOS)**: If the input field loses focus (for example, the host dismisses the keyboard, or the user taps outside the field), the field itself remains mounted; tapping it re-presents the keyboard. This source does not configure `UIScrollView.keyboardDismissMode`, so no swipe-to-dismiss gesture is enabled by default.
- **Scrolling while new messages arrive**: Auto-scroll is suppressed once the distance from the bottom reaches or exceeds the 40pt threshold (see **auto-scroll-on-new-content**); scroll direction or velocity does not affect the check, only the distance at the moment a new message arrives.
- **Very long messages**: Message bubble width is capped at 75% of the transcript container width, or 200pt (iOS) / 200px (web) minimum, whichever is larger. Text wrapping is delegated to the bubble view.
- **Rapid-fire message sends**: If the user sends multiple messages in quick succession, each message is submitted independently; no debouncing occurs.
- **Theme change while open**: Surface responds to theme changes and reapplies colors immediately (see **theme-color-reapplication**).
- **Screen rotation (iOS) or window resize (web)**: Transcript is rebuilt to recalculate max bubble width; scroll position is preserved if scroll is not at bottom; otherwise scrolls to bottom with new messages.

