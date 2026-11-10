
**Decision**: The cluster mirrors the order and meanings of the window title bar's close/minimize/zoom controls, not their exact glyphs — macOS window controls are colored circles, while this cluster uses SF Symbol glyphs.
**Rationale**: Principle of least astonishment: a pane is a window-shaped thing inside a window, and a reader who has to learn a second control arrangement pays for nothing.
**Approved**: pending

**Decision**: A disabled button (`canClose = false`, or `canMinimize = false` while not minimized) is rendered dim (tertiary text color tint) rather than hidden.
**Rationale**: A live-looking, unresponsive button reads as a broken pane; a dim button reads as a protected one, which matches the host's responsibility model — the host decides whether a pane may be closed or minimized.
**Approved**: pending

**Decision**: The minimize button serves a dual role (minimize / restore), swapping its glyph, label, tooltip, and accessibility identifier based on `isMinimized`, rather than showing a second button.
**Rationale**: Keeps the control cluster compact while accessibility stays correct, since the identifier and label always match the button's current role.
**Approved**: pending

**Decision**: The component observes `ThemeManager`/`ThemeScope` theme-change notifications and re-applies each button's tint automatically, rather than requiring the host to push an explicit update whenever the app's own theme changes. It does not itself observe the OS Increase Contrast setting or a bare system light/dark appearance switch — `ThemeManager.refreshApplicationAppearance()`, the path a host uses for that case, deliberately posts no notification, so this component's tint only follows a theme change that goes through `ThemeManager.selectTheme(id:)`, an in-place theme edit, or a text-scale change.
**Rationale**: Keeps theme-responsiveness self-contained for the changes the component's own semantic palette actually models; the host only has to manage `isZoomed`, `isMinimized`, `canMinimize`, and `canClose` — appearance follow-through for those changes is the component's job. OS-level Increase Contrast and appearance-only changes are out of scope because the palette has no dynamic/high-contrast variant to switch to.
**Approved**: pending

**Decision**: The component never infers `isZoomed` from a click; only the host sets it, after deciding whether to grant the zoom request.
**Rationale**: The pane's zoom state must always reflect the host's actual internal state — a click is a request, not an outcome, and the host may refuse it.
**Approved**: pending

