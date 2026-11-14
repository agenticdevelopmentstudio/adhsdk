---
id: 16744ac3-fd46-4dc1-81c9-6be312a33ce7
title: "Topic Dialog Window"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A resizable modal dialog built as a settings window: topic sidebar, help, a problem line and Cancel and OK under the detail, shown app-modally, as a sheet or as a window."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - dialog
  - window
depends-on: []
related:
  - 7cac2263-94fe-47ec-ab1d-6cf5a12baf14
  - a0d31e57-2b64-4c0e-8f1b-5e7c9d4a3b22
references:
  - https://developer.apple.com/design/human-interface-guidelines/sheets
  - https://developer.apple.com/design/human-interface-guidelines/alerts
approved-by: ""
approved-date: ""
---

# Topic Dialog Window

## Overview

The topic dialog window is a modal dialog built as a settings window: the same
topic sidebar, toolbar and help drawer, resizable, with a problem line and
Cancel and OK buttons under the detail pane. The close button is Cancel,
Escape is Cancel and Return is OK. It is for editing one record in steps: the
topics are the steps, in the order given. See
[adhsdk.ingredient.ui.settings.settings-window](cookbook:7cac2263-94fe-47ec-ab1d-6cf5a12baf14)
for the window it extends.

It can be shown three ways. `present()` shows it app-modally. `beginSheet(on:)`
shows it as a sheet on one window, which holds up only that window; a sheet has
no toolbar, so its help is behind a standard round help button at the bottom
left. `show()` shows it as an ordinary window that holds up nothing and keeps
its toolbar and help drawer.

OK asks the owner's `validate` closure. A returned sentence stays in the dialog
as the problem line and the dialog stays open. With no problem, OK either
finishes the dialog (when `onOK` is unset) or hands over to `onOK`, for an owner
that saves asynchronously; that owner then calls `finish(true)` itself, or
shows a problem and re-enables OK. The dialog reports its one answer through
`onFinish`.

## Behavioral Requirements

- **main-actor-confined**: The dialog MUST be confined to the main actor.
- **answers-once**: `finish` MUST call `onFinish` at most once, with true after OK and false after Cancel; every later call MUST do nothing.
- **ok-validates**: After it has cleared the problem line, OK MUST call `validate` before it finishes or calls `onOK`.
- **problem-keeps-open**: When `validate` returns a sentence, OK MUST show it as the problem line, MUST leave the dialog open and MUST NOT call `onFinish`.
- **ok-clears-stale-problem**: OK MUST clear any earlier problem line before it calls `validate`.
- **ok-finishes**: When `validate` returns nothing and `onOK` is unset, OK MUST finish the dialog with true.
- **ok-hands-over**: When `validate` returns nothing and `onOK` is set, OK MUST call `onOK` instead of finishing, and MUST disable the OK button first.
- **ok-single-flight**: While OK is disabled, OK (including Return) MUST do nothing.
- **ok-re-enable**: Setting `okEnabled` MUST update the OK button's enabled state at once.
- **cancel-finishes-false**: Cancel MUST finish the dialog with false and MUST NOT call `validate`.
- **close-cancels**: The window's close button MUST cancel the dialog and MUST refuse to close the window itself, leaving `finish` to take it down.
- **escape-cancels**: The Cancel button MUST carry the Escape key equivalent.
- **return-confirms**: The OK button MUST carry the Return key equivalent.
- **problem-line**: `showProblem` MUST show the given sentence beside the buttons and MUST hide the line for nil; the problem MUST be readable as the dialog's `problem`.
- **problem-line-color**: The problem line MUST be drawn in the system red color and MUST wrap to at most 2 lines.
- **footer-buttons**: Cancel and OK MUST be standard push buttons at the regular control size, with OK trailing 20 points from the footer's right edge and Cancel 12 points to OK's left, OK never narrower than Cancel.
- **ok-title**: The OK button's title MUST be the initializer's `okTitle`, defaulting to "OK".
- **resizable-not-minimizable**: The window MUST be titled, closable and resizable, and MUST NOT be miniaturizable.
- **default-size**: The window MUST open centered at 860 by 600 points the first time and remember its frame afterward, with a minimum size of 680 by 460 points; an owner MAY set its own window spec.
- **frame-keyed-by-id**: The saved size and position MUST be keyed by the `windowID` given to the initializer.
- **topics-in-order**: The topics MUST keep the order given, MUST NOT be sorted by title and MUST NOT offer a sidebar search field.
- **single-topic-no-list**: With one topic or fewer, the topic list MUST be hidden.
- **sidebar-width-apart**: The sidebar width MUST be saved under its own autosave name, `ComposableSettings.TopicDialogSidebar`, apart from the settings window's.
- **help-drawer-memory-apart**: Whether the help drawer is open MUST be remembered in the dialog's own user setting, apart from the settings window's.
- **toolbar-title**: The toolbar title MUST be the dialog title followed by an em dash flanked by spaces and the selected topic's title; it MUST be the dialog title alone when the topic title is nil or empty or when the topic list is hidden.
- **first-topic-selected**: `prepare` MUST select the first topic when none is selected and MUST return the built window without showing it.
- **present-app-modal**: `present()` MUST return at once and start the app-modal session on the next pass of the run loop, not inside the call.
- **present-activates**: The modal session MUST bring the app forward before it runs.
- **present-skips-finished**: `present()` MUST do nothing when the dialog has already finished, and a session MUST NOT start if the dialog finished before it began.
- **show-modeless**: `show()` MUST order the window front and activate the app without holding up any other window, and MUST do nothing when the dialog has finished or is already a sheet.
- **sheet-no-toolbar**: `beginSheet(on:)` MUST remove the toolbar, hide the window title and show the help button.
- **sheet-help-button**: The help button MUST be a standard round help button with tooltip and accessibility label "Help" that toggles the help drawer, and MUST be hidden unless the dialog is a sheet.
- **sheet-problem-offset**: In a sheet, the problem line MUST start 12 points right of the help button; otherwise it MUST start 20 points from the footer's left edge.
- **sheet-guard**: `beginSheet(on:)` MUST do nothing when the dialog has finished or already has a sheet parent.
- **sheet-ends-before-finish**: When finishing a sheet, the dialog MUST end the sheet before calling `onFinish`, so the owner can begin the next sheet on the same parent, and MUST clear `sheetParent`.
- **keeps-itself-alive**: A presented dialog MUST keep itself alive until it finishes, so an owner that lets go does not lose it.
- **modal-ends-without-event**: Finishing a running modal session MUST stop the session and post an application-defined event so the session ends even when no event is pending.
- **releases-owner-closures**: On finish, the dialog MUST replace `onFinish` with a no-op, clear `onOK` and replace `validate` with one that returns nothing, so that what the owner captured is released.
- **hides-on-finish**: Finishing MUST order the window out.
- **is-finished**: `isFinished` MUST be true from the first `finish` onward.
- **detail-fills**: The panels MUST take the height above the footer.

## Appearance

- **Corner radius**: Not set by this dialog; the window and buttons use the system's.
- **Padding**: Footer: OK 20 points from trailing and bottom edges and 12 points from the footer's top; Cancel 12 points left of OK; help button and problem line 20 points from the leading edge; the problem line keeps at least 20 points clear of Cancel and at least 8 points from the footer's top; the help button is vertically centered with OK.
- **Font**: System defaults for push buttons and the wrapping label; the dialog sets none.
- **Background**: The settings window's themed background, applied by the shared split.
- **Foreground/Text**: Problem line in the system red color, up to 2 lines; buttons use the system push style.
- **Border**: None set by the dialog.
- **Shadow**: None set by the dialog.
- **Min/Max size**: Default 860 by 600 points, minimum 680 by 460 points, no maximum; the detail footer is under 100 points tall (per the layout test) so panels take the rest. The detail area inherits a minimum of 200 points from the nested split.

## States

| State | Appearance change |
|-------|------------------|
| Default | Window not yet shown; OK enabled; problem line hidden; help button hidden |
| Presenting app-modally | Window key and front, toolbar and help drawer present, other windows held up |
| Shown as a window | Same as presenting, with other windows usable |
| Sheet | No toolbar, title hidden, help button visible at the bottom left, problem line offset right of it |
| Problem showing | The problem line shows the sentence in red; the dialog stays open |
| Awaiting save (onOK called) | OK disabled until the owner re-enables it or finishes |
| Finished | Window ordered out; `isFinished` true; owner closures released |
| Pressed | Standard push button pressed appearance, drawn by the system |
| Disabled | OK disabled while a save is in flight; Cancel is never disabled |
| Focused | Not applicable: the dialog sets no focus order of its own; OK is the default button through its Return key equivalent |
| Loading | Not applicable: the dialog shows no spinner; the awaiting-save state is only OK disabled |

## Accessibility

- Role/trait: The Help button is a standard help button with accessibility label "Help"; Cancel and OK are standard push buttons with their titles.
- Label requirements: The help button's accessibility label MUST be "Help"; the buttons are labelled by their titles; the problem line is a text field whose text is the sentence.
- **announce-state-changes**: NEEDS REVIEW: Not implemented in source. A problem sentence appearing, and OK being disabled during a save, post no accessibility notification and move no focus; a screen-reader pass would settle whether the problem line needs to be announced.
- Minimum tap target: Not applicable: Cancel, OK and the help button are standard regular-size system buttons whose size the system sets; the layout test requires a regular button to be at least 20 points high.

## Conformance Test Vectors

Derived from `TopicDialogWindowTests` beside the source, which builds the
dialog with two stub panels "Zebra" and "Apple" and title "Edit".

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| topic-dialog-001 | sidebar-width-apart (testTheSidebarWidthIsKeptApartFromTheSettingsWindows) | Read the dialog split's sidebar autosave name and a root split's | The dialog's is non-nil and differs from the root's |
| topic-dialog-002 | topics-in-order (testTheTopicsKeepTheOrderGiven) | Build with Zebra then Apple | Panels read Zebra then Apple; sidebar search is off |
| topic-dialog-003 | resizable-not-minimizable, toolbar-title, first-topic-selected (testTheWindowIsAResizableDialogWithTheHelpDrawerAndToolbar) | `prepare()` | The mask has resizable and closable and not miniaturizable; a toolbar and help presenter exist; the selected topic is Zebra; the toolbar title for Zebra is "Edit — Zebra" |
| topic-dialog-004 | default-size (testAnOwnerCanGiveTheFirstSize) | Set a spec of 1000 by 640 with minimum 900 by 500, not persisted; `prepare()` | The frame is 1000 by 640; the minimum width is 900 and the minimum height at least 500 |
| topic-dialog-005 | footer-buttons, escape-cancels, return-confirms, detail-fills (testTheButtonsAreStandardPushButtonsUnderThePanels) | `prepare()` and lay out | Both buttons are push style at regular size and at least 20 points high; OK has Return, Cancel has Escape; the footer is under 100 points tall and the panels have more than 300 points; OK sits right of Cancel and near the bottom |
| topic-dialog-006 | ok-validates, problem-keeps-open, problem-line (testOKWithAProblemShowsItAndStaysOpen) | `validate` returns "Name is empty."; `ok()` | `problem` is that sentence, the problem line is visible, `onFinish` has not been called |
| topic-dialog-007 | ok-finishes, answers-once (testOKWithNoProblemFinishesTrueOnce) | `ok()`, `ok()`, `cancel()` | `onFinish` is called once with true; `problem` is nil |
| topic-dialog-008 | cancel-finishes-false (testCancelFinishesFalseWithoutValidating) | `cancel()`, then `ok()` | `onFinish` receives false once; `validate` was never called |
| topic-dialog-009 | close-cancels (testTheCloseButtonCancels) | Call `windowShouldClose` on the window | It answers false; `onFinish` receives false; the window is not visible |
| topic-dialog-010 | ok-hands-over, ok-single-flight, ok-re-enable, answers-once (testOnOKReplacesFinishingAndDisablesOK) | Set `onOK`; `ok()` twice; show a problem; set `okEnabled` true; `finish(true)`; `finish(false)` | `onOK` ran once; OK was disabled and no finish happened; after re-enabling the button is enabled; `onFinish` receives true once |
| topic-dialog-011 | ok-clears-stale-problem (testOKClearsAStaleProblemBeforeValidating) | `validate` fails then passes; `ok()` twice | First: problem "Bad."; second: problem nil and the line hidden |
| topic-dialog-012 | keeps-itself-alive, present-skips-finished (testAPresentedDialogKeepsItselfUntilFinished) | Build a one-topic dialog in an autorelease pool, call `present()`, drop the reference, then `finish(false)` | The dialog is still alive after the pool; after finishing its window is not visible |
| topic-dialog-013 | sheet-no-toolbar, sheet-help-button, sheet-guard (testASheetBeginsOnTheParentWithoutAToolbarAndShowsTheHelpButton) | Before: help button hidden. `beginSheet(on: parent)` | `sheetParent` is the parent; the parent's attached sheet is the dialog window; the toolbar is nil; the help button is visible with the help bezel |
| topic-dialog-014 | sheet-ends-before-finish, answers-once (testOKEndsTheSheetThenCallsOnFinishOnce) | Begin a sheet; `ok()`; `cancel()` | `onFinish` receives true once; at that moment the parent has no attached sheet; `sheetParent` is nil afterward |
| topic-dialog-015 | cancel-finishes-false, sheet-ends-before-finish (testCancelEndsTheSheetAndFinishesFalse) | Begin a sheet; `cancel()` | `onFinish` receives false; the parent has no attached sheet |
| topic-dialog-016 | toolbar-title, single-topic-no-list | Build with one panel "Only"; read `toolbarTitle(forPanel: "Only")`; also with an empty title | Both return "Edit" |
| topic-dialog-017 | releases-owner-closures | Finish, then read the dialog's `validate` and call it | It returns nil |

## Edge Cases

- **Validation returns a sentence** (MUST): The sentence stays as the problem line and the dialog stays open; the next OK clears it before validating again.
- **OK pressed twice quickly with `onOK` set** (MUST): The second press does nothing, because OK is disabled and the guard refuses it; Return is refused with it.
- **Owner's save fails** (MUST): The owner calls `showProblem` and sets `okEnabled` true; the dialog does not do this itself. The dialog never times out a pending save; an owner that never answers leaves OK disabled.
- **finish called more than once** (MUST): The first call wins; later calls do nothing, including a late `finish(true)` after Cancel.
- **finish before the modal session starts** (MUST): The queued session checks the finished flag and does not start; the window is ordered out.
- **finish from a save that comes from no event** (MUST): A stop-modal request alone takes effect only when the loop next handles an event, so an application-defined event is posted to end the session at once.
- **present on a finished dialog** (MUST): Does nothing.
- **show or beginSheet on a finished dialog or one already a sheet** (MUST): Does nothing. `present()` does not check for a sheet parent.
- **Showing again with `show()`** (SHOULD): The window is brought forward again; the dialog does not build a second window.
- **Sheet owner begins the next sheet inside onFinish** (MUST): Allowed, because the sheet has ended before `onFinish` runs.
- **Escape while a save is in flight** (MUST): Cancel is never disabled, so Escape still cancels and finishes with false.
- **One topic** (MUST): The list is hidden; the toolbar title is the dialog title alone.
- **No topics** (MUST): The list is hidden (one or fewer) and `prepare` selects nothing.
- **Empty or nil problem** (MUST): Nil hides the line; an empty string shows an empty visible line, as `showProblem` hides only for nil.
- **Long problem sentence** (MUST): Wraps to at most 2 lines and keeps 20 points clear of Cancel; beyond 2 lines it is truncated by the label.
- **Owner lets go after present** (MUST): The dialog keeps itself alive until it finishes.
- **Concurrent access** (MUST): The type is confined to the main actor; calls are serialized on the main thread.
- **Network or offline state**: Not applicable: the dialog does no network work itself; an owner's save runs in `onOK`.
- **Decoding or restoring**: Not applicable: the dialog is built only in code.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| windowID | String | none (required) | Keys the dialog's saved size and position |
| title | String | none (required) | The dialog title, used in the window title and toolbar title |
| panels | array of panels | none (required) | The topics, in the order shown |
| okTitle | String | "OK" | The OK button's title |
| validate | closure returning an optional String | none (required) | Asked on OK; a sentence keeps the dialog open |
| onFinish | closure taking a Bool | none (required) | Called once with true after OK, false after Cancel |
| onOK | optional closure | nil | When set, a validated OK calls it instead of finishing |
| okEnabled | Bool | true | Whether OK can be pressed |
| windowSpec | WindowSpec | 860 by 600, minimum 680 by 460, centered, persists frame | Size and position policy; an owner may replace it |

## Deep Linking

Not applicable: the dialog has no address or route in source; it is shown by its owner.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | Cancel | Cancel button title; written as a literal in source |
| (none; literal) | OK | Default OK button title, overridable by `okTitle` |
| (none; literal) | Help | Help button tooltip and accessibility label |
| (none; literal) | Title — Topic | Toolbar title format: dialog title, an em dash, topic title |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the dialog adds no animation of its own; the sheet and window motion belong to the system. |
| Increase Contrast | Not applicable: the dialog uses system colors and standard buttons, which the system adapts. |
| Differentiate Without Color | The problem line is a sentence of text, so it does not rely on its red color alone. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: None by the dialog itself; the owner's panels collect whatever the owner edits.
- **Storage**: The window frame (under the window ID), the sidebar width (under the dialog's autosave name) and whether the help drawer is open (a user setting) are saved.
- **Transmission**: None.
- **Retention**: Until the user's defaults are cleared; closing the dialog does not clear them.

## Logging

Not applicable: the source writes no log entry.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/TopicDialogWindow.swift`, an AppKit `SettingsWindow` subclass, `@MainActor` and `public final`. In SwiftUI, present a `.sheet(item:)` holding a `NavigationSplitView` of topics, with a `.toolbar` carrying `ToolbarItem(placement: .cancellationAction)` for Cancel and `.confirmationAction` for OK, `.keyboardShortcut(.defaultAction)` and `.cancelAction` for Return and Escape, an error `Text` in `.red` with `lineLimit(2)`, and `.disabled(saving)` on OK. For the app-modal form, use an `NSWindow` hosting the view and `NSApp.runModal`.
- **Compose**: Use a `Dialog` (`DialogProperties(usePlatformDefaultWidth = false)`) or a full `ModalBottomSheet` on phone, with a `Row` of a topic list and a detail, a `Text` in `MaterialTheme.colorScheme.error` limited to 2 lines, and `TextButton` Cancel and `Button` OK in a footer `Row` with `Arrangement.End`; disable OK while saving; map Escape and Enter through `onKeyEvent`.
- **React/Web**: A `dialog` element opened with `showModal()` (which gives modal behavior, Escape-to-cancel through the `cancel` event and a focus trap) with `aria-labelledby` for the title, a `nav` of topics, a detail region, an `aria-live="polite"` problem paragraph with `role="alert"`, and a `form` whose submit button is OK (Enter submits) and Cancel is `type="button"`; disable OK while a save is pending.
- **AppKit / UIKit**: In AppKit the source builds an `NSWindow` with style mask titled, closable, resizable and full-size content view, runs it with `NSApp.runModal(for:)` started from `CFRunLoopPerformBlock`, or `beginSheet(_:completionHandler:)`, with push-bezel `NSButton`s using key equivalents `\r` and `\u{1b}`, an `NSTextField(wrappingLabelWithString:)` and a help-bezel `NSButton`. On UIKit, present a `UIViewController` with `modalPresentationStyle = .formSheet`, `UIBarButtonItem`s for Cancel and Done, and `isModalInPresentation = true` so a swipe does not dismiss it silently.
- **WinUI 3**: Use a `ContentDialog` with `PrimaryButtonText="OK"`, `CloseButtonText="Cancel"`, `DefaultButton="Primary"` (Enter) and `XamlRoot` set to the host window's root; Escape closes it through the close button. Handle `PrimaryButtonClick`: take a `Deferral` from the event args, run `validate`, and set `args.Cancel = true` after showing the sentence in a `TextBlock` with `Foreground="{ThemeResource SystemFillColorCriticalBrush}"`, `TextWrapping="Wrap"` and `MaxLines="2"`; set `IsPrimaryButtonEnabled="False"` while a save is in flight and complete the deferral when the owner calls finish. For the sheet-like form, show it with `ShowAsync()` on the parent's `XamlRoot` (it blocks only that window's content); for the app-modal form, host a content `Window` and disable the others through `OverlappedPresenter.IsModal = true`. The topic list is a `NavigationView` with `PaneDisplayMode="Left"` inside the dialog `Content`, hidden by `IsPaneVisible="False"` for one topic, and the help is an `AppBarButton` with `Icon="Help"` and `AutomationProperties.Name="Help"`. Remember size per window ID with `ApplicationData.Current.LocalSettings`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/TopicDialogWindow.swift` | confirmed (1.0.1) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The dialog is built as a settings window (topic sidebar, toolbar, help drawer) rather than a plain form.
**Rationale**: A record edited in steps reuses the settings window's navigation and help, so the two read as the same kind of surface.
**Approved**: pending

**Decision**: The close button is Cancel, and the window refuses to close itself.
**Rationale**: Closing must answer the owner exactly once, so the one `finish` path takes the window down.
**Approved**: pending

**Decision**: OK either finishes or hands over to `onOK`, which disables OK until the owner re-enables it or finishes.
**Rationale**: An owner that saves asynchronously needs one save in flight; Return is refused with the button.
**Approved**: pending

**Decision**: `present()` starts the modal session on the next run-loop pass, not inside the call.
**Rationale**: A caller running as a main-queue block would otherwise hold the main queue for as long as the dialog is up, and every await the dialog's own work makes on the main actor would wait for it to close.
**Approved**: pending

**Decision**: The dialog keeps a reference to itself from present, show or beginSheet until it finishes.
**Rationale**: A window does not keep its own controller, so an owner that presents and lets go would lose the dialog before its modal session starts.
**Approved**: pending

**Decision**: Finishing a running modal session also posts an application-defined event.
**Rationale**: Stopping the session takes effect when the loop next handles an event; an OK that completes from an awaited save comes from no event.
**Approved**: pending

**Decision**: The sheet is ended before `onFinish` is called.
**Rationale**: The owner can then begin the next sheet on the same window from within `onFinish`.
**Approved**: pending

**Decision**: A sheet has no toolbar; help moves to a round help button at the bottom left, and the problem line shifts right of it.
**Rationale**: A toolbar does not belong in a sheet; the topics stay in the sidebar.
**Approved**: pending

**Decision**: The dialog's sidebar width and help-drawer memory are stored apart from the settings window's.
**Rationale**: A dialog is smaller, and the settings window's remembered width would take most of it.
**Approved**: pending

**Decision**: Topics are not sorted and have no search field, and a single topic hides the list.
**Rationale**: The topics are steps in one task, in the order given, and few enough that a search field would only take room; one topic is the whole dialog.
**Approved**: pending

**Decision**: The owner's closures are released on finish.
**Rationale**: The dialog is done with what the owner captured; releasing avoids retain cycles.
**Approved**: pending

**Decision**: The dialog is not minimizable.
**Rationale**: It holds up the app until answered.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The dialog does one job: gather an answer through topics and a footer,
leaving validation and saving to its owner through closures, so separation of
concerns passes. A test file beside the source covers the footer, validation,
single-answer, close, hand-over, self-retention and sheet paths, so unit test
coverage passes, though the app-modal run itself has no test. Return and
Escape are bound to OK and Cancel, so keyboard navigation passes. Screen
reader support is partial: the buttons and the help button are labelled, but
a new problem line is not announced. Standard push buttons, a standard help
button, sheets and modal sessions are native, so native controls preference
passes. The Cancel and Help strings and the default OK title are literals in
source, so hardcoded strings fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Review markers in one-line form |
