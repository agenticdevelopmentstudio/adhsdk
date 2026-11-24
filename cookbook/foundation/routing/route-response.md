---
id: 6a645c72-4525-4b96-9df4-85abecfacd27
title: "Route Response"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A transport-free response value for shared routes, with a JSON wire encoder, a JSON error body, a 404 helper and a 204 constant."
platforms:
  - swift
  - macos
tags:
  - foundation
  - routing
  - http
  - json
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Route Response

## Overview

A response as shared routes produce it: no transport and no framework. A daemon's HTTP layer converts it into its own response type. `RouteResponse` is a `Sendable`, `Equatable` struct holding `status`, `body`, `contentType` and `headers`, plus static builders: `makeJSONEncoder()` (the wire encoder), `json(_:status:)`, `error(_:status:)`, `notFound(_:)` and the `noContent` constant. On Apple the encoder is Foundation's `JSONEncoder` with `keyEncodingStrategy = .convertToSnakeCase`, `dateEncodingStrategy = .iso8601` and `outputFormatting = [.prettyPrinted, .sortedKeys]`, and the error body is a private `ErrorBody` struct with one `error` key.

## Behavioral Requirements

### Shape

- **fields**: A `RouteResponse` MUST carry `status` (`Int`), `body` (`Data`), `contentType` (`String`) and `headers` (`[String: String]`) exactly as given to `init`.
- **builders-empty-headers**: `json`, `error`, `notFound` and `noContent` MUST each return a response whose `headers` is empty.
- **init-defaults**: `init` MUST default `contentType` to `application/json` and `headers` to an empty dictionary; `status` and `body` are required.
- **status-unchecked**: `init` MUST NOT validate `status`; any `Int` is stored as given.
- **value-semantics**: A `RouteResponse` MUST be `Sendable` and `Equatable`; two responses are equal when every field is equal.

### JSON encoding

- **wire-encoder-format**: `makeJSONEncoder()` MUST return an encoder that writes snake_case keys, ISO-8601 dates, pretty-printed output and sorted keys.
- **encoder-fresh-per-call**: `makeJSONEncoder()` MUST return a new encoder instance on every call, because `JSONEncoder` is a reference type and handlers run concurrently.
- **json-body**: `json(value, status:)` MUST encode the value with `makeJSONEncoder()` and return a response whose body is the encoded data, whose `status` is the given status (200 by default) and whose `contentType` is `application/json`.
- **json-snake-case-keys**: A property such as `fooBar` MUST appear as `foo_bar` in the body.
- **json-iso-dates**: A `Date` property MUST be written as an ISO-8601 string without fractional seconds (`2026-01-31T00:00:00Z`).
- **json-format-is-pretty-sorted**: The body MUST be pretty-printed with keys sorted, so the exact bytes are deterministic for a given value; with Foundation's formatting that is a two-space indent and ` : ` between key and value. A `/` inside a string value MUST be written as `\/`, as Foundation's `JSONEncoder` does by default, so a value such as `a/b` has the same bytes on every platform.
- **json-encode-failure-is-empty-object**: When encoding throws, `json(_:status:)` MUST return a response with the body `{}` and the requested status, and MUST NOT throw, log or otherwise surface the failure.

### Error and fixed responses

- **error-body**: `error(message, status:)` MUST return a response whose body is the JSON object with the single key `error` holding the message, produced through `json(_:status:)`.
- **error-body-is-valid-json**: The error body MUST be valid JSON that decodes back to the exact message for any message, including one with a quote, a backslash or a newline.
- **error-status**: `error(_:status:)` MUST set the response `status` to the given value.
- **not-found**: `notFound(message)` MUST return `error(message, status: 404)`, with the message defaulting to `Not found`.
- **no-content**: `noContent` MUST be a response with `status` 204 and an empty body.
- **no-content-content-type**: `noContent` MUST keep the default `contentType` of `application/json` even though its body is empty.
- **pure-builders**: Every builder MUST depend only on its arguments, MUST NOT perform I/O and MUST NOT mutate shared state.

## Appearance

Not applicable — this is a response data type and JSON builder, not a visual component.

## States

Not applicable — this is an immutable value type, not a visual component; it has no runtime state beyond its fields.

## Accessibility

Not applicable — this is a response data type, not a visual component.

## Conformance Test Vectors

Tests named below are in the `RouteResponse` suite (`RouteResponseTests`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| route-response-001 | json-body, json-snake-case-keys, json-iso-dates, json-format-is-pretty-sorted | `json(Sample(fooBar: 1, at: 2026-01-31T00:00:00Z))` | Body is the text `{\n  "at" : "2026-01-31T00:00:00Z",\n  "foo_bar" : 1\n}`; `status` 200; `contentType` `application/json` (test: jsonUsesSnakeCaseIsoDatesPrettyPrintingAndSortedKeys). |
| route-response-002 | json-body | `json(sample, status: 201)` | `status` is 201 (test: jsonCarriesTheRequestedStatus). |
| route-response-003 | json-encode-failure-is-empty-object | `json(value)` where the value's `encode(to:)` throws. | Body is the text `{}` (test: aValueThatFailsToEncodeYieldsAnEmptyObject). |
| route-response-004 | error-body, error-body-is-valid-json, error-status | `error("a \"quoted\" msg\nwith a newline and a \\ backslash", status: 400)` | `status` 400; the body parses as JSON and `error` equals the exact message (test: errorBodyIsValidJSONThatDecodesBackToTheMessage). |
| route-response-005 | not-found | `notFound()` | `status` 404; the body decodes to `error` equal to `Not found` (test: notFoundIs404, which checks only that the body text contains `Not found`; the decoded check is stricter, like vector 007). |
| route-response-006 | no-content, no-content-content-type | `noContent` | `status` 204; body is empty; `contentType` is `application/json` (test: noContentIs204WithAnEmptyBody). |
| route-response-007 | not-found | `notFound("gone")` | `status` 404; the body decodes to `error` equal to `gone` (derived from the builder; no test beside the source covers a custom message). |
| route-response-008 | init-defaults | `RouteResponse(status: 200, body: Data())` | `contentType` is `application/json`; `headers` is empty (derived from the initializer defaults; no test beside the source). |
| route-response-009 | encoder-fresh-per-call | Two calls to `makeJSONEncoder()`. | Two distinct instances, each with the wire format (derived from the declaration; no test beside the source). |
| route-response-010 | status-unchecked | `RouteResponse(status: 999, body: Data()).status` | 999 (derived: `init` stores the argument without a check; no test beside the source). |
| route-response-011 | json-format-is-pretty-sorted | `json(Path(path: "a/b"))` for a struct with one `String` property `path`. | Body is the text `{\n  "path" : "a\/b"\n}`, with the slash escaped (derived from `JSONEncoder` defaults; no test beside the source). |
| route-response-012 | builders-empty-headers | `json(sample)`, `error("x", status: 400)`, `notFound()` and `noContent`. | `headers` is empty for each (derived from the initializer default; no test beside the source). |

## Edge Cases

- **Null / empty input**: An empty body is allowed (`noContent`, and any `RouteResponse` built with empty `Data`). An empty error message is encoded through the same builder as a pretty-printed object whose `error` value is the empty string (derived; no test beside the source).
- **Boundary values**: `status` is any `Int` with no range check; a caller that passes a value outside the HTTP range gets it stored unchanged. A date is written to whole seconds, so sub-second precision is dropped by the ISO-8601 strategy.
- **Malformed input**: A message containing a quote, backslash or newline MUST yield valid JSON because the body is encoded, not spliced (test: errorBodyIsValidJSONThatDecodesBackToTheMessage). Non-ASCII text is encoded by `JSONEncoder` as given.
- **Encoding failure**: A value that cannot be encoded MUST yield `{}` with the requested status; the failure is dropped by `try?` and the response gives the caller no signal that the real body was lost. The doc comment declares this contract, so it is a fact, not a gap.
- **Concurrent access**: A `RouteResponse` is an immutable `Sendable` value, and `makeJSONEncoder()` returns a fresh encoder each call, so handlers running concurrently never share an encoder.
- **Error states**: No builder throws. The only failure path is the encoding fallback above.
- **Offline / disconnected state**: Not applicable: the type performs no network access; the daemon's HTTP layer sends it.
- **Cancellation and timeouts**: Not applicable: every builder is a synchronous in-memory computation.

## Configuration

None — `RouteResponse` reads no environment variable or settings key. The wire encoder's strategies are fixed in `makeJSONEncoder()` and cannot be changed by a caller; `json(_:status:)` always uses it. Callers supply `status`, `contentType` and `headers` through the initializer.

## Deep Linking

Not applicable: `RouteResponse` defines no URL scheme or navigation destination.

## Localization

`RouteResponse` has one user-facing string of its own, the default `notFound` message `Not found`, which is hardcoded English and is not localized. It is an API error text read by clients, not a UI string; any other message arrives from the caller.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (inline literal) | `Not found` | Default message of `notFound(_:)`. |

## Accessibility Options

Not applicable: `RouteResponse` presents no UI and responds to no display option.

## Feature Flags

Not applicable: `RouteResponse` contains no feature-flag reference.

## Analytics

Not applicable: `RouteResponse` contains no analytics call.

## Privacy

- **Data handled**: Whatever the caller encodes into `body` and `headers`, and the error message text.
- **Storage**: None; it persists nothing.
- **Transmission**: None by itself; the daemon's HTTP layer transmits the response.
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: `RouteResponse` calls no logging API; in particular the encoding fallback is not logged.

## Platform Notes

- **SwiftUI**: The source file `Core/Routing/RouteResponse.swift` imports only `Foundation` and is UI-independent, so a SwiftUI host uses it unchanged. It is a `public struct` that is `Sendable` and `Equatable`. A SwiftUI host calls the builders from a background route handler and never from a view body. The wire encoder and `ErrorBody` are described in the Overview.
- **Compose**: A Kotlin `data class RouteResponse` (override `equals` for the `ByteArray` body). Use kotlinx.serialization `Json` with `prettyPrint = true` and a naming strategy of snake case (`JsonNamingStrategy.SnakeCase`), and format dates as ISO-8601 strings with `Instant.toString()` truncated to seconds. Note that kotlinx.serialization's key order is declaration order, not sorted, so sort keys explicitly to match the bytes, and its pretty printer writes `"key": value` rather than `"key" : value`; it does not escape `/`, so escape each `/` in string values as `\/`.
- **React/Web**: A readonly object type with `Uint8Array` or string body. Build with `JSON.stringify(value, replacer, 2)`, snake-casing keys and sorting them in the replacer and converting `Date` to an ISO string without milliseconds; `JSON.stringify` writes `"key": value` (no space before the colon), so byte equality with the Swift output needs a custom formatter; `JSON.stringify` also leaves `/` unescaped, so replace `/` with `\/` inside string values. Build the error body from an object, never string concatenation.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic and only the embedding application differs, never this contract.
- **WinUI 3**: A C# `record RouteResponse` with `byte[]` body (supply a custom `Equals` for the array). Use `System.Text.Json` with `JsonNamingPolicy.SnakeCaseLower` (.NET 8 and later), `WriteIndented = true` and a custom ordering of properties, since `System.Text.Json` writes properties in declaration order and indents with two spaces but writes `"key": value`, and it does not escape `/` by default, so escape it as `\/` in string values (a custom converter, or a post-pass over string tokens). In ASP.NET Core minimal APIs, `Results.Json` or a custom `IResult` writes this status, body and headers; share one configured `JsonSerializerOptions` (it is safe to share once frozen, unlike the Swift encoder note).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Routing/RouteResponse.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `makeJSONEncoder()` returns a new encoder on every call.
**Rationale**: The doc comment on `makeJSONEncoder()` in `RouteResponse.swift` says `JSONEncoder` is a reference type and handlers run concurrently, so a shared instance would be shared mutable state.
**Approved**: pending

**Decision**: The error body is built by encoding a small `ErrorBody` struct through `json(_:status:)`, not by splicing the message into a string.
**Rationale**: The doc comment on `error(_:status:)` in `RouteResponse.swift` says a message containing a quote, backslash or newline would otherwise produce invalid JSON (test: errorBodyIsValidJSONThatDecodesBackToTheMessage).
**Approved**: pending

**Decision**: A value that fails to encode produces `{}` with the requested status rather than a thrown error or an error response.
**Rationale**: The doc comment on `json(_:status:)` in `RouteResponse.swift` states the fallback and keeps the function non-throwing so handlers need no error path (test: aValueThatFailsToEncodeYieldsAnEmptyObject). The cost is that the lost body is not reported, and a client reads `{}` with the requested status (often 200) as an empty success. Alternatives weighed: a 500 `error` body would tell the client the handler failed and would be the safer signal; a log line would tell the operator without changing the response; `{}` with the requested status keeps the signature and every call site unchanged. The source chose `{}`; whether to switch to a 500 body or add a log is the owner's call, which is why this decision stays pending.
**Approved**: pending

**Decision**: `noContent` keeps the default `application/json` content type with an empty body.
**Rationale**: The source builds it with the plain initializer; the test pins the resulting content type (test: noContentIs204WithAnEmptyBody).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because the type builds response values only; sending them is the daemon's HTTP layer. `unit-test-coverage` passes: every vector (001 to 012) has a test in `RouteResponseTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Routing/RouteResponseTests.swift`). `error-response-handling` passes because every error response has one JSON shape, `error`, built through the encoder. `explicit-error-handling` is partial because the encoding failure is swallowed into `{}` by design without a log or signal. `no-hardcoded-strings` fails because the default not-found message is an inline English literal; it is an API error text and the source offers no localization path.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (RouteResponseTests.swift, 12 of 12 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved the source reasoning out of requirements, added the slash-escaping rule and the empty-headers requirement with vectors, tightened vector 005, weighed the alternatives for the encode-failure decision, moved the encoder details out of the SwiftUI note, and downgraded unit-test-coverage to partial. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
