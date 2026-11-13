---
id: 1c826ac4-20e0-4089-870f-5d1fd4b59983
title: "IntegrationsSettingsPanel"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Integrations settings panel: a sidebar of added integrations (today only Gmail) beside the selected one's detail, with add and confirmed-remove controls."
platforms:
  - swift
  - macos
tags:
  - integrations
  - settings
  - gmail
  - sidebar
  - split-view
depends-on: []
related:
  - 2fa64944-9744-4d71-8fed-f785e7ce1e51
  - 4f066e76-2eca-4cd7-8b73-840178e4edf3
  - a1d787e2-2e3f-4742-a30b-120a8607c518
  - 0fc99299-f3ba-4883-ab08-9bd614da7900
  - ba8d9517-2528-4ae9-bc52-16046d68b126
references: []
approved-by: ""
approved-date: ""
---

# IntegrationsSettingsPanel

## Overview

`IntegrationsSettingsPanel` is the "Integrations" pane of the settings window. It is a split view: a sidebar lists the integrations added so far, and the detail shows the selected one. Today the only integration is Gmail, whose detail is the Gmail settings view driven by a Gmail settings model that the panel creates from the mail client it is given.

A footer under the sidebar holds a `+` button, which offers the integrations that can be added, and a `−` button, which removes the selected integration after a confirmation. Nothing is listed until Gmail is configured on the service or the user picks it from `+`.

The panel also contributes help topics and search keywords to the settings window, and exposes two members for the landing that follows a browser sign-in: whether this panel started the latest sign-in, and a call that reloads the accounts.

## Behavioral Requirements

- **panel-identity**: The panel MUST describe itself to the settings window with the title "Integrations" and the `puzzlepiece.extension` symbol as its icon.
- **sidebar-title**: The panel MUST set the sidebar title to "Integrations".
- **help-topics**: The panel MUST supply exactly two help topics, "Integrations" and "Gmail".
- **help-integrations-body**: The "Integrations" help topic body MUST be the exact Integrations help body string in the Localization table.
- **help-gmail-body**: The "Gmail" help topic body MUST be the exact Gmail help body string in the Localization table.
- **search-keywords**: The panel MUST contribute the search keywords "integrations", "gmail", "mail", "email", "google", "oauth", "account" and "sync".
- **gmail-detail-keywords**: The Gmail detail MUST contribute the search keywords "gmail", "mail", "email", "google", "oauth", "account" and "sync", without "integrations".
- **gmail-row**: The Gmail detail MUST describe itself with the title "Gmail" and the `envelope` symbol, and that title MUST be the sidebar row label.
- **model-from-client**: The panel MUST create its Gmail settings model ([Gmail settings model](cookbook:2fa64944-9744-4d71-8fed-f785e7ce1e51)) from the mail client and the sign-in tracker given to its initializer, and MUST use the shared sign-in tracker when none is given.
- **footer-controls**: The panel MUST install an add-and-remove footer ([AddRemoveFooterView](cookbook:a1d787e2-2e3f-4742-a30b-120a8607c518)) under the sidebar list, with a separator above it and the accessibility prefix `integrations.add-remove`.
- **add-tooltip**: The add button MUST carry the tooltip "Add an integration".
- **remove-tooltip**: The remove button MUST carry the tooltip "Remove the selected integration".
- **initial-load**: When its view loads, the panel MUST build its listing and MUST ask the model to reload.
- **listing-rule**: The sidebar MUST list Gmail when the loaded provider reports it configured or when Gmail has been picked from `+` in this session, and MUST list nothing otherwise.
- **picked-in-memory**: A Gmail pick from `+` MUST be held only in memory and MUST NOT be sent to the service.
- **auto-select**: Whenever the listing is rebuilt and is not empty, the panel MUST select its first row.
- **remove-enabled**: The remove button MUST be enabled exactly when the listing is not empty, and MUST be re-evaluated on every rebuild.
- **rebuild-on-change**: When the model's provider changes, the panel MUST rebuild the listing only if whether Gmail is listed no longer matches whether a row is shown, and MUST evaluate that against the provider's post-change value, not its value before the change.
- **add-menu**: Pressing the add button MUST pop up a menu with one item, "Gmail", anchored at the bottom-left of the add button.
- **add-menu-disabled**: The "Gmail" menu item MUST be disabled while Gmail is already listed.
- **add-gmail**: Choosing "Gmail" from the menu MUST mark Gmail as picked and rebuild the listing.
- **remove-refused-when-empty**: Pressing the remove button while Gmail is not listed MUST announce refusal feedback and MUST NOT open a confirmation.
- **remove-confirmation**: Pressing the remove button while Gmail is listed MUST open a destructive confirmation ([confirmDestructive](cookbook:0fc99299-f3ba-4883-ab08-9bd614da7900)) attached to the panel's window, with the title, detail and action title given as the exact "Remove Gmail?", confirmation detail and "Remove" strings in the Localization table.
- **remove-cancel-default**: The removal confirmation MUST make Cancel the Return default and MUST treat Esc as declining, as the shared destructive confirmation does.
- **remove-declined**: When the confirmation is declined, the panel MUST NOT change the picked state, the listing or the service.
- **remove-configured**: When the removal is confirmed and the provider is configured or its configuration is unknown (not loaded yet, or the load failed; see Design Decisions), the panel MUST clear the picked state, ask the model to remove the integration, and rebuild the listing.
- **remove-unconfigured**: When the removal is confirmed and the provider is known to be not configured, the panel MUST clear the picked state, MUST dismiss the model's error message, MUST NOT ask the model to remove anything, and MUST rebuild the listing.
- **started-latest-sign-in**: The panel MUST expose whether the most recent Gmail sign-in in the app was started by its model.
- **reload-after-sign-in**: The panel MUST expose a call that asks the model to reload, because a panel brought back to the front gets no appearance callback.
- **gmail-body**: The Gmail detail MUST host the [Gmail settings view](cookbook:4f066e76-2eca-4cd7-8b73-840178e4edf3) over the shared model, wrapped in the themed root.
- **sync-error-surface**: The panel MUST NOT display an error message of its own; errors belong to the Gmail settings view over the shared model.

## Appearance

- **Corner radius**: Not applicable: the panel draws no shape of its own; it composes the shared settings split view, list and footer.
- **Padding**: Not applicable: the panel sets no insets; spacing comes from the shared split view and footer, and the Gmail view owns its own padding.
- **Font**: Not applicable: the panel sets no fonts; the sidebar and detail use the shared settings styling.
- **Background**: Not applicable: no color is set in the panel; the detail body is wrapped in the themed root.
- **Foreground/Text**: Sidebar title "Integrations"; row label "Gmail".
- **Border**: A separator is drawn above the footer (`separatorAbove: true`).
- **Shadow**: Not applicable: the panel sets no shadow.
- **Min/Max size**: Not applicable: the panel sets no size constraints; the split view's divider and sizing are the shared base class's.
- **Icons**: The panel uses the `puzzlepiece.extension` system symbol; the Gmail row uses `envelope`. Neither carries an accessibility description.
- **Footer**: A `+` add button and a `−` remove button under the sidebar list. Their glyphs, sizes and spacing belong to the shared add-and-remove footer.

## States

| State | Appearance change |
|-------|------------------|
| Empty (Gmail not configured and not picked) | The sidebar lists no rows, the remove button is disabled, and no detail is selected. |
| Gmail picked, not yet configured | The sidebar lists the "Gmail" row, which is selected; the remove button is enabled; the detail is the Gmail settings view, whose OAuth client form is shown. |
| Gmail configured | The sidebar lists the "Gmail" row, which is selected; the remove button is enabled. This holds with or without a pick. |
| Add menu open | A menu with one "Gmail" item is shown under the add button; the item is disabled while Gmail is listed. |
| Remove confirmation open | A destructive confirmation sheet is attached to the window with Cancel as the default. |
| Provider not yet loaded | Gmail is listed only if it was picked; the panel treats the unknown state as configured when removing. |
| Pressed, Focused, Loading | Not applicable: the panel has no state of its own for them; button pressed and focus appearance belong to the shared footer, and loading belongs to the Gmail settings view and model. |
| Disabled | Only the remove button and the "Gmail" menu item disable, as above; the panel as a whole is never disabled. |

## Accessibility

- **footer-accessibility-prefix**: The footer MUST be given the accessibility prefix `integrations.add-remove` so its buttons have stable accessibility identifiers.
- **refusal-announcement**: When the remove button is pressed with nothing to remove, the panel MUST announce the refusal through the shared refusal feedback.
- **keyboard-confirmation**: The removal confirmation MUST be operable by keyboard: Return activates Cancel and Esc declines.
- **native-controls**: The add menu MUST be a standard menu so the platform supplies its keyboard and assistive-technology behavior.
- **tooltips-as-labels**: The add and remove buttons SHOULD carry tooltips that describe their action, as the panel sets.
- **symbol-descriptions**: Both symbol images SHOULD carry an accessibility description. NEEDS REVIEW: Not implemented in source. Both symbol images are created with no accessibility description, so what assistive technology announces for the sidebar icon and the Gmail row icon is whatever the shared panel base class composes; a VoiceOver pass over the sidebar would settle whether the row reads as "Gmail" alone.
- **footer-labels**: The footer's add and remove buttons MUST carry accessibility labels "Add" and "Remove", which the shared `AddRemoveFooterView` gives their symbol images, and the identifiers `integrations.add-remove.add` and `integrations.add-remove.remove`; the panel adds only the tooltips.
- **target-size**: The panel MAY leave control sizing to the shared footer, as it does: it sets no control size, and the footer buttons come from the shared settings-panel footer, which owns their size.

## Conformance Test Vectors

Only the model the panel drives has tests (`GmailSettingsModelTests`); the panel has no test beside it. Vectors marked "derived" take their model-side expectation from the named test, and the panel-side expectation from the source. The panel has no test target, so the panel-side expectation of every derived vector is untested.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| integrations-settings-panel-001 | listing-rule, picked-in-memory, remove-enabled | Provider loaded with `configured` false and nothing picked | Sidebar has no rows; remove button disabled; no call sent to the service. |
| integrations-settings-panel-002 | listing-rule, add-gmail, auto-select, remove-enabled | Provider not configured; choose "Gmail" from the add menu | Sidebar lists one "Gmail" row, selected; remove button enabled; no call sent to the service. |
| integrations-settings-panel-003 | listing-rule, rebuild-on-change | Provider changes to `configured` true after a reload (derived from `reloadLoadsProviderAndAccounts`) | One main-queue turn later the sidebar lists the "Gmail" row and selects it. (panel side untested) |
| integrations-settings-panel-004 | add-menu, add-menu-disabled | Gmail already listed; press `+` | A one-item menu appears under the button; "Gmail" is disabled. |
| integrations-settings-panel-005 | remove-refused-when-empty | Nothing listed; press `−` | Refusal feedback is announced; no confirmation opens; listing unchanged. |
| integrations-settings-panel-006 | remove-confirmation, remove-cancel-default | Gmail listed; press `−` | Sheet "Remove Gmail?" with action "Remove" and the stated detail; Return selects Cancel. |
| integrations-settings-panel-007 | remove-declined | Open the confirmation; press Esc | Sheet closes; Gmail still listed; no `removeProvider` call sent. |
| integrations-settings-panel-008 | remove-configured | Provider `configured` true; confirm "Remove" | The model sends the remove-provider call (derived from `removeIntegrationClearsAccounts`); listing rebuilds empty; remove button disabled. (panel side untested) |
| integrations-settings-panel-009 | remove-configured | Provider not yet loaded or its load failed; Gmail picked; confirm "Remove" | The model's remove call is sent; picked state cleared; listing rebuilds empty. |
| integrations-settings-panel-010 | remove-unconfigured | Provider loaded with `configured` false; Gmail picked from `+`; confirm "Remove" | No remove call sent; the model's error message is cleared (derived from `dismissErrorClearsIt`); listing rebuilds empty. (panel side untested) |
| integrations-settings-panel-011 | started-latest-sign-in | Two panels share one tracker; only the first starts a sign-in (derived from `onlyTheModelThatStartedTheLatestSignInClaimsIt`) | The first panel reports true; the second reports false. (panel side untested) |
| integrations-settings-panel-012 | reload-after-sign-in | Call `reloadAfterSignIn()` after a sign-in finished | The model reloads and the listing reflects the new provider state. |
| integrations-settings-panel-013 | help-topics, search-keywords, gmail-detail-keywords | Read the help content and keywords of the panel and its Gmail detail | Two topics titled "Integrations" and "Gmail"; the panel keywords are the eight listed, the Gmail detail's are seven, without "integrations". |
| integrations-settings-panel-014 | panel-identity, sidebar-title, gmail-row, footer-controls, add-tooltip, remove-tooltip | Load the panel's view | Title and sidebar title "Integrations"; row "Gmail"; add tooltip "Add an integration"; remove tooltip "Remove the selected integration"; footer prefix `integrations.add-remove` with separator above. |

## Edge Cases

- **Provider unknown at removal**: Covered by remove-configured; the decision is `provider?.configured != false`, so only a known not-configured state skips the call.
- **Pick then remove**: When Gmail was picked from `+` and never configured, a confirmed removal MUST only clear the pick and the error message; nothing is sent.
- **Pick already configured elsewhere**: When Gmail is configured, the menu item is disabled, so a pick cannot duplicate it; the listing rule still shows a single row.
- **Pick survives configuration**: A pick is in-memory only and is not persisted; it is cleared by a confirmed removal and not by a successful configuration, which shows the same single row through the listing rule.
- **Remove with nothing listed**: Pressing `−` MUST announce refusal and MUST NOT open a confirmation, even though the button is also disabled in that state.
- **Missing window**: The confirmation is attached to the panel's window if it has one; the source passes an optional window. Without one, the shared `confirmDestructive` logs a warning and answers declined, so nothing is removed.
- **Provider publisher timing**: The provider publisher emits before the property holds its new value, so the AppKit panel runs the rebuild check one main-queue turn later; checking immediately would see the stale value.
- **Redundant provider updates**: A provider update that does not change whether Gmail is listed MUST NOT rebuild the listing, which preserves the user's selection.
- **Rebuild after panel deallocation**: Callbacks hold the panel weakly, so a callback after deallocation does nothing.
- **Reload failure**: The panel does not handle a failed reload itself; the failure is the model's error message, shown by the Gmail view. The provider keeps its previous value, which is unknown if it never loaded, so in that case only a pick lists Gmail.
- **Concurrent access**: The panel and the Gmail detail are main-actor isolated, and reloads and removals run as unstructured tasks started from the main actor; overlapping calls are serialized and counted by the model (`busyStaysTrueUntilOverlappingCallsBothFinish`), not by the panel.
- **Offline or disconnected service**: The panel sends nothing itself; a failed or unreachable service surfaces as the model's error message and leaves the provider state as it was.
- **Decoding from an archive**: Creation from an archive terminates the process with a fatal error.
- **Null and empty input**: The initializer takes a required client and a tracker defaulting to the shared one; there is no optional input to be empty.
- **Boundary values**: The listing is either empty or one row, because Gmail is the only integration.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `client` | `MailClient` | required | The mail client the Gmail settings model sends its calls through. |
| `signIns` | `GmailSignInTracker` | `.shared` | Tracks which surface started the latest Gmail sign-in. |

## Deep Linking

Not applicable: the panel registers no URL or route; its only link to a browser flow is `startedLatestSignIn` and `reloadAfterSignIn()`, which the app's sign-in landing calls.

## Localization

Strings are hardcoded English literals; the source uses no localization lookup.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | Integrations | Panel title and sidebar title, and help topic title. |
| (none; literal) | Gmail | Row title, add menu item, and help topic title. |
| (none; literal) | Add an integration | Add button tooltip. |
| (none; literal) | Remove the selected integration | Remove button tooltip. |
| (none; literal) | Remove Gmail? | Confirmation title. |
| (none; literal) | This removes the OAuth client and every connected Gmail account from this Mac, along with their stored sign-ins. | Confirmation detail. |
| (none; literal) | Remove | Confirmation action title. |
| (none; literal) | Each row is a service whose data is kept in sync on this Mac. Add one with +, remove the selected one with −. | Integrations help body. |
| (none; literal) | Gmail needs a Google Cloud OAuth client (Desktop app): enter its client ID and secret, or import its downloaded JSON. Then add one or more accounts and choose which mail to sync. Sign-in tokens are kept in your login Keychain. | Gmail help body. |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the panel defines no animation or transition. |
| Increase Contrast | Not applicable: the panel sets no colors; it composes shared and system controls. |
| Differentiate Without Color | Not applicable: the panel conveys no state by color; the empty and picked states differ by the presence of the row. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics event and calls no analytics API.

## Privacy

- **Data collected**: None by the panel itself; it handles no user data directly.
- **Storage**: The panel stores nothing. The help text states that sign-in tokens are kept in the login Keychain, and the removal confirmation states that it removes the OAuth client and every connected account with their stored sign-ins from this Mac.
- **Transmission**: The panel transmits nothing itself; the model's calls go to the service through the given client.
- **Retention**: Not applicable: nothing is retained by the panel. Removal deletes the stored OAuth client, accounts and sign-ins on the service.

## Logging

Not applicable: the source writes no log entries.

## Platform Notes

- **SwiftUI**: The panel is an AppKit class that hosts SwiftUI. `IntegrationsSettingsPanel` in `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/IntegrationsSettingsPanel.swift` is an open `@MainActor` subclass of `ComposableSettings.SettingsPanelSplitViewController` ([split view base](cookbook:ba8d9517-2528-4ae9-bc52-16046d68b126)). Its private `GmailSettingsPanel` subclass of `SettingsPanelViewController` hosts the SwiftUI `GmailSettingsView` through `hostingView(for:)` and `themedRoot()`. The model's `$provider` is a Combine publisher observed with `sink`, which emits before the new value lands, which is why the rebuild is deferred one main-queue turn. In pure SwiftUI, use `NavigationSplitView` with a `List` selection and a footer toolbar or bottom bar, and `confirmationDialog` or `alert` with a destructive role.
- **Compose**: Start from a two-pane layout, such as a `ListDetailPaneScaffold` or a `Row` of a `LazyColumn` and a detail pane. Collect the model's provider as state; derive the listing from `configured || picked` and key the selection on it. The add button opens a `DropdownMenu` whose single item is disabled when listed. The removal confirmation is an `AlertDialog` with a destructive confirm button and Cancel as the initially focused action. Holding the pick in `rememberSaveable` or the view model keeps it across rotation, which the source does not need on macOS.
- **React/Web**: Compose a sidebar `ul` with `role="listbox"` and a detail region. Keep `picked` in component state and derive `isAdded = provider?.configured === true || picked`. The footer is two buttons with `aria-label` text and a `menu` or `select` popup for add. Use the native `dialog` element for the confirmation, focusing Cancel first and closing on Esc. Derive the listing and the remove-enabled state during render from the provider and `picked`, with no `useEffect` to sync state; there is then no stale-value window to defer past.
- **AppKit / UIKit**: This is the source platform on AppKit: `NSMenu` with `autoenablesItems` off and a manually enabled `NSMenuItem`, popped up with `popUp(positioning:at:in:)` anchored under the add button. The confirmation is a sheet. Creation from an archive is unsupported: the `NSCoder` initializer of the panel and of the Gmail detail terminates with a fatal error. On UIKit, use a `UISplitViewController` with a `UITableView` sidebar, a `UIMenu` on the add button, and a `UIAlertController` with the destructive style on "Remove" and Cancel as the preferred action.
- **WinUI 3**: Build a `Page` with a `NavigationView` (`PaneDisplayMode="Left"`, `IsSettingsVisible="False"`) or a two-column `Grid` holding a `ListView` (`SelectionMode="Single"`) and a detail `Frame` hosting the Gmail page. Put the footer in a `StackPanel` below the `ListView` with two `Button` controls: `+` carries a `Flyout` or `MenuFlyout` with one `MenuFlyoutItem` titled "Gmail" whose `IsEnabled` binds to the inverse of `GmailIsAdded`, and `−` has `IsEnabled` bound to `GmailIsAdded`. Set `ToolTipService.ToolTip` to the two tooltip strings and `AutomationProperties.Name` and `AutomationProperties.AutomationId` (`integrations.add-remove.add` and `.remove`) so Narrator and UI tests find them; the macOS source sets only tooltips, and the shared footer supplies the "Add" and "Remove" labels. Drive the listing from a view model: `GmailIsAdded` is `Provider?.Configured == true || Picked`, and an `ObservableCollection` holds zero or one row, selecting index 0 after each change. `INotifyPropertyChanged` fires after the value lands, so the deferred turn is not needed. Confirm removal with a `ContentDialog` (`Title="Remove Gmail?"`, `PrimaryButtonText="Remove"`, `CloseButtonText="Cancel"`, `DefaultButton="Close"` so Enter picks Cancel, `XamlRoot` set from the page); Esc closes it as Cancel. For removal, treat `Configured` as a nullable `bool?` and call the remove command unless it is exactly `false`. For the refusal, use `FocusState` or a brief `InfoBar` since WinUI has no refusal sound; there is no direct equivalent of `RefusalFeedback.announce()`. Only one `ContentDialog` may be open per `XamlRoot`, which also serializes with the Gmail view's error alerts.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/IntegrationsSettingsPanel.swift` | unverified |
| ios | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Unknown provider state counts as configured when removing, so only a loaded `configured` of false skips the remove call.
**Rationale**: The source comment says removing an integration that is not there is harmless, while skipping one that is leaks its secrets.
**Approved**: pending

**Decision**: Picking Gmail from `+` is held only in memory and nothing is sent to the service until the OAuth client is imported.
**Rationale**: The source comment says Gmail "stays listed, in memory, until it is configured"; this lets the user reach the OAuth client form without creating service state.
**Approved**: pending

**Decision**: The listing rebuild runs one main-queue turn after the provider publishes.
**Rationale**: The source comment says `$provider` publishes before the new value lands, so reading it immediately would see the old value.
**Approved**: pending

**Decision**: The panel exposes `startedLatestSignIn` and `reloadAfterSignIn()` instead of reloading on appearance.
**Rationale**: The source comment says a panel brought back to the front gets no appearance callback, so the landing asks for the reload itself.
**Approved**: pending

**Decision**: The panel lists a single integration through a general sidebar, add menu and footer.
**Rationale**: The doc comment says "today only Gmail"; the sidebar, add menu and removal flow are built so further integrations can be added, but the code has one hardcoded branch for Gmail rather than a registry.
**Approved**: pending

**Decision**: Strings are literals and the panel writes no log entries.
**Rationale**: The source has no localization or logging calls; this is recorded as technical debt for the localization check and does not change behavior.
**Approved**: pending

**Decision**: The panel has no unit test of its own.
**Rationale**: Only `GmailSettingsModelTests` exist for the code it drives, and they cover the model, not the listing, the add menu or the removal flow; this affects the test coverage compliance result.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |

`separation-of-concerns` is passed: the panel owns only the listing, the add menu and the removal flow, and delegates the Gmail form and account handling to the Gmail settings view and model, and the footer, split view, confirmation and refusal feedback to shared settings components. `unit-test-coverage` is failed: the only tests nearby, `GmailSettingsModelTests`, exercise the model; nothing tests the listing rule, the add menu, the confirmation outcomes or the deferred rebuild. `keyboard-navigable` is partial: the confirmation has Return and Esc defaults and the add menu is a standard menu, but the panel adds no key handling and the footer's keyboard reach is the shared view's. `screen-reader-support` is partial: the footer has an accessibility prefix and the refusal is announced, but both symbol images are created without an accessibility description; the buttons get their "Add" and "Remove" labels from the shared footer and the panel adds only tooltips. `no-hardcoded-strings` is failed: every title, tooltip, help body and confirmation text is an English literal. `native-controls-preference` is passed: the panel uses a standard menu, a standard sheet and the shared split view rather than custom controls.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | mfullerton | Initial creation |
