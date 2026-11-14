---
id: e8911288-108d-4050-aec5-663690bd5751
title: "Route Table"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An ordered list of async route handlers where the first to return a response wins, with table merging and an exact method-and-path handler builder."
platforms:
  - swift
  - macos
tags:
  - foundation
  - routing
  - http
  - dispatch
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Route Table

## Overview

An ordered list of route handlers. Each handler either claims a request by returning a response or declines it by returning `nil`. `RouteTable` is a `Sendable` struct over `Handler`, a `@Sendable` async function from `RouteRequest` to an optional `RouteResponse`. It dispatches a request to the first handler that claims it, merges two tables in order, and builds a handler for one exact method and path. It is transport-free: a daemon's HTTP layer converts its own request into `RouteRequest`, calls `handle`, and treats `nil` as no route.

## Behavioral Requirements

- **handler-type**: `Handler` MUST be an async function that takes a `RouteRequest` and returns `RouteResponse?`, and MUST be `@Sendable`.
- **init-handlers**: `init` MUST store the given handlers in the given order and MUST default to an empty list.
- **first-claim-wins**: `handle(request)` MUST call the handlers in order and MUST return the first non-nil response.
- **later-handlers-skipped**: Once a handler has claimed a request, `handle(request)` MUST NOT call any later handler.
- **declined-handlers-fall-through**: A handler that returns `nil` MUST leave the request for the next handler.
- **none-claims-is-nil**: `handle(request)` MUST return `nil` when no handler claims the request, including for an empty table.
- **handle-is-async-sequential**: `handle(request)` MUST be `async` and MUST await each handler before calling the next; handlers MUST NOT run in parallel for one request.
- **merging-order**: `merging(other)` MUST return a new table holding this table's handlers first and then `other`'s, so this table's handlers take precedence.
- **merging-non-mutating**: `merging(other)` MUST NOT change either operand.
- **exact-handler-claims-method-and-path**: `exact(method, components, respond)` MUST return a handler that calls `respond` and returns its response only when the request `method` equals `method` and the request `pathComponents` equal `components`.
- **exact-handler-declines-otherwise**: The `exact` handler MUST return `nil`, without calling `respond`, when the method differs or the path components differ in value, count or order.
- **exact-method-case-sensitive**: The `exact` handler MUST compare `method` as an exact string; `get` does not match `GET`.
- **exact-path-via-components**: The `exact` handler MUST compare the request's `pathComponents`, so empty segments in the path are ignored (`//a/` matches `["a"]`) and the query string is not part of the path.
- **exact-responder-always-responds**: The `respond` closure of `exact` MUST return a non-optional `RouteResponse`, so an `exact` handler cannot decline after matching.
- **handlers-hold-no-table-state**: A `RouteTable` MUST hold no state other than its immutable handler list.

## Appearance

Not applicable — this is a request dispatcher, not a visual component.

## States

Not applicable — this is an immutable value type, not a visual component; its handler list never changes after construction.

## Accessibility

Not applicable — this is a request dispatcher, not a visual component.

## Conformance Test Vectors

Tests named below are in the `RouteTable` suite (`RouteTableTests`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| route-table-001 | first-claim-wins, declined-handlers-fall-through, later-handlers-skipped | Table of [declining handler, handler returning 201, handler returning 202]; `handle` a `GET /a` request. | The response has `status` 201 (test: theFirstNonNilHandlerWins). |
| route-table-002 | none-claims-is-nil | Table of two declining handlers, then an empty table; `handle` a `GET /a` request. | `nil` in both cases (test: aTableThatClaimsNothingReturnsNil). |
| route-table-003 | merging-order | `first` (returns 201) and `second` (returns 202); `first.merging(second).handle` and `second.merging(first).handle`. | 201, then 202 (test: mergingTriesSelfBeforeOther). |
| route-table-004 | declined-handlers-fall-through, merging-order | `first` declines, `second` returns 202; `first.merging(second).handle`. | 202 (test: mergingFallsThroughToOtherWhenSelfDeclines). |
| route-table-005 | exact-handler-claims-method-and-path | Table with `exact("GET", ["a"])` returning 200; request `GET /a`. | `status` 200 (test: exactClaimsOnlyItsMethodAndPath). |
| route-table-006 | exact-handler-declines-otherwise | Same table; request `POST /a`. | `nil` (test: exactClaimsOnlyItsMethodAndPath). |
| route-table-007 | exact-handler-declines-otherwise | Same table; request `GET /a/b`. | `nil` (test: exactClaimsOnlyItsMethodAndPath). |
| route-table-008 | exact-handler-declines-otherwise | Same table; request `GET /`. | `nil` (test: exactClaimsOnlyItsMethodAndPath). |
| route-table-009 | exact-method-case-sensitive | `exact("GET", ["a"])`; request `get /a`. | `nil` (derived from the exact string comparison; no test beside the source). |
| route-table-010 | exact-path-via-components | `exact("GET", ["a"])`; request `GET //a/`. | The handler claims it and `respond` runs (derived from `pathComponents` dropping empty segments, tested in the `RouteRequest` suite; no `RouteTable` test). |
| route-table-011 | merging-non-mutating | `first.merging(second)` evaluated, then `first.handle` of a request only `second` claims. | `nil`: `first` is unchanged (derived; no test beside the source). |
| route-table-012 | later-handlers-skipped | Table of [claiming handler, handler that records a call]; `handle` a request. | The recording handler is never called (derived; no test beside the source). |

## Edge Cases

- **Null / empty input**: An empty table MUST return `nil` for every request. A table of only declining handlers MUST return `nil`. An `exact` handler built with an empty component list matches only a request whose `pathComponents` are empty, such as path `/` (derived; no test beside the source).
- **Boundary values**: A request path with extra, fewer or reordered segments than the `exact` components MUST be declined (test: exactClaimsOnlyItsMethodAndPath covers extra segments and the empty path). Two tables merged repeatedly keep every handler in order, with no deduplication.
- **Overlapping handlers**: When two handlers could both claim a request, the earlier one wins and the later one is never reached; ordering is the only precedence rule.
- **Malformed input**: The table does not validate the request; a malformed path is just its split components, and an `exact` handler claims it only if those components equal its own exactly.
- **Concurrent access**: `RouteTable` is `Sendable` with an immutable handler array and `@Sendable` handlers, so one table can serve requests concurrently from many tasks. Within one `handle` call the handlers run sequentially. Whether a handler's own shared state is safe is that handler's responsibility, not the table's.
- **Handler failure**: A handler cannot throw (its type is not `throws`), so the table has no failure path; a handler that traps takes the process with it. What a daemon does when `handle` returns `nil` (usually a 404) is outside this code.
- **Offline / disconnected state**: Not applicable: the table performs no network access; the daemon's HTTP layer owns transport.
- **Cancellation and timeouts**: The table adds no timeout and does not check for cancellation itself; `handle` is `async`, so cancellation of the calling task reaches a handler only if that handler checks it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `handlers` (init) | `[RouteTable.Handler]` | `[]` | The handlers to try, in order; earlier handlers take precedence. |
| `other` (`merging`) | `RouteTable` | none | The table whose handlers are tried after this table's. |
| `method`, `components`, `respond` (`exact`) | `String`, `[String]`, async closure | none | The exact request method, the exact path components, and the closure that produces the response. |

`RouteTable` reads no environment variable or settings key.

## Deep Linking

Not applicable: `RouteTable` defines no URL scheme or navigation destination; the `exact` helper matches HTTP method and path components of a request it is given, not app links.

## Localization

Not applicable: `RouteTable` contains no user-facing string.

## Accessibility Options

Not applicable: `RouteTable` presents no UI and responds to no display option.

## Feature Flags

Not applicable: `RouteTable` contains no feature-flag reference.

## Analytics

Not applicable: `RouteTable` contains no analytics call.

## Privacy

- **Data handled**: The requests passed through `handle`, which may carry headers and a body; the table only forwards them to handlers.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access itself.
- **Retention**: None beyond the lifetime of the table and the requests the caller holds.

## Logging

Not applicable: `RouteTable` calls no logging API; an unclaimed request is returned as `nil` with no log line.

## Platform Notes

- **SwiftUI**: The source file `Core/Routing/RouteTable.swift` imports only `Foundation` and is UI-independent, so a SwiftUI host uses it unchanged. It is a `public struct` that is `Sendable`; `Handler` is a `@Sendable` async closure typealias, and the table iterates its array with `for` and `await`.
- **Compose**: A Kotlin class over `List<suspend (RouteRequest) -> RouteResponse?>`. `handle` is a `suspend fun` using a loop and returning the first non-null; `merging` is `RouteTable(handlers + other.handlers)`. `exact` returns a lambda comparing `method` and the path-components list. Coroutine cancellation is cooperative and is checked at each suspension point.
- **React/Web**: An array of `(req: RouteRequest) => Promise<RouteResponse | null>`. `handle` is an `async` function with a `for ... of` loop and `await` per handler (sequential, as in the source, not `Promise.any`); `merging` is `new RouteTable([...a, ...b])`; `exact` compares `method` with `===` and the component arrays elementwise.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic and only the embedding application differs, never this contract.
- **WinUI 3**: A C# class over `IReadOnlyList<Func<RouteRequest, Task<RouteResponse?>>>` (nullable reference types) with an `async Task<RouteResponse?> HandleAsync` loop that awaits each handler in order; `Merging` is `new RouteTable(handlers.Concat(other.handlers).ToList())`; `Exact` compares `method` with `string.Equals(..., StringComparison.Ordinal)` and the components with `SequenceEqual`. In ASP.NET Core, a minimal API routes by endpoint metadata instead, so the table is mounted as a catch-all middleware (`app.Run` or `Map("/{**path}")`) that converts `HttpContext` to `RouteRequest`, calls `HandleAsync` and writes a 404 when it returns `null`. Pass `HttpContext.RequestAborted` through to handlers, since the source type has no cancellation parameter.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Routing/RouteTable.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A handler claims a request by returning a response and declines by returning `nil`, and the first claim wins.
**Rationale**: The source defines routing as an ordered list with that rule, so a route written once against `RouteRequest` can be mounted by any daemon and the order of the list is the only precedence (test: theFirstNonNilHandlerWins).
**Approved**: pending

**Decision**: `merging` places this table's handlers before `other`'s.
**Rationale**: The doc comment fixes that order, which lets a daemon put its own routes ahead of shared ones and have them win (test: mergingTriesSelfBeforeOther).
**Approved**: pending

**Decision**: `exact` compares `pathComponents`, not the raw path.
**Rationale**: The source matches on the components list so trailing and doubled slashes do not change the match; the `GET /` and `GET /a/b` cases pin the boundary (test: exactClaimsOnlyItsMethodAndPath).
**Approved**: pending

**Decision**: Handlers run sequentially for one request and cannot throw.
**Rationale**: The source loop awaits each handler in turn and the `Handler` type is not `throws`, so one request's handlers are tried in list order and a handler has no way to signal failure to the table; any error response is a `RouteResponse` the handler itself returns.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | Access Patterns |

`separation-of-concerns` passes because the table only orders and dispatches handlers; the HTTP transport, the handlers' business logic and what to do with an unclaimed request belong to the daemon and its routes. `unit-test-coverage` passes because `RouteTableTests` covers first-claim-wins, an unclaimed request, merge order and fall-through, and the exact handler's method, path, extra-segment and empty-path cases; the method case-sensitivity and sequential-await rules are derived without a test. `api-design-conventions` passes because dispatch is one deterministic rule, ordered first-claim-wins, over a transport-free request.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
