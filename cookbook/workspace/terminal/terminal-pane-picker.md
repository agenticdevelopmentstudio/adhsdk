---
id: 27310902-e328-4bdf-9d3c-23f027be7af4
title: "Terminal Pane Picker"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A floating panel that catches window clicks until the user clicks a terminal pane to connect to, outlines the pick and confirms it, or is cancelled."
platforms:
  - swift
  - macos
tags:
  - terminal
  - picker
  - composable-tabs
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Pane Picker

## Overview

A click-to-choose control for a terminal pane. A small movable panel titled "Connect to Terminal" appears over the window and asks the user to click on a terminal. While it runs, every left click in the host window is caught and treated as a choice, and nothing else in the window reacts to it. A click on a pane whose content offers the terminal-pane-connectable contract is a pick, whether or not that terminal is running; the picked pane is outlined, the panel confirms the choice by name and its button becomes OK. A click on any other pane says so and the picker keeps waiting. A click outside every pane is ignored. Cancel or Escape ends the pick without a choice. The picker reports a pick once and reports when the panel has closed, which is the moment for its owner to let it go. Starting the picked pane's terminal is the connection's business, not the picker's.

## Behavioral Requirements

- **panel-title**: The panel MUST be titled "Connect to Terminal".
- **panel-style**: The panel MUST be a titled utility panel, 320 by 110 points initially, that floats above the host window, can be moved by dragging its background, stays visible when the app is not active and is not released when closed.
- **panel-key-only-if-needed**: The panel MUST become the key window only if needed.
- **initial-message**: The panel MUST initially show the centered message "Click on a terminal to connect to." in a label 280 points wide.
- **initial-button**: The panel MUST initially show a rounded button titled "Cancel" whose key equivalent is Escape.
- **panel-layout**: The message and button MUST be stacked vertically, centered horizontally, 14 points apart, inside insets of 18 points top, 20 leading, 16 bottom and 20 trailing.
- **begin-placement**: WHEN the pick begins, the panel MUST be centered over the host window's frame and ordered to the front.
- **begin-catches-clicks**: WHEN the pick begins, the picker MUST install a local monitor for left mouse-down and key-down events.
- **begin-no-window**: WHEN the pick begins and the host window no longer exists, the picker MUST finish at once without putting the panel up.
- **host-window-weak**: The picker MUST NOT keep the host window alive.
- **click-in-host-window**: WHILE no pick has been made, a left click whose window is the host window MUST be handled as a choice and MUST NOT be delivered to the window.
- **click-elsewhere-passes**: A left click in any other window MUST pass through unchanged, and so MUST a left click in the host window after a pick has been made.
- **panes-asked-live**: The picker MUST ask for the panes on offer each time a click is handled, so the answer follows the layout.
- **hit-test**: A click MUST choose the first offered pane whose view is loaded, is in the host window and contains the click point; a click outside every such pane MUST be ignored, and the picker MUST keep waiting.
- **not-a-terminal**: WHEN the clicked pane's content is not terminal-pane-connectable, the message MUST change to "That isn't a terminal. Click on a terminal to connect to." and the picker MUST keep waiting.
- **running-not-required**: A pane whose content is terminal-pane-connectable MUST be pickable whether or not its terminal is running.
- **pick-effect**: WHEN a connectable pane is clicked, the picker MUST mark the pick as made, outline the pane, set the message to "Connected to <pane title>.", set the button title to "OK", and make Return its key equivalent.
- **pick-report**: WHEN a connectable pane is clicked, the picker MUST report the pane and its connectable content through its pick callback.
- **pick-once**: The picker MUST accept only one pick; further clicks in the host window after the pick MUST pass through.
- **outline-style**: The outline MUST be a ring 3 points wide with a corner radius of 4 points in the system accent color, over a fill of the accent color at 8 percent opacity, covering the picked pane's bounds and resizing with it.
- **outline-transparent**: The outline MUST let every click through and MUST NOT be an accessibility element.
- **escape-ends**: WHEN the Escape key (key code 53) is pressed anywhere, the picker MUST finish without a choice and MUST consume the key.
- **return-ends-after-pick**: WHEN a pick has been made and Return or keypad Enter (key codes 36 and 76) is pressed anywhere, the picker MUST finish and MUST consume the key.
- **other-keys-pass**: Any other key MUST pass through unchanged, and Return before a pick MUST pass through.
- **button-ends**: Pressing the panel's button, labeled Cancel before a pick and OK after, MUST finish the picker.
- **cancel-api**: The picker MUST offer a cancel call that ends it without a choice, as the button does.
- **finish-cleanup**: WHEN the picker finishes, it MUST remove the event monitor, remove the outline, take the panel off screen, clear the pick callback and clear the finish callback.
- **finish-callback-once**: WHEN the picker finishes, it MUST call the finish callback exactly once, after cleanup.
- **finish-idempotent**: Finishing a second time MUST NOT call the finish callback again.
- **identifiers**: The panel, message and button MUST carry the accessibility identifiers "terminalPanePicker", "terminalPanePicker.message" and "terminalPanePicker.button".
- **main-actor**: The picker MUST be used on the main actor.
- **no-coder-init**: The outline view MUST NOT be creatable from an archive.
- **message-announcement**: NEEDS REVIEW: Not implemented in source. The picker changes its message text on a wrong click and on a pick but never posts an accessibility announcement; a check that assistive technology reads the changed message would settle whether the label announces its changes.

## Appearance

- **Panel size**: 320 by 110 points initially, utility-window title bar, titled "Connect to Terminal".
- **Panel placement**: Centered over the host window.
- **Content padding**: 18 points top, 20 leading, 16 bottom, 20 trailing; 14 points between the message and the button.
- **Message**: Centered wrapping label, 280 points wide.
- **Button**: Rounded bezel; "Cancel" before a pick, "OK" after.
- **Outline border**: 3 points, the system accent color, corner radius 4 points.
- **Outline fill**: The system accent color at 8 percent opacity.
- **Shadow**: None set by the source.

## States

| State | Appearance change |
|-------|------------------|
| Default (not begun) | Panel off screen; no monitor; no outline. |
| Waiting | Panel up; message "Click on a terminal to connect to."; button "Cancel". |
| Wrong pick | Message "That isn't a terminal. Click on a terminal to connect to."; still waiting. |
| Picked | Pane outlined; message "Connected to <pane title>."; button "OK" with Return as its key equivalent; clicks in the host window pass through. |
| Finished | Panel off screen; monitor and outline removed; callbacks cleared. |
| Pressed / Focused | Not applicable: the button is a standard rounded system button and the source sets no custom pressed or focused appearance. |
| Disabled | Not applicable: the source never disables the button. |
| Loading | Not applicable: the picker does no asynchronous work. |

## Accessibility

- **identifiers**: The panel, message and button have stable accessibility identifiers, "terminalPanePicker", "terminalPanePicker.message" and "terminalPanePicker.button".
- **button-keyboard**: The button's key equivalent is Escape while waiting and Return after a pick; Escape also ends the pick from whichever window has the keyboard.
- **outline-hidden**: The outline is not an accessibility element and lets all clicks through.
- **button-label**: The button's visible title is its label, "Cancel" or "OK".
- **pointer-only-choice**: NEEDS REVIEW: Not implemented in source. Choosing a pane is only possible by clicking it; the source gives no keyboard or assistive route to pick a pane, and a review of the platform's full-keyboard-access expectations would settle whether one is needed.

## Conformance Test Vectors

No test in the repository targets this picker; the vectors below are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-picker-001 | panel-title, panel-style, initial-message, initial-button, identifiers | Create the picker | A 320 by 110 utility panel titled "Connect to Terminal" with message "Click on a terminal to connect to." and a "Cancel" button, with the three identifiers set. |
| terminal-picker-002 | begin-placement, begin-catches-clicks | Call begin on a picker over a host window | The panel is centered on the host window frame and in front, and left clicks and key presses are monitored. |
| terminal-picker-003 | begin-no-window | Host window has been released, then begin is called | The finish callback is called and no panel is shown. |
| terminal-picker-004 | click-in-host-window, hit-test, pick-effect, pick-report, outline-style | Click inside a pane whose content is connectable | The click is consumed; the pane is outlined; message "Connected to <title>."; button "OK"; the pick callback receives the pane and its content. |
| terminal-picker-005 | not-a-terminal | Click inside a pane whose content is not connectable | Message "That isn't a terminal. Click on a terminal to connect to."; no pick callback; still waiting. |
| terminal-picker-006 | hit-test | Click in the host window outside every offered pane | The click is consumed and nothing else changes. |
| terminal-picker-007 | running-not-required | Click a connectable pane whose terminal has not started | The pane is picked. |
| terminal-picker-008 | click-elsewhere-passes | Click in a window other than the host window | The click is delivered unchanged. |
| terminal-picker-009 | pick-once, click-elsewhere-passes | After a pick, click again in the host window | The click is delivered unchanged and no second pick is reported. |
| terminal-picker-010 | escape-ends, finish-cleanup, finish-callback-once | Press Escape while waiting | The key is consumed, the monitor and outline are removed, the panel is off screen, and the finish callback is called once. |
| terminal-picker-011 | return-ends-after-pick, other-keys-pass | Press Return before a pick, then after a pick | Before: the key passes through; after: the picker finishes and the key is consumed. |
| terminal-picker-012 | button-ends, cancel-api, finish-idempotent | Press the button, then call cancel | The picker finishes once; the second call does not call the finish callback again. |
| terminal-picker-013 | panes-asked-live | Change the layout between two clicks | The second click is tested against the panes returned at that moment. |
| terminal-picker-014 | outline-transparent | Hit-test a point inside the outline of a picked pane, and query the outline's accessibility | The outline's hit test returns no view, so it never receives the click, and it is not an accessibility element. |
| terminal-picker-015 | host-window-weak | Release the host window while the picker is held | The picker does not keep the window alive. |

## Edge Cases

- **Host window gone at begin (MUST)**: The picker finishes at once without a panel.
- **Click on a pane not in the host window (MUST)**: Panes whose view is not in the host window are skipped.
- **Pane with an unloaded view (MUST)**: Skipped, because only loaded views are tested.
- **Overlapping panes (MUST)**: The first offered pane whose bounds contain the point wins.
- **Click outside every pane (MUST)**: Consumed and ignored; the picker keeps waiting.
- **Cancel after finish (MUST)**: Calls no callback, because both callbacks were cleared; the cleanup steps run again with nothing left to remove.
- **Picker owner discards it early (MUST)**: Calling cancel ends the pick, removes the monitor and outline and takes the panel down.
- **Concurrent access**: The picker is main-actor isolated and its monitor handler runs on the main thread; no other concurrency is defined.
- **Offline or disconnected state**: Not applicable: the picker is in-process and uses no network.
- **Null and empty input**: An empty list of panes means every click is ignored.
- **Boundary values**: Not applicable: no numeric input beyond fixed panel and outline sizes.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| window | window | required | The window whose panes can be picked; held weakly. |
| panes | closure returning panes | required | The panes on offer, asked again on every click. |
| onPick | callback with pane and connectable content | none | Called once, when the user picks a terminal pane. |
| onFinish | callback | none | Called once, when the panel has closed, picked or cancelled. |

## Deep Linking

Not applicable: the picker is a transient panel and registers no URL or scheme.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Connect to Terminal | Panel title |
| none (literal) | Click on a terminal to connect to. | Initial message |
| none (literal) | That isn't a terminal. Click on a terminal to connect to. | Wrong pick |
| none (literal) | Connected to <pane title>. | After a pick |
| none (literal) | Cancel | Button before a pick |
| none (literal) | OK | Button after a pick |

- **string-localization**: NEEDS REVIEW: Not implemented in source. Every user-visible string is an English literal with no localization lookup; a decision on the host's supported languages would settle it.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the picker runs no animation. |
| Increase Contrast | Not applicable: the outline uses the system accent color, which the system adjusts; the source adds no handling of its own. |
| Differentiate Without Color | The pick is shown by the outline and by the message text and the changed button title, not by color alone. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics events.

## Privacy

- **Data collected**: None; the picker reads click locations only to find the pane under them.
- **Storage**: None.
- **Transmission**: None; the picked pane and its connectable content are passed to the owner's callback in-process.
- **Retention**: Not applicable: the picker keeps no data after it finishes, since it clears its callbacks and outline.

## Logging

Not applicable: the source declares no logger and writes no log entries.

## Platform Notes

- **SwiftUI**: Drive a state machine (waiting, wrong pick, picked) from an observable object; show the instruction in a floating panel or overlay and capture the choice with a full-window overlay that uses a gesture reading the click location against pane frames; the outline is a stroke and fill overlay with hit testing disabled.
- **Compose**: Use a full-screen Popup or a Box overlay with pointerInput consuming taps, compare the tap offset against each pane's bounds from onGloballyPositioned, and draw the outline with a border and a translucent background; Escape through onKeyEvent.
- **React/Web**: Use a fixed-position overlay with a capturing pointerdown listener on the document that calls preventDefault and stopPropagation, hit-test panes with getBoundingClientRect, add an outline element with pointer-events none and aria-hidden, and a role dialog panel with Escape and Enter handlers.
- **AppKit / UIKit**: Source platform. The file is `TerminalPanePicker.swift`: an NSPanel with an NSStackView, a local NSEvent monitor for left mouse-down and key-down, hit testing through converted view coordinates and a layer-backed outline view whose hit test returns nothing. UIKit has no local event monitor, so a transparent full-screen overlay with a tap recognizer would replace it.
- **WinUI 3**: Show the instruction in a small floating Window (or a Popup with a Grid) holding a TextBlock and a Button with Escape as an accelerator via KeyboardAccelerator; capture the choice by hooking PointerPressed on the host content with AddHandler and handledEventsToo set, mark the event handled, and hit-test each pane with VisualTreeHelper or TransformToVisual and ActualWidth and ActualHeight; draw the outline as a Border with BorderThickness 3, CornerRadius 4, the SystemAccentColor brush and an 8 percent opacity fill, IsHitTestVisible set to false and AutomationProperties.AccessibilityView set to Raw.

## Design Decisions

**Decision**: While the picker runs, every left click in the host window is caught and nothing else reacts to it.
**Rationale**: The source comment says nothing else in the window reacts to a click meant as a choice.
**Approved**: pending

**Decision**: Any connectable pane can be picked whether or not its terminal is running.
**Rationale**: Starting its terminal is the connection's business, not the picker's.
**Approved**: pending

**Decision**: After a pick the panel stays up with a confirmation and an OK button, and Return finishes it.
**Rationale**: The panel confirms the choice by naming the pane while the pane is outlined, so the user sees what was chosen before it closes.
**Approved**: pending

**Decision**: The panes are asked for again on every click.
**Rationale**: The answer follows the layout as panes are added or closed.
**Approved**: pending

**Decision**: The panel is floating, key only if needed and not hidden on deactivate.
**Rationale**: It must stay in view above the window while the user clicks a pane in that window, without taking the keyboard from it.
**Approved**: pending

**Decision**: The owner is told when the panel has closed, not when the pick is made.
**Rationale**: The source says to hold on to the picker while it runs and release it when it reports it finished.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |

The picker finds the pane and reports it, leaving connecting, starting and remembering to its owner, so separation of concerns passes. No test in the repository targets it, so unit-test coverage fails. Its strings are English literals, so the hardcoded-strings check fails. Escape and Return work from any window and the button is a standard control, but choosing a pane needs a pointer, so keyboard navigation is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
