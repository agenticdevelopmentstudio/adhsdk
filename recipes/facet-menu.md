---
id: 60a907a2-2cc8-4c0c-bb54-3b0516d280b6
title: Facet Menu
domain: adhsdk://recipes/facet-menu
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Multi-select filter menu with count badge and quick-select actions.
platforms:
- typescript
- web
tags:
- filter
- multi-select
- menu
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Facet Menu

## Overview

A facet menu is a multi-select filter control presented as a button with a popover. The trigger button displays the filter label and a count of selected values. The popover provides checkboxes for each option, along with quick-select "All" and "None" actions, and it stays open across repeated selections — it is not a dismiss-on-pick menu, because that would end the multi-select interaction after the first checkbox toggle. This component is used to narrow result sets in lists or tables without removing the visual indication of active filters.

## Behavioral Requirements

- **render-trigger**: The component MUST render a button trigger displaying the label text and a count of selected items in parentheses (e.g., "Category (3)") when one or more items are selected.
- **omit-count-when-empty**: The component MUST NOT display the count when zero items are selected; only the label text MUST be shown in the trigger.
- **disable-trigger**: The component MUST disable the trigger button when the options list is empty.
- **show-chevron**: The component MUST display a chevron-down icon in the trigger, marked as decorative (`aria-hidden="true"`).
- **trigger-expanded-state**: The trigger MUST expose its expanded/collapsed state and that it controls a popup (`aria-expanded`, `aria-haspopup`), supplied by the underlying Popover trigger component.
- **render-popover**: The component MUST display a popover when the trigger is clicked, containing the option list and quick-select buttons, and the popover MUST remain open while options are toggled.
- **render-options**: The component MUST render each option as a checkbox with an associated label, derived from the options array.
- **label-transform**: The component MAY accept a `labelOf` function to transform option values into display labels; if not provided, the option value MUST be displayed as-is.
- **toggle-on-checkbox-click**: The component MUST add or remove an option from the selection when its checkbox is toggled (by click or by keyboard activation), invoking the `onChange` callback with the updated selection.
- **synchronous-selection-update**: Each `onChange` call MUST be computed from the current `selected` prop at the moment of the toggle. The component holds no selection state of its own, so the host MUST apply each `onChange` to `selected` before the next toggle is processed, or rapid toggles will each compute from the same stale `selected` value and overwrite one another instead of accumulating.
- **render-all-button**: The component MUST render an "All" quick-select button that selects every option and invokes `onChange`.
- **disable-all-button**: The component MUST disable the "All" button when all options are already selected.
- **render-none-button**: The component MUST render a "None" quick-select button that clears all selections and invokes `onChange`.
- **disable-none-button**: The component MUST disable the "None" button when zero items are currently selected.
- **handle-overflow**: The component MUST allow the option list to scroll vertically when the number of options exceeds available space (max-height 16rem, vertical scrolling enabled).
- **preserve-selection-state**: The component MUST NOT alter the selection when the popover is opened or closed.
- **empty-selection-semantics**: The component MUST NOT assign any filtering meaning to the selection itself — it only tracks which values are checked. Whether an empty selection means "no filter is applied" is the host application's decision, not the component's.
- **stale-selection-values**: If `selected` contains a value not present in `options`, that value remains selected and continues to count toward the trigger's badge, but is not rendered as a checkbox. When "All" is enabled (see **disable-all-button** — some current option is not yet selected), clicking it MUST replace the selection with exactly the current `options` (dropping the stale value); clicking "None" MUST always replace the selection with an empty set (also dropping the stale value), since **disable-none-button** only disables "None" when the selection — stale values included — is already empty. If every current option is already selected alongside a stale value, **disable-all-button** disables "All", so "All" cannot drop the stale value in that state; only "None", or the host clearing it directly, can. Because the component is fully controlled, the host MAY clear a stale value directly by calling `onChange` itself, even while the trigger is disabled for having zero options.

## Appearance

- **Trigger Button**:
  - Variant: ghost (low prominence)
  - Size: small
  - Text: label, followed by count in parentheses (when count > 0)
  - Icon: ChevronDown, 14×14px, margin-left 4px
  - Background: transparent in default state, platform-standard hover/pressed backgrounds
  - Foreground: inherit from button component

- **Popover**:
  - Width: 14rem (224px)
  - Background: platform-standard panel background
  - Alignment: start (left-aligned to trigger)
  - Padding: 8px

- **Quick-Select Buttons** ("All" and "None"):
  - Variant: ghost
  - Size: small
  - Arranged horizontally
  - Gap: 4px
  - Row gap: 8px below buttons to option list

- **Option Checkboxes**:
  - Checkbox: 16×16px
  - Label text: 14px (small body text style), rendered inline with checkbox
  - Row gap: 8px between checkbox and label
  - Row padding: 2px vertical (0.125rem) per row
  - Cursor: pointer on label (entire row is clickable)

## States

| State | Appearance Change |
|-------|------------------|
| Trigger Default | Ghost button, chevron down, no count if selection empty |
| Trigger Disabled | Opacity reduced, pointer-events disabled (when options.length === 0) |
| Trigger Hover | Platform-standard ghost button hover (if enabled) |
| Trigger Pressed | Platform-standard ghost button pressed |
| Popover Open | Popover visible, stacked "All"/"None" buttons above scrollable option list |
| Popover Closed | Popover hidden |
| "All" Button Enabled | Clickable, standard ghost appearance |
| "All" Button Disabled | Opacity reduced (all options already selected) |
| "None" Button Enabled | Clickable, standard ghost appearance |
| "None" Button Disabled | Opacity reduced (selection already empty) |
| Checkbox Checked | Checkmark visible, aria-checked="true" |
| Checkbox Unchecked | No checkmark, aria-checked="false" |

## Accessibility

- **Role**: The trigger MUST be a button (`<button>` or `role="button"`).
- **Label**: The trigger MUST have accessible text from its label content (e.g., "Category").
- **Count Semantics**: The count in the trigger (e.g., "(3)") MUST be included in the accessible label to convey how many filters are active; see **stale-selection-values** for how it counts values no longer present in `options`, and #localization/facet.trigger_count for how the format must be produced.
- **Chevron Icon**: The chevron-down icon MUST be marked `aria-hidden="true"`. It is decoration only — the collapsible/expanded state is not conveyed by the label or the chevron, but by **trigger-expanded-state** (`aria-expanded`/`aria-haspopup` on the trigger itself).
- **Checkbox Labels**: Each checkbox MUST have an associated label via `<label>` wrapping. The label text is derived from the option value or the `labelOf` function; the base checkbox component points `aria-labelledby` at the wrapping `<label>` automatically.
- **Checkbox State**: Each checkbox MUST have `aria-checked` set to match the checked state (the checkbox is an ARIA-pattern control, not a native `<input type="checkbox">`, so this state is not implicit).
- **Popover Accessibility**: The popover MUST be exposed with `role="dialog"` (provided by the underlying Popover component) — a non-modal disclosure surface, not a menu. Focus SHOULD move to the first interactive element in the popover (per platform conventions).
- **Keyboard Navigation**: The popover MUST be navigable by keyboard (Tab moves between checkboxes and buttons; Enter or Space toggles a checkbox); the Escape key or clicking outside SHOULD close the popover without altering the selection (see **preserve-selection-state**).
- **Touch Target**: All interactive elements (trigger button, checkboxes, quick-select buttons) MUST have a touch target of at least 44×44px on touch-enabled platforms; on web with mouse/pointer input, 16×16px is acceptable for checkboxes if the associated label is large enough to encompass a 44×44px target.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| facet-001 | render-trigger, omit-count-when-empty, empty-selection-semantics | options: ["A", "B"], selected: empty | Trigger displays "Label" only, no count; the component performs no filtering logic of its own |
| facet-002 | render-trigger, omit-count-when-empty | options: ["A", "B"], selected: {"A"} | Trigger displays "Label (1)" |
| facet-003 | disable-trigger | options: [], selected: empty | Trigger button's `disabled` attribute is `true`; clicking it does not open the popover |
| facet-004 | show-chevron | options: ["A", "B"], selected: empty | ChevronDown icon is visible and aria-hidden="true" |
| facet-005 | render-popover | options: ["A", "B"], trigger clicked | Popover opens, displaying "All", "None", and checkbox list |
| facet-006 | render-options | options: ["Apple", "Banana"], selected: empty | Checkboxes labeled "Apple" and "Banana" are rendered |
| facet-007 | label-transform | options: ["a", "b"], labelOf: (v) => v.toUpperCase(), selected: empty | Checkboxes labeled "A" and "B" are rendered |
| facet-008 | toggle-on-checkbox-click | options: ["A", "B"], selected: {"A"}, click checkbox "B" | onChange called with {"A", "B"} |
| facet-009 | render-all-button | options: ["A", "B", "C"], selected: empty | "All" button is rendered and clickable |
| facet-010 | disable-all-button | options: ["A", "B"], selected: {"A", "B"} | "All" button is disabled |
| facet-011 | render-none-button | options: ["A"], selected: {"A"} | "None" button is rendered and clickable |
| facet-012 | disable-none-button | options: ["A"], selected: empty | "None" button is disabled |
| facet-013 | handle-overflow | options: [40 items], selected: empty | Option list scrolls vertically when popover is open |
| facet-014 | preserve-selection-state | options: ["A", "B"], selected: {"A"}, open and close popover | Selection remains {"A"} |
| facet-015 | trigger-expanded-state | options: ["A", "B"], selected: empty, popover closed then opened | Trigger's `aria-expanded` is "false" when closed and "true" when open; `aria-haspopup` is present at all times |
| facet-016 | render-all-button | options: ["A", "B", "C"], selected: {"A"}, click "All" | onChange called with {"A", "B", "C"} |
| facet-017 | render-none-button | options: ["A", "B"], selected: {"A", "B"}, click "None" | onChange called with an empty Set |
| facet-018 | toggle-on-checkbox-click | options: ["A", "B"], selected: {"A", "B"}, click checkbox "A" (uncheck) | onChange called with {"B"} |
| facet-019 | disable-trigger | options: [], attempt to activate trigger via Enter or Space | Popover does not open |
| facet-020 | toggle-on-checkbox-click | options: ["A"], selected: empty, checkbox "A" focused via keyboard, press Space | onChange called with {"A"} |
| facet-021 | preserve-selection-state | options: ["A", "B"], selected: {"A"}, popover open, press Escape | Popover closes; selection remains {"A"} |
| facet-022 | stale-selection-values | options: ["B"], selected: {"A", "B"} (A stale), popover opened | Only checkbox "B" is rendered; trigger displays "Label (2)" |
| facet-023 | stale-selection-values, disable-all-button | options: ["B", "C"], selected: {"A", "B"} ("A" stale, "C" unselected), click "All" | "All" is enabled (not every current option is selected); onChange called with {"B", "C"} (stale "A" dropped) |
| facet-024 | stale-selection-values | options: ["B"], selected: {"A", "B"}, click "None" | onChange called with an empty Set (stale "A" dropped) |
| facet-025 | synchronous-selection-update | options: ["A", "B"], selected: {"A"}, checkbox "B" clicked twice in immediate succession with no intervening prop update | onChange is invoked twice, each call computed from selected={"A"} (both calls yield {"A", "B"}); the component does not accumulate a running selection internally |

## Edge Cases

- **Empty options array**: When `options.length === 0`, the trigger MUST be disabled and the popover MUST NOT open. The selection is unchanged (even if it was previously populated).
- **Selected items not in options**: If the `selected` set contains a value not present in the current `options` array, that value MUST remain in the selection and continue to count toward the trigger's badge, but MUST NOT be rendered as a checkbox in the popover. (This can occur if options are dynamically filtered and a selected value is removed from the list.) See **stale-selection-values** for how "All" and "None" resolve this: "None" always replaces the selection outright, dropping the stale value; "All" does the same, but only while it is enabled — if every current option is already selected alongside the stale value, **disable-all-button** disables "All", and only "None" (or a host-driven `onChange`) can drop the stale value. Because the component is controlled, a host can also clear a stale value directly through `onChange` without going through the UI — which matters because the trigger (and therefore the popover) is disabled whenever `options` is empty.
- **All selected after filtering**: If options are filtered and all remaining options become selected, the "All" button MUST be disabled.
- **Rapid onChange calls**: Multiple rapid checkbox clicks MUST result in multiple separate `onChange` calls; no debouncing or coalescing is performed by the component. See **synchronous-selection-update**: each call is computed from whatever `selected` prop the component currently has, so clicks made before the host re-renders with the previous call's result will each compute from the same starting selection rather than building on each other.
- **LabelOf function returns empty string**: If `labelOf(option)` returns an empty string, the checkbox is rendered with no visible label text (the label container is still present for accessibility but empty).
- **Very long option labels**: Long labels MUST wrap or truncate gracefully within the popover width; no minimum or maximum label length is enforced.

## Configuration

Not a runtime-configurable component — `FacetMenu` is controlled entirely through its props:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | `string` | — (required) | Text shown in the trigger, before the count |
| `options` | `string[]` | — (required) | The full set of selectable values, in render order |
| `selected` | `Set<string>` | — (required) | The currently checked values; owned by the host |
| `onChange` | `(next: Set<string>) => void` | — (required) | Invoked with the updated selection on every toggle, "All", or "None" |
| `labelOf` | `(value: string) => string` | identity (value shown as-is) | Optional transform from an option value to its display label |

## Deep Linking

Not applicable: FacetMenu is a UI component without navigation semantics; it does not participate in deep linking.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `facet.all` | "All" | Quick-select button to select all options |
| `facet.none` | "None" | Quick-select button to clear all selections |
| `facet.trigger_count` | "{label} ({count})" | Trigger text combining the filter label with its selected count; MUST be produced through a locale-aware, plural-capable formatter (e.g., ICU MessageFormat) rather than a fixed "(N)" template, since numeral placement and pluralization are not the same across locales |

The component does not provide i18n keys for option labels; label strings come from the `options` array or the `labelOf` function, which are the responsibility of the host application to localize. If a host's `labelOf` applies a casing transform (for example, upper-casing an option value), that transform is locale-sensitive and MUST use a locale-aware casing API — never an invariant-culture call — because the option label is user-facing text.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Popover opening/closing animation SHOULD be disabled or simplified; checkbox state changes SHOULD not animate. Popover positioning SHOULD occur instantly. |
| Increase Contrast | Button and checkbox backgrounds and borders SHOULD use increased contrast colors per platform guidelines. Label and value text MUST meet WCAG AA contrast ratio (4.5:1 for normal text, 3:1 for large text). |
| Differentiate Without Color | State distinctions (checked vs. unchecked, enabled vs. disabled) MUST NOT rely on color alone; checkboxes MUST use a checkmark or fill pattern to indicate state. |

## Feature Flags

Not applicable: FacetMenu is a foundational UI component with no feature flags. It is always enabled.

## Analytics

Not applicable: FacetMenu does not generate analytics events. The host application is responsible for instrumenting selection changes via the `onChange` callback if analytics are desired.

## Privacy

Not applicable: FacetMenu does not collect, store, or transmit user data. It is a stateless UI component that emits selection state changes to the host application via the `onChange` callback.

## Logging

Not applicable: FacetMenu is a UI component and does not perform logging. Errors in the `onChange` callback or `labelOf` function are the responsibility of the host application to handle and log.

## Platform Notes

- **SwiftUI**: Implement with `.popover(isPresented:)` (or an equivalent overlay) attached to the trigger `Button`, not `Menu` — `Menu` and its toggle items dismiss after each selection, which breaks the multi-select toggle interaction. Inside the popover, lay out the "All"/"None" buttons above a `ScrollView` of checkbox-style `Toggle` rows. Apply `.disabled()` to the trigger `Button` when `options` is empty.

- **Compose**: Implement with a custom, non-dismissing dropdown surface (e.g. a themed `Popup` or `DropdownMenu` composable configured to stay open on item selection) anchored to the trigger `Button` — not `ExposedDropdownMenuBox`, which is a single-select text-field pattern that closes on pick. Render "All"/"None" as `Button`s above a `Column` of checkbox rows constrained with `Modifier.heightIn(max = 256.dp)` and vertical scrolling.

- **React/Web**: Implement using this package's `Popover`/`PopoverTrigger`/`PopoverContent`, `Button`, and `Checkbox` components, as shown in `blocks/facet-menu.tsx`: the trigger is a ghost `Button` (disabled when `options` is empty); the popover content holds "All"/"None" ghost `Button`s above a vertically scrollable (`max-h-64 overflow-auto`) column of `<label>`-wrapped `Checkbox` rows.

- **AppKit / UIKit**: Implement with a custom, non-dismissing popover — `NSPopover` on macOS, a custom-anchored or sheet-presented view controller on iOS — rather than `NSMenu`/`UIMenu`, both of which close after a single item is picked and would break the multi-select toggle. The popover content mirrors the React layout: "All"/"None" buttons above a scrollable checkbox list.

- **WinUI 3**: Implement with a `Flyout` attached to the trigger `Button` (not a plain `ComboBox`, which is a single-select text field, and not `InfoBar`, which is a notification banner — neither fits a multi-select filter). Place "All"/"None" `Button`s in the flyout content above a `ScrollViewer` bounded to a fixed height (e.g. `MaxHeight="256"`) containing `CheckBox` rows.

## Design Decisions

- **Decision**: The count displayed in the trigger (e.g., "Category (3)") is shown whenever one or more values are selected, not hidden by default.
  **Rationale**: Operators rely on this count to verify that filters are active without opening the popover; a hidden count risks acting on a filtered set as though it were the full list — for example, deleting the "wrong" rows when a filter is invisibly active.
  **Approved**: pending

- **Decision**: Both "All" and "None" quick-select buttons are kept, even though selecting every option and clearing the selection show the same filtered rows.
  **Rationale**: They serve different interaction purposes: "All" is the starting point for excluding a single option ("everything except this"), which requires the boxes to actually be checked to represent that intent; "None" is the way back to no active filter. The trigger's count (N vs. 0) makes the two states visibly distinct.
  **Approved**: pending

- **Decision**: Checkboxes do not carry an individual `aria-label`; each is wrapped in a `<label>` element with text content, and the base checkbox component points `aria-labelledby` at that wrapping label.
  **Rationale**: Adding an `aria-label` on top of the `<label>`/`aria-labelledby` association would make the computed accessible name announce the option text twice.
  **Approved**: pending

- **Decision**: The option list is constrained to a maximum height (16rem / 256px) with vertical scrolling enabled; horizontal scrolling is not enabled.
  **Rationale**: This keeps the popover from exceeding the visible viewport on small screens and keeps the behavior consistent across platforms; long labels are expected to wrap or be truncated by the host container instead.
  **Approved**: pending

- **Decision**: FacetMenu is implemented and documented as a popover that stays open across multiple selections, not as a native auto-dismissing menu.
  **Rationale**: A native menu (SwiftUI `Menu`, `NSMenu`/`UIMenu`, a dismiss-on-pick WinUI `MenuFlyout`) closes after each item is picked, which breaks the multi-select toggle interaction the component depends on.
  **Approved**: pending

- **Decision**: "All" replaces the selection with exactly the current `options`, and "None" replaces it with an empty set — both drop any stale selected values not present in `options`.
  **Rationale**: The component only ever sets `selected` to values it can see; a value that came from a since-filtered-out option has no representation in the current option list, so neither quick-select action can special-case it.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [locale-aware-formatting](agenticdevelopercookbook://compliance/internationalization#locale-aware-formatting) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The trigger, checkboxes, and quick-select buttons are built on ARIA-pattern primitives (base-ui `Popover`, `Checkbox`) that supply keyboard support, so `keyboard-navigable` passes; contrast, touch-target sizing on non-web platforms, `aria-expanded`/`aria-haspopup` exposure, and dynamic type scaling are inherited from those shared components and platform theming rather than demonstrated in this source, so they read as `partial`; the "All"/"None" strings are already keyed (`facet.all`, `facet.none`) while the trigger's "(N)" count is a fixed, non-plural-aware template baked into the component (`facet.trigger_count`), so `string-externalization`/`no-hardcoded-strings` are `partial` and `locale-aware-formatting` `failed`. `separation-of-concerns` passes because `facet-menu.tsx` delegates all keyboard/focus/dismissal behavior to base-ui's `Popover`/`Checkbox` primitives and owns only the selection-set logic (All/None, disabled state) a filter widget needs. `unit-test-coverage` passes: `facetMenu.test.tsx` renders `FacetMenu` directly and exercises ticking, All/None, and the disabled-trigger state.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | All-button disables when every option selected; stale-selection, facet-023, edge case fixed. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; rewrote Overview, Popover Accessibility, and Platform Notes to describe a non-dismissing popover instead of a native menu; added trigger-expanded-state, empty-selection-semantics, stale-selection-values, and synchronous-selection-update requirements grounded in the source's controlled-Set behavior; filled Configuration with the prop types; reformatted Design Decisions into Decision/Rationale/Approved form and added two new decisions; replaced the "Not applicable" Compliance section with a check table and supporting sentence; fixed the Tailwind-class and self-contradictory padding value in Appearance; added a localization key and casing-transform note for the trigger count; added conformance vectors for All/None payloads, unchecking, the disabled-menu case, keyboard toggling, Escape, and stale selections; replaced facet-003's nondeterministic assertion with a `disabled`-attribute check |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
