
**Decision**: `status` and `source` are plain strings on the DTO, although the daemon has `FindingStatus` and `FindingSource` enums and a database CHECK constraint on status.
**Rationale**: A string keeps the wire forward compatible: an older client decodes a finding from a newer daemon instead of failing the whole list. The cost is that a client switching on status needs a default branch.
**Approved**: pending

**Decision**: All twelve keys are required on decode; there is no tolerant decoder as on the session DTO.
**Rationale**: The doc comment says the daemon's database layer and the app decode the identical shape, and the app, daemon and CLI ship together. The cost shows in the HTTP client's act path, which expects the full body and otherwise falls back to status `acted`.
**Approved**: pending

**Decision**: `severity` is documented as 0 to 100 but is neither clamped nor validated by the DTO.
**Rationale**: It is an ordering hint; the script observer builds every finding in the source, including script-driven ones whose observer is the script's `id`, and passes the session's context-used percentage as severity, which is already a percentage. A future producer would set its own severity.
**Approved**: pending

