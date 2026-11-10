
**Session construction and identity (`useChatSession`)**

- **session-requires-backend-or-orchestrator**: `useChatSession` MUST throw
  `Error('useChatSession needs either a backend or an orchestrator.')` when
  neither an `orchestrator` nor a `backend` option is supplied.
- **session-orchestrator-adoption**: When an `orchestrator` option is given,
  the hook MUST adopt it as-is (`owned: false`), MUST NOT call `start()` on
  it, and MUST ignore any `welcomeMessage` option.
- **session-orchestrator-teardown-noop**: An adopted session's
  `destroyBackend()` MUST be a no-op, since the orchestrator is not the
  hook's to close.
- **session-backend-adaptation**: When a `backend` option is given and it
  does not implement `inboundEvents` (`isContractBackend` returns `false`),
  the hook MUST wrap it in a `ChatBackendAdapter` configured with the persona
  ID and a `history` callback that returns the current projection
  (`() => project()`).
- **session-orchestrator-construction**: When built from a `backend`, the
  hook MUST construct a `DefaultOrchestrator` with a fresh
  `crypto.randomUUID()` conversation ID, `localParticipantID: 'local'`, the
  initial participants, empty `commands`/`observingHooks`/`gatingHooks`
  lists, a fresh `InMemoryPermissionStore`, the (possibly adapted) backend,
  and a display config of `{showAvatars:true, showReadReceipts:false,
  showTypingIndicators:true, allowJoining:false, allowDeparting:false,
  reducedMotion:false}`.
- **session-default-participants**: Absent explicit participants, the
  session MUST default the user participant to `{name:'You', avatar:'Y'}`
  and the persona ID to `'persona'`.
- **session-welcome-message**: When `welcomeMessage` is supplied on a
  backend-built session, the hook MUST deliver one `messageReceived` inbound
  event from the persona ID BEFORE `start()` is ever called.
- **session-identity-stability**: The hook MUST construct its internal
  session object exactly once per mount (guarded by `sessionRef.current ===
  null`) and MUST NOT rebuild it when `backend`/`orchestrator`/etc. identity
  changes across renders, so an inline backend/orchestrator literal passed
  at each render does not reset the conversation.
- **session-subscription**: On mount, the hook MUST subscribe an observer
  (`chatDidUpdate`) to the orchestrator that triggers a re-render, and MUST
  call `orchestrator.start()` only when the session is `owned`.
- **session-teardown**: On unmount, the hook MUST remove its observer and
  MUST call `session.destroyBackend()`, which for an owned, adapter-wrapped
  session MUST call `destroy()` on the wrapped backend (the adapter itself),
  never directly on the raw backend, so the adapter's own teardown (its
  `AbortController` and event queue) runs.
- **session-draft-stamp-eviction**: Before each projection, the hook MUST
  evict any cached `draft:`-prefixed timestamp whose draft no longer exists
  among the orchestrator's active drafts.
- **session-messages-projection**: The hook MUST expose `messages` as a
  memoized projection (`session.project()`), recomputed only when the
  session or its internal version counter changes.
- **session-is-typing-derivation**: `isTyping` MUST be `false` whenever there
  are active drafts; otherwise it MUST be `true` iff the most recently
  projected message's sender is the local participant.
- **session-send-message**: `sendMessage(text)` MUST trim the input and, if
  the trimmed result is empty, MUST NOT call the orchestrator at all;
  otherwise it MUST call `orchestrator.submitMessage(trimmed, [])` and MUST
  swallow any rejection from that call.
- **session-say**: `say(text)` MUST reveal `text` incrementally via
  `draftUpdated` events, one growing slice per simulated keystroke with a
  randomized `26–54ms` delay between slices, and MUST conclude with exactly
  one `messageReceived` event carrying the full, untruncated `text`.
- **session-say-landing-on-teardown**: Every in-flight `say`/`sayStream` call
  MUST be tracked in a pending set, and on unmount the hook MUST "land" (not
  abandon) each one — delivering its final `messageReceived` event — even
  though the component driving it has already unmounted. For `say`, landing
  also resolves the call's returned promise. For `sayStream`, landing only
  delivers the `messageReceived` event; the call's returned promise is the
  `for await` loop over the caller's chunk generator, and it settles only
  when that loop next wakes (a new yielded chunk, or the generator ending)
  and observes that the line already landed — so a `sayStream` call stalled
  on a generator that never yields or completes leaves its promise
  unsettled after unmount.
- **session-say-stream**: `sayStream(chunks)` MUST accumulate text across
  yielded chunks, deliver a `draftUpdated` event after each chunk (skipping
  it if already landed), and MUST deliver exactly one final
  `messageReceived` event with whatever text has accumulated, guarded
  against double-landing.
- **session-select-message**: `selectMessage(index)` MUST update the
  selected index only when `index` is within `[-1, messages.length)`; the
  initial selection MUST be `-1`.
- **session-return-shape**: The hook MUST return a memoized object of
  exactly `{messages, isTyping, sendMessage, say, sayStream, selectedIndex,
  selectMessage}`.
- **session-backend-error-apology**: When a wrapped legacy backend's
  `sendMessage` rejects, the resulting persona message MUST surface the
  fixed text "Sorry, something went wrong. Let's try again." (sourced from
  `ChatBackendAdapter`, observed through `useChatSession`'s own contract and
  test suite).

**Connection ritual (`useConnectRitual`)**

- **ritual-required-config**: `ConnectRitualConfig` MUST require `say`,
  `welcome`, `greeting`, and `connectingLine`/`connectedLine`; `waitLines`
  and `stallLines` MUST default to `[]`.
- **ritual-defaults**: Absent overrides, the hook MUST use
  `engageOn:'pointer'`, `readyAfterMs:2000`, `giveUpAfterMs:30000`,
  `greetDelayMs:800`, `waitStepMs:900`, `stallStepMs:1600`.
- **ritual-initial-state**: The hook MUST start with `inputDisabled:true`,
  `connected:false`, `engaged:false`, `engagedByUser:false`.
- **ritual-status-stepping**: While not yet engaged and any wait/stall lines
  exist, the hook MUST advance the displayed status line every `waitStepMs`
  through `waitLines`, then every `stallStepMs` cycling through
  `stallLines`.
- **ritual-status-last-wait-line-hold**: When `stallLines` is empty, the
  status line MUST hold on the last wait line indefinitely once `waitLines`
  is exhausted, rather than becoming `undefined`/`NaN`.
- **ritual-status-priority**: The displayed status line MUST be
  `connectedLine` once connected, else `connectingLine` once engaged, else
  the current wait/stall line (or `null` if there are none).
- **ritual-begin-idempotent**: The ritual's begin sequence MUST run at most
  once per session (an internal `started` guard), engaging, speaking
  `welcome`, marking connected, waiting `greetDelayMs`, speaking `greeting`,
  then enabling input — in that order, with a liveness check between each
  step.
- **ritual-strict-mode-safety**: The ritual MUST re-arm an `alive` flag at
  the start of every effect run (including a React Strict Mode remount) and
  MUST check `alive` before each step of the begin sequence, so a torn-down
  instance never resumes speaking after unmount, while a genuine remount
  still runs the ritual once, to completion.
- **ritual-engage-on-mount**: When `engageOn:'mount'`, the hook MUST begin
  the ritual immediately, not user-initiated (`engagedByUser` stays
  `false`), ignoring `readyAfterMs`/`giveUpAfterMs`.
- **ritual-engage-on-element**: When `engageOn` is a ref, the hook MUST begin
  the ritual (user-initiated) on `pointerdown` or `focusin` on that element,
  and MUST NOT apply `readyAfterMs` pointer-tracking or `giveUpAfterMs`.
- **ritual-engage-on-pointer**: In the default pointer mode, the hook MUST
  NOT engage from a pointer move before `readyAfterMs` has elapsed or before
  the document has focus, MUST engage (user-initiated) on the first
  qualifying pointer move afterward, and MUST engage automatically (not
  user-initiated) if `giveUpAfterMs` elapses first.
- **ritual-teardown**: On unmount, the hook MUST mark itself no longer
  alive, clear any pending step timer, and remove any listeners it
  installed.

**Adaptive sizing (`useChatSizing`)**

- **sizing-defaults**: Absent a `sizing` option, the hook MUST behave as
  `{active:{mode:'fixed'}}`.
- **sizing-engagement-tracking**: The hook MUST track focus/pointer/Escape
  engagement only when an `inactive` behavior is configured, treating the
  element as engaged on `focusin` inside the root, disengaged on
  `pointerdown` outside the root, and disengaged on `Escape`.
- **sizing-behavior-selection**: The active behavior MUST be `active` while
  engaged (or when `inactive` is not configured), else `inactive`.
- **sizing-content-hugging-cap**: For `mode:'content-hugging'`, the hook
  MUST compute a `maxHeight` cap from the chat element's bottom offset and
  the configured `cap` (`css` length, `viewport-offset`, or
  `element-offset`), clamping the result to be non-negative.
- **sizing-css-length-units**: A `css` cap MUST support plain pixel numbers
  and `vh` values (resolved against `window.innerHeight`); an unparseable
  value MUST resolve to `0`.
- **sizing-element-offset-fallback**: An `element-offset` cap whose ref is
  not yet mounted MUST fall back to the chat element's own bottom (no
  subtraction), rather than throwing or omitting a cap.
- **sizing-minimal-no-cap**: For `mode:'minimal'`, the hook MUST NOT compute
  or apply a height cap.
- **sizing-hugging-classes**: For `content-hugging` or `minimal` modes, the
  hook MUST add a `pc-hugging` class to both the element and its parent, and
  MUST remove both on cleanup.
- **sizing-observers**: The hook MUST recompute the cap in response to a
  `ResizeObserver` on the chat element (and on the offset anchor, for
  `element-offset`), plus `window` resize/scroll and `visualViewport`
  resize/scroll.
- **sizing-transition-class**: A `pc-anim` class MUST be applied only when
  `transition:'animated'` (the default) and engagement tracking is active;
  `transition:'none'` MUST omit it.
- **sizing-collapsed-class**: A `pc-collapsed` class MUST be applied
  whenever the active mode is `minimal`.
- **sizing-return-shape**: The hook MUST return `{ref, style, engaged,
  collapsed, className}`, where `style` carries `maxHeight` only for a
  hugging mode with a computed cap, and is otherwise `{}`.

**Scroll anchoring (`useScrollToBottom`)**

- **scroll-bottom-threshold**: The hook MUST consider the container "at
  bottom" when `scrollHeight - scrollTop - clientHeight < 30`, recomputed on
  every native `scroll` event.
- **scroll-mutation-follow**: A `MutationObserver`
  (`childList`/`subtree`/`characterData`) MUST trigger the container to
  auto-scroll to its new bottom, but only if the reader was at the bottom at
  the time of the mutation.
- **scroll-follow-coalesced**: An auto-scroll MUST be scheduled at most once
  per animation frame (a `queued` guard), and MUST re-check "at bottom"
  immediately before writing `scrollTop`, since the reader may have scrolled
  away in the interim.
- **scroll-deps-follow**: On a change to the caller-supplied `deps` array,
  the hook MUST also schedule a same-frame scroll-to-bottom when the reader
  is at the bottom, covering renders (e.g., a streamed reply growing one
  bubble in place) that the `MutationObserver` path alone might race.
- **scroll-preserves-reader-position**: If the reader is not at the bottom,
  neither the mutation observer nor a `deps` change MUST move `scrollTop`.
- **scroll-teardown**: On unmount, the hook MUST remove its scroll listener
  and disconnect the `MutationObserver`.

**Image-load gating (`useAllImagesLoaded`)**

- **images-loaded-extraction**: The hook MUST derive its watched set from
  `content` items whose `type === 'image'`, mapped to their `src`.
- **images-loaded-key**: The hook MUST re-run its loading effect only when
  the joined (`'|'`-separated) set of image sources changes.
- **images-loaded-empty-set**: With no image items, the hook MUST report all
  images loaded (`true`) without creating any `Image` objects.
- **images-loaded-tracking**: For a non-empty set, the hook MUST reset its
  loaded map, then for each source create an `Image`, wire both `onload` and
  `onerror` to mark that source loaded, and set `img.src`.
- **images-loaded-cancellation**: A cleanup MUST prevent stale
  `onload`/`onerror` callbacks (from a superseded content set) from updating
  state after the effect re-runs or the component unmounts.
- **images-loaded-return-value**: The hook MUST return `true` iff every
  tracked source is marked loaded in state.

**Caret geometry (`caretMetrics`, `useCaretTracker`)**

- **caret-metrics-geometry**: `caretMetrics` MUST compute the caret box's
  `height` as `round(fontSize * 0.65)` and `width` as `max(2, round(fontSize
  * 0.42))`.
- **caret-metrics-index**: The caret index used for measurement MUST be
  `selectionStart` when `selectionDirection === 'backward'`, else
  `selectionEnd`, falling back to the value's length when either is null.
- **caret-metrics-mirror**: `caretMetrics` MUST measure text width via a
  temporary, visually hidden mirror `<span>` (copying font
  family/size/weight/style/letter-spacing) appended to and removed from
  `document.body` within the same call, leaving no residual node.
- **caret-metrics-clamping**: The computed `x` MUST be clamped to
  `[rect.left, rect.right - width]`, and `top` MUST vertically center the
  caret box within the input's rect.
- **caret-tracker-disabled**: `useCaretTracker` MUST emit `null` and install
  no listeners when `enabled` is `false`.
- **caret-tracker-no-match**: If no element matches `selector`, the hook
  MUST install no listeners and MUST NOT invoke `onMeasure` at all, even on
  unmount.
- **caret-tracker-focus-gate**: The hook MUST report a measurement only when
  the matched input is both `document.activeElement` and the document has
  focus; otherwise it MUST report `null`.
- **caret-tracker-triggers**: The hook MUST re-measure (coalesced to one
  `requestAnimationFrame`) on input focus/blur, `selectionchange` while the
  input is active, window scroll (capture) and resize, and `visualViewport`
  resize/scroll.
- **caret-tracker-stable-callback**: The hook MUST hold the latest
  `onMeasure` in a ref so its listeners are re-subscribed only when
  `wrapperRef`, `enabled`, or `selector` change, never on every `onMeasure`
  identity change.
- **caret-tracker-teardown**: On cleanup, the hook MUST cancel any pending
  animation frame, remove every listener it installed, and emit `null`.

**Block cursor (`useBlockCursor`)**

- **block-cursor-composition**: The hook MUST derive its measurement via
  `useCaretTracker`, updating its own caret-box state only when the new box
  differs from the previous one in `x`, `top`, `height`, or `width` (else it
  MUST keep the same object reference).
- **block-cursor-reset-remeasure**: On a `resetKey` change, the hook MUST
  re-measure only if `enabled` and the tracked input is currently focused.
- **block-cursor-hides-native-caret**: While enabled, the hook MUST set the
  input's `caretColor` to `'transparent'`, restoring it to `''` when
  disabled or on cleanup.
- **block-cursor-disabled-returns-null**: The hook MUST return `null`
  whenever `enabled` is `false`, regardless of the last measured box.

**Caret gaze (`useCaretGaze`)**

- **caret-gaze-defaults**: `downBias` MUST default to `0.9` and `selector`
  to the shared chat-input selector.
- **caret-gaze-empty-or-missing**: The hook MUST report `null` gaze whenever
  the input is missing, the anchor is missing, or the input's value is
  empty.
- **caret-gaze-unfocused**: The hook MUST report `null` gaze when the input
  is not the focused, active element, independent of the anchor/value
  checks.
- **caret-gaze-computation**: When focused with a non-empty value and an
  anchor, the hook MUST compute `x` as the horizontal offset between the
  caret and the anchor's center, normalized by half the input element's own
  width (falling back to `1` for a zero-width input) and clamped to
  `[-1, 1]`, and MUST report `y` as the fixed `downBias`.
- **caret-gaze-always-tracked**: The hook MUST track the caret with
  `useCaretTracker`'s `enabled` fixed to `true`, regardless of any
  caller-level engagement gating (that gating is the caller's
  responsibility, per `usePersonaGaze`'s composition).

**Mouse gaze (`useMouseGaze`)**

- **mouse-gaze-enabled-gate**: The hook MUST install its `pointermove`
  listener only while `enabled` is `true`, and MUST call `onGaze` only in
  that state.
- **mouse-gaze-missing-anchor**: A pointer move MUST NOT report a gaze value
  when the anchor ref has no current element.
- **mouse-gaze-computation**: The hook MUST compute `x`/`y` as the pointer's
  offset from the anchor's center, normalized by half the viewport's
  width/height respectively, each clamped to `[-1, 1]`.
- **mouse-gaze-teardown**: On cleanup (disable or unmount), the hook MUST
  remove its `pointermove` listener; a subsequent pointer move MUST NOT
  invoke `onGaze`.

**Persona gaze arbitration (`usePersonaGaze`)**

- **persona-gaze-mouse-while-disengaged**: While not engaged, the hook MUST
  forward mouse-driven gaze to the caller.
- **persona-gaze-mouse-silenced-while-engaged**: While engaged, the hook
  MUST NOT forward mouse-driven gaze, even for an identical pointer move
  that would have produced a value while disengaged.
- **persona-gaze-caret-while-engaged**: While engaged with a focused,
  non-empty input, the hook MUST forward caret-driven gaze (carrying the
  caret source's fixed `y` bias).
- **persona-gaze-caret-gated-while-disengaged**: While not engaged, the hook
  MUST NOT forward caret-driven gaze even if the input is focused and
  non-empty.
- **persona-gaze-stable-callbacks**: The mouse-source callback MUST have a
  stable identity across renders (via a ref-held `onGaze`), and the
  caret-source callback MUST be re-created only when `engaged` changes,
  never on every `onGaze` identity change.

**Persona mood (`usePersonaMood`)**

- **mood-idle-state**: With neither `responding` nor `composing`, the hook
  MUST report `{mood: null, beat: false}`.
- **mood-composing-state**: While composing only, the hook MUST report the
  current `typingMoods` entry with `beat:false`.
- **mood-responding-priority**: While both `responding` and `composing` are
  `true`, `responding` MUST take priority for mood selection.
- **mood-rotation**: While engaged (`responding || composing`), the hook
  MUST advance through the applicable mood list every `cycleMs` (default
  `1500`), wrapping via modulo, and MUST reset the rotation step to `0` and
  stop advancing once disengaged.
- **mood-answer-beat**: On a `responding` transition from `true` to `false`
  with `answerBeat` configured, the hook MUST report `{mood:
  answerBeat.mood, beat:true}` immediately, then clear to `{mood:null,
  beat:false}` after `answerBeat.ms`, regardless of whether
  `answerBeat.mood` also happens to appear in `flightMoods`.
- **mood-answer-beat-optional**: With `answerBeat` omitted, a `responding`
  transition to `false` MUST be a no-op (no beat fired, no throw).
- **mood-beat-timer-teardown**: On unmount, the hook MUST clear any pending
  beat-clear timer.

**Rotating phrase and transient echo (`useRotatingPhrase`, `useTransientEcho`)**

- **rotating-phrase-initial-value**: `useRotatingPhrase` MUST initialize its
  displayed phrase to `pool[0] ?? ''`, so server and client agree before the
  first client-only roll.
- **rotating-phrase-mount-roll**: The hook MUST perform its first random
  roll in a mount-only effect, after the initial render.
- **rotating-phrase-reroll-on-key-change**: A `rerollKey` change MUST
  re-roll the phrase to a new random pool member within the same render
  pass that observes the key change (React's "adjust state during render"
  pattern), not deferred to a subsequent effect.
- **rotating-phrase-stable-on-same-key**: Re-rendering with the same
  `rerollKey` MUST NOT change the displayed phrase.
- **rotating-phrase-empty-pool**: An empty pool MUST yield `''` rather than
  throwing or returning `undefined`.
- **transient-echo-noop-without-id**: `useTransientEcho` MUST take no action
  while `utterance?.id` is `undefined`.
- **transient-echo-shows-then-clears**: On a new `utterance.id`, the hook
  MUST display that utterance's text, then clear it (and advance
  `idleIndex`) after `holdMs` (default `1800`) with no further activity.
- **transient-echo-replaces-pending-hold**: A new `utterance.id` arriving
  before a prior hold timer fires MUST cancel that timer and start a fresh
  `holdMs` hold for the new utterance, so the stale timer cannot clear the
  new echo early.
- **transient-echo-teardown**: On unmount, the hook MUST clear any pending
  hold timer.

**Input focus reclaim (`useInputFocusReclaim`)**

- **focus-reclaim-disabled-noop**: With `enabled` `false`, the hook MUST
  install no listeners and MUST NOT claim focus.
- **focus-reclaim-immediate**: On enable, the hook MUST attempt to reclaim
  focus once immediately (subject to the same guards as any other reclaim).
- **focus-reclaim-guards**: The hook MUST NOT reclaim focus when the
  document lacks focus, when the input is disabled, or when the input is
  already the active element.
- **focus-reclaim-selection-guard**: The hook MUST NOT reclaim focus
  following a `pointerup` if the window currently has a non-empty text
  selection (a drag-select in progress).
- **focus-reclaim-outside-click-guard**: The hook MUST NOT reclaim focus
  following a `pointerup` whose target lies outside the wrapper element, so
  a click that collapses or blurs the chat is left alone.
- **focus-reclaim-deferred**: A qualifying `pointerup` inside the wrapper
  MUST reclaim focus on a deferred (`setTimeout(...,0)`) tick, not
  synchronously, so the clicked control's own handler runs first.
- **focus-reclaim-window-focus**: The hook MUST also attempt to reclaim
  focus on the window's `focus` event.
- **focus-reclaim-teardown**: On cleanup, the hook MUST remove both the
  `window` `focus` and `document` `pointerup` listeners.

