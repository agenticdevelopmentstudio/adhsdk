
**Decision**: Made `lastCycleAt`, `probeIntervalMs` and `monitorVersion` required on the client, matching the server copy; they were once optional so an older backend degraded gracefully.
**Rationale**: The staleness window and the freshness verdict moved to the server, so the client no longer needs a floor or a fallback for a missing field; the parity guard keeps the two copies identical.
**Approved**: pending

**Decision**: Carry `downSince` as server truth rather than the client's per-tab onset.
**Rationale**: The doc comment calls it "durable across browsers (unlike the client store's per-tab onset)"; the retire-stale-monitor surface judges a 7-day outage and needs an onset that survives reloads.
**Approved**: pending

**Decision**: Carry `lastCycleAt` separately from `generatedAt`.
**Rationale**: `generatedAt` "is read-time and always looks fresh", so only the newest-persisted-probe clock can expose a wedged or never-redeployed poller.
**Approved**: pending

**Decision**: Keep the module type-only with no DB imports.
**Rationale**: The header states it is shared by the route and the client store; a DB import would drag server code into the browser bundle.
**Approved**: pending

