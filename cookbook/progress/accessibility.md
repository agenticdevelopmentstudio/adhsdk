
**UI**:

- Renders `role="progressbar"` with `aria-valuemin` 0, `aria-valuemax` 100, and
  `aria-valuenow` set to the rounded, clamped percentage — so assistive technology
  announces determinate progress.
- It is a determinate bar only; there is no indeterminate mode (see the Controls
  component below for the toolkit's indeterminate progress control).
- The component carries no built-in visible or accessible label. Consumers MUST
  pass an `aria-label` (or `aria-labelledby`) — the demo labels each bar
  ("Build progress", "Complete") — since an unnamed `progressbar` fails WCAG
  4.1.2 (Name, Role, Value); see **requires-accessible-name** and T8.
- Purely presentational otherwise: not focusable and not interactive; progress is
  driven by the consumer's `value`.

**Controls**:

- Renders `role="progressbar"` with `aria-valuemin` 0 and `aria-valuemax` set to `max`;
  `aria-valuenow` is the raw, unrounded `value` (or omitted when `indeterminate` or when
  `value` is `undefined`) — see **reports-raw-valuenow** and **omits-valuenow-without-value**.
- Does support an indeterminate mode (the `indeterminate` prop); see
  **indeterminate-mode** and States.
- The optional `label` renders as a plain `aws-field__label` div with no
  `id`/`aria-labelledby` pairing to the `role="progressbar"` element, so it is not
  programmatically associated with the progress bar the way the UI bar's forwarded
  `aria-label` is. A screen reader announces this component's progress bar with no
  accessible name unless a consumer supplies one out of band.
- Purely presentational otherwise: not focusable and not interactive; progress is driven
  by the consumer's `value`.

