---
id: a17a8253-0be8-4646-a76a-6941b1af3528
title: Tooltip
domain: adhsdk://recipes/tooltip
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Contextual label that appears on hover or focus, positioned relative to its
  trigger element with configurable placement and optional pointer.
platforms:
- typescript
- web
tags:
- ui
- primitives
- tooltips
depends-on: []
related:
- adhsdk://recipes/popover
- adhsdk://recipes/inline-popover
references:
- https://base-ui.io/react/components/tooltip/
approved-by: ''
approved-date: ''
---

# Tooltip

## Overview

A tooltip is a non-interactive label that displays supplementary information when a user hovers over or focuses on a trigger element. The component wraps Base UI's tooltip primitive, providing consistent styling, positioning, and behavior across the application. It is used to provide brief, contextual help text without cluttering the primary interface. Use a tooltip when you need to explain an icon, clarify a button's action, or provide additional context that is not critical to understanding the interface.

## Behavioral Requirements

- **render-on-hover**: The tooltip MUST display when the user hovers over the trigger element.
- **render-on-focus**: The tooltip MUST display when the trigger element receives keyboard focus.
- **respect-provider-delay**: The tooltip MUST respect the `delay` property set on the `TooltipProvider`, which controls the number of milliseconds before the tooltip opens (this wrapper defaults it to 200ms).
- **not-clipped-by-ancestors**: The tooltip content MUST NOT be clipped by an ancestor's `overflow` or stacking-context constraints.
- **position-relative-to-trigger**: The tooltip MUST position relative to the trigger element using a Positioner component that supports `side` (top, bottom, left, right), `sideOffset`, and `align` (start, center, end) properties.
- **support-style-override**: The tooltip content MUST support consumer-supplied overrides or extensions to its default styling.
- **show-arrow**: The tooltip SHOULD display an optional pointer (arrow) by default; it MAY be disabled by setting the `arrow` prop to `false`.
- **render-children-in-content**: The tooltip content MUST render the provided `children` prop as the label text.
- **dismiss-on-escape**: The tooltip MUST dismiss when the user presses Escape while it is open (inherited from Base UI).
- **remain-open-on-content-hover**: The tooltip MUST remain open while the pointer is over the tooltip content itself, not only while it is over the trigger (inherited from Base UI).
- **dismiss-on-pointer-leave-or-blur**: The tooltip MUST dismiss when the pointer leaves both the trigger and the content, or when the trigger loses focus (inherited from Base UI).

## Appearance

- **Corner radius**: 6px (rounded-md)
- **Padding**: vertical 6px × horizontal 10px (py-1.5 px-2.5)
- **Font**: weight 400, size 12px (text-xs)
- **Background**: `apt-surface-2` token (secondary surface color)
- **Foreground/Text**: `apt-text` token (primary text color)
- **Border**: 1px solid, `apt-border` token
- **Shadow**: Medium drop shadow (shadow-md)
- **Arrow**: 8px × 8px diamond (size-2), rotated 45deg, 1px border on right and bottom edges, inherits background and border from content, positioned to touch the edge of the trigger element
- **Max width**: 320px (max-w-xs)
- **Z-index**: 50 (z-50)

## States

| State | Appearance change |
|-------|------------------|
| Default | Not rendered — the `Popup` is unmounted (inside the `Portal`) while the tooltip is closed |
| Visible | Rendered with full styling, positioned adjacent to trigger |
| Arrow visible | Diamond pointer visible (default state when arrow=true) |
| Arrow hidden | No pointer element rendered (when arrow=false) |

The component defines no CSS transition or animation on open/close, so there is no separate opening/closing transition state; visibility changes are an instant mount/unmount via the Portal.

## Accessibility

- **Role**: `tooltip` (inherited from Base UI primitive via `role="tooltip"`)
- **Label requirements**: The trigger element SHOULD have an associated label or accessible name that describes its purpose; the tooltip content provides supplementary information only, not the primary label.
- **Keyboard support**: The tooltip MUST display when the trigger element receives focus via keyboard navigation.
- **Announce on open**: The wrapper inherits Base UI Tooltip's `role="tooltip"` and `aria-describedby` wiring. Screen readers announce the tooltip content as the description of the trigger element when the relationship is established via `aria-describedby`.
- **Dismiss, hover, and persist**: See #requirements/dismiss-on-escape, #requirements/remain-open-on-content-hover, and #requirements/dismiss-on-pointer-leave-or-blur (WCAG 1.4.13, Content on Hover or Focus).
- **Minimum touch target**: The trigger element's touch target size is the consuming application's responsibility (recommended minimum 44×44pt per platform guidelines); the tooltip content itself is non-interactive and has no target of its own.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|-------|----------|
| tooltip-001 | render-on-hover | User hovers over a trigger element within a `TooltipProvider` | Tooltip content displays after the provider's configured delay (default 200ms) |
| tooltip-002 | render-on-focus | User presses Tab to focus a trigger element | Tooltip content displays after the provider's configured delay |
| tooltip-003 | respect-provider-delay | `TooltipProvider` with `delay={500}` wraps a trigger | Tooltip does not appear until 500ms after hover begins |
| tooltip-004 | not-clipped-by-ancestors | A tooltip is rendered within a nested container with `overflow: hidden` | Tooltip content is not clipped and renders outside the container's bounds |
| tooltip-005 | position-relative-to-trigger | `TooltipContent` with `side="bottom"` and `sideOffset={8}` | Tooltip appears below the trigger, 8px from its bottom edge |
| tooltip-006 | position-relative-to-trigger | `TooltipContent` with `align="start"` | Tooltip's leading edge aligns with the trigger's leading edge |
| tooltip-007 | support-style-override | `TooltipContent` with `className="custom-bg"` where custom-bg sets background to red | Content renders with red background instead of default `apt-surface-2` |
| tooltip-008 | show-arrow | `TooltipContent` with default props (no `arrow` prop) | Diamond pointer is rendered adjacent to the content |
| tooltip-009 | show-arrow | `TooltipContent` with `arrow={false}` | No pointer element is rendered |
| tooltip-010 | render-children-in-content | `TooltipContent` with `children="Help text"` | The text "Help text" appears inside the tooltip |
| tooltip-011 | dismiss-on-escape | Tooltip is open; user presses Escape | Tooltip closes |
| tooltip-012 | remain-open-on-content-hover | Tooltip is open; user moves the pointer from the trigger onto the tooltip content | Tooltip remains open |
| tooltip-013 | dismiss-on-pointer-leave-or-blur | Tooltip is open via hover; user moves the pointer off both the trigger and the content without pressing Escape | Tooltip closes |
| tooltip-014 | position-relative-to-trigger | Document `dir="rtl"`; `TooltipContent` with `align="start"` | Tooltip's leading edge (the trigger's right edge in RTL) aligns with the trigger's leading edge |
| tooltip-015 | renders-with-empty-content | `TooltipContent` with `children=""` | Tooltip still renders and positions normally, with no visible text content |
| tooltip-016 | very-long-text-wraps | `TooltipContent` with `children` text longer than 320px wide | Tooltip wraps text onto multiple lines and grows vertically without exceeding `max-w-xs` |
| tooltip-017 | single-open-tooltip | User moves the pointer rapidly between two trigger elements within the same `TooltipProvider` before the first tooltip's delay elapses | Only one tooltip is open at a time; the delay timer resets for the newly hovered trigger |
| tooltip-018 | auto-flip-near-viewport-edge | `TooltipContent` with `side="bottom"` on a trigger near the bottom edge of the viewport | Positioner flips the tooltip to the opposite or best-fit side so it stays within the viewport |
| tooltip-019 | arrow-rotates-per-side | `TooltipContent` with `side="bottom"` | Arrow rotates 225deg to point upward toward the trigger instead of 45deg |
| tooltip-020 | disabled-trigger-not-observed | Trigger's `disabled` attribute is set to true while its tooltip is open, with no pointer-leave, blur, or Escape event | Tooltip does not close on its own |

## Edge Cases

- **renders-with-empty-content**: If `children` is an empty string or falsy, the tooltip MUST still render and position normally, with no visible text content.
- **very-long-text-wraps**: Text longer than `max-w-xs` (320px) MUST wrap to multiple lines, and the tooltip MUST grow vertically to accommodate it.
- **single-open-tooltip**: If a user quickly moves the pointer between trigger elements within the same `TooltipProvider`, only one tooltip MUST be open at a time, and the delay timer MUST reset for the newly hovered trigger (inherited from Base UI).
- **auto-flip-near-viewport-edge**: If the configured `side` would place the tooltip outside the viewport (for example `side="bottom"` near the bottom edge), Base UI's Positioner MUST adjust the side automatically so the tooltip stays within the viewport.
- **arrow-rotates-per-side**: When `side="bottom"`, the arrow MUST rotate 225deg to point upward instead of 45deg; for `side="left"` or `side="right"`, the arrow's position MUST adjust accordingly.
- **disabled-trigger-not-observed**: The component does not observe the trigger element's `disabled` state. If the trigger becomes disabled while its tooltip is open, the tooltip does not close on its own — dismissal depends entirely on whether the trigger's own pointer-leave, blur, or Escape handling still fires, which this component does not control.

## Configuration

| Option | Type | Default | Owner | Description |
|--------|------|---------|-------|-------------|
| delay | number | 200 | `TooltipProvider` | Milliseconds before the tooltip opens after the user hovers or focuses the trigger |
| side | "top" \| "bottom" \| "left" \| "right" | "top" | `TooltipContent` | Which side of the trigger the tooltip appears on |
| sideOffset | number | 6 | `TooltipContent` | Distance in pixels from the trigger to the tooltip |
| align | "start" \| "center" \| "end" | "center" | `TooltipContent` | Horizontal/vertical alignment of the tooltip relative to the trigger |
| arrow | boolean | true | `TooltipContent` | Whether to display the pointer diamond |
| className | string | undefined | `TooltipContent` | Additional CSS class(es) to apply to the content wrapper |
| children | ReactNode | required | `TooltipContent` | The text or content to display in the tooltip |

## Deep Linking

Not applicable: Tooltip is a non-interactive UI component overlay; it does not correspond to navigable app states or deep-linkable destinations.

## Localization

Not applicable: The Tooltip component does not render any static text strings; all content comes from the `children` prop, which the consuming application provides.

## Accessibility Options

Not applicable: The component does not implement platform-specific accessibility display options (Reduce Motion, Increase Contrast, Differentiate Without Color). These concerns SHOULD be addressed at the application level by conditionally disabling tooltips or adjusting the provider's delay based on user preferences.

## Feature Flags

Not applicable: No feature flags are present in the source code; the component is always enabled.

## Analytics

Not applicable: The component does not emit any analytics events; event tracking is the responsibility of the consuming application.

## Privacy

Not applicable: The component does not collect, store, or transmit any user data.

## Logging

Not applicable: The component does not emit any structured logs; debugging relies on React DevTools and browser console.

## Platform Notes

- **React/Web**: Wraps Base UI's tooltip primitive (`@base-ui/react/tooltip`) in the exported `Tooltip`, `TooltipTrigger`, `TooltipContent`, and `TooltipProvider` components. `TooltipContent` composes the primitive's `Portal`, `Positioner` (side, sideOffset, align), `Popup`, and `Arrow`: the `Portal` is what satisfies #requirements/not-clipped-by-ancestors, and the `className` prop forwarded to `Popup` is what satisfies #requirements/support-style-override. The arrow is an 8×8 (`size-2`) square rotated 45deg with a border on its right and bottom edges and a 2px corner radius (`rounded-[2px]`), not a 2px square.
- **SwiftUI**: Use the `.help(_:)` view modifier, which attaches a native tooltip that macOS shows on pointer hover. It has no `delay`, `side`, `sideOffset`, or `arrow` equivalents, so those semantics are informational only on this platform.
- **Compose**: Use Material 3's `TooltipBox` composable with a `PlainTooltip` (or `RichTooltip` for richer content) and `rememberTooltipState()`, anchoring it to the trigger composable; `TooltipBox`'s `positionProvider` controls placement analogous to `side`/`align`.
- **AppKit / UIKit**: On macOS, set `NSView.toolTip` (or the inherited `NSControl` property) to a string; AppKit shows it automatically after its own hover delay. On iOS/iPadOS, attach a `UIToolTipInteraction` to the trigger view; it only appears for pointer-based interactions (trackpad/mouse), matching this component's hover semantics.
- **WinUI 3**: Use the `ToolTipService.ToolTip` attached property (or an explicit `ToolTip` control) on the trigger element. `Placement` controls side (Top, Bottom, Left, Right, Mouse), and `VerticalOffset`/`HorizontalOffset` map to `sideOffset`. Show delay is controlled by `ToolTipService.ShowDuration` / system settings, analogous to the Provider's `delay`.

## Design Decisions

**Decision**: `TooltipProvider` defaults `delay` to 200ms rather than deferring to Base UI's own default.
**Rationale**: This timing prevents tooltip flicker on quick mouse passes while remaining responsive to intentional hovers; the delay is configurable per provider, letting different contexts trade responsiveness for noise reduction.
**Approved**: pending

**Decision**: The `arrow` prop lets consumers disable the pointer diamond.
**Rationale**: Tooltips on left/right sides can have arrows that visually overlap text content, reducing readability; consumers can disable the arrow for those cases while keeping it enabled for top/bottom (the common case).
**Approved**: pending

**Decision**: Tooltip content renders through a React Portal.
**Rationale**: Ensures tooltips are not clipped by `overflow: hidden` ancestors and always render above sibling content via z-index; see #requirements/not-clipped-by-ancestors.
**Approved**: pending

**Decision**: The Positioner and Popup both render at `z-50`.
**Rationale**: `z-50` is Tailwind's utility convention for floating UI layers, so the tooltip sits above ordinary page content. This component defines no relationship to modal or dialog z-index tiers, so its ordering relative to those overlays is undefined here and must be coordinated by the consuming application.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Screen-reader, keyboard, and semantic-markup statuses rest on Base UI's built-in `role="tooltip"`/`aria-describedby` wiring and this wrapper's hover/focus triggers documented above; contrast and RTL are marked partial because the source confirms the design tokens and the Positioner's logical placement but not the rendered contrast values or `dir="rtl"` behavior directly; text-expansion is passed on the wrapping behavior confirmed in **very-long-text-wraps**; the four exports are themed pass-throughs of base-ui's `Tooltip` primitives with no logic of their own (separation-of-concerns passed), and no test in the web workspace imports this source — the candidate tests matched by name are unrelated macOS `Chrome`-pane Swift files (unit-test-coverage failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Narrowed frontmatter platforms to typescript/web, matching the component's single web source. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; restate must-use-portal/must-support-custom-className as outcomes and move their React specifics into the React/Web platform note; rewrite non-web Platform Notes around each platform's native tooltip API and correct unsupported/inaccurate claims (SwiftUI, Compose, WinUI 3, 200ms default); add dismiss/hover-persist requirements and test vectors plus an RTL test vector; rewrite edge cases as RFC 2119 requirements with vectors; resolve the z-index and arrow-size contradictions; reformat Design Decisions to the three-line form; normalize the Compliance table and fix frontmatter platforms/related drift |
| 1.0.1 | 2026-09-22 | Claude Haiku 4.5 | Remove review marker from Accessibility section; state that wrapper inherits Base UI Tooltip's role and aria-describedby wiring for screen reader announcement |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from Base UI tooltip source |
