---
id: c10a6fd9-470a-45a1-a025-3c75554c2a41
title: ViewportComposer
domain: adhsdk://recipes/viewport-composer
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Bottom-anchored container that lifts above the on-screen keyboard and respects
  safe-area insets.
platforms:
- typescript
- web
tags:
- viewport
- keyboard
- safe-area
depends-on:
- adhsdk://recipes/viewport-shell
related:
- adhsdk://recipes/viewport-shell
- adhsdk://recipes/viewport-spacer
references: []
approved-by: ''
approved-date: ''
---

# ViewportComposer

## Overview

ViewportComposer is a container component that anchors to the bottom of a ViewportShell, lifting above the on-screen keyboard automatically and respecting platform safe-area insets. It is used to render persistent controls (typically input composition or action buttons) that remain accessible while the keyboard is visible.

## Behavioral Requirements

- **render-children**: Component MUST render its children as direct descendants, in document order, with no wrapper element inserted around them.
- **compose-classname**: Component MUST accept an optional `className` prop. When provided, the rendered element's `class` attribute MUST contain both the internal `vp-composer` class and the provided `className`, space-separated; when omitted, only `vp-composer` MUST appear.
- **adjust-bottom-padding**: Component MUST set its bottom padding to `calc(var(--kb-inset) + env(safe-area-inset-bottom))` (implemented as `calc(var(--kb-inset) + var(--safe-bottom))`, with `--safe-bottom` resolving `env(safe-area-inset-bottom, 0px)`) so it lifts above the keyboard and respects the home indicator, animating the change over 180ms ease-out.
- **kb-inset-read-only**: Component MUST read the `--kb-inset` custom property but MUST NOT set it. The value is written by `useKeyboardInset()`, which the parent `ViewportShell` mounts; see adhsdk://recipes/viewport-shell (the **keyboard-inset** requirement) — `useKeyboardInset` is not itself a separate recipe.

## Appearance

- **Background**: Transparent; the component sets no background or border of its own.
- **Padding**: Bottom padding is `calc(var(--kb-inset) + var(--safe-bottom))` (see adjust-bottom-padding), animated over 180ms ease-out; left, right, and top padding are not set by the composer itself — add them via `className`.
- **Border**: None; the component sets no border.
- **Width / position / stacking order**: Not owned by ViewportComposer. It renders a plain block `<div>` with no explicit `width` or `position`; its full width and its position at the bottom of the page come from being the last child inside `ViewportShell`'s column-flex layout — see adhsdk://recipes/viewport-shell.
- **Height**: Auto (sized by children and padding)

## States

| State | Appearance change |
|-------|------------------|
| Default | Bottom padding equals `calc(var(--kb-inset) + var(--safe-bottom))`; full width and bottom placement come from ViewportShell's layout, not the composer |
| Keyboard visible | Bottom padding increases as `--kb-inset` grows |
| Safe area present | Bottom padding includes the resolved `--safe-bottom` (`env(safe-area-inset-bottom)`) |

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
| vp-composer-004 | adjust-bottom-padding | Unit test: render `<ViewportComposer>` and read the `padding-bottom` and `transition` declarations applied to `.vp-composer` | `padding-bottom` declaration is `calc(var(--kb-inset) + var(--safe-bottom))`; `transition` includes `padding-bottom 180ms ease-out` |
| vp-composer-005 | adjust-bottom-padding | Playwright: set `--kb-inset: 300px` on the enclosing `ViewportShell` root and measure the composer | Composer's resolved bottom padding equals `300px` plus the device's safe-area-inset-bottom, and its bounding box shifts upward by that amount |
| vp-composer-006 | kb-inset-read-only | Inspect the component's source and its rendered output | ViewportComposer neither imports nor calls `useKeyboardInset()` and sets no inline style or property on `--kb-inset`; the variable's only writer is `useKeyboardInset()`, mounted by `ViewportShell` |

## Edge Cases

- **No children**: Component renders an empty container; padding is still applied.
- **Multiple className strings**: If `className` contains spaces or multiple class names, all are preserved in the output.
- **Base stylesheet not loaded**: `--kb-inset` and `--safe-bottom` are defined only by `:root` rules in the package's `base.css` (imported once at the app root per the package's setup instructions). If a consumer renders `ViewportComposer` without importing that stylesheet, both properties are genuinely undefined, the whole `calc()` becomes invalid, and the browser drops the `padding-bottom` declaration entirely — the composer then gets no bottom padding at all, not a padding of `0`. When `base.css` is loaded, `--kb-inset` defaults to `0px` and `--safe-bottom` resolves `env(safe-area-inset-bottom, 0px)`, so both terms are always valid and the `calc()` never breaks.
- **Safe area not present (unsupported browser)**: On browsers without `env()` support for `safe-area-inset-bottom`, `--safe-bottom` falls back through its own `env(safe-area-inset-bottom, 0px)` declaration to `0px`; the component continues to function with keyboard-only padding.
- **Missing `viewport-fit=cover`**: `env(safe-area-inset-bottom)` only reports a non-zero value when the page's viewport meta tag includes `viewport-fit=cover` (documented in the package's required HTML/Next.js setup). None of `ViewportShell`, `ViewportSpacer`, or `ViewportComposer` set this meta tag; providing it is the consuming app's responsibility.
- **Children unmount/remount**: Component preserves its positioning and padding through child updates.

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

- **Web**: Render as a `<div>` with class `vp-composer`. Bottom padding is `calc(var(--kb-inset) + var(--safe-bottom))`, where `--kb-inset` defaults to `0px` and `--safe-bottom` resolves `env(safe-area-inset-bottom, 0px)` — both declared at `:root` by the package's `base.css`. `--kb-inset` is written by `useKeyboardInset()`, mounted by the parent `ViewportShell`; ViewportComposer only reads it (see **kb-inset-read-only**). No `position` is set on `.vp-composer`; the composer's width and its position at the bottom of the page come from being the last child in `ViewportShell`'s column-flex layout.
- **SwiftUI**: Compose using a `ZStack` with `.frame(maxWidth: .infinity, alignment: .bottom)`, or a `VStack` preceded by a `Spacer()`. Rely on SwiftUI's built-in keyboard avoidance, or opt in explicitly with `.safeAreaInset(edge: .bottom) { composerContent }`, which insets the content above both the keyboard and the home indicator without any manual keyboard-height tracking.
- **Compose**: Use `Box(Modifier.fillMaxWidth().imePadding())`, or `Modifier.windowInsetsPadding(WindowInsets.ime.union(WindowInsets.navigationBars))` to lift above the IME and navigation bar together. Both read the system IME inset directly; no manual keyboard-height observer is needed.
- **AppKit / UIKit**: UIKit — pin the composer's bottom anchor to `keyboardLayoutGuide.topAnchor` so it lifts above the on-screen keyboard automatically, and let `view.safeAreaLayoutGuide` supply the home-indicator inset. AppKit (macOS) — not applicable: macOS has no on-screen software keyboard and no home-indicator safe area, so the composer needs no keyboard or safe-area handling there.
- **WinUI 3**: Use `StackPanel` with `VerticalAlignment="Bottom"`. `InputPane.GetForCurrentView()` is UWP-only and unavailable in a WinUI 3 desktop app; resolve the input pane instead via the window-handle interop `InputPaneInterop.GetForWindow(hwnd)` (or observe `CoreInputView` for text-entry-triggered visibility), and bind its `Showing`/`Hiding` occluded-rect height to the panel's bottom `Margin` alongside any window-chrome safe-area inset.

## Design Decisions

**Decision**: ViewportComposer delegates keyboard-height tracking to its parent, reading the `--kb-inset` CSS custom property instead of observing the keyboard itself.
**Rationale**: Keeps the composer a simple, stateless container that responds to external state rather than managing its own keyboard observer, avoiding duplicate keyboard-tracking logic across components (see **kb-inset-read-only**) and simplifying testing and composition.
**Approved**: pending

**Decision**: Safe-area insets are read through the standard CSS environment variable (via `--safe-bottom`) rather than passed as a prop or tracked in JavaScript.
**Rationale**: Follows the same "read external state, don't own it" pattern used for the keyboard inset; the browser already exposes `env(safe-area-inset-bottom)`, so no additional plumbing is needed.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

keyboard-navigable and semantic-markup pass because the source renders a single plain `<div>` with no `tabIndex`, ARIA role, or focus-trapping logic; reduced-motion fails because `base.css` transitions `padding-bottom` over 180ms unconditionally, with no `prefers-reduced-motion` guard. `separation-of-concerns` passes because the component is pure presentation over `children`/`className` with no business logic; `unit-test-coverage` fails because no test exercises it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: replace nonexistent Platform Notes APIs with real mechanisms; rename requirements to subject-only kebab-case and merge the duplicate classname requirements/vectors; add a kb-inset-read-only requirement plus ViewportShell/useKeyboardInset dependencies; split the untestable keyboard vector into a unit test and a Playwright test; correct the base-stylesheet and safe-area-prerequisite edge cases; reformat Design Decisions into Decision/Rationale/Approved blocks; and replace "Not applicable" Compliance with a real table |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Dropped the dangling URI of the never-written use-keyboard-inset recipe from depends-on, related, and kb-inset-read-only; pointed to viewport-shell's keyboard-inset requirement instead. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
