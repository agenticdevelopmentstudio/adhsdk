
### Classification (`ClaudeAuthEvaluator.state(of:now:)`)

- **classify-without-login**: `state(of:now:)` MUST return `.unknown` for a credential whose `oauth` is absent (a `claude setup-token` token or a probe-only credential).
- **classify-without-expiry**: `state(of:now:)` MUST return `.unknown` for a credential whose login has no `expiresAt`, and MUST NOT treat a missing expiry as expired.
- **classify-usable**: `state(of:now:)` MUST return `.usable` when the access token's expiry in epoch seconds minus `now` is strictly greater than the effective margin.
- **classify-expired**: `state(of:now:)` MUST return `.expired` when the access token's expiry in epoch seconds minus `now` is less than or equal to the effective margin, including an expiry already in the past.
- **effective-margin**: The effective margin MUST be the larger of `ClaudeTokenRefresher.refreshMargin` (300 seconds) and the credential's `refreshWithin`; a `refreshWithin` smaller than 300 seconds, or absent, MUST leave the margin at 300 seconds.
- **classify-offline**: `state(of:now:)` MUST NOT perform any network request or invoke the refresher.
- **classify-states-only**: `state(of:now:)` MUST return only `.unknown`, `.usable` or `.expired`; the other `Sessions.ClaudeTokenState` cases arise only from a refresh attempt.

### Evaluation round (`ClaudeAuthEvaluator.evaluate(_:now:refresh:)`)

- **round-status-per-credential**: `evaluate` MUST return exactly one entry in `Outcome.statuses` for every credential passed in.
- **round-order**: `Outcome.statuses`, `Outcome.probeable` and `Outcome.rotated` MUST each list their entries in the order the credentials were passed in, even though the credentials are judged concurrently.
- **round-concurrent**: `evaluate` MUST judge all credentials of a round concurrently, so a round with several expired logins costs one refresh's round trip in wall-clock time rather than the sum of them.
- **round-single-now**: Every judgment in a round MUST use the one `now` value passed to `evaluate` (default: the current time at the call).
- **round-never-throws**: `evaluate` MUST NOT throw; every refresh failure MUST be folded into that credential's status.
- **round-failure-isolated**: A refresh failure for one credential MUST NOT change the state, probeability or status of any other credential in the round.
- **refresh-precondition**: `evaluate` MUST invoke the refresher for a credential only when all four hold: its state is `.expired`, it carries a login, a refresher was supplied, and it carries an `itemKey`.
- **refresh-at-most-once**: `evaluate` MUST invoke the refresher at most once per credential per round.
- **classify-only-mode**: A caller MAY pass `nil` as `refresh`; `evaluate` MUST then invoke no refresher and MUST classify every credential with `state(of:now:)` alone.
- **unrefreshed-probeability**: For a credential that is not refreshed, the credential MUST appear in `Outcome.probeable` unchanged exactly when its state's `isProbeable` is true (`.usable` and `.unknown` are probeable; `.expired` is not).
- **unrefreshed-status**: For a credential that is not refreshed, the status MUST carry its classified state and no `detail`.
- **missing-item-key-refusal**: An expired credential with a login and a refresher available but no `itemKey` MUST NOT be refreshed, MUST NOT appear in `Outcome.probeable`, MUST produce no rotation, and MUST get the status `.expired`.
- **missing-item-key-log**: The refusal in missing-item-key-refusal MUST emit one error-level log line naming the account.
- **refresh-success-probe**: After a successful refresh, `Outcome.probeable` MUST carry the credential with `token` set to the fresh access token, `oauth` set to the fresh login, the same `account`, `credentialKind` and `itemKey`, and no `refreshWithin`.
- **refresh-success-rotation**: After a successful refresh, `Outcome.rotated` MUST carry one rotation with the credential's `itemKey`, its `account` and the fresh login.
- **refresh-success-status**: After a successful refresh, the status MUST have state `.refreshed`, expiry fields read from the fresh login, and no `detail`.
- **every-rotation-returned**: Every login the refresher returns during a round MUST appear in `Outcome.rotated`; the evaluator MUST NOT discard or retain a rotation.
- **refusal-mapping**: A `ClaudeOAuthRefreshError` MUST map to a state as follows: `.spent` to `.spent`, `.rateLimited` to `.rateLimited`, and both `.inconclusive` and `.unsent` to `.inconclusive`.
- **refusal-probeability**: After a refresh that throws a `ClaudeOAuthRefreshError`, the original credential MUST appear in `Outcome.probeable` exactly when the mapped state is probeable (`.rateLimited` and `.inconclusive` are; `.spent` is not).
- **refusal-detail**: After a refresh that throws a `ClaudeOAuthRefreshError`, the status `detail` MUST be the error's `shortText`.
- **foreign-error-inconclusive**: After a refresh that throws any other error, the status MUST be `.inconclusive`, the original credential MUST appear in `Outcome.probeable`, and the `detail` MUST be the error's localized description shortened to 60 characters.
- **failure-status-expiry**: After any refresh failure, the status expiry fields MUST be read from the original login, not from anything the refresher produced.
- **refresh-failure-log**: Every refresh failure MUST emit one error-level log line naming the account and the short reason.
- **no-self-scheduled-refresh**: The evaluator MUST NOT refresh outside a call to `evaluate` or `renew`; it MUST hold no timer and no state between calls.

### Renewal (`ClaudeAuthEvaluator.renew(_:refresh:)`)

- **renew-unconditional**: `renew` MUST invoke the refresher exactly once regardless of the login's expiry, including for an access token with hours left.
- **renew-success**: A successful `renew` MUST return a `Sessions.ClaudeLoginRenewalDTO` with state `.refreshed`, `oauth` set to the fresh login, no `detail`, and `tokenUntouched` false.
- **renew-refusal**: A `renew` whose refresher throws a `ClaudeOAuthRefreshError` MUST return the state given by refusal-mapping, no `oauth`, the error's `shortText` as `detail`, and `tokenUntouched` equal to the error's `leftTokenUntouched`.
- **renew-foreign-error**: A `renew` whose refresher throws any other error MUST return state `.inconclusive`, no `oauth`, the localized description shortened to 60 characters as `detail`, and `tokenUntouched` false.
- **renew-never-throws**: `renew` MUST NOT throw.
- **renew-failure-log**: Every failed `renew` MUST emit one error-level log line with the short reason and no account name.

### Status (`ClaudeAuthEvaluator.status(_:state:oauth:now:detail:)`)

- **status-identity**: `status` MUST copy `account`, `credentialKind` and `itemKey` from the credential unchanged.
- **status-state**: `status` MUST store the given state's raw value (for example `rate_limited` for `.rateLimited`).
- **status-expiry-seconds**: `status` MUST set `expiresAt` to the login's `expiresAt` divided by 1000 and `refreshExpiresAt` to its `refreshTokenExpiresAt` divided by 1000.
- **status-countdown**: `status` MUST set `secondsRemaining` to `expiresAt` minus `now` in seconds, negative once the expiry has passed.
- **status-no-login**: `status` MUST leave `expiresAt`, `refreshExpiresAt` and `secondsRemaining` absent when `oauth` is nil or carries no expiry.
- **status-secret-free**: A status MUST NOT contain an access token or a refresh token.

### Refresher injection

- **refresher-injectable**: `evaluate` and `renew` MUST accept the refresh operation as a parameter of type `Refresher` (a `Sendable` async throwing function from login to login), defaulting to `liveRefresher`.
- **live-refresher**: `liveRefresher` MUST perform the refresh through `ClaudeTokenRefresher.refresh`, the one network operation this ingredient can trigger.

### Token usability (`ClaudeTokenRefresher.isAccessTokenUsable(_:now:margin:)`)

- **usable-unknown-expiry**: `isAccessTokenUsable` MUST return true for a login with no `expiresAt`.
- **usable-threshold**: `isAccessTokenUsable` MUST return true exactly when the expiry in epoch seconds minus `now` is strictly greater than the larger of 300 seconds and `margin` (absent counts as 0).
- **usable-margin-widens-only**: A `margin` below 300 seconds MUST NOT narrow the threshold below 300 seconds.

### Token exchange (`ClaudeTokenRefresher.refresh(_:now:)`)

- **exchange-endpoint**: `refresh` MUST send exactly one `POST` to `https://platform.claude.com/v1/oauth/token` per call, with no retry.
- **exchange-headers**: The request MUST carry `content-type: application/json`, `accept: application/json`, `anthropic-beta: oauth-2025-04-20` and `user-agent: Stenographer (macOS)`.
- **exchange-body**: The request body MUST be a JSON object with `grant_type` `refresh_token`, `refresh_token` set to the login's refresh token, and `client_id` `9d1c250a-e61b-44d9-88ed-5944d1962f5e`.
- **exchange-timeout**: The request MUST time out after 15 seconds.
- **exchange-unsent**: A transport error whose code proves the request never left the machine (see never-sent-codes) MUST throw `.unsent` carrying the error's localized description.
- **exchange-transport-other**: Any other transport error, including a timeout, a dropped connection or a cancellation, MUST throw `.inconclusive` carrying the error's localized description.
- **exchange-no-status**: A response that is not an HTTP response MUST throw `.inconclusive("the token endpoint answered with no status")`.
- **exchange-refusal**: A non-2xx status MUST throw the error `refusal(status:body:)` returns for it.
- **exchange-missing-access-token**: A 2xx reply whose body is not a JSON object, or carries no non-empty string `access_token`, MUST throw `.inconclusive("the token endpoint returned no access token")`.
- **exchange-success**: A 2xx reply with a non-empty `access_token` MUST return `rotated(_:with:accessToken:now:)` of the stored login, the reply body and that token.
- **never-sent-codes**: `neverSent` MUST return true for exactly `notConnectedToInternet`, `cannotFindHost`, `cannotConnectToHost`, `dnsLookupFailed`, `internationalRoamingOff` and `dataNotAllowed`, and false for every other code (including `timedOut` and `networkConnectionLost`).

### Refusal classification (`ClaudeTokenRefresher.refusal(status:body:)`)

- **refusal-2xx**: `refusal` MUST return nil for any status from 200 to 299.
- **refusal-429**: `refusal` MUST return `.rateLimited` for status 429.
- **refusal-401**: `refusal` MUST return `.spent` for status 401, whatever the body.
- **refusal-400-invalid-grant**: `refusal` MUST return `.spent` for status 400 only when the body is a JSON object whose `error` is the string `invalid_grant`.
- **refusal-other**: `refusal` MUST return `.inconclusive("HTTP <status>")` for every other status, including a 400 with any other or no OAuth error, 403, 408 and every 5xx.

### Rotation fold (`ClaudeTokenRefresher.rotated(_:with:accessToken:now:)`)

- **fold-access-token**: The result MUST carry the given access token.
- **fold-refresh-token**: The result MUST carry the body's `refresh_token` when it is a non-empty string, and the stored refresh token otherwise.
- **fold-expiry**: The result's `expiresAt` MUST be `(now + expires_in) * 1000` in epoch milliseconds, where `expires_in` is the body's numeric value or 28 800 seconds (8 hours) when it is absent or not a number.
- **fold-refresh-expiry**: The result's `refreshTokenExpiresAt` MUST be `(now + refresh_token_expires_in) * 1000` when the body carries that number, and the stored value otherwise.
- **fold-scopes**: The result's `scopes` MUST be the body's `scope` split on spaces when it is a non-empty string, and the stored scopes otherwise.
- **fold-carry-forward**: Every other field of the stored login (for example `subscriptionType` and `rateLimitTier`) MUST be carried forward unchanged.

### Refresh errors (`ClaudeOAuthRefreshError`)

- **error-untouched**: `leftTokenUntouched` MUST be true for `.rateLimited` and `.unsent`, and false for `.spent` and `.inconclusive`.
- **error-short-text**: `shortText` MUST be `login spent elsewhere — save it again` for `.spent`, `rate limited — not a credential problem` for `.rateLimited`, and the carried reason shortened to 60 characters for `.inconclusive` and `.unsent`.
- **error-description**: `errorDescription` MUST be a full English sentence per case, and for `.inconclusive` and `.unsent` MUST read `Couldn't refresh this saved login: <reason>`.

### Fingerprint digest and lookup (`AccountFingerprints`)

- **fingerprint-digest**: `fingerprint(of:)` MUST return the SHA-256 of the token's UTF-8 bytes as 64 lowercase hex characters, the same for the same token on every call.
- **fingerprint-default-path**: `defaultPath` MUST be `account-fingerprints.json` inside `StenographerPaths().supportDirectory`, resolved at each access.
- **lookup-empty-token**: `accountName(forToken:atPath:)` MUST return `""` for a nil or empty token without touching the filesystem.
- **lookup-hit**: `accountName(forToken:atPath:)` MUST return the account the file maps the token's fingerprint to.
- **lookup-miss**: `accountName(forToken:atPath:)` MUST return `""` when the file is missing, unreadable, unparseable or holds no entry for the fingerprint, and MUST NOT throw.

### Fingerprints file format (`parse`, `entries`)

- **parse-shape**: `parse` MUST read a JSON object whose `tokens` member is an object of fingerprint to entry object, and return fingerprint to the entry's `account`.
- **parse-skip-invalid**: `parse` MUST skip an entry that is not an object, has no string `account`, or has an empty `account`, and keep the rest.
- **parse-garbage**: `parse` MUST return an empty map for empty data, non-JSON, a non-object root, or a root without a `tokens` object.
- **parse-version-ignored**: `parse` MUST NOT read or check the `version` member.
- **entries-seen-default**: `entries` MUST apply parse-skip-invalid and MUST give an entry whose `seen` is absent or not a number a `seen` of 0.
- **entries-order**: `entries` MUST return entries newest `seen` first, ties broken by fingerprint in ascending order.

### Merge (`AccountFingerprints.merge(into:_:now:)`)

- **merge-stamp-fresh**: Every fingerprint in `fresh` MUST appear in the result with its account and `seen` equal to `now`.
- **merge-restamp**: A fingerprint present in both `existing` and `fresh` MUST appear once, re-stamped with `now`.
- **merge-reassign**: A fingerprint present in `existing` under one account and in `fresh` under another MUST appear once, under the `fresh` account.
- **merge-cap-per-account**: The result MUST keep at most `historyPerAccount` (8) fingerprints per account, counting each account separately.
- **merge-trim-oldest**: When an account has more than 8, the result MUST keep its 8 newest by `seen` (ties by ascending fingerprint) and drop the rest.
- **merge-order**: The result MUST be ordered newest `seen` first, ties by ascending fingerprint.

### Publish (`AccountFingerprints.publish(_:atPath:now:)`)

- **publish-digest-keys**: The caller MUST pass fingerprints, not tokens, as the keys of `fresh`; `publish` writes the keys as given and hashes nothing.
- **publish-create-directory**: `publish` MUST create the file's parent directory, with intermediates, when it is missing.
- **publish-merge**: `publish` MUST write the merge of the file's current entries with `fresh` at `now`, never `fresh` alone.
- **publish-format**: `publish` MUST write a pretty-printed JSON object with sorted keys, `version` 1 and `tokens` mapping each fingerprint to `{"account": <name>, "seen": <epoch seconds>}`.
- **publish-atomic**: `publish` MUST replace the file atomically, so a concurrent reader sees either the old file or the new one.
- **publish-permissions**: `publish` MUST set the file's POSIX permissions to 0600 after writing.
- **publish-permissions-failure**: NEEDS REVIEW: Not implemented in source. A failure to set 0600 is discarded with `try?`, so the file can stay at the atomic write's default mode with no error, log or return value; settled by the toolkit owner deciding whether that failure throws or logs, plus a test with a read-only parent.
- **publish-throws**: `publish` MUST throw when creating the directory, serializing the JSON or writing the file fails.

### Read cache (`AccountFingerprints` lookups)

- **cache-reuse**: A lookup MUST reuse the previously parsed map while the path is the same and the symlink-resolved file's modification date and size are both unchanged.
- **cache-invalidate**: A lookup MUST re-read and re-parse the file when the path differs from the cached one or the resolved file's modification date or size changed.
- **cache-single-slot**: The cache MUST hold one path at a time, process-wide.
- **cache-serialized**: Cache reads and refills MUST be serialized by one lock, so concurrent lookups from any thread never observe a half-updated cache.

