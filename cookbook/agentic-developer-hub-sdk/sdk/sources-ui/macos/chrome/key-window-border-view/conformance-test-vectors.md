
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| key-001 | stroke-border | Component initialized and added to a window | `draw(_:)` strokes a rounded-rect path with `lineWidth == 1` within the view's bounds |
| key-002 | half-point-inset | Component draws | The stroked path's rect equals `bounds.insetBy(dx: 0.5, dy: 0.5)` |
| key-003 | accent-stroke-color | Theme accent is red (example) | `strokeColor`'s underlying color, ignoring alpha, equals the theme's red accent |
| key-004 | inactive-alpha | Window is not key; `inactiveAlpha` = 0.28 | `strokeColor.alphaComponent == 0.28` |
| key-005 | active-alpha | Window becomes key; `activeAlpha` = 0.85 | `strokeColor.alphaComponent == 0.85` |
| key-006 | click-through | Mouse event at (x, y) within component bounds | `hitTest(_:)` returns `nil`; event passes through to the view underneath |
| key-007 | key-state-redraw | Window key state changes from inactive to active | `keyStateChanged()` sets `needsDisplay = true`; the next `draw(_:)` computes `strokeColor.alphaComponent == activeAlpha` |
| key-008 | corner-radius-customization | Set `cornerRadius` to 15 | The stroked path is built with `xRadius == 15` and `yRadius == 15` |
| key-009 | alpha-customization | Set `inactiveAlpha` to 0.5; window is not key | `strokeColor.alphaComponent == 0.5` |
| key-010 | redraw-on-property-change | Modify `cornerRadius`, `inactiveAlpha`, or `activeAlpha` | `needsDisplay` becomes `true` immediately after the property's `didSet` runs |
| key-011 | theme-color-update | Theme palette changes; accent color changes to blue | `accent` updates to blue and `needsDisplay` becomes `true`; the next stroke uses the blue accent |
| key-012 | observer-cleanup | Component is deallocated | `deinit` calls `NotificationCenter.default.removeObserver(self)`; no further notifications reach the instance |
| key-013 | observer-cleanup | `viewDidMoveToWindow()` runs with `window == nil` (view removed from its window) | Observers registered for the previous window are removed; no drawing is scheduled; no observers remain for `self` |
| key-014 | observer-cleanup | Component is moved from window A to window B | Observers for window A are removed before observers for window B are registered; `needsDisplay` becomes `true` for the new window |
| key-015 | initial-key-state | `viewDidMoveToWindow()` runs for the first time on a window that is already key | `needsDisplay` becomes `true`, and the next `draw(_:)` uses `activeAlpha`, without waiting for a `didBecomeKeyNotification` |
| key-016 | main-actor-isolation | Project builds under Swift strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`) | The build succeeds with zero data-race or actor-isolation diagnostics for `KeyWindowBorderView` |

