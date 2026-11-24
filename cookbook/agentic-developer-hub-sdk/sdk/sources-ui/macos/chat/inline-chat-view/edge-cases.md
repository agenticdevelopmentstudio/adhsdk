
- **Empty messages list**: Component renders transcript container with no bubbles; only typing indicator and input visible.
- **Very long messages**: Bubbles respect max width (75% or 200pt floor) and wrap or truncate per `MessageBubbleView` behavior.
- **Rapid message arrivals**: Multiple messages added in a single update render in one transcript rebuild rather than one per message, auto-scrolling once to the final bottom (Apple: see Platform Notes).
- **Concurrent local and remote typing**: Thinking indicator prioritizes remote participant statuses (sorted by ID); if none has an explicit status, it falls back to whether any remote participant is typing. The local user's own typing never shows the indicator (see the **Status prioritizes remote statuses over typing flag** design decision).
- **Draft with no text**: Drafts with empty text are filtered out and not rendered (Apple: see Platform Notes for the exact filter).
- **Window resize during engagement**: A transcript width change triggers a rebuild on the next layout pass; repeated layouts at the same width do not trigger redundant rebuilds (Apple: see Platform Notes).
- **Click outside while composing**: Escape disengages immediately; a click outside the view disengages only while already engaged and only if the click lands outside the view's bounds (Apple).
- **Text scale nudge without handler**: If `onTextScaleNudge` is nil, shortcuts are passed to parent responder chain (Apple).
- **Backdrop added/removed**: Old backdrop unsubscribed from animation, constraints removed; new backdrop positioned and optionally animated.
- **Missing viewport measurements**: On Apple, a height cap computed before the view has been laid out (bounds height still zero) resolves to zero rather than a negative value; web sizing is deferred until layout.
- **Focus moving to transcript**: On Apple, focus moving into the scrollable transcript does not disengage the component — it stays engaged while the user is reading.
- **Status presence toggling**: A status changing from none to an active `ChatStatus` (or vice versa) updates only the status line, not a full transcript rebuild (performance optimization).

