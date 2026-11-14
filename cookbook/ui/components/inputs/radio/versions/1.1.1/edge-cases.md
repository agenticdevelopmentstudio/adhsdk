
- **No initial selection**: When neither `value` nor `defaultValue` is set on the group, no RadioGroupItem in the set renders its selected indicator.
- **Value matches no item**: When the group's `value` does not match any item's `value`, no RadioGroupItem displays as checked; this is a valid state, e.g., before a default is chosen.
- **All items disabled**: When every RadioGroupItem in the group has `disabled` set, none can be selected via pointer or keyboard; because the rendered root is a `<span role="radio">` rather than a native button, none render dimmed — each is instead marked `aria-disabled="true"`, `data-disabled`, and `tabindex="-1"`.
- **Disabled item already checked**: A RadioGroupItem can be both checked and disabled simultaneously; it shows the selected indicator combined with the disabled item's non-interactive, non-dimmed state (see States: Checked + Disabled).
- **Boundary values**: Size is fixed at 16×16px via `shrink-0`; no resizing or scaling occurs even inside a shrinking flex container.

