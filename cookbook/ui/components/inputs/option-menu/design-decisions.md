
**Decision**: Hand-manage the selection (highlighted row) in component state, independent of DOM focus, instead of building on `DropdownMenu` / Base-UI menu roles.
**Rationale**: Menu roles hijack typeahead and focus and fight an embedded text input; tracking selection in state lets arrow keys work whether DOM focus is on the listbox surface or in the Other input.
**Approved**: pending

**Decision**: Keep selection and commit distinct — selection is a transient highlight that never fires `onChange`; only a commit (Enter, OK, row click) fires `onChange` and closes.
**Rationale**: Lets users browse the list with arrow keys (including into and out of the Other input) without side effects, so only a deliberate action commits a value.
**Approved**: pending

**Decision**: Hard-code the OK button label ("OK") rather than expose an `okLabel` option.
**Rationale**: The source has no `okLabel` prop, so the label cannot be localized today; this is recorded as known debt (the failed `no-hardcoded-strings` check) until an `okLabel` option is added.
**Approved**: pending
