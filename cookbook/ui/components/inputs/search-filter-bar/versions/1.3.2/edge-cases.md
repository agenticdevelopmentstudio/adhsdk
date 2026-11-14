
- **Empty option list**: a filter with `options: []` still renders its all-pass
  option, so the select is never empty.
- **Stale selected value**: if a filter's `value` is not present in `options`, the
  underlying React-controlled `<select>` cannot render a selection that isn't one
  of its options — it displays the first option (the all-pass entry) instead,
  while `value` (and the caller's state) still holds the stale, unmatched string.
  This is misleading: the control *looks* reset to "all", but the caller's filter
  is still narrowed by the old value. The caller owns keeping `value` within the
  option universe (e.g. the research pane sources options from the *unfiltered*
  document universe for this reason). See **T12**.
- **Search-only bar**: omit `filters` (or pass `[]`) for a bare search field.
- **Duplicate option strings**: the React key for each `<option>` is `value` (not
  `label`), so the caller must pre-dedupe by value before passing `options` —
  two options that share a value collide on that key, even if their labels
  differ.

