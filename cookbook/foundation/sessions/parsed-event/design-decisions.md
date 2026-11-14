
**Decision**: The oauth email is carried on the event, resolved at capture.
**Rationale**: Write time may be much later (spool during a migration, a drop file across a reboot), and the first-oauth-wins upsert would make a wrong attribution permanent.
**Approved**: pending

**Decision**: `oauthAccountEmail` is optional, and nil and empty are different answers.
**Rationale**: Older drop files carry no field, where write-time resolution is still the best answer; empty is a resolved "no login".
**Approved**: pending

**Decision**: The type is `@unchecked Sendable` with immutable fields instead of holding a `Sendable` payload type.
**Rationale**: Hook payloads are arbitrary JSON, held as `[String: Any]`; the invariant is that they are built once and never mutated, which the compiler cannot verify.
**Approved**: pending

**Decision**: The initializer validates nothing.
**Rationale**: Deciding what a malformed or session-less event is belongs to `ParseResult`, which has three non-event outcomes for it; a second check here would drift.
**Approved**: pending

