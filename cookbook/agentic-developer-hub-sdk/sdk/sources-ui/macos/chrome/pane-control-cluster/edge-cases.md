
- **Minimize when canMinimize is false**: Component ignores clicks on the minimize button; the button appears disabled. When `isMinimized` becomes true programmatically (set by the host), the button becomes enabled and shows restore state.
- **Restore when isMinimized is true**: The minimize button is always enabled while `isMinimized = true`, even if `canMinimize = false`. This ensures the user can always restore a minimized pane.
- **Close when canClose is false**: Component ignores clicks on the close button; the button appears disabled. The button remains visually reachable (disabled, not hidden) to communicate state, not capability, per principle-of-least-astonishment.
- **Multiple state changes in sequence**: If `isZoomed`, `isMinimized`, `canClose`, and `canMinimize` are all modified before layout occurs, the component updates all three buttons in a single internal pass, rather than updating each one independently as its own property changes — see **respond-to-state-changes**.
- **Theme changes during interaction**: If a `ThemeManager`/`ThemeScope` theme-change notification fires while a button is highlighted or being interacted with, the component re-applies tinting immediately — see **theme-aware-tinting**.
- **No actions configured**: All four closures (`onClose`, `onMinimize`, `onRestore`, `onZoom`) are optional. If a closure is nil, activating the corresponding button has no effect.

