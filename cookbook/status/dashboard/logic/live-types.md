---
id: 41f840c1-ea34-489d-9b9f-a61dec2a9402
title: "Live Snapshot Wire Types"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Type-only wire contract for the status dashboard's /api/live snapshot, shared by the live store and its consumers."
platforms:
  - typescript
  - web
tags: []
depends-on: []
related:
  - ca7205d2-31c0-424a-95a2-a356bed30187
  - 15c61cfc-543c-493d-b686-c605b773be83
  - eb7e9eeb-86f3-4053-827a-ea259833c6ad
references: []
approved-by: ""
approved-date: ""
---

# Live Snapshot Wire Types

## Overview

`packages/web/packages/status-web/src/lib/live-types.ts` declares the `/api/live` contract: in its header's words, "one self-contained snapshot of everything the client displays." It is a hand mirror of the status server's copy, and every verdict in it (freshness, blindness, the per-platform pills, which monitors are retire candidates, an endpoint's deploys, an unconfirmed deploy's status) is the server's; the client renders the fields and owns no copy of the rules behind them.

It exports two string unions (`ProviderKey`, `SnapshotFreshnessState`) and ten interfaces (`EndpointDeploys`, `LiveServiceDTO`, `LiveDeploymentDTO`, `StaleProdDTO`, `ProviderHealth`, `LiveFreshness`, `PlatformSummary`, `StaleMonitor`, `StaleMonitorsView`, `LiveSnapshot`) built on `ServiceStatusDTO`, `DeploymentDTO` and `DeployStatus` from `../types`. It emits no runtime code.

Consumers in the web package: `use-live-snapshot.ts` types every SSE frame and every `/api/live` poll response as `LiveSnapshot` and compares frames with `isSameSnapshot`; `SnapshotStaleBanner` renders `freshness`; `StaleMonitorsBanner` renders `staleMonitors`; `Dashboard` renders `platformSummary`; `DeployList` reads `unconfirmedAt`; `OverviewTab` shows `monitorVersion` and reads `blind`. `live-snapshot.fixture.ts` builds the default test snapshot. The status server holds its own copy of these types in `status-server/src/monitor/live-types.ts` and produces the payload in `routes/reads.ts`.
## Behavioral Requirements

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

## Appearance

Not applicable — this is a type-only wire contract, not a visual component.

## States

Not applicable — this is a type-only wire contract, not a visual component.

## Accessibility

Not applicable — this is a type-only wire contract, not a visual component.

## Conformance Test Vectors
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| live-types-001 | snapshot-required-fields | `liveSnapshot()` from the fixture: `generatedAt: "2026-06-30T00:00:00.000Z"`, empty `services`/`deployments`/`staleProd`/`platformSummary`, all four providers `{ configured: true, ok: true }`, `configDegraded: false`, `configReason: null`, `lastCycleAt: null`, `probeIntervalMs: 60000`, `monitorVersion: null`, `freshness: { state: "fresh", asOf: null }`, `blind: false`, `staleMonitors: { thresholdDays: 7, monitors: [] }` | Carries exactly the fourteen `LiveSnapshot` keys; typechecks as `LiveSnapshot`, and removing any required field fails to typecheck |
| live-types-002 | provider-key-members, provider-health-fields, providers-complete | Read the fixture's `providers` | Exactly the keys `cloudflare-pages`, `crunchy`, `railway`, `vercel` (no `cloudflare`); each value has exactly `configured` and `ok`, both booleans |
| live-types-003 | generated-at-identity | `isSameSnapshot(a, b)` where `a` and `b` are distinct objects with `generatedAt: "2026-06-30T00:00:00.000Z"`; then with `b.generatedAt: "2026-06-30T00:01:00.000Z"`; then `isSameSnapshot(null, b)` | `true`, then `false`, then `false` |
| live-types-004 | live-service-extends, live-service-status-values, dns-ok-field, down-since-field, down-since-null | A `LiveServiceDTO` literal with every `ServiceStatusDTO` and `EndpointDeploys` field, `status: "unknown"`, `dnsOk: true`, `downSince: null` | Typechecks; omitting `dnsOk` or `downSince`, or setting `status: "offline"`, fails to typecheck (compile-time only) |
| live-types-005 | stale-prod-fields | A `StaleProdDTO` with `projectName: "site"`, `environment: "production"`, and `detail`, `sourceUrl`, `liveUrl` all `null` | Typechecks; `environment: null` fails to typecheck (compile-time only) |
| live-types-006 | provider-key-members | Assign `"cloudflare"` as a `ProviderKey` | Fails to typecheck; `"cloudflare-pages"` typechecks (compile-time only) |
| live-types-007 | type-only-module, no-side-effects | Import the module and inspect its runtime exports | No runtime values are exported |
| live-types-008 | no-db-imports | Read the module's import statements | Exactly one, a type-only import from `../types` |
| live-types-009 | server-parity | Compare the client's `LiveSnapshot`, `LiveServiceDTO`, `LiveDeploymentDTO`, `LiveFreshness`, `PlatformSummary` and `StaleMonitorsView` with the server's | Mutually assignable (compile-time only, enforced by the read-types parity guard) |
## Edge Cases

- **Missing required field**: A payload that omits a required `LiveSnapshot` field does not typecheck, but there is no runtime validation, so one cast from JSON reaches consumers as-is; the consumers' optional chaining on `freshness` and `staleMonitors` tolerates it. MUST (fact of the contract).
- **First probe not yet run**: `lastCycleAt: null` MUST mean no probe has run, and MUST NOT make the client raise a warning on its own; the server's `freshness` decides. MUST.
- **Empty snapshot**: `services`, `deployments` and `staleProd` MAY each be empty arrays (the fixture default). MUST.
- **Endpoint down with no onset**: A `down` service with `downSince: null` carries no onset; the client MUST NOT invent one from a per-tab clock. MUST.
- **Unknown union member at runtime**: A `status` or provider key outside the declared unions is not rejected (no runtime validation); it reaches consumers unchecked. MUST (fact of the contract).
- **Re-delivered frame**: A frame whose `generatedAt` equals the last ingested one MUST be treated as the same delivery. MUST.
- **Client and server copies drift**: A field renamed in only one copy fails the typecheck of `read-types-parity.test.ts`; see server-parity. MUST.
- **Config fallback**: `configDegraded` MUST be `true` only on the static-list fallback; the server's successful-read path always sends `configDegraded: false` and `configReason: null`. MUST.
- **Concurrency, network, offline, cancellation, timeouts**: Not applicable; the module has no runtime behavior. Transport failures are owned by `use-live-snapshot.ts`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| — | — | — | None. The module takes no parameters, environment variables or injected dependencies. `probeIntervalMs` and `monitorVersion` are set by the server, not by this module. |

## Deep Linking

Not applicable: the module declares data types and handles no URLs or routes.

## Localization

Not applicable: the module holds no strings; `configReason`, `StaleProdDTO.detail` and service `error` are server-supplied values.

## Accessibility Options

Not applicable: the module has no visual output.

## Feature Flags

Not applicable: the module reads no flags.

## Analytics

Not applicable: the module emits no events.

## Privacy

Not applicable: the module stores and transmits nothing; the fields it types (service names, URLs, commit hashes, provider health) carry no credentials or personal data by declaration.

## Logging

Not applicable: the module has no runtime code and logs nothing.

## Platform Notes

- **SwiftUI**: Model each interface as a `struct` conforming to `Codable, Sendable, Equatable` and `ProviderKey` as a `String` raw-value `enum` with `case cloudflarePages = "cloudflare-pages"`. Decode `providers` as `[ProviderKey: ProviderHealth]` (a `Codable` dictionary keyed by a `String` enum needs `CodingKeyRepresentable`) and check all four keys are present. Nullable fields (`lastCycleAt`, `monitorVersion`, `configReason`, `downSince`) become Swift optionals. Unlike TypeScript, `JSONDecoder` rejects an unknown enum member, so add an `unknown` fallback if tolerance is wanted.
- **Compose**: Kotlin `@Serializable data class` per interface with `kotlinx.serialization`; `ProviderKey` as an `enum class` with `@SerialName("cloudflare-pages")`; `providers` as `Map<ProviderKey, ProviderHealth>`. Give nullable fields defaults (`val lastCycleAt: String? = null`, `val monitorVersion: String? = null`); set `Json { ignoreUnknownKeys = true }`.
- **React/Web**: Source platform. `src/lib/live-types.ts` is the type-only contract, `src/lib/live-snapshot.fixture.ts` the default test snapshot, and `src/hooks/use-live-snapshot.ts` the only producer of typed values (by cast). Types are erased, so a port wanting runtime safety adds a schema (for example zod) at the fetch and SSE parse sites.
- **AppKit / UIKit**: Same `Codable` structs as the SwiftUI note, in a UI-free module shared by both; no framework types are involved.
- **WinUI 3**: Declare C# `record` types (`public sealed record LiveSnapshot(...)`) with `string?`, `long?` and `bool` properties and `IReadOnlyList<T>` for arrays, deserialized with `System.Text.Json` using `JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }`. `LiveServiceDTO` extends a `ServiceStatusDTO` record by record inheritance. `providers` becomes `IReadOnlyDictionary<string, ProviderHealth>` (a C# enum key would need a custom converter for `"cloudflare-pages"`); validate the four keys after deserializing. The nullable fields are nullable properties. `generatedAt` and `lastCycleAt` may be `DateTimeOffset?`, but keep `generatedAt`'s raw string if frame identity comparison is ported. Surface the snapshot through a view model implementing `INotifyPropertyChanged`, projecting `services` and `deployments` into `ObservableCollection<T>`; there is no compile-time parity check against the server, so a shared contract assembly or JSON-schema test is the equivalent guard.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-web/src/lib/live-types.ts` | confirmed (2.0.0) |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

The module holds only the wire contract, with transport, selection and rendering in other modules, so separation-of-concerns passes. Unit-test-coverage is partial: live-types-001, 002, 003, 007 and 008 have passing tests, while live-types-004, 005, 006 and 009 are skipped because they are compile-time facts (type assignability and the client/server parity guard in `read-types-parity.test.ts`) that vitest cannot exercise at runtime; `tsc` enforces them. Data-integrity is partial because the parity guard is a typecheck, and no runtime check rejects a mismatched payload. Graceful-degradation passes: the server always sends every snapshot field and the freshness verdict, and consumers read the verdict rather than derive it.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-14 | Mike Fullerton | Match recipe to source: fourteen required snapshot fields, server-owned verdicts, removed client-side selection functions |
| 1.0.2 | 2026-09-27 | Mike Fullerton | Moved into the concept grouping. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial recipe extracted from `live-types.ts` and its consumers |
