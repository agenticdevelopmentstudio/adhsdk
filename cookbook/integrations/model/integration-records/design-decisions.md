
**Decision**: Persist non-column properties as JSON text through the `Codable` conformance instead of writing per-record encode code.
**Rationale**: GRDB stores these `Codable` values as JSON TEXT on its own, so adding a field to a nested type such as `MailSyncSettings` changes no column and needs no schema migration or mapping code.
**Approved**: pending

**Decision**: Cache `mailClass` on `EmailMessage`, derived once in the initializer when not supplied.
**Rationale**: Queries and tombstoning read the class directly instead of re-running the classifier over `labelIds` for every row; the explicit parameter lets the store restore a stored class unchanged even if the classifier rules later change.
**Approved**: pending

**Decision**: Keep `EmailLabel.type`, `ActionLog.status` and `ActionLog.requestPayload` as plain strings rather than enums or typed payloads.
**Rationale**: The value sets are documented only in comments, and this version keeps them as strings. Enum text that is not a known raw value fails to decode the whole row, so a new provider-side label type or action state would make existing rows unreadable. A port may promote them to enums stored as raw-value TEXT, as `ConnectionStatus` is, once the sets are closed.
**Approved**: pending

**Decision**: Store every timestamp as an ISO-8601 UTC string with fractional seconds.
**Rationale**: A fixed-width UTC string with three fractional digits sorts and compares correctly as text in SQLite, so queries and cursors need no date parsing.
**Approved**: pending

