
- The pager is a `<nav aria-label="Pagination">` landmark, so assistive tech can jump
  straight to it and tell it apart from other `nav`s on the page.
- `Prev` and `Next` are real buttons with visible text labels (no icon-only
  ambiguity), disabled through the native `disabled` attribute at the bounds — so AT
  announces them as unavailable and skips them in the focus order.
- The `Page X of Y` caption is visible, textual position that anyone can read; it is
  plain text with no `aria-live` attribute, so a page change is **not** announced to a
  screen reader automatically — an assistive-technology user must return focus to the
  caption (or navigate through it) to learn the new page number.

