
- **Missing transport configuration**: Calling `useChatSession` with neither
  `backend` nor `orchestrator` throws synchronously during construction
  (**session-requires-backend-or-orchestrator**).
- **Empty/whitespace-only outgoing message**: `sendMessage('')` and
  `sendMessage('   ')` are both silently ignored — no orchestrator call, no
  message added (**session-send-message**).
- **Backend rejection**: A legacy backend's `sendMessage` rejecting does not
  propagate as an unhandled rejection or leave the transcript without a
  reply; it surfaces as a normal persona message carrying the fixed apology
  text (**session-backend-error-apology**).
- **Silent submit failure on the modern path**: `useChatSession`'s own
  `sendMessage` swallows any rejection from `orchestrator.submitMessage`
  with no caller-visible signal beyond whatever the orchestrator itself
  projects — a caller has no way to distinguish "sent" from "silently
  failed to submit" from the hook's return value alone
  (**session-send-message**).
- **Unmounting mid-`say`/`sayStream`**: Every pending line is landed, not
  abandoned, on teardown, delivering its final `messageReceived` event
  either way. For `say`, an `await`ing caller's promise also resolves after
  the component is gone. For `sayStream`, landing does not itself resolve
  the caller's promise — that promise settles only when the underlying
  `for await` loop over the caller's chunk generator next wakes, so a
  `sayStream` call stalled on a generator that never yields or completes
  can still hang after unmount despite the line having landed
  (**session-say-landing-on-teardown**).
- **Concurrent in-flight lines at teardown**: The pending set is iterated
  over a snapshot copy so multiple simultaneous `say`/`sayStream` calls are
  each landed exactly once, even though landing one can itself trigger
  further state updates (**session-say-landing-on-teardown**).
- **React Strict Mode double-mount**: Both `useChatSession`'s
  session-identity guard and `useConnectRitual`'s re-armed `alive` flag are
  specifically built to survive a mount→cleanup→mount cycle without
  resetting the conversation or re-running the connection ritual twice
  (**session-identity-stability**, **ritual-strict-mode-safety**).
- **No DOM match for a caret/focus selector**: `useCaretTracker`,
  `useBlockCursor`, and `useInputFocusReclaim` all install nothing and
  quietly report an inert state (`null`/no focus claim) when their selector
  matches no element, rather than throwing (**caret-tracker-no-match**).
- **Overflowing input text**: `caretMetrics`'s clamped `x` keeps the caret
  box inside the input's visible rect even when the mirrored text is far
  wider than the input, rather than reporting a caret position outside the
  element (**caret-metrics-clamping**).
- **Unmounted `element-offset` anchor**: `useChatSizing`'s `element-offset`
  cap degrades to "no subtraction" rather than computing against a
  zero/undefined rect when the anchor ref isn't mounted yet
  (**sizing-element-offset-fallback**).
- **Drag-select in progress**: `useInputFocusReclaim` deliberately does not
  reclaim focus while the window has an active text selection, so a
  click-and-drag selection isn't interrupted mid-gesture
  (**focus-reclaim-selection-guard**).
- **Click outside the chat**: Both `useInputFocusReclaim` (outside
  `pointerup`) and `useChatSizing` (outside `pointerdown` while
  `inactive` is configured) deliberately let the chat blur/collapse rather
  than fighting the user's click (**focus-reclaim-outside-click-guard**,
  **sizing-engagement-tracking**).
- **Document without focus**: `useInputFocusReclaim` never calls `.focus()`
  while `document.hasFocus()` is `false`, and `useConnectRitual`'s
  pointer-mode engagement similarly requires document focus before a
  pointer move can engage it (**focus-reclaim-guards**,
  **ritual-engage-on-pointer**).
- **Give-up timeout racing a real user gesture**: In pointer mode, whichever
  of "a qualifying pointer move" or "`giveUpAfterMs` elapses" happens first
  determines whether engagement is recorded as user-initiated
  (**ritual-engage-on-pointer**).
- **No stall lines configured**: The ritual's status line holds on the last
  wait line forever, rather than looping an empty array (division by zero)
  or going blank (**ritual-status-last-wait-line-hold**).
- **Stale hold timer superseded by a new utterance**: `useTransientEcho`
  cancels an in-flight hold timer when a new `id` arrives, so a slow-clearing
  stale timer cannot null out a newer echo early
  (**transient-echo-replaces-pending-hold**).
- **Empty rotating-phrase pool**: `useRotatingPhrase([], key)` returns `''`
  rather than throwing on an out-of-range array index
  (**rotating-phrase-empty-pool**).
- **Reader scrolled away from the bottom**: `useScrollToBottom` never
  fights a reader who has intentionally scrolled up, for either a DOM
  mutation or a `deps` change (**scroll-preserves-reader-position**).
- **Concurrent/overlapping timers**: `useConnectRitual`'s status-stepping
  interval and its `begin()` sequence's own delays run independently and
  are both cleared together on unmount; `usePersonaMood`'s rotation
  interval and its answer-beat timer are likewise independent and both
  cleared on unmount (**ritual-teardown**, **mood-beat-timer-teardown**).
- **Unreachable/never-resolving backend**: None of these hooks impose a
  timeout on `orchestrator.submitMessage`, `say`, or `sayStream` — an
  outgoing request that never settles simply leaves `isTyping`/the draft
  bubble open indefinitely; this is a direct consequence of
  **session-send-message**'s swallow-and-forget behavior, not a separate
  mechanism, so it is not treated as its own defect.

