---
id: bc99bb92-f6b7-4767-8d29-f68ee9e5e2b4
title: "Session Activity"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Three-case enum for what a live Claude Code session is doing now, derived from process liveness, the last hook event and a subagent flag."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-hooks
  - state-derivation
depends-on: []
related:
  - 787b5da6-2f20-4f3e-8104-1763959a735f
references: []
approved-by: ""
approved-date: ""
---

# Session Activity

## Overview

`SessionActivity` says what a session is doing right now: `working`, `idle` or `waiting`. It is separate from `SessionStatus`, which only says whether a process exists. A session can be alive and idle, alive and working, or alive and blocked on the user.

The value is never stored. `SessionActivity.derive(isActive:lastEventType:subagentWorking:)` computes it from what the daemon recorded: whether the process is alive, the last hook event type of the main agent's turn, and the daemon's verdict that a subagent was busy just now. The daemon records what happened and not what it means, so the mapping can change, or learn a new event type, without a schema change.

The enum is the one reading shared by the Sessions window's activity icon and `steno conversation status`, so the two cannot disagree.

The inputs are `isActive` (whether the session's process is alive; `false` forces `idle`), `lastEventType` (the last hook event recorded for the main agent's turn) and `subagentWorking` (the daemon's verdict that a subagent was busy just now). None of them is configuration.

The `waiting` reading of `"Notification"` assumes the daemon records only a Notification that asks for an answer, not the idle reminder sent after every finished turn; recording is the daemon's job, outside this component.

## Behavioral Requirements

**Shape**

- **activity-cases**: `SessionActivity` MUST have exactly three cases: `working`, `idle` and `waiting`.
- **activity-raw-values**: Each case's `String` raw value MUST equal its case name: `"working"`, `"idle"`, `"waiting"`.
- **activity-case-iterable**: `SessionActivity` MUST conform to `CaseIterable`, listing the cases in the order `working`, `idle`, `waiting`.
- **activity-sendable**: `SessionActivity` MUST conform to `Sendable`.
- **activity-derived-not-stored**: The enum MUST expose no stored or cached activity; callers MUST call `derive` on each read from the recorded inputs.

**Turn activity**

- **turn-waiting-events**: `turnActivity(lastEventType:)` MUST return `waiting` for `"Notification"`, `"PermissionRequest"` and `"Elicitation"`, the events where the agent has handed control back and is waiting on the user.
- **turn-idle-events**: `turnActivity(lastEventType:)` MUST return `idle` for `"Stop"`, `"StopFailure"`, `"Interrupted"`, `"SessionStart"`, `"SessionEnd"` and the empty string. `StopFailure` is a turn ended by an API error; `Interrupted` is the daemon's own record of the user cutting a turn short, which fires no Claude Code hook.
- **turn-working-default**: `turnActivity(lastEventType:)` MUST return `working` for every other string, including `"UserPromptSubmit"`, `"PreToolUse"`, `"PostToolUse"` and `"PostToolUseFailure"`.
- **turn-exact-match**: `turnActivity(lastEventType:)` MUST compare the event type as an exact, case-sensitive string; it MUST NOT trim whitespace or fold case.
- **turn-ignores-liveness**: `turnActivity(lastEventType:)` MUST depend on `lastEventType` alone; it takes no liveness or subagent input.

**Derivation**

- **derive-inactive-idle**: `derive(isActive:lastEventType:subagentWorking:)` MUST return `idle` when `isActive` is `false`, whatever `lastEventType` and `subagentWorking` are.
- **derive-turn-passthrough**: When `isActive` is `true` and `turnActivity(lastEventType:)` returns `working` or `waiting`, `derive` MUST return that value.
- **derive-subagent-promotes-idle**: When `isActive` is `true`, the turn reads `idle` and `subagentWorking` is `true`, `derive` MUST return `working`.
- **derive-subagent-never-over-waiting**: When the turn reads `waiting`, `derive` MUST return `waiting` even if `subagentWorking` is `true`.
- **derive-idle-without-subagent**: When `isActive` is `true`, the turn reads `idle` and `subagentWorking` is `false`, `derive` MUST return `idle`.
- **derive-total**: `derive` and `turnActivity` MUST return a value for every input; neither throws nor returns an optional.
## Appearance

Not applicable — this is a state-derivation enum, not a visual component. The icon that shows it lives in the macOS SessionWatcher feature.

## States

Not applicable — this is a state-derivation enum, not a visual component. Its three cases are specified under Behavioral Requirements.

## Accessibility

Not applicable — this is a state-derivation enum, not a visual component.

## Conformance Test Vectors

Every vector is a direct call to the Core functions `SessionActivity.derive(isActive:lastEventType:subagentWorking:)` or `SessionActivity.turnActivity(lastEventType:)`; a port tests them at that level. In the vectors, "ended" means `isActive` is `false`. The Swift tests listed in the Input column live in the macOS test class `SessionWatcherSessionActivityTests`, which reaches `derive` through `SessionWatcherSession.activity`; no test sits beside the Core file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-activity-001 | turn-idle-events, derive-idle-without-subagent | Test `testFinishedTurnsReadAsIdle`: active session, `lastEventType` each of `Stop`, `StopFailure`, `Interrupted`, `SessionStart`, `SessionEnd`, `""`, no subagent | `idle` for each |
| session-activity-002 | turn-waiting-events, derive-turn-passthrough | Test `testRequestsForTheUserReadAsWaiting`: active, `lastEventType` each of `Notification`, `PermissionRequest`, `Elicitation` | `waiting` for each |
| session-activity-003 | turn-working-default, derive-turn-passthrough | Test `testTurnInFlightReadsAsWorking`: active, `lastEventType` each of `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure` | `working` for each |
| session-activity-004 | derive-inactive-idle | Test `testAnEndedSessionIsIdleWhateverItLastDid`: not active, `lastEventType` `PreToolUse` | `idle` |
| session-activity-005 | derive-subagent-promotes-idle | Test `testASessionWaitingOnASubagentReadsAsWorking`: active, `subagentWorking` true, `lastEventType` each of `Stop`, `StopFailure`, `Interrupted`, `SessionStart`, `SessionEnd`, `""` (the test covers all but `SessionEnd`; `derive-subagent-promotes-idle` covers every `idle` turn, so `SessionEnd` with a live subagent on an active session reads `working`) | `working` for each |
| session-activity-006 | derive-subagent-never-over-waiting | Test `testALiveSubagentNeverOverridesWaiting`: active, `subagentWorking` true, `lastEventType` each of `Notification`, `PermissionRequest`, `Elicitation` | `waiting` for each |
| session-activity-007 | derive-inactive-idle | Test `testAnEndedSessionIsIdleEvenWithASubagentStampLeftBehind`: not active, `subagentWorking` true, `lastEventType` `Stop` | `idle` |
| session-activity-008 | turn-working-default | `turnActivity(lastEventType: "SomeFutureEvent")` | `working` |
| session-activity-009 | turn-exact-match | `turnActivity(lastEventType:)` with each of `"stop"`, `"STOP"` and `" Stop"` | `working` for each, because none matches `"Stop"` exactly |
| session-activity-010 | derive-inactive-idle | `derive(isActive: false, lastEventType: "PermissionRequest", subagentWorking: false)` | `idle`, not `waiting` |
| session-activity-011 | activity-raw-values, activity-case-iterable | Read `SessionActivity.allCases` and each `rawValue` | `[working, idle, waiting]` with raw values `"working"`, `"idle"`, `"waiting"` |
| session-activity-012 | turn-ignores-liveness | `turnActivity(lastEventType: "SessionEnd")`; plus a static check that the function's signature has only the `lastEventType` parameter | `idle`; no liveness or subagent input exists to change it |
| session-activity-013 | derive-total | `derive` and `turnActivity` called with `lastEventType` `""`, `"Stop"`, `"Notification"`, `"SomeFutureEvent"` and each of `isActive`, `subagentWorking` true and false | a `SessionActivity` returns for every combination; nothing throws and nothing is optional |
| session-activity-014 | derive-turn-passthrough | `derive(isActive: true, lastEventType: "PreToolUse", subagentWorking: true)` | `working`; the subagent flag changes nothing when the turn already reads `working` |
## Edge Cases

- **Empty event type**: `lastEventType` of `""` MUST read `idle` (a session that has recorded no turn event), and with a live subagent `derive` MUST read `working`. Covered by session-activity-001 and session-activity-005.
- **Unknown event type**: A string the switch does not list, such as a hook event added later, MUST read `working`. This is the default branch, so a new event reads as mid-turn until the mapping is updated.
- **Case and whitespace**: `"stop"`, `"STOP"` and `" Stop"` MUST read `working`; the match is exact. Covered by session-activity-009.
- **Ended session with stale inputs**: A session whose process is gone MUST read `idle` even when `lastEventType` is mid-turn or `subagentWorking` is still stamped true. The liveness check runs first.
- **Subagent and waiting**: `subagentWorking` MUST NOT lower a `waiting` reading; a session blocked on a permission prompt still needs the user.
- **Subagent and working**: `subagentWorking` has no effect when the turn already reads `working`. Covered by session-activity-014.
- **Boundary values**: Not applicable: there are no numeric inputs; the only inputs are two booleans and a string.
- **Concurrent access**: Not applicable: both functions are static, pure and hold no state; the enum is `Sendable`.
- **Error states and offline**: Not applicable: nothing is read from disk or network and no function throws.
- **Cancellation and timeouts**: Not applicable: both functions are synchronous and return immediately.

## Configuration
Not applicable: `SessionActivity` has no options. `derive` and `turnActivity` take inputs, not configuration; the inputs are described in the Overview.
## Deep Linking

Not applicable: the enum is a pure value type with no URLs or routes.

## Localization

Not applicable: the component holds no user-facing strings; the raw values are identifiers, and any label for them is the caller's.

## Accessibility Options

Not applicable: the enum is not a visual component, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the source reads no flags; the mapping is fixed in `turnActivity`.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the component reads three values passed to it and stores, transmits and logs nothing.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

- **SwiftUI**: `SessionActivity.swift` in `Core/Sessions` is a Foundation-only `enum` with a `String` raw value, so a SwiftUI view reads it as an ordinary value. Map each case to a symbol or tint in the view, not in the enum.
- **Compose**: Port as a Kotlin `enum class SessionActivity` with an `isActive: Boolean` argument on a companion `derive` function, and a `when` over the event string with an `else` branch returning `working`. A composable maps the case to an icon or color.
- **React/Web**: Port as a TypeScript string-literal union `"working" | "idle" | "waiting"` and two pure functions. Use a `switch` with a `default` branch for `working`, and compare with `===` so the match stays case-sensitive.
- **AppKit / UIKit**: In the macOS sources `SessionWatcherSession.activity` calls `derive` with `isActive` set from `status == .active`, and `SessionWatcher.SessionWatcherActivity` is a typealias of `SessionActivity`. The macOS SessionWatcher feature calls `derive` from `SessionWatcherSession.activity` and draws an activity icon through `SessionWatcherActivityIconView`. In AppKit or UIKit keep the derivation in the model and give the view only the resolved case.
- **WinUI 3**: Use a C# `enum SessionActivity { Working, Idle, Waiting }` and a `static class` with `Derive(bool isActive, string lastEventType, bool subagentWorking)` and `TurnActivity(string lastEventType)`. Use a `switch` expression with a discard arm for `Working` and `StringComparison.Ordinal` semantics, which `==` on `string` already gives. Expose the value as a property on a view model that implements `INotifyPropertyChanged`, and bind an icon to it with an `x:Bind` function or a `IValueConverter`. Unlike the Swift source, a C# enum does not carry a `String` raw value, so serialize with `JsonStringEnumConverter` in `System.Text.Json` when the lowercase names must cross a boundary.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/SessionActivity.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/SessionWatcher/SessionWatcherSessionActivityTests.swift` | confirmed (1.0.2) |

## Design Decisions

**Decision**: The activity is derived on each read from recorded inputs and is not stored.
**Rationale**: The doc comment on `SessionActivity.derive` in `SessionActivity.swift` says the daemon records what happened, not what it means, so the meaning can be re-read or re-mapped for a new event type without a schema change.
**Approved**: pending

**Decision**: A live subagent promotes an `idle` turn to `working` but never overrides `waiting`.
**Rationale**: The same `derive` doc comment says a live subagent reads as working because it is, and a session blocked on a permission prompt still needs the user whatever its subagents are doing. The quieter reading must not bury the louder one, as the test `testALiveSubagentNeverOverridesWaiting` records.
**Approved**: pending

**Decision**: Any event type not listed, including events added later, reads as `working`; the empty string is listed and reads `idle`.
**Rationale**: The comment on the `default` branch of `turnActivity(lastEventType:)` in `SessionActivity.swift` says the agent is mid-turn for everything else, so an unmapped hook event shows as busy rather than silently idle. The cost is that a new turn-ending event reads `working` until it is added to the idle list.
**Approved**: pending

**Decision**: One enum serves both the Sessions window icon and `steno conversation status`.
**Rationale**: The doc comment on the `SessionActivity` enum in `SessionActivity.swift` states this is so the two can never disagree about what a session is doing.
**Approved**: pending

**Decision**: `SessionActivity` is kept separate from `SessionStatus`.
**Rationale**: Status answers "does a process exist"; activity answers what a live process is doing. Collapsing them would force a single enum to carry both questions.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

Separation of concerns passes: the file holds only the derivation, with no storage, transport or drawing, and the macOS icon view consumes the resolved case. Unit-test coverage passes: `SessionActivityConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Sessions/SessionActivityConformanceTests.swift`) calls `derive` and `turnActivity` directly, one test per vector 001-014, including the unknown, case-variant and padded event types. No hardcoded user-facing strings exist: the only literals are hook event names and raw values.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (SessionActivityConformanceTests.swift, 14 of 14 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Folded the Interrupted and StopFailure requirements into turn-idle-events, restated activity-derived-not-stored, cited source doc comments, moved the macOS wiring and notification-scope to Overview and Platform Notes, marked Configuration not applicable, added vectors for derive-total, subagent-with-working and SessionEnd, and emptied references. |
