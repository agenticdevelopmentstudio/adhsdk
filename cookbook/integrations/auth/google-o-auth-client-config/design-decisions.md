
**Decision**: `parse(json:)` rejects a Web client with its own message rather than the generic missing-keys message.
**Rationale**: A Web client's file has `web` where a Desktop client has `installed`, and the Desktop flow cannot use it. A specific message tells the user which client type to create. The check runs only when `installed` is absent, so a file with both keys is read as installed.
**Approved**: pending

**Decision**: `installedJSON()` re-emits the downloaded file's shape instead of a bespoke format.
**Rationale**: The source's doc comment says values typed into a form go through the same import and the same `parse` checks as an uploaded file, so there is one validated entry point for the OAuth client.
**Approved**: pending

**Decision**: `installedJSON()` sorts keys.
**Rationale**: Equal configs give byte-identical JSON, which makes the import payload deterministic for tests and comparison.
**Approved**: pending

**Decision**: The memberwise initializer does not validate, and `parse(json:)` does not trim.
**Rationale**: Validation lives in one place, the import path, and trimming lives in the form model that owns user typing. A config built by the service from stored values is rebuilt as is. A consequence is that a whitespace-only value passes `parse(json:)`.
**Approved**: pending

**Decision**: `parse(json:)` collapses every decoding failure into one fixed message.
**Rationale**: The decode uses `try?`, so the decoder's detail is dropped. The message tells the user what the file must be, and no file content can leak into the error. The loss of detail is deliberate.
**Approved**: pending

**Decision**: The type holds the secret as a plain `String` and leaves storage to the caller.
**Rationale**: The type is a transient carrier between import and the token calls. `MailIntegrationService` keeps the secret in the Keychain through its secret store and only the id in the database. The type itself offers no redaction, so a caller printing a config would print the secret.
**Approved**: pending

