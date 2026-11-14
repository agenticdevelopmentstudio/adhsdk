
- **Data collected**: The user's appearance choices (colour mode, motion, contrast, text size, spacing, focus outlines, underline links). None of it identifies the person.
- **Storage**: In memory for the page's life and in `localStorage` under `adh:appearance` as the JSON of `AppearancePrefs`. The store never writes anywhere else.
- **Transmission**: The store sends nothing off the device. The server copy is read and written by the consuming application.
- **Retention**: The cache lasts until sign-out, when `resetAppearance` removes it so the next person on a shared browser does not inherit the previous user's theme. A browser that never signs out keeps it indefinitely.

