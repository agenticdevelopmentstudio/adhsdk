
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
- Gutter: one column per `gutterColumnCount`, each `gutterColumnWidth(c) + 2` advances of `0` wide (default content width `max(3, digits(rowCount))`), values right-aligned in `.secondaryText` and clipped to their column, a 1 pt `.divider` line after the last column. The gutter is pinned to the visible left edge and carries each row's background and selection. Text starts one advance after the gutter.
- With `foldsAtHeaders`, a header row draws a down chevron (expanded) or right chevron (folded) in `.secondaryText` before its text.

