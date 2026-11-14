
**Decision**: Timestamps and absent values are plain strings, with the empty string as the sentinel for unresolved, no repo, open and still idle.
**Rationale**: The source records no rationale for choosing strings over optionals. It documents each sentinel in a doc comment (`"" = unresolved`, `"" = open`, `"" = still idle`) and types every field as a `String`.
**Approved**: pending

**Decision**: The initializers do no validation.
**Rationale**: The types are a read-only projection; parsing and malformed-input handling live in derivation, which keeps these types free of date logic.
**Approved**: pending

**Decision**: The session id is derived from the span id through `ActivitySpanSession`, not stored.
**Rationale**: One function (`ActivitySpanSession.sessionId(spanId:)`) owns the `app:` prefix so a span and its billing session cannot disagree, and the prefix is the marker that separates app segments from Claude segments.
**Approved**: pending

