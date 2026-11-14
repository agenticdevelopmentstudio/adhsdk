---
id: 4f066e76-2eca-4cd7-8b73-840178e4edf3
title: "GmailSettingsView"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Gmail detail pane: OAuth client entry, a list of signed-in accounts, and per-account sync controls, driven entirely by GmailSettingsModel."
platforms:
  - swift
  - macos
tags:
  - gmail
  - settings
  - oauth
  - mail-sync
  - accounts
depends-on:
  - 2fa64944-9744-4d71-8fed-f785e7ce1e51
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references:
  - https://developers.google.com/identity/protocols/oauth2/native-app
approved-by: ""
approved-date: ""
---

# GmailSettingsView

## Overview

GmailSettingsView is the Gmail detail pane of the macOS settings surface. It has two sections stacked vertically and separated by a divider: an **OAuth Client** section for entering or importing the Google Cloud Desktop app client, and an **Accounts** section that lists signed-in Gmail accounts and exposes sync controls for the selected one.

The view owns no business state. The contract is that it reads `GmailSettingsModel` and calls it, nothing else. The model is observed, never created, by the view. Every action the view offers is a call into the model, and every piece of display text that is not a fixed label comes from the model (`oauthClientText`, `currentClientId`, `maskedClientSecret`, `statusText`, `lastSyncedText`). The view adds two things the model does not: presentation of errors as alerts, and the two native panels (open panel for the client JSON, destructive confirmation for account removal).

Use it as the Gmail entry of a settings window whose model is already built. It does not load itself: the model must be reloaded by its owner, and until it has been, the pane shows the model's "Checking for an OAuth client…" text.

## Behavioral Requirements

### Layout and structure

- **section-order**: The view MUST render the OAuth Client section first, a divider, then the Accounts section, in one leading-aligned vertical stack with 12 pt spacing between them.
- **fill-and-inset**: The view MUST inset its content by 20 pt on every edge and expand to fill the width and height offered, anchored top-leading.
- **no-self-loading**: The view MUST NOT load the provider or accounts itself; it MUST display whatever the model currently holds.

### OAuth client section

- **client-heading-and-text**: The OAuth Client section MUST show the heading "OAuth Client" followed by the model's `oauthClientText`, wrapping onto as many lines as it needs.
- **current-client-readout**: When the model reports both a current client ID and a masked client secret, the view MUST show them as a two-row grid labelled "Current client ID" and "Current secret"; when either is nil the grid MUST be absent.
- **client-id-selectable**: The current client ID MUST be shown in full, in a monospaced face, and MUST be selectable text.
- **secret-never-revealed**: The current secret row MUST use a monospaced face and MUST NOT be selectable; what it shows is governed by #requirements/secret-masked-readout.
- **client-form-fields**: The view MUST show a "Client ID" text field with the prompt "….apps.googleusercontent.com" bound to the model's `clientIdDraft`, and a "Client secret" field bound to `clientSecretDraft` that conceals input (see #requirements/secret-entry-concealed), in a form no wider than 460 pt.
- **save-client-button**: The view MUST show a button titled "Save Client" when no client is imported and "Replace Client" when one is, and pressing it MUST call the model's `saveClientDraft`.
- **save-client-enablement**: The save-client button MUST be disabled while the model is busy or while `canSaveClientDraft` is false.
- **import-json-button**: The view MUST show a button titled "Import Client JSON…" when no client is imported and "Replace from JSON…" when one is, separated from the save button by the secondary-styled word "or".
- **import-json-enablement**: The import button MUST be disabled while the model is busy, and MUST NOT depend on the draft fields.
- **import-json-panel**: Pressing the import button MUST open a modal file-open panel that allows only JSON files, a single selection, and no directories.
- **import-json-cancel**: If the file panel is dismissed without choosing a file, the view MUST make no model call.
- **import-json-call**: If a file is chosen, the view MUST call the model's `importClientJSON(from:)` with its URL.
- **reconnect-hint**: When a client is imported and at least one account exists, the view MUST show the caption "Accounts signed in with a replaced client need Reconnect." The condition is deliberately broad: see the design decision on the reconnect hint.

### Accounts section

- **accounts-heading**: The Accounts section MUST show the heading "Accounts".
- **add-client-first-hint**: While no client is imported, the view MUST show the caption "Add the OAuth client above before adding an account."
- **account-list**: The view MUST show the model's accounts in a selectable list at least 120 pt tall, with the selection bound to the model's `selectedAccountId`.
- **account-row-content**: Each row MUST show the account's email, a capsule badge containing `GmailSettingsModel.statusText` for the account's status, and beneath them a caption in secondary style containing `GmailSettingsModel.lastSyncedText` for the account's last sync time.
- **add-account-button**: The view MUST show an "Add Account…" button that calls the model's `addAccount`, and MUST disable it while the model is busy or no client is imported.
- **remove-button**: The view MUST show a "Remove" button, MUST disable it while no account is selected or the model is busy, and on press MUST ask for confirmation for the selected account instead of removing it.
- **remove-confirmation**: The removal confirmation MUST be titled "Remove <email>?", MUST say it signs the account out of Google, removes its stored sign-in and deletes its mail from this Mac, and MUST offer an action titled "Remove".
- **remove-safe-default**: The removal confirmation MUST make Cancel the default response to Return, and Esc MUST decline.
- **remove-call**: The view MUST call the model's `remove(accountId:)` only when the user confirms, and MUST make no model call when the user declines or when there is no key window to attach the confirmation to; the shared confirmation helper answers no without a window, so unlike alerts the confirmation has no app-modal fallback.
- **sign-in-progress**: While the model's `signingIn` is true, the view MUST show a small spinner, the caption "Waiting for Google sign-in in your browser…" and a "Cancel" button beside the Add Account and Remove buttons.
- **cancel-sign-in**: The "Cancel" button MUST call the model's `cancelSignIn` and MUST NOT be disabled by the model's busy state.

### Selected-account controls

- **controls-follow-selection**: The per-account controls MUST appear only while the model has a selected account, and MUST act on that account.
- **reconnect-button**: The view MUST show a "Reconnect" button only when the selected account's status is revoked or error; it MUST call the model's `addAccount` and MUST be disabled while the model is busy.
- **sync-now-button**: The view MUST show a "Sync Now" button for every selected account that calls the model's `syncNow(accountId:)` and MUST be disabled while the model is busy.
- **show-error-button**: The view MUST show a "Show Error" button only when the selected account's status is error and its last error is present; it MUST call the model's `showError(accountId:)` and MUST NOT be disabled by the busy state.
- **sync-toggles**: The view MUST show three toggles, "Sync archived mail", "Sync junk mail" and "Sync deleted mail", bound to the account's `includeArchived`, `includeSpam` and `includeTrash` settings.
- **window-picker**: The view MUST show a "Fetch mail from the last" picker, no wider than 300 pt, whose fixed choices are 7, 14, 30, 90, 180 and 365 days, each labelled "<n> days".
- **poll-picker**: The view MUST show a "Check for mail every" picker, no wider than 300 pt, whose fixed choices are 5, 15, 30 and 60 minutes, each labelled "<n> minutes".
- **custom-value-preserved**: When an account's current window or poll value is not one of the fixed choices, the picker MUST add that value to its choices in ascending order so the current value stays selectable and displayed.
- **whole-settings-write**: A change to any toggle or picker MUST send the account's complete settings with only that field changed, through the model's `update(accountId:_:)`.
- **settings-stay-enabled**: The toggles and pickers MUST NOT be disabled while the model is busy, because the model coalesces rapid changes.

### Error presentation

- **error-as-alert**: When the model's `errorMessage` becomes non-nil, the view MUST present a warning alert titled "Gmail" with that message and an "OK" button, and MUST call the model's `dismissError` when the alert is closed.
- **account-error-as-alert**: When the model's `accountError` becomes non-nil, the view MUST present a warning alert titled "<email> couldn't sync" with the error's message and an "OK" button, and MUST call the model's `dismissAccountError` when the alert is closed.
- **alert-on-appear**: The view MUST present an alert for an error already set when the view first appears.
- **alert-sheet-or-modal**: The view MUST present an alert as a sheet on the key window when there is one, and otherwise as an application-modal alert, and in both cases MUST report the close to the model afterward.
- **no-inline-errors**: The view MUST NOT show error text inline in the pane; the only error text outside alerts is the account row's "Error" badge.

### Security

- **secret-entry-concealed**: The client secret entry field MUST conceal what is typed.
- **secret-masked-readout**: The view MUST display the stored client secret only as the model's `maskedClientSecret`, never in any other form.

## Appearance

- **Layout**: Vertical stack, leading-aligned, 12 pt between sections; Divider between OAuth Client and Accounts; trailing flexible space pushes content to the top.
- **Padding**: 20 pt on all edges.
- **Section headings**: System headline font ("OAuth Client", "Accounts").
- **OAuth section spacing**: 8 pt between items; the current-value grid uses 8 pt horizontal and 4 pt vertical spacing.
- **Current-value labels**: Secondary foreground style; values in the monospaced variant of the body font.
- **Client form**: Maximum width 460 pt.
- **Buttons**: Standard push buttons in horizontal rows; the word "or" between the save and import buttons uses the secondary foreground style.
- **Captions**: Caption font; hints use the secondary foreground style, while the sign-in progress text uses caption without secondary style.
- **Accounts section spacing**: 12 pt between items; per-account controls use 10 pt.
- **List**: Minimum height 120 pt; row content is a 2 pt vertical stack of an email-and-badge line over a secondary caption.
- **Status badge**: Caption font, 6 pt horizontal padding, quaternary-style capsule background. The badge carries only its text; there is no color-coded variant per status.
- **Sign-in progress**: Small-control-size spinner followed by caption text and a Cancel button.
- **Pickers**: Maximum width 300 pt.
- **Alerts**: Warning style, a single "OK" button.
- **Min/Max size**: The pane has no maximum; the account list has a 120 pt minimum height.

## States

| State | Appearance change |
|-------|------------------|
| Default | Both sections shown; controls enabled as the model allows. |
| Loading (before first load) | The OAuth text reads "Checking for an OAuth client…"; no current-value grid; accounts empty. |
| No client imported | Instructional OAuth text; button titles "Save Client" and "Import Client JSON…"; Add Account disabled; caption "Add the OAuth client above before adding an account." |
| Client imported | Explanatory OAuth text; current client ID and masked secret grid; button titles "Replace Client" and "Replace from JSON…"; Add Account enabled. |
| Client imported with accounts | As above plus the caption "Accounts signed in with a replaced client need Reconnect." |
| Busy | Save Client, Import, Add Account, Remove, Reconnect and Sync Now are disabled; toggles, pickers, Cancel and Show Error stay enabled. |
| Draft incomplete | Save Client disabled while either field is empty after trimming whitespace. |
| Signing in | Spinner, "Waiting for Google sign-in in your browser…" and Cancel appear beside Add Account and Remove. |
| No selected account | Remove disabled; per-account controls absent. |
| Account status active | Badge "Connected"; Sync Now only. |
| Account status pending | Badge "Pending"; Sync Now only. |
| Account status error | Badge "Error"; Reconnect and Sync Now; Show Error when the account has a last error. |
| Account status revoked | Badge "Reconnect needed"; Reconnect and Sync Now. |
| Never synced | Row caption "Never synced". |
| Synced | Row caption "Last synced <relative time>", for example "Last synced 2 hours ago". |
| Error alert showing | A warning alert, as a sheet on the key window when there is one. |

Not applicable: the view has no pressed, hover or focused styling of its own; those come from the standard controls it composes.

## Accessibility

- **native-controls**: The view MUST be built from standard text fields, a secure field, buttons, toggles, pickers, a list and a progress indicator so that the platform supplies their roles, keyboard handling and focus behavior.
- **control-labels**: Every toggle and picker MUST carry its visible title as its label, and every button MUST carry its visible title.
- **status-by-text**: Account status MUST be conveyed by the badge's text, never by color alone.
- **keyboard-reach**: Every control MUST be operable from the keyboard through the standard controls' own handling; the view MUST NOT add custom key handling that replaces it.
- **row-accessibility-label**: NEEDS REVIEW: Not implemented in source. The account row is a stack of three texts with no explicit accessibility label or grouping, so what a screen reader announces for a row is whatever the platform composes; a VoiceOver pass over the list would settle whether email, status and last-synced time read as one coherent item.
- **badge-contrast**: NEEDS REVIEW: Not implemented in source. The status badge is caption text on a quaternary-style capsule and the hint captions use the secondary style; the source cannot say whether these meet 4.5:1 contrast in every appearance, and a contrast measurement in light and dark appearances would settle it.
- **spinner-announcement**: The sign-in spinner and its caption SHOULD be exposed to assistive technology through the standard progress indicator and text; the view adds no explicit announcement beyond what those supply.

## Conformance Test Vectors

The model's tests are in `GmailSettingsModelTests` (`packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/Integrations/GmailSettingsModelTests.swift`). The view has no test beside it, so vectors marked "(view)" are derived from the view source; those naming a test assert the model behavior the view relies on. View-level tests are a known gap: tests should be added for `choices(_:including:)` (gmail-033, gmail-034), the busy gating of Save Client, Import, Add Account, Remove, Reconnect and Sync Now (gmail-006, gmail-019, gmail-024) and the alert wiring (gmail-035 to gmail-037).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gmail-001 | client-heading-and-text | Model before first load (test `oauthClientTextBeforeTheFirstLoad`) | Pane shows "Checking for an OAuth client…"; no current-value grid. |
| gmail-002 | client-heading-and-text, add-client-first-hint | Model loaded with an unconfigured provider (test `oauthClientTextWhenNoClientIsImported`) | Text begins "Enter the client ID and secret of your Google Cloud Desktop app OAuth client"; caption "Add the OAuth client above before adding an account." shown; Add Account disabled. |
| gmail-003 | current-client-readout, secret-masked-readout | Provider configured, client ID "id-9.apps.googleusercontent.com", secret suffix "12345" (test `theImportedClientIsShownWithTheSecretMasked`) | Grid shows the full ID and "••••••••••12345"; buttons read "Replace Client" and "Replace from JSON…". |
| gmail-004 | current-client-readout, secret-masked-readout | Provider configured with no secret suffix (test `aSecretTooShortToPartlyShowIsFullyHidden`) | Current secret row reads "Stored (hidden)". |
| gmail-005 | current-client-readout | Provider unconfigured (test `nothingIsShownWithoutAnImportedClient`) | No current-value grid. |
| gmail-006 | save-client-enablement | Client ID "id", secret "   " (test `anIncompleteClientFormSendsNothing`) | Save Client disabled; no import request is sent. |
| gmail-007 | save-client-button | ID "  id-1.apps.googleusercontent.com \n", secret " GOCSPX-secret " (test `savingTheClientFormSendsItAsInstalledJSONAndClearsTheFields`) | One import request with trimmed values; both fields empty afterward; no alert. |
| gmail-008 | save-client-button, error-as-alert | Service rejects the import with "bad client" (test `aRejectedClientKeepsTheFormFilled`) | Fields keep "id" and "secret"; an alert titled "Gmail" shows "bad client". |
| gmail-009 | import-json-call | Chosen file containing a client JSON (test `importFromURLSendsTheFileBytes`) | The file's bytes are sent unchanged; no error; client reported configured. |
| gmail-010 | import-json-call, error-as-alert | Chosen URL that does not exist (test `importFromMissingURLSetsErrorMessage`) | No import request; an alert titled "Gmail" shows the read failure. |
| gmail-011 | import-json-cancel | Open panel dismissed without a file (view) | No model call; no alert. |
| gmail-012 | import-json-panel | Press "Import Client JSON…" (view) | Modal open panel accepting only JSON, one file, no folders. |
| gmail-013 | reconnect-hint | Client imported, one account (view) | Caption "Accounts signed in with a replaced client need Reconnect." shown; absent when accounts is empty. |
| gmail-014 | account-row-content | Status values active, error, revoked, pending (test `statusText`) | Badges read "Connected", "Error", "Reconnect needed", "Pending". |
| gmail-015 | account-row-content | Last sync two hours before now, en_US (test `lastSyncedTextIsExactForAFixedDate`) | Caption "Last synced 2 hours ago". |
| gmail-016 | account-row-content | No last sync, or unparseable text "garbage" (same test) | Caption "Never synced". |
| gmail-017 | account-list, controls-follow-selection | Loaded accounts, no prior selection (test `reloadLoadsProviderAndAccounts`) | List shows the account; first account selected; per-account controls visible. |
| gmail-018 | add-account-button | Press "Add Account…" with a client imported (test `addAccountSendsSignInThenReloads`) | Sign-in request sent, then accounts reloaded. |
| gmail-019 | add-account-button | Model busy, or no client imported (view) | Button disabled. |
| gmail-020 | sign-in-progress, cancel-sign-in | Sign-in pending (test `cancelSignInSendsCancelWhileSigningIn`) | Spinner, waiting caption and Cancel visible; pressing Cancel sends cancel-sign-in even though busy is true; `signingIn` false after the sign-in call ends. |
| gmail-021 | remove-confirmation, remove-safe-default | Press "Remove" with "a@x.com" selected (view) | Confirmation titled "Remove a@x.com?" with the stated detail, Cancel default, action "Remove". |
| gmail-022 | remove-call | Confirm removal (test `removeSendsRemoveAccount`) | Remove-account request for that account's ID. |
| gmail-023 | remove-call | Decline removal, press Esc, or press Remove with no key window (view; the confirmation helper answers no without a window) | No model call. |
| gmail-024 | remove-button | No account selected, or model busy (view) | Remove disabled. |
| gmail-025 | sync-now-button | Press "Sync Now" (test `syncNowSendsSyncNow`) | Sync-now request for the selected account. |
| gmail-026 | reconnect-button | Selected account status revoked or error (view) | "Reconnect" shown; pressing it calls addAccount. |
| gmail-027 | reconnect-button | Selected account status active or pending (view) | "Reconnect" absent. |
| gmail-028 | show-error-button, account-error-as-alert | Account in error with a last error, press "Show Error" (view, model `showError`) | Alert titled "<email> couldn't sync" with the error message. |
| gmail-029 | show-error-button | Account in error with no last error (view) | "Show Error" absent. |
| gmail-030 | whole-settings-write | Toggle "Sync junk mail" on and set window to 90 (test `updateSendsSettings`) | Update request carries the whole settings with `includeSpam` true and `windowDays` 90; account shows them. |
| gmail-031 | whole-settings-write, error-as-alert | Update rejected with "nope" (test `updateFailureRestoresServerStateAndSetsError`) | Alert titled "Gmail" shows "nope"; account settings revert to the server's. |
| gmail-032 | settings-stay-enabled | Changes made while a settings send is in flight (tests `rapidUpdatesCoalesceToTheLatestSettings`, `aReloadDuringASettingsSendKeepsShowingTheChosenValue`) | Controls show the chosen value at once; only the first and the latest values are sent. |
| gmail-033 | window-picker, poll-picker | Account with window 30 days and poll 15 minutes (view) | Window picker lists 7, 14, 30, 90, 180, 365 days; poll picker lists 5, 15, 30, 60 minutes. |
| gmail-034 | custom-value-preserved | Account with window 45 days (view) | Window picker lists 7, 14, 30, 45, 90, 180, 365 days with 45 selected. |
| gmail-035 | error-as-alert | Sign-in fails with "sign-in cancelled" (test `remoteFailureSetsErrorMessage`) | Warning alert titled "Gmail" with that message; closing it calls `dismissError`, leaving `errorMessage` nil (test `dismissErrorClearsIt`). |
| gmail-036 | alert-on-appear | Model already holds an error message when the view appears (view) | Alert shown immediately. |
| gmail-037 | alert-sheet-or-modal | No key window when an error arrives (view) | Application-modal alert; `dismissError` called after it closes. |
| gmail-038 | secret-entry-concealed | Type into "Client secret" (view) | Characters are concealed. |
| gmail-039 | no-self-loading | View created over a fresh model (view) | No service request is made by the view itself. |

## Edge Cases

- **Empty accounts list**: MUST show an empty list with Remove disabled and no per-account controls; the model clears `selectedAccountId` when the selected account disappears (test `removeIntegrationClearsAccounts`).
- **Selection points at a vanished account**: MUST show no per-account controls, because they appear only for the model's `selectedAccount`; the model reselects the first account after the next reload.
- **Custom setting value**: MUST keep a window or poll value outside the fixed choices selectable by adding it to the list in ascending order (`choices(_:including:)`).
- **Whitespace-only draft fields**: MUST leave Save Client disabled, because the model trims before checking (test `anIncompleteClientFormSendsNothing`).
- **Secret too short to show a suffix**: MUST show "Stored (hidden)" instead of dots (test `aSecretTooShortToPartlyShowIsFullyHidden`).
- **Unparseable last-sync text**: MUST show "Never synced" (test `lastSyncedTextIsExactForAFixedDate`).
- **Boundary values of settings**: window choices span 7 to 365 days and poll choices 5 to 60 minutes; the view enforces no bound beyond them and shows a stored out-of-range value as a custom choice.
- **Concurrent access**: rapid toggle or picker changes MUST NOT queue one request each; the model sends the first and then only the latest (test `rapidUpdatesCoalesceToTheLatestSettings`). The view is main-actor bound and is safe to use only from the main thread.
- **Overlapping calls**: busy MUST stay true until every in-flight call finishes (tests `busyStaysTrueUntilOverlappingCallsBothFinish`, `busyIsNotClearedByTheFirstOfTwoOverlappingCalls`), so busy-gated buttons stay disabled until the last call ends.
- **Account error alerts**: MUST NOT alert again for an account error already alerted until the account leaves the error state or its error message changes; the model raises the next unseen account error only after `dismissAccountError`, and "Show Error" re-presents it on request. Whether an ordinary error alert and an account-error alert arriving together queue cleanly on one window is decided by the platform, not by the source.
- **No key window**: an error alert MUST fall back to an application-modal alert and call the close handler after it returns; the removal confirmation has no such fallback, because the shared confirmation helper answers no when given no window, so Remove then does nothing.
- **Service unavailable or call fails**: the model turns every failure into `errorMessage`, which the view shows as an alert titled "Gmail"; the view has no retry control other than pressing the same button again, and no timeout or backoff of its own.
- **Offline or disconnected**: a failed reload surfaces as the same alert and the view keeps showing the last known accounts; a pending sign-in waits on the browser until the user completes or cancels it.
- **Reconnect**: Reconnect is the Add Account flow; the service matches the account by email and reuses it (model comment on `addAccount`).
- **Sign-in cancelled**: the sign-in call fails with "Sign-in was cancelled" (model comment on `cancelSignIn`), which then appears as an alert.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| model | GmailSettingsModel | none (required) | The observed model the view reads and calls. |
| pollChoices | list of minutes | 5, 15, 30, 60 | Fixed choices for "Check for mail every". |
| windowChoices | list of days | 7, 14, 30, 90, 180, 365 | Fixed choices for "Fetch mail from the last"; fixed windows rather than a stepper because "each change re-syncs, so a day at a time is costly". |
| client form maximum width | points | 460 | Width limit of the ID and secret fields. |
| picker maximum width | points | 300 | Width limit of both pickers. |
| list minimum height | points | 120 | Minimum height of the account list. |
| content inset | points | 20 | Padding around the pane. |

## Deep Linking

Not applicable: the view is a pane inside a settings window and registers no destination of its own. The browser return after Google sign-in is handled by the model's `GmailSignInTracker` and its owner, not by this view.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (literal) | OAuth Client | Section heading |
| (literal) | Current client ID / Current secret | Grid labels |
| (literal) | Client ID / Client secret | Field labels |
| (literal) | ….apps.googleusercontent.com | Client ID prompt |
| (literal) | Save Client / Replace Client | Save button |
| (literal) | Import Client JSON… / Replace from JSON… | Import button |
| (literal) | or | Between buttons |
| (literal) | Accounts signed in with a replaced client need Reconnect. | Hint caption |
| (literal) | Accounts | Section heading |
| (literal) | Add the OAuth client above before adding an account. | Hint caption |
| (literal) | Add Account… / Remove / Cancel / Reconnect / Sync Now / Show Error | Buttons |
| (literal) | Waiting for Google sign-in in your browser… | Sign-in progress |
| (literal) | Sync archived mail / Sync junk mail / Sync deleted mail | Toggles |
| (literal) | Fetch mail from the last / Check for mail every | Picker labels |
| (literal) | n days / n minutes | Picker choices |
| (literal) | Gmail / email couldn't sync / OK | Alert title and button |
| (literal) | Remove email? / This signs the account out of Google, removes its stored sign-in and deletes its mail from this Mac. / Remove | Removal confirmation |

The source has no string catalog or externalization step; strings are literals in the view and the model, and the relative-time text is the only part formatted for the current locale (a relative date formatter with the current locale). The picker labels "n days" and "n minutes" use no plural rules, so a stored value of 1 would read "1 days".

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the view defines no animation or transition; the only moving element is the standard progress spinner. |
| Increase Contrast | Not applicable: the view sets no custom colors; it uses semantic foreground and background styles that follow the system setting. |
| Differentiate Without Color | Account status is a text badge ("Connected", "Error", "Reconnect needed", "Pending"), so no state depends on color alone. |

## Feature Flags

Not applicable: the view has no conditional enablement of its own; the only gates are model state (client imported, busy, signing in, selection).

## Analytics

Not applicable: the view emits no events and calls no analytics API.

## Privacy

- **Data collected**: The client ID and client secret typed into the form (held in the model's draft fields), and the JSON file chosen by the user. The view displays account emails and sync times.
- **Storage**: The view stores nothing. Drafts live in the model until saved; they are cleared after a successful save and kept after a failure. The service stores the client secret, and the model's `maskedClientSecret` comment states "The daemon sends only those characters", the last five, so the full secret is never returned to the view.
- **Transmission**: Client values and file bytes go to the mail service through the model; the view makes no network call. Removing an account signs it out of Google and deletes its mail from this Mac, as the confirmation text states.
- **Retention**: Not governed by the view. Account mail is fetched for the chosen window (7 to 365 days by default choices) and deleted from this Mac when the account is removed.

## Logging

Not applicable: the view writes no log output and has no logging subsystem; errors reach the user as alerts.

## Platform Notes

- **SwiftUI**: This is the source platform. The view is `GmailSettingsView` in `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/GmailSettingsView.swift`, observing `GmailSettingsModel` from the sibling `GmailSettingsModel.swift`. It uses `Grid`, `Form`, `TextField` with a prompt, `SecureField`, `List` with a selection binding, `Toggle`, `Picker`, `ProgressView` and a `Capsule` background. A generic `binding(_:_:)` helper turns a writable key path of the account's settings into a binding whose setter sends the whole settings, and `.onChange` with `initial: true` raises alerts for errors already set. The account removal confirmation uses the shared `ComposableSettings.Alerts.confirmDestructive` helper.
- **Compose**: Start from a screen composable that collects the model state as a state flow. Use `OutlinedTextField` with a `PasswordVisualTransformation` for the secret, `LazyColumn` with selectable rows for accounts, `Switch` rows for the three toggles, and `ExposedDropdownMenuBox` for the pickers. Errors map to an `AlertDialog` driven by the model's error state. The destructive confirmation maps to an `AlertDialog` whose dismiss button is the default focus. There is no open-panel API; use the document picker contract restricted to the JSON media type.
- **React/Web**: Compose a settings panel from labelled inputs (`type="password"` for the secret), a listbox or table with `aria-selected` rows for accounts, checkboxes or switches for toggles and `select` elements for the pickers. Use the native `dialog` element (or a modal component) for the two alert kinds, with Cancel focused first in the removal dialog, and a file input with `accept=".json"` for the import. Relative time is available from `Intl.RelativeTimeFormat`.
- **AppKit / UIKit**: On AppKit, the same layout is a vertical `NSStackView` with `NSTextField` and `NSSecureTextField`, an `NSTableView` for accounts, `NSButton` checkboxes and `NSPopUpButton` pickers; the view already calls `NSOpenPanel` and `NSAlert` directly (`beginSheetModal` on the key window, `runModal` otherwise). On UIKit, use a `UITableView` or `UICollectionView` list, `UISwitch` and `UIMenu`-backed buttons for pickers, `UIAlertController` for both alert kinds with the destructive style on "Remove" and Cancel as the preferred action, and `UIDocumentPickerViewController` for JSON.
- **WinUI 3**: Build a `Page` or `UserControl` with a `StackPanel` (`Spacing="12"`, `Padding="20"`) holding two sections separated by a thin `Rectangle` divider. For the OAuth section use a `TextBlock` with `Style` set to `SubtitleTextBlockStyle` for the heading, a `TextBlock` with `TextWrapping="Wrap"` bound to the model text, a two-column `Grid` for the current values (`IsTextSelectionEnabled="True"` on the client ID only, `FontFamily="Consolas"` on both), a `TextBox` with `PlaceholderText` for the client ID and a `PasswordBox` for the secret (`MaxWidth="460"`), and buttons in a horizontal `StackPanel`; bind `IsEnabled` to the inverse of `Busy` and to `CanSaveClientDraft`. Import with a `FileOpenPicker` filtered to `.json` and initialized with the window handle through `WinRT.Interop.InitializeWithWindow`. For accounts use a `ListView` with `SelectionMode="Single"` and `SelectedItem` two-way bound to the selected account and `MinHeight="120"`. Its `DataTemplate` is a `StackPanel` with the email, a `Border` (`CornerRadius="10"`, `Padding="6,0"`, `Background` from `ControlFillColorSecondaryBrush`) around the status `TextBlock` using `CaptionTextBlockStyle`, and a secondary caption using `TextFillColorSecondaryBrush`. For the sign-in state show a small `ProgressRing` and caption with `Visibility` bound to `SigningIn`, and leave its Cancel button enabled. Per-account toggles are `ToggleSwitch` controls with `Header` set to the title, and the pickers are `ComboBox` controls with `Header` and `MaxWidth="300"` whose `ItemsSource` is rebuilt to include a current custom value. Show errors with a `ContentDialog` (title, `CloseButtonText="OK"`, `XamlRoot` set from the page), and the removal confirmation with a `ContentDialog` whose `PrimaryButtonText="Remove"`, `CloseButtonText="Cancel"` and `DefaultButton="Close"` make Cancel the Enter response; Esc closes a `ContentDialog` as Cancel. Only one `ContentDialog` can be open per `XamlRoot` at a time, so queue them as the model already serializes account errors. Set `AutomationProperties.Name` on each row to compose email, status and last-synced text so Narrator reads one item, a point the source leaves open.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/GmailSettingsView.swift` | unverified |
| ios | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The view calls only the model and renders only model state.
**Rationale**: The model is "the tested unit"; keeping the view thin leaves all behavior in one place that tests cover and makes the view replaceable on another platform.
**Approved**: pending

**Decision**: Errors, including per-account sync errors, are shown as alerts, not inline text.
**Rationale**: Alerts interrupt until acknowledged, so a failure cannot be missed in a pane that otherwise has no place for it. The account row carries only the "Error" badge, and "Show Error" re-raises the alert on request.
**Approved**: pending

**Decision**: The fetch window offers fixed choices (7, 14, 30, 90, 180, 365 days) rather than a stepper, and the picker adds the account's current value when it is custom.
**Rationale**: Each change to the window triggers a re-sync, so stepping a day at a time would be costly. Adding the current value stops a stored custom setting from being silently replaced or shown blank.
**Approved**: pending

**Decision**: Toggles and pickers stay enabled while the model is busy.
**Rationale**: The model applies a change locally at once and coalesces rapid changes into the latest send, so a disabled control would only get in the way. The busy gate applies to actions, not to settings.
**Approved**: pending

**Decision**: A change sends the account's whole settings with one field changed.
**Rationale**: The service receives a complete settings value each time, so receives a complete settings value each time and partial writes need no merging.
**Approved**: pending

**Decision**: Account removal asks for confirmation with Cancel as the default and Esc declining.
**Rationale**: Removal signs the account out, removes the stored sign-in and deletes its mail from the Mac; the shared destructive-confirmation helper supplies the safe default.
**Approved**: pending

**Decision**: Reconnect reuses the Add Account flow.
**Rationale**: The service matches the account by email and reuses it, so no separate reconnect call exists.
**Approved**: pending

**Decision**: The Cancel button for sign-in is not disabled while the model is busy.
**Rationale**: Sign-in is itself a call in flight, so the model is busy for the whole wait; gating Cancel on busy would make the sign-in impossible to cancel.
**Approved**: pending

**Decision**: The client secret is shown only as ten fixed dots plus the last five characters, or "Stored (hidden)" when no suffix is available.
**Rationale**: The daemon sends only those characters, and the mask has a fixed length so it does not reveal the secret's length.
**Approved**: pending

**Decision**: Strings are literals with no localization layer, and picker labels do not pluralize. This is acknowledged debt (it is why no-hardcoded-strings fails), not a goal.
**Rationale**: The macOS source ships English literals. No fixed choice is 1, so "1 days" could appear only for a stored custom value. A port SHOULD use localized, pluralized labels from the start; the debt is repaid on macOS when the settings surface adopts a string catalog.
**Approved**: pending

**Decision**: The reconnect hint appears whenever a client is imported and any account exists, not only after a client was replaced.
**Rationale**: The view reads only the model, and the model exposes no "client replaced since sign-in" state, so the view cannot tell. A short always-on caption costs little and warns before a replacement, which is when it matters.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |

The view passes separation-of-concerns because it only reads and calls the model and keeps its own logic to presentation: alerts, panels and picker choices. Unit-test-coverage is partial: the model has a thorough test file, including the text the view displays and the coalescing the view relies on, but the view has no test, so the choices helper, the button gating and the alert wiring are verified only by reading the source. Explicit-error-handling passes because every model failure becomes an alert and nothing is swallowed in the view. Screen-reader-support is partial: standard controls supply roles and titles, but the account row has no explicit label, and the open question on `row-accessibility-label` remains. No-hardcoded-strings fails because every string is a literal. Native-controls-preference passes because the view uses only standard controls and system panels.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
