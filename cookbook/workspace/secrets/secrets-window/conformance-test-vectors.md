
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| secrets-window-001 | lock-idle | Idle since t, now t + 299 s, 5 minutes | Not idle. |
| secrets-window-002 | lock-idle | Idle since t, now t + 300 s, 5 minutes | Idle. |
| secrets-window-003 | lock-idle | Idle since t, now t + 1 day, 0 minutes | Not idle. |
| secrets-window-004 | settings-panel | Idle labels for 0, 1, 15 | "Never", "1 minute", "15 minutes". |

