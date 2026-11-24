---
id: 9c7c78d3-23ca-4ca6-a519-9968b440b8c6
title: "Stenographer HTTP Client"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The loopback HTTP implementation of the Stenographer daemon service: one route per call, failures read as nil or false, and a health poll that detects daemon restarts."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - http-client
  - daemon
depends-on:
  - 96f73261-cf32-42cc-92f3-f8b58542382a
  - e8286557-84ee-4f45-b78c-f1d184c51a37
  - b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43
related:
  - 25b6559b-69c1-450f-85b3-fc026d55f469
  - 7d2280c6-ae67-4ecc-9aae-dbee574b1eab
  - 1088e4ae-f6ee-4174-8ba5-a913587af3be
  - 703b9227-1bed-46ae-91f8-353c5908883d
  - 844fde57-2231-4516-bcc9-a93c56d74a2d
references: []
approved-by: ""
approved-date: ""
---

# Stenographer HTTP Client

## Overview

`StenographerHTTPClient` is the implementation of the `StenographerDaemonService` protocol ([adhsdk.ingredient.foundation.stenographer.stenographer-daemon-service](cookbook:96f73261-cf32-42cc-92f3-f8b58542382a)) that talks to the Stenographer daemon over its loopback HTTP API. It uses the same routes the `steno` command-line tool uses. Every request and reply is JSON in the `StenographerWire` spelling ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37): snake_case keys, ISO-8601 dates), with one deliberate exception for the provider registry push.

The source is `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerHTTPClient.swift`, a `public final class` that is `@unchecked Sendable` and guards its mutable state with an `NSLock`. The default base URL comes from `StenographerIdentifiers` ([adhsdk.ingredient.foundation.stenographer.stenographer-identifiers](cookbook:b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43)).

The client is built for callers that must keep working when the daemon is down. A refused connection, a non-2xx status or a body that does not decode all read the same way: `nil` for a read, `false` for a write. The one exception is a 404 on a single session, which is a real answer ("no such session"). Summarizing a session is the other exception: it throws, so the daemon's own reason can reach the user.

The daemon has no push channel to a client that is not an XPC subscriber, so the client also offers `onReconnect`: it polls `/health` and treats an `uptime` that went down as a daemon restart.

## Behavioral Requirements

- **default-base-url**: `StenographerHTTPClient.defaultBaseURL` MUST be the URL parsed from the `STENOGRAPHER_URL` environment variable when it is set and parses as a URL, and otherwise `StenographerIdentifiers.httpBaseURL` (`http://127.0.0.1:22847`).
- **init-parameters**: `init(baseURL:session:healthPollInterval:)` MUST default `baseURL` to `defaultBaseURL`, `session` to `URLSession.shared` and `healthPollInterval` to 30 seconds.
- **wire-coding**: The client MUST encode request bodies and decode replies with `StenographerWire.encoder()` and `StenographerWire.decoder()`.
- **nil-on-failure**: Every read that returns an optional MUST return `nil` when the connection fails, when the status is outside 200 to 299, or when the body does not decode as the expected type.
- **false-on-failure**: Every write that returns `Bool` MUST return `false` when the connection fails, when the body cannot be encoded, or (for the writes that read a status or a reply) when the status is outside 200 to 299 or the reply does not decode.
- **health-route**: `health()` MUST send `GET /health` and return a decoded `HealthDTO`.
- **sessions-query**: `sessions(status:project:sinceHours:includeCounts:)` MUST send `GET /sessions` with `status` only when non-nil, `project` only when non-nil, `since_hours` only when `sinceHours` is greater than 0, and `counts=false` only when `includeCounts` is false.
- **session-detail**: `session(id:includeCounts:)` MUST send `GET /sessions/<id>`, adding `counts=false` when `includeCounts` is false, and return the `session` of the decoded `SessionDetailDTO` wrapped in `.some`.
- **session-not-found**: `session(id:includeCounts:)` MUST return `.some(nil)` (the inner value nil) for a 404 reply, and the outer `nil` for an unreachable daemon, a non-2xx status other than 404, or an undecodable body.
- **summarize-route**: `summarize(sessionId:)` MUST send `POST /sessions/<id>/summarize` with an empty body.
- **summarize-transport-error**: `summarize(sessionId:)` MUST throw `URLError(.cannotConnectToHost)` when the request produces no reply.
- **summarize-daemon-failure**: `summarize(sessionId:)` MUST throw `SummarizeDaemonFailure` for a status outside 200 to 299, with `reason` set to the `error` field of the reply body, or `HTTP <status>` when the body has no such field.
- **conversations-query**: `conversations(limit:includeWorkOutput:before:sessionId:)` MUST send `GET /conversations` with `limit` always, `work=true` only when `includeWorkOutput` is true, `before` only when non-nil and `session_id` only when non-nil.
- **oversight-findings-query**: `oversightFindings(status:)` MUST send `GET /oversight/findings`, adding `status` only when non-nil.
- **oversight-action-target**: `oversightActionTarget(findingId:)` MUST send `GET /oversight/findings/<findingId>/action`.
- **act-on-finding-route**: `actOnOversightFinding(findingId:)` MUST send `POST /oversight/findings/<findingId>/act` with an empty body.
- **act-on-finding-success**: `actOnOversightFinding(findingId:)` MUST return an `OversightActResultDTO` with `succeeded` true, an empty `reason`, and `status` taken from the decoded `OversightFindingDTO` of the reply, or `acted` when that body does not decode, for any 2xx status.
- **act-on-finding-failure**: `actOnOversightFinding(findingId:)` MUST return an `OversightActResultDTO` with `succeeded` false, an empty `status` and `reason` set to the `error` field of the reply body (or `HTTP <status>`) for a non-2xx status.
- **act-on-finding-unreachable**: `actOnOversightFinding(findingId:)` MUST return `nil` when the request produces no reply.
- **oversight-scripts-read**: `oversightScripts()` MUST send `GET /oversight/scripts`.
- **save-oversight-script**: `saveOversightScript(_:)` MUST send `POST /oversight/scripts/<script.id>` with the script encoded in wire spelling, return `nil` when encoding fails, and otherwise return the decoded reply.
- **delete-oversight-script**: `deleteOversightScript(id:)` MUST send `POST /oversight/scripts/<id>/delete` with an empty body and return true for any 2xx status (including 204 with no body).
- **reset-oversight-script**: `resetOversightScript(id:)` MUST send `POST /oversight/scripts/<id>/reset` with an empty body and return the decoded `OversightScript`.
- **ai-interactions-read**: `aiInteractions(limit:)` MUST send `GET /ai/interactions` with `limit`, and `aiInteraction(id:)` MUST send `GET /ai/interactions/<id>`.
- **preference-reads**: `aiProviderConfigs()` MUST send `GET /preferences/ai/configs`, `summaryPreferences()` MUST send `GET /preferences/summaries` and `oversightPreferences()` MUST send `GET /preferences/oversight`.
- **set-preferences-wire**: `setSummaryPreferences(_:)` and `setOversightPreferences(_:)` MUST send `POST /preferences/summaries` and `POST /preferences/oversight` with the request encoded in wire spelling, and return true only when the reply decodes as the matching response type.
- **set-ai-preferences-plain-encoder**: `setAIPreferences(_:)` MUST encode the `AIProviderConfigSync` with a default `JSONEncoder`, so its keys stay camelCase, because `POST /preferences/ai` decodes the registry with a default `JSONDecoder`.
- **set-ai-preferences-status**: `setAIPreferences(_:)` MUST return true for any 2xx status regardless of the reply body, and false for a non-2xx status or no reply.
- **url-construction**: Every request MUST be built by replacing the path of `baseURL` with the route path and setting the query items only when the list is non-empty; a URL that cannot be formed MUST read as an unreachable daemon.
- **json-content-type**: A request that carries a body (including the empty body of the action routes) MUST set `Content-Type: application/json`, and a request without a body MUST NOT set it.
- **timeouts**: `timeout(method:path:)` MUST return 605 seconds for a `POST` whose path ends in `/summarize`, 15 seconds for a `GET` of `/conversations`, `/ai/interactions` or a path starting `/ai/interactions/`, and 10 seconds for every other request.
- **error-body-format**: The failure reason MUST be read from a reply body shaped `{"error": "..."}`, the body DaemonKit's `HTTPResponse.error` produces; any other body yields no reason.
- **reconnect-registration**: `onReconnect(_:)` MUST append the handler to the registered list and start the health poll only when no poll is running.
- **reconnect-detection**: Each poll MUST call `health()`, record the returned `uptime`, and call every registered handler once when the new `uptime` is lower than the previously recorded one.
- **reconnect-first-poll**: The first successful poll MUST NOT call any handler, because there is no earlier `uptime` to compare with.
- **reconnect-failed-poll**: A poll whose `health()` returns `nil` MUST NOT change the recorded `uptime` and MUST NOT call any handler.
- **reconnect-interval**: The poll MUST run immediately when started and then wait `healthPollInterval` seconds between polls until the task is cancelled or the client is released.
- **reconnect-lifetime**: The poll task MUST hold the client weakly and stop when the client is released, and `deinit` MUST cancel the stored task.
- **handlers-outside-lock**: Handlers MUST be called after the lock is released, so a handler may call back into the client.
- **reconnect-start-race**: NEEDS REVIEW: Not implemented in source. `onReconnect` decides under the lock whether to start a poll and stores `healthTask` under a second, separate acquisition, so two concurrent first registrations can each see no running poll and each start one, leaving one task unreferenced by `healthTask`; evidence that would settle it is a decision on whether the second registration must wait for the first task to be stored, plus a concurrent-registration test.
- **sendability**: The class is declared `@unchecked Sendable`; the handler list, the last recorded `uptime` and the task reference MUST only be read or written while holding the `NSLock`. The decision to start a poll and the store of `healthTask` are two separate acquisitions, which is the gap described in `reconnect-start-race`.
- **no-retry**: The client MUST NOT retry a failed request, and MUST NOT send an idempotency key; each call sends exactly one request, and the daemon's reply surfaces unchanged.

## Appearance

Not applicable — this is a network client, not a visual component.

## States

Not applicable — this is a network client, not a visual component.

## Accessibility

Not applicable — this is a network client, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stenographer-http-client-001 | nil-on-failure, false-on-failure | No stub handler, so the connection fails. Call `sessions(status: nil, project: nil, sinceHours: 24, includeCounts: false)`, `oversightFindings()` and `setSummaryPreferences(SummaryPreferenceRequest(enabled: true))`. | `nil`, `nil` and `false` (test: testUnreachableDaemonReturnsNil). |
| stenographer-http-client-002 | sessions-query, wire-coding | Reply 200 with one snake_case session; call `sessions(status: "active", project: nil, sinceHours: 24, includeCounts: false)`. | Path is `/sessions`; query contains `status=active`, `since_hours=24` and `counts=false`; no `project`; the result has session id `s1` (test: testSessionsBuildsQueryAndDecodes). |
| stenographer-http-client-003 | session-not-found | Reply 404 with `{"error":"Session not found: zz"}`; call `session(id: "zz", includeCounts: false)`. | The outer value is non-nil and the inner value is nil (test: testSessionNotFoundIsInnerNil). |
| stenographer-http-client-004 | summarize-daemon-failure | Reply 500 with `{"error":"Summarize failed: model too large"}`; call `summarize(sessionId: "s1")`. | Throws `SummarizeDaemonFailure` with `reason` `Summarize failed: model too large` (test: testSummarizeThrowsDaemonReason). |
| stenographer-http-client-005 | act-on-finding-failure | Reply 409 with `{"error":"Finding is already acted"}`; call `actOnOversightFinding(findingId: 7)`. | `succeeded` false and `reason` `Finding is already acted` (test: testActOnFindingMapsConflictToFailure). |
| stenographer-http-client-006 | act-on-finding-success | Reply 200 with a finding whose `status` is `acted`; call `actOnOversightFinding(findingId: 7)`. | `succeeded` true and `status` `acted` (test: testActOnFindingSuccess). |
| stenographer-http-client-007 | delete-oversight-script | Reply 204 with no body; call `deleteOversightScript(id: "abc")`. | The request is `POST /oversight/scripts/abc/delete`; the result is true (test: testDeleteScriptIs204). |
| stenographer-http-client-008 | set-preferences-wire | Reply 200 with a snake_case summary preference body; call `setSummaryPreferences(SummaryPreferenceRequest(enabled: false, selectedConfigId: "c"))`. | Result true; path `/preferences/summaries`; the posted body has `enabled` false and `selected_config_id` `c` (test: testSetSummaryPreferencesPostsSnakeCase). |
| stenographer-http-client-009 | set-ai-preferences-plain-encoder | Reply 200 with `{}`; call `setAIPreferences` with a registry whose selection is a UUID. | Result true; path `/preferences/ai`; the posted body key is `selectedConfigId` (camelCase) and decodes back to the same `AIProviderConfigSync` with a default `JSONDecoder` (test: testSetAIPreferencesPostsTheRegistryAsCamelCase). |
| stenographer-http-client-010 | set-ai-preferences-status | Reply 400 with `{}`, then no daemon. | `setAIPreferences` returns false both times (test: testSetAIPreferencesIsFalseOnAnErrorStatusOrNoDaemon). |
| stenographer-http-client-011 | reconnect-detection, reconnect-interval | `/health` replies with `uptime` 500, 600, 3, 10 in turn; client with a 0.05 second interval; `onReconnect` registered. | The handler fires exactly once, after the drop from 600 to 3, and does not fire on the 500 to 600 step or the 3 to 10 step (test: testReconnectFiresWhenUptimeDrops). |
| stenographer-http-client-012 | timeouts | `timeout(method: "POST", path: "/sessions/s1/summarize")` | 605 (derived from the source; no test). |
| stenographer-http-client-013 | timeouts | `timeout(method: "GET", path: "/conversations")`, `timeout(method: "GET", path: "/ai/interactions/5")`, `timeout(method: "POST", path: "/ai/interactions")`, `timeout(method: "GET", path: "/health")` | 15, 15, 10, 10 (derived from the source; no test). |
| stenographer-http-client-014 | summarize-daemon-failure | Reply 500 with a body that is not JSON; call `summarize(sessionId: "s1")`. | Throws `SummarizeDaemonFailure` with `reason` `HTTP 500` (derived from the source; no test). |
| stenographer-http-client-015 | summarize-transport-error | No daemon; call `summarize(sessionId: "s1")`. | Throws `URLError` with code `cannotConnectToHost` (derived from the source; no test). |
| stenographer-http-client-016 | reconnect-first-poll, reconnect-failed-poll | `/health` replies with a steady `uptime` of 500, or fails. | No handler fires (derived from the source; no test). |
| stenographer-http-client-017 | default-base-url | `STENOGRAPHER_URL` set to `http://localhost:9999`; read `defaultBaseURL`. Then unset it and read again. | `http://localhost:9999`, then `http://127.0.0.1:22847` (derived from the source; no test). |
| stenographer-http-client-018 | url-construction | Client with base URL `http://127.0.0.1:22847/ignored`; call `session(id: "s1", includeCounts: true)`. | The request URL is `http://127.0.0.1:22847/sessions/s1` with no query string (derived from the source; no test). |
| stenographer-http-client-019 | json-content-type | Call `actOnOversightFinding(findingId: 7)` and `health()`, and inspect each request. | The first request has `Content-Type: application/json`; the second has none (derived from the source; no test). |
| stenographer-http-client-020 | act-on-finding-unreachable | No daemon; call `actOnOversightFinding(findingId: 7)`. | `nil` (derived from the source; no test). |
## Edge Cases

- **Null / empty input**: A nil `status` or `project` filter on `sessions`, a nil `before` or `sessionId` on `conversations`, and a nil `status` on `oversightFindings` each add no query item (the client MUST omit it). `sinceHours` of 0 or less adds no `since_hours` item. The empty `Data()` body on the action routes is sent with a JSON content type. A reply body that is empty on a 2xx read does not decode and reads as `nil`.
- **Boundary values**: `limit` is sent as given with no clamp; the daemon owns any ceiling. The summarize timeout is 605 seconds because the daemon may summarize inline for up to the user's largest "Give up after" of 600 seconds, plus 5 seconds (per the source comment). The heavy reads (the conversations list and the AI interaction reads) get 15 seconds because they can be slow on a cold cache.
- **Concurrent access**: Requests carry no shared state beyond the immutable encoder, decoder and session, so they may run in parallel (the client MAY be called from any task). The reconnect state is guarded by the lock; the race in the open question on `reconnect-start-race` is the one unordered case.
- **Error states**: A non-2xx status, an undecodable body and a refused connection are indistinguishable to the caller of a read (they all return `nil`); the client logs nothing. `summarize` and `actOnOversightFinding` are the two calls that carry the daemon's `error` text. A 2xx reply with a body that fails to decode is `nil` for a read, `acted` for an action, and true for `deleteOversightScript` and `setAIPreferences`.
- **Offline / disconnected state**: While the daemon is down every read is `nil` and every write is `false`, and each call waits up to its timeout (10, 15 or 605 seconds) before failing; a refused loopback connection normally fails sooner. When the daemon comes back with a lower `uptime`, the registered handlers fire on the next poll, so up to `healthPollInterval` seconds pass before the client notices. A restart that is not observed by a successful poll before `uptime` climbs past its old value goes undetected.
- **Path building**: Ids are placed into the route path as given. The client does not validate them, and it relies on `URLComponents` to encode characters that are illegal in a path.
- **Remote base URL**: `STENOGRAPHER_URL` can name any host, and the client does not check that the host is loopback or that the scheme is secure. `setAIPreferences` posts the provider registry, including its secrets, to whatever base URL is set, in clear text when the scheme is `http`. The source does not refuse a non-loopback URL.
- **Cancellation**: The calls do not check for cancellation themselves; cancelling the calling task cancels the underlying `URLSession` request. The poll loop stops when its task is cancelled or the client is released.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `STENOGRAPHER_URL` | environment variable | unset | Overrides the default base URL when it parses as a URL. |
| `baseURL` | `URL` | `defaultBaseURL` | Daemon address; the default is `StenographerIdentifiers.httpBaseURL`. |
| `session` | `URLSession` | `.shared` | Injected for tests with a stub protocol. |
| `healthPollInterval` | `TimeInterval` | 30 | Seconds between health polls once `onReconnect` has been called. |

## Deep Linking

Not applicable: the client addresses the daemon's HTTP routes, not navigation destinations.

## Localization

Not applicable: the client defines no user-facing string of its own. The only text it produces is the fallback `reason` `HTTP <status>` carried in `SummarizeDaemonFailure` and `OversightActResultDTO`, which is an English diagnostic and not a localized string; every other message is the daemon's own text passed through.

## Accessibility Options

Not applicable: the client presents no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Session metadata, conversation entries, AI interaction records and provider settings, all read from the local daemon. `setAIPreferences` posts the provider registry, which per its test includes provider `secrets` such as an API key.
- **Storage**: None; the client keeps only the reconnect handlers, the last `uptime` and the poll task in memory.
- **Transmission**: Plain HTTP to the loopback address `127.0.0.1` by default; nothing leaves the machine unless `STENOGRAPHER_URL` points elsewhere, and the client adds no authentication header.
- **Retention**: Not applicable: no data is kept after a call returns.

## Logging

Not applicable: the client calls no logging API; every failure is returned as `nil`, `false` or a thrown error.

## Platform Notes

- **SwiftUI**: Call the client from a view model with `async` functions: `await` each call off the main actor, publish the result on the main actor, and treat `nil` or `false` as "daemon unreachable" so the view shows an offline state instead of an error alert.
- **Compose**: Use OkHttp or Ktor with kotlinx.serialization and `JsonNamingStrategy.SnakeCase`, a `suspend` function per route returning a nullable type, and a coroutine in a `CoroutineScope` for the health poll. Per-request timeouts map to `OkHttpClient.newBuilder().callTimeout(...)`.
- **React/Web**: Use `fetch` with `AbortSignal.timeout(ms)` per request, convert keys between camelCase and snake_case in one place, and run the poll with `setInterval` (single-threaded, so the start race does not occur). A browser cannot reach the daemon unless the daemon allows the origin.
- **AppKit / UIKit**: Use the same `Foundation` client from an AppKit controller or a UIKit view controller, and update the UI on the main thread after each await. The `STENOGRAPHER_URL` variable is read from the process environment, which a sandboxed macOS app may not receive from the shell; iOS has no local daemon, so the client has no use there.
- **WinUI 3**: Use `System.Net.Http.HttpClient` (one shared instance) with a `CancellationTokenSource` timeout per call, and `System.Text.Json` with `JsonNamingPolicy.SnakeCaseLower` (and a converter for ISO-8601 dates). Return `Task<T?>` for reads and `Task<bool>` for writes, and throw a custom exception type for the summarize failure. Run the health poll with a `PeriodicTimer` in a `Task` that is cancelled on dispose, guard the handler list with a `lock`, read the base URL with `Environment.GetEnvironmentVariable`, and keep the `HttpClient` timeout infinite so the per-request 10, 15 and 605 second limits apply.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerHTTPClient.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Failures read as `nil` or `false` rather than throwing, with `summarize` as the exception.
**Rationale**: The source comment states the aim: a failed connection, a non-2xx reply or an undecodable body all mean "unreachable", so callers handle one case. `summarize` throws so the daemon's reason (a memory guard, a provider error) reaches the user instead of a generic failure.
**Approved**: pending

**Decision**: A 404 on a single session is `.some(nil)`, a real answer, not unreachable.
**Rationale**: The source comment names it as the one exception; callers need to tell "no such session" from "daemon down".
**Approved**: pending

**Decision**: `setAIPreferences` uses a default `JSONEncoder` instead of the wire encoder.
**Rationale**: The source comment states that `POST /preferences/ai` decodes the registry with a default `JSONDecoder`, so its keys stay camelCase.
**Approved**: pending

**Decision**: Timeouts are 605, 15 and 10 seconds by route.
**Rationale**: The source comment gives the reasons: a summary runs inline on the daemon for up to 600 seconds plus 5, the heavy reads can be slow on a cold cache, and everything else is a quick read.
**Approved**: pending

**Decision**: Reconnect is detected by an `uptime` that went down, polled every 30 seconds.
**Rationale**: The source comment states the daemon has no push channel to a client that is not an XPC subscriber, so polling `/health` is the only signal.
**Approved**: pending

**Decision**: The client does not retry or back off.
**Rationale**: The source has no retry; a failed call returns at once and the caller decides. The poll interval is the only repetition.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |

`separation-of-concerns` passes because the client only moves requests and replies; the wire spelling, identifiers and DTOs live in their own types. `unit-test-coverage` passes because every vector has a test in `StenographerHTTPClientTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/StenographerHTTPClientTests.swift`): the failure mapping, query building, the 404, the summarize and action failures, both preference encoders, the reconnect trigger and its first-poll and failed-poll cases, `timeout(method:path:)`, URL construction, the content type and the default base URL. `timeout-configuration` passes because every request carries one of three explicit timeouts. `error-response-handling` is partial because the daemon's `error` text is surfaced only for summarize and finding actions; every other failure collapses to `nil` or `false` by design. `retry-with-backoff` is marked failed because the client never retries; that is deliberate (see the Design Decision "The client does not retry or back off"), since the caller decides and the daemon is on loopback, so the check is a known and accepted failure rather than a defect. `secure-transport` is partial because traffic is plain HTTP, which is acceptable only on the loopback address, and the base URL can be overridden to any address through `STENOGRAPHER_URL`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (StenographerHTTPClientTests.swift, 20 of 20 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Linked the daemon service, wire and identifiers specs, reconciled the lock wording, added a remote-base-URL edge case and four test vectors, and rewrote the platform notes as guidance. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
