
| State | Button | Page | Dialog |
|-------|--------|------|--------|
| idle | `eye.slash`, "Hide distracting items" | as rendered | none |
| selecting | `stop.circle`, "Stop selecting" | outline follows pointer; clicks swallowed | none |
| dialog | `stop.circle`, "Stop selecting" | outline gone; picks paused; preview rule set as the checkbox says | open |

Transitions: idle → selecting (popover select button); selecting → dialog
(accepted pick); dialog → selecting (OK or Cancel); selecting or dialog →
idle (stop button, Esc while selecting, `cancel` message, navigation, tab
switch or close).

