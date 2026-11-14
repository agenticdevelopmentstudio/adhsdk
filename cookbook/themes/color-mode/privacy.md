
- **Data collected**: the user's color-mode preference only.
- **Storage**: `localStorage` under `storageKey`, only for `light` or `dark`; `auto` removes the key.
- **Transmission**: none; the value never leaves the browser.
- **Retention**: until the user chooses `auto`, clears site data, or the browser evicts storage; the legacy key is never cleaned up by this code.

