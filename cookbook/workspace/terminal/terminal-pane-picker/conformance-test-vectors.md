
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

