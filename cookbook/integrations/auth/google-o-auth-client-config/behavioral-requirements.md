
Data shape

- **fields**: The type MUST expose exactly two immutable string fields, `clientId` and `clientSecret`.
- **memberwise-init**: The public initializer MUST store both arguments unchanged. It MUST NOT trim, validate or reject empty strings; validation happens only in `parse(json:)`.
- **value-semantics**: The type MUST be `Equatable` with equality over both fields, and MUST be `Sendable` so a config can cross concurrency domains without isolation.

Parsing (`parse(json:)`)

- **parse-entry**: `parse(json:)` MUST be a `static` throwing function taking `Data` and returning a `GoogleOAuthClientConfig`.
- **parse-json-object-required**: `parse(json:)` MUST throw `IntegrationError.invalidSettings("the OAuth client file is not valid JSON")` when the data does not decode as JSON or decodes to anything other than an object (an array, string or number, or empty data).
- **parse-web-client-rejected**: `parse(json:)` MUST throw `IntegrationError.invalidSettings("this is a Web application client; create a Desktop app OAuth client instead")` when the root object has no `installed` key and has a `web` key.
- **parse-installed-keys-required**: `parse(json:)` MUST throw `IntegrationError.invalidSettings("the OAuth client file has no installed.client_id and installed.client_secret")` when `installed` is missing (with no `web` key), is not an object, or lacks `client_id` or `client_secret` as a string.
- **parse-empty-values-rejected**: `parse(json:)` MUST throw the same missing-keys error when `installed.client_id` or `installed.client_secret` is an empty string.
- **parse-success**: `parse(json:)` MUST return a config whose `clientId` is `installed.client_id` and whose `clientSecret` is `installed.client_secret`, exactly as written in the file.
- **parse-extra-keys-ignored**: `parse(json:)` MUST ignore every other key in the file, in the root object and inside `installed` (for example `auth_uri`).
- **parse-installed-wins**: `parse(json:)` MUST read `installed` and ignore `web` when both keys are present, because the Web-client rejection applies only when `installed` is absent.
- **parse-no-trimming**: `parse(json:)` MUST NOT trim or otherwise alter the id or secret; a value of only whitespace is accepted because it is non-empty.
- **parse-error-type**: Every failure of `parse(json:)` MUST be an `IntegrationError.invalidSettings` whose associated string is the reason. `IntegrationError.errorDescription` renders it as "Invalid sync settings: " followed by the reason.
- **parse-is-pure**: `parse(json:)` MUST have no side effect and MUST NOT perform I/O.

Serialising (`installedJSON()`)

- **installed-json-shape**: `installedJSON()` MUST return JSON of exactly the form `{"installed":{"client_id":<id>,"client_secret":<secret>}}`, with no other keys.
- **installed-json-key-order**: `installedJSON()` MUST serialise with sorted keys (`.sortedKeys`), so equal configs produce byte-identical output.
- **installed-json-round-trip**: The output of `installedJSON()` MUST be accepted by `parse(json:)` and MUST yield an equal config whenever both fields are non-empty.
- **installed-json-no-validation**: `installedJSON()` MUST NOT validate the fields. A config with an empty field serialises, and its output is then rejected by `parse(json:)`.
- **installed-json-throws**: `installedJSON()` MUST be declared `throws` and MUST propagate any `JSONSerialization` error unchanged. With two `String` values the source has no path that raises one.

Ordering and concurrency

- **no-shared-state**: The type MUST hold no shared mutable state, so concurrent calls to `parse(json:)` and `installedJSON()` MUST NOT interfere with each other. Both are synchronous and not tied to an actor or queue.

Security of the secret

- **secret-sensitivity**: `clientSecret` is sensitive credential material. The type itself MUST NOT persist, log or transmit it; it exists only as a field value held by its owner.
- **secret-not-in-errors**: The error strings thrown by `parse(json:)` MUST NOT contain the file's contents, the client id or the client secret.
- **secret-storage-by-caller**: Persisting the secret is the caller's job. The source's only caller that does so, `MailIntegrationService.importOAuthClient`, stores it through its secret store (the Keychain) and keeps only the client id in the provider config. `GoogleOAuthClientConfig` defines no token lifetime or revocation behavior; those belong to `GoogleTokenProvider` and `GoogleAuthorizer`.

