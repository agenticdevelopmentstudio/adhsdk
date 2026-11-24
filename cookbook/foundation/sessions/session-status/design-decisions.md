
**Decision**: `SessionStatus` records only whether a process exists, and activity is a separate enum.
**Rationale**: The `SessionActivity` source states it is "distinct from its `SessionStatus` ('does a process exist')". Keeping the two apart lets a session be alive and idle, alive and working, or alive and blocked.
**Approved**: pending

**Decision**: The raw strings are the stored and published values, so the case names double as the wire format.
**Rationale**: The daemon code writes `rawValue` into the sessions table and the status-change payload, and compares rows with `SessionStatus.active.rawValue`. Renaming a case would change stored data and the payload.
**Approved**: pending

**Decision**: `stale` stays declared although the SDK's liveness service never sets it.
**Rationale**: The source declares three cases and the daemon's own comments name "ended / stale" as the status changes it publishes. The SDK code searched sets only `active` and `ended`, but the schema's `CHECK` constraint allows `stale` and the liveness query reads `active` and `stale` rows, so a port keeps the case to read values written elsewhere.
**Approved**: pending

**Decision**: The enum has no fallback case for an unknown raw string.
**Rationale**: The source declares exactly three cases, and the failable `init(rawValue:)` returns `nil` for anything else, leaving the caller to choose how to treat an unknown stored value.
**Approved**: pending

