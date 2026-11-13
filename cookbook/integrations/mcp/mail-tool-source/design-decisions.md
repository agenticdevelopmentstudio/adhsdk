
**Decision**: Argument failures and service failures are both returned as error results, never thrown.
**Rationale**: The model that called the tool can read an error result and correct its next call, whereas a thrown error would abort the host's tool loop.
**Approved**: pending

**Decision**: Arguments are re-validated in code and the advertised schema is not trusted; booleans are kept distinct from numbers.
**Rationale**: Hosts and models do not reliably honour a schema, and a platform JSON parser may treat `true` as the number 1, so `limit: true` would otherwise be accepted as a page size of 1. (In Swift both bridge to `NSNumber`; see Platform Notes.)
**Approved**: pending

**Decision**: Invalid or non-object argument JSON becomes an empty dictionary instead of its own error.
**Rationale**: The call then fails with the first missing-argument message, which keeps one failure path and tells the model what to supply, instead of adding a second parse-error message for a case the model rarely causes.
**Approved**: pending

**Decision**: `since` and `until` are normalised to UTC strings with millisecond precision; a bare date spans the whole UTC day.
**Rationale**: The message store compares UTC date strings lexically, so every bound must have the same fixed-width form for the comparison to be correct.
**Approved**: pending

**Decision**: Only a limit of zero or less is rejected; a limit above 500 is clamped by `MailMessageFilter`.
**Rationale**: The filter already owns the page-size range, so keeping the clamp there leaves one place to change it; the tool rejects only values no range could accept.
**Approved**: pending

**Decision**: The tool does not check `any_labels` against `query`; the client does.
**Rationale**: Only the client knows whether the service honoured the combination, so the check lives where the reply is seen and reaches the caller as an error result.
**Approved**: pending

**Decision**: `from` distinguishes absent from empty by passing `nil` or an empty array.
**Rationale**: The two cases mean different things (move out of INBOX versus only add the label), and collapsing them would make "add only" impossible to request.
**Approved**: pending

**Decision**: No timeout, cancellation, retry or logging is added in this layer.
**Rationale**: The transport owns timeouts and retries so that retry policy stays in one place, and the host owns cancellation and logging; a second layer here would double-retry and hide which layer gave up.
**Approved**: pending

