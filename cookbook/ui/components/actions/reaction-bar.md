---
id: 169da1b6-2a22-4fec-9f01-8118e5242bd5
title: "ReactionBar"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-08-08
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The emoji reactions on one subject — count chips that toggle plus a small palette; presentational, so the caller owns the tallies and the write."
platforms:
  - typescript
  - web
tags:
  - component
  - reactions
  - emoji
  - toggle
  - ui
depends-on: []
related:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
references: []
approved-by: ""
approved-date: ""
---

# ReactionBar

## Overview

The shared `ReactionBar` in `@adh-sdk/ui` — the emoji reactions on **one subject**,
rendered as a row of count chips plus a small palette for adding one. It is the single home
for the reaction treatment, so a work-item comment, a discussion post and anything else the
backend's polymorphic reaction store can name all react the same way.

The component is **presentational**, like the rest of the package: it receives the tallies
already folded (`{ emoji, count, mine }`) and calls back with an emoji. It never fetches, never
writes, and holds no reaction state — the only state it owns is whether its palette popover is
open. That is what keeps one bar reusable across subjects that have nothing else in common.

A chip is a **toggle, not a counter**. Pressing a chip you are already part of takes your
reaction back; pressing one you are not adds it. Both directions call the same `onToggle` with
the same argument, because the caller can already tell which way it goes from the `mine` flag it
supplied — two callbacks would be two chances for them to disagree.

Two exports ship from `@adh-sdk/ui/components/reaction-bar`: the `ReactionBar`
component and `DEFAULT_REACTIONS`, the default palette, exported so a host starts from one
fact rather than restating a literal per surface.

## Behavioral Requirements

- **renders-one-chip-per-tally**: The component MUST render exactly one chip per entry in `reactions`, in the order given — it MUST NOT sort, merge or filter them.
- **chip-shows-emoji-and-count**: Each chip MUST show its emoji and its count.
- **chip-is-a-toggle**: Activating a chip MUST invoke `onToggle` with that chip's emoji, whether or not the viewer has already reacted with it.
- **announces-own-reaction**: A chip whose `mine` is true MUST carry `aria-pressed="true"`, and a chip whose `mine` is false MUST carry `aria-pressed="false"`.
- **stateless-tallies**: The component MUST NOT change a count or a `mine` flag itself; it only signals `onToggle`, leaving the write and the re-read to the consumer.
- **palette-offers-choices**: The component MUST render a palette trigger that opens a popover offering `choices` (default `DEFAULT_REACTIONS`).
- **palette-uses-the-same-toggle**: Picking an emoji from the palette MUST invoke `onToggle` with that emoji — the same call a chip makes — and MUST close the popover.
- **palette-offers-everything**: The palette MUST offer every entry in `choices`, including emoji already present on the subject, so it never has to explain an absence.
- **busy-goes-inert**: When `busy`, every chip and the palette trigger MUST be disabled, and the bar MUST keep rendering the same chips in the same order.
- **disabled-hides-the-way-in**: When `disabled`, the counts MUST still render, every chip MUST be disabled, and the palette trigger MUST NOT render at all.
- **names-the-subject**: Every control's accessible name MUST include `subjectLabel`, so two bars on one page are distinguishable.
- **glyph-is-decorative**: The emoji glyph inside a control MUST be `aria-hidden`, leaving the control's `aria-label` as its sole accessible name.

## Appearance

```
 ┌─────────┐ ┌─────────┐
 │ 👍  3   │ │ 🎉  1   │  ☺+       ← chips (pressed / not) + palette trigger
 └─────────┘ └─────────┘
   mine        theirs    add

        ┌──────────────────────┐
        │ 👍 🎉 👀 🙏 😄 ❤️  │   ← the popover palette
        └──────────────────────┘
```

- Row: `flex flex-wrap items-center gap-1`, so a long set wraps rather than scrolls.
- Chip: the shared `Button` at `size="xs"`, `rounded-full border px-2`. A chip the viewer is
  part of is `variant="secondary"` with `border-apt-gold`; one they are not is `variant="ghost"`
  with `border-apt-border`. The count is `tabular-nums text-apt-text-dim`, so a count crossing
  9 → 10 does not shift the row.
- Palette trigger: a `size-6` circular `PopoverTrigger` holding a lucide `SmilePlus` at 14px,
  `text-apt-text-muted` brightening to `text-apt-text` on hover/focus, with an
  `apt-gold/25` focus ring.
- Palette: `PopoverContent` at `w-auto p-1.5`, aligned to the trigger's start, holding one
  `size="icon-xs"` ghost `Button` per choice.
- No raw hex; no arbitrary colors; no `!important`.

## States

| State | Appearance change |
|---|---|
| Rest, not yours | Ghost chip, `border-apt-border` |
| Rest, yours | Secondary (filled) chip, `border-apt-gold`, `aria-pressed="true"` |
| Chip hover / focus-visible | The shared `Button`'s own hover and focus treatment |
| Palette open | The popover renders below/beside the trigger, aligned to its start |
| Busy (write in flight) | Every chip and the trigger disabled; the row is otherwise unchanged |
| Disabled (viewer may not react) | Chips render and are disabled; the palette trigger is absent |
| No reactions yet | No chips; the palette trigger alone |

## Accessibility

- Each chip is a real `<button type="button">` with `aria-pressed`, so it reads as a toggle
  rather than as a link or a plain button — the pressed state is announced, not merely coloured.
- A chip's accessible name is `"<emoji> <count> on <subjectLabel>"`, and the palette's controls
  are `"React to <subjectLabel>"` and `"React <emoji> to <subjectLabel>"`. The subject is in
  every name because a page shows many bars, and "👍 3" alone does not say which comment.
- The name states the emoji, the count and the subject — never the interaction ("click to…"):
  the role and `aria-pressed` already carry that, and a screen reader would otherwise read the
  instruction on every chip.
- The glyph inside each control is `aria-hidden`, so AT is not told the emoji's CLDR name twice.
- The palette trigger is the `PopoverTrigger` primitive **styled directly**, not a `Button`
  wrapped in one, so there is a single focusable element rather than two nested.
- `busy` disables rather than removes: a bar that dropped its chips mid-write would move the
  pointer's target between the press and the result.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-one-chip-per-tally, chip-shows-emoji-and-count, names-the-subject | `reactions=[{👍,2,mine},{🎉,1}]`, `subjectLabel="Ada's comment"` | buttons named `👍 2 on Ada's comment` and `🎉 1 on Ada's comment` |
| T2 | announces-own-reaction | same as T1 | the 👍 chip has `aria-pressed="true"`; the 🎉 chip `"false"` |
| T3 | chip-is-a-toggle | click the 👍 chip (the viewer's own) | `onToggle` called with `"👍"` |
| T4 | stateless-tallies | after T3 without a consumer re-render | the chip still reads `2` and still reads pressed |
| T5 | palette-offers-choices, palette-uses-the-same-toggle | open the palette, pick `DEFAULT_REACTIONS[1]` | `onToggle` called with that emoji; the popover closes |
| T6 | palette-offers-everything | open the palette while 👍 is on the subject | 👍 is still offered in the palette |
| T7 | busy-goes-inert | `busy` | every chip is `disabled`; the same two chips are still present, in order |
| T8 | disabled-hides-the-way-in | `disabled` | the chips render and are disabled; no control named `React to <subject>` exists |
| T9 | renders-one-chip-per-tally | `reactions=[]` | no chip; the palette trigger alone |
| T10 | glyph-is-decorative | inspect a chip's glyph | the emoji `<span>` carries `aria-hidden` |
| T11 | names-the-subject (Playwright) | two bars with different `subjectLabel` | each bar's chips are addressable by name without ambiguity |

## Edge Cases

- **A count reaching zero is the consumer's problem.** The bar renders what it is given; a
  tally that drops to zero should be dropped from `reactions` by the caller, not rendered as
  "👍 0".
- **An emoji not in `choices`.** A subject can carry an emoji the palette does not offer (an
  older palette, another client). It renders and toggles normally — `choices` governs what can
  be *added*, not what can be shown.
- **A repeat press.** The bar does not debounce; a caller that can have two writes in flight
  passes `busy` while one is running.
- **Signed out.** `disabled` keeps the counts (they are public) and removes the way in, rather
  than hiding the bar — a subject with reactions still shows them.
- **A long set.** The row wraps (`flex-wrap`). A palette long enough to need a grid is a
  different component (a picker), which is why `DEFAULT_REACTIONS` is deliberately short.
- **Duplicate emoji in `reactions`.** Not deduplicated here — React would warn on the repeated
  key. The fold that produces the tallies owns uniqueness.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `reactions` | `ReactionBarItem[]` | — | The subject's tallies, in the order they should read. Required. |
| `onToggle` | `(emoji: string) => void` | — | Add the emoji when the viewer has not reacted with it, take it back when they have. Required. |
| `subjectLabel` | `string` | — | Names the subject in every control's accessible name. Required. |
| `choices` | `readonly string[]` | `DEFAULT_REACTIONS` | What the palette offers. |
| `busy` | `boolean` | `false` | A write is in flight: everything is inert, nothing is hidden or re-ordered. |
| `disabled` | `boolean` | `false` | The viewer may not react; counts still show, the palette trigger is not rendered. |
| `className` | `string` | — | Extra classes for the row; merged via `cn()`. |

`ReactionBarItem` is `{ emoji: string; count: number; mine: boolean }`.

`DEFAULT_REACTIONS` is `["👍", "🎉", "👀", "🙏", "😄", "❤️"]`, in that order.

## Deep Linking

Not applicable: ReactionBar is a presentational component with no navigable state or independent views to deep-link to. Navigation concerns belong to the consumer.

## Localization

The component builds its own accessible-name strings around the consumer-supplied `subjectLabel`:
`` `${emoji} ${count} on ${subjectLabel}` ``, `` `React to ${subjectLabel}` ``, and
`` `React ${emoji} to ${subjectLabel}` ``. Only `subjectLabel` comes from the consumer — the
surrounding English phrasing ("on", "React to", "React … to") is hardcoded in the component and
is not externalized or translated. The count is interpolated as a plain number without
locale-aware formatting (no `Intl.NumberFormat`), so a large count renders in a fixed,
non-localized digit grouping. See **string-externalization**, **no-hardcoded-strings**, and
**locale-aware-formatting** in Compliance.

## Accessibility Options

Not applicable: The component responds to all standard browser and OS-level accessibility features through its native HTML `<button>` elements and the `aria-pressed` attribute. Assistive technologies interact with these standard mechanisms directly; no component-specific accessibility options are defined.

## Feature Flags

Not applicable: The component is not feature-flagged. It is always available as part of `@adh-sdk/ui`.

## Analytics

Not applicable: ReactionBar is presentational and signals user interactions through the `onToggle` callback only. The caller owns the logic of what a toggle means and any analytics associated with it — logging, event classification, and telemetry belong in the consumer's implementation of `onToggle`.

## Privacy

Not applicable: The component is presentational and carries no data collection, storage, transmission, or retention logic. It passes user choices to the consumer's `onToggle` handler; privacy and data handling are the consumer's responsibility.

## Logging

No logging. `ReactionBar` is presentational; what a toggle means, and any telemetry about it, belong to the consumer's `onToggle` handler.

## Platform Notes

- **React/Web**: File: `packages/web/packages/ui/src/components/reaction-bar.tsx`, exported from `@adh-sdk/ui/components/reaction-bar` via the package's `./components/*` wildcard. Composes the shared `Button` and `Popover`/`PopoverTrigger`/`PopoverContent` primitives, plus a lucide `SmilePlus` icon; carries `"use client"` directive to own the popover's open state. Themes via `@adh-sdk/ui` token system (`apt-gold`, `apt-border`, `apt-text-*`, etc.).

- **SwiftUI**: `VStack`/`HStack` do not wrap, so use a custom flow `Layout` for the chip row.
  Each reaction is a SwiftUI `Button` with its pressed state driven from the `mine` input, not
  from local state, and announced via `.accessibilityAddTraits(mine ? .isSelected : [])` — the
  equivalent of `aria-pressed`. The palette could be a `Menu` or custom `Popup`/`Popover` with
  emoji buttons. Count display uses `Text` with `.monospacedDigit()` font modifier. `@State` is
  used only for whether the palette is open or closed.

- **Compose**: `Row` with `Modifier.fillMaxWidth()` does not wrap, so use `FlowRow` for the chip
  row. Each reaction is a `Button` composable with the pressed state exposed via
  `Modifier.toggleable(value = mine, onValueChange = { ... })` or
  `Modifier.semantics { selected = mine }` — the equivalent of `aria-pressed` — plus a separate
  trigger `Button` styled as a circular icon for the palette. Palette is a `Popup` or
  `DropdownMenu`. Counts display in `Text` with `style = TextStyle(fontFeatureSettings = "tnum")`
  for monospaced digits (`fontFeatureSettings` is a `TextStyle` parameter, not a modifier). Use
  `remember { mutableStateOf(false) }` only for palette open state.

- **AppKit / UIKit**: `NSStackView`/`UIStackView` do not wrap, and `.fillEqually` is wrong for
  chips of different widths, so use `NSCollectionView` (AppKit) or `UICollectionView` (UIKit)
  with a flow layout. Each chip is an `NSButton` (AppKit) with `.pushOnPushOff` for toggle
  semantics, or a `UIButton` (UIKit) with the `.selected` trait bound to `mine`. The palette is
  an `NSPopover` (AppKit) or a `UIMenu`/`UIAction` presented via a
  `UIPopoverPresentationController` (UIKit; `UIMenuActions` does not exist). Accessibility via
  `NSAccessibilityRole` (AppKit) or `accessibilityTraits` (UIKit) set to `.button`, with custom
  `NSAccessibilityElement` / `accessibilityLabel` construction for each chip and trigger.

- **WinUI 3**: `StackPanel` has no `TextWrapping` property, so use an `ItemsRepeater` with a
  `WrapLayout` (or a `WrapPanel`) for the row. Each reaction is a `ToggleButton` with `IsChecked`
  bound to `mine` (`Button` has no `IsToggled` property), styled per the Fluent 2 Design System.
  The palette is a `Flyout` or `MenuFlyout` attached to a `Button` trigger. Count display uses
  `TextBlock` with `FontFamily="Segoe UI Variable"` and `Typography.NumeralAlignment="Tabular"`
  for tabular numerals (`NumberSubstitution.CultureOverride` does not give tabular digits).
  Accessibility via `AutomationProperties.Name` (equivalent to aria-label) for every interactive
  element.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/reaction-bar.tsx` | unverified |

## Design Decisions

**Decision**: One `onToggle` callback, not separate `onAdd` and `onRemove` callbacks.
**Rationale**: The caller already knows which way the press goes — it supplied `mine`. A second
callback would let the two disagree and would push the same decision into every consumer.
**Approved**: pending

**Decision**: The bar holds no tallies itself.
**Rationale**: Optimistically mutating a count here would fork the truth: the server's answer
arrives moments later and the bar would have to reconcile a state it does not own. Keeping it
presentational is also what lets one component serve every subject kind.
**Approved**: pending

**Decision**: Announce the pressed state with `aria-pressed` rather than colour alone.
**Rationale**: The pressed/not distinction is the whole interaction; a border tint states it
only to people who can see it.
**Approved**: pending

**Decision**: The palette trigger is the `PopoverTrigger` primitive itself, styled directly, not
a `Button` wrapped in one.
**Rationale**: Wrapping a `Button` inside a `PopoverTrigger` nests two focusable elements;
styling the trigger directly is the sibling `OptionMenu` / `SectionHeader` idiom in this
package.
**Approved**: pending

**Decision**: `DEFAULT_REACTIONS` is exported and deliberately short.
**Rationale**: Exported so the default palette is one fact rather than a literal per surface;
short because a long grid is a picker, and a picker is a different component.
**Approved**: pending

**Decision**: `busy` disables controls rather than hiding them.
**Rationale**: Removing chips mid-write moves the pointer's target between the press and its
result.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: it styles every element through `apt-*` tokens with no raw hex and
composes only the shared `Button`/`Popover` primitives (no bespoke controls); it sets
`aria-pressed`, `aria-hidden`, and a subject-naming `aria-label` correctly on every control; and
it builds its accessible-name and count text as hardcoded English template literals with no
`Intl.NumberFormat` call, which is what fails the three internationalization checks. The component
is explicitly presentational — the caller fetches tallies and performs the toggle, never the bar
itself (separation-of-concerns passed); `reactionBar.test.tsx` directly exercises chip labeling,
pressed state, toggle/take-back, the palette, busy inertness, and the disabled/empty-reactions
cases (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: fix Compliance table statuses/links and add the Internationalization checks the Localization gap fails; reformat Design Decisions to the Decision/Rationale/Approved triple; correct WinUI 3, Compose, SwiftUI and AppKit/UIKit platform-note API errors; drive the SwiftUI pressed state from `mine` instead of local state; require chips to be disabled under `disabled`; list the exact `DEFAULT_REACTIONS` array in Configuration; rewrite Localization to describe the component's hardcoded English strings and unformatted counts. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Add platform notes for SwiftUI, Compose, AppKit/UIKit, WinUI 3; mark inapplicable sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy). |
| 1.0.0 | 2026-08-08 | Mike Fullerton | Initial recipe; documents the toggle chips, the palette, and the presentational contract. |
