
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

