
| State | Button | Where the picker runs |
|-------|--------|-----------------------|
| idle | `person.crop.circle.badge.xmark`, "Hide elements from agent" | nowhere |
| selecting (Website) | `stop.circle`, "Stop selecting" | live page, `adk-element-picker` world |
| selecting (Agent preview) | `stop.circle`, "Stop selecting" | preview webview, `adk-element-picker` world |
| dialog | `stop.circle`, "Stop selecting" | paused |

Transitions are the element picker's; switching the pane's view while
selecting returns to idle.

