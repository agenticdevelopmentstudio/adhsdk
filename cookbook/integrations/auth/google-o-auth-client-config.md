---
id: 238f4d91-4a22-4a0d-ae4b-b4070d02b357
title: "GoogleOAuthClientConfig"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Value type for the Google Desktop-app OAuth client: parses the downloaded client JSON, rejects Web clients, and re-emits the same JSON shape."
platforms:
  - swift
  - macos
tags:
  - oauth
  - google
  - gmail
  - credentials
  - parsing
depends-on: []
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - 2fa64944-9744-4d71-8fed-f785e7ce1e51
  - 351e3bf8-b137-4f59-94de-c769aa8b0666
references: []
approved-by: ""
approved-date: ""
---

# GoogleOAuthClientConfig

## Overview

`GoogleOAuthClientConfig` is the in-memory form of the Google "Desktop app" OAuth client that the user imports: the pair of `clientId` and `clientSecret` found in the client JSON that Google's console lets the user download. It is a `public struct` conforming to `Sendable` and `Equatable`, with two `public let` fields and no mutation after construction.

It has two operations. `parse(json:)` turns the downloaded file into a config, or throws `IntegrationError.invalidSettings` (cookbook:351e3bf8-b137-4f59-94de-c769aa8b0666) with a reason. `installedJSON()` turns a config back into the downloaded file's shape, so values typed into a form travel through the same import and the same `parse` checks as an uploaded file, giving one validated entry point for the OAuth client.

The type does no network, file, Keychain or logging work. Its callers use it as follows:

- `MailIntegrationService` (cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) parses an imported file, stores the secret under `GoogleTokenProvider.clientSecretKey` in the secret store, saves the id in the provider config, and rebuilds a config from the two stored halves when a sign-in or refresh needs one.
- `GmailSettingsModel` (cookbook:2fa64944-9744-4d71-8fed-f785e7ce1e51) builds a config from the two form fields (trimmed) and sends `installedJSON()` as the import payload.
- `GoogleSignInFlow` (implemented by `AppAuthGoogleSignIn`), `GoogleTokenEndpoint` (implemented by `URLSessionGoogleTokenEndpoint`) and `GoogleTokenProvider` take a config as a parameter to sign in, refresh and fetch access tokens.

## Behavioral Requirements

Data shape

- **fields**: The type MUST expose exactly two immutable string fields, `clientId` and `clientSecret`.
- **memberwise-init**: The public initializer MUST store both arguments unchanged. It MUST NOT trim, validate or reject empty strings; validation happens only in `parse(json:)`.
- **value-semantics**: The type MUST be `Equatable` with equality over both fields, and MUST be `Sendable` so a config can cross concurrency domains without isolation.

Parsing (`parse(json:)`)

- **parse-entry**: `parse(json:)` MUST be a static (type-level) operation taking the raw file bytes and returning a `GoogleOAuthClientConfig`, reporting failure as a typed error.
- **parse-json-object-required**: `parse(json:)` MUST throw a typed invalid-settings error `IntegrationError.invalidSettings("the OAuth client file is not valid JSON")` when the data does not decode as JSON or decodes to anything other than an object (an array, string or number, or empty data).
- **parse-web-client-rejected**: `parse(json:)` MUST throw `IntegrationError.invalidSettings("this is a Web application client; create a Desktop app OAuth client instead")` when the root object has no `installed` key and has a `web` key.
- **parse-installed-keys-required**: `parse(json:)` MUST throw `IntegrationError.invalidSettings("the OAuth client file has no installed.client_id and installed.client_secret")` when `installed` is missing (with no `web` key), is not an object, or lacks `client_id` or `client_secret` as a string.
- **parse-empty-values-rejected**: `parse(json:)` MUST throw the same missing-keys error when `installed.client_id` or `installed.client_secret` is an empty string.
- **parse-success**: `parse(json:)` MUST return a config whose `clientId` is `installed.client_id` and whose `clientSecret` is `installed.client_secret`, exactly as written in the file.
- **parse-extra-keys-ignored**: `parse(json:)` MUST ignore every other key in the file, in the root object and inside `installed` (for example `auth_uri`).
- **parse-installed-wins**: `parse(json:)` MUST read `installed` and ignore `web` when both keys are present, because the Web-client rejection applies only when `installed` is absent.
- **parse-no-trimming**: `parse(json:)` MUST NOT trim or otherwise alter the id or secret; a value of only whitespace is accepted because it is non-empty.
- **parse-error-type**: Every failure of `parse(json:)` MUST be an `IntegrationError.invalidSettings` whose associated string is the reason.
- **parse-is-pure**: `parse(json:)` MUST have no side effect and MUST NOT perform I/O.

Serialising (`installedJSON()`)

- **installed-json-shape**: `installedJSON()` MUST return JSON of exactly the form `{"installed":{"client_id":<id>,"client_secret":<secret>}}`, with no other keys.
- **installed-json-key-order**: `installedJSON()` MUST emit keys in sorted order, so equal configs produce identical output on one platform. Escaping of characters such as `/` is platform-specific, so byte equality across platforms is not required; every output MUST still decode to the same values. The Swift source uses `.sortedKeys`.
- **installed-json-round-trip**: The output of `installedJSON()` MUST be accepted by `parse(json:)` and MUST yield an equal config whenever both fields are non-empty.
- **installed-json-no-validation**: `installedJSON()` MUST NOT validate the fields. A config with an empty field serialises, and its output is then rejected by `parse(json:)`.
- **installed-json-throws**: `installedJSON()` MUST surface any serialisation failure to the caller as a typed error rather than swallowing it. With two string values the Swift source has no path that raises one (it is declared `throws` and propagates any `JSONSerialization` error).

Ordering and concurrency

- **no-shared-state**: The type MUST hold no shared mutable state, so concurrent calls to `parse(json:)` and `installedJSON()` MUST NOT interfere with each other. Both are synchronous and not tied to an actor or queue.

Security of the secret

- **secret-sensitivity**: `clientSecret` is sensitive credential material. The type itself MUST NOT persist, log or transmit it; it exists only as a field value held by its owner.
- **secret-not-in-errors**: The error strings thrown by `parse(json:)` MUST NOT contain the file's contents, the client id or the client secret.
- **secret-no-redaction-gap**: The Swift source has no redaction: the synthesized `description` and `dump` of the struct print `clientSecret`. This is a known gap, stated here as fact; no requirement or test covers it (see Design Decisions and Compliance).

## Appearance

Not applicable — this is a data type and parser for an OAuth client file, not a visual component.

## States

Not applicable — this is a stateless immutable value type, not a visual component; it has no runtime state machine.

## Accessibility

Not applicable — this is a data type and parser, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gocc-001 | parse-success, parse-extra-keys-ignored | `{"installed":{"client_id":"abc","client_secret":"xyz","auth_uri":"u"}}` (test `parsesInstalledClientJSON`) | Returns a config equal to `clientId` "abc", `clientSecret` "xyz" |
| gocc-002 | parse-web-client-rejected, parse-error-type | `{"web":{"client_id":"abc","client_secret":"xyz"}}` (test `rejectsWebClientJSON`) | Throws `IntegrationError.invalidSettings` with the exact reason "this is a Web application client; create a Desktop app OAuth client instead" (the existing test asserts only the error type) |
| gocc-003 | parse-installed-keys-required | `{"installed":{"client_id":"abc"}}` (test `rejectsMissingKeys`) | Throws `IntegrationError.invalidSettings` with the exact reason "the OAuth client file has no installed.client_id and installed.client_secret" (the existing test asserts only the error type) |
| gocc-004 | parse-json-object-required | `not json`, `[]` and empty data | Each throws `IntegrationError.invalidSettings("the OAuth client file is not valid JSON")` |
| gocc-005 | parse-empty-values-rejected | `{"installed":{"client_id":"","client_secret":"xyz"}}` | Throws the missing-keys message |
| gocc-006 | parse-installed-keys-required | `{"installed":{"client_id":"abc","client_secret":7}}` and `{"installed":"x"}` and `{}` | Each throws the missing-keys message |
| gocc-007 | parse-installed-wins | `{"installed":{"client_id":"a","client_secret":"b"},"web":{}}` | Returns a config with id "a" and secret "b" |
| gocc-008 | parse-no-trimming | `{"installed":{"client_id":" a ","client_secret":"b"}}` | Returns `clientId` " a " with its spaces |
| gocc-009 | installed-json-shape, installed-json-key-order | `GoogleOAuthClientConfig(clientId: "id", clientSecret: "secret").installedJSON()` | The bytes `{"installed":{"client_id":"id","client_secret":"secret"}}` |
| gocc-010 | installed-json-round-trip | `installedJSON()` of a config with id "id-1.apps.googleusercontent.com" and secret "GOCSPX-secret", fed to `parse(json:)` (test `savingTheClientFormSendsItAsInstalledJSONAndClearsTheFields`) | Returns a config equal to the original |
| gocc-011 | installed-json-no-validation | `GoogleOAuthClientConfig(clientId: "", clientSecret: "s").installedJSON()` then `parse(json:)` | `installedJSON()` returns data; `parse(json:)` throws the missing-keys message |
| gocc-012 | memberwise-init, value-semantics | Two configs built with the same two strings, one with a different secret | The first two compare equal; the third does not |
| gocc-013 | secret-not-in-errors | Two inputs: the non-JSON body `not json GOCSPX-abc`, and `{"installed":{"client_id":"","client_secret":"GOCSPX-abc"}}` | For each, the thrown reason is the fixed message for that failure and does not contain "GOCSPX-abc" |

Test traceability: gocc-001 to gocc-003 are the assertions of `GoogleOAuthTests` (target `AgenticDeveloperHubSDKIntegrationsTests`). gocc-010 is derived from `GmailSettingsModelTests` and the use of `installedJSON()` in `MailIntegrationServiceTests`. gocc-004 to gocc-009 and gocc-011 to gocc-013 follow from the source and have no test beside it.

## Edge Cases

- **empty-or-malformed-data**: Empty data, truncated JSON or non-JSON bytes MUST throw the not-valid-JSON error. The underlying decoder error is discarded (`try?`) and replaced by that fixed message, which is lossy but still surfaced to the caller.
- **non-object-root**: A JSON array, string, number or `null` at the root MUST throw the not-valid-JSON error, because the decode is cast to a string-keyed dictionary.
- **web-client**: See #behavioral-requirements/parse-web-client-rejected.
- **both-keys**: See #behavioral-requirements/parse-installed-wins.
- **wrong-types**: See #behavioral-requirements/parse-installed-keys-required; a number, `null` or array in place of a string or object takes that path.
- **installed-null**: `"installed": null` with no `web` key MUST throw the missing-keys error; a present `null` is not treated as missing, but it fails the object cast.
- **empty-strings**: See #behavioral-requirements/parse-empty-values-rejected and #behavioral-requirements/parse-no-trimming. The form model trims before constructing a config; the type does not.
- **slash-escaping**: `installedJSON()` MAY escape a forward slash in a value as a backslash and slash pair, as `JSONSerialization` does by default. The output still decodes to the original string, so the round trip holds.
- **unicode-and-special-characters**: A value with quotes, backslashes or non-ASCII characters MUST survive the `installedJSON()` then `parse(json:)` round trip, because the JSON layer escapes and decodes them.
- **large-input**: The source sets no size limit on the data; the whole input is decoded in memory. A caller SHOULD impose a limit before calling if the file comes from an untrusted source.
- **missing-keys-message**: The single missing-keys reason names both `installed.client_id` and `installed.client_secret` even when only one is absent, empty or mistyped, because the code does not distinguish which check failed (see Design Decisions).
- **secret-printed-by-description**: The struct's synthesized `description` and `dump` output includes `clientSecret`, and the source adds no masking.
- **concurrent-calls**: Not applicable beyond `no-shared-state`: both functions are pure and the type is immutable, so there is nothing to serialise.
- **network-and-offline**: Not applicable: the type performs no network, file-system or Keychain access, so there is no unreachable dependency or offline state.
- **cancellation-and-timeout**: Not applicable: both operations are synchronous and complete without suspension, so there is nothing to cancel and no timeout exists.
- **error-text-language**: The thrown reasons are fixed English strings with no localization (see Localization).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clientId` | `String` | none (required) | The Google OAuth client ID, passed to the initializer or read from `installed.client_id` |
| `clientSecret` | `String` | none (required) | The Google OAuth client secret, passed to the initializer or read from `installed.client_secret` |
| `json` | `Data` | none (required) | The downloaded client file given to `parse(json:)` |

The type reads no environment variables, settings keys or files and has no injected dependencies. The accepted file shape is the object keyed `installed` with string members `client_id` and `client_secret`.

## Deep Linking

Not applicable: the type parses a JSON document and defines no URL, scheme or route.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | the OAuth client file is not valid JSON | Reason in `IntegrationError.invalidSettings` from `parse(json:)` |
| none (hardcoded) | this is a Web application client; create a Desktop app OAuth client instead | Reason for a file with `web` and no `installed` |
| none (hardcoded) | the OAuth client file has no installed.client_id and installed.client_secret | Reason for a missing, mistyped or empty id or secret |

The reasons are hardcoded English literals, not looked up through a string table. `IntegrationError.errorDescription` wraps them, also in English, as "Invalid sync settings: <reason>". The keys `installed`, `web`, `client_id` and `client_secret` are Google's file format and are not localized.

## Accessibility Options

Not applicable: the type has no visual surface, so it does not respond to Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the source reads no flag, setting or build condition.

## Analytics

Not applicable: the source emits no event, metric or counter.

## Privacy

- **Data collected**: The user's own Google OAuth client ID and client secret, supplied by the user.
- **Storage**: None by this type. Persisting the secret is the caller's job: `MailIntegrationService` (cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) (`importOAuthClient`) stores the secret in the secret store (Keychain) and the id in the provider config; neither is done here. Token lifetime and revocation belong to `GoogleTokenProvider` and `AppAuthGoogleSignIn`, not to this type.
- **Transmission**: None by this type. The values are later sent to Google's token endpoint by `URLSessionGoogleTokenEndpoint`, outside this source. `GmailSettingsModel` (cookbook:2fa64944-9744-4d71-8fed-f785e7ce1e51) sends `installedJSON()` to the service as an import request.
- **Retention**: A config lives as long as its owner holds it. Deleting the stored client is the caller's responsibility (`removeProvider` in `MailIntegrationService`).

## Logging

Not applicable: the source makes no log call, and the reasons it throws carry no value from the file.

## Platform Notes

- **SwiftUI**: Source platform: Swift. The code is `packages/apple/AgenticDeveloperHubSDK/Integrations/Auth/GoogleOAuthClientConfig.swift` and uses only Foundation (`JSONSerialization`, `Data`). `installedJSON()` is declared `throws` and passes `.sortedKeys` to `JSONSerialization`; `parse(json:)` decodes with `try?`, discarding the decoder error. It is a `Sendable`, `Equatable` struct, so SwiftUI form models can hold it directly. The form that feeds it, `GmailSettingsModel` (cookbook:2fa64944-9744-4d71-8fed-f785e7ce1e51) in the macOS target, trims the two fields before building the config.
- **Compose**: Use a Kotlin `data class` with two `val` strings for equality, and parse with `org.json.JSONObject` or `kotlinx.serialization` with `JsonObject` access. Android has no Foundation `Equatable` or `Sendable`; immutability of the `data class` gives the same thread-safety. Throw a sealed-class error carrying the reason in place of `IntegrationError.invalidSettings`. Android's `JSONObject.optString` returns an empty string for a missing key, so check key presence and type explicitly to keep the missing-key and empty-value errors distinct from success.
- **React/Web**: Use a frozen object or `readonly` interface for the two fields, and `JSON.parse` inside a try block for the not-valid-JSON case. `JSON.parse` accepts arrays and primitives, so check for a plain object before reading `installed`. Match the key presence rule: Web rejection only when `installed` is undefined and `web` is defined. Serialise with an explicit object literal built in sorted key order, since `JSON.stringify` follows insertion order; it does not escape forward slashes, which differs from the Swift output but still round-trips.
- **AppKit / UIKit**: The type is identical on both Apple UI stacks because it uses Foundation only. A UIKit or AppKit settings form should trim the entered id and secret before building the config, as `GmailSettingsModel` does, and import through `installedJSON()` so the same checks apply as for a dropped file.
- **WinUI 3**: Port to a C# `sealed record GoogleOAuthClientConfig(string ClientId, string ClientSecret)`, which gives value equality like `Equatable`. Parse with `System.Text.Json.JsonDocument.Parse` inside a try for `JsonException`, and check `JsonValueKind.Object` on the root, since `JsonDocument` accepts arrays and primitives. Test `TryGetProperty("installed", out var installed)` and `installed.ValueKind == JsonValueKind.Object`; treat `"web"` as the Web-client case only when `installed` is absent. Read members with `GetString()` after confirming `JsonValueKind.String`, and treat an empty result as missing. Throw a custom `IntegrationException` (or a result type) carrying the reason. Serialise with `Utf8JsonWriter` writing `installed`, `client_id`, `client_secret` in that order, or `JsonSerializer.Serialize` of a `SortedDictionary`; `System.Text.Json` escapes `+` and non-ASCII by default, so set `JavaScriptEncoder.UnsafeRelaxedJsonEscaping` if output close to the Swift version matters (it round-trips either way). For the form, bind two fields through a view model implementing `INotifyPropertyChanged`, use a `PasswordBox` for the secret, and keep the secret in `Windows.Security.Credentials.PasswordVault` in place of the Keychain; this type holds no storage.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Auth/GoogleOAuthClientConfig.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `parse(json:)` rejects a Web client with its own message rather than the generic missing-keys message.
**Rationale**: A Web client's file has `web` where a Desktop client has `installed`, and the Desktop flow cannot use it. A specific message tells the user which client type to create. The check runs only when `installed` is absent, so a file with both keys is read as installed.
**Approved**: pending

**Decision**: `installedJSON()` re-emits the downloaded file's shape instead of a bespoke format.
**Rationale**: Values typed into a form go through the same import and the same `parse` checks as an uploaded file, so there is one validated entry point for the OAuth client.
**Approved**: pending

**Decision**: `parse(json:)` uses one missing-keys message for every missing, empty or mistyped field.
**Rationale**: The message tells the user what the file must contain. A single message keeps the error text fixed and leaks nothing from the file. It reads "and" because the file needs both values, even when only one is wrong.
**Approved**: pending

**Decision**: `installedJSON()` sorts keys.
**Rationale**: Equal configs give identical JSON on one platform, which makes the import payload deterministic for tests and comparison.
**Approved**: pending

**Decision**: The memberwise initializer does not validate, and `parse(json:)` does not trim.
**Rationale**: Validation lives in one place, the import path, and trimming lives in the form model that owns user typing. A config built by the service from stored values is rebuilt as is. A consequence is that a whitespace-only value passes `parse(json:)`.
**Approved**: pending

**Decision**: `parse(json:)` collapses every decoding failure into one fixed message.
**Rationale**: The decode uses `try?`, so the decoder's detail is dropped. The message tells the user what the file must be, and no file content can leak into the error. The loss of detail is deliberate.
**Approved**: pending

**Decision**: The type holds the secret as a plain `String` and leaves storage to the caller.
**Rationale**: The type is a transient carrier between import and the token calls. `MailIntegrationService` keeps the secret in the Keychain through its secret store and only the id in the database. The type itself offers no redaction (no `CustomStringConvertible` mask), so the synthesized `description` and `dump`, and any caller printing a config, would print the secret. This is a known gap, not a requirement.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | partial | security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The type passes separation-of-concerns: it only parses and serialises one file shape, while storage, network and form handling sit in `MailIntegrationService`, the token types and `GmailSettingsModel`. Unit-test coverage is partial: `GoogleOAuthTests` covers a valid file, a Web client and a missing key (the last two asserting only the error type), and the form model's test covers the `installedJSON()` round trip, but no test beside the source covers invalid JSON, empty values, wrong types, both keys present or key sorting. Explicit error handling passes because every failure is a typed `invalidSettings` with a reason. Secure storage is partial because the type stores nothing itself and leaves the secret in an ordinary `String`, with the Keychain write done by its caller. No-hardcoded-strings fails because the three error reasons are English literals with no string table.

Secure log output is partial: the type logs nothing and its errors carry no file content, but the synthesized `description` and `dump` print `clientSecret` because the struct has no redaction.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
