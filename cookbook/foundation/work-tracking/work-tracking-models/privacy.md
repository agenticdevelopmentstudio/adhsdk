
- **Data collected**: The models describe the data tracking holds: bundle ids the user added or removed, and a current `ActivitySpanDTO` that carries window title, working path, repo root and branch.
- **Storage**: Not in this file. `WorkTrackingSettingsKeys` names the daemon's `settings` keys that hold the preferences and the last Accessibility answer.
- **Transmission**: Not in this file. The models are the payloads the app and the daemon exchange.
- **Retention**: `retentionDays` is the user's retention setting, default 90 and clamped to 7 through 3650. This file only holds and clamps the number.

