---
id: 3f1efb26-3dfb-4e6c-bbbc-32609151ce78
title: "Claude Account Request DTOs"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Wire DTOs for saved Claude accounts: operation enum, request and response, token states, secret-free status, rotations, renewals, no-app refusal."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-accounts
  - credentials
  - wire
  - dto
  - xpc
depends-on:
  - d457c4d4-005c-4fcb-a3a6-3e1680bcb561
  - 2b552bde-d0bd-425a-9e79-fc624b52f516
  - 94bac7a5-3fc6-463d-86d1-7c59350cd7cb
  - fe798f91-076e-41fc-9713-907b744c5539
related:
  - a2cb25cc-f3d1-4b82-8a32-52e727c317e1
  - c5231579-d9c0-412d-8ae0-4c9bfb7937d3
references: []
approved-by: ""
approved-date: ""
---

# Claude Account Request DTOs

## Overview

Two files in the `Sessions` namespace define the wire contract between the `steno claude` command, the daemon and the menu-bar app for everything that can be asked or told about saved Claude accounts. Both import only `Foundation` and hold pure data: they perform no I/O, routing or validation, which belong to the daemon's and the app's handlers outside these files.

`ClaudeAccountRequestDTOs.swift` holds the request side:

- `ClaudeAccountOperation`, a `String`-backed enum naming the eight operations.
- `ClaudeAccountRequestDTO`, the one request envelope every operation travels in, which the daemon forwards to the app unchanged for a relayed operation.
- `ClaudeSavedAccountSummaryDTO`, one saved credential as the app lists it, with no secret in it.
- `ClaudeAccountResponseDTO`, the answer, in which each operation fills only the fields it is about.
- `ClaudeAccountRelay`, the two constants both ends compare on: the exact refusal sentence sent when no app is connected, and the app's bundle identifier.

`ClaudeAccountTokenDTOs.swift` holds the token side:

- `ClaudeTokenState`, the seven actionable states of one saved credential's token, with a short display `title` and an `isProbeable` verdict.
- `ClaudeAccountTokenStatusDTO`, one credential's token state "with no secret in it", the read surface for the CLI, the status line and the Usage window, with `counting(from:)` to recompute the countdown at read time.
- `ClaudeRotatedCredentialDTO`, a login the daemon just rotated, on its way back to the process that stores it.
- `ClaudeCredentialEvaluationDTO`, the daemon's answer when the app hands over its saved credentials: whether the set changed, and every rotated login.
- `ClaudeLoginRenewalDTO`, the daemon's answer to a request to renew one saved login before the app installs it as Claude Code's own.
- `ClaudeAccountsDTO`, the whole account picture: token statuses and quota readings in one document.

The source's doc comment states the split the request envelope serves: the daemon answers `usage` and `token` from what it already holds, so they work with the app shut, and every operation that has to touch a keychain item is relayed to the app, "which keeps custody of those items and runs the very code its own menus run."

The credential kind fields carry the raw value of Claude Credential Kind ([adhsdk.ingredient.foundation.claude-accounts.claude-credential-kind](cookbook:d457c4d4-005c-4fcb-a3a6-3e1680bcb561)), and `itemKey` carries that recipe's `"<kind>:<account>"` key spelling. Rotated and renewed logins carry a Claude OAuth Credential ([adhsdk.ingredient.foundation.claude-accounts.claude-o-auth-credential](cookbook:2b552bde-d0bd-425a-9e79-fc624b52f516)). Quota readings are `AccountQuotaReadingDTO` from Status Line DTOs ([adhsdk.ingredient.foundation.sessions.wire.status-line-dt-os](cookbook:94bac7a5-3fc6-463d-86d1-7c59350cd7cb)). The bundle identifier comes from Stenographer Instance ([adhsdk.ingredient.foundation.stenographer.stenographer-instance](cookbook:fe798f91-076e-41fc-9713-907b744c5539)).

## Behavioral Requirements

**Operation enum**

- **operation-cases**: `ClaudeAccountOperation` MUST have exactly eight cases: `usage`, `token`, `saved`, `switchLogin`, `saveToken`, `saveLogin`, `forget` and `refresh`.
- **operation-raw-values**: The raw strings MUST be `"usage"`, `"token"`, `"saved"`, `"switch"`, `"save_token"`, `"save_login"`, `"forget"` and `"refresh"` respectively; `switchLogin`, `saveToken` and `saveLogin` MUST NOT encode as their Swift case names.
- **operation-unknown-raw**: Constructing an operation from a raw string that is not one of the eight MUST yield no value, and decoding a request whose `operation` is such a string MUST fail with a decoding error; the enum has no fallback case.
- **operation-codable-sendable**: `ClaudeAccountOperation` MUST conform to `Codable` and `Sendable`.
- **operation-daemon-answered**: `usage` and `token` MUST be documented as answered by the daemon from state it already holds, so that they work while the app is not running.
- **operation-app-relayed**: `saved`, `switchLogin`, `saveToken`, `saveLogin`, `forget` and `refresh` MUST be documented as relayed to the app, because each touches a keychain item the app keeps custody of.
- **operation-saved-never-mints**: The `saved` operation MUST be documented as listing accounts without minting a token, so that listing cannot spend a refresh token.
- **operation-token-refresh-first**: The `token` operation MUST be documented as asking the app to refresh first when the saved token has less than `minimumLifetime` seconds left; the daemon sends `refresh` itself in that case.

**Request envelope**

- **request-fields**: `ClaudeAccountRequestDTO` MUST carry exactly these stored properties: `operation` (`ClaudeAccountOperation`, required), and the optionals `account` (`String`), `credentialKind` (`String`), `itemKey` (`String`), `token` (`String`), `minimumLifetime` (`Double`) and `remeasure` (`Bool`).
- **request-immutable**: Every request property MUST be immutable after construction (`let`).
- **request-init-defaults**: The memberwise initializer MUST take `operation` as its only required argument and default every other argument to `nil`.
- **request-equatable**: `ClaudeAccountRequestDTO` MUST conform to `Equatable`, comparing all seven properties.
- **request-codable-sendable**: `ClaudeAccountRequestDTO` MUST conform to `Codable` and `Sendable`.
- **request-json-keys**: The encoded JSON keys MUST be the property names as spelled in the source (`operation`, `account`, `credentialKind`, `itemKey`, `token`, `minimumLifetime`, `remeasure`); the type declares no custom coding keys.
- **request-nil-omitted**: Encoding MUST omit a key whose optional value is `nil`, and decoding MUST yield `nil` for any optional key that is absent.
- **request-relay-unchanged**: For a relayed operation the daemon MUST forward the request to the app unchanged, as the type's doc comment declares.
- **request-account-meaning**: `account` MUST hold the account name (an email) when the operation names an account.
- **request-credential-kind-meaning**: `credentialKind` MUST hold a Claude Credential Kind raw value (`"oauth"` or `"long-lived"`) when the account has both kinds saved and the operation must pick one.
- **request-item-key-meaning**: `itemKey` MUST hold the addressed keychain item in the form `"<kind>:<account>"`, and is documented for `token` and `refresh`.
- **request-token-meaning**: `token` MUST hold the token to store, and is documented for `saveToken` only.
- **request-minimum-lifetime-meaning**: `minimumLifetime` MUST be a count of seconds of life the handed-out token must still have, and is documented for `token` and `refresh`.
- **request-remeasure-meaning**: `remeasure`, for `usage`, MUST mean re-probe every account now instead of serving the cache.
- **request-no-validation**: The type MUST NOT validate which optional fields are present for a given operation; a request with any combination of fields encodes and decodes, and enforcing the per-operation fields falls to the daemon's and the app's handlers.

**Saved-account summary**

- **summary-fields**: `ClaudeSavedAccountSummaryDTO` MUST carry `name` (`String`), `credentialKind` (`String`), `itemKey` (`String`), `addedAt` (`Double?`), `expiresAt` (`Double?`), `refreshExpiresAt` (`Double?`), `isCurrentLogin` (`Bool`) and `location` (`String`).
- **summary-no-secret**: The summary MUST NOT carry a token or any other secret; it holds only what a table of accounts shows.
- **summary-immutable**: Every summary property MUST be immutable after construction (`let`).
- **summary-init-explicit**: The initializer MUST require every argument, including the optional ones, with no defaults.
- **summary-equatable**: `ClaudeSavedAccountSummaryDTO` MUST conform to `Equatable`, `Codable` and `Sendable`.
- **summary-epoch-seconds**: `addedAt`, `expiresAt` and `refreshExpiresAt` MUST be epoch seconds as `Double`.
- **summary-login-only-expiry**: `expiresAt` (access-token expiry) and `refreshExpiresAt` (refresh-token expiry) MUST be documented as set for logins only.
- **summary-current-login**: `isCurrentLogin` MUST be `true` exactly when this saved login is the machine-wide login.
- **summary-location**: `location` MUST name the keychain that holds the item, documented as `login` or `shared`.

**Response**

- **response-fields**: `ClaudeAccountResponseDTO` MUST carry the optionals `accounts` (`ClaudeAccountsDTO`), `saved` (array of `ClaudeSavedAccountSummaryDTO`), `token` (`String`), `custodianConnected` (`Bool`), `callerTrust` (`String`) and `message` (`String`).
- **response-mutable**: Every response property MUST be mutable (`var`), so a handler can fill fields after construction.
- **response-init-defaults**: The initializer MUST default every argument to `nil`.
- **response-codable-sendable**: `ClaudeAccountResponseDTO` MUST conform to `Codable` and `Sendable`.
- **response-not-equatable**: `ClaudeAccountResponseDTO` MUST NOT be assumed `Equatable`; the source declares no such conformance.
- **response-per-operation-fields**: Each operation MUST fill only the fields it is about and leave the rest `nil`: `accounts` for `usage`, `saved` for `saved`, `token` for `token`, and `message` as the one-line confirmation of a write.
- **response-custodian-connected**: `custodianConnected` MUST report whether the app is connected to answer relayed operations, and MUST be set on every reply the daemon itself writes.
- **response-caller-trust**: `callerTrust` MUST carry the caller-trust verdict label for the caller, for `steno claude doctor`.
- **response-no-refusal-field**: A refusal MUST NOT be expressed in the response; it travels as the reply's reason string instead.
- **response-json-keys**: The encoded JSON keys MUST be the property names as spelled in the source, with `nil` values omitted on encode and absent keys decoded as `nil`.

**Relay constants**

- **relay-no-custodian-reason**: `ClaudeAccountRelay.noCustodianReason` MUST equal exactly `"The Stenographer app isn't running; only it can reach the saved accounts' keychain."` (with ASCII apostrophes, as written in the source).
- **relay-reason-exact-match**: The daemon MUST send `noCustodianReason` as the refusal when a relayed operation arrives and no app is connected, and `steno` MUST match on that exact sentence to decide that launching the app and asking again will help.
- **relay-bundle-identifier**: `ClaudeAccountRelay.appBundleIdentifier` MUST equal `StenographerInstance.baseLabel`, which is `"com.agenticdevelopmentstudio.stenographer"`.
- **relay-launch-on-reason**: `steno` MUST launch the app identified by `appBundleIdentifier` in the background when it receives `noCustodianReason`.
- **relay-no-instances**: `ClaudeAccountRelay` MUST be a case-less enum used only as a namespace for its two static constants.

**Token state**

- **token-state-cases**: `ClaudeTokenState` MUST have exactly seven cases, in this declaration order: `usable`, `refreshed`, `expired`, `spent`, `rateLimited`, `inconclusive` and `unknown`.
- **token-state-raw-values**: The raw strings MUST be `"usable"`, `"refreshed"`, `"expired"`, `"spent"`, `"rate_limited"`, `"inconclusive"` and `"unknown"` respectively; `rateLimited` MUST NOT encode as its Swift case name.
- **token-state-conformances**: `ClaudeTokenState` MUST conform to `Codable`, `Sendable` and `CaseIterable`, and `allCases` MUST list the seven cases in declaration order.
- **token-state-meanings**: Each state MUST carry the meaning its doc comment gives: `usable` good to send with time to spare; `refreshed` was expired or near enough and the daemon minted a fresh pair this round; `expired` expired with no refresh attempted yet; `spent` the refresh token is void because the account logged in or refreshed elsewhere; `rateLimited` Anthropic rate-limited the refresh and the credential is untouched; `inconclusive` a refresh that neither worked nor proved anything (offline, a 5xx, an unreadable reply); `unknown` a credential with no expiry to read.
- **token-state-spent-distinct**: `spent` and `expired` MUST remain separate states, because an expired access token is a routine refresh and a spent refresh token needs a browser login.
- **token-state-rate-limited-not-dead**: A `rateLimited` credential MUST NOT be reported dead.
- **token-state-titles**: `title` MUST return `"Usable"`, `"Refreshed"`, `"Expired"`, `"Spent elsewhere"`, `"Rate limited"`, `"Unknown — retry"` (with an em dash) and `"No expiry"` for the seven cases in declaration order.
- **token-state-probeable**: `isProbeable` MUST be `true` for `usable`, `refreshed`, `unknown`, `rateLimited` and `inconclusive`.
- **token-state-not-probeable**: `isProbeable` MUST be `false` for `expired` and `spent`.

**Token status**

- **status-fields**: `ClaudeAccountTokenStatusDTO` MUST carry `account` (`String`), `credentialKind` (`String?`), `itemKey` (`String?`), `state` (`String`), `expiresAt` (`Double?`), `refreshExpiresAt` (`Double?`), `secondsRemaining` (`Double?`) and `detail` (`String?`), all immutable (`let`).
- **status-no-secret**: The status MUST NOT carry a token or any other secret; it is kept a separate type from `ClaudeCredentialDTO`, which carries the token and travels only inward.
- **status-conformances**: `ClaudeAccountTokenStatusDTO` MUST conform to `Codable`, `Sendable` and `Equatable`.
- **status-init-defaults**: The initializer MUST require `account` and `state` and default every other argument to `nil`.
- **status-init-typed-state**: The initializer MUST take `state` as a `ClaudeTokenState` and store its raw value in the `state` string.
- **status-state-raw-string**: `state` MUST be encoded and decoded as a plain string, so a payload with a state this build does not know still decodes.
- **status-token-state-fallback**: `tokenState` MUST return the `ClaudeTokenState` named by `state`, or `unknown` when `state` names no case this build knows.
- **status-credential-kind-optional**: `credentialKind` MUST be `nil` for a credential whose kind the pushing client never named.
- **status-item-key-meaning**: `itemKey` MUST name the keychain item the credential lives in, the same address a rotation is written back to.
- **status-epoch-seconds**: `expiresAt` (access token) and `refreshExpiresAt` (refresh token) MUST be epoch seconds.
- **status-detail-no-token**: `detail` MUST be a one-line reason given when the state is anything but `usable`, and MUST NOT contain a token.
- **status-counting-seconds**: `counting(from: now)` MUST return a status whose `secondsRemaining` equals `expiresAt` minus `now` in epoch seconds, negative once `expiresAt` has passed.
- **status-counting-nil-expiry**: `counting(from:)` MUST return `secondsRemaining == nil` when `expiresAt` is `nil`.
- **status-counting-preserves**: `counting(from:)` MUST copy `account`, `credentialKind`, `itemKey`, `expiresAt`, `refreshExpiresAt` and `detail` unchanged.
- **status-counting-normalizes-state**: `counting(from:)` MUST rebuild `state` from `tokenState`, so a recognized state is unchanged and an unrecognized state string becomes `"unknown"`.
- **status-counting-pure**: `counting(from:)` MUST NOT modify the receiver; it returns a new value.

**Rotated credential and evaluation**

- **rotated-fields**: `ClaudeRotatedCredentialDTO` MUST carry `itemKey` (`String`), `account` (`String`) and `oauth` (`ClaudeOAuthCredential`), all immutable and all required by the initializer.
- **rotated-conformances**: `ClaudeRotatedCredentialDTO` MUST conform to `Codable` and `Sendable`; the source declares no `Equatable` conformance.
- **rotated-only-copy**: A rotated credential's `oauth` pair MUST be treated as the only working copy of that login, because the refresh token it replaced was voided when the token endpoint answered.
- **rotated-return-path**: A rotated credential MUST travel back down the same connection that supplied it, in the reply to the call that asked for the evaluation.
- **evaluation-fields**: `ClaudeCredentialEvaluationDTO` MUST carry `changed` (`Bool`) and `rotated` (array of `ClaudeRotatedCredentialDTO`), both immutable.
- **evaluation-rotated-default**: The initializer MUST require `changed` and default `rotated` to an empty array.
- **evaluation-conformances**: `ClaudeCredentialEvaluationDTO` MUST conform to `Codable` and `Sendable`; the source declares no `Equatable` conformance.
- **evaluation-changed-meaning**: `changed` MUST be `true` exactly when the pushed set differed from the one already held, which is also when the quota cache was invalidated.
- **evaluation-store-rotated-first**: A caller receiving an evaluation MUST store every entry of `rotated` before doing anything that can fail.
- **evaluation-no-summary**: The evaluation MUST NOT carry the secret-free per-credential summary; that is served by `GET /accounts` alongside the quota readings.
- **evaluation-acceptance**: Receipt of the evaluation MUST be the acceptance of the push; a reply that never arrives surfaces as a thrown error, not as a field.

**Login renewal**

- **renewal-fields**: `ClaudeLoginRenewalDTO` MUST carry `state` (`String`), `oauth` (`ClaudeOAuthCredential?`), `detail` (`String?`) and `tokenUntouched` (`Bool?`), all immutable.
- **renewal-conformances**: `ClaudeLoginRenewalDTO` MUST conform to `Codable` and `Sendable`; the source declares no `Equatable` conformance.
- **renewal-init-defaults**: The initializer MUST require `state` (as a `ClaudeTokenState`, stored as its raw value), default `oauth` and `detail` to `nil`, and default `tokenUntouched` to `false`.
- **renewal-init-writes-untouched**: A renewal built through the initializer MUST hold a non-nil `tokenUntouched`, so it encodes a `tokenUntouched` key even when the value is `false`.
- **renewal-documented-states**: `state` MUST be documented as `refreshed` with `oauth`, or `spent`, `rateLimited` or `inconclusive` without `oauth`.
- **renewal-oauth-only-copy**: When `oauth` is present it MUST be treated as the only working copy of the login, and the caller MUST store it before doing anything else that can fail.
- **renewal-detail-no-token**: `detail` MUST be a one-line reason given when the renewal did not work, and MUST NOT contain a token.
- **renewal-untouched-meaning**: `tokenUntouched` MUST be `true` only when the failed renewal certainly left the refresh token unspent (a rate limit, or a request that never left the Mac), and `false` after a timeout, a 5xx or an unreadable reply.
- **renewal-untouched-absent**: `leftTokenUntouched` MUST return `false` when `tokenUntouched` is absent (an older daemon), and the value of `tokenUntouched` otherwise.
- **renewal-no-install-unless-untouched**: After a failed renewal whose `leftTokenUntouched` is `false`, the saved pair MUST NOT be installed as if it still worked.
- **renewal-token-state-fallback**: `tokenState` MUST return the `ClaudeTokenState` named by `state`, or `inconclusive` when `state` names no case this build knows, and an unknown state MUST NOT be a reason to refuse a login.

**Accounts document**

- **accounts-fields**: `ClaudeAccountsDTO` MUST carry `tokens` (array of `ClaudeAccountTokenStatusDTO`), `quotas` (array of `AccountQuotaReadingDTO`) and `measuredAt` (`Double?`), all immutable.
- **accounts-init-defaults**: The initializer MUST require `tokens` and `quotas` and default `measuredAt` to `nil`.
- **accounts-conformances**: `ClaudeAccountsDTO` MUST conform to `Codable` and `Sendable`; the source declares no `Equatable` conformance.
- **accounts-measured-at**: `measuredAt` MUST be the epoch seconds of the last completed probe round, or `nil` if none has run.
- **accounts-one-document**: Token statuses and quota readings MUST be served together in one document, not through two endpoints a caller has to correlate.

## Appearance

Not applicable — this is a set of wire data types, not a visual component.

## States

Not applicable — this is a set of wire data types, not a visual component.

## Accessibility

Not applicable — this is a set of wire data types, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-account-request-001 | operation-raw-values | `ClaudeAccountOperation.switchLogin.rawValue`, `.saveToken.rawValue`, `.saveLogin.rawValue` | `"switch"`, `"save_token"`, `"save_login"` |
| claude-account-request-002 | operation-raw-values, operation-cases | Raw values of `usage`, `token`, `saved`, `forget`, `refresh` | `"usage"`, `"token"`, `"saved"`, `"forget"`, `"refresh"` |
| claude-account-request-003 | operation-unknown-raw | `ClaudeAccountOperation(rawValue: "switchLogin")` and `ClaudeAccountOperation(rawValue: "Usage")` | `nil` for both; matching is exact and case-sensitive |
| claude-account-request-004 | operation-unknown-raw | Decode `{"operation":"delete"}` as `ClaudeAccountRequestDTO` | Throws a decoding error |
| claude-account-request-005 | request-init-defaults, request-nil-omitted, request-json-keys | Encode `ClaudeAccountRequestDTO(operation: .usage)` with a default JSON encoder | JSON object with the single key `operation` = `"usage"` |
| claude-account-request-006 | request-json-keys, request-nil-omitted | Decode `{"operation":"token","itemKey":"oauth:a@b.com","minimumLifetime":300}` | `operation == .token`, `itemKey == "oauth:a@b.com"`, `minimumLifetime == 300.0`, every other optional `nil` |
| claude-account-request-007 | request-equatable | Two requests `(.saveToken, account: "a@b.com", token: "t1")` and `(.saveToken, account: "a@b.com", token: "t2")` | Not equal; the same two with equal tokens are equal |
| claude-account-request-008 | request-no-validation | Encode then decode `ClaudeAccountRequestDTO(operation: .usage, token: "x", remeasure: true)` | Round-trips to an equal value; no error for a field the operation does not use |
| claude-account-request-009 | summary-fields, summary-equatable, response-json-keys | Encode a summary with `name: "a@b.com"`, `credentialKind: "oauth"`, `itemKey: "oauth:a@b.com"`, `addedAt: nil`, `expiresAt: 1.0`, `refreshExpiresAt: nil`, `isCurrentLogin: true`, `location: "login"`, then decode | Decoded value equals the original; the JSON has no `addedAt` or `refreshExpiresAt` key |
| claude-account-request-010 | summary-no-secret | List the stored properties of `ClaudeSavedAccountSummaryDTO` | None named `token` or holding a secret |
| claude-account-request-011 | response-init-defaults, response-per-operation-fields | Encode `ClaudeAccountResponseDTO(token: "abc", custodianConnected: true)` | JSON with exactly the keys `token` and `custodianConnected` |
| claude-account-request-012 | response-mutable | Construct an empty response, assign `message = "Saved."` | `message == "Saved."`; every other field `nil` |
| claude-account-request-013 | relay-no-custodian-reason | Read `ClaudeAccountRelay.noCustodianReason` | Exactly `The Stenographer app isn't running; only it can reach the saved accounts' keychain.` with ASCII apostrophes |
| claude-account-request-014 | relay-bundle-identifier | Read `ClaudeAccountRelay.appBundleIdentifier` | `"com.agenticdevelopmentstudio.stenographer"` |
| claude-account-request-015 | token-state-raw-values, token-state-conformances, token-state-cases | `ClaudeTokenState.allCases.map(\.rawValue)` | `["usable", "refreshed", "expired", "spent", "rate_limited", "inconclusive", "unknown"]` |
| claude-account-request-016 | token-state-titles | `title` of each case in `allCases` order | `"Usable"`, `"Refreshed"`, `"Expired"`, `"Spent elsewhere"`, `"Rate limited"`, `"Unknown — retry"`, `"No expiry"` |
| claude-account-request-017 | token-state-probeable, token-state-not-probeable | `isProbeable` of each case | `true` for `usable`, `refreshed`, `unknown`, `rateLimited`, `inconclusive`; `false` for `expired`, `spent` |
| claude-account-request-018 | status-init-typed-state, status-init-defaults, status-conformances | Encode `ClaudeAccountTokenStatusDTO(account: "a@b.com", state: .rateLimited)` | JSON with exactly the keys `account` = `"a@b.com"` and `state` = `"rate_limited"` |
| claude-account-request-019 | status-state-raw-string, status-token-state-fallback | Decode `{"account":"a@b.com","state":"quarantined"}` | Decodes without error; `state == "quarantined"`, `tokenState == .unknown` |
| claude-account-request-020 | status-counting-seconds, status-counting-preserves | Status with `expiresAt: 1000`, `detail: "x"`; call `counting(from: Date(timeIntervalSince1970: 400))` | `secondsRemaining == 600`; `expiresAt == 1000`, `detail == "x"` |
| claude-account-request-021 | status-counting-seconds | Status with `expiresAt: 1000`; `counting(from: Date(timeIntervalSince1970: 1300))` | `secondsRemaining == -300` |
| claude-account-request-022 | status-counting-nil-expiry | Status with `expiresAt: nil`, `secondsRemaining: 42`; `counting(from: .now)` | `secondsRemaining == nil` |
| claude-account-request-023 | status-counting-normalizes-state, status-counting-pure | Decode a status with `state: "quarantined"`, call `counting(from:)` | Result's `state == "unknown"`; the original still has `state == "quarantined"` |
| claude-account-request-024 | evaluation-rotated-default, evaluation-fields | Encode `ClaudeCredentialEvaluationDTO(changed: false)` | JSON `{"changed": false, "rotated": []}` (key order aside) |
| claude-account-request-025 | renewal-init-defaults, renewal-init-writes-untouched | Encode `ClaudeLoginRenewalDTO(state: .spent, detail: "void")` | JSON with keys `state` = `"spent"`, `detail` = `"void"`, `tokenUntouched` = `false`; no `oauth` key |
| claude-account-request-026 | renewal-untouched-absent | Decode `{"state":"rate_limited"}` as `ClaudeLoginRenewalDTO` | `tokenUntouched == nil`, `leftTokenUntouched == false`, `tokenState == .rateLimited` |
| claude-account-request-027 | renewal-untouched-absent | `ClaudeLoginRenewalDTO(state: .rateLimited, tokenUntouched: true).leftTokenUntouched` | `true` |
| claude-account-request-028 | renewal-token-state-fallback | Decode `{"state":"quarantined"}` as `ClaudeLoginRenewalDTO` | `tokenState == .inconclusive` (not `.unknown`) |
| claude-account-request-029 | accounts-init-defaults, accounts-fields | Encode `ClaudeAccountsDTO(tokens: [], quotas: [])` | JSON with `tokens` = `[]`, `quotas` = `[]` and no `measuredAt` key |
| claude-account-request-030 | rotated-fields | Encode then decode a `ClaudeRotatedCredentialDTO(itemKey: "oauth:a@b.com", account: "a@b.com", oauth: <credential>)` | Decoded `itemKey`, `account` and every field of `oauth` equal the originals |

No test file for these types exists in the SDK's test targets; the vectors are derived from the source declarations alone. The documentation-only requirements (operation-daemon-answered, operation-app-relayed, operation-saved-never-mints, operation-token-refresh-first, request-relay-unchanged, response-custodian-connected, response-caller-trust, response-no-refusal-field, relay-reason-exact-match, relay-launch-on-reason, token-state-meanings, token-state-spent-distinct, token-state-rate-limited-not-dead, status-detail-no-token, rotated-only-copy, rotated-return-path, evaluation-changed-meaning, evaluation-store-rotated-first, evaluation-no-summary, evaluation-acceptance, renewal-documented-states, renewal-oauth-only-copy, renewal-detail-no-token, renewal-untouched-meaning, renewal-no-install-unless-untouched, accounts-measured-at, accounts-one-document) describe what the daemon, the app and `steno` do with these types; their vectors belong to those handlers' tests (the daemon's credential evaluator and the app's keychain code), not to this data contract.

## Edge Cases

- **Empty request**: A request built with only `operation` MUST encode to a one-key object and decode back to an equal value (vector 005).
- **Unknown operation string**: A request whose `operation` is not one of the eight raw strings MUST fail to decode; there is no fallback case, so a newer sender's operation is a decoding error for an older receiver (vector 004).
- **Swift case name on the wire**: `"switchLogin"`, `"saveToken"` or `"saveLogin"` sent as the operation MUST be rejected as unknown, because the wire spellings are `switch`, `save_token` and `save_login` (vector 003).
- **Fields the operation does not use**: A request MUST encode and decode with any combination of optional fields present; nothing in these types rejects, for example, a `token` on a `usage` request (vector 008).
- **Unrecognized credential kind**: `credentialKind` is a plain `String` on the request, summary and status, so a value that is not a Claude Credential Kind raw value MUST still encode and decode; interpreting it is the receiver's job.
- **Malformed item key**: `itemKey` is a plain `String` with no format check; a value without a colon MUST still encode and decode.
- **Negative or zero lifetime**: `minimumLifetime` accepts any `Double`, including `0`, negative values and non-integral seconds; the types MUST NOT clamp or reject it.
- **Missing expiry on a long-lived token**: A summary for a `long-lived` credential SHOULD carry `nil` for `expiresAt` and `refreshExpiresAt`, which are documented as logins only; the type does not enforce this.
- **Empty saved list**: `saved` MAY be an empty array, which MUST encode as `[]` and is distinct from `nil` (omitted).
- **Response decode of an unknown extra key**: Decoding MUST ignore JSON keys a type does not declare, as synthesized decoding does.
- **No app connected**: When a relayed operation arrives with no app connected, the reply MUST be a refusal whose reason string is exactly `noCustodianReason`, not a `ClaudeAccountResponseDTO`; any change to that sentence breaks `steno`'s match.
- **Unknown token state from a newer daemon**: A status whose `state` string this build does not know MUST still decode; `tokenState` reads it as `unknown` (vector 019). A renewal with such a state reads it as `inconclusive`, never as a reason to refuse a login (vector 028). The two fallbacks differ on purpose: a status with an unreadable state is still probeable, and a renewal with one is treated as having proved nothing.
- **Counting an unknown state**: `counting(from:)` rebuilds the status through the typed initializer, so an unrecognized state string MUST come back as `"unknown"`; the original raw string is lost on the copy (vector 023).
- **Stale stored countdown**: A status's stored `secondsRemaining` is frozen at decision time and a status may be read for up to five minutes after the app pushes; a reader that wants the live countdown MUST call `counting(from:)`, which discards the stored value (vector 022).
- **Expiry already past**: `counting(from:)` MUST return a negative `secondsRemaining` when `now` is after `expiresAt`; it does not clamp to zero (vector 021).
- **Missing `tokenUntouched` from an older daemon**: A renewal decoded without `tokenUntouched` MUST read `leftTokenUntouched == false`, so the saved pair is treated as possibly spent (vector 026).
- **Renewal with `refreshed` but no `oauth`**: Nothing in the type ties `oauth` to the `refreshed` state; a payload with `state: "refreshed"` and no `oauth` MUST still decode, and deciding what to do with it is the caller's job.
- **Empty rotation list**: An evaluation with no rotations MUST encode `rotated` as `[]`, not omit it, because `rotated` is non-optional (vector 024).
- **No probe round yet**: `ClaudeAccountsDTO.measuredAt` MUST be `nil` until a probe round has completed; `tokens` and `quotas` MAY be empty arrays.
- **Concurrent access**: All declarations are `Sendable` value types (or a case-less namespace with `static let` constants); they hold no shared mutable state, so concurrent reads are safe and a mutated response copy never affects another copy.
- **Network or storage failure**: Not applicable to these types: they perform no transport, keychain or file access. Transport errors belong to the XPC connection and handlers that carry them; a lost evaluation reply surfaces as a thrown error at the caller (evaluation-acceptance).

## Configuration

None — the types read no environment variable or settings key; every value arrives through an initializer argument or a decoded payload. The one fixed value, `appBundleIdentifier`, is taken from `StenographerInstance.baseLabel` rather than spelled here. `counting(from:)` takes the reference time as an argument rather than reading the clock itself, so the caller supplies "now".

## Deep Linking

Not applicable: the types define no URL scheme, route or navigation destination.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | The Stenographer app isn't running; only it can reach the saved accounts' keychain. | `ClaudeAccountRelay.noCustodianReason`, the refusal reason a user can see in `steno` output |
| (none; literal) | Usable | `ClaudeTokenState.usable.title`, quota card or CLI line |
| (none; literal) | Refreshed | `ClaudeTokenState.refreshed.title` |
| (none; literal) | Expired | `ClaudeTokenState.expired.title` |
| (none; literal) | Spent elsewhere | `ClaudeTokenState.spent.title` |
| (none; literal) | Rate limited | `ClaudeTokenState.rateLimited.title` |
| (none; literal) | Unknown — retry | `ClaudeTokenState.inconclusive.title` |
| (none; literal) | No expiry | `ClaudeTokenState.unknown.title` |

Every string here is a hardcoded English literal with no localization lookup. `noCustodianReason` MUST NOT be localized as things stand, because `steno` matches on its exact text; translating it would break that match. The `title` strings are display text with no such match on them.

## Accessibility Options

Not applicable: the types present no UI.

## Feature Flags

Not applicable: the types contain no feature-flag reference.

## Analytics

Not applicable: the types contain no analytics call.

## Privacy

- **Data collected**: Account names (emails) in `account`, `itemKey`, the summary's `name` and the status's `account`; bearer tokens in the request's `token` (for `saveToken`) and the response's `token` (for `token`); whole OAuth logins, access and refresh token together, in `ClaudeRotatedCredentialDTO.oauth` and `ClaudeLoginRenewalDTO.oauth`.
- **Secret-free surfaces**: `ClaudeSavedAccountSummaryDTO` and `ClaudeAccountTokenStatusDTO` carry no secret by design, and `detail` on the status and the renewal is documented never to contain a token. The status is kept a separate type from the token-bearing `ClaudeCredentialDTO` because one shared type "would be one field rename away from serving a refresh token over HTTP".
- **Storage**: None in these types. The saved credentials live in keychain items the app keeps custody of; the summary's `location` names which keychain (`login` or `shared`).
- **Transmission**: The values cross process boundaries between `steno`, the daemon and the app as encoded payloads; the types themselves perform no transmission. A rotated login goes back only down the connection that supplied it, "the one path that hands it to nobody else".
- **Retention**: None beyond the lifetime of the value the caller holds.
- **Secret exposure**: The request, response, rotated-credential and renewal structs declare no redacting description, so their default reflection (`print`, string interpolation, `dump`) includes any token in clear; code that logs one would log the token.
- **Token lifetime**: A token handed out for `token` carries at least `minimumLifetime` seconds of life when the daemon honors the request. A refresh token is single-use: once the token endpoint answers, the pair in a rotation or renewal is the only working copy and the caller stores it first. Expiry, refresh and revocation themselves are owned by the app's keychain code and the daemon's credential evaluator, outside these files.

## Logging

Not applicable: the types call no logging API.

## Platform Notes

- **SwiftUI**: The sources are `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/ClaudeAccountRequestDTOs.swift` and `ClaudeAccountTokenDTOs.swift` beside it, extensions of the case-less `Sessions` namespace that import only `Foundation`. Every type relies on synthesized `Codable`; JSON keys are the property names, and synthesized encoding omits `nil` optionals through `encodeIfPresent`. `ClaudeOAuthCredential` comes from `Core/ClaudeAccounts/ClaudeOAuthCredential.swift` (its expiries are Unix milliseconds, unlike the epoch seconds here), `AccountQuotaReadingDTO` and `ClaudeCredentialDTO` from `StatusLineDTOs.swift` in the same folder, and `StenographerInstance.baseLabel` from `Core/Stenographer/StenographerInstance.swift`. Nothing here is SwiftUI-specific; a SwiftUI view reads `ClaudeTokenState.title` for its label.
- **Compose**: Use Kotlin `@Serializable` data classes with nullable fields defaulting to `null` and `explicitNulls = false` in the `Json` configuration to match the omit-nil encoding. Model the operation as an enum class with `@SerialName("switch")`, `@SerialName("save_token")` and `@SerialName("save_login")`, and the token state with `@SerialName("rate_limited")`; keep `state` fields as `String` with a `tokenState` getter that maps unknown values to `UNKNOWN` (status) or `INCONCLUSIVE` (renewal). Keep `ignoreUnknownKeys = true` and give `rotated` a default of `emptyList()` while still encoding it (`encodeDefaults = true` for that class).
- **React/Web**: TypeScript interfaces with optional properties (`account?: string`) and string-literal unions for the operation (`'usage' | 'token' | 'saved' | 'switch' | 'save_token' | 'save_login' | 'forget' | 'refresh'`) and the token state; validate the operation on parse, since a plain `JSON.parse` does not reject an unknown string the way Swift's decoder does, and type `state` as `string` with a separate narrowing function. `countingFrom(now: Date)` returns a new object with `secondsRemaining = expiresAt - now.getTime() / 1000`. Export `noCustodianReason` as a single shared constant so both ends compare the identical string.
- **AppKit / UIKit**: Identical to the SwiftUI note: the files are UI-framework-agnostic, and the relay is carried over XPC in the Apple implementation (the response doc comment cites the `XPCReply` reason-string convention).
- **WinUI 3**: Use C# `record` types serialized with `System.Text.Json`, `JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase, DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull }` so keys match the Swift property names and `null` fields are omitted. Model the operation as an `enum` with `[JsonStringEnumMemberName("switch")]` (or a custom `JsonConverter`) for `switch`, `save_token` and `save_login`, and leave unknown values as a `JsonException`; model `ClaudeTokenState` the same way with `rate_limited`, but keep the DTOs' `State` as `string` with a computed `TokenState` property using `Enum.TryParse`-style mapping and the per-type fallback. `CountingFrom(DateTimeOffset now)` returns `this with { SecondsRemaining = ExpiresAt - now.ToUnixTimeMilliseconds() / 1000.0, State = TokenState.ToWire() }` to keep the state normalization. Give `Rotated` an initializer of `[]` so it serializes as an empty array, and `TokenUntouched` a `bool?` with a `LeftTokenUntouched => TokenUntouched ?? false` property. The relay between the CLI, a background service and the app would run over a named pipe or `AppService` connection instead of XPC; keep `NoCustodianReason` as a `const string` shared by both ends, and store the credentials in Windows Credential Manager (`PasswordVault`) where the Apple app uses the keychain. Mark the response's properties `{ get; set; }` and every other DTO's `{ get; init; }` to mirror `var` versus `let`, and override `ToString()` on the token-bearing records if they may be logged.

<!-- No `## Reference Implementations` section is authored. Record the code that implements this
ingredient with `cookr implements <uuid|rdid> <location> --platform <p>` and `cookr confirm <uuid|rdid>`;
a compiled doc or skill shows those rows as a derived section here. -->

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/ClaudeAccountRequestDTOs.swift` | confirmed (1.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/ClaudeAccountTokenDTOs.swift` | confirmed (1.1.0) |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | Access Patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | partial | Security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | passed | Security |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because the files hold only wire shapes, two shared constants and pure accessors, with no transport, keychain or routing code. `unit-test-coverage` fails: no test in the SDK's test targets exercises these types, so none of the vectors is asserted. `api-design-conventions` passes: one envelope, explicit enums with stable raw strings, a response that fills only the fields each operation is about, and raw-string states that let an older client decode a newer daemon's reply. `error-response-handling` passes because refusals have one defined channel, the reply's reason string, the no-app refusal is a single shared constant both ends match on, and a renewal's failure carries a state, a one-line `detail` and whether the token was left untouched. `data-minimization` passes because the saved-account summary and the token status deliberately carry no secret, only what a table of accounts or a status line shows. `secure-log-output` is partial: the types never log, but the request, response, rotated-credential and renewal carry tokens with no redacting description, so a caller that logs one logs the token. `token-lifecycle` passes at the contract level: token states distinguish routine expiry from a spent refresh token, rotations and renewals are marked as the only working copy to be stored first, and `tokenUntouched` stops a possibly spent pair from being installed. `data-integrity` passes because the single-use rotation is returned on the one connection that holds the keychain item and the caller is required to store it before anything that can fail. `no-hardcoded-strings` fails because `noCustodianReason` and the seven state titles are user-visible English literals, and the exact-match contract keeps the first from being localized.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-21 | Mike Fullerton | Cover ClaudeAccountTokenDTOs.swift: token states, secret-free status with counting(from:), rotated credentials, evaluation, login renewal and the accounts document |
