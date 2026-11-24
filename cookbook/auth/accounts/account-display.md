---
id: 86eccc6f-cd1b-4ac7-bb98-851eb7c54324
title: "Account Display"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Platform-free rules for what an accounts screen shows per account state: visible controls, spinner, status line and user."
platforms:
  - swift
  - macos
  - ios
tags:
  - auth
  - accounts
  - display
depends-on: []
related:
  - 9cf9784d-48c9-4b29-b553-c72ffdfce7b9
  - f46b9323-7954-4f66-a476-970fcc9db372
references: []
approved-by: ""
approved-date: ""
---

# Account Display

## Overview

`AccountDisplay` is an immutable value that turns one account's state into the visibility decisions every account detail view needs: which user to show, whether the "Checking sign-in…" status line and a spinner show, which of Login, Signup and Logout show, whether the buttons are enabled, and which error or status message line shows. It is the platform-free half of the accounts screen: macOS and iOS each draw it with their own controls, and the rules for what is visible live here once. It is a pure function of its inputs (an `AccountState` from the Account ([adhsdk.ingredient.auth.accounts.account](cookbook:9cf9784d-48c9-4b29-b553-c72ffdfce7b9)) ingredient, a message, whether a signup URL exists, and the previous render's shown user); it holds no storage, performs no I/O and starts no work.

## Behavioral Requirements

Shape and ordering

- **value-type**: `AccountDisplay` MUST be an immutable value type (`struct` with only `let` properties) that is `Sendable` and `Equatable`.
- **pure-computation**: Every property MUST be computed once at construction from the inputs alone; constructing with the same inputs MUST yield an equal value.
- **state-initializer**: The display MUST be constructible from `state: AccountState`, `message: String?`, `hasSignupURL: Bool` and `lastUser: AccountUser?`, where `lastUser` is the previous render's `shownUser`.
- **account-initializer**: A second initializer taking `account: any Account` and `lastUser: AccountUser?` MUST be isolated to the main actor and MUST delegate to the state initializer with `account.state`, `account.message`, and `hasSignupURL` true exactly when `account.signupURL` is not `nil`.

Which user is shown

- **shown-user-signed-in**: When the state is `.signedIn(user)`, `shownUser` MUST be that user, regardless of `lastUser`.
- **shown-user-busy**: When the state is `.busy`, `shownUser` MUST be `lastUser` (which may be `nil`), so that signing out keeps showing who is signing out rather than flashing the signed-out controls.
- **shown-user-otherwise**: In every other state (`.restoring`, `.signedOut`), `shownUser` MUST be `nil` and `lastUser` MUST be ignored.

Status line and spinner

- **status-text**: `showsStatusText` MUST be true exactly when the state is `.restoring`.
- **restoring-text**: The status line text exposed as `AccountDisplay.restoringText` MUST be the string `Checking sign-in…` (with a single ellipsis character).
- **spinner**: `showsSpinner` MUST be true exactly when the state is `.restoring` or `.busy`.

Controls

- **login-visibility**: `showsLogin` MUST be true exactly when the display is signed-out-like: the state is `.signedOut`, or the state is `.busy` and `shownUser` is `nil`.
- **signup-visibility**: `showsSignup` MUST be true exactly when the display is signed-out-like and `hasSignupURL` is true.
- **logout-visibility**: `showsLogout` MUST be true exactly when `shownUser` is not `nil`.
- **no-controls-while-restoring**: While the state is `.restoring`, `showsLogin`, `showsSignup` and `showsLogout` MUST all be false.
- **controls-enabled**: `controlsEnabled` MUST be false when the state is `.busy` and true when the state is `.signedOut` or `.signedIn`.
- **enabled-is-independent-of-visibility**: `controlsEnabled` MUST depend only on whether the state is busy, never on which buttons are visible. Its value while the state is `.restoring` is unspecified, because no button is visible then and consumers MUST NOT read it. The source computes `true` there.

Message

- **message-passthrough**: `message` MUST be the `message` input unchanged for every state; `nil` means the line is hidden. The display neither trims, rewrites nor suppresses it, including an empty string.

Side effects

- **no-side-effects**: Constructing an `AccountDisplay` MUST NOT start sign-in, sign-out or restore work, and MUST NOT write to any store or the network. The account-based initializer only reads `state`, `message` and `signupURL` from the account.

Ordering and concurrency

- **actor-isolation**: The state initializer is nonisolated and callable from any context; only the account-based initializer is `@MainActor`, because `Account` is a main-actor protocol. The value itself is `Sendable` and may cross actors.
- **caller-feeds-last-user**: The caller MUST pass the previous render's `shownUser` back as `lastUser` on the next render; the display keeps no history of its own, so a caller that passes `nil` while busy gets the signed-out controls.

Verification

- **derived-vectors-tested**: `AccountDisplayTests` SHOULD assert test vectors 008 to 014, so the account-based initializer, `restoringText` and the empty-string message are covered by tests and not only by this document.
## Appearance

Not applicable — this is a display-rules value, not a visual component.

## States

Not applicable — this is a display-rules value, not a visual component. The account states it maps (`restoring`, `signedOut`, `busy`, `signedIn`) are inputs to Behavioral Requirements, and the resulting visibility is tabulated under Conformance Test Vectors.

## Accessibility

Not applicable — this is a display-rules value, not a visual component.

## Conformance Test Vectors

Vectors 001 to 007 mirror the tests in `AccountDisplayTests`; 002 and 003 share one test (`signedOut_showsLoginAndSignup_onlyWithASignupURL`), so six tests cover seven vectors (`restoring_showsTheStatusLineAndSpinner_andNoButtons`, `signedOut_showsLoginAndSignup_onlyWithASignupURL`, `signedIn_showsTheUserAndLogout`, `busyAfterSignedIn_keepsShowingTheUser_withControlsDisabled`, `busyFromSignedOut_keepsTheSignedOutControls`, `signedOut_forgetsTheLastUser`). Vectors 008 to 014 are derived from the initializer and are not asserted by those tests. `U` is a user such as id `u1`, name `Ada Lovelace`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| account-display-001 | status-text, spinner, no-controls-while-restoring, shown-user-otherwise | state `.restoring`, message `nil`, hasSignupURL true, lastUser `nil` (test: `restoring_showsTheStatusLineAndSpinner_andNoButtons`) | showsStatusText true, showsSpinner true, showsLogin/showsSignup/showsLogout false, shownUser `nil`. |
| account-display-002 | login-visibility, signup-visibility, logout-visibility | state `.signedOut`, hasSignupURL true, lastUser `nil` (test: `signedOut_showsLoginAndSignup_onlyWithASignupURL`) | showsLogin true, showsSignup true, showsLogout false. |
| account-display-003 | signup-visibility | state `.signedOut`, hasSignupURL false, lastUser `nil` (same test) | showsLogin true, showsSignup false. |
| account-display-004 | shown-user-signed-in, logout-visibility, controls-enabled, spinner | state `.signedIn(U)`, hasSignupURL true, lastUser `nil` (test: `signedIn_showsTheUserAndLogout`) | shownUser `U`, showsLogout true, showsLogin false, showsSignup false, showsSpinner false, controlsEnabled true. |
| account-display-005 | shown-user-busy, controls-enabled, spinner, status-text | state `.busy`, hasSignupURL true, lastUser `U` (test: `busyAfterSignedIn_keepsShowingTheUser_withControlsDisabled`) | shownUser `U`, showsLogout true, showsLogin false, showsSpinner true, showsStatusText false, controlsEnabled false. |
| account-display-006 | login-visibility, signup-visibility, controls-enabled | state `.busy`, hasSignupURL true, lastUser `nil` (test: `busyFromSignedOut_keepsTheSignedOutControls`) | shownUser `nil`, showsLogin true, showsSignup true, showsLogout false, controlsEnabled false. |
| account-display-007 | shown-user-otherwise, message-passthrough | state `.signedOut`, message `Signed out`, hasSignupURL false, lastUser `U` (test: `signedOut_forgetsTheLastUser`) | shownUser `nil`, message `Signed out`. |
| account-display-008 | shown-user-signed-in | state `.signedIn(U)`, lastUser a different user `V` | shownUser `U`, not `V`. |
| account-display-009 | shown-user-otherwise, no-controls-while-restoring | state `.restoring`, lastUser `U` | shownUser `nil`, showsLogout false. |
| account-display-010 | enabled-is-independent-of-visibility | state `.restoring` | controlsEnabled is unspecified (the source gives true) while every button is hidden; consumers do not read it. |
| account-display-011 | restoring-text | read `AccountDisplay.restoringText` | `Checking sign-in…`. |
| account-display-012 | message-passthrough | state `.signedIn(U)`, message `nil`, then message `""` (empty) | message `nil` in the first, empty string in the second (not coerced to `nil`). |
| account-display-013 | account-initializer | a main-actor account whose state is `.signedOut`, message `Try again`, signupURL non-nil, with lastUser `nil` | Equal to the state initializer called with `.signedOut`, `Try again`, hasSignupURL true, `nil`. |
| account-display-014 | account-initializer | the same account with signupURL `nil` | showsSignup false. |

## Edge Cases

- **Null / empty input**: A `nil` `lastUser` while `.busy` MUST yield the signed-out controls (Login, and Signup when a URL exists) with controls disabled, not an empty signed-in layout. A `nil` message hides the line; an empty-string message is passed through as an empty string, not converted to `nil` (`message-passthrough`).
- **Boundary values**: `lastUser` survives only across consecutive `.busy` renders; any `.signedOut` or `.restoring` render resets `shownUser` to `nil`. In `.signedIn`, a differing `lastUser` MUST be ignored in favour of the state's user.
- **Concurrent access**: The value is immutable and `Sendable`, so any number of readers are safe. Only the account-based initializer is main-actor isolated, so it is serialised with the account's own state changes.
- **Error states**: There is no failing path: the initializers do not throw or return an error. An error is shown only as the pass-through `message`; the display decides no wording and no severity.
- **Offline / disconnected state**: Not applicable: the display performs no network access; an unreachable server reaches it only as an account `message` or a state change.
- **Cancellation**: Not applicable: the display starts no asynchronous work, so there is nothing to cancel.
- **Stale caller history**: If the caller forgets to feed `shownUser` back as `lastUser`, a sign-out in progress renders as signed out (Login visible, disabled). The source documents this contract and does not guard against it (`caller-feeds-last-user`).
- **Busy with a signup URL absent**: Signed-out-like and busy with `hasSignupURL` false shows Login only.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `state` | `AccountState` | none (required) | One of `restoring`, `signedOut`, `busy`, `signedIn(AccountUser)`. |
| `message` | `String?` | none (required) | The account's error or status line; `nil` hides it. |
| `hasSignupURL` | `Bool` | none (required) | Whether the account has a signup URL; false hides Signup. |
| `lastUser` | `AccountUser?` | none (required) | The previous render's `shownUser`, used only while busy. |

These are the inputs of the state initializer. The account-based initializer takes `account` and `lastUser` instead (see `account-initializer`), and the `restoringText` constant is listed under Localization. The display reads no environment variable or settings key.

## Deep Linking

Not applicable: the display defines no URL scheme or route; it only observes whether an account has a signup URL.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none yet (hardcoded literal `AccountDisplay.restoringText`; target key `account.status.restoring`) | `Checking sign-in…` | Status line shown while a stored login is being checked. |

The string is a hardcoded English literal with no localization lookup. The `message` it passes through is localized, if at all, by the account that supplies it.

## Accessibility Options

Not applicable: the display decides visibility only and renders nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color apply to the views that draw it.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data collected**: None of its own; it carries the `AccountUser` (id, name, email, avatar URL) and message it is given.
- **Storage**: None; it is an in-memory value that persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: Only for the lifetime of the value the caller holds.

## Logging

Not applicable: the source calls no logging API.

## Platform Notes

- **SwiftUI**: The file imports only `Foundation`, so a SwiftUI view model uses it unchanged: build a new `AccountDisplay` on each `Account.onChange` and store the previous `shownUser` to pass as `lastUser`. Bind `controlsEnabled` to `.disabled(!display.controlsEnabled)` and conditionally include Login, Signup, Logout and a `ProgressView` from the `shows` flags.
- **Compose**: Model it as an immutable data class with a companion factory taking state, message, hasSignupURL and lastUser; hold the account state in a `StateFlow` and derive the display with `map`. Render buttons with `Button(enabled = display.controlsEnabled)` and a `CircularProgressIndicator` for the spinner.
- **React/Web**: A pure function returning a frozen object (or a `useMemo` over the inputs); keep the previous `shownUser` in a `useRef` and pass it back as `lastUser`. Map `controlsEnabled` to the `disabled` attribute and `showsSpinner` to a `role="progressbar"` element.
- **AppKit / UIKit**: This is the source platform. The shared tier is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Accounts/AccountDisplay.swift`; the macOS detail panel (`AccountDetailPanelViewController`) constructs it and draws it with `ThemedActionButton` (a push-button subclass) for Login, Signup and Logout, hiding each from the `shows` flags, and an `NSProgressIndicator`; the iOS `MobileAccountViewController` rebuilds it with `lastUser` set to the previous `display.shownUser` and maps it to table rows (user, status with a `UIActivityIndicatorView`, Login, Signup, Logout) through `rows(for:)`, so the iOS buttons are list cells rather than `UIButton`. The account-based initializer is `@MainActor`, matching the view controllers.
- **WinUI 3**: Implement it as an immutable C# `record` (value equality matches `Equatable`) with a constructor taking `AccountState`, `string?`, `bool` and `AccountUser?`, where `AccountState` is a discriminated union (an abstract record with `Restoring`, `SignedOut`, `Busy` and `SignedIn(AccountUser)` subtypes). Expose the flags to XAML through a view model that implements `INotifyPropertyChanged` and rebuilds the record on the account's change event; bind `Visibility` to the `shows` flags with a `BoolToVisibilityConverter` (or `x:Bind` function binding), `Button.IsEnabled` to `ControlsEnabled`, and a `ProgressRing` with `IsActive` to `ShowsSpinner`. Marshal the rebuild onto the UI thread through `DispatcherQueue.TryEnqueue`, the analogue of the source's `@MainActor` account initializer.

## Design Decisions
All four decisions are `Approved: pending`: the recipe is in review and none has been settled by the owner yet.

**Decision**: While busy, the display keeps showing the user shown before the work began (supplied by the caller as `lastUser`) instead of switching to the signed-out controls.
**Rationale**: Without it, a sign-out in progress would flash the signed-out controls instead of showing who is signing out (the doc comment on `AccountDisplay.shownUser`). The display stays stateless, so the caller carries the previous `shownUser` forward.
**Approved**: pending

**Decision**: A busy account with no remembered user renders as signed out (Login, and Signup when a URL exists), with every control disabled.
**Rationale**: Signing in through a browser sheet starts from the signed-out state, so the signed-out controls stay in place, disabled, rather than vanishing during the sign-in.
**Approved**: pending

**Decision**: `controlsEnabled` depends only on busy, not on whether a button is visible.
**Rationale**: One rule, "False while busy: every button is disabled" (the doc comment on `AccountDisplay.controlsEnabled`), applies to whichever buttons a view shows. During restoring no button shows, so the value is unspecified there and no consumer depends on it.
**Approved**: pending

**Decision**: `restoringText` is a hardcoded English constant on the type and the account `message` is passed through verbatim.
**Rationale**: One constant on the type (`AccountDisplay.restoringText`) makes both platforms show the same text, and the account that produces an error owns its wording. The hardcoded literal is known internationalization debt, which is why `no-hardcoded-strings` is `failed`. It should be paid off by looking the text up under a key such as `account.status.restoring` with the English default `Checking sign-in…`, when the SDK gains a localization layer.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because the type holds only visibility rules: it draws nothing, stores nothing and performs no I/O, and leaves rendering to each platform's views. `unit-test-coverage` passes: `AccountDisplayTests` (`Accounts/AccountDisplayTests.swift`) asserts all fourteen vectors, including the `@MainActor` account-based initializer, the `restoringText` value and an empty-string message. `no-hardcoded-strings` fails because `restoringText` is an English literal with no localization lookup.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (AccountDisplayTests.swift, 14 of 14 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Corrected spec claims against AccountDisplay source and tightened requirements and vectors. |
