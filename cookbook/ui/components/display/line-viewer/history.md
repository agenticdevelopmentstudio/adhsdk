
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.0 | 2026-11-13 | Mike Fullerton | Long ASCII rows in a column-true font are sliced by column with no layout; other long rows use a cache sized to twice the visible rows that never evicts a row of the current frame; a row's content MUST NOT change between reloadData() calls. |
| 1.1.0 | 2026-11-13 | Mike Fullerton | Long rows draw from a cached per-row layout, only the glyphs under the dirty rect, so split and whole drawing agree; the gutter view carries `<identifier>.gutter`. |
| 1.0.1 | 2026-11-13 | Mike Fullerton | Long rows lay out only the visible slice; gutter column widths come from the data source and values are clipped; the gutter is pinned to the visible left edge. |
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
