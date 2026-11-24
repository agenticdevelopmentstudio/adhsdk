---
id: 1c2b7ff7-4d12-4580-94b0-17258d3384e1
title: "Hook Event Type"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Enum of 27 Claude Code hook events plus the synthetic StatusLine, with rules for activity, turn state and subagent activity."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-hooks
  - hook-events
depends-on: []
related:
  - fc622208-1504-421f-8892-c5869820550c
  - 9eb46f78-0ceb-455f-9584-b6b43ddf0871
references: []
approved-by: ""
approved-date: ""
---

# Hook Event Type

## Overview

`HookEventType` is a `String`-backed, `CaseIterable`, `Sendable` enum of the Claude Code hook events a session daemon captures: 27 events Claude Code emits plus `StatusLine`, which only the status-line dispatcher produces. `ClaudeHookInstaller` ([adhsdk.ingredient.foundation.claude-hooks.claude-hook-installer](cookbook:fc622208-1504-421f-8892-c5869820550c)) and `ClaudeHookConfiguration` ([adhsdk.ingredient.foundation.sessions.claude-hook-configuration](cookbook:9eb46f78-0ceb-455f-9584-b6b43ddf0871)) derive hook registration from the case list. Each raw value is the event name exactly as it appears in a hook envelope.

The enum also holds the classification rules the ingest path applies to a raw event type string and its `hook_data`: whether the event is evidence the session did something (`isActivity`), whether it may decide the session's working, idle or waiting state (`setsTurnState`), what it says about subagents (`subagentClock`), and the SQLite table name for its detail rows (`tableName`). The rules take the raw string, not a case, so an event type this build does not model still gets an answer. The ingest store reads `isActivity` to keep an ambient event from moving a session row that already exists; that behavior belongs to the store, not to this enum.

Test coverage is partial: `HookEventTypeTests` asserts `tableName`, `isActivity` and the case count, and `EventIngestStoreTests` covers an ambient event end to end, but no test calls `setsTurnState` or `subagentClock` directly or pins the sets' members. The registration claim in the type's doc comment is the open question on **registration-list**.

## Behavioral Requirements

### Inputs

- **classification-inputs**: Every classification function MUST take the event name as a raw `String`, and `setsTurnState` and `subagentClock` MUST also take the event's payload as `hookData: [String: Any]`, of which only `notification_type`, `source` and `agent_id` are read. The sets (`ambientEventTypes`, `offTurnEventTypes`, `waitingNotificationTypes`, `turnEndingEventTypes`) and `interruptedEventType` MUST be fixed constants that a caller cannot inject.

### Cases

- **case-list**: The enum MUST have exactly these 28 cases, each with a raw value equal to its name in UpperCamelCase: `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`, `Stop`, `StopFailure`, `SubagentStart`, `SubagentStop`, `Notification`, `PreCompact`, `PostCompact`, `Setup`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `Elicitation`, `ElicitationResult`, `ConfigChange`, `InstructionsLoaded`, `WorktreeCreate`, `WorktreeRemove`, `CwdChanged`, `FileChanged` and `StatusLine`.
- **case-count-pinned**: `allCases.count` MUST be 28, so adding or removing a case is a visible change (test `caseCountIsPinned`).
- **status-line-synthetic**: `StatusLine` MUST be treated as synthetic: Claude Code does not emit it; the status-line dispatcher forwards each render's stdin payload to `steno hook --event StatusLine`.
- **registration-list**: NEEDS REVIEW: Not implemented in source. The doc comment says the installer "registers exactly this list", but `ClaudeHookConfiguration.defaultHookedEvents` and `ClaudeHookInstaller.hookedEventTypes` filter out `ClaudeHookInstaller.excludedEventTypes` (`WorktreeCreate` and `WorktreeRemove`, which Claude Code treats as delegations, and the synthetic `StatusLine`), so 25 of the 28 cases are registered; the comment or the registration needs to change, and the owner of the installer settles which.

### Activity

- **ambient-event-types**: `ambientEventTypes` MUST be exactly the raw values `ConfigChange`, `StatusLine` and `InstructionsLoaded`: events that fire for reasons unrelated to the session (settings edits fan out to every live session, status-line renders arrive many times per second, instruction-file changes fan out to idle sessions).
- **is-activity-false-for-ambient**: `isActivity(_:)` MUST return false for each raw value in `ambientEventTypes`.
- **is-activity-true-otherwise**: `isActivity(_:)` MUST return true for every other string, including a type this build does not model and the empty string, because a hook not yet modelled is more likely real work than ambient noise.
- **is-activity-exact-match**: `isActivity(_:)` MUST compare the raw string exactly, so `configchange` in another case is activity.

### Turn state

- **off-turn-event-types**: `offTurnEventTypes` MUST be exactly the raw values `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`, `PreCompact`, `PostCompact` and `FileChanged`: events that report on something other than the main agent's turn.
- **waiting-notification-types**: `waitingNotificationTypes` MUST be exactly `permission_prompt` and `elicitation_dialog`, the `Notification` types that mean the agent is blocked on the user; the rest, above all `idle_prompt` (sent a minute after every finished turn), are informational.
- **turn-ending-event-types**: `turnEndingEventTypes` MUST be exactly `Stop`, `StopFailure` and `SessionEnd`: events after which nothing runs until the user speaks.
- **interrupted-event-type**: `interruptedEventType` MUST be the string `Interrupted`, a synthetic `last_event_type` for a user interrupt (Claude Code fires no hook for one); it is not a case of the enum and is not in any of the sets above.
- **sets-turn-state-ambient-or-off-turn**: `setsTurnState(_:hookData:)` MUST return false when `isActivity` is false or the type is in `offTurnEventTypes`, before any other rule.
- **sets-turn-state-blocking-requests**: `setsTurnState` MUST return true for `PermissionRequest` and `Elicitation` whatever `hook_data` holds, even when it carries an `agent_id`, because a session waiting on the user is waiting either way.
- **sets-turn-state-notification**: For `Notification`, `setsTurnState` MUST return true when `hook_data["notification_type"]` is missing, not a string or empty, and otherwise true only when the value is in `waitingNotificationTypes`.
- **sets-turn-state-session-start**: For `SessionStart`, `setsTurnState` MUST return false only when `hook_data["source"]` is the string `compact`; a missing or non-string `source` returns true.
- **sets-turn-state-default**: For every other type, including an unknown one, `setsTurnState` MUST return true only when `hook_data["agent_id"]` is missing, not a string or empty, so a subagent's hook never sets the main turn's state.

### Subagent clock

- **subagent-clock-signals**: `subagentClock` returns one of three signals, which ports SHOULD name rather than carry as bare integers, for example a small enum with cases `stamp` (1), `clear` (-1) and `none` (0); the Swift source returns `Int`.
- **subagent-clock-stop**: `subagentClock(_:hookData:)` MUST return -1 for `SubagentStop`, whether or not `hook_data` has an `agent_id`; a stop is terminal, one per subagent, so it clears the stamp rather than ageing out.
- **subagent-clock-no-agent**: `subagentClock` MUST return 0 for any other type when `hook_data["agent_id"]` is missing, not a string or empty.
- **subagent-clock-stop-failure**: `subagentClock` MUST return -1 for `StopFailure` carrying a non-empty `agent_id`, because a subagent the API refused is finished and most such subagents never send `SubagentStop`.
- **subagent-clock-activity**: `subagentClock` MUST return 1 for any other type carrying a non-empty `agent_id`, including `SubagentStart`; the caller stamps `sessions.subagent_activity_at` on 1 and clears it on -1.

### Table name

- **table-name**: `tableName` MUST insert `_` before every uppercase character that is not first, lower-case every character, and append `_events`, giving the SQLite table for the event type's detail rows (`PreToolUse` becomes `pre_tool_use_events`, and a name with consecutive capitals such as `MCPCall` becomes `m_c_p_call_events`).

### Concurrency and side effects

- **pure-and-sendable**: The enum MUST be `Sendable`, the four sets and `interruptedEventType` MUST be immutable `static let` values, and every function MUST be a pure computation over its arguments that reads no file, logs nothing and posts no notification; as a consequence any thread MAY call them concurrently.
- **hook-data-untrusted**: `hookData` values are read with `as? String`; a value of another type is treated as absent, and no function throws.

## Appearance

Not applicable — this is an event-type enumeration, not a visual component.

## States

Not applicable — this is an event-type enumeration, not a visual component.

## Accessibility

Not applicable — this is an event-type enumeration, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hook-event-type-001 | case-count-pinned, case-list | `HookEventType.allCases.count` | 28 (test `caseCountIsPinned`) |
| hook-event-type-002 | table-name | `HookEventType.preToolUse.tableName` | `pre_tool_use_events` (test `tableNameIsSnakeCaseWithEventsSuffix`) |
| hook-event-type-003 | table-name | `.postToolUseFailure.tableName`, `.statusLine.tableName`, `.stop.tableName`, `.cwdChanged.tableName` | `post_tool_use_failure_events`, `status_line_events`, `stop_events`, `cwd_changed_events` |
| hook-event-type-004 | is-activity-false-for-ambient, ambient-event-types | `isActivity("ConfigChange")` | false (test `ambientTypesAreNotActivityAndUnknownTypesAre`); likewise `StatusLine` and `InstructionsLoaded` |
| hook-event-type-005 | is-activity-true-otherwise | `isActivity("SomethingNew")`, `isActivity("")` | true, true (first from the same test) |
| hook-event-type-006 | is-activity-exact-match | `isActivity("configchange")` | true |
| hook-event-type-007 | sets-turn-state-ambient-or-off-turn | `setsTurnState("ConfigChange", [:])`, `("SubagentStop", [:])`, `("FileChanged", [:])`, `("PreCompact", [:])` | false for each |
| hook-event-type-008 | sets-turn-state-default | `setsTurnState("PreToolUse", [:])`, then with `["agent_id": "a1"]`, then with `["agent_id": ""]` | true, false, true |
| hook-event-type-009 | sets-turn-state-blocking-requests | `setsTurnState("PermissionRequest", ["agent_id": "a1"])`, `("Elicitation", ["agent_id": "a1"])` | true, true |
| hook-event-type-010 | sets-turn-state-notification | `notification_type` of `idle_prompt`, `permission_prompt`, `elicitation_dialog`, `""`, absent, `5` (a number) | false, true, true, true, true, true |
| hook-event-type-011 | sets-turn-state-session-start | `source` of `compact`, `startup`, absent | false, true, true |
| hook-event-type-012 | sets-turn-state-default | `setsTurnState("Stop", [:])`, `("SomethingNew", [:])`, `("SomethingNew", ["agent_id": "a1"])` | true, true, false |
| hook-event-type-014 | subagent-clock-stop | `subagentClock("SubagentStop", [:])` and with an `agent_id` | -1, -1 |
| hook-event-type-015 | subagent-clock-activity | `subagentClock("PreToolUse", ["agent_id": "a1"])`, `("SubagentStart", ["agent_id": "a1"])` | 1, 1 |
| hook-event-type-016 | subagent-clock-stop-failure | `subagentClock("StopFailure", ["agent_id": "a1"])`, and `("StopFailure", [:])` | -1, 0 |
| hook-event-type-017 | subagent-clock-no-agent | `subagentClock("Stop", [:])`, `("PreToolUse", ["agent_id": ""])`, `("PreToolUse", ["agent_id": 7])` | 0, 0, 0 |
| hook-event-type-018 | waiting-notification-types, turn-ending-event-types, off-turn-event-types, interrupted-event-type | read the four constants | `ambientEventTypes` is `{ConfigChange, StatusLine, InstructionsLoaded}`; `offTurnEventTypes` is `{SubagentStart, SubagentStop, TaskCreated, TaskCompleted, TeammateIdle, PreCompact, PostCompact, FileChanged}`; `waitingNotificationTypes` is `{permission_prompt, elicitation_dialog}`; `turnEndingEventTypes` is `{Stop, StopFailure, SessionEnd}`; `interruptedEventType == "Interrupted"` (untested: no test pins the members) |

## Edge Cases

- **Unknown event type** (MUST): `isActivity` and `setsTurnState` treat a string outside the enum as activity, and `setsTurnState` falls to the `agent_id` rule; the enum has no failure path for it.
- **Empty string** (MUST): `isActivity("")` is true and `setsTurnState("", [:])` is true.
- **Missing or wrong-typed `hook_data` fields** (MUST): `notification_type`, `source` and `agent_id` of another type than string are treated as absent; an empty `agent_id` is treated as absent.
- **Boundary: stop without start** (MUST): `subagentClock` returns -1 for `SubagentStop` with no earlier `SubagentStart`, because most subagents on disk have a stop and no start.
- **Table name for consecutive capitals** (MUST, **table-name**): `tableName` puts `_` before each uppercase character, so a future event name such as `MCPCall` MUST become `m_c_p_call_events`; this is an accepted limitation, and no current case has consecutive capitals.
- **Concurrent access** (MUST): every member is immutable or pure, so concurrent calls need no coordination.
- **Error states, offline or disconnected** (not applicable): no function does I/O, throws or touches a network.
- **Case sensitivity** (MUST): raw values are compared exactly; `Stop` and `stop` differ.

## Configuration
Not applicable: no configurable options. The inputs of each function are defined by **classification-inputs** in the Behavioral Requirements, and the sets are fixed constants.
## Deep Linking

Not applicable: this enum defines no URL or deep link.

## Localization

Not applicable: this enum contains no user-facing string; raw values are Claude Code's event names and the table names are SQL identifiers.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: this enum reads `notification_type`, `source` and `agent_id` from a payload and returns a flag or an integer; it stores and transmits nothing.

## Logging

Not applicable: this code makes no log call.

## Platform Notes

- **SwiftUI**: Not used; the enum has no view layer, though Settings views iterate `allCases` to drive hook install and uninstall.
- **Compose**: Port as a Kotlin `enum class` with a `rawValue` property, and `companion object` sets as `Set<String>`; `Map<String, Any?>` for `hookData`, read with `as? String` safe casts.
- **React/Web**: Port as a string-literal union plus a frozen `Set<string>` per constant; read `hookData` as `Record<string, unknown>` and test `typeof value === "string"`; build `tableName` with a replace on uppercase letters that skips index 0.
- **AppKit / UIKit**: The enum is Foundation-only and uses no AppKit or UIKit type, so an app embeds it unchanged. `tableName` iterates `Character.isUppercase`, which is Unicode-aware, so a port on another platform should pick the matching character test.
- **WinUI 3**: Use a C# `enum` with a `[JsonStringEnumMemberName]` or a static `Dictionary<HookEventType, string>` for the raw values (a C# enum has no raw strings), `Enum.GetValues<HookEventType>()` for `allCases`, `HashSet<string>` constants (`FrozenSet<string>` on .NET 8) and `IReadOnlyDictionary<string, object?>` or `JsonElement` for `hookData`, checking `JsonValueKind.String` instead of `as? String`. `tableName` maps to `char.IsUpper` over `string`; return the three clock signals as a small enum (or an `int` as the source does). All of it is pure, so `static` methods in a `static class` suffice.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/HookEventType.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Classification functions take the raw event type string, not a case.
**Rationale**: A hook Claude Code adds after this build must still be ingested; unknown types count as activity, since they are more likely real work than ambient noise.
**Approved**: pending

**Decision**: Ambient events do not advance activity, and only main-turn events set turn state.
**Rationale**: One settings save stamped seven untouched sessions with the same second, `StatusLine` arrives many times per second, and subagent and compaction events arrive after a turn has ended; counting them kept finished sessions looking busy.
**Approved**: pending

**Decision**: Blocking requests (`PermissionRequest`, `Elicitation`) set turn state even from a subagent, and a `Notification` without a type reads as waiting.
**Rationale**: The session is waiting on the user either way, and nothing in a typeless notification says it is informational.
**Approved**: pending

**Decision**: `subagentClock` returns a signal (1, -1, 0), and `SubagentStop` and a subagent's `StopFailure` clear it outright.
**Rationale**: Measured over real capture a stop is terminal (1.03 rows per `agent_id`) and 94% of refused subagents send no stop; clearing is self-healing because a surviving subagent re-stamps within seconds, while a false "working" would outlive the work by the freshness window. The result is a stamp signal and not a count, because `SubagentStart` is younger than `SubagentStop` and a counter would run negative.
**Approved**: pending

**Decision**: `setsTurnState` checks `agent_id` only in its default branch, so a subagent's waiting `Notification` or `SessionStart` is counted.
**Rationale**: Open question: the code does not read `agent_id` for `Notification` or `SessionStart`, so a subagent's waiting `Notification` or non-compact `SessionStart` returns true, but the doc comment says "nor anything a subagent did" and the source gives no reason either way. The behavior is not required of ports until the owner decides, and no conformance vector pins it.
**Approved**: pending

**Decision**: `tableName` is derived from the raw value by a small loop, not stored per case.
**Rationale**: A new case gets its table name without a second edit; the cost is the consecutive-capitals behaviour noted in Edge Cases, accepted as a known limitation: `MCPCall` would become `m_c_p_call_events`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

unit-test-coverage is passed: every vector is covered by `Tests/AgenticDeveloperHubSDKCoreTests/Sessions/HookEventTypeTests.swift`.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (HookEventTypeTests.swift, 17 of 17 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Corrected the summary to 27 events plus StatusLine, dropped the unsettled turn-state and registration vectors, named the subagent-clock signals, listed the set members in vector 018, and made the purity and table-name rules MUST. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
