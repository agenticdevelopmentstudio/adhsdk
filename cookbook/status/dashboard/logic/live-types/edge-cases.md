
- **Missing required field**: A payload that omits a required `LiveSnapshot` field does not typecheck, but there is no runtime validation, so one cast from JSON reaches consumers as-is; the consumers' optional chaining on `freshness` and `staleMonitors` tolerates it. MUST (fact of the contract).
- **First probe not yet run**: `lastCycleAt: null` MUST mean no probe has run, and MUST NOT make the client raise a warning on its own; the server's `freshness` decides. MUST.
- **Empty snapshot**: `services`, `deployments` and `staleProd` MAY each be empty arrays (the fixture default). MUST.
- **Endpoint down with no onset**: A `down` service with `downSince: null` carries no onset; the client MUST NOT invent one from a per-tab clock. MUST.
- **Unknown union member at runtime**: A `status` or provider key outside the declared unions is not rejected (no runtime validation); it reaches consumers unchecked. MUST (fact of the contract).
- **Re-delivered frame**: A frame whose `generatedAt` equals the last ingested one MUST be treated as the same delivery. MUST.
- **Client and server copies drift**: A field renamed in only one copy fails the typecheck of `read-types-parity.test.ts`; see server-parity. MUST.
- **Config fallback**: `configDegraded` MUST be `true` only on the static-list fallback; the server's successful-read path always sends `configDegraded: false` and `configReason: null`. MUST.
- **Concurrency, network, offline, cancellation, timeouts**: Not applicable; the module has no runtime behavior. Transport failures are owned by `use-live-snapshot.ts`.

