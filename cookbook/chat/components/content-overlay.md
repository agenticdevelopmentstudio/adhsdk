---
id: bd17a89e-aac9-475d-adcd-98b61d24f941
title: "Content Overlay"
type: ingredient
version: 1.2.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A controlled overlay component that displays content with a customizable close button."
platforms:
  - typescript
  - web
tags:
  - overlay
  - chat
  - controlled-component
  - dismissible
depends-on: []
related:
  - 447d0e33-c66e-4bf9-8511-e7823bdbcf9b
references: []
approved-by: ""
approved-date: ""
---

# Content Overlay

## Overview

ContentOverlay is a controlled React component that conditionally displays content in an overlay structure with a dismissal button. It accepts an `open` boolean to control visibility state, an `onClose` callback for dismissal, a customizable close button label, and child content to render. The component manages CSS classes and layout structure; styling is delegated to an external stylesheet.

## Behavioral Requirements

- **closed-invisible**: When `open` is `false`, the overlay MUST NOT be visible.
- **closed-non-interactive**: When `open` is `false`, the overlay MUST NOT respond to pointer input (clicks/taps on the header, close button, and body do not invoke `onClose` or otherwise pass through). This covers pointer input only: keyboard focus and Enter/Space activation of the close button are not blocked by the source, which is a known gap (see the non-modal Design Decision).
- **apply-open-class**: The component MUST apply the `open` CSS class to the root element when the `open` prop is `true`.
- **omit-open-class**: The component MUST NOT apply the `open` CSS class to the root element when the `open` prop is `false`.
- **invoke-on-close**: The component MUST invoke the `onClose` callback function when the close button is clicked.
- **render-children**: The component MUST render the `children` prop within the body element.
- **close-label**: The component MUST display the `closeLabel` prop as the close button text when provided.
- **default-close-label**: The component MUST display the string `'← back'` as the close button text when `closeLabel` is not provided.
- **custom-class-name**: The component MUST apply the `className` prop to the root element, in addition to base and state CSS classes, when provided.

## Appearance

Traced to `packages/web/packages/chat/src/css/components/content-overlay.css`.

- **Corner radius**: None. Root, header, close button, and body are unrounded.
- **Padding**: Header: `10px 12px`. Close button: `6px 0`. Root bottom: `calc(env(safe-area-inset-bottom, 0px) + 44px)`. Body bottom: `env(safe-area-inset-bottom, 0)`.
- **Font**: Close button: `var(--font-mono, ui-monospace, SFMono-Regular, monospace)`, `0.65rem`, `0.06em` letter-spacing.
- **Background**: Root: `rgba(10, 10, 14, 0.3)` with `backdrop-filter: blur(16px)` (`-webkit-backdrop-filter` included for Safari). Header, close button, and body have no background of their own.
- **Foreground/Text**: Close button text: `var(--text-muted, #8a8a9a)` by default, `var(--accent, #c4a35a)` while pressed (`:active`).
- **Border**: Header: `1px solid rgba(42, 42, 54, 0.4)` bottom border. Close button and body have no border.
- **Shadow**: None defined.
- **Min/Max size**: Root fills the viewport (`position: fixed; top/left/right/bottom: 0`). No min/max constraints on header, close button, or body; body uses `flex: 1; min-height: 0` to fill remaining vertical space.
- **Z-index**: Root: `z-index: 1`.
- **Transitions**: Root `opacity` transitions over `0.3s` with `cubic-bezier(0.16, 1, 0.3, 1)`, unconditionally (no `prefers-reduced-motion` gating — see **Accessibility Options**). Close button `color` transitions over `0.15s` (default easing).
- **Layout**: Root is a flex column (`display: flex; flex-direction: column; overflow: hidden`). Header does not shrink (`flex-shrink: 0`). Body is `flex: 1` and is itself a flex column.
- **Responsive**: No `pc-content-overlay`-specific responsive rules are defined in this stylesheet. (The same stylesheet file also carries a `@media (max-width: 768px)` block for `.persona-chat`, `.pc-input`, and `.pc-input-area` — those target content typically hosted in the body slot, e.g. a chat, and belong to the chat ingredient's stylesheet, not this one.)

## States

| State | Appearance change |
|-------|------------------|
| Closed (open=false) | `opacity: 0`, `pointer-events: none` — overlay is invisible and non-interactive |
| Open (open=true) | `opacity: 1`, `pointer-events: auto` — fades in over `0.3s` (`cubic-bezier(0.16, 1, 0.3, 1)`) and becomes interactive |
| Close button — pressed (`:active`) | Text color changes from `var(--text-muted, #8a8a9a)` to `var(--accent, #c4a35a)` |

## Accessibility

- **Role**: The close button is a native HTML `<button>` element, providing automatic semantic button role.
- **Label**: The close button is labeled by its text content: `closeLabel` prop or default `'← back'`. When `closeLabel` is an empty string, the button has no accessible name (see **Edge Cases**).
- **Keyboard support**: Native button element supports keyboard activation (Enter, Space keys) from the platform. The `pointer-events: none` used when closed blocks pointer/click hit-testing but not keyboard focus or keyboard-triggered activation, so the close button (and any focusable content in the body) remains tab-reachable and screen-reader-visible while the overlay is closed — see the non-modal Design Decision.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| overlay-001 | closed-invisible, closed-non-interactive | open=false | Header, close button, and body remain present but the root has no `open` class, `opacity: 0` and `pointer-events: none` apply, as computed from the stylesheet (browser hit-testing of the click itself is not exercised in jsdom) |
| overlay-002 | apply-open-class | open=true | Root div has class `pc-content-overlay open` |
| overlay-003 | omit-open-class | open=false | Root div has class `pc-content-overlay` (no `open` class) |
| overlay-004 | invoke-on-close | open=true; user clicks close button; onClose is a spy function | onClose is called exactly once |
| overlay-005 | render-children | children=a `<div>test content</div>` element, open=true | Text "test content" appears in body element |
| overlay-006 | close-label | closeLabel="Custom Label", open=true | Close button displays "Custom Label" |
| overlay-007 | default-close-label | closeLabel is undefined, open=true | Close button displays "← back" |
| overlay-008 | custom-class-name | className="custom-style", open=true | Root div includes class `custom-style` |
| overlay-009 | close-label | closeLabel="", open=true | Close button renders with empty text content; button remains present and clickable |
| overlay-010 | invoke-on-close | open=true; user clicks close button 3 times in rapid succession; onClose is a spy function | onClose is called exactly 3 times, once per click (invocations are not merged or debounced) |
| overlay-011 | render-children | children=null, open=true | Body element renders with no content and no thrown error |
| overlay-012 | closed-non-interactive | open=false; the close button is focused and the user presses Enter | `onClose` is called once (keyboard activation is not blocked while closed; known gap) |
| overlay-013 | custom-class-name | className is undefined, open=true | Root div class is exactly `pc-content-overlay open`, with no literal `undefined` in the class string |
## Edge Cases

- **Null or undefined children**: When children is null or undefined, the body element renders empty. Expected behavior: no error, body is rendered and visible (empty). (MUST render without error)
- **Empty closeLabel**: When closeLabel is an empty string, the close button renders with no visible text and, since the source provides no fallback label, no accessible name either. Expected behavior: button remains present and clickable (SHOULD allow empty string), but is not identifiable to screen reader users in this state. Callers SHOULD avoid passing an empty `closeLabel`.
- **Multiple rapid closes**: User clicks close button multiple times in rapid succession. Expected behavior: onClose is invoked once per click; multiple invocations are not merged. (MUST invoke per click)
- **Missing onClose callback**: `onClose` is a required prop (`onClose: () => void`, non-optional in the TypeScript signature), and the click handler performs no runtime check before calling it. If a caller bypasses the type system and omits `onClose`, clicking the close button calls `undefined` and throws. Expected behavior: a runtime error on click (MUST NOT be silently swallowed — the component makes no defensive null check for a required prop).
- **className with special characters**: className contains spaces, hyphens, or other CSS class name characters. Expected behavior: className is concatenated into the class string as-is. (SHOULD preserve className as provided)

## Configuration

Not applicable: The component is configured entirely through its React props (`open`, `onClose`, `closeLabel`, `children`, `className`) and has no separate configuration options.

## Deep Linking

Not applicable: ContentOverlay is a presentation component with no navigation or routing behavior.

## Localization

The `closeLabel` prop's value, when supplied by the caller, should be localized by the caller — ContentOverlay performs no translation itself. The default value used when `closeLabel` is omitted, `'← back'`, is a hardcoded English string with a decorative arrow glyph baked into the same text node; it is not sourced from a localization resource and does not adapt to locale. Callers targeting non-English locales MUST always pass a localized `closeLabel` rather than relying on the default. See **default-close-label**.

The default `'← back'` bakes a left-pointing arrow into the text, which points the wrong way in right-to-left locales. The source does not mirror it. Callers in RTL locales should pass a localized `closeLabel` with the arrow omitted or mirrored, and a port may keep the arrow as a separate, mirrored icon rather than part of the text.
## Accessibility Options

The component does not directly respond to system-level accessibility options. Increase Contrast and Differentiate Without Color are not addressed in the traced stylesheet. Reduce Motion is also not addressed: the root's `opacity` transition (see Appearance → Transitions) runs unconditionally, with no `prefers-reduced-motion` media query gating it.

## Feature Flags

Not applicable: The component has no feature flag gating or conditional behavior.

## Analytics

Not applicable: The component does not emit analytics events. Event tracking is the responsibility of the calling component.

## Privacy

Not applicable: The component does not collect, store, or transmit any data.

## Logging

Not applicable: The component does not emit log messages.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/chat/src/components/ContentOverlay.tsx`. The component is a stateless, controlled component that always mounts the header/close-button/body structure and toggles visibility and interactivity via CSS classes rather than conditional rendering, satisfying **closed-non-interactive** through `pointer-events`/`opacity` rather than unmounting. Visibility and styling are delegated to the stylesheet using class names `pc-content-overlay`, `pc-content-overlay-header`, `pc-content-overlay-close`, and `pc-content-overlay-body`.

- **SwiftUI**: Implement as a `ZStack` layer that stays in the view hierarchy at all times (mirroring **closed-non-interactive**), not a `.sheet()` or `.fullScreenCover()`, both of which unmount when dismissed. Bind visibility to `open` with `.opacity(open ? 1 : 0)` and `.allowsHitTesting(open)`, matching the CSS `opacity`/`pointer-events` toggle. Structure a header row (a close `Button` bound to `onClose`, label from the `closeLabel` parameter, default `"← back"`) above a content area holding the children view. Animate the opacity change with a timing curve matching `cubic-bezier(0.16, 1, 0.3, 1)` over `0.3s`. The web source leaves the closed layer reachable by keyboard and screen reader; a port should instead hide it while closed (`.accessibilityHidden(!open)`).

- **Compose**: Implement as a `Box` that is always composed, not a `Dialog` or `Popup`, which unmount when dismissed. Drive visibility with `Modifier.graphicsLayer { alpha = if (open) 1f else 0f }` and gate interaction with `Modifier.pointerInput(open) { if (!open) awaitPointerEventScope { while (true) { awaitPointerEvent(PointerEventPass.Initial).changes.forEach { it.consume() } } } }` so the closed layer swallows pointer input before its children see it, and hide it from accessibility while closed with `Modifier.semantics { if (!open) invisibleToUser() }` so the header/close button/body stay composed but non-interactive when closed. A header `Row` holds a close `Button` (`onClick = onClose`, text from the `closeLabel` parameter, default `"← back"`). Animate alpha with `animateFloatAsState` using a matching easing curve.

- **AppKit / UIKit**: Add the overlay view as a permanent full-bleed subview of the window's content view — not a sheet, popover, or modal view controller, all of which remove the view when dismissed. On iOS (UIKit), toggle `view.alpha` and `view.isUserInteractionEnabled` from the `open` state. On macOS (AppKit), toggle `view.alphaValue` and override `hitTest(_:)` to return `nil` when closed (AppKit has no `isUserInteractionEnabled` equivalent). The header is a stack view with a close `UIButton`/`NSButton` whose action calls `onClose`, titled from the `closeLabel` parameter (default `"← back"`). Animate the alpha change over `0.3s` with a matching timing curve (`UIView.animate` / `NSAnimationContext`). The web source leaves the closed layer reachable by keyboard and screen reader; a port should instead hide it while closed (on iOS, `accessibilityElementsHidden = !open`; on macOS, keep it out of the key-view loop and accessibility hierarchy).

- **WinUI 3**: Implement as a `Grid` overlay layer that stays in the visual tree alongside the page's main content — not a `ContentDialog`, which is a true modal. Bind `Opacity` and `IsHitTestVisible` to the `open` state so the header/close button/body remain in the tree but are invisible and non-interactive when closed, mirroring the CSS `opacity`/`pointer-events` behavior. The header is a `Grid`/`StackPanel` containing a close `Button` whose `Click` event calls `onClose`, with `Content` bound to the close-label parameter (default `"← back"`). Animate `Opacity` with a `DoubleAnimation` using a `KeySpline` matching `cubic-bezier(0.16, 1, 0.3, 1)`. The web source leaves the closed layer reachable by keyboard and screen reader; a port should instead set `IsTabStop=false` on the close button while closed and keep the layer out of the automation tree.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/components/ContentOverlay.tsx` | confirmed (1.2.2) |

## Design Decisions

**Decision**: Use fully controlled props (`open`, `onClose`) rather than internal state.
**Rationale**: Requires the parent to manage `open` state and implement `onClose` dismissal, which enables precise parent control, simplifies testing, and aligns with React controlled-component patterns.
**Approved**: pending

**Decision**: Default `closeLabel` to `'← back'` when the caller does not supply one.
**Rationale**: Provides a sensible default for navigation-oriented overlays while still permitting per-caller customization.
**Approved**: pending

**Decision**: The overlay is intentionally non-modal: it always stays mounted and toggles visibility purely through CSS (`opacity`/`pointer-events`) rather than conditional mounting or `aria-hidden`/`inert`, and it defines no ARIA dialog role, no focus trap, no Escape-to-close, and no focus move on open or focus return on close.
**Rationale**: Keeps the component a lightweight, always-present layer suited to being toggled behind a persistent surface such as chat. The tradeoff is that the closed state's header, close button, and body remain keyboard-focusable and screen-reader-reachable (see the [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) check in Compliance) until the source adds `inert`/`aria-hidden` gating.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The close button is a native `<button>` (dynamic-type via `rem` sizing), but keyboard-navigable is partial because a closed, invisible overlay keeps its close button in the tab order (see the non-modal Design Decision), and the source defines no fallback accessible name for an empty `closeLabel`, no `prefers-reduced-motion` gating for the root's opacity transition, no explicit touch-target sizing or resolvable contrast values (colors depend on unresolved `--text-muted`/`--accent` custom properties), no landmark or region label on the overlay container (it is deliberately non-modal, so it has no dialog role), and no focus containment when closed (see the non-modal Design Decision) — and the default `closeLabel` of `'← back'` is a hardcoded, non-externalized English string. separation-of-concerns passes because `ContentOverlay.tsx` is a stateless controlled component that toggles CSS classes from its `open` prop with no business logic of its own, and unit-test-coverage is partial because `ContentOverlay.test.tsx` covers vectors overlay-001 to 011 and 013, but overlay-012 (Enter on the focused close button while closed) is skipped since jsdom does not synthesize a native button's Enter-to-click activation.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-11-14 | Mike Fullerton | Lint fixes: split closed-invisible from closed-non-interactive and narrowed the latter to pointer input, downgraded keyboard-navigable and unit-test-coverage to partial, rebased semantic-markup on a real gap, linked the focus-management check, added keyboard and className vectors, fixed overlay-005, gave native ports accessibility-hiding guidance and a concrete Compose modifier, and noted RTL arrow mirroring. |
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and promoted className to MUST; added tags and a related link to persona-chat; reformatted Design Decisions and added one documenting the non-modal tradeoff; built the Compliance table; resolved the missing-onClose edge-case contradiction; corrected the Reduce Motion and Responsive claims; rewrote the native Platform Notes as full-bleed overlays instead of modal dialogs; added test vectors for empty label, rapid clicks, and null children; and reworded the render-structure requirement and Localization/Accessibility Options sections around observable behavior |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Filled Appearance and States from content-overlay.css; dropped the review marker |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
