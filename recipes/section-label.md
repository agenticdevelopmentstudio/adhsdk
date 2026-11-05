---
id: fce1333d-7f42-49f8-86da-508159701043
title: SectionLabel
domain: adhsdk://recipes/section-label
type: ingredient
version: 1.2.1
status: review
language: en
created: '2026-07-03'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The display micro-heading — a quiet uppercase-mono in-pane label (sectionLabelClass) with an optional trailing slot; distinct from a Field caption or title."
platforms:
- typescript
- web
tags:
- component
- typography
- heading
- ui
depends-on: []
related:
- adhsdk://recipes/user-card
- adhsdk://recipes/field
- adhsdk://recipes/section-header
references: []
approved-by: ''
approved-date: ''
---

# SectionLabel

## Overview

The shared `SectionLabel` in `@adh-sdk/ui` — the **display micro-heading**: the
quiet, wide-tracked uppercase-mono label that heads a pane or an in-card section
("RECENT ACTIVITY", "SOCIAL LINKS", "MONITORED SITES"). It ships as two exports
from `@adh-sdk/ui/components/section-label`: the `sectionLabelClass` string (so
any element can wear the treatment) and the `SectionLabel` component (the div
that applies it, with an optional trailing slot).

The treatment is `font-mono text-[0.625rem] font-medium uppercase
tracking-[0.1em] text-apt-text-dim` — smaller, dimmer, and wider-tracked than a
form caption. When a `trailing` node is given, the label lays out as a
`justify-between` row so an action (a "Refresh" button, a gear) sits opposite the
label on the same baseline; with no trailing node it is a bare div.

**This is one of three deliberately distinct heading treatments — keep them apart:**

| Treatment | Home | Role | Look |
|---|---|---|---|
| `sectionLabelClass` / `SectionLabel` | `components/section-label.tsx` | **Display** in-pane / in-card micro-heading | `text-[0.625rem]` mono, `apt-text-dim`, `tracking-[0.1em]` |
| `fieldCaptionClass` | `lib/typography.ts` | **Form** caption / group title / column header | `text-[0.7rem]` mono, `apt-text-muted`, `tracking-wider` |
| `SectionHeader` | `blocks/section-header.tsx` | **Page/section title** (with `?` help + actions) | `text-sm` mono, **`apt-gold`**, `font-medium` |

SectionLabel is the *quietest* of the three: dimmer and smaller than a field
caption, and a different element entirely from the gold page title. Reach for
`fieldCaptionClass` when labeling a form field; reach for `SectionHeader` for the
gold headline of a page area; reach for `SectionLabel` for the muted label inside
a pane or card. It is a stateless div with no `"use client"` directive.

## Behavioral Requirements

- **exports-class-string**: The module MUST export `sectionLabelClass` as a string so any element can adopt the display micro-heading treatment without the component.
- **applies-display-treatment**: The component MUST apply `sectionLabelClass` (`font-mono text-[0.625rem] font-medium uppercase tracking-[0.1em] text-apt-text-dim`) to the label element.
- **renders-children-as-label**: The component MUST render its `children` as the label text.
- **bare-div-without-trailing**: With no `trailing` node, the component MUST render a single div carrying `sectionLabelClass` (no wrapping row).
- **row-with-trailing**: Given a `trailing` node, the component MUST render a `flex items-center justify-between` row with the label on the left and the trailing node on the right.
- **merges-classname-on-label**: The component MUST merge any `className` after `sectionLabelClass` on the label div via `cn()`, so a consumer MAY tweak it without losing the treatment.
- **distinct-from-caption-and-title**: The component MUST NOT reuse `fieldCaptionClass` or the `SectionHeader` gold-title treatment — it is a separate, quieter display label.

## Appearance

```
bare (no trailing)
  RECENT ACTIVITY
  Deployed build #147 to staging.

with trailing (justify-between row)
  MONITORED SITES                             [ Refresh ]
  57 sites · all green.
```

- Label element: `sectionLabelClass` =
  `font-mono text-[0.625rem] font-medium uppercase tracking-[0.1em] text-apt-text-dim`.
- Bare form: `<div className={cn(sectionLabelClass, className)}>{children}</div>`.
- Trailing form: an outer `flex items-center justify-between gap-2` row wrapping
  the same label div plus the `trailing` node.
- Token-driven color (`apt-text-dim`); no raw hex, no `!important`.

## States

| State | Appearance change |
|---|---|
| Bare | Single div with the display micro-heading treatment |
| With `trailing` | `justify-between` row: label left, trailing node right |
| Restyled (`className`) | Extra classes merged onto the label div after `sectionLabelClass` |

## Accessibility

- SectionLabel renders a plain `div`, **not** a semantic heading (`h1`–`h6`) or
  `role="heading"` — it is a *display* label, so it does not enter the document's
  heading outline. Consumers who need the label in the outline SHOULD supply
  their own heading semantics.
- It carries no interactivity of its own; the `trailing` slot's node (a button,
  say) brings its own accessible name and focus behavior.
- Sufficient for a quiet in-pane label whose associated content follows visually;
  the treatment relies on size/case/tracking, not color alone, to read as a
  heading.
- Rendered at `text-[0.625rem]` (10px) in the dim `apt-text-dim` color token,
  this is small, low-contrast text; it MUST meet WCAG AA's 4.5:1 contrast ratio
  against the pane/card surfaces it appears on (see the `contrast-ratio`
  compliance check below) — the source defines the token but not its resolved
  color, so verify `apt-text-dim` against each surface it is used on.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | applies-display-treatment, renders-children-as-label | `<SectionLabel>Recent activity</SectionLabel>` | text "Recent activity" is present; its className contains every token of `sectionLabelClass` |
| T2 | bare-div-without-trailing | same as T1 | label is a single div (no justify-between wrapper row) |
| T3 | row-with-trailing, renders-children-as-label | `<SectionLabel trailing={<button>gear</button>}>Stats</SectionLabel>` | outer wrapper's className contains `justify-between`; the label element (text "Stats") and the button named "gear" are both direct children of that wrapper |
| T4 | exports-class-string | import `sectionLabelClass` | it is a string containing `font-mono`, `text-[0.625rem]`, `uppercase`, `tracking-[0.1em]`, `text-apt-text-dim` |
| T5 | merges-classname-on-label | `<SectionLabel className="mb-2">Env</SectionLabel>` | label className contains both `mb-2` and `text-apt-text-dim` |
| T6 | distinct-from-caption-and-title | compare to `fieldCaptionClass` | `sectionLabelClass` differs (`text-[0.625rem]`/`apt-text-dim` vs `text-[0.7rem]`/`apt-text-muted`) |
| T7 | distinct-from-caption-and-title | compare `sectionLabelClass` to `SectionHeader`'s title treatment | `sectionLabelClass` contains no `apt-gold` token — it differs entirely from `SectionHeader`'s gold title color, not only from `fieldCaptionClass` |

## Edge Cases

- **`trailing={null}` / omitted.** `trailing == null` selects the bare-div
  branch, so an explicit `null` behaves exactly like omitting the prop.
- **Falsy-but-present trailing.** `trailing={false}` is not `== null`, so it
  takes the row branch and renders an empty right cell — pass `undefined`/`null`
  (or omit) to get the bare div.
- **Rich children.** `children` is any `ReactNode`, so a label MAY include an
  inline count or icon, though the treatment is tuned for short uppercase text.
- **Not a heading.** Because it is a div, it will not appear in a screen reader's
  heading list — intentional for a display micro-label, but a trap if you needed
  outline semantics.
- **Overriding the color.** A `className` that sets a text-color token overrides
  `apt-text-dim` via `cn()` merge; classes that touch other properties leave the
  dim color in place.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `children` | `ReactNode` | — | The label text (typically short uppercase words). |
| `trailing` | `ReactNode` | — | Optional node placed opposite the label in a `justify-between` row (e.g. a Refresh button). |
| `className` | `string` | — | Extra classes merged after `sectionLabelClass` on the label div via `cn()`. |
| `sectionLabelClass` | `string` (export) | — | The raw treatment string, for applying the micro-heading look to any element directly. |

## Deep Linking

Not applicable: SectionLabel is an internal presentational component, not an app screen or navigation destination.

## Localization

Not applicable: The component renders only its children (caller-provided text); it carries no strings of its own.

## Accessibility Options

Not applicable: SectionLabel responds to no display options such as Reduce Motion or Increase Contrast; it is a static label.

## Feature Flags

Not applicable: The component is not gated behind a feature flag.

## Analytics

Not applicable: The component has no interactive behavior and logs no analytics events.

## Privacy

Not applicable: The component collects, stores, and transmits no user data.

## Logging

No logging. `SectionLabel` is a presentational label; it holds no state and takes
no action.

## Platform Notes

- **SwiftUI**: A SwiftUI implementation would start from `Text` or `Label` with font modifiers for the micro-heading treatment — `.font(.system(.caption2, design: .monospaced))`, `.fontWeight(.medium)`, and `.tracking(1)`. SwiftUI's `tracking` is in points, not em, so `0.1` (copied literally from the CSS `em` value) gives almost no visible tracking at caption2 size; use roughly `size × 0.1` (caption2 is ~11pt, so ≈1pt) to match `tracking-[0.1em]`. Bind the foreground to the tertiary text semantic color (`.foregroundStyle(.tertiary)`), not the secondary color `fieldCaptionClass` uses — the two treatments must stay visually distinct.
- **Compose**: An Android/Compose implementation would start from `Text` with `fontSize = 10.sp` (matching `text-[0.625rem]`), `fontFamily = FontFamily.Monospace`, `fontWeight = FontWeight.Medium`, and `letterSpacing = 0.1.em` (matching `tracking-[0.1em]`). Set the text color to the theme's dim/tertiary text color (e.g. a tertiary-text token distinct from the one used for captions), matching the web treatment's `apt-text-dim` — not the muted/secondary tone `fieldCaptionClass` uses.
- **React/Web**: Component exported from `packages/web/packages/ui/src/components/section-label.tsx`. Stateless div with optional flex-row wrapper for the trailing slot. Merges consumer `className` after `sectionLabelClass` via the `cn()` utility (from `lib/utils`). No `"use client"` directive — renders in a server component. Sibling treatments (`fieldCaptionClass` and `SectionHeader`) are defined separately; do not collapse them.
- **AppKit / UIKit**: An iOS/macOS implementation would start from `NSTextField` (AppKit) or `UILabel` (UIKit) — not SwiftUI's `Text` — with font `.monospacedSystemFont(ofSize: 10, weight: .medium)`, an `NSAttributedString.Key.kern` attribute of about `1` (matching `tracking-[0.1em]` at this size), and the string uppercased (`.uppercased()`). That uppercasing is a locale-sensitive transform — let it run with the current locale as the source's CSS `text-transform: uppercase` does; do not force an invariant/`en_US_POSIX` locale for user-facing text. Bind the text color to the tertiary label semantic color (`NSColor.tertiaryLabelColor` / `UIColor.tertiaryLabel`), not the secondary label color used for the caption treatment.
- **WinUI 3**: A Windows/WinUI implementation would use a two-column `Grid` (`ColumnDefinitions="*,Auto"`) as the row, not a horizontal `StackPanel` — a `StackPanel` cannot express `justify-between`; the label sits in the `*` column and the trailing slot in the `Auto` column. `TextBlock` has no `CharacterCasing` property, so uppercase the text at the source or through a converter — again a locale-sensitive transform, so avoid an invariant-culture uppercase call for user-facing text. Set `CharacterSpacing="100"` (WinUI's units are 1/1000 em, so `100` matches `tracking-[0.1em]`), and bind `Foreground` to `TextFillColorTertiaryBrush`, not the secondary/muted brush used for the caption treatment. Set the column spacing to `8` (px), matching the source's `gap-2`, rather than a general `Margin`.

## Design Decisions

- **Decision**: Ship `sectionLabelClass` as an exported string alongside the `SectionLabel` component.
  **Rationale**: Lets an element that can't be a `SectionLabel` (a `<legend>`, an existing div) still wear the exact treatment, keeping the look in one place.
  **Approved**: pending

- **Decision**: Keep three distinct heading treatments — `SectionLabel`, `fieldCaptionClass`, and `SectionHeader` — rather than one shared heading component.
  **Rationale**: The display micro-label is quieter (dimmer, smaller, wider-tracked) than a form caption, and it is a plain label rather than the gold page title. Keeping them separate prevents a one-size heading that fits none of the three roles.
  **Approved**: pending

- **Decision**: Build the common "label + one action opposite it" pane head into `SectionLabel` via a single `trailing` prop, rather than a separate row component.
  **Rationale**: This is the most common pane head, so building it in avoids forcing every caller to hand-roll a flex row.
  **Approved**: pending

- **Decision**: Render a `div` (or `span`), not a semantic heading element.
  **Rationale**: It is a display label, not an outline node; semantic headings are the caller's choice when the outline matters.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

These statuses rest on the source's plain `<div>`/`<span>` markup (no ARIA role or heading claimed), its `rem`-based sizing that scales with root font size, its color reference to the `apt-text-dim` token without a resolved contrast value, its complete absence of hardcoded string literals (`children` is always caller-supplied), and its reliance on the browser's built-in `text-transform: uppercase` for case-folding of that caller-supplied text. `separation-of-concerns` passes because `section-label.tsx` is pure presentation with no business logic, and `unit-test-coverage` passes because `stat.test.tsx` renders `SectionLabel` directly and asserts on its class treatment.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: name the dim/tertiary color explicitly in every non-web Platform Notes bullet instead of "muted"; give concrete SwiftUI/Compose/AppKit-UIKit/WinUI 3 translation values and flag the uppercase casing transform as locale-sensitive; rewrite T3's expected outcome as a mechanical DOM assertion and add T7 to test distinct-from-caption-and-title against SectionHeader; reformat Design Decisions into the Decision/Rationale/Approved triple; rebuild Compliance as catalog-linked checks; add section-header to related; note the WCAG contrast risk of the dim 10px text in Accessibility. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Revise Platform Notes: remove "Not applicable" phrasing from non-web bullets; add concrete WinUI 3 translation guidance (TextBlock, CharacterCasing, Foreground, Margin, StackPanel for trailing). |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Revise recipe: fix domain URI, add "Not applicable" sections per cookbook guidelines, restructure Platform Notes as translation guidance, update status to review. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents SectionLabel + sectionLabelClass and its boundary vs caption/title. |
