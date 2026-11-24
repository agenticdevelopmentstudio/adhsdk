---
id: d54db476-c847-4ac0-827e-eae336109f38
title: "Privacy Words Vault"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The in-memory, app-wide holder of the privacy words: silent loading, owner authentication before seeing or saving, and cross-app change announcements."
platforms:
  - swift
  - macos
tags:
  - foundation
  - privacy
  - keychain
depends-on:
  - 8a51a893-a170-4cfc-a620-37939ae6b27b
  - 998864ec-d852-4e92-aa2c-3177130ff21d
related: []
references: []
approved-by: ""
approved-date: ""
---

# Privacy Words Vault

## Overview

`PrivacyWordsVault` holds the privacy words while the app runs: read from the keychain through a `PrivacyWordStore` when a private terminal first needs them, kept in memory as a `TextSubstitutionFilter`, and nowhere else. One vault serves the whole app, so an edit applies to every private terminal at once. Reading the words to run a terminal never prompts; seeing them does, so showing a terminal, opening the editor and saving each go through `authenticate(reason:)`. Every app that shares the keychain item keeps its own vault, so a save announces itself with a distributed notification and every other vault that already holds the words reads them again. It is a `@MainActor` `ObservableObject` publishing the current filter.

## Behavioral Requirements

- **main-actor**: The vault MUST be a `@MainActor` final class conforming to `ObservableObject`; all of its operations run on the main actor.
- **store-injected**: The vault MUST be created with a `PrivacyWordStore`, exposed as the read-only property `store`.
- **filter-published**: `filter` MUST be a published, publicly read-only `TextSubstitutionFilter?` that is nil until the words have been read.
- **is-loaded**: `isLoaded` MUST be true exactly when `filter` is non-nil.
- **load-silent**: `load()` MUST return true without touching the store when the words are already in memory.
- **load-reads-store**: When the words are not in memory, `load()` MUST read them with `store.load()`, build a filter from the pairs (which drops any pair with an empty alias or real), publish it and return true.
- **load-needs-auth**: `load()` MUST return false and leave `filter` nil when the store throws `needsAuthentication`; this is the case only for words still saved under the old `userPresence` guard.
- **load-other-errors**: `load()` MUST propagate any other store error (`keychain`, `unreadable`) unchanged.
- **load-empty**: `load()` on a keychain with no item MUST succeed and publish a filter with no pairs, so `isLoaded` is true.
- **authenticate-prompts-every-time**: `authenticate(reason:)` MUST prompt for owner authentication on every call and MUST NOT remember a success.
- **authenticate-errors**: `authenticate(reason:)` MUST propagate the `authenticationFailed` error from `PrivacyWordStore.authenticate(reason:)` and MUST NOT change `filter` when it fails.
- **authenticate-rereads**: After a successful authentication, `authenticate` MUST read the words from the store again even when they are already in memory, and replace `filter` with them, because another app may have saved since.
- **authenticate-upgrades**: When that read throws `needsAuthentication`, `authenticate` MUST read again with the authenticated context, save those pairs back so the item is rewritten without the old guard, and set `filter` to them.
- **load-upgrading**: `loadUpgradingIfNeeded()` MUST return silently when `load()` returns true; only when `load()` returns false MUST it call `authenticate` with the reason `upgrade how the privacy words are stored. This is asked once`; any error `load()` throws (`keychain`, `unreadable`) MUST propagate without prompting.
- **upgrade-shared**: While an upgrade is in progress, further calls to `loadUpgradingIfNeeded()` MUST await that same upgrade rather than starting a second prompt, so private terminals starting together share one prompt.
- **authenticate-store-error**: When the re-read or the upgrade read or write inside `authenticate` throws a store error, `authenticate` MUST propagate that error and MUST NOT change `filter`.
- **upgrade-cleared**: The in-progress upgrade MUST be cleared when the call that started it finishes, whether it succeeded or threw.
- **save-authenticates**: `save(_:reason:)` MUST call `authenticate(reason:)` first and MUST NOT write to the store when authentication throws.
- **save-normalises**: `save` MUST build a `TextSubstitutionFilter` from the given pairs and persist its `pairs`, so pairs with an empty alias or real are dropped before storing.
- **save-applies**: After a successful write, `save` MUST set `filter` to the new filter.
- **save-store-error**: `save` MUST propagate a store error from the write and MUST NOT change `filter` to the new words when the write throws.
- **persist-announces**: A successful store write MUST post a distributed notification with delivery immediately, named by `changedNotification(for:)`, with the process identifier as its string object and no user info.
- **notification-name**: `changedNotification(for:)` MUST return the name `<service>.<account>.changed` built from the store's `service` and `account`, so vaults sharing an item share a name.
- **notification-no-words**: The notification MUST NOT carry any alias or real word.
- **observe-changes**: The vault MUST observe that notification for its store on the main queue from creation until deallocation, and MUST remove the observer on deinit.
- **ignore-own-posts**: A notification whose object equals this process's identifier string MUST be ignored, so a vault does not reload from its own save.
- **reload-if-loaded**: On another process's notification, the vault MUST read the words again and replace `filter` only when it is already loaded; a vault that never loaded MUST do nothing.
- **reload-failure-ignored**: NEEDS REVIEW: Not implemented in source. When the reload read throws (a locked Mac, an unreadable value, an item back under authentication), the vault discards the error with `try?` and keeps the old filter with no log, state or callback, so the app keeps concealing with words another app has already replaced. Evidence that would settle it: the pending Design Decision on reload failure.
- **plain-memory**: The vault MUST hold the words only in memory and in the keychain through the store; it MUST NOT write them elsewhere.
- **concurrency**: Synchronous steps (`load`, the write inside `save`, a reload) MUST NOT interleave with each other; steps separated by `await` (the authentication in `authenticate`, `save` and the upgrade) MAY interleave with other main-actor calls, and two overlapping `save` calls MUST apply in the order their writes run, the later write winning.
- **no-timeout-no-retry**: The vault MUST NOT retry a failed store call or time out an authentication.

## Appearance

Not applicable — this is an in-memory model object, not a visual component.

## States

Not applicable — this is an in-memory model object, not a visual component. Its runtime states are described under Behavioral Requirements: not loaded (`filter` nil), loaded (`filter` set), and an upgrade in progress.

## Accessibility

Not applicable — this is an in-memory model object, not a visual component.

## Conformance Test Vectors

The source has no test of its own; `TerminalPaneFamilyTests` only constructs a vault (with a test service name) to build a pane family. The vectors below are derived from the source and need an injectable or test keychain item.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| privacy-words-vault-001 | filter-published, is-loaded | A new vault. | `filter` is nil and `isLoaded` is false (test: TerminalPaneFamilyTests builds a vault and only reads allowances). |
| privacy-words-vault-002 | load-empty | A new vault over an empty keychain; `load()`. | Returns true, `filter` has no pairs, `isLoaded` is true. |
| privacy-words-vault-003 | load-reads-store | The item holds pairs `a`/`b` and an empty-alias pair; `load()`. | Returns true and `filter.pairs` is only `a`/`b`. |
| privacy-words-vault-004 | load-silent | After vector 003, change the keychain item and call `load()` again. | Returns true and `filter` is unchanged from the first read. |
| privacy-words-vault-005 | load-needs-auth | The item is guarded by the old `userPresence` access control; `load()`. | Returns false, `filter` stays nil. |
| privacy-words-vault-006 | load-other-errors | The stored value is not valid JSON pairs; `load()`. | Throws `StoreError.unreadable`. |
| privacy-words-vault-007 | authenticate-upgrades | The old-guarded item; `authenticate(reason:)` and the owner succeeds. | `filter` holds the pairs, and a later silent `store.load()` succeeds without error. |
| privacy-words-vault-008 | authenticate-errors | The owner cancels the prompt; `authenticate(reason:)`. | Throws `authenticationFailed`; `filter` is unchanged. |
| privacy-words-vault-009 | authenticate-rereads | Loaded vault; another process rewrites the item; `authenticate` succeeds. | `filter` shows the new pairs. |
| privacy-words-vault-010 | upgrade-shared | The old-guarded item; start `loadUpgradingIfNeeded()` twice together. | One authentication prompt is shown and both calls complete. |
| privacy-words-vault-011 | save-authenticates | `save(pairs, reason:)` when authentication throws. | The error propagates and the store is not written. |
| privacy-words-vault-012 | save-applies, persist-announces | `save([Pair(alias: "a", real: "b")], reason:)` with success. | `filter.pairs` equals the pair and a notification named `<service>.<account>.changed` is posted with the process identifier as its object. |
| privacy-words-vault-013 | ignore-own-posts | A vault whose own save posts the notification. | With a subscriber on `$filter`, after the save and one pass of the main run loop there is exactly one emission after the save, so the vault did not reload from its own post. |
| privacy-words-vault-014 | reload-if-loaded | Two vaults on one item, both loaded; one saves. | The other's `filter` becomes the saved pairs. |
| privacy-words-vault-015 | reload-if-loaded | A vault that never loaded receives another process's notification. | `filter` stays nil and the store is not read. |
| privacy-words-vault-016 | notification-name | `changedNotification(for:)` with service `s` and account `a`. | `s.a.changed`. |
| privacy-words-vault-017 | save-normalises | `save([Pair(alias: "a", real: "b"), Pair(alias: "", real: "c")], reason:)` with success; then `store.load()`. | `filter.pairs` and the stored pairs are only `a`/`b`. |
| privacy-words-vault-018 | upgrade-cleared | The old-guarded item; `loadUpgradingIfNeeded()` with the owner cancelling, then again with the owner succeeding. | The first call throws `authenticationFailed`; the second prompts again and completes. |
| privacy-words-vault-019 | save-store-error | `save(pairs, reason:)` with authentication succeeding and the store write throwing (an access group the app is not signed for). | The store error propagates and `filter` is unchanged. |
| privacy-words-vault-020 | load-upgrading | A loaded vault, or an item with no guard; `loadUpgradingIfNeeded()`. | Returns with no prompt and `isLoaded` is true. |
| privacy-words-vault-021 | notification-no-words | Observe the distributed notification during `save` of pair `a`/`b`. | The notification has no user info and its object is only the process identifier string, with neither `a` nor `b`. |
| privacy-words-vault-022 | authenticate-store-error | A loaded vault; authentication succeeds and the re-read throws `keychain`. | The error propagates and `filter` keeps the earlier pairs. |
## Edge Cases

- **Null / empty input**: Empty pairs saved leave the loaded filter with no pairs and the store removes the keychain item (see `PrivacyWordStore`'s `save-empty-removes`). Pairs with an empty side are dropped on load and on save (MUST).
- **Boundary values**: There is no limit on the number of pairs; whatever `TextSubstitutionFilter` accepts is kept.
- **Concurrent access**: `@MainActor` isolation serialises synchronous steps; calls overlapping across an `await` can interleave. Many simultaneous `loadUpgradingIfNeeded` calls share one prompt (MUST). Two overlapping `save` calls each authenticate separately and the later write wins (see the concurrency requirement).
- **Error states**: `load` and `loadUpgradingIfNeeded` throw store errors; `authenticate` and `save` throw authentication and store errors; the failed `save` leaves the previous in-memory filter in place. The reload after another app's save drops its error silently (see the pending Design Decision on reload failure).
- **Cross-process staleness**: A vault that has not loaded does not follow other apps' saves; its first `load` then reads the current item (MUST).
- **Notification from the same process**: A second vault in this same process, with the same store, ignores the post because the object is the shared process identifier; it keeps its old words until `authenticate` re-reads .
- **Upgrade failure**: When the upgrade prompt is refused, the error propagates to every awaiting caller and the pending upgrade is cleared so a later call prompts again (MUST).
- **Offline / disconnected state**: Not applicable: the vault performs no network access; announcements travel between processes on this Mac only.
- **Cancellation**: Not applicable: the vault has no cancel call; a cancelled `Task` is not checked by the vault itself, and a refused prompt surfaces as `authenticationFailed`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `store` | `PrivacyWordStore` | none (required) | Injected keychain store; its `service` and `account` also name the change notification. |
| Upgrade reason | `String` | `upgrade how the privacy words are stored. This is asked once` | Fixed prompt text used by `loadUpgradingIfNeeded`. |

The distributed notification center and the process identifier are not injectable: the vault always uses `DistributedNotificationCenter.default()` and the identifier of the running process. The vectors that involve another app (009, 014, 015) are exercised with two processes, or by posting the change notification from the test with a different string object.
## Deep Linking

Not applicable: the vault defines no URL scheme, route or navigation destination.

## Localization

The vault carries one hardcoded English string with no localization lookup: the upgrade prompt reason `upgrade how the privacy words are stored. This is asked once`. All other prompt reasons come from the caller, and error text comes from `PrivacyWordStore.StoreError`.

## Accessibility Options

Not applicable: the vault presents no UI and responds to no accessibility display option.

## Feature Flags

Not applicable: the vault contains no feature-flag reference.

## Analytics

Not applicable: the vault contains no analytics call.

## Privacy

- **Data collected**: The user's privacy words (alias and real pairs), held in memory as a `TextSubstitutionFilter`.
- **Storage**: In memory only for the vault's lifetime; the persistent copy is the device-only keychain item owned by `PrivacyWordStore`.
- **Transmission**: The words never leave the process except into the keychain. The distributed notification between apps on the Mac names the store and carries the process identifier only; it carries no words (MUST).
- **Retention**: Until the vault is deallocated; the keychain item persists until saved empty.
- **Authentication**: Every `authenticate` call proves the owner anew, so no success is cached; this is what stands between the words and someone else at the keyboard.
- **Violation handling**: A failed or cancelled authentication throws and changes nothing; a failed reload is dropped silently (see the open question on `reload-failure-ignored`).

## Logging

Not applicable: the vault calls no logging API; the words are never written to a log.

## Platform Notes

- **SwiftUI**: Source is `Core/Privacy/PrivacyWordsVault.swift`, importing `Combine` and `Foundation`. It is a `@MainActor` `ObservableObject` with a `@Published` filter, usable from SwiftUI with `@StateObject` or `@ObservedObject`. `changeObserver` is `nonisolated(unsafe)` so `deinit` can remove it. The store and filter types are in `Core/Privacy/PrivacyWordStore.swift` and `Core/TextSubstitutionFilter.swift`.
- **Compose**: A `ViewModel` exposing a `StateFlow` of the filter, with suspend functions for `authenticate`, `save` and `loadUpgradingIfNeeded`, mutated on the main dispatcher; a `Mutex` or a shared `Deferred` replaces the shared upgrade task. Cross-app announcements need an Android `BroadcastReceiver` (package-scoped) or a `ContentObserver`.
- **React/Web**: A store (for example a `useSyncExternalStore` source) holding the filter; use a shared promise for the one-prompt upgrade. Cross-tab announcements use `BroadcastChannel` with a per-tab identifier in place of the process id; the web has no keychain, so the backing store is the server.
- **AppKit / UIKit**: The same file serves both; the macOS private terminal and the privacy words editor take the vault by injection. `DistributedNotificationCenter` is macOS only; an iOS port has no cross-app notification for the same items and would reload on foreground.
- **WinUI 3**: A class implementing `INotifyPropertyChanged` raising for `Filter`, marshalled with `DispatcherQueue.TryEnqueue`; `async Task` methods for `AuthenticateAsync`, `SaveAsync` and `LoadUpgradingIfNeededAsync`, with a stored `Task` field for the shared upgrade (cleared in `finally`) and `SemaphoreSlim` if overlapping saves must be ordered. For cross-app announcements use a named `EventWaitHandle`, a `Windows.ApplicationModel.AppService`, or a `FileSystemWatcher` on a shared file; there is no distributed notification equivalent, so the process id tag becomes an instance or process id carried in the signal. Owner proof comes from `UserConsentVerifier`, as in the store.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Privacy/PrivacyWordsVault.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Reading the words to run a terminal never prompts, while seeing them does.
**Rationale**: The source says a private terminal must conceal from its first byte, so starting one must not ask; what stands between the words and someone else at the keyboard is the authentication on showing, opening and saving.
**Approved**: pending

**Decision**: Authentication success is never remembered; every `authenticate` call prompts and re-reads.
**Rationale**: The source says this is the barrier against another person at the keyboard; re-reading also protects an editor opened here from writing back a list that predates another app's save.
**Approved**: pending

**Decision**: Words still saved under the old `userPresence` guard are upgraded by one prompt, shared by terminals starting together.
**Rationale**: Reading and saving again without the guard means no later start asks; the shared upgrade task stops several terminals stacking prompts, and the prompt text says it is asked once.
**Approved**: pending

**Decision**: Each app keeps its own vault and announces saves with a distributed notification naming no words.
**Rationale**: The source says an edit in one app conceals in all of them; the notification leaks nothing, and a vault that never loaded has nothing to refresh, so only loaded vaults re-read.
**Approved**: pending

**Decision**: A vault ignores notifications carrying its own process identifier.
**Rationale**: Its own save already set the filter; the tag also means a second vault in the same process does not refresh from it.
**Approved**: pending

**Decision**: What a vault does when the reload after another app's save fails: keep the stale filter (today, silently), drop the filter, publish an error, or log it.
**Rationale**: The source discards the error with `try?` and keeps concealing with the old words, which another app has already replaced; which behavior is right is not settled, so the requirement stays marked until it is.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

Separation of concerns passes: the vault holds the in-memory words, the authentication policy and the cross-app announcement, while keychain access sits in `PrivacyWordStore` and matching in `TextSubstitutionFilter`. Unit-test coverage is partial: `PrivacyWordsVaultConformanceTests.swift` covers V1, V15 and V16 and skips the other 19 vectors because they need a real entitled keychain, a userPresence item or a real owner-authentication prompt, and the vault has no seam to inject either. Explicit error handling is partial because every operation throws its errors except the reload after another app's save, which discards its error. Secure storage passes because the vault keeps the words in memory and the store's device-only keychain item, and the announcement carries no words. No PII in logs passes because the vault calls no logging API. No hardcoded strings fails because the upgrade prompt is an English literal.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PrivacyWordsVaultConformanceTests.swift, 3 of 22 vectors tested, 19 skipped: need a real entitled keychain or owner authentication); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added authenticate-store-error and a pending reload-failure Design Decision, reworded concurrency and load-upgrading, stated which inputs are not injectable, added six vectors and an observable vector 013, depends-on the store and filter specs, and fixed Compliance categories. |
