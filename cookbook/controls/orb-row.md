---
id: 96e5e0cf-79a9-4873-9745-03442849b2fd
title: "Orb Row"
type: ingredient
version: 1.2.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Navigation row displaying a series of site orbs with gradient backgrounds, emoji indicators, and current-page highlighting."
platforms:
  - typescript
  - web
tags:
  - navigation
  - site-navigation
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Orb Row

## Overview

Orb Row renders a horizontal navigation bar listing available sites as circular "orbs". Each orb displays an emoji icon with a gradient background and supports a "current" state to indicate the active site. The component is accessible via semantic navigation markup and ARIA attributes, and can be visually "docked" (a rendering variant for fixed positioning contexts).

## Behavioral Requirements

- **render-orb-links**: The component MUST render each site as an `<a>` element with `href` pointing to the site's URL.
- **apply-current-state**: The component MUST apply the `is-current` class to the link whose `id` matches `currentSite`.
- **set-aria-current**: When a link is current, the component MUST set `aria-current="page"` on that link; other links MUST NOT have `aria-current` set.
- **render-emoji-hidden**: The component MUST render the emoji in a `<span>` with `aria-hidden="true"` so it is not exposed in the accessibility tree.
- **render-tooltip-role**: The component MUST render the site name in a `<span>` with `role="tooltip"`.
- **apply-gradient-background**: The component MUST apply each site's `iconGradient` value as the CSS `background` style property on the orb link.
- **render-indicator-when-current**: When a site is current, the component MUST render an indicator `<span>` with class `orb-row-here` and `aria-hidden="true"`.
- **set-navigation-role**: The component MUST render the container with `role="navigation"` and `aria-label="Agentic family"`.
- **set-docked-class**: When the `docked` prop is `true`, the component MUST apply the `is-docked` class to the root container.
- **apply-custom-class**: The component MUST append any `className` prop value to the root container's class list.
- **set-link-label**: The component MUST set `aria-label="{site.name}"` on each orb link so it has an accessible name distinct from its (hidden) visual content.
- **render-focus-indicator**: When an orb link receives keyboard focus, the component MUST present a visible focus indicator (a box-shadow ring applied via `:focus-visible`) and pause its floating animation.
- **show-tooltip-on-focus**: The component MUST reveal the tooltip span on keyboard focus (`:focus-visible`) as well as on pointer hover.

## Appearance

- **Container**: Role is navigation; a horizontal flex row, centered on both axes, wrapping onto further lines when needed, with a `0.75rem` gap (`0.5rem` at widths of `640px` or less) and `0.5rem 0` padding.
- **Orb**: A circle of `48px` (`36px` at widths of `640px` or less) with the site's gradient as its background, containing a centered emoji at `1.4rem` (`1.1rem` at `640px` or less). Orbs float: each translates up `10px` and back over `3s` with ease-in-out, forever, with the animation delay stepping by `-0.25s` per orb for the first twelve orbs.
- **Hover and focus**: On hover or `:focus-visible` the float animation pauses, the outline is removed, and the orb gets a `0 6px 18px rgba(0,0,0,0.45)` shadow.
- **Emoji**: Centered within the orb, line-height `1`, ignores pointer events.
- **Tooltip**: The site name in a box centered above the orb (`12px` clear of it): background `#14141a`, text `#e8e6e3`, `1px` solid `#2a2a36` border, `0.4rem 0.7rem` padding (`0.3rem 0.5rem` at `640px` or less), `6px` corner radius, `DM Mono` (monospace fallback) at `0.7rem` (`0.65rem` at `640px` or less), single line, and a `5px` arrow pointing at the orb. It is hidden (`opacity: 0`) and fades to `opacity: 1`, moving `4px` up into place, over `0.15s` on hover or `:focus-visible`.
- **Current orb**: A `2px` ring of `#c4a35a` plus a `0 0 14px rgba(196,163,90,0.55)` glow, and an outer `1px` ring (`rgba(196,163,90,0.45)`, inset `-7px`) that pulses over `2.4s`, fading between `0.4` and `0.9` opacity while scaling between `1` and `1.08`.
- **Indicator**: The `orb-row-here` span is a `6px` dot of `#c4a35a` with a `0 0 8px rgba(196,163,90,0.8)` glow, centered `8px below` the orb.
- **Docked variant**: When `docked=true`, the container receives the `is-docked` class: fixed `1rem` from the bottom of the viewport and horizontally centered, as a pill (`999px` corner radius) with a `rgba(20,20,26,0.85)` background, an `8px` backdrop blur, a `1px` solid `#2a2a36` border, `0.5rem 1rem` padding, a `0 4px 20px rgba(0,0,0,0.45)` shadow and z-index `50`. In this variant the tooltip appears below the orb and the current-page indicator above it.
## States

| State | Appearance change |
|-------|------------------|
| Default | Orb shows emoji with gradient background; tooltip hidden until hover or focus. |
| Current | `is-current` class applied; aria-current="page" set; indicator span rendered. |
| Focused | `:focus-visible` pauses the floating animation, applies a box-shadow ring, and reveals the tooltip (see **render-focus-indicator**, **show-tooltip-on-focus**). |
| Docked | `is-docked` class applied to container; specific layout adjustments via stylesheet. |

## Accessibility

- **Role**: Container is a navigation landmark via an explicit `role="navigation"` on a `<div>` (see **set-navigation-role**); the source does not use a native `<nav>` element.
- **Label**: Container includes `aria-label="Agentic family"` to identify the navigation purpose.
- **Link labels**: Each link receives `aria-label="{site.name}"` (see **set-link-label**) for screen reader announcement.
- **Current page indicator**: Links use `aria-current="page"` to mark the active page, per WCAG best practices (see **set-aria-current**).
- **Emoji handling**: Emoji spans have `aria-hidden="true"` to prevent redundant announcement (see **render-emoji-hidden**).
- **Indicator handling**: Current-page indicator span has `aria-hidden="true"` (visual only).
- **Tooltip role**: The site name span carries `role="tooltip"` (see **render-tooltip-role**), but the source does not associate it with the link via `aria-describedby`; assistive technology receives the site name only through the link's `aria-label`, not through the tooltip role itself.
- **Keyboard focus**: `:focus-visible` pauses the floating animation and applies a box-shadow ring (see **render-focus-indicator**), and reveals the tooltip on focus the same way it does on hover (see **show-tooltip-on-focus**). This meets only the reveal-on-focus part of WCAG 2.1 SC 1.4.13 (Content on Hover or Focus): the tooltip has `pointer-events: none`, and no requirement or test covers dismissing it (Esc), hovering over it or keeping it visible.
- **Minimum tap target**: Orbs are 48×48px by default (`styles/orb-row.css`), which meets the 44×44px minimum; the `max-width: 640px` breakpoint shrinks orbs to 36×36px, which falls below it.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| orb-row-001 | render-orb-links | sites=[{id:"a",url:"https://site-a.com",name:"Site A",emoji:"🅰",iconGradient:"linear-gradient(...)"}] | Rendered `<a href="https://site-a.com">` element |
| orb-row-002 | set-navigation-role | (default) | Root element has `role="navigation"` and `aria-label="Agentic family"` |
| orb-row-003 | apply-current-state, set-aria-current | currentSite="a", sites with id "a" | The link for site "a" (matched by its `href`) has class `is-current` and `aria-current="page"`; other links lack both. |
| orb-row-004 | apply-gradient-background | sites=[{...iconGradient:"linear-gradient(to right, #ff0000, #0000ff)"}] | Link's style attribute includes `background: linear-gradient(to right, #ff0000, #0000ff)` |
| orb-row-005 | render-emoji-hidden | sites=[{emoji:"🎯"}] | Emoji renders inside `<span aria-hidden="true">🎯</span>`; querying the link's accessible name via the accessibility tree does not include the emoji glyph. |
| orb-row-006 | render-tooltip-role | sites=[{name:"Example"}] | Site name renders in `<span role="tooltip">Example</span>` |
| orb-row-007 | render-indicator-when-current | currentSite="x", sites with id "x" | Indicator `<span class="orb-row-here" aria-hidden="true"></span>` rendered inside current link |
| orb-row-008 | set-docked-class | docked=true | Root element includes `is-docked` class |
| orb-row-009 | apply-custom-class | className="custom-class" | Root element includes `custom-class` in its class list |
| orb-row-010 | set-link-label | sites=[{name:"Example"}] | Link has `aria-label="Example"` |
| orb-row-011 | set-aria-current | currentSite=null or not in sites list | No link has `aria-current` set |
| orb-row-012 | render-focus-indicator | orb link receives keyboard focus | Link matches `:focus-visible`; computed `animation-play-state` is `paused`, `box-shadow` is `0 6px 18px rgba(0,0,0,0.45)` and the outline is `none` |
| orb-row-013 | show-tooltip-on-focus | orb link receives keyboard focus | Tooltip span's computed `opacity` is `1`, matching the hover-revealed state |
| orb-row-014 | apply-current-state | sites=[] | Root element renders with role="navigation" and no `<a>` children; no error |
| orb-row-015 | apply-custom-class | className="" | Root class list is `orb-row` with no empty token |
| orb-row-016 | set-docked-class | docked=false, then docked undefined | Neither render has the `is-docked` class |
| orb-row-017 | apply-current-state | Two sites share id "a", currentSite="a" | Both links have `is-current` and `aria-current="page"` |
## Edge Cases

- **Empty sites array**: Component renders a navigation container with no orbs. No error is thrown; the component degrades gracefully.
- **currentSite not in sites**: No orb receives the current state. The component does not error; aria-current is not applied to any link.
- **currentSite is null/undefined**: Same as above; no orb is marked current.
- **Missing site properties**: The component does not validate site properties and renders them directly without null or undefined checks. If any required property (url, name, emoji, iconGradient) is missing, the component will render an incomplete or broken link and the caller is responsible for ensuring all site data is well-formed.
- **className prop is empty string**: Empty strings are filtered out before joining; class attribute does not contain empty tokens.
- **docked=false and docked=undefined**: No `is-docked` class applied; both cases are treated identically.
- **Duplicate site ids**: Every site whose `id` equals `currentSite` is marked current, so several orbs can be current at once, and React warns about the duplicate `key`; the caller is responsible for unique ids.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sites` | `OrbSite[]` | required | Ordered list of sites to render as orbs. Each `OrbSite` requires `id`, `name`, `emoji`, `iconGradient`, and `url` (all `string`); the component renders them directly and does not validate that they are present. |
| `currentSite` | `string` (an `OrbSite.id`) | `undefined` | ID of the site to mark as current; no orb is marked current when omitted or when it matches no site. |
| `docked` | `boolean` | `undefined` (falsy) | When `true`, applies the `is-docked` class for the fixed-position layout variant. |
| `className` | `string` | `undefined` | Appended to the root container's class list. |

## Deep Linking

Not applicable: This component contains links to other sites but does not itself define a deep-link target; deep linking to the orb-row component is not a use case.

## Localization

The `sites` array supplies site names and emoji, so caller-localized site names are shown as given. The container's accessible name `aria-label="Agentic family"` is a hardcoded English, app-specific string in `OrbRow.tsx` (see **set-navigation-role**); the component has no prop or localization lookup to replace it, so localizing it means changing the component.
## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented: the `orb-row-float` and `orb-row-pulse` animations in `styles/orb-row.css` run unconditionally and have no `prefers-reduced-motion` guard (see Compliance: reduced-motion, failed). |
| Increase Contrast | Not implemented: the component adds no handling; style changes are the consuming stylesheet's responsibility. |
| Differentiate Without Color | Not implemented: the current orb is marked by a gold ring and dot, and by `aria-current="page"` for assistive technology; no shape change is made for users who cannot distinguish color. |
## Feature Flags

Not applicable: No feature flags are defined or consumed in the source code.

## Analytics

Not applicable: The component does not emit analytics events; navigation actions are handled by the browser (link navigation).

## Privacy

Not applicable: The component does not collect, transmit, or store user data.

## Logging

Not applicable: The component does not log diagnostic information.

## Platform Notes

- **React/Web**: `OrbRow.tsx` renders a `<div>` container with an explicit `role="navigation"` (not a native `<nav>` element) and `aria-label="Agentic family"`, mapping over the `sites` array to create `<a>` links. Each link applies its `iconGradient` as an inline `background` style, toggles `is-current`/`aria-current="page"` from `currentSite`, and marks the emoji and current-page indicator `aria-hidden`. Styling (dimensions, spacing, the floating/pulse animations, and the `:focus-visible` tooltip reveal) lives in the associated CSS.

- **SwiftUI**: Build from an `HStack` (the row is horizontal, not a `VStack`) of `Button`/`NavigationLink` views, each with a circular background from a `LinearGradient` parsed from the site's `iconGradient` string. `HStack` has no selection binding, so pass the current site's id in as a plain value and apply the `is-current` treatment with an `.overlay()` ring. Show the site name as the tooltip with `.help(site.name)`. Mark the emoji `Text`/`Image` with `.accessibilityHidden(true)` (not `isHidden`, which only affects visibility, not the accessibility tree), and expose the site name via `.accessibilityLabel()`. Handle `docked` with a conditional `.frame()`/positioning modifier.

- **Compose**: Use a `Row` (or `LazyRow` for many sites) with `Modifier.clickable` per item — not `NavigationLink`, which is a SwiftUI API. Each item is a `Box` with a gradient `Modifier.background()` (parsed from `iconGradient`), a centered emoji, and a Material 3 `TooltipBox` with a `PlainTooltip` showing the site name. Mark the current item with `Modifier.semantics { selected = true }` (mapping to the `is-current` class), and apply `Modifier.padding()` to match orb sizing. Toggle a docked layout `Modifier` (fixed alignment + background) to match `is-docked`.

- **AppKit / UIKit**: Use a `UIStackView`/`NSStackView` (horizontal axis) of `NSButton`/`UIButton` subclasses styled as circular orbs, applying the gradient via `CAGradientLayer` (not `UIGradientView`, which does not exist) on each button's layer. Manage current state with the button's `.selected` trait/state (not `accessibilityCustomContent`), and set `accessibilityLabel` to the site name and `accessibilityTraits` to `.link`. Show the site name as the tooltip with `toolTip` (`NSView.toolTip`; `UIButton.toolTip` on iOS 15+). Render the emoji in an `NSImageView`/`UIImageView` or as attributed button text.

- **WinUI 3**: Use an `ItemsControl` or `ListView` with a per-site `DataTemplate` containing a `Button` whose background is a `LinearGradientBrush` built from `iconGradient`, a centered `TextBlock` for the emoji, and a `ToolTipService.ToolTip` set to the site name. Use a `ListView` if you want `SelectedItem` (an `ItemsControl` has none); otherwise pass the current site's id to each template. Either way, drive a `VisualStateManager` "IsCurrent" state that applies the border/glow used for `is-current`. Map `docked` concretely: when `true`, host the `ItemsControl` in a `Popup` (or a bottom-pinned `Grid.Row`) with a translucent `Background` and rounded `CornerRadius`, matching the fixed-position pill in the web CSS; when `false`, lay it out inline in normal flow.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/orb-row/OrbRow.tsx` | confirmed (1.2.2) |

## Design Decisions

**Decision**: The `sites` array is treated as read-only, and `currentSite` is external state; the component does not manage navigation or page state itself.
**Rationale**: Each site is a simple data object (`url`, `name`, `emoji`, `iconGradient`) supplied by the caller, so keeping the component stateless keeps it composable with any router or state layer.
**Approved**: pending

**Decision**: Current-page links use `aria-current="page"`.
**Rationale**: This follows WCAG best practices for marking the active page within a navigation landmark.
**Approved**: pending

**Decision**: The emoji span and the current-page indicator span are marked `aria-hidden="true"`.
**Rationale**: Both are purely visual reinforcement of information already conveyed by the link's `aria-label` and `href`; announcing them again would be redundant.
**Approved**: pending

**Decision**: The site name span carries `role="tooltip"`.
**Rationale**: The role signals that the span is contextual, hover-revealed help text, though the source does not associate it with the link via `aria-describedby`, so assistive technology receives the site name only through the link's `aria-label`, not through the tooltip role itself.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on `OrbRow.tsx` (links, `aria-label`, `aria-hidden`, `aria-current`) and `styles/orb-row.css` (the `:focus-visible` rules; the `rem`-based emoji and tooltip font sizes next to the fixed `px` orb sizes (dynamic-type-support: partial); the 48px default vs. 36px `max-width: 640px` orb sizing; and the unguarded `orb-row-float`/`orb-row-pulse` animations, which have no `prefers-reduced-motion` guard); the component is pure presentation over the `sites`/`currentSite`/`docked` props with no state or business logic (separation-of-concerns: passed), and `packages/web/packages/controls/src/orb-row/__tests__/OrbRow.test.tsx` covers every conformance vector except orb-row-012 and orb-row-013, which are skipped because jsdom does not evaluate `:focus-visible` or cascade its computed styles (unit-test-coverage: partial).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-11-14 | Mike Fullerton | Downgraded dynamic-type-support to partial, narrowed the WCAG 1.4.13 claim, documented the reduced-motion gap and the hardcoded container label, moved concrete visual values into Appearance, fixed vector wording, added edge case and vectors, and corrected the WinUI, SwiftUI, Compose and AppKit platform notes. |
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case everywhere; add set-link-label, render-focus-indicator, and show-tooltip-on-focus requirements with test vectors; split the folded emoji/tooltip vector and drop the untestable duplicate; add Configuration and Compliance tables; split Design Decisions into Decision/Rationale/Approved entries; correct the dangling tooltip role, the div-vs-nav wording, and the wrong Platform Notes APIs |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Remove non-genuine review marker; clarify missing property handling in Edge Cases |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
