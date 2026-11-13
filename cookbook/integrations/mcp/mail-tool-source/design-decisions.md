
**Decision**: Argument failures and service failures are both returned as error results, never thrown.
**Rationale**: The type's doc comment says "a bad argument or a service failure comes back as an error result", so the model that called the tool can read the message and correct itself.
**Approved**: pending

**Decision**: Arguments are re-validated in code and the advertised schema is not trusted; booleans are told apart from numbers with `CFBooleanGetTypeID`.
**Rationale**: JSON booleans and numbers both bridge to `NSNumber` (the source's own comment), so `limit: true` would otherwise read as 1.
**Approved**: pending

**Decision**: Invalid or non-object argument JSON becomes an empty dictionary instead of its own error.
**Rationale**: The call then fails with the first missing-argument message, which keeps one failure path; the source does this with `try?` and a default.
**Approved**: pending

**Decision**: `since` and `until` are normalised to UTC strings with millisecond precision; a bare date spans the whole UTC day.
**Rationale**: `MailDateBound`'s doc comment says the store compares UTC strings lexically, so every bound must have the same fixed-width form.
**Approved**: pending

**Decision**: Only a limit of zero or less is rejected; a limit above 500 is clamped by `MailMessageFilter`.
**Rationale**: The schema text says "1 to 500" but the filter's `didSet` clamps, so the tool does not duplicate the range check.
**Approved**: pending

**Decision**: The tool does not check `any_labels` against `query`; the client does.
**Rationale**: `MailClient.messages` throws when the service did not apply `any_labels` or `query`, so the refusal reaches the caller as an error result.
**Approved**: pending

**Decision**: `from` distinguishes absent from empty by passing `nil` or an empty array.
**Rationale**: The schema description gives the two cases different meanings (INBOX versus nothing), and the move tests assert all three request shapes.
**Approved**: pending

**Decision**: No timeout, cancellation, retry or logging is added in this layer.
**Rationale**: The source has none; the transport inside `MailClient` and the host own them.
**Approved**: pending

