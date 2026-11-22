
- **Data collected**: The types carry, but do not collect, the following: item keys (`account`, `savedCredentials`, `accounts`), which embed an account email for OAuth credentials; `organizationId` / `organizationIds`; `sessionId`; request `method` and `path` without the query; quota utilizations; and token counts. They MUST NOT carry tokens, header values or bodies (secret-free).
- **Storage**: None. The types are in-memory values; the routing log they describe is stored by the daemon in its `account_router_exchange` table.
- **Transmission**: Values cross the loopback HTTP boundary between the daemon and its CLI and Settings clients; transport is the caller's.
- **Retention**: None in these types. `retentionDays` reports and sets how long the daemon keeps routing history (default 30, 0 forever).

