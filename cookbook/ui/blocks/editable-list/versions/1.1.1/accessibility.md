
- **Role**: `role="grid"` (with `row`/`gridcell`/`columnheader`/`aria-sort` on its children) for a selectable table, or plain `role="table"` (with `row`/`cell`/`columnheader`) for a non-selectable one — see **grid-role-and-focus**. The bar is `role="toolbar"`. The details-pane divider is `role="separator"` with `aria-orientation="horizontal"` and `aria-valuenow`/`aria-valuemin`/`aria-valuemax`.
- **Search input label**: `aria-label="Filter [ariaLabel]"`, with `ariaLabel` lowercased (e.g., "Filter users") — see the Localization note on the locale-sensitivity of that transform.
- **Text filter input labels**: `aria-label={filter.placeholder}` from filter metadata.
- **Facet menu labels**: Named from `facet.label`; each option is a native `<label>` wrapping its checkbox rather than a separate `aria-label`, so the name is announced once, not twice.
- **Selection count button**: `aria-live="polite"` to announce selection changes; includes a visually-hidden "Clear selection" label naming what the button (and its trailing icon) does.
- **Table aria-label**: Passed from component prop `ariaLabel` (required).
- **Row descriptions**: Checkboxes are named using `describeRow` callback or the table's own fallback guess (the row's first non-empty string field that isn't the id).
- **Details pane label**: Passed to `ResizableSplit` as `bottomLabel`, and also used as the disclosure chevron's `aria-label`.
- **Keyboard model**: See **grid-role-and-focus** for the grid's focus/Arrow/Space/Enter behavior. Column resizing (the drag handle on a header's trailing border) has no keyboard equivalent — it is pointer-only; see **keyboard-navigable** in Compliance.
- **Minimum touch target**: The selection-count button is 1.75rem (28px) tall; the search and filter inputs are 2rem (32px) tall — both under the 44×44pt / 48×48dp platform minimum; see **touch-target-size** in Compliance.

