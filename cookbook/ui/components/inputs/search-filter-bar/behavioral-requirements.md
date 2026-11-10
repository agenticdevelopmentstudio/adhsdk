
- **search-region-wrapper**: The SearchFilterBar MUST render its controls
  inside a single element with `role="search"`.
- **search-field-control**: The SearchFilterBar MUST render the search field
  as a controlled `type="search"` input bound to `search.value`, calling
  `search.onChange` with the new string on every keystroke.
- **search-field-label**: The SearchFilterBar MUST expose `search.label` as
  the search field's accessible name (the field is icon-only, with no visible
  label).
- **one-select-per-filter**: The SearchFilterBar MUST render exactly
  one `Select` per entry in `filters`, each labelled by its `label`, in the given
  order, with a leading all-pass option whose value is the empty string and whose
  text is `allLabel`.
- **filter-options-list**: The SearchFilterBar MUST render each filter's
  `options` (in order) as `<option>`s after the all-pass entry. A bare string
  option MUST be used as both the value and the visible text; a
  `{ value, label }` option MUST store `value` and read as `label`. The two forms
  MUST be mixable on one axis.
- **filter-value-sync**: The SearchFilterBar MUST set each
  select's current value from the filter's `value` and call that filter's
  `onChange` with the newly selected value (the empty string when the all-pass
  entry is chosen).
- **filter-row-children**: The SearchFilterBar MUST render
  `children` in the filter row, after any `filters`, so a caller-supplied control
  is one more axis on the same row rather than a second bar.
- **filter-row-omitted-when-empty**: The SearchFilterBar MUST NOT render the filter
  row when it would be empty — no `filters` and no `children` that React would
  actually render (a `false`/`null` child does not open the row).
- **orientation-layout**: The SearchFilterBar MUST stack the filter row
  under the search field by default (`orientation="stacked"`), and MUST lay the
  field and the row out as one wrapping line when `orientation="inline"`, the
  search field taking the free space with a minimum width of its own.
- **autofill-form-scope**: The SearchFilterBar MAY root itself on a
  `<form>` instead of a `<div>` when `asForm` is set, carrying `role="search"`
  onto that element and cancelling its `submit`. It MUST default to the `<div>`.

