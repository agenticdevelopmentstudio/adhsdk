---
id: 9cf9784d-48c9-4b29-b553-c72ffdfce7b9
title: "Account"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Account protocol, AccountState, AccountUser and AccountPresentationAnchor: the Foundation-only contract an accounts UI renders from and drives."
platforms:
  - swift
  - macos
  - ios
tags:
  - auth
  - accounts
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Account

## Overview

`Account` is the contract for one sign-in-able account an app knows about. An accounts panel renders from the protocol's properties and calls its verbs. How an account actually signs in is the conformer's business, which is why login is "present your sign-in UI" and not a credentials method. The file also defines the value types the protocol speaks in: `AccountUser` (who is signed in), `AccountState` (where the account stands) and `AccountPresentationAnchor` (what a platform hands an account so it can present its own sign-in UI). The tier is Foundation-only: it imports neither AppKit nor UIKit.

## Behavioral Requirements

- **account-protocol-main-actor**: `Account` MUST be a class-bound protocol (`AnyObject`) isolated to `@MainActor`, so every property read and verb call happens on the main actor.
- **account-id**: An `Account` MUST expose a `String` `id`.
- **account-display-name**: An `Account` MUST expose a `String` `displayName`, the account's title.
- **account-summary**: An `Account` MUST expose a `String` `summary`, one line shown under the title while the account is signed out.
- **account-state**: An `Account` MUST expose its current `AccountState` through `state`.
- **account-message**: An `Account` MUST expose `message` as an optional `String`: an error or status line, `nil` when there is none.
- **account-signup-url**: An `Account` MUST expose `signupURL` as an optional `URL`; `nil` means the account has no web sign-up and Signup is hidden.
- **account-on-change-fires**: An `Account` MUST call `onChange` after any change to `state` or `message`.
- **account-on-change-single-slot**: `onChange` is a single settable slot of type `@MainActor () -> Void`; assigning it again MUST replace the earlier observer. The accounts UI that shows the account is its one observer.
- **account-restore-purpose**: `restore()` MUST start finding out whether a stored login is still good and MUST leave `.restoring` when done.
- **account-restore-lazy**: The accounts UI calls `restore()` when it first shows the account, so the check (a Keychain read, a network call) is paid only when someone looks.
- **account-restore-idempotent**: Calling `restore()` again MUST do nothing.
- **account-present-sign-in**: `presentSignIn(from:)` MUST take an `AccountPresentationAnchor` and let the account present its own sign-in UI from it; the protocol takes no credentials.
- **account-sign-out**: `signOut()` MUST be `async` and non-throwing; it returns when sign-out work finishes. The protocol declares no error return and names no other failure channel.
- **account-state-cases**: `AccountState` MUST have exactly four cases: `restoring`, `signedOut`, `busy` and `signedIn(AccountUser)`.
- **account-state-busy**: `busy` MUST mean work the account is doing on its own, such as signing in through a browser sheet or signing out.
- **account-state-equatable**: `AccountState` MUST be `Sendable` and `Equatable`; `signedIn` states compare equal when their `AccountUser` values are equal.
- **account-user-fields**: `AccountUser` MUST carry `id`, `name` and `email` as `String` and `avatarURL` as an optional `URL`, all immutable, set by `init(id:name:email:avatarURL:)`.
- **account-user-sendable-equatable**: `AccountUser` MUST be `Sendable` and `Equatable`.
- **account-user-initials-words**: `AccountUser.initials` MUST be the uppercased first character of each of the name's first two whitespace-separated words, joined in order.
- **account-user-initials-email**: When the name has no words, `initials` MUST be the uppercased first character of `email`.
- **account-user-initials-placeholder**: When the name has no words and `email` is empty, `initials` MUST be `"?"`, so the value is never empty.
- **anchor-weak-reference**: `AccountPresentationAnchor` MUST hold its `object` weakly and type-erased (`AnyObject`), so the Foundation-only tier does not import AppKit or UIKit and the anchor does not extend the presenter's lifetime.
- **anchor-nil-after-release**: `AccountPresentationAnchor.object` MUST read `nil` once the presenter is released.
- **anchor-platform-object**: The platform MUST supply an `NSWindow` or `NSViewController` on macOS and a `UIViewController` on iOS as the anchor's object, per the type's documentation comment.
- **no-validation**: The types MUST NOT validate their inputs: `AccountUser` accepts any strings, and `AccountPresentationAnchor.init` accepts any object.
- **no-persistence**: The contract performs no file, network, process or notification side effects; those belong to conformers.

## Appearance

Not applicable — this is a protocol and value types, not a visual component.

## States

Not applicable — this is a protocol and value types, not a visual component. The runtime states (`restoring`, `signedOut`, `busy`, `signedIn`) are specified under Behavioral Requirements.

## Accessibility

Not applicable — this is a protocol and value types, not a visual component.

## Conformance Test Vectors

Vectors AC-001 to AC-003 and AC-006 are derived from `AccountUserTests` and `AccountPresentationAnchorTests` in `AccountsTests.swift`. The others are derived from the declarations in `Account.swift`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| AC-001 | account-user-initials-words | `AccountUser(id: "1", name: "ada lovelace byron", email: "a@b.c", avatarURL: nil).initials` (test `twoWords`) | `"AL"` |
| AC-002 | account-user-initials-email | name `"   "`, email `"zed@b.c"` (test `blankName`) | `"Z"` |
| AC-003 | account-user-initials-placeholder | name `""`, email `""` (test `nothing`) | `"?"` |
| AC-004 | account-user-initials-words | name `"Prince"`, email `"p@x.y"` | `"P"` (a single word gives one letter, no email letter added) |
| AC-005 | account-user-initials-email | name `""`, email `"zed@b.c"` | `"Z"` |
| AC-006 | anchor-weak-reference, anchor-nil-after-release | Build an anchor from an `NSObject`, then release the object (test `weak`) | `anchor.object` is non-nil before release and `nil` after |
| AC-007 | account-state-equatable | `AccountState.signedIn(u1) == AccountState.signedIn(u2)` where `u1` and `u2` have equal fields | `true` |
| AC-008 | account-state-equatable | `AccountState.busy == AccountState.signedOut` | `false` |
| AC-009 | account-on-change-single-slot | Assign `onChange` twice with different closures, then change `state` on a conformer | Only the second closure runs |
| AC-010 | account-restore-idempotent | Call `restore()` twice on a conformer whose stored login is good | One check runs; `state` leaves `.restoring` once |
| AC-011 | account-signup-url | A conformer with `signupURL == nil` | The accounts UI hides Signup |
| AC-012 | no-validation | `AccountUser(id: "", name: "", email: "", avatarURL: nil)` | Construction succeeds with all fields stored as given |

## Edge Cases

- **Blank name**: A name of only whitespace has no words, so `initials` falls back to the email. Behavior: MUST.
- **Empty name and email**: `initials` is `"?"`. Behavior: MUST.
- **Name with more than two words**: Only the first two words contribute. Behavior: MUST.
- **Lowercase or non-letter first character**: The first character is uppercased as `String.uppercased()` does it; a digit or symbol stands as it is. Behavior: MUST.
- **Anchor object released**: `object` reads `nil`; `presentSignIn(from:)` receives an anchor with no object and the conformer decides what to do. Behavior: the weak read MUST return `nil`.
- **Repeated `restore()`**: Does nothing after the first call. Behavior: MUST.
- **Second observer assigned to `onChange`**: Replaces the first; the first stops being notified. Behavior: MUST.
- **Null and empty input**: `message` and `signupURL` are optional; `nil` means "none". Empty strings are accepted for every `String` field of `AccountUser` without validation.
- **Boundary values**: The only boundary is the two-word cap on `initials`, covered above.
- **Concurrent access**: Not applicable as a race: `Account` is `@MainActor`, so calls are serialised on the main actor; `AccountUser` and `AccountState` are immutable `Sendable` values.
- **Error states**: `signOut()` returns no error and the protocol carries no error channel other than `message`; how a conformer reports a failure is its own contract.
- **Offline or disconnected**: Not applicable to this file; it performs no I/O. A conformer's `restore()` may make a network call and owns the behavior when it fails.
- **Cancellation, timeout, retry**: The protocol declares none; `signOut()` has no cancellation hook and `restore()` has no timeout.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `String` | supplied by the conformer | Identity; an account registry treats an id already present as a duplicate |
| `displayName` | `String` | supplied by the conformer | Title shown for the account |
| `summary` | `String` | supplied by the conformer | One line under the title while signed out |
| `signupURL` | `URL?` | supplied by the conformer | Where to sign up; `nil` hides Signup |
| `onChange` | `@MainActor () -> Void` | set by the conformer's initial value | Single observer slot, set by the accounts UI |
| `AccountUser.avatarURL` | `URL?` | none | Optional avatar image address |

## Deep Linking

Not applicable: the file has no routes or URL schemes; its only URL, `signupURL`, is an outbound web address.

## Localization

Not applicable: the file defines no user-facing strings of its own. The strings an account shows (`displayName`, `summary`, `message`) are supplied by each conformer, and `initials` uses `uppercased()` on the first characters without a locale.

## Accessibility Options

Not applicable: this is a protocol and value types with no visual presentation to adapt.

## Feature Flags

Not applicable: the source reads no flag or setting.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: `AccountUser` holds a user `id`, `name`, `email` and an optional avatar URL, which are personal data.
- **Storage**: The types hold the values in memory only; they do not persist them. A conformer's `restore()` may read a stored login, such as from the Keychain, as the doc comment says.
- **Transmission**: The types transmit nothing.
- **Retention**: A value lives as long as its holder; `AccountUser` values are immutable.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

- **SwiftUI**: The source platform is Swift. `Account.swift` lives in the SDK's `Accounts` source folder and imports Foundation only. `@MainActor` isolation makes a SwiftUI view model a natural conformer; replace the single `onChange` slot with `ObservableObject` or `@Observable` change tracking and render from `state` and `message`.
- **Compose**: Use a Kotlin interface with a `StateFlow` of a sealed class for `AccountState` (`Restoring`, `SignedOut`, `Busy`, `SignedIn(user)`), a `StateFlow` for `message`, and `suspend fun signOut()`. Pass the `Activity` or `Context` in place of `AccountPresentationAnchor`, held through a `WeakReference` to avoid leaking it. Unlike the source, flows allow many observers.
- **React/Web**: Use a TypeScript interface and a discriminated union for `AccountState`. Notify through a subscribe function or an `EventTarget` and use `useSyncExternalStore` in components. `signOut()` becomes a `Promise`. A browser has no presentation anchor; use a popup window or a redirect.
- **AppKit / UIKit**: The anchor carries an `NSWindow` or `NSViewController` on macOS and a `UIViewController` on iOS, which is how `ASWebAuthenticationSession` finds its presentation context. Weak storage prevents the account from retaining a closed window or controller.
- **WinUI 3**: Define an `IAccount` interface in C# implementing `INotifyPropertyChanged` for `State` and `Message`; `AccountState` becomes an abstract record with sealed subclasses (`Restoring`, `SignedOut`, `Busy`, `SignedIn`), and `AccountUser` a `record` (value equality like `Equatable`). `SignOutAsync()` returns `Task`. For the anchor, hold the `Window` or `XamlRoot` in a `WeakReference<object>`; browser sign-in goes through `WebAuthenticationBroker` or the system browser with a protocol-activation redirect. Marshal calls to the UI thread with `DispatcherQueue.TryEnqueue`, since .NET has no `@MainActor`. `ObservableCollection` is not needed for a single account. Store tokens with `PasswordVault` or DPAPI, not in the types.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Accounts/Account.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Login is `presentSignIn(from:)` rather than a method that takes credentials.
**Rationale**: The doc comment says how an account signs in is its own business; a hosted web login, a passkey or a social provider can all fit one verb.
**Approved**: pending

**Decision**: `AccountPresentationAnchor` is a weak, type-erased wrapper over `AnyObject`.
**Rationale**: The doc comment says this keeps the Foundation-only tier from importing AppKit or UIKit; weak storage keeps the anchor from retaining a window or controller.
**Approved**: pending

**Decision**: `onChange` is a single slot, and assigning it again replaces the earlier observer.
**Rationale**: The doc comment names the accounts UI that shows the account as its one observer.
**Approved**: pending

**Decision**: `restore()` is explicit, lazy and idempotent.
**Rationale**: The doc comment says an app pays for the stored-login check only when someone looks at the account.
**Approved**: pending

**Decision**: `initials` never returns an empty string.
**Rationale**: The doc comment says an avatar always has a face; the fallbacks are the email's first letter, then `"?"`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |

The contract separates concerns cleanly: the protocol and value types hold no UI, storage or network code, and platform specifics reach it only through the type-erased anchor. Unit tests cover `AccountUser.initials` (three cases) and the weak anchor, so coverage is partial: the protocol has only a stub conformer in the tests, and `AccountState` equality, the `onChange` rules and the `restore()` rules have no test in `AccountsTests.swift`. The source makes no log calls, so personal data in `AccountUser` is not written to logs here.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
