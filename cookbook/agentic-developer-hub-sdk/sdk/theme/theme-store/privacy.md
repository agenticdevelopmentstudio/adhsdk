
- **Data collected**: None collected by the store. It handles theme definitions (names, colors, typography, optional attribution text) and reads user-chosen theme files.
- **Storage**: Entirely in the injected `ThemeStorage`; the store keeps no copy. `UserDefaultsThemeStorage` is the bundled conformer.
- **Transmission**: The store makes no network call; data leaves the device only if the host's storage syncs it.
- **Retention**: Custom themes stay until `delete(id:)` removes them; the store applies no expiry.

