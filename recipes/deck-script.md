---
id: e16d896e-9318-48ac-bf1e-b48ef648d73c
title: DeckScript
domain: adhsdk://recipes/deck-script
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Renders critical initialization scripts that must run before first paint
  to control scroll behavior and viewport settings.
platforms:
- typescript
- web
tags:
- scroll
- initialization
- performance
- viewport
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# DeckScript

## Overview

DeckScript is a React component that renders inline scripts executed before page hydration to initialize scroll behavior, scroll snapping, smooth scroll easing, and iOS/iPadOS viewport zoom constraints. All four behaviors are optional and default to enabled. The component exports both a function that returns the script as a string and a React component that renders it. It SHOULD be placed first inside `<body>`, not `<head>`, so the viewport meta tag has already been parsed when `restoreZoomOffIos` runs; a `load`-event fallback covers a miss, but only from that point on.

## Behavioral Requirements

- **render-script-element**: Component MUST render a `<script>` element with `dangerouslySetInnerHTML` containing the generated inline script body.
- **execute-before-hydration**: The rendered script MUST execute as a literal inline `<script>` tag before React hydration begins; it MUST NOT be wrapped in a client component or effect.
- **open-at-top**: When `openAtTop` is `true` (default), the script MUST set `history.scrollRestoration` to `"manual"` to force every load to start at the top.
- **arm-snapping**: When `armSnapping` is `true` (default), the script MUST attach a `{once:true,passive:true}` listener to each of `pointerdown`, `wheel`, and `keydown`; the first of these to fire sets a `data-snap` attribute on `document.documentElement`. Because each event type has its own one-time listener, the attribute can be set by more than one of the three if they fire close together — repeat sets of the same value are harmless no-ops.
- **arm-smooth**: When `armSmooth` is `true` (default), the script MUST attach `{passive:true}` listeners (without `once`) to `pointerdown`, `wheel`, and `keydown` to set a `data-smooth` attribute on `document.documentElement`, and MUST remove that attribute on every `popstate` event so history-restoration scrolls are not eased.
- **restore-zoom-off-ios**: When `restoreZoomOffIos` is `true` (default), the script MUST detect iOS or iPadOS — `iPhone`/`iPad`/`iPod` in the user agent, or a `MacIntel` platform with `maxTouchPoints > 1` (the desktop-mode Safari signature for iPadOS) — and skip on those platforms; on every other platform it MUST strip any `maximum-scale` constraint from the viewport meta tag when the script executes, and again on the `load` event as a fallback for a meta tag not yet present.
- **independent-disabling**: Each of the four behaviors (`openAtTop`, `armSnapping`, `armSmooth`, `restoreZoomOffIos`) MUST be independently disableable via the options object passed to the component or function.
- **compose-into-single-string**: The `deckScript()` function MUST concatenate enabled script segments, in `openAtTop`, `armSnapping`, `armSmooth`, `restoreZoomOffIos` order, into a single string with no separators; the component MUST pass this string to `dangerouslySetInnerHTML.__html`.
- **passive-listeners**: Every listener attached by `armSnapping` and `armSmooth` MUST use `{passive:true}`; `armSnapping`'s listeners MUST also use `{once:true}`.
- **target-root-element**: All attribute mutations (`data-snap`, `data-smooth`) MUST target `document.documentElement`, not any other element.
- **css-contract**: The host stylesheet MUST define `html[data-snap]` (scroll-snap activation) and `html[data-smooth]` (`scroll-behavior: smooth`) rules for `armSnapping` and `armSmooth` to have any visible effect, and MUST cancel `scroll-behavior: smooth` on `html[data-smooth]` under `@media (prefers-reduced-motion: reduce)`. DeckScript sets and clears the two attributes; it does not define the CSS that reacts to them.

## Appearance

Not applicable: DeckScript is a script element that does not render visible content. It contains only JavaScript code that initializes page behavior.

## States

Not applicable: DeckScript is an initialization script with no interactive states. It executes once at page load and operates via side effects on document attributes.

## Accessibility

DeckScript operates at the initialization layer and does not itself call any accessibility API, but the behaviors it arms have real accessibility consequences that live in the CSS contract (see **css-contract**) and with the caller, not in this script. `armSmooth` performs no reduced-motion check of its own — it only toggles `data-smooth`; the CSS contract MUST cancel `scroll-behavior: smooth` under `@media (prefers-reduced-motion: reduce)` so easing respects the system preference automatically. A caller who wants to disable arming outright, rather than rely on that CSS override, MAY pass `armSmooth: false`. `restoreZoomOffIos` is itself an accessibility fix: stripping `maximum-scale` off non-iOS platforms restores pinch-zoom where the zoom-on-focus problem `maximum-scale=1` guards against doesn't occur (see **restore-zoom-off-ios** and Design Decisions).

## Conformance Test Vectors

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

## Edge Cases

- **Empty options object**: When `deckScript({})` is called, all four defaults (true) MUST be applied, returning the full script string.
- **Undefined options parameter**: When `deckScript()` is called with no arguments, defaults MUST be applied identically to `deckScript({})`.
- **Disabled all behaviors**: When `deckScript({ openAtTop: false, armSnapping: false, armSmooth: false, restoreZoomOffIos: false })` is called, the function MUST return an empty string.
- **Viewport meta tag missing**: When `restoreZoomOffIos` runs and no viewport meta tag exists yet, the code does not throw — the `if(m)` check short-circuits — and it awaits the `load` event to retry the query.
- **Multiple DeckScript renders**: Only one `<DeckScript />` instance SHOULD be rendered per page. Rendering more than one injects a separate script block per instance; the effects layer harmlessly (idempotent attribute sets, duplicate listeners) but wastes bytes and events.
- **DeckScript rendered in `<head>`**: The component SHOULD be placed first in `<body>` as documented; if placed in `<head>`, the viewport meta tag may not yet be parsed and `restoreZoomOffIos` behavior is degraded to only the `load` event fallback.
- **Input firing before arm-snapping's listeners attach**: A user CAN scroll, click, or press a key before this script reaches its listener-attachment lines — for example during a slow fetch of the surrounding HTML. That input is simply missed, since no listener exists yet to see it, and `data-snap` stays unset. The next `pointerdown`, `wheel`, or `keydown` after the script runs arms snapping normally.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `openAtTop` | boolean | `true` | Scroll to top on every page load by setting `history.scrollRestoration` to `"manual"` |
| `armSnapping` | boolean | `true` | Enable scroll snapping on `document.documentElement` after first user input (pointerdown, wheel, or keydown) |
| `armSmooth` | boolean | `true` | Enable smooth scrolling easing on first input; disable on browser back/forward (popstate event) |
| `restoreZoomOffIos` | boolean | `true` | Remove `maximum-scale` viewport meta constraint on non-iOS platforms to re-enable pinch-zoom |

## Deep Linking

Not applicable: DeckScript is an initialization script and does not handle deep linking or URL routing.

## Localization

Not applicable: DeckScript contains only JavaScript logic and inline HTML attribute operations; it generates no user-facing text.

## Accessibility Options

DeckScript operates at the initialization layer and performs no Reduce Motion check itself. The CSS contract (see **css-contract**) is what MUST honor `prefers-reduced-motion`; a caller who wants to skip arming entirely, rather than rely on that CSS override, MAY also pass `armSmooth: false`.

## Feature Flags

Not applicable: DeckScript is a low-level initialization primitive with no feature flag interface. Enable or disable each behavior via the configuration options passed to the function or component.

## Analytics

Not applicable: DeckScript performs no analytics event tracking. It operates before page hydration and user interaction begins.

## Privacy

Not applicable: DeckScript performs no data collection, storage, or transmission. It reads and writes only to the DOM and performs user-agent sniffing locally.

## Logging

Not applicable: DeckScript does not emit log messages. It performs silent initialization; the one failure mode it anticipates — no viewport meta tag present when `restoreZoomOffIos` runs — is handled with a `load`-event retry and no reporting.

## Platform Notes

- **TypeScript/Web**: `deckScript()` and `<DeckScript />` are the reference implementation every other platform's port matches behavior against; see `packages/web/packages/landing/src/deck/DeckScript.tsx`. The component exports both `deckScript(options)` (string generator) and `DeckScript` (React component). Render first inside `<body>`. Requires `base.css` to define `html[data-snap]` (scroll-snap activation) and `html[data-smooth]` (`scroll-behavior: smooth`) selectors, plus a `@media (prefers-reduced-motion: reduce)` override that cancels `scroll-behavior: smooth` on `html[data-smooth]` (see **css-contract**).

- **SwiftUI**: Equivalent functionality would require wrapping a `WKWebView` with `WKWebViewConfiguration` that injects JavaScript at document start time. Create a `WKUserScript` with `injectionTime: .atDocumentStart` and `forMainFrameOnly: true`, then add it to `WKWebViewConfiguration.userContentController`. Each behavior maps to a discrete script segment that can be conditionally included in the source string passed to `WKUserScript`. SwiftUI views wrapping the web view would need to expose configuration properties corresponding to the four boolean options.

- **Compose**: Equivalent functionality requires embedding a `WebView` and injecting via `WebViewCompat.addDocumentStartJavaScript` (from `androidx.webkit`), which runs the script before the page's own scripts execute — the real analogue of `WKUserScript`'s `.atDocumentStart`. `WebViewClient.onPageStarted()` fires too late relative to the page's own script execution to guarantee the same before-first-paint timing, so treat it only as a fallback where the document-start API is unavailable, or embed the script directly in the HTML template served to the WebView. Conditional segments follow the same pattern as TypeScript.

- **AppKit / UIKit**: Use `WKWebView` with `WKUserScript` injected at `injectionTime: .atDocumentStart` into `WKWebViewConfiguration.userContentController`, identical to SwiftUI. The script runs before any user interaction, ensuring scroll restoration and snapping arm before the first input. View controllers would configure the `WKWebView` and build the script string from the same four boolean flags.

- **WinUI 3**: Embed a `WebView2` control and use `CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync()` to inject the JavaScript before navigating. The script executes at document-creation time, before rendering; `CoreWebView2.ExecuteScriptAsync()` is for post-load scripts only and is not a substitute for pre-paint initialization. Compose the script string conditionally from the four options, then pass the complete string to `AddScriptToExecuteOnDocumentCreatedAsync()`.

## Design Decisions

- **Decision**: The component exposes four independent boolean behaviors (`openAtTop`, `armSnapping`, `armSmooth`, `restoreZoomOffIos`) rather than a single on/off switch.
  **Rationale**: Each behavior addresses a distinct UX concern (pull-to-refresh parity, preventing mid-load snap, respecting history traversal, accessibility), and disabling one does not require disabling the others.
  **Approved**: pending

- **Decision**: `armSnapping` and `armSmooth` arm on the reader's first input, not on page load or after a fixed delay.
  **Rationale**: Avoids the "mid-load snap" problem — if scroll snap were active during the initial layout pass while section heights are still settling, the snap engine would pick a snap point at an intermediate height, stranding the reader between two screens. Arming on first input guarantees the page is at rest when the property activates.
  **Approved**: pending

- **Decision**: `armSmooth`'s `pointerdown`/`wheel`/`keydown` listeners intentionally omit `{once:true}` (unlike `armSnapping`'s, which use it), and a `popstate` listener clears `data-smooth` on every history traversal.
  **Rationale**: The browser's own scroll restoration uses `scroll-behavior: smooth` (from `base.css`), which would animate the reader back to a previous offset and create a false impression of travel. Clearing `data-smooth` on `popstate` removes easing from the restoration scroll; because the input listeners were never `{once:true}`, the very next input re-arms it before there is anything left to ease.
  **Approved**: pending

- **Decision**: `maximum-scale` is stripped from the viewport meta tag on every platform except iOS/iPadOS.
  **Rationale**: `maximum-scale=1` is the only way to stop iOS Safari zooming the page when a form field takes focus, so it ships in the meta tag for iOS; but it also disables pinch-zoom entirely, which is a real accessibility cost. On iOS the trade is made deliberately — pinch-zoom is knowingly sacrificed to prevent zoom-on-focus. Off iOS, where that hazard doesn't exist, stripping the constraint restores pinch-zoom with no downside.
  **Approved**: pending

- **Decision**: DeckScript renders a literal `<script>` tag with an inline body; it is not a React effect.
  **Rationale**: By the time React effects fire (after hydration), scroll restoration and user input may already have occurred. The script must run before any React lifecycle to have any of its four effects.
  **Approved**: pending

- **Decision**: The component SHOULD be rendered first inside `<body>`, not in `<head>`.
  **Rationale**: `restoreZoomOffIos` calls `document.querySelector('meta[name=viewport]')` immediately when the script runs. In `<head>`, the viewport meta tag may not yet be parsed, depending on framework render order. Placing the script first inside `<body>` guarantees the meta tag is already behind it in the DOM; the `load`-event fallback still catches a miss, but only from that point on, during which window non-iOS pinch-zoom stays disabled for nothing.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`armSmooth` only toggles the `data-smooth` attribute; whether `scroll-behavior: smooth` is actually cancelled under `@media (prefers-reduced-motion: reduce)` depends on the `base.css` rule this source file does not contain, so the status is `partial` rather than `passed` (see **css-contract**). `separation-of-concerns` is passed because all four behaviors are built as plain strings by the pure `deckScript()` function, with `DeckScript` itself only a thin wrapper that injects that string into a literal `<script>` tag; `unit-test-coverage` is passed on `deck.test.tsx`, which calls `deckScript()` directly and asserts each of the four options' markers (`scrollRestoration`, `data-snap`, `data-smooth`/`popstate`, `maximum-scale`) both present and absent.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | deck-script-013/025 vectors add restoreZoomOffIos:false so exclusivity claims hold; wrapped bare <head> in a code span. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited, added the css-contract requirement and its compliance/accessibility row, corrected arm-snapping/restore-zoom/design-decision/logging accuracy, reformatted Design Decisions into Decision/Rationale/Approved triples, unified RFC 2119 keyword usage, expanded Platform Notes (fixed Compose and SwiftUI API names) and Conformance Test Vectors (platform-independent 008, hydration/composition/UA-branch/edge-case coverage), unquoted frontmatter dates |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
