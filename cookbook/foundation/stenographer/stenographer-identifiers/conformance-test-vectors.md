
The source has no test file of its own. `ADKDIdentifiersTests` builds `StenographerPaths(home:exists:)` with `exists` always false and compares several of its values with the Kitchen daemon's; all other vectors are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stenographer-identifiers-001 | http-port | `httpPort`, `httpBaseURL` | `22847` and `http://127.0.0.1:22847`. |
| stenographer-identifiers-002 | router-port | `routerPort`, `routerBaseURL` | `22848` and `http://127.0.0.1:22848`, different from the HTTP port. |
| stenographer-identifiers-003 | label-value, keychain-service-values | The label and keychain constants. | `com.agenticdevelopmentstudio.stenographer`; `daemonKeychainService` `com.agenticdevelopmentstudio.stenographer.daemon`; legacy daemon service `com.agentic-cookbook.stenographer.daemon`. |
| stenographer-identifiers-004 | subsystem-suffix | `subsystem("db")` and `subsystem("")` | `com.agenticdevelopmentstudio.stenographer.db` and the label followed by a trailing dot. |
| stenographer-identifiers-005 | support-directory-resolution | `exists` is true only for `<current>/stenographer.db` | `supportDirectory` is `<home>/Library/Application Support/com.agenticdevelopmentstudio.stenographer`. |
| stenographer-identifiers-006 | support-directory-resolution, empty-current-does-not-hide | `exists` is true for the legacy directory and for the current directory but not for the database file. | `supportDirectory` is the legacy directory. |
| stenographer-identifiers-007 | support-directory-resolution | `exists` is always false (the fresh-install case that `ADKDIdentifiersTests` builds). | `supportDirectory` is the current directory; `logsDirectory` is the current logs directory. |
| stenographer-identifiers-008 | plugin-directories, plugin-directories-both | Any `home`. | Two URLs, the current then the legacy `Plugins` directory, in that order. |
| stenographer-identifiers-009 | write-support-file, write-support-file-attempts | The closure creates the file; `exists` flips to make the legacy directory resolve to the current one after the first write. | The closure runs twice, the second time in the current directory, and the returned URL is the current one. |
| stenographer-identifiers-010 | write-support-file-attempts | `attempts: 0` and a directory that never stabilises. | The closure runs once (`max(attempts, 1)`), and with `attempts: 3` and a directory that changes every time it runs three times; in both cases the returned URL is the one resolved after the last write, not a location written to. |
| stenographer-identifiers-011 | write-support-file-errors | The closure throws. | The error propagates and the closure has run once. |
| stenographer-identifiers-012 | launch-agent-plists | Any `home`. | `Library/LaunchAgents/` plus the label, legacy label and legacy menubar label, each with `.plist`. |
| stenographer-identifiers-013 | label-value, http-port, keychain-service-values, file-names | Compare with `ADKDIdentifiers` (test: testNothingCollidesWithStenographer). | The label, port, keychain service, database name, support directory, logs directory and launch-agent plist all differ. |

