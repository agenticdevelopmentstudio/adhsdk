
### Module shape

- **type-only-module**: The module MUST export only types; importing it MUST produce no runtime value or side effect.
- **no-db-imports**: The module MUST NOT import database or storage code; its only import MUST be the type-only import of `ServiceStatusDTO`, `DeploymentDTO` and `DeployStatus` from `../types`.
- **no-runtime-validation**: The module MUST NOT validate a payload at runtime; `use-live-snapshot.ts` casts `JSON.parse(data) as LiveSnapshot` and `(await r.json()) as LiveSnapshot` unchecked, so a mismatched payload reaches consumers as-is.
- **server-parity**: The module is a hand mirror of the server copy (`status-server/src/monitor/live-types.ts`), which the route uses. `read-types-parity.test.ts` pins the two with mutual-assignability assertions for `LiveServiceDTO`, `LiveDeploymentDTO`, `LiveFreshness`, `PlatformSummary`, `StaleMonitorsView` and `LiveSnapshot`, so a field changed in only one copy fails the typecheck. A port keeps one definition of these types for both server and client, or keeps an equivalent parity guard.

### LiveServiceDTO

- **live-service-extends**: `LiveServiceDTO` MUST carry every field of `ServiceStatusDTO` (`slug`, `group`, `name`, `url`, `environment`, `platform`, `deployProject`, `status`, `responseTimeMs`, `statusCode`, `error`, `lastCheckedAt`, `slow`) and of `EndpointDeploys` (`deployIds`, `latestTerminalDeployId`, `deployFailures`) plus `dnsOk` and `downSince`.
- **live-service-status-values**: `LiveServiceDTO.status` MUST be one of `"healthy"`, `"degraded"`, `"down"` or `"unknown"` (`HealthStatus | "unknown"`).
- **dns-ok-field**: `dnsOk` MUST be a required `boolean` stating whether the hostname resolved in DNS.
- **dns-ok-source-meaning**: `dnsOk: false` MUST denote a `dns`-source problem, not an `http`-source one.
- **down-since-field**: `downSince` MUST be a required `string | null`: the ISO time the endpoint's current http/dns issue opened.
- **down-since-null**: `downSince` MUST be `null` when the endpoint is not down.
- **down-since-server-truth**: `downSince` MUST be the server's durable onset, identical across browsers, and consumers MUST NOT substitute a per-tab onset for it.

### StaleProdDTO

- **stale-prod-fields**: `StaleProdDTO` MUST carry exactly `projectName: string`, `environment: string`, `detail: string | null`, `sourceUrl: string | null`, `liveUrl: string | null`.
- **stale-prod-prefiltered**: Every entry in `LiveSnapshot.staleProd` MUST already be a Vercel project whose live production deploy is errored or behind; consumers MUST NOT re-filter it for staleness.

### Providers

- **provider-key-members**: `ProviderKey` MUST be exactly `"vercel" | "cloudflare-pages" | "railway" | "crunchy"`.
- **provider-health-fields**: `ProviderHealth` MUST carry exactly `configured: boolean` and `ok: boolean`.
- **provider-configured-meaning**: `configured` MUST be `true` only when the platform is actually polled: an active integration that has a token.
- **provider-ok-meaning**: `ok` MUST state whether the latest poll reached the provider API.
- **providers-complete**: `LiveSnapshot.providers` MUST be a `Record<ProviderKey, ProviderHealth>` holding an entry for every one of the four `ProviderKey` members.

### LiveSnapshot

- **snapshot-required-fields**: `LiveSnapshot` MUST carry exactly fourteen required fields: `generatedAt: string`, `lastCycleAt: string | null`, `probeIntervalMs: number`, `monitorVersion: string | null`, `services: LiveServiceDTO[]`, `deployments: LiveDeploymentDTO[]`, `staleProd: StaleProdDTO[]`, `providers: Record<ProviderKey, ProviderHealth>`, `configDegraded: boolean`, `configReason: string | null`, `freshness: LiveFreshness`, `blind: boolean`, `platformSummary: PlatformSummary[]` and `staleMonitors: StaleMonitorsView`. None is optional; a payload that omits one does not typecheck.
- **generated-at-meaning**: `generatedAt` MUST be an ISO timestamp from the server clock, stamped at read time, and MUST serve as the client's event-time reference.
- **generated-at-identity**: `generatedAt` MUST identify a delivery: two snapshots with equal `generatedAt` are the same frame (`isSameSnapshot` returns `true` for them).
- **last-cycle-at-meaning**: `lastCycleAt` MUST be the ISO time of the newest persisted probe, and `null` before the first probe.
- **last-cycle-at-distinct**: `lastCycleAt` MUST NOT be treated as the scheduler's cycle-completion clock served at `/health`.
- **last-cycle-at-null**: A `null` `lastCycleAt` is the state before the first probe. The staleness verdict is the server's (`freshness`), so the client renders it and makes no judgment from the clock itself.
- **probe-interval-meaning**: `probeIntervalMs` MUST be the backend's probe interval in milliseconds, a required `number`. The client derives no staleness window from it.
- **monitor-version-meaning**: `monitorVersion` MUST be the git commit the monitor itself is running, or `null` when there is none (locally).
- **monitor-version-null**: A `null` `monitorVersion` MUST cause the board to show no version.
- **config-degraded-meaning**: `configDegraded` MUST be `true` only when the server's config read fell back to the static list because the database was unreachable.
- **config-reason-field**: `configReason` MUST be a `string | null` carried beside `configDegraded`; the module gives no further meaning to it.

### Server verdicts

- **freshness-field**: `freshness` MUST be a `LiveFreshness` with `state: SnapshotFreshnessState` (`"fresh"`, `"stale"` or `"very-stale"`) and `asOf: string | null`, the data clock the verdict was judged on; it is the server's verdict on how far `lastCycleAt` lags `generatedAt`, and the client MUST render it without re-deriving it.
- **blind-field**: `blind` MUST be a required `boolean`, `true` when no endpoint is monitored at all, and MUST NOT be read as healthy.
- **platform-summary-fields**: Each `PlatformSummary` MUST carry exactly `platform: string`, `ready: number`, `building: number`, `buildingUnconfirmedAt: string[]`, `failed: number` and `total: number`; `buildingUnconfirmedAt` lists when each deploy counted in `building` stops being believed.
- **stale-monitor-fields**: Each `StaleMonitor` MUST carry exactly `slug`, `name`, `url`, `environment: string | null`, `detail`, `dnsOk`, `downSince: string` and `ageMs: number`; `StaleMonitorsView` MUST carry `thresholdDays: number` and `monitors: StaleMonitor[]`, longest-down first. The selection is the server's and the client MUST NOT re-select.
- **endpoint-deploys-fields**: `EndpointDeploys` MUST carry `deployIds: string[]` (this snapshot's deployments of the endpoint's deploy target, newest first), `latestTerminalDeployId: string | null` and `deployFailures: number`.
- **live-deployment-fields**: `LiveDeploymentDTO` MUST extend `DeploymentDTO` with `effectiveStatus: DeployStatus` and `unconfirmedAt: string | null`; `unconfirmedAt` is when an in-flight `effectiveStatus` must read as `"unknown"` on a display still showing this snapshot, `null` when it never lapses.

### Concurrency and side effects

- **no-side-effects**: The module MUST perform no I/O, hold no state and have no ordering or concurrency behavior; it is erased at compile time.

