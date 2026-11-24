
- **Data collected**: The bundle ids the user added or removed and the retention length.
- **Storage**: The shared user-settings store, through `UserSetting`; this code adds none.
- **Transmission**: None by this code; the snapshot leaves the process only when the app pushes it to the daemon.
- **Retention**: Until the user changes or removes a setting.

