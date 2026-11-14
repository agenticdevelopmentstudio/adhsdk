
- **Data collected**: None. The allowlist holds bundle ids and display names only, and no user content.
- **Storage**: None. The type is in memory; the added and removed ids it reads are stored by `WorkTrackingPreferences`, outside this code.
- **Transmission**: None.
- **Retention**: Not applicable here; `retentionDays` belongs to `WorkTrackingPreferences`.
- **Purpose**: The allowlist is the gate on what gets recorded: only apps on it are stored, and anything else is never stored.

