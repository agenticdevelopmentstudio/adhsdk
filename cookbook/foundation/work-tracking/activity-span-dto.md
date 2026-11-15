---
id: 92a9546a-eec1-47ed-8420-7db51e8d0261
title: "Activity Span DTO"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A Codable value type describing one contiguous stretch of focus on an allowlisted development app, with open and closed span semantics."
platforms:
  - swift
  - macos
tags:
  - work-tracking
  - foundation
  - dto
depends-on: []
related:
  - aa775836-5679-4a22-9ff3-b2bdcb09cc20
references: []
approved-by: ""
approved-date: ""
---

# Activity Span DTO

## Overview

`ActivitySpanDTO` is the wire and storage shape of one contiguous stretch of focus on an allowlisted development app, per its doc comment "One contiguous stretch of focus on an allowlisted development app." It is a plain value type (`Codable`, `Sendable`, `Equatable`, `Identifiable`) with no behavior beyond one derived flag, `isOpen`. It is carried inside `WorkTrackingStatus` ([adhsdk.ingredient.foundation.work-tracking.work-tracking-models](cookbook:aa775836-5679-4a22-9ff3-b2bdcb09cc20)) as `currentSpan` and is the span unit used by the work-tracking persistence contract. This ingredient covers the shape, defaults, sentinel values and mutability rules only.

## Behavioral Requirements

- **conformances**: `ActivitySpanDTO` MUST conform to `Codable`, `Sendable`, `Equatable` and `Identifiable`.
- **identity-field**: The type MUST expose `id` as a `String`, which serves as the `Identifiable` identity.
- **default-id**: When `init` is called without an `id`, the type MUST generate one from `UUID().uuidString`.
- **required-init-arguments**: `init` MUST require `bundleId`, `appName`, `startedAt` and `tz`; every other argument MUST have a default.
- **string-defaults**: `windowTitle`, `workingPath`, `repoRoot`, `branch`, `endedAt` and `lastSeenAt` MUST each default to the empty string.
- **all-strings**: Every field MUST be a `String`, including the timestamps, so the value carries no `Date` type.
- **immutable-fields**: `id`, `bundleId`, `appName`, `workingPath`, `repoRoot`, `branch`, `startedAt` and `tz` MUST be immutable (`let`) after construction.
- **mutable-fields**: `windowTitle`, `endedAt` and `lastSeenAt` MUST be mutable (`var`) after construction.
- **working-path-sentinel**: An empty `workingPath` MUST mean the path is unresolved.
- **repo-root-sentinel**: An empty `repoRoot` MUST mean the span has no repository.
- **started-at-format**: Callers MUST supply `startedAt` as an ISO-8601 UTC timestamp, as the source comment states; the type does not enforce it.
- **tz-format**: Callers SHOULD supply `tz` as a time zone identifier string such as `America/Los_Angeles`; the type does not validate it.
- **ended-at-sentinel**: An empty `endedAt` MUST mean the span is still open.
- **last-seen-sentinel**: An empty `lastSeenAt` MUST mean no heartbeat has been recorded yet.
- **is-open-derivation**: `isOpen` MUST be true exactly when `endedAt` is empty.
- **is-open-not-encoded**: `isOpen` MUST be a computed property and MUST NOT be a stored or encoded field.
- **codable-synthesis**: Encoding and decoding MUST use the compiler-synthesized `Codable` keyed by the property names (`id`, `bundleId`, `appName`, `windowTitle`, `workingPath`, `repoRoot`, `branch`, `startedAt`, `endedAt`, `tz`, `lastSeenAt`).
- **snake-case-by-strategy**: The type MUST declare no `CodingKeys`; snake_case on the wire MUST come from the caller's key strategy (`convertToSnakeCase` and `convertFromSnakeCase`), as the models test does. The wire key format therefore belongs to the caller; a caller that uses the default encoder gets the camelCase property names.
- **no-validation**: The type MUST NOT validate or normalize any field at construction or decode; every string is stored as given.
- **value-semantics**: Copies MUST be independent values; mutation of a copy MUST NOT affect the original.

## Appearance

Not applicable — this is a data transfer type, not a visual component.

## States

Not applicable — this is a data transfer type, not a visual component. The only runtime distinction, open versus closed, is `isOpen` under Behavioral Requirements.

## Accessibility

Not applicable — this is a data transfer type, not a visual component.

## Conformance Test Vectors

Derived from the type's source and from `testStatusRoundTripsSnakeCase` in `WorkTrackingModelsTests`, which round-trips a `WorkTrackingStatus` holding an `ActivitySpanDTO`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| activity-span-dto-001 | required-init-arguments, string-defaults | `ActivitySpanDTO(bundleId: "com.apple.dt.Xcode", appName: "Xcode", startedAt: "2026-10-01T09:00:00Z", tz: "UTC")` | `windowTitle`, `workingPath`, `repoRoot`, `branch`, `endedAt`, `lastSeenAt` are all `""` |
| activity-span-dto-002 | default-id | Two inits with no `id` argument | Each `id` is a valid UUID string and the two differ |
| activity-span-dto-003 | identity-field | Init with `id: "s"` | `id == "s"` |
| activity-span-dto-004 | is-open-derivation, ended-at-sentinel | Span with `endedAt: ""` | `isOpen == true` |
| activity-span-dto-005 | is-open-derivation | Span with `endedAt: "2026-10-01T10:00:00Z"` | `isOpen == false` |
| activity-span-dto-006 | mutable-fields, is-open-derivation | Open span, then set `endedAt = "2026-10-01T10:00:00Z"` | `isOpen` flips from true to false |
| activity-span-dto-007 | mutable-fields, immutable-fields | Set `windowTitle` and `lastSeenAt` on a span | Both read back the new values; `id` and `startedAt` are unchanged |
| activity-span-dto-008 | codable-synthesis, snake-case-by-strategy | Encode with `convertToSnakeCase`, decode with `convertFromSnakeCase` a `WorkTrackingStatus` whose `currentSpan` is a span with id `s` (test `testStatusRoundTripsSnakeCase`) | Decoded value equals the original |
| activity-span-dto-009 | is-open-not-encoded | Encode an open span to JSON | The JSON has no `isOpen` or `is_open` key |
| activity-span-dto-010 | no-validation | Init with `startedAt: "not a date"` and `tz: ""` | Construction succeeds and both strings are stored unchanged |
| activity-span-dto-011 | value-semantics | Copy a span, set `endedAt` on the copy | The original `isOpen` remains true |
| activity-span-dto-012 | conformances | Compare two spans built with identical arguments including `id` | They are equal; spans differing only in `lastSeenAt` are not equal |
| activity-span-dto-013 | working-path-sentinel, repo-root-sentinel, last-seen-sentinel | Span built with defaults | `workingPath`, `repoRoot` and `lastSeenAt` are `""`, meaning unresolved, no repo, no heartbeat |
| activity-span-dto-014 | all-strings | Encode a span with the default encoder and inspect every value in the JSON object | Every value is a JSON string |
## Edge Cases

- **Empty `endedAt` with a non-empty `lastSeenAt`**: The span MUST be open; a heartbeat does not close a span, because `isOpen` reads only `endedAt`.
- **Whitespace `endedAt`**: A value of a single space MUST count as closed, because `isOpen` tests `isEmpty` and does not trim.
- **Malformed timestamps**: A `startedAt`, `endedAt` or `lastSeenAt` that is not ISO-8601 MUST be stored and encoded unchanged; the type does not parse timestamps, so no error is raised.
- **Empty `bundleId`, `appName` or `tz`**: The initializer MUST accept them; callers own that precondition, since no validation exists.
- **Duplicate ids**: Two spans with the same `id` MUST be representable; uniqueness is not enforced in this type. The `ActivityPersistence` contract owns the rule: its doc comment says opening an id that already exists throws, and `InMemoryActivityStore` throws `duplicateSpanId`.
- **Missing keys on decode**: Decoding JSON that lacks any property MUST fail with the standard `DecodingError`, because synthesized `Codable` has no default for absent keys, including the ones the initializer defaults.
- **Ended before started**: `endedAt` earlier than `startedAt` MUST be accepted without error; ordering is not checked.
- **Concurrent access**: The type is a `Sendable` value type; each thread works on its own copy, so there is no shared mutable state and no ordering rule.
- **Error states, offline and cancellation**: Not applicable — the type performs no I/O, networking, or async work and raises no errors of its own.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | String | `UUID().uuidString` | Span identity |
| `bundleId` | String | required | Bundle identifier of the focused app |
| `appName` | String | required | Display name of the focused app |
| `windowTitle` | String | `""` | Mutable window title |
| `workingPath` | String | `""` | Resolved working path; empty is unresolved |
| `repoRoot` | String | `""` | Repository root; empty is no repo |
| `branch` | String | `""` | Branch name |
| `startedAt` | String | required | ISO-8601 UTC start |
| `endedAt` | String | `""` | ISO-8601 UTC end; empty is open |
| `tz` | String | required | Time zone identifier string |
| `lastSeenAt` | String | `""` | Last heartbeat; empty is none yet |

No environment variables or settings keys; the caller supplies every value.

## Deep Linking

Not applicable: the type is a passive data shape with no URL or navigation surface.

## Localization

Not applicable: the type holds no user-facing strings of its own; `appName` and `windowTitle` are captured values from the observed app.

## Accessibility Options

Not applicable: the type has no visual surface, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source declares no flag; whether tracking is enabled lives on `WorkTrackingStatus.enabled`, outside this type.

## Analytics

Not applicable: the type emits no events.

## Privacy

- **Data collected**: The fields `windowTitle`, `workingPath`, `repoRoot`, `branch` and `appName` describe what the user is working on, and `windowTitle` may include document or project names.
- **Storage**: The type does not store itself; the persistence layer (`ActivityPersistence`) and in-memory store own storage.
- **Transmission**: The type crosses the process boundary as part of `WorkTrackingStatus` through the work-tracking XPC protocol; it does no networking.
- **Retention**: Not set by this type; retention is configured outside it (`retentionDays` in `WorkTrackingModels`).

## Logging

Not applicable: the type contains no log calls.

## Platform Notes

- **SwiftUI**: Source platform. The file is `ActivitySpanDTO.swift` under `Core/WorkTracking`. A SwiftUI view reads `isOpen` and the string fields directly. Timestamps are strings, so views parse them with `ISO8601DateFormatter` before display.
- **Compose**: Use a Kotlin `data class` annotated `@Serializable` (kotlinx.serialization) with String properties defaulting to `""`, `val` for the immutable fields and `var` for the mutable ones, and `val isOpen get() = endedAt.isEmpty()` outside the serialized properties. Use `@SerialName` for snake_case if the wire needs it; unlike the source there is no global key strategy.
- **React/Web**: Use a TypeScript `interface` with string fields and a helper `isOpen(span)` that returns `span.endedAt === ""`. The wire key format belongs to the caller; if the wire is snake_case, map the keys at the boundary. Use `crypto.randomUUID()` for the default id and `readonly` for the immutable fields.
- **AppKit / UIKit**: Same Swift type, no differences; the DTO has no platform dependency beyond `Foundation`.
- **WinUI 3**: Use a C# `record` (`init` properties for the immutable fields, `{ get; set; }` for `WindowTitle`, `EndedAt` and `LastSeenAt`) with string defaults of `string.Empty` and `Id` defaulting to `Guid.NewGuid().ToString()`. Serialize with `System.Text.Json` and, when the wire is snake_case, `JsonNamingPolicy.SnakeCaseLower` (.NET 8) to match the caller's strategy. Default every string to `string.Empty`, never serialize `null`, and expose `IsOpen` as `EndedAt.Length == 0` marked `[JsonIgnore]`, so a `null` `EndedAt` is not a state the type has. Where a XAML view binds to a mutable span, wrap it in an `INotifyPropertyChanged` type, since records raise no change notifications. Missing JSON keys leave defaults rather than failing, unlike Swift's synthesized `Codable`, so add `[JsonRequired]` to match.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/ActivitySpanDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Timestamps are ISO-8601 strings, not `Date`.
**Rationale**: The source comments declare `startedAt` as "ISO-8601 UTC" and the type holds `String` throughout, which keeps the wire shape identical across processes and platforms and avoids date-strategy mismatches between encoder and decoder.
**Approved**: pending

**Decision**: Absence is encoded as the empty string, not as an optional.
**Rationale**: The comments `"" = unresolved`, `"" = no repo`, `"" = open` and `"" = no heartbeat yet` name each sentinel, so every field is always present on the wire and decoders never see `null`.
**Approved**: pending

**Decision**: Only `windowTitle`, `endedAt` and `lastSeenAt` are mutable.
**Rationale**: A span's identity, app, location and start are fixed when it opens, while the title, close time and heartbeat change as the span lives; the `let` and `var` split in the source encodes that.
**Approved**: pending

**Decision**: `isOpen` is derived from `endedAt` alone.
**Rationale**: One source of truth avoids a stored flag drifting from the end timestamp.
**Approved**: pending

**Decision**: No field validation in the type.
**Rationale**: The source has no checks; callers such as the recorder own correctness, which keeps the DTO a pure carrier.
**Approved**: pending

**Decision**: The type declares no `CodingKeys`, so the wire key format belongs to the caller's encoder and decoder strategy.
**Rationale**: The source relies on `convertToSnakeCase` and `convertFromSnakeCase`, as the models test does, which keeps the type free of key names; the cost is that a caller using the default strategy silently produces camelCase keys.
**Approved**: pending

**Decision**: Decoding is strict: a missing key fails, so adding a field to the type breaks decoding of data written before the field existed.
**Rationale**: Synthesized `Codable` has no default for an absent key, and the source adds no `decodeIfPresent` defaults. A change that adds a field has to decide how older stored or sent data is handled.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

The type is a pure data carrier with no I/O, so separation of concerns passes. Unit coverage passes: `ActivitySpanDTOConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/WorkTracking/ActivitySpanDTOConformanceTests.swift`) covers every vector, beside the snake_case round trip in `WorkTrackingModelsTests`. Data integrity is partial because the type accepts any string for every field and leaves timestamp format and ordering to callers.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ActivitySpanDTOConformanceTests.swift, 14 of 14 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Stated that the wire key format belongs to the caller, made the startedAt format a caller precondition, added a tz format requirement, strict-decode and key-format Design Decisions, an all-strings vector, a related link, and fixed the Overview wording and the WinUI and wire-format notes. |
