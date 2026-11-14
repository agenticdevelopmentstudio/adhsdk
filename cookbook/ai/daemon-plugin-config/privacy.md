
- **Data collected**: The component handles plugin identifiers and field keys as key text. It never sees field values or secrets, only the names under which the daemon stores them.
- **Storage**: None by the component. Per its doc comment the daemon stores non-secret fields in its settings table and secret fields in its own Keychain namespace under these keys.
- **Transmission**: None by the component; keys are an internal daemon detail and the wire protocol carries descriptor field keys, not these strings.
- **Retention**: None by the component. The secret-fields ledger exists so the daemon can delete a plugin's Keychain secrets on a plugin switch; `PreferencesService.clearStoredSecrets(forPlugin:)` does that by reading the ledger.

