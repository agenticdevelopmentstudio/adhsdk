---
id: 8b79c521-04f3-4a43-90db-ae6e0bba9f84
title: Hub Client Auth
domain: adhsdk://recipes/hub-client-auth
type: ingredient
version: 1.0.2
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Credential/session types, Keychain and in-memory stores, and bearer-auth
  plus refresh-and-retry middleware for the Hub Swift client.
platforms:
- swift
- macos
- ios
tags: []
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Hub Client Auth

## Overview

`hub-client-auth` is the authentication subsystem of the hub client's Swift
framework target (`Sources/Auth/`), supporting macOS 14.0+ and iOS 17.0+
(`project.yml`). It has no visual
surface: it is a set of value types (`Credentials`, `Session`), storage
protocols and concrete stores (Keychain-backed and in-memory), and two
`ClientMiddleware` implementations — `AuthenticationMiddleware` (bearer-only)
and `SessionRefreshMiddleware` (bearer plus transparent refresh-and-retry) —
that `ADHClient` attaches to every outgoing request. A thin set of convenience
wrappers on `ADHClient` (`login`, `createAPIToken`, `adopt`, `logout`, `signIn`,
`completeMfa`, `sendMfaSms`, passkey and OAuth-exchange flows, `signOut`,
`currentUser`) drive these stores and surface typed outcomes and errors instead
of the generated OpenAPI request/response shapes. This recipe covers exactly
the nine files under `Sources/Auth/`; `ADHClient` itself, its transports, and
`rawJSON` are referenced only where the Auth files call into them.

## Behavioral Requirements

### Credentials and Session data types (`Credentials.swift`, `Session.swift`)

- **credentials-shape**: `Credentials` MUST be a `Sendable, Equatable, Codable` struct with a mutable `token: String` and `kind: Kind`, where `Kind` is a `String`-backed enum with cases `jwt` and `apiToken`.
- **credentials-transmission-uniformity**: Both `Kind` values MUST be sent identically as `Authorization: Bearer <token>` — `kind` is informational only and MUST NOT change how the token is transmitted.
- **credentials-redaction**: `Credentials` MUST override `CustomStringConvertible`/`CustomDebugStringConvertible` to print exactly `Credentials(kind: <kind>, token: <redacted>)`, never the raw token, so logging or a failed test assertion cannot leak a live bearer token.
- **credentials-redaction-value-semantics**: Redaction MUST be presentation-only: `Credentials` equality, hashing through `Codable` round-trips, and the underlying `token`/`kind` values MUST be unchanged by the custom description.
- **session-shape**: `Session` MUST be a `Sendable, Equatable, Codable` struct with `credentials: Credentials` and an optional `refreshToken: String?`, defaulting `refreshToken` to `nil` in its initializer.
- **session-refresh-token-optionality**: A `Session` for an API-token credential MUST carry `refreshToken == nil`; only password/MFA/passkey/OAuth sign-ins populate a refresh token.
- **session-redaction**: `Session`'s custom description MUST print exactly `Session(kind: <kind>, token: <redacted>, refreshToken: <none|<redacted>>)` — neither the access token nor the refresh token is ever printed, but whether a refresh token is present IS reported.

### Storage protocols (`CredentialStore.swift`, `SessionStore.swift`)

- **credential-provider-contract**: `CredentialProvider` MUST be a `Sendable` protocol exposing `currentCredentials() -> Credentials?`, read by middleware at request time (not at client-construction time) so a rotated credential takes effect on the next request without rebuilding the client.
- **credential-store-contract**: `CredentialStore` MUST extend `CredentialProvider` with `save(_ credentials: Credentials)` and `clear()`.
- **session-store-contract**: `SessionStore` MUST extend `CredentialStore` with `currentSession() -> Session?` and `save(_ session: Session)`.
- **session-store-credential-derivation**: `SessionStore`'s default protocol extension MUST derive `currentCredentials()` as `currentSession()?.credentials`.
- **session-store-adopt-drops-refresh**: `SessionStore`'s default `save(_ credentials: Credentials)` MUST replace the whole session with `Session(credentials: credentials, refreshToken: nil)` — adopting a bare credential (e.g. an API token) MUST discard any previously stored refresh token.

### Concrete stores

- **keychain-credential-store-namespacing**: `KeychainCredentialStore.init(keyPrefix:)` MUST default `keyPrefix` to `"adh.api"` and derive exactly two Keychain account keys, `<prefix>.token` and `<prefix>.token.kind`.
- **keychain-credential-store-statelessness**: `KeychainCredentialStore` MUST hold no in-memory state; every `currentCredentials()`/`save`/`clear()` call MUST read or write the Keychain directly, so the value survives process restarts and is shared across instances with the same prefix and `KeychainHelper.service`.
- **keychain-credential-store-kind-fallback**: `KeychainCredentialStore.currentCredentials()` MUST default `kind` to `.jwt` when the stored kind key is missing or fails to parse as a `Credentials.Kind` raw value.
- **in-memory-credential-store-thread-safety**: `InMemoryCredentialStore` MUST be a `final class, @unchecked Sendable` guarding its single `Credentials?` with an `NSLock` on every read and write.
- **in-memory-session-store-thread-safety**: `InMemorySessionStore` MUST be a `final class, @unchecked Sendable` guarding its single `Session?` with an `NSLock` on every read and write.
- **keychain-session-store-three-keys**: `KeychainSessionStore.init(keyPrefix:)` MUST default `keyPrefix` to `"adh.api"` and derive three keys: `<prefix>.token`, `<prefix>.token.kind`, `<prefix>.refresh`.
- **keychain-session-store-shared-prefix-compat**: `KeychainSessionStore` MUST share its `.token`/`.token.kind` key names with `KeychainCredentialStore` under the same prefix, so a credential saved by one store is readable by the other as a session with no refresh token, and a session saved here is readable there as its bare credentials.
- **keychain-session-store-save-order**: `KeychainSessionStore.save(_ session:)` MUST write the token and kind unconditionally, then either write `refreshToken` to `<prefix>.refresh` when non-nil or delete that key when `refreshToken == nil` — adopting an API token (no refresh token) into a store that previously held a JWT session MUST remove the stale refresh token from the Keychain.
- **keychain-session-store-clear**: `KeychainSessionStore.clear()` MUST delete all three keys (token, kind, refresh).

### `KeychainHelper`

- **keychain-helper-service-default**: `KeychainHelper.service` MUST default to `Bundle.main.bundleIdentifier`, falling back to a hardcoded literal reverse-DNS bundle-identifier string naming the hub client itself when the bundle identifier is `nil`. It is declared `nonisolated(unsafe) public static var`: the type does not synchronize reads or writes of this global, so a caller that reassigns `service` MUST do so before any concurrent Keychain access begins, per Swift's declaration-level isolation for a `nonisolated(unsafe)` value.
- **keychain-helper-set-overwrite**: `KeychainHelper.set(_:forKey:)` MUST delete any existing item for the key and then `SecItemAdd` the new value — an overwrite, never an update-in-place.
- **keychain-helper-ios-accessibility**: On iOS, `set(_:forKey:)` MUST set `kSecAttrAccessible` to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so a background refresh can read the token after the device's first unlock, and the item never leaves the device via backup or Keychain sync.
- **keychain-helper-macos-accessibility**: On macOS, `set(_:forKey:)` MUST leave `kSecAttrAccessible` unset (the implicit default) because the file-based legacy Keychain rejects or ignores an explicit accessibility class unless the item also opts into the data-protection Keychain, and that migration is out of this component's scope.
- **keychain-helper-get**: `get(forKey:)` MUST return the UTF-8-decoded string for the key, or `nil` when the item is absent or the query otherwise fails.
- **keychain-helper-delete-idempotent**: `delete(forKey:)` MUST return `true` for both `errSecSuccess` and `errSecItemNotFound` — deleting an absent item is not an error.
- **keychain-helper-exists**: `exists(forKey:)` MUST return whether `SecItemCopyMatching` succeeds for the key, without decoding the stored value.
- **keychain-helper-error-logging**: A failed `set` or a `get` failure other than `errSecItemNotFound` MUST log the key name and the `OSStatus` at `.error` level via an `os.Logger` scoped to the hub client's own reverse-DNS subsystem identifier and the `Keychain` category, and MUST NOT log the stored value.

### `AuthenticationMiddleware`

- **authentication-middleware-bearer-injection**: `AuthenticationMiddleware.intercept` MUST set `Authorization: Bearer <token>` on every outgoing request when `credentials.currentCredentials()?.token` is non-nil.
- **authentication-middleware-no-header-when-unauthenticated**: When `currentCredentials()` returns `nil`, `AuthenticationMiddleware` MUST forward the request with no `Authorization` header rather than an empty or placeholder one.
- **authentication-middleware-runtime-read**: The middleware MUST read the credential at send time (inside `intercept`), never cache it at construction, so a credential rotated after the client was built is picked up on the next request without rebuilding the client.

### `SessionRefreshMiddleware` and `RefreshCoordinator`

- **session-refresh-bearer-injection**: `SessionRefreshMiddleware.intercept` MUST attach `Authorization: Bearer <token>` from the current session's credentials before the first attempt, identically to `AuthenticationMiddleware`.
- **session-refresh-body-buffering**: `intercept` MUST buffer the entire outgoing request body via `Data(collecting:upTo: ADHBodyLimit.maxBuffered)` (16 MiB) for every request, not only ones that eventually fail, so the same body bytes can be resent unchanged on a post-refresh retry.
- **session-refresh-passthrough-non-401**: A response that is not HTTP 401 MUST be returned unchanged, with no refresh attempt.
- **session-refresh-exempt-operations**: A 401 on an operation whose ID is in `SessionRefreshMiddleware.exemptOperationIDs` MUST be returned unchanged with no refresh attempt. That set MUST be derived from the generated `Operations.X.id` constants (`PostAuthLogin`, `PostAuthLoginMfa`, `PostAuthLoginMfaSmsSend`, `PostAuthLoginMfaWebauthn`, `PostAuthLoginMfaWebauthnOptions`, `PostAuthLoginWebauthn`, `PostAuthLoginWebauthnOptions`, `PostAuthRefresh`, `PostOauthSigninExchange`) plus `ADHClient.revokeRawOperationID`, never hand-written string literals, so a renamed or removed generated operation fails to compile instead of silently rotting the exemption list.
- **session-refresh-no-session-passthrough**: A 401 with no current session, an API-token session (`kind != .jwt`), or a JWT session with no `refreshToken` MUST be returned unchanged with no refresh attempt.
- **session-refresh-trigger**: A 401 on a non-exempt operation, for a JWT session that has a non-nil `refreshToken`, MUST trigger exactly one refresh attempt through `RefreshCoordinator.shared`.
- **session-refresh-refreshed-retry**: When the refresh outcome is `.refreshed(rotated)`, the middleware MUST retry the original request exactly once with `Authorization: Bearer <rotated token>` and the same buffered body, and MUST return that retry's response (whatever its status).
- **session-refresh-rejected-clears**: When the refresh outcome is `.rejected`, the middleware MUST clear the session store, invoke `onSessionExpired`, and return the ORIGINAL 401 response — a rejected refresh (invalid/expired refresh token) ends the local session.
- **session-refresh-unavailable-preserves**: When the refresh outcome is `.unavailable`, the middleware MUST leave the session store untouched, MUST NOT call `onSessionExpired`, and MUST return the original 401 — a 5xx or transport-error refresh attempt (backend unreachable) MUST NEVER sign the user out locally.
- **refresh-perform-status-mapping**: `SessionRefreshMiddleware.performRefresh` MUST post `{"refreshToken": <token>}` to `/auth/refresh` and map HTTP 200 with a decodable `{token, refreshToken}` body to `.refreshed`, HTTP 401 or 403 to `.rejected`, and any other status, a request-encoding failure, or a thrown transport error to `.unavailable`.
- **refresh-coordinator-shared-instance**: Refreshes MUST serialize through the single process-wide `RefreshCoordinator.shared` actor, not one coordinator per `SessionRefreshMiddleware` instance, because the single-use refresh token lives in the (possibly shared) `SessionStore`, and a per-instance coordinator would let two clients over one store each lead a refresh and have the loser's replay rejected by the server.
- **refresh-coordinator-leader-follower**: The first caller for a given expired access token (`previousToken`) MUST run `perform` directly as the leader; a caller that arrives while a refresh for the SAME `previousToken` is in flight MUST queue as a follower and receive the leader's outcome instead of spending the single-use refresh token again.
- **refresh-coordinator-follower-token-mismatch**: A follower whose `previousToken` differs from the in-flight leader's MUST be resumed with `nil` and re-evaluate from the top rather than inherit the leader's outcome.
- **refresh-coordinator-late-arrival**: A caller that reaches the coordinator holding a token the store has already rotated away from MUST receive `.refreshed` with the store's current session directly, without performing a network refresh.
- **refresh-coordinator-save-before-resume**: The leader MUST save the rotated session (via the `save` closure) before resuming any follower's continuation, so every follower released from `await` sees the store already rotated.
- **refresh-coordinator-nonescaping-closures**: `perform`, `currentSession`, and `save` MUST remain non-escaping parameters of `RefreshCoordinator.refresh`, because `perform` closes over the non-escaping `next` closure `ClientMiddleware.intercept` provides; the leader MUST call `perform` in place (a plain `await`) rather than scheduling it on a detached `Task`.

### `ADHClient+Auth` wrappers (`login`, `createAPIToken`, `adopt`, `logout`)

- **login-persists-jwt**: `login(email:password:)` MUST `POST /auth/login`, and on success MUST persist `Credentials(token: <response token>, kind: .jwt)` through the client's `credentials` store before returning the decoded `AuthResponse`.
- **create-api-token-returns-secret**: `createAPIToken(name:expiresAt:)` MUST `POST /auth/tokens` and return the decoded `CreatedAPIToken` (`Components.Schemas.ApiTokenCreated`), whose one-time raw secret is at `.value2.token`.
- **create-api-token-does-not-persist**: `createAPIToken` MUST NOT write to the credential store — minting a new API token MUST leave the currently active credential untouched; the caller must call `adopt(_:)` to switch to it.
- **adopt-switches-active-credential**: `adopt(_ credentials:)` MUST call `self.credentials.save(credentials)`, switching the client to that credential for subsequent requests.
- **logout-clears-locally-only**: `logout()` MUST call `credentials.clear()` synchronously and MUST NOT make any network call — it is a local-only forget, unlike `signOut()` below, which best-effort revokes server-side.

### `ADHClient+Session` wrappers (sign-in family, passkeys, OAuth exchange, sign-out, current user)

- **session-wrappers-require-session-store**: Every session wrapper except `signOut()` and `currentUser()` MUST call a private `sessionStore()` that throws `SessionError.notASessionClient` when the client was built via `init(transport:credentials:)` (no `SessionStore`) rather than `init(transport:session:onSessionExpired:)`.
- **sign-in-outcome-signed-in**: `signIn(email:password:)` MUST `POST /auth/login`; an `.ok` response MUST store `Session(credentials: Credentials(token:, kind: .jwt), refreshToken:)` and return `.signedIn(user)`.
- **sign-in-outcome-mfa-required**: An `.accepted` response from `signIn` MUST return `.mfaRequired(challenge)` and MUST NOT store any session.
- **sign-in-invalid-credentials**: A `.unauthorized` response from `signIn` MUST throw `SessionError.invalidCredentials`.
- **sign-in-undocumented-response**: An `.undocumented(status, _)` response from `signIn` MUST throw `SessionError.unexpectedResponse("HTTP <status>")`.
- **complete-mfa-method-mapping**: `MfaMethod` (`.sms`, `.totp`, `.recovery`) MUST map 1:1 to the generated `Operations.PostAuthLoginMfa.Input.Body.JsonPayload.MethodPayload` case via its `payload` property.
- **complete-mfa-persists-and-returns-user**: `completeMfa(challengeToken:method:code:)` MUST `POST /auth/login/mfa` and, on `.ok`, store the session and return the `User`; it MUST map `.unauthorized` to `.invalidCredentials` and `.badRequest`/`.conflict` to `.unexpectedResponse` carrying the backend's decoded message.
- **send-mfa-sms**: `sendMfaSms(challengeToken:)` MUST `POST /auth/login/mfa/sms/send` and return normally on `.accepted`, mapping `.unauthorized`, `.badRequest`, `.conflict`, `.unprocessableContent`, and `.tooManyRequests` each to the corresponding `SessionError`.
- **passkey-options-shape**: `passkeyOptions(identifier:)` MUST `POST /auth/login/webauthn/options` and return a `PasskeyOptions(token:, options:)` where `options` is the raw `OpenAPIObjectContainer` WebAuthn `PublicKeyCredentialRequestOptionsJSON`, passed through uninterpreted.
- **complete-passkey-persists-and-returns-user**: `completePasskey(challengeToken:response:)` MUST `POST /auth/login/webauthn` with the given assertion `response` wrapped as `additionalProperties`, and on `.ok` MUST store the session and return the `User`.
- **mfa-passkey-options-rotated-token**: `mfaPasskeyOptions(challengeToken:)` MUST `POST /auth/login/mfa/webauthn/options` and return a `PasskeyOptions` whose `.token` MAY differ from the input `challengeToken` (the backend may rotate the pending challenge); callers MUST send the returned token, not the original, to `completeMfaPasskey`.
- **complete-mfa-passkey-persists-and-returns-user**: `completeMfaPasskey(challengeToken:response:)` MUST `POST /auth/login/mfa/webauthn` and, on `.ok`, store the session and return the `User`.
- **oauth-exchange-path-constant**: `ADHClient.oauthExchangePath` MUST equal `"/oauth/signin/exchange"`, shared between the typed and raw exchange paths and any middleware exemption keyed on it.
- **oauth-exchange-typed-path**: `exchangeOAuthCode(_:userAgent: nil)` MUST call the generated `postOauthSigninExchange` operation; on `.ok` it MUST store the session and return the `User`, mapping `.unauthorized` to `.invalidCredentials` and `.badRequest`/`.undocumented` accordingly.
- **oauth-exchange-native-user-agent**: When `userAgent` is non-nil, `exchangeOAuthCode` MUST route through `rawJSON(method: .post, path: oauthExchangePath, body:, headers: ["User-Agent": userAgent])` instead of the generated operation, because the backend binds an exchange code to the `User-Agent` of the browser that originally received it and the generated request has no place for that header; a native caller MUST supply the captured browser `User-Agent` or every redemption 401s with a code already consumed by the browser's own (nil-`User-Agent`) attempt.
- **oauth-exchange-raw-error-mapping**: The raw exchange path MUST map a caught `RawRequestError` to `SessionError` identically to the typed path: `.invalidPath` becomes `.unexpectedResponse`, `.http(401, _)` becomes `.invalidCredentials`, and any other `.http(status, body)` becomes `.unexpectedResponse` carrying the decoded backend message or `"HTTP <status>"` when the body does not decode.
- **error-message-extraction**: The private `message(_:)` helper MUST extract a human-readable message from `Components.Schemas._Error` as `error.error?.message ?? error.error?.code ?? "unknown error"` — the nested `error` payload and both its fields are optional in the generated schema.
- **sign-out-best-effort-revoke**: `signOut()` MUST, when the session has a `refreshToken`, attempt `POST /auth/revoke` with `{"refreshToken": <token>}` via `rawJSON`, wrapped in `try?` — a failed or unreachable revoke MUST NOT prevent the local session from being cleared, because a dead backend must not keep the user signed in locally.
- **sign-out-revoke-body-workaround**: The revoke call MUST go through `rawJSON` rather than the generated `postAuthRevoke` operation, because the committed `openapi.json` describes `POST /auth/revoke` as a bodiless 204 while the backend actually requires the refresh token in the request body; the generated operation cannot express this request, so the raw path is what makes revocation work at all.
- **sign-out-revoke-exempt-from-refresh**: The revoke request MUST be exempt from refresh-and-retry (`ADHClient.revokeRawOperationID` is a member of `SessionRefreshMiddleware.exemptOperationIDs`) — signing out with an already-expired access token 401s, and refreshing mid-revoke would rotate the single-use refresh token and resend the now-stale one, which the server can no longer match.
- **sign-out-always-clears**: `signOut()` MUST call `session.clear()` unconditionally after the best-effort revoke attempt (or immediately, when there is no `refreshToken` to revoke), and MUST return without throwing regardless of the revoke's outcome.
- **sign-out-silent-when-not-a-session-client**: Unlike every other session wrapper except `currentUser()`, `signOut()` MUST NOT throw `SessionError.notASessionClient` when the client has no `SessionStore` (`session == nil`) — it MUST simply return, making it safe to call on any `ADHClient` regardless of how it was built.
- **current-user-fetch**: `currentUser()` MUST `GET /auth/me` and return the decoded `User` on `.ok`, mapping `.unauthorized` to `SessionError.invalidCredentials` and `.undocumented(status, _)` to `.unexpectedResponse("HTTP <status>")`; unlike the other session wrappers, it MUST NOT call `sessionStore()` first, so it also works on a client built via `init(transport:credentials:)` with no `SessionStore` — the bearer credential alone authenticates the request.

## Appearance

Not applicable — this is a non-UI authentication and session-management component, not a visual component.

## States

Not applicable — this is a non-UI authentication and session-management component, not a visual component. Its runtime state machines (signed-out / signed-in / MFA-pending / refreshing / expired) are specified under Behavioral Requirements, not as a visual-state table.

## Accessibility

Not applicable — this is a non-UI authentication and session-management component, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| hub-client-auth-001 | login-persists-jwt | `login(email: "a@b.c", password: "pw")` against a mock returning `token: "jwt-xyz"` | `store.currentCredentials() == Credentials(token: "jwt-xyz", kind: .jwt)` (`AuthWrappersTests.swift`, "login persists the returned JWT") |
| hub-client-auth-002 | create-api-token-does-not-persist | `createAPIToken(name: "ci")` on a store already holding `jwt-existing` | returned token is `"tok-secret"`; `store.currentCredentials()?.token == "jwt-existing"` unchanged (`AuthWrappersTests.swift`, "createAPIToken returns the secret but leaves the active credential untouched") |
| hub-client-auth-003 | adopt-switches-active-credential, logout-clears-locally-only | `adopt(Credentials(token: "tok-secret", kind: .apiToken))` then `logout()` | store holds the adopted credential, then `nil` after logout (`AuthWrappersTests.swift`, "adopt switches the client to a credential; logout clears it") |
| hub-client-auth-004 | sign-in-outcome-signed-in | `signIn(email:password:)` with mock `.ok` + auth JSON | `.signedIn(user)` with `user.id == "u1"`; store holds `Session(Credentials("jwt-1", .jwt), refreshToken: "r-1")` (`SessionWrappersTests.swift`, "signIn with a password stores the session and returns the user") |
| hub-client-auth-005 | sign-in-outcome-mfa-required | `signIn` with mock `.accepted` + MFA JSON | `.mfaRequired(challenge)` with `challenge.token == "mfa-tok"`; `store.currentSession() == nil` (`SessionWrappersTests.swift`, "signIn surfaces an MFA challenge without storing anything") |
| hub-client-auth-006 | sign-in-invalid-credentials | `signIn` with mock `.unauthorized` | throws `SessionError.invalidCredentials` (`SessionWrappersTests.swift`, "signIn maps 401 to invalidCredentials") |
| hub-client-auth-007 | complete-mfa-persists-and-returns-user | `completeMfa(challengeToken: "mfa-tok", method: .totp, code: "123456")` | posts to `/auth/login/mfa`; `user.id == "u1"`; `store.currentSession()?.refreshToken == "r-1"` (`SessionWrappersTests.swift`, "completeMfa posts token/method/code and stores the session") |
| hub-client-auth-008 | send-mfa-sms | `sendMfaSms(challengeToken: "mfa-tok")` with mock `.accepted` | posts to `/auth/login/mfa/sms/send`, returns normally (`SessionWrappersTests.swift`, "sendMfaSms posts the challenge token") |
| hub-client-auth-009 | passkey-options-shape | `passkeyOptions(identifier: "a@b.c")` | posts to `/auth/login/webauthn/options`; `result.token == "pk-tok"`, `result.options.value["challenge"] as? String == "abc"` (`SessionWrappersTests.swift`, "passkeyOptions returns the challenge token and the raw options object") |
| hub-client-auth-010 | complete-passkey-persists-and-returns-user | `completePasskey(challengeToken: "pk-tok", response:)` | posts to `/auth/login/webauthn`; `user.id == "u1"`; session token `"jwt-1"` stored (`SessionWrappersTests.swift`, "completePasskey stores the session") |
| hub-client-auth-011 | mfa-passkey-options-rotated-token | `mfaPasskeyOptions(challengeToken: "mfa-tok")` | posts to `/auth/login/mfa/webauthn/options`; returns rotated `result.token == "mfa-tok-2"` (`SessionWrappersTests.swift`, "mfaPasskeyOptions returns the rotated challenge token and raw options") |
| hub-client-auth-012 | complete-mfa-passkey-persists-and-returns-user | `completeMfaPasskey(challengeToken: "mfa-tok-2", response:)` | posts to `/auth/login/mfa/webauthn`; session stored (`SessionWrappersTests.swift`, "completeMfaPasskey stores the session") |
| hub-client-auth-013 | oauth-exchange-typed-path | `exchangeOAuthCode("code-1")` (no `userAgent`) | posts to `/oauth/signin/exchange`; `user.id == "u1"`; session stored (`SessionWrappersTests.swift`, "exchangeOAuthCode stores the session") |
| hub-client-auth-014 | sign-out-best-effort-revoke, sign-out-revoke-body-workaround | `signOut()` with a stored refresh token `"r-1"`, mock returns `.serviceUnavailable` | request path `/auth/revoke`, body `{"refreshToken":"r-1"}`; `store.currentSession() == nil` after, despite the failed revoke (`SessionWrappersTests.swift`, "signOut revokes the refresh token and clears the store, even if revoke fails") |
| hub-client-auth-015 | sign-out-revoke-exempt-from-refresh | `signOut()` where the revoke itself 401s | only one request is recorded (`/auth/revoke`), no `/auth/refresh` call; operation ID equals `ADHClient.revokeRawOperationID`; session cleared (`SessionWrappersTests.swift`, "a 401 on revoke does not trigger a refresh") |
| hub-client-auth-016 | current-user-fetch | `currentUser()` against `/auth/me` returning capabilities `["x"]` | `user.capabilities == ["x"]` (`SessionWrappersTests.swift`, "currentUser decodes GET /auth/me") |
| hub-client-auth-017 | session-wrappers-require-session-store | `signIn(...)` on an `ADHClient` built with `credentials:` (no `SessionStore`) | throws `SessionError.notASessionClient` (`SessionWrappersTests.swift`, "wrappers refuse a credentials-only client") |
| hub-client-auth-018 | authentication-middleware-bearer-injection, authentication-middleware-no-header-when-unauthenticated | typed `get/health` call with and without a stored credential | `Authorization: Bearer tok-abc` present when authenticated, header `nil` when not (`ADHClientWiringTests.swift`, "authHeaderInjected" / "noAuthHeaderWhenUnauthenticated") |
| hub-client-auth-019 | session-refresh-bearer-injection, session-refresh-passthrough-non-401 | one `.ok` response through `SessionRefreshMiddleware` for a JWT session | `response.status == .ok`; exactly one call recorded with `Authorization: Bearer jwt-1` (`SessionRefreshMiddlewareTests.swift`, "attaches the session bearer and passes a non-401 response through") |
| hub-client-auth-020 | session-refresh-no-session-passthrough | 401 through `SessionRefreshMiddleware` with an empty `InMemorySessionStore` | `response.status == .unauthorized`; one call, no `Authorization` header, no refresh attempted (`SessionRefreshMiddlewareTests.swift`, "no session → no Authorization header, no refresh attempt on 401") |
| hub-client-auth-021 | session-refresh-trigger, session-refresh-refreshed-retry, refresh-perform-status-mapping | 401 then `.ok` refresh JSON then `.ok` retry, for a JWT session with a refresh token | 3 calls total: `/auth/refresh` (no auth header, body `{"refreshToken":"r-retry"}`) then the retried original request with `Authorization: Bearer jwt-2` and the SAME request body; store now holds `Credentials("jwt-2", .jwt)`/`refreshToken: "r-2"` (`SessionRefreshMiddlewareTests.swift`, "401 on a JWT session refreshes, saves the rotated session, and retries once with the new bearer") |
| hub-client-auth-022 | session-refresh-rejected-clears | 401 then a 401 refresh response with an "invalid or expired refresh token" body | 2 calls; `store.currentSession() == nil`; `onSessionExpired` invoked exactly once; response returned is the original 401 (`SessionRefreshMiddlewareTests.swift`, "a rejected refresh clears the session and reports expiry; the original 401 is returned") |
| hub-client-auth-023 | session-refresh-unavailable-preserves | 401 then a `.serviceUnavailable` refresh response | session's token unchanged; `onSessionExpired` NOT invoked; response returned is the original 401 (`SessionRefreshMiddlewareTests.swift`, "an unavailable refresh (5xx) keeps the session and returns the original 401") |
| hub-client-auth-024 | refresh-perform-status-mapping | `next` throws `URLError(.notConnectedToInternet)` when called for `/auth/refresh` | outcome treated as `.unavailable`; session token unchanged; original 401 returned (`SessionRefreshMiddlewareTests.swift`, "a transport error during refresh keeps the session and returns the original 401") |
| hub-client-auth-025 | session-refresh-exempt-operations | 401 for each ID in `SessionRefreshMiddleware.exemptOperationIDs` | every one is returned unchanged with exactly one call and no refresh attempted (`SessionRefreshMiddlewareTests.swift`, "exempt operations (the login family, refresh itself, and the raw revoke) never trigger a refresh") |
| hub-client-auth-026 | session-refresh-exempt-operations | compare `SessionRefreshMiddleware.exemptOperationIDs` to the literal generated ID strings | set equals `{"post/auth/login", "post/auth/login/mfa", "post/auth/login/mfa/sms/send", "post/auth/login/mfa/webauthn", "post/auth/login/mfa/webauthn/options", "post/auth/login/webauthn", "post/auth/login/webauthn/options", "post/auth/refresh", "post/oauth/signin/exchange", "raw POST /auth/revoke"}`, excludes `"postAuthLogin"` and `Operations.GetAuthMe.id` (`SessionRefreshMiddlewareTests.swift`, "the exemption set is exactly the generated, path-style operation IDs") |
| hub-client-auth-027 | session-refresh-no-session-passthrough | 401 for an API-token session (`kind: .apiToken`) | one call, no refresh, session token unchanged (`SessionRefreshMiddlewareTests.swift`, "an API-token session is never refreshed") |
| hub-client-auth-028 | session-refresh-no-session-passthrough | 401 for a JWT session with `refreshToken: nil` | one call, no refresh attempted (`SessionRefreshMiddlewareTests.swift`, "a JWT session without a refresh token is not refreshed") |
| hub-client-auth-029 | refresh-coordinator-leader-follower | two concurrent `intercept` calls sharing one store both hit 401 | exactly one `/auth/refresh` call is made; both callers resolve `.ok`; final token is `"jwt-2"` (`SessionRefreshMiddlewareTests.swift`, "concurrent 401s share one refresh") |
| hub-client-auth-030 | refresh-coordinator-shared-instance, refresh-coordinator-save-before-resume | two separate `ADHClient`s (two `SessionRefreshMiddleware` instances) over ONE shared `SessionStore`, concurrent 401s | exactly one refresh call; `onSessionExpired` never fires; store ends with the single rotated session (`SessionRefreshMiddlewareTests.swift`, "two clients over one store share a single refresh and neither clears the session") |
| hub-client-auth-031 | refresh-coordinator-follower-token-mismatch | two `SessionRefreshMiddleware`s over two DIFFERENT stores, concurrent 401s | each store gets its own independent refresh and its own rotated pair; two refresh calls total (`SessionRefreshMiddlewareTests.swift`, "two middlewares over two different stores each get their own refresh") |
| hub-client-auth-032 | session-refresh-body-buffering | 401/refresh/retry sequence carrying a JSON request body `{"name":"x"}` on a `PATCH` operation | the retried request (call index 2) carries the identical body bytes (`SessionRefreshMiddlewareTests.swift`, "401 on a JWT session refreshes, saves the rotated session, and retries once with the new bearer") |
| hub-client-auth-033 | keychain-session-store-three-keys | `KeychainSessionStore(keyPrefix: "adh.test")` | `tokenKey == "adh.test.token"`, `kindKey == "adh.test.token.kind"`, `refreshKey == "adh.test.refresh"` (`SessionStoreTests.swift`, "keychain store derives its three keys from the prefix") |
| hub-client-auth-034 | keychain-session-store-save-order | save a session with a refresh token, then save bare `Credentials(kind: .apiToken)` on the same prefix | `refreshKey` item exists after the first save, is deleted after the second; `currentSession()` reports `refreshToken: nil` (`SessionStoreTests.swift`, `KeychainSessionStoreTests`, "saving a session with no refresh token deletes a previously stored one") |
| hub-client-auth-035 | keychain-session-store-clear | `clear()` on a populated `KeychainSessionStore` | all three keys absent; `currentSession()`/`currentCredentials()` both `nil` (`SessionStoreTests.swift`, `KeychainSessionStoreTests`, "clear removes all three keys") |
| hub-client-auth-036 | keychain-session-store-shared-prefix-compat | save via `KeychainCredentialStore(keyPrefix:)`, read via `KeychainSessionStore(keyPrefix:)` with the same prefix, and vice versa | credential written by one store is visible as a session (no refresh token) via the other, and a session's credentials are visible via the older store (`SessionStoreTests.swift`, `KeychainSessionStoreTests`, "round-trips with KeychainCredentialStore under the same prefix") |
| hub-client-auth-037 | session-store-adopt-drops-refresh | `InMemorySessionStore` holding a session with `refreshToken: "r-1"`, then `save(Credentials(kind: .apiToken))` | resulting session has `refreshToken: nil` (`SessionStoreTests.swift`, "saving bare credentials drops any refresh token (an API token has none)") |
| hub-client-auth-038 | credentials-redaction, session-redaction | `"\(credentials)"`, `String(reflecting:)`, and the same for `Session` with and without a refresh token | none of the strings contain the raw access or refresh token; `Session` without a refresh token prints `refreshToken: none` (`SessionStoreTests.swift`, `CredentialRedactionTests`, "Credentials never prints its token" / "Session never prints either token but reports whether a refresh token is present") |
| hub-client-auth-039 | credentials-redaction-value-semantics | encode/decode a `Session` through `JSONEncoder`/`JSONDecoder` after asserting its redacted description | round-trips equal; `session.credentials.token` and `session.refreshToken` still hold the real values (`SessionStoreTests.swift`, `CredentialRedactionTests`, "redaction does not change value semantics") |
| hub-client-auth-040 | oauth-exchange-native-user-agent, sign-out-revoke-body-workaround (raw path shares `rawJSON`) | `rawJSON(method: .get, path: "/organization/organizations", query: ["workspace": "a b"])` on a session client | request runs through the session middleware, bearer attached, query percent-encoded to `?workspace=a%20b` (`RawJSONTests.swift`, "runs through the session middleware: bearer attached, query encoded, body forwarded") |
| hub-client-auth-041 | session-refresh-trigger (via `rawJSON`) | `rawJSON` call 401s, refresh succeeds | request is retried and succeeds like any typed operation (`RawJSONTests.swift`, "a 401 is refreshed and retried like any typed operation") |
| hub-client-auth-042 | oauth-exchange-raw-error-mapping (shared `RawRequestError`) | `rawJSON` receives a 404 | throws `RawRequestError.http(status: 404, body: <error body>)` (`RawJSONTests.swift`, "status >= 400 throws RawRequestError.http with the body") |
| hub-client-auth-043 | oauth-exchange-raw-error-mapping | `rawJSON(path: "billing/context")` (no leading slash) | throws `RawRequestError.invalidPath("billing/context")` (`RawJSONTests.swift`, "a path without a leading slash is rejected") |

## Edge Cases

- **Empty/malformed sign-in input**: `email`, `password`, `code`, and challenge tokens are passed straight through to the generated request body with no client-side validation (traced to source: no validation code exists in `ADHClient+Auth.swift` or `ADHClient+Session.swift`); the backend is the sole point of validation, surfaced back as `.badRequest`/`.unprocessableContent` → `SessionError.unexpectedResponse`.
- **Request body larger than the buffering cap**: `SessionRefreshMiddleware.intercept` buffers the entire request body via `Data(collecting:upTo: ADHBodyLimit.maxBuffered)` (16 MiB, shared with `rawJSON`'s response buffering) before the first send; a body larger than that limit fails during buffering before any request is issued.
- **Concurrent 401s on one store, one middleware instance**: coalesced into a single refresh (`hub-client-auth-029`).
- **Concurrent 401s on one store, two middleware instances (two `ADHClient`s)**: still coalesced into a single refresh via the process-wide `RefreshCoordinator.shared` (`hub-client-auth-030`); a per-instance coordinator would have let both lead and had the loser's replay of the single-use refresh token rejected by the server.
- **Concurrent 401s on two different stores**: each gets its own independent refresh; a follower whose `previousToken` does not match the in-flight leader's re-evaluates rather than sharing an unrelated outcome (`hub-client-auth-031`).
- **A caller arriving after a refresh already completed**: is handed `.refreshed` with the store's current session directly, without a network round-trip, per `refresh-coordinator-late-arrival`.
- **Offline / unreachable backend during refresh**: a thrown transport error (e.g. `URLError(.notConnectedToInternet)`) or any non-200/401/403 status from `/auth/refresh` is treated as `.unavailable` — the session is preserved and the original 401 is returned to the caller, never a forced sign-out (`hub-client-auth-023`, `hub-client-auth-024`).
- **Refresh token rejected (rotated or revoked elsewhere)**: `.rejected` clears the local session and fires `onSessionExpired` even though the failing request's own response is still the original 401 (`hub-client-auth-022`).
- **Sign-out with an already-expired access token**: the revoke call itself may 401; this is exempt from refresh-and-retry so it is never retried with a rotated refresh token that the revoke body no longer carries, and the session is cleared locally regardless (`hub-client-auth-015`).
- **Sign-out with no refresh token**: `signOut()` skips the revoke network call entirely (the `if let refreshToken = ...` guard) and clears the session immediately.
- **Sign-out on a client that has no `SessionStore`**: unlike every other session wrapper except `currentUser()`, `signOut()` returns silently instead of throwing `SessionError.notASessionClient` (`sign-out-silent-when-not-a-session-client`).
- **`currentUser()` on a client that has no `SessionStore`** (built via `init(transport:credentials:)`): it never calls `sessionStore()`, so it does not throw `SessionError.notASessionClient` either — it sends `GET /auth/me` authenticated by the stored credential and returns the `User` normally (`current-user-fetch`).
- **Missing Keychain item**: `KeychainHelper.get(forKey:)` and `exists(forKey:)` both treat `errSecItemNotFound` as an unlogged, ordinary "absent" result, not an error.
- **Adopting an API token over an existing JWT session**: `KeychainSessionStore.save` and the `SessionStore` default `save(_ credentials:)` both drop the previous refresh token so it cannot be replayed against a session that no longer matches it (`hub-client-auth-034`, `hub-client-auth-037`).
- **`_Error` payload with neither `message` nor `code`**: `message(_:)` falls back to the literal string `"unknown error"` rather than throwing or returning an empty string.
- **WebAuthn `options`/`response` payloads**: passed through as opaque `OpenAPIObjectContainer` values with no client-side schema validation beyond what `Codable`/`JSONSerialization` impose when constructing them.

- **Keychain save failures are logged, not surfaced to the caller**: `KeychainHelper.set(_:forKey:)` is `@discardableResult`, and both call sites (`KeychainCredentialStore.save`, `KeychainSessionStore.save`) discard the returned `Bool`; a failed `SecItemAdd` is logged at `.error` (see Logging) but `save` itself returns `Void`, so `login`, `adopt`, and session-refresh persistence proceed as though the write succeeded.
- **`KeychainSessionStore.save` writes its three keys non-atomically**: `tokenKey`, `kindKey`, and (conditionally) `refreshKey` are written as three independent `SecItemAdd`/`SecItemDelete` calls with no rollback; a crash or process termination between them can leave a mixed old/new triple in the Keychain (e.g. a new token paired with a stale refresh token), with no recovery path in this code.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `KeychainCredentialStore.keyPrefix` | `String` | `"adh.api"` | Namespaces the two Keychain account keys (`.token`, `.token.kind`); lets multiple independent stores share one Keychain service. |
| `KeychainSessionStore.keyPrefix` | `String` | `"adh.api"` | Namespaces the three Keychain account keys (`.token`, `.token.kind`, `.refresh`); shares its first two keys with `KeychainCredentialStore` under the same prefix. |
| `KeychainHelper.service` | `String` (`nonisolated(unsafe) static var`) | `Bundle.main.bundleIdentifier`, else a hardcoded reverse-DNS identifier naming the hub client | The Keychain `kSecAttrService` every key is scoped under. |
| `InMemoryCredentialStore.init(_:)` | `Credentials?` | `nil` | Seeds the in-memory credential for tests or ephemeral, non-persisted sessions. |
| `InMemorySessionStore.init(_:)` | `Session?` | `nil` | Seeds the in-memory session for tests or ephemeral, non-persisted sessions. |
| `AuthenticationMiddleware.credentials` | `any CredentialProvider` | — (required) | Injected dependency the middleware reads at send time. |
| `SessionRefreshMiddleware.session` | `any SessionStore` | — (required) | Injected dependency read and written for bearer injection and refresh persistence. |
| `SessionRefreshMiddleware.onSessionExpired` | `@Sendable () -> Void` | `{}` (no-op) | Called when a refresh is `.rejected` and the store has been cleared. |
| `ADHBodyLimit.maxBuffered` | `Int` | `16 * 1024 * 1024` (16 MiB) | Shared cap for the request-body buffering `SessionRefreshMiddleware` needs to retry, and for `rawJSON`'s response-body collection. |
| `createAPIToken(name:expiresAt:)` | `String`, `Date?` | `expiresAt: nil` | Name and optional expiry for a minted long-lived API token. |
| `exchangeOAuthCode(_:userAgent:)` | `String`, `String?` | `userAgent: nil` | The exchange code and, for native callers, the captured browser `User-Agent` the code was bound to. |

## Deep Linking

Not applicable: this component makes no use of URL schemes or universal links — it is an authentication/session data and middleware layer with no navigable surface.

## Localization

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| (none — inline literal) | `unknown error` | Fallback message in `ADHClient+Session.message(_:)` when the backend's `_Error.error` payload has neither `message` nor `code`. Surfaces to callers via `SessionError.unexpectedResponse`. |
| (none — inline literal) | `HTTP <status>` | Fallback message built in every `.undocumented(status, _)` branch across `signIn`, `completeMfa`, `sendMfaSms`, `passkeyOptions`, `completePasskey`, `mfaPasskeyOptions`, `completeMfaPasskey`, `exchangeOAuthCode`, and `currentUser`, and in the raw-exchange's `RawRequestError.invalidPath` mapping. Not translated; interpolates the raw HTTP status code. |

## Accessibility Options

Not applicable: this is a non-UI component with no rendered surface for Reduce Motion, Increase Contrast, or Differentiate Without Color to affect.

## Feature Flags

Not applicable: none of the nine Auth source files reference a feature-flag key; every code path listed under Behavioral Requirements runs unconditionally.

## Analytics

Not applicable: none of the nine Auth source files emit an analytics event; the only instrumentation is the `os.Logger` calls under Logging below.

## Privacy

- **Data collected**: bearer credentials — short-lived JWTs (`Credentials.Kind.jwt`) and long-lived API tokens (`.apiToken`) — and, for password/MFA/passkey/OAuth sign-ins, a single-use refresh token (`Session.refreshToken`).
- **Storage**: `KeychainCredentialStore`/`KeychainSessionStore` persist these values as macOS/iOS Keychain generic-password items scoped to `KeychainHelper.service`, with iOS additionally set to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (this-device-only, no backup/sync). `InMemoryCredentialStore`/`InMemorySessionStore` hold the same values only in process memory, guarded by an `NSLock`, and never write them to disk.
- **Transmission**: the access token leaves the process only as an `Authorization: Bearer <token>` header, attached by `AuthenticationMiddleware` or `SessionRefreshMiddleware` at send time. The refresh token leaves the process only in the JSON body of `POST /auth/refresh` (rotation) and `POST /auth/revoke` (best-effort sign-out); it is never sent as a header or query parameter. Transport-level encryption (TLS) is the concern of the `APITransport`/`ADHClient` layer, outside these nine files.
- **Retention**: credentials/sessions persist until `logout()`, `adopt(_:)` (replaces the credential), `signOut()` (revokes then clears), or a `.rejected` refresh (clears and calls `onSessionExpired`) — whichever comes first. This component never proactively expires a stored token on a timer; expiry is discovered reactively, via a 401.
- **Redaction**: both `Credentials` and `Session` override their string descriptions to print `<redacted>` for every token value, specifically so a consuming app's logging or a failed test assertion cannot spill a live bearer or refresh token (`credentials-redaction`, `session-redaction`).

## Logging

Subsystem: the hub client's own reverse-DNS identifier (`KeychainHelper.service`'s fallback literal) | Category: `Keychain`

| Event | Level | Message |
|-------|-------|---------|
| `KeychainHelper.set` fails (`status != errSecSuccess`) | error | `Keychain set failed for '<key>': <OSStatus>` — key name and status only, never the value being stored. |
| `KeychainHelper.get` fails for a reason other than "not found" (`status != errSecSuccess && status != errSecItemNotFound`) | error | `Keychain get failed for '<key>': <OSStatus>` — key name and status only, never any value. |

No other file under `Sources/Auth/` logs anything; `errSecItemNotFound` is treated as a normal, unlogged outcome in both `get` and `exists`.

## Platform Notes

- **SwiftUI**: this is the source implementation's own layer — no SwiftUI dependency. `ObservableObject`/`@Observable` wrappers around `ADHClient`'s session wrappers (e.g. exposing `SignInOutcome` as published state) belong in an app target, not here; nothing in these nine files imports SwiftUI.
- **Compose**: a port starts from `kotlinx.coroutines` `suspend` functions mirroring `login`/`signIn`/`completeMfa`/etc., `kotlinx.serialization` `@Serializable` data classes for `Credentials`/`Session`, Android `EncryptedSharedPreferences` (or the Keystore-backed `Jetpack Security` crypto library) in place of `KeychainHelper`, and a `Mutex`-guarded singleton in place of the `RefreshCoordinator` actor — Kotlin has no built-in actor model, so the leader/follower coalescing needs an explicit `Mutex` plus a `CompletableDeferred` per waiter.
- **React/Web**: a port starts from `fetch`-based async functions for each wrapper, a `Credentials`/`Session` TypeScript interface, `localStorage`/`sessionStorage` (or, for stronger isolation, an HttpOnly cookie set server-side) in place of Keychain, and a single in-flight `Promise` cached at module scope (keyed by the expired token, the way `RefreshCoordinator` keys by `previousToken`) to coalesce concurrent 401s instead of an actor.
- **AppKit / UIKit**: identical to SwiftUI here — this layer has no view-layer dependency at all; both AppKit and UIKit consumers call the same `ADHClient` wrappers directly, exactly as the Mac and iOS destinations of this same framework target already do.
- **WinUI 3**: a port starts from `System.Net.Http.HttpClient` for the auth/session HTTP calls, `System.Text.Json` for the `Credentials`/`Session` models (`Session` needs a custom `ToString()`/`DebugView` override to reproduce the redaction requirement), the Windows Credential Locker (`Windows.Security.Credentials.PasswordVault`) in place of Keychain — `PasswordVault` has no built-in "this-device-only" accessibility class, so the iOS `AfterFirstUnlockThisDeviceOnly` requirement has no direct equivalent and must be approximated by simply never syncing the vault entry (Credential Locker does not roam by default) — and a `SemaphoreSlim`-guarded singleton keyed by the expired token in place of `RefreshCoordinator`, since .NET has no structured-concurrency actor either. `ObservableCollection`/`INotifyPropertyChanged` are irrelevant here (no collection or bindable property in this component); a WinUI view model wrapping `SignInOutcome` would implement `INotifyPropertyChanged` itself, one layer above this port.

## Design Decisions

- **Decision**: Buffer the entire outgoing request body (not just failing ones) up to a single shared 16 MiB cap (`ADHBodyLimit.maxBuffered`), reused by both `SessionRefreshMiddleware`'s retry-resend and `rawJSON`'s response collection.
  **Rationale**: A retry after refresh must resend byte-identical content; buffering only on failure would require re-deriving the body from the caller, which the middleware has no way to do generically. A single shared limit avoids two independently-tuned buffering policies for what is the same underlying concern.
  **Approved**: pending

- **Decision**: Route `signOut()`'s revoke call through `rawJSON` with a hand-built `{"refreshToken": …}` body, rather than the generated `postAuthRevoke` operation.
  **Rationale**: The committed `openapi.json` still documents `POST /auth/revoke` as a bodiless 204, but the backend requires the refresh token in the body to actually revoke it; the generated client can only express the documented (stale) contract, so the raw escape hatch is the only way to send a request that revokes anything.
  **Approved**: pending

- **Decision**: Serialize every refresh through one process-wide `RefreshCoordinator.shared` actor, keyed by the expired access token, rather than one coordinator per `SessionRefreshMiddleware` instance.
  **Rationale**: The refresh token is single-use and lives in a `SessionStore` that multiple `ADHClient`s (e.g. two view models) can share; a per-instance coordinator would let two clients each lead a refresh, and the loser's replay of the already-spent refresh token would be rejected by the server, incorrectly clearing the session the winner just saved.
  **Approved**: pending

- **Decision**: On macOS, leave Keychain items on the implicit accessibility default rather than setting `kSecAttrAccessible` explicitly; on iOS, always set `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
  **Rationale**: macOS's file-based legacy Keychain rejects or ignores an explicit accessibility class unless the item also opts into the data-protection Keychain (`kSecUseDataProtectionKeychain`), and making that switch would strand items already stored under the legacy Keychain by existing callers. iOS has no such legacy-Keychain constraint, so it gets the stricter, device-local class outright.
  **Approved**: pending

- **Decision**: `createAPIToken` never writes to the credential store; only `adopt(_:)` does.
  **Rationale**: Minting a new long-lived API token is a distinct action from switching the active session to it — a caller (e.g. one creating a token to hand to a daemon or a CI secret) must not have their own active session silently replaced as a side effect of minting.
  **Approved**: pending

- **Decision**: Derive `SessionRefreshMiddleware.exemptOperationIDs` from the generated `Operations.X.id` constants, never from hand-written string literals.
  **Rationale**: The runtime hands `intercept` the generator's path-style operation ID (e.g. `"post/auth/login"`), not the Swift method name (`postAuthLogin`); a hand-written literal cannot be checked by the compiler and silently stops matching if the OpenAPI spec (and therefore the generated ID) changes, while a constant reference fails to compile instead.
  **Approved**: pending

- **Decision**: `Credentials` and `Session` both override `CustomStringConvertible`/`CustomDebugStringConvertible` to redact every token value.
  **Rationale**: The default reflection-based description prints every stored property verbatim; an app's `logger.error("\(credentials)")` or a failed `#expect(a == b)` test assertion would otherwise spill a live bearer or refresh token into a log or test report.
  **Approved**: pending

- **Decision**: `KeychainSessionStore` and `KeychainCredentialStore` share the same `<prefix>.token` / `<prefix>.token.kind` key names under a matching prefix.
  **Rationale**: This lets a credential saved by the older, session-agnostic store be read back by the newer session-aware store as a session with no refresh token, and vice versa, without a data migration step when a caller switches between the two.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | Security |
| [secure-log-output](agenticdevelopercookbook://compliance/security#secure-log-output) | passed | Security |
| [token-lifecycle](agenticdevelopercookbook://compliance/security#token-lifecycle) | partial | Security |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | failed | Security |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | passed | Access Patterns |
| [retry-with-backoff](agenticdevelopercookbook://compliance/access-patterns#retry-with-backoff) | failed | Access Patterns |
| [offline-behavior](agenticdevelopercookbook://compliance/access-patterns#offline-behavior) | partial | Access Patterns |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |

`token-lifecycle` is partial: JWT sessions rotate through single-use refresh tokens on 401 (`session-refresh-trigger`, `refresh-perform-status-mapping`), but API tokens are long-lived with no client-side expiry check or rotation — `createAPIToken`'s `expiresAt` is passed to the backend and never inspected locally. `input-sanitization` is failed: no file under `Sources/Auth/` validates `email`, `password`, `code`, or any challenge token before sending it; validation is entirely the backend's responsibility (see Edge Cases). `retry-with-backoff` is failed: `SessionRefreshMiddleware` retries the ORIGINAL request exactly once, immediately, with no backoff and no further retries if the retry itself fails — deliberate (a single-use refresh token cannot be spent repeatedly), but it is not the backoff-and-retry pattern the check describes. `offline-behavior` is partial: an unreachable backend during refresh (`.unavailable`) preserves the session and returns the original 401 rather than forcing a sign-out, but nothing in these files queues, delays, or retries the *original* request while offline — that is left entirely to the caller.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | session-wrappers-require-session-store, sign-out-silent-when-not-a-session-client and current-user-fetch corrected: currentUser() never calls sessionStore() and works with no SessionStore; also removed 6 agenticdeveloperhub product-name mentions (private-scope leak) by rephrasing to code-identifier descriptions. |
