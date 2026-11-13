
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | the OAuth client file is not valid JSON | Reason in `IntegrationError.invalidSettings` from `parse(json:)` |
| none (hardcoded) | this is a Web application client; create a Desktop app OAuth client instead | Reason for a file with `web` and no `installed` |
| none (hardcoded) | the OAuth client file has no installed.client_id and installed.client_secret | Reason for a missing, mistyped or empty id or secret |

The reasons are hardcoded English literals, not looked up through a string table. `IntegrationError.errorDescription` wraps them, also in English, as "Invalid sync settings: <reason>". The keys `installed`, `web`, `client_id` and `client_secret` are Google's file format and are not localized.

