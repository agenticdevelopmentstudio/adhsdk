
**Decision**: Reuse the standard Button Bar with only Cancel and Save instead of drawing a custom bar.
**Rationale**: The source says a document should read the same as every other editing surface.
**Approved**: pending

**Decision**: Show save failures inline in the bar rather than in a browser alert.
**Rationale**: The source documents that the failure is "shown here rather than in a browser alert", so the message stays beside the controls that caused it.
**Approved**: pending

**Decision**: A conflict replaces the changed-elsewhere notice and puts its choices in a warning below the bar.
**Rationale**: When someone else saved first the user has a real decision (Reload theirs or Overwrite), so the weaker "changed" notice would be redundant.
**Approved**: pending

**Decision**: Wording is replaceable per notice through `messages`, with a `noun` for the defaults.
**Rationale**: A file-backed host needs different words (the source's example is "This file changed on disk.") without changing the component.
**Approved**: pending

**Decision**: Overwrite is disabled while saving, but Reload theirs is not.
**Rationale**: Overwrite starts a save and a second one must not overlap; Reload theirs discards the draft and starts no save.
**Approved**: pending

**Decision**: Save and Overwrite are fired and their promises ignored.
**Rationale**: The document object owns success and failure and reports them through `saving`, `saveError` and `conflict`, so the bar only reflects them.
**Approved**: pending

