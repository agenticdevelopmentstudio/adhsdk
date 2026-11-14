---
id: fafeef0d-c283-4ecf-92fb-b5de35d71f79
title: "Google Authorizer"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Google OAuth for a desktop app: loopback browser sign-in under a deadline, form-encoded token refresh and revoke, and a coalescing, Keychain-backed token provider."
platforms:
  - swift
  - macos
tags:
  - integrations
  - auth
  - oauth
  - google
  - token-refresh
depends-on:
  - 238f4d91-4a22-4a0d-ae4b-b4070d02b357
  - 351e3bf8-b137-4f59-94de-c769aa8b0666
  - d274abfa-3696-4fd0-b3e8-cff6fdffb825
  - 667825e5-d557-4410-b54e-29dcf98ca930
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references:
  - https://developers.google.com/identity/protocols/oauth2/native-app (Google OAuth 2.0 for installed apps)
  - https://accounts.google.com/o/oauth2/v2/auth (Google authorization endpoint)
  - https://oauth2.googleapis.com/token (Google token endpoint)
  - https://oauth2.googleapis.com/revoke (Google revoke endpoint)
  - https://www.rfc-editor.org/rfc/rfc8252 (RFC 8252, OAuth 2.0 for Native Apps)
  - https://www.rfc-editor.org/rfc/rfc7636 (RFC 7636, PKCE)
  - https://www.rfc-editor.org/rfc/rfc3986#section-2.3 (RFC 3986, unreserved characters)
  - https://github.com/openid/AppAuth-iOS (AppAuth)
approved-by: ""
approved-date: ""
---

# Google Authorizer

## Overview

Google Authorizer is the Google OAuth layer for the Gmail integration. It has four parts that a port reproduces together. `GoogleCredential` is the token triple for one connected Google account. `GoogleSignInFlow` and its implementation `AppAuthGoogleSignIn` run the interactive sign-in through the default browser and a loopback listener on 127.0.0.1. `GoogleTokenEndpoint` and `URLSessionGoogleTokenEndpoint` exchange a refresh token for a new access token and revoke a token at Google. `GoogleTokenProvider` is an actor that hands out fresh access tokens, refreshes shortly before expiry, shares one refresh among concurrent callers per connection, and persists each credential as JSON in a `SecretStoring` Keychain abstraction under a per-connection key. A free function, `withSignInDeadline`, bounds the sign-in with a timeout and maps cancellation to a typed error.

The OAuth client (`GoogleOAuthClientConfig`, with `clientId` and `clientSecret`) and the error type (`IntegrationError`) live in sibling files and are inputs to this component, not part of it. This component only reads `clientId` and `clientSecret` from the config.

## Behavioral Requirements

### Credential

- **credential-shape**: `GoogleCredential` MUST be a `Codable`, `Sendable`, `Equatable` value with the mutable fields `accessToken: String`, `refreshToken: String` and `expiresAt: Date`.
- **credential-wire-format**: A persisted credential MUST be the JSON encoding of `GoogleCredential` using the default `JSONEncoder` and `JSONDecoder` settings, stored as a UTF-8 string.

### Sign-in flow contract

- **signin-protocol**: A sign-in implementation MUST expose a single async operation `signIn(config:)` that takes a `GoogleOAuthClientConfig` and returns a `GoogleCredential` or throws.
- **signin-endpoints**: `AppAuthGoogleSignIn` MUST use `https://accounts.google.com/o/oauth2/v2/auth` as the authorization endpoint and `https://oauth2.googleapis.com/token` as the token endpoint.
- **signin-scopes**: `AppAuthGoogleSignIn` MUST request exactly the scopes `openid`, `email` and `https://www.googleapis.com/auth/gmail.modify`.
- **signin-offline-consent**: The authorization request MUST carry the additional parameters `access_type=offline` and `prompt=consent`, so Google issues a refresh token on every sign-in.
- **signin-response-type**: The authorization request MUST use the authorization-code response type and send `clientId` and `clientSecret` from the config.
- **signin-pkce**: The authorization request MUST carry an S256 `code_challenge` (RFC 7636) and the token exchange MUST send the matching `code_verifier`. The source does not set these; AppAuth's `OIDAuthorizationRequest` generates them by default, so a port that does not use AppAuth must add them.
- **signin-state**: The authorization request MUST carry a random `state`, and a redirect whose `state` does not match MUST fail the flow rather than be exchanged (RFC 8252). The source relies on AppAuth for both the value and the check.
- **signin-loopback-redirect**: The redirect URL MUST come from a local HTTP listener started on the loopback interface for the duration of the flow.
- **signin-listener-failure**: If the local listener cannot be started, `signIn` MUST throw `IntegrationError.signInFailed("Could not start the local sign-in listener")` before opening a browser.
- **signin-listener-teardown**: The local listener MUST be cancelled when the flow finishes, whether it succeeds, fails or is cancelled.
- **signin-default-browser**: The authorization URL MUST be opened in the user's default browser (not an embedded web view).
- **signin-success-url**: When a `successURL` is supplied, the browser MUST be sent there after Google redirects back with the code; without one the browser shows AppAuth's plain return-to-the-app page.
- **signin-no-browser-after-cancel**: If the flow has already been cancelled before presentation, `signIn` MUST throw `IntegrationError.signInCancelled` and MUST NOT open the browser.
- **signin-credential-assembly**: A finished sign-in MUST yield a `GoogleCredential` from the token response's access token, refresh token and access-token expiry date.
- **signin-missing-access-token**: A token response with a nil or empty access token MUST throw `IntegrationError.signInFailed("Google returned no access token")`.
- **signin-missing-refresh-token**: A token response with a nil or empty refresh token MUST throw `IntegrationError.signInFailed("Google returned no refresh token")`; the access-token check runs first.
- **signin-expiry-fallback**: When the token response carries no expiry date, `expiresAt` MUST be the injected clock's `now` plus 3600 seconds.
- **signin-error-mapping**: An AppAuth error in the general error domain with code user-canceled or program-canceled MUST map to `IntegrationError.signInCancelled`; every other error MUST map to `IntegrationError.signInFailed` carrying the error's localized description, and a nil error MUST map to `signInFailed("unknown error")`.
- **signin-main-actor**: The UI and the listener (the browser launch, the AppAuth flow, the loopback handler and the cancellation handle) MUST be touched only on the UI thread; cancellation from the deadline helper MUST hop to that thread before tearing the flow down.
- **signin-default-timeout**: `AppAuthGoogleSignIn` MUST default its timeout to 300 seconds, with `successURL` defaulting to nil and the clock to `Date.init`.

### Sign-in deadline

- **deadline-result**: `withSignInDeadline` MUST return the operation's result when it finishes before the deadline.
- **deadline-timeout**: When the timeout elapses first, `withSignInDeadline` MUST throw `IntegrationError.signInFailed("Sign-in timed out")`.
- **deadline-timeout-cancels**: On timeout, `withSignInDeadline` MUST invoke the `cancel` closure and cancel the operation task.
- **deadline-caller-cancel**: Cancelling the calling task MUST throw `IntegrationError.signInCancelled` and invoke the `cancel` closure.
- **deadline-operation-cancellation-error**: An operation that throws `CancellationError` MUST surface as `IntegrationError.signInCancelled`; any other thrown error MUST propagate unchanged.
- **deadline-first-wins**: The operation, the timer and the caller's cancellation MUST race to settle a single result, and the first to settle wins.
- **deadline-prompt**: `withSignInDeadline` MUST return promptly on timeout or cancellation even if the operation ignores cancellation and never returns.
- **deadline-cleanup**: On exit, `withSignInDeadline` MUST cancel its timer task and its operation task.

### Token endpoint

- **endpoint-protocol**: A token endpoint MUST provide `refresh(refreshToken:config:)`, returning an access token and an `expiresIn` in seconds, and `revoke(token:)`.
- **endpoint-refresh-request**: `refresh` MUST send one POST to `https://oauth2.googleapis.com/token` with `Content-Type: application/x-www-form-urlencoded` and the body fields, in this order, `grant_type=refresh_token`, `refresh_token`, `client_id`, `client_secret`.
- **endpoint-revoke-request**: `revoke` MUST send one POST to `https://oauth2.googleapis.com/revoke` with the same content type and a single body field `token`.
- **endpoint-form-encoding**: Form values MUST be percent-encoded, escaping every character except the RFC 3986 unreserved set (ASCII letters, digits, `-`, `.`, `_`, `~`), so that `+`, `/`, `=`, `&` and space are escaped.
- **endpoint-invalid-grant**: A non-2xx refresh reply whose JSON `error` is `invalid_grant` MUST throw `IntegrationError.revoked`.
- **endpoint-refresh-failure**: Any other non-2xx refresh reply MUST throw `IntegrationError.tokenRefresh("<status> <error>")`, using `unknown` when the body has no string `error` and `0` when the response is not an HTTP response.
- **endpoint-missing-access-token**: A 2xx refresh reply with no string `access_token` MUST throw `IntegrationError.tokenRefresh("no access_token in reply")`.
- **endpoint-expires-default**: A 2xx refresh reply with no numeric `expires_in` MUST yield `expiresIn` of 3600 seconds.
- **endpoint-revoke-failure**: A non-2xx revoke reply MUST throw `IntegrationError.tokenRefresh("revoke failed: <status> <error>")`.
- **endpoint-transport-errors**: A transport error from the URL session MUST propagate unchanged; the component adds no retry, no custom timeout and no idempotency key.
- **endpoint-body-parse**: A reply body that is not a JSON object MUST be treated as having no fields rather than raising a parse error.

### Token provider

- **provider-actor**: `GoogleTokenProvider` MUST serialise all of its state in a single actor.
- **provider-key**: A credential MUST be stored under `integrations.gmail.<connectionId>.credential`, and the client secret key constant MUST be `integrations.gmail.oauth-client-secret`.
- **provider-fresh-token**: `accessToken(connectionId:config:)` MUST return the stored access token without calling the endpoint when `expiresAt` is at least 60 seconds after `now`.
- **provider-refresh-margin**: When `expiresAt` is less than 60 seconds after `now` (including already expired), `accessToken` MUST refresh before returning.
- **provider-refresh-result**: A refresh MUST produce a credential with the new access token, the unchanged refresh token and `expiresAt` of `now` plus the reply's `expiresIn`, and MUST persist it before returning the token.
- **provider-coalesce**: Concurrent `accessToken` callers for one connection MUST share a single in-flight refresh and receive the same outcome.
- **provider-owner-persists**: Only the first caller to settle a refresh MUST persist the result and clear the in-flight entry.
- **provider-save-error-to-owner**: When that save fails, only the persisting (first-to-settle) caller MUST receive the save error; every other caller sharing the refresh MUST return the refreshed access token without error.
- **provider-propagates-endpoint-error**: An error thrown by the endpoint's `refresh` MUST propagate unchanged from `accessToken` to every caller sharing that refresh, and MUST NOT be persisted or change the stored credential.
- **provider-failed-not-reused**: A failed refresh MUST be dropped from the in-flight table so the next call starts a new refresh.
- **provider-missing-credential**: A missing credential, or one stored but not decodable as `GoogleCredential`, MUST throw `IntegrationError.revoked` from `accessToken`.
- **provider-keychain-read-error**: A secret store that throws on read MUST surface `IntegrationError.keychain("Could not read the Google credential: <description>")`, MUST NOT report `revoked` and MUST NOT call the endpoint.
- **provider-store**: `store(_:connectionId:)` MUST persist the credential and supersede any refresh in progress for the connection.
- **provider-store-failure**: A failed encode or Keychain write MUST throw `IntegrationError.signInFailed("Could not save the Google credential to the Keychain")`.
- **provider-forget**: `forget(connectionId:)` MUST delete the stored credential and supersede any refresh in progress.
- **provider-forget-failure**: When the Keychain delete reports failure, `forget` MUST throw `IntegrationError.keychain("Could not remove the Google credential")`.
- **provider-supersede**: A refresh superseded by `store` or `forget` while in flight MUST have its result discarded, whether it succeeded or failed, and the current credential MUST be re-read, so a stale `invalid_grant` never reports `revoked` after a fresh sign-in.
- **provider-unsaved-fallback**: A refreshed credential the Keychain refused to save MUST be kept in memory and used by later `accessToken` calls instead of refreshing again, and the original save error MUST still be thrown to the caller that triggered the refresh.
- **provider-unsaved-clear**: The in-memory unsaved credential MUST be cleared by a later successful save, a `store`, or a `forget`.
- **provider-revoke-best-effort**: `revoke(connectionId:)` MUST send the stored refresh token (not the access token) to the endpoint and MUST NOT throw: an unreadable Keychain and a failed request are logged, and a missing credential returns silently.
- **provider-revoke-keeps-credential**: `revoke` MUST NOT delete the local credential; removal is `forget`.
- **provider-injected-clock**: The provider and the sign-in MUST read time only through the injected `now` closure.

## Appearance

Not applicable — this is an authentication and token-management component, not a visual component. The only interface it touches is the system browser, which it opens with the authorization URL.

## States

Not applicable — this is an authentication and token-management component, not a visual component. The sign-in flow's runtime outcomes (succeeded, failed with `signInFailed`, cancelled with `signInCancelled`, timed out) are specified under Behavioral Requirements.

## Accessibility

Not applicable — this is an authentication and token-management component, not a visual component.

## Conformance Test Vectors

Vectors derive from `GoogleOAuthTests` in `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKIntegrationsTests/GoogleOAuthTests.swift`. Times use a fixed clock `epoch`. The Verification column says whether a unit test exists (`unit`) or the vector is traced to the code only (`manual`); a port needs a test for each `manual` row it can automate.

| ID | Requirements | Input | Expected | Verification |
|----|-------------|-------|----------|--------------|
| gauth-001 | provider-fresh-token | Stored credential `old` expiring at epoch + 300 s; call `accessToken` (test `returnsCachedTokenWhenFresh`) | Returns `old`; endpoint call count 0 | unit |
| gauth-002 | provider-refresh-margin, provider-refresh-result | Stored credential `old`, refresh token `r`, expiring epoch + 30 s; endpoint returns `new`, 3600 (test `refreshesWhenWithin60Seconds`) | Returns `new`; stored JSON has `accessToken` `new`, `refreshToken` `r`, `expiresAt` epoch + 3600 s | unit |
| gauth-003 | provider-coalesce, provider-owner-persists | Credential already expired; ten concurrent `accessToken` calls (test `concurrentCallersShareOneRefresh`) | All ten return `new`; endpoint call count 1 | unit |
| gauth-004 | provider-propagates-endpoint-error | Endpoint fails with `revoked` (test `invalidGrantThrowsRevoked`) | `accessToken` throws `IntegrationError.revoked` | unit |
| gauth-005 | provider-missing-credential | No credential stored for `nope` (test `missingCredentialThrowsRevoked`) | Throws `IntegrationError.revoked` | unit |
| gauth-006 | provider-forget | Store then `forget` (test `forgetRemovesCredential`) | Secret store has no value for the key | unit |
| gauth-007 | provider-forget-failure | Secret store delete returns false (test `forgetThrowsWhenTheKeychainDeleteFails`) | Throws `keychain("Could not remove the Google credential")` | unit |
| gauth-008 | provider-keychain-read-error | Secret store read throws "locked" (test `aKeychainReadErrorIsNotReportedAsRevoked`) | Throws `keychain("Could not read the Google credential: locked")`; endpoint call count 0 | unit |
| gauth-009 | provider-failed-not-reused, provider-propagates-endpoint-error | Endpoint fails `tokenRefresh("500 backend_error")`; two calls (test `aFailedRefreshIsNotReusedByTheNextCall`) | Both throw that error; endpoint call count 2 | unit |
| gauth-010 | provider-revoke-best-effort, provider-revoke-keeps-credential | Revoke endpoint throws; `revoke` for a stored connection and for `missing` (test `revokeSendsTheRefreshTokenAndIgnoresFailure`) | Endpoint received exactly `["r1"]`; no throw; credential still stored | unit |
| gauth-011 | signin-expiry-fallback, signin-missing-access-token, signin-missing-refresh-token | `credential(accessToken:"a", refreshToken:"r", expiresAt:nil, now:epoch)`; refresh token empty; access token nil (test `signInFallbackExpiryUsesTheInjectedClock`) | `expiresAt` epoch + 3600 s; then `signInFailed("Google returned no refresh token")`; then `signInFailed("Google returned no access token")` | unit |
| gauth-012 | endpoint-invalid-grant | Stub reply 400 with `{"error":"invalid_grant"}` (test `tokenEndpointMapsInvalidGrantToRevoked`) | `refresh` throws `revoked` | unit |
| gauth-013 | endpoint-refresh-request, endpoint-protocol | Stub reply 200 `{"access_token":"tok","expires_in":3599}` (test `tokenEndpointParsesSuccess`) | Returns `tok`, 3599; request is POST to the token URL, form content type, body `grant_type=refresh_token&refresh_token=r&client_id=id&client_secret=secret` | unit |
| gauth-014 | endpoint-form-encoding | Refresh token `1//a+b/c=d&e`, client secret `s+t ~` (test `tokenEndpointPercentEncodesPlusAndReservedCharacters`) | Body `grant_type=refresh_token&refresh_token=1%2F%2Fa%2Bb%2Fc%3Dd%26e&client_id=id&client_secret=s%2Bt%20~` | unit |
| gauth-015 | endpoint-refresh-failure | Stub reply 500 `{"error":"backend_error"}` (test `tokenEndpointReportsOtherFailuresAsRefreshErrors`) | Throws `tokenRefresh("500 backend_error")` | unit |
| gauth-016 | endpoint-revoke-request | `revoke(token: "1//r+t")` with 200 reply (test `tokenEndpointRevokePostsTheTokenToGoogle`) | POST to the revoke URL, body `token=1%2F%2Fr%2Bt` | unit |
| gauth-017 | endpoint-revoke-failure | Stub reply 400 `{"error":"invalid_token"}` (test `tokenEndpointRevokeFailureThrows`) | Throws `tokenRefresh("revoke failed: 400 invalid_token")` | unit |
| gauth-018 | provider-supersede, provider-forget | `forget` while a refresh is gated, then release (test `forgetDuringRefreshKeepsCredentialRemoved`) | Pending call throws `revoked`; secret store still has no value | unit |
| gauth-019 | provider-supersede, provider-store | `store` fresh credential `signed-in` while a refresh is gated, then release (test `storeDuringRefreshSurvivesStaleRefresh`) | Pending call returns `signed-in`; endpoint call count 1; stored value equals the fresh credential | unit |
| gauth-020 | provider-supersede | As gauth-019 but the gated refresh fails with `revoked` (test `storeDuringFailingRefreshReturnsNewCredential`) | Pending call returns `signed-in`, not `revoked` | unit |
| gauth-021 | provider-store-failure | `store` against a store whose writes fail (test `storeThrowsWhenKeychainWriteFails`) | Throws `signInFailed("Could not save the Google credential to the Keychain")` | unit |
| gauth-022 | provider-unsaved-fallback, provider-unsaved-clear | Seeded credential, writes fail; call `accessToken` three times (tests `refreshPersistFailureSurfaces`, `aRefreshThatCouldNotBeSavedIsStillUsedByLaterCalls`) | First throws the save error; second and third return `new`; endpoint call count 1 | unit |
| gauth-023 | deadline-timeout, deadline-timeout-cancels, deadline-cleanup | 100 ms timeout, operation hangs until cancelled (test `deadlineTimesOutPromptlyAndCancelsFlow`) | Throws `signInFailed("Sign-in timed out")` in under 5 s; `cancel` was invoked | unit |
| gauth-024 | deadline-caller-cancel, deadline-operation-cancellation-error | Cancel the calling task after the operation starts (test `deadlineCancellationMapsToSignInCancelled`) | Throws `signInCancelled`; `cancel` invoked | unit |
| gauth-025 | deadline-prompt, deadline-first-wins | Operation never returns and ignores cancellation; once timing out at 100 ms, once cancelled by the caller (test `deadlineIsPromptEvenWhenTheOperationIgnoresCancellation`) | First throws `signInFailed("Sign-in timed out")` in under 5 s; second throws `signInCancelled` | unit |
| gauth-026 | deadline-result | Operation returns 42 with a 60 s timeout (test `deadlineReturnsOperationResult`) | Returns 42 | unit |
| gauth-027 | signin-error-mapping | AppAuth error with code user-canceled in the general domain; same domain with another code and description "boom"; nil error | `signInCancelled`; `signInFailed("boom")`; `signInFailed("unknown error")` (traced to `map`; no unit test) | manual |
| gauth-028 | signin-endpoints, signin-scopes, signin-offline-consent, signin-response-type, signin-pkce, signin-state, signin-listener-failure | Run `signIn` with a valid config (traced to `run`; the source states it is verified manually) | Request has the two endpoints, the three scopes, the code response type, an S256 `code_challenge`, a random `state` (a mismatched `state` fails the flow) and parameters `access_type=offline`, `prompt=consent`; a listener bind failure throws `signInFailed("Could not start the local sign-in listener")` before any browser opens | manual |
| gauth-029 | credential-shape, credential-wire-format, provider-key | Store a credential for connection `c` (test `refreshesWhenWithin60Seconds`) | Value under `integrations.gmail.c.credential` decodes with a default `JSONDecoder` to the credential | unit |
| gauth-030 | signin-default-timeout | Construct `AppAuthGoogleSignIn()` (traced to the initializer; no unit test) | Timeout is 300 s, `successURL` is nil, clock is `Date.init` | manual |
| gauth-033 | signin-no-browser-after-cancel | Cancel before presentation, then run a sign-in (traced to `run`; manual only) | `signInCancelled` is thrown; no browser opens | manual |
| gauth-034 | signin-listener-teardown | Run a sign-in that succeeds, one that fails and one that is cancelled (traced to the `defer` in `run`; manual only) | The listener is cancelled in each case | manual |
| gauth-035 | signin-loopback-redirect, signin-default-browser, signin-success-url | Run a sign-in with and without a `successURL` (traced to `run` and `DefaultBrowserUserAgent`; manual only) | The redirect URL is a 127.0.0.1 listener URL; the authorization URL opens in the default browser; the browser is sent to `successURL` when given, else shows AppAuth's return page | manual |
| gauth-036 | signin-main-actor | Run a sign-in and cancel through the deadline helper (traced to `run` and `SessionBox`; manual only) | The flow, handler and cancel handle are touched only on the main actor | manual |
| gauth-037 | signin-protocol, signin-credential-assembly | Run `signIn(config:)` to a finished token response (traced to `run` and `credential`; manual only) | One async call returns a `GoogleCredential` built from the response's access token, refresh token and expiry | manual |
| gauth-038 | provider-save-error-to-owner | Expired credential, writes fail; two concurrent `accessToken` calls on one connection (no unit test yet) | One call throws the save error; the other returns `new`; endpoint call count 1 | manual |
| gauth-031 | endpoint-missing-access-token, endpoint-body-parse | Stub reply 200 with body `not json` (traced to `refresh` and `post`; no unit test) | `tokenRefresh("no access_token in reply")` | manual |
| gauth-039 | endpoint-transport-errors | A transport failure from the session (traced to `post`; no unit test) | The session's error propagates unchanged; no retry | manual |
| gauth-032 | provider-actor, provider-injected-clock | Provider built with `now: { epoch }` (every test via `makeProvider`) | All expiry decisions and stored `expiresAt` values use `epoch`; no wall-clock reads | unit |

## Edge Cases

- **Empty or missing tokens at sign-in**: Empty-string tokens MUST be rejected the same as nil ones, with the access-token check first (the `credential` guards).
- **Missing expiry at sign-in**: A missing expiry date MUST fall back to one hour from the injected clock rather than failing.
- **Missing expiry at refresh**: A reply without `expires_in` MUST be treated as 3600 seconds.
- **Exact margin boundary**: A credential expiring exactly 60 seconds from `now` MUST be treated as fresh, because the check is greater-than-or-equal.
- **Corrupt stored credential**: Stored text that does not decode as `GoogleCredential` MUST read as absent and surface as `revoked`, prompting sign-in again; the decode failure is not logged or reported separately.
- **Keychain read failure versus absence**: A throwing read MUST surface as `keychain` and never as `revoked`.
- **Keychain write failure on refresh**: The refreshed credential MUST stay usable from memory; the in-memory copy is lost on restart, and the Keychain keeps the stale credential.
- **Waiters on a refresh whose save failed**: See `provider-save-error-to-owner`: only the persisting caller sees the save error; the other callers return the refreshed access token.
- **Concurrent access**: Same-connection refreshes MUST coalesce; different connections MUST refresh independently because the in-flight table and generation counters are keyed by `connectionId`.
- **Re-entrancy after supersede**: A superseded refresh MUST re-read the current credential through `accessToken` rather than return its own result.
- **Revoked grant**: `invalid_grant` on refresh MUST surface `revoked` but MUST NOT delete the stored credential; the caller decides whether to `forget`.
- **Revoke with no credential or unreadable Keychain**: `revoke` MUST return silently when nothing is stored, and after logging when the Keychain cannot be read (see `provider-revoke-best-effort`).
- **Timeout during browser wait**: Expiry of the 300-second default MUST cancel AppAuth's flow and the listener, and throw `signInFailed("Sign-in timed out")`.
- **User closes the browser or denies consent**: AppAuth's user-canceled code maps to `signInCancelled`; whether AppAuth detects a closed browser tab is AppAuth's behavior, and the source adds no handling.
- **Network unavailable**: A transport failure on refresh or revoke propagates as the URL session's error; there is no retry, backoff, timeout override or offline queue in this component, so `accessToken` fails and the next call refreshes again.
- **Rate limiting and 5xx**: Any non-2xx other than `invalid_grant` surfaces as `tokenRefresh` with no `Retry-After` handling; Google owns throttling behavior.
- **Non-JSON error body**: The status alone is reported, with error text `unknown`.
- **Listener bind failure**: AppAuth's listener returns nil on failure but Swift imports it as non-null and would trap, so the code calls it through the Objective-C runtime to receive an optional; a port MUST check for a failed start.
- **Cancelled before browser opens**: No browser opens and `signInCancelled` is thrown.
- **Concurrent sign-ins**: The source defines no ordering between two concurrent `signIn` calls; each creates its own session box and listener and they do not share state.
- **Revoke ordering with forget**: `revoke` and `forget` are independent operations; callers invoke `revoke` first, because `forget` removes the refresh token that `revoke` reads.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` | `GoogleOAuthClientConfig` | required | Desktop-app OAuth client id and secret, passed to `signIn`, `refresh` and `accessToken` |
| `timeout` | `Duration` | 300 seconds | Sign-in deadline for `AppAuthGoogleSignIn` |
| `successURL` | `URL?` | nil | Where the browser is sent after the redirect, typically the host app's URL scheme |
| `now` | `@Sendable () -> Date` | `Date.init` | Clock for `AppAuthGoogleSignIn` and `GoogleTokenProvider` |
| `session` | `URLSession` | `.shared` | Session used by `URLSessionGoogleTokenEndpoint` |
| `secrets` | `any SecretStoring` | required | Keychain abstraction used by `GoogleTokenProvider` |
| `endpoint` | `any GoogleTokenEndpoint` | required | Token endpoint used by `GoogleTokenProvider` |
| Refresh margin | `TimeInterval` | 60 seconds | Constant; not caller-configurable |
| Fallback lifetime | `TimeInterval` | 3600 seconds | Constant; used when Google reports no expiry |
| Credential key | string | `integrations.gmail.<connectionId>.credential` | Keychain key per connection |
| Client secret key | string | `integrations.gmail.oauth-client-secret` | Public constant for hosts that store the client secret |

## Deep Linking

Not applicable: the component registers no URL scheme or route. It only forwards an optional host-supplied `successURL` to the browser after the loopback redirect.

## Localization

The component returns hardcoded English reason strings inside `IntegrationError` cases (for example `Sign-in timed out`, `Google returned no access token`, `Could not remove the Google credential`) and no localization keys. `IntegrationError.errorDescription`, in a sibling file, wraps them in English prefixes. Localization is therefore not implemented here; hosts that need other languages translate at the display layer.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none | `Sign-in timed out` | `signInFailed` reason on deadline expiry |
| none | `Could not start the local sign-in listener` | `signInFailed` reason on listener failure |
| none | `Google returned no access token` / `Google returned no refresh token` | `signInFailed` reasons on an incomplete token response |
| none | `Could not save the Google credential to the Keychain` | `signInFailed` reason on a save failure |
| none | `Could not remove the Google credential` / `Could not read the Google credential: <description>` | `keychain` reasons |

## Accessibility Options

Not applicable: the component renders nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color have nothing to affect.

## Feature Flags

Not applicable: the source reads no flag; the endpoints, scopes and margins are constants.

## Analytics

Not applicable: the source emits no analytics event; the only instrumentation is the two `Logger` error calls under Logging.

## Privacy

- **Data collected**: A Google access token, refresh token and token expiry per connected account, plus the OAuth client id and secret passed in by the caller. The `email` and `openid` scopes are requested, but this component reads no profile data.
- **Storage**: Each credential is persisted as JSON through `SecretStoring` (the Keychain) under a per-connection key. A credential the Keychain refused to save is held in actor memory only, until a save succeeds, a `store` or `forget`, or process exit.
- **Transmission**: Tokens and the client secret are sent only to Google, over HTTPS: the authorization, token and revoke endpoints listed under Behavioral Requirements. The loopback redirect carries the authorization code over plain HTTP on 127.0.0.1 only. The refresh token is the only value sent to revoke.
- **Retention**: A credential stays in the Keychain until `forget` removes it; `revoke` ends the grant at Google but does not delete the local copy. Access tokens last as long as Google reports (default 3600 seconds) and are refreshed 60 seconds before expiry. Revocation by the user surfaces as `invalid_grant`, then `revoked`.
- **Log hygiene**: The logger records the connection id (marked public) and the error's description; none of the logged values are tokens or secrets.

## Logging

Subsystem: `com.agenticdeveloperhub.integrations` | Category: `GoogleTokens`

| Event | Level | Message |
|-------|-------|---------|
| Revoke skipped, credential unreadable | error | `Not revoking <connectionId>: <description>` |
| Revoke request failed | error | `Revoking <connectionId> at Google failed: <description>` |

`AppAuthGoogleSignIn` and `URLSessionGoogleTokenEndpoint` log nothing.

## Platform Notes

- **SwiftUI**: Source platform is Swift (macOS). The files are `Integrations/Auth/GoogleAuthorizer.swift`, with `GoogleOAuthClientConfig.swift` beside it, `Integrations/Model/IntegrationError.swift` and `AIPluginKit/SecretStoring.swift`. A SwiftUI host calls `signIn` from a task and shows `IntegrationError.errorDescription`. The sign-in uses AppKit (`NSWorkspace.shared.open`) and AppAuth, so it is macOS only, and the source file imports AppKit and AppAuth as a whole; `GoogleTokenProvider`, the token endpoint and `withSignInDeadline` use only platform-neutral Swift concurrency (actor, `Task`, `URLSession`, `Logger`) and would need to be split out of that file to build elsewhere.
- **Compose**: Android has no direct equivalent of the loopback sign-in: start from AppAuth-Android with a custom-tab authorization request and a redirect URI intent filter, keep PKCE and `state` on (AppAuth-Android does), and keep the same scopes and the `access_type=offline`, `prompt=consent` parameters. Port the provider as a class with a per-connection `Mutex` and a map of `Deferred` refreshes; store the JSON in `EncryptedSharedPreferences` or Android Keystore-backed storage; use OkHttp with a hand-built `application/x-www-form-urlencoded` body that escapes everything outside the unreserved set; wrap sign-in in `withTimeout` and map `CancellationException` to cancelled.
- **React/Web**: Browser apps cannot hold a client secret or a long-lived refresh token safely. A port normally runs the authorization-code flow with PKCE against a backend that holds the secret, or uses Google Identity Services; for a Node or Electron host, use `google-auth-library` with a loopback `http.createServer` redirect. Coalesce refreshes with a `Map<string, Promise<Credential>>` (single-threaded, so no lock) plus a generation counter; encode forms with `URLSearchParams` (it encodes space as `+`, so check it against the `s+t ~` vector); race the sign-in promise against a timer and an `AbortController` for the deadline.
- **AppKit / UIKit**: AppKit uses the source as written (default browser through `NSWorkspace`). On iOS and iPadOS, AppAuth's iOS external user agent backed by `ASWebAuthenticationSession` replaces the loopback listener and the custom user agent, because loopback redirects and `NSWorkspace` are unavailable; the Keychain, actor and `URLSession` parts transfer unchanged.
- **WinUI 3**: `WebAuthenticationBroker` is not available to desktop WinUI 3 apps, so run the loopback flow: start an `HttpListener` (or a Kestrel minimal API bound to 127.0.0.1 on a free port), open the authorization URL with `Launcher.LaunchUriAsync`, and read the `code` from the redirect, exchanging it with `HttpClient` or a library such as `Google.Apis.Auth`. Port `GoogleCredential` as a `record` serialised with `System.Text.Json` and stored through `Windows.Security.Credentials.PasswordVault` or DPAPI-protected files under `Windows.Storage.ApplicationData`; a PasswordVault failure other than not-found must map to the keychain error, never to revoked. Implement the provider as a class with a `Dictionary<string, Lazy<Task<GoogleCredential>>>` guarded by a per-connection `SemaphoreSlim`, plus an integer generation, to reproduce coalescing and supersede; express the deadline with `CancellationTokenSource.CancelAfter` and `Task.WhenAny`, mapping `OperationCanceledException` to the sign-in-cancelled error. `FormUrlEncodedContent` encodes space as `+` and is looser than the source's unreserved-only escaping, so escape each value with `Uri.EscapeDataString` and build the body string yourself to match the vectors. The source's main-actor isolation corresponds to running UI-touching steps on the `DispatcherQueue`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Auth/GoogleAuthorizer.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Request `access_type=offline` and `prompt=consent` on every authorization.
**Rationale**: Google returns a refresh token on the first consent unless consent is forced, and the component rejects a response without one. Forcing consent keeps re-sign-in for an existing account working.
**Approved**: pending

**Decision**: Open the default browser through a private external user agent that calls `NSWorkspace.shared.open`.
**Rationale**: The source comment says AppAuth's own macOS agent reaches the browser only through a deprecated initializer, and otherwise requires a window for `ASWebAuthenticationSession`.
**Approved**: pending

**Decision**: Start the loopback listener through the Objective-C runtime selector and check the optional result.
**Rationale**: The source comment explains that `startHTTPListener` returns nil on a bind failure, but Swift imports it as non-null and would trap. This is a workaround that a port must replace with an explicit failed-start check.
**Approved**: pending

**Decision**: `withSignInDeadline` races the work, the timer and caller cancellation to settle one result.
**Rationale**: The doc comment requires a prompt return even if the operation ignores cancellation, so waiting on the operation itself is not enough. The first writer to settle wins and later outcomes are dropped.
**Approved**: pending

**Decision**: Refresh 60 seconds before expiry.
**Rationale**: A margin avoids handing out a token that expires in transit. The 60-second value is a constant and not a caller option.
**Approved**: pending

**Decision**: Coalesce refreshes per connection and discard any refresh superseded by `store` or `forget`, tracked by a generation counter.
**Rationale**: Concurrent callers must not each spend a refresh round trip, and a stale `invalid_grant` or stale token must never overwrite or contradict a fresh sign-in or a removal. The tests `storeDuringRefreshSurvivesStaleRefresh` and `forgetDuringRefreshKeepsCredentialRemoved` pin this.
**Approved**: pending

**Decision**: Keep a refreshed credential in memory when the Keychain refuses to save it.
**Rationale**: The comment says the credential is still valid, and re-refreshing on every request would hammer Google. The cost is that the unsaved copy vanishes on restart; the caller that triggered the refresh still sees the save error.
**Approved**: pending

**Decision**: Treat an undecodable stored credential as absent (`revoked`) but a throwing Keychain read as `keychain`.
**Rationale**: The doc comment separates "sign in again" from "could not look", so a locked Keychain does not wrongly prompt re-authentication.
**Approved**: pending

**Decision**: Percent-encode form bodies with the unreserved set only, instead of using `URLComponents`.
**Rationale**: The source comment states `URLComponents` leaves `+`, `/` and `=` alone, and a server decodes a raw `+` as a space, corrupting tokens and secrets.
**Approved**: pending

**Decision**: `revoke` is best effort and does not delete locally.
**Rationale**: Removing an account should also end the grant at Google, but a failed network call must not block local removal, so failures are logged and ignored and the caller runs `forget` separately.
**Approved**: pending

**Decision**: The browser round trip of `AppAuthGoogleSignIn` has no unit test.
**Rationale**: The source states it is verified manually because the browser round trip cannot run headless; only `credential` and `withSignInDeadline` are unit tested. The requirements for the flow are traced to the code, not to a test.
**Approved**: pending

**Decision**: The authorizer is Gmail-only on purpose: the scope `gmail.modify` and the Keychain keys `integrations.gmail.*` are fixed, not configuration options.
**Rationale**: The component is the Google layer of the Gmail integration and the source hard-codes both. A general Google authorizer would take scopes and a key prefix as inputs; this one does not, and a port for another Google API must change the constants.
**Approved**: pending

**Decision**: The logging subsystem `com.agenticdeveloperhub.integrations` is a literal, not a template variable.
**Rationale**: The source logs under the SDK's own subsystem, shared by every integration type, so the value belongs to the SDK and not to the host app's bundle id. A port keeps the SDK's subsystem rather than substituting an app id.
**Approved**: pending

**Decision**: PKCE and `state` are left to AppAuth's defaults rather than set explicitly.
**Rationale**: `OIDAuthorizationRequest` generates an S256 code challenge and a random `state` and checks the returned `state`, so the source never mentions them. `signin-pkce` and `signin-state` state them explicitly because a port without AppAuth would otherwise omit them.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | passed | security |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | passed | security |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | access-patterns |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | partial | access-patterns |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The component separates the interactive flow, the HTTP exchange, deadline logic and token caching into distinct types behind protocols (`GoogleSignInFlow`, `GoogleTokenEndpoint`, `SecretStoring`) with an injected clock, so `separation-of-concerns` passes. Unit tests cover the provider, the token endpoint (through a stub URL protocol), form encoding, the credential assembly and the deadline; the AppAuth browser round trip is verified manually, so `unit-test-coverage` is partial. Credentials live only in the Keychain abstraction, travel over HTTPS to Google, expire with a 60-second refresh margin, and can be revoked at Google and forgotten locally, so the security checks pass; the sign-in's PKCE and `state` protection (`signin-pkce`, `signin-state`) come from AppAuth's defaults, and the loopback redirect (`signin-loopback-redirect`) is plain HTTP on 127.0.0.1, which RFC 8252 permits for native apps. There is no retry or backoff on refresh and no timeout on the token requests beyond the session's own, so `retry-with-backoff` fails and `timeout-configuration` is partial (the sign-in deadline is configurable at 300 seconds, token calls are not). Error reasons are hardcoded English strings, so `no-hardcoded-strings` fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
