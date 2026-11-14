---
id: 5f9e0c63-382d-4803-bd50-a8fb90ea9e4d
title: "Line Viewer"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A read-only, virtualised Core Text line view: styled runs, row backgrounds, gutter columns, header folding, selection and copy, with vertical scroll sync for side-by-side use."
platforms:
  - macos
tags:
  - component
  - display
  - ui
  - virtualised
  - diff
depends-on:
  - 0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6
related:
  - 6708bfd4-5b29-4bf9-b180-05904873906e
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/UI/LineViewer/ (adhsdk)
approved-by: ""
approved-date: ""
---

# Line Viewer

## Overview

A read-only, virtualised view of many lines of text: each row is a text line or a header, with styled runs (colours from the [syntax highlighter](cookbook:6708bfd4-5b29-4bf9-b180-05904873906e) or anywhere else), a background role, and N gutter columns. It draws with Core Text, never TextKit, and asks its data source only for the rows it is drawing, so a 100 000-line file costs no more to show than a 100-line one. Diff and blame are configurations of it: inline diff is one viewer, side-by-side is two viewers whose vertical scroll is locked by `LineViewerScrollSync`. It knows nothing about git. Colours and the monospaced font come from the [theme engine](cookbook:0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6).

## Behavioral Requirements

- **data-source**: The viewer MUST read rows only through `LineViewerDataSource` (`gutterColumnCount`, `rowCount`, `row(at:)`); it MUST NOT copy the rows. `reloadData()` MUST re-read the counts, clear folds and selection, and resize the document view.
- **geometry**: The document view MUST be flipped and exactly `displayedRowCount × rowHeight` tall, where `rowHeight` is `ceil(ascent + descent + leading) + 4` of the theme's code font and `displayedRowCount` is `rowCount` less the rows hidden by folds. Its width MUST be the larger of the clip view's width and the widest row drawn so far.
- **virtualised-drawing**: Drawing MUST ask the data source only for the rows intersecting the dirty rect; drawing a 10-row rect of a 100 000-row source MUST call `row(at:)` at most 20 times.
- **folding**: With `foldsAtHeaders`, clicking a header row MUST hide the rows after it up to (not including) the next header or the end, and clicking it again MUST show them. Folding MUST remove hidden rows from the selection. A header click MUST NOT change the selection. Without `foldsAtHeaders` a header row selects like any row.
- **selection**: A click MUST select the clicked row; shift-click MUST extend from the anchor row; command-click MUST toggle the row; dragging MUST extend from the anchor. Every change MUST call `lineViewer(_:didSelectRows:)` with data-source row indices. `selectedRows` is in data-source indices.
- **gutter-click**: A click inside gutter column `c` of row `r` MUST call `lineViewer(_:didClickGutterColumn: c, row: r)` and MUST NOT change the selection.
- **copy**: Copy (Cmd-C, `copy(_:)`) MUST put the selected rows' `text`, in row order, joined by `\n` with no trailing newline, on the general pasteboard as a plain string; with nothing selected the menu item MUST be disabled and the pasteboard left alone.
- **scroll-to-row**: `scrollToRow(_:)` MUST unfold the fold hiding the row, if any, then scroll vertically so the row is at the top, clamped to the scrollable range, keeping the horizontal offset.
- **scroll-sync**: `LineViewerScrollSync` MUST keep the vertical scroll offset of every viewer it holds equal to the last one scrolled, leaving each viewer's horizontal offset alone, without re-entering itself. It holds the viewers weakly; rows are assumed aligned.
- **theme**: The viewer MUST repaint and re-measure (font, row height, gutter width) on every theme change, through `ThemePaletteObserver`.

## Appearance

```
| 12 | 12 | let x = 1                    |   none
| 13 |    | let y = 2                    |   removed: .danger @ 0.18
|    | 13 | let y = 3                    |   added:   .success @ 0.18, a run with highlight emphasis @ 0.40
|////|////|//////////////////////////////|   filler:  .surface hatched
| v @@ -20,4 +20,5 @@                  |   header:  .surface
```

- Font: the theme's `code` text role (`SemanticPalette.font(.code)`, from `ThemeTypography`), monospaced.
- Row backgrounds span the whole row, gutter included: `none` draws nothing over `windowBackground`; `added` and `removed` are `.success` and `.danger` at 0.18 alpha; `emphasis` is 0.40 alpha of the row's tone (`.success` on an added row, `.danger` on a removed row, `.accent` otherwise); `header` is `.surface`; `filler` is `.surface` diagonal hatching (1 pt lines, 6 pt apart, 45 degrees).
- A run's `highlight` paints that role behind the run's glyphs, full row height, with the same colours (an `emphasis` run on an added row is `.success` at 0.40).
- Selected rows are overlaid with `.selection`.
- Text: each run's `foreground`, or `.primaryText` where no run says; `fontStyle` maps bold and italic to font traits, underline and strikethrough to single lines.
- Gutter: one column per `gutterColumnCount`, each `(max(3, digits(rowCount)) + 2)` advances of `0` wide, values right-aligned in `.secondaryText`, a 1 pt `.divider` line after the last column. Text starts one advance after the gutter.
- With `foldsAtHeaders`, a header row draws a down chevron (expanded) or right chevron (folded) in `.secondaryText` before its text.

## States

- **Empty**: no data source or `rowCount` 0; the document view is zero rows tall and nothing is drawn (no placeholder text).
- **Loaded**: rows drawn on demand.
- **Folded**: one or more header sections hidden; the document view is shorter by their rows.
- **Selecting**: one or more rows selected; Copy enabled.

## Accessibility

- The scroll view carries the viewer's accessibility identifier (`init(identifier:)`); the document view carries `<identifier>.text`.
- The document view is an accessibility element with role `textArea`, read-only, whose `accessibilityValue` is the text of the rows currently visible, joined by `\n`.
- Colour is never the only signal: diff rows also carry their gutter values, and folded headers draw a chevron.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| line-viewer-001 | geometry | 100 rows | document height `100 × rowHeight`. |
| line-viewer-002 | folding | rows: header, 3 text, header, 2 text; `foldsAtHeaders`; click row 0 | 4 rows displayed, height `4 × rowHeight`; display row 1 is data row 4; click again restores 7. |
| line-viewer-003 | copy, selection | rows `a`, `b`, `c`; rows 0 and 2 selected | pasteboard string `a\nc`. |
| line-viewer-004 | virtualised-drawing | 100 000-row source; draw a 10-row rect | 10 to 20 calls to `row(at:)`. |
| line-viewer-005 | scroll-sync | two 1 000-row viewers in a sync; scroll one to row 500 | both clip views have the same vertical origin, `500 × rowHeight`. |

## Edge Cases

- **Null / empty input**: No data source or no rows draws only the background; copy is disabled.
- **Boundary values**: A run range past the end of its row is clipped to the row; a run of zero length draws nothing. A click below the last row selects nothing.
- **Concurrent access**: Main actor only; the data source is asked on the main thread during drawing.
- **Error states**: None: the viewer draws whatever rows it is given.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: Not applicable: drawing is synchronous and bounded by the visible rows.

## Configuration

`init(identifier:)` (accessibility identifier), `dataSource`, `delegate`, `foldsAtHeaders` (default `false`).

## Deep Linking

Not applicable: The viewer defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The viewer contains no user-facing string; every string it draws comes from its data source.

## Accessibility Options

The font follows the theme's `code` role and the reader's text size scale, so Text Size changes re-measure the rows.

## Feature Flags

Not applicable: The viewer contains no feature-flag reference.

## Analytics

Not applicable: The viewer contains no analytics call.

## Privacy

Not applicable: The viewer draws what it is given and sends nothing anywhere.

## Logging

Not applicable: The viewer logs nothing.

## Platform Notes

- **SwiftUI**: Host the AppKit controller in an `NSViewControllerRepresentable`; a `LazyVStack` of `Text` rows would not reach 100 000 rows smoothly.
- **Compose**: A `LazyColumn` over the same row model gives the same virtualisation.
- **React/Web**: A windowed list (fixed row height) over the same row model.
- **AppKit / UIKit**: AppKit: an `NSScrollView` over a flipped document view drawing with Core Text. UIKit: a `UIScrollView` with the same drawing.
- **WinUI 3**: An `ItemsRepeater` with a fixed-height virtualising layout.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/LineViewer/` | confirmed (1.0.0) |

## Design Decisions

**Decision**: One fixed row height and Core Text drawing of only the dirty rows, rather than an `NSTableView` or a TextKit text view.
**Rationale**: Row geometry is then arithmetic, so hit testing, folding and scroll sync need no layout pass, and the cost of a frame is bounded by the visible rows however long the file is.
**Approved**: pending

**Decision**: The document width grows to the widest row drawn so far instead of measuring every row up front.
**Rationale**: Measuring every row would ask the data source for all of them, which is exactly what virtualisation avoids; growing on demand keeps horizontal scrolling correct for everything the reader has seen.
**Approved**: pending

**Decision**: Folds are held as data-source ranges and cleared by `reloadData()`.
**Rationale**: After a reload the rows may have moved, so an old fold range could hide the wrong lines; the views that reload know what changed and can fold again.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |

`separation-of-concerns` passes because the viewer draws a row model it does not build: diff and blame models live with their features. `no-hardcoded-strings` passes because every drawn string comes from the data source.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
