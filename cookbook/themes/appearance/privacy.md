
- **Data collected**: the user's display preferences (color mode, motion, contrast, text size, spacing, focus outlines, link underlines). No identifiers.
- **Storage**: `localStorage` key `adh:appearance` in the user's browser, as a cache of preferences held on the server for signed-in users.
- **Transmission**: none from this module; the server sync is separate.
- **Retention**: until `clearStoredAppearance` runs (the caller invokes it on sign-out so the cache does not outlive the session on a shared browser) or the user clears site data.

