
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

