
`GoogleOAuthClientConfig` is the in-memory form of the Google "Desktop app" OAuth client that the user imports: the pair of `clientId` and `clientSecret` found in the client JSON that Google's console lets the user download. It is a `public struct` conforming to `Sendable` and `Equatable`, with two `public let` fields and no mutation after construction.

It has two operations. `parse(json:)` turns the downloaded file into a config, or throws `IntegrationError.invalidSettings` with a reason. `installedJSON()` turns a config back into the downloaded file's shape, so values typed into a form travel through the same import and the same `parse` checks as an uploaded file (the source's own doc comment on `installedJSON`).

The type does no network, file, Keychain or logging work. Its callers use it as follows:

- `MailIntegrationService` parses an imported file, stores the secret under `GoogleTokenProvider.clientSecretKey` in the secret store, saves the id in the provider config, and rebuilds a config from the two stored halves when a sign-in or refresh needs one.
- `GmailSettingsModel` builds a config from the two form fields (trimmed) and sends `installedJSON()` as the import payload.
- `GoogleAuthorizer`, `GoogleTokenEndpoint` and `GoogleTokenProvider` take a config as a parameter to sign in, refresh and fetch access tokens.

