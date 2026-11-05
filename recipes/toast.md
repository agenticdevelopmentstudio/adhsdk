---
id: 8f2e4a12-7c3b-4d9f-a1e2-6b5f9c1d3e4a
title: "Toast"
domain: adhsdk://recipes/toast
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: '2026-09-25'
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
  - adhsdk://recipes/button
  - agenticdevelopercookbook://guidelines/implementing/ui/iconography
  - agenticdevelopercookbook://guidelines/implementing/ui/theming-with-tokens
references: []
approved-by: ''
approved-date: ''
---

# Toast

## Overview

A toast is a transient, non-modal notification displayed in a fixed viewport at the bottom-right of the viewport. It conveys brief messages with optional title and description text, and allows the user to dismiss it via a close button. Toasts are enqueued and rendered as a stacked list.

## Behavioral Requirements

- **render-title**: Toast MUST render a title element when provided.
- **render-description**: Toast MUST render a description element when provided.
- **render-close-button**: Toast MUST render a clickable close button.
- **dismiss-on-close**: Toast MUST dismiss and remove itself from the viewport when the close button is clicked.
- **enqueue-toasts**: The `useToast()` hook MUST accept objects with `title` and `description` properties and enqueue them for display.
- **position-viewport-bottom-right**: The toast viewport MUST be positioned at the bottom-right corner of the viewport (1rem from the right edge, 1rem from the bottom edge).
- **manage-z-index**: The toast viewport MUST render at z-index 50 (above typical page content).
- **animate-entrance**: Toasts MUST fade in smoothly (opacity transition from 0 to 1) on entrance.
- **animate-exit**: Toasts MUST fade out smoothly (opacity transition to 0) when dismissed.
- **stack-toasts**: Multiple toasts MUST render in a vertical stack with 0.5rem gap between each.
- **constrain-width**: Each toast MUST have a fixed width of 320px, capped to (viewport width − 2rem) when the viewport is narrower than 320px plus margins.
- **localize-close-label**: The close button's dismiss label MUST be localized for the active locale.
- **enlarge-close-hit-area**: The close button SHOULD provide a hit area of at least 44×44pt, independent of the visible icon size, since the icon alone does not meet this minimum.
- **respect-reduced-motion**: Toasts SHOULD disable or shorten the opacity fade when the system reduced-motion preference is enabled.
- **independent-provider-queues**: Each `ToastProvider` instance MUST manage its own toast queue independently.

## Appearance

- **Corner radius**: 0.5rem
- **Padding**: 1rem vertical × 1rem horizontal, with 2.25rem on the right to accommodate the close button
- **Font (title)**: weight 500, size 0.875rem
- **Font (description)**: size 0.875rem
- **Background**: design token `apt-surface-2`
- **Foreground/Text**: design token `apt-text` for title and primary text; `apt-text-muted` for description
- **Border**: 1px solid, color `apt-border`
- **Shadow**: drop shadow, large blur radius
- **Gap between title and description**: 0.25rem
- **Close button**: 1rem icon, positioned absolute, offset 0.75rem from the toast's top and right edges, color `apt-text-muted` at rest, color `apt-text` on hover

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
- **Close button label**: MUST be localized (see **localize-close-label**); the source hard-codes `aria-label="Close"` in English, which does not yet satisfy this requirement.
- **Focus management**: Close button MUST be keyboard-focusable and dismissible via the Enter or Space key (it is a native `<button>` element per Base UI's `ToastPrimitive.Close`). The source also inherits Base UI's default Escape-to-dismiss behavior: pressing Escape while focus is inside the toast closes it, the same as activating Close (see the Design Decision on dismissal below). The viewport is reachable via the F6 landmark shortcut or Tab, and focus is redirected to the frontmost dismissible toast when the viewport receives focus.
- **Minimum tap target**: See **enlarge-close-hit-area**. The source renders the Close control as an absolutely-positioned button containing only a 16px icon, with no additional padding shown that would extend the hit area to 44×44pt.
- **Announcement**: Toast entry and exit is announced through the viewport's `aria-live="polite"` region (see Role above); Base UI's `aria-relevant="additions text"` announces newly added toasts and their text content.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| toast-001 | render-title | `useToast().add({ title: "Success" })` | Toast renders containing "Success" in title element |
| toast-002 | render-description | `useToast().add({ description: "Operation complete" })` | Toast renders containing "Operation complete" in description element |
| toast-003 | render-close-button | Toast rendered in viewport | Close button with X icon is visible and clickable |
| toast-004 | dismiss-on-close | User clicks close button | Toast animates out and is removed from viewport |
| toast-005 | enqueue-toasts | `useToast().add({ title: "Alert" })` called inside ToastProvider subtree | Toast appears in viewport |
| toast-006 | position-viewport-bottom-right | Viewport rendered in page | Viewport is positioned 1rem from right edge and 1rem from bottom edge of window |
| toast-007 | manage-z-index | Toast viewport and multiple page layers present | Toast viewport appears above other content at z-index 50 |
| toast-008 | animate-entrance | Toast added to queue | Toast element opacity transitions from 0 to 1 over transition duration |
| toast-009 | animate-exit | Close button clicked | Toast element opacity transitions to 0 over transition duration before removal |
| toast-010 | stack-toasts | Multiple toasts enqueued | Each toast renders below the previous with 0.5rem vertical spacing |
| toast-011 | constrain-width | Toast rendered at viewport width 1024px | Toast displays at a fixed width of 320px |
| toast-012 | constrain-width | Toast rendered at viewport width 320px | Toast width is capped to calc(100vw - 2rem) (32px total margin), narrower than the 320px fixed width |
| toast-013 | independent-provider-queues | Two `ToastProvider` instances mounted in separate subtrees, each with its own `useToast().add(...)` call | Each provider's viewport shows only the toasts added through its own `useToast()` instance |
| toast-014 | localize-close-label | Toast rendered with the active locale set to a non-English locale | Close button's accessible label text matches that locale's localized string, not the hard-coded English word "Close" |

## Edge Cases

- **Empty title and description**: Toast renders with no title or description content; only close button visible. MUST not error.
- **Very long title text**: Title text MUST wrap to multiple lines and remain readable; no text truncation or overflow.
- **Very long description text**: Description text MUST wrap to multiple lines; container height expands to fit content.
- **Close button rapid clicks**: Rapid clicks on close button MUST dismiss toast once (no double-dismiss error); subsequent clicks on dismissed toast MUST have no effect.
- **Viewport overflow (many toasts)**: The viewport is a fixed flex container with vertical layout and no overflow scrolling defined in the source. Base UI's `ToastProvider` accepts a `limit` prop that caps the number of simultaneously visible toasts (marking the rest `data-limited` and excluding them from keyboard focus), but this component does not set one, so the cap is whatever the library defaults to rather than a value this recipe controls. Implementations SHOULD pass an explicit `limit` to `ToastProvider` to bound the stack instead of relying on unconfigured default behavior.
- **Viewport near right or bottom edge**: When rendered near right or bottom edges, toast MUST respect max-width and not overflow window; responsive max-width constraint ensures this.
- **Multiple providers in same app**: See **independent-provider-queues** (toast-013). Each `ToastProvider` instance reads and writes only its own React context, so nested or sibling providers never share a queue.

## Configuration

Not applicable: Toast is rendered via the `Toaster` component with fixed viewport position and dimensions. Consumers configure content via `useToast().add({ title, description })` but not the component's layout or styling.

## Deep Linking

Not applicable: Toast is a transient, non-navigable UI element with no persistent state or deep-link target.

## Localization

- **Close button aria-label**: MUST be localized per **localize-close-label**. The source currently hard-codes the label to the English string "Close" via `aria-label="Close"` with no localization resource lookup, so this requirement is not yet satisfied by the reference implementation.

## Accessibility Options

- **Reduce Motion**: The source uses CSS `transition-all` on the toast root and `transition-colors` on the close button, and does not read or respond to the `prefers-reduced-motion` media query — transitions are always applied. See **respect-reduced-motion**.
- **Increase Contrast**: Close button colors use the design tokens `apt-text-muted` (rest state) and `apt-text` (hover); the focus ring uses `apt-gold/40` opacity. The component hardcodes no color value, so implementations MUST use those tokens — see the open question on increase-contrast.
- **increase-contrast**: NEEDS REVIEW: Not implemented in source. Neither `toast.tsx` nor a single fixed theme settles whether `apt-text-muted`, `apt-text`, and `apt-gold/40` clear WCAG AA contrast (4.5:1 for text, 3:1 for graphics) against `apt-surface-2`: the themes package resolves these tokens to different underlying colors across each of its theme stylesheets, and some of those stylesheets (e.g. `dev-team.css`'s `--color-text-secondary`) already carry a "nudged for AA" comment showing the margin is theme-specific, so the ratio depends on which theme is active. The active theme's resolved token values, run through a contrast checker, would settle it.
- **Differentiate Without Color**: The close button focus indication relies on color change (apt-text-muted to apt-text) and a colored focus ring (apt-gold/40). No non-color visual indicator such as a border, outline, or text styling change is present in the source.

## Feature Flags

Not applicable: Toast component has no feature flags; it is always enabled when `Toaster` is rendered.

## Analytics

Not applicable: Toast component does not emit analytics events in source code.

## Privacy

Not applicable: Toast component does not collect, store, or transmit any personal data. Title and description are caller-provided and not retained after dismissal.

## Logging

Not applicable: Toast component does not emit logs in source code.

## Platform Notes

- **React/Web**: Implemented using Base UI React toast primitives (`@base-ui/react/toast`), exporting `ToastProvider`, `Toaster`, and `useToast`. Styling uses Tailwind CSS utility classes — `w-80` and `max-w-[calc(100vw-2rem)]` for width, `p-4`/`pr-9` for padding, `top-3`/`right-3` for the close button offset, `gap-2` for the viewport stack gap, `gap-1` for the title/description gap, `rounded-lg` for corner radius, `shadow-lg` for the drop shadow, `font-medium`/`text-sm` for typography, and `size-4` for the close icon — plus design tokens (`apt-border`, `apt-surface-2`, `apt-text`, `apt-text-muted`, `apt-gold/40`). Entrance/exit animation is driven by Base UI's `data-starting-style`/`data-ending-style` attributes, mapped to `opacity-0` via Tailwind's data-attribute variants.
- **SwiftUI**: Implement using a custom overlay view — not `Notification` or `ProgressView`, neither of which is a toast view — aligned to `.bottomTrailing` within a `ZStack`/overlay, with `.transition(.opacity)` driving entrance/exit. Manage the toast queue in an `@Observable` model (Swift 6's replacement for `@ObservedObject`/`ObservableObject`).
- **Compose**: Implement using `Snackbar` from Material 3 or custom `Composable` with `Modifier.pointerInput()` for dismiss. Position using `Modifier.align(Alignment.BottomEnd)` within a Box with `Modifier.fillMaxSize()`. Manage queue with `State<List<Toast>>`.
- **AppKit / UIKit**: Implement as a composed container — an `NSStackView` (macOS) or `UIStackView` (iOS) hosted by a plain view controller — rather than an `NSView`/`UIView` subclass. Use `CABasicAnimation` on `opacity` for entrance/exit transitions, and `NSLayoutConstraint`/Auto Layout to pin the container to the bottom-right corner. Manage the toast queue in the hosting view controller or a dedicated state object, not the container view itself.
- **WinUI 3**: Implement using `InfoBar` items hosted in a bottom-right overlay — an `ItemsControl` with a `StackPanel` `ItemsPanelTemplate` inside a `Grid` with `HorizontalAlignment="Right"` and `VerticalAlignment="Bottom"` — rather than a `TeachingTip` (an anchored callout, not a stacked notification) or `PART_PopupRoot` (not a hosting surface an app can target). Set `IsOpen` and handle each `InfoBar`'s `CloseButtonClick` event for dismissal. Use `DoubleAnimation` on `Opacity` for fade transitions, and theme resources such as `CardBackgroundFillColorDefaultBrush` for the surface background and `TextFillColorPrimaryBrush` for text (not the invalid `SystemControlForeground`).

## Design Decisions

**Decision**: Position the toast viewport at the bottom-right corner rather than top-center or full-width.
**Rationale**: Avoids blocking critical interface elements and keeps toasts out of the visual center; bottom-right is a common placement for transient system notifications in desktop web applications, distinct from primary content and navigation regions.
**Approved**: pending

**Decision**: Use opacity-only animation for entrance and exit rather than slide-out or scale-down.
**Rationale**: Minimizes layout thrashing and keeps the animation lightweight.
**Approved**: pending

**Decision**: Render the toast through `ToastPrimitive.Portal`.
**Rationale**: Escapes the local DOM hierarchy, preventing stacking-context issues and keeping z-index management consistent.
**Approved**: pending

**Decision**: Rely on Base UI's default dismiss behaviors rather than overriding them: the source re-exports `ToastPrimitive.Provider` and `ToastPrimitive.Root` with no `timeout` or `swipeDirection` override, so in addition to clicking Close, a toast auto-closes after Base UI's default 5000ms timeout (paused while hovered or focused), closes on Escape when focus is inside it, and can be swiped away (down or right, past a 40px threshold).
**Rationale**: Adopting Base UI's defaults gives users several independent ways to dismiss a toast without the component reimplementing any of them; the Close button remains available as an explicit, discoverable control for users who prefer not to wait, swipe, or use the keyboard.
**Approved**: pending

**Decision**: Reference design tokens (`apt-surface-2`, `apt-text`, `apt-gold/40`, etc.) for background, text, and focus-ring colors rather than hardcoded hex values.
**Rationale**: Enables consistent theming across the application.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | partial | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on the source's hard-coded `aria-label="Close"`, the unpadded 16px close icon as the only hit area, Base UI's default `role`/`aria-live` assignment, the absence of any `prefers-reduced-motion` handling, and the `right-4`/`bottom-4` physical-direction positioning with no RTL adaptation. `separation-of-concerns` is passed because `toast.tsx` is pure presentation — layout and styling wrapped around `@base-ui/react/toast`'s primitives, with all toast state (queueing, timing, dismissal) owned by that library, none of it in this file; `unit-test-coverage` is failed because no test in this repo exercises `toast.tsx` — the evidence's candidate test list is empty.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-09-25 | Mike Fullerton | Corrected dismissal claims: Base UI 5000ms auto-dismiss, Escape-dismiss, and swipe-dismiss are real; Decision and Focus management rewritten. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: fix the viewport offset (4rem → 1rem) and the false 44×44 touch-target claim, remove the unsupported Material Design citation, drop unimplemented auto-dismiss from the exit vector, replace AppKit/UIKit subclassing guidance with composition, correct the SwiftUI and WinUI 3 platform notes, name the toast's actual ARIA roles and live-region politeness, require Space alongside Enter for Close dismissal and state that Escape does not dismiss, require a localized Close label, add a reduced-motion requirement, specify overflow behavior via the Provider's limit prop, rebuild Compliance as a table, reformat Design Decisions, move Tailwind class names into the React/Web platform note, clarify the fixed-vs-capped toast width, add related cross-references, rename all requirements to drop the must-/should- prefix, and add conformance vectors for per-provider queue isolation and the localized Close label |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Revise accessibility sections and edge cases: document hard-coded Close label, add Reduce Motion fact, clarify Differentiate Without Color limitation, state viewport overflow behavior, reword Compliance as Not applicable |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
