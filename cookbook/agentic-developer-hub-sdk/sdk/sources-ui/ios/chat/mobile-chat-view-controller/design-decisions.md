
**Decision**: Delay focusing the input field by ~350ms after the surface becomes visible, rather than focusing immediately.
**Rationale**: Focusing immediately (e.g., in `viewDidLoad`) is too early — the keyboard animation doesn't reliably appear before the view hierarchy has settled. A 350ms delay lets the hierarchy settle first; this mirrors web chat surfaces that focus on mount with the same delay.
**Approved**: pending

**Decision**: Render the thinking/typing indicator in its own `statusRow` above the composer, outside the scrolling transcript.
**Rationale**: This keeps the status line visible above the keyboard on mobile, where the transcript commonly scrolls out of view. Web mirrors this with `.pc-typing` as a sibling of `.pc-transcript`, not a child.
**Approved**: pending

**Decision**: Auto-scroll to new content only when the user's scroll position is within 40pt of the bottom.
**Rationale**: This accommodates accidental small scrolls or swipes while still respecting an intentional read of history. A stricter threshold (1-2pt) would re-center on nearly every new message; a looser one (100pt+) would miss intentional history reads.
**Approved**: pending

**Decision**: Filter active drafts with empty (zero-length) text out of the transcript.
**Rationale**: A user typing and then clearing the field shouldn't create visual noise. Once the draft text becomes non-empty, it appears immediately in the transcript (live drafting).
**Approved**: pending

**Decision**: Make the send button touch-only, with no keyboard shortcut beyond the Return key in the input field.
**Rationale**: The source provides no modifier-key path (e.g., Cmd+Return on macOS, Ctrl+Return on web); adding one is deferred to a follow-up rather than invented here.
**Approved**: pending

**Decision**: Delegate individual message rendering, styling, and delivery-status display to `MobileMessageBubbleView` (iOS) and the `Transcript` component (web).
**Rationale**: Mobile Chat concerns itself only with layout, scrolling, and session-state updates, not message presentation.
**Approved**: pending

**Decision**: Ship without command-activity pills (`ToolCallPillView`) on mobile; only the thinking indicator appears in the status row.
**Rationale**: Deferring pills lets Mobile Chat ship without full feature parity with the desktop surface — a customer who wants them can file that as a follow-up rather than blocking on a half-parity port.
**Approved**: pending

**Decision**: Submit messages with an empty `attachments` array; no attachment picker or preview UI exists yet.
**Rationale**: The source calls `submitMessage(text:attachments:)` with `attachments: []`. A future revision can add an attachment picker once one is built, rather than this recipe documenting UI that doesn't exist.
**Approved**: pending

