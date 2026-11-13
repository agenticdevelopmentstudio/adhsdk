
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| integration-error-001 | desc-revoked | `IntegrationError.revoked.errorDescription` (test `MailSyncSettingsTests.errorText`) | `Google access was revoked — sign in again` |
| integration-error-002 | desc-not-configured | `IntegrationError.notConfigured.errorDescription` (test `MailSyncSettingsTests.errorText`) | `Gmail is not configured — import an OAuth client JSON first` |
| integration-error-003 | desc-gmail, gmail-payload | `IntegrationError.gmail(status: 503, message: "Backend Error").errorDescription` | `Gmail returned 503: Backend Error` |
| integration-error-004 | conforms-equatable | `IntegrationError.gmail(status: 403, message: "Insufficient Permission") == IntegrationError.gmail(status: 403, message: "Insufficient Permission")` (the `GmailRESTClientTests` expectations rely on this) | `true` |
| integration-error-005 | conforms-equatable | `IntegrationError.gmail(status: 403, message: "x") == IntegrationError.gmail(status: 404, message: "x")` | `false` |
| integration-error-006 | desc-unknown-account | `IntegrationError.unknownAccount("a@b.com").errorDescription` | `No connected account matches “a@b.com”` |
| integration-error-007 | desc-unknown-message, desc-unknown-label | `unknownMessage("m1")` and `unknownLabel("L1")` descriptions | `No message matches “m1”` and `No label matches “L1”` |
| integration-error-008 | desc-sign-in-failed, desc-sign-in-cancelled | `signInFailed("Google returned no refresh token")` and `signInCancelled` descriptions (`GoogleOAuthTests` throws the former) | `Sign-in failed: Google returned no refresh token` and `Sign-in was cancelled` |
| integration-error-009 | desc-token-refresh, desc-keychain | `tokenRefresh("500 backend_error")` and `keychain("Could not read the Google credential: locked")` descriptions (`GoogleOAuthTests`) | `Token refresh failed: 500 backend_error` and `Keychain error: Could not read the Google credential: locked` |
| integration-error-010 | desc-invalid-settings, raised-invalid-settings | `MailSyncSettings` with an out-of-range `windowDays`, then `validated()` (`MailSyncSettingsTests`) | Throws `IntegrationError.invalidSettings`, described as `Invalid sync settings: windowDays must be 1–3650, got <value>` |
| integration-error-011 | raised-revoked | A Gmail call fails with `IntegrationError.revoked` during sync (`MailIntegrationServiceTests`) | The connection is saved with status `revoked` |
| integration-error-012 | raised-gmail | A Gmail call fails with `gmail(status: 500, message: "boom")` (`MailIntegrationServiceTests`) | The connection status is `error`, not `revoked` |
| integration-error-013 | desc-verbatim-payload | `invalidSettings("  spaced ")` | `Invalid sync settings:   spaced ` with the payload's whitespace intact |

