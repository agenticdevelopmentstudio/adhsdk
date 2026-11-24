---
id: dc4d1700-f641-4276-8ecd-ec6790a2c894
title: "Oversight Action DTOs"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The action target a client needs to act on an oversight finding now, and the result of marking the finding acted, with the safe-breakpoint rule in one place."
platforms:
  - swift
  - macos
tags:
  - stenographer
  - foundation
  - dto
  - wire
depends-on: []
related:
  - 7d2280c6-ae67-4ecc-9aae-dbee574b1eab
  - 96f73261-cf32-42cc-92f3-f8b58542382a
  - 9c7c78d3-23ca-4ca6-a519-9968b440b8c6
  - e8286557-84ee-4f45-b78c-f1d184c51a37
references: []
approved-by: ""
approved-date: ""
---

# Oversight Action DTOs

## Overview

Two shapes let a client act on an oversight finding. `OversightActionTargetDTO` says whether the finding's session is at a safe breakpoint and, when it is, which terminal target to inject text into. `OversightActResultDTO` is the outcome of `POST /oversight/findings/:id/act` (and its XPC equivalent): whether the finding was marked `acted`. The daemon computes the target because it is the single source of truth for session state. The terminal capability (can iTerm2 or Terminal.app be scripted for this pane) is decided in the app, which holds the Automation grant, so a client combines `actionable` with its own injector's terminal support before enabling the control. Phase-4 autonomous action gates on the same `actionable` check, so the safety rule lives in one place. The route, the lookup and the status change are the daemon's, outside these sources.

## Behavioral Requirements

- **target-fields**: An `OversightActionTargetDTO` MUST carry `findingId` (Int), `actionable` (Bool), `reason`, `sessionId`, `termProgram`, `termSessionId` and `injectText` (String), and `pid` (Int).
- **target-actionable**: `actionable` MUST be true only when the session is live and at a safe breakpoint, meaning the last event was `Stop`: Claude finished a response and is waiting for the user.
- **target-do-not-act**: A consumer MUST NOT act on a target whose `actionable` is false, and MUST read `reason`.
- **target-reason**: `reason` MUST explain why the target is not actionable, and MUST be an empty string when `actionable` is true.
- **target-terminal-and**: A client MUST combine `actionable` with its own injector's terminal support before enabling the control, because the daemon does not decide terminal capability.
- **target-single-rule**: Autonomous action MUST gate on the same `actionable` value, so the safety rule is not duplicated.
- **target-term-program**: `termProgram` MUST be the terminal app (for example `iTerm.app` or `Apple_Terminal`), from which the client picks the injection strategy.
- **target-term-session-id**: `termSessionId` MUST be the pane identifier (`TERM_SESSION_ID`) for exact iTerm2 targeting, and MAY be empty.
- **target-pid**: `pid` MUST be the session's `claude` PID, from which the client can resolve the pane's TTY.
- **target-inject-text**: `injectText` MUST be the text to inject, for example `/compact`.
- **target-blocked**: `OversightActionTargetDTO.blocked(findingId:reason:)` MUST return a target with the given `findingId` and `reason`, `actionable` false, empty `sessionId`, `termProgram`, `termSessionId` and `injectText`, and `pid` 0.
- **target-blocked-use**: The `blocked` target MUST be used when the finding is missing, resolved, or its session is not at a safe breakpoint.
- **target-memberwise-init**: `OversightActionTargetDTO.init` MUST take every field with no default.
- **result-fields**: An `OversightActResultDTO` MUST carry `findingId` (Int), `succeeded` (Bool), `status` (String) and `reason` (String).
- **result-succeeded**: `succeeded` MUST be true only when the finding transitioned to `acted`. The HTTP client instead sets it true for any 2xx reply, and reports `status` `acted` when it cannot decode the reply body.
- **result-status**: On the XPC and daemon path, `status` MUST be the finding's status after the call: `acted` on success, the current status when it was already resolved, and empty when the finding was not found. Two exceptions send an empty `status` for a finding that exists: the daemon's `.failed` outcome, and every failure reply the HTTP client builds (it uses the route's `error` text as `reason`).
- **result-reason**: `reason` MUST be a human-readable explanation when `succeeded` is false, and MUST be an empty string on success.
- **result-after-injection**: The app MUST call the act route only after a successful injection, so a failure is a rare race: the finding was already resolved or vanished.
- **conformance-protocols**: `OversightActionTargetDTO` and `OversightActResultDTO` MUST be `Codable`, `Sendable` and `Equatable`.
- **no-validation**: The initializers MUST NOT validate: `actionable` true with a non-empty `reason`, or `succeeded` false with an empty `reason`, constructs without error.

## Appearance

Not applicable — this is a pair of data shapes, not a visual component.

## States

Not applicable — this is a pair of data shapes, not a visual component.

## Accessibility

Not applicable — this is a pair of data shapes, not a visual component.

## Conformance Test Vectors

No test beside the source exercises these shapes; the vectors are derived from the declarations and doc comments.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| oversight-action-dt-os-001 | target-blocked | `OversightActionTargetDTO.blocked(findingId: 7, reason: "session is mid-response")` | `findingId` 7, `actionable` false, `reason` as given, `sessionId`, `termProgram`, `termSessionId`, `injectText` all empty, `pid` 0 |
| oversight-action-dt-os-002 | target-fields, target-actionable, target-reason | `OversightActionTargetDTO(findingId: 7, actionable: true, reason: "", sessionId: "s1", termProgram: "iTerm.app", termSessionId: "w0t0p0:ABC", pid: 42, injectText: "/compact")` | each field reads back; `reason` is empty |
| oversight-action-dt-os-003 | target-term-session-id | the same with `termSessionId: ""` | constructs; `termSessionId` is empty |
| oversight-action-dt-os-004 | target-do-not-act | any target with `actionable` false | a consumer does not inject and shows `reason` |
| oversight-action-dt-os-005 | target-terminal-and | `actionable` true and a client whose injector does not support `Apple_Terminal`, with `termProgram` `Apple_Terminal` | the control stays disabled |
| oversight-action-dt-os-006 | result-succeeded, result-status | `OversightActResultDTO(findingId: 7, succeeded: true, status: "acted", reason: "")` | each field reads back |
| oversight-action-dt-os-007 | result-status, result-reason | `OversightActResultDTO(findingId: 7, succeeded: false, status: "resolved", reason: "already resolved")` | `status` is the current status; `reason` is non-empty |
| oversight-action-dt-os-008 | result-status | `OversightActResultDTO(findingId: 9, succeeded: false, status: "", reason: "not found")` | `status` is empty |
| oversight-action-dt-os-012 | result-status | `OversightActionService.result(for: .failed("boom"), findingId: 7)` | `succeeded` false, `status` empty, `reason` `boom` |
| oversight-action-dt-os-013 | result-status | `StenographerHTTPClient.actOnOversightFinding` against a non-2xx reply | `succeeded` false, `status` empty, `reason` the route's `error` text or `HTTP <code>` |
| oversight-action-dt-os-009 | conformance-protocols | two targets built from identical arguments | they compare equal |
| oversight-action-dt-os-010 | conformance-protocols | encode then decode a target and a result | the decoded values equal the originals |
| oversight-action-dt-os-011 | no-validation | `OversightActionTargetDTO(findingId: 1, actionable: true, reason: "x", ...)` | constructs without error |

## Edge Cases

- **Missing finding**: the daemon answers with a `blocked` target; its `sessionId` is empty and `pid` is 0, so a client MUST NOT try to resolve a pane from it.
- **Resolved finding**: the `blocked` target carries a reason, and an act call returns `succeeded` false. The DTO's documented `status` is the current status, but the HTTP client builds a failed result with an empty `status` and the route's `error` text as `reason`.
- **Session mid-response**: the last event is not `Stop`, so `actionable` is false and `reason` says why.
- **Empty `termSessionId`**: allowed; the client falls back to another way to find the pane, such as resolving the TTY from `pid`.
- **Race at act time**: between injection and the act call the finding may be resolved or removed; the result reports it in `succeeded`, `status` and `reason`.
- **Concurrent access**: both types are immutable `Sendable` values; whether two clients can race to act on one finding is decided by the daemon's status transition, outside these sources.
- **Error and offline states**: no I/O here; an unreachable daemon is the caller's failure, and the shapes carry only a refusal, never a transport error.
- **Boundary values**: `findingId` and `pid` are unbounded `Int`s here; `pid` 0 is the placeholder of a `blocked` target.

## Configuration

Not applicable: `injectText` and `termProgram` are wire fields the daemon fills in per finding; nothing configures them.
## Deep Linking

Not applicable: the shapes define no URL or deep link; the act route is named only in a doc comment and is the daemon's.

## Localization

Not applicable: `reason` strings are produced by the daemon, and no user-facing string is defined in this code.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: the finding id, session id, terminal program and pane id, the claude pid and the text to inject.
- **Storage**: none here; the daemon owns the finding and session records.
- **Transmission**: values cross XPC or HTTP between the daemon and the app on the local machine; this code opens no connection.
- **Retention**: none defined by this code.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used (AppKit only).
- **Compose**: Kotlin data classes with `kotlinx.serialization`; the `blocked` factory is a companion function; the control's enabled state is `target.actionable && injector.supports(target.termProgram)`.
- **React/Web**: TypeScript interfaces; the act call is a `POST` through `fetch`; a browser cannot inject into a terminal, so a web client only displays `reason` and the target.
- **AppKit / UIKit**: A finding row binds its action button's `isEnabled` to `actionable` and the injector's terminal support, with `reason` as the tooltip. The structs are `Codable`, `Sendable`, `Equatable` with a static factory; the injection itself uses the app's Automation grant, which is app-side and not in this file.
- **WinUI 3**: Use C# records with `System.Text.Json` and a static `Blocked(int findingId, string reason)` factory on the target record; a `Button` with `IsEnabled` bound through `x:Bind` to `Actionable` and a terminal-support check; `HttpClient.PostAsync` calls the act route after injection succeeds; the injection itself has no direct Windows equivalent of Apple's Automation, so a port needs a console or terminal input API (for example `SendInput` against a Windows Terminal window, or `WriteConsoleInput`) decided separately.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/OversightActionDTOs.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The daemon computes `actionable`, and the client adds terminal support.
**Rationale**: The source states the daemon is the single source of truth for session state, while only the app holds the Automation grant that decides terminal capability.
**Approved**: pending

**Decision**: Safe breakpoint means the last event was `Stop`.
**Rationale**: The source states Claude has then finished a response and waits for the user; acting mid-response is unsafe.
**Approved**: pending

**Decision**: The same `actionable` check gates phase-4 autonomous action.
**Rationale**: The source states this keeps the safety rule in exactly one place.
**Approved**: pending

**Decision**: The shapes are flat Strings and Bools, not enums or a blocked/actionable sum type.
**Rationale**: The source types `status` and `termProgram` as Strings and lets `actionable` and `reason` be set independently, so the wire shape stays simple and a new value decodes without a shape change, at the cost of no compile-time check.
**Approved**: pending

**Decision**: The shape does not constrain `injectText`.
**Rationale**: The source carries the daemon's text as a plain String, so whether to allow-list it (for example to known slash commands) before typing it into a terminal is the consuming app's decision.
**Approved**: pending

**Decision**: The app calls the act route only after a successful injection.
**Rationale**: The source states this makes a failure there a rare race, so the result carries a reason and the current status and not a retry protocol.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | user-safety |

separation-of-concerns passes: the file holds two shapes and a factory; session state is the daemon's and terminal injection is the app's. unit-test-coverage is partial: `OversightActionDTOsConformanceTests` covers vectors 001 to 003 and 006 to 011, vector 012 is `testV012_resultForFailedHasEmptyStatusAndTheMessage` in `OversightActionServiceTests`, and vector 013 is `testV013_actOnFindingNon2xxHasEmptyStatusAndRouteErrorOrHTTPCode` in `StenographerHTTPClientTests`. Vectors 004 and 005 are skipped because the consumer that gates injection on `actionable` and on the injector's terminal support is app code that these DTOs do not contain. safe-defaults passes: the `blocked` target is non-actionable with empty fields, so the absence of data never reads as permission to act.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (OversightActionDTOsConformanceTests.swift, plus V012 in OversightActionServiceTests.swift and V013 in StenographerHTTPClientTests.swift, 11 of 13 vectors); unit-test-coverage now partial (004 and 005 skipped: consumer gating is app code). |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Narrowed result-status to the XPC path with the HTTP and failed exceptions and two new vectors, tightened result-succeeded, recorded flat-shape and injectText decisions, set Configuration to not applicable, fixed the platform notes, and added related links. |
