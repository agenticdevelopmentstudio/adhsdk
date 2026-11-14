
- **Data collected**: the user's custom theme definitions (colors, names, typography) and the id of the selected theme; no personal identifiers.
- **Storage**: the `UserDefaults` domain given to `init`, which is the app's preferences property list when the standard defaults are used or the shared suite's list for an app group. The source applies no encryption and sets no protection level.
- **Transmission**: this class sends nothing. A host that uses an iCloud-backed or shared domain has `UserDefaults` carry the values; that is outside this code.
- **Retention**: until the host overwrites or removes the keys; the class has no expiry or cleanup.

