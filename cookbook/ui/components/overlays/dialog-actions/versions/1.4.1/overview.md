
`DialogActions` (`@adh-sdk/ui`) is the standard footer for a dialog or alert:
a cancel button (optional) and a confirm button, laid out per the rule in
**alert-and-dialog §Layout**, which resolves to one of two shapes according to how
much room the container gives them:

- **equal-width** — each button takes half the row and the row fills the container
  (`[ Cancel ][ Confirm ]`), when the container is narrow.
- **natural-width, right-justified** — the buttons keep their content width and
  hug the right edge, when the container has room for both.

The rule is expressed in CSS rather than measured in JavaScript: each button is
`flex-1 max-w-max` inside a `justify-end` row, so it grows into its share of the
row but never past its natural width, and any leftover space collects on the left.
The layout engine therefore resolves equal-vs-natural during first layout, and the
first painted frame is the final one. The component also sets initial focus on
mount (defaulting to the safe button) and renders a spinner while `busy`.

One symbol ships from `@adh-sdk/ui/components/dialog-actions`: the
`DialogActions` component. There is no exported layout helper — see *Design
Decisions*.

