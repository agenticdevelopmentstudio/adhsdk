---
id: 53408483-6ccf-4a69-bc29-3b5b6e16d4a8
title: "Invalid Timestamp"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The error value a route returns when a timestamp query parameter such as since is malformed: a message-carrying Error that is Equatable and prints as its message."
platforms:
  - swift
  - macos
tags:
  - foundation
  - routing
  - errors
  - timestamps
depends-on: []
related:
  - 1a8e345f-c602-4ccb-8880-432b1deac6ac
  - 6a645c72-4525-4b96-9df4-85abecfacd27
references: []
approved-by: ""
approved-date: ""
---

# Invalid Timestamp

## Overview

`InvalidTimestamp` is the failure type for a rejected `?since=` style query parameter. The doc comment on the type in `InvalidTimestamp.swift` gives the reason it exists: `Result`'s failure must be an `Error`, and a retroactive `extension String: Error` would make every string in the process a throwable, a cure worse than the bare `String` it replaces. It is a public struct that carries one human-readable `message`, compares by value, and prints as its message. It holds no parsing logic; `RouteRequest` builds it when a timestamp does not parse (see the `RouteRequest` recipe ([adhsdk.ingredient.foundation.routing.route-request](cookbook:1a8e345f-c602-4ccb-8880-432b1deac6ac))).

## Behavioral Requirements

- **conforms-to-error**: `InvalidTimestamp` MUST conform to `Error`, so it can be the failure type of a `Result`.
- **carries-message**: `InvalidTimestamp` MUST expose the text given at construction as the read-only property `message`, unchanged.
- **init-takes-message**: `InvalidTimestamp` MUST be constructible with `init(message:)` from any string, and MUST NOT transform or validate it.
- **description-is-message**: `InvalidTimestamp.description` (its `CustomStringConvertible` text) MUST equal `message`.
- **equatable-by-message**: Two `InvalidTimestamp` values MUST compare equal exactly when their `message` strings are equal.
- **no-string-error-extension**: The module that declares `InvalidTimestamp` MUST NOT declare `extension String: Error`; the dedicated type is the only error shape for a rejected timestamp. This is a module-level rule, checked by searching the module's source (vector 010), not by running the type.
- **immutable**: `message` MUST be a `let`; a value MUST NOT change after construction.

## Appearance

Not applicable — this is an error value type, not a visual component.

## States

Not applicable — this is an immutable value type, not a visual component; it has no runtime state beyond its `message`.

## Accessibility

Not applicable — this is an error value type, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| invalid-timestamp-001 | carries-message, init-takes-message | `InvalidTimestamp(message: "bad since").message` | `bad since`. |
| invalid-timestamp-002 | description-is-message | `InvalidTimestamp(message: "bad since").description` | `bad since`. |
| invalid-timestamp-003 | equatable-by-message | `InvalidTimestamp(message: "a") == InvalidTimestamp(message: "a")` | `true`. |
| invalid-timestamp-004 | equatable-by-message | `InvalidTimestamp(message: "a") == InvalidTimestamp(message: "b")` | `false`. |
| invalid-timestamp-005 | init-takes-message | `InvalidTimestamp(message: "").message` | The empty string: no validation is applied. |
| invalid-timestamp-006 | conforms-to-error | Use a value as the failure of `Result<String, InvalidTimestamp>`, then `throw` it. | Compiles and throws; the caught error is an `InvalidTimestamp` with the same `message`. |
| invalid-timestamp-007 | carries-message | `RouteRequest(method: "GET", path: "/events", queryValues: ["since": ["yesterday"]]).validatedTimestamp("since")` | `.failure` whose `message` contains both `since` and `yesterday` (test: aWordIsRejectedRatherThanSortingAboveEveryRealTimestamp in the RouteRequest tests). |
| invalid-timestamp-008 | carries-message | `RouteRequest.activitySince("yesterday")` | `.failure` whose `message` contains `` `since` `` (test: activitySinceTakesOnlyTheTextAndItsRefusalNamesSince in the RouteRequest tests). |
| invalid-timestamp-009 | immutable | Compile `var e = InvalidTimestamp(message: "a"); e.message = "b"` | Compilation fails: `message` is a `let` and cannot be assigned (a compile check, derived from the declaration). |
| invalid-timestamp-010 | no-string-error-extension | Search the module's source for `extension String: Error` | No match (a search check, derived from the declaration). |

Vectors 001 to 006, 009 and 010 are derived from the declaration in `InvalidTimestamp.swift`; no test constructs the type directly. Vectors 007 and 008 are the existing assertions that exercise it through `RouteRequest`.

## Edge Cases

- **Null / empty input**: An empty `message` MUST be accepted and kept as is; the type does not validate it.
- **Boundary values**: Not applicable: the type holds one string with no length limit.
- **Malformed input**: Any string, including one with quotes, newlines or non-ASCII text, is stored and returned unchanged; escaping is the consumer's concern (`RouteResponse.error` JSON-encodes it).
- **Concurrent access**: `message` is an immutable stored property of a value type, so concurrent reads are safe and there is no mutation to race.
- **Error states**: Not applicable: constructing the type cannot fail.
- **Offline / disconnected state**: Not applicable: the type performs no network access.
- **Cancellation and timeouts**: Not applicable: construction and reads are synchronous in-memory operations.

## Configuration

None — `InvalidTimestamp` reads no environment variable or settings key; its one input is the `message` argument of `init(message:)`.

## Deep Linking

Not applicable: `InvalidTimestamp` defines no URL scheme, route or navigation destination.

## Localization

Not applicable: `InvalidTimestamp` contains no string literal; the message text, which is English and built by `RouteRequest`, is the caller's. The open concern for translating that message belongs to the `RouteRequest` recipe ([adhsdk.ingredient.foundation.routing.route-request](cookbook:1a8e345f-c602-4ccb-8880-432b1deac6ac)).

## Accessibility Options

Not applicable: `InvalidTimestamp` presents no UI and responds to no display option.

## Feature Flags

Not applicable: `InvalidTimestamp` contains no feature-flag reference.

## Analytics

Not applicable: `InvalidTimestamp` contains no analytics call.

## Privacy

- **Data handled**: Only the message its caller passes in; `RouteRequest` includes the rejected raw query value in it.
- **Echoed value**: The message includes the raw, untrusted query value (`RouteRequest.swift`, `parseISO8601`), which can hold quotes, newlines or markup. The type does not limit its length or escape it. A consumer MUST NOT write the message to a log or render it as markup without escaping; `RouteResponse.error` JSON-encodes it.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access itself.
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: `InvalidTimestamp` calls no logging API.

## Platform Notes

- **SwiftUI**: The source file `Core/Routing/InvalidTimestamp.swift` imports only `Foundation` and is UI-independent, so a SwiftUI host uses it unchanged. It is a `public struct` conforming to `Error`, `Equatable` and `CustomStringConvertible`; `Equatable` is synthesized from the single stored property.
- **Compose**: A Kotlin `data class InvalidTimestamp(val message: String)` gives value equality and a `toString` override that returns `message`. To use it in a result type, return `Result.failure` with an exception subclass, or a sealed result class; Kotlin's `Throwable` carries a `message` already.
- **React/Web**: A small class extending `Error` with the `message` field, or a plain frozen object `{ message }` in a discriminated union; compare by `message` since JavaScript has no synthesized value equality.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic and only the embedding application differs, never this contract.
- **WinUI 3**: A C# `record InvalidTimestamp(string Message)` gives value equality; override `ToString()` to return `Message`. A .NET port that needs it throwable derives from `Exception` (passing `Message` to the base constructor); otherwise return it through a result type. Equality on an exception subclass is by reference unless overridden, so keep the record shape for the value contract.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Routing/InvalidTimestamp.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A dedicated `InvalidTimestamp` struct is used as the `Result` failure instead of `String`.
**Rationale**: The doc comment on `InvalidTimestamp` in `InvalidTimestamp.swift` states that `Result`'s failure must be an `Error`, and a retroactive `extension String: Error` would make every string in the process throwable, which it calls a cure worse than the bare `String` it replaces.
**Approved**: pending

**Decision**: The type carries only a `message` and conforms to `CustomStringConvertible` with `description` equal to `message`.
**Rationale**: A malformed `since` gets a 400 with a single human-readable reason, instead of being clamped silently; the doc comment on `validatedTimestamp` in `RouteRequest.swift` explains that a malformed bound would otherwise quietly select the wrong rows and return 200. Printing the value yields the message itself with no wrapper text.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | partial | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

`separation-of-concerns` passes because the type only carries a message; deciding a timestamp is malformed and wording the message belong to `RouteRequest`. `unit-test-coverage` is partial: `InvalidTimestampTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Routing/InvalidTimestampTests.swift`) covers vectors 001 to 006, and vectors 007 and 008 are covered by the `RouteRequest` tests; vectors 009 (a compile-failure check) and 010 (a source search) are skipped because a unit test cannot assert that code fails to compile or search the module source. `explicit-error-handling` passes because the type exists to give a rejected timestamp a typed, equatable error instead of a bare string. `secure-log-output` is partial: the message echoes an untrusted query value and the type leaves escaping to its consumers, so each consumer MUST NOT log or render it unescaped (see Privacy).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (InvalidTimestampTests.swift, 8 of 10 vectors, 009 and 010 skipped as non-unit checks); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Cited InvalidTimestamp.swift and RouteRequest.swift next to the quoted claims, linked RouteRequest and RouteResponse in related and the text, added vectors 009 and 010, clarified the 400 rationale and added an echoed-value privacy note with a secure-log-output row. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
