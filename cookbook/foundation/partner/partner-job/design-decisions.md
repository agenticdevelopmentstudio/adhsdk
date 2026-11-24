
**Decision**: A job carries its guidelines and steps as plain text and data, with no logic.
**Rationale**: The partner follows guidelines written in prose and types steps verbatim, so the model only needs to carry them; templating, scheduling and prompt assembly sit in separate types that read these fields.
**Approved**: pending

**Decision**: `scheduleSeconds` is an optional integer, and the type keeps any integer as given; what a non-positive value means is left to the consumer that arms a timer.
**Rationale**: The type stays a passive value; the controller that arms timers decides what a usable interval is, so the model needs no validation and can round-trip whatever the editor stored.
**Approved**: pending

**Decision**: The types do not validate ids, names or step contents.
**Rationale**: Validation depends on where the value is used. The installer checks the id before building a file path, and the store keys on the id, so each caller guards what it needs.
**Approved**: pending

**Decision**: Decoding requires every non-optional key, including `isBuiltIn`.
**Rationale**: The source relies on synthesized `Codable`, which has no defaults for missing keys. A stored job written by an older app version without a new field would fail to decode, so adding a field requires a migration or an optional type.
**Approved**: pending

**Decision**: A step's environment is a closed two-case set rather than free text.
**Rationale**: Step templating treats a terminal command as a shell line and quotes values into it, while a Claude step is a prompt typed as written; the two cases drive that difference, so an unknown value must fail rather than be guessed.
**Approved**: pending

