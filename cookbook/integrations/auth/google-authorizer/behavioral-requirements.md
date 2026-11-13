
### Credential

- **credential-shape**: `GoogleCredential` MUST be a `Codable`, `Sendable`, `Equatable` value with the mutable fields `accessToken: String`, `refreshToken: String` and `expiresAt: Date`.
- **credential-wire-format**: A persisted credential MUST be the JSON encoding of `GoogleCredential` using the default `JSONEncoder` and `JSONDecoder` settings, stored as a UTF-8 string.

### Sign-in flow contract

- **signin-protocol**: A sign-in implementation MUST expose a single async operation `signIn(config:)` that takes a `GoogleOAuthClientConfig` and returns a `GoogleCredential` or throws.
- **signin-endpoints**: `AppAuthGoogleSignIn` MUST use `https://accounts.google.com/o/oauth2/v2/auth` as the authorization endpoint and `https://oauth2.googleapis.com/token` as the token endpoint.
- **signin-scopes**: `AppAuthGoogleSignIn` MUST request exactly the scopes `openid`, `email` and `https://www.googleapis.com/auth/gmail.modify`.
- **signin-offline-consent**: The authorization request MUST carry the additional parameters `access_type=offline` and `prompt=consent`, so Google issues a refresh token on every sign-in.
- **signin-response-type**: The authorization request MUST use the authorization-code response type and send `clientId` and `clientSecret` from the config.
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
- **signin-main-actor**: The AppAuth flow, the loopback handler and the cancellation handle MUST be used on the main actor.
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
- **provider-revoke-best-effort**: `revoke(connectionId:)` MUST send the stored refresh token (not the access token) to the endpoint and MUST NOT throw: an unreadable Keychain, a missing credential or a failed request ends the call, with the first and last logged.
- **provider-revoke-keeps-credential**: `revoke` MUST NOT delete the local credential; removal is `forget`.
- **provider-injected-clock**: The provider and the sign-in MUST read time only through the injected `now` closure.

