
- Browse mode: the list is `role="tree"` (`aria-label="Categories"`); each row is
  `role="treeitem"` with `aria-selected`, `aria-expanded` (parents only) and
  `aria-disabled` on a forbidden row. Exactly one row carries `tabIndex={0}` (the
  roving tab stop); every other row is `tabIndex={-1}`, so Tab moves past the
  whole tree in one stop and arrow keys move within it (WAI-ARIA tree pattern).
- Filter mode: the list is `role="listbox"` (`aria-label="Categories"`); each row
  is `role="option"` with `aria-selected` / `aria-disabled`.
- The filter field is `role="searchbox"` with `aria-label="Filter categories"`
  and `autoFocus` on open.
- The dialog itself carries the shared `Dialog`'s focus trap, portal and
  Escape-to-close; closing (when not `busy`) returns focus per that primitive.
- Every expand/collapse chevron button carries a `title="Expand/Collapse <name>"`
  tooltip and is `aria-hidden`, so it is excluded from both the tab order
  (`tabIndex={-1}`) and the accessibility tree entirely — it is a pointer
  affordance; the same action is reachable from the row via ArrowRight/Left.

