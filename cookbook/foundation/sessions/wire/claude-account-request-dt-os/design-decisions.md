
**Decision**: One request envelope carries every operation, whether the daemon answers it or relays it to the app.
**Rationale**: The source's doc comment records that the two kinds of operation share one envelope, and the request's doc comment says the daemon forwards a relayed request to the app unchanged. One shape means the daemon never re-encodes what it relays and `steno` has one type to send.
**Approved**: pending

**Decision**: Keychain-touching operations are answered by the app, not the daemon; only `usage` and `token` are served by the daemon.
**Rationale**: The app keeps custody of the keychain items and runs the same code its own menus run, while the daemon answers from state it already holds so those two work with the app shut. `saved` never mints a token, so listing cannot spend a refresh token.
**Approved**: pending

**Decision**: A refusal travels as the reply's reason string, not as a field of the response, and the no-app refusal is a shared exact sentence.
**Rationale**: The response's doc comment cites the `XPCReply` convention for refusals. `steno` matches on `noCustodianReason` verbatim to decide that launching the app and retrying will help, so the sentence is defined once in shared code rather than at each end; the cost is that it is an English literal that cannot be localized without changing the match.
**Approved**: pending

**Decision**: Four enum cases use wire spellings that differ from their Swift case names (`switch`, `save_token`, `save_login`, `rate_limited`).
**Rationale**: `switch` is a Swift keyword, so the case is `switchLogin` with raw value `"switch"`; the others use snake_case raw values. A port has to keep the raw strings, not the case names.
**Approved**: pending

**Decision**: `credentialKind` is a plain `String` rather than the `ClaudeCredentialKind` enum, and the request performs no per-operation validation.
**Rationale**: The doc comments describe the field as the kind's raw value. Keeping it a string lets a request or summary carrying a kind this build does not know still decode; which fields an operation needs is checked by the handlers, not by the wire type.
**Approved**: pending

**Decision**: Token states are the states a caller can act on, so `spent` and `expired` are separate cases, and `isProbeable` is a different question from account health.
**Rationale**: The source's doc comment: an expired access token is a routine refresh the next round performs, a spent refresh token is a dead account that needs a browser login, and telling them apart keeps a status line quiet or sends the user somewhere useful. A `spent` login's access token may still be within its eight hours, so it is not probeable without being healthy.
**Approved**: pending

**Decision**: `state` on the status and the renewal is a raw string, with typed accessors that fall back to `unknown` (status) and `inconclusive` (renewal).
**Rationale**: The doc comments say a raw string lets a client older than a state the daemon knows still decode the rest. The renewal falls back to `inconclusive` because an unknown state is "never a reason to refuse a login". A consequence the source does not guard: `counting(from:)` rebuilds the status through the typed initializer, so it rewrites an unrecognized state string to `"unknown"`.
**Approved**: pending

**Decision**: The secret-free token status is a separate type from the token-bearing credential, and the per-credential summary is not repeated on the evaluation reply.
**Rationale**: A single type used both ways "would be one field rename away from serving a refresh token over HTTP". The summary is one document served by `GET /accounts` with the quota readings; a second copy on the push "would be a copy nobody reads and everybody has to keep in step".
**Approved**: pending

**Decision**: `secondsRemaining` is computed daemon-side and recomputed on every read through `counting(from:)`.
**Rationale**: Computing it daemon-side means every client agrees on "now"; recomputing at read time matters because a status is decided once per push and read for up to five minutes, and a frozen countdown would overstate the time left.
**Approved**: pending

**Decision**: Rotated and renewed logins return down the connection that supplied them, the caller stores them before anything that can fail, and `tokenUntouched` defaults to `false`.
**Rationale**: A refresh token is single-use, so the returned pair is the only working copy, and the supplying connection is the one path guaranteed to reach the process holding the keychain item and no one else. A timeout, 5xx or unreadable reply may have rotated the pair server-side and lost the answer, so only a certain non-spend sets `tokenUntouched`, and an older daemon's missing field reads `false`.
**Approved**: pending

