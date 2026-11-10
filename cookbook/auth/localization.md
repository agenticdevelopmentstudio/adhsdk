
| String Key | Default (en) | Context |
|-----------|---------------|---------|
| (none — inline literal) | `unknown error` | Fallback message in `ADHClient+Session.message(_:)` when the backend's `_Error.error` payload has neither `message` nor `code`. Surfaces to callers via `SessionError.unexpectedResponse`. |
| (none — inline literal) | `HTTP <status>` | Fallback message built in every `.undocumented(status, _)` branch across `signIn`, `completeMfa`, `sendMfaSms`, `passkeyOptions`, `completePasskey`, `mfaPasskeyOptions`, `completeMfaPasskey`, `exchangeOAuthCode`, and `currentUser`, and in the raw-exchange's `RawRequestError.invalidPath` mapping. Not translated; interpolates the raw HTTP status code. |

