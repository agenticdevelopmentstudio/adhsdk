---
id: 587b3d8d-5f9d-4a32-80ae-ffc053ec49df
title: "Database Stats DTO"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Per-lane bounded-execution counters a daemon's database-stats endpoint returns: in-flight, completed, evicted and latency."
platforms:
  - swift
  - macos
tags:
  - stenographer
  - foundation
  - dto
  - wire
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Database Stats DTO

## Overview

`DBStatsDTO` is the payload of a daemon's database-stats endpoint: per-lane bounded-execution counters. It holds two lists of `DBStatsDTO.Pool`, one for write lanes and one for read lanes. Each `Pool` names a pool and gives its in-flight, completed and evicted counts and its p50 and p99 latency in milliseconds. The type is a plain value; the daemon fills it and a client reads it. The daemon's `DaemonDatabase.dbStats()` fills it from its bounded database executor and serves it at `GET /db/stats`; the counting and timing live in that executor, outside this file.

## Behavioral Requirements

- **stats-fields**: A `DBStatsDTO` MUST carry `write` and `read`, each an array of `DBStatsDTO.Pool`.
- **stats-memberwise-init**: `DBStatsDTO.init(write:read:)` MUST set both arrays as given, with no default.
- **pool-fields**: A `DBStatsDTO.Pool` MUST carry `pool` (String), `inFlight` (Int), `completed` (Int), `evicted` (Int), `p50Ms` (Double) and `p99Ms` (Double).
- **pool-name**: `pool` SHOULD be the name of the lane the counters describe (the DTO accepts any string, see **no-validation**). Producer behavior, not enforced here: the daemon's `DaemonDatabase.dbStats()` fills `write` with the lane named `write` and `read` with the lane named `read`.
- **pool-counters**: `inFlight`, `completed` and `evicted` MUST be integer counters, one per lane: `inFlight` is the operations running now, `completed` the operations that finished within their deadline and `evicted` the operations ejected for exceeding it, which the daemon does not count as completed (producer behavior, not enforced here).
- **pool-latency-unit**: `p50Ms` and `p99Ms` MUST be milliseconds. Producer behavior, not enforced here: the daemon takes them over the most recent 128 completed operations of the lane and reports 0 for a lane with none.
- **pool-memberwise-init**: `Pool.init(pool:inFlight:completed:evicted:p50Ms:p99Ms:)` MUST set every field as given, with no default.
- **conformance-protocols**: `DBStatsDTO` and `DBStatsDTO.Pool` MUST be `Codable` and `Sendable`.
- **not-equatable**: `DBStatsDTO` and `Pool` need not be `Equatable`; the Swift source declares neither, and a port MAY compare fields explicitly.
- **no-validation**: The initializers MUST NOT validate: they accept negative counts, a p99 below the p50 and an empty pool name.
- **empty-arrays-encoded**: An empty `write` or `read` list MUST be carried as an empty array, never by omitting the key.
- **wire-keys**: The synthesized `Codable` MUST use the property names as JSON keys: `write`, `read`, `pool`, `inFlight`, `completed`, `evicted`, `p50Ms`, `p99Ms`.

## Appearance

Not applicable — this is a data shape, not a visual component.

## States

Not applicable — this is a data shape, not a visual component.

## Accessibility

Not applicable — this is a data shape, not a visual component.

## Conformance Test Vectors

`DBStatsDTOConformanceTests` (Core test target) covers every vector, derived from the declarations.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| db-stats-dto-001 | pool-memberwise-init, pool-fields | `Pool(pool: "write", inFlight: 1, completed: 10, evicted: 2, p50Ms: 1.5, p99Ms: 9.0)` | each field reads back as given |
| db-stats-dto-002 | stats-memberwise-init, stats-fields | `DBStatsDTO(write: [a], read: [b, c])` | `write` has one pool and `read` has two, in order |
| db-stats-dto-003 | wire-keys | encode a stats value with one write pool | JSON has `write` and `read` arrays whose pool objects have keys `pool`, `inFlight`, `completed`, `evicted`, `p50Ms`, `p99Ms` |
| db-stats-dto-004 | wire-keys, conformance-protocols | decode the JSON from vector 003 | an equal field-for-field value |
| db-stats-dto-005 | stats-fields, empty-arrays-encoded | `DBStatsDTO(write: [], read: [])` | both arrays empty; encode and decode succeed, and the encoded JSON contains both keys as empty arrays |
| db-stats-dto-006 | no-validation | `Pool(pool: "", inFlight: -1, completed: 0, evicted: 0, p50Ms: 5, p99Ms: 1)` | constructs without error and keeps the values |
| db-stats-dto-007 | stats-fields | decode JSON that lacks the `read` key | decoding fails; both lists are required |

## Edge Cases

- **Empty lists**: a daemon with no write or no read lanes returns an empty array; the shape carries it as an empty array, not an omitted key (see **empty-arrays-encoded**).
- **Missing key**: a payload without `write` or `read` fails to decode, because neither is optional.
- **Boundary values**: counters and latencies are unbounded here; zero, negative and very large values all construct, and the source states no range.
- **Unit mixups**: the field names carry `Ms`; a client MUST read the latencies as milliseconds and not scale them.
- **Lane with no completed work**: the daemon reports `p50Ms` and `p99Ms` of 0 for a lane that has completed nothing, so 0 is not a measured latency.
- **Concurrent access**: both types are immutable `Sendable` values, so a snapshot is safe to share across threads; the counters are a point-in-time snapshot taken by the daemon.
- **Error and offline states**: the type performs no I/O; an unreachable daemon is the client's failure, not this shape's.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| write | array of `Pool` | none (caller supplies) | Write-lane counters. |
| read | array of `Pool` | none (caller supplies) | Read-lane counters. |

## Deep Linking

Not applicable: this shape defines no URL or deep link.

## Localization

Not applicable: the shape holds numbers and a pool name, and no user-facing string.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: the counters and pool names describe the daemon's database lanes, not a person's content.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: A diagnostics view lists the two arrays in a `Table` or `List`, one row per pool.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; `Int` becomes `Long`, because Swift `Int` is 64-bit on Apple platforms and counters could overflow a 32-bit `Int`; `Double` stays `Double`; the property names are the JSON keys.
- **React/Web**: TypeScript interface with `write: Pool[]` and `read: Pool[]`; all numbers are `number`.
- **AppKit / UIKit**: The types are UI-agnostic; an AppKit or UIKit diagnostics panel reads the two arrays into an `NSTableView` or `UITableView`, one row per pool. Public memberwise initializers must be written out by hand in Swift because synthesized ones are internal.
- **WinUI 3**: Use C# records (`public sealed record DbStats(IReadOnlyList<Pool> Write, IReadOnlyList<Pool> Read)` and a nested `Pool` record with `int` and `double` members) and `System.Text.Json` with `JsonNamingPolicy.CamelCase`; bind the lists to a `DataGrid` or `ListView` through an `ObservableCollection` when the view refreshes; `HttpClient.GetFromJsonAsync` reads the endpoint.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/DBStatsDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The counters are grouped by lane kind, `write` and `read`, as two arrays of one `Pool` shape.
**Rationale**: The source's header calls them per-lane bounded-execution counters, and one shape for every lane keeps a new lane a new element and not a new field.
**Approved**: pending

**Decision**: The DTO is `Codable` and `Sendable` but not `Equatable`.
**Rationale**: A stats snapshot is a point-in-time reading with floating-point latencies, so nothing needs to compare two of them for equality; a port should not assume value equality on one.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.reliability.health-observability](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d4ece88d-eeff-5e3f-8823-d8c2929a35e0) | passed | reliability |

separation-of-concerns passes: the file is two shapes and no behavior. unit-test-coverage passes: `DBStatsDTOConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/DBStatsDTOConformanceTests.swift`) covers vectors 001 to 007. health-observability passes: the shape exists to expose in-flight, completed, evicted and latency figures for each lane.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (DBStatsDTOConformanceTests.swift, 7 of 7 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Relaxed pool-name and not-equatable, marked producer behavior, added empty-arrays-encoded, fixed vector 001, the Long note and platform notes, and shortened the summary. |
