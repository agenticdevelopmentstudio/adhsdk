---
id: af6f9e80-4913-495e-8717-9a939dc15733
title: "Date Range Picker"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Two labelled native date fields, From and To, each bounding the other; reports a changed end with the other kept and ignores a cleared field."
platforms:
  - typescript
  - web
tags:
  - component
  - date-range-picker
  - ui
depends-on:
  - 0f5b7167-b375-4f44-977b-566f720a453d
  - c5703986-6d14-4341-8719-b89e44f2ab80
related: []
references:
  - https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.calendardatepicker
approved-by: ""
approved-date: ""
---

# Date Range Picker

## Overview

`DateRangePicker` picks an inclusive calendar-day range with two native date fields, labelled "From" and "To", laid out side by side and wrapping onto two rows when the space is narrow. It is a controlled component: the caller owns the range as a `DateRange` (an object with `from` and `to`, both `YYYY-MM-DD` strings) and receives a new `DateRange` through `onChange`. The source comment gives the reason for native fields over a calendar popover: "the browser's own picker is keyboard- and screen-reader-complete for free". Each end bounds the other, so the picker steers away from an inverted range, but the comment also states the limit: "a typed date bypasses min/max, so a caller that needs a valid range must still check it". A cleared field is ignored rather than reported as an empty day. The two fields are the shared [Input](cookbook:0f5b7167-b375-4f44-977b-566f720a453d) and [Label](cookbook:c5703986-6d14-4341-8719-b89e44f2ab80) components. The module is a client component (`"use client"`).

## Behavioral Requirements

- **render-two-date-fields**: The component MUST render two date fields, the first for the start of the range and the second for the end, in that order.
- **label-from-field**: The component MUST label the first field with the text "From".
- **label-to-field**: The component MUST label the second field with the text "To".
- **associate-labels-with-fields**: Each label MUST be programmatically associated with its own field, so that activating or querying the label text reaches that field.
- **unique-field-identity**: Each instance MUST generate a field identifier of its own, so that two pickers on one page do not share label associations.
- **show-controlled-value**: The first field MUST display `value.from` and the second field MUST display `value.to`; the component MUST NOT hold a displayed value of its own.
- **bound-from-by-min**: The first field's lower bound MUST be the `min` prop.
- **bound-from-by-to**: The first field's upper bound MUST be the current `value.to`, not the `max` prop.
- **bound-to-by-from**: The second field's lower bound MUST be the current `value.from`, not the `min` prop.
- **bound-to-by-max**: The second field's upper bound MUST be the `max` prop.
- **report-changed-from**: When the first field changes to a non-empty date, the component MUST call `onChange` once with a range whose `from` is the new date and whose `to` is the existing `value.to`.
- **report-changed-to**: When the second field changes to a non-empty date, the component MUST call `onChange` once with a range whose `to` is the new date and whose `from` is the existing `value.from`.
- **ignore-cleared-field**: When either field changes to the empty string, the component MUST NOT call `onChange`.
- **pass-typed-date-through**: The component MUST report a non-empty date exactly as the field supplied it, with no clamping to `min`, `max` or the other end and no inverted-range check.
- **merge-class-name**: The component MUST merge a caller `className` onto its wrapper element alongside its own layout classes.
- **load-as-client-module**: The module MUST be marked `"use client"`. This is verified by a static check for the directive at the top of `date-range-picker.tsx`, not by a runtime test vector.

The bounds are asymmetric by design in the source: `min` reaches only the first field and `max` reaches only the second. Together with the cross bounds they keep both fields inside `min` to `max` and keep `from` from passing `to`, but only for picks made in the browser's own picker.

## Appearance

- **Corner radius**: None of its own; each field's corner radius comes from the shared Input component.
- **Padding**: None on the wrapper. Each field group stacks its label above its field with a 6px gap (`gap-1.5`); the two groups sit 12px apart (`gap-3`).
- **Font**: None of its own; the label font comes from the shared Label component and the field font from the shared Input component.
- **Background**: None on the wrapper; the field background comes from the shared Input component.
- **Foreground/Text**: None of its own; text color comes from the shared Label and Input components.
- **Border**: None on the wrapper; the field border comes from the shared Input component.
- **Shadow**: None.
- **Min/Max size**: The wrapper has no fixed size. Each field is `w-auto`, so it takes the width of the browser's native date control instead of stretching to its container. The wrapper is a flex row with `flex-wrap` and `items-end`, so the groups wrap onto a second row when the width runs out and bottom-align when they share a row.

The visual form of the native date control (segments, calendar button, popup) is the browser's; the source does not style it.

## States

| State | Appearance change |
|-------|------------------|
| Default | Two fields showing `value.from` and `value.to`. |
| Focused | Not styled by this component; the shared Input component and the browser's native control own the focus indication. |
| Pressed | Not applicable: the component has no pressable element of its own; the native date control owns its calendar button. |
| Disabled | Not applicable: `DateRangePickerProps` has no `disabled` prop and the component forwards nothing to the fields. |
| Loading | Not applicable: the component renders synchronously from `value` and never waits on anything. |
| Out of range | No change. The component shows no error for a typed date outside `min`, `max` or the other end; the browser's constraint-validation state, if any, is the only signal. |

## Accessibility

- **Role/trait**: Each field is a native `input` of type `date`, so the browser supplies the date-field role, the segment navigation and the calendar picker, the reason the source gives for choosing native fields.
- **Label requirements**: Each field has a visible label bound with `htmlFor` to the field's generated id, so the accessible name of the first field is "From" and of the second is "To".
- **Keyboard**: The component adds no key handling; keyboard operation is the native date control's.
- **State announcements**: The component announces nothing of its own; it has no error, loading or disabled state.
- **Minimum tap target**: NEEDS REVIEW: Not implemented in source. The component sets no height or hit area for the fields; the shared Input component gives each field `h-9` (36px, 2.25rem) and `w-auto`, and the source does not say whether 36px is acceptable. A check of the rendered date field against the platform minimum target size, such as 44pt on Apple platforms and 48dp in Material, would settle it.

## Conformance Test Vectors

The suite beside the source is `dateRangePicker.test.tsx` (`packages/web/packages/ui/src/__tests__/dateRangePicker.test.tsx`); vectors derived from it name its tests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| date-range-picker-001 | render-two-date-fields, label-from-field, label-to-field, show-controlled-value | Render with `value` of `2026-09-01` to `2026-09-30`; look the fields up by label text (test "shows both ends, each bounding the other") | Field labelled "From" has value `2026-09-01`; field labelled "To" has value `2026-09-30` |
| date-range-picker-002 | associate-labels-with-fields | Same render; query by label text "From" and "To" | Each query resolves to exactly one `input` of type `date`, the first and second field respectively |
| date-range-picker-003 | bound-from-by-min, bound-from-by-to | Render with `min` of `2026-01-01`, `max` of `2026-12-31` and the value above (test "shows both ends, each bounding the other") | "From" field has `min` of `2026-01-01` and `max` of `2026-09-30` |
| date-range-picker-004 | bound-to-by-from, bound-to-by-max | Same render | "To" field has `min` of `2026-09-01` and `max` of `2026-12-31` |
| date-range-picker-005 | bound-to-by-from, bound-from-by-to | Render with the value above and no `min` or `max` | "From" has no `min` attribute and `max` of `2026-09-30`; "To" has `min` of `2026-09-01` and no `max` attribute |
| date-range-picker-006 | report-changed-from | Change "From" to `2026-09-10` (test "reports a changed end with the other kept") | `onChange` is called with `from` of `2026-09-10` and `to` of `2026-09-30` |
| date-range-picker-007 | report-changed-to | Change "To" to `2026-09-20` (same test) | `onChange` is last called with `from` of `2026-09-01` and `to` of `2026-09-20` |
| date-range-picker-008 | ignore-cleared-field | Change "To" to the empty string (test "ignores a cleared field") | `onChange` is not called |
| date-range-picker-009 | ignore-cleared-field | Change "From" to the empty string | `onChange` is not called |
| date-range-picker-010 | pass-typed-date-through | Render with the value above and `max` of `2026-12-31`; change "To" to `2027-03-01` | `onChange` is called with `to` of `2027-03-01`; the component does not clamp it to the `max` prop |
| date-range-picker-011 | pass-typed-date-through | Render with the value above; change "From" to `2026-10-15`, later than `value.to` | `onChange` is called with `from` of `2026-10-15` and `to` of `2026-09-30` (an inverted range is reported, not rejected) |
| date-range-picker-012 | unique-field-identity | Render two pickers in one document | The four fields have four distinct ids and each label's association reaches its own field |
| date-range-picker-013 | show-controlled-value | Render with a value, then re-render with a different value | Both fields show the new value; no earlier value is retained |
| date-range-picker-014 | merge-class-name | Render with `className` of `mt-4` | The wrapper element carries `mt-4` together with `flex`, `flex-wrap`, `items-end` and `gap-3` |

## Edge Cases

- **Null and empty input**: A cleared field MUST NOT produce a call to `onChange`; the control keeps showing the empty field until the caller re-renders, because the component holds no value of its own. A caller that passes an empty string for `value.from` or `value.to` gets an empty date control for that end, and the cross bound on the other field becomes an empty attribute value.
- **Boundary values**: A day equal to the other end MUST be accepted: the cross bounds are inclusive, so `from` may equal `to`. A typed date outside `min` or `max` MUST be reported unchanged (the typed-date bypass the source comment names); the browser's own calendar is the part that honours the bounds.
- **Inverted range**: A typed `from` after `to`, or `to` before `from`, MUST be reported as typed. A caller that needs a valid range MUST check it itself, as the source comment states.
- **Concurrent access**: Not applicable: the component holds no state beyond a generated id, so there is nothing for two sessions or threads to contend over; each change event reads the `value` of the render it belongs to, so two changes before a re-render each keep the other end from that render's `value`.
- **Error states**: Not applicable: the component calls no dependency that can fail; the only failure-like input is a date outside the bounds, covered above.
- **Offline or disconnected state**: Not applicable: the component performs no network access.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | `DateRange` | required | The current range, `from` and `to` as `YYYY-MM-DD`. |
| `onChange` | `(range: DateRange) => void` | required | Called with the new range when a field changes to a non-empty date. |
| `min` | `string` | none | Earliest selectable day, `YYYY-MM-DD`; bounds the From field only. |
| `max` | `string` | none | Latest selectable day, `YYYY-MM-DD`; bounds the To field only. |
| `className` | `string` | none | Extra classes merged onto the wrapper. |

## Deep Linking

Not applicable: the component has no URL routing and reads no address.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | From | Label of the first field |
| none (literal) | To | Label of the second field |

- **string-externalization**: NEEDS REVIEW: Not implemented in source. The two labels are literal English strings and no prop supplies a translation; label props or a string table would be needed, and the owner's localization approach for shared web components would settle which.

The displayed date format and the calendar popup language are the browser's, from the user's locale; the value crossing the component boundary is always `YYYY-MM-DD`.

## Accessibility Options

Not applicable: the component has no animation, color or motion of its own; the native control follows whatever the browser and operating system apply to date fields.

## Feature Flags

Not applicable: the component has no feature flag logic.

## Analytics

Not applicable: the component performs no analytics tracking.

## Privacy

- **Data collected**: None. The component reports the dates the user picks to its caller and records nothing itself.
- **Storage**: None.
- **Transmission**: None. The component makes no network request.
- **Retention**: None.

## Logging

Not applicable: the component performs no logging.

## Platform Notes

- **SwiftUI**: Start with two compact-style `DatePicker` views in an `HStack`, titled "From" and "To", bound to a `from` and a `to` date. Give the first `in: min...to` and the second `in: from...max` to reproduce the cross bounds. Differs from the source: `DatePicker` has no cleared state, so ignore-cleared-field has nothing to apply to, and dates are `Date` values, not `YYYY-MM-DD` strings.
- **Compose**: Material 3 offers `DateRangePicker` and `DateRangePickerState`, a single calendar surface that selects both ends in one gesture rather than two fields. To match the source's two-field shape, use two `DatePickerState` instances behind `OutlinedTextField` and a dialog, with a `SelectableDates` implementation expressing the cross bounds. Differs from the source in having no native date input to inherit keyboard and screen-reader behavior from, so those must be supplied.
- **React/Web**: `packages/web/packages/ui/src/components/date-range-picker.tsx` is the implementation: two `Input` fields of `type="date"` with `Label` components tied by `useId`-derived ids, `w-auto` fields in a wrapping flex row, and a `set` factory that drops an empty value and otherwise reports `{ ...value, [end]: e.target.value }`. The suite is `packages/web/packages/ui/src/__tests__/dateRangePicker.test.tsx`.
- **AppKit / UIKit**: On macOS start with two `NSDatePicker` controls (`datePickerStyle` of `.textFieldAndStepper`, `datePickerElements` of `.yearMonthDay`) with `minDate` and `maxDate` set to express the cross bounds, each beside an `NSTextField` label. On iOS use two `UIDatePicker` views (`datePickerMode` of `.date`, `preferredDatePickerStyle` of `.compact`) with `minimumDate` and `maximumDate`. Differs from the source: the controls take `Date` values and cannot be cleared, and the cross bounds must be reassigned from the target-action handler on every change.
- **WinUI 3**: Start with two `CalendarDatePicker` controls in a `StackPanel` (or a `VariableSizedWrapGrid` for the wrapping row), the first with `Header="From"` and the second with `Header="To"`. `CalendarDatePicker` has `Date` (a nullable `DateTimeOffset`), `MinDate`, `MaxDate`, `DateFormat`, `PlaceholderText` and a `DateChanged` event whose arguments carry `NewDate`. In the handler, return early when `NewDate` is null (the cleared case, matching ignore-cleared-field) and otherwise rebuild the range. Set the first picker's `MaxDate` from the second's `Date`, the second's `MinDate` from the first's `Date`, and apply the `min` and `max` props to the first picker's `MinDate` and the second picker's `MaxDate`. Visual states come from the control template (`Normal`, `PointerOver`, `Pressed`, `Disabled` and the focus states); the header is the accessible label unless `AutomationProperties.Name` is set. Differs from the source in three ways: the control opens a calendar flyout, so entry is by the flyout's day grid and not by typed date segments; out-of-range days are disabled in the flyout, so the typed-date bypass the source documents does not arise; and the value is a `DateTimeOffset`, which must be formatted to and parsed from `YYYY-MM-DD` at the boundary.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/date-range-picker.tsx` | confirmed (1.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

- **Decision**: Use two native date inputs rather than a calendar popover.
  **Rationale**: The source comment states the browser's own picker is keyboard- and screen-reader-complete for free, so the component adds no key handling, focus management or announcements of its own.
  **Approved**: pending

- **Decision**: Bound each end by the other (`from` by `value.to`, `to` by `value.from`) and send `min` only to the first field and `max` only to the second.
  **Rationale**: The cross bounds make the picker steer away from an inverted range; `min` and `max` then bound the whole range through the first and second field respectively, the pair the cross bounds already order.
  **Approved**: pending

- **Decision**: Do not validate, clamp or reject a typed date.
  **Rationale**: The source comment states that a typed date bypasses min and max and that a caller needing a valid range must check it; the component reports what the browser supplies and leaves validation to the caller, who knows what an invalid range means for the screen.
  **Approved**: pending

- **Decision**: Ignore a cleared field instead of reporting an empty day.
  **Rationale**: The source comment states a cleared field is ignored rather than reported as an empty day, so `onChange` never carries an empty `from` or `to` and `DateRange` stays two real days.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | passed | Internationalization |

`separation-of-concerns` passes because the component only composes two shared components and reports changes, leaving validation to the caller. `unit-test-coverage` passes because `dateRangePicker.test.tsx` covers the cross bounds, the changed-end report and the cleared field. `keyboard-navigable` and `semantic-markup` pass because the fields are native date inputs with labels bound by `htmlFor`. `touch-target-size` is partial because the component sets no size of its own and the source cannot show the rendered target. `no-hardcoded-strings` fails because "From" and "To" are literals with no way to override them. `locale-aware-formatting` passes because the native control renders the date text in the user's locale and only `YYYY-MM-DD` crosses the boundary.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
