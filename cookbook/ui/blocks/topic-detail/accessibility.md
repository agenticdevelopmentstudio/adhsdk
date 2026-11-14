
- **row-semantics**: Rows are native buttons; the active one carries `aria-current="true"`; disabled rows are native disabled buttons; icons are `aria-hidden`.
- **icon-only-name**: Icon-only rows carry the label (plus ", needs attention" when blocked) as `aria-label`; expanded blocked rows append a screen-reader-only ", needs attention".
- **landmarks**: The rail is an `aside` named `railLabel` or "Topic list"; the toolbar is a named `role="toolbar"`; dividers are `role="separator"`; the collapse toggle is named from the label "topic list" and controls the list element.
- **tool-names**: The `+`, the close button, the filter button and the clear button take their names from `label` (so a screen reader and a hover tooltip both read it); the trash button is named "Delete {name}"; batch checkboxes are named by the row label.
- **live-regions**: A polite status region announces "Loading" while busy; "Searching…" and "Nothing matches" render as `role="status"`.
- **combobox**: The filter field is a combobox with `aria-expanded`, `aria-controls` and `aria-activedescendant` following the highlight; options are `role="option"` with `aria-selected`.
- **focus-return**: Closing the filter returns focus to the filter button; the confirmation dialog opens with focus on Cancel, with its keyboard shortcuts off (owned by `AlertModal`).
- **non-colour-signals**: The blocked dot is paired with the announced text, and the active row pairs the gold bar with `aria-current`.
- **resize-handle-keyboard**: NEEDS REVIEW: Not implemented in source. The resize handle is a `role="separator"` with an `aria-label` but handles only pointer events, so a keyboard user cannot resize the rail; the collapse toggle is the only keyboard route to a narrower rail. A product decision on whether keyboard resizing is required would settle it.
- **tool-target-size**: NEEDS REVIEW: Not implemented in source. `ListToolButton` is a 16px icon with `p-0.5` padding (about 20px) and the trash button is 19px, with no touch-size override in this file or in `styles/components.css`, whose touch rules (`adh-touch-row`, `data-htd-row`) grow the rows and suggestion options only; whether these tools meet the target-size floor is a decision the source cannot make. A target-size audit on a touch device would settle it.

