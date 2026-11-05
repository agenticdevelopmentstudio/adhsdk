---
id: 3562bffe-c137-4f4e-91da-f9ef27a5b712
title: Markdown Theme Switcher
domain: adhsdk://recipes/markdown-theme-switcher
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A dropdown selector for choosing between predefined markdown viewing themes.
platforms:
- typescript
- web
tags:
- theme-selection
- dropdown
- markdown-viewer
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Markdown Theme Switcher

## Overview

The Markdown Theme Switcher is a theme picker component for the MarkdownViewer. It renders as a labeled dropdown (native `<select>`) that allows users to switch between available reading themes. The component is self-contained and emits a callback when the user selects a different theme.

## Behavioral Requirements

- **active-theme**: The control MUST accept the id of the currently active theme as an input value.
- **mark-active-selection**: The control MUST display the theme identified by the active theme id as the current selection.
- **emit-theme-change**: The control MUST invoke a change callback with the newly selected theme's id whenever the user picks a different theme.
- **render-theme-options**: The control MUST present one selectable option per theme in the available theme registry, showing each theme's label as the visible text and using each theme's id as the underlying value.
- **unique-control-id**: The control MUST generate a unique identifier for its selection element so that multiple instances on the same page do not collide.
- **label-control**: The control MUST render a visible label that is programmatically associated with the selection element via the unique identifier.
- **group-container**: The control MUST wrap the label and selection element in a single container element, associating them as one interaction unit.
- **accessible-label**: The control MUST expose the accessible name "Select reading theme" on the selection element for screen reader users.

## Appearance

- **Layout**: Flex row, items centered vertically, 8px gap between label and select
- **Label styling**: No text wrapping, 12px (0.75rem) font size, dimmed text color token `apt-text-dim`
- **Select styling**: 32px height, width auto with a 112px minimum, 0 vertical padding, 12px (0.75rem) font size
- **Background**: Inherits from the Select primitive
- **Border**: Inherits from the Select primitive

## States

| State | Appearance change |
|-------|------------------|
| Default | The control shows the active theme's label; the dropdown is closed |
| Focused | The control shows a visible focus indicator (inherited from the Select primitive); the dropdown stays closed until activated |
| Open | Activating the focused control (click, Enter, Space, or an arrow key) expands the dropdown to show all available options |
| Option highlighted | Hovering or keyboard-navigating to an option highlights it (native browser behavior) |

## Accessibility

- **Role**: The native `<select>` element exposes the `combobox` role to assistive technology (a single-selection native select maps to ARIA `combobox`, not `listbox`); no additional ARIA role is needed.
- **Label requirement**: A visual `<label>` element (via `htmlFor`) and an `aria-label` on the select both provide an accessible name; the `aria-label` ("Select reading theme") takes precedence in the computed accessible name. It contains the visible label text ("Theme") as a substring, satisfying WCAG 2.5.3 Label in Name.
- **Group container**: The wrapping `role="group"` associates the label and control as one interaction unit; it carries no accessible name of its own, so screen readers rely on the control's own accessible name (see **accessible-label**), not the group's.
- **Keyboard navigation**: The native select supports standard keyboard interaction (arrow keys, Enter/Space to open, arrow keys to navigate options, Enter to select)
- **Screen reader**: Screen readers announce the select's accessible name ("Select reading theme") and the option text when navigating
- **Touch/click target**: The control is 32px tall (the component's `h-8` sizing) with an auto width and a 112px minimum; the label is adjacent and can be clicked to focus the control. See **touch-target-size** in Compliance.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-001 | active-theme, mark-active-selection | `activeThemeId="dark"` with three themes in the registry (`light`, `dark`, `high-contrast`) | The control's selected value is `"dark"` |
| theme-002 | mark-active-selection | Component re-rendered with `activeThemeId` changed from `"light"` to `"high-contrast"` | The control's selected value changes to `"high-contrast"`, displaying the label "High Contrast" |
| theme-003 | emit-theme-change | User selects a different theme from the control | The change callback is invoked once with the selected theme's id string |
| theme-004 | render-theme-options | Registry contains `{id: "light", label: "Light"}`, `{id: "dark", label: "Dark"}`, `{id: "high-contrast", label: "High Contrast"}` | Three options render, each with the matching id as its value and the matching label as its visible text |
| theme-005 | unique-control-id | Two instances of the component render on the same page | Each instance's label and selection control share a distinct identifier pair; no duplicate `id` attribute appears in the DOM |
| theme-006 | label-control | Component renders | A label element is present and programmatically associated with the selection control via its unique identifier |
| theme-007 | accessible-label | Component renders | The selection control exposes the accessible name "Select reading theme" |
| theme-008 | group-container | Component renders | The label and selection control are wrapped in a single container exposing a group role |
| theme-009 | mark-active-selection, emit-theme-change | User selects the theme that is already active | The control's selected value is unchanged; the change callback still fires with that theme's id |
| theme-010 | render-theme-options | Registry is empty | The control renders with no options; no error is thrown |
| theme-011 | active-theme | `activeThemeId` does not match any theme id in the registry | The control renders with no option visibly selected; selecting any option still invokes the change callback |

## Edge Cases

- **Empty theme registry**: If the theme registry is empty, the control MUST render with no options; no error is thrown, and the control remains present but offers no selectable theme.
- **Unknown active theme id**: If the given active theme id does not match any theme in the registry, the control renders with no option visibly selected; selecting any option still invokes **emit-theme-change**.
- **Theme registry mutation**: The registry is immutable input. Mutating a theme object's fields in place (e.g., changing a label) after render is a caller error: the control MUST NOT be relied upon to reflect that mutation until the control's own next render (e.g., driven by a change to the active theme id or a parent re-render).
- **Rapid theme changes**: Each selection closes the dropdown; picking a different theme again requires reopening it. The control MUST NOT debounce or deduplicate **emit-theme-change**: every selection, however rapid the sequence, invokes the callback once per change.
- **Focus retention on selection**: The native `<select>` element keeps keyboard focus after an option is chosen; focus does not move away from the control.

## Configuration

Not applicable: The component accepts only two required props (`activeThemeId` and `onThemeChange`); there are no optional configuration options.

## Deep Linking

Not applicable: This is a local theme switcher UI element with no associated URL or deep-link pattern. Theme selection may affect the MarkdownViewer's display, but no separate deep-link path is defined for the switcher itself.

## Localization

Not applicable: The only user-facing string is "Theme" (the label text), which is hardcoded in the component. To localize this string, the component would need a prop or context-based label key, which is not implemented in the source. See **no-hardcoded-strings** and **string-externalization** in Compliance.

## Accessibility Options

Not applicable: The component does not respond to platform accessibility settings (Reduce Motion, Increase Contrast, Differentiate Without Color). It uses the native select element, which inherits the browser's default accessibility behavior but does not explicitly adapt to these display modes.

## Feature Flags

Not applicable: The component has no feature flag gating; it is always enabled when imported and rendered.

## Analytics

Not applicable: The component does not emit any analytics events. Parent components may wrap the `onThemeChange` callback to log theme selections.

## Privacy

Not applicable: The component does not collect, store, or transmit any user data. Theme selection is a local UI action.

## Logging

Not applicable: The component does not emit any log messages. Debugging theme changes would require inspecting the `onThemeChange` callback invocations at the parent level.

## Platform Notes

- **React/Web**: Component imports `useId` from React and the `Select` primitive from the ATK UI package. `useId()` generates the unique identifier shared by the `<label htmlFor>` and the `<select id>`, satisfying **unique-control-id** and **label-control**. It renders a flex-layout container with `role="group"` (**group-container**) holding the label and a native `<select>`. Each theme in the registry renders as an `<option>` (**render-theme-options**). The select's `onChange` reads the new value from `e.currentTarget.value` and passes it to the change callback (**emit-theme-change**). `aria-label="Select reading theme"` satisfies **accessible-label**.
- **SwiftUI**: Implement as a `Picker` control with a `Menu` or `.segmented` style (depending on the number of themes), wrapped in an `HStack` with a label. Bind the `selection` parameter to the active theme id. Emit the selected theme id through a closure callback or environment-driven state binding. Apply `.accessibilityLabel()` with "Select reading theme".
- **Compose**: Implement as an `ExposedDropdownMenuBox` containing a read-only text field and a `DropdownMenu` listing the available themes. Render each theme as a `DropdownMenuItem`, and emit the selected theme id from that item's `onClick`. Apply `Modifier.semantics { contentDescription = "Select reading theme" }` for accessibility.
- **AppKit / UIKit**: On macOS, use `NSPopUpButton` (or `NSSegmentedControl` when the theme count is small) to render theme options. On iOS, use a `UIButton` with a `UIMenu` (`showsMenuAsPrimaryAction = true`) listing the themes. Bind the selected theme to the control's target-action callback (or the `UIMenu` item's handler) and invoke the theme-change handler with the selected theme's id. Set the control's `accessibilityLabel` property to "Select reading theme".
- **WinUI 3**: Implement as a `ComboBox` control within a horizontal `StackPanel` with a `TextBlock` label. Set `ComboBox.ItemsSource` to the list of themes and `ComboBox.SelectedValuePath = "Id"`, and bind `ComboBox.SelectedValue` to the active theme id; handle `ComboBox.SelectionChanged` to emit the selected theme id. Set `AutomationProperties.LabeledBy` to point at the `TextBlock` label for screen reader support.

## Design Decisions

**Decision**: Reuse the ATK UI `Select` primitive (a styled native `<select>`) instead of building a custom dropdown.
**Rationale**: This ensures cross-browser consistency and automatic accessibility features (ARIA roles, keyboard navigation) without a custom implementation. A custom dropdown would offer more visual control but at the cost of re-implementing accessibility and keyboard behavior.
**Approved**: pending

**Decision**: Hardcode the "Theme" label text rather than accepting a label prop.
**Rationale**: This is intentional for a component in an English-primary environment, but it limits reuse in multilingual contexts; localizing it would require accepting a label prop or deriving it from context.
**Approved**: pending

**Decision**: Do not debounce or deduplicate the theme-change callback.
**Rationale**: Rapid theme selections trigger multiple callbacks. This allows the parent to handle rapid changes as needed (e.g., for analytics or throttling) rather than constraining the behavior in the component. If rapid changes should be rejected, the parent should implement debouncing in the callback handler.
**Approved**: pending

**Decision**: Generate the selection element's id via `useId()` rather than requiring an id prop.
**Rationale**: This ensures unique ids without external coordination or props, which is crucial for multiple instances on the same page (e.g., multiple MarkdownViewer + MarkdownThemeSwitcher pairs). The approach is sound for SSR and client-side hydration.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on the source's explicit ARIA and native semantics (`aria-label`, `<label htmlFor>`, native `<select>`) and Tailwind sizing classes (`h-8`, `text-xs`) visible in `MarkdownThemeSwitcher.tsx`; the `Select` primitive's actual color tokens and root font-size behavior are not visible from this file, and the hardcoded "Theme" string has no externalization mechanism in the source; the component is pure presentation over `activeThemeId`/`onThemeChange` props with no inline logic (separation-of-concerns: passed), and no test file exercises `MarkdownThemeSwitcher` (unit-test-coverage: failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; platform-neutralized Behavioral Requirements; corrected accessibility, states, and platform-notes technical errors; rebuilt Compliance with real catalog checks; reformatted Design Decisions; fixed Appearance units and Conformance Test Vectors |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
