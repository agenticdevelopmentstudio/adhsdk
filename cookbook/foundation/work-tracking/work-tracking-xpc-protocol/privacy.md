
- **Data collected**: The payloads carry the tracked-app preferences and the activity spans (app, window title, working path, repository, branch), the latter through `ActivitySpanDTO`.
- **Storage**: None here; the daemon owns persistence.
- **Transmission**: Between an app and a daemon on the same machine through XPC; this code does no networking.
- **Retention**: Not set by the protocol; retention days travel in the preferences body.

