
**Decision**: `ScriptPredicate` and `ScriptAction` have hand-written Codable with fixed single-word keys, while the structs use the wire-wide snake_case strategy.
**Rationale**: The doc comment says the enums are strategy-invariant: a type discriminator with fixed keys survives any encoder configuration, so the daemon's storage encoding and the wire encoding of the same enum agree. The cost is a second spelling rule to port.
**Approved**: pending

**Decision**: The operation key on the wire is `op`, while the Swift case label is `operation`.
**Rationale**: Recorded as a naming divergence so a port uses the wire name; the source's `Keys` enum maps `operation` to `"op"`.
**Approved**: pending

**Decision**: Unknown `type` discriminators fail the whole decode instead of being skipped or kept as an unknown case.
**Rationale**: The source throws a data-corrupted error; the documentation states the discriminated format leaves room for new action types, but this version has no tolerant path, so a client older than the daemon cannot read a script list that holds a new action.
**Approved**: pending

**Decision**: A condition's `value` is a String for every field, numeric or not.
**Rationale**: One value slot keeps the editor and the wire simple; `isNumeric` tells the evaluator and the save-time validator which fields parse the string as a number.
**Approved**: pending

**Decision**: `OversightProviderSelection` lives in this file beside the script types although it concerns provider choice.
**Rationale**: The doc comment places it in the shared package so the app's picker and the daemon's settings reader use one constant. It is a one-constant namespace, not part of the script shape.
**Approved**: pending

