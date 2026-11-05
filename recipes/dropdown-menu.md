---
id: 25de0c8f-b6cb-4e9f-ba30-38afca642232
title: Dropdown Menu
domain: adhsdk://recipes/dropdown-menu
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Positioned menu triggered by a button or link, with support for nested submenus,
  checkbox, and radio items.
platforms:
- typescript
- web
tags:
- menu
- dropdown
- overlay
- navigation
depends-on: []
related:
- adhsdk://recipes/popup-menu
- adhsdk://recipes/gear-menu-trigger
- adhsdk://recipes/category-gear-menu
references:
- https://base-ui.com/react/components/menu
- https://www.w3.org/WAI/WCAG21/Understanding/target-size.html
approved-by: ''
approved-date: ''
---

# Dropdown Menu

## Overview

A dropdown menu is a positioned overlay component that displays a list of actions or options. Triggered by a button, link, or other interactive element, the menu appears adjacent to the trigger and closes when the user selects an item, clicks outside, or presses Escape. The component supports nested submenus, multi-select checkbox items, single-select radio items, labels, and visual separators.

## Behavioral Requirements

- **render-trigger**: The component MUST render a trigger element (button, link, or other control) that opens the menu.
- **render-content**: The component MUST render a positioned popup containing menu items.
- **close-on-item-select**: The component MUST close the menu when a user selects a standard menu item (unless `closeOnClick` is explicitly set to false).
- **close-on-link-select**: DropdownMenuLinkItem MUST close the menu after the link click handler fires, preserving browser link semantics (middle-click, Cmd+click for new tabs).
- **close-on-escape**: The component MUST close the menu when the user presses Escape.
- **close-on-outside-click**: The component MUST close the menu when the user clicks outside the menu and trigger.
- **support-checkbox-items**: Checkbox items MUST support a `checked` state and MUST render a checkmark icon when checked.
- **support-radio-items**: Radio items MUST support a single-selected value within a RadioGroup and MUST render a circle indicator when selected.
- **support-submenus**: SubmenuRoot items MUST open a nested menu positioned relative to the parent menu, and MUST close when the user moves focus away from the submenu.
- **position-with-offset**: DropdownMenuContent MUST accept `side`, `sideOffset`, `align`, and `alignOffset` props to control menu positioning. Default `sideOffset` is 4px.
- **support-semantic-classes**: All menu elements MUST apply semantic CSS class names prefixed with `adh-dropdown-menu__` to enable consistent theming.
- **support-inset-items**: Menu items and labels MUST support an `inset` prop that adds the `adh-dropdown-menu__item--inset` class for visual indentation.
- **support-accent-items**: Menu items MUST support an `accent` prop that applies the theme's accent styling on hover/focus via the `adh-dropdown-menu__item--accent` class.
- **close-on-click-default**: CheckboxItem, RadioItem, and LinkItem SHOULD default `closeOnClick` to `true`, closing the menu when the item is clicked. MenuItem's `closeOnClick` has no explicit default and inherits Base UI's default of `true` (see close-on-item-select).
- **keyboard-navigation**: The component MUST support arrow-key navigation of menu items: ArrowDown/ArrowUp move focus between items, and ArrowRight/ArrowLeft open/close submenus.
- **focus-management**: The component MUST move focus into the menu, onto the first focusable item, when the menu opens via the trigger, and MUST return focus to the trigger when the menu closes.
- **checkbox-state-announcement**: Checkbox items MUST announce their checked state to assistive technology via `aria-checked`.
- **disabled-state-announcement**: Disabled items MUST announce their disabled state via `aria-disabled`. This does not guarantee they are skipped by keyboard navigation; see the **Focus on disabled item** edge case.
- **submenu-indication**: Submenu triggers MUST indicate that they open a submenu, via the ChevronRight icon and `aria-haspopup="menu"`.

## Appearance

- **Positioning**: Positioned via Base UI Positioner (side, sideOffset, align, alignOffset); z-index 50.
- **Item padding**: Applied via semantic `adh-dropdown-menu__item` class.
- **Item inset**: When `inset={true}`, applies `adh-dropdown-menu__item--inset` class for additional horizontal padding.
- **Item accent**: When `accent={true}`, applies `adh-dropdown-menu__item--accent` class for the theme's accent styling on hover/focus.
- **Checkbox icon**: Check icon from lucide-react rendered when CheckboxItem is checked, styled via `adh-dropdown-menu__indicator-check` class.
- **Radio icon**: Circle icon from lucide-react rendered when RadioItem is selected, styled via `adh-dropdown-menu__indicator-dot` class.
- **Submenu chevron**: ChevronRight icon from lucide-react rendered on SubmenuTrigger, styled via `adh-dropdown-menu__sub-trigger-chevron` class.
- **Separator**: Rendered via MenuPrimitive.Separator with class `adh-dropdown-menu__separator`.
- **Label**: Plain styled div with class `adh-dropdown-menu__label`, supports `inset` prop.

## States

| State | Appearance change |
|-------|------------------|
| Default | Menu hidden, trigger rendered in default state |
| Open | Menu popup visible at positioned location, trigger may display open state |
| Item hovered | Item background changes (neutral surface, or the theme's accent styling for accent items) |
| Item focused | Item background changes, focus outline visible |
| Item disabled | Item appearance dimmed or greyed (if disabled prop is passed) |
| Checkbox checked | Checkmark icon rendered inside indicator slot |
| Radio selected | Circle indicator rendered inside indicator slot |
| Submenu open | Nested menu appears positioned relative to parent |

## Accessibility

- **Role**: Menu items MUST have the `menuitem` role (provided by Base UI MenuPrimitive).
- **Label requirement**: Menu items MUST have accessible text content or an aria-label.
- **Keyboard navigation**: Menu MUST support arrow key navigation (up/down to move focus, left/right to open/close submenus).
- **Escape key**: Menu MUST close on Escape, returning focus to the trigger.
- **Focus management**: Focus MUST return to the trigger when the menu closes.
- **Checkbox state announcement**: Checkbox items MUST announce checked state to assistive technology via aria-checked.
- **Radio state announcement**: Radio items MUST announce selected state to assistive technology via aria-checked.
- **Disabled state announcement**: Disabled items MUST announce disabled state via aria-disabled.
- **Submenu indication**: Submenu triggers MUST indicate they open a submenu (via ChevronRight icon and aria-haspopup).
- **Minimum target size**: Menu items SHOULD have a minimum touch/click target size of 44×44px (WCAG 2.5.5 Target Size Enhanced; see references).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dropdown-001 | render-trigger, render-content | Render DropdownMenu with Trigger and Content | Trigger element renders; clicking trigger shows menu content |
| dropdown-002 | close-on-item-select | Render MenuItem inside open menu; click it | Menu closes after click |
| dropdown-003 | close-on-link-select | Render LinkItem inside open menu; click it | Menu closes; browser link semantics preserved (middle-click opens new tab) |
| dropdown-004 | close-on-escape | Open menu; press Escape key | Menu closes; focus returns to trigger |
| dropdown-005 | close-on-outside-click | Open menu; click outside | Menu closes |
| dropdown-006 | support-checkbox-items | Render CheckboxItem with checked={true} | Checkmark icon appears in indicator slot |
| dropdown-007 | support-checkbox-items | Render CheckboxItem with checked={false} | Indicator slot is empty |
| dropdown-008 | support-radio-items | Render RadioGroup with RadioItem selected | Circle indicator appears in indicator slot |
| dropdown-009 | support-radio-items | Render RadioGroup with RadioItem unselected | Indicator slot is empty |
| dropdown-010 | support-submenus | Render SubmenuRoot with SubmenuTrigger inside open parent menu | Submenu opens; ChevronRight icon renders on trigger |
| dropdown-011 | position-with-offset | Render DropdownMenuContent with side="bottom" sideOffset={8} | Content positioned 8px below trigger |
| dropdown-012 | position-with-offset | Render DropdownMenuContent with default sideOffset | Content positioned 4px from trigger (default) |
| dropdown-013 | support-semantic-classes | Render MenuItem | MenuItem renders with class adh-dropdown-menu__item |
| dropdown-014 | support-inset-items | Render MenuItem with inset={true} | MenuItem renders with classes adh-dropdown-menu__item adh-dropdown-menu__item--inset |
| dropdown-015 | support-accent-items | Render MenuItem with accent={true} | MenuItem renders with classes adh-dropdown-menu__item adh-dropdown-menu__item--accent |
| dropdown-016 | close-on-click-default | Render open menu with CheckboxItem; click it | Menu closes (closeOnClick defaults to true) |
| dropdown-017 | close-on-click-default | Render open menu with RadioItem; click it | Menu closes (closeOnClick defaults to true) |
| dropdown-018 | close-on-click-default | Render open menu with LinkItem; click it | Menu closes (closeOnClick defaults to true) |
| dropdown-019 | keyboard-navigation | Open menu; press ArrowDown then ArrowUp | Focus moves to the next item, then back to the previous item |
| dropdown-020 | focus-management | Open menu via trigger click | Focus moves into the menu, landing on the first focusable item |
| dropdown-021 | checkbox-state-announcement | Render CheckboxItem with checked={true}; inspect DOM | Item exposes aria-checked="true" |
| dropdown-022 | disabled-state-announcement | Render MenuItem with disabled={true}; attempt to move focus to it via ArrowDown | Focus moves onto the disabled item (Base UI's list navigation does not skip disabled items) and it exposes aria-disabled="true" |
| dropdown-023 | submenu-indication | Render SubmenuTrigger | Trigger exposes aria-haspopup="menu" and renders the ChevronRight icon |
| dropdown-024 | support-submenus | Open SubmenuRoot; move focus outside the submenu (e.g. ArrowLeft to the parent item) | Submenu closes while the parent menu remains open |

## Edge Cases

- **Empty menu**: Menu with no items still renders and positions correctly; no minimum height constraint forces item rendering.
- **Very long item text**: Item text that exceeds the available menu width truncates with an ellipsis rather than wrapping (see the long-item-text-truncates design decision).
- **Disabled items**: Items with a `disabled` prop render in disabled state and do not respond to click events.
- **No trigger provided**: `MenuPrimitive.Root` renders without error. Without a Trigger child, the menu has no interactive control that opens it and MUST remain closed unless opened programmatically via a controlled `open` prop; Base UI emits no dev-time warning for this case.
- **Multiple submenus**: Nested submenus at depth >1 position relative to their parent submenu; no depth limit enforced by component.
- **Rapid item clicks**: Clicking multiple items rapidly before menu closes closes menu on first click; subsequent clicks do not interact with menu items if menu is already closed.
- **Focus on disabled item**: Arrow-key navigation (ArrowUp/ArrowDown/Home/End) does NOT skip disabled items — Base UI's list navigation runs with an empty `disabledIndices` set, so a disabled item can still receive focus and is exposed via `aria-disabled="true"`; it is only dimmed visually (`pointer-events: none`, reduced opacity). The one exception: when the menu opens via the keyboard and the first item is disabled, that initial focus placement skips it.
- **Menu with only separators**: Menu renders separators without error; visually appears as empty menu with dividers.
- **Checkbox item without checked prop**: CheckboxItem without explicit `checked` prop behaves as unchecked (no indicator icon shown).
- **Radio item without value**: A RadioItem in a RadioGroup without a `value` prop MUST NOT participate in group selection: it renders and remains clickable, but selecting it does not change the RadioGroup's value and it never renders the selected indicator.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | "top" \| "bottom" \| "right" \| "left" \| "inline-start" \| "inline-end" | undefined | Position of menu relative to trigger (DropdownMenuContent / DropdownMenuSubContent) |
| `sideOffset` | number | 4 (for DropdownMenuContent); undefined (for DropdownMenuSubContent) | Distance in pixels between menu and trigger edge (DropdownMenuContent / DropdownMenuSubContent) |
| `align` | "start" \| "center" \| "end" | undefined | Alignment of menu along the perpendicular axis to `side` |
| `alignOffset` | number | undefined | Additional offset along the alignment axis |
| `inset` | boolean | false | Add visual indentation to MenuItem, DropdownMenuLabel, DropdownMenuSubTrigger |
| `accent` | boolean | false | Apply the theme's accent styling on MenuItem, CheckboxItem, RadioItem, DropdownMenuSubTrigger |
| `closeOnClick` | boolean | true (for MenuItem, inherited from Base UI's default; explicit true for LinkItem, CheckboxItem, RadioItem) | Close menu when item is clicked |
| `checked` | boolean | undefined | Checked state for CheckboxItem |
| `children` | ReactNode | undefined | Content rendered inside component (text, icons, elements) |

## Deep Linking

Not applicable: Dropdown menus are overlay components with no document-level or app-level navigation identity. Individual menu items may navigate (via DropdownMenuLinkItem), but the menu itself has no persistent URL state.

## Localization

Not applicable: Dropdown menu components render no internal text strings. Localization is the responsibility of the consuming application's menu item labels and text content.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: this component implements no animation directly in its source. If the external `components.css` theme layer adds an open/close transition, that layer MUST honor `prefers-reduced-motion`. |
| Increase Contrast | The `adh-dropdown-menu__item--accent` accent styling MUST meet WCAG AA contrast in high-contrast mode; enforced by the semantic CSS theme layer this component's classes hook into (see support-accent-items). |
| Differentiate Without Color | Satisfied: checked and selected states render the Check/Circle icon in the indicator slot regardless of color, so selection state is never conveyed by color alone. |

## Feature Flags

Not applicable: The dropdown menu component does not implement feature flags. Feature flagging is the responsibility of consuming code that conditionally renders menu items or the menu itself.

## Analytics

Not applicable: The dropdown menu component does not implement analytics events. Event tracking is the responsibility of consuming code that attaches click handlers or change handlers to menu items.

## Privacy

Not applicable: The dropdown menu component does not collect, store, or transmit user data. No sensitive information is handled.

## Logging

Not applicable: The dropdown menu component does not implement logging. Consuming code may attach event handlers or side effects to menu interactions for debugging or monitoring.

## Platform Notes

- **React/Web**: Implemented using Base UI's `Menu` primitive (`@base-ui/react/menu`) in the `@adh-sdk/ui` package's dropdown-menu component (see the reference-implementation design decision). Trigger, Content, MenuItem, CheckboxItem, RadioItem, SubmenuTrigger, SubmenuRoot, SubmenuContent, Positioner, and Portal are pass-through wrappers around MenuPrimitive components. Icons (Check, ChevronRight, Circle) are from lucide-react. Semantic CSS classes (`adh-dropdown-menu__*`) are applied to support theming via a public surface; consumers may pass an additional `className`, which is merged with the semantic classes rather than replacing them.
- **SwiftUI**: Use a SwiftUI `Menu`, which already renders native `Toggle` for checkbox items and `Picker(.inline)` for radio-style single-select groups with native checkmarks — custom indicator views are not needed. Differences: SwiftUI Menu does not support arbitrary positioning (side/sideOffset/align); it positions itself relative to its anchor, so a popover-based menu with custom positioning logic is only needed when explicit offset control is required. Semantic class mapping is not applicable; use SwiftUI native styling instead. Support `inset` and `accent` via SwiftUI padding and foreground color/tint modifiers.
- **Compose**: Start from Material Design's DropdownMenu or build a custom menu composition. Differences: Material DropdownMenu has limited positioning control; use a Popup or Dialog for full side/offset control. Checkbox and RadioItem support is available via native Compose components. No semantic CSS classes; use Compose's Material theming system. Map `inset` to padding and `accent` to color overrides.
- **AppKit / UIKit**: Use NSMenu on macOS or UIMenu on iOS (iOS 13+). Differences: NSMenu and UIMenu do not support custom positioning props (side/sideOffset/align); positioning is determined by the platform. CheckboxItem and RadioItem state is supported via NSMenuItem/UIAction state. No semantic CSS classes; use native platform styling. `inset` and `accent` map to platform menu item attributes and custom appearance if needed.
- **WinUI 3**: Use the MenuFlyout control with MenuFlyoutItem children. Positioning is controlled via the `Placement` property (equivalent to `side`). MenuFlyout has no `VerticalOffset`/`HorizontalOffset` properties; offset (equivalent to `sideOffset` + `alignOffset`) is set by calling `ShowAt(target, new FlyoutShowOptions { Position = ..., Placement = ... })` instead. Checkbox items use ToggleMenuFlyoutItem; radio items use `RadioMenuFlyoutItem`. Semantic class names do not apply to WinUI; use native visual state customization via ControlTemplate. Implement `inset` via MenuFlyoutItem Padding override; `accent` via Background brush override. Submenu support via nested MenuFlyout and MenuFlyoutSubItem.

## Design Decisions

**Semantic CSS class names**
**Decision**: All components apply stable `adh-dropdown-menu__*` class names to the DOM to provide a public theming surface.
**Rationale**: This design enables theme editors and user CSS overrides to target dropdown menu elements without relying on implementation details. The class names are committed to backward compatibility.
**Approved**: pending

**closeOnClick default flips for checkbox, radio, and link items**
**Decision**: This wrapper inverts Base UI's `closeOnClick` default from `false` to `true` for `CheckboxItem`, `RadioItem`, and `LinkItem`.
**Rationale**: Base UI's `CheckboxItem` and `RadioItem` default `closeOnClick` to `false` to keep the menu open while toggling state, but this wrapper matches typical dropdown menu behavior where selecting an option closes the menu. `LinkItem` is defaulted to `true` for the same reason: in this codebase, `render={<Link/>}` navigates client-side without unmounting the header, so the menu would remain open after navigation unless explicitly closed. This decision is traced to Base UI's `Menu` documentation and to the code comments on the `DropdownMenuLinkItem` and `DropdownMenuCheckboxItem` wrapper functions.
**Approved**: pending

**Submenu positioning defaults**
**Decision**: `DropdownMenuSubContent` does not set its own positioning defaults.
**Rationale**: Base UI's Positioner already defaults to `side="inline-end"` (right in LTR) and `align="start"` (top), which produces the classic submenu flyout behavior; explicit positioning overrides remain available via props.
**Approved**: pending

**SubmenuTrigger includes ChevronRight icon**
**Decision**: The ChevronRight icon is always rendered on `SubmenuTrigger` as a visual indicator that the item opens a submenu; it is not conditionally renderable.
**Rationale**: Consuming code cannot hide it, keeping the submenu affordance consistent everywhere the component is used.
**Approved**: pending

**Label component not bound to Group**
**Decision**: `DropdownMenuLabel` is a plain styled `<div>`, not Base UI's `MenuPrimitive.GroupLabel`.
**Rationale**: `MenuPrimitive.GroupLabel` throws when rendered outside a `Menu.Group`, and this label is also used standalone (e.g. as a heading in the DebugMenu). This flexibility comes at the cost of no built-in ARIA relationship to a group.
**Approved**: pending

**Reference implementation**
**Decision**: The `@adh-sdk/ui` package's dropdown-menu component — `DropdownMenu`, `DropdownMenuContent`, `DropdownMenuItem`, `DropdownMenuLinkItem`, `DropdownMenuCheckboxItem`, `DropdownMenuRadioItem`, and related exports, built on Base UI's `Menu` primitive — is the reference implementation for this ingredient's behavioral contract.
**Rationale**: Citing the package and exported symbol names, rather than a file path or line numbers, keeps the reference stable as the file is refactored. See the Base UI `Menu` documentation in references.
**Approved**: pending

**Long item text truncates**
**Decision**: Item text that exceeds the available menu width truncates with an ellipsis rather than wrapping.
**Rationale**: Keeps the menu's width and item height consistent; wrapping would enlarge item height unpredictably and complicate keyboard-navigation focus rings.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The `partial` statuses reflect that keyboard navigation, focus management, ARIA state announcements, text sizing, and contrast are delegated to Base UI's `Menu` primitive and the external `components.css` theme layer rather than implemented in this wrapper's source; `semantic-markup` is `passed` because the wrapper directly applies the `adh-dropdown-menu__*` classes in source, and `rtl-layout-support` is `passed` because the `side`/`align` props accept the logical `inline-start`/`inline-end` values shown in the Configuration table. `separation-of-concerns` passes because every export is a thin wrapper around Base UI's `MenuPrimitive.*` with no internal state or business logic; `unit-test-coverage` passes because `dropdownMenu.test.tsx` imports the dropdown-menu components directly and exercises them with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added missing keyboard-navigation/focus-management/checkbox-state-announcement/disabled-state-announcement/submenu-indication requirements; fixed dropdown-022 and Focus-on-disabled-item edge case (Base UI does not skip disabled items). Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and merged the three closeOnClick-default requirements into one; fixed the SwiftUI and WinUI 3 platform notes; replaced stale line-number and unsourced touch-target citations with symbol names and WCAG/Base UI references; described accent styling via the theme's accent token instead of a fixed color; resolved the two undefined edge cases; converted Design Decisions to the Decision/Rationale/Approved format and added two new decisions; filled in tags, related, and Compliance; added test vectors for accessibility and submenu-close coverage; fixed the ambiguous closeOnClick default and moved platform-specific paths out of Configuration and Platform Notes. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
