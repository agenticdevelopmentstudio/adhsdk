---
id: 351e3bf8-b137-4f59-94de-c769aa8b0666
title: "IntegrationError"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The single error enum for integration operations, with eleven cases and a human-readable sentence for each."
platforms:
  - swift
  - macos
  - ios
tags:
  - integrations
  - errors
depends-on: []
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - c448c9f4-195d-4625-a49d-22dd5468a914
  - 238f4d91-4a22-4a0d-ae4b-b4070d02b357
  - df121975-deb8-49a9-b023-0aadcb0923d8
  - c19280fd-b80c-46f3-a6a7-0b60a0c90d91
references: []
approved-by: ""
approved-date: ""
---

# IntegrationError

## Overview

IntegrationError is the one error type that integration code throws or returns when an operation fails: settings validation, Google sign-in, token refresh, Keychain access, account and message lookup, and Gmail REST calls. It is a Swift enum with eleven cases, several carrying a string or a status code, and its doc comment states the design goal: "Every case reads as a sentence a person can act on." It conforms to `Error`, `Equatable`, `Sendable` and `LocalizedError`. It holds no state and performs no I/O. Callers branch on the case, and surface `errorDescription` to a person.

## Behavioral Requirements

### Cases and payloads

- **case-set**: `IntegrationError` MUST declare exactly these cases: `invalidSettings(String)`, `notConfigured`, `unknownAccount(String)`, `unknownMessage(String)`, `unknownLabel(String)`, `revoked`, `gmail(status: Int, message: String)`, `signInCancelled`, `signInFailed(String)`, `tokenRefresh(String)` and `keychain(String)`.
- **gmail-payload**: The `gmail` case MUST carry an integer `status` and a string `message`, both labelled.
- **keep-unknown-label**: `unknownLabel(String)` MUST stay in the case set with its description, even though no other integrations file throws it, so callers compile against the same set.

### Protocol conformance

- **conforms-error**: `IntegrationError` MUST conform to `Error`.
- **conforms-sendable**: `IntegrationError` MUST conform to `Sendable`, so an error can cross actor and task boundaries.
- **conforms-equatable**: `IntegrationError` MUST conform to `Equatable`, with the synthesized rule that two values are equal when the case and every payload match. Callers rely on it to compare against `.revoked` and to match `gmail(status: 404, ...)`.
- **conforms-localized**: `IntegrationError` MUST conform to `LocalizedError` and return a non-nil `errorDescription` for every case.

### Descriptions

- **desc-invalid-settings**: `invalidSettings(reason)` MUST describe itself as `Invalid sync settings: <reason>`.
- **desc-not-configured**: `notConfigured` MUST describe itself as `Gmail is not configured — import an OAuth client JSON first`.
- **desc-unknown-account**: `unknownAccount(account)` MUST describe itself as `No connected account matches “<account>”`, wrapping the value in curly double quotes.
- **desc-unknown-message**: `unknownMessage(id)` MUST describe itself as `No message matches “<id>”`, wrapping the value in curly double quotes.
- **desc-unknown-label**: `unknownLabel(id)` MUST describe itself as `No label matches “<id>”`, wrapping the value in curly double quotes.
- **desc-revoked**: `revoked` MUST describe itself as `Google access was revoked — sign in again`.
- **desc-gmail**: `gmail(status, message)` MUST describe itself as `Gmail returned <status>: <message>`.
- **desc-sign-in-cancelled**: `signInCancelled` MUST describe itself as `Sign-in was cancelled`.
- **desc-sign-in-failed**: `signInFailed(reason)` MUST describe itself as `Sign-in failed: <reason>`.
- **desc-token-refresh**: `tokenRefresh(reason)` MUST describe itself as `Token refresh failed: <reason>`.
- **desc-keychain**: `keychain(reason)` MUST describe itself as `Keychain error: <reason>`.
- **desc-verbatim-payload**: A payload string MUST be inserted into the description unchanged: no trimming, truncation or escaping.
- **desc-typography**: The descriptions MUST use the exact non-ASCII characters of the source, never ASCII substitutes: the em dash U+2014 (`—`) in `notConfigured` and `revoked`, the en dash U+2013 (`–`) in the range text of the `batchModify` and `windowDays` messages that callers pass as payloads, and the curly double quotes U+201C and U+201D (`“ ”`) around the value in `unknownAccount`, `unknownMessage` and `unknownLabel`.

### Raised by

These bullets record which callers throw each case today. They describe other components, not the enum, and carry no MUST: the owning ingredient holds the binding requirement.

- **gmail-status-zero**: [GmailRESTClient](cookbook:c448c9f4-195d-4625-a49d-22dd5468a914) uses `gmail(status: 0, ...)` for a request whose URL cannot be built (message "Invalid URL for" followed by the path) and for a `batchModify` call whose id list is not 1 to the batch limit (message "batchModify takes 1–<limit> ids, got <count>"), so a status of 0 denotes a failure before any HTTP response.
- **token-refresh-scope**: `tokenRefresh` is used for Google's token endpoint failing for a reason other than revoked access (a 5xx, a bad reply), per its doc comment.
- **keychain-scope**: `keychain` is used for the Keychain failing to read or remove a credential (for example, when it is locked), per its doc comment.
- **revoked-distinct**: Revoked access (the token endpoint answering `invalid_grant`, or no stored credential for a connection) is reported as `revoked`, never as `tokenRefresh`, because callers treat the two differently.

- **raised-invalid-settings**: `invalidSettings` is thrown by [GoogleOAuthClientConfig](cookbook:df121975-deb8-49a9-b023-0aadcb0923d8).parse(json:) for non-JSON input, a Web application client file or missing keys, and by [MailSyncSettings](cookbook:238f4d91-4a22-4a0d-ae4b-b4070d02b357).validated() when `windowDays` is outside 1–3650 or `pollIntervalMinutes` is outside 1–1440.
- **raised-not-configured**: `notConfigured` is thrown by [MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) when no provider configuration or OAuth client is available, and when provider removals are pending.
- **raised-unknown-account**: `unknownAccount` is thrown by `MailIntegrationService` when an account identifier or email matches no connection, and by `IntegrationsStore`(cookbook:c19280fd-b80c-46f3-a6a7-0b60a0c90d91) when no live connection has the id being updated.
- **raised-unknown-message**: `unknownMessage` is thrown by `MailIntegrationService` when Gmail answers 400 or 404 for a requested message id, and `MailIntegrationService.handle` converts it to a `notFound` response carrying its description.
- **raised-unknown-label**: `unknownLabel` is declared, but no other file in the integrations sources throws it (see #requirements/keep-unknown-label).
- **raised-revoked**: `revoked` is thrown by the Google token endpoint on `invalid_grant`, by the credential store when a connection has no stored credential, and by `MailIntegrationService` when a sync is requested for a connection whose status is revoked. A recorded `revoked` sets the connection status to `revoked`; any other error except cancellation sets it to `error`.
- **raised-gmail**: `gmail` is thrown by [GmailRESTClient](cookbook:c448c9f4-195d-4625-a49d-22dd5468a914) for a non-success Gmail response, an unbuildable URL or a `batchModify` id list of the wrong size. Callers treat statuses 400 and 404 as "the item is gone" in several paths.
- **raised-sign-in**: `signInCancelled` is thrown when the user or the calling task cancels sign-in, and `signInFailed` when sign-in fails, times out ("Sign-in timed out"), returns no access token or no refresh token, or cannot start its local listener or save the credential.
- **raised-token-refresh**: `tokenRefresh` is thrown with `<status> <error code>` for a failed refresh or revoke call, `no access_token in reply` for a reply without a token, and `invalid endpoint <endpoint>` for an unusable endpoint.
- **raised-keychain**: `keychain` is thrown when the Google credential cannot be read or removed, or the OAuth client secret cannot be read.

## Appearance

Not applicable — this is an error enum, not a visual component.

## States

Not applicable — this is an error enum, not a visual component. The type is an immutable value with no runtime state machine.

## Accessibility

Not applicable — this is an error enum, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| integration-error-001 | desc-revoked | `IntegrationError.revoked.errorDescription` (test `MailSyncSettingsTests.errorText`) | `Google access was revoked — sign in again` |
| integration-error-002 | desc-not-configured | `IntegrationError.notConfigured.errorDescription` (test `MailSyncSettingsTests.errorText`) | `Gmail is not configured — import an OAuth client JSON first` |
| integration-error-003 | desc-gmail, gmail-payload | `IntegrationError.gmail(status: 503, message: "Backend Error").errorDescription` (new) | `Gmail returned 503: Backend Error` |
| integration-error-004 | conforms-equatable | `IntegrationError.gmail(status: 403, message: "Insufficient Permission") == IntegrationError.gmail(status: 403, message: "Insufficient Permission")` (the `GmailRESTClientTests` expectations rely on this) | `true` |
| integration-error-005 | conforms-equatable | `IntegrationError.gmail(status: 403, message: "x") == IntegrationError.gmail(status: 404, message: "x")` (new) | `false` |
| integration-error-006 | desc-unknown-account | `IntegrationError.unknownAccount("a@b.com").errorDescription` (new) | `No connected account matches “a@b.com”` |
| integration-error-007 | desc-unknown-message, desc-unknown-label | `unknownMessage("m1")` and `unknownLabel("L1")` descriptions (new) | `No message matches “m1”` and `No label matches “L1”` |
| integration-error-008 | desc-sign-in-failed, desc-sign-in-cancelled | `signInFailed("Google returned no refresh token")` and `signInCancelled` descriptions (`GoogleOAuthTests` throws the former) | `Sign-in failed: Google returned no refresh token` and `Sign-in was cancelled` |
| integration-error-009 | desc-token-refresh, desc-keychain | `tokenRefresh("500 backend_error")` and `keychain("Could not read the Google credential: locked")` descriptions (`GoogleOAuthTests`) | `Token refresh failed: 500 backend_error` and `Keychain error: Could not read the Google credential: locked` |
| integration-error-010 | desc-invalid-settings, raised-invalid-settings | `MailSyncSettings` with `windowDays: 0`, then `validated()` (existing: `MailIntegrationServiceTests.invalidSettingsFail`) | Throws `IntegrationError.invalidSettings`, described as `Invalid sync settings: windowDays must be 1–3650, got 0` |
| integration-error-011 | raised-revoked | A Gmail call fails with `IntegrationError.revoked` during sync (`MailIntegrationServiceTests`) | The connection is saved with status `revoked` |
| integration-error-012 | raised-gmail | A Gmail call fails with `gmail(status: 500, message: "boom")` (`MailIntegrationServiceTests`) | The connection status is `error`, not `revoked` |
| integration-error-013 | desc-verbatim-payload | `invalidSettings("  spaced ")` (new) | `Invalid sync settings:   spaced ` with the payload's whitespace intact |
| integration-error-014 | conforms-localized, desc-invalid-settings, desc-typography | Build one value of each of the eleven cases (`invalidSettings("r")`, `notConfigured`, `unknownAccount("a")`, `unknownMessage("m")`, `unknownLabel("l")`, `revoked`, `gmail(status: 1, message: "g")`, `signInCancelled`, `signInFailed("r")`, `tokenRefresh("r")`, `keychain("r")`) and read each `errorDescription` (new) | Every value is non-nil and equals, in order: `Invalid sync settings: r`, `Gmail is not configured — import an OAuth client JSON first`, `No connected account matches “a”`, `No message matches “m”`, `No label matches “l”`, `Google access was revoked — sign in again`, `Gmail returned 1: g`, `Sign-in was cancelled`, `Sign-in failed: r`, `Token refresh failed: r`, `Keychain error: r` |
## Edge Cases

- **empty-payload**: A payload string MAY be empty, and the description then ends with its prefix and no text (`Sign-in failed: `); the type does not validate payloads.
- **negative-or-zero-status**: `gmail` accepts any `Int` status, including 0 (used for an unbuildable URL or a wrong-size `batchModify` id list) and negative values; the type applies no range check.
- **special-characters**: A payload containing quotes, newlines or non-ASCII text appears in the description unchanged. See #requirements/desc-verbatim-payload.
- **unknown-label-unused**: `unknownLabel` exists and has a description, but nothing in the integrations sources throws it. See #requirements/keep-unknown-label.
- **equality-of-payloads**: Two `gmail` values with the same status and different messages are not equal. See #requirements/conforms-equatable.
- **concurrent-access**: Not applicable: the enum is an immutable `Sendable` value with no shared mutable state, so it can be passed between tasks freely.
- **cancellation**: Task cancellation is not itself an `IntegrationError`; only the sign-in paths convert it to `signInCancelled`, and `MailIntegrationService` ignores `CancellationError` when recording connection status.
- **offline-or-timeout**: Not applicable: the type performs no I/O. It has no timeout or connectivity case; a sign-in timeout is reported as `signInFailed("Sign-in timed out")`.
- **boundary-values**: Not applicable beyond the status integer above: the type constrains no other numeric input. Range checks (1–3650, 1–1440) live in `MailSyncSettings`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Not applicable | — | — | The enum takes no parameters, environment variables, settings keys or injected dependencies; each case is built from its payload alone. |

## Deep Linking

Not applicable: the type is an error enum and handles no URLs of its own (the `gmail` status 0 message mentions a URL only as text).

## Localization

Not applicable as a mechanism: every description is a hardcoded English string in `errorDescription`, with no string table or `String(localized:)` call. The English strings are the contract; a port that localizes them MUST keep the same payload placement.

## Accessibility Options

Not applicable: the type is an error enum with no visual output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag; the enum behaves the same in every build.

## Analytics

Not applicable: the source emits no event.

## Privacy

Not applicable as collection: the type stores nothing and sends nothing. Payloads can carry an account email (`unknownAccount`) or Gmail's reply text (`gmail`), and [MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) stores the description as the connection's `lastError`, so a port SHOULD treat a payload as user data.

## Logging

Not applicable: the source makes no log call; callers decide whether to log or display a description.

## Platform Notes

- **SwiftUI**: Source platform. The file is `packages/apple/AgenticDeveloperHubSDK/Integrations/Model/IntegrationError.swift`, a single `public enum` conforming to `Error`, `Equatable`, `Sendable` and `LocalizedError`. Equality is synthesized. SwiftUI shows the message through `error.localizedDescription`, which reads `errorDescription`.
- **Compose**: Use a Kotlin sealed class (or sealed interface) extending `Exception`, with data classes for the payload cases and objects for `notConfigured`, `revoked` and `signInCancelled`. Data classes give the same value equality. Override `message` with the same sentences; Android string resources are the usual route if localized, which the source does not do.
- **React/Web**: Use a discriminated union keyed by a `kind` field, or an `Error` subclass with a `kind` and payload fields, and a `describe()` function returning the same sentences. Union members compare structurally only with a helper; do not rely on `===`. The type is serializable, which suits crossing a worker or RPC boundary.
- **AppKit / UIKit**: Same Swift type, shared unchanged. Present it with `NSAlert(error:)` or `UIAlertController` using `localizedDescription`; `LocalizedError` supplies the message, and no recovery suggestion or failure reason is defined.
- **WinUI 3**: Model it as an abstract `IntegrationException : Exception` with one sealed subclass per case, or a single class with an `IntegrationErrorKind` enum plus `Status` and `Detail` properties; use C# `record` types to get value equality. Override `Message` with the same sentences, since .NET has no `LocalizedError` equivalent. Keep the type immutable so it is safe across `Task` boundaries, and bind `Message` to a `TextBlock` or a `ContentDialog` for display. Strings can move into a `.resw` resource file through `ResourceLoader`; the source keeps them inline in English.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Mail/Model/IntegrationError.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Use one enum for every integration failure (settings, sign-in, token refresh, Keychain, lookup, Gmail) instead of one error type per layer.
**Rationale**: The doc comment says every case reads as a sentence a person can act on, so any layer's failure can reach the UI and the stored `lastError` through one description path. [MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a).handle relies on this when it turns any thrown error into `.failure(localizedDescription)`.
**Approved**: pending

**Decision**: Keep `revoked` separate from `tokenRefresh` and `signInFailed`.
**Rationale**: `MailIntegrationService` compares against `.revoked` to mark a connection `revoked` (the user must sign in again) and marks every other failure `error`. Folding it into a string case would break that comparison.
**Approved**: pending

**Decision**: Carry Gmail failures as `gmail(status:message:)`, with status 0 for a failure before any response (an unbuildable URL or a wrong-size `batchModify` id list).
**Rationale**: Callers pattern-match on status 400 and 404 to treat a missing item as gone, so the number has to stay machine-readable instead of being folded into the message.
**Approved**: pending

**Decision**: Hardcode the English descriptions in the enum.
**Rationale**: The source has no string table. Whether to localize is an owner decision, so this ingredient records the current behavior as the contract.
**Approved**: pending

**Decision**: Keep `unknownLabel` although no other integrations file throws it.
**Rationale**: It is part of the declared public case set and has a defined description. Removing it would change the public surface, so #requirements/keep-unknown-label requires keeping it; whether to remove it is for the owner.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The enum names failures and words them, with no I/O, storage or presentation, so separation of concerns passes. Tests assert descriptions directly only for `revoked` and `notConfigured` (`MailSyncSettingsTests.errorText`) and, through the stored `lastError`, for `revoked` and `gmail(status: 500, message: "boom")` (`MailIntegrationServiceTests`); the other descriptions are exercised only through the code that throws them, so unit test coverage is partial. Explicit error handling passes because each failure has its own case with a described reason. No-hardcoded-strings fails because every sentence is an inline English literal with no externalization.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
