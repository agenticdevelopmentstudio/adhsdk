---
id: 2fa64944-9744-4d71-8fed-f785e7ce1e51
title: "Gmail Settings Model"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Main-actor observable model behind the Gmail settings view: OAuth client form, account list, coalesced settings updates, sign-in ordering, error alerts and display text."
platforms:
  - swift
  - macos
tags:
  - integrations
  - gmail
  - settings
  - view-model
  - oauth
depends-on:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - df121975-deb8-49a9-b023-0aadcb0923d8
related:
  - 4f066e76-2eca-4cd7-8b73-840178e4edf3
references: []
approved-by: ""
approved-date: ""
---

# Gmail Settings Model

## Overview

`GmailSettingsModel` is the state behind the Gmail settings view. It is a main-actor `ObservableObject` that wraps a `MailClient` and exposes the mail provider status, the list of Gmail accounts, the selected account, the OAuth client form drafts, a busy flag, a sign-in flag, an error message and a pending account-error alert. Every action the view offers (reload, import or save the OAuth client, add or reconnect an account, cancel a sign-in, remove an account, update an account's sync settings, sync now, remove the integration) goes through this model. The source comment states the intent: "this is the tested unit; the view only reads it and calls it."

The file also holds `GmailSignInTracker`, a main-actor ticket counter shared by all settings models. A browser return (`{{app_scheme}}://signed-in`) says only that a sign-in finished, not which surface started it, so each model keeps the ticket of its last sign-in and `startedLatestSignIn` tells the surface that started the newest one apart from the others.

Use it wherever the Gmail integration is configured. It owns no views and makes no calls except through the injected client.

## Behavioral Requirements

- **main-actor-isolation**: The model and the tracker MUST be isolated to the main actor.
- **injected-client**: The model MUST send every service call through the `MailClient` given at initialization.
- **shared-tracker-default**: The model MUST use `GmailSignInTracker.shared` when no tracker is given at initialization.
- **reload-after-every-action**: After every action that goes through the shared call path, the model MUST read the provider status from the client.
- **accounts-only-when-configured**: The model MUST read the account list only when the provider status reports `configured` as true, and MUST set the account list to empty otherwise.
- **error-cleared-at-call-start**: The model MUST set `errorMessage` to nil when a call starts.
- **error-from-first-failure**: When the action fails, the model MUST set `errorMessage` to the failure's `localizedDescription` and MUST still perform the reload.
- **reload-failure-reported-if-none**: When the reload fails and `errorMessage` is nil, the model MUST set `errorMessage` to the reload failure's `localizedDescription`.
- **reload-failure-keeps-first-error**: When the reload fails and `errorMessage` is already set, the model MUST keep the earlier message.
- **busy-while-in-flight**: `busy` MUST be true while at least one call is in flight and false when none is.
- **busy-counts-overlap**: `busy` MUST stay true until every overlapping call has finished.
- **selection-defaults-to-first**: After a reload, when `selectedAccountId` matches no loaded account, the model MUST set it to the first account's id, or nil when there are no accounts.
- **selection-kept-when-valid**: After a reload, when `selectedAccountId` matches a loaded account, the model MUST leave it unchanged.
- **selected-account**: `selectedAccount` MUST return the account whose id equals `selectedAccountId`, or nil when none matches.
- **dismiss-error**: `dismissError` MUST set `errorMessage` to nil without making a service call.
- **import-file-read-in-call**: `importClientJSON(from:)` MUST read the file inside the call, so a read failure becomes `errorMessage`.
- **import-file-bytes**: `importClientJSON(from:)` MUST send the file's bytes unchanged as an import-OAuth-client request.
- **client-draft-gate**: `canSaveClientDraft` MUST be true only when both `clientIdDraft` and `clientSecretDraft` are non-empty after trimming whitespace and newlines.
- **client-draft-incomplete**: When `canSaveClientDraft` is false, `saveClientDraft` MUST set `errorMessage` to "Enter both the client ID and the client secret." and MUST NOT send a request.
- **client-draft-trimmed**: `saveClientDraft` MUST send the trimmed client id and trimmed client secret as installed-app OAuth client JSON.
- **client-draft-cleared-on-success**: `saveClientDraft` MUST clear both drafts once the service accepts the client.
- **client-draft-kept-on-failure**: `saveClientDraft` MUST leave both drafts unchanged when the service rejects the client, so a typo can be corrected.
- **add-account-ticket**: `addAccount` MUST take a new ticket from the tracker before it sends the sign-in request.
- **signing-in-flag**: `signingIn` MUST be true from the start of `addAccount` until it returns.
- **started-latest-sign-in**: `startedLatestSignIn` MUST be true only when this model's last ticket is the tracker's latest ticket, and false when the model has never started a sign-in.
- **reconnect-is-add-account**: Reconnecting an account MUST use `addAccount`; the service matches the account by email and reuses it.
- **cancel-sign-in**: `cancelSignIn` MUST send a cancel-sign-in request.
- **cancel-sign-in-error**: When the cancel request fails, `cancelSignIn` MUST set `errorMessage` to the failure's `localizedDescription`.
- **cancel-sign-in-no-reload**: `cancelSignIn` MUST NOT reload and MUST NOT change `busy`; the pending `addAccount` call fails with "Sign-in was cancelled", reports that failure and reloads.
- **remove-account**: `remove(accountId:)` MUST send a remove-account request for that account.
- **sync-now**: `syncNow(accountId:)` MUST send a sync-now request for that account.
- **remove-integration**: `removeIntegration` MUST send a remove-provider request.
- **update-applies-locally**: `update(accountId:_:)` MUST set the account's settings in `accounts` before any request is sent.
- **update-coalesces**: While a settings send for an account is in flight, a further `update` for that account MUST only replace the pending value, and the running send MUST deliver the latest pending value when its current request finishes.
- **update-no-restart**: A further `update` made during a send MUST NOT start a second concurrent send for the same account.
- **update-failure-restores**: When a settings send fails, the model MUST drop the pending value for that account, set `errorMessage`, and show the service's settings from the reload that follows.
- **reload-keeps-chosen-settings**: A reload that finishes while a settings send is in flight MUST show the newest settings the user chose for that account rather than the service's previous value.
- **chosen-settings-released**: When the sends for an account finish, the model MUST stop overriding that account's settings with the user's choice.
- **account-error-alert**: After a reload, when an account has status error and a non-nil `lastError` that has not been alerted, and no alert is showing, the model MUST set `accountError` to an alert for the first such account in list order.
- **account-error-once**: The model MUST NOT alert again about the same message for the same account while the account stays in error.
- **account-error-new-message**: The model MUST alert again when an account in error reports a different message than the one last alerted.
- **account-error-after-recovery**: The model MUST forget an account once it is no longer in error, so a later failure alerts even when the message is identical.
- **account-error-one-at-a-time**: The model MUST NOT replace an alert that is showing.
- **dismiss-account-error**: `dismissAccountError` MUST clear `accountError` and then raise the next account error not yet shown.
- **show-error**: `showError(accountId:)` MUST set `accountError` for that account when it is in error with a `lastError`, and MUST do nothing otherwise.
- **show-error-marks-alerted**: `showError(accountId:)` MUST record the message as alerted so the next reload does not repeat it.
- **client-imported**: `isClientImported` MUST be true only when the provider status is loaded and `configured` is true.
- **oauth-client-text**: `oauthClientText` MUST be "Checking for an OAuth client…" before the first load, the instruction to enter or import a client when not configured, and the replace-client text when configured.
- **current-client-id**: `currentClientId` MUST return the provider's client id when a client is imported, and nil otherwise.
- **masked-secret**: `maskedClientSecret` MUST return ten "•" characters followed by the provider's secret suffix when a client is imported and the suffix is non-empty.
- **masked-secret-hidden**: `maskedClientSecret` MUST return "Stored (hidden)" when a client is imported and the suffix is nil or empty, and nil when no client is imported.
- **masked-secret-fixed-length**: The mask MUST be a fixed ten characters so it does not reveal the secret's length.
- **status-text**: `statusText` MUST map active to "Connected", error to "Error", revoked to "Reconnect needed" and pending to "Pending".
- **last-synced-text**: `lastSyncedText` MUST return "Last synced " followed by the full-style relative date from the formatter in the given locale, relative to the given clock.
- **last-synced-never**: `lastSyncedText` MUST return "Never synced" when the timestamp is nil or is not an ISO 8601 date with fractional seconds.
- **last-synced-defaults**: The overload without clock and locale MUST use the current date and the current locale.

## Appearance

Not applicable: the model draws nothing. The source comment says "the view only reads it and calls it", and `GmailSettingsView` owns layout, type and color. The model supplies only strings (`oauthClientText`, `maskedClientSecret`, `statusText`, `lastSyncedText`).

- **Corner radius**: Not applicable: no visual element.
- **Padding**: Not applicable: no visual element.
- **Font**: Not applicable: no visual element.
- **Background**: Not applicable: no visual element.
- **Foreground/Text**: Not applicable: no visual element.
- **Border**: Not applicable: no visual element.
- **Shadow**: Not applicable: no visual element.
- **Min/Max size**: Not applicable: no visual element.

## States

The model has no pressed, focused or disabled states. Its observable states are these.

| State | Appearance change |
|-------|------------------|
| Default | `provider` is nil and `accounts` is empty until the first call finishes; `oauthClientText` reads "Checking for an OAuth client…". |
| Busy | `busy` is true while any call is in flight. |
| Signing in | `signingIn` is true while `addAccount` waits for the browser sign-in. |
| Not configured | `provider.configured` is false; `accounts` is empty; the client id and secret accessors return nil. |
| Configured | `provider.configured` is true; accounts are listed; the client id and masked secret are available. |
| Error | `errorMessage` is non-nil until the next call starts or `dismissError` runs. |
| Account error alert | `accountError` is non-nil until `dismissAccountError` runs. |
| Loading | Not applicable: the model has no separate loading flag; `busy` covers reloads. |

## Accessibility

Not applicable: the model is not a visual or interactive element, so it has no role, label, focus or tap target. Accessibility belongs to `GmailSettingsView`. The model does supply the status words ("Connected", "Error", "Reconnect needed", "Pending") and the account-error alert text that the view presents.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gmail-settings-001 | reload-after-every-action, accounts-only-when-configured, selection-defaults-to-first | Service has a configured provider and one account `a1`; call `reload` (test `reloadLoadsProviderAndAccounts`) | `provider` is configured with client id "abc", `accounts` has the account, `selectedAccountId` is "a1", `busy` is false, `errorMessage` is nil |
| gmail-settings-002 | accounts-only-when-configured, client-imported, current-client-id, masked-secret-hidden | Provider not configured; `reload` (test `nothingIsShownWithoutAnImportedClient`) | `currentClientId` and `maskedClientSecret` are nil, `isClientImported` is false |
| gmail-settings-003 | add-account-ticket, started-latest-sign-in | Two models share one tracker; `desktop.addAccount()` then `settings.addAccount()` (test `onlyTheModelThatStartedTheLatestSignInClaimsIt`) | Before any sign-in both report false; after the first only `desktop` reports true; after the second only `settings` reports true |
| gmail-settings-004 | reload-after-every-action, signing-in-flag, injected-client | `addAccount` with a service that gains an account (test `addAccountSendsSignInThenReloads`) | The sign-in request is sent, the last request is the account listing, `accounts` has one entry |
| gmail-settings-005 | error-from-first-failure, error-cleared-at-call-start | Sign-in fails with "sign-in cancelled", then `reload` (tests `remoteFailureSetsErrorMessage`, `errorMessageClearsWhenTheNextCallStarts`) | `errorMessage` is "sign-in cancelled" after the failure and nil after the reload |
| gmail-settings-006 | dismiss-error | Sign-in fails with "boom"; call `dismissError` (test `dismissErrorClearsIt`) | `errorMessage` is nil |
| gmail-settings-007 | busy-while-in-flight, busy-counts-overlap | Two overlapping calls, the first finishing before the second (tests `busyIsTrueDuringACall`, `busyStaysTrueUntilOverlappingCallsBothFinish`, `busyIsNotClearedByTheFirstOfTwoOverlappingCalls`) | `busy` is true during the calls, stays true after the first finishes, and is false after both |
| gmail-settings-008 | update-applies-locally, update-coalesces, update-no-restart, chosen-settings-released | `update` window 7 held in flight, then `update` 14 and `update` 30 (tests `updateAppliesLocallyBeforeTheSend`, `rapidUpdatesCoalesceToTheLatestSettings`) | `accounts` shows 30 days at once; the service receives window values 7 then 30 only; `busy` ends false |
| gmail-settings-009 | update-failure-restores, error-from-first-failure | Settings send fails with "nope"; `update` with include-trash on (test `updateFailureRestoresServerStateAndSetsError`) | `errorMessage` is "nope"; the account's settings equal the default settings |
| gmail-settings-010 | reload-keeps-chosen-settings | `update` window 7 held in flight; `syncNow` completes its reload meanwhile (test `aReloadDuringASettingsSendKeepsShowingTheChosenValue`) | The account shows the chosen settings, not the service's previous value |
| gmail-settings-011 | import-file-bytes | `importClientJSON` with a file (test `importFromURLSendsTheFileBytes`) | The import request carries the file's bytes |
| gmail-settings-012 | import-file-read-in-call | `importClientJSON` with a missing file (test `importFromMissingURLSetsErrorMessage`) | `errorMessage` is set |
| gmail-settings-013 | client-draft-trimmed, client-draft-cleared-on-success, client-draft-gate | Drafts "  id-1.apps.googleusercontent.com \n" and " GOCSPX-secret "; `saveClientDraft` (test `savingTheClientFormSendsItAsInstalledJSONAndClearsTheFields`) | One import request whose JSON parses to the trimmed id and secret; both drafts are empty; `errorMessage` is nil; `isClientImported` is true |
| gmail-settings-014 | client-draft-kept-on-failure | Service rejects the client with "bad client" (test `aRejectedClientKeepsTheFormFilled`) | `errorMessage` is "bad client"; drafts still "id" and "secret" |
| gmail-settings-015 | client-draft-incomplete, client-draft-gate | Id "id", secret "   "; `saveClientDraft` (test `anIncompleteClientFormSendsNothing`) | `canSaveClientDraft` is false; `errorMessage` is "Enter both the client ID and the client secret."; no import request is sent |
| gmail-settings-016 | masked-secret, masked-secret-fixed-length, current-client-id, oauth-client-text | Configured provider, client id "id-9.apps.googleusercontent.com", suffix "12345" (test `theImportedClientIsShownWithTheSecretMasked`) | `maskedClientSecret` is ten "•" followed by "12345"; `currentClientId` is the full id; `oauthClientText` is the replace-client text |
| gmail-settings-017 | masked-secret-hidden | Configured provider with no suffix (test `aSecretTooShortToPartlyShowIsFullyHidden`) | `maskedClientSecret` is "Stored (hidden)" |
| gmail-settings-018 | oauth-client-text, client-imported | New model before any load; and unconfigured provider after load (tests `oauthClientTextBeforeTheFirstLoad`, `oauthClientTextWhenNoClientIsImported`) | "Checking for an OAuth client…" first; then the enter-or-import instruction ending "One client serves every Gmail account." |
| gmail-settings-019 | status-text | Each of the four statuses (test `statusText`) | "Connected", "Error", "Reconnect needed", "Pending" |
| gmail-settings-020 | last-synced-text, last-synced-never | Clock 2026-01-02T05:04:05.000Z, locale en_US; inputs nil, "2026-01-02T03:04:05.000Z", "garbage" (test `lastSyncedTextIsExactForAFixedDate`) | "Never synced", "Last synced 2 hours ago", "Never synced" |
| gmail-settings-021 | account-error-alert, account-error-once | One account in error, `reload` twice (test `aFailingAccountIsAlertedOnce` in GmailSettingsAccountErrorTests) | One alert after the first reload; no second alert after dismiss and reload |
| gmail-settings-022 | account-error-new-message, account-error-after-recovery | Account's error message changes; and an account recovers then fails with the same message (tests `aDifferentErrorIsAlertedAgain`, `theSameErrorAfterARecoveryIsAlertedAgain`) | Each case raises a new alert |
| gmail-settings-023 | dismiss-account-error, account-error-one-at-a-time | Two failing accounts; dismiss the first alert (test `dismissingRaisesTheNextFailingAccount`) | The second account's alert appears after the dismiss, not before |
| gmail-settings-024 | show-error, show-error-marks-alerted | `showError` on a failing account, and on a healthy one (tests `showErrorReopensItWithoutRepeatingAfterwards`, `showErrorIgnoresAHealthyAccount`) | The failing account's alert reopens and is not repeated after the next reload; the healthy account raises nothing |
| gmail-settings-025 | cancel-sign-in, cancel-sign-in-no-reload | `cancelSignIn` while signing in (test `cancelSignInSendsCancelWhileSigningIn`) | A cancel-sign-in request is sent; no reload request follows the cancel and `busy` does not change (the test asserts only that the request is sent) |
| gmail-settings-026 | remove-account, sync-now, remove-integration | `remove`, `syncNow`, `removeIntegration` (tests `removeSendsRemoveAccount`, `syncNowSendsSyncNow`, `removeIntegrationClearsAccounts`) | The matching request is sent and the reloaded accounts reflect the service |
| gmail-settings-027 | selection-kept-when-valid, selected-account | Select an existing account, then reload (no test asserts this yet) | `selectedAccountId` is unchanged and `selectedAccount` is that account |
| gmail-settings-028 | reload-failure-reported-if-none, reload-failure-keeps-first-error | Provider read fails, with `errorMessage` nil; then an action fails and the provider read fails again (no test asserts this yet) | The first case sets `errorMessage` to the reload failure's text; the second keeps the action's message |
| gmail-settings-029 | cancel-sign-in-error | The cancel request fails with "no sign-in" (no test asserts this yet) | `errorMessage` is "no sign-in" and no reload request follows |
| gmail-settings-030 | shared-tracker-default | Two models created without a tracker; each calls `addAccount` in turn (no test asserts this yet) | The second model's ticket supersedes the first, so only the second reports `startedLatestSignIn` |
| gmail-settings-031 | reconnect-is-add-account | An account in `revoked` state; `addAccount` (no test asserts this yet) | A sign-in request is sent, with no separate reconnect request |
| gmail-settings-032 | last-synced-defaults | `lastSyncedText` with only a timestamp one hour in the past (no test asserts this yet) | "Last synced " followed by the relative date in the current locale |
| gmail-settings-033 | account-error-alert | Two accounts in error, listed `b1` then `a1`; `reload` (no test asserts this yet) | The alert is for `b1`, the first in list order |

This ingredient has no SHOULD requirements, so no omission needs a rationale.

## Edge Cases

- **Null and empty input, drafts**: Both drafts blank or whitespace-only. `saveClientDraft` MUST set the incomplete-form message and send nothing.
- **Null and empty input, secret suffix**: A configured client whose suffix is nil or empty. `maskedClientSecret` MUST return "Stored (hidden)".
- **Null and empty input, timestamp**: A nil or unparsable `lastSyncAt`. `lastSyncedText` MUST return "Never synced".
- **Null and empty input, selection**: No accounts. `selectedAccountId` MUST become nil after a reload.
- **Boundary values, sign-in tickets**: A model that has never signed in has no ticket, and `startedLatestSignIn` MUST be false.
- **Boundary values, secret mask**: The mask MUST be ten characters plus the suffix; the model does not compute the suffix length, the service sends it in the provider status (see the [mail integration service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)).
- **Boundary values, settings ranges**: The model does not clamp or validate `windowDays` or `pollIntervalMinutes`; it sends the settings it is given. Range limits live in `MailSyncSettings`.
- **Concurrent access, overlapping calls**: Calls may overlap; `busy` MUST count them and stay true until all finish. Each call's reload replaces `accounts` with the service's list.
- **Concurrent access, rapid settings changes**: Only one settings send per account runs at a time; later values replace the pending one (MUST).
- **Concurrent access, tracker**: The tracker is main-actor isolated, so tickets are issued serially (MUST).
- **Error states, action failure**: The first failure sets `errorMessage`; the reload still runs (MUST).
- **Error states, reload failure**: The reload failure sets `errorMessage` only when none is set (MUST). When the account read fails after the provider read succeeded, `provider` is updated and only `accounts` keeps its previous value, so `provider` can be newer than `accounts`. When the provider read fails, both keep their previous values.
- **Error states, settings send failure**: Pending value dropped, chosen-value override released, reload restores the service's state (MUST). When several values were pending, the failure discards them all.
- **Error states, cancel failure**: Only `errorMessage` is set; no reload runs (MUST).
- **Error states, duplicate alerts**: An account error already alerted MUST NOT alert again until the account leaves the error state or its message changes.
- **Error states, removed account**: When an alerted account is removed, the next reload drops its record, because the alerted record is filtered to accounts still in error (MUST).
- **Offline or disconnected state**: The model has no connectivity handling of its own. A call that cannot reach the service fails like any other failure and shows `errorMessage`; there is no retry, backoff or timeout in this file. Whether the injected client retries is outside the file.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| client | `MailClient` | required | The service client every call goes through. |
| signIns | `GmailSignInTracker` | `GmailSignInTracker.shared` | The ticket counter shared by every settings model in the app. Tests pass their own. |
| clientIdDraft | `String` | empty | Client id field of the OAuth client form. |
| clientSecretDraft | `String` | empty | Client secret field of the OAuth client form. |
| selectedAccountId | `String?` | nil | The account the detail controls edit; settable by the view. |

## Deep Linking

Not applicable: the model registers no URL and handles no deep link. It only supplies `startedLatestSignIn`, which the app can read when `{{app_scheme}}://signed-in` arrives to send the user back to the surface that began the sign-in.

## Localization

- **string-externalization**: NEEDS REVIEW: Not implemented in source. The strings the model returns ("Connected", "Error", "Reconnect needed", "Pending", "Never synced", "Last synced ", "Stored (hidden)", "Checking for an OAuth client…", the two OAuth client descriptions, and the incomplete-form error) are English literals with no localization lookup; evidence that would settle it is the product's localization decision for the Integrations settings screen.
- **relative-date-locale**: The model MUST format the relative date with the given locale, which defaults to the current locale; the surrounding "Last synced " prefix is not localized.

## Accessibility Options

Not applicable: the model draws nothing and animates nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color do not reach it. The view owns those responses.

## Feature Flags

Not applicable: the source reads no flag; the model is always active when the view uses it.

## Analytics

Not applicable: the source records no analytics event.

## Privacy

- **Data collected**: The model holds the user's Gmail account emails, sync status and last error messages, and the OAuth client id and secret the user types.
- **Storage**: The model keeps these in memory only. The service stores the OAuth client; the daemon sends only the last five characters of the secret, so the whole secret never returns to the model after import.
- **Transmission**: The drafts leave the process only in the import request to the injected client. Drafts clear after the service accepts them.
- **Retention**: The drafts stay in memory after a rejected import so the user can correct them; the model does not persist them.

## Logging

Not applicable: the file writes no log statements.

## Platform Notes

- **SwiftUI**: Source platform. The source is `macOS/Features/Integrations/GmailSettingsModel.swift` and holds the model and the tracker. The model is an `ObservableObject` with `@Published` properties (private setters except `selectedAccountId` and the drafts), isolated with `@MainActor`, and uses Swift concurrency (`async` functions and `defer`) with a plain in-flight counter for `busy`. Tests use Swift Testing with a scripted `MailClient`.
- **Compose**: Translate to a `ViewModel` exposing a `StateFlow` of one immutable state class, with actions as `suspend` functions run on `viewModelScope`. Collect state updates on the main dispatcher in place of main-actor isolation; keep the in-flight counter for `busy` and the per-account pending map for coalescing.
- **React/Web**: Translate to a hook or store (a reducer or a small observable class) with async action functions. Browser code is single-threaded, so main-actor isolation is implicit, but the coalescing map and ticket counter still need to be explicit. Use `Intl.RelativeTimeFormat` with the `long` style for the relative date.
- **AppKit / UIKit**: AppKit is the shipping surface: bind with Combine sinks on the `@Published` properties, present `accountError` with `NSAlert` and call `dismissAccountError` from its handler. A UIKit port should reuse the model as written (the recipe lists no `ios` platform because no iOS source exists yet), bind the same way and present `accountError` with `UIAlertController`.
- **WinUI 3**: Implement as a view-model class (a C# class using CommunityToolkit.Mvvm `ObservableObject` with `[ObservableProperty]`) and bind from XAML with `x:Bind` in `OneWay` mode, and `TwoWay` for `SelectedAccountId` on a `ListView` `SelectedValue` and for the two drafts on a `TextBox` and a `PasswordBox`. Marshal back to the UI thread through `DispatcherQueue.TryEnqueue` after each await, which stands in for main-actor isolation. Drive busy and signing-in with `ProgressRing.IsActive` and disable the commands (`AsyncRelayCommand.CanExecute`) while `Busy` is true; expose `CanSaveClientDraft` as the `Button.IsEnabled` binding. Show `AccountError` in a `ContentDialog` (set `XamlRoot` before `ShowAsync`, and call `DismissAccountError` on close); `ContentDialog` allows only one open dialog at a time, which matches the one-alert-at-a-time rule. Format the relative date with the `Humanizer` library or a custom formatter, and load the display strings from `.resw` files through `ResourceLoader`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/GmailSettingsModel.swift` | unverified |
| ios | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Every view action goes through one private call path that runs the action, then always reloads provider and accounts.
**Rationale**: The reload makes the model show the service's state, which also repairs optimistic changes after a failure.
**Approved**: pending

**Decision**: Settings updates apply locally at once, then coalesce per account to the latest value while a send is in flight.
**Rationale**: A stepper or toggle can change faster than the service answers, and each change must not restart a sync. A failure drops all pending values and reloads, so the user may lose several intermediate choices at once.
**Approved**: pending

**Decision**: A reload that lands mid-send re-applies the newest chosen settings over the service's list.
**Rationale**: A change made while reloading has not reached the service yet, so the model keeps showing it and avoids a visible snap back to the old value.
**Approved**: pending

**Decision**: Sign-ins are ordered by a shared tracker rather than by each model alone.
**Rationale**: The browser return says only that a sign-in finished, not where it began, and the same settings may show on several surfaces. A model that never signed in reports false.
**Approved**: pending

**Decision**: Account errors alert once per account and message, and the row carries only the "Error" badge; "Show Error" reopens the alert on request.
**Rationale**: Alerting again about the same failure on every reload would nag the user, so the model remembers what it alerted and forgets an account once it recovers, so a later identical failure alerts. Only one alert shows at a time.
**Approved**: pending

**Decision**: The client secret is shown as a fixed ten-bullet mask plus the last five characters of the secret that the mail integration service sends in the provider status (see the [mail integration service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a), which owns the five-character limit), or "Stored (hidden)" when no suffix exists.
**Rationale**: A fixed mask length does not reveal the secret's length, and the service sends only those characters.
**Approved**: pending

**Decision**: `cancelSignIn` makes its own call without the shared call path, so it neither reloads nor changes `busy`.
**Rationale**: The pending sign-in call is the one that fails with "Sign-in was cancelled" and reloads, so a second reload would duplicate that work. This is a quirk: when the pending sign-in then fails, its own call sets `errorMessage` to that failure, so a cancel failure message can be replaced.
**Approved**: pending

**Decision**: Display strings are English literals inside the model, with the clock and locale injectable for tests.
**Rationale**: Keeping the text beside the state lets the model's tests cover it. This is deliberate technical debt for localization, tracked on `string-externalization` in Localization. It is retired when the first non-English locale ships for the Integrations settings screen, or when the product decides how that screen is localized, whichever comes first; the owner is the Integrations settings screen's maintainer.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The model keeps state and decisions apart from the view and from the service client, which it receives by injection, and its behavior is covered by two test files beside it (`GmailSettingsModelTests` and `GmailSettingsAccountErrorTests`), including the concurrency cases. Unit-test coverage is partial: vectors gmail-settings-027 to 033 are derived from the code and no named test asserts them, and the cancel test does not check that no reload follows. Every failure is surfaced as `errorMessage` or an account alert rather than swallowed, except that a failed reload is hidden when an earlier error is already set. Only the last five characters of the secret reach the model. Relative dates use the injected locale, but the surrounding words are English literals and no localization lookup exists, so locale-aware formatting is partial and hardcoded strings fail.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
