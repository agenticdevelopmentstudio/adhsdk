
- **Data collected**: The user's own Google OAuth client ID and client secret, supplied by the user.
- **Storage**: None by this type. Persisting the secret is the caller's job: `MailIntegrationService` (cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) (`importOAuthClient`) stores the secret in the secret store (Keychain) and the id in the provider config; neither is done here. Token lifetime and revocation belong to `GoogleTokenProvider` and `AppAuthGoogleSignIn`, not to this type.
- **Transmission**: None by this type. The values are later sent to Google's token endpoint by `URLSessionGoogleTokenEndpoint`, outside this source. `GmailSettingsModel` (cookbook:2fa64944-9744-4d71-8fed-f785e7ce1e51) sends `installedJSON()` to the service as an import request.
- **Retention**: A config lives as long as its owner holds it. Deleting the stored client is the caller's responsibility (`removeProvider` in `MailIntegrationService`).

