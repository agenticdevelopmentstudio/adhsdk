
- **Missing `actions` and no `children`**: If neither `actions` nor `children` is provided, the toolbar renders with only the border, background, and padding applied; no buttons or content. This is not an error state; it is a valid composition for a pane that implements its own button logic elsewhere. Behavior: MUST render an empty recessed bar.
- **Both `actions` and `children` provided**: When both are present, `children` takes precedence and `actions` is ignored. Behavior: MUST render only the custom children and suppress the preset action flow.
- **`onCreate` not provided but `showCreate={true}`**: The Create button MUST NOT render (checked by the guard `showCreate && onCreate && (...)` in the source). Behavior: MUST skip the Create button and separator.
- **`onDelete` not provided but `showDelete={true}`**: The Delete button MUST NOT render (same guard logic). Behavior: MUST skip the Delete button.
- **`canDelete` not provided**: The Delete button defaults to `undefined`, which is falsy in the context of `!canDelete`. Behavior: MUST render the Delete button as disabled if `onDelete` is provided and `showDelete` is true.
- **`saving` not provided**: Defaults to `false`. Buttons do not appear disabled due to saving state. Behavior: MUST treat as no save in progress.
- **Click while `disabled={true}`**: Native HTML `disabled` attribute prevents click events from firing. Behavior: MUST not invoke the callback.
- **Rapid clicks while saving**: Once `saving={true}`, the Save button is disabled. If the user clicks very quickly before the parent updates `saving={true}`, the second click does not fire because the button is disabled. Behavior: MUST rely on the HTML `disabled` attribute for race condition protection.

