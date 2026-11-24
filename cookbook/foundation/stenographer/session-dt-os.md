---
id: 25b6559b-69c1-450f-85b3-fc026d55f469
title: "Session DTOs"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The shared wire records for sessions: the session, its events, a session with recent events, and the daemon health probe, with their tolerant decoding."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - dto
  - wire
depends-on:
  - e8286557-84ee-4f45-b78c-f1d184c51a37
related:
  - 96f73261-cf32-42cc-92f3-f8b58542382a
  - 9c7c78d3-23ca-4ca6-a519-9968b440b8c6
references: []
approved-by: ""
approved-date: ""
---

# Session DTOs

## Overview

Four serializable records transferred over XPC and HTTP between the Stenographer daemon, the app and the CLI. `SessionDTO` is one tracked Claude Code session. `SessionEventDTO` is one recorded hook event. `SessionDetailDTO` pairs a session with its newest events (the body of `GET /sessions/:id`, the XPC `getSessionDetail`, and what `steno session` prints). `HealthDTO` is the daemon's liveness probe.

All four are immutable values with `let` fields. Their wire spelling is the stenographer-wide snake_case strategy. Most fields are Strings; timestamps travel as strings in the daemon's SQLite `datetime` form and are never parsed here. `SessionDTO` has a hand-written decoder that tolerates payloads from an older daemon. The types hold no behavior: how a session is enriched, how activity is derived and how health figures are measured belong to the daemon. The wire coders are specified by the stenographer wire spec ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37)), the routes that serve these records by the daemon service ([adhsdk.ingredient.foundation.stenographer.stenographer-daemon-service](cookbook:96f73261-cf32-42cc-92f3-f8b58542382a)), and the client that decodes them by the HTTP client ([adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6)).

## Behavioral Requirements

**Common**

- **dto-conformances**: `SessionDTO`, `SessionEventDTO`, `SessionDetailDTO` and `HealthDTO` MUST each be `Codable` and `Sendable` immutable value types; none declares `Equatable`, `Hashable` or `Identifiable`.
- **dto-wire-spelling**: The records MUST travel with snake_case keys through the shared wire encoder and decoder, so `sessionId` is `session_id`, `lastActivityAt` is `last_activity_at`, `recentEvents` is `recent_events` and so on.
- **dto-timestamps-opaque**: Every timestamp field MUST be carried as a String exactly as stored; no type here parses or compares it.

**SessionDTO**

- **session-field-set**: `SessionDTO` MUST carry these fields: `sessionId`, `cwd`, `model`, `startedAt`, `lastActivityAt`, `lastTool`, `status`, `gitBranch`, `summary`, `termProgram`, `projectRoot`, `termSessionId`, `transcriptTitle`, `lastOutput`, `lastEventType`, `summaryAt`, `turnStateAt` (all String), `pid` and `eventCount` (Int), and `subagentWorking` (Bool).
- **session-required-keys**: Decoding MUST fail when any of these twelve keys is missing: `session_id`, `cwd`, `model`, `started_at`, `last_activity_at`, `last_tool`, `status`, `git_branch`, `summary`, `pid`, `term_program`, `event_count`.
- **session-optional-keys**: Decoding MUST succeed when any of `project_root`, `term_session_id`, `transcript_title`, `last_output`, `last_event_type`, `summary_at`, `turn_state_at` is absent, defaulting each to the empty string, and MUST default an absent `subagent_working` to false.
- **session-init-defaults**: The public initializer MUST default `projectRoot`, `termSessionId`, `transcriptTitle`, `lastOutput`, `lastEventType`, `summaryAt` and `turnStateAt` to the empty string and `subagentWorking` to false, and MUST require the other twelve.
- **session-encode-synthesized**: Encoding MUST be the synthesized one: every field is written, including empty strings and false.
- **session-null-optional**: An optional key present with JSON `null` MUST decode as the default (the decoder uses a present-or-nil read followed by a default), not fail.
- **session-project-root**: `projectRoot` holds the top-level (non-submodule) git project root for `cwd`. The daemon fills it; it is empty until enrichment resolves it or when `cwd` is not in a git working tree.
- **session-term-session-id**: `termSessionId` MUST be the terminal's `TERM_SESSION_ID` (example in source: iTerm's `w0t1p0:UUID`) so the app can jump to the exact tab or pane; it is empty for terminals that do not set it.
- **session-transcript-title**: `transcriptTitle` MUST be the session's Claude Code title (the tab name or Claude's auto-title, from the transcript's `custom-title` and `ai-title` records), empty until the session is named. It MUST NOT carry the AI summary: the two live in separate fields.
- **session-last-output**: `lastOutput` holds the agent's most recent prose reply, which the daemon tails from the transcript when the Stop hook fires. It is empty for a session that has not answered.
- **session-last-event-type**: `lastEventType` MUST be the last hook event seen (examples: `PreToolUse`, `Notification`); the Sessions window reads it as working, idle or waiting on the user. It tracks the main agent's turn only.
- **session-summary-at**: `summaryAt` MUST be when `summary` was written in `datetime()` form, empty when never.
- **session-subagent-working**: `subagentWorking` MUST be a verdict, not a timestamp: true when a subagent of the session was doing something just now. The daemon owns the freshness window; a client MUST NOT re-derive it.
- **session-turn-state-at**: `turnStateAt` MUST be when `lastEventType` was recorded (the `turn_state_at` column, SQLite `datetime` form); it moves only when the turn state moves, unlike `lastActivityAt`, which ambient events also advance. It is empty from a daemon that predates the field.

**SessionEventDTO**

- **event-field-set**: `SessionEventDTO` MUST carry `id` (Int), and `sessionId`, `eventType`, `timestamp`, `cwd`, `detail`, `gitBranch` (String).
- **event-init-default**: The public initializer MUST default `gitBranch` to the empty string and require the other six.
- **event-decode-strict**: Decoding MUST fail when any of the seven keys is missing, including `git_branch`: the type has no tolerant decoder, so the initializer default does not apply on decode.

**SessionDetailDTO**

- **detail-field-set**: `SessionDetailDTO` MUST carry `session` (`SessionDTO`) and `recentEvents` (a list of `SessionEventDTO`), with wire keys `session` and `recent_events`, both required.
- **detail-ordering-owner**: The DTO MUST NOT impose an order or a count on `recentEvents`; the daemon decides how many and in what order.
- **detail-delivery**: The daemon returns a detail as the body of `GET /sessions/:id` and through the XPC `getSessionDetail`. The HTTP client's `session(id:includeCounts:)` returns `SessionDTO??`: for a 2xx reply whose body decodes as this type it returns `.some(detail.session)`; for a 404 it returns `.some(nil)` (the daemon answered and the session does not exist); for an unreachable daemon, a non-2xx reply other than 404, or a body that does not decode, it returns the outer `nil`. That client behavior belongs to the HTTP client spec and is described here for context.

**HealthDTO**

- **health-field-set**: `HealthDTO` MUST carry `status` (String), `uptime` (`TimeInterval`), `version` (String), `activeSessionCount`, `totalEventCount`, `startupDurationMs`, `memoryFootprintMb`, `memoryPeakMb` (all optional Int) and `statusLineError` (optional String).
- **health-status-values**: The daemon's `/health` route sets `status` to `ok` when its database is ready and to `migrating` when the schema is not current yet; it also fills `startupDurationMs`, the two memory figures and `statusLineError`, and leaves the two counts nil. This is daemon behavior; the DTO carries any String in `status`.
- **health-init-defaults**: The public initializer MUST require `status`, `uptime` and `version` and default every other field to nil.
- **health-decode**: Decoding MUST fail when `status`, `uptime` or `version` is missing, and MUST yield nil for any absent optional key (the synthesized decoder reads optionals with a present-or-nil read).
- **health-liveness-only**: `/health` is documented as a pure liveness probe that never touches the database; a consumer MUST treat `activeSessionCount` and `totalEventCount` as always nil from `/health`. They are retained for source compatibility, with `/insights/summary` as the DB-backed source of counts.
- **health-startup-duration**: `startupDurationMs` MUST be milliseconds from process start to HTTP-ready, nil until first startup completes.
- **health-memory-footprint**: `memoryFootprintMb` MUST be the daemon's `phys_footprint` in MB, nil if the kernel declined the reading.
- **health-memory-peak**: `memoryPeakMb` holds the highest footprint since the daemon process started; it never falls, and only a restart re-baselines it.
- **health-mb-casing**: The two memory properties MUST be spelled with a lowercase `b` (`Mb`), because clients decode with the from-snake-case strategy, which rebuilds `memory_footprint_mb` as `memoryFootprintMb`. An all-caps `MB` property would never match and, being optional, would decode to nil with no error. The wire keys are `memory_footprint_mb` and `memory_peak_mb`.
- **health-status-line-error**: `statusLineError` holds the status-line dispatcher's record of the renderer's last failure (why Claude Code's status line is missing Stenographer's part). The daemon reads it from a file, never the database; it is cleared on the next success and nil while the renderer works.

## Appearance

Not applicable — these are non-visual data transfer objects, not visual components.

## States

Not applicable — these are non-visual data transfer objects, not visual components.

## Accessibility

Not applicable — these are non-visual data transfer objects, not visual components.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-dtos-001 | session-optional-keys | Decode a session body with only the twelve required keys | Succeeds; `projectRoot`, `termSessionId`, `transcriptTitle`, `lastOutput`, `lastEventType`, `summaryAt` and `turnStateAt` are `""` and `subagentWorking` is false |
| session-dtos-002 | session-required-keys | Decode a session body with `event_count` removed, then another with `git_branch` removed | Each throws a key-not-found error for the removed key; both are required on `SessionDTO` |
| session-dtos-004 | dto-wire-spelling, session-encode-synthesized | Encode a session with the wire encoder | All twenty keys appear, snake_case, including empty strings and `subagent_working` false |
| session-dtos-005 | session-null-optional | Decode a body with `"project_root": null` | Succeeds with `projectRoot` equal to `""` |
| session-dtos-006 | session-init-defaults | Construct a session with only the twelve required arguments | Optional strings are `""` and `subagentWorking` is false |
| session-dtos-007 | event-decode-strict | Decode an event body without `git_branch` | Throws, although the initializer defaults it |
| session-dtos-008 | event-field-set, dto-wire-spelling | Encode then decode an event with the wire coders | Keys `id`, `session_id`, `event_type`, `timestamp`, `cwd`, `detail`, `git_branch`; fields round-trip |
| session-dtos-009 | detail-field-set | Decode `{"session": ..., "recent_events": []}` | `recentEvents` is empty and `session` decodes; a body without `recent_events` throws |
| session-dtos-010 | health-init-defaults | Construct `HealthDTO(status: "ok", uptime: 1, version: "test")` (as DaemonProviderPickerViewTests does) | Every optional field is nil |
| session-dtos-011 | health-mb-casing | Decode `{"status":"ok","uptime":5,"version":"1","memory_footprint_mb":812,"memory_peak_mb":900}` with the from-snake-case decoder | `memoryFootprintMb` is 812 and `memoryPeakMb` is 900 |
| session-dtos-012 | health-decode | Decode a health body with `version` removed | Throws a key-not-found error for `version` |
| session-dtos-014 | dto-wire-spelling, session-last-event-type, session-subagent-working | Decode a session body with `last_event_type` `PreToolUse` and `subagent_working` true | `lastEventType` is `PreToolUse` and `subagentWorking` is true |
| session-dtos-015 | health-decode | Decode a health body with `status`, `uptime` and `version` present and `status_line_error` absent | Succeeds and `statusLineError` is nil |
| session-dtos-016 | dto-conformances | Pass a `SessionDTO`, `SessionEventDTO`, `SessionDetailDTO` and `HealthDTO` to a generic function constrained to `Codable & Sendable` | Compiles; no type needs `Equatable`, `Hashable` or `Identifiable` |
| session-dtos-017 | dto-timestamps-opaque | Decode a session body with `started_at` `2026-11-14 09:30:00` | `startedAt` is that exact string; no date parsing occurs |
| session-dtos-018 | session-field-set | Construct a session passing all twenty fields | Each field reads back as given |
| session-dtos-019 | event-init-default | Construct an event with the six required arguments and no `gitBranch` | `gitBranch` is `""` |
| session-dtos-020 | health-field-set | Construct a health value passing all nine fields | Each field reads back as given |
| session-dtos-021 | detail-ordering-owner | Decode a detail body whose `recent_events` holds events with ids 3, 1, 2 | `recentEvents` holds ids 3, 1, 2 in that order; the type neither sorts nor truncates |
## Edge Cases

- **Null and empty input**: Every String field MAY be empty, and every optional health field MAY be absent or `null`. A missing required session or event key MUST fail the whole decode.
- **Boundary values**: `pid`, `eventCount`, `id` and the health Ints take any Int, including zero and negative values; nothing is clamped. `uptime` is a Double.
- **Concurrent access**: The values are immutable and `Sendable`, so they MAY be shared across threads and actors.
- **Error states**: Decoding errors are the standard `DecodingError`s and are thrown, not swallowed. The HTTP client reads a body that does not decode as nil (for example `health()` returns nil and the detail call returns nil).
- **Offline or disconnected state**: Not applicable: the types perform no I/O; the client that fetches them returns nil when the daemon is unreachable.
- **Version skew**: A payload from an older daemon that predates the later-added session keys MUST decode, per session-optional-keys. An old client decoding a newer daemon's payload ignores unknown keys; for an older daemon missing a required key, decoding fails.
- **Casing trap**: A port that spells the two memory properties with an all-caps `MB` suffix reads nil silently from a from-snake-case decoder; health-mb-casing forbids that spelling.
- **Encoding is not lenient**: A client encoding a session always writes every key, so a payload encoded by this type decodes under the strict and the tolerant readers alike.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `SessionDTO` optional initializer parameters | String and Bool | `""` and false | Eight fields default so a caller can build a session from the twelve required values. |
| `SessionEventDTO.gitBranch` | String | `""` | Defaults in the initializer only. |
| `HealthDTO` optional initializer parameters | Int and String optionals | nil | Six fields default to nil. |
| wire coding strategy | snake_case keys | `StenographerWire` | Callers use the shared encoder and decoder. |

## Deep Linking

Not applicable: these types define no URL or deep link; the routes they ride (`GET /sessions/:id`, `/health`) are daemon API routes.

## Localization

Not applicable: the types hold no user-facing literal. `summary`, `transcriptTitle` and `lastOutput` are user or model text carried verbatim, and `statusLineError` is a developer-facing message.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: `cwd`, `projectRoot`, `gitBranch`, `summary`, `transcriptTitle` and `lastOutput` describe a user's working directories and the content of their coding session (the agent's last reply and an AI summary); event `detail` may hold tool details.
- **Storage**: The types store nothing; the daemon persists sessions and events.
- **Transmission**: Over XPC to the app and over HTTP on the daemon's loopback address to the CLI and app.
- **Retention**: Not set by these types; the daemon owns retention.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Plain Swift with no view code. The records are not `Identifiable`, so a list needs `id: \.sessionId`. Treat the empty string as "not set" when showing fields such as `transcriptTitle` or `projectRoot`.
- **Compose**: `kotlinx.serialization` data classes with `@SerialName` snake_case keys. Give the eight tolerant session fields default values and `coerceInputValues` or explicit nullable handling for `null`, and leave the required twelve without defaults so a missing key fails as in the source. Keep the event `git_branch` required.
- **React/Web**: TypeScript interfaces with snake_case keys, the eight tolerant session keys optional and defaulted when read. Name memory fields exactly `memory_footprint_mb` and `memory_peak_mb`; there is no casing trap on the wire.
- **AppKit / UIKit**: Foundation-only; the hand-written `SessionDTO` decoder uses a present-or-nil read plus a default for the tolerant keys, and the casing rule for the memory properties follows the from-snake-case strategy.
- **WinUI 3**: Use C# records with `System.Text.Json` and `JsonNamingPolicy.SnakeCaseLower` (which needs .NET 8 or later). Set `JsonSerializerOptions.UnmappedMemberHandling` to `Skip` so unknown keys are ignored, as the Swift source does. Mark the twelve required session properties `required` so a missing key throws, and give the eight tolerant ones initializers (`string ProjectRoot { get; init; } = ""` and `bool SubagentWorking { get; init; }`). A JSON `null` for a non-nullable string throws under default settings, so add a converter or nullable annotation that maps `null` to the default for the tolerant keys. Use `double Uptime` and `int?` for the optional health integers, `string? StatusLineError`, and keep timestamps as `string`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/SessionDTOs.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `SessionDTO` has a hand-written decoder that makes eight fields optional on decode (defaulting to empty or false), while `SessionEventDTO` and `HealthDTO`'s required fields stay strict.
**Rationale**: The tolerant decoder protects against an old daemon serving a freshly-updated client while app, daemon and CLI update. It applies a default to `project_root` and to seven further later-added keys, which are the eight tolerant fields. `SessionEventDTO` never gained a later field, so it stays synthesized.
**Approved**: pending

**Decision**: The `SessionEventDTO.gitBranch` initializer default does not apply on decode.
**Rationale**: The type has no tolerant decoder, so a payload without `git_branch` fails. Recorded so a port does not assume the default covers the wire.
**Approved**: pending

**Decision**: `subagentWorking` is a verdict computed by the daemon, not a timestamp a client compares.
**Rationale**: The main agent's `lastEventType` cannot say whether a background subagent is working, and subagent hooks are refused so a late `SubagentStop` cannot leave a finished session spinning. The daemon owns the freshness window so no client re-derives it.
**Approved**: pending

**Decision**: `transcriptTitle` and `summary` are separate fields.
**Rationale**: They once shared a column and the Sessions window showed the name where the summary belonged for every named session; the split is the fix.
**Approved**: pending

**Decision**: The health memory properties are spelled `Mb`, not `MB`.
**Rationale**: The casing is load-bearing: the from-snake-case strategy rebuilds `memory_footprint_mb` as `memoryFootprintMb`, an all-caps property would never match, and because it is optional the synthesized decoder returns nil without throwing. The wire format is unchanged.
**Approved**: pending

**Decision**: `/health` carries no database counts; `activeSessionCount` and `totalEventCount` stay in the type but are always nil.
**Rationale**: `/health` is a pure liveness probe that never touches the database, so an in-flight retention or import cannot slow it. The fields remain for source compatibility.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

separation-of-concerns passes: the file declares four shapes and the tolerant decoder; enrichment, activity derivation, health measurement, routes and transport live in the daemon and the HTTP client. unit-test-coverage passes: every vector has a test, in `SessionDTOsConformanceTests.swift` (decode defaults, required keys, `Mb` casing, strict event decode and the rest), beside the constructions in `DaemonSessionSummarizerTests` and `DaemonProviderPickerViewTests`. graceful-degradation passes because the session decoder defaults the later-added keys instead of failing on an older daemon's payload.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (SessionDTOsConformanceTests.swift, 18 of 18 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Daemon and client behavior in Behavioral Requirements rewritten as descriptive field notes, detail-delivery now states the exact SessionDTO?? results, stale doc-comment claims removed from Design Decisions, edge-case keywords made unambiguous, vectors merged, split and added for the uncovered requirements, WinUI 3 note cut to record and serializer guidance with Skip required, and depends-on and related linked. |
