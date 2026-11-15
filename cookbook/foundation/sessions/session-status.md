---
id: 787b5da6-2f20-4f3e-8104-1763959a735f
title: "Session Status"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Three-case lifecycle enum for a Claude Code session: active, stale or ended, whose raw strings are the stored and published status values."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-hooks
  - lifecycle
depends-on: []
related:
  - bc99bb92-f6b7-4767-8d29-f68ee9e5e2b4
  - 6a37e531-b5ae-4eea-b4f0-d28866776ddc
references: []
approved-by: ""
approved-date: ""
---

# Session Status

## Overview

`SessionStatus` is the lifecycle state of a Claude Code session: `active`, `stale` or `ended`. It answers only whether a process exists for the session. What a live session is doing is a separate question, answered by `SessionActivity` (Session Activity ([adhsdk.ingredient.foundation.sessions.session-activity](cookbook:bc99bb92-f6b7-4767-8d29-f68ee9e5e2b4))).

The enum is a `String`-backed value. The raw strings are what the SDK writes to the sessions table's status column, compares against rows read back, and publishes in the `{session_id, status}` payload that `SessionEventEncoding.encodeSessionStatus(sessionId:status:)` builds (Session Event Sink ([adhsdk.ingredient.foundation.sessions.session-event-sink](cookbook:6a37e531-b5ae-4eea-b4f0-d28866776ddc))). A port has to keep those three strings exactly.

What each case means, as the SDK's daemon uses them. This is description, not requirement; the transitions belong to `LivenessService` and the session-records code. `active` means a live process exists for the session; the liveness service sets it when a live `claude` process maps to the session's id. `ended` means no live process remains; the liveness service sets it when the process is gone and the recorded `cwd` is not empty, and it does not end a session whose `cwd` is empty, because ending it would be a guess. `stale` is declared but nothing in the SDK's own daemon code writes it: the status column's `CHECK(status IN ('active','stale','ended'))` allows it, and `fetchActiveSessionsForLiveness` selects rows whose status is `active` or `stale`. The enum does not conform to `CaseIterable`, and it has no fallback case for an unknown raw string.
## Behavioral Requirements

**Shape**

- **status-cases**: `SessionStatus` MUST have exactly three cases: `active`, `stale` and `ended`.
- **status-raw-values**: Each case's `String` raw value MUST equal its case name: `"active"`, `"stale"`, `"ended"`.
- **status-sendable**: `SessionStatus` MUST conform to `Sendable`.
- **status-raw-init-optional**: Initializing from a raw string that is not one of the three values MUST yield no value (the failable `init(rawValue:)` returns `nil`).

**Meaning of each case**

- **stale-declared**: A consumer MUST accept `stale` as a valid status when it reads one, because the sessions table's status column allows it.
- **status-vs-activity**: A consumer that needs to know what a live session is doing MUST use `SessionActivity` (Session Activity ([adhsdk.ingredient.foundation.sessions.session-activity](cookbook:bc99bb92-f6b7-4767-8d29-f68ee9e5e2b4))) and not infer it from `SessionStatus`.

**Use as a stored and published value**

- **status-stored-as-raw**: Code that writes or compares the status column MUST use the `rawValue` string, as `updateSessionStatus(_:sessionId:)` and the liveness comparison `status == SessionStatus.active.rawValue` do.
- **status-update-failure**: `updateSessionStatus(_:sessionId:)` MUST NOT throw; it MUST write the raw value with a single-row UPDATE keyed by session id, and on a write failure it MUST log the error through the logger and return.
- **status-published-as-raw**: A session-status broadcast MUST carry the raw string in the payload's `status` field (see Session Event Sink ([adhsdk.ingredient.foundation.sessions.session-event-sink](cookbook:6a37e531-b5ae-4eea-b4f0-d28866776ddc))).

## Appearance

Not applicable — this is a lifecycle enum, not a visual component.

## States

Not applicable — this is a lifecycle enum, not a visual component. Its three cases are specified under Behavioral Requirements.

## Accessibility

Not applicable — this is a lifecycle enum, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-status-001 | status-raw-values | `SessionStatus.active.rawValue`, `SessionStatus.stale.rawValue`, `SessionStatus.ended.rawValue` | `"active"`, `"stale"`, `"ended"` |
| session-status-002 | status-raw-values, status-raw-init-optional | `SessionStatus(rawValue: "ended")` | `.ended` |
| session-status-003 | status-raw-init-optional | `SessionStatus(rawValue: "Active")` | `nil`; the match is case-sensitive |
| session-status-004 | status-raw-init-optional | `SessionStatus(rawValue: "")` | `nil` |
| session-status-005 | status-raw-init-optional | `SessionStatus(rawValue: "closed")` | `nil` |
| session-status-006 | status-raw-values, status-stored-as-raw | `SessionStatus(rawValue: "active")` and `SessionStatus.active.rawValue == "active"` | `.active`; the stored string and the enum agree |
| session-status-007 | status-cases | `SessionStatus(rawValue:)` for each of `"active"`, `"stale"`, `"ended"` | `.active`, `.stale`, `.ended`; no other raw string yields a value |
| session-status-008 | status-vs-activity | Inspect the enum's API surface | `SessionStatus` offers no operation that returns a `SessionActivity`; activity comes only from `SessionActivity.derive` (Session Activity ([adhsdk.ingredient.foundation.sessions.session-activity](cookbook:bc99bb92-f6b7-4767-8d29-f68ee9e5e2b4))) |
| session-status-009 | stale-declared, status-raw-init-optional | Decode a stored value `"stale"` with `SessionStatus(rawValue:)` | `.stale` |
| session-status-010 | status-published-as-raw | `SessionEventEncoding.encodeSessionStatus(sessionId: "s1", status: .stale)` | JSON whose `status` is `"stale"` |
| session-status-011 | status-sendable | Pass a `SessionStatus` value across a task boundary | Compiles without a `Sendable` diagnostic |
## Edge Cases

- **Unknown string**: A string outside the three raw values MUST fail to convert, yielding `nil` from `init(rawValue:)`. The sessions table's `CHECK` constraint keeps the column to the three values, so the case arises from external input such as the `status` query parameter of the session list route, where an unrecognized value becomes `nil` and the list is returned unfiltered. The enum has no fallback case, so the caller owns the handling.
- **Empty string**: `SessionStatus(rawValue: "")` MUST yield `nil`.
- **Case variants**: `"Active"` and `"ENDED"` MUST yield `nil`; the raw values are lowercase and the match is exact.
- **Stale in the SDK's own writes**: No SDK daemon code sets `stale`, so a port MAY omit a transition into it, but MUST keep the case so rows and payloads from other writers still convert (`stale-declared`).
- **Concurrent access**: Not applicable: the enum is an immutable `Sendable` value with no state of its own; ordering of writes to the status column belongs to the database layer.
- **Boundary values, errors, offline**: Not applicable: the enum has no numeric inputs, throws nothing and does no I/O.

## Configuration
Not applicable: the enum has no parameters, defaults, environment variables or injected dependencies; the only input is a raw string through `init(rawValue:)`.
## Deep Linking

Not applicable: the enum is a plain value with no URLs or routes.

## Localization

Not applicable: the raw values are machine identifiers, not user-facing text; the source holds no display strings.

## Accessibility Options

Not applicable: the enum is not a visual component, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the enum carries one of three fixed words and holds no personal data or credentials.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes
The `platforms` of this recipe are swift and macos; the notes for the other targets are porting guidance only.


- **SwiftUI**: `SessionStatus.swift` in `Core/Sessions` is a Foundation-only `enum` with a `String` raw value. A SwiftUI view should show a label chosen by the view layer and not the raw value.
- **Compose**: Port as a Kotlin `enum class SessionStatus(val raw: String)` with a `fromRaw(String): SessionStatus?` function that returns `null` for an unknown string, matching the failable initializer.
- **React/Web**: Port as a TypeScript string-literal union `"active" | "stale" | "ended"` plus a function `parseSessionStatus(s: string): SessionStatus | undefined` that returns the matching literal and `undefined` for anything else.
- **AppKit / UIKit**: The same Foundation enum is used unchanged; a table or list cell maps the case to an icon or text. Store and compare the raw string, as the daemon code does.
- **WinUI 3**: Use a C# `enum SessionStatus { Active, Stale, Ended }`. C# enums carry no string raw value, so serialize with `JsonStringEnumConverter` using a camel-case naming policy in `System.Text.Json` to get the lowercase wire strings, and map the three wire strings explicitly (a `switch` on `"active"`, `"stale"` and `"ended"`, or `[JsonStringEnumMemberName]` in .NET 9 and later), returning no value for anything else. Do not use `Enum.TryParse(..., ignoreCase: false)` on the lowercase wire strings: the members are `Active`, `Stale` and `Ended`, so it rejects every stored value. If you do parse with `Enum.TryParse`, keep the `Enum.IsDefined` guard, since `Enum.TryParse` accepts numeric strings. For a SQLite column use `Microsoft.Data.Sqlite` and convert at the boundary. Expose the value on a view model through `INotifyPropertyChanged` and bind a glyph or text to it with an `x:Bind` function.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/SessionStatus.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKDatabaseTests/Daemon/Sessions/LivenessServiceTests.swift` | confirmed (1.0.3) |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

Separation of concerns passes: the file is three cases and nothing else, with transitions owned by `LivenessService` and persistence by the session records code. Unit-test coverage is partial: `SessionStatusConformanceTests` covers every vector except 008, which is skipped because an absent API cannot be asserted at runtime. No user-facing strings exist; the literals are identifiers.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (SessionStatusConformanceTests.swift, 10 of 11 vectors); unit-test-coverage now partial (008 skipped: an absent API cannot be asserted at runtime). |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Restore requirements lost in the lint pass: status-update-failure |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Dropped status-not-case-iterable and status-update-failure, cut stale-declared to a consumer MUST and moved the case descriptions to Overview, replaced the liveness vectors with enum-level ones, fixed the WinUI parsing note and the web guard signature, linked related specs and emptied references. |
