---
id: a2cb25cc-f3d1-4b82-8a32-52e727c317e1
title: "Claude Auth Evaluator"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Judges saved Claude credentials, refreshes expired logins at Claude Code's token endpoint, and maps token digests to the accounts they bill."
platforms:
  - swift
  - macos
tags:
  - foundation
  - claude-auth
  - oauth
  - credentials
depends-on:
  - 2b552bde-d0bd-425a-9e79-fc624b52f516
  - 0de17653-f56d-418f-b212-33e9017972cd
  - 81fb66c5-e31d-4817-ba36-5ccace191e8f
  - b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43
  - 3f1efb26-3dfb-4e6c-bbbc-32609151ce78
  - 94bac7a5-3fc6-463d-86d1-7c59350cd7cb
related: []
references: []
approved-by: ""
approved-date: ""
---

# Claude Auth Evaluator

## Overview

This ingredient is the toolkit's Claude-token judgment layer, three static namespaces (caseless Swift `enum`s) in Core's `ClaudeAuth` folder:

- **`ClaudeAuthEvaluator`** decides what each saved Claude credential's token is worth and mints a fresh one when it is worth nothing. It answers three questions in one place: is this access token still good, is it close enough to expiry that a probe started now would arrive after it died, and when a refresh fails, is that a dead login, a rate limit or an inconclusive answer. It also offers `renew`, which spends one login's refresh token unconditionally, for the moment a saved login is about to be installed as Claude Code's own.
- **`ClaudeTokenRefresher`** is the one HTTP exchange: it spends a login's single-use refresh token at Claude Code's OAuth token endpoint and folds the reply into the stored login. Its failures are the typed `ClaudeOAuthRefreshError`, whose four cases tell a caller whether the login is dead, rate-limited, unknown or certainly untouched. Its source comment names `ClaudeAuthEvaluator` as its one caller.
- **`AccountFingerprints`** answers "which account does this `CLAUDE_CODE_OAUTH_TOKEN` belong to" without any reader holding a token. The app, which owns the keychain items, publishes a JSON map of SHA-256(token) to account name; the daemon and the CLI hash the token they were given and look the digest up. A miss is an answer (`""`), not a failure: attribution falls back elsewhere.

The evaluator is used by a daemon that measures account quota (`AccountQuotaProbe`). The app pushes the whole login in (refresh token included) as `Sessions.ClaudeCredentialDTO` values; the evaluator classifies each one, spends refresh tokens where needed, and returns an `Outcome` carrying the credentials worth probing, every rotated login (which the caller MUST hand back to the app) and a secret-free status per credential. Custody does not move: nothing here reads or writes the keychain, the evaluator never persists anything and never refreshes on a timer of its own. A rotation is produced only inside a call the app made, so the process that can store it always receives it.

The terms used throughout: a **credential** is one `Sessions.ClaudeCredentialDTO` ([adhsdk.ingredient.foundation.sessions.wire.status-line-dt-os](cookbook:94bac7a5-3fc6-463d-86d1-7c59350cd7cb)); a **login** is its `ClaudeOAuthCredential` (the `oauth` field, see [adhsdk.ingredient.foundation.claude-accounts.claude-o-auth-credential](cookbook:2b552bde-d0bd-425a-9e79-fc624b52f516)); a **rotation** is a `Sessions.ClaudeRotatedCredentialDTO` and a **status** a `Sessions.ClaudeAccountTokenStatusDTO` (both in [adhsdk.ingredient.foundation.sessions.wire.claude-account-request-dt-os](cookbook:3f1efb26-3dfb-4e6c-bbbc-32609151ce78)); a **round** is one call to `evaluate`; a **fingerprint** is the lowercase hex SHA-256 of a token; the **fingerprints file** is `account-fingerprints.json`.

## Behavioral Requirements

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
- **refresh-once-per-token**: Within one `evaluate` call, the refresher MUST be invoked at most once per distinct refresh token. Credentials carrying the same refresh token (one login pushed under several item keys) MUST share that one refresh's result: on success each is reported `.refreshed`, each gets its own `Outcome.rotated` entry under its own `itemKey` with the same fresh login, and none is reported `.spent`; on failure each is reported with the same failure state.
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
- **publish-permissions**: `publish` MUST write the new contents to a temporary file beside the target, set that file's POSIX permissions to 0600, and only then rename it over the target, so the published file is never readable by others, even for a moment.
- **publish-permissions-failure**: When setting 0600 fails, `publish` MUST throw that error, MUST leave the previous file (or no file, on a first publish) exactly as it was, and MUST remove its temporary file, so a file readable by others is never published and nothing is left behind.
- **publish-throws**: `publish` MUST throw when creating the directory, serializing the JSON or writing the file fails.

### Read cache (`AccountFingerprints` lookups)

- **cache-reuse**: A lookup MUST reuse the previously parsed map while the path is the same and the symlink-resolved file's modification date and size are both unchanged.
- **cache-invalidate**: A lookup MUST re-read and re-parse the file when the path differs from the cached one or the resolved file's modification date or size changed.
- **cache-single-slot**: The cache MUST hold one path at a time, process-wide.
- **cache-serialized**: Cache reads and refills MUST be serialized by one lock, so concurrent lookups from any thread never observe a half-updated cache.

## Appearance

Not applicable — this is a token-evaluation, token-exchange and fingerprint-lookup library of static functions, not a visual component.

## States

Not applicable — this is a token-evaluation library, not a visual component; the per-credential token states are listed under Behavioral Requirements.

## Accessibility

Not applicable — this is a token-evaluation library, not a visual component.

## Conformance Test Vectors

Rows 057 to 062 are tested beside the toolkit copy, in `Tests/AgenticDeveloperHubSDKCoreTests/ClaudeAuth/ClaudeAuthEvaluatorDuplicateLoginTests.swift` and `FingerprintsPublishModeTests.swift`. Other rows marked with a test name are derived from Stenographer's `Apple/Stenographer/stenographerd/Tests/ClaudeTokenEvaluatorTests.swift` (which tests `ClaudeTokenEvaluator` and `ClaudeOAuthRefresher`, the predecessors of `ClaudeAuthEvaluator` and `ClaudeTokenRefresher`, moved with only imports, access modifiers, type names, `Sessions.` qualification and a public `Outcome` initializer changed) and `AccountFingerprintsTests.swift` beside it (testing an `AccountFingerprints` whose logic is identical; only imports, access modifiers, a public `Entry` initializer and one doc paragraph differ); `AccountQuotaObserveTests` in the toolkit exercises `publish` and `accountName` through `CredentialFence`. Evaluator rows use `now` = epoch 1 700 000 000 and an injected refresher; none may use `liveRefresher`. "Login(n)" is a credential for `a@example.com` with kind `oauth`, `itemKey` `oauth:a@example.com`, token `access-0`, refresh token `refresh-0` and an access expiry `n` seconds after `now`. Fingerprint rows use a fresh temporary path per test.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-auth-evaluator-001 | classify-without-login | `state(of:)` a credential with kind `long_lived`, a token and no login (`testLongLivedCredentialIsUnknownRatherThanExpired`). | `.unknown`. |
| claude-auth-evaluator-002 | classify-without-expiry | `state(of:)` a login with no `expiresAt` (`testLoginWithNoExpiryIsUnknownRatherThanExpired`). | `.unknown`. |
| claude-auth-evaluator-003 | classify-expired, classify-usable, effective-margin | `state(of:)` Login(240), then Login(3600) (`testLoginInsideTheRefreshMarginCountsAsExpired`). | `.expired`, then `.usable`. |
| claude-auth-evaluator-004 | classify-expired, effective-margin | `state(of:)` Login(300). | `.expired` (300 is not strictly greater than the 300-second margin). |
| claude-auth-evaluator-005 | effective-margin | `state(of:)` Login(3600) with `refreshWithin` 7200; then Login(3600) with `refreshWithin` 60. | `.expired`; then `.usable`. |
| claude-auth-evaluator-006 | unrefreshed-probeability, unrefreshed-status, refresh-precondition | `evaluate([Login(3600)])` with a counting refresher (`testUsableLoginIsProbedWithoutSpendingARefreshToken`). | Refresher called 0 times; probeable tokens `["access-0"]`; rotated empty; statuses `[.usable]` with no `detail`. |
| claude-auth-evaluator-007 | refresh-success-probe, refresh-success-rotation, refresh-success-status, every-rotation-returned, refresh-at-most-once, refresher-injectable | `evaluate([Login(60)])`; a counting refresher returns `access-1`/`refresh-1` expiring 8 h after `now` (`testExpiredLoginIsRefreshedAndTheRotationComesBack`). | Refresher called once; probeable tokens `["access-1"]`; one rotation with `itemKey` `oauth:a@example.com`, account `a@example.com`, refresh token `refresh-1`; statuses `[.refreshed]`. |
| claude-auth-evaluator-008 | classify-only-mode, unrefreshed-probeability | `evaluate([Login(60)], refresh: nil)` (`testRefreshWithNoRefresherClassifiesWithoutSpendingOne`). | Probeable empty; rotated empty; statuses `[.expired]`. |
| claude-auth-evaluator-009 | refusal-mapping, refusal-probeability, refusal-detail, refresh-failure-log, round-never-throws | `evaluate([Login(60)])`; refresher throws `.spent` (`testSpentRefreshTokenIsNotProbedWith`). | Returns without throwing; probeable empty; rotated empty; statuses `[.spent]` with detail `login spent elsewhere — save it again`; one error log line containing `a@example.com` and that detail. |
| claude-auth-evaluator-010 | refusal-mapping, refusal-probeability, status-state | `evaluate([Login(60)])`; refresher throws `.rateLimited` (`testRateLimitedRefreshKeepsTheCredentialProbeable`). | One probeable credential (token `access-0`); statuses `[.rateLimited]`, raw value `rate_limited`. |
| claude-auth-evaluator-011 | refusal-mapping, refusal-detail | `evaluate([Login(60)])`; refresher throws `.unsent("offline")`. | One probeable credential; status `.inconclusive` with detail `offline`; rotated empty. |
| claude-auth-evaluator-012 | foreign-error-inconclusive | `evaluate([Login(60)])`; refresher throws an error that is not a `ClaudeOAuthRefreshError` (`testAnUnrecognizedFailureIsInconclusiveAndStillProbed`). | One probeable credential; statuses `[.inconclusive]`; detail at most 60 characters (a longer description is cut to 57 characters plus an ellipsis). |
| claude-auth-evaluator-013 | round-failure-isolated, round-order | `evaluate([dead@ Login(60), live@ Login(3600)])`; refresher throws `.spent` (`testOneDeadLoginDoesNotStopTheRest`). | Probeable accounts `["live@example.com"]`; status accounts `["dead@example.com", "live@example.com"]`; states `[.spent, .usable]`. |
| claude-auth-evaluator-014 | missing-item-key-refusal, missing-item-key-log | `evaluate` one Login(60) with no `itemKey` and a counting refresher (`testACredentialWithNoItemKeyIsNeverRefreshed`). | Refresher called 0 times; probeable empty; rotated empty; statuses `[.expired]`; one error log line naming the account. |
| claude-auth-evaluator-015 | round-order, round-status-per-credential | `evaluate` eight usable logins `a0@`…`a7@`, `refresh: nil` (`testTheRoundAnswersInTheOrderItWasAsked`). | Status and probeable accounts both equal the input accounts in input order; 8 statuses. |
| claude-auth-evaluator-016 | round-concurrent | `evaluate` four Login(60) credentials with distinct item keys; each refresher call waits on a shared latch that opens only once all four calls have started, then succeeds. | Returns (a sequential round would deadlock on the latch); four rotations, in input order. |
| claude-auth-evaluator-017 | status-countdown, status-expiry-seconds | `status(Login(3600), state: .usable, oauth: its login, now:)`, then `counting(from: now + 600)` (`testStatusCountsDownAgainstTheReadingTime`). | `secondsRemaining` 3600, then 3000; state still `.usable`; `expiresAt` = 1 700 003 600. |
| claude-auth-evaluator-018 | status-no-login, status-identity | `status` of a `long_lived` credential with `itemKey` `long_lived:a@example.com`, state `.unknown`, `oauth: nil`. | `expiresAt`, `refreshExpiresAt`, `secondsRemaining` absent; account, kind and item key copied. |
| claude-auth-evaluator-019 | renew-unconditional, renew-success | `renew(Login(3600).oauth)`; counting refresher returns `access-1`/`refresh-1` (`testRenewalSpendsTheTokenEvenWhenTheAccessTokenIsStillGood`). | Refresher called once; state `.refreshed`; `oauth.refreshToken` `refresh-1`; `tokenUntouched` false. |
| claude-auth-evaluator-020 | renew-refusal, renew-never-throws, renew-failure-log | `renew(Login(60).oauth)`; refresher throws `.spent` (`testRenewalOfASpentLoginSaysSoAndCarriesNoCredential`). | Returns without throwing; state `.spent`; `oauth` absent; detail `login spent elsewhere — save it again`; one error log line `token-evaluator: can't renew a login: login spent elsewhere — save it again`, with no account in it. |
| claude-auth-evaluator-021 | renew-refusal, renew-foreign-error | `renew` with a refresher throwing `.rateLimited`, then one throwing a raw `URLError(.notConnectedToInternet)` (`testRenewalThatProvesNothingIsNotReportedSpent`). | `.rateLimited` and `.inconclusive`; `oauth` absent in both; the raw `URLError` gives `tokenUntouched` false. |
| claude-auth-evaluator-022 | renew-refusal, error-untouched | `renew` with refreshers throwing `.rateLimited`, `.unsent("offline")`, `.inconclusive("HTTP 502")`, `.spent` (`testRenewalSaysWhetherTheTokenIsCertainlyUntouched`). | `tokenUntouched` true, true, false, false; the `.unsent` case has state `.inconclusive`. |
| claude-auth-evaluator-023 | failure-status-expiry | `evaluate([Login(60)])`; refresher throws `.inconclusive("HTTP 502")`. | Status `expiresAt` = 1 700 000 060 and `secondsRemaining` 60, from the original login. |
| claude-auth-evaluator-024 | refresh-success-probe | `evaluate([Login(60) with refreshWithin 3600])`; refresher succeeds. | The probeable credential has no `refreshWithin`. |
| claude-auth-evaluator-025 | classify-states-only, classify-offline | `state(of:)` each of: a no-login credential, a login with no expiry, Login(60), Login(3600), with networking disabled. | `.unknown`, `.unknown`, `.expired`, `.usable`; no request attempted. |
| claude-auth-evaluator-026 | live-refresher, exchange-endpoint, exchange-body, exchange-refusal, refusal-401 | Call `liveRefresher` with Login(60).oauth while a URL protocol stub answers the token endpoint with HTTP 401. | Throws `.spent`; the stub saw one POST to `https://platform.claude.com/v1/oauth/token` carrying `grant_type` `refresh_token`, `refresh_token` `refresh-0` and `client_id` `9d1c250a-e61b-44d9-88ed-5944d1962f5e`. |
| claude-auth-evaluator-027 | round-single-now | `evaluate([Login(3600), Login(7200) for b@])` with the fixed `now`, `refresh: nil`. | `secondsRemaining` exactly 3600 and 7200. |
| claude-auth-evaluator-028 | status-secret-free | JSON-encode every status from vector 007. | The JSON contains none of `access-0`, `refresh-0`, `access-1`, `refresh-1`. |
| claude-auth-evaluator-029 | no-self-scheduled-refresh | After vector 007 returns, drain the main and global queues once and read the counting refresher. | The count is still 1; nothing was scheduled. |
| claude-auth-evaluator-030 | refusal-2xx, refusal-401, refusal-400-invalid-grant, refusal-429, refusal-other | `refusal(status:body:)` for 200; 401; 400 with `{"error":"invalid_grant"}`; 400 with `{"error":"invalid_request"}`; 403; 408; 503; 429 (`testOnlyARefusedGrantIsSpent`). | nil; `.spent`; `.spent`; `.inconclusive("HTTP 400")`; `.inconclusive("HTTP 403")`; `.inconclusive("HTTP 408")`; `.inconclusive("HTTP 503")`; `.rateLimited`. |
| claude-auth-evaluator-031 | never-sent-codes | `neverSent` for `notConnectedToInternet`, `cannotFindHost`, `cannotConnectToHost`, `timedOut`, `networkConnectionLost` (`testOnlyAConnectFailureProvesTheRequestNeverLeft`). | true, true, true, false, false. |
| claude-auth-evaluator-032 | exchange-unsent, exchange-transport-other | Stub the session to fail with `URLError(.dnsLookupFailed)`, then with `URLError(.timedOut)`. | Throws `.unsent(...)`, then `.inconclusive(...)`, each carrying the error's localized description. |
| claude-auth-evaluator-033 | exchange-headers, exchange-timeout | Capture the request `refresh` sends. | Headers `content-type` and `accept` `application/json`, `anthropic-beta` `oauth-2025-04-20`, `user-agent` `Stenographer (macOS)`; timeout interval 15 s. |
| claude-auth-evaluator-034 | exchange-missing-access-token | Stub a 200 with body `{"token_type":"bearer"}`, then a 200 with `{"access_token":""}`. | Both throw `.inconclusive("the token endpoint returned no access token")`. |
| claude-auth-evaluator-035 | exchange-success, fold-access-token, fold-refresh-token, fold-expiry, fold-refresh-expiry, fold-scopes | `rotated(login, with: {"refresh_token":"r2","expires_in":3600,"refresh_token_expires_in":86400,"scope":"user:inference user:profile"}, accessToken: "a2", now: 1 700 000 000)`. | `accessToken` `a2`; `refreshToken` `r2`; `expiresAt` 1 700 003 600 000; `refreshTokenExpiresAt` 1 700 086 400 000; `scopes` `["user:inference", "user:profile"]`. |
| claude-auth-evaluator-036 | fold-refresh-token, fold-expiry, fold-refresh-expiry, fold-scopes, fold-carry-forward | `rotated` of a login with refresh token `r1`, `refreshTokenExpiresAt` 5, scopes `["x"]`, `subscriptionType` `max`, with body `{"refresh_token":""}`, access token `a2`, `now` 1 700 000 000. | `refreshToken` `r1`; `expiresAt` 1 700 028 800 000 (8 h assumed); `refreshTokenExpiresAt` 5; scopes `["x"]`; `subscriptionType` `max`. |
| claude-auth-evaluator-037 | usable-unknown-expiry, usable-threshold, usable-margin-widens-only | `isAccessTokenUsable` for: no expiry; 301 s left, no margin; 300 s left; 600 s left with margin 900; 600 s left with margin 60. | true; true; false; false; true. |
| claude-auth-evaluator-038 | error-short-text, error-description | `shortText` and `errorDescription` of `.rateLimited` and `.inconclusive("HTTP 502")`. | `rate limited — not a credential problem` / `Anthropic rate-limited the token refresh. The saved login is fine; this will work again shortly.`; `HTTP 502` / `Couldn't refresh this saved login: HTTP 502`. |
| claude-auth-evaluator-039 | fingerprint-digest | `fingerprint(of: "tok-a")` twice and `fingerprint(of: "tok-b")` (`testTheFingerprintIsSHA256HexAndIsNotTheToken`). | 64 characters, not containing `tok-a`, equal across calls, different from the `tok-b` digest. |
| claude-auth-evaluator-040 | lookup-hit, publish-merge | Publish `{fp("tok-a"): "a@x.com"}`; look up `tok-a` (`testAPublishedTokenResolvesToItsAccount`). | `a@x.com`. |
| claude-auth-evaluator-041 | lookup-miss | Publish `{fp("tok-a"): "a@x.com"}`; look up `tok-b`; look up `tok-a` at `/no/such/file.json` (`testAnUnknownTokenResolvesToNothing`, `testAMissingFileResolvesToNothingRatherThanThrowing`). | `""`, `""`, no throw. |
| claude-auth-evaluator-042 | lookup-empty-token | Publish `{fp("tok-a"): "a@x.com"}`; look up `nil` and `""` (`testNoTokenResolvesToNothing`); then publish `{fp(""): "a@x.com"}` and look up `""`. | `""` in every case, even when the empty token's digest is in the file. (The toolkit's `testFenceRejectsAnEmptyToken` publishes the same file but asserts through `CredentialFence.owns("")`, which rejects the empty token with its own guard before calling `accountName`.) |
| claude-auth-evaluator-043 | publish-digest-keys, publish-format | Publish `{fp("super-secret-token"): "a@x.com"}`; read the file as text (`testThePublishedFileDoesNotContainTheToken`). | The text contains `a@x.com` and does not contain `super-secret-token`; it has `"version" : 1` and a `tokens` object. |
| claude-auth-evaluator-044 | publish-permissions, publish-create-directory | Publish into a missing directory, then read the file's attributes (`testThePublishedFileIsOwnerReadableOnly`). | The directory exists; `posixPermissions` is 0o600. |
| claude-auth-evaluator-045 | parse-shape, parse-skip-invalid | `parse` of `{"version":1,"tokens":{"aa":{"account":"a@x.com","seen":1},"bb":{"account":"","seen":2},"cc":{"seen":3},"dd":"not-an-object"}}` (`testParseSkipsEntriesItCannotUse`). | `["aa": "a@x.com"]`. |
| claude-auth-evaluator-046 | parse-garbage, parse-version-ignored | `parse` of empty data, `not json`, `[1,2]`, `{"version":1}`; then `{"version":99,"tokens":{"aa":{"account":"a"}}}` (`testParseToleratesGarbage`). | Empty four times; then `["aa": "a"]`. |
| claude-auth-evaluator-047 | publish-merge | Publish `{fp("old"): "a@x.com"}`, then `{fp("new"): "a@x.com"}`; look up both (`testPublishKeepsFingerprintsAnEarlierRoundRecorded`). | Both resolve to `a@x.com`. |
| claude-auth-evaluator-048 | merge-cap-per-account, merge-trim-oldest, merge-order | `merge` 12 entries `d0`…`d11` for `a@x.com` with `seen` 0…11, `fresh` empty, `now` 1000 (`testMergeTrimsAnAccountToItsNewestHistory`). | 8 entries; first is `d11`; `d0` absent. |
| claude-auth-evaluator-049 | merge-cap-per-account | `merge` 11 entries for `a@x.com` and one `b0` for `b@x.com` with `seen` 0 (`testMergeCountsTheHistoryPerAccount`). | 8 for `a@x.com`, 1 for `b@x.com`. |
| claude-auth-evaluator-050 | merge-restamp, merge-stamp-fresh | `merge` `[aa/a@x.com/1]` with `{"aa": "a@x.com"}` at 500 (`testMergeRestampsAFingerprintItAlreadyHeld`). | One entry, `seen` 500. |
| claude-auth-evaluator-051 | merge-reassign | `merge` `[aa/a@x.com/1]` with `{"aa": "b@x.com"}` at 500 (`testMergeTakesTheNewestClaimOnADigest`). | Exactly `[aa/b@x.com/500]`. |
| claude-auth-evaluator-052 | cache-reuse, cache-invalidate | Publish `{fp("tok-a"): "a@x.com"}`, look up; publish `{fp("tok-a"): "bbbbbb@x.com"}`, look up (`testARepublishIsPickedUpDespiteTheCache`). | `a@x.com`, then `bbbbbb@x.com`. |
| claude-auth-evaluator-053 | entries-seen-default, entries-order | `entries` of `{"tokens":{"b":{"account":"x","seen":5},"a":{"account":"x","seen":5},"c":{"account":"y"}}}`. | `[a/x/5, b/x/5, c/y/0]`. |
| claude-auth-evaluator-054 | fingerprint-default-path | Compare `defaultPath` with `StenographerPaths().supportDirectory` joined with `account-fingerprints.json`. | Equal. |
| claude-auth-evaluator-055 | publish-throws | Publish to a path whose parent is an existing regular file. | `publish` throws; no fingerprints file is created. |
| claude-auth-evaluator-056 | cache-serialized, cache-single-slot | From 8 threads, look up tokens alternately at two different paths 1 000 times each while another thread republishes one of them. | No crash; every answer equals what the file at that path held when it was read. |
| claude-auth-evaluator-057 | refresh-once-per-token, refresh-success-rotation | One expired login (refresh token `shared-refresh`) pushed under item keys `oauth:a@x.com` and `claude-code:a@x.com`; a refresher that answers `.spent` for a refresh token it has already rotated (`testOneLoginUnderTwoItemKeysIsRefreshedOnceAndBothItemsAreRotated`). | One refresher call; both states `refreshed`; `rotated` holds both item keys with the same fresh refresh token; two `probeable`. |
| claude-auth-evaluator-058 | refresh-once-per-token | Two expired logins with different refresh tokens (`testDifferentLoginsAreEachRefreshed`). | Two refresher calls; both `refreshed`. |
| claude-auth-evaluator-059 | refresh-once-per-token | One expired login under two item keys; a refresher that throws `rateLimited` (`testAFailedSharedRefreshIsReportedTheSameForEveryCopy`). | Both states `rate_limited`; `rotated` is empty. |
| claude-auth-evaluator-060 | publish-permissions | Publish one entry (`testPublishedFileIsOwnerOnly`). | The file's mode is 0600. |
| claude-auth-evaluator-061 | publish-permissions-failure | Publish once, then publish again with setting the mode failing (`testAFailureToSetTheModeThrowsAndKeepsThePreviousFile`). | The second `publish` throws; the file's bytes are the first publish's; the directory holds only `account-fingerprints.json`. |
| claude-auth-evaluator-062 | publish-permissions-failure | A first publish with setting the mode failing (`testAFailureToSetTheModeOnAFirstPublishLeavesNoFile`). | Throws; no fingerprints file and no temporary file exist. |

## Edge Cases

- **empty-round**: `evaluate([])` MUST return an `Outcome` with empty `probeable`, `rotated` and `statuses`, and MUST invoke no refresher.
- **no-login-credential**: A credential with no `oauth` MUST be classified `.unknown`, MUST appear in `probeable`, and MUST never be refreshed, even with a refresher supplied.
- **expiry-zero-or-past**: An `expiresAt` of 0, or any expiry already past, MUST classify as `.expired` with a negative `secondsRemaining`.
- **expiry-exactly-at-margin**: An access token with exactly 300 seconds left (or exactly `refreshWithin` seconds when that is larger) MUST classify as `.expired`; the comparison is strict.
- **empty-refresh-token-content**: An expired login whose `refreshToken` is an empty string MUST still be passed to the refresher when every refresh-precondition holds; nothing validates token content, and the endpoint's answer decides the state.
- **missing-item-key**: An expired login with no `itemKey` MUST NOT be refreshed and MUST be reported `.expired`. When `refresh` is also `nil`, it MUST be reported `.expired` without the log line, because the classify-only path is taken first.
- **refresher-network-failure**: With `liveRefresher`, a request that never left the machine MUST arrive as `.unsent` and be reported `.inconclusive` and probeable; a timeout or dropped connection MUST arrive as `.inconclusive` and be reported the same way. Nothing retries within the round or the call; the next call is the only retry.
- **refresher-timeout**: The evaluator MUST impose no timeout of its own; with `liveRefresher` each refresh is bounded by the 15-second request timeout, and because judgments run concurrently a round is bounded by roughly one such timeout.
- **raw-transport-error-from-injected-refresher**: An injected refresher that throws a bare `URLError`, even one proving the request never left, MUST be treated as a foreign error: `.inconclusive`, and in `renew` `tokenUntouched` false. Only `ClaudeTokenRefresher.refresh` translates transport errors into `.unsent`.
- **caller-abandons-round**: When the caller stops waiting, rotations already produced MUST still be in the returned `Outcome`, but a caller that never reads it loses them; there is no other route back. The evaluator MUST NOT check task cancellation itself; a cancellation reaches the live refresher as a `URLError` that is not in never-sent-codes, so it is reported `.inconclusive` with the token possibly spent.
- **concurrent-rounds**: Nothing here MUST serialize separate calls to `evaluate` or `renew`; two calls judging the same expired login would each spend its refresh token. Serializing rounds is the caller's job, and `AccountQuotaProbe` does it with a `SerialAsyncGate` around `takeCredentials`.
- **duplicate-login-in-one-round**: Two credentials in one `evaluate` call carrying the same refresh token MUST NOT spend it twice: the refresher runs once and both share its result (`refresh-once-per-token`), so neither copy is reported `.spent` by the other's rotation and both item keys receive the fresh login. Two separate `evaluate` calls are still the caller's to serialize (`concurrent-rounds`).
- **unknown-state-from-older-client**: Statuses store state as a raw string so an older reader decodes unknown future states as `.unknown` (`ClaudeAccountTokenStatusDTO.tokenState`); this ingredient MUST only emit the seven states `Sessions.ClaudeTokenState` defines.
- **offline**: When the machine is offline, every expired login in a round MUST be reported `.inconclusive` and kept probeable; usable and unknown logins MUST be unaffected because classification does no I/O.
- **redirect-or-informational-status**: A final status outside 2xx that is not 401, 429 or a 400 naming `invalid_grant` (for example an unfollowed 3xx) MUST be reported `.inconclusive("HTTP <status>")`.
- **400-without-json-body**: A 400 whose body is empty or not JSON MUST be `.inconclusive("HTTP 400")`, never `.spent`.
- **expires-in-not-a-number**: An `expires_in` that is a string or absent MUST stamp an 8-hour expiry rather than keep the old one, so a fresh token never reads as already stale.
- **scope-with-repeated-spaces**: A `scope` of `"a  b"` MUST yield `["a", "b"]`; empty pieces are dropped by the split.
- **2xx-with-error-body**: A 2xx carrying only an OAuth `error` member and no `access_token` MUST be `.inconclusive("the token endpoint returned no access token")`, though the refresh token may already be spent.
- **fingerprints-corrupt-file**: When the existing fingerprints file is not parseable, `publish` MUST treat it as empty and overwrite it with only the fresh entries; earlier history is lost.
- **fingerprints-account-removed**: No operation removes an account; an account no longer saved MUST keep its up to 8 fingerprints until a later write of the same fingerprint reassigns them.
- **fingerprints-concurrent-writers**: `publish` is an unlocked read-merge-write; two concurrent publishers MUST be expected to lose one side's merge (last writer wins). Its doc comment assigns writing to the app alone, so a single writer is a caller precondition.
- **fingerprints-same-mtime-and-size**: A rewrite that lands with the same modification date and the same byte size as the cached file MUST be expected to serve the stale map until either changes.
- **fingerprints-symlink**: When the path is a symlink, cache validity MUST follow the linked file's attributes, so rewriting the target invalidates the cache.
- **fingerprints-missing-file-cached**: A missing file MUST be cached as an empty map, re-checked on every lookup, and picked up as soon as it appears.
- **fingerprints-non-numeric-seen**: An entry whose `seen` is not a number MUST be kept with `seen` 0, so it is the first trimmed.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `now` (on `state`, `evaluate`, `status`, `refresh`, `rotated`, `isAccessTokenUsable`, `publish`) | `Date` (`Double` on `merge`) | `Date()` at call time | The instant expiries are compared against and fingerprints are stamped with. |
| `refresh` (on `evaluate`) | `Refresher?` | `liveRefresher` | The refresh operation; `nil` selects classify-only mode. |
| `refresh` (on `renew`) | `Refresher` | `liveRefresher` | The refresh operation; not optional. |
| `ClaudeCredentialDTO.refreshWithin` | `Double?` (seconds) | `nil` | Widens the refresh margin for one evaluation. |
| `margin` (on `isAccessTokenUsable`) | `TimeInterval?` | `nil` | Widens the 300-second margin; never narrows it. |
| `ClaudeTokenRefresher.refreshMargin` | `TimeInterval` constant | 300 s | Minimum margin below which an access token counts as expired. |
| `ClaudeTokenRefresher.tokenURL` | `URL` constant | `https://platform.claude.com/v1/oauth/token` | Claude Code's OAuth token endpoint. |
| `ClaudeTokenRefresher.clientID` | `String` constant | `9d1c250a-e61b-44d9-88ed-5944d1962f5e` | Claude Code's OAuth client id. |
| `ClaudeTokenRefresher.beta` | `String` constant | `oauth-2025-04-20` | The `anthropic-beta` header value. |
| `ClaudeTokenRefresher.userAgent` | `String` constant | `Stenographer (macOS)` | Names the client so Cloudflare does not reject it (403, "error code: 1010"); `AccountQuotaProbe` reuses it. |
| Request timeout | private constant | 15 s | Bounds each live refresh. |
| Assumed access life | private constant | 8 h (28 800 s) | Used when the reply omits `expires_in`. |
| `path` (on `accountName`, `publish`) | `String` | `AccountFingerprints.defaultPath` | Fingerprints file location; tests and `CredentialFence` inject their own. |
| `AccountFingerprints.historyPerAccount` | `Int` constant | 8 | Fingerprints kept per account. |
| `detail` length | constant | 60 characters | `String.shortened()` default ([adhsdk.ingredient.foundation.text.short-text](cookbook:0de17653-f56d-418f-b212-33e9017972cd)). |
| Logger subsystem / category | `Loggable` defaults | main bundle identifier / `ClaudeAuthEvaluator` | Where the evaluator's error lines go. |

No environment variable or settings key is read. The fingerprints file's directory comes from `StenographerPaths` ([adhsdk.ingredient.foundation.stenographer.stenographer-identifiers](cookbook:b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43)), which follows the Stenographer instance's data root.

## Deep Linking

Not applicable: nothing here defines a URL scheme, route or navigation destination; these are static functions called by a daemon, a CLI and an app.

## Localization

No string is localized. The `detail` strings put into statuses and renewals, and `ClaudeOAuthRefreshError.errorDescription`, are hardcoded English.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; `ClaudeOAuthRefreshError.shortText`) | `login spent elsewhere — save it again` | `detail` for a `.spent` refusal. |
| (none; `ClaudeOAuthRefreshError.shortText`) | `rate limited — not a credential problem` | `detail` for a `.rateLimited` refusal. |
| (none; the reason the error carries) | e.g. `HTTP 503`, `the token endpoint returned no access token`, `the token endpoint answered with no status` | `detail` for `.inconclusive` / `.unsent`, shortened to 60 characters. |
| (none; `errorDescription`) | `This saved login was spent elsewhere — logging in or refreshing on another machine voids every older copy of its refresh token. Save the account again after a fresh login.` | Full description of `.spent`. |
| (none; `errorDescription`) | `Anthropic rate-limited the token refresh. The saved login is fine; this will work again shortly.` | Full description of `.rateLimited`. |
| (none; `errorDescription`) | `Couldn't refresh this saved login: <reason>` | Full description of `.inconclusive` and `.unsent`. |

## Accessibility Options

Not applicable: nothing here presents UI, so no display option reaches it.

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no UI. |
| Increase Contrast | Not applicable: no UI. |
| Differentiate Without Color | Not applicable: no UI. |

## Feature Flags

Not applicable: no feature flag is read; classify-only mode is chosen per call by passing `nil` as `refresh`.

## Analytics

Not applicable: no analytics call is made.

## Privacy

- **Data collected**: Bearer secrets supplied by the caller (OAuth access tokens, single-use refresh tokens, setup tokens), plus the account email, keychain item key and subscription metadata riding in each login. `AccountFingerprints` handles tokens only long enough to hash them, and stores account names.
- **Storage**: The evaluator and refresher store nothing and keep no state between calls; custody of the stored login stays with the app. The fingerprints file stores SHA-256 digests of tokens and account names (emails) with a `seen` time, in the Stenographer support directory, mode 0600, set on a temporary file before it replaces the old one, so a failure to set it publishes nothing (`publish-permissions-failure`). A digest does not reverse to the token. The read cache keeps the parsed map in process memory.
- **Transmission**: `ClaudeTokenRefresher.refresh` sends an expired login's refresh token and the client id over HTTPS to Claude Code's token endpoint. Rotated logins leave only in `Outcome.rotated` or `Sessions.ClaudeLoginRenewalDTO.oauth`, to the caller that supplied them. The fingerprints file never leaves the machine.
- **Retention**: Secrets are not retained after a call returns. The fingerprints file keeps the 8 most recently seen fingerprints per account indefinitely; no entry expires by age and no account is ever purged.

### Security

- **sensitive-data**: The access token, the refresh token and the rotated pair are the sensitive data; the refresh token is the most sensitive because it mints further credentials and is single-use.
- **status-carries-no-secret**: `Outcome.statuses` and every value from `status(...)` MUST carry no token, so they can be served to any reader.
- **rotation-return-path**: A rotated pair MUST leave the evaluator only as a return value of the call that produced it.
- **no-unstorable-rotation**: The evaluator MUST NOT spend a refresh token for a credential with no `itemKey`, because a rotation with no storage address destroys the saved login.
- **token-lifetime**: An access token is treated as expired 300 seconds (or `refreshWithin`, when larger) before its stated expiry; a login with no stated expiry is never refreshed pre-emptively. A fresh token gets the reply's `expires_in` or 8 hours. Refresh-token lifetime is recorded in `refreshTokenExpiresAt` and reported in `refreshExpiresAt` but decides nothing.
- **revocation-handling**: A `.spent` refusal (HTTP 401, or 400 with `invalid_grant`) MUST be reported as `.spent` and the credential MUST be dropped from `probeable`; nothing retries it.
- **transport**: The token exchange MUST use the HTTPS `tokenURL`; the refresh token travels only in the request body, never in the URL.
- **fingerprints-carry-no-secret**: The fingerprints file MUST hold digests, never tokens; this rests on the caller passing fingerprints to `publish` (publish-digest-keys).
- **tokens-not-logged**: Log lines MUST NOT include any token; they include the account email (as public) and the short reason only.

## Logging

Subsystem: main bundle identifier (`Loggable.subsystem`) | Category: `ClaudeAuthEvaluator`

| Event | Level | Message |
|-------|-------|---------|
| Expired credential with no item key, refresh refused | error | `token-evaluator: <account> is expired but carries no keychain item key — refusing to spend its refresh token on a rotation nothing could store` |
| Refresh refused by the endpoint during a round | error | `token-evaluator: can't refresh <account>: <shortText>` |
| Refresh failed with a foreign error during a round | error | `token-evaluator: can't refresh <account>: <localized description>` |
| Renewal refused by the endpoint | error | `token-evaluator: can't renew a login: <shortText>` |
| Renewal failed with a foreign error | error | `token-evaluator: can't renew a login: <localized description>` |

The account and reason are interpolated with `privacy: .public`, so the account email is visible in unified-log output. Successful refreshes and classifications are not logged. `ClaudeTokenRefresher` and `AccountFingerprints` log nothing: the refresher reports through its thrown error, and fingerprint misses return `""`.

## Platform Notes

- **SwiftUI**: Sources are `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeAuth/ClaudeAuthEvaluator.swift` (`Foundation`, `OSLog`; a `withTaskGroup` whose results are tagged with their index and sorted before folding, logging via the toolkit's `Loggable`), `ClaudeTokenRefresher.swift` (`URLSession.shared`, `JSONSerialization`, a typed `ClaudeOAuthRefreshError`) and `AccountFingerprints.swift` (`CryptoKit` `SHA256`, `DigestHex`'s `hexString`, `Data.write(options: .atomic)`, an `NSLock` around `nonisolated(unsafe)` static cache fields). A SwiftUI host never calls the evaluator directly; a daemon does, and the app talks to that daemon. The app is the fingerprints writer.
- **Compose**: Kotlin `object`s with `suspend fun evaluate(...)` using `coroutineScope { credentials.map { async { judge(it) } }.awaitAll() }`, which preserves input order. The refresher uses OkHttp or Ktor with a 15-second call timeout and maps `UnknownHostException`/`ConnectException` to `Unsent`; refusals are a sealed class. Fingerprints use `MessageDigest.getInstance("SHA-256")`, write a temp file then `Files.move(..., ATOMIC_MOVE)`, and guard the cache with a `Mutex` or `synchronized`; the app-private files directory replaces 0600.
- **React/Web**: A server-side or worker module: `Promise.all(credentials.map(judge))` preserves order; the refresher uses `fetch` with `AbortSignal.timeout(15000)`; errors are a discriminated union checked with a type guard. Fingerprints use `crypto.createHash("sha256")` in Node (or `crypto.subtle.digest` in a worker), write-temp-then-`fs.rename` for atomicity and `fs.chmod(path, 0o600)`. Never expose refresh tokens to page script.
- **AppKit / UIKit**: Identical to the SwiftUI note: the files are UI-framework-agnostic. The custody half (keychain reads and writes of the rotated pair, and calling `publish` with the fingerprints of the tokens just read) belongs to the AppKit or UIKit app, which must store every `Outcome.rotated` entry before anything else that can fail.
- **WinUI 3**: Port to static classes. `ClaudeAuthEvaluator.EvaluateAsync(IReadOnlyList<ClaudeCredentialDto>, DateTimeOffset now, Func<ClaudeOAuthCredential, CancellationToken, Task<ClaudeOAuthCredential>>? refresh)` starts each judgment as a `Task` and awaits `Task.WhenAll(...)`, whose result array is already in input order. `ClaudeTokenRefresher` uses one shared `HttpClient` with `Timeout = TimeSpan.FromSeconds(15)`, a `DefaultRequestHeaders.UserAgent` set to the client name, `anthropic-beta` added per request, and a body built with `System.Text.Json`; parse replies with `JsonDocument` and `TryGetProperty`. Model refusals as `ClaudeOAuthRefreshException` with a `Kind` enum and `LeftTokenUntouched`, caught before a general `catch (Exception)`; map `HttpRequestException` whose inner `SocketException` is `HostNotFound`, `NoData` or `ConnectionRefused` to `Unsent`, and `TaskCanceledException` (timeout) to `Inconclusive`. `AccountFingerprints` uses `SHA256.HashData(Encoding.UTF8.GetBytes(token))` with `Convert.ToHexString(...).ToLowerInvariant()`, writes to a temp file and swaps it in with `File.Replace` or `File.Move(temp, path, overwrite: true)`, restricts access with a file ACL (`FileSystemAclExtensions.SetAccessControl`, current user only) in place of 0600, and caches on `File.GetLastWriteTimeUtc` plus `FileInfo.Length` under a `lock`; the folder is `ApplicationData.Current.LocalFolder` (or `%LOCALAPPDATA%` for an unpackaged service). DTOs are C# `record`s with `State` kept as a string. Logging uses `ILogger<ClaudeAuthEvaluator>`. Custody stays in the packaged WinUI app through `Windows.Security.Credentials.PasswordVault`; the evaluator runs in a background service (an `IHostedService` or a full-trust companion process) and never touches the vault.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeAuth/ClaudeAuthEvaluator.swift` | confirmed (1.1.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeAuth/AccountFingerprints.swift` | confirmed (1.1.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeAuth/ClaudeTokenRefresher.swift` | confirmed (1.1.1) |

## Design Decisions

**Decision**: A login with no stated expiry is classified `.unknown` (and counts as usable to `isAccessTokenUsable`) and is never refreshed pre-emptively.
**Rationale**: The source comment says refreshing on a guess spends a single-use refresh token "to learn what a failed request would have said for free"; the probe's own 401 answers the question with certainty.
**Approved**: pending

**Decision**: Having an `itemKey` is a precondition for spending a refresh token, checked before the refresh rather than after.
**Rationale**: The refresh token is single-use, so a rotation with no storage address would work for one round and then leave the app holding a voided pair. Refusing keeps the saved login alive, at the cost of reporting it `.expired` and unprobed.
**Approved**: pending

**Decision**: Credentials in a round are judged concurrently, and order is restored before folding.
**Rationale**: Each refresh has a 15-second ceiling and the app waits on the call with a ceiling of its own; four sequential refreshes could outlast that wait and the app would lose every rotation produced so far. Order is restored because the caller reads statuses positionally against what it pushed.
**Approved**: pending

**Decision**: The evaluator decides and refreshes, but never stores; it holds no timer and no state.
**Rationale**: macOS names the requesting process in a keychain permission dialog and only a process with a UI can answer it, so the app keeps custody. Refreshing only inside a call the app made guarantees the rotation reaches the one process that can persist it.
**Approved**: pending

**Decision**: Only `.spent` and an unrefreshed `.expired` drop a credential from `probeable`; `.rateLimited` and `.inconclusive` keep the original credential.
**Rationale**: A rate limit or an inconclusive answer says nothing about the login, and dropping it would blank the account's quota for a reason that is not about the account.
**Approved**: pending

**Decision**: `renew` ignores expiry and always spends the refresh token.
**Rationale**: It is called when a saved login is about to be installed as Claude Code's own, where the goal is a full access-token lifetime and proof the refresh token is alive; the caller is waiting on that one reply, so the rotation has a home.
**Approved**: pending

**Decision**: An error that is not a `ClaudeOAuthRefreshError` is reported `.inconclusive`, and in `renew` sets `tokenUntouched` false even when it is a transport error proving nothing was sent.
**Rationale**: Only `ClaudeTokenRefresher` can tell an unsent request from a lost reply, so anything else is treated as possibly spent. The quirk is that an injected refresher throwing a raw `URLError` never gets the `.unsent` treatment.
**Approved**: pending

**Decision**: Only a 401, or a 400 naming `invalid_grant`, is `.spent`; every other 4xx (403, 408, other 400s) is `.inconclusive`.
**Rationale**: Cloudflare's 403 "error code: 1010" never reaches the endpoint and a 408 is an edge timing out; reporting a good login dead sends the user through a browser login it never needed.
**Approved**: pending

**Decision**: Only six connection-level `URLError` codes count as never sent; a timeout or dropped connection is `.inconclusive`.
**Rationale**: A timeout proves nothing: the endpoint may have answered into the void and spent the token, so only failures that prove the request never left the machine may report the token untouched.
**Approved**: pending

**Decision**: A reply without `expires_in` is stamped with an 8-hour expiry instead of keeping the old one, and only fields the reply speaks to are folded in.
**Rationale**: Keeping an old expiry against a new token makes it read as stale, so every probe would refresh again and burn another single-use token. Carrying other fields forward keeps the login valid in Claude Code's own format, which this code does not fully know.
**Approved**: pending

**Decision**: A 2xx reply without a usable access token is caught right after parsing and reported `.inconclusive`, not passed deeper.
**Rationale**: By then the refresh token is spent; the source comment says a failure further along "would abandon whatever the response did carry and void the stored credential for nothing".
**Approved**: pending

**Decision**: Account attribution is published as a map of SHA-256(token) to account name in one shared file, written only by the app.
**Rationale**: The daemon and CLI cannot read keychain items, and a digest answers "whose token is this" without shipping a credential to a process that has no business holding one. One file means the daemon and the CLI cannot attribute one token to two accounts.
**Approved**: pending

**Decision**: `publish` merges into the existing file and keeps 8 fingerprints per account, re-stamping a digest seen again and letting the newest claim win a contested digest.
**Rationale**: A token minted an hour ago is still billing its account, so replacing would un-attribute live sessions; the cap stops the file growing one entry per rotation forever; a token cannot belong to two accounts, so keeping both would let lookup order decide.
**Approved**: pending

**Decision**: Lookups cache the parsed map keyed on the symlink-resolved file's modification date and size, and an empty token returns before any file access.
**Rationale**: The daemon asks on every hook event, so the steady state must be a dictionary lookup. `attributesOfItem` does not follow a final symlink, and a rewrite can land on the same coarse mtime, so size is in the key. Most hook events carry no token and must not pay for a read.
**Approved**: pending

**Decision**: Log lines name the account email with `privacy: .public`.
**Rationale**: The failure lines are what tells the owner which saved login to save again, and a redacted `<private>` line answers nothing on a single-user machine; the email is not a credential, and no token ever reaches a log line. The cost is that `no-pii-in-logs` is only partial.
**Approved**: pending

**Decision**: The parser skips entries it cannot use and ignores `version`.
**Rationale**: The source comment says a reader meets a newer file "by ignoring what it does not recognise, which is cheaper than a version negotiation between three targets that ship together anyway".
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | passed | Security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | passed | Security |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | partial | Privacy and Data |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | Performance |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |

`separation-of-concerns` passes: the evaluator only decides, the HTTP exchange lives in `ClaudeTokenRefresher`, attribution lives in `AccountFingerprints`, storage of rotations lives in the app, and serialization of rounds lives in `AccountQuotaProbe`. `unit-test-coverage` is partial: beside the toolkit copies only `ClaudeAuthEvaluatorDuplicateLoginTests` and `FingerprintsPublishModeTests` test them directly; the identical predecessors are covered by Stenographer's `ClaudeTokenEvaluatorTests` and `AccountFingerprintsTests`, and the toolkit's `AccountQuotaObserveTests` covers `publish` and `accountName` through `CredentialFence`, but the margin-widening, foreign-error detail length, failure-status expiry, concurrency timing, request shape, rotation fold and cache concurrency vectors have no test anywhere. `explicit-error-handling` is partial: every refresh failure is caught, classified, logged and returned, and `publish` throws when it cannot set 0600 (`publish-permissions-failure`). `error-response-handling` passes because each endpoint answer maps to a distinct, documented state with a one-line detail. `timeout-configuration` passes: each exchange has a 15-second timeout. `retry-with-backoff` fails: there is no retry within a call, deliberately, since a retried refresh may spend a token the first attempt already rotated; the next call is the only retry. `fault-tolerance` passes because one credential's failure never affects another's judgment and a bad fingerprints file degrades to "no match". `idempotent-operations` is partial: classification, status, `refusal`, `rotated`, `merge` and lookups are pure or repeatable, but `evaluate` and `renew` spend single-use refresh tokens, and concurrent calls are not guarded; a duplicate login inside one round is refreshed once (`refresh-once-per-token`). `data-integrity` is partial: fingerprints are written atomically, but concurrent publishers lose merges and a corrupt file is overwritten without its history. `token-lifecycle` passes: expiry margin, single-use rotation, revocation (`.spent`), the 8-hour default life and the refusal to refresh without a storage address are all handled. `secure-transport` passes: the exchange goes only to an HTTPS URL with the token in the body. `secure-storage` is partial: no token is stored, and the fingerprints file holds only digests and names at 0600, set before the file replaces the old one, and a failure to set it publishes nothing. `secure-log-output` passes: no token is ever logged. `no-pii-in-logs` is partial: the account email is logged with public privacy. `data-minimization` passes: readers get digests, never tokens, and statuses are secret-free. `caching-strategy` passes: the lookup cache invalidates on path, mtime and size. `main-thread-freedom` passes because every refreshing entry point is `async` and the network work runs in child tasks; the fingerprint lookup is a synchronous file stat plus, on change, a small read.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-11-21 | Mike Fullerton | Resolved duplicate-login-in-one-round (new refresh-once-per-token: one refresh per distinct refresh token per round, shared by every copy) and publish-permissions-failure (0600 is set on a temporary file before it replaces the old one, and a failure throws and publishes nothing); added vectors 057 to 062. |
| 1.1.0 | 2026-11-21 | Mike Fullerton | Covers ClaudeTokenRefresher and AccountFingerprints alongside the evaluator; drops the authored Reference Implementations section |
| 1.0.0 | 2026-11-21 | Mike Fullerton | Initial creation |
