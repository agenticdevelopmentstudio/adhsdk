---
id: 9c1e6915-44ec-435e-a159-57b80b455698
title: "Window Options Dialog"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "App-modal dialog for a window's own appearance settings, built from host state at open time and centered on screen."
platforms:
  - swift
  - macos
tags:
  - ui
  - modal
  - window-chrome
depends-on:
  - 56388aa3-bc75-4d0a-830b-222f39750a9d
related:
  - 972be0d0-a9f5-45cd-a23b-c8329410b3d1
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
  - a105b6cf-307d-4156-8b73-468f627f3c9b
  - 25816370-14ff-454a-83d4-ebd588a2ff01
references: []
approved-by: ""
approved-date: ""
---

# Window Options Dialog

## Overview

The Window Options Dialog is a modal dialog system for managing window-specific appearance settings — distinct from application-wide settings. It is presented via a gear button positioned in the window's title bar chrome or custom layout. The dialog itself is app-modal: the window behind it remains visible, and MAY still change on screen, but only as a side effect of the dialog's own controls driving host state — the host window itself is blocked from receiving keyboard or mouse input while the dialog is up. The dialog is centered on the screen (not anchored to the gear), and dynamically built at open time from a host-supplied closure. This design allows live updates to controls as underlying state changes and ensures the dialog follows the host window's level hierarchy.

The component comprises four related pieces: the dialog manager (`WindowOptionsDialog`), an optional slider with live caption (`WindowOptionsSlider`), an optional toggle/checkbox (`WindowOptionsToggle`), and an optional "Reset to Defaults" button (`WindowOptionsResetButton`).

## Behavioral Requirements

- **present-modal**: The dialog MUST be presented as an app-modal window: interaction with the host window and every other app window MUST be blocked (mouse and keyboard) for as long as it is open, even though the host window remains visible and MAY still change on screen — but only as a side effect of the dialog's own controls driving host state, never from direct user interaction with the host.
- **center-on-screen**: The dialog MUST be positioned at the center of the screen the host window is on when it opens, not anchored to the gear button or positioned relative to the host window's frame. The position is computed once, at open time; it is not recomputed while the dialog remains open (see Edge Cases).
- **host-level-sync**: The dialog MUST adopt the host window's level (e.g., `.normal`, `.floating`) at open time and MUST continue tracking the host's level for as long as it stays open, moving with it whenever the host's level changes.
- **build-controls-at-open-time**: Controls MUST be built from the host's closure when the dialog is opened, not at construction time, allowing the host to read live state.
- **rebuild-on-title-change**: When the `title` property changes while the dialog is open, the dialog MUST call `rebuildControls()`, which re-invokes the host's `makeControls` closure and replaces the dialog's content, so every row — not only ones tied to the title — reflects current host state.
- **rebuild-controls-public**: `rebuildControls()` MUST be public API, callable directly by the host independently of a title change, so a host can force the dialog's rows to refresh whenever its own state changes while the dialog is open.
- **support-toggle**: The dialog MUST support a `toggle()` method that opens the dialog if closed and closes it if open.
- **support-present-close**: The dialog MUST support `present()` to open and `close()` to close independently.
- **track-shown-state**: The dialog MUST track whether it is currently shown via the read-only `isShown` property.
- **gear-button-borderless**: The gear button MUST be borderless (`bezelStyle = .accessoryBarAction`, `isBordered = false`).
- **gear-button-gearshape-symbol**: The gear button MUST display the system `gearshape` symbol as its image, `imageOnly` position.
- **gear-button-secondary-text-tint**: The gear button's content tint MUST match the theme's secondary text color and MUST respond to theme changes.
- **gear-button-tooltip**: The gear button MUST have a tooltip set (default "Window appearance", customizable).
- **gear-button-accessible-label**: The gear button's accessible name MUST come from the `gearshape` image's `accessibilityDescription`, which MUST be set to the tooltip text at construction, so VoiceOver announces the button by its purpose rather than as an unlabeled image button.
- **dialog-window-titlebar-closable**: The dialog window MUST have a title bar with the host-provided title and MUST have a close button. The close button MUST route through the component's `close()` method.
- **dialog-window-undecorated-except-title**: The dialog window style MUST be `.titled` and `.closable` only, with no other decorations.
- **gear-button-public**: The `gearButton` property MUST be public so the host can add it to the window's chrome via `makeTitlebarAccessory()` or custom layout.
- **titlebar-accessory-helper**: The component MUST provide a `makeTitlebarAccessory()` method to position the gear button in a right-aligned title bar accessory, optionally with leading views.
- **titlebar-accessory-right-align**: The title bar accessory MUST right-align the gear button using autoresizing masks and `NSTitlebarAccessoryViewController` with `.right` layout attribute.
- **titlebar-accessory-leading-views**: The `makeTitlebarAccessory()` method MUST accept an optional array of leading views to place left of the gear button, with configurable spacing (6pt default) and centered vertical alignment.
- **close-on-window-close-button**: When the dialog's close button is clicked, the dialog MUST close and the modal session MUST end. Clicking the button MUST NOT close the window itself — only dismiss the dialog.
- **dialog-window-keyboard-dismissal**: Because the dialog window's style is `.closable`, the standard ⌘W keyboard shortcut MUST dismiss it through the same `windowShouldClose` delegate path as clicking the close button, ending the modal session the same way.
- **configurable-width**: The dialog body width MUST be configurable at construction time, falling back to the component's built-in default when omitted, allowing hosts with wider controls to avoid cramping.
- **slider-caption-updates-continuously**: The slider's caption MUST update continuously as the user moves the slider, reflecting the value via the host-supplied `caption` closure.
- **slider-value-constrained-to-range**: The slider's value MUST be constrained to the provided range; initial values outside the range MUST be clamped to the valid bounds.
- **slider-calls-onchange**: When the slider moves, the slider MUST call the `onChange` callback with the new value.
- **slider-custom-range**: The slider MUST support a custom closed range (e.g., 0.0...100.0, 1.0...10.0).
- **toggle-updates-state**: When the user clicks the checkbox, the toggle's `isOn` property MUST reflect the new state and the `onChange` callback MUST be called.
- **toggle-is-on-settable**: The `isOn` property MUST be settable from outside, allowing the host to update the displayed state without triggering `onChange` (one-way assignment).
- **toggle-accessibility-id**: The toggle MUST provide a `checkboxAccessibilityID()` method to set an accessibility identifier on the underlying checkbox, not the wrapper view.
- **reset-button-standard-title**: The "Reset to Defaults" button MUST use the static `WindowOptionsResetButton.title` string for consistency across windows.
- **reset-button-centered**: The reset button MUST be centered horizontally under the rows, not stretched to the full dialog width.
- **reset-button-rounded**: The reset button MUST use `bezelStyle = .rounded`.
- **reset-button-calls-onreset**: When the reset button is clicked, it MUST call the host-supplied `onReset` closure.
- **single-dialog-instance**: Calling `present()` while the dialog is already open MUST be a no-op — no second dialog is created and the existing session is left undisturbed. `toggle()` does not share this behavior: while the dialog is open, `toggle()` MUST close it instead (see **support-toggle**).
- **end-modal-session-on-close**: When `close()` is called while the dialog is open, the active modal session MUST end, but only when the dialog's own window is the one currently running the modal loop — an unrelated modal session MUST NOT be ended. Calling `close()` when the dialog is not open MUST be a no-op.

## Appearance

- **Gear Button**:
  - Bezel style: `.accessoryBarAction` (borderless, toolbar-appropriate)
  - Image: `NSImage(systemSymbolName: "gearshape")`
  - Image position: `.imageOnly` (no text)
  - Content tint color: theme's secondary text color, theme-aware (see Platform Notes for the exact API)
  - Tooltip: "Window appearance" (default, customizable)

- **Dialog Window**:
  - Style: `.titled, .closable` (no resize handle, no minimize/maximize)
  - Title: Provided by host at construction
  - Background: theme's window background color, theme-aware (see Platform Notes)
  - Width: Configurable via `width` parameter; falls back to the component's built-in default when omitted (see Platform Notes)
  - Position: Centered horizontally and vertically on the screen the host window is on at open time

- **Slider** (`WindowOptionsSlider`):
  - Title font: `.systemFont(ofSize: .systemFontSize)` (standard control size)
  - Caption font: `.systemFont(ofSize: .systemFontSize)` (standard size)
  - Caption color: `.secondaryLabelColor`
  - Caption alignment: Right-aligned
  - Layout: Title and caption in horizontal stack at top, slider below
  - Title-caption spacing: 6pt horizontal gap with flexible distribution
  - Slider-caption spacing: 6pt vertical gap

- **Toggle** (`WindowOptionsToggle`):
  - Checkbox font: `.systemFont(ofSize: .systemFontSize)` (standard control size)
  - Checkbox state: `.on` / `.off`
  - Layout: Checkbox only (title embedded in checkbox)

- **Reset Button** (`WindowOptionsResetButton`):
  - Bezel style: `.rounded`
  - Title: `"Reset to Defaults"` (static, consistent)
  - Horizontal alignment: Centered under rows
  - Margin: Leading and trailing constraints ensure it does not exceed dialog width but allows centering

## States

| Component | State | Appearance Change |
|-----------|-------|------------------|
| Dialog | Hidden (closed) | Not visible, `isShown == false` |
| Dialog | Shown (open) | Visible and focused, `isShown == true`, title bar active |
| Gear Button | Default | Borderless, secondary text tint |
| Gear Button | Hover | Secondary text tint with slight highlight (standard AppKit button behavior) |
| Gear Button | Pressed | Highlighted momentarily when tapped |
| Slider | Moving | Caption updates in real time as slider value changes |
| Slider | At minimum | Caption shows minimum value result |
| Slider | At maximum | Caption shows maximum value result |
| Toggle | On | Checkbox displays checkmark, `isOn == true` |
| Toggle | Off | Checkbox empty, `isOn == false` |
| Reset Button | Ready | Rounded bezel, clickable |
| Reset Button | Hover | Slight highlight (standard AppKit button behavior) |
| Reset Button | Pressed | Highlighted momentarily when clicked |

## Accessibility

- **Dialog Window**:
  - Role: Modal dialog (AppKit window delegate handles modal session)
  - Label: Window title (provided by host)
  - Keyboard: ⌘W closes the dialog (see **dialog-window-keyboard-dismissal**); Tab navigates between controls; Enter/Space activate buttons

- **Gear Button**:
  - Role: Button
  - Label: The `gearshape` image's `accessibilityDescription`, set to the tooltip text at construction (see **gear-button-accessible-label**)
  - Action: Tap/click opens or closes the dialog

- **Slider** (`WindowOptionsSlider`):
  - Role: Slider
  - Labels: Title label above describes the setting; caption label (right-aligned) shows the current value for sighted users
  - Keyboard: Left/Right arrow keys adjust value continuously
  - Announce: The slider itself is a standard `NSSlider`, so VoiceOver announces its value as arrow keys adjust it. The caption label mirrors the same value in a sighted-user-facing string but is a plain text field, not a live accessibility announcement region — changing its text does not itself trigger a VoiceOver announcement.

- **Toggle** (`WindowOptionsToggle`):
  - Role: Checkbox
  - Label: Checkbox title text
  - Keyboard: Space toggles state
  - State announcement: Checkbox state (on/off) announced by screen reader; custom accessibility ID can be set

- **Reset Button** (`WindowOptionsResetButton`):
  - Role: Button
  - Label: "Reset to Defaults"
  - Keyboard: Space or Enter activates
  - Action: Tapping resets all window options to defaults

- **Target size**: macOS does not define a touch-target minimum the way iOS's 44×44pt does — these are pointer-driven click targets, not touch targets. The gear button's `gearshape` glyph is roughly 16×16pt but sits inside a 28pt-tall title bar accessory row, giving it a larger effective click area. The checkbox, slider knob, and reset button use standard AppKit control sizes (roughly 16–20pt content), which is platform-normal for these controls but does not meet a 44×44pt figure. See Compliance: `touch-target-size` (`partial`).

- **Accessibility Prefix**: Dialog rows use the prefix `"window.options"` for accessibility identifiers, ensuring unique and meaningful IDs when there are multiple window option dialogs.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dialog-001 | present-modal | Call `present()` on `WindowOptionsDialog` | Dialog appears as app-modal; host window remains visible but is blocked from receiving keyboard or mouse input; the host may still change on screen only as a result of the dialog's own controls driving host state |
| dialog-002 | center-on-screen | Open dialog on a screen; verify position | Dialog frame center matches screen visible frame center |
| dialog-003 | host-level-sync | Host window at `.normal`, dialog open; change host to `.floating` | Dialog level changes to `.floating` while open |
| dialog-004 | build-controls-at-open-time | Create dialog with `makeControls` closure that reads current time; open, note time; close; reopen | Reopened dialog shows current time, not cached time from construction |
| dialog-005 | rebuild-on-title-change | Dialog open; change `title` property | Window title updates; `rebuildControls()` is called; controls are rebuilt from `makeControls()` |
| dialog-006 | support-toggle | Dialog closed; call `beginDialog()` directly — `toggle()`'s open branch calls `present()`, which calls `beginDialog()` and then blocks in `NSApp.runModal` until the session ends, so a test cannot call `toggle()`/`present()` themselves and observe the open state afterward (see dialog-008, dialog-009) | Returns a non-nil window; `isShown == true` |
| dialog-007 | support-toggle | Dialog open; call `toggle()` | Dialog closes; `isShown == false` |
| dialog-008 | support-present-close | Dialog closed; call `beginDialog()` directly (not `present()`); assert the returned window and `isShown`; then call `endDialog(window)` directly (not `close()`) | `beginDialog()` returns a non-nil window and `isShown` becomes `true` without entering a modal run loop; `endDialog(window)` then sets `isShown` back to `false` and orders the window out — the same open/close transition `present()`/`close()` drive, exercised without `NSApp.runModal` |
| dialog-009 | track-shown-state | Check `isShown` before/after `beginDialog()`/`endDialog(window)` — not `present()`, which blocks in `NSApp.runModal` until the session ends and only calls `endDialog(window)` (clearing `dialogWindow`) once it returns, so `isShown` is always `false` by the time a caller sees `present()` return (see dialog-008) | `isShown == false` before, `isShown == true` after `beginDialog()`, `isShown == false` after `endDialog(window)` |
| gear-010 | gear-button-borderless | Call `makeGearButton()`; inspect `isBordered` and `bezelStyle` | `isBordered == false`, `bezelStyle == .accessoryBarAction` |
| gear-011 | gear-button-gearshape-symbol | Call `makeGearButton()`; inspect image | Image symbol name is "gearshape", `imagePosition == .imageOnly` |
| gear-012 | gear-button-secondary-text-tint | Call `makeGearButton()` in light and dark themes | Content tint color matches the theme's secondary text color in each theme |
| gear-013 | gear-button-tooltip | Call `makeGearButton(tooltip: "Custom Tip")`; inspect `toolTip` | `toolTip == "Custom Tip"` |
| window-014 | dialog-window-titlebar-closable | Open dialog; inspect window | Window has `.titled` and `.closable` style; close button visible; window title == dialog title |
| window-015 | close-on-window-close-button | Dialog open; click window close button | Dialog closes, modal session ends, `isShown == false` |
| window-016 | configurable-width | Create dialog with `width: 400`; open | Dialog body width is 400pt |
| titlebar-017 | titlebar-accessory-helper | Call `makeTitlebarAccessory(leading: [view1, view2])`; inspect result | Returns `NSTitlebarAccessoryViewController` with `.right` layout attribute; container has `minXMargin` autoresizing; gear button is rightmost; leading views are to its left |
| slider-018 | slider-caption-updates-continuously | Create slider with range 0...100 and caption showing percentage; move slider | Caption updates in real time as slider moves; each position shows correct percentage |
| slider-019 | slider-value-constrained-to-range, slider-custom-range | Create slider with range 10...50; initialize with value 60 | Initial value clamped to 50, demonstrating both clamping and a custom (non-0...100) range |
| slider-020 | slider-calls-onchange | Create slider; move slider; verify callback | `onChange` called for each movement with new value |
| toggle-021 | toggle-updates-state | Create toggle `isOn: false`; click checkbox | `isOn` becomes true, `onChange(true)` called |
| toggle-022 | toggle-is-on-settable | Toggle open; set `toggle.isOn = true` from outside | Checkbox displays checked state; `onChange` is NOT called |
| toggle-023 | toggle-accessibility-id | Create toggle; call `checkboxAccessibilityID("my-id")`; inspect checkbox | Checkbox accessibility identifier == "my-id", not the wrapper view |
| reset-024 | reset-button-standard-title | Create reset button; inspect title | Button title == `WindowOptionsResetButton.title` == "Reset to Defaults" |
| reset-025 | reset-button-calls-onreset | Create reset button; click it | `onReset` callback is called |
| dialog-026 | single-dialog-instance | Dialog open; call `beginDialog()` again | Returns `nil`, no second dialog created |
| dialog-027 | end-modal-session-on-close | Dialog open in modal session; call `close()` | `NSApp.stopModal()` called only once; modal session ends |
| dialog-028 | end-modal-session-on-close | Dialog never opened; call `close()` | No-op; no exception; `isShown` remains `false` |
| gear-029 | gear-button-accessible-label | Call `makeGearButton(tooltip: "Custom Tip")`; inspect the button's image | `gearButton.image?.accessibilityDescription == "Custom Tip"` |
| window-030 | dialog-window-undecorated-except-title | Open dialog; inspect `window.styleMask` | `styleMask == [.titled, .closable]` exactly — no `.resizable`, `.miniaturizable`, or `.fullSizeContentView` |
| window-031 | dialog-window-keyboard-dismissal | Dialog open; simulate ⌘W (`performClose(_:)`) | `windowShouldClose(_:)` is invoked and routes to `close()`; dialog closes exactly as the close button would; the window is not closed directly by AppKit |
| titlebar-032 | titlebar-accessory-leading-views | Call `makeTitlebarAccessory(leading: [view1, view2])`; inspect the row `NSStackView` | `row.spacing == 6`; `row.alignment == .centerY`; `gearButton` is the last view in the stack, after `view1` and `view2` |
| reset-033 | reset-button-centered | Add `WindowOptionsResetButton` to a dialog's row stack; inspect its constraints | The button's `centerXAnchor` is pinned to the container's `centerXAnchor`; leading/trailing are `greaterThanOrEqualTo` constraints, not full-width equal constraints |
| reset-034 | reset-button-rounded | Create `WindowOptionsResetButton`; inspect its button's `bezelStyle` | `bezelStyle == .rounded` |

## Edge Cases

- **Dialog already open**: Calling `present()` when `isShown == true` is a no-op — see **single-dialog-instance**. Calling `toggle()` when open does NOT share this no-op behavior: it closes the dialog instead (see **support-toggle**).

- **Close called when dialog is not open**: A no-op; no exception thrown — see **end-modal-session-on-close**.

- **Title changed while dialog open**: The dialog rebuilds controls via `rebuildControls()` — see **rebuild-on-title-change** and **rebuild-controls-public**. This is necessary for windows whose title changes (e.g., a tab-like pane named by its content).

- **Host window level changes during modal session**: The dialog re-samples the host's window level on every pass of the event loop while the modal session is active and adjusts its own level to match — see **host-level-sync**. This prevents the dialog from appearing behind its host when the host is raised to `.floating`.

- **Host window closed while dialog is open**: The host window reference (`gearButton.window`) becomes `nil`. The dialog remains open; subsequent attempts to read the host's level or reposition the dialog fall back to the main screen or the window's own `center()`. The component does not close the dialog or end the modal session on its own in this case.

- **Host window moved to a different screen while dialog is open**: The dialog's screen was sampled once, from the host window's screen at the moment it opened — see **center-on-screen**. It is not re-centered if the host is subsequently moved to a different screen while the dialog stays open; this differs from **host-level-sync**, which does track the host continuously.

- **Multiple dialogs in same window**: Each window can have multiple gear buttons with their own `WindowOptionsDialog` instances, each managing a separate modal dialog. The dialogs do not interfere if opened sequentially.

- **Concurrent modifications to title or controls**: All updates occur on `@MainActor`, so thread safety is managed by the actor isolation.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `String` | (required) | The dialog window's title, displayed in the title bar. Settable at runtime. |
| `tooltip` | `String` | `"Window appearance"` | Tooltip for the gear button, set on construction. |
| `width` | `CGFloat` | component's built-in default (see Platform Notes) | Width of the dialog's body, allowing hosts with wider controls to avoid cramping. |
| `makeControls` | `@MainActor () -> [NSView]` | (required) | Closure that returns an array of row views (sliders, toggles, etc.) to display in the dialog. Called at open time so controls read live state. |
| `gearButton` | `NSButton` (read-only public) | Auto-created | The button to be placed in the window's chrome, created and configured by the component. |
| `isShown` | `Bool` (read-only) | `false` initially | Whether the dialog is currently visible. |

## Deep Linking

Not applicable: The window options dialog is a window-local configuration panel, not a top-level navigation destination. Deep links do not target option dialogs; they target the window or view the dialog belongs to.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `window-options.gear.tooltip` | `"Window appearance"` | Gear button tooltip; would typically be localized per host app. |
| `window-options.reset.title` | `"Reset to Defaults"` | Reset button title; shared across all window option dialogs in the app. |

The source does not yet look these strings up by key — `WindowOptionsResetButton.title` and the default tooltip are Swift string literals with no resource-file lookup. The keys above are the target shape for wiring in localization; see Compliance: `string-externalization`.

All other user-facing strings (control titles, captions) are supplied by the host via `makeControls()` and are the host's responsibility to localize.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: The dialog itself has no animations. Host-supplied controls (sliders, toggles) SHOULD respect Reduce Motion if they animate state changes. |
| Increase Contrast | Not applicable: The dialog uses system colors (theme window background, theme secondary text). System color palettes adapt to Increase Contrast settings automatically. |
| Differentiate Without Color | Not applicable: The dialog does not rely on color alone to convey state. Checkboxes use checkmarks; sliders are labeled. |

## Feature Flags

Not applicable: The window options dialog is a core UI component without feature-flag control. A host application may guard the entire gear button/dialog behind an app-level feature flag if it chooses.

## Analytics

Not applicable: Analytics events are the responsibility of the host application, which owns the dialog's `makeControls()` closure and can instrument individual controls (sliders, toggles, reset button) as needed.

## Privacy

Not applicable: The window options dialog does not collect, store, or transmit any data. The host's `makeControls()` closure reads and writes the host's own settings, which are subject to the host app's privacy policy.

## Logging

Not applicable: The component does not perform its own logging. A host may add instrumentation around `present()`, `close()`, `toggle()`, and title/level changes if it needs to trace this dialog's lifecycle.

## Platform Notes

- **Source Platform (Apple)**: Implemented in `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/WindowOptionsDialog.swift`. The component is AppKit-only (`@MainActor`, `NSObject`, `NSWindow`, `NSButton`, etc.) and targets macOS. `WindowOptionsSlider`, `WindowOptionsToggle`, and `WindowOptionsResetButton` are companion views for composing common dialog rows. The source relies on `OptionsDialogViewController` for the dialog body layout and `ThemePaletteObserver` for theme-aware colors (`palette.nsColor(.secondaryText)` for the gear button tint, `palette.windowBackgroundColor` for the dialog background). The default `width` falls back to `OptionsDialogViewController.defaultWidth`. Internally, `present()` delegates to a `beginDialog()`/`endDialog(_:)` seam so the open and close halves can be asserted without entering `NSApp.runModal`; `close()` calls `NSApp.stopModal()` only when `NSApp.modalWindow` is this dialog's own window; the host level is tracked live via `NSWindow.didUpdateNotification` observed on the dialog's own window (not the host window) — AppKit posts it on every pass of the event loop that touches that window, which during the modal session is every event, so the dialog catches the host's level change on the very next one.

- **SwiftUI**: `WindowOptionsDialog` is an `NSObject`, not a view or view controller, so wrapping it in `NSViewControllerRepresentable` is not applicable — there is no view controller to represent. Instead, hold a `WindowOptionsDialog` instance in a coordinator or `@State`-held object owned by the SwiftUI scene, and call `present()` / `close()` / `toggle()` from a `Button`'s action in response to SwiftUI state (e.g., a toolbar gear `Button` with system image `"gearshape"` calling `dialog.toggle()`). For the rows passed to `makeControls`, build `NSHostingView`-wrapped `SwiftUI.Slider`, `SwiftUI.Toggle`, and a plain `Button` for reset, binding them to the host's own state and driving the same `onChange`/`onReset` closures the AppKit rows use.

- **Compose**: Use a `Dialog` composable (not `AlertDialog`, which is button-oriented) as the app-modal container, with `DialogProperties(dismissOnClickOutside = false)`. Replace `NSButton` with a Material 3 `IconButton` (gear icon) for the trigger, `Slider` with a `Text` caption for the row, `Checkbox` or `Switch` for the toggle, and a `TextButton`/`Button` for reset. Android has no window-level concept equivalent to `NSWindow.Level` — **host-level-sync** is N/A on this platform; a `Dialog` is already always-on-top of its host by construction. Centering on screen is the composable's default `Dialog` behavior.

- **AppKit / UIKit**: On macOS, `WindowOptionsDialog` is directly usable as described. On iOS, the component would need significant adaptation: modal presentation replaces app-modal windows (`UIModalPresentationStyle`). The gear button becomes a standard `UIBarButtonItem` in the navigation bar. Sliders, toggles, and buttons use iOS standard sizes and spacing. Consider `UITableViewController` or `UICollectionViewController` for the dialog body to support scrolling on smaller screens. The "Reset to Defaults" button would be a full-width row at the bottom (possibly in a footer section).

- **WinUI 3**: `ContentDialog` is scoped to its `XamlRoot` and cannot be centered on the physical screen or take part in window Z-order/level tracking, so it is the wrong container here. Use an owned, modal `AppWindow` instead: create it, size and position it centered on the host's `DisplayArea`, and make it modal to the host via the owner-window relationship (blocking host input the way `NSApp.runModal` does). The gear button is a `Button` with an icon (a gear glyph from `Segoe Fluent Icons`, ``). Slider is `Slider` (WinUI) with a `TextBlock` label showing the caption. Toggle is `CheckBox` with inline label text. Reset button is a standard `Button` at the dialog's footer. For level/Z-order tracking, subscribe to the host `AppWindow`'s `Changed` event and re-apply the equivalent owner/top-most state when it fires, mirroring the host.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/WindowOptionsDialog.swift` | unverified |

## Design Decisions

- **Decision**: Use an app-modal dialog centered on the screen instead of a popover anchored to the gear button.
  **Rationale**: A popover anchored to the gear would move as the window resizes (sliders change size). An app-modal dialog centered on the screen remains stable during interactive adjustments, providing a better user experience when live slider adjustments change the window's dimensions.
  **Approved**: pending

- **Decision**: Build controls from a closure at dialog open time, not construction time.
  **Rationale**: Building controls from a closure at open time ensures they reflect live state, even if other UI or keyboard shortcuts have changed settings while the dialog was closed. This avoids stale UI and prevents the need for complex state synchronization.
  **Approved**: pending

- **Decision**: Make the dialog's `title` settable at runtime, triggering a control rebuild.
  **Rationale**: Paned or tabbed windows may change their displayed name based on content. Allowing the title to be updated and triggering a control rebuild ensures the dialog's context remains correct.
  **Approved**: pending

- **Decision**: Track and match the host window's level for the duration of the dialog session.
  **Rationale**: The dialog matches the host window's level so that options for a floating or docked window remain accessible. Without this, a dialog could appear behind its own window if the host's level changed, confusing the user.
  **Approved**: pending

- **Decision**: Make the dialog's body width configurable at construction time.
  **Rationale**: Not all options are simple checkboxes and sliders. Some dialogs may need wider rows (e.g., a picker or a button row). Configurable width avoids over-constraining the layout and supports diverse use cases.
  **Approved**: pending

- **Decision**: Expose gear button creation as a static factory (`makeGearButton()`), independent of a dialog instance.
  **Rationale**: A host window without a full dialog (e.g., one that shows options in a menu instead) can still use the same, consistent gear button appearance.
  **Approved**: pending

- **Decision**: Route the window's close button through the dialog's own `close()` logic rather than letting AppKit close the window directly.
  **Rationale**: Letting the close button directly close the window would bypass the modal session end logic, leaving the app in a modal loop with no window on screen. Routing it through `close()` ensures clean teardown.
  **Approved**: pending

- **Decision**: Center the reset button under the rows instead of stretching it to the full dialog width.
  **Rationale**: A full-width reset button would visually group with the control rows above, making it look like another option rather than a separate action. Centering it distinguishes its role.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Accessibility statuses rest on the gear button's `accessibilityDescription`, standard AppKit keyboard/Tab handling, and the app-modal run loop blocking host interaction (source: `WindowOptionsDialog.swift`); `touch-target-size` is `partial` because the checkbox, slider, and reset button use standard 16–20pt AppKit control sizes rather than a 44×44pt minimum; `string-externalization` is `failed` because `WindowOptionsResetButton.title` and the default tooltip are Swift string literals with no resource-file lookup. `separation-of-concerns` passes because the dialog knows nothing of what settings it holds — a host supplies `makeControls` as a closure, and the dialog itself owns only presentation, positioning, and modal-session bookkeeping; `unit-test-coverage` passes on `WindowOptionsDialogTests.swift`'s exercise of the gear, the titlebar accessory, dialog identity/level, open/close bookkeeping, positioning, and its controls.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | single-dialog-instance corrected to exempt toggle() (which closes an open dialog, per support-toggle); dialog-006/dialog-009 vectors corrected to use beginDialog()/endDialog() since present() blocks in NSApp.runModal; Platform Note corrected: didUpdateNotification observed on dialog's own window, not host window. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; resolved the app-modal interaction contradiction between Overview, present-modal, and dialog-001; corrected screen-positioning claims (position is sampled once at open, not live-tracked) and dropped the false must-reposition-on-screen-change requirement; replaced the inaccurate 44pt touch-target claim with real macOS guidance and marked touch-target-size partial; added gear-button-accessible-label, rebuild-controls-public, and dialog-window-keyboard-dismissal requirements with new test vectors, plus vectors for close()-when-not-open, reset-button-centered, reset-button-rounded, dialog-window-undecorated-except-title, and leading-view spacing, and made dialog-008 concrete; moved AppKit internals (palette APIs, beginDialog/endDialog, NSApp.stopModal, NSWindow.didUpdateNotification, default width symbol) out of requirements into the Apple platform note; corrected the SwiftUI, WinUI 3, and Compose platform notes; reformatted Design Decisions into Decision/Rationale/Approved form; fixed Compliance check links/categories and added applicable checks; dropped the unused Logging table; added stable localization keys; filled in depends-on and related. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from WindowOptionsDialog.swift source |
