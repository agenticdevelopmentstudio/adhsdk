
Subsystem: `com.agenticdeveloperhub.integrations` | Category: `Mail`

| Event | Level | Message |
|-------|-------|---------|
| Revoking a discarded sign-in's grant at Google failed | error | `Revoking a discarded sign-in at Google failed: <error>` |

This is the only log call in the file. Sync failures are recorded on the connection (`status`, `lastError`), not logged; a failed `batchModify` is recorded in the action log table, not in the system log.

