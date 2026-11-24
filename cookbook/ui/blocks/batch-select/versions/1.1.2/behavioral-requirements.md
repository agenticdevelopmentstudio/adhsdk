
- **expose-active-state**: The hook MUST expose a boolean `active` property indicating whether batch mode is currently active.
- **expose-selected-ids**: The hook MUST expose a `selectedIds` property as a `Set<string>` of currently selected row identifiers.
- **provide-set-selected-ids**: The hook MUST provide a `setSelectedIds` function to update the selected row IDs, accepting a `Set<string>` parameter.
- **expose-toggle-active**: The hook MUST provide a `toggleActive` function that switches batch mode on and off.
- **clear-selection-on-toggle-exit**: When `toggleActive` is called to exit batch mode, the `selectedIds` MUST be cleared to an empty `Set<string>`.
- **clear-selection-on-toggle-entry**: When `toggleActive` is called to enter batch mode, the `selectedIds` MUST be cleared to an empty `Set<string>`.
- **provide-clear-function**: The hook MUST provide a `clear` function that empties `selectedIds` without changing the `active` state.
- **expose-count**: The hook MUST expose a `count` property equal to the size of `selectedIds`.
- **reset-on-reset-key-change**: When the `resetKey` option changes (as determined by `Object.is` comparison), the hook MUST reset `selectedIds` to an empty `Set<string>` synchronously during render.
- **set-selected-ids-new-reference**: Each call to `setSelectedIds` MUST hand back exactly the `Set<string>` instance the caller supplied; the hook MUST NOT synthesize a new instance or preserve the previous one by comparing contents, so calling `setSelectedIds` with a different object — even one with identical contents — MUST produce a new `selectedIds` reference on the next render.
- **reset-uses-shared-empty-selection**: Every render-time reset (see **reset-on-reset-key-change**) MUST set `selectedIds` to the same shared `EMPTY_SELECTION` instance rather than a freshly constructed empty `Set`, so consecutive resets return an identical reference and do not invalidate callers' memoized effects.
- **button-render-label**: The `BatchSelectButton` MUST render a clickable element displaying either the `selectLabel` (when inactive) or `doneLabel` (when active).
- **button-toggle-on-click**: The `BatchSelectButton` MUST call `batch.toggleActive` when clicked.
- **button-announce-pressed-state**: The `BatchSelectButton` MUST set `aria-pressed` to reflect the `batch.active` state.
- **button-default-select-label**: If `selectLabel` is not provided, the button MUST render "Select".
- **button-default-done-label**: If `doneLabel` is not provided, the button MUST render "Done".

