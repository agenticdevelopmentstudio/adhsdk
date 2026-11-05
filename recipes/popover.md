---
id: c61a220c-b63e-4dcd-a12b-715de20f7b5d
title: Popover
domain: adhsdk://recipes/popover
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A positioned overlay component that displays content relative to a trigger
  element.
platforms:
- typescript
- web
tags:
- ui
- overlay
- positioning
depends-on: []
related:
- adhsdk://recipes/popup-menu
- adhsdk://recipes/facet-menu
- adhsdk://recipes/category-gear-menu
- adhsdk://recipes/dismissible-hint
references:
- https://base-ui.com/react/components/popover
- https://base-ui.com/react/overview/accessibility
approved-by: ''
approved-date: ''
---

# Popover

## Overview

This recipe covers two independent components that share the name "popover" but little else:

- **Full-featured** (`Popover` / `PopoverTrigger` / `PopoverContent`, source: `packages/web/packages/ui/src/components/popover.tsx`): built on `@base-ui/react/popover`, with `dialog` role, non-modal focus management, and four-sided placement.
- **Lightweight** (`Popover`, source: `packages/web/packages/popover/src/Popover.tsx`): a hover-only panel with no positioning library and no dialog semantics, supporting only top/bottom placement.

Every requirement, test vector, and configuration option below is tagged with the variant(s) it applies to. Where the two disagree, each keeps its own behavior rather than being forced into a shared contract.

## Behavioral Requirements

- **open-visible** (full-featured, lightweight): The component MUST render visible when the `open` prop is `true`.
- **hide-on-close-unmount** (full-featured): When `open` is `false`, `PopoverContent` MUST be removed from the DOM. `PopoverContent` does not forward a `keepMounted` prop to Base UI's `Popover.Portal`, so this uses Base UI's default (`keepMounted={false}`) and cannot be overridden through this wrapper.
- **hide-on-close-visibility** (lightweight): When `open` is `false`, the panel MUST remain mounted and be hidden via the `hover-popover--open` class rather than being removed from the DOM, so its content is present in server-rendered HTML for non-JavaScript clients.
- **placement** (full-featured, lightweight): The component MUST accept a placement prop naming which side of the anchor the panel appears on: `side` on `PopoverContent` (`'top' | 'bottom' | 'left' | 'right'`, default `'bottom'`), or `placement` on the lightweight `Popover` (`'top' | 'bottom'` only, default `'top'`).
- **render-children** (full-featured, lightweight): The component MUST render all provided child content within the panel.
- **side-offset** (full-featured): `PopoverContent` MUST accept a `sideOffset` prop to control the gap, in pixels, between the panel and the trigger element (default `8`). The lightweight variant has no equivalent prop; its gap is a CSS custom property on `.hover-popover`.
- **alignment** (full-featured): `PopoverContent` MUST accept an `align` prop to control alignment along the axis perpendicular to `side` (`'start' | 'center' | 'end'`, default `'center'`). The lightweight variant has no equivalent prop.
- **custom-styling** (full-featured, lightweight): The component MUST accept a `className` prop, concatenated after its own default classes, to allow custom styling.
- **arrow** (full-featured): `PopoverContent` MAY render an optional pointer indicator, controlled by the `arrow` prop (default `false`). The lightweight variant always renders its arrow as a fixed part of the panel; it has no prop to disable it.

## Appearance

Numeric spec (full-featured variant; the class names that implement it are listed under **Platform Notes → React/Web**):

- **Corner radius**: 8px
- **Padding**: 1rem (16px) on all sides
- **Font**: 14px (0.875rem), default weight from context
- **Background**: Surface color token (apt-surface)
- **Foreground/Text**: Text color token (apt-text)
- **Border**: 1px solid, border color token (apt-border)
- **Shadow**: Drop shadow with blur and offset
- **Min/Max size**: Maximum width 288px; further constrained by the positioning library's available-width custom property

The lightweight variant's paint and geometry are custom properties declared on `.hover-popover`, outside the two source files this recipe is grounded in; this recipe does not specify their values.

## States

| State | Appearance change |
|-------|------------------|
| Open | Panel is visible with full opacity and visibility:visible |
| Closed (lightweight) | Panel has opacity:0 and visibility:hidden; content remains in DOM |
| Closed (full-featured) | Panel is unmounted (see **hide-on-close-unmount**) |
| Arrow enabled (full-featured, `arrow={true}`) | Diamond pointer (8px square) rendered at panel edge, rotated per `side` |
| Arrow disabled (full-featured, `arrow={false}`, default) | No pointer element rendered |
| Arrow (lightweight) | Always rendered; not conditional |

## Accessibility

These requirements describe the full-featured variant only, which wraps Base UI's Popover. The lightweight variant renders a plain `<div>` with mouse handlers and has no ARIA role, no focus management, and no keyboard equivalent to its hover trigger — it is a pointer-only affordance.

- **dialog-role** (full-featured): The popover content MUST be assigned the `dialog` role via Base UI's `Popover.Popup`.
- **return-focus-on-close** (full-featured): The popover is non-modal by default (Base UI `Popover.Root`'s `modal` prop, not set by this wrapper, defaults to `false`), so opening it does not trap focus inside the panel. When the popover closes via Escape, or via an outside interaction that lands on a non-focusable area, focus MUST return to the trigger element (Base UI's default `finalFocus` behavior). When the popover instead closes because focus itself left the panel (Tab past the last focusable element, Base UI's `focus-out` dismissal), Base UI suppresses the return-focus behavior and forwards focus to the next tabbable element after the trigger instead — the closing Tab keypress is left to complete its forward navigation rather than being undone (see popover-022).
- **escape-closes** (full-featured): The Escape key MUST close the popover (Base UI Popover's native keyboard handling).
- **aria-expanded** (full-featured): The trigger element MUST have `aria-expanded="true"` when the popover is open and `aria-expanded="false"` when closed (Base UI `Popover.Trigger` handles this automatically).
- **label-association** (full-featured): The popover SHOULD be associated with a descriptive label via `aria-labelledby` or `aria-label` on `Popover.Popup` for screen reader users.
- **live-region-updates** (full-featured, lightweight): Dynamic content changes inside the panel SHOULD use `aria-live="polite"` or `aria-live="assertive"` as appropriate to announce updates to assistive technology users.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| popover-001 | open-visible | `open={true}` (full-featured) | `PopoverContent` is present in the DOM |
| popover-002 | open-visible | `open={true}` (lightweight) | Panel has the `hover-popover--open` class; opacity/visibility at full/normal |
| popover-003 | hide-on-close-unmount | `open={false}` (full-featured) | `PopoverContent`'s DOM subtree is absent (Base UI default `keepMounted={false}`) |
| popover-004 | hide-on-close-visibility | `open={false}` (lightweight) | Panel markup remains in DOM; opacity:0, visibility:hidden; no `hover-popover--open` class |
| popover-005 | placement | `side="top"` (full-featured) | Panel appears above the trigger element |
| popover-006 | placement | `side="bottom"` (full-featured) | Panel appears below the trigger element |
| popover-007 | placement | `side="left"` (full-featured) | Panel appears to the left of the trigger element |
| popover-008 | placement | `side="right"` (full-featured) | Panel appears to the right of the trigger element |
| popover-009 | placement | `placement="top"` (lightweight, default) | Panel appears above the trigger element |
| popover-010 | placement | `placement="bottom"` (lightweight) | Panel appears below the trigger element |
| popover-011 | render-children | `children={<p>Content text</p>}` (full-featured) | Child content is rendered and visible inside the panel |
| popover-012 | render-children | `children={<p>Content text</p>}` (lightweight) | Child content is rendered and visible inside the panel |
| popover-013 | side-offset | `sideOffset={16}` (full-featured) | Gap between panel edge and trigger element is 16px |
| popover-014 | alignment | `align="start"` (full-featured) | Popover's start edge aligns with trigger's start edge |
| popover-015 | alignment | `align="center"` (full-featured, default) | Popover center aligns with trigger center along the perpendicular axis |
| popover-016 | alignment | `align="end"` (full-featured) | Popover's end edge aligns with trigger's end edge |
| popover-017 | custom-styling | `className="custom-popover-class"` (full-featured or lightweight) | Custom class is applied to the panel element alongside default classes |
| popover-018 | arrow | `arrow={true}` (full-featured) | Diamond pointer (8px square, rotated per `side`) appears at the edge of the panel facing the trigger |
| popover-019 | arrow | `arrow={false}` (full-featured, default) | No pointer element is rendered |
| popover-020 | dialog-role | Popover rendered via `PopoverContent` (full-featured) | Inspect DOM; the `Popover.Popup` element has `role="dialog"` |
| popover-021 | return-focus-on-close | Popover open (full-featured, non-modal), Tab from the first focusable element inside the panel through the last | Focus moves forward through the panel's focusable elements in DOM order; it does not cycle back to the first panel element (no focus trap) |
| popover-022 | return-focus-on-close | Popover open (full-featured), focus on the last focusable element inside the panel, press Tab | Focus leaves the panel and moves to the next tabbable element after the trigger in document tab order; the popover closes (Base UI's `focus-out` dismissal); return-focus is suppressed, so focus does NOT go back to the trigger element (contrast Escape, which does return focus to the trigger) |
| popover-023 | escape-closes | Popover open (full-featured, controlled via `open`/`onOpenChange`), press Escape | `onOpenChange(false, ...)` is called; the consumer setting `open` to `false` in response causes `PopoverContent` to unmount |
| popover-024 | aria-expanded | Popover open (full-featured) | Trigger element has `aria-expanded="true"` |
| popover-025 | aria-expanded | Popover closed (full-featured) | Trigger element has `aria-expanded="false"` |

## Edge Cases

- **Content larger than max-width** (full-featured): If popover content exceeds 288px width, text MUST wrap rather than overflow the panel's width; no max-height or overflow-scroll behavior for content that also exceeds the panel's height is defined in the source.
- **Placement adjustment** (full-featured): If the requested `side` would render the popover outside the viewport, the positioning library (base-ui) MAY auto-adjust placement or alignment to keep the popover visible.
- **Empty children** (full-featured, lightweight): If no children are provided, the popover MUST render as an empty panel; no fallback content is added.
- **Rapid visibility toggles** (lightweight): If `open` toggles rapidly, the panel MUST remain stable without layout thrashing, since it stays mounted throughout (see **hide-on-close-visibility**).
- **Arrow orientation per placement** (full-featured): When `arrow={true}`, the arrow MUST be rotated per the active `side`: 45deg for top, 225deg for bottom, 315deg for left, 135deg for right.
- **Tab-out closes without returning focus** (full-featured): Tabbing forward past the last focusable element inside the panel closes the popover via Base UI's `focus-out` dismissal; unlike Escape or an outside press on a non-focusable area, this path does not return focus to the trigger — focus instead lands on the next tabbable element after the trigger, continuing the forward Tab (see **return-focus-on-close**, popover-022).

## Configuration

| Option | Type | Default | Variant / Component | Description |
|--------|------|---------|----------------------|-------------|
| `open` | boolean | — | Both — lightweight `Popover`; full-featured `Popover` (forwards Base UI `Popover.Root.Props`) | Controls visibility. Lightweight: hides via CSS when `false` (stays in DOM). Full-featured: unmounts `PopoverContent` when `false` (see **hide-on-close-unmount**). |
| `onOpenChange` | `(open: boolean, eventDetails) => void` | — | Full-featured `Popover` / Base UI `Popover.Root` only | Called when the popover requests to open or close (Escape, outside press, focus-out, trigger press). Required alongside `open` for controlled usage. |
| `defaultOpen` | boolean | `false` | Full-featured `Popover` / Base UI `Popover.Root` only | Initial open state for uncontrolled usage (no `open`/`onOpenChange` passed). |
| `side` | `'top' \| 'bottom' \| 'left' \| 'right'` | `'bottom'` | Full-featured `PopoverContent` only | Which side of the trigger the panel appears on. |
| `placement` | `'top' \| 'bottom'` | `'top'` | Lightweight `Popover` only | Which side of the anchor the panel appears on. |
| `sideOffset` | number | `8` | Full-featured `PopoverContent` only | Gap in pixels between the panel and the trigger element. |
| `align` | `'start' \| 'center' \| 'end'` | `'center'` | Full-featured `PopoverContent` only | Alignment along the axis perpendicular to `side`. |
| `arrow` | boolean | `false` | Full-featured `PopoverContent` only | Whether to render the optional pointer indicator. |
| `className` | string | — | Full-featured `PopoverContent`; lightweight `Popover` | Custom CSS class, concatenated after default classes. |
| `children` | ReactNode | — | Full-featured `PopoverContent`; lightweight `Popover` | Content to display inside the panel. |
| `onMouseEnter` / `onMouseLeave` | `() => void` | — | Lightweight `Popover` only | Passed through to the panel element so a caller can compose hover-driven show/hide. |

## Deep Linking

Not applicable: Popovers are transient, context-dependent UI elements without independent navigation identity; they cannot be deep-linked.

## Localization

Not applicable: The component renders only the child content provided by the parent; it does not define any locale-specific strings.

## Accessibility Options

- **Reduce Motion**: When enabled at the system level, transitions and animations on the popover (if any) SHOULD be disabled or shortened to instant.
- **Increase Contrast**: Border and background colors SHOULD adapt to provide WCAG AA contrast ratios (4.5:1 for text, 3:1 for non-text elements) when high-contrast mode is active.

## Feature Flags

Not applicable: No feature flags are defined in the source implementation.

## Analytics

Not applicable: This is a presentational component; event tracking is the responsibility of parent components or trigger elements.

## Privacy

Not applicable: The component does not collect, store, or transmit user data.

## Logging

Not applicable: No logging behavior is specified in the source implementation.

## Platform Notes

- **React/Web (full-featured)** (source: `packages/web/packages/ui/src/components/popover.tsx`): Built on `@base-ui/react/popover`. Exports `Popover` (wraps `Popover.Root`), `PopoverTrigger` (wraps `Trigger`), and `PopoverContent` (wraps `Popup` + `Positioner` + `Portal`). Styling uses Tailwind classes and `apt-*` design tokens: `rounded-lg` (corner radius), `p-4` (padding), `text-sm` (font), `bg-apt-surface` / `border-apt-border` / `text-apt-text` (tokens), `shadow-lg` (shadow), `w-72 max-w-(--available-width)` (max size). The arrow is a conditionally rendered rotated square (`size-2 rounded-[2px] border-r border-b border-apt-border bg-apt-surface`) with CSS `data-[side=...]` attribute selectors controlling rotation and offset per `side` (top: `-bottom-1 rotate-45`; bottom: `-top-1 rotate-[225deg]`; left: `-right-1 rotate-[315deg]`; right: `-left-1 rotate-[135deg]`). Supports all four sides via `side`; default is `bottom`.
- **React/Web (lightweight variant)** (source: `packages/web/packages/popover/src/Popover.tsx`): Simpler hover-only popover using CSS class composition (`hover-popover`, `hover-popover--{placement}`, `hover-popover--open`). Supports top/bottom placement only, via `placement` (default `top`). Always rendered in DOM, hidden via `opacity`/`visibility` CSS. `onMouseEnter`/`onMouseLeave` pass through to caller-supplied handlers. Useful for inline hover popovers without positioning-library overhead.
- **SwiftUI**: Use `.popover(isPresented:attachmentAnchor:arrowEdge:)` to present the panel relative to the source view; `arrowEdge` selects the side, matching `side`/`placement`. Draw the arrow indicator with a rotated `Rectangle` or a custom `Shape`, rotated per placement angle.
- **Compose**: Build with `Popup` and a custom `PopupPositionProvider` to position the panel relative to the anchor and compute placement, offset, and alignment. Draw the arrow with `Canvas` or a custom `Composable` shape.
- **AppKit / UIKit**: Use `NSPopover` (AppKit, supports automatic positioning) for AppKit, and `UIPopoverPresentationController` for UIKit. Manage visibility via `.isShown` (AppKit) or the presentation controller's dismissal (UIKit). Draw the arrow via Core Graphics or a custom view layer.
- **WinUI 3**: Use the `Flyout` control with its `Placement` property (Top, Bottom, Left, Right, Full). Style via `ControlTemplate` overrides; render the arrow as a custom element in the template, styled with a `Brush` and rotated via `RenderTransform`/`RotateTransform`. Control offset via margin on the Flyout's inner content.

## Design Decisions

1. **Decision**: The lightweight variant remains mounted in the DOM at all times and is hidden via CSS (`opacity`/`visibility`) rather than unmounting; the full-featured variant unmounts `PopoverContent` when closed (Base UI's default `keepMounted={false}`, not overridden by this wrapper).
   **Rationale**: For the lightweight variant, this ensures server-rendered HTML includes the full page structure, accessible to non-JavaScript clients and screen readers, and lets CSS transitions work smoothly. The full-featured variant instead relies on Base UI's own mount/unmount and animation-completion handling.
   **Approved**: pending

2. **Decision**: The `arrow` prop on `PopoverContent` defaults to `false`.
   **Rationale**: Maintains backward compatibility with existing consumers who were built before the arrow feature was added and do not expect it.
   **Approved**: pending

3. **Decision**: On web, `PopoverContent` renders in a React Portal.
   **Rationale**: Escapes stacking context and ensures correct z-index layering above other page content without relying on parent CSS properties.
   **Approved**: pending

4. **Decision**: Appearance is defined using `apt-*` design tokens (apt-surface, apt-border, apt-text) rather than hard-coded color values.
   **Rationale**: Allows theming via token override without duplicating CSS rules.
   **Approved**: pending

5. **Decision**: Default placement is `bottom` for the full-featured variant and `top` for the lightweight variant, with an 8px offset on the full-featured variant.
   **Rationale**: Conventional defaults for popover components, providing adequate visual separation from the trigger without excessive displacement.
   **Approved**: pending

6. **Decision**: The full-featured variant is non-modal by default and delegates its accessibility behavior (dialog role, non-modal focus handling, Escape, aria-expanded) to Base UI's Popover rather than re-implementing it; the lightweight variant implements no accessibility behavior at all.
   **Rationale**: Ensures consistency with Base UI's tested and maintained standards for the full-featured variant, while keeping the lightweight variant intentionally minimal for inline hover use.
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

The full-featured variant satisfies these checks through Base UI's `dialog` role, non-modal focus handling (return-focus-on-close), and automatic `aria-expanded`, but its colors come from `apt-*` tokens whose actual contrast values the source does not define; the lightweight variant has no ARIA role, no focus management, and no keyboard path to its hover trigger. Because this recipe covers both variants, each check is only partly satisfied overall. Both `Popover.tsx` and `popover.tsx` are pure presentation with no business logic or data access (separation-of-concerns passed), but neither has a dedicated test rendering the component itself — `useHoverPopoverGroup.test.tsx` exercises only the pairing hook, and `entityChooser.test.tsx` reaches the full-featured variant only through its parent `EntityChooser` (unit-test-coverage partial).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | return-focus-on-close and popover-022 corrected: focus-out (Tab past last panel element) does not return focus to the trigger, only Escape/outside-press do; added Edge Case and popover-022 expected result. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: tag requirements, configuration, and platform notes by variant (full-featured vs. lightweight); rename requirements to subject-only kebab-case; correct hide-on-close and focus behavior to match Base UI defaults (non-modal, `keepMounted={false}`); fix SwiftUI/Compose/UIKit/WinUI 3 platform APIs; add `onOpenChange`/`defaultOpen` configuration; reformat Design Decisions to Decision/Rationale/Approved; populate Compliance as a table; add related recipes and Base UI references; move Tailwind class names into the React/Web platform note; split ambiguous test vectors by variant |
| 1.0.1 | 2026-09-22 | Claude Haiku 4.5 | Revise Accessibility section: state Base UI delegation as requirements (dialog role, focus trap, Escape handling, aria-expanded); add test vectors for accessibility features; drop review marker |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
