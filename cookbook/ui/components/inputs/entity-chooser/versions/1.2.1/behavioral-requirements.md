
- **accept-single-value**: In single mode, accepting an option or a created entry MUST report it through `onChange(next)` as the new value, replacing any prior one.
- **show-trigger-label-single-when-null**: In single mode, when the value is `null` the trigger MUST show the configured trigger label.
- **show-trigger-value-single**: In single mode, when the value is non-null the trigger MUST show that value.
- **add-to-set-multi**: In multi mode, accepting an option or a created entry MUST append it to the set via `onChange([...value, entry])`.
- **prevent-duplicates-multi**: In multi mode, an entry already in the set MUST NOT be added again — no duplicate and no `onChange`.
- **hide-selected-options-multi**: In multi mode, options already in the set MUST be omitted from the browser's list so they cannot be re-offered.
- **render-removable-chips-multi**: In multi mode, the current set MUST render as chips, each with a control labelled `Remove <value>` that removes that entry via `onChange`.
- **show-empty-hint-multi**: In multi mode, when the set is empty the chip area MUST show the empty-selection hint instead of chips.
- **trigger-label-only-multi**: In multi mode, the trigger MUST always show the configured trigger label, never a member of the set (the inner `ListChooser` value is held at `null`).
- **delegate-list-behavior**: Filtering, the roving-keyboard highlight, OK/Cancel, and add-new MUST be delegated to the embedded `ListChooser`, not re-implemented.
- **block-create-when-disallowed**: When `allowCreate` is false, typed text matching no option MUST NOT be acceptable (no create row shown).
- **respect-disabled**: When `disabled`, the trigger and every chip-remove control MUST be non-interactive.
- **host-mode-renders-trigger-only**: In multi mode with `selectionPlacement="host"`, the component MUST render only the trigger; the caller is responsible for rendering the selected set (via `EntitySelectionChips`).

