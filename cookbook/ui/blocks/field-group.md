---
id: 781740e8-c83f-40a1-8215-43abfb8d8f56
title: "FieldGroup"
type: recipe
version: 1.3.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A titled, bordered card that groups related Fields — the standard sectioning wrapper for settings forms, with an optional trailing accessory by the title."
platforms:
  - typescript
  - web
tags:
  - forms
  - layout
  - section
  - field
  - ui
ingredients:
  - 0c199036-81c3-47c3-9e79-e4b8187ca69a
depends-on: []
related:
  - 0c199036-81c3-47c3-9e79-e4b8187ca69a
references: []
approved-by: ""
approved-date: ""
---

# FieldGroup

## Overview

The shared `FieldGroup` in `@adh-sdk/ui` — the standard sectioning wrapper for
settings and editor forms. It is a bordered card with an uppercase-mono title row
across the top and its `Field` children stacked below, so a settings pane reads as a
series of titled groups instead of a flat wall of inputs.

The title row also carries an optional `trailing` accessory pinned to its right
edge — a status line ("Saved"), a small action (a "Reset" button), or a badge —
that belongs to the group as a whole rather than to any one field.

`FieldGroup` is presentation-only: it owns no form state and imposes no field type.
It composes the shared `Field` ([adhsdk.ingredient.ui.blocks.field](cookbook:0c199036-81c3-47c3-9e79-e4b8187ca69a)) as its
expected children and reuses the same `fieldCaptionClass` caption treatment as the
field caption, so the group title and the field captions share one visual language.

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Field | [adhsdk.ingredient.ui.blocks.field](cookbook:0c199036-81c3-47c3-9e79-e4b8187ca69a) | The grouped rows — each caption+control+hint/error that the group stacks | yes | Passed as `children`; the group applies `gap-3` between them |

The group title reuses the shared `fieldCaptionClass` from `@adh-sdk/ui/lib/typography`
(the same uppercase-mono caption treatment `Field` uses), so titles and field
captions stay visually identical. `trailing` is an arbitrary caller node
(status text, a `Button`, a badge) — not a fixed ingredient.

## Integration Requirements

- **render-title**: The group MUST render the `title` node as an uppercase-mono
  heading (the shared `fieldCaptionClass`) in the top row.
- **render-title-as-heading**: The group MUST render the `title` inside an
  `<h3>` so the section is a real heading in the document outline.
- **render-trailing-when-set**: When `trailing` is provided, the group MUST
  render it in the title row, right-aligned opposite the title; when unset, the
  title row MUST show the title alone.
- **stack-children**: The group MUST render its `children` (the Fields) as a
  vertical stack below the title row, with consistent spacing between rows.
- **bordered-card**: The group MUST present as a bordered, rounded surface
  (`apt-border` / `apt-surface` tokens) that visually contains its title and fields.
- **merge-classname**: The group MUST merge a caller-supplied `className` onto
  its root `section` without dropping its own layout classes.

## Layout

```
┌ section (rounded, bordered, recessed surface) ─────────────────┐
│  GROUP TITLE                              [ trailing accessory ]│  ← title row
│                                                                 │
│  ┌ Field ───────────────────────────────────────────────────┐ │
│  │ CAPTION / control / hint|error                            │ │
│  └───────────────────────────────────────────────────────────┘ │
│  ┌ Field ───────────────────────────────────────────────────┐ │
│  │ CAPTION / control / hint|error                            │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

- Root: `section` — `flex flex-col gap-3 rounded-lg border border-apt-border
  bg-apt-surface-2/40 p-3` (recessed card).
- Title row: `flex items-center justify-between gap-2`; the `<h3>` title on the
  `fieldCaptionClass`, the `trailing` node right-aligned via `justify-between`.
- Children: the `Field` rows follow the title row in the same column, separated by
  the section's `gap-3`.
- No raw hex; no `!important`; every color is an `apt-*` token.

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `title` | Caller | Group heading (`<h3>`) | Down | Prop |
| `trailing` | Caller | Title-row accessory slot | Down | Prop (optional) |
| `children` (Fields) | Caller | Stacked group body | Down | Prop |
| Field values / validation | Owning form (outside the group) | The `Field` controls | — | Not owned by `FieldGroup` — it is pure layout |

`FieldGroup` holds no state of its own; it is a stateless layout wrapper, so all
form state flows through the `Field` controls the caller nests, not through the
group.

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-title, render-title-as-heading | `title="Profile"` | An `<h3>` carrying the `fieldCaptionClass` classes (`font-mono uppercase tracking-wider text-apt-text-muted`) renders in the top row, containing "Profile" |
| T2 | render-trailing-when-set | `trailing={<Button>Reset</Button>}` | The Reset button renders right-aligned in the title row, opposite the title |
| T3 | render-trailing-when-set | `trailing` omitted | The title row shows the title alone; no trailing element exists in the DOM |
| T4 | stack-children | two `Field` children | Both Fields render stacked below the title row with the group's `gap-3` |
| T5 | bordered-card | any props | The root `section` has the bordered rounded recessed-surface treatment |
| T6 | merge-classname | `className="mt-6"` | Root keeps `flex flex-col … border …` and adds `mt-6` |

## Edge Cases

- No `trailing` → the title row still lays out with `justify-between`, so the title
  sits at the left edge exactly as with an accessory present.
- Zero `children` → an empty titled card renders (title row only); the group does
  not error on an empty body.
- A `trailing` node wider than its slot shares the row via `gap-2`; the title
  (`h3`) does not truncate here — long titles wrap unless the caller constrains them.
- `children` need not be `Field`s specifically — any nodes stack — but the group is
  designed and spaced for `Field` rows.
- `title` is a `ReactNode`, so an inline glyph/badge in the title still renders with
  the caption treatment.

## Platform Notes

- **SwiftUI**: Use `Form` with a `Section(header:)` as the native grouping container — `Section`'s header holds the uppercase-mono title `Text`, with an optional trailing view alongside it in an `HStack` (`.frame(maxWidth: .infinity, alignment: .trailing)` on the trailing side), and the section's content closure holds the grouped field rows in place of `children`. Outside a `Form` context, use a `GroupBox` with the same header/content split.
- **Compose**: Use an `OutlinedCard` as the bordered container, with a `Row` header inside — an uppercase-mono `Text` title and an optional trailing composable, laid out via `Arrangement.SpaceBetween` — followed by a `Column` holding the grouped field rows in place of `children`.
- **React/Web**: Implemented in `packages/web/packages/ui/src/blocks/field-group.tsx`, exported via `@adh-sdk/ui/blocks/field-group`. The component carries `"use client"` at the top of the file; nothing in its own render path (no hooks, no state, no event handlers) needs it, and the `Field` ingredient it composes ships without the directive at all. It composes `Field` ([adhsdk.ingredient.ui.blocks.field](cookbook:0c199036-81c3-47c3-9e79-e4b8187ca69a)) as its children plus the shared `fieldCaptionClass` for the title. Used platform-wide as the sectioning wrapper in settings/editor panes; commonly the last group in such a pane is a destructive "danger zone" section. Verify responsive behavior via Playwright (ui-showcase) at 375 / 768 / 1440 — the title/trailing row and the stacked Fields stay usable on mobile.
- **AppKit / UIKit**: AppKit — use an `NSBox` (`.boxType = .custom`, `.borderType = .lineBorder`) as the bordered container, with its title view holding an uppercase-mono `NSTextField` and an optional trailing `NSView` laid out in a horizontal stack. UIKit — use a grouped `UITableView`/`UICollectionView` section: the section's header view carries the uppercase-mono title label and an optional trailing accessory view, and the section's rows hold the grouped fields.
- **WinUI 3**: Use a vertical `StackPanel` with `Spacing="12"` as the root container (the web `gap-3` is 12px). Apply `Padding="12"`, `BorderBrush` bound to the border token with `BorderThickness="1"` as a literal, `CornerRadius="8"`, and `Background` bound to the surface token for the recessed card effect. Make the title row a `Grid` with `ColumnDefinitions="*,Auto"` and `ColumnSpacing="8"` (the web `gap-2`) — a `TextBlock` header (uppercase letter-spacing to match the web `fieldCaptionClass`) in column 0, and an optional trailing `UIElement` in column 1 — since a `Grid`'s columns give the trailing element real right-alignment where a horizontal `StackPanel` ignores `HorizontalAlignment` on its children. Below the title row, add a vertical `StackPanel` with its own `Spacing="12"` for the grouped field rows — `StackPanel` does not propagate `Spacing` to a nested panel, so each stack sets it explicitly. No interactive states required — the component is a stateless layout wrapper.

API (`@adh-sdk/ui/blocks/field-group`):

```ts
interface FieldGroupProps {
  title: React.ReactNode
  trailing?: React.ReactNode   // right-aligned accessory in the title row
  children: React.ReactNode    // the grouped Fields
  className?: string
}
export function FieldGroup(props: FieldGroupProps): React.ReactElement
```

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/field-group.tsx` | unverified |

## Design Decisions

- **Decision**: The title reuses `fieldCaptionClass` (the same treatment as `Field`
  captions) inside an `<h3>`.
  **Rationale**: Group titles and field captions read as one caption language, and
  the heading gives the section real document-outline structure for AT.
  **Approved**: pending

- **Decision**: `trailing` is a single right-aligned slot rather than a fixed
  actions API.
  **Rationale**: Keeps the group a generic wrapper (status, a button, or a badge)
  and optimizes-for-change by not baking a specific accessory contract into the
  group.
  **Approved**: pending

- **Decision**: The group owns no form state.
  **Rationale**: It stays a pure layout composition over `Field`; value and
  validation policy live in the owning form, keeping the group reusable across
  every settings pane.
  **Approved**: pending

- **Decision**: Recessed `apt-surface-2/40` card on `apt-border`.
  **Rationale**: The group reads as a contained section against the pane
  background without a heavy border or any color literal.
  **Approved**: pending

- **Decision**: The `<h3>` title heading level is fixed rather than exposed as a
  `headingLevel` prop; the group assumes it is placed under an `<h2>`-level pane
  heading.
  **Rationale**: Every current caller nests `FieldGroup` inside a settings/editor
  pane whose own heading is `<h2>`, so a fixed `<h3>` keeps the document outline
  correct without adding an API surface no caller needs yet.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`semantic-markup` and `contrast-ratio` are partial because the source renders a
correct `<h3>` heading and resolves every color through `apt-*` tokens, but the
root `<section>` has no accessible name to be exposed as a landmark region, and
the source does not state the tokens' resolved contrast values.
`dynamic-type-support` is passed because the title uses `fieldCaptionClass`'s
`text-[0.7rem]`, a `rem`-based size that scales with the user's base font
setting. `platform-theming` is passed because every color in the source
(`apt-border`, `apt-surface-2`) resolves through a theme token, with no raw hex
and no `!important`. `separation-of-concerns` is passed because the component
is pure layout over `title`/`trailing`/`children` props with no business logic;
`unit-test-coverage` is failed because no test exercises `field-group.tsx`.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case everywhere they're cited; give SwiftUI/Compose/AppKit-UIKit real native grouping-container guidance in place of "Not applicable"; correct WinUI 3 spacing, title-row layout, and border-brush binding; reformat Design Decisions into Decision/Rationale/Approved blocks and add a decision documenting the fixed h3/assumed-h2-parent heading level; rebuild Compliance as linked, canonically-categorized catalog checks; sharpen the T1 and T3 test vector assertions; correct the React/Web note's "use client" rationale. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Revise WinUI 3 Platform Notes with concrete translation guidance — control names, properties, layout pattern, and XAML structure. Remove "Not applicable" wording. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Expand Platform Notes to all five platforms with translation guidance; set status to review. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe for the titled FieldGroup sectioning wrapper. |
