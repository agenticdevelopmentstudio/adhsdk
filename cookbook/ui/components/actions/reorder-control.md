---
id: a70a5906-e2c2-4e15-8b2c-913453ff3714
title: "Reorder Control"
type: ingredient
version: 1.1.3
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A pair of arrow buttons to move items up and down within a list, always visible with disabled state at boundaries."
platforms:
  - typescript
  - web
tags:
  - ui
  - reorder
  - list
depends-on: []
related:
  - 26df832c-a7f7-4cf6-b3f5-240c61e8bd68
references:
  - https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-disabled
approved-by: ""
approved-date: ""
---

# Reorder Control

## Overview

A pair of arrow buttons (↑/↓) that enable users to move items up or down within a list. Unlike controls that hide on hover, this component is always visible, with disabled state used to indicate the boundaries (first and last item) rather than removing the button. The component accepts a subject string to personalize button labels, supports a busy state to indicate in-flight moves, and uses arrow icons (not chevrons) to distinguish reordering from disclosure actions.

## Behavioral Requirements

- **render-up-button**: Component MUST render an "up" button that, when clicked and not busy, calls the onMoveUp callback.
- **render-down-button**: Component MUST render a "down" button that, when clicked and not busy, calls the onMoveDown callback.
- **disable-up-at-boundary**: Component MUST set the up button's disabled attribute when canMoveUp is false.
- **disable-down-at-boundary**: Component MUST set the down button's disabled attribute when canMoveDown is false.
- **boundary-buttons-persist**: Component MUST NOT remove buttons when canMoveUp or canMoveDown is false; it MUST display them in disabled state.
- **arrow-icons**: Component MUST use arrow-shaped icons to represent move direction (up and down), not chevrons or other shapes.
- **group-role**: Component MUST wrap both buttons in a container with role="group" to semantically group them.
- **group-aria-label**: Component MUST provide an aria-label to the group container: `Reorder` when there is no subject, otherwise `Reorder ${subject}` (one space between).
- **button-aria-labels**: Each button MUST have an aria-label describing the action: `Move up` or `Move down` when there is no subject, otherwise `Move up ${subject}` or `Move down ${subject}` (one space between).
- **button-titles**: Each button MUST have a title attribute matching its aria-label for tooltip display.
- **custom-subject-support**: Component MUST append a space and the subject string to the button and group labels when the subject prop is provided, as in `Move up Work item`.
- **busy-state-appearance**: When busy is true, component MUST reduce opacity to 60% on the outer container. The ARIA rules for busy are in **aria-disabled-while-busy** and **group-aria-busy**.
- **aria-disabled-while-busy**: Component MUST use aria-disabled (not the disabled HTML attribute) when busy to preserve keyboard focus.
- **busy-click-guard**: Click handlers for onMoveUp and onMoveDown MUST NOT fire when busy is true, even if the button is clicked.
- **decorative-icons**: Component MUST mark arrow icons as aria-hidden="true" because they are decorative (the aria-label conveys the meaning).
- **compact-transparent-buttons**: Component MUST render both buttons as transparent, compact icon buttons (no visible background or border) sized for inline use, each showing a single directional arrow glyph.
- **custom-class-name**: Component MAY accept a custom className prop for additional styling applied to the outer container.
- **overlapping-disabled-states**: When busy is true and a button's boundary flag (canMoveUp or canMoveDown) is false, the button MUST carry both the disabled attribute (from the boundary) and aria-disabled (from busy) at the same time — the two are set independently and are not mutually exclusive.
- **group-aria-busy**: Component MUST set aria-busy to true on the group container when busy is true, and MUST leave it unset (undefined) when busy is false.
- **empty-subject-no-suffix**: When subject is omitted or an empty string, component MUST render button and group labels without a trailing space or subject suffix (e.g., "Move up", not "Move up ").
- **both-boundaries-disabled**: When both canMoveUp and canMoveDown are false, component MUST render both buttons disabled and MUST NOT error.
- **busy-to-idle-recovery**: When busy transitions from true to false, component MUST restore full opacity and interactivity, and MUST no longer set aria-disabled or aria-busy.
- **subject-not-truncated**: Component MUST include the full subject text in every label it builds, however long; it MUST NOT truncate or wrap it. Truncation is the consuming component's job if it wants one.
## Appearance

- **Corner radius**: set by the icon-sm size variant of the shared Button (`min(var(--radius-md), 12px)`), not by the ghost variant.
- **Gap**: 2px between the two buttons.
- **Font**: Inherited from Button component (not directly styled)
- **Background**: Transparent (ghost variant)
- **Foreground/Text**: The muted foreground color role, applied to the icons.
- **Border**: None (ghost variant)
- **Shadow**: None
- **Min/Max size**: 28×28px per button, fixed by the icon-sm Button size.
## States

| State | Appearance change |
|-------|-------------------|
| Default | Both buttons fully opaque, interactive if not at boundary |
| Up button at boundary (canMoveUp=false) | Up button appears disabled (reduced opacity and pointer events disabled, inherited from the shared Button's disabled styling), down button unaffected |
| Down button at boundary (canMoveDown=false) | Down button appears disabled (reduced opacity and pointer events disabled, inherited from the shared Button's disabled styling), up button unaffected |
| Busy/In-flight (busy=true) | Group container dimmed to opacity 60% (buttons dim with it), aria-busy set on the group, aria-disabled set on both buttons (not the group), click handlers guarded |
| Boundary button also busy (e.g. canMoveUp=false AND busy=true) | Both the disabled attribute (boundary) and aria-disabled (busy) are set on the same button; see **overlapping-disabled-states** |
| Focused button | Standard focus styling from Button component (outline/ring) |

## Accessibility

- **Role/trait**: The outer container uses role="group"; each button is a standard button control.
- **Label requirements**: The group has an aria-label ("Reorder" or "Reorder subject"); each button has an aria-label with the direction and optional subject; title attributes provide tooltips.
- **Icon semantics**: Arrow icons are marked aria-hidden="true" because their meaning is conveyed by the button's aria-label.
- **State announcement**: aria-disabled on both buttons (not the group) when busy; aria-busy set to true on the group when busy (see **group-aria-busy**) and removed when not busy.
- **Disabled state**: When canMoveUp or canMoveDown is false, the button's disabled attribute is set. Independently, when busy, aria-disabled is set on that same button to preserve keyboard focus — the two are not exclusive, so a boundary button that is also busy carries both attributes at once (see **overlapping-disabled-states**).
- **Keyboard navigation**: Buttons are fully keyboard accessible; disabled buttons are skipped by tab order; focused buttons can be activated via Enter or Space.
- **Minimum tap target**: Buttons use the icon-sm variant, which is 28×28px — short of all three platform minimum tap targets (44×44pt iOS, 48×48dp Android, 40×40px web). The Button component's `--adh-button-min-height` / `--adh-button-min-width` CSS variables let a consuming surface raise the floor for every descendant button, but icon-sm's own default does not meet these minimums.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| reorder-control-001 | render-up-button | canMoveUp=true, onMoveUp callback | Up button renders; clicking it calls onMoveUp |
| reorder-control-002 | render-down-button | canMoveDown=true, onMoveDown callback | Down button renders; clicking it calls onMoveDown |
| reorder-control-003 | disable-up-at-boundary | canMoveUp=false | Up button renders with disabled attribute; click does not call onMoveUp |
| reorder-control-004 | disable-down-at-boundary | canMoveDown=false | Down button renders with disabled attribute; click does not call onMoveDown |
| reorder-control-005 | boundary-buttons-persist | canMoveUp=false, canMoveDown=true (first row) | Up button is present but disabled; down button is enabled |
| reorder-control-006 | boundary-buttons-persist | canMoveUp=true, canMoveDown=false (last row) | Down button is present but disabled; up button is enabled |
| reorder-control-007 | arrow-icons | default | The up and down icons are an up arrow and a down arrow glyph (the `ArrowUp` and `ArrowDown` icons on web); neither is a chevron icon |
| reorder-control-008 | group-role, group-aria-label | default | Outer span has role="group" and aria-label containing "Reorder" |
| reorder-control-009 | button-aria-labels, button-titles | default | Both buttons have aria-label and title attributes with "Move up" or "Move down" text |
| reorder-control-010 | custom-subject-support | subject="Work item" | Button aria-labels are exactly `Move up Work item` and `Move down Work item`; group aria-label is exactly `Reorder Work item` |
| reorder-control-011 | busy-state-appearance | busy=true | Group container opacity is 60% |
| reorder-control-012 | aria-disabled-while-busy | busy=true | aria-disabled attribute is set; disabled attribute is not set (buttons remain in tab order) |
| reorder-control-013 | busy-click-guard | busy=true, user clicks up or down button | onMoveUp and onMoveDown are not called; component ignores click |
| reorder-control-014 | decorative-icons | default | Arrow icons have aria-hidden="true" |
| reorder-control-015 | compact-transparent-buttons | default | Buttons render with no visible background fill or border and compute to 28×28px |
| reorder-control-016 | custom-class-name | className="custom-class" | Custom class is applied to outer container alongside default classes |
| reorder-control-017 | overlapping-disabled-states | busy=true, canMoveUp=false | Up button has both the disabled attribute and aria-disabled set at the same time |
| reorder-control-018 | group-aria-busy | busy=true, then busy=false | Group has aria-busy="true" while busy; attribute is absent once busy is false |
| reorder-control-019 | empty-subject-no-suffix | subject=undefined | Button aria-labels are exactly "Move up" / "Move down"; group aria-label is exactly "Reorder" (no trailing space) |
| reorder-control-020 | both-boundaries-disabled | canMoveUp=false, canMoveDown=false | Both buttons render disabled; component does not throw |
| reorder-control-021 | busy-to-idle-recovery | busy=true transitioning to busy=false | Opacity returns to 100%; aria-disabled and aria-busy are no longer set on group or buttons |
| reorder-control-022 | subject-not-truncated | subject is a 300-character string | Every button aria-label and the group aria-label contain the full 300 characters |
| reorder-control-023 | busy-click-guard, aria-disabled-while-busy | busy=true, focus a button and press Enter, then Space | onMoveUp and onMoveDown are not called; the button keeps focus |
## Edge Cases

- **Empty or undefined subject**: no trailing space or suffix on any label (see **empty-subject-no-suffix**).
- **Rapid clicks while busy**: none reach `onMoveUp` or `onMoveDown` (see **busy-click-guard**).
- **Both moves disabled** (a single-item list): both buttons render disabled, with no error (see **both-boundaries-disabled**).
- **Transition from busy to not busy**: full opacity and interactivity return, and the busy attributes are removed (see **busy-to-idle-recovery**).
- **Very long subject text**: the full text goes into every label (see **subject-not-truncated**).
## Configuration

| Prop | Type | Required | Default | Description |
|---|---|---|---|---|
| `onMoveUp` | `() => void` | yes | — | Move the row one place toward the start of its list. |
| `onMoveDown` | `() => void` | yes | — | Move the row one place toward the end of its list. |
| `canMoveUp` | `boolean` | yes | — | False on the first row; the up button renders disabled rather than disappearing. |
| `canMoveDown` | `boolean` | yes | — | False on the last row. |
| `busy` | `boolean` | no | `false` | A move for this row is in flight: the pair dims and ignores clicks. |
| `subject` | `string` | no | `undefined` | Accessible subject appended to the labels, e.g. `"work item Ship it"`. |
| `className` | `string` | no | `undefined` | Extra classes for the outer container. |

Styling beyond `className` is controlled by the shared Button component.
## Deep Linking

Not applicable: This component is a UI control within a list context and does not represent a navigable route or deep-linkable resource.

## Localization

The component's labels are hardcoded English strings (`Move up`, `Move down`, `Reorder`). Localizing them would need label props or a locale provider, neither of which the source implements. This is recorded as accepted debt in Design Decisions.
## Accessibility Options

Not applicable: The component has no animations or motion, so Reduce Motion does not apply. Increase Contrast and Differentiate Without Color can be handled via className overrides at the consuming level, as the component uses arrow icons (directional, not color-based) and relies on the Button component's contrast behavior.

## Feature Flags

Not applicable: This component is a basic UI primitive with no feature-flag gating in the source code.

## Analytics

Not applicable: The component has no built-in event tracking. Analytics instrumentation is the responsibility of the consuming component, which can instrument the onMoveUp and onMoveDown callbacks as needed.

## Privacy

Not applicable: This component does not collect, transmit, or store any user data beyond the immediate interaction state.

## Logging

Not applicable: The component has no internal logging or diagnostic output. Debugging and logging would be handled at the consumer level.

## Platform Notes

- **React/Web**: Implemented as a functional component using the Button component from the same UI library, Tailwind CSS classes (cn utility for class merging, `gap-0.5` for the 2px gap, `opacity-60`, `inline-flex`, `items-center`, and `text-apt-text-muted` for the muted foreground), and Lucide React icons (ArrowUp, ArrowDown). The transparent, compact-button intent (see **compact-transparent-buttons**) is implemented via the Button component's `variant="ghost"` and `size="icon-sm"` props (28×28px, the `size-7` utility; radius from the same variant). The component is self-contained with minimal dependencies.
- **SwiftUI**: A SwiftUI port would use an HStack containing two Button views with SF Symbol arrows (arrowshape.up and arrowshape.down). Boundary state uses the button's `.disabled(!canMoveUp)` / `.disabled(!canMoveDown)` modifiers, matching the source's use of the real disabled attribute at boundaries. Busy state must NOT use `.disabled`, which removes a control from the accessibility focus tree — instead wrap the HStack in `.opacity(busy ? 0.6 : 1.0)` and guard the action closure itself (`if !busy { onMoveUp() }`), the same guard the source uses, so the button stays focusable during a busy in-flight move (see **aria-disabled-while-busy**).
- **Compose**: A Jetpack Compose port would use a Row with two IconButton composables, leveraging Material Design Icons (Icons.Filled.ArrowUpward and Icons.Filled.ArrowDownward). Boundary state is managed via the button's `enabled` parameter, and `enabled` is for boundaries only: busy must NOT set `enabled = false`, which would lose focus. Busy keeps the control enabled, applies a graphicsLayer modifier for opacity, and guards the click action itself, like the source.
- **AppKit / UIKit**: On AppKit, use NSStackView (Orientation=Horizontal) with two NSButton instances styled as icon-only with arrow template images. On UIKit, use UIStackView with two UIButton instances configured as system buttons with SF Symbol images. Boundary state via the isEnabled property, and `isEnabled` is for boundaries only: busy must NOT set `isEnabled = false`, which would lose focus. Busy keeps the control enabled, dims via alphaValue (AppKit) or alpha (UIKit), and guards the action in the target.
- **WinUI 3**: A WinUI 3 port would use a StackPanel (Orientation=Horizontal) containing two Button controls. Boundary state binds `IsEnabled` to `canMoveUp` / `canMoveDown`, matching the source's use of the real disabled attribute at boundaries. Busy state must NOT toggle `IsEnabled` or rely on `AllowFocusOnInteraction` — a disabled control cannot receive focus regardless of that property — instead apply an `Opacity` binding to `0.6` and guard the `Click` event handler itself (skip the move when busy), the native equivalent of `aria-disabled` (see **aria-disabled-while-busy**).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/reorder-control.tsx` | confirmed (1.1.3) |

## Design Decisions

**Decision**: Render disabled buttons at the first/last row boundaries rather than removing them.
**Rationale**: Keeps the column width stable, preventing visual shift when navigating a list, and signals to users that the list has an order even when the current row cannot move (see **boundary-buttons-persist**).
**Approved**: pending

**Decision**: Use arrow icons (↑/↓), not chevrons, for the move actions.
**Rationale**: A deliberate departure from sibling controls like InlineCommitControl; chevrons mean disclosure elsewhere in these packages (e.g. TreeRowLabel), and a row that can both expand and reorder would otherwise carry two different metaphors as the same shape (see **arrow-icons**).
**Approved**: pending

**Decision**: Use aria-disabled, not the HTML disabled attribute, to signal the busy state.
**Rationale**: Borrowed from InlineCommitControl ([adhsdk.ingredient.ui.components.actions.inline-commit-control](cookbook:26df832c-a7f7-4cf6-b3f5-240c61e8bd68)) and preserves keyboard focus for users navigating via keyboard, letting them remain in the control sequence during an in-flight request without losing their place (see **aria-disabled-while-busy**). The [MDN aria-disabled reference](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-disabled) documents this focus-preserving behavior, in contrast to the native disabled attribute.
**Approved**: pending

**Decision**: Ship the labels as hardcoded English, and accept that as known debt.
**Rationale**: `Move up`, `Move down` and `Reorder` are built inside the component, so a non-English UI cannot change them without forking (the `no-hardcoded-strings` check fails for this reason). The remedy is optional label props, or a locale provider, defaulting to today's English so adding them is not a breaking change.
**Approved**: pending

**Decision**: Ship the 28×28px icon-sm buttons, and accept that as known debt against the touch-target minimums.
**Rationale**: The compact size suits an inline trailing cell, but it is short of 44pt, 48dp and 40px (the `touch-target-size` check fails for this reason). The remedy is a larger size variant for touch surfaces; a surface can also raise the floor today with the Button's `--adh-button-min-height` and `--adh-button-min-width` variables.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source (`reorder-control.tsx`): `aria-label`/`title` on the group and both buttons and `aria-hidden` on the icons support screen readers; native `<button>` elements plus the independent `disabled`/`aria-disabled` handling keep keyboard operability and focus intact; `role="group"`, `aria-label`, `aria-disabled`, and `aria-busy` are all applied correctly for semantic markup; the icon-sm size renders at 28×28px, short of every platform's tap-target minimum; `text-apt-text-muted` sets color via a theme token whose resolved contrast ratio the source does not state (partial); and "Move up", "Move down", and "Reorder" are hardcoded string literals with no localization path. The consumer owns every piece of state — where the row sits, what "up" means, whether a move is in flight — and the control only renders it (separation-of-concerns passed); `reorderControl.test.tsx` directly exercises the handler wiring, the boundary-disabled arrows, and the busy state (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.3 | 2026-11-14 | Mike Fullerton | Pinned the exact label templates and made custom-subject-support a MUST, added subject-not-truncated and vectors 022 and 023, replaced Configuration with a props table, recorded the hardcoded-string and touch-target debt as Design Decisions, trimmed duplicated busy rules, neutralized Appearance, and aligned the Compose and AppKit/UIKit busy guidance. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Fixed busy-state-appearance: aria-disabled belongs to both buttons only; group gets aria-busy, not aria-disabled. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Renamed `may-accept-custom-className` to the subject-only `custom-class-name`. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; added requirements and test vectors for the busy/boundary overlap, aria-busy, empty-subject, both-boundaries-disabled, and busy-to-idle edge cases; corrected Appearance and minimum-tap-target values against the source; reworded the ghost/icon-sm and lucide-react-specific requirements and test vector as platform-neutral intent, moving the web specifics to Platform Notes; fixed the SwiftUI and WinUI 3 busy-state focus guidance; filled in the Compliance table; split Design Decisions into Decision/Rationale/Approved blocks; added the InlineCommitControl related-domain and an aria-disabled reference. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
