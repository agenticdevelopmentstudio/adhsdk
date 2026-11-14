---
id: 090a0676-4c12-4a0d-ae5a-019cdcc3cb6d
title: "Billing App Spans"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Value types that carry one recorded app-activity span and one idle interval into billing derivation, plus the span's billing session id."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - activity
depends-on: []
related:
  - bc417768-9933-49b1-b0ba-4bf537167805
  - 01942f60-6711-43e7-a7b2-a8e7cb4c2cda
references: []
approved-by: ""
approved-date: ""
---

# Billing App Spans

## Overview

Two immutable value types that billing derivation reads from the host. `BillingAppSpanRow` is one recorded app-activity span reduced to what derivation needs; `BillingIdleInterval` is one recorded stretch with no user input. Per the source's doc comment, the host reads a span row from its own activity table and billing never writes it except to stamp the derivation watermark; the source says nothing about where an idle interval is read from. The types hold data only and carry one derived property, the billing session id under which the span's runs are stored.

## Behavioral Requirements

- **span-row-fields**: `BillingAppSpanRow` MUST carry exactly the fields `id`, `bundleId`, `appName`, `windowTitle`, `workingPath`, `repoRoot`, `branch`, `startedAt`, `endedAt` and `tz`, all strings.
- **span-row-immutable**: Every field of `BillingAppSpanRow` MUST be a constant set once by the memberwise initializer that takes all ten fields.
- **working-path-unresolved**: A `workingPath` of the empty string MUST mean the working path is unresolved.
- **repo-root-definition**: `repoRoot` MUST hold the main repo root, the parent of the git common directory, and the empty string MUST mean there is no repo.
- **started-at-format**: `startedAt` MUST be an ISO-8601 UTC timestamp.
- **ended-at-open**: An `endedAt` of the empty string MUST mean the span is still open.
- **span-session-id**: `BillingAppSpanRow.sessionId` MUST equal the result of `ActivitySpanSession.sessionId(spanId:)` applied to the row's `id`, which is the prefix `app:` followed by the span id.
- **session-id-marker**: The `sessionId` MUST be the one marker that tells an app segment from a Claude one, so `ActivitySpanSession.spanId(sessionId:)` applied to it MUST return the original `id`.
- **idle-interval-fields**: `BillingIdleInterval` MUST carry exactly the strings `idleFrom` and `idleUntil`, set by a two-argument initializer.
- **idle-from-meaning**: `idleFrom` MUST hold the last input before the gap.
- **idle-until-open**: An `idleUntil` of the empty string MUST mean the machine is still idle.
- **value-semantics**: Both types MUST be `Sendable` and `Equatable`, so they cross concurrency domains and compare by field value.
- **no-validation**: The initializers MUST store their arguments unchanged; neither type validates a timestamp, an identifier or the ordering of start and end. Parsing and interpretation belong to the derivation code that consumes the rows.

## Appearance

Not applicable — this is a pair of data types, not a visual component.

## States

Not applicable — this is a pair of data types, not a visual component.

## Accessibility

Not applicable — this is a pair of data types, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-app-spans-001 | span-session-id, session-id-marker | `BillingAppSpanRow` with `id` `X1`; test `testSpanRowSessionIdMatchesActivitySpanSession` | `sessionId` equals `ActivitySpanSession.sessionId(spanId: "X1")` and `ActivitySpanSession.spanId(sessionId:)` of it returns `X1` |
| billing-app-spans-002 | span-session-id | Row with `id` `S` | `sessionId` is `app:S` |
| billing-app-spans-003 | ended-at-open | Row with `endedAt` empty, derived at a time with recent input (`testOpenSpanActiveNowIsRunning`) | The span is treated as open and still running |
| billing-app-spans-004 | idle-until-open | `BillingIdleInterval(idleFrom: t, idleUntil: "")` consumed by derivation (`testOpenSpanWhileIdlePastCutoffEndsAtLastInput`) | With `idleFrom` `2026-10-01T09:20:00Z`, cutoff 900 s and now `2026-10-01T09:40:00Z`, the idle interval is treated as still idle and the open span ends at `idleFrom` (1200 s) |
| billing-app-spans-005 | value-semantics | Two `BillingAppSpanRow` values built from identical arguments | They compare equal; changing any one field makes them unequal |
| billing-app-spans-006 | no-validation | `BillingAppSpanRow` built with `startedAt` `not-a-date` | The initializer returns without error and `startedAt` reads back unchanged; derivation handles it (`testMalformedTimestampIsEmpty`) |
| billing-app-spans-007 | working-path-unresolved, repo-root-definition | Row with empty `workingPath` and empty `repoRoot` | Both fields read back as the empty string |

## Edge Cases

- Null and empty input: there are no optionals; every absent value is the empty string (`workingPath`, `repoRoot`, `endedAt`, `idleUntil`), and consumers MUST treat the empty string as the documented sentinel, not as a timestamp.
- Boundary values: nothing is clamped; an `endedAt` earlier than `startedAt`, or an `idleUntil` earlier than `idleFrom`, is stored as given.
- Malformed input: a timestamp that does not parse is stored unchanged; derivation yields no runs for it (`testMalformedTimestampIsEmpty`).
- Concurrent access: the types are `Sendable` immutable values, so concurrent reads are safe and there is nothing to serialise.
- Error states: the types raise no error and perform no I/O.
- Offline or disconnected state: not applicable; the types touch no network.
- An `id` that already begins with `app:` yields a `sessionId` with the prefix doubled, because the prefix is added unconditionally.

## Configuration

None: the types take no configuration beyond the values passed to their initializers. The only constant they depend on is `ActivitySpanSession.prefix`, which is `app:`.

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing strings.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: the types only carry values the host already recorded; they collect, store and transmit nothing of their own, although `windowTitle`, `workingPath` and `repoRoot` pass through them.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; the types have no view layer.
- **Compose**: Kotlin `data class` with `val` string properties, which gives structural equality and immutability; the session id is a computed property.
- **React/Web**: Readonly TypeScript interfaces or frozen object literals with string fields; a plain function returns the `app:` prefix plus the span id, since object equality is by reference and a comparison helper is needed.
- **AppKit / UIKit**: `BillingAppSpanRow` and `BillingIdleInterval` in `Core/Billing/BillingAppSpans.swift`, public structs conforming to `Sendable` and `Equatable`, with explicit public memberwise initializers (a public struct gets no public memberwise initializer for free) and a `swiftlint` identifier_name suppression on `tz` and `startedAt`; `ActivitySpanSession` lives in `Core/WorkTracking/WorkTrackingModels.swift`.
- **WinUI 3**: C# `record` or `readonly record struct` types with `init`-only string properties, which give value equality and immutability; a `SessionId` property returns `"app:" + Id`. Use `string.Empty` for the sentinels and parse timestamps with `DateTimeOffset.TryParse` in the consuming code, not in the type. Records are safe to share across `Task` boundaries.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Billing/BillingAppSpans.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Timestamps and absent values are plain strings, with the empty string as the sentinel for unresolved, no repo, open and still idle.
**Rationale**: The source documents each sentinel in a doc comment (`"" = unresolved`, `"" = open`, `"" = still idle`) and types every field as a `String`, instead of using optionals.
**Approved**: pending

**Decision**: The initializers do no validation.
**Rationale**: The types are a read-only projection; parsing and malformed-input handling live in derivation, which keeps these types free of date logic.
**Approved**: pending

**Decision**: The session id is derived from the span id through `ActivitySpanSession`, not stored.
**Rationale**: One function owns the `app:` prefix so a span and its billing session cannot disagree, and the prefix is the marker that separates app segments from Claude segments.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: the file holds only data shapes and delegates the session id format to `ActivitySpanSession`. unit-test-coverage is partial: `BillingAppRunsTests` asserts the session id (`testSpanRowSessionIdMatchesActivitySpanSession`) and exercises both types through derivation, but no test targets the initializers or equality directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
