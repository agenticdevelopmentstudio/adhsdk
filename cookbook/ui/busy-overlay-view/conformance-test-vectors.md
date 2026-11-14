
No test file exists beside the source; the vectors below are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| busy-overlay-001 | cover-host, fade-in | A host view with two subviews; `show(in: host)` | The overlay is the last subview of the host; its four edges equal the host's; it starts at opacity 0 and reaches 1 after 0.2 seconds |
| busy-overlay-002 | message-line, accessibility-label | `show(in: host, message: "Saving")` | The message line is visible with the text "Saving"; the accessibility label is "Saving" |
| busy-overlay-003 | message-hidden-when-empty | `show(in: host, message: "Saving")`, then `show(in: host, message: nil)` | The message line is hidden and its text is empty; the accessibility label is cleared |
| busy-overlay-004 | message-hidden-when-empty | `show(in: host, message: "")` | The message line is hidden |
| busy-overlay-005 | message-update-in-place | Overlay already over `host`; `show(in: host, message: "Next")` | The host's subview count is unchanged; the message reads "Next" |
| busy-overlay-006 | move-between-hosts | Overlay over `hostA`; `show(in: hostB)` | The overlay is no longer a subview of `hostA`; it is the topmost subview of `hostB` |
| busy-overlay-007 | hide-fades-out, hide-removes, is-showing | Showing overlay; `hide()` | `isShowing` is false at once; after 0.2 seconds the overlay is removed from the host and the spinner is stopped |
| busy-overlay-008 | hide-idempotent | `hide()` on an overlay never shown; then `hide()` twice in a row on a showing overlay | No error; the second call during the fade changes nothing; the overlay is removed once |
| busy-overlay-009 | show-cancels-hide | Showing overlay; `hide()`; `show(in: host)` before 0.2 seconds elapse | The overlay is still over the host after the fade completes; `isShowing` is true; opacity returns to 1 |
| busy-overlay-010 | swallow-pointer | Showing overlay at opacity 1 over a button; hit test at a point inside the overlay's frame | The hit test answers the overlay, not the button |
| busy-overlay-011 | ignore-hidden-hits | Overlay with `isHidden == true`, or at opacity 0; hit test at a point inside its frame | The hit test answers nothing |
| busy-overlay-012 | swallow-click-events, no-dismiss-on-input | Send left, right and other mouse-down events and a scroll-wheel event to the showing overlay | No action is taken and the overlay stays over the host with `isShowing == true` |
| busy-overlay-013 | first-click-accepted | Ask whether the overlay accepts the first mouse event | The answer is true |
| busy-overlay-014 | accessibility-role | Read the accessibility role of a new overlay | The role is progress indicator |
| busy-overlay-015 | material-configurable | Initialize with a given material, then with no argument | The blurred ground carries the given material, then the HUD window material |

