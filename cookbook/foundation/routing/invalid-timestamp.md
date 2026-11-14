---
id: 53408483-6ccf-4a69-bc29-3b5b6e16d4a8
title: "Invalid Timestamp"
type: ingredient
version: 1.0.0
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
related: []
references: []
approved-by: ""
approved-date: ""
---

# Invalid Timestamp

## Overview

`InvalidTimestamp` is the failure type for a rejected `?since=` style query parameter. The source comment gives the reason it exists: `Result`'s failure must be an `Error`, and a retroactive `extension String: Error` would make every string in the process a throwable, a cure worse than the bare `String` it replaces. It is a public struct that carries one human-readable `message`, compares by value, and prints as its message. It holds no parsing logic; `RouteRequest` builds it when a timestamp does not parse.

## Behavioral Requirements

- **conforms-to-error**: `InvalidTimestamp` MUST conform to `Error`, so it can be the failure type of a `Result`.
- **carries-message**: `InvalidTimestamp` MUST expose the text given at construction as the read-only property `message`, unchanged.
- **init-takes-message**: `InvalidTimestamp` MUST be constructible with `init(message:)` from any string, and MUST NOT transform or validate it.
- **description-is-message**: `InvalidTimestamp.description` (its `CustomStringConvertible` text) MUST equal `message`.
- **equatable-by-message**: Two `InvalidTimestamp` values MUST compare equal exactly when their `message` strings are equal.
- **no-string-error-extension**: The component MUST NOT make `String` itself an `Error`; the dedicated type is the only error shape for a rejected timestamp.
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

Vectors 001 to 006 are derived from the declaration; no test beside the source constructs the type directly. Vectors 007 and 008 are the existing assertions that exercise it through `RouteRequest`.

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

Not applicable: `InvalidTimestamp` contains no string literal; the message text, which is English and built by `RouteRequest`, is the caller's. The open concern for translating that message belongs to the recipe for `RouteRequest`.

## Accessibility Options

Not applicable: `InvalidTimestamp` presents no UI and responds to no display option.

## Feature Flags

Not applicable: `InvalidTimestamp` contains no feature-flag reference.

## Analytics

Not applicable: `InvalidTimestamp` contains no analytics call.

## Privacy

- **Data handled**: Only the message its caller passes in; `RouteRequest` includes the rejected raw query value in it.
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
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Routing/InvalidTimestamp.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A dedicated `InvalidTimestamp` struct is used as the `Result` failure instead of `String`.
**Rationale**: The source comment states that `Result`'s failure must be an `Error`, and a retroactive `extension String: Error` would make every string in the process throwable, which it calls a cure worse than the bare `String` it replaces.
**Approved**: pending

**Decision**: The type carries only a `message` and conforms to `CustomStringConvertible` with `description` equal to `message`.
**Rationale**: `RouteRequest` reports a rejected bound as a 400 with one human-readable reason (its doc comment says this one is a 400, not a silent clamp); printing the value yields the message itself with no wrapper text.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

`separation-of-concerns` passes because the type only carries a message; deciding a timestamp is malformed and wording the message belong to `RouteRequest`. `unit-test-coverage` is partial because no test constructs `InvalidTimestamp` directly; only the `RouteRequest` tests assert on its `message`, through the failure path. `explicit-error-handling` passes because the type exists to give a rejected timestamp a typed, equatable error instead of a bare string.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
