---
id: c10a6fd9-470a-45a1-a025-3c75554c2a41
title: "ViewportComposer"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Bottom-anchored container that lifts above the on-screen keyboard and respects safe-area insets."
platforms:
  - typescript
  - web
tags:
  - viewport
  - keyboard
  - safe-area
depends-on:
  - 960a1577-bf48-4d56-a93f-aa690853f64f
related:
  - 556f7dbf-2a14-4e97-aaa2-0954c7488e6f
references: []
approved-by: ""
approved-date: ""
---

# ViewportComposer

## Overview

ViewportComposer is a container component that anchors to the bottom of a ViewportShell, lifting above the on-screen keyboard automatically and respecting platform safe-area insets. It is used to render persistent controls (typically input composition or action buttons) that remain accessible while the keyboard is visible.

## Behavioral Requirements

- **render-children**: Component MUST render its children as direct descendants, in document order, with no wrapper element inserted around them.
- **compose-classname**: Component MUST accept an optional `className` prop. When provided, the rendered element's `class` attribute MUST contain both the internal `vp-composer` class and the provided `className`, space-separated; when omitted, only `vp-composer` MUST appear.
- **adjust-bottom-padding**: Component MUST set its bottom padding to `calc(var(--kb-inset) + env(safe-area-inset-bottom))` (implemented as `calc(var(--kb-inset) + var(--safe-bottom))`, with `--safe-bottom` resolving `env(safe-area-inset-bottom, 0px)`) so it lifts above the keyboard and respects the home indicator.
- **animate-bottom-padding**: Component MUST animate changes to its bottom padding with `transition: padding-bottom 180ms ease-out` (declared on `.vp-composer` in `base.css`).
- **kb-inset-read-only**: Component MUST read the `--kb-inset` custom property but MUST NOT set it. The value is written by `useKeyboardInset()`, which the parent `ViewportShell` mounts; see [adhsdk.ingredient.viewport.viewport-shell](cookbook:960a1577-bf48-4d56-a93f-aa690853f64f) (the **keyboard-inset** requirement) — `useKeyboardInset` is not itself a separate recipe.

## Appearance

- **Background**: Transparent; the component sets no background or border of its own.
- **Padding**: Bottom padding follows **adjust-bottom-padding** and animates per **animate-bottom-padding**; left, right, and top padding are not set by the composer itself — add them via `className`.
- **Border**: None; the component sets no border.
- **Width / position / stacking order**: Not owned by ViewportComposer. It renders a plain block `<div>` with no explicit `width` or `position`; its full width and its position at the bottom of the page come from being the last child inside `ViewportShell`'s column-flex layout — see [adhsdk.ingredient.viewport.viewport-shell](cookbook:960a1577-bf48-4d56-a93f-aa690853f64f).
- **Height**: Auto (sized by children and padding)

## States

| State | Appearance change |
|-------|------------------|
| Default | Bottom padding per **adjust-bottom-padding**; full width and bottom placement come from ViewportShell's layout, not the composer |
| Keyboard visible | Bottom padding increases as `--kb-inset` grows |
| Safe area present | Bottom padding includes the safe-area term of **adjust-bottom-padding** |

## Accessibility

- Role: Generic container (`div`)
- Children inherit accessibility semantics from their own markup
- Component itself is transparent to assistive technology; focus moves directly to interactive children
- Keyboard navigation is not blocked by the container

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| vp-composer-001 | render-children | `<ViewportComposer><button>Send</button></ViewportComposer>` | Button element renders as the sole child of the container, at the same position it was passed, with no wrapper element inserted |
| vp-composer-002 | compose-classname | `<ViewportComposer className="custom-class">Text</ViewportComposer>` | Rendered element's class attribute is `vp-composer custom-class` |
| vp-composer-003 | compose-classname | `<ViewportComposer>Text</ViewportComposer>` (no `className`) | Rendered element's class attribute is `vp-composer` only |
| vp-composer-004 | adjust-bottom-padding | Unit test: render `<ViewportComposer>` and read the `padding-bottom` declaration applied to `.vp-composer` | `padding-bottom` declaration is `calc(var(--kb-inset) + var(--safe-bottom))` |
| vp-composer-007 | animate-bottom-padding | Unit test: read the `transition` declaration applied to `.vp-composer` | `transition` includes `padding-bottom 180ms ease-out` |
| vp-composer-005 | adjust-bottom-padding | Playwright: set `--kb-inset: 300px` on the enclosing `ViewportShell` root and measure the composer | `getComputedStyle(composer).paddingBottom` equals `300px` plus the device's safe-area-inset-bottom, and the first child's `top` moves up by the same amount |
| vp-composer-006 | kb-inset-read-only | Static check of `ViewportComposer.tsx`, plus render `<ViewportComposer>Text</ViewportComposer>` | The source has no import or call of `useKeyboardInset`; the rendered element has no `style` attribute touching `--kb-inset` |
| vp-composer-008 | render-children | `<ViewportComposer />` rendered with no children (untyped caller) | An empty `div.vp-composer` renders; its `padding-bottom` is still the declared value |
| vp-composer-009 | compose-classname | `<ViewportComposer className="a b">Text</ViewportComposer>` | Rendered element's class attribute is `vp-composer a b` |
| vp-composer-010 | adjust-bottom-padding | Render `<ViewportComposer>` in a page that does not load `base.css` and read the computed `padding-bottom` | Computed `padding-bottom` is `0px` (no rule applies), and `transition-property` is not `padding-bottom` |

## Edge Cases

- **No children**: `children` is required by the component's type, but an untyped caller that omits it gets an empty container; padding is still applied.
- **Multiple className strings**: If `className` contains spaces or multiple class names, all are preserved in the output.
- **Base stylesheet not loaded**: `--kb-inset` and `--safe-bottom` are defined only by `:root` rules in the package's `base.css` (imported once at the app root per the package's setup instructions). Without that stylesheet the `.vp-composer` rule itself is also absent, so the composer gets no bottom padding and no transition at all, not a padding of `0`. With `base.css` loaded, both terms of **adjust-bottom-padding** are always valid.
- **Safe area not present (unsupported browser)**: On browsers without `env()` support for `safe-area-inset-bottom`, `--safe-bottom` falls back to `0px`; the component continues to function with keyboard-only padding.
- **Missing `viewport-fit=cover`**: `env(safe-area-inset-bottom)` only reports a non-zero value when the page's viewport meta tag includes `viewport-fit=cover` (documented in the package's required HTML/Next.js setup). None of `ViewportShell`, `ViewportSpacer`, or `ViewportComposer` set this meta tag; providing it is the consuming app's responsibility.
- **Children unmount/remount**: The composer's own element and its computed `padding-bottom` are unchanged when its children are replaced.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| children | ReactNode | required | Content to render inside the composer |
| className | string | undefined | Additional CSS class names to apply alongside `vp-composer` |

## Deep Linking

Not applicable: ViewportComposer is a layout container with no navigable identity.

## Localization

Not applicable: ViewportComposer has no text content of its own.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The `padding-bottom` transition (180ms ease-out, defined in `base.css`) runs unconditionally; it is not gated behind `prefers-reduced-motion`. See **reduced-motion** in Compliance. |
| Increase Contrast | Inherits from parent styling; component provides no special behavior |
| Differentiate Without Color | Not applicable; component is a structural container with no color semantics |

## Feature Flags

Not applicable: ViewportComposer is a core layout primitive with no feature-gating requirement.

## Analytics

Not applicable: Component is a structural container; analytics events belong to interactive children.

## Privacy

Not applicable: Component stores and transmits no data.

## Logging

Not applicable: Component has no internal state or error conditions requiring logging.

## Platform Notes

- **Web**: Render as a `<div>` with class `vp-composer`. Bottom padding follows **adjust-bottom-padding**; both custom properties are declared at `:root` by the package's `base.css`. `--kb-inset` is written by `useKeyboardInset()`, mounted by the parent `ViewportShell`; ViewportComposer only reads it (see **kb-inset-read-only**). No `position` is set on `.vp-composer`; the composer's width and its position at the bottom of the page come from being the last child in `ViewportShell`'s column-flex layout.
- **SwiftUI**: Compose using a `ZStack` with `.frame(maxWidth: .infinity, alignment: .bottom)`, or a `VStack` preceded by a `Spacer()`. Rely on SwiftUI's built-in keyboard avoidance, or opt in explicitly with `.safeAreaInset(edge: .bottom) { composerContent }`, which insets the content above both the keyboard and the home indicator without any manual keyboard-height tracking.
- **Compose**: Use `Box(Modifier.fillMaxWidth().imePadding())`, or `Modifier.windowInsetsPadding(WindowInsets.ime.union(WindowInsets.navigationBars))` to lift above the IME and navigation bar together. Both read the system IME inset directly; no manual keyboard-height observer is needed.
- **AppKit / UIKit**: UIKit — pin the composer's bottom anchor to `keyboardLayoutGuide.topAnchor` so it lifts above the on-screen keyboard automatically, and let `view.safeAreaLayoutGuide` supply the home-indicator inset. AppKit (macOS) — not applicable: macOS has no on-screen software keyboard and no home-indicator safe area, so the composer needs no keyboard or safe-area handling there.
- **WinUI 3**: Use `StackPanel` with `VerticalAlignment="Bottom"`. `InputPane.GetForCurrentView()` is UWP-only and unavailable in a WinUI 3 desktop app; resolve the input pane instead via the COM window-handle interop `IInputPaneInterop::GetForWindow(hwnd)`, and bind its `Showing`/`Hiding` occluded-rect height to the panel's bottom `Margin` alongside any window-chrome safe-area inset.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/viewport/src/ViewportComposer.tsx` | confirmed (1.1.2) |
| web | `packages/web/packages/viewport/src/css/base.css` | confirmed (1.1.2) |

## Design Decisions

**Decision**: ViewportComposer delegates keyboard-height tracking to its parent, reading the `--kb-inset` CSS custom property instead of observing the keyboard itself.
**Rationale**: Keeps the composer a simple, stateless container that responds to external state rather than managing its own keyboard observer, avoiding duplicate keyboard-tracking logic across components (see **kb-inset-read-only**) and simplifying testing and composition.
**Approved**: pending

**Decision**: Safe-area insets are read through the standard CSS environment variable (via `--safe-bottom`) rather than passed as a prop or tracked in JavaScript.
**Rationale**: Follows the same "read external state, don't own it" pattern used for the keyboard inset; the browser already exposes `env(safe-area-inset-bottom)`, so no additional plumbing is needed.
**Approved**: pending

**Decision**: Accept two failed Compliance checks as known debt for now: the 180ms `padding-bottom` transition is not gated behind `prefers-reduced-motion`, and no unit test exercises the component.
**Rationale**: The transition is declared unconditionally in `base.css` and no test exists in the package for `ViewportComposer`; both are recorded here as work to fix rather than hidden, and the recipe stays in `review` until they are resolved.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

keyboard-navigable and semantic-markup pass because the source renders a single plain `<div>` with no `tabIndex`, ARIA role, or focus-trapping logic; reduced-motion fails because `base.css` transitions `padding-bottom` over 180ms unconditionally, with no `prefers-reduced-motion` guard. `separation-of-concerns` passes because the component is pure presentation over `children`/`className` with no business logic; `unit-test-coverage` is partial because `ViewportComposer.test.tsx` covers every vector except vp-composer-005, which needs a real browser (Playwright) and is skipped.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: replace nonexistent Platform Notes APIs with real mechanisms; rename requirements to subject-only kebab-case and merge the duplicate classname requirements/vectors; add a kb-inset-read-only requirement plus ViewportShell/useKeyboardInset dependencies; split the untestable keyboard vector into a unit test and a Playwright test; correct the base-stylesheet and safe-area-prerequisite edge cases; reformat Design Decisions into Decision/Rationale/Approved blocks; and replace "Not applicable" Compliance with a real table |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Dropped the dangling URI of the never-written use-keyboard-inset recipe from depends-on, related, and kb-inset-read-only; pointed to viewport-shell's keyboard-inset requirement instead. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Split the transition into an animate-bottom-padding requirement, removed repeated padding formulas, recorded the reduced-motion and unit-test failures as a pending Design Decision, clarified the no-children case, reworded vectors 005 and 006, added vectors for edge cases, dropped the duplicate related entry, and removed CoreInputView from the WinUI 3 note. |
