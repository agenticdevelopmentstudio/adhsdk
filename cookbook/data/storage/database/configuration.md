
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `path` | string | required | Database file path, or `":memory:"` for a private in-memory database using a single shared connection. |
| `readers` | integer | `3` | Size of the read connection pool. |
| `readDeadline` | duration | 10 seconds | Default ejection ceiling for a top-level read. |
| `writeDeadline` | duration | 60 seconds | Default ejection ceiling for a top-level write or transaction-free write. |
| `busyTimeout` | duration (seconds) | `5` | Seconds to wait on a locked database before failing. |
| `prepare` | optional hook function | none | Runs on every connection at open, after the temp-store setting and before the ejection mechanism is installed; for app-specific setup. |
| `deadline` (per call) | optional duration | none (use the lane default) | Overrides the deadline for one top-level call; ignored on nested calls. |
| Declared display name (platform bundle metadata) | string | `"AgenticDeveloperHubSDK"` when absent or empty | Source of the display name and token. |
| `home` (storage-directory operation) | location | required | Directory under which the dotfolder is placed. |
| `token` (storage-directory operation) | string | the default token | Name folded to lowercase for the dotfolder. |
| Progress-check interval | constant | 1000 execution steps | Not configurable. |
| Percentile window | constant | 128 durations per lane | Not configurable. |
| `service` (`KeychainAccountCredentialStore`) | string | required | Keychain service the credential item lives under; a daemon passes `<its label>.accounts`. |
| `label` (`AccountQuotaProbe`, `AccountRouterConfiguration`) | string | required | The daemon's label; names the probe queue and the router's log subsystem and queues. |
| `credentials` (`AccountQuotaProbe`) | `AccountCredentialStore` | required | Where the held credential set is saved. |
| `userAgent` (`AccountQuotaProbe`) | string | `ClaudeTokenRefresher.userAgent` | The `User-Agent` every probe sends. |
| `dataDirectory`, `fingerprintsPath`, `upstream`, `templateDirectory`, `providerSecret` (`AccountRouterConfiguration`) | various | `upstream` is `https://api.anthropic.com`; templates go in the data directory's template subdirectory; provider keys come from the shared Keychain namespace | Where the router keeps its files, where it sends requests and how it reads provider keys. |
| `router` (`AccountRouterRoutes.table`) | optional `AccountRouterServer` | required | The daemon's router; nil makes `/router/*` answer 503. |
| `probe` (`AccountRouterRoutes.table`) | `AccountQuotaProbe` | required | The probe that takes custody of relayed credentials. |
| `since_hours` default | constant | `24` (`AccountRouterRoutes.defaultReportHours`) | The report window when the query omits it. |
| `workTracking` (`ActivityRoutes.table`) | optional `ActivityRoutes.WorkTrackingControl` | required | The daemon's work tracker (status, apply, recheck); nil makes those three routes answer 503. |
| `appRegistry` (`ActivityRoutes.table`) | optional `SessionAppRegistry` | required | The single-instance registry; nil leaves `/app/*` unserved. |
