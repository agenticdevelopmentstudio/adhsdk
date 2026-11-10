
- **render-caption**: The field MUST render the `label` node as an
  uppercase-mono caption (the shared `fieldCaptionClass`) above its control.
- **associate-label-implicitly**: The field MUST wrap the caption and the
  control in a single shared `Label` so activating the caption focuses the control,
  without the caller supplying `htmlFor`/`id`.
- **render-control**: The field MUST render its `children` (the control)
  between the caption and the supporting line.
- **show-hint-when-no-error**: When `error` is unset and `hint` is provided,
  the field MUST render `hint` below the control in dim mono.
- **show-error-in-place-of-hint**: When `error` is set, the field MUST render
  `error` below the control in red mono and MUST NOT also render `hint`.
- **omit-supporting-line-when-empty**: When neither `error` nor `hint` is
  provided, the field MUST render no supporting line below the control.
- **merge-classname**: The field MUST merge a caller-supplied `className` onto
  its root without dropping its own layout classes.
- **name-error-line**: When `errorId` is provided and `error` is set, the field
  MUST set `errorId` as the `id` of the rendered error line (never the hint line),
  so a control can point its own `aria-describedby` at it.
- **render-inline-layout**: When `layout` is `"inline"`, the field MUST render the
  caption beside the control instead of above it — a right-aligned label column
  sized by the `--apt-field-label-w` custom property, with the control (and any
  sibling children) in one cell and the supporting line in the second column.

