---
id: 8f2e4a12-7c3b-4d9f-a1e2-6b5f9c1d3e4a
title: "Toast"
type: ingredient
version: 1.1.3
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Transient notification displayed in a fixed viewport at the bottom-right corner with optional dismiss button."
platforms:
  - typescript
  - web
tags:
  - notification
  - toast
depends-on: []
related:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/98c5c5c2-5a45-4425-97b7-31932cb6af0c
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/70f2ab2f-a05f-4981-9fea-e9d169fc1753
references: []
approved-by: ""
approved-date: ""
---

# Toast

## Overview

A toast is a transient, non-modal notification displayed in a fixed viewport at the bottom inline-end corner of the viewport (bottom-right in left-to-right locales). It conveys brief messages with optional title and description text, and allows the user to dismiss it via a close button. Toasts are enqueued and rendered as a stacked list.

## Behavioral Requirements
- **render-title**: Toast MUST render a title element when provided.
- **render-description**: Toast MUST render a description element when provided.
- **render-close-button**: Toast MUST render a clickable close button.
- **dismiss-on-close**: Toast MUST dismiss and remove itself from the viewport when the close button is clicked.
- **enqueue-toasts**: The `useToast()` hook MUST accept objects with `title` and `description` properties and enqueue them for display.
- **position-viewport-bottom-right**: The toast viewport MUST be positioned at the bottom inline-end corner of the viewport (1rem from the inline-end edge, which is the right edge in left-to-right locales, and 1rem from the bottom edge); the source uses `fixed end-4 bottom-4`, so it mirrors in right-to-left locales.
- **manage-z-index**: The toast viewport MUST render at z-index 50 (above typical page content).
- **animate-entrance**: Toasts MUST fade in smoothly (opacity transition from 0 to 1) on entrance.
- **animate-exit**: Toasts MUST fade out smoothly (opacity transition to 0) when dismissed.
- **stack-toasts**: Multiple toasts MUST render in a vertical stack with 0.5rem gap between each.
- **constrain-width**: Each toast MUST have a fixed width of 320px, capped to (viewport width − 2rem) when the viewport is narrower than 320px plus margins.
- **localize-close-label**: The close button's dismiss label MUST be localized for the active locale; `Toaster` takes a `closeLabel` prop (default `"Close"`) that callers pass their localized string through.
- **enlarge-close-hit-area**: The close button SHOULD provide a hit area of at least 44×44pt, independent of the visible icon size; the source renders it as an `inline-flex size-11` (44×44) button at `top-0 end-0` with the 16px icon centred, and the toast root's `pe-11` keeps text clear of it.
- **respect-reduced-motion**: Toasts SHOULD disable or shorten the opacity fade when the system reduced-motion preference is enabled; the toast root and the close button carry `motion-reduce:transition-none`.
- **independent-provider-queues**: Each `ToastProvider` instance MUST manage its own toast queue independently.
- **auto-dismiss-timeout**: A toast MUST close itself after a timeout, 5000ms by default, and the countdown MUST pause while the toast is hovered or holds focus.
- **dismiss-on-escape**: Pressing Escape while focus is inside a toast MUST dismiss it.
- **dismiss-on-swipe**: A toast MUST be dismissible by swiping it down or to the right past a 40px threshold.
- **set-explicit-limit**: Implementations SHOULD pass an explicit `limit` to `ToastProvider` to bound the number of simultaneously visible toasts.
- **use-design-tokens**: Implementations MUST use the design tokens `apt-text-muted`, `apt-text` and `apt-gold/40` for the close button's rest, hover and focus-ring colors, and MUST NOT hardcode a color value.
## Appearance

- **Corner radius**: 0.5rem
- **Padding**: 1rem vertical × 1rem horizontal, with 2.75rem on the inline-end side (`pe-11`) to accommodate the close button
- **Font (title)**: weight 500, size 0.875rem
- **Font (description)**: size 0.875rem
- **Background**: design token `apt-surface-2`
- **Foreground/Text**: design token `apt-text` for title and primary text; `apt-text-muted` for description
- **Border**: 1px solid, color `apt-border`
- **Shadow**: drop shadow, large blur radius
- **Gap between title and description**: 0.25rem
- **Close button**: 44×44px hit area (`inline-flex size-11`) with a centred 1rem icon, positioned absolute at the toast's top and inline-end edges (`top-0 end-0`), color `apt-text-muted` at rest, color `apt-text` on hover

## States

| State | Appearance change |
|-------|------------------|
| Default | Fully opaque (opacity 1), border and background visible, title and description rendered |
| Hovered (close button) | Close button text color transitions to `apt-text` |
| Focused (close button) | Close button displays focus ring: 2px ring at `apt-gold/40` opacity |
| Entering | Opacity animates from 0 to 1 on mount |
| Exiting | Opacity animates to 0 before removal |

## Accessibility

- **Role**: The toast root renders `role="dialog"` by default (Base UI `ToastPrimitive.Root`); it only escalates to `role="alertdialog"` when a toast is added with `priority: 'high'`, which this source's `useToast().add({ title, description })` calls do not set. The viewport (`ToastPrimitive.Viewport`) renders `role="region"`, `aria-live="polite"`, and `aria-label="Notifications"`.
- **Close button label**: MUST be localized (see **localize-close-label**); `Toaster` takes a `closeLabel` prop (default `"Close"`) that becomes the close button's `aria-label`, and callers pass their localized string.
- **Focus management**: Close button MUST be keyboard-focusable and dismissible via the Enter or Space key (it is a native `<button>` element per Base UI's `ToastPrimitive.Close`). The source also inherits Base UI's default Escape-to-dismiss behavior: pressing Escape while focus is inside the toast closes it, the same as activating Close (see the Design Decision on dismissal below). The viewport is reachable via the F6 landmark shortcut or Tab, and focus is redirected to the frontmost dismissible toast when the viewport receives focus.
- **Minimum tap target**: See **enlarge-close-hit-area**. The source renders the Close control as an absolutely-positioned `inline-flex size-11` button (44×44 CSS px) at `top-0 end-0`, with the 16px icon centred in it.
- **Announcement**: Toast entry is announced through the viewport's `aria-live="polite"` region (see Role above); Base UI's `aria-relevant="additions text"` announces newly added toasts and changes to their text, and does not announce removals.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| toast-001 | render-title | `useToast().add({ title: "Success" })` | Toast renders containing "Success" in title element |
| toast-002 | render-description | `useToast().add({ description: "Operation complete" })` | Toast renders containing "Operation complete" in description element |
| toast-003 | render-close-button | Toast rendered in viewport | Close button with X icon is visible and clickable |
| toast-004 | dismiss-on-close | User clicks close button | Toast animates out and is removed from viewport |
| toast-005 | enqueue-toasts | `useToast().add({ title: "Alert" })` called inside ToastProvider subtree | Toast appears in viewport |
| toast-006 | position-viewport-bottom-right | Viewport rendered in page | Viewport is positioned 1rem from the inline-end edge (right in left-to-right locales) and 1rem from the bottom edge of window (`fixed end-4 bottom-4`) |
| toast-007 | manage-z-index | Toast viewport and multiple page layers present | Toast viewport appears above other content at z-index 50 |
| toast-008 | animate-entrance | Toast added to queue | Toast element opacity transitions from 0 to 1 over transition duration |
| toast-009 | animate-exit | Close button clicked | Toast element opacity transitions to 0 over transition duration before removal |
| toast-010 | stack-toasts | Multiple toasts enqueued | Each toast renders below the previous with 0.5rem vertical spacing |
| toast-011 | constrain-width | Toast rendered at viewport width 1024px | Toast displays at a fixed width of 320px |
| toast-012 | constrain-width | Toast rendered at viewport width 320px | Toast width is capped to calc(100vw - 2rem) (32px total margin), narrower than the 320px fixed width |
| toast-013 | independent-provider-queues | Two `ToastProvider` instances mounted in separate subtrees, each with its own `useToast().add(...)` call | Each provider's viewport shows only the toasts added through its own `useToast()` instance |
| toast-014 | localize-close-label | `<Toaster closeLabel="Fermer" />` and a toast added | the close button's accessible label is `Fermer`; no button is labelled `Close` |
| toast-015 | respect-reduced-motion | Toast added; inspect the toast root and close button classes (jsdom has no media queries) | Both carry `motion-reduce:transition-none`, so the fade is disabled under reduced motion |
| toast-016 | enlarge-close-hit-area | Inspect the close button's classes | The close button is `inline-flex size-11` (44×44 CSS px) at `top-0 end-0` with the icon centred, and the toast root uses `pe-11` so text clears it |
| toast-017 | position-viewport-bottom-right | Render the viewport in a right-to-left locale | The viewport uses `end-4` (1rem from the inline-end edge, the left edge in RTL) and the close button uses `end-0`, so both mirror |
| toast-018 | auto-dismiss-timeout | Add a toast and wait 5000ms without hovering or focusing it | The toast closes itself |
| toast-019 | auto-dismiss-timeout | Add a toast and hover it for longer than 5000ms | The toast stays open until the pointer leaves |
| toast-020 | dismiss-on-escape | Focus inside a toast and press Escape | The toast is dismissed |
| toast-021 | dismiss-on-swipe | Drag a toast down past 40px | The toast is dismissed |
| toast-022 | set-explicit-limit | Mount `ToastProvider` with `limit={2}` and add three toasts | Two toasts are visible; the oldest is marked `data-limited` |
| toast-023 | use-design-tokens | Inspect the close button's color classes | Colors come from `apt-text-muted`, `apt-text` and `apt-gold/40`; no hardcoded color value |
## Edge Cases

- **Empty title and description**: Toast renders with no title or description content; only close button visible. MUST NOT error.
- **Very long title text**: Title text MUST wrap to multiple lines and remain readable; no text truncation or overflow.
- **Very long description text**: Description text MUST wrap to multiple lines; container height expands to fit content.
- **Close button rapid clicks**: Rapid clicks on close button MUST dismiss toast once (no double-dismiss error); subsequent clicks on dismissed toast MUST have no effect.
- **Viewport overflow (many toasts)**: The viewport is a fixed flex container with vertical layout and no overflow scrolling defined in the source. Base UI's `ToastProvider` accepts a `limit` prop that caps the number of simultaneously visible toasts (marking the rest `data-limited` and excluding them from keyboard focus), but this component does not set one, so the cap is the library's default of 3 rather than a value this recipe controls (see **set-explicit-limit**).
- **Viewport near right or bottom edge**: When rendered near right or bottom edges, toast MUST respect max-width and not overflow window; responsive max-width constraint ensures this.
- **Multiple providers in same app**: See **independent-provider-queues** (toast-013). Each `ToastProvider` instance reads and writes only its own React context, so nested or sibling providers never share a queue.

## Configuration

`ToastProvider` is Base UI's provider, re-exported unchanged, and accepts two options that matter here, and `Toaster` takes one prop, `closeLabel`. The viewport position and toast dimensions are fixed.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `limit` | number | 3 | Maximum number of simultaneously visible toasts; older toasts beyond it are marked `data-limited`. This ingredient recommends passing it explicitly (see **set-explicit-limit**). |
| `timeout` | number (ms) | 5000 | How long a toast stays before closing itself (see **auto-dismiss-timeout**). |
| `closeLabel` (`Toaster`) | string | `"Close"` | The close button's `aria-label`; pass the localized string (see **localize-close-label**). |

Consumers supply content with `useToast().add({ title, description })`.
## Deep Linking

Not applicable: Toast is a transient, non-navigable UI element with no persistent state or deep-link target.

## Localization

- **Close button aria-label**: MUST be localized per **localize-close-label**. `Toaster` takes `closeLabel?: string` (default `"Close"`) and applies it as the close button's `aria-label`; callers pass their localized string, the package's label-prop convention (as `cancelLabel` in dialog-actions). Layout mirrors in right-to-left locales: the viewport uses `end-4` and the close button `end-0`.

## Accessibility Options

- **Reduce Motion**: The source uses CSS `transition-all` on the toast root and `transition-colors` on the close button, and does not read or respond to the `prefers-reduced-motion` media query — transitions are always applied. See **respect-reduced-motion**.
- **increase-contrast**: NEEDS REVIEW: Not implemented in source. Close button colors use the tokens `apt-text-muted` (rest), `apt-text` (hover) and `apt-gold/40` (focus ring), as **use-design-tokens** requires, and no color value is hardcoded, but neither `toast.tsx` nor a single fixed theme settles whether `apt-text-muted`, `apt-text`, and `apt-gold/40` clear WCAG AA contrast (4.5:1 for text, 3:1 for graphics) against `apt-surface-2`: the themes package resolves these tokens to different underlying colors across each of its theme stylesheets, and some of those stylesheets (e.g. `dev-team.css`'s `--color-text-secondary`) already carry a "nudged for AA" comment showing the margin is theme-specific, so the ratio depends on which theme is active. The active theme's resolved token values, run through a contrast checker, would settle it.
- **Differentiate Without Color**: The close button's 2px focus ring is an outline, so keyboard focus is shown by a shape as well as by its `apt-gold/40` color. The hover state relies only on the color change from `apt-text-muted` to `apt-text`, with no non-color indicator such as a border or text styling change.

## Feature Flags

Not applicable: Toast component has no feature flags; it is always enabled when `Toaster` is rendered.

## Analytics

Not applicable: Toast component does not emit analytics events in source code.

## Privacy

Not applicable: Toast component does not collect, store, or transmit any personal data. Title and description are caller-provided and not retained after dismissal.

## Logging

Not applicable: Toast component does not emit logs in source code.

## Platform Notes

- **React/Web**: Implemented using Base UI React toast primitives (`@base-ui/react/toast`), exporting `ToastProvider`, `Toaster`, and `useToast`. Styling uses Tailwind CSS utility classes — `w-80` and `max-w-[calc(100vw-2rem)]` for width, `p-4`/`pe-11` for padding, `size-11` with `top-0`/`end-0` for the 44×44 close button and `fixed end-4 bottom-4` for the viewport (logical edges, so both mirror in right-to-left locales), `motion-reduce:transition-none` on the root and close button, a `closeLabel` prop on `Toaster` for the close button's `aria-label`, `gap-2` for the viewport stack gap, `gap-1` for the title/description gap, `rounded-lg` for corner radius, `shadow-lg` for the drop shadow, `font-medium`/`text-sm` for typography, and `size-4` for the close icon — plus design tokens (`apt-border`, `apt-surface-2`, `apt-text`, `apt-text-muted`, `apt-gold/40`). Entrance/exit animation is driven by Base UI's `data-starting-style`/`data-ending-style` attributes, mapped to `opacity-0` via Tailwind's data-attribute variants.
- **SwiftUI**: Implement using a custom overlay view — not `Notification` or `ProgressView`, neither of which is a toast view — aligned to `.bottomTrailing` within a `ZStack`/overlay, with `.transition(.opacity)` driving entrance/exit. Manage the toast queue in an `@Observable` model (the Observation framework, introduced in Swift 5.9 for iOS 17 and macOS 14, which replaces `ObservableObject` and `@ObservedObject`).
- **Compose**: Implement with a custom `Composable` per toast (Material 3's `Snackbar` shows one message at a time, so it does not give a stack), using `Modifier.pointerInput()` with `detectDragGestures` for swipe dismissal. Position using `Modifier.align(Alignment.BottomEnd)` within a Box with `Modifier.fillMaxSize()`. Keep the queue in a `mutableStateListOf<Toast>()` held by a state holder; dismissing removes the item from the list, and a `LaunchedEffect` delay per toast supplies the auto-dismiss timeout.
- **AppKit / UIKit**: Implement as a composed container — an `NSStackView` (macOS) or `UIStackView` (iOS) hosted by a plain view controller — rather than an `NSView`/`UIView` subclass. Use `CABasicAnimation` on `opacity` for entrance/exit transitions, and `NSLayoutConstraint`/Auto Layout to pin the container to the bottom-right corner. Manage the toast queue in the hosting view controller or a dedicated state object, not the container view itself.
- **WinUI 3**: Implement using `InfoBar` items hosted in a bottom-right overlay — an `ItemsControl` with a `StackPanel` `ItemsPanelTemplate` inside a `Grid` with `HorizontalAlignment="Right"` and `VerticalAlignment="Bottom"` — rather than a `TeachingTip` (an anchored callout, not a stacked notification) or `PART_PopupRoot` (not a hosting surface an app can target). Set `IsOpen` and handle each `InfoBar`'s `CloseButtonClick` event for dismissal. Use `DoubleAnimation` on `Opacity` for fade transitions, and theme resources such as `CardBackgroundFillColorDefaultBrush` for the surface background and `TextFillColorPrimaryBrush` for text (not the invalid `SystemControlForeground`).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/toast.tsx` | confirmed (1.1.3) |

## Design Decisions

**Decision**: Position the toast viewport at the bottom inline-end corner (bottom-right in left-to-right locales, via `end-4`) rather than top-center or full-width.
**Rationale**: Avoids blocking critical interface elements and keeps toasts out of the visual center; bottom-right is a common placement for transient system notifications in desktop web applications, distinct from primary content and navigation regions.
**Approved**: pending

**Decision**: Use opacity-only animation for entrance and exit rather than slide-out or scale-down.
**Rationale**: A fade is one visual property and involves no movement, so there is no slide or scale to distract from the page. The source applies it with `transition-all` on the toast root, which animates every property rather than opacity alone.
**Approved**: pending

**Decision**: Render the toast through `ToastPrimitive.Portal`.
**Rationale**: Escapes the local DOM hierarchy, preventing stacking-context issues and keeping z-index management consistent.
**Approved**: pending

**Decision**: Rely on Base UI's default dismiss behaviors rather than overriding them: the source re-exports `ToastPrimitive.Provider` and `ToastPrimitive.Root` with no `timeout` or `swipeDirection` override, so in addition to clicking Close, a toast auto-closes after Base UI's default 5000ms timeout (paused while hovered or focused), closes on Escape when focus is inside it, and can be swiped away (down or right, past a 40px threshold); these are specified as **auto-dismiss-timeout**, **dismiss-on-escape** and **dismiss-on-swipe**.
**Rationale**: Adopting Base UI's defaults gives users several independent ways to dismiss a toast without the component reimplementing any of them; the Close button remains available as an explicit, discoverable control for users who prefer not to wait, swipe, or use the keyboard.
**Approved**: pending

**Decision**: Reference design tokens (`apt-surface-2`, `apt-text`, `apt-gold/40`, etc.) for background, text, and focus-ring colors rather than hardcoded hex values.
**Rationale**: Enables consistent theming across the application.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on the `closeLabel` prop that sets the close button's `aria-label` (default `"Close"`; callers pass the localized string), the 44×44 `size-11` close button, Base UI's default `role`/`aria-live` assignment, `motion-reduce:transition-none` on the toast root and close button, and the logical `end-4`/`bottom-4`/`end-0` positioning that mirrors in RTL. `separation-of-concerns` is passed because `toast.tsx` is pure presentation — layout and styling wrapped around `@base-ui/react/toast`'s primitives, with all toast state (queueing, timing, dismissal) owned by that library, none of it in this file; `unit-test-coverage` is partial: `toast.test.tsx` covers 19 of the 23 vectors; the remaining skips are toast-008, toast-009, toast-011 and toast-012, because jsdom has no layout or CSS transitions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.3 | 2026-11-14 | Mike Fullerton | Added named requirements and vectors for auto-dismiss, Escape, swipe, explicit limit, design tokens, reduced motion and hit area, restated position in logical edges with an RTL vector, stated newest-on-top stacking, listed provider options in Configuration, merged the Increase Contrast marker, and corrected the announcement, focus-ring, Observation and Compose notes. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Corrected dismissal claims: Base UI 5000ms auto-dismiss, Escape-dismiss, and swipe-dismiss are real; Decision and Focus management rewritten. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: fix the viewport offset (4rem → 1rem) and the false 44×44 touch-target claim, remove the unsupported Material Design citation, drop unimplemented auto-dismiss from the exit vector, replace AppKit/UIKit subclassing guidance with composition, correct the SwiftUI and WinUI 3 platform notes, name the toast's actual ARIA roles and live-region politeness, require Space alongside Enter for Close dismissal and state that Escape does not dismiss, require a localized Close label, add a reduced-motion requirement, specify overflow behavior via the Provider's limit prop, rebuild Compliance as a table, reformat Design Decisions, move Tailwind class names into the React/Web platform note, clarify the fixed-vs-capped toast width, add related cross-references, rename all requirements to drop the must-/should- prefix, and add conformance vectors for per-provider queue isolation and the localized Close label |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Revise accessibility sections and edge cases: document hard-coded Close label, add Reduce Motion fact, clarify Differentiate Without Color limitation, state viewport overflow behavior, reword Compliance as Not applicable |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
