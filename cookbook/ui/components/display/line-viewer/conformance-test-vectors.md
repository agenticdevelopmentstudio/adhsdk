
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| line-viewer-001 | geometry | 100 rows | document height `100 × rowHeight`. |
| line-viewer-002 | folding | rows: header, 3 text, header, 2 text; `foldsAtHeaders`; click row 0 | 4 rows displayed, height `4 × rowHeight`; display row 1 is data row 4; click again restores 7. |
| line-viewer-003 | copy, selection | rows `a`, `b`, `c`; rows 0 and 2 selected | pasteboard string `a\nc`. |
| line-viewer-004 | virtualised-drawing | 100 000-row source; draw a 10-row rect | 10 to 20 calls to `row(at:)`. |
| line-viewer-005 | scroll-sync | two 1 000-row viewers in a sync; scroll one to row 500 | both clip views have the same vertical origin, `500 × rowHeight`. |
| line-viewer-006 | long-row-layout | one 1 000 000-unit row ending in `é`; draw a 400 pt by one-row rect at x 0, then at 600 000 advances along; then `reloadData()` | fewer than 1 000 glyphs drawn each time; one cached layout, none after the reload. |
| line-viewer-007 | gutter-columns | widths 8 and 4; column 0 value 26 characters | column 0 is 10 advances wide, column 1 starts at its end and is 6 wide; column 1 stays one uniform colour. |
| line-viewer-008 | pinned-gutter, gutter-click | document 5 000 pt wide; scroll the clip view to x 300; click one advance right of 300 | the gutter's x is 300; a column-0 gutter click, no selection. |
| line-viewer-009 | long-row-layout | one row of `ab⇥c中d😀ef` × 300 with an underlined run; draw x 0–900 whole, then as rects 0–333, 333–617, 617–900 each clipped to itself | identical pixels. |
| line-viewer-010 | long-row-layout | one ASCII code row × 50 with bold, italic-underlined, highlighted and struck runs; draw whole, then as three adjacent rects | identical pixels; no layout built. |
| line-viewer-011 | long-row-layout | 30 visible long ASCII rows (about 5 000 units); draw the frame twice | no layout built either time; nothing cached. |
| line-viewer-012 | long-row-layout | 30 visible long rows with tabs, wide characters and emoji; draw the frame twice | 30 layouts built by the first draw, none by the second; 30 cached. |
| line-viewer-013 | long-row-layout | 60 such rows in one dirty rect of a viewer whose capacity is about 34; draw twice | 60 layouts built and cached by the first draw, none built by the second. |

