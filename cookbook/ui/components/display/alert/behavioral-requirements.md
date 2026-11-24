
- **alert-role**: Alert MUST render its root element with
  `role="alert"` for every variant, unless the caller overrides it (see
  **override-role-and-data-slot**).
- **alert-data-slot**: Alert MUST render its root element with
  `data-slot="alert"`.
- **override-role-and-data-slot**: A caller MAY override the root element's
  `role` and `data-slot` by passing them as props, because the remaining
  props are applied after those two defaults. Passing a non-assertive `role`
  (for example `status`) is the escape hatch for a callout that must not
  interrupt screen-reader users.
- **default-variant**: Alert MUST apply the `default`
  variant's styling when no `variant` prop is supplied.
- **six-variants**: Alert MUST support exactly six `variant`
  values: `default`, `info`, `success`, `error`, `warning`, `accent`.
- **merge-classname**: Alert, AlertTitle, and AlertDescription MUST each
  merge a caller-supplied `className` with their own base classes (the
  variant's base classes, for Alert) rather than replacing them.
- **forward-div-props**: Alert, AlertTitle, and AlertDescription MUST each
  forward all received props to their root `<div>`, except `className`, which
  is merged with the base classes (see **merge-classname**) rather than
  passed through unchanged, and, for Alert, `variant`, which selects the
  styling and is not forwarded.
- **widen-grid-when-icon-present**: When Alert has a direct `<svg>`
  child, Alert MUST change its grid-template-columns from `0 1fr` to
  `1.25rem 1fr` and MUST add a `0.75rem` column gap between them.
- **size-icon-child**: Alert MUST render any direct `<svg>` child at a
  fixed size of `1rem` × `1rem` and MUST offset it `0.125rem` downward from
  its row's top edge.
- **title-data-slot**: AlertTitle MUST render its root element with
  `data-slot="alert-title"`.
- **description-data-slot**: AlertDescription MUST render its root element
  with `data-slot="alert-description"`.
- **place-title-column-two**: AlertTitle MUST render in the grid's
  second column.
- **style-title-medium-weight**: AlertTitle MUST render its text with
  medium font weight.
- **place-description-column-two**: AlertDescription MUST render in
  the grid's second column.
- **style-description-small-muted**: AlertDescription MUST render its
  text at the small text size (0.875rem) in the muted text color.
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
  icon-aware grid/sizing behavior; see the Design Decisions entry on icon
  detection via CSS `:has()` for the mechanism and rationale.
