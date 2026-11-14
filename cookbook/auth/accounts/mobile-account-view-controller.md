---
id: f46b9323-7954-4f66-a476-970fcc9db372
title: "MobileAccountViewController"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "iOS grouped-table screen for one account's sign-in: who is signed in or Login and Signup rows, Logout, and a spinner row while busy."
platforms:
  - swift
  - ios
tags:
  - accounts
  - ui
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# MobileAccountViewController

## Overview

MobileAccountViewController is the iOS twin of the macOS account detail panel. It shows one account's sign-in as a single-section inset-grouped table. While signed in it shows who is signed in and a Logout row. While signed out it shows a Login row and, when the account has a signup URL, a Signup row. While the stored login is being checked, or the account is busy, it shows a spinner row.

What is visible comes from `AccountDisplay`, the platform-free rules shared with the macOS panel. The controller keeps no copy of the account's state beyond the last `AccountDisplay` and the rows derived from it. It is the account's one observer and asks the account to restore its stored login when the view first loads.

## Behavioral Requirements

- **title-from-account**: The screen MUST set its title to the account's display name when it is created.
- **grouped-single-section**: The screen MUST present one section in the inset-grouped table style.
- **observe-account**: The screen MUST set the account's change callback when its view loads, replacing any earlier observer, and MUST re-render on every callback.
- **restore-on-load**: The screen MUST call the account's restore operation once when its view loads, after the first render.
- **render-from-display**: On every render the screen MUST recompute its display from the account's current state, message and signup URL, passing the previously shown user as the last user.
- **no-reload-before-load**: Rendering before the view is loaded MUST recompute the display and rows without reloading the table.
- **reload-after-load**: Rendering after the view is loaded MUST reload the table data.
- **row-order**: The rows MUST appear in this order, each only when the display calls for it: user, status, Login, Signup, Logout.
- **user-row**: When the display has a shown user, the screen MUST show a row with the user's name as the primary text, the user's email as the secondary text in the secondary label color, and a filled person-circle symbol image.
- **status-row-spinner**: When the display shows a spinner, the screen MUST show a status row with an animating medium activity indicator as its accessory.
- **status-row-text**: The status row MUST read "Checking sign-in…" while the display shows status text, and "Working…" otherwise.
- **status-row-color**: The status row text MUST use the secondary label color.
- **login-row**: When the display shows Login, the screen MUST show a row titled "Login" in the tint color.
- **signup-row**: When the display shows Signup, the screen MUST show a row titled "Signup" in the tint color.
- **logout-row**: When the display shows Logout, the screen MUST show a row titled "Logout" in the system red color.
- **disabled-action-color**: While controls are disabled, Login, Signup and Logout rows MUST use the tertiary label color instead of their normal color.
- **highlight-gating**: A row MUST highlight on touch only when controls are enabled and the row is Login, Signup or Logout.
- **select-gating**: Selecting a row MUST do nothing while controls are disabled.
- **deselect-on-select**: Selecting any row MUST deselect it with animation before any action runs.
- **login-action**: Selecting Login MUST ask the account to present its sign-in UI, anchored on this screen.
- **signup-action**: Selecting Signup MUST hand the account's signup URL to the injected open-URL closure.
- **signup-no-url**: Signup MUST NOT call the open-URL closure when the account has no signup URL.
- **logout-action**: Selecting Logout MUST start the account's asynchronous sign-out in a task.
- **inert-rows**: Selecting the user row or the status row MUST do nothing.
- **message-footer**: When the display has a message, the section footer MUST be that message, whether or not a user is shown.
- **summary-footer**: When there is no message, no shown user, and the account's summary is not empty, the section footer MUST be the account's summary.
- **no-footer**: In every other case the section footer MUST be absent.
- **open-url-injection**: The screen SHOULD accept an open-URL closure at creation so tests and hosts can intercept the signup page; the default MUST hand the URL to the system.
- **selection-style**: Rows MUST use no selection style except Login, Signup and Logout, which use the default selection style.
- **accessibility-identifiers**: The table and each row type MUST carry the identifiers listed under Accessibility.
- **no-coder-init**: Creating the screen from a decoder MUST be unavailable and, if called, MUST terminate with the message "init(coder:) is not supported".
- **main-actor**: The screen MUST be confined to the main actor.

## Appearance

- **Corner radius**: Not specified in source; the inset-grouped table style supplies the platform's rounded section.
- **Padding**: Not specified in source; the default list cell content configuration supplies it.
- **Font**: Not specified in source; the default list content configuration text styles are used.
- **Background**: The inset-grouped table's default background; cells use the default cell background.
- **Foreground/Text**: User secondary text in the secondary label color; status text in the secondary label color; Login and Signup in the tint color; Logout in the system red color; disabled actions in the tertiary label color.
- **Border**: None specified in source.
- **Shadow**: None specified in source.
- **Min/Max size**: None specified in source; cells use the subtitle style and size to their content.

Row content:

- User row: leading image is the filled person-circle system symbol; name above, email below.
- Status row: text with a medium activity indicator as the trailing accessory view.
- Action rows: a single line of text.

## States

| State | Appearance change |
|-------|------------------|
| Default | Signed out: Login row, plus Signup row when the account has a signup URL; the footer shows the account's summary when it is not empty. |
| Pressed | Login, Signup and Logout rows highlight with the default selection style while controls are enabled; the user and status rows never highlight. |
| Disabled | While the account is busy, Login, Signup and Logout stay visible in the tertiary label color, do not highlight, and ignore selection. |
| Focused | Not applicable: the source defines no focus state of its own; the rows have no focus styling beyond the table's defaults. |
| Loading | While the stored login is checked: one status row reading "Checking sign-in…" with a spinner, and no action rows. While busy: a status row reading "Working…" with a spinner; a signed-in user row and Logout stay visible when a user was shown before the busy state began; Login and Signup stay visible when none was. |

Signed in: user row and Logout row, with no summary footer. An account message replaces the footer in every state.

## Accessibility

- **table-identifier**: The table carries the identifier `accounts.detail`.
- **user-row-identifier**: The user row carries `accounts.detail.user`.
- **spinner-row-identifier**: The status row carries `accounts.detail.spinner`.
- **login-row-identifier**: The Login row carries `accounts.detail.login`.
- **signup-row-identifier**: The Signup row carries `accounts.detail.signup`.
- **logout-row-identifier**: The Logout row carries `accounts.detail.logout`.
- **traits-and-labels**: NEEDS REVIEW: Not implemented in source. Behavior undefined. The source sets no accessibility labels, traits or hints; action rows read as plain table cells and a disabled action is distinguished only by color and by being unhighlightable. A review of VoiceOver output for a disabled action row would settle whether a not-enabled trait is needed.
- **dynamic-type**: The screen MUST leave text sizing to the default list content configuration. It sets no font or text-style override, so the system text styles apply and scale with the user's text size setting.
- **differentiate-without-color**: NEEDS REVIEW: Not implemented in source. Behavior undefined. Disabled actions differ from enabled ones only by text color; evidence from an increase-contrast and color-differentiation review would settle whether a second cue is needed.
- Minimum tap target: the rows use the table's default row height; the source sets no explicit target size.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mobile-account-001 | title-from-account, restore-on-load, status-row-text | Account named "Stub Hub" in the restoring state; load the view (test `loading_restoresTheAccount_andShowsTheCheckingRow`) | Restore count is 1; rows are one status row with text "Checking sign-in…"; title is "Stub Hub" |
| mobile-account-002 | row-order, login-row, signup-row, summary-footer | Signed-out account with a signup URL and summary "Sign in to the stub." (test `signedOut_showsLoginAndSignup_withTheSummaryAsFooter`) | Rows are Login then Signup; footer is "Sign in to the stub." |
| mobile-account-003 | user-row, logout-row, no-footer | Account becomes signed in as Ada (test `signedIn_showsTheUserAndLogout`) | Rows are the user row then Logout; footer is absent |
| mobile-account-004 | status-row-spinner, status-row-text, disabled-action-color, highlight-gating | Signed in, then busy (test `busyWhileSignedIn_keepsTheUser_andAddsASpinner`) | Rows are the user row, a status row with no custom text (shown as "Working…"), then Logout; controls are disabled (the test asserts only this); by the source, Logout is not highlightable |
| mobile-account-005 | message-footer | Account message "The hub turned the login down." and signed-out state (test `aMessage_replacesTheFooter`) | Footer is "The hub turned the login down." instead of the summary |
| mobile-account-006 | login-action, signup-action | Call login and signup with an open-URL closure that records its argument (test `login_presentsTheAccountsSignIn_andSignupOpensItsURL`) | Sign-in presentation count is 1; the recorded URL equals the account's signup URL |
| mobile-account-007 | signup-no-url, row-order | Signed-out account whose signup URL is nil | Rows are Login only; calling signup does not invoke the open-URL closure |
| mobile-account-008 | select-gating, highlight-gating | Busy account with no earlier user; select the Login row | No sign-in is presented; the row does not highlight |
| mobile-account-009 | inert-rows | Signed-in account; select the user row | No account action runs and the row is deselected |
| mobile-account-010 | logout-action | Signed-in account; select Logout | The account's sign-out runs; the account moves to signed out and rows become Login and Signup |
| mobile-account-011 | observe-account, no-reload-before-load | Create the controller and change the account state before loading the view | The account's callback is not yet set, so nothing re-renders; loading the view renders the current state once |
| mobile-account-012 | no-coder-init | Create the screen from a decoder | Creation is unavailable at compile time; if forced at run time the process terminates with "init(coder:) is not supported" |

## Edge Cases

- **Empty summary** (MUST): With no message and no shown user, an empty account summary gives no footer, not an empty one.
- **Message with a user** (MUST): A message replaces the footer even while a user is shown.
- **No signup URL** (MUST): Signup is hidden and the signup action does nothing.
- **Busy after signed in** (MUST): The last shown user stays on screen with controls disabled, so signing out does not flash the signed-out rows.
- **Busy from signed out** (MUST): Login and Signup stay visible but disabled.
- **Signed out clears the last user** (MUST): After the account returns to signed out, the previous user is no longer shown.
- **Second observer** (MUST): If another party sets the account's change callback, this screen stops receiving changes; the account holds a single slot.
- **Render before view load** (MUST): Rows are computed but the table is not reloaded until the view loads.
- **Sign-out failure**: The sign-out task discards any result. Any error is only visible through the account's message and state; the screen does nothing else with it.
- **Concurrent access**: The screen is main-actor confined; render, selection handlers and the account's callback all run on the main actor, and the sign-out task starts from the selection handler.
- **Offline or disconnected**: Not applicable: the screen performs no network calls itself; connectivity is the account's concern and reaches the screen only as account state and message.
- **Boundary values**: Not applicable: the screen has no numeric or size inputs; row count is at most three, because the user row never appears with Login or Signup.
- **Weakly held anchor**: The sign-in anchor wraps this screen weakly; if the screen is gone before the account uses it, the anchor holds nothing.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| account | `any Account` | required | The account shown; its display name becomes the title. |
| openURL | main-actor closure taking a URL | hands the URL to the system | Opens the signup page. |

## Deep Linking

Not applicable: the screen defines no URL scheme or route. It opens the account's signup URL outward only.

## Localization

Not applicable in source: the strings are literals, not localized keys. The table lists the literals as they are.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (literal) | Login | Login row title |
| (literal) | Signup | Signup row title |
| (literal) | Logout | Logout row title |
| (literal) | Working… | Status row text while busy |
| `AccountDisplay.restoringText` | Checking sign-in… | Status row text while the stored login is checked |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the screen defines no animation of its own other than the system's row deselect and the activity indicator. |
| Increase Contrast | Not applicable: the source uses semantic system colors only and adds no contrast handling. |
| Differentiate Without Color | The open question on `differentiate-without-color` covers this. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics events.

## Privacy

- **Data collected**: None by the screen itself; it displays the signed-in user's name and email supplied by the account.
- **Storage**: None; the screen keeps only the last display and rows in memory.
- **Transmission**: None by the screen; sign-in and sign-out are delegated to the account and the signup URL is opened outside the app.
- **Retention**: None; state lives only as long as the screen.

## Logging

Not applicable: the source logs nothing.

## Platform Notes

- **SwiftUI**: Start from a `List` with the inset-grouped style and a `Section` whose footer shows the message or summary. Drive it from an observable model wrapping the account; rows become `Button` views, disabled with the `disabled` modifier, and the signup row uses `openURL` from the environment. Unlike the source, SwiftUI re-renders from observed state, so there is no manual render and reload step.
- **Compose**: Use a `LazyColumn` of list items inside a card-like container, with the footer as a trailing supporting-text item. Model the display as a state holder; action rows are `ListItem`s with `clickable(enabled = ...)`, and the status row uses a `CircularProgressIndicator` trailing content. Material 3 has no inset-grouped style; use a rounded surface.
- **React/Web**: Use a `ul` or `div` with `role="list"`, buttons for the action rows with the `disabled` attribute, an element with `role="status"` for the spinner row, and a paragraph below the list for the footer. Follow WCAG 2.1 for contrast and target size.
- **AppKit / UIKit**: Source platform. The code lives in `MobileAccountViewController.swift`, a `UITableViewController` subclass with the inset-grouped style. Rows are built per call with the subtitle cell style and the list content configuration, not reused. Display rules come from `AccountDisplay` in the shared SDK tier; the macOS panel `AccountDetailPanelViewController` draws the same rules with AppKit controls. The sign-in anchor is `AccountPresentationAnchor`.
- **WinUI 3**: Start from a `ListView` (single section) in a `Page`, with `SelectionMode="None"` and `IsItemClickEnabled="True"`. Use a `DataTemplateSelector` keyed on the row kind: a user template with `PersonPicture`, name and email; a status template with a `ProgressRing` (`IsActive="True"`) and text; action templates as `Button` or `HyperlinkButton` with `IsEnabled` bound to controls-enabled, which gives the Disabled visual state for free (use the `TextFillColorDisabledBrush` theme resource instead of a tertiary color). Show the footer in a `TextBlock` below the list using `TextFillColorSecondaryBrush`. Set `AutomationProperties.AutomationId` to the identifiers listed under Accessibility. Open the signup URL with `Launcher.LaunchUriAsync`. Because WinUI binds to properties, an `INotifyPropertyChanged` view model replaces the manual render and reload pair; keep the visibility rules in the shared display type, not in XAML triggers.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| ios | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/iOS/Accounts/MobileAccountViewController.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The screen keeps no account state of its own and derives all visibility from `AccountDisplay`.
**Rationale**: The macOS and iOS panels must follow the same rules; the source states "nothing here keeps a copy of the account's state". The only carried value is the last shown user, kept so a busy sign-out still shows who is signing out.
**Approved**: pending

**Decision**: The screen sets the account's single change slot in view load and replaces any earlier observer.
**Rationale**: The `Account` contract says the accounts UI that shows the account is its one observer. Rendering before load only updates rows because no callback is set until then.
**Approved**: pending

**Decision**: Restore is called after the first render in view load.
**Rationale**: The `Account` contract says the accounts UI calls restore when it first shows the account, so an app pays for the stored-login check only when someone looks.
**Approved**: pending

**Decision**: Disabled actions stay visible in the tertiary label color and ignore touches, instead of being hidden.
**Rationale**: The display's `controlsEnabled` is false while busy; hiding the rows would make the screen jump when sign-in or sign-out starts.
**Approved**: pending

**Decision**: An account message replaces the summary footer in every state, including while signed in.
**Rationale**: The source comment states the message (an error) replaces the summary whenever there is one, so an error is never hidden behind explanatory text.
**Approved**: pending

**Decision**: Row strings are literals, not localized resources, and the status literal "Working…" lives in the screen while "Checking sign-in…" lives in `AccountDisplay`.
**Rationale**: Technical debt noted for fidelity: the source has no localization layer, so implementers on other platforms must add their own.
**Approved**: pending

**Decision**: The open-URL closure SHOULD be injectable.
**Rationale**: It lets tests record the signup URL without launching the system; a host may deviate by hard-wiring the system opener, at the cost of testability.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |

The screen separates concerns well: visibility rules sit in the shared `AccountDisplay` and the account performs sign-in, restore and sign-out, so the controller only maps display to rows and forwards taps. Unit coverage is partial: the tests cover restoring, signed out, signed in, busy, message footer and the login and signup actions, but not the disabled-control gating, the missing signup URL, or Logout selection. The screen uses a native table, list content configuration, activity indicator and system colors. Visible strings are hardcoded literals, so the no-hardcoded-strings check fails. Screen reader support is partial: stable accessibility identifiers exist, but no labels or traits are set beyond the system defaults.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
