
- **Data collected**: A list of file-name patterns the user types; patterns can reveal directory or project names.
- **Storage**: The plain (non-secure) backing store of `UserSettings.shared`; the key is not marked secure.
- **Transmission**: The component sends nothing; whether the list leaves the device depends on the backend behind `UserSettings.shared`, such as a cloud-synced one.
- **Retention**: Kept until the user edits the list or the store's value is removed; the component sets no expiry.

