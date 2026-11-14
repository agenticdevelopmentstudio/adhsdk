
`GoogleOAuthClientConfig` is the in-memory form of the Google "Desktop app" OAuth client that the user imports: the pair of `clientId` and `clientSecret` found in the client JSON that Google's console lets the user download. It is a `public struct` conforming to `Sendable` and `Equatable`, with two `public let` fields and no mutation after construction.

It has two operations. `parse(json:)` turns the downloaded file into a config, or throws `IntegrationError.invalidSettings` (cookbook:351e3bf8-b137-4f59-94de-c769aa8b0666) with a reason. `installedJSON()` turns a config back into the downloaded file's shape, so values typed into a form travel through the same import and the same `parse` checks as an uploaded file, giving one validated entry point for the OAuth client.

The type does no network, file, Keychain or logging work. Its callers use it as follows:

- `MailIntegrationService` (cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) parses an imported file, stores the secret under `GoogleTokenProvider.clientSecretKey` in the secret store, saves the id in the provider config, and rebuilds a config from the two stored halves when a sign-in or refresh needs one.
- `GmailSettingsModel` (cookbook:2fa64944-9744-4d71-8fed-f785e7ce1e51) builds a config from the two form fields (trimmed) and sends `installedJSON()` as the import payload.
- `GoogleSignInFlow` (implemented by `AppAuthGoogleSignIn`), `GoogleTokenEndpoint` (implemented by `URLSessionGoogleTokenEndpoint`) and `GoogleTokenProvider` take a config as a parameter to sign in, refresh and fetch access tokens.

