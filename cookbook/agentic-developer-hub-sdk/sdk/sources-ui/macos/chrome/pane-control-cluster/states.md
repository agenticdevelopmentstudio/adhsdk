
| State | Appearance Change |
|-------|------------------|
| Default (not zoomed, not minimized, all enabled) | Close: "xmark" enabled; Minimize: "minus" enabled; Zoom: "arrow.up.left.and.arrow.down.right" enabled |
| Zoomed | Zoom button: "arrow.down.right.and.arrow.up.left" glyph; label changes to "Unzoom Pane" |
| Minimized | Minimize button: "plus" glyph, label "Restore Pane", enabled regardless of `canMinimize`; minimize button appears in restore role |
| Close disabled | Close button: tertiary text color tint, no interaction |
| Minimize disabled | Minimize button: tertiary text color tint (only when not minimized) |
| Dark mode | Tinting adjusts to match a dark theme once `ThemeManager.didChangeNotification`/`ThemeScope.didChangeNotification` fires (theme selection, in-place theme edit, or text-scale change); secondary/tertiary text colors recalculated from that notification, not from the OS appearance switch directly |
| Light mode | Tinting adjusts to match a light theme once `ThemeManager.didChangeNotification`/`ThemeScope.didChangeNotification` fires (theme selection, in-place theme edit, or text-scale change); secondary/tertiary text colors recalculated from that notification, not from the OS appearance switch directly |

