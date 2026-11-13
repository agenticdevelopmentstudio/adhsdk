---
id: 018e4a69-cbeb-4105-8f39-dae3e6f7d8ec
title: "MailBrowserViewController"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Three-pane mail window: mailboxes, messages and reader, with sync polling and error alerts."
platforms:
  - swift
  - macos
tags:
  - integrations
  - mail
  - split-view
  - polling
depends-on:
  - b3edb32d-7473-464b-acfb-c19cdd44e99e
related:
  - 83a5a5e0-3337-4aff-aef8-40a7393dabfe
  - 26473390-9629-40f0-ae98-32ccab2fc5da
  - ac5b0100-ea5d-4abf-a9aa-11a477878514
references:
  - https://developer.apple.com/documentation/appkit/nssplitviewcontroller
  - https://developer.apple.com/documentation/appkit/nssplitviewitem
  - https://developer.apple.com/documentation/appkit/nsalert
  - https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.contentdialog
  - https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.grid
approved-by: ""
approved-date: ""
---

# MailBrowserViewController

## Overview

The content of the mail window. It lays out three panes side by side: a sidebar of mailboxes, the selected mailbox's message list, and a reader for the open message. A host app puts it in a window; it needs only a mail client, which it hands to a `MailBrowserModel` that holds all state and actions (the three pane controllers read and call that model).

This controller owns three things the panes do not: the split layout (pane order, widths, remembered divider positions), a background poll that reloads the model when a sync has finished, and the alert that reports the model's error message. It is the composition root for the mail window, not a place for mail logic.

## Behavioral Requirements

- **client-only-dependency**: The component MUST be constructible from a mail client alone, with no other required argument.
- **model-owned**: The component MUST create one model from the supplied client at construction and expose it as a public `model`.
- **shared-model**: The component MUST give that same model instance to the sidebar, the message list and the reader.
- **no-coder-init**: The component does not support construction from an archive; in the macOS source `init(coder:)` traps with the message "init(coder:) has not been implemented", and a port MAY trap or fail the same way (see the design decision on technical debt).
- **pane-order**: The component MUST lay out the panes in this order: mailbox sidebar, message list, reader.
- **sidebar-width**: The sidebar pane MUST be between 180 and 320 points wide.
- **list-min-width**: The message list pane MUST be at least 280 points wide.
- **reader-min-width**: The reader pane MUST be at least 360 points wide.
- **divider-persistence**: The component MUST set the split view's autosave name to "MailBrowserSplit" so divider positions are remembered.
- **initial-load**: The component MUST ask the model to reload once, when its view loads.
- **poll-start**: The component MUST start a repeating refresh task each time the view appears, cancelling any task already running first.
- **poll-interval**: The refresh task MUST wait one refresh interval before each refresh, so the first refresh follows the appearance by one full interval.
- **poll-default-interval**: The refresh interval MUST default to 30 seconds and MAY be set at construction.
- **poll-action**: Each tick MUST call the model's refresh-if-synced action, which reads the local store and never calls the remote mail provider.
- **poll-stop**: The component MUST cancel the refresh task and drop it when the view disappears.
- **poll-cancel-exit**: The refresh task MUST end without calling the model when it was cancelled during its wait.
- **poll-no-retain**: The refresh task MUST hold the controller weakly while it waits; if the controller is gone when a wait ends, the task MUST end. (It holds the controller strongly only for the duration of one refresh call.)
- **error-observe**: The component MUST observe the model's error message on the main queue and present an alert for every non-nil value.
- **error-nil-ignored**: The component MUST NOT present an alert when the error message becomes nil.
- **error-alert-content**: The alert MUST use the title "Mail", the model's message as informative text, the warning style and a single "OK" button.
- **error-sheet**: When the view is in a window, the alert MUST be presented as a sheet on that window.
- **error-modal-fallback**: When the view has no window, the alert MUST be run application-modally.
- **error-dismiss**: The component MUST call the model's dismiss-error action after the alert is closed, in both the sheet and modal paths.

## Appearance

- **Corner radius**: Not applicable: the controller draws nothing itself; the panes and the system split view draw their own content.
- **Padding**: Not applicable: the controller sets no insets; its only layout values are the pane widths below.
- **Font**: Not applicable: the controller sets no text; the alert uses system alert typography.
- **Background**: Not applicable: no background is set by this controller.
- **Foreground/Text**: Not applicable: no text is set by this controller beyond the alert strings.
- **Border**: The system split view's dividers separate the panes; the controller sets no border.
- **Shadow**: Not applicable: none set by this controller.
- **Min/Max size**: Sidebar 180 to 320 points wide. Message list at least 280 points wide. Reader at least 360 points wide. The window's minimum content width is therefore at least 820 points (180 + 280 + 360), a consequence of the pane minimums rather than a value the source sets.

The sidebar pane uses the system sidebar style and the list pane the system content-list style; the reader is a plain pane.

## States

| State | Appearance change |
|-------|------------------|
| Default | Three panes shown in order; polling runs only while the view is on screen. |
| Pressed | Not applicable: the controller is a container with no pressed state; presses occur in the panes. |
| Disabled | Not applicable: the controller has no disabled state in source. |
| Focused | Not applicable: the controller sets no focus behavior of its own. |
| Loading | Not applicable on the controller: the model publishes a loading flag, and the controller does not read it. |
| Polling | View on screen: a refresh task is waiting or refreshing. No visual change. |
| Idle | View off screen: no refresh task exists. |
| Error | An alert sheet (or modal alert when there is no window) is up with the model's message until the user clicks OK. |

## Accessibility

- **role**: The controller exposes the system split view and system alert; it sets no role, trait or label of its own.
- **alert-label**: The alert MUST present its text as the standard alert message and informative text, and its single button MUST be titled "OK".
- **keyboard-path**: NEEDS REVIEW: Not implemented in source. The controller sets no key view loop and no shortcut for moving between the three panes, and relies on whatever the system split view and pane controllers provide; a keyboard run-through with VoiceOver on would settle whether a SHOULD requirement for pane switching is needed.
- **pane-labels**: The controller sets no accessibility label on the panes. Each pane controller sets its own accessibility identifier on its main view (`mail.sidebar`, `mail.messages`, `mail.reader.body`), and the sidebar and list rows set their own labels.
- **target-size**: Not applicable: the controller has no controls of its own; the alert's button is system-drawn.

## Conformance Test Vectors

The model contract the controller relies on is covered by `MailBrowserModelTests`; no test file covers the controller itself, so the controller vectors below are manual or UI-test vectors derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-browser-vc-001 | client-only-dependency, model-owned | Construct with a client and no interval. | The controller exists and its `model` is non-nil. |
| mail-browser-vc-002 | shared-model | Construct, load the view, then on the controller's `model` select the "Sent" mailbox and then one message in it. | The sidebar highlights "Sent", the message list shows the Sent messages, and the reader shows the selected message's body (the panes hold the model privately, so only the shared instance can drive all three). |
| mail-browser-vc-003 | no-coder-init | Decode the controller from an archive. | The process traps with "init(coder:) has not been implemented". |
| mail-browser-vc-004 | pane-order | Load the view. | Items are, in order: sidebar, message list, reader. |
| mail-browser-vc-005 | sidebar-width, list-min-width, reader-min-width | Drag each divider to its extremes. | Sidebar stays within 180 to 320 points; list never below 280; reader never below 360. |
| mail-browser-vc-006 | divider-persistence | Move a divider, close and reopen the window. | The divider is where it was left; the autosave name is "MailBrowserSplit". |
| mail-browser-vc-007 | initial-load | Load the view with a scripted client holding one account. | The model reloads once; its selected mailbox is that account's Inbox (see `reloadSelectsTheFirstAccountsInboxAndListsIt`). |
| mail-browser-vc-008 | poll-interval, poll-action | Appear with a 30 s interval and a client whose account sync time is later changed. | No refresh at 0 s; the first refresh call happens at 30 s; new messages show after it (model side: `aFinishedSyncReloadsTheList`). |
| mail-browser-vc-009 | poll-stop, poll-cancel-exit | Appear, then disappear 5 s later, with a 30 s interval. | No refresh call is made after the disappearance. |
| mail-browser-vc-010 | poll-start | Appear twice without disappearing in between. | Only one refresh task runs; the first is cancelled. |
| mail-browser-vc-011 | error-observe, error-alert-content, error-sheet, error-dismiss | Model fails a list request with "store unavailable" (see `aFailedListBecomesTheErrorMessage`) while the view is in a window. | A warning sheet titled "Mail" shows "store unavailable" with one "OK" button; after OK the model's error message is nil. |
| mail-browser-vc-012 | error-modal-fallback, error-dismiss | Same failure while the view has no window. | A modal alert runs; when it returns the model's error message is nil. |
| mail-browser-vc-013 | error-nil-ignored | Model's error message goes from a message to nil via dismiss. | No second alert appears. |
| mail-browser-vc-014 | poll-default-interval | Construct without an interval. | Refreshes occur every 30 seconds while on screen. |
| mail-browser-vc-015 | poll-no-retain | Release the controller while a refresh task is waiting. | When the wait ends the task exits and makes no model call. |
| mail-browser-vc-016 | poll-interval, poll-action, poll-stop, poll-cancel-exit, poll-no-retain | Construct with `refreshInterval` of 100 ms and a scripted client whose account sync time changes once; appear, wait 250 ms, then disappear and wait 250 ms more; repeat, releasing the controller instead of disappearing. | No refresh before 100 ms; the refresh after the sync change reloads the list; no model call follows the disappearance or the release. Runs in milliseconds, with no 30 s wait; vectors 008, 009, 014 and 015 use the same check with the default interval. |
## Edge Cases

- **Refresh while off screen**: No refresh task exists while the view is not on screen. The component MUST NOT poll in that state.
- **Cancellation during sleep**: The wait ignores the cancellation error, and the loop then checks for cancellation and exits. The component MUST NOT refresh after cancellation.
- **Repeated appear**: A second appear cancels the earlier task before starting a new one. The component MUST keep at most one refresh task.
- **Short or zero interval**: The source does not bound the interval; a very short interval makes the model check for syncs that often. The source validates nothing here: zero or negative intervals are accepted at construction (see the design decision on the unchecked interval).
- **Failed account read during a poll**: The model's refresh swallows a failed accounts read and does nothing; no alert appears. This is the model's behavior and the controller adds nothing.
- **Error with no window**: The alert runs application-modally and blocks until closed. The component MUST dismiss the model error afterward.
- **Error cleared**: The error stream drops nil values, so clearing the error shows nothing.
- **Second error while one is showing**: Each non-nil value triggers a new alert request; the source does not coalesce or suppress them. Behavior of stacked sheets is the system's. The source defines no coalescing or queuing of alerts (see the design decision on overlapping alerts).
- **No accounts or provider not configured**: Not a controller concern: the model clears the list and the panes show their empty state.
- **Concurrent access**: The controller and model are confined to the main actor; the refresh task hops to the main actor to call the model, so calls are serialized with UI work.
- **Offline**: The poll reads only the local store, so loss of connectivity does not affect it; the controller makes no network call.
- **Initial reload not cancelled on disappear**: The initial reload is an unstructured main-actor task whose handle is not kept, so it MAY outlive the view and is not cancelled when the view disappears. A port SHOULD keep the handle and cancel it on disappear.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| client | MailClient | none, required | The mail client the model reads and writes through. |
| refreshInterval | Duration | 30 seconds | How long the poll waits before each check for a finished sync. |

## Deep Linking

Not applicable: the controller is the content of a window and defines no URL or route.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none in source (a port should use `mail.alert.title`) | Mail | Alert title |
| none in source (a port should use `mail.alert.ok`) | OK | Alert button |

- **localization-support**: NEEDS REVIEW: Not implemented in source. The alert title and button are string literals with no localization lookup, and the model's message is passed through as the error's description; a decision on supported locales would settle whether these need keys.

## Accessibility Options

Not applicable: the controller sets no animation, no color and no differentiation by color; it reads no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: None by this controller; it displays mail the model loads.
- **Storage**: None by the controller. The poll reads a local store through the model.
- **Transmission**: The controller transmits nothing; its poll never calls the remote mail provider.
- **Retention**: Not applicable: the controller keeps no data beyond the live model.

## Logging

Not applicable: the source writes no log line; failures reach the user as the alert.

## Platform Notes

- **SwiftUI**: Source is AppKit. Start from `NavigationSplitView` with sidebar, content and detail columns and `navigationSplitViewColumnWidth(min:ideal:max:)`; `.alert` or `.sheet` bound to an optional error; `.task` with a loop and `Task.sleep` gives the poll, cancelled automatically when the view goes away. Divider persistence needs `SceneStorage` or similar, unlike the autosave name here.
- **Compose**: Start from a three-pane layout (`Row` with weighted or fixed-width panes, or the Material 3 list-detail adaptive scaffold on large screens); `LaunchedEffect` with a `delay` loop for the poll, scoped to the lifecycle; `AlertDialog` for errors. Divider positions are not remembered for free.
- **React/Web**: Three CSS grid columns with `min-width`, a drag handle component for dividers, positions in local storage; `useEffect` with `setInterval` or a timeout loop and cleanup on unmount; a modal `role="alertdialog"` for errors, with focus moved into it.
- **AppKit / UIKit**: Source: `macOS/Features/Integrations/Mail/MailBrowserViewController.swift`, an `NSSplitViewController` main-actor subclass using `NSSplitViewItem` factories for sidebar and content-list styles, `autosaveName` for dividers, `NSAlert` with `beginSheetModal`. The polling task starts in `viewDidAppear` and stops in `viewDidDisappear`. On UIKit use `UISplitViewController` (triple-column style) with column width properties; there is no autosave name, and alerts are `UIAlertController`.
- **WinUI 3**: Use a `Grid` with three `ColumnDefinition` entries and two `GridSplitter` controls from the Windows Community Toolkit, setting `MinWidth` 180, 280 and 360 on the columns and `MaxWidth` 320 on the first, since WinUI has no built-in autosave for column widths; persist `ColumnDefinition.Width` in `ApplicationData.Current.LocalSettings` on `SizeChanged`. A `NavigationView` in `Left` pane mode can host the mailbox sidebar instead of a first column. Start the poll in the page's `Loaded` handler with a `DispatcherQueueTimer` (`Interval` of 30 seconds, `IsRepeating` true) and stop it in `Unloaded`; the timer's first tick falls one full interval after `Start`, matching the source. Show errors with a `ContentDialog` (`Title` "Mail", `Content` the message, `CloseButtonText` "OK", `XamlRoot` set to the page's root); `ContentDialog` allows one open at a time, so a second error while one is showing needs queuing, which the source does not define. The fallback with no window has no WinUI equivalent; a `ContentDialog` always needs a `XamlRoot`. Set `AutomationProperties.Name` on each pane and keep Tab order across panes in a `TabNavigation` group.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/Mail/MailBrowserViewController.swift` | unverified |
| ios | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The controller holds no mail logic; all state and actions live in `MailBrowserModel`, and the three panes only read and call it.
**Rationale**: The model's own header comment calls it "the tested unit"; the controller stays a thin composition root, so the model is tested without UI.
**Approved**: pending

**Decision**: The poll waits one interval before its first refresh instead of refreshing at once.
**Rationale**: The initial reload at view load already shows current data, so an immediate refresh would repeat it; the sleep comes first in the loop.
**Approved**: pending

**Decision**: Each tick calls the model's refresh-if-synced action, a read of the local store that never calls the remote mail provider.
**Rationale**: The class comment says it is "a read of the local store, never a Gmail call"; the poll costs no network or API quota. How the model decides a sync has landed belongs to the `MailBrowserModel` artifact.
**Approved**: pending

**Decision**: The poll runs only between appear and disappear.
**Rationale**: A window that is not on screen has no reason to reload; the task is cancelled on disappear and replaced on every appear.
**Approved**: pending

**Decision**: Errors are shown by the controller as an alert, not by the model or panes, and are cleared only after the user closes it.
**Rationale**: The model publishes `errorMessage` as state and cannot present UI; a sheet on the window keeps the user in context, and the modal fallback covers a view with no window.
**Approved**: pending

**Decision**: Pane widths are 180 to 320 for the sidebar, 280 minimum for the list and 360 minimum for the reader, with divider positions saved under "MailBrowserSplit".
**Rationale**: The values are fixed in source with no comment; their reasons are not recorded there, so this records what the code does.
**Approved**: pending

**Decision**: The controller's alert strings are literals, and `init(coder:)` traps.
**Rationale**: Technical debt that affects behavior: the strings cannot be localized without a change, and the controller cannot be loaded from a nib or storyboard. The debt is retired when the alert strings move to localization keys and the controller either supports archive construction or the trap is documented as permanent by a host-app decision.
**Approved**: pending

**Decision**: The refresh interval is accepted as given, with no check for zero or negative values.
**Rationale**: The source takes a `Duration` and passes it to the sleep; a very short interval only makes the local-store read run more often, and the only caller uses the default. Rejecting bad values at construction is left to a future change.
**Approved**: pending

**Decision**: Overlapping errors each present their own alert; the controller neither coalesces nor queues them.
**Rationale**: The source presents one alert per non-nil error value and leaves stacking to AppKit. A port to a platform that allows one dialog at a time (WinUI `ContentDialog`) needs a queue or coalescing step, which this spec does not define yet.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc) | passed | performance |

The controller is a thin composition root: layout, a poll and an error alert, with all logic in the model, so separation of concerns passes. Unit coverage is partial because `MailBrowserModelTests` exercises the model's reload, error and refresh behavior while no test constructs the controller, its poll timing or its alert. Errors are never swallowed here: every non-nil model error reaches the user. The one swallowed failure, an accounts read that fails during a poll, happens inside the model's refresh and belongs to `MailBrowserModel`, not to this controller. The alert title and button are hardcoded literals, which fails the hardcoded-strings check. The split view, sidebar styling and alert are system controls. The poll reads only the local store and stops when the view is off screen.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
