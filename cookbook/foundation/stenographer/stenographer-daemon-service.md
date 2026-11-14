---
id: 96f73261-cf32-42cc-92f3-f8b58542382a
title: "Stenographer Daemon Service"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The injectable protocol Stenographer windows use to ask the daemon for sessions, oversight, AI logs and preferences; unreachable reads as nil."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - protocol
  - client
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Stenographer Daemon Service

## Overview

`StenographerDaemonService` is the one injectable seam through which the moved Stenographer windows (sessions, conversations, oversight findings and scripts, the AI log, preference panes) ask the stenographer daemon for data. The production implementation is `StenographerHTTPClient` over the daemon's loopback HTTP API; tests hand the windows a stub. The file holds the protocol, the default-argument convenience overloads in a protocol extension, `SummarizeDaemonFailure` (the daemon declined to summarize and said why) and `DaemonProviderConfig` (one row of the daemon's saved provider list).

The protocol is the contract that matters: what each operation asks, what it answers, and what "the daemon could not be reached" looks like to a caller. The routes, query spelling, timeouts and reconnect polling belong to the implementation and are described under Platform Notes and Edge Cases only where a conforming port must match them.

## Behavioral Requirements

**Protocol shape**

- **service-sendable**: `StenographerDaemonService` MUST be `Sendable`, so one instance can be shared by every window and called from any actor.
- **service-async**: Every operation except `onReconnect` MUST be `async`; only `summarize` is `throws`.
- **service-seam**: Windows MUST depend on the protocol, not on the HTTP client, so a stub can replace it in tests.

**Unreachable-daemon contract**

- **reads-nil-when-unreachable**: Each read MUST answer nil when the daemon cannot be reached, so callers keep what is on screen.
- **writes-false-or-nil-when-unreachable**: Each write MUST answer `false` (for Bool returns) or nil (for value returns) in the same case.
- **session-doubly-optional**: `session(id:includeCounts:)` MUST answer `SessionDTO??`: the outer nil means the daemon is unreachable and the inner nil means there is no such session.

**Operations**

- **op-health**: `health()` MUST answer `HealthDTO?`.
- **op-sessions**: `sessions(status:project:sinceHours:includeCounts:)` MUST answer `[SessionDTO]?`, taking an optional status, an optional project, an Int `sinceHours` and a Bool `includeCounts`.
- **op-session**: `session(id:includeCounts:)` MUST answer one session by id.
- **op-summarize**: `summarize(sessionId:)` MUST be `async throws`, return nothing on success, throw `SummarizeDaemonFailure` carrying the daemon's reason when the daemon declines, and throw any other error for a transport failure.
- **op-conversations**: `conversations(limit:includeWorkOutput:before:sessionId:)` MUST answer `[ConversationEntryDTO]?`, taking an Int `limit`, a Bool `includeWorkOutput`, an optional `before` cursor and an optional session id.
- **op-oversight-findings**: `oversightFindings(status:)` MUST answer `[OversightFindingDTO]?` with an optional status filter.
- **op-oversight-action-target**: `oversightActionTarget(findingId:)` MUST answer `OversightActionTargetDTO?`.
- **op-act-on-finding**: `actOnOversightFinding(findingId:)` MUST answer `OversightActResultDTO?`.
- **op-oversight-scripts**: `oversightScripts()` MUST answer `[OversightScript]?`.
- **op-save-script**: `saveOversightScript(_:)` MUST answer the saved `OversightScript?`.
- **op-delete-script**: `deleteOversightScript(id:)` MUST answer a Bool, true when the daemon took the delete.
- **op-reset-script**: `resetOversightScript(id:)` MUST answer the reset `OversightScript?`.
- **op-ai-interactions**: `aiInteractions(limit:)` MUST answer `[AIInteractionDTO]?` and `aiInteraction(id:)` MUST answer one `AIInteractionDTO?` by Int id.
- **op-provider-configs**: `aiProviderConfigs()` MUST answer `[DaemonProviderConfig]?`, the daemon's saved LLM provider configurations (what Stenographer's LLM Providers pane pushed), for the pickers in the moved panes.
- **op-preferences-read**: `summaryPreferences()` MUST answer `SummaryPreferenceResponse?` and `oversightPreferences()` MUST answer `OversightPreferenceResponse?`.
- **op-preferences-write**: `setSummaryPreferences(_:)` and `setOversightPreferences(_:)` MUST answer a Bool for a `SummaryPreferenceRequest` and an `OversightPreferenceRequest`.
- **op-set-ai-preferences**: `setAIPreferences(_:)` MUST replace the daemon's LLM provider registry with the given `AIProviderConfigSync` (the whole set plus the active selection) and answer true when the daemon took it.
- **op-on-reconnect**: `onReconnect(_:)` MUST register a `@Sendable` handler that fires when the daemon is seen to have restarted, so a preference push can re-send its snapshot. It is synchronous and not `async`.

**Default-argument overloads (protocol extension)**

- **default-sessions**: `sessions(status:sinceHours:includeCounts:)` MUST default `status` to nil, `sinceHours` to 0 and `includeCounts` to true, pass `project` as nil, and call the full operation.
- **default-session**: `session(id:)` MUST call `session(id:includeCounts:)` with `includeCounts` true.
- **default-findings**: `oversightFindings()` MUST call `oversightFindings(status:)` with nil.
- **default-ai-interactions**: `aiInteractions()` MUST call `aiInteractions(limit:)` with 200.
- **default-conversations**: `conversations(limit:includeWorkOutput:sessionId:)` MUST default `limit` to 200, `includeWorkOutput` to false and `sessionId` to nil, and call the full operation with `before` nil.

**SummarizeDaemonFailure**

- **failure-shape**: `SummarizeDaemonFailure` MUST be a `LocalizedError`, `Equatable` and `Sendable` struct with one `reason` String and a public initializer `init(reason:)`.
- **failure-description**: Its `errorDescription` MUST be the `reason` string.
- **failure-distinct**: It MUST be distinct from a transport failure so the list can show the daemon's reason. Examples of a reason in the source documentation: a memory guard or a provider error.

**DaemonProviderConfig**

- **config-shape**: `DaemonProviderConfig` MUST be a `Codable`, `Sendable`, `Equatable` and `Identifiable` struct with `id` (UUID), `name`, `pluginIdentifier` and `templateId` (String), and a public initializer taking all four.
- **config-no-secrets**: A provider configuration as the daemon stores it carries no secrets and no model; those are the daemon's own.
- **config-wire-keys**: Through the stenographer wire spelling the keys are `id`, `name`, `plugin_identifier` and `template_id`; the type is one row of `GET /preferences/ai/configs`.

**Production implementation notes (StenographerHTTPClient)**

- **impl-wire-spelling**: The HTTP implementation MUST send and read JSON in the shared wire spelling (snake_case keys, ISO-8601 dates) over the daemon's loopback API, with the base URL taken from the `STENOGRAPHER_URL` environment variable when it is a valid URL and the stenographer HTTP base URL constant otherwise.
- **impl-unreachable-mapping**: A failed connection, a non-2xx reply or a body that does not decode MUST all read as unreachable (nil or false); the one exception is a 404 on a single session, which answers inner nil (no such session).
- **impl-summarize-errors**: `summarize` MUST throw a URL error `cannotConnectToHost` when no reply arrives and `SummarizeDaemonFailure` with the daemon's `error` message, or `HTTP <status>` when the body has none, on a non-2xx reply.
- **impl-act-result**: `actOnOversightFinding` MUST answer a succeeded result with status from the decoded finding, or `acted` when the body does not decode, on a 2xx reply, and a failed result carrying the daemon's error message or `HTTP <status>` otherwise.
- **impl-ai-prefs-camelcase**: `setAIPreferences` MUST be sent with a plain encoder (camelCase keys), not the wire encoder, because the daemon's `POST /preferences/ai` decodes the registry with a default decoder. This is the one write that differs from the others' snake_case body.
- **impl-timeouts**: Request timeouts MUST be 605 seconds for a POST ending in `/summarize` (a summary runs inline on the daemon for up to the user's largest give-up time of 600 seconds, plus 5), 15 seconds for GET `/conversations` and the AI interaction reads, and 10 seconds for everything else.
- **impl-reconnect-poll**: The reconnect signal MUST come from polling `/health` (every 30 seconds by default) and treating an `uptime` that went down as a restart, firing every registered handler once; the daemon has no push channel to a client that is not an XPC subscriber.
- **impl-no-retry**: The implementation has no retry, no backoff, no authentication header and no cancellation beyond the polling task's own, and each request is sent once.

## Appearance

Not applicable — this is a protocol and its supporting value types, not a visual component.

## States

Not applicable — this is a protocol and its supporting value types, not a visual component. The runtime reconnect state (last seen uptime, registered handlers, polling task) belongs to the HTTP implementation and is described under Edge Cases.

## Accessibility

Not applicable — this is a protocol and its supporting value types, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| daemon-service-001 | reads-nil-when-unreachable, impl-unreachable-mapping | Stub transport with no daemon (StenographerHTTPClientTests `testUnreachableDaemonReturnsNil`) | `sessions` and `oversightFindings` answer nil and `setSummaryPreferences` answers false (`health()` takes the same path) |
| daemon-service-002 | op-sessions, default-sessions | Call `sessions(status: "active")` (StenographerHTTPClientTests `testSessionsBuildsQueryAndDecodes`) | The request carries `status=active`; the body decodes into `[SessionDTO]` |
| daemon-service-003 | session-doubly-optional, impl-unreachable-mapping | The daemon answers 404 for `GET /sessions/<id>` (`testSessionNotFoundIsInnerNil`) | `session(id:)` answers the inner nil (not found), not the outer nil |
| daemon-service-004 | session-doubly-optional | No daemon reachable | `session(id:)` answers the outer nil |
| daemon-service-005 | op-summarize, failure-distinct | The daemon answers 500 with `{"error": "Summarize failed: model too large"}` (`testSummarizeThrowsDaemonReason`) | `summarize` throws `SummarizeDaemonFailure` whose `reason` is `Summarize failed: model too large`, and its `errorDescription` is that text |
| daemon-service-006 | op-summarize, impl-summarize-errors | No reply from the daemon | `summarize` throws a URL error with code `cannotConnectToHost` |
| daemon-service-007 | op-act-on-finding, impl-act-result | The daemon answers 409 to the act route (`testActOnFindingMapsConflictToFailure`) | A result with `succeeded` false and the daemon's error text as `reason` |
| daemon-service-008 | impl-act-result | The daemon answers 200 with a finding body whose status is `acted` (`testActOnFindingSuccess`); a 2xx body that does not decode as a finding follows the same source path with the fallback status `acted` and has no test of its own | `succeeded` true and `status` `acted` |
| daemon-service-009 | op-delete-script | The daemon answers 204 to the delete route (`testDeleteScriptIs204`) | `deleteOversightScript(id:)` answers true |
| daemon-service-010 | op-preferences-write, impl-wire-spelling | `setSummaryPreferences` with a request (`testSetSummaryPreferencesPostsSnakeCase`) | The posted body has snake_case keys |
| daemon-service-011 | op-set-ai-preferences, impl-ai-prefs-camelcase | `setAIPreferences` with a config set (`testSetAIPreferencesPostsTheRegistryAsCamelCase`) | The posted body has camelCase keys and the call answers true on a 2xx |
| daemon-service-012 | writes-false-or-nil-when-unreachable | `setAIPreferences` against an error status and against no daemon (`testSetAIPreferencesIsFalseOnAnErrorStatusOrNoDaemon`) | Both answer false |
| daemon-service-013 | op-on-reconnect, impl-reconnect-poll | Health polls report uptimes 500, 600, 3, 10 (`testReconnectFiresWhenUptimeDrops`) | The registered handler fires when the uptime falls from 600 to 3 |
| daemon-service-014 | default-conversations, default-ai-interactions | Call `conversations()` and `aiInteractions()` | They call the full operations with limit 200, includeWorkOutput false, before nil, sessionId nil, and limit 200 |
| daemon-service-015 | impl-timeouts | Timeout for POST `/sessions/x/summarize`, GET `/conversations`, GET `/ai/interactions/3`, GET `/health` | 605, 15, 15 and 10 seconds |
| daemon-service-016 | config-wire-keys | Decode `{"id":"<uuid>","name":"n","plugin_identifier":"p","template_id":"t"}` with the wire decoder | A `DaemonProviderConfig` with those four values |

## Edge Cases

- **Null and empty input**: Optional filters (`status`, `project`, `before`, `sessionId`) MAY be nil and are then omitted from the request. `sinceHours` of 0 or less sends no age filter (MUST). A `limit` is sent as given with no clamping. An empty list reply is a real answer (empty array), distinct from nil.
- **Boundary values**: The default limits are 200 for conversations and AI interactions. A reconnect needs a strictly lower uptime than the previous poll (MUST); an equal or higher uptime fires nothing.
- **Concurrent access**: The protocol is `Sendable`. The HTTP implementation guards its handler list, last uptime and polling task with a lock and is `@unchecked Sendable`; the polling task starts on the first handler registration and only once (MUST). Handlers run outside the lock on the polling task and MUST be `@Sendable`. Concurrent requests are independent; the implementation serializes nothing else.
- **Error states**: A transport failure, non-2xx status or undecodable body is indistinguishable to the caller of a read (all nil). Writes that return a value are nil in the same cases. Only `summarize` and `actOnOversightFinding` surface a daemon reason. The decode error itself is discarded by the implementation (a `try?`), which is deliberate and documented in the type comment.
- **Offline or disconnected state**: With no daemon, every read is nil and every write false or nil; callers keep what is on screen. There is no retry or backoff; the next user action or refresh is the retry. Reconnect detection resumes when `/health` answers again.
- **Daemon restart mid-session**: A drop in `/health` uptime fires the reconnect handlers once so preference pushes re-send their snapshot; the first successful poll ever only records the baseline, and a failed poll leaves the last recorded uptime in place, so the first success after a gap is compared with the uptime from before it.
- **Slow summaries**: A summary runs inline on the daemon for up to 600 seconds; the client waits up to 605 seconds before the call fails as a transport error.
- **Preference encoding split**: The two other preference writes (`setSummaryPreferences` and `setOversightPreferences`) use the snake_case wire encoder and `setAIPreferences` uses camelCase; a port that unifies them breaks the daemon's decoding of the registry (MUST NOT).
- **Account of what a caller cannot tell**: A 4xx that is not 404 for a session reads as unreachable; the caller cannot distinguish "unreachable" from "daemon refused".

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `STENOGRAPHER_URL` | environment variable | unset | Overrides the daemon base URL when it parses as a URL. |
| stenographer HTTP base URL | URL constant | `http://127.0.0.1:22847` | The loopback address used when the variable is unset or invalid. |
| `healthPollInterval` | seconds | 30 | How often the implementation polls `/health` for restarts. |
| `session` | `URLSession` | `.shared` | The injected transport of the HTTP implementation. |
| request timeouts | seconds | 10, 15, 605 | Quick reads, heavy reads, and summarize. |

## Deep Linking

Not applicable: the protocol defines no URL or deep link; the routes belong to the daemon's HTTP API.

## Localization

Not applicable: the file holds no user-facing literal of its own; `SummarizeDaemonFailure.errorDescription` is the daemon's reason text shown unmodified, and the implementation's fallback `HTTP <status>` is a developer-facing English string.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: The operations carry session identifiers, working directories, conversation entries, AI interaction records, oversight findings and scripts, and LLM provider registry data. `DaemonProviderConfig` carries no secrets and no model by documented design.
- **Storage**: The protocol stores nothing; the daemon owns persistence. `setAIPreferences` replaces the daemon's provider registry with the pushed set.
- **Transmission**: Over HTTP to the daemon's loopback address (`http://127.0.0.1:22847` unless overridden by `STENOGRAPHER_URL`); no authentication header is sent.
- **Retention**: Not set by this protocol.

## Logging

Not applicable: neither the protocol nor the HTTP implementation makes log calls; failures read as nil or false.

## Platform Notes

- **SwiftUI**: Inject the protocol through the environment or an initializer and call it from `.task`, keeping the last good value when a read answers nil. Convert the doubly optional session result into three view states (loading failed, not found, found).
- **Compose**: Define a Kotlin interface with suspend functions returning nullable values; model the session result as a sealed type (Unreachable, NotFound, Found) rather than a doubly nullable. Implement the transport with `HttpURLConnection` or OkHttp, `kotlinx.serialization` for the wire spelling, and a coroutine polling `/health` for reconnect.
- **React/Web**: A TypeScript interface of async functions returning `T | null`, with a discriminated result for the session lookup; `fetch` with `AbortController` timeouts of 10, 15 and 605 seconds. Poll `/health` with `setInterval` for reconnect.
- **AppKit / UIKit**: Source file `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerDaemonService.swift`. The protocol is `Sendable` and the moved windows (sessions, oversight, AI log and the provider pickers) take it by initializer, with `StenographerHTTPClient` as production and a stub in tests. `onReconnect` takes an escaping `@Sendable` closure.
- **WinUI 3**: Define `IStenographerDaemonService` in C# with `Task<T?>` returns (`Task<HealthDto?> HealthAsync()`), `Task<bool>` for writes, `Task SummarizeAsync(string sessionId)` that throws a `SummarizeDaemonFailure : Exception` (override `Message`) for a daemon refusal and an `HttpRequestException` for transport, and `void OnReconnect(Action handler)`. Represent the doubly optional session lookup as a small result type or a tuple of reachability and value, since C# has no nested optional. Implement with a single shared `HttpClient` (base address from the `STENOGRAPHER_URL` environment variable or `http://127.0.0.1:22847`), `System.Text.Json` with `JsonNamingPolicy.SnakeCaseLower` for reads and writes (use `PropertyNamingPolicy = null` for the camelCase `setAIPreferences` body), and `HttpClient.Timeout` or a `CancellationTokenSource` per request for the 10, 15 and 605 second limits. Return null on any `HttpRequestException`, non-success status or `JsonException`, with 404 on a single session as the not-found result. Drive reconnect with a `PeriodicTimer` polling `/health`, guarded by a `lock`. Register the implementation in the Windows App SDK host's `Microsoft.Extensions.DependencyInjection` container, and hold results in `ObservableCollection` with `INotifyPropertyChanged` view models. For the daemon side in ASP.NET Core, the routes are minimal API endpoints in an `IHostedService`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerDaemonService.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Unreachable reads answer nil and writes answer false or nil, instead of throwing.
**Rationale**: The type comment gives the reason: callers keep what is on screen when the daemon is down. The cost is that a caller cannot tell an unreachable daemon from a refusal or an undecodable body; only `summarize` and `actOnOversightFinding` surface a reason.
**Approved**: pending

**Decision**: `session(id:includeCounts:)` returns `SessionDTO??`.
**Rationale**: One type carries two distinct answers, unreachable (outer nil) and not found (inner nil). A port without nested optionals should use a three-case result.
**Approved**: pending

**Decision**: `summarize` throws while every other operation answers nil or false.
**Rationale**: A refusal has a reason the list can show (a memory guard, a provider error), so `SummarizeDaemonFailure` is distinct from a transport error. The act operation instead answers a result value carrying the reason.
**Approved**: pending

**Decision**: `setAIPreferences` is sent with camelCase keys while all other bodies are snake_case.
**Rationale**: The daemon's `POST /preferences/ai` decodes the registry with a default `JSONDecoder`. The wire definition is otherwise one dialect, so this is the documented exception; the implementation's comment and a test assert it.
**Approved**: pending

**Decision**: Reconnect is detected by polling `/health` and watching uptime fall, not by a push.
**Rationale**: The daemon has no push channel to a client that is not an XPC subscriber. A restart that reaches a higher uptime than the previous poll between polls is not detected; that is the cost of the approach.
**Approved**: pending

**Decision**: The default-argument overloads live in a protocol extension rather than in the requirement list.
**Rationale**: Conforming types implement only the full operations; the convenience forms (200-row limits, `includeCounts` true, nil status) stay identical everywhere and a stub cannot drift from the defaults.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.offline-behavior](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/df7f401a-39be-5c60-bab4-85dd95bd1ab1) | passed | Access Patterns |

separation-of-concerns passes: the protocol is the seam, the HTTP client is one implementation, and the windows depend only on the protocol. unit-test-coverage is partial: `StenographerHTTPClientTests` covers the unreachable path, the session query, the not-found mapping, summarize, act, delete, the preference writes and reconnect, but no test exercises the default-argument overloads, `DaemonProviderConfig` decoding or the timeout table directly, so vectors 014 to 016 follow from the source. timeout-configuration passes because each request class has a stated limit (10, 15 and 605 seconds). offline-behavior passes because an unreachable daemon yields nil or false and callers keep their current data, though there is no retry.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
