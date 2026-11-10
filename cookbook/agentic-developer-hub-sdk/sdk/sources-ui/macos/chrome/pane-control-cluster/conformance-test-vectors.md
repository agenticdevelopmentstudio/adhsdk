
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cluster-001 | render-three-buttons | Component initialized | Three buttons appear in order: close, minimize, zoom |
| cluster-002 | standard-glyphs | Component in default state | Close button shows "xmark"; Minimize shows "minus"; Zoom shows "arrow.up.left.and.arrow.down.right" |
| cluster-003 | report-close-action | Close button activated | `onClose` closure invoked once |
| cluster-004 | report-minimize-action | `isMinimized = false`, minimize button activated | `onMinimize` closure invoked once, passed the minimize button as an anchor reference |
| cluster-005 | report-restore-action | `isMinimized = true`, minimize button activated | `onRestore` closure invoked once |
| cluster-006 | report-zoom-action | Zoom button activated | `onZoom` closure invoked once |
| cluster-007 | render-minimized-state | `isMinimized = true` | Minimize button renders "plus" glyph, "Restore Pane" label, "pane.restore" ID, enabled state |
| cluster-008 | render-zoomed-state | `isZoomed = true` | Zoom button renders "arrow.down.right.and.arrow.up.left" glyph, "Unzoom Pane" label |
| cluster-009 | render-zoomed-state | `isZoomed = false` | Zoom button renders "arrow.up.left.and.arrow.down.right" glyph, "Zoom Pane" label |
| cluster-010 | disable-close-button | `canClose = false` | Close button disabled, tinted with the tertiary text color |
| cluster-011 | disable-minimize-button | `isMinimized = false`, `canMinimize = false` | Minimize button disabled, tinted with the tertiary text color |
| cluster-012 | disable-minimize-button | `isMinimized = true`, `canMinimize = false` | Minimize button enabled (restore state overrides `canMinimize` disable) |
| cluster-013 | respond-to-state-changes | `isZoomed` changes from false to true | Zoom button glyph and label update immediately |
| cluster-014 | respond-to-state-changes | `canClose` changes from true to false | Close button immediately disables and re-tints to the tertiary text color |
| cluster-015 | theme-aware-tinting | The app's active theme is switched to a dark `ColorTheme` via `ThemeManager.selectTheme(id:)` | All button tints re-resolve to dark theme secondary/tertiary text colors, driven by the resulting `ThemeManager.didChangeNotification` |
| cluster-016 | borderless-icon-buttons, tinted-glyph-color | Component rendered | No border visible; buttons appear borderless; glyphs tinted, not filled |
| cluster-017 | render-three-buttons | Component initialized | Close/minimize/zoom buttons expose accessibility IDs "pane.close"/"pane.minimize"/"pane.zoom" and labels "Close Pane"/"Minimize Pane"/"Zoom Pane" |
| cluster-018 | render-three-buttons | Component initialized | Each button's tooltip equals its accessibility label |
| cluster-019 | render-minimized-state | `isMinimized = true` | Minimize button's tooltip equals "Restore Pane" |
| cluster-020 | render-zoomed-state | `isZoomed = true` | Zoom button's tooltip equals "Unzoom Pane" |
| cluster-021 | disable-close-button | `canClose = false` | Close button's content tint resolves to the palette's tertiary-text color (a color swap, not an alpha/opacity change) |
| cluster-022 | disable-minimize-button | `isMinimized = false`, `canMinimize = false` | Minimize button's content tint resolves to the palette's tertiary-text color (a color swap, not an alpha/opacity change) |
| cluster-023 | report-close-action, report-minimize-action, report-restore-action, report-zoom-action | `onClose`, `onMinimize`, `onRestore`, `onZoom` all nil | Activating any button has no effect and does not crash |
| cluster-024 | respond-to-state-changes | `isMinimized` changes from false to true | Minimize button transitions from "minus" / "Minimize Pane" / "pane.minimize" / `canMinimize`-gated enabled state to "plus" / "Restore Pane" / "pane.restore" / always-enabled state |
| cluster-025 | render-three-buttons | macOS button rendered with the `.accessoryBarAction` bezel | Hit area matches the compact accessory-bar sizing convention; no 44×44pt minimum is enforced, consistent with system window-control sizing |
| cluster-026 | render-three-buttons | iOS UIKit port renders the equivalent buttons (see Platform Notes) | Each button's hit area is at least 44×44pt per Apple HIG |
| cluster-027 | theme-aware-tinting | System Increase Contrast enabled, with no theme-change notification posted | Button tint does not change: the component observes only `ThemeManager`/`ThemeScope` theme-change notifications, and nothing posts one for the OS Increase Contrast setting; the palette's colors are static sRGB values with no dynamic/high-contrast variant to switch to |
| cluster-028 | render-minimized-state | Differentiate Without Color enabled | Minimize button's state is distinguished by glyph shape (minus vs. plus) and accessibility label, not by color alone |

