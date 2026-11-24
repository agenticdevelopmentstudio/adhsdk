
**Decision**: Orphans are surfaced as roots rather than dropped.
**Rationale**: This prioritizes visibility over strict hierarchy correctness — a user's view will not silently lose rows due to missing parents. The tradeoff is that inconsistent parentId mappings become visible in the UI.
**Approved**: pending

**Decision**: Cycles are detected only after a full depth-first descent, and unreached rows are surfaced at depth 0 in input order.
**Rationale**: This ensures no row is lost and all rows are visited exactly once. The cost is O(n) space for the `reached` set and a final O(n) scan.
**Approved**: pending

**Decision**: Leaves render a spacer element (not a disabled toggle) to preserve layout alignment across parent and leaf rows.
**Rationale**: A disabled button would imply interactivity (and accessibility) that does not exist; a spacer is semantic and silent.
**Approved**: pending

**Decision**: The toggle uses a ChevronRight glyph (rotated 90° when expanded) instead of a separate DownChevron glyph.
**Rationale**: This is consistent with the Disclosure component in the same design system (see `related`) and reduces icon count.
**Approved**: pending

**Decision**: Indent is set to `1.25em` per nesting level.
**Rationale**: Visually distinct at moderate nesting depth (up to 5–6 levels) without consuming excessive horizontal space — at 5 levels, `6.25em` of inline-start padding is typical for desktop layouts.
**Approved**: pending

**Decision**: The toggle button has no visible background or border by default, appearing as a muted-foreground chevron; hover and focus states are subtle (foreground color change and focus ring).
**Rationale**: This keeps the row visually clean and focuses attention on the content, not the toggle itself.
**Approved**: pending

**Decision**: Ports and callers building a standalone tree browser — one that owns its own selection, keyboard navigation, and virtualization — should reach for the platform's native tree control instead of this recipe: SwiftUI `OutlineGroup`/`DisclosureGroup`, AppKit `NSOutlineView`, WinUI 3 `TreeView`/`TreeViewItem`, or web `role="treegrid"`/`aria-level`. `flattenTree` and `TreeRowLabel` exist for the opposite case: hierarchy layered onto an *existing* flat table, list, or card grid whose column logic, sorting, resizing, selection, and keyboard behavior must keep working unchanged (see Overview).
**Rationale**: A native tree control owns its own row rendering and interaction model; grafting it onto an existing table would mean re-deriving that table's behavior inside the tree control instead of reusing it.
**Approved**: pending

**Decision**: `TreeRowLabel` and `flattenTree` do not set `role="treegrid"`, `aria-level`, `aria-posinset`, or `aria-setsize`.
**Rationale**: The component intentionally does not become a `<TreeTable>` (see Overview) — the caller's own table/list row owns the outer semantic element, so tree-level ARIA attributes belong there, not in this inner label.
**Approved**: pending

