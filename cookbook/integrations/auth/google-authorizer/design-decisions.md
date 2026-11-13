
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
