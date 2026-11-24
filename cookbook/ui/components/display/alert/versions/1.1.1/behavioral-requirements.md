
- **alert-role**: Alert MUST render its root element with
  `role="alert"`.
- **alert-data-slot**: Alert MUST render its root element with
  `data-slot="alert"`.
- **default-variant**: Alert MUST apply the `default`
  variant's styling when no `variant` prop is supplied.
- **five-variants**: Alert MUST support exactly five `variant`
  values: `default`, `info`, `success`, `error`, `accent`.
- **merge-classname-alert**: Alert MUST merge a caller-supplied
  `className` with the selected variant's base classes rather than
  replacing them.
- **forward-div-props-alert**: Alert MUST forward all received props
  other than `variant` to its root `<div>`; `className` is not passed
  through unchanged — it is merged with the variant's base classes (see
  **merge-classname-alert**) rather than dropped.
- **widen-grid-when-icon-present**: When Alert has a direct `<svg>`
  child, Alert MUST change its grid-template-columns from `0 1fr` to
  `1.25rem 1fr` and MUST add a column gap between them.
- **size-icon-child**: Alert MUST render any direct `<svg>` child at a
  fixed size of `1rem` × `1rem` and MUST offset it `0.125rem` downward from
  its row's top edge.
- **place-title-column-two**: AlertTitle MUST render in the grid's
  second column (`col-start-2`).
- **style-title-medium-weight**: AlertTitle MUST render its text with
  medium font weight.
- **merge-classname-title**: AlertTitle MUST merge a
  caller-supplied `className` with its base classes rather than replacing
  them.
- **forward-div-props-title**: AlertTitle MUST forward all received
  props other than `className` to its root `<div>`; `className` is not
  passed through unchanged — it is merged with the base classes (see
  **merge-classname-title**) rather than dropped.
- **place-description-column-two**: AlertDescription MUST render in
  the grid's second column (`col-start-2`).
- **style-description-small-muted**: AlertDescription MUST render its
  text at the `text-sm` size in the muted text color.
- **merge-classname-description**: AlertDescription MUST merge
  a caller-supplied `className` with its base classes rather than
  replacing them.
- **forward-div-props-description**: AlertDescription MUST forward
  all received props other than `className` to its root `<div>`;
  `className` is not passed through unchanged — it is merged with the base
  classes (see **merge-classname-description**) rather than dropped.
- **export-alert-variants**: The module MUST export `alertVariants` as
  a function usable independently of the `Alert` component.
- **compose-title-and-description-as-children**: Alert SHOULD be
  composed with `AlertTitle` and/or `AlertDescription` as children so their
  content aligns in the shared second grid column alongside an optional
  icon (see Design Decisions for rationale and the conditions under which a
  caller may deviate).
- **render-without-icon-title-or-description**: Alert MAY be rendered
  with no icon, no `AlertTitle`, and no `AlertDescription`; the root
  element places no constraint on child type or count.
- **accept-any-icon-element**: Alert MAY receive any element that
  renders as a literal `<svg>` tag as a leading child to trigger the
  icon-aware grid/sizing behavior; see Design Decisions > Icon detection via
  CSS `:has()`, not an icon prop, for the mechanism and rationale.

