
- **Data collected**: The user's own Google OAuth client ID and client secret, supplied by the user.
- **Storage**: None by this type. The caller `MailIntegrationService` stores the secret in the secret store (Keychain) and the id in the provider config; neither is done here.
- **Transmission**: None by this type. The values are later sent to Google's token endpoint by `URLSessionGoogleTokenEndpoint`, outside this source. `GmailSettingsModel` sends `installedJSON()` to the service as an import request.
- **Retention**: A config lives as long as its owner holds it. Deleting the stored client is the caller's responsibility (`removeProvider` in `MailIntegrationService`).

