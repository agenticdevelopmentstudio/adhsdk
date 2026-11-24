
- **Data collected**: The calls carry the tracked-app preferences and activity spans (app, window title, working path, repository, branch).
- **Storage**: None; the client holds no state and does not cache.
- **Transmission**: To a daemon on the same machine over XPC; no networking in this code.
- **Retention**: None here.

