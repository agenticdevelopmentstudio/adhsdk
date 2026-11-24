---
id: 595f1a5e-0f92-49c5-a980-af6f809be932
title: "Commit Graph Cell"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Draws one row of the commit graph layout: top and bottom segments and the commit's node (ring for a merge), in theme ANSI lane colours, 14 pt per column."
platforms:
  - macos
tags:
  - component
  - display
  - ui
  - git
  - graph
depends-on:
  - 750fe184-d20a-4b58-867b-3edd094d59b4
  - 0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/UI/Graph/ (adhsdk)
approved-by: ""
approved-date: ""
---

# Commit Graph Cell

## Overview

The commit list's graph column for one row: it draws one `Row` of the [commit graph layout](cookbook:750fe184-d20a-4b58-867b-3edd094d59b4) — the lines entering the row from its top edge, the lines leaving it from the commit's centre to its bottom edge, and the commit's node — in lane colours taken from the [theme engine](cookbook:0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6)'s ANSI palette. It lays nothing out itself and knows nothing about git; a table cell hosts one per row and hands it the row the layout returned.

## Behavioral Requirements

- **row-input**: The cell MUST draw exactly the `row` it is given (`CommitGraphLayout<String>.Row?`) and nothing when it is `nil`. Setting a different row MUST invalidate its intrinsic size and redraw it.
- **width**: `intrinsicContentSize.width` MUST be `row.width × columnWidth` (`columnWidth` = 14 pt), 0 for no row; the height MUST be `NSView.noIntrinsicMetric`, so the row height comes from the table.
- **geometry**: Column `c`'s centre MUST be at `x = (c + 0.5) × columnWidth`; the commit's centre at `y = bounds.midY`. Each `top` segment MUST run from `(x(from), top edge)` to `(x(to), midY)`; each `bottom` segment from `(x(from), midY)` to `(x(to), bottom edge)`.
- **lane-colour**: Each segment and the node MUST be stroked or filled with `SemanticPalette.laneColor(lane)`, which cycles the theme's ANSI slots `1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14` by `lane mod 12`, falling back to the `accent` role for a slot the theme lacks.
- **node**: A commit with one parent or none MUST draw a filled circle; a merge (two or more `bottom` segments leaving the commit's column) MUST draw a ring, its centre left unpainted.
- **theme**: The cell MUST repaint on every theme change, through `ThemePaletteObserver` (`observeTheme`).

## Appearance

```
 |  |        top segments: edge -> centre, 2 pt lines
 o  |        node: filled circle, radius 4 pt
 |\ |        bottom segments: centre -> edge
 ( ) |       merge node: 2 pt ring, radius 4 pt, hollow
```

- Column width 14 pt; lines 2 pt wide with round caps; node radius 4 pt.
- Lane colours: the ANSI slots `1…6` then `9…14` (the six normal and six bright hues; black, white and their bright forms are skipped because they vanish on dark or light backgrounds).
- The cell paints no background: the table row underneath shows through, selection included.

## States

- **Empty**: no row; nothing is drawn and the width is 0.
- **Commit**: one row drawn, filled node.
- **Merge**: one row drawn, ring node.

## Accessibility

- The cell carries the accessibility identifier `commitGraph.cell`, which a host may replace.
- The graph is decoration beside the commit's text: colour is never the only signal, because the row's subject, author and hash carry the information.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| commit-graph-cell-001 | width | row with `width` 3 | `intrinsicContentSize.width` 42; no row: 0. |
| commit-graph-cell-002 | lane-colour | lanes 0, 5, 6, 11, 12 | ANSI slots 1, 6, 9, 14, 1. |
| commit-graph-cell-003 | lane-colour | a theme with no ANSI slots | every lane is the `accent` colour. |
| commit-graph-cell-004 | node | one-parent row vs two-parent row at column 0, drawn 14 × 20 | the centre pixel is painted for the commit and transparent for the merge. |

## Edge Cases

- **Null / empty input**: A `nil` row draws nothing and has zero width.
- **Boundary values**: Lanes only grow, so `lane mod 12` keeps any lane in the palette; a negative lane is reduced into range too.
- **Concurrent access**: Main actor only.
- **Error states**: None: the cell draws whatever row it is given.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: Not applicable: drawing is synchronous.

## Configuration

`row` (`CommitGraphLayout<String>.Row?`), `CommitGraphCellView.columnWidth` (14 pt, constant).

## Deep Linking

Not applicable: The cell defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The cell draws no text.

## Accessibility Options

Not applicable: The cell draws no text; its colours follow the theme, including high-contrast themes.

## Feature Flags

Not applicable: The cell contains no feature-flag reference.

## Analytics

Not applicable: The cell contains no analytics call.

## Privacy

Not applicable: The cell draws a layout row and sends nothing anywhere.

## Logging

Not applicable: The cell logs nothing.

## Platform Notes

- **SwiftUI**: A `Canvas` drawing the same segments, sized by `row.width × columnWidth`.
- **Compose**: A `Canvas` composable with the same geometry.
- **React/Web**: An inline SVG per row, or one canvas for the visible rows.
- **AppKit / UIKit**: AppKit: an `NSView` drawing with `NSBezierPath` in `draw(_:)`. UIKit: a `UIView` with the same drawing.
- **WinUI 3**: A `Canvas` of `Line` and `Ellipse` shapes, or Win2D for long lists.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/Graph/CommitGraphCellView.swift` | confirmed (1.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Theme/SemanticPalette+Lanes.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Lane colours are ANSI slots 1–6 and 9–14 of the theme rather than a palette of their own.
**Rationale**: The ANSI 16 is the vocabulary terminal-derived themes are authored in, so every theme already has twelve distinct, background-contrasting hues; a separate graph palette would be a second colour source to keep in step.
**Approved**: pending

**Decision**: A merge is recognised from the row itself (two or more bottom segments leaving the commit's column) rather than from a flag the layout adds.
**Rationale**: Every bottom segment from the commit's column is one parent edge, pass-through segments never start there, so the row already says it; the layout's `Row` stays unchanged.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |

`separation-of-concerns` passes because the cell draws a row it does not compute: lane assignment is the layout's.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
