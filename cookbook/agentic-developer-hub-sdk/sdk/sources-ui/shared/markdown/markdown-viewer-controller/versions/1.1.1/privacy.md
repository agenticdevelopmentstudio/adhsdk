
**Data collected**: Theme preference (ID string, e.g., "dark" or "light") — web only, where the component owns the selection. On Apple, the component receives `palette` from the host and does not itself collect or store anything. No sensitive user data is collected or transmitted on either platform.

**Storage**: On web, the theme ID is persisted to `localStorage`, local-only and never sent to a server. On Apple, persistence (if any) is the host's responsibility — e.g. via `UserDefaults` — since the component only receives an already-resolved `palette`.

**Transmission**: No data is transmitted to analytics or telemetry services by the component.

**Retention**: On web, the theme preference persists until the user clears storage or selects a different theme; no expiry or automatic cleanup. Apple retention is whatever the host implements.

