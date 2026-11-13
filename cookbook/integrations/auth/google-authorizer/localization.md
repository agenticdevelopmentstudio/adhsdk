
The component returns hardcoded English reason strings inside `IntegrationError` cases (for example `Sign-in timed out`, `Google returned no access token`, `Could not remove the Google credential`) and no localization keys. `IntegrationError.errorDescription`, in a sibling file, wraps them in English prefixes. Localization is therefore not implemented here; hosts that need other languages translate at the display layer.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none | `Sign-in timed out` | `signInFailed` reason on deadline expiry |
| none | `Could not start the local sign-in listener` | `signInFailed` reason on listener failure |
| none | `Google returned no access token` / `Google returned no refresh token` | `signInFailed` reasons on an incomplete token response |
| none | `Could not save the Google credential to the Keychain` | `signInFailed` reason on a save failure |
| none | `Could not remove the Google credential` / `Could not read the Google credential: <description>` | `keychain` reasons |

