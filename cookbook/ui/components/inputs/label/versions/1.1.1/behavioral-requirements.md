
- **renders-label-element**: Component MUST render as an HTML `label` element.
- **forwards-label-props**: Component MUST accept and forward all standard HTML label attributes (`htmlFor`, `id`, event handlers, etc.) via prop spreading.
- **default-typography**: Component MUST render its text at medium weight, small size, with a line-height of 1 (no extra leading), and MUST NOT allow that text to be user-selected.
- **merges-classname**: Component MUST accept a `className` prop and merge it with its default styling using a class merging utility, such that a consumer-supplied class overrides the corresponding default class.
- **peer-disabled-style**: When the label is rendered as a sibling immediately following a peer form control (a control carrying the `peer` class) and that control is disabled, the label MUST render with 50% opacity and a not-allowed cursor. A control nested inside the label, or a peer control that comes after the label rather than before it, does not trigger this style.
- **focuses-associated-control**: Clicking the label's rendered text MUST move focus to (and, for a checkbox or radio control, toggle) the form control it is associated with via `htmlFor` or nesting. This follows from rendering a native `label` element (**renders-label-element**); the component adds no click handling of its own.

