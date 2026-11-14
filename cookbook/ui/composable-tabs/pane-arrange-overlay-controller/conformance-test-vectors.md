
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

