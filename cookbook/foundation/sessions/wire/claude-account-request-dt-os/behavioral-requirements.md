
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

