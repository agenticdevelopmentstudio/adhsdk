
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

