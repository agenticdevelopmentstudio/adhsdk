---
id: 96f73261-cf32-42cc-92f3-f8b58542382a
title: "Stenographer Daemon Service"
type: ingredient
version: 1.0.2
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
depends-on:
  - e8286557-84ee-4f45-b78c-f1d184c51a37
  - 25b6559b-69c1-450f-85b3-fc026d55f469
  - 7d2280c6-ae67-4ecc-9aae-dbee574b1eab
  - 1088e4ae-f6ee-4174-8ba5-a913587af3be
  - 08d59319-de4b-438a-a144-dcf3912aa2e5
  - 7a776b77-a7b2-4ed5-a26f-94795434d675
  - dc4d1700-f641-4276-8ecd-ec6790a2c894
  - b05ceb21-7c1c-4d62-83ba-01a3132df00a
  - b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43
  - eaa5d7f1-c35d-4fe6-91a0-06b6e48b8ba2
related:
  - 9c7c78d3-23ca-4ca6-a519-9968b440b8c6
references: []
approved-by: ""
approved-date: ""
---

# Stenographer Daemon Service

## Overview

`StenographerDaemonService` is the one injectable seam through which the Stenographer windows (sessions, conversations, oversight findings and scripts, the AI log, preference panes) ask the stenographer daemon for data. The production implementation is `StenographerHTTPClient` over the daemon's loopback HTTP API; tests hand the windows a stub. The file holds the protocol, the default-argument convenience overloads in a protocol extension, `SummarizeDaemonFailure` (the daemon declined to summarize and said why) and `DaemonProviderConfig` (one row of the daemon's saved provider list).

The records the operations carry are specified by the session DTOs ([adhsdk.ingredient.foundation.stenographer.session-dt-os](cookbook:25b6559b-69c1-450f-85b3-fc026d55f469)), the oversight finding DTO ([adhsdk.ingredient.foundation.stenographer.oversight-finding-dto](cookbook:7d2280c6-ae67-4ecc-9aae-dbee574b1eab)), the oversight script DTO ([adhsdk.ingredient.foundation.stenographer.oversight-script-dto](cookbook:1088e4ae-f6ee-4174-8ba5-a913587af3be)), the conversation entry DTO ([adhsdk.ingredient.foundation.stenographer.conversation-entry-dto](cookbook:08d59319-de4b-438a-a144-dcf3912aa2e5)), the AI interaction DTO ([adhsdk.ingredient.foundation.stenographer.ai-interaction-dto](cookbook:7a776b77-a7b2-4ed5-a26f-94795434d675)), the oversight action DTOs ([adhsdk.ingredient.foundation.stenographer.oversight-action-dt-os](cookbook:dc4d1700-f641-4276-8ecd-ec6790a2c894)), the preference DTOs ([adhsdk.ingredient.foundation.stenographer.stenographer-preference-dt-os](cookbook:eaa5d7f1-c35d-4fe6-91a0-06b6e48b8ba2)) and the AI provider config sync ([adhsdk.ingredient.foundation.stenographer.ai-provider-config-sync](cookbook:b05ceb21-7c1c-4d62-83ba-01a3132df00a)). The wire spelling comes from the stenographer wire spec ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37)) and the base URL constant from the stenographer identifiers ([adhsdk.ingredient.foundation.stenographer.stenographer-identifiers](cookbook:b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43)). The HTTP implementation is also specified by its own ingredient ([adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6)); the `impl-*` requirements below describe it from this protocol's side.

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
- **op-ai-interactions**: `aiInteractions(limit:)` MUST answer `[AIInteractionDTO]?`.
- **op-ai-interaction**: `aiInteraction(id:)` MUST answer one `AIInteractionDTO?` by Int id.
- **op-provider-configs**: `aiProviderConfigs()` MUST answer `[DaemonProviderConfig]?`, the daemon's saved LLM provider configurations (what Stenographer's LLM Providers pane pushed), for the pickers in the preference panes.
- **op-summary-preferences-read**: `summaryPreferences()` MUST answer `SummaryPreferenceResponse?`.
- **op-oversight-preferences-read**: `oversightPreferences()` MUST answer `OversightPreferenceResponse?`.
- **op-summary-preferences-write**: `setSummaryPreferences(_:)` MUST answer a Bool for a `SummaryPreferenceRequest`.
- **op-oversight-preferences-write**: `setOversightPreferences(_:)` MUST answer a Bool for an `OversightPreferenceRequest`.
- **op-set-ai-preferences**: `setAIPreferences(_:)` MUST replace the daemon's LLM provider registry with the given `AIProviderConfigSync` (the whole set plus the active selection) and answer true when the daemon took it.
- **since-hours-nonpositive-omitted**: A `sinceHours` of 0 or less MUST send no `since_hours` query item (no age filter); only a positive value is sent.
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
- **failure-distinct**: It MUST be distinct from a transport failure so the list can show the daemon's reason.

**DaemonProviderConfig**

- **config-shape**: `DaemonProviderConfig` MUST be a `Codable`, `Sendable`, `Equatable` and `Identifiable` struct with `id` (UUID), `name`, `pluginIdentifier` and `templateId` (String), and a public initializer taking all four.
- **config-no-secrets**: `DaemonProviderConfig` MUST NOT carry secrets or a model; those are the daemon's own.
- **config-wire-keys**: Through the stenographer wire spelling `DaemonProviderConfig` MUST use the keys `id`, `name`, `plugin_identifier` and `template_id`; the type is one row of `GET /preferences/ai/configs`.

**Production implementation notes (StenographerHTTPClient)**

- **impl-wire-spelling**: The HTTP implementation MUST send and read JSON in the shared wire spelling (snake_case keys, ISO-8601 dates) over the daemon's loopback API, with the base URL taken from the `STENOGRAPHER_URL` environment variable when it is a valid URL and the stenographer HTTP base URL constant otherwise.
- **impl-unreachable-mapping**: A failed connection, a non-2xx reply or a body that does not decode MUST all read as unreachable (nil or false); the one exception is a 404 on a single session, which answers inner nil (no such session).
- **impl-summarize-errors**: `summarize` MUST throw a URL error `cannotConnectToHost` when no reply arrives, which includes the 605-second timeout expiring (the transport's own timeout error is discarded, so a timeout reads exactly like an unreachable daemon), and `SummarizeDaemonFailure` with the daemon's `error` message, or `HTTP <status>` when the body has none, on a non-2xx reply.
- **impl-act-result**: `actOnOversightFinding` MUST answer a succeeded result with status from the decoded finding, or `acted` when the body does not decode, on a 2xx reply, and a failed result carrying the daemon's error message or `HTTP <status>` otherwise.
- **impl-ai-prefs-camelcase**: `setAIPreferences` MUST be sent with a plain encoder (camelCase keys), not the wire encoder, because the daemon's `POST /preferences/ai` decodes the registry with a default decoder. This is the one write that differs from the others' snake_case body.
- **impl-timeouts**: Request timeouts MUST be 605 seconds for a POST ending in `/summarize` (a summary runs inline on the daemon for up to the user's largest give-up time of 600 seconds, plus 5), 15 seconds for GET `/conversations` and the AI interaction reads, and 10 seconds for everything else.
- **reconnect-strictly-lower**: A reconnect MUST fire only when a `/health` poll reports an `uptime` strictly lower than the previous successful poll's; an equal or higher uptime, the first successful poll and a failed poll fire nothing.
- **poll-starts-once**: The health polling task MUST start on the first `onReconnect` registration only; later registrations add handlers without starting another task.
- **encoders-not-unified**: `setSummaryPreferences` and `setOversightPreferences` MUST use the snake_case wire encoder and `setAIPreferences` MUST use a plain (camelCase) encoder; an implementation MUST NOT unify them.
- **impl-reconnect-poll**: The reconnect signal MUST come from polling `/health` (every 30 seconds by default) and treating an `uptime` that went down as a restart, firing every registered handler once; the daemon has no push channel to a client that is not an XPC subscriber.
- **impl-no-retry**: The implementation MUST NOT retry, back off, send an authentication header or offer cancellation beyond the polling task's own, and MUST send each request once.

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
| daemon-service-002 | op-sessions, since-hours-nonpositive-omitted | Call `sessions(status: "active")` (StenographerHTTPClientTests `testSessionsBuildsQueryAndDecodes`) | The request carries `status=active`; the body decodes into `[SessionDTO]` |
| daemon-service-003 | session-doubly-optional, impl-unreachable-mapping | The daemon answers 404 for `GET /sessions/<id>` (`testSessionNotFoundIsInnerNil`) | `session(id:)` answers the inner nil (not found), not the outer nil |
| daemon-service-004 | session-doubly-optional | No daemon reachable (no test of its own) | `session(id:)` answers the outer nil |
| daemon-service-005 | op-summarize, failure-distinct | The daemon answers 500 with `{"error": "Summarize failed: model too large"}` (`testSummarizeThrowsDaemonReason`) | `summarize` throws `SummarizeDaemonFailure` whose `reason` is `Summarize failed: model too large`, and its `errorDescription` is that text |
| daemon-service-006 | op-summarize, impl-summarize-errors | No reply from the daemon (no test of its own) | `summarize` throws a URL error with code `cannotConnectToHost` |
| daemon-service-007 | op-act-on-finding, impl-act-result | The daemon answers 409 to the act route (`testActOnFindingMapsConflictToFailure`) | A result with `succeeded` false and the daemon's error text as `reason` |
| daemon-service-008 | impl-act-result | The daemon answers 200 with a finding body whose status is `acted` (`testActOnFindingSuccess`) | `succeeded` true and `status` `acted` |
| daemon-service-009 | op-delete-script | The daemon answers 204 to the delete route (`testDeleteScriptIs204`) | `deleteOversightScript(id:)` answers true |
| daemon-service-010 | op-summary-preferences-write, impl-wire-spelling, encoders-not-unified | `setSummaryPreferences` with a request (`testSetSummaryPreferencesPostsSnakeCase`) | The posted body has snake_case keys |
| daemon-service-011 | op-set-ai-preferences, impl-ai-prefs-camelcase, encoders-not-unified | `setAIPreferences` with a config set (`testSetAIPreferencesPostsTheRegistryAsCamelCase`) | The posted body has camelCase keys and the call answers true on a 2xx |
| daemon-service-012 | writes-false-or-nil-when-unreachable | `setAIPreferences` against an error status and against no daemon (`testSetAIPreferencesIsFalseOnAnErrorStatusOrNoDaemon`) | Both answer false |
| daemon-service-013 | op-on-reconnect, impl-reconnect-poll, reconnect-strictly-lower, poll-starts-once | Health polls report uptimes 500, 600, 3, 10 (`testReconnectFiresWhenUptimeDrops`) | The registered handler fires when the uptime falls from 600 to 3 |
| daemon-service-014 | default-conversations, default-ai-interactions | Call `conversations()` and `aiInteractions()` (no test of its own) | They call the full operations with limit 200, includeWorkOutput false, before nil, sessionId nil, and limit 200 |
| daemon-service-015 | impl-timeouts | Timeout for POST `/sessions/x/summarize`, GET `/conversations`, GET `/ai/interactions/3`, GET `/health` (no test of its own) | 605, 15, 15 and 10 seconds |
| daemon-service-016 | config-wire-keys | (no test of its own) Decode `{"id":"<uuid>","name":"n","plugin_identifier":"p","template_id":"t"}` with the wire decoder | A `DaemonProviderConfig` with those four values |
| daemon-service-017 | impl-summarize-errors | The summarize request exceeds its 605-second timeout so the transport throws (no test of its own) | `summarize` throws a URL error with code `cannotConnectToHost`, the same as for no reply |
| daemon-service-018 | impl-act-result | The daemon answers 200 to the act route with a body that does not decode as a finding (no test of its own) | `succeeded` true and `status` `acted` from the fallback |
| daemon-service-019 | default-sessions | Call `sessions()` with no arguments (no test of its own) | The full operation runs with status nil, project nil, sinceHours 0 and includeCounts true |
| daemon-service-020 | since-hours-nonpositive-omitted | Call `sessions` with `sinceHours` 0 and then 6 | The first request has no `since_hours` item; the second carries `since_hours=6` |
## Edge Cases

- **Null and empty input**: Optional filters (`status`, `project`, `before`, `sessionId`) MAY be nil and are then omitted from the request. `sinceHours` of 0 or less sends no age filter (since-hours-nonpositive-omitted). A `limit` is sent as given with no clamping. An empty list reply is a real answer (empty array), distinct from nil.
- **Boundary values**: The default limits are 200 for conversations and AI interactions. A reconnect needs a strictly lower uptime than the previous poll (reconnect-strictly-lower); an equal or higher uptime fires nothing.
- **Concurrent access**: The protocol is `Sendable`. The HTTP implementation guards its handler list, last uptime and polling task with a lock and is `@unchecked Sendable`; the polling task starts on the first handler registration and only once (poll-starts-once). Handlers run outside the lock on the polling task and are `@Sendable`. Concurrent requests are independent; the implementation serializes nothing else.
- **Error states**: A transport failure, non-2xx status or undecodable body is indistinguishable to the caller of a read (all nil). Writes that return a value are nil in the same cases. Only `summarize` and `actOnOversightFinding` surface a daemon reason. The decode error itself is discarded by the implementation (a `try?`), which is deliberate and documented in the type comment.
- **Offline or disconnected state**: With no daemon, every read is nil and every write false or nil; callers keep what is on screen. There is no retry or backoff; the next user action or refresh is the retry. Reconnect detection resumes when `/health` answers again.
- **Daemon restart mid-session**: A drop in `/health` uptime fires the reconnect handlers once so preference pushes re-send their snapshot; the first successful poll ever only records the baseline, and a failed poll leaves the last recorded uptime in place, so the first success after a gap is compared with the uptime from before it.
- **Slow summaries**: A summary runs inline on the daemon for up to 600 seconds; the client waits up to 605 seconds, then the call throws `cannotConnectToHost`, the same error as for no reply (impl-summarize-errors).
- **Preference encoding split**: The two other preference writes (`setSummaryPreferences` and `setOversightPreferences`) use the snake_case wire encoder and `setAIPreferences` uses camelCase; a port that unifies them breaks the daemon's decoding of the registry (encoders-not-unified).
- **Account of what a caller cannot tell**: A 4xx that is not 404 for a session reads as unreachable; the caller cannot distinguish "unreachable" from "daemon refused".

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `STENOGRAPHER_URL` | environment variable | unset | Overrides the daemon base URL when it parses as a URL. |
| stenographer HTTP base URL | URL constant | `http://127.0.0.1:22847` | The loopback address used when the variable is unset or invalid. |
| `healthPollInterval` | seconds | 30 | How often the implementation polls `/health` for restarts. |
| `session` | `URLSession` | `.shared` | The injected transport of the HTTP implementation. |

Request timeouts (10, 15 and 605 seconds, see impl-timeouts) are fixed in the implementation and are not configurable.
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
- **AppKit / UIKit**: The protocol is `Sendable` and the windows (sessions, oversight, AI log and the provider pickers) take it by initializer, with `StenographerHTTPClient` as production and a stub in tests. `onReconnect` takes an escaping `@Sendable` closure.
- **WinUI 3**: Define `IStenographerDaemonService` in C# with `Task<T?>` returns for reads and for writes that return a value (`Task<HealthDto?> HealthAsync()`, `Task<OversightScript?> SaveOversightScriptAsync(OversightScript script)`), `Task<bool>` only for the writes that return a Bool, `Task SummarizeAsync(string sessionId)` that throws a `SummarizeDaemonFailure : Exception` (override `Message`) for a daemon refusal and an `HttpRequestException` for transport, and `void OnReconnect(Action handler)`. Represent the doubly optional session lookup as a small result type or a tuple of reachability and value, since C# has no nested optional. Implement with a single shared `HttpClient` (base address from the `STENOGRAPHER_URL` environment variable or `http://127.0.0.1:22847`), `System.Text.Json` with `JsonNamingPolicy.SnakeCaseLower` for reads and writes (use `PropertyNamingPolicy = null` for the camelCase `setAIPreferences` body), and `HttpClient.Timeout` or a `CancellationTokenSource` per request for the 10, 15 and 605 second limits. Return null on any `HttpRequestException`, non-success status or `JsonException`, with 404 on a single session as the not-found result. Drive reconnect with a `PeriodicTimer` polling `/health`, guarded by a `lock`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerDaemonService.swift` | confirmed (1.0.2) |
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
**Rationale**: A refusal has a reason the list can show (a memory guard, a provider error), so `SummarizeDaemonFailure` is distinct from a transport error. The act operation instead answers a result value carrying the reason. Examples of a reason from the source documentation are a memory guard or a provider error.
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

**Decision**: The implementation discards decode errors and non-2xx statuses and writes no log or signpost when it maps them to nil or false.
**Rationale**: The source has no logging in the protocol or the HTTP implementation, and the type comment documents the collapse to "unreachable" as deliberate. The cost is that schema drift between client and daemon looks exactly like a daemon that is down, with no trace anywhere; only `summarize` and `actOnOversightFinding` surface a reason. A port that wants diagnosability can log at debug level without changing any contract here.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.offline-behavior](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/df7f401a-39be-5c60-bab4-85dd95bd1ab1) | passed | Access Patterns |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |
| [adc.check.security.secure-authentication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1d5c23d5-9a26-57fb-a23d-358271e4204a) | failed | Security |

separation-of-concerns passes: the protocol is the seam, the HTTP client is one implementation, and the windows depend only on the protocol. unit-test-coverage passes: `StenographerHTTPClientTests` and `DaemonServiceConformanceTests.swift` between them cover every vector, including the default-argument overloads, `DaemonProviderConfig` decoding, the timeout table and the summarize and unreachable paths. timeout-configuration passes because each request class has a stated limit (10, 15 and 605 seconds). offline-behavior passes because an unreachable daemon yields nil or false and callers keep their current data, though there is no retry. secure-transport is partial because traffic is plain HTTP, acceptable only on the loopback address, and `STENOGRAPHER_URL` can point the client at any address. secure-authentication is marked failed because the client sends no authentication header and `setAIPreferences` replaces the daemon's provider registry over that unauthenticated loopback endpoint, so any local process can call it; that is a known and accepted limit of the loopback design (see impl-no-retry), not a defect in the protocol contract.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (DaemonServiceConformanceTests.swift, 9 new vectors; the other 11 already covered by StenographerHTTPClientTests, 20 of 20 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Requirements given RFC keywords and split one per operation, four named requirements added for since-hours, reconnect, polling start and encoder split, vectors cite them and new vectors cover timeout, act fallback and defaults, silent-failure cost recorded as a pending Design Decision, configuration timeouts row dropped, WinUI 3 note made concrete, security compliance rows added, and depends-on and related linked. |
