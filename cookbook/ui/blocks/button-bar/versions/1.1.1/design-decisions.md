
**Decision**: Derive the Save button's inert-ness from a single source of truth, `saveDisabled = !canSave || saving`, and key its variant, `disabled` attribute, and muted-text styling all off that one value.
**Rationale**: This ensures a button that reads "Saving…" is guaranteed to have `disabled={true}`, and a disabled Save button is guaranteed to show muted text and the ghost variant — preventing the visual inconsistency of a "gold, enabled-looking button" that reads "Saving…" and ignores clicks.
**Approved**: pending

**Decision**: Make the preset editing action flow (Create/Delete/Cancel/Save) optional and composable: consumers either pass `actions` for the preset flow or `children` for their own button logic, with `children` taking precedence; the separator between Create and Delete renders only when Create is shown.
**Rationale**: This accommodates both simple panes (single-record editors with no Create/Delete) and complex list toolbars (filters, selection actions) without orphaned visual dividers when Create is hidden.
**Approved**: pending

**Decision**: Default `ariaLabel` to `"Editing actions"`, default `saving` to `false`, and treat an omitted `canDelete` as falsy.
**Rationale**: The toolbar stays accessible and labeled even if a consumer forgets to set `ariaLabel`; the `saving` default reduces boilerplate for panes with no async save logic; and the `canDelete` default lets consumers omit it entirely when delete is never available.
**Approved**: pending

