---
id: fba584ed-a87c-4223-a4a9-de9c6dd342d3
title: Select
domain: adhsdk://recipes/select
type: ingredient
version: 1.3.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Native HTML select element with optional label and hint, supporting single-value
  selection from a fixed set of choices.
platforms:
- typescript
- web
tags:
- form-control
- select
depends-on: []
related: []
references:
- https://html.spec.whatwg.org/multipage/form-elements.html#the-select-element
- https://www.w3.org/TR/WCAG21/#info-and-relationships
- https://www.w3.org/TR/WCAG21/#name-role-value
- https://www.w3.org/TR/WCAG21/#focus-visible
- https://www.w3.org/TR/WCAG21/#non-text-contrast
- https://www.w3.org/TR/WCAG21/#target-size
approved-by: ''
approved-date: ''
---

# Select

## Overview

The Select component is a form control that renders a native HTML `<select>` element with an optional label and optional hint text below. It manages a single selected value from a set of choices and notifies the parent component via an `onChange` callback when the selection changes. The component accepts styling via a `className` prop and generates or uses a provided `id` for associating the label.

## Behavioral Requirements

- **native-select**: The component MUST render a native HTML `<select>` element, not a custom listbox or dropdown.
- **change-callback**: The component MUST invoke the `onChange` callback with the newly selected value when the user changes the selection.
- **value-reflection**: The component MUST display the `value` prop as the currently selected option in the select element.
- **choice-rendering**: The component MUST render a native `<option>` element for each choice in the `choices` array.
- **choice-label-text**: Each `<option>` element MUST display the `label` property of its corresponding choice.
- **disabled-choices**: The component MUST respect the `disabled` property of individual choices and render disabled options.
- **disabled-control**: The component MUST disable the entire select element when the `disabled` prop is `true`, preventing user interaction.
- **generated-id**: When no `id` prop is provided, the component MUST generate a stable ID using React's `useId` hook.
- **provided-id**: When an `id` prop is provided, the component MUST use that ID instead of generating one.
- **label-association**: When a `label` is provided, the component MUST render an HTML `<label>` element with `htmlFor` set to the select's ID, associating the label to the control.
- **wrapper-classname**: In the `aws-field` implementation, the component MUST apply the `className` prop to the wrapper `<div>` when provided. The apt-token implementation instead applies `className` to the `<select>` element itself; its wrapper `<div>` class is a fixed `"relative"` that never receives caller classes (see Platform Notes).
- **hint-display**: When a `hint` prop is provided, the component MUST render it as text content below the select element.
- **chevron-indicator**: The component SHOULD display a visual indicator (such as a chevron icon) to signify that the element is a dropdown control.
- **focus-style**: The component SHOULD apply visual styling to indicate focus when the select has keyboard focus.
- **hint-described-by**: When a `hint` is provided, the component SHOULD associate it with the select via `aria-describedby` so assistive technology announces it as descriptive text for the control.

## Appearance

Two implementations exist in source: the generic (`aws-field`) implementation defers all appearance to caller-supplied CSS classes and specifies no fixed values in source; the apt-token implementation gives concrete values. The following canonical appearance draws from the apt-token implementation, given as sizes in px and a semantic role per color.

- **Container**: Wrapper `<div>` (`position: relative` in the apt implementation) that groups the label, select, and hint; the generic implementation applies the classes `aws-field` and `aws-field--select` as its styling hooks.
- **Native select styling**: The native select element renders with `appearance: none` to allow custom styling while retaining native behavior.
- **Corner radius**: 8px, from the shared field-shell style.
- **Padding**: 12px horizontal, 8px vertical; the apt implementation adds 36px of trailing padding to clear the chevron icon.
- **Font**: 14px; color role "primary text".
- **Background**: color role "field surface", from the shared field-shell style.
- **Border**: 1px, color role "field border" by default; on focus, color role "accent".
- **Focus ring**: 2px, color role "accent" at 25% opacity.
- **Indicator icon**: 16px chevron-down icon, positioned 12px from the trailing edge, vertically centered; color role "muted text".
- **Min/Max size**: height 36px; width grows to fill its container.
- **Disabled appearance**: 50% opacity, pointer events removed, cursor shows not-allowed.

## States

| State | Appearance change |
|-------|------------------|
| Default | Native select with chevron indicator visible; text and border use the field's base color roles |
| Focused | Border switches to the accent color role; adds a 2px ring in the accent role at 25% opacity; focus-visible outline applied via CSS |
| Disabled | Opacity reduced to 50%; pointer events disabled; cursor shows not-allowed symbol |
| Pressed (open dropdown) | Handled by native browser behavior; no component-specific styling |

## Accessibility

- **Role**: A single-select `<select>` element with no `size` attribute (as used here) maps to the implicit ARIA role `combobox`; no custom role is required.
- **Label requirement**: The `label` prop is optional. When provided, it MUST be associated to the select via the `htmlFor` attribute on the `<label>` element, matching the select's `id` (see **label-association**). No fallback ARIA properties (`aria-label`, `aria-labelledby`) are implemented; when `label` is omitted, the control has no accessible name from the component itself.
- **Keyboard navigation**: Native select supports keyboard navigation; users can open the dropdown with Space or Enter, navigate with arrow keys, and select with Enter. This is provided by the browser and requires no component implementation.
- **Minimum touch target**: The control's visual height is 36px (`h-9`), which falls short of the 44×44pt minimum touch target (WCAG 2.1 SC 2.5.5 Target Size, Enhanced).
- **Hint association**: The hint text renders as a sibling `<p>` element; the select has no `aria-describedby` attribute referencing it (see **hint-described-by**), so screen readers do not announce the hint as descriptive text for the control.
- **Disabled state announcement**: Native select announces disabled state to assistive technologies automatically; the component applies no additional ARIA attributes.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| select-001 | native-select | Render with `value="a"`, `choices=[{value:"a",label:"A"}]`, and a no-op `onChange` | Component renders a native `<select>` element |
| select-002 | change-callback | Render with `value="a"` and `choices=[{value:"a",label:"A"},{value:"b",label:"B"}]`; user selects the option labeled "B" | `onChange` is invoked with `"b"` |
| select-003 | value-reflection | Render with `value="option2"` and three choices | The option with value `option2` is selected in the rendered select |
| select-004 | choice-rendering | Render with `choices=[{value:"a",label:"A"},{value:"b",label:"B"}]` | Two `<option>` elements are rendered |
| select-005 | choice-label-text | Render a choice with `label:"Choose Me"` | The rendered `<option>` displays text "Choose Me" |
| select-006 | disabled-choices | Render a choice with `disabled: true` | The rendered `<option>` has the `disabled` attribute |
| select-007 | disabled-control | Render with `disabled={true}` | The `<select>` element has the `disabled` attribute; user cannot interact |
| select-008 | generated-id | Render without an `id` prop | A stable ID is generated via `useId`; label's `htmlFor` matches the generated ID |
| select-009 | provided-id | Render with `id="my-select"` | The rendered select has `id="my-select"`; label's `htmlFor` is `"my-select"` |
| select-010 | label-association | Render with `label="Choose an option"` | A `<label>` element is rendered with `htmlFor` matching the select's ID |
| select-011 | wrapper-classname | Render the `aws-field` implementation with `className="custom-class"` | The wrapper div includes the class `custom-class` (the apt-token implementation instead applies `custom-class` to the `<select>` element; its wrapper div stays `class="relative"`) |
| select-012 | hint-display | Render with `hint="Select one item"` | A `<p>` element is rendered below the select displaying the hint text |
| select-013 | chevron-indicator | Render component | A chevron-down icon is displayed to the right of the select |
| select-014 | focus-style | Focus the select element via keyboard | Border changes to the accent color role, ring is visible, focus-visible styles are applied |
| select-015 | label-association | Render without a `label` prop | No `<label>` element is rendered; the select has no accessible name supplied by the component |
| select-016 | choice-rendering | Render with `choices=[]` | No `<option>` elements are rendered; the select has no selectable options |
| select-017 | hint-display | Render with `hint="Select one item"` and no `id` prop | The hint `<p>` renders as a sibling of the select; the select's `aria-describedby` attribute is not set to the hint's id (see **hint-described-by**) |
| select-018 | disabled-choices | Render a choice with `disabled: true` and attempt to select it via keyboard or pointer | The disabled `<option>` cannot be selected; native browser behavior skips it during navigation |

## Edge Cases

- **Empty choices provided**: If `choices` is an empty array, the select renders with no options, and no selection is possible until choices are provided.
- **Choice value mismatch**: If `value` does not match any choice's value, no `<option>` matches the controlled value; per the HTML `<select>` specification, the browser falls back to displaying the first `<option>` in document order. Neither implementation provides a placeholder or empty-option choice; a caller wanting a "no selection" state must include an explicit placeholder entry in the `choices` array (e.g., `{ value: '', label: 'Select…' }`).
- **Missing label**: If `label` is not provided (undefined), no label is rendered. Hint text is rendered if provided. If neither label nor hint exists, the select has no accessible name. This is an accessibility concern, as the component provides no fallback method (such as `aria-label`) to name the control when the label prop is omitted.
- **Disabled with focused select**: If the select is disabled while focused, the browser blurs it; focus is lost and moves to `document.body` rather than automatically advancing to another focusable element. No component-specific handling.
- **Label without select id**: Since the component generates an ID if none is provided and associates the label via `htmlFor`, this edge case cannot occur by design.
- **Null or undefined choices**: If `choices` is `null` or `undefined`, invoking `.map()` on a null/undefined value throws a runtime error. The component does not provide defensive null checking.
- **Concurrent value and onChange**: If the parent updates `value` while the user is interacting with the select (e.g., mid-click), the component re-renders and reflects the new value. No debounce or queue behavior is implemented.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | `ReactNode` | `undefined` | Optional label text or element rendered above the select |
| `hint` | `ReactNode` | `undefined` | Optional hint text or element rendered below the select |
| `value` | `T` (extends `string`, default `string`) | Required | The currently selected value (controlled component) |
| `onChange` | `(value: T) => void` | Required | Callback invoked when the user changes the selection |
| `choices` | `Choice<T>[]` | Required | Array of options; each choice has `value`, `label`, and optional `disabled` |
| `disabled` | `boolean` | `false` | Disables the select element and prevents user interaction |
| `className` | `string` | `undefined` | Optional CSS class name; applied to the wrapper div in the `aws-field` implementation, and to the `<select>` element itself in the apt-token implementation |
| `id` | `string` | Generated via `useId()` | Optional HTML id; if not provided, one is automatically generated |

## Deep Linking

Not applicable: The Select component is a form control without inherent deep-link targets. Deep linking would be handled at the page or route level by the parent container.

## Localization

Not applicable: all strings are caller-supplied.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The component does not apply transition or animation effects; this option has no effect. |
| Increase Contrast | The component relies on the field's text, accent, and border color roles. If the design system's tokens for those roles are updated to provide higher-contrast colors, the component automatically uses them. No component-level implementation required. |
| Differentiate Without Color | On focus the component switches the border to the accent color role and adds a 2px ring at 25% accent opacity; both are color changes, so differentiation still relies partly on hue. Whether the ring's own contrast against its background meets WCAG 1.4.11 Non-text Contrast (3:1) has not been measured from source alone. |

## Feature Flags

Not applicable: The Select component is a foundational form control without feature flag integration in the source code. Feature flags would be applied at the application or parent component level.

## Analytics

Not applicable: The component does not emit analytics events. Event tracking would be implemented by the parent component via hooks or event handlers on the `onChange` callback.

## Privacy

Not applicable: The component handles no sensitive data. It passes user-selected values to the parent via the `onChange` callback; storage and transmission of those values are the parent's responsibility.

## Logging

Not applicable: The component does not emit logs. Debugging or activity logging would be implemented by the parent component using React's dev tools or custom logging in the `onChange` callback.

## Platform Notes

- **React/Web**: Two implementations exist in source, and they diverge in more than styling. `packages/web/packages/controls/src/user-settings/components/Select.tsx` (the `aws-field` implementation, from the AgenticWebStack design system) implements the full API this recipe describes: `label`, `hint`, a `choices` array rendered as `<option>`s, `useId`-generated fallback `id`, a wrapped `onChange` that hands the caller the new value directly, and a wrapper `<div>` that receives `className`. `packages/web/packages/ui/src/components/select.tsx` (the apt-token implementation) is a thinner styling wrapper: its props are `React.ComponentProps<"select">`, so callers supply native `<option>` children and their own `onChange` (receiving the raw `ChangeEvent`, not an extracted value), `id`, and accessible name directly — see `search-filter-bar.tsx`'s `<Select aria-label={f.label} value={f.value} onChange={(e) => f.onChange(e.target.value)}>` for a caller doing exactly that. It has no `label`, `hint`, or `choices` prop at all; it always renders a fixed `<div className="relative">` around the `<select>` and always shows a chevron icon regardless of any prop. Only the `label`/`hint`/`choices`/id-generation/wrapped-`onChange` behavior in Behavioral Requirements above is specific to the `aws-field` implementation — the apt-token implementation supplies the Appearance section's styling and nothing else.
- **SwiftUI**: Use `Picker` with `.pickerStyle(.menu)` for a dropdown-style control matching the native `<select>`'s single-value, collapsed-until-tapped behavior. Provide a label via the `label` parameter. Bind the selection via `@State`. Provide hint or descriptive text via a secondary `Text` view positioned below the Picker.
- **Compose**: Use `ExposedDropdownMenuBox` from Material 3, with a read-only `OutlinedTextField` (`readOnly = true`) as the anchor via `.menuAnchor()`. Provide a label via the `OutlinedTextField`'s `label` parameter. Use `DropdownMenuItem` to render each choice inside the box's menu. Bind selection via `mutableStateOf()`. Associate hint text via the `supportingText` parameter on the `OutlinedTextField` for screen reader announcement.
- **AppKit / UIKit**: On macOS, use `NSPopUpButton` with a label via `NSTextField`. On iOS, use a `UIButton` configured with a `menu` and `showsMenuAsPrimaryAction = true`, populating `UIAction` items for each choice. For hint text, add an `NSTextField` or `UILabel` below the control with `lineBreakMode = .byWordWrapping`. Set `accessibilityHint` on the control to associate the hint; VoiceOver custom actions are not the right mechanism for this.
- **WinUI 3**: Use `ComboBox` control with `ItemsSource` bound to the choices array, `SelectedItem` or `SelectedValuePath` for the value, and `SelectionChanged` event for the callback. `IsEditable` already defaults to `false`, so no explicit setting is needed to prevent typing. Provide a label via the `ComboBox.Header` property so it is exposed to UIA automatically. Place hint text in a `TextBlock` below the ComboBox and associate it via the `AutomationProperties.HelpText` attached property on the ComboBox.

## Design Decisions

**Decision**: Use a native HTML `<select>` element rather than a custom listbox or dropdown.
**Rationale**: Prioritizes accessibility (native keyboard and screen-reader support), simplicity, and browser compatibility; richer interactions (multiselect, filtering, grouping) are left to a separate custom component.
**Approved**: pending

**Decision**: Accept a `className` prop for composition and use design system tokens for color and spacing rather than hardcoded values.
**Rationale**: Lets the component adapt to different design systems by swapping token/class definitions, at the cost of coupling the component to the presence of those definitions.
**Approved**: pending

**Decision**: Generate an ID via `useId()` when none is provided, while still accepting an `id` prop for caller control.
**Rationale**: Ensures the label can always be associated to the select, preventing lost accessible names, while letting a caller match a server-rendered ID when needed.
**Approved**: pending

**Decision**: Implement Select as a controlled component; `value` is a required prop and the parent owns the state.
**Rationale**: Keeps the parent always aware of the current value, enabling undo, validation, or other state-management patterns without the component maintaining parallel state.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Statuses rest on the native `<select>`/`<option>` markup and native `disabled` semantics in both source files, the `htmlFor`/`id` label association with no `aria-label` fallback, the `h-9` (36px) control height against the 44px minimum, the `apt-text`/`apt-gold` design tokens used without stated contrast values, the rem-based `text-sm` utility whose scaling depends on a Tailwind config not visible in this source, the fully caller-supplied `label`/`hint`/`choice.label` strings, and the physical `right-3`/`pr-9` positioning of the chevron and padding that does not flip for right-to-left locales. `separation-of-concerns` passes because both `Select.tsx` files are pure presentation over props with no business logic. `unit-test-coverage` is partial: `user-settings/components/Select.tsx` is exercised directly and meaningfully in `components.test.tsx`, but `ui/components/select.tsx` has no test of its own — it is only exercised indirectly through `SearchFilterBar`'s combobox assertions in `searchFilterBar.test.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.2 | 2026-09-25 | Mike Fullerton | Scoped wrapper-classname/select-011/Configuration className row and Platform Notes to the aws-field vs apt-token divergence. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.3.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename Behavioral Requirements to subject-only kebab-case and update every citation; add hint-described-by requirement and remove the deferred Design Decision it replaced; reformat Design Decisions to the Decision/Rationale/Approved form; rebuild Compliance as a catalog-linked table with lowercase statuses and merge the label/accessible-name contradiction into one partial row; correct AppKit/UIKit, Compose, and WinUI 3 Platform Notes to real APIs and drop the irrelevant SwiftUI multiselect aside; rewrite Appearance in px sizes and color roles instead of raw Tailwind classes and tokens; state the 36px touch target falls short instead of claiming it meets the minimum; align the label-optional contract across Accessibility, Configuration, and Edge Cases; correct `value`/`onChange` typing to match the source's generic `T`; sharpen the value-mismatch edge case with the concrete browser fallback; replace the invented Localization table with "not applicable"; correct the Role bullet to name `combobox` directly; add missing conformance test vectors for a missing label, empty choices, the hint/aria-describedby gap, and disabled-option unselectability; cite specific WCAG success criteria and the WHATWG select-element anchor in place of the whole WCAG21 document and the obsolete HTML 5.2 spec; correct the disabled-while-focused edge case to blur-to-body instead of an unverified "next focusable element"; note that the focus ring/border differentiation still relies partly on hue pending measured contrast; drop the SwiftUI segmented-style aside since it doesn't match a collapsed dropdown; name the `aws-*` namespace as the AgenticWebStack design system; and make test vectors select-001, select-002, and select-008 concrete instead of vague or mismatched with their requirement's wording |
| 1.2.0 | 2026-09-22 | Claude Haiku 4.5 | Revise markers: replace aria-label fallback question with concrete fact; keep hint aria-describedby gap as genuine issue; enhance Platform Notes with concrete translation guidance for all platforms |
| 1.1.1 | 2026-09-22 | Claude Haiku 4.5 | Fold in ui-blocks source; confirm all requirements traceable to both web implementations |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Revise markers: replace reviewer questions with concrete facts; keep accessible name and hint association as genuine gaps |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web (React) source |
