---
id: 8a51a893-a170-4cfc-a620-37939ae6b27b
title: "Privacy Word Store"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Device-only keychain store for privacy-word pairs, plus the owner-authentication helper callers use first."
platforms:
  - swift
  - macos
  - ios
tags:
  - foundation
  - privacy
  - keychain
depends-on:
  - 998864ec-d852-4e92-aa2c-3177130ff21d
related:
  - d54db476-c847-4ac0-827e-eae336109f38
references: []
approved-by: ""
approved-date: ""
---

# Privacy Word Store

## Overview

`PrivacyWordStore` keeps the privacy words, a list of `TextSubstitutionFilter.Pair` values (an `alias` the user writes and reads, a `real` word the program is given), in the keychain and nowhere else: no defaults, no database, no file. The list is one generic-password item whose value is the pairs as JSON. The item is readable without a prompt by the apps in its access group while the Mac is unlocked, because a private terminal needs the words from its first byte; what asks for the owner's proof is the app, through `authenticate(reason:)`, before it shows a private terminal, opens the words or saves them. The item never leaves the Mac it was typed on. Because the keychain calls are synchronous and run on the calling thread, a caller that cares about latency calls them off its main thread. The store is a small value type with `load`, `save` and one static authentication helper; the caller supplies the keychain access group.

## Behavioral Requirements

- **value-type**: The store MUST be a `Sendable` value type configured by `accessGroup` (optional), `service` and `account`, all readable as `let` properties.
- **default-identity**: `service` MUST default to `com.agenticdevelopmentstudio.privacy-words` and `account` to `privacy-words`.
- **access-group-injected**: The access group MUST come from the caller; the store MUST NOT choose one, and when `accessGroup` is nil it MUST omit the access-group attribute from every query.
- **single-item**: All pairs MUST live in one generic-password keychain item identified by service and account, its value being the pairs encoded as a JSON array.
- **keychain-only**: The store MUST NOT write the words to user defaults, a database or a file.
- **data-protection-keychain**: Every query MUST use the data-protection keychain, so the binary needs a `keychain-access-groups` entitlement whether or not an access group is given.
- **never-synchronizable**: Every query MUST set synchronizable to false, so the item never syncs to another device.
- **accessibility**: A saved item MUST be created with accessibility `WhenUnlockedThisDeviceOnly`, so it is readable only while the Mac is unlocked and never moves to another device or backup restore.
- **item-label**: A saved item MUST carry the label `Privacy words`.
- **load-empty-when-absent**: `load` MUST return an empty array when the keychain reports the item not found.
- **load-silent**: `load` called without a context MUST NOT prompt: it MUST run with a fresh `LAContext` whose `interactionNotAllowed` is true.
- **load-with-context**: `load(context:)` MUST pass a supplied authenticated context to the keychain read instead of the silent one.
- **needs-authentication**: `load` MUST throw `StoreError.needsAuthentication` when the keychain answers `errSecInteractionNotAllowed` or `errSecAuthFailed`; this is how an item saved under the older `userPresence` guard is reported.
- **keychain-error**: `load` MUST throw `StoreError.keychain(status)` for any other non-success status.
- **unreadable**: `load` MUST throw `StoreError.unreadable` when the keychain returns success but the value is not `Data` or does not decode as an array of pairs.
- **save-replaces**: `save` MUST replace the whole stored list by deleting the existing item and then adding a new one.
- **save-empty-removes**: `save` with an empty array MUST leave no item stored, and MUST NOT add one.
- **delete-tolerates-missing**: `save` MUST treat a delete status of success or item-not-found as proceeding, and MUST throw `StoreError.keychain(status)` for any other delete status without adding anything.
- **add-error**: `save` MUST throw `StoreError.keychain(status)` when adding the new item fails.
- **encode-errors-propagate**: An error thrown by `JSONEncoder` while encoding the pairs MUST propagate unchanged from `save`, after the old item has already been deleted.
- **authenticate**: `authenticate(reason:)` MUST be an async static function that evaluates the `deviceOwnerAuthentication` policy (Touch ID or the account password) with `reason` as the prompt text and return the `LAContext` that proved it.
- **authenticate-cannot-evaluate**: `authenticate` MUST throw `StoreError.authenticationFailed` carrying the system's localized description, or `This Mac cannot authenticate its owner.` when none is given, when the policy cannot be evaluated.
- **authenticate-rejected**: `authenticate` MUST throw `StoreError.authenticationFailed` carrying the system's localized description, or `Authentication failed.` when none is given, when the user fails or cancels the evaluation.
- **error-descriptions**: `StoreError` MUST conform to `Error`, `LocalizedError` and `Equatable`; `errorDescription` MUST return the reason for `authenticationFailed`, the sentence `The privacy words need you to authenticate once before they can be read.` for `needsAuthentication`, the system message for the status (or `Keychain error <status>.`) for `keychain`, and `The privacy words in the keychain could not be read.` for `unreadable`.
- **no-in-process-gate**: The store itself MUST NOT require authentication for `load` or `save`; showing, opening and saving the words are guarded by the caller taking `authenticate(reason:)` first. `PrivacyWordsVault` is the caller that does this.
- **blocking-calls**: `load` and `save` MUST be synchronous and MUST NOT dispatch to another queue or actor; they run on the calling thread.
- **no-retry**: The store MUST NOT retry a failed keychain call.

## Appearance

Not applicable — this is a keychain-backed store, not a visual component.

## States

Not applicable — this is a keychain-backed store, not a visual component. The persisted state is either no item or one item, described under Behavioral Requirements.

## Accessibility

Not applicable — this is a keychain-backed store, not a visual component. The system's authentication sheet is presented by LocalAuthentication, not by this type.

## Conformance Test Vectors

The source has no test beside it that calls the store; the one test that mentions it, `TerminalPaneFamilyTests`, only constructs a `PrivacyWordsVault` around it. The vectors below are derived from the source and assume a keychain with the target entitlement.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| privacy-word-store-001 | load-empty-when-absent | New service and account with nothing saved; `load()`. | `[]`. |
| privacy-word-store-002 | save-replaces, single-item | `save([Pair(alias: "Acme", real: "Globex")])`, then `load()`. | An array equal to the one saved. |
| privacy-word-store-003 | save-replaces | `save` two pairs, then `save` one different pair, then `load()`. | Only the last pair. |
| privacy-word-store-004 | save-empty-removes | `save` one pair, then `save([])`, then `load()`. | `[]`; no item remains. |
| privacy-word-store-005 | save-empty-removes, delete-tolerates-missing | On an empty keychain, `save([])`. | Returns without error. |
| privacy-word-store-006 | unreadable | The item's data is bytes that are not a JSON array of pairs; `load()`. | Throws `StoreError.unreadable`. |
| privacy-word-store-007 | needs-authentication | Setup: write the item directly with `SecItemAdd` using an access control from `SecAccessControlCreateWithFlags(.userPresence)`. Then `load()` with no context. | Throws `StoreError.needsAuthentication`, no prompt shown. |
| privacy-word-store-008 | load-with-context | The same item; `load(context:)` with a context from `authenticate`. | The stored pairs. |
| privacy-word-store-009 | save-replaces | After vector 008, `save` the pairs, then `load()` with no context. | The pairs, with no error. |
| privacy-word-store-010 | keychain-error | Run without a `keychain-access-groups` entitlement or with an access group the app is not signed for; `save` one pair. | Throws `StoreError.keychain` carrying the failing status: the delete status when the delete already fails, otherwise the add status. |
| privacy-word-store-011 | authenticate-cannot-evaluate | A Mac with no usable owner authentication; `authenticate(reason:)`. | Throws `StoreError.authenticationFailed` with a non-empty message. |
| privacy-word-store-012 | error-descriptions | `StoreError.unreadable.errorDescription`. | `The privacy words in the keychain could not be read.` |
| privacy-word-store-013 | default-identity | `PrivacyWordStore(accessGroup: nil)`. | `service` is `com.agenticdevelopmentstudio.privacy-words`, `account` is `privacy-words`. |
| privacy-word-store-014 | access-group-injected | Two stores that differ only in `accessGroup`. | `load()` on the store with the second `accessGroup` returns `[]` after `save` on the first store (setup: save via store A, load via store B). |
| privacy-word-store-015 | authenticate-rejected | A Mac with owner authentication; `authenticate(reason:)` and the user cancels the system sheet. | Throws `StoreError.authenticationFailed` with the system's message, or `Authentication failed.` when none is given. |
## Edge Cases

- **Null / empty input**: Nothing saved loads as an empty list (MUST); saving an empty list removes the item (MUST). A nil access group omits the attribute and the keychain uses the app's default group (MUST).
- **Boundary values**: Pairs are stored as given; the store does not trim, deduplicate, order or limit them, and a pair with an empty alias or real is stored like any other.
- **Concurrent access**: The type is a `Sendable` value with no lock or queue. Two `save` calls interleaving can each delete and then add, in which case the add of the second can find the item already added by the first and surface `StoreError.keychain` with the duplicate-item status; the keychain, not this type, serialises each call, and callers should serialise saves (SHOULD). `PrivacyWordsVault` is the caller that owns that ordering.
- **Error states**: Every failure is thrown, never swallowed: locked or interaction-denied reads become `needsAuthentication`, other keychain statuses become `keychain`, bad data becomes `unreadable`, authentication refusals become `authenticationFailed` (MUST).
- **Save is not atomic**: `save` deletes the old item before adding the new one, so when the add or the JSON encoding then fails the old words are already gone and the error is thrown; this is a fact of the implementation (MUST describe), not a rollback.
- **Locked Mac**: Because the item is `WhenUnlockedThisDeviceOnly`, a read while the Mac is locked is a keychain read that `load` maps by status: `errSecInteractionNotAllowed` and `errSecAuthFailed` throw `needsAuthentication`, and any other failing status throws `keychain` with that status.
- **Authentication cancelled**: A cancel in the system sheet throws `authenticationFailed` with the system's message (MUST); there is no separate cancelled case.
- **Offline / disconnected state**: Not applicable: the store performs no network access and the item is never synchronizable.
- **Timeouts**: Not applicable: calls are local keychain operations with no timeout of their own; `authenticate` waits as long as the user takes.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `accessGroup` | `String?` | none (required argument) | The keychain access group, chosen by the app's entitlements; nil omits the attribute. |
| `service` | `String` | `com.agenticdevelopmentstudio.privacy-words` | The keychain service attribute. |
| `account` | `String` | `privacy-words` | The keychain account attribute. |
| `reason` | `String` | none | Parameter of `authenticate`, shown in the system authentication prompt. |
| `context` | `LAContext?` | nil | Parameter of `load`; an authenticated context from `authenticate` for reading an item saved under the older guard. |
## Deep Linking

Not applicable: the store defines no URL scheme, route or navigation destination.

## Localization

The store carries hardcoded English strings with no localization lookup: the `errorDescription` sentences for `needsAuthentication` and `unreadable`, the fallback messages `This Mac cannot authenticate its owner.`, `Authentication failed.` and `Keychain error <status>.`, and the item label `Privacy words`. Messages for `authenticationFailed` and `keychain` otherwise come from the system and follow the system language. The prompt text is the caller's `reason`.

## Accessibility Options

Not applicable: the store presents no UI and responds to no accessibility display option.

## Feature Flags

Not applicable: the store contains no feature-flag reference.

## Analytics

Not applicable: the store contains no analytics call.

## Privacy

- **Data collected**: The alias and real word pairs the user typed; the real words name the user, which is why they are guarded.
- **Storage**: One keychain generic-password item, JSON-encoded, in the data-protection keychain, accessible only while unlocked, this device only, never synchronizable, shareable only with the apps in the given access group. No defaults, database or file copy. The item has no expiry; it lives until `save([])` or the user removes it.
- **Transmission**: None; the store performs no network access and the item is excluded from keychain sync.
- **Retention**: Until replaced by `save` or removed with an empty `save`.
- **Sensitive-data handling**: The item is readable by the group's apps without a prompt (deliberate, so a private terminal can conceal output from its first byte); the owner is asked by the app, not the store, before showing, opening or saving. A violation (a refused or failed authentication, or an unreadable value) is reported as a thrown `StoreError`, never partial data.
- **Token lifetime and revocation**: Not applicable: the store handles no token or session; an authenticated `LAContext` is the caller's to keep or discard.

## Logging

Not applicable: the store calls no logging API; failures are thrown, and the words are never written to a log.

## Platform Notes

- **SwiftUI**: A SwiftUI host calls `authenticate` from a task before presenting the words, and calls `load` and `save` off the main actor. `authenticate` is `async`, so it fits `.task` directly.
- **Compose**: Use the Android Keystore with `EncryptedSharedPreferences` or an encrypted file for the single JSON value, requiring the unlocked device and excluding it from backup; `BiometricPrompt` with `DEVICE_CREDENTIAL` allowed replaces `authenticate`. Map the four error cases to a sealed class.
- **React/Web**: No keychain exists; a web port keeps the words on the server behind the account, or in an encrypted store keyed by a user secret, with `WebAuthn` or a password re-entry as the authenticate step. Errors map to a discriminated union.
- **AppKit / UIKit**: On macOS the binary must carry a `keychain-access-groups` entitlement, because the store always uses the data-protection keychain. On iOS the same Security and LocalAuthentication calls apply; call `authenticate` before presenting the words view controller. Source is `Core/Privacy/PrivacyWordStore.swift`, a public `Sendable` struct importing `Foundation`, `LocalAuthentication` and `Security`; `authenticate` bridges `evaluatePolicy` through `withCheckedThrowingContinuation`.
- **WinUI 3**: Store the JSON in `Windows.Security.Credentials.PasswordVault` (resource as the service, user name as the account), or encrypt it with `System.Security.Cryptography.ProtectedData` using `DataProtectionScope.CurrentUser` and keep it in `Windows.Storage.ApplicationData.Current.LocalSettings` or `LocalFolder` (never roaming, to match device-only). Use `Windows.Security.Credentials.UI.UserConsentVerifier.RequestVerificationAsync(reason)` for `authenticate` and map its non-verified results to `authenticationFailed`. Serialise with `System.Text.Json`. Model `StoreError` as an exception hierarchy or a result type. PasswordVault has no unlocked-only attribute, so the unlocked-only guarantee falls to the user session; there is no keychain access group, so sharing between apps needs a shared package family or a broker.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Privacy/PrivacyWordStore.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The item is readable without a prompt by apps in its access group while the Mac is unlocked.
**Rationale**: The source doc comment explains a private terminal needs the words from its first byte, because they conceal its output, so starting one must not ask. The prompt moves to the app, which authenticates before showing a private terminal, opening the words and saving them.
**Approved**: pending

**Decision**: The item is `WhenUnlockedThisDeviceOnly` and never synchronizable.
**Rationale**: The source says the words name the user and stay on the Mac they were typed on.
**Approved**: pending

**Decision**: The access group is a constructor argument, not a constant.
**Rationale**: Which group applies belongs to the app's entitlements; the source cites its `dependency-injection` rule. The data-protection keychain is always used, so the entitlement is needed either way.
**Approved**: pending

**Decision**: `save` is delete then add, and an empty list means delete only.
**Rationale**: One path rewrites any older guarded item without that guard and removes the item when the list is empty. The cost is that a failure after the delete leaves no item; the failure is thrown.
**Approved**: pending

**Decision**: The store reports an item still guarded by `userPresence` as `needsAuthentication` instead of prompting.
**Rationale**: The silent context makes `load` non-interactive, so migration of older items is explicit: authenticate, `load(context:)`, then `save`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | security |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | privacy-and-data |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

Separation of concerns passes: the store holds persistence and the owner-proof helper, while the vault, the filter and the UI live elsewhere. Unit-test coverage is partial: `PrivacyWordStoreConformanceTests.swift` covers V12 and V13 (error descriptions, default identity) and skips V1-V11, V14 and V15 because they need a real entitled keychain, a userPresence item or a real owner-authentication prompt. Secure storage and secure data storage pass because the words sit in one device-only, unlocked-only, non-synchronizable keychain item with no other copy. No PII in logs passes because the store calls no logging API. No hardcoded strings fails because the error sentences and the item label are English literals.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PrivacyWordStoreConformanceTests.swift, 2 of 15 vectors tested, 13 skipped: need a real entitled keychain or owner authentication); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Restated blocking-calls and no-retry as checkable, folded save-rewrites-unguarded into vector 009, fixed vectors 007, 009 and 014 and added 015, named the locked-read status mapping, moved the entitlement row and file details into platform notes, added ios, depends-on and related, and shortened the summary. |
