
- **renders-combobox-role**: The text input MUST expose `role="combobox"` and, while collapsed, `aria-expanded="false"`.
- **type-reveals-suggestions**: Typing MUST open the popup and show only the suggestions whose text contains the query as a case-insensitive substring.
- **empty-shows-message**: When the query matches no suggestion, the popup MUST show the empty message rather than an empty box.
- **arrow-moves-active**: ArrowDown / ArrowUp MUST move the active suggestion, reflected via `aria-activedescendant` on the input.
- **enter-picks-active**: Enter MUST pick the active suggestion, filling the input with its text via `onValueChange`, and close the popup. When no suggestion is active, Enter MUST leave the input's text unchanged.
- **escape-closes**: Esc MUST close the popup without changing the input's current text.
- **pointer-pick**: A pointer click on a suggestion MUST pick it (fill the input) and close.
- **controlled-value**: The input MUST reflect the `value` prop and report every edit through `onValueChange`.
- **aria-controls-listbox**: While open, the input's `aria-controls` MUST reference the rendered listbox element.
- **disabled-inert**: When `disabled`, the input MUST be non-interactive and MUST NOT open the popup.
- **current-value-marked**: The suggestion row whose text equals the current `value` MUST show a check mark.

