
- **Data collected**: the finding id, session id, terminal program and pane id, the claude pid and the text to inject.
- **Storage**: none here; the daemon owns the finding and session records.
- **Transmission**: values cross XPC or HTTP between the daemon and the app on the local machine; this code opens no connection.
- **Retention**: none defined by this code.

