
- **render-trigger**: The component MUST render a button trigger displaying the label text and a count of selected items in parentheses (e.g., "Category (3)") when one or more items are selected.
- **omit-count-when-empty**: The component MUST NOT display the count when zero items are selected; only the label text MUST be shown in the trigger.
- **disable-trigger**: The component MUST disable the trigger button when the options list is empty.
- **show-chevron**: The component MUST display a chevron-down icon in the trigger, marked as decorative (`aria-hidden="true"`).
- **trigger-expanded-state**: The trigger MUST expose its expanded/collapsed state and that it controls a popup (`aria-expanded`, `aria-haspopup`), supplied by the underlying Popover trigger component.
- **render-popover**: The component MUST display a popover when the trigger is clicked, containing the option list and quick-select buttons, and the popover MUST remain open while options are toggled.
- **render-options**: The component MUST render each option as a checkbox with an associated label, derived from the options array.
- **label-transform**: The component MAY accept a `labelOf` function to transform option values into display labels; if not provided, the option value MUST be displayed as-is.
- **toggle-on-checkbox-click**: The component MUST add or remove an option from the selection when its checkbox is toggled (by click or by keyboard activation), invoking the `onChange` callback with the updated selection.
- **synchronous-selection-update**: Each `onChange` call MUST be computed from the current `selected` prop at the moment of the toggle. The component holds no selection state of its own, so the host MUST apply each `onChange` to `selected` before the next toggle is processed, or rapid toggles will each compute from the same stale `selected` value and overwrite one another instead of accumulating.
- **render-all-button**: The component MUST render an "All" quick-select button that selects every option and invokes `onChange`.
- **disable-all-button**: The component MUST disable the "All" button when all options are already selected.
- **render-none-button**: The component MUST render a "None" quick-select button that clears all selections and invokes `onChange`.
- **disable-none-button**: The component MUST disable the "None" button when zero items are currently selected.
- **handle-overflow**: The component MUST allow the option list to scroll vertically when the number of options exceeds available space (max-height 16rem, vertical scrolling enabled).
- **preserve-selection-state**: The component MUST NOT alter the selection when the popover is opened or closed.
- **empty-selection-semantics**: The component MUST NOT assign any filtering meaning to the selection itself — it only tracks which values are checked. Whether an empty selection means "no filter is applied" is the host application's decision, not the component's.
- **stale-selection-values**: If `selected` contains a value not present in `options`, that value remains selected and continues to count toward the trigger's badge, but is not rendered as a checkbox. When "All" is enabled (see **disable-all-button** — some current option is not yet selected), clicking it MUST replace the selection with exactly the current `options` (dropping the stale value); clicking "None" MUST always replace the selection with an empty set (also dropping the stale value), since **disable-none-button** only disables "None" when the selection — stale values included — is already empty. If every current option is already selected alongside a stale value, **disable-all-button** disables "All", so "All" cannot drop the stale value in that state; only "None", or the host clearing it directly, can. Because the component is fully controlled, the host MAY clear a stale value directly by calling `onChange` itself, even while the trigger is disabled for having zero options.

