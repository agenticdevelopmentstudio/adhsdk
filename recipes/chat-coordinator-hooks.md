---
id: 259f4a99-1b18-44a2-a102-e14e0fd8e30f
title: Chat Coordinator Hooks
domain: adhsdk://recipes/chat-coordinator-hooks
type: ingredient
version: 1.0.1
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Thirteen headless React hooks for a chat surface — transport (useChatSession),
  caret/gaze tracking, mood, sizing, scroll, focus, idle phrases, image gating.
platforms:
- typescript
- web
tags:
- chat
- hooks
- react
- coordinator
depends-on:
- adhsdk://recipes/chat-coordinator-runtime
- adhsdk://recipes/chat-coordinator-backends
- adhsdk://recipes/chat-coordinator-projection
related:
- adhsdk://recipes/chat-coordinator
- adhsdk://recipes/chat-contract
references: []
approved-by: ''
approved-date: ''
---

## Overview

This recipe covers the thirteen React hooks in `@adh-sdk/chat`'s
`src/hooks/` directory: `useAllImagesLoaded`, `useBlockCursor`, `useCaretGaze`,
`useCaretTracker` (which also exports the standalone `caretMetrics` function),
`useChatSession`, `useChatSizing`, `useConnectRitual`,
`useInputFocusReclaim`, `useMouseGaze`, `usePersonaGaze`, `usePersonaMood`,
`useRotatingPhrase` (which also exports `useTransientEcho`), and
`useScrollToBottom`. It is a **logic** collection: none of these hooks render
any JSX or own any DOM node. Each one either computes a value from a
caller-supplied `RefObject`/DOM element (measuring, observing, or listening),
or manages timers and state machines that a host component reads and renders
however it likes.

`useChatSession` is the load-bearing member of the set: it adapts either a
legacy `ChatBackend` or a modern contract `Backend` into a `DefaultOrchestrator`
(or adopts a caller-owned orchestrator directly), projects the orchestrator's
view-model into the `ChatMessage[]` shape a transcript renders, and exposes
`sendMessage`/`say`/`sayStream` for driving it. The other twelve hooks are
independent, composable peripherals a chat surface typically needs alongside
that transport: a first-contact "connecting..." ritual (`useConnectRitual`),
caret-following visuals (`useCaretTracker`/`useBlockCursor`/`useCaretGaze`),
attention cues (`useMouseGaze`/`usePersonaGaze`/`usePersonaMood`), layout
(`useChatSizing`/`useScrollToBottom`), input ergonomics
(`useInputFocusReclaim`), copy variety (`useRotatingPhrase`/`useTransientEcho`),
and readiness gating (`useAllImagesLoaded`). None of them import from each
other except `useBlockCursor`, `useCaretGaze`, and `usePersonaGaze`, which are
built on top of `useCaretTracker`/`useMouseGaze`/`useCaretGaze`.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a collection of headless React hooks, not a
visual component. They render no JSX and own no DOM node; several read
geometry from (or write a handful of inline style properties/classes onto)
a caller-supplied element, but the actual appearance is entirely the host
component's.

## States

Not applicable — this is a collection of headless React hooks, not a
stateful visual component with its own state machine. The runtime state
each hook tracks (session messages/typing, ritual engagement/connection,
sizing engagement/collapse, gaze/mood values, echo/phrase selection) is
specified under Behavioral Requirements above and is exposed as plain
return values for a host component's own rendering to interpret.

## Accessibility

Not applicable — this is a collection of headless React hooks with no
rendered surface of their own, so there is nothing here for a screen reader
or other assistive technology to encounter directly. Accessibility
properties of the resulting UI (roles, labels, live regions) belong to
whatever host component consumes these hooks' return values.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| chat-coordinator-hooks-001 | session-welcome-message | `useChatSession({backend, persona, welcomeMessage:'Hello!'})` on mount | `messages.length === 1`, `messages[0].text === 'Hello!'`, `messages[0].isPersona === true` |
| chat-coordinator-hooks-002 | session-welcome-message | `useChatSession({backend, persona})` (no `welcomeMessage`) on mount | `messages.length === 0` |
| chat-coordinator-hooks-003 | session-send-message | `sendMessage('hi')` | `messages.length === 2`; `messages[0] === {text:'hi', isPersona:false}` |
| chat-coordinator-hooks-004 | session-send-message | Backend resolves `'bot says hi'` after `sendMessage('hi')` | `messages[1].text === 'bot says hi'`, `messages[1].isPersona === true` |
| chat-coordinator-hooks-005 | session-send-message | Backend resolves `{text:'Check this out', content:[{type:'link',...}], popover:{title:'Details',...}}` | `botMessage.text === 'Check this out'`, `botMessage.content.length === 1`, `botMessage.popover.title === 'Details'` |
| chat-coordinator-hooks-006 | session-backend-error-apology | Backend's `sendMessage` rejects with `Error('Network error')` | `messages.length === 2`; `messages[1].text` contains `'something went wrong'` |
| chat-coordinator-hooks-007 | session-send-message | `sendMessage('')` then `sendMessage('   ')` | `messages.length === 0`; backend's `sendMessage` never called |
| chat-coordinator-hooks-008 | session-backend-adaptation | `sendMessage('hi')` with a prior `welcomeMessage` | `backend.sendMessage`'s second argument (history) has `length >= 1` and `history[0].text === 'Welcome'` |
| chat-coordinator-hooks-009 | session-select-message | `selectMessage(0)` | `selectedIndex` goes from `-1` to `0` |
| chat-coordinator-hooks-010 | session-default-participants | `sendMessage('hi')` with no explicit user participant | `messages[0].sender.name === 'You'` |
| chat-coordinator-hooks-011 | session-teardown | `unmount()` on an owned, raw-backend session | Raw backend's `destroy()` is called |
| chat-coordinator-hooks-012 | session-teardown | `unmount()` on an owned, adapter-wrapped session | Both `ChatBackendAdapter.prototype.destroy` AND the raw backend's `destroy()` are called |
| chat-coordinator-hooks-013 | session-say-landing-on-teardown | `say('a line long enough to still be mid-word')`, advance `100ms`, then `unmount()` | Timer count is `> 0` before unmount, `=== 0` immediately after |
| chat-coordinator-hooks-014 | session-say-landing-on-teardown | Same `say(...)` call, `unmount()`, then `advanceTimersByTimeAsync(0)` | The line's promise, unsettled at `+100ms`, becomes settled after unmount |
| chat-coordinator-hooks-015 | caret-metrics-geometry | `caretMetrics(input)` with `fontSize:'20px'` | `box.height === 13`, `box.width === 8` |
| chat-coordinator-hooks-016 | caret-metrics-clamping | `caretMetrics(input)` with a very long value | `box.x` stays within `[rect.left, rect.right]` |
| chat-coordinator-hooks-017 | caret-metrics-mirror | Any `caretMetrics(input)` call | `document.body.childElementCount` is unchanged after the call returns |
| chat-coordinator-hooks-018 | caret-tracker-disabled | `useCaretTracker(ref, false, onMeasure)` | `onMeasure` is called with `null` immediately |
| chat-coordinator-hooks-019 | caret-tracker-teardown | `useCaretTracker(ref, true, onMeasure)` then `unmount()` | `onMeasure` is called with `null` on unmount |
| chat-coordinator-hooks-020 | caret-tracker-no-match | `selector` matches no element in the wrapper | `onMeasure` is never called, including on unmount |
| chat-coordinator-hooks-021 | block-cursor-disabled-returns-null | `useBlockCursor(ref, false, resetKey)` | Returns `null` |
| chat-coordinator-hooks-022 | block-cursor-hides-native-caret | `useBlockCursor(ref, true, resetKey)` then disable | `input.style.caretColor` is `'transparent'` while enabled, restored to `''` on disable |
| chat-coordinator-hooks-023 | block-cursor-composition | Focused input at `left:10` on mount | Returns `{x:10, top:18.5, height:13, width:8}` |
| chat-coordinator-hooks-024 | block-cursor-composition | `resetKey` bump with unchanged geometry | Returned box is `toBe` (same reference as) the previous box |
| chat-coordinator-hooks-025 | block-cursor-reset-remeasure | Blur the input, advance `20ms` | Returned box becomes `null` |
| chat-coordinator-hooks-026 | caret-gaze-empty-or-missing | Focused, non-empty input, no `anchorRef` | `onGaze(null)` |
| chat-coordinator-hooks-027 | caret-gaze-empty-or-missing | Focused, empty input, with anchor | `onGaze(null)` |
| chat-coordinator-hooks-028 | caret-gaze-unfocused | Unfocused input, non-empty value, with anchor | `onGaze(null)` |
| chat-coordinator-hooks-029 | caret-gaze-computation | Value `'hihihi'`, anchor `{left:100,right:150,width:50}` | `onGaze({x:-0.1, y:0.9})` |
| chat-coordinator-hooks-030 | caret-gaze-computation | Same value, anchor far to the right (`left:1000,right:1000,width:0`) | `onGaze` clamps to `{x:-1, y:0.9}` |
| chat-coordinator-hooks-031 | caret-gaze-computation | Same setup, `downBias:0.3` | `onGaze({x:-0.1, y:0.3})` |
| chat-coordinator-hooks-032 | mouse-gaze-computation | Anchor center `(200,150)`, viewport `1000×800`, pointer move to `(450,350)` | `onGaze({x:0.5, y:0.5})` |
| chat-coordinator-hooks-033 | mouse-gaze-computation | Pointer move to `(5000,-5000)` | `onGaze` clamps to `{x:1, y:-1}` |
| chat-coordinator-hooks-034 | mouse-gaze-enabled-gate | `useMouseGaze(anchorRef, false, onGaze)`, pointer move | `onGaze` never called |
| chat-coordinator-hooks-035 | persona-gaze-mouse-silenced-while-engaged | `engaged:true`, pointer move that would produce `{x:0.5,y:0.5}` if disengaged | `onGaze` is never called with `{x:0.5,y:0.5}` |
| chat-coordinator-hooks-036 | persona-gaze-caret-while-engaged | `engaged:true`, focused non-empty input, after flushing the rAF-coalesced tracker | `onGaze` called with an object containing `y:0.9` |
| chat-coordinator-hooks-037 | mood-idle-state | `responding:false, composing:false` | `{mood:null, beat:false}` |
| chat-coordinator-hooks-038 | mood-composing-state | `responding:false, composing:true` | `mood` equals the current `typingMoods` entry, `beat:false` |
| chat-coordinator-hooks-039 | mood-responding-priority | `responding:true, composing:true` | `mood` equals the current `flightMoods` entry (responding wins) |
| chat-coordinator-hooks-040 | mood-rotation | `responding:true`, advance `cycleMs` (`1000`) | Mood advances from the first `flightMoods` entry to the second |
| chat-coordinator-hooks-041 | mood-answer-beat | `flightMoods:['smug']`, `responding:true` | `beat === false` (a flight mood string-equal to `answerBeat.mood` is not itself a beat) |
| chat-coordinator-hooks-042 | mood-answer-beat | `responding` flips `true → false` with `answerBeat:{mood:'smug', ms:2000}` | Immediately `{mood:'smug', beat:true}`; after `2000ms`, `{mood:null, beat:false}` |
| chat-coordinator-hooks-043 | mood-answer-beat-optional | Same transition, `answerBeat` omitted | `{mood:null, beat:false}`, no throw |
| chat-coordinator-hooks-044 | rotating-phrase-stable-on-same-key | Re-render with the same `rerollKey` | Displayed phrase is `toBe` (same value as) before |
| chat-coordinator-hooks-045 | rotating-phrase-reroll-on-key-change | `rerollKey` changes (`Math.random` mocked `0 → 0.99` over a 3-item pool) | Phrase changes from index `0` to index `2` in the same render pass |
| chat-coordinator-hooks-046 | rotating-phrase-empty-pool | `useRotatingPhrase([], k)` | Returns `''` |
| chat-coordinator-hooks-047 | transient-echo-shows-then-clears | New `utterance.id`, `holdMs:1800` (default) | Echo text present at `+1799ms`, cleared (`null`) at `+1800ms`; `idleIndex` bumps |
| chat-coordinator-hooks-048 | transient-echo-shows-then-clears | Custom `holdMs:500` | Echo present at `+499ms`, cleared at `+500ms` |
| chat-coordinator-hooks-049 | transient-echo-replaces-pending-hold | A second `utterance.id` arrives `900ms` into a first `1800ms` hold | Echo shows the second utterance's text and does not clear until `1800ms` after the *second* utterance's own arrival |
| chat-coordinator-hooks-050 | scroll-deps-follow, scroll-mutation-follow | Reader at bottom; a draft message's text grows from `'a'` to `'a'.repeat(500)` (same message id) | `el.scrollTop === el.scrollHeight` after settling |
| chat-coordinator-hooks-051 | scroll-preserves-reader-position | Reader scrolled to `scrollTop:0`; same text growth | `el.scrollTop` remains `0` |
| chat-coordinator-hooks-052 | sizing-defaults | `useChatSizing(undefined)` | `style === {}` |
| chat-coordinator-hooks-053 | sizing-css-length-units | `cap:{kind:'css', value:'60vh'}`, `innerHeight:800` | `style.maxHeight === '480px'` |
| chat-coordinator-hooks-054 | sizing-content-hugging-cap | `cap:{kind:'viewport-offset', topOffsetPx:80}`, `chatBottom:780` | `style.maxHeight === '700px'` |
| chat-coordinator-hooks-055 | sizing-content-hugging-cap | `cap:{kind:'element-offset', gapPx:40}`, anchor `bottom:120`, `chatBottom:780` | `style.maxHeight === '620px'` |
| chat-coordinator-hooks-056 | sizing-element-offset-fallback | `cap:{kind:'element-offset'}` with a `null` anchor ref, `chatBottom:500` | `style.maxHeight === '500px'` |
| chat-coordinator-hooks-057 | sizing-content-hugging-cap | `cap:{kind:'viewport-offset', topOffsetPx:1000}`, `chatBottom:200` | `style.maxHeight === '0px'` (clamped, not negative) |
| chat-coordinator-hooks-058 | sizing-engagement-tracking, sizing-collapsed-class | `focusin` on the element (active mode `content-hugging`) | `engaged:true`, `collapsed:false`, cap applied; a subsequent `Escape` returns `engaged:false`, `collapsed:true` |
| chat-coordinator-hooks-059 | sizing-engagement-tracking | `pointerdown` on `document.body` after a `focusin` | `collapsed:true` again |
| chat-coordinator-hooks-060 | focus-reclaim-immediate | `useInputFocusReclaim(ref, true)` on mount | `document.activeElement === input` |
| chat-coordinator-hooks-061 | focus-reclaim-deferred | `pointerup` dispatched inside the wrapper | Not reclaimed synchronously; reclaimed after `advanceTimersByTime(0)` |
| chat-coordinator-hooks-062 | focus-reclaim-outside-click-guard | `pointerup` dispatched on `document` (outside the wrapper) | Never reclaimed, even after the timer advances |
| chat-coordinator-hooks-063 | focus-reclaim-selection-guard | Non-empty `window.getSelection().toString()`, inside click | Reclaim is blocked |
| chat-coordinator-hooks-064 | focus-reclaim-guards | `document.hasFocus()` stubbed `false`, inside click plus timer advance | `input.focus()` is never called |
| chat-coordinator-hooks-065 | ritual-status-stepping | `waitLines:['summoning...','accepted...']`, `stallLines:['stalling a...','stalling b...']` | `t0:'summoning...'`; `+900ms:'accepted...'`; `+900ms:'stalling a...'`; `+900ms` more: still `'stalling a...'`; `+700ms` more: `'stalling b...'`; `+1600ms` more: back to `'stalling a...'` |
| chat-coordinator-hooks-066 | ritual-status-last-wait-line-hold | Same config with `stallLines:[]` | Holds `'accepted...'` indefinitely (tested through `+10000ms` more) |
| chat-coordinator-hooks-067 | ritual-engage-on-pointer | `advanceTimersByTimeAsync(30000)` (the `giveUpAfterMs` default) with no pointer move | `engaged:true`; `+1000ms` more: `connected:true`, `inputDisabled:false` |
| chat-coordinator-hooks-068 | ritual-teardown | `engageOn:'mount'`, `unmount()` right after the welcome line lands, then `+5000ms` | The greeting is never spoken post-unmount (only the welcome line was said) |
| chat-coordinator-hooks-069 | ritual-strict-mode-safety | Real `useChatSession` + `useConnectRitual`, rendered with `{reactStrictMode:true}`, `advanceTimersByTimeAsync(5000)` | `ritual.connected:true`, `ritual.inputDisabled:false`, `session.messages.map(m=>m.text)` equals exactly `['connected.', 'hello.']` — spoken once each, in order |
| chat-coordinator-hooks-070 | ritual-engage-on-element | `engageOn:` an element ref; `pointerdown` inside it (never a window pointer move or the give-up timeout, even after `60000ms`) | Engages only from the deliberate `pointerdown`/`focusin` |
| chat-coordinator-hooks-071 | images-loaded-empty-set | `content:[]` | Returns `true` immediately (traced to source; no dedicated test file exists for this hook) |
| chat-coordinator-hooks-072 | images-loaded-tracking, images-loaded-return-value | Two image items; one `Image` fires `onload`, the other fires `onerror` | Both are marked loaded; hook returns `true` (traced to source) |

Vectors 001–014 are traced to `useChatSession.test.ts`; 015–017 to
`useCaretTracker.test.ts`'s `caretMetrics` block; 018–020 to the same
file's `useCaretTracker` block; 021–025 to `useBlockCursor.test.ts`; 026–031
to `useCaretGaze.test.ts`; 032–034 to `useMouseGaze.test.ts`; 035–036 to
`usePersonaGaze.test.ts`; 037–043 to `usePersonaMood.test.ts`; 044–046 to
`useRotatingPhrase.test.ts`'s `useRotatingPhrase` block; 047–049 to the same
file's `useTransientEcho` block; 050–051 to `useScrollToBottom.test.tsx`;
052–059 to `useChatSizing.test.ts`; 060–064 to
`useInputFocusReclaim.test.ts`; 065–070 to `useConnectRitual.test.ts`.
Vectors 071–072 have no backing test file — `useAllImagesLoaded` is the one
hook among these thirteen without one — so they are derived directly from
reading `useAllImagesLoaded.ts` itself, per **images-loaded-empty-set** and
**images-loaded-tracking**/**images-loaded-return-value** above.

## Edge Cases

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

## Configuration

Every one of these hooks is configured entirely through typed function
arguments — there are no environment variables, settings keys, feature
flags, or persisted files involved anywhere in this source.

| Hook | Option | Type | Default | Description |
|------|--------|------|---------|-------------|
| `useChatSession` | `backend` | `ChatBackend \| Backend` | — | Legacy or contract backend; required unless `orchestrator` is given |
| `useChatSession` | `orchestrator` | `Orchestrator` | — | A caller-owned orchestrator to adopt instead of building one |
| `useChatSession` | `persona` | `Partial<ChatParticipant>` | `{}` (persona ID `'persona'`) | Persona participant identity |
| `useChatSession` | `user` | `Partial<ChatParticipant>` | `{name:'You', avatar:'Y'}` | Local user participant identity |
| `useChatSession` | `welcomeMessage` | `string` | none | Initial persona message delivered before `start()`; ignored when adopting an orchestrator |
| `useConnectRitual` | `say` | `(text: string) => Promise<void>` | — | Required; delivers a line into the transcript |
| `useConnectRitual` | `welcome` / `greeting` | `string` | — | Required lines spoken during the ritual |
| `useConnectRitual` | `connectingLine` / `connectedLine` | `string` | — | Required status-line text |
| `useConnectRitual` | `waitLines` / `stallLines` | `string[]` | `[]` | Status-line cadence content before/after the primary wait sequence |
| `useConnectRitual` | `engageOn` | `'pointer' \| 'mount' \| RefObject` | `'pointer'` | What triggers engagement |
| `useConnectRitual` | `readyAfterMs` | `number` | `2000` | Delay before a pointer move can engage (pointer mode only) |
| `useConnectRitual` | `giveUpAfterMs` | `number` | `30000` | Auto-engage timeout (pointer mode only) |
| `useConnectRitual` | `greetDelayMs` | `number` | `800` | Pause between `welcome` and `greeting` |
| `useConnectRitual` | `waitStepMs` / `stallStepMs` | `number` | `900` / `1600` | Status-line stepping cadence |
| `useChatSizing` | `sizing.active` | `InlineChatSizing['active']` | `{mode:'fixed'}` | Behavior while engaged (or always, without `inactive`) |
| `useChatSizing` | `sizing.inactive` | `InlineChatSizing['active']` | none | Behavior while disengaged; its presence enables engagement tracking |
| `useChatSizing` | `sizing.transition` | `'animated' \| 'none'` | `'animated'` | Whether the `pc-anim` class is applied |
| `useScrollToBottom` | `ref` | `RefObject<HTMLElement>` | — | The scrollable transcript container |
| `useScrollToBottom` | `deps` | `unknown[]` | — | Dependency array that also triggers a same-frame bottom check |
| `useAllImagesLoaded` | `content` | `ContentItem[]` | `[]` | Rich-content items; only `type:'image'` entries are watched |
| `useCaretTracker` | `wrapperRef` | `RefObject<HTMLElement>` | — | Container searched for the input via `selector` |
| `useCaretTracker` | `enabled` | `boolean` | — | Whether tracking is active |
| `useCaretTracker` | `onMeasure` | `(input: HTMLInputElement \| null) => void` | — | Reports the focused input, or `null` |
| `useCaretTracker` | `selector` | `string` | `CHAT_INPUT_SELECTOR` (`'.pc-input'`) | CSS selector for the input |
| `useBlockCursor` | `resetKey` | `unknown` | — | Value whose change forces a re-measure while focused |
| `useCaretGaze` | `downBias` | `number` | `0.9` | Fixed `y` reported for caret-driven gaze |
| `useCaretGaze` | `selector` | `string` | `CHAT_INPUT_SELECTOR` | CSS selector for the input |
| `useMouseGaze` | `anchorRef` | `RefObject<HTMLElement>` | — | Element whose center is the gaze origin |
| `useMouseGaze` | `enabled` | `boolean` | — | Whether the `pointermove` listener is installed |
| `usePersonaMood` | `responding` / `composing` | `boolean` | — | Engagement inputs; `responding` takes priority |
| `usePersonaMood` | `flightMoods` / `typingMoods` | `E[]` | — | Mood pools rotated while responding/composing |
| `usePersonaMood` | `answerBeat` | `{mood: E, ms: number}` | none | Optional one-shot mood shown when `responding` ends |
| `usePersonaMood` | `cycleMs` | `number` | `1500` | Mood rotation interval |
| `useRotatingPhrase` | `pool` | `readonly string[]` | — | Candidate phrases |
| `useRotatingPhrase` | `rerollKey` | `number` | — | Value whose change triggers a re-roll |
| `useTransientEcho` | `utterance` | `{text: string, id: number} \| null \| undefined` | — | The utterance to echo |
| `useTransientEcho` | `holdMs` | `number` | `1800` | How long the echo persists before clearing |
| `useInputFocusReclaim` | `wrapperRef` | `RefObject<HTMLElement>` | — | Container used for the outside-click guard |
| `useInputFocusReclaim` | `enabled` | `boolean` | — | Whether reclaim is active |
| `useInputFocusReclaim` | `selector` | `string` | `CHAT_INPUT_SELECTOR` | CSS selector for the input |

## Deep Linking

Not applicable: none of these thirteen hooks read or write `location`,
`history`, route params, or any other link-derived state. The identifiers
they do carry (conversation ID, persona ID, participant IDs) are either
caller-supplied configuration or generated locally with
`crypto.randomUUID()` inside `useChatSession`, never parsed from a URL.

## Localization

Nearly every user-facing string surfaced through these hooks — persona and
user names, `useConnectRitual`'s `waitLines`/`stallLines`/`welcome`/
`greeting`/`connectingLine`/`connectedLine`, `useRotatingPhrase`'s pool
contents, and any text passed to `say`/`sayStream` — is caller-supplied
configuration, not a string this package owns, so there is nothing here for
a translation layer to intercept.

The one string this package does own: when `useChatSession` wraps a
legacy `ChatBackend` (one without `inboundEvents`) via `ChatBackendAdapter`
and that backend's `sendMessage` rejects, the persona reply is the fixed
English string "Sorry, something went wrong. Let's try again."
(`ChatBackendAdapter.ts`; `useChatSession.test.ts` "handles backend errors
gracefully"). `UseChatSessionOptions` has no override for it, so a port
ships the same string and localizes it in its own resource table.

## Accessibility Options

Not applicable within the scope of these thirteen hooks specifically: none
of them drives an unconditional, indefinite animation loop the way, for
example, the separate avatar engine does. `useChatSizing`'s `pc-anim` class
only enables a CSS height transition the host page's own stylesheet defines
(this source contains no keyframe/tween of its own to gate), and
`useConnectRitual`'s status-line stepping is text content, not motion. A
grep of `hooks/` for `matchMedia`/`reduce`/`prefers`/`contrast` finds
nothing, consistent with there being no motion here for such a check to
guard. Separately, `useChatSession` passes a hardcoded `reducedMotion:false`
into the `DefaultOrchestrator` display config on every construction; that
field belongs to the orchestrator's own contract (covered by the
`chat-coordinator-runtime` recipe) and is out of scope for these hooks'
own behavior, so it is noted here rather than flagged as a gap of this
recipe's sources.

## Feature Flags

Not applicable: there is no flag-reading mechanism anywhere in these
sources. The fixed booleans `useChatSession` passes into the orchestrator's
display config (`showAvatars`, `showReadReceipts`, `showTypingIndicators`,
`allowJoining`, `allowDeparting`, `reducedMotion`) are hardcoded literals at
the call site, not values read from any flag service, environment variable,
or remote config.

## Analytics

Not applicable: a grep of `hooks/` for analytics/tracking calls finds
nothing — none of these hooks emits an event, calls a tracking SDK, or
records usage of any kind.

## Privacy

Not applicable: these hooks pass caller-supplied text (message content,
ritual lines, phrase pools) directly to the caller-supplied backend or
orchestrator and to caller-supplied callbacks; none of them persists,
transmits independently, or logs that text themselves. A grep of `hooks/`
for `localStorage`/`sessionStorage`/`cookie`/`credential`/`token`/`password`
finds nothing.

## Logging

Not applicable: a grep of `hooks/` for `console.`/`logger` finds nothing —
none of these hooks writes to the console or any logging facility.

## Platform Notes

- **React/Web (reference implementation)**: as described throughout —
  `useEffect`/`useLayoutEffect`, `useRef`-held mutable closures,
  `requestAnimationFrame`-coalesced measurement, `ResizeObserver`/
  `MutationObserver`, native `Image`, `setTimeout`/`setInterval`, and DOM
  `RefObject`s as the entire configuration surface for the DOM-touching
  hooks.
- **SwiftUI (Apple)**: `useChatSession` maps to an `@Observable` (or
  `ObservableObject`) coordinator exposing `messages`/`isTyping` as
  published properties and `sendMessage`/`say`/`sayStream` as `async`
  methods run on `Task`s that are stored and explicitly cancelled — rather
  than landed via a pending closure `Set` — when the owning view
  disappears. Caret/gaze/scroll hooks become `GeometryReader`/
  `PreferenceKey`-driven measurements, or drop down to `UIViewRepresentable`/
  `NSViewRepresentable` bridges so `UITextView`/`NSTextView` caret-rect APIs
  can replace the hidden-mirror-`<span>` measurement entirely.
- **Jetpack Compose (Android)**: `useChatSession` becomes a `ViewModel`
  exposing `StateFlow`/`mutableStateOf`; `say`/`sayStream` become `suspend`
  functions launched in `viewModelScope`, landed from `onCleared()` instead
  of an unmount effect. Caret/scroll geometry hooks map to
  `Modifier.onGloballyPositioned`/`LayoutCoordinates` and
  `BringIntoViewRequester`; timers map to `delay()` inside a coroutine
  rather than `setTimeout`/`setInterval`.
- **AppKit/UIKit (imperative Apple)**: the transport hook becomes a plain
  coordinator object exposing KVO-observable properties or a delegate
  callback. DOM-ref-based hooks (caret, gaze, sizing, scroll, focus reclaim)
  map onto `NSTextView`/`UITextView` caret and selection APIs,
  `NSTrackingArea`/hover gesture recognizers for gaze, and Auto Layout
  constraint changes plus `CATransaction` animation blocks in place of the
  CSS-transition-driven `pc-anim` class.
- **WinUI 3 (Windows)**: this is the reason this recipe exists — there is
  no existing Windows port. `useChatSession`'s transport/orchestrator glue
  maps to a coordinator class implementing `INotifyPropertyChanged`, backed
  by an `ObservableCollection<ChatMessage>` for `messages`, with
  `sendMessage`/`say`/`sayStream` as `async Task` methods that issue
  requests through `HttpClient` and decode SSE/JSON payloads with
  `System.Text.Json`; the pending-lines-landed-on-teardown pattern
  (**session-say-landing-on-teardown**) maps to cancelling and awaiting
  outstanding `Task`s from the control's `Unloaded` handler rather than
  firing-and-forgetting them. `useConnectRitual`'s cadence and give-up
  timers (**ritual-status-stepping**, **ritual-engage-on-pointer**) map to
  `DispatcherQueueTimer`, gated by an `alive`-equivalent boolean field
  re-armed in the control's `Loaded` handler — WinUI's nearest analog of a
  React Strict Mode remount is a control being unloaded and reloaded inside
  a navigation frame's page cache. `caretMetrics`/`useCaretTracker`/
  `useBlockCursor`/`useCaretGaze` translate directly to
  `TextBox.SelectionStart` and `TextBox.GetRectFromCharacterIndex` — a
  native replacement for the hidden-mirror-`<span>` measurement — polled or
  hooked via `TextBox.SelectionChanged`/`GotFocus`/`LostFocus`, with a
  `DispatcherQueueTimer` standing in for `requestAnimationFrame` coalescing.
  `useMouseGaze`/`usePersonaGaze` map to `UIElement.PointerMoved`, and
  `useChatSizing`'s `ResizeObserver`-driven cap becomes a `SizeChanged`
  handler on the relevant `FrameworkElement`s feeding an
  `INotifyPropertyChanged`-bound `MaxHeight`. `useScrollToBottom` maps to
  `ScrollViewer.ChangeView`, triggered from the same
  `ObservableCollection<ChatMessage>.CollectionChanged` event that stands in
  for the `MutationObserver`. Any persistence a caller layers on top of
  these hooks belongs to `Windows.Storage.ApplicationData` — none of these
  hooks themselves persist anything.

## Design Decisions

**Decision**: `useChatSession` lands, rather than abandons, every in-flight `say`/`sayStream` line in a final unmount-only effect.
**Rationale**: source comments document that an `await`ing caller must still see its promise resolve after teardown — particularly under React Strict Mode's mount→cleanup→mount cycle — rather than hang forever waiting on a line whose owning component is already gone.
**Approved**: pending

**Decision**: `destroyBackend()` calls `destroy()` on the wrapped backend (the `ChatBackendAdapter` instance, when one was created), never directly on the raw backend passed in as an option.
**Rationale**: source comments explain that destroying the raw backend directly was a prior bug — it skipped the adapter's own teardown of its `AbortController` and event queue, leaking one adapter/loop per mount cycle.
**Approved**: pending

**Decision**: `useChatSession` builds its internal session object exactly once (`sessionRef.current === null` guard) and never rebuilds it when `backend`/`orchestrator` identity changes across renders.
**Rationale**: source comments explain that an inline `new MockBackend()` literal in a demo render would otherwise reset the whole conversation on every render.
**Approved**: pending

**Decision**: `useRotatingPhrase` performs its first roll in a mount-only effect but re-rolls synchronously during render on a `rerollKey` change (React's "adjust state during render" pattern), instead of doing both rolls in effects.
**Rationale**: the source's own comment states the initial pick happens on mount "so server and client agree on the first frame," while later key changes re-roll during render "so the new phrase lands in the same paint as its trigger, with no one-frame lag from an effect."
**Approved**: pending

**Decision**: `useConnectRitual` re-arms its `alive` flag at the start of every effect run rather than setting it once forever at initial mount.
**Rationale**: this makes the ritual safe under React Strict Mode's deliberate double-invoke without disabling that check — a stale first mount's `alive` flag is correctly left `false` after its cleanup runs, while the second, genuine mount re-arms its own flag and completes the ritual normally.
**Approved**: pending

**Decision**: `useBlockCursor` only updates its caret-box state when the newly measured box differs from the previous one in position or size, otherwise keeping the exact same object reference.
**Rationale**: the underlying `useCaretTracker` measurement is coalesced to one `requestAnimationFrame` per relevant DOM event, but an unchanged caret position (e.g., a `selectionchange` that doesn't actually move the caret) would otherwise still produce a new object and re-render every consumer on every such event.
**Approved**: pending

**Decision**: `useAllImagesLoaded` treats a watched image's `onerror` identically to its `onload` — both mark that source "loaded."
**Rationale**: a broken image `src` is a terminal outcome, not a pending one; treating it the same as a successful load prevents whatever gate depends on "all images loaded" (e.g., an initial-render reveal) from waiting forever on an image that will never fire `onload`.
**Approved**: pending

**Decision**: `useMouseGaze` never itself decides whether to defer to a caret-driven gaze source; `usePersonaGaze` composes `useMouseGaze` and `useCaretGaze` and performs that arbitration one level up.
**Rationale**: keeps `useMouseGaze` a single-source, independently reusable and testable hook; the mutual-exclusion policy (mouse silenced while engaged, caret gated while disengaged) only makes sense to a caller that already knows about both sources.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |

Each hook owns exactly one concern (transport, caret geometry, gaze, mood,
sizing, scroll, focus, phrase rotation, or image-load gating) in its own
file, and the only cross-hook composition (`useBlockCursor`/`useCaretGaze`
on `useCaretTracker`, `usePersonaGaze` on `useMouseGaze`+`useCaretGaze`) is
one-directional and narrow, so separation-of-concerns passes. Twelve of the
thirteen hooks have a dedicated test file exercising their documented
behavior in real depth (fake timers, jsdom rect stubs, Strict Mode
rendering); `useAllImagesLoaded` has none at all, so unit-test-coverage is
partial rather than passed. Error handling is inconsistent rather than
absent: a legacy backend's rejection is caught and surfaced as a visible
apology message (**session-backend-error-apology**), but the same
`sendMessage`'s call into `orchestrator.submitMessage` swallows any
rejection with `.catch(() => {})` and no caller-visible signal at all — one
path handles the failure explicitly, the other silently discards it — so
explicit-error-handling is partial. Every timer this source starts is paired
with a teardown (`useConnectRitual`'s step/beat timers, `usePersonaMood`'s
rotation/beat timers, `useTransientEcho`'s hold timer, `useCaretTracker`'s
rAF), every listener installed is removed, and in-flight `say`/`sayStream`
lines are landed rather than abandoned on unmount, so fault-tolerance
passes. Every DOM-touching hook that can't find its target (no selector
match, no anchor, no wrapper) quietly reports an inert state instead of
throwing, so a host that omits an optional ref or renders before the DOM is
ready still functions — graceful-degradation passes. Accessibility,
security, networking, and persistence categories beyond what's covered
above are not listed here because these hooks render no visible surface of
their own (see Accessibility), make no network calls directly (transport is
delegated entirely to the caller-supplied backend/orchestrator), and
persist nothing (see Privacy).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-09-25 | Mike Fullerton | Trimmed summary <=160c; fixed caret-gaze input-width normalization; corrected sayStream teardown. |
| 1.0.0 | 2026-09-23 | Claude Sonnet 5 | Initial creation from the thirteen hook sources in `@adh-sdk/chat`'s `src/hooks/` and their test suites; documents the hardcoded English apology string on `useChatSession`'s legacy-backend error path under Localization. |
