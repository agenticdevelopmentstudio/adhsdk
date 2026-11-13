---
id: cebee4d7-3d01-440d-a35e-6220957c1603
title: "Gear Menu Trigger"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A triggering button with a settings gear icon that opens a dropdown menu of actions on a list or collection."
platforms:
  - typescript
  - web
tags:
  - ui
  - menu
  - trigger
  - action
depends-on:
  - 25de0c8f-b6cb-4e9f-ba30-38afca642232
related: []
references: []
approved-by: ""
approved-date: ""
---

# Gear Menu Trigger

## Overview

A small, fixed-size icon button that triggers a dropdown menu. The component is a visual signal—used in rail headers or home bars—indicating that a list or collection has associated actions. The gear metaphor consistently marks action menus across all apps using this toolkit, and this component ensures that sign remains visually identical everywhere it appears. The component is deliberately minimal: it renders only the trigger; the menu content and items are composed by the host.

## Behavioral Requirements

- **required-label**: The component MUST accept a `label` prop (string) that describes what the menu acts on, as a screen reader announces it (e.g., "Registry actions"). TypeScript enforces that the prop is provided; the component does not validate that the value is non-empty — the host guarantees a meaningful, non-empty label.
- **gear-icon**: The component MUST render a settings gear icon (from Lucide React, `Settings` component) at 14px size.
- **dropdown-trigger**: The component MUST render as a `DropdownMenuTrigger`, and MUST be composed as a child of a host-provided `DropdownMenu` — the host supplies the `DropdownMenuContent` that the trigger opens.
- **disabled-state**: The component MUST accept a `disabled` prop (boolean, defaults to `false`) that disables user interaction.
- **disabled-opacity**: When `disabled` is `true`, the component MUST apply 40% opacity to the trigger.
- **icon-aria-hidden**: The component MUST render the settings icon with `aria-hidden` set to `true` so the icon does not announce redundantly.
- **aria-label**: The component MUST set the `aria-label` attribute of the trigger to the value of the `label` prop.
- **class-override**: The component MUST accept an optional `className` prop that allows callers to override or extend the default styling using Tailwind class names.
- **focus-indicator**: The component MUST remove the default browser outline (`outline-none`) and rely solely on the `focus-visible` ring (2px, `apt-gold/40`) as the visible focus indicator.
- **hover-color**: On hover, the component MUST change its foreground color from `text-apt-text-dim` to `text-apt-text`.

## Appearance

- **Size**: 24px × 24px (Tailwind `size-6`). Fixed; no resize.
- **Corner radius**: Small rounded corners (Tailwind `rounded`).
- **Icon size**: 14px (Lucide `Settings` component `size={14}`).
- **Default text color**: `text-apt-text-dim` — the dimmed-text token, sourced from the theme's `--color-text-dim` role (`@adh-sdk/themes`).
- **Hover text color**: `text-apt-text` — the normal-text token, sourced from the theme's `--color-on-surface` role, shown on hover (requirement **hover-color**).
- **Focus ring**: 2px solid ring with `apt-gold/40` — the theme's primary/accent role at 40% opacity — shown on `focus-visible` (requirement **focus-indicator**).
- **Disabled opacity**: 40% opacity (Tailwind `opacity-40`) when disabled.
- **Padding/spacing**: Icon is centered within the 24px square via flex centering.
- **Background**: Transparent (no background color set).
- **Border**: None.
- **Shadow**: None.

## States

| State | Appearance change |
|-------|------------------|
| Default | 24px square, dimmed text color, rounded corners, no outline |
| Hover | Text color changes to normal brightness |
| Focused (keyboard) | 2px gold/40 ring displayed around the trigger |
| Active/Pressed | (No distinct visual change specified; focus ring remains) |
| Disabled | Opacity reduced to 40%, interaction disabled |

## Accessibility

- **Role**: Button (implied by `DropdownMenuTrigger` semantic role).
- **Label**: REQUIRED. The `label` prop provides the accessible name via `aria-label` (requirement **aria-label**). It MUST describe what the menu acts on (e.g., "Registry actions", not just "Menu" or "Actions"); the component does not validate non-emptiness, so the host guarantees a meaningful, non-empty label (requirement **required-label**).
- **Icon announcement**: The icon is `aria-hidden` (requirement **icon-aria-hidden**) to avoid redundant announcements, since the `aria-label` fully describes the button's purpose.
- **Keyboard navigation**: The component is focusable and activatable via keyboard (Enter/Space) because it is a `DropdownMenuTrigger`.
- **Focus indicator**: A 2px gold/40 ring is displayed on keyboard focus (requirement **focus-indicator**), meeting visibility requirements for keyboard navigation.
- **Disabled state announcement**: When `disabled` is `true`, the native `disabled` attribute on the trigger conveys the disabled state to assistive technology; the visual opacity change provides visual feedback. This also removes the trigger from the tab order while disabled — the same as any native disabled button — so a screen-reader user tabbing through the page skips it entirely rather than encountering it as unavailable.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gear-001 | gear-icon, dropdown-trigger | Render with `label="Test"` | Settings icon (14px) is rendered and is `aria-hidden`; component is a clickable/activatable trigger |
| gear-002 | aria-label | Render with `label="Registry actions"` | `aria-label="Registry actions"` is set on the trigger element |
| gear-003 | required-label | Attempt to render without `label` prop | TypeScript compiler error (missing required prop) |
| gear-004 | disabled-state, disabled-opacity | Render with `disabled={true}` | Trigger element has `disabled` attribute; opacity is 40% |
| gear-005 | disabled-state | Render with `disabled={true}` and attempt to click/activate | Trigger does not respond to interaction (native `disabled` behavior) |
| gear-006 | class-override | Render with `className="custom-class"` | Custom class is applied to the trigger element alongside default styles |
| gear-007 | icon-aria-hidden | Render and inspect icon element | Icon has `aria-hidden="true"` |
| gear-008 | focus-indicator | Render and inspect trigger element (not focused) | `outline: none` is applied (no browser outline visible) |
| gear-009 | hover-color | Render and hover over trigger | Text color changes from `text-apt-text-dim` to `text-apt-text` |
| gear-010 | focus-indicator | Render and focus via keyboard | 2px gold/40 focus ring is visible around the 24px square, serving as the sole focus indicator |

## Edge Cases

- **Empty or whitespace-only label**: The component does not validate or trim the `label` prop. If an empty string or whitespace-only string is passed, `aria-label` will be set to that value, and screen readers will announce it as empty or whitespace. The host is responsible for providing a non-empty label.
- **Very long label**: If `label` is a very long string, the `aria-label` will reflect that full string, but the visual trigger remains 24px and does not resize or wrap text. Screen readers announce the full label.
- **Disabled triggering dropdown**: When `disabled` is `true`, the trigger is inert and does not open the associated `DropdownMenuContent`. This is native browser behavior for a disabled button.
- **No DropdownMenuContent provided**: The component is the trigger only. If no `DropdownMenuContent` is composed as a sibling by the host, the trigger renders but has no effect when activated. The host MUST provide the menu content.
- **Multiple instances on same page**: Each instance is independent; the `label` prop distinguishes them for accessibility.
- **Rapid clicks when enabled**: If the trigger is rapidly clicked, the dropdown menu behavior is governed by the `DropdownMenuTrigger` component; repeated activations toggle or re-open the menu normally.

## Configuration

Not applicable. The component has no configuration options beyond its props (`label`, `disabled`, `className`).

## Deep Linking

Not applicable. This component is a UI trigger; it does not represent a navigable route or deep linkable state on its own. Deep linking applies to the menu's content and items, which are the host's responsibility.

## Localization

The `label` prop is a string that the host provides; the host is responsible for localization of the label. The component itself has no internal strings to localize.

## Accessibility Options

- **Reduce Motion**: Not applicable. The component is static and has no animations or transitions defined.
- **Increase Contrast**: The component relies on token-based colors (`apt-text-dim`, `apt-text`, `apt-gold/40`); actual contrast compliance depends on the active theme's resolved token values (see Compliance: **contrast-ratio**) and has not been verified against WCAG 1.4.11 (3:1 minimum for non-text contrast) at the source level.
- **Differentiate Without Color**: Not applicable. The component uses a gear icon that conveys meaning through shape, and state changes via opacity and focus rings, not color alone.

## Feature Flags

Not applicable. The component has no feature flags.

## Analytics

Not applicable. The component is a trigger; analytics event capture for menu interactions is the host's responsibility when composing the `DropdownMenuContent`.

## Privacy

Not applicable. The component does not collect, store, transmit, or process any data.

## Logging

Not applicable. The component has no logging requirements.

## Platform Notes

- **React/Web**: Defined in `packages/web/packages/ui/src/blocks/gear-menu-trigger.tsx`. It is a React functional component that wraps `DropdownMenuTrigger` from the local component library. The Lucide React `Settings` icon is imported and rendered at 14px. Tailwind CSS provides all styling. The component is exported as a named export.
- **SwiftUI**: Use SwiftUI's `Menu` view as both trigger and menu container — no separate flyout wiring is needed. Render the gear glyph via `Image(systemName: "gear")` sized with `.font(.system(size: 14))` inside a `.frame(width: 24, height: 24)` label. Apply the dimmed foreground via a semantic token-backed `Color` and switch to the normal-text token on hover using `.onHover`. Set the accessible name with `.accessibilityLabel(label)`. Disable via `.disabled(disabled)` and apply `.opacity(0.4)` when `disabled` is true to match the token. On touch platforms, keep the 24×24pt visual frame but pad the hit area to at least 44×44pt (e.g. `.contentShape(Rectangle())` over a larger invisible frame) so the tap target meets the platform minimum without changing the visible size.
- **Compose**: Use Compose's `IconButton` wrapping the settings glyph, composed alongside a `DropdownMenu`. `IconButton`'s own default touch target (48.dp minimum) gives the platform-minimum hit area independently of the 24.dp visible icon area. Render the settings icon via `Icons.Default.Settings` at `size = 14.dp`, with `contentDescription = null` so it is hidden from screen readers. Apply the dimmed color as a `Color` parameter and switch it on hover/press via `interactionSource`. Use `enabled = !disabled` and apply `Modifier.alpha(0.4f)` when disabled. Set `Modifier.semantics { contentDescription = label }` on the button for the accessible name.
- **AppKit / UIKit**: On iOS, use `UIButton(type: .system)` configured with `menu` set to the host's `UIMenu` and `showsMenuAsPrimaryAction = true`, so the system opens the menu on tap without custom gesture code. Set the button's image to `UIImage(systemName: "gear")` at a 14pt point size, inside a 24×24pt frame; pad the hit area (e.g. via `configuration.contentInsets` or an invisible overlay) to at least 44×44pt to meet the HIG minimum without enlarging the visible glyph. Set the `accessibilityLabel` property (not `setAccessibilityLabel()`) to the `label` parameter. Use `isEnabled` for the disabled state and `alpha = 0.4` to match the token. On macOS with AppKit, use `NSPopUpButton` configured as a pull-down (`pullsDown = true`) with an `NSMenuItem` image set to the same SF Symbol; call `setAccessibilityLabel(_:)` for the accessible name, and use `isEnabled` for the disabled state.
- **WinUI 3**: Use a `Button` with `Flyout` set to a `MenuFlyout`, so the platform's own `PointerOver` / `Pressed` / `Disabled` visual states drive the hover and disabled appearance instead of hand-wired `PointerEntered`/`PointerExited` handlers. Set the button's `Content` to a `FontIcon` using the Segoe Fluent Icons glyph `` (the settings glyph — `Symbol.Settings` belongs to `SymbolIcon`, not `FontIcon`) at 14pt `FontSize`. Set `Width` and `Height` to 24 (`ActualWidth`/`ActualHeight` are read-only render-time values, not settable). Set `AutomationProperties.Name` to the `label` parameter. Use `IsEnabled` to manage the disabled state and bind `Opacity` to `0.4` when disabled. Apply a `CornerRadius` for rounded corners, and rely on the control's built-in `Focused` visual state to show the 2px gold/40 focus ring rather than manual focus-tracking code.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/gear-menu-trigger.tsx` | unverified |

## Design Decisions

- **Decision**: Fix the trigger at 24×24px and make it non-resizable.
  **Rationale**: It is a small, compact icon button that fits rail headers and home bars, and stays a fleet-wide sign for "actions on this list" only while every instance looks the same. A developer who needs a different size should compose a custom trigger rather than parameterize this component.
  **Approved**: pending

- **Decision**: Mark the settings icon `aria-hidden`.
  **Rationale**: The `aria-label` already describes the button's action (e.g., "Registry actions"), so the icon itself adds no information and would clutter screen reader output if announced.
  **Approved**: pending

- **Decision**: Exclude menu content (`DropdownMenuContent`, menu items) from the component; render the trigger only.
  **Rationale**: Every list or collection may have different actions, so a one-size-fits-all menu would be unmaintainable. Keeping the component trigger-only keeps it reusable; the host composes it with its own content inside a `DropdownMenu`.
  **Approved**: pending

- **Decision**: Map the `disabled` prop to the trigger's native `disabled` attribute rather than `aria-disabled`.
  **Rationale**: This gives keyboard and assistive technology users the browser's standard disabled-state signal; the tradeoff is that it also removes the trigger from the tab order while disabled (see Accessibility).
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`screen-reader-support`, `keyboard-navigable`, and `semantic-markup` pass on the `aria-label`, `aria-hidden`, and native `DropdownMenuTrigger` semantics visible in the source. `contrast-ratio` is partial because the dimmed foreground and `gold/40` focus ring resolve through theme tokens whose values the source does not fix. `touch-target-size` is partial because the 24×24 CSS-pixel trigger meets the web source's minimum, but iOS and Compose ports need the platform-minimum hit area called out in Platform Notes. `separation-of-concerns` is `passed` because the component is pure presentation over `DropdownMenuTrigger` with no business logic; `unit-test-coverage` is `failed` because no test exercises `gear-menu-trigger.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case, merged outline-none into a focus-indicator requirement and added a hover-color requirement, rephrased the trigger requirement as host-composed within a DropdownMenu, reformatted Design Decisions into Decision/Rationale/Approved blocks, replaced the "Not applicable" Compliance section with an accessibility checks table, added dropdown-menu to depends-on, corrected Platform Notes APIs, and noted the native-disabled tab-order tradeoff |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
