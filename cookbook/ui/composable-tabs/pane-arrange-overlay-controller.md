---
id: f174fc81-410d-412f-9b17-0d16fff16816
title: "Pane Arrange Overlay Controller"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Arrange mode for one pane: the scrim and toolbar over it, the arrow, Return and Escape keys that drive it, and the title bar toggle and accessory helpers."
platforms:
  - swift
  - macos
tags:
  - component
  - composable-tabs
  - ui
depends-on:
  - 0640ca96-95c5-4234-925e-386425cc4435
  - 2b4d0f95-dbdf-48a9-8579-a3e5b7d488fe
related: []
references:
  - https://learn.microsoft.com/en-us/windows/apps/design/keyboard-interactions/keyboard-accelerators
approved-by: ""
approved-date: ""
---

# Pane Arrange Overlay Controller

## Overview

The file holds three types around arrange mode, the window-wide mode in which the panes of a [Composable Tabs](cookbook:0640ca96-95c5-4234-925e-386425cc4435) tab can be moved, added and removed. `PaneArrangeOverlayController` is one pane's side of the mode: while the pane's window is arranging, it covers the pane with a scrim and toolbar (`ComposableTabsArrangeOverlayView`) inside the active-pane border and installs the keys that drive the mode. Arrows move the selected pane; Return, Enter and Escape leave the mode. Any pane on a `ComposableTabsPaneBackgroundView` uses it, whatever holds the pane: a project window's tree and the Coding Partner's two fixed panes ask different questions about what a pane may do and answer through the controller's closures, while the mode, the overlay and the keys are one thing. `ArrangeModeTitlebarButton` is the title bar toggle for the mode, tinted with the accent color while the mode is on. `WindowTitlebarAccessory` builds the 14-point symbol buttons, installs them right-aligned in a window's title bar and applies the integrated title bar a project-style window wears. The pane itself is described in [Pane View](cookbook:2b4d0f95-dbdf-48a9-8579-a3e5b7d488fe).

## Behavioral Requirements

- **follow-mode-for-own-window**: The controller MUST update its overlay when the arrange mode changes for the window that holds its pane, and MUST ignore a change for any other window.
- **install-overlay-when-arranging**: While arrange mode is on in the pane's window, the controller MUST have exactly one overlay installed over the pane.
- **remove-overlay-when-not-arranging**: When arrange mode is off in the pane's window, the controller MUST remove its overlay.
- **reinstall-on-reentry**: `update()` MUST install the overlay again when the pane is re-hosted while the mode is on, so the pane comes back with the scrim it left with.
- **overlay-inside-border**: The overlay MUST sit above the pane's content and inset from each edge of the pane view by `ComposableTabsPaneBackgroundView.borderInset`, so it stays inside the active-pane border.
- **overlay-reflects-pane**: The overlay MUST be given the pane's name, whether it offers add and remove, and closures for whether the pane can add, can remove and which directions it can move, and for adding, removing and moving.
- **overlay-done-leaves-mode**: The overlay's done action MUST turn arrange mode off in the pane's window.
- **refresh-availability-on-layout-change**: The controller MUST refresh the overlay's availability whenever any tab's layout changes, because a pane moving changes what every other pane may do.
- **remove-on-window-close**: The controller MUST remove its overlay and key monitor when its pane's window closes, even if the window never left arrange mode.
- **exit-keys**: While arrange mode is on in the pane's window, Return (key code 36), Enter (key code 76) and Escape (key code 53) MUST turn the mode off and be consumed.
- **exit-is-idempotent**: Turning the mode off MUST be a no-op when it is already off, since every pane in the window has its own key monitor and each one runs.
- **arrow-moves-selected-pane**: While arrange mode is on, an arrow key MUST call the move action with the matching direction only in the pane that is the window's active pane, and be consumed.
- **unselected-pane-ignores-arrows**: A pane that is not the window's active pane MUST NOT move on an arrow key and MUST NOT consume it.
- **keys-ignored-outside-pane-window**: A key event whose window is not the pane's window MUST be left unconsumed, so a sheet's Escape cancels the sheet and not the mode behind it.
- **keys-ignored-when-not-arranging**: A key event while arrange mode is off in the pane's window MUST be left unconsumed.
- **monitor-sees-keys-before-content**: The key handling MUST see key events before the pane's content does, so a content view that holds first responder cannot swallow an arrow.
- **single-monitor**: The controller MUST hold at most one key monitor, and remove it when the overlay is removed.
- **toggle-button-toggles-mode**: Pressing the title bar toggle button MUST toggle arrange mode in the attached window.
- **toggle-button-follows-mode**: The toggle button MUST show the accent color as its content tint and the on state while arrange mode is on in its window, and no tint and the off state otherwise, whether the mode was changed by the button or by another control such as the Window menu.
- **toggle-button-identity**: The toggle button MUST use the symbol `rectangle.3.group`, the accessibility description "Arrange Panes", the tooltip "Arrange panes" and the accessibility identifier it is given.
- **titlebar-button-size**: A button from `makeButton` MUST use a 14-point regular-weight symbol, image-only, textured rounded bezel, in a 36 by 24 point frame with the given tooltip, target and action.
- **install-accessory-right-aligned**: `install(_:in:)` MUST add the buttons in a horizontal stack with 4 points between them, as a right-aligned title bar accessory of width 40 points per button and height 24 points, and return the accessory.
- **integrated-titlebar**: `applyIntegratedTitlebar(to:)` MUST set a unified toolbar style, a transparent title bar, no title bar separator, the project pane backdrop as window background and disallowed native tabbing.

## Appearance

- **Corner radius**: Not applicable: the overlay's appearance is defined by `ComposableTabsArrangeOverlayView`, outside this file.
- **Padding**: The overlay is inset by `ComposableTabsPaneBackgroundView.borderInset` from each edge of the pane view (2 points in the source). The title bar stack has 4 points of spacing.
- **Font**: Not applicable: the file sets no text style.
- **Background**: The overlay's scrim is drawn by `ComposableTabsArrangeOverlayView`. The integrated title bar sets the window background to the theme palette's project pane backdrop color.
- **Foreground/Text**: The toggle button's content tint is the palette's accent color while the mode is on and the system default otherwise.
- **Border**: None set here; the overlay stays inside the active-pane border.
- **Shadow**: None.
- **Min/Max size**: A title bar button is 36 by 24 points with a 14-point symbol; the accessory is 40 points wide per button and 24 points tall.

## States

| State | Appearance change |
|-------|------------------|
| Default | No overlay on the pane, no key monitor, toggle button untinted and off. |
| Arranging | The overlay covers the pane inside its border, the key monitor is installed and the toggle button is tinted with the accent color and on. |
| Selected pane | Only the window's active pane acts on an arrow key. |
| Pressed | The toggle button is pressed by the system; this file adds no pressed styling. |
| Disabled | Not applicable: nothing in the file disables the overlay or the toggle button; whether a pane can add, remove or move is expressed through the closures and shown by the overlay. |
| Loading | Not applicable: the overlay is installed synchronously from the mode. |
| Window closing | The overlay and key monitor are removed without the mode having been turned off. |

## Accessibility

- **Role/trait**: The toggle is a standard `NSButton` with an image-only appearance; the overlay's controls are in `ComposableTabsArrangeOverlayView`.
- **Label requirements**: The toggle's symbol carries the accessibility description "Arrange Panes", and the button has the tooltip "Arrange panes" and the accessibility identifier it is initialized with.
- **Announce state changes**: NEEDS REVIEW: Not implemented in source. The toggle's on and off state is set on the button and shown by tint, but no announcement of entering or leaving arrange mode is made and the tint is the only mode indicator on the button; a VoiceOver pass and the overlay view's own labels would settle whether the mode is conveyed another way.
- **Keyboard**: Arrow keys move the selected pane, and Return, Enter and Escape leave the mode, as above.
- **Minimum tap target**: NEEDS REVIEW: Not implemented in source. The toggle is 36 by 24 points. Whether a 24-point-tall target is acceptable is the platform guideline's call and the source cannot decide it.

## Conformance Test Vectors

No test beside the source exercises these types (the test bundles contain no reference to them), so these vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-arrange-001 | follow-mode-for-own-window, install-overlay-when-arranging | Attach a controller to a pane view in window W; turn arrange mode on in W | One overlay is installed over the pane |
| pane-arrange-002 | follow-mode-for-own-window | With the controller attached to a pane in W, turn arrange mode on in another window | The pane's overlay is not installed |
| pane-arrange-003 | remove-overlay-when-not-arranging | From the arranging state, turn the mode off in W | The overlay is removed and the key monitor is removed |
| pane-arrange-004 | install-overlay-when-arranging | Turn the mode on, then call `update()` again | Still exactly one overlay, with its availability refreshed |
| pane-arrange-005 | reinstall-on-reentry | Turn the mode on, re-host the pane so its overlay is lost, then call `update()` from `viewDidAppear` | The overlay is installed again |
| pane-arrange-006 | overlay-inside-border | Install the overlay on a pane view of 400 by 300 points | The overlay's frame is inset 2 points from each edge, 396 by 296 points |
| pane-arrange-007 | overlay-reflects-pane | Set `paneName` to "Terminal", `canRemove` to true and `offersAddRemove` to false, then install | The overlay shows the name "Terminal", reports can-remove true and does not offer add and remove |
| pane-arrange-008 | overlay-done-leaves-mode | Trigger the overlay's done action | Arrange mode is off in W |
| pane-arrange-009 | refresh-availability-on-layout-change | Post a layout-change notification while the overlay is installed | The overlay's availability is refreshed |
| pane-arrange-010 | remove-on-window-close | While arranging, close W | The overlay and key monitor are removed without the mode having been turned off first |
| pane-arrange-011 | exit-keys | While arranging in W, send keyDown with key code 36, then in a new arranging session 76, then 53 | Each turns the mode off and is consumed |
| pane-arrange-012 | exit-is-idempotent | With three panes in W, press Escape | The mode ends and every pane's handler runs without a second change notification |
| pane-arrange-013 | arrow-moves-selected-pane | Pane P is the active pane of W; send keyDown with key code 123 | `onMove` is called once with the left direction and the event is consumed |
| pane-arrange-014 | arrow-moves-selected-pane | Same, with key codes 124, 125 and 126 | `onMove` is called with right, below and above respectively |
| pane-arrange-015 | unselected-pane-ignores-arrows | Pane Q is not the active pane; send an arrow key | Q's `onMove` is not called and Q does not consume the event |
| pane-arrange-016 | keys-ignored-outside-pane-window | A sheet is up so the key event's window is not W; send Escape | The mode stays on and the event is passed on |
| pane-arrange-017 | keys-ignored-when-not-arranging | Arrange mode is off; send Return | The event is not consumed |
| pane-arrange-018 | monitor-sees-keys-before-content | A terminal in the pane holds first responder; send an arrow key while P is active | `onMove` is called and the terminal does not receive the key |
| pane-arrange-019 | single-monitor | Install the overlay twice | One key monitor exists |
| pane-arrange-020 | toggle-button-toggles-mode, toggle-button-follows-mode | Attach the toggle button to W and press it | The mode is on, the button is tinted with the accent color and in the on state |
| pane-arrange-021 | toggle-button-follows-mode | Turn the mode on from the Window menu | The button becomes tinted and on without being pressed |
| pane-arrange-022 | toggle-button-identity | Create the button with identifier `window.toggle` | Its identifier is `window.toggle`, its tooltip "Arrange panes" and its symbol description "Arrange Panes" |
| pane-arrange-023 | titlebar-button-size | Call `makeButton` with any symbol and tooltip | The frame is 36 by 24 points, the bezel textured rounded, the position image only |
| pane-arrange-024 | install-accessory-right-aligned | Install two buttons in a window | The accessory stack is 80 by 24 points with 4 points of spacing and is laid out on the right |
| pane-arrange-025 | integrated-titlebar | Call `applyIntegratedTitlebar(to:)` | The toolbar style is unified, the title bar transparent, the separator style none, tabbing disallowed and the background the palette's backdrop color |

## Edge Cases

- **Null and empty input**: A controller whose pane view has no window MUST treat the mode as off: `isEnabled(in:)` answers false for a nil window and the key handler returns unconsumed. A pane with no name closure set uses the default empty name; the default closures answer false and an empty direction set.
- **Boundary values**: An arrow key whose code matches no direction MUST pass through unconsumed. Keys other than Return, Enter, Escape and the four arrows MUST pass through unconsumed.
- **Reentrant install**: Calling `install` with an overlay present MUST refresh its availability and install nothing more.
- **Concurrent access**: The controller is `@MainActor`, but the key monitor's closure is not isolated, so it hands the work to the main actor with `MainActor.assumeIsolated` and only the consumed flag crosses back out, because the event type is not `Sendable`. Every pane in a window has a monitor, so one key press runs several handlers; turning the mode off twice is a no-op and only the active pane acts on an arrow.
- **Error states**: Not applicable: the controller calls no dependency that can fail; a pane view or window that has gone away stops the handlers by their guards.
- **Offline or disconnected state**: Not applicable: the controller performs no network access.
- **Teardown**: A `deinit` cannot remove the monitor because it is nonisolated, so the monitor is removed on window close or when the overlay is removed; a window that closes without leaving the mode MUST NOT leak the monitor.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nodeID` | `UUID` | required | The layout node naming the pane to the active-pane tracker. |
| `paneName` | `() -> String` | empty string | The pane's name shown by the overlay. |
| `canAdd` | `() -> Bool` | false | Whether the pane can add a neighbor. |
| `canRemove` | `() -> Bool` | false | Whether the pane can be removed. |
| `availableDirections` | `() -> Set<Direction>` | empty set | Directions the pane can move. |
| `offersAddRemove` | `Bool` | true | Whether the overlay offers add and remove. |
| `onAdd` | `() -> Void` | does nothing | Called when the overlay's add action is chosen. |
| `onRemove` | `() -> Void` | does nothing | Called when the overlay's remove action is chosen. |
| `onMove` | `(Direction) -> Void` | does nothing | Called with the direction for an overlay move or an arrow key. |
| `accessibilityID` (button) | `String` | required | Identifier of the title bar toggle, naming the window it sits in. |

## Deep Linking

Not applicable: the file has no URL routing.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Arrange Panes | Toggle symbol accessibility description |
| none (literal) | Arrange panes | Toggle tooltip |

- **string-externalization**: NEEDS REVIEW: Not implemented in source. The two strings are literals with no string table lookup; the owner's localization approach for macOS UI strings would settle whether they move to a table.

## Accessibility Options

Not applicable: the file sets no animation and no contrast behavior of its own; the toggle's accent tint comes from the theme palette.

## Feature Flags

Not applicable: the file has no feature flag logic.

## Analytics

Not applicable: the file performs no analytics tracking.

## Privacy

- **Data collected**: None. The key monitor reads key codes of events in the pane's own window and records nothing.
- **Storage**: None.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the file performs no logging.

## Platform Notes

- **SwiftUI**: Model arrange mode as an `@Observable` per-window object in the environment. Draw the scrim and toolbar as a `ZStack` overlay on the pane with `.overlay` and `.padding(2)`, drive keys with `.onKeyPress(.upArrow)`, `.onKeyPress(.escape)` and the other arrows on a focusable container, and make the toggle a toolbar `Button` or `Toggle` with `Image(systemName: "rectangle.3.group")` and `.tint`. Differs from the source: `onKeyPress` sees keys only when the container has focus, so a content view that owns focus will take them; there is no local event monitor equivalent short of `NSEvent` bridging.
- **Compose**: Hold the mode in a `ViewModel` flow and draw the scrim as a `Box` overlay over the pane. Handle keys with `Modifier.onPreviewKeyEvent`, which sees events before the content (Key.DirectionLeft, Key.Escape, Key.Enter) and return true to consume. Differs from the source in that preview key events travel the focus path, so the focused node must be inside the pane tree.
- **React/Web**: Use a context holding the mode, an absolutely positioned overlay with a 2px inset inside the pane, and a `keydown` listener added in the capture phase on `window` (so it runs before the content) that checks `event.key` for ArrowLeft, ArrowRight, ArrowUp, ArrowDown, Enter and Escape, calls `preventDefault` and `stopPropagation` when it acts, and removes itself in the effect cleanup. Differs from the source: there is no sheet window distinction, so ignore events whose target is inside a dialog.
- **AppKit / UIKit**: `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/PaneArrangeOverlayController.swift` is the implementation: a `@MainActor` class using `NotificationCenter` publishers (Combine) for the mode, layout and window close, `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` for keys, `MainActor.assumeIsolated` to cross the isolation boundary, and Auto Layout constraints to inset the overlay. `ArrangeModeTitlebarButton` and `WindowTitlebarAccessory` (an `NSButton` with an SF Symbol, an `NSStackView` and an `NSTitlebarAccessoryViewController` at `.right`) are in the same file. UIKit would use `UIKeyCommand` and `pressesBegan` instead of a local monitor.
- **WinUI 3**: Start with a `Grid` overlay (`Margin="2"`, `Background` as a semi-transparent brush, `Visibility` bound to the arrange mode) placed above the pane content in the pane's root `Grid`. For keys, add `KeyboardAccelerator` objects (`Key="Left"`, `Right`, `Up`, `Down`, `Enter`, `Escape`) to the window content's `KeyboardAccelerators`, with `ScopeOwner` set to the pane root, or handle `UIElement.PreviewKeyDown` on the pane root, which sees key events before a focused child's `KeyDown`; set `e.Handled = true` to consume. Check `e.OriginalSource` against the content window, and use the `XamlRoot` of a `ContentDialog` to tell that a dialog is up, since it has its own root and its Escape closes the dialog first. For the toggle use a `ToggleButton` (`FontIcon` or `SymbolIcon`, `ToolTipService.ToolTip="Arrange panes"`, `AutomationProperties.Name="Arrange Panes"`) in the title bar region, with its checked state bound to the mode and the checked visual state (`Checked`, `CheckedPointerOver`, `CheckedPressed`) styled with the accent brush. For the integrated title bar, set `ExtendsContentIntoTitleBar = true` and `SetTitleBar(dragRegion)`, with `AppWindow.TitleBar.ButtonBackgroundColor` transparent and the backdrop brush behind it. Differs from the source: WinUI 3 has no process-wide local event monitor, so every pane needs a handler on its own root (a single handler on the window content is the cleaner composition and removes the need for the idempotent exit), and unhooking on `Unloaded` or window `Closed` plays the role of the window-close removal.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/PaneArrangeOverlayController.swift` | confirmed (1.0.1) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

- **Decision**: Use a local key event monitor instead of `keyDown` on the pane.
  **Rationale**: The source comment states the pane's content owns the first responder (a terminal, an editor) and would eat the arrow long before the pane saw it.
  **Approved**: pending

- **Decision**: Treat Return, Enter and Escape as the same action, leaving the mode.
  **Rationale**: The source comment states the mode is what they dismiss, and which of the three a person reaches for is a habit, not a distinction worth honouring.
  **Approved**: pending

- **Decision**: Give every pane its own monitor but let only the window's active pane move on an arrow key.
  **Rationale**: The source comments state every pane in the window has a monitor, so exit runs more than once and turning the mode off twice is a no-op, while only the pane the user selected moves.
  **Approved**: pending

- **Decision**: Ignore key events that do not belong to the pane's own window.
  **Rationale**: The source comment states a different window means a sheet is up, and Escape there cancels the sheet rather than the mode behind it.
  **Approved**: pending

- **Decision**: Remove the monitor on window close and on overlay removal, not in `deinit`.
  **Rationale**: The source comment states a closing window takes its panes with it without ever leaving arrange mode, and a `deinit` cannot touch the monitor because it is nonisolated.
  **Approved**: pending

- **Decision**: Refresh availability from the tree on every layout change instead of from the pane that acted.
  **Rationale**: The source comment states any pane moving changes what every other pane may do.
  **Approved**: pending

- **Decision**: Return only the consumed flag out of the key monitor's closure.
  **Rationale**: The source comment states `assumeIsolated` hands its result across an isolation boundary and the event type is not `Sendable`.
  **Approved**: pending

- **Decision**: Make the toggle button follow the mode, not the click.
  **Rationale**: The doc comment states the mode can also be turned on from the Window menu, so the tint follows the mode.
  **Approved**: pending

- **Decision**: Take the controller's pane questions as closures rather than a fixed pane type.
  **Rationale**: The doc comment states a project window's tree and the Coding Partner's two fixed panes ask different questions about what a pane may do while the mode, overlay and keys are one thing.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |

`separation-of-concerns` passes because the mode, the overlay view, the pane's questions and the key handling are separate, joined by closures and notifications. `unit-test-coverage` fails because no test in the test bundles references these types. `keyboard-navigable` passes because arrows, Return, Enter and Escape drive the mode. `screen-reader-support` is partial because the toggle has a description and tooltip but the open question on `Announce state changes` records that no mode change is announced. `touch-target-size` is partial because the toggle is 36 by 24 points and the open question on `Minimum tap target` records that the source cannot decide it. `no-hardcoded-strings` fails because the toggle strings are literals. `state-recovery` passes because the overlay is reinstalled when a pane is re-hosted and removed when the window closes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Review markers in one-line form |
