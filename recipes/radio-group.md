---
id: d431934e-d64c-4dcf-bdab-b7c3465ee71b
title: Radio Group
domain: adhsdk://recipes/radio-group
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A group of mutually exclusive radio button options where only one choice
  can be selected at a time.
platforms:
- typescript
- web
tags:
- form-control
- radio-button
depends-on: []
related:
- adhsdk://recipes/radio
- adhsdk://recipes/checkbox
- adhsdk://recipes/choice-slider
- adhsdk://recipes/field
references:
- https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fieldset
- https://developer.mozilla.org/en-US/docs/Web/HTML/Element/legend
- https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/radio
- https://www.w3.org/WAI/WCAG21/Understanding/target-size.html
approved-by: ''
approved-date: ''
---

# Radio Group

## Overview

A radio group component presents a set of mutually exclusive options; native radio-input semantics guarantee that at most one choice is checked at any time. The caller supplies the currently selected value, and when it matches one of the choices' values, that choice renders as checked. The component wraps native HTML radio inputs with semantic markup and supports optional labels, hints, and individual choice disabling. It is the appropriate control for binary or multiple-choice selections where only one answer is valid.

## Behavioral Requirements

- **render-choices**: The component MUST render each choice in the choices array as a distinct radio button option.
- **maintain-selection-state**: The component MUST maintain and reflect the currently selected value in the `value` prop, rendering that choice's radio input as checked.
- **handle-value-change**: The component MUST invoke the `onChange` callback with the new value when the user selects a different choice.
- **fieldset-root**: The component MUST render a `<fieldset>` element as the root container.
- **legend-label**: When a label prop is provided, the component MUST render it inside a `<legend>` element as the first child of the fieldset.
- **radiogroup-role**: The component MUST render a container element with `role="radiogroup"` that contains all radio button inputs.
- **choice-labels**: The component MUST display a label for each choice; the label MUST be associated with its corresponding radio input.
- **choice-hints**: When a choice has a hint property, the component MUST render that hint adjacent to the choice label.
- **field-hint**: When a hint prop is provided to the component, the component MUST render it as field-level guidance below all choices.
- **disabled-state**: When the disabled prop is true, the component MUST disable all radio inputs and prevent user interaction with the entire group.
- **individual-choice-disable**: When a choice has disabled: true, the component MUST disable only that specific radio input while allowing other choices to remain interactive.
- **custom-classname**: The component MUST accept a className prop and apply it to the root fieldset element, allowing callers to customize appearance.
- **generated-name**: When the name prop is not provided, the component MUST generate a unique name for the radio group using a stable mechanism (e.g., useId).
- **provided-name**: When the name prop is provided, the component MUST use that name for all radio inputs in the group.

## Appearance

- **Corner radius**: None (uses native input styling)
- **Padding**: Fieldset padding managed by CSS classes (aws-field)
- **Font**: Uses inherited font; choice labels rendered with aws-radio__label class
- **Background**: Transparent (fieldset background managed by aws-field class)
- **Foreground/Text**: Inherited text color for labels and hints
- **Border**: Not defined in this source file; entirely owned by the `aws-field` stylesheet rule the caller supplies. No border renders unless that external CSS adds one.
- **Shadow**: None
- **Min/Max size**: No explicit constraints; layout determined by CSS classes

## States

| State | Appearance change |
|-------|------------------|
| Default | All unselected choices render with empty indicator |
| Selected | Selected choice renders with filled/checked indicator and checked input attribute |
| Disabled (group) | All radio inputs and fieldset receive disabled attribute; text may render grayed out per CSS |
| Disabled (individual choice) | Individual radio input receives disabled attribute; that choice's option appears inactive |
| Focused | Native browser focus ring on the focused radio input |

## Accessibility

- **Role/trait**: Fieldset with legend for group label; each input is a native radio control with associated label. The choices additionally sit inside a `<div role="radiogroup">`; that container carries no `aria-labelledby` of its own, so the group's accessible name for assistive technology comes from the enclosing fieldset/legend pairing, not from the radiogroup role itself.
- **Label requirements**: Each radio input MUST have an associated label element; the group MUST have a legend when a label prop is provided; each choice MUST have a label rendered in its associated label element
- **Announce state changes**: When a choice is selected via keyboard or mouse, the input's checked state changes are announced by assistive technology automatically via the native checked attribute
- **Keyboard navigation**: Users MUST be able to navigate between choices using arrow keys (browser default for radio groups); the focused choice MUST be selectable with the Space key (native radio input behavior). Enter is not a radio-selection key — in a form it submits the enclosing form instead — so implementations MUST NOT add an Enter handler for selection.
- **Minimum tap target**: Per WCAG 2.1 [SC 2.5.5 Target Size (Enhanced)](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html) (Level AAA), the clickable area (including the label text and indicator) SHOULD meet a minimum 44×44 CSS-pixel target on touch devices. The source does not define the rendered size of the label/indicator — that depends on the `aws-field`/`aws-radio` stylesheet rules supplied by the caller — so whether a given instance meets the target cannot be confirmed from this file alone.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| radio-group-001 | render-choices | choices=[{value:'a',label:'A'},{value:'b',label:'B'}] | Both choices rendered as radio options |
| radio-group-002 | maintain-selection-state | choices=[{value:'a',...},{value:'b',...}], value='b' | The choice with value='b' renders with checked=true |
| radio-group-003 | handle-value-change | choices=[{value:'a',label:'A'},{value:'b',label:'B'},{value:'c',label:'C'}]; user clicks choice with value='c' | onChange callback invoked with value='c' |
| radio-group-004 | fieldset-root | Component rendered | Root element is a fieldset |
| radio-group-005 | legend-label | label='Group Label' provided | Legend element renders with text 'Group Label' |
| radio-group-006 | radiogroup-role | Component rendered | Container element has role="radiogroup" |
| radio-group-007 | choice-labels | choices=[{value:'a',label:'Option A'}] | Text 'Option A' appears next to radio input |
| radio-group-008 | choice-hints | choices=[{value:'a',label:'A',hint:'Hint text'}] | 'Hint text' rendered adjacent to the choice |
| radio-group-009 | field-hint | hint='Field guidance' | Text 'Field guidance' rendered below the radio choices |
| radio-group-010 | disabled-state | disabled=true, choices=[{...},{...}] | All radio inputs have disabled attribute; fieldset has disabled attribute |
| radio-group-011 | individual-choice-disable | choices=[{value:'a',...},{value:'b',disabled:true}] | Choice 'b' radio input has disabled attribute; choice 'a' remains enabled |
| radio-group-012 | custom-classname | className='custom-class' | Root fieldset renders with 'custom-class' in its class list |
| radio-group-013 | generated-name | Two RadioGroup instances rendered, neither given a name prop | Each instance's own radio inputs share one name within that instance; the two instances' generated names differ from each other and neither is empty |
| radio-group-014 | provided-name | name='my-group' | All radio inputs have name="my-group" |
| radio-group-015 | render-choices | choices=[] | Fieldset and radiogroup div render; no radio inputs render |
| radio-group-016 | legend-label | label=undefined | No legend element renders |
| radio-group-017 | field-hint | hint=undefined | No field-level hint element renders |
| radio-group-018 | choice-hints | choices=[{value:'a',label:'A'}] (no hint property) | No hint element renders for that choice |
| radio-group-019 | maintain-selection-state | choices=[{value:'a',...},{value:'b',...}], value='z' | No radio input renders as checked |
| radio-group-020 | disabled-state | disabled=true; user attempts to click a choice | onChange is never invoked |
| radio-group-021 | maintain-selection-state | value='b' selected; the choices array is replaced by a new array that still contains value 'b' | Choice 'b' still renders as checked |
| radio-group-022 | maintain-selection-state | value='b' selected; the choices array is replaced by a new array that no longer contains value 'b' | No choice renders as checked, until onChange updates value |

## Edge Cases

- **Empty choices array**: When choices is an empty array, the component MUST render a fieldset and radiogroup div but no radio options. This is a valid but typically undesired state; the component does not prevent it. See radio-group-015.
- **Null or undefined label**: When label is null or undefined, the component MUST NOT render a legend element. See radio-group-016.
- **Null or undefined hint**: When the component hint is null or undefined, no field-level hint element MUST be rendered. See radio-group-017.
- **Null or undefined choice hints**: When a choice hint is null or undefined, no hint element MUST be rendered for that choice. See radio-group-018.
- **Value not in choices**: When the value prop does not match any choice's value, no radio input will be checked. This is a valid state representing an unselected group (e.g., during initial render before a default is set); the component does not enforce that value matches a choice. See radio-group-019.
- **Disabled group with onChange**: When disabled=true, the onChange callback MUST NOT be invoked even if the user attempts interaction (disabled by browser). See radio-group-020.
- **Changing choices array mid-interaction**: If the choices array changes while a choice is selected, the component MUST continue to render the current value as checked if it still exists in the new choices array; if the selected value no longer exists, no choice is checked until onChange updates the value. See radio-group-021 and radio-group-022.
- **Type T generics**: The component is generic over T (string | number). Values and onChange callback MUST maintain type consistency; the component does not enforce this at runtime but consumers must ensure type alignment. This is a compile-time constraint with no observable runtime output, so it has no conformance test vector of its own.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| label | ReactNode | undefined | Optional label text rendered in a legend element |
| hint | ReactNode | undefined | Optional field-level guidance text rendered below choices |
| value | T (string \| number) | required | The currently selected choice value; SHOULD match one of the choice values so that choice renders as checked. If it does not match any choice, no radio input is checked (see Edge Cases: Value not in choices). |
| onChange | (value: T) => void | required | Callback invoked when the user selects a different choice |
| choices | `Choice<T>[]` | required | Array of choice objects, each with value, label, and optional disabled and hint properties |
| disabled | boolean | false | When true, disables all radio inputs and the fieldset |
| className | string | undefined | Optional CSS class string applied to the root fieldset element |
| name | string | undefined | Optional name attribute for all radio inputs; if omitted, a unique name is generated via useId |

## Deep Linking

Not applicable: The radio group component is a form control and does not support direct deep linking to a specific choice selection via URL or URI pattern.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| N/A | N/A | The component does not emit any static strings; all text (label, hints, choice labels) comes from props and is caller's responsibility to localize. |

## Accessibility Options

- **Reduce Motion**: The component does not animate; no changes required.
- **Increase Contrast**: The component relies on native input styling and CSS classes; callers applying high-contrast CSS must ensure radio indicators and labels remain distinguishable.
- **Differentiate Without Color**: The component must not rely on color alone to indicate selection state; the checked input attribute and native browser rendering already provide non-color distinction (e.g., filled vs. empty indicator).

## Feature Flags

Not applicable: The component is a foundational form control with no feature-flag-gated behavior.

## Analytics

Not applicable: The component does not emit any analytics events; consumers implementing this component are responsible for tracking selection changes via the onChange callback if analytics instrumentation is desired.

## Privacy

Not applicable: The component does not collect, transmit, or retain user data; it is a stateless UI control that only holds the selected value in its parent's state.

## Logging

Not applicable: The component does not emit any log messages.

## Platform Notes

- **React/Web**: The source platform. Implemented using native HTML `<fieldset>` and `<input type="radio">` elements with a `<legend>` (when `label` is provided) and a `role="radiogroup"` container div wrapping the inputs. React's `useId` hook generates a stable unique name when `name` is not provided. CSS classes (aws-field, aws-radio, etc.) provide styling hooks; consumers must provide the corresponding stylesheets. Reference: `packages/web/packages/controls/src/user-settings/components/RadioGroup.tsx`.

- **SwiftUI**: On macOS, use `Picker` with `.pickerStyle(.radioGroup)`, which renders true radio buttons with built-in mutual exclusivity and keyboard navigation; bind its selection to a `Binding<T>` in place of the `value`/`onChange` pair. iOS has no native SwiftUI radio-group style; use a `List` (or a `ForEach` of rows) whose selected row shows a trailing checkmark (`Image(systemName: "checkmark")`) instead. Render the field-level hint as `Text` below the picker, and a per-choice hint as secondary `Text` within that choice's row. Disable the whole control with `.disabled(true)`; disable a single choice by disabling only that row.

- **Compose**: Wrap the choices in a `Column` with `Modifier.selectableGroup()`, which exposes the set to accessibility services as a single selectable group (Compose provides no automatic fieldset-like grouping otherwise). Give each choice row `Modifier.selectable(selected = choice.value == value, onClick = { onChange(choice.value) }, role = Role.RadioButton)`, with a `RadioButton(selected = ..., onClick = null)` inside it — passing `onClick = null` on the inner `RadioButton` avoids firing the callback twice, since the row's `selectable` modifier already handles the click. Disable the whole group by setting `enabled = false` on every row's `selectable` modifier; disable a single choice by setting it only on that row.

- **AppKit / UIKit**: On macOS, use `NSButton(radioButtonWithTitle:target:action:)` for each choice; radio-type buttons that share the same target/action and superview become mutually exclusive automatically, so no manual state tracking via KVO/bindings is needed. Put the group label in an `NSTextField` above the buttons (the AppKit analogue of `<legend>`), and a secondary `NSTextField` for each hint. UIKit has no native radio-group control; use a `UITableView`/list section with a checkmark accessory (`.checkmark` accessory type) on the selected row rather than `UISegmentedControl`, which represents a different interaction pattern. Set `isEnabled = false` on the container to disable the whole group, or on a single row's control to disable one choice.

- **WinUI 3**: Use the `RadioButtons` group control (not loose `RadioButton` elements wired together via `GroupName`), which provides built-in arrow-key navigation, a single tab stop for the whole group, and a `Header` property for the group label — the WinUI analogue of `<legend>`. Bind `SelectedItem`/`SelectedIndex` in place of the `value`/`onChange` pair. Use `Content` for each choice's label and a secondary `TextBlock` for a per-choice hint; render the field-level hint as a `TextBlock` below the control. Set `IsEnabled="False"` on the `RadioButtons` control to disable the whole group, or on an individual `RadioButton` item to disable one choice.

## Design Decisions

1. **Decision**: Use native `<input type="radio">` elements rather than styled divs with custom click handlers.
**Rationale**: Native inputs work correctly with all assistive technologies and require no JavaScript event handling to achieve keyboard interaction.
**Approved**: pending

2. **Decision**: Wrap the radiogroup in a `<fieldset>` and render the label in a `<legend>`.
**Rationale**: This follows HTML standards for form grouping and is the correct semantic structure for grouped form inputs; screen readers announce the legend as the group's accessible name.
**Approved**: pending

3. **Decision**: Support both a per-choice hint and a field-level hint.
**Rationale**: This allows flexible UX patterns where a group needs both overall field instructions and choice-specific guidance.
**Approved**: pending

4. **Decision**: Generate a unique group name via `useId` when no `name` prop is provided.
**Rationale**: Prevents multiple RadioGroup instances on the same page from interfering with each other's selection state, which would happen if all used the same hardcoded name.
**Approved**: pending

5. **Decision**: Make the component generic over `T` (`string | number`).
**Rationale**: Supports both string and numeric choice values, allowing consumers to work with their own type systems without additional conversion.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The `passed` statuses rest on the native `fieldset`/`legend`/`label` semantics and the keyboard-operable `<input type="radio">` visible in the source. The `screen-reader-support` status is `partial` because the `role="radiogroup"` container carries no `aria-labelledby` of its own (see Accessibility). The `contrast-ratio` and `touch-target-size` statuses are `partial` because the `apt-*`/`aws-*` token values and the effective click-target size (label padding/line-height) are defined in an external stylesheet not present in this source file. `separation-of-concerns` passes because `RadioGroup` only renders the `choices` it is given and reports selection via `onChange`, with no logic for how `value`/`choices` are produced. `unit-test-coverage` passes because `components.test.tsx`'s `RadioGroup` suite renders it with choices and asserts clicking a choice's label calls `onChange` with that choice's value.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source (`packages/web/packages/controls/src/user-settings/components/RadioGroup.tsx`) |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case and update every citation; reconcile the exactly-one-selected vs. unmatched-value contradiction across Overview/Configuration/Edge Cases; correct the Enter/Space keyboard claim and cite WCAG 2.5.5 by name; rebuild Compliance as a linked, honestly-scoped table instead of blanket `passed`; replace the SwiftUI/Compose/WinUI platform notes' non-native suggestions with the real native radio-group APIs and state the AppKit mutual-exclusivity mechanism explicitly; reformat Design Decisions into Decision/Rationale/Approved form; fix test vector 003's undefined choice and vector 013's implementation-detail assertion, and add vectors for every untested edge case; fill `related` with the sibling form-control recipes and `references` with the cited WCAG/HTML sources; state the Border appearance entry as caller-owned instead of "may". |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Wrapped Choice<T>[] in code span; added best-practices Compliance rows. |
