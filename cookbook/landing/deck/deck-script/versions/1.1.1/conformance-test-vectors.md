
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| deck-script-001 | render-script-element | `<DeckScript />` rendered in JSX | A `<script>` element with non-empty `dangerouslySetInnerHTML` property appears in the rendered output |
| deck-script-002 | open-at-top | `deckScript({ openAtTop: true })` | Returned string contains `history.scrollRestoration="manual"` |
| deck-script-003 | open-at-top | `deckScript({ openAtTop: false })` | Returned string does NOT contain `history.scrollRestoration` |
| deck-script-004 | arm-snapping | `deckScript({ armSnapping: true })` | Returned string contains `addEventListener` calls for `pointerdown`, `wheel`, `keydown` and sets a `data-snap` attribute |
| deck-script-005 | arm-snapping | `deckScript({ armSnapping: false })` | Returned string does NOT contain `data-snap` attribute code |
| deck-script-006 | arm-smooth | `deckScript({ armSmooth: true })` | Returned string contains listeners that set `data-smooth` and a `popstate` listener that removes it |
| deck-script-007 | arm-smooth | `deckScript({ armSmooth: false })` | Returned string does NOT contain `data-smooth` attribute code |
| deck-script-008 | restore-zoom-off-ios | `deckScript({ restoreZoomOffIos: true })`, called on any platform | Returned string contains the code that strips `maximum-scale` from the viewport meta tag; the string is identical regardless of the calling platform, since the iOS/iPadOS check runs later, when the script executes in a browser |
| deck-script-009 | restore-zoom-off-ios | `deckScript({ restoreZoomOffIos: false })` | Returned string does NOT contain viewport meta modification code |
| deck-script-010 | independent-disabling | `deckScript({ openAtTop: true, armSnapping: false, armSmooth: true, restoreZoomOffIos: true })` | Returned string contains only the three enabled segments; total length is shorter than all-enabled |
| deck-script-011 | passive-listeners | `deckScript({ armSnapping: true })` | Returned string contains `{once:true,passive:true}` for the snapping listeners |
| deck-script-012 | passive-listeners | `deckScript({ armSmooth: true })` | Returned string contains `{passive:true}` for the smooth listeners, without `once` |
| deck-script-013 | target-root-element | `deckScript({ armSnapping: true, armSmooth: true, restoreZoomOffIos: false })` | Returned string calls `setAttribute`/`removeAttribute` only on `document.documentElement` (or a variable referencing it) |
| deck-script-014 | execute-before-hydration | `<DeckScript />` rendered server-side and the HTML inspected before the client bundle runs | The `<script>` tag and its inline body are present in the server-rendered HTML, not injected later by an effect |
| deck-script-015 | compose-into-single-string | `deckScript({ openAtTop: true, armSnapping: true, armSmooth: true, restoreZoomOffIos: true })` | Returned string equals the concatenation of the four segments in `openAtTop`, `armSnapping`, `armSmooth`, `restoreZoomOffIos` order, with no separators between them |
| deck-script-016 | restore-zoom-off-ios | Runtime execution (jsdom/Playwright) of the returned script with an iOS Safari user agent | `maximum-scale` is NOT removed from the viewport meta tag |
| deck-script-017 | restore-zoom-off-ios | Runtime execution (jsdom/Playwright) of the returned script with a non-iOS user agent | `maximum-scale` IS removed from the viewport meta tag, both synchronously and again on `load` |
| deck-script-018 | edge case: default options (empty) | `deckScript({})` | Returned string equals the all-enabled string (all four defaults are `true`) |
| deck-script-019 | edge case: default options (omitted) | `deckScript()` | Returned string is identical to `deckScript({})` |
| deck-script-020 | edge case: all disabled | `deckScript({ openAtTop: false, armSnapping: false, armSmooth: false, restoreZoomOffIos: false })` | Returned string is `""` |
| deck-script-021 | edge case: viewport meta tag missing | Runtime execution with no `<meta name=viewport>` element present | No error is thrown; a `load` listener is registered to retry the query |
| deck-script-022 | edge case: input before listeners attach | Runtime execution where a `wheel` event is dispatched before the script's listener-attachment line runs, then again after | The first event has no observable effect; the second sets `data-snap` |
| deck-script-023 | edge case: multiple instances | Two `<DeckScript />` components rendered in the same tree | Two separate `<script>` elements appear, each independently correct; effects are redundant but harmless (idempotent attribute sets, duplicate listeners) |
| deck-script-024 | edge case: rendered in `<head>` | `<DeckScript />` rendered inside `<head>`, before the viewport meta tag | `restoreZoomOffIos` succeeds only via the `load` fallback, leaving pinch-zoom disabled until `load`; `openAtTop`, `armSnapping`, and `armSmooth` are unaffected by placement |
| deck-script-025 | css-contract | `deckScript({ armSnapping: true, armSmooth: true, restoreZoomOffIos: false })` | Returned string's only attribute names are `data-snap` and `data-smooth`, matching the `html[data-snap]` / `html[data-smooth]` selectors the host stylesheet must define |

