
| State | Appearance change | Opacity | When triggered |
|-------|------------------|---------|-----------------|
| Detached | No stroke drawn | — | View has no window (`window` is `nil`); no key-state observers are registered |
| Inactive | Border faded | `inactiveAlpha` (0.28) | Window is not key; see `NSWindow.didResignKeyNotification` |
| Active | Border brightened | `activeAlpha` (0.85) | Window is key; see `NSWindow.didBecomeKeyNotification` |

