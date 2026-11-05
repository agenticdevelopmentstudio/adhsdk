---
id: 37b7b456-790f-4b2d-8f3a-a364016ce389
title: StatList
domain: adhsdk://recipes/stat-list
type: recipe
version: 1.3.1
status: review
language: en
created: '2026-07-03'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A stack of tone-dotted status rows — StatusDot + truncating label + trailing figure — the fleet/telemetry idiom (down sites, top error issues)."
platforms:
- typescript
- web
tags:
- block
- stat
- status
- list
- ui
ingredients:
- adhsdk://recipes/status-dot
depends-on: []
related:
- adhsdk://recipes/stat-card
references: []
approved-by: ''
approved-date: ''
---

# StatList

## Overview

`StatList` and `StatListRow` in `@adh-sdk/ui` are the shared **status list** — a
vertical stack of "tone dot + truncating label + trailing figure" rows. It is the
fleet/telemetry idiom: a monitor's *down sites* (name · duration), a card's *top
error issues* (title · count · deep link). Each row is a `StatusDot` (size 7) at the
family tone, a `min-w-0 flex-1 truncate` label, and a right-aligned `shrink-0`
trailing slot the caller fills (a bold duration, a count plus an `ExternalLink`).

It was extracted because that exact row + list grammar was hand-rolled
character-identically in the fleet status site (`MonitorCard`), the status backend's
telemetry cards (`TelemetrySections`), and the ui-showcase — the "same markup twice →
extract it" rule. `StatList` owns the list wrapper (an optional top divider + the
row gap); `StatListRow` owns one row. Both are **pure assembly** — the only visual
primitive is the shared `StatusDot`; everything else is layout + the caller's text.

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| StatusDot | adhsdk://recipes/status-dot | The leading tone dot on each row (size 7), decorative (no aria label — the row's text carries the meaning) | yes | `tone` per row from `StatListRow.tone`; fixed `size={7}` |

In this toolkit, leaf UI components are themselves recipes rather than a
separate `ingredient` type, so `StatusDot` is cited here by its recipe domain.

`StatListRow`'s label and trailing content are caller-supplied `ReactNode`s, not
components this block owns; `StatList` is a bare wrapper element.

## Integration Requirements

- **render-a-dot-per-row**: `StatListRow` MUST render a decorative `StatusDot` (size 7, no accessible label) at its `tone` as the row's leading glyph.
- **truncate-the-label**: `StatListRow` MUST render `label` so it clips with an ellipsis when it overflows the row's available width, flexing to claim the remaining space, and MUST set its native `title` to `labelTitle` when provided, so a clipped label is still readable on hover.
- **right-align-trailing**: When `trailing` is not `null`/`undefined` — a falsy-but-present value such as `0` still counts as provided — `StatListRow` MUST render it right-aligned and non-shrinking after the label; when `trailing` is `null` or `undefined`, it MUST render no trailing slot.
- **honor-row-element**: `StatListRow` MUST render as a `li` when `as="li"` and a `div` otherwise, so a semantic list uses `ul`/`li`.
- **stack-rows**: `StatList` MUST arrange its children in a single vertical column with consistent spacing between rows and no list-marker bullets.
- **divide-when-asked**: `StatList` MUST add a top divider (border + padding) when `divided` is set (the list sits under card content) and MUST omit it otherwise.
- **honor-list-element**: `StatList` MUST render as a `ul` when `as="ul"` and a `div` otherwise.
- **spread-host-attributes**: Both MUST spread remaining host attributes (`data-*`, `id`, handlers) onto their root element so hosts can tag them (e.g. the fleet `data-testid="down-list"`).
- **as-consistency**: Neither component checks the other's `as`, so a caller SHOULD use `as="li"` rows only inside an `as="ul"` StatList (and `as="div"` rows only inside an `as="div"` StatList) to keep list semantics valid; see also **honor-row-element** and **honor-list-element**.

## Layout

```
StatList  (as="ul" divided)
--- divider (border-t) --------------------------------------
 (dot) app · production        (truncates…)             1h
 (dot) worker queue            (truncates…)            12m
        ^ StatusDot   ^ min-w-0 flex-1 truncate label   ^ trailing (shrink-0)
```

- Row: `flex items-center gap-2 font-mono text-[11px]` — dot, then the truncating
  label, then the trailing group.
- Trailing group: `inline-flex shrink-0 items-center gap-2` so multiple trailing
  bits (a count + a deep link) space consistently.
- List: `flex list-none flex-col gap-1.5`, plus `border-t border-apt-border pt-2.5`
  when `divided`.
- No raw hex, no `!important` — color via `apt-*` tokens and the composed StatusDot.

## Shared State

Both components are pure and stateless — every prop flows down into layout or the
composed `StatusDot`; nothing flows back up.

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `tone` | Caller | StatusDot | Down | Prop pass-through |
| `label` / `labelTitle` | Caller | Truncating label element | Down | Prop |
| `trailing` | Caller | Trailing slot | Down | Prop (rendered when non-null) |
| `as` / `divided` | Caller | Root element + wrapper classes | Down | Prop |
| host attributes (`data-*`, `id`) | Caller | Root element | Down | Rest-prop spread |

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-a-dot-per-row, truncate-the-label, right-align-trailing | `<StatListRow tone="error" label="app" labelTitle="app" trailing={<span>1h</span>} />` | a decorative dot, a label that clips with an ellipsis and carries `title="app"`, and "1h" rendered right-aligned and non-shrinking after the label |
| T2 | truncate-the-label | label longer than its box | the label clips with an ellipsis instead of wrapping or overflowing |
| T3 | right-align-trailing | `StatListRow` with no `trailing` | no trailing slot element rendered |
| T4 | right-align-trailing | `<StatListRow trailing={0} />` | the trailing slot renders (containing `0`) — a falsy-but-non-null value is not treated as absent |
| T5 | honor-row-element | `as="li"` | the row is an `li` |
| T6 | honor-row-element | `StatListRow` with no `as` | the row is a `div` |
| T7 | stack-rows, divide-when-asked, honor-list-element | `<StatList as="ul" divided>` | a `ul` arranged as a single vertical column with row spacing, no list-marker bullets, and a top divider (border + padding) |
| T8 | divide-when-asked | `<StatList>` (no `divided`) | no top divider rendered |
| T9 | honor-list-element | `StatList` with no `as` | the list is a `div` |
| T10 | spread-host-attributes | `<StatList data-testid="down-list">` | the root carries `data-testid="down-list"` |
| T11 | spread-host-attributes | `<StatListRow data-testid="row-1">` | the root carries `data-testid="row-1"` |
| T12 | as-consistency | `<StatListRow as="li" />` rendered outside any `StatList` | still renders as an `li` — the component does not check its parent, so the caller alone keeps the `as="li"`/`as="ul"` pairing valid |

## Edge Cases

- **No `trailing`**: the row is dot + label only (a bare status line); the trailing
  slot is omitted entirely.
- **Decorative dots**: the dot never carries an aria label — the row's own text
  (label + trailing) is the accessible content, so a screen reader reads the item
  once, not "status" twice, the same pattern StatusDot's own
  `adhsdk://recipes/status-dot#requirements/unlabeled-is-decorative`
  requirement documents for an unlabeled dot.
- **`labelTitle` vs `label`**: pass the plain-text form as `labelTitle` so the native
  tooltip works even when `label` is rich `ReactNode`.
- **Multiple trailing bits**: wrap them in the `trailing` prop (a fragment); the
  block's trailing wrapper spaces them with a consistent gap (e.g. `24×` + a deep link).
- **`as` mismatch**: see **as-consistency** — neither component enforces the pairing,
  so a caller-side mistake renders without error but breaks list semantics.

## Platform Notes

- **SwiftUI**: This is a web/React component; on Apple platforms, build an equivalent using a vertical `VStack` of rows, each an `HStack` containing a decorative status indicator (via `Circle` or a custom view), a text label with `.lineLimit(1)` and `.truncationMode(.tail)`, and a trailing value view pinned after a `Spacer()` with `.layoutPriority(1)` so it stays fully visible while the label clips.
- **Compose**: This is a web/React component; on Android, compose rows using a `Column` with `verticalArrangement = Arrangement.spacedBy()`, each row a `Row` containing a leading status dot, a `Text` with `maxLines = 1`, `overflow = TextOverflow.Ellipsis`, and `Modifier.weight(1f)` so it claims the remaining width and clips before a trailing value composable placed after it.
- **React/Web (TypeScript)**: `packages/web/packages/ui/src/blocks/stat-list.tsx`, exported from `@adh-sdk/ui` (`@adh-sdk/ui/blocks/stat-list`). Composes `StatusDot` (`../components/status-dot`). Exports `StatList`, `StatListRow`, `StatListProps`, `StatListRowProps`. Demo in `ui-showcase` Topic `stat-list` (group "Blocks — cards & sections"); regenerate `sources.generated.ts` via `gen-sources.py` after source changes. Rows truncate their label to fit any width; verify at 375 / 768 / 1440 that the trailing figure stays visible while the label clips.
- **AppKit / UIKit**: This is a web/React component; on macOS and iOS, build an equivalent using `NSStackView` (AppKit) or `UIStackView` (UIKit) with vertical axis, each row a horizontal stack containing a decorative status badge, a truncating label with `lineBreakMode = .byTruncatingTail`, and a trailing value.
- **WinUI 3**: Build the list using a vertical `StackPanel` (Orientation="Vertical", with `Spacing` for row gaps) or an `ItemsRepeater` bound to the rows. Each row is a `Grid` with column definitions `Auto`, `*`, `Auto` (dot / label / trailing) — a horizontal `StackPanel` gives its children unlimited width, so a `TextTrimming` value never fires and `HorizontalAlignment="Right"` has no effect inside it. Put the status indicator (`Ellipse` or custom control) in the first column; a `TextBlock` with `TextWrapping="NoWrap"` and `TextTrimming="CharacterEllipsis"` in the `*` column so it clips within its constrained width; and the trailing content in the third column, inside a `StackPanel` with Orientation="Horizontal" and HorizontalAlignment="Right".

## Design Decisions

- **Decision**: split into `StatList` (wrapper) + `StatListRow` (row) rather than one
  data-driven component.
  **Rationale**: the two real call sites differ only in the
  trailing content (a bold duration vs a count + deep link); a `trailing` slot keeps
  the row declarative for the common part while letting each site own its tail without
  a config explosion.
  **Approved**: pending
- **Decision**: the dot is always decorative (no aria label).
  **Rationale**: the row's
  visible label + trailing already convey the item; labeling the dot too would make a
  screen reader announce the status twice — the same a11y trap StatusDot's own
  `adhsdk://recipes/status-dot#requirements/unlabeled-is-decorative`
  requirement addresses.
  **Approved**: pending
- **Decision**: `divided` is a boolean, not a caller-supplied className.
  **Rationale**:
  both sites use the identical top-border-and-padding treatment when the
  list sits under card content; a named flag keeps that one decision in the block.
  **Approved**: pending
- **Decision**: `as` picks the element (`ul`/`li` vs `div`).
  **Rationale**: a monitor's
  down sites ARE a semantic list, while a card's freeform tail may not be; the block
  supports both without forcing list semantics where they don't fit.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | partial | Platform Compliance |
| [rf-compliance](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-compliance) | passed | Artifact Formatting |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The dot carries no `aria-label` while the label + trailing text convey the row's
meaning (screen-reader-support); `StatListRow`/`StatList` render a semantic `li`/`ul`
when `as` requests one (semantic-markup); styling is expressed entirely through
`apt-*` token classes with no raw hex or `!important`, though the dark-mode/
high-contrast wiring those tokens resolve to lives in the themes package rather
than in this source, hence `partial` (platform-theming); and this section now
matches the Check/Status/Category table format with linked, catalog check ids
(rf-compliance); `StatListRow`/`StatList` are pure presentation assembled from
`StatusDot` and caller content with no business logic (separation-of-concerns
passed), and `statList.test.tsx` directly renders both and asserts on their DOM
output (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case and add as-consistency; state truncation/stacking/divider behavior instead of literal Tailwind classes; add test vectors for default `div` roots, `StatListRow` attribute spreading, `trailing={0}`, and the `as` mismatch case; rework WinUI 3 Platform Notes onto a `Grid` layout and drop "Not applicable" from SwiftUI/Compose/AppKit-UIKit, adding trailing-visibility guidance to SwiftUI/Compose; link Compliance checks to the catalog with `passed`/`partial` status and reformat Design Decisions with `Approved` lines; trim the frontmatter summary; note that leaf components are recipes in this toolkit; record the domain scheme's move to `adhsdk` (commit c1d412c), which this version's frontmatter already carries. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Revise WinUI 3 Platform Notes with concrete control guidance; remove "Not applicable" phrasing. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Reorganize Platform Notes per cookbook standards; fix domain URI scheme from agenticdeveloperhub to agenticdevelopercookbook; update status to review. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; the StatusDot + truncating label + trailing figure row/list grammar extracted from the fleet and telemetry status lists. |
