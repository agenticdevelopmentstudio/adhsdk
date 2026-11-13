
### Cases and payloads

- **case-set**: `IntegrationError` MUST declare exactly these cases: `invalidSettings(String)`, `notConfigured`, `unknownAccount(String)`, `unknownMessage(String)`, `unknownLabel(String)`, `revoked`, `gmail(status: Int, message: String)`, `signInCancelled`, `signInFailed(String)`, `tokenRefresh(String)` and `keychain(String)`.
- **gmail-payload**: The `gmail` case MUST carry an integer `status` and a string `message`, both labelled.
- **gmail-status-zero**: The Gmail REST client MUST use `gmail(status: 0, ...)` for a request whose URL cannot be built (message "Invalid URL for" followed by the path), so a status of 0 denotes a failure before any HTTP response.
- **token-refresh-scope**: `tokenRefresh` MUST be used for Google's token endpoint failing for a reason other than revoked access (a 5xx, a bad reply), per its doc comment.
- **keychain-scope**: `keychain` MUST be used for the Keychain failing to read or remove a credential (for example, when it is locked), per its doc comment.
- **revoked-distinct**: Revoked access (the token endpoint answering `invalid_grant`, or no stored credential for a connection) MUST be reported as `revoked`, never as `tokenRefresh`, because callers treat the two differently.

### Protocol conformance

- **conforms-error**: `IntegrationError` MUST conform to `Error`.
- **conforms-sendable**: `IntegrationError` MUST conform to `Sendable`, so an error can cross actor and task boundaries.
- **conforms-equatable**: `IntegrationError` MUST conform to `Equatable`, with the synthesized rule that two values are equal when the case and every payload match. Callers rely on it to compare against `.revoked` and to match `gmail(status: 404, ...)`.
- **conforms-localized**: `IntegrationError` MUST conform to `LocalizedError` and return a non-nil `errorDescription` for every case.

### Descriptions

- **desc-invalid-settings**: `invalidSettings(reason)` MUST describe itself as `Invalid sync settings: <reason>`.
- **desc-not-configured**: `notConfigured` MUST describe itself as `Gmail is not configured — import an OAuth client JSON first`.
- **desc-unknown-account**: `unknownAccount(account)` MUST describe itself as `No connected account matches “<account>”`, wrapping the value in curly double quotes.
- **desc-unknown-message**: `unknownMessage(id)` MUST describe itself as `No message matches “<id>”`, wrapping the value in curly double quotes.
- **desc-unknown-label**: `unknownLabel(id)` MUST describe itself as `No label matches “<id>”`, wrapping the value in curly double quotes.
- **desc-revoked**: `revoked` MUST describe itself as `Google access was revoked — sign in again`.
- **desc-gmail**: `gmail(status, message)` MUST describe itself as `Gmail returned <status>: <message>`.
- **desc-sign-in-cancelled**: `signInCancelled` MUST describe itself as `Sign-in was cancelled`.
- **desc-sign-in-failed**: `signInFailed(reason)` MUST describe itself as `Sign-in failed: <reason>`.
- **desc-token-refresh**: `tokenRefresh(reason)` MUST describe itself as `Token refresh failed: <reason>`.
- **desc-keychain**: `keychain(reason)` MUST describe itself as `Keychain error: <reason>`.
- **desc-verbatim-payload**: A payload string MUST be inserted into the description unchanged: no trimming, truncation or escaping.

### Where each case is raised

- **raised-invalid-settings**: `invalidSettings` is thrown by `GoogleOAuthClientConfig.parse(json:)` for non-JSON input or missing keys, and by `MailSyncSettings.validated()` when `windowDays` is outside 1–3650 or `pollIntervalMinutes` is outside 1–1440.
- **raised-not-configured**: `notConfigured` is thrown by `MailIntegrationService` when no provider configuration or OAuth client is available, and when provider removals are pending.
- **raised-unknown-account**: `unknownAccount` is thrown by `MailIntegrationService` when an account identifier or email matches no connection.
- **raised-unknown-message**: `unknownMessage` is caught by `MailIntegrationService.handle` and converted to a `notFound` response carrying its description.
- **raised-unknown-label**: `unknownLabel` is declared, but no other file in the integrations sources throws it.
- **raised-revoked**: `revoked` is thrown by the Google token endpoint on `invalid_grant`, by the credential store when a connection has no stored credential, and by `MailIntegrationService` when a sync is requested for a connection whose status is revoked. A caught `revoked` sets the connection status to `revoked`; any other error sets it to `error`.
- **raised-gmail**: `gmail` is thrown by `GmailRESTClient` for a non-success Gmail response or an unbuildable URL. Callers treat statuses 400 and 404 as "the item is gone" in several paths.
- **raised-sign-in**: `signInCancelled` is thrown when the user or the calling task cancels sign-in, and `signInFailed` when sign-in fails, times out ("Sign-in timed out"), returns no access token or no refresh token, or cannot start its local listener or save the credential.
- **raised-token-refresh**: `tokenRefresh` is thrown with `<status> <error code>` for a failed refresh or revoke call, `no access_token in reply` for a reply without a token, and `invalid endpoint <endpoint>` for an unusable endpoint.
- **raised-keychain**: `keychain` is thrown when the Google credential or the OAuth client secret cannot be read or removed.

