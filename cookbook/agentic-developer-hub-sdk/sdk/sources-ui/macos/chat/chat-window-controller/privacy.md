
- **Data collected**: ChatWindowController collects no personal user data. It persists two kinds of local preference state — window frame geometry and appearance settings (text size, transparency, backdrop visibility, floating, caret blink) — both scoped to the `defaultsNamespace` supplied in `ChatWindowConfiguration`.
- **Storage**: Frame geometry is stored by AppKit itself under the key `"NSWindow Frame <namespace>.chatWindowFrame"` in `UserDefaults.standard`, via `windowFrameAutosaveName` (see **autosave-frame**). Appearance settings are stored by `WindowAppearanceDefaults` in `UserDefaults.standard` under `<namespace>.textScale`, `<namespace>.transparencyPercent`, `<namespace>.backdrop.off`, `<namespace>.floating`, and `<namespace>.blinkCaret.off`. All of this is local to the device.
- **Transmission**: No data transmission occurs.
- **Retention**: Frame and appearance settings are retained indefinitely until the host application, the user, or `WindowAppearanceDefaults.resetWindowAppearance()` clears them.

