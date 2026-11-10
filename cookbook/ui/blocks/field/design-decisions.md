
**Decision**: Wrap the whole row in one shared `Label` rather than pairing an
`htmlFor`/`id`.
**Rationale**: Implicit association removes per-call id wiring and makes the
caption a real click target, while keeping every caption on the one
`fieldCaptionClass` treatment.
**Approved**: pending

**Decision**: `error` occupies the same slot as `hint` (one supporting line, not
two).
**Rationale**: Once a `hint` is already occupying the slot, the row height
stays stable as validation toggles, and forms get a single, consistent place
for inline errors instead of re-inventing error text; a field with no `hint`
at all still gains a line the first time an `error` appears (see the Edge
Cases qualification of **omit-supporting-line-when-empty**).
**Approved**: pending

**Decision**: `Field` owns no value or validation.
**Rationale**: It stays a reusable layout primitive over any control;
optimize-for-change keeps validation policy in the form, not the row.
**Approved**: pending

**Decision**: Hint and error are mono at the same `0.7rem` metrics.
**Rationale**: Error and hint read as the same "supporting text" rhythm,
differing only by the `apt-red` tone that signals the error.
**Approved**: pending

**Decision**: `layout` prop controls caption placement (stacked above or inline
beside).
**Rationale**: Grouped inline forms (e.g., categories and tags rows) align
captions by sharing the `--apt-field-label-w` custom property, reducing
per-call coupling while keeping the default stacked layout simple and
no-config.
**Approved**: pending

