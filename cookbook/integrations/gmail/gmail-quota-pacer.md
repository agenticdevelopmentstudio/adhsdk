---
id: f0543d0b-31fe-4dcc-833e-21ead91bdca5
title: "Gmail Quota Pacer"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Actor that reserves Gmail quota units per call and returns the wait that keeps a process under the per-user rate, plus the table of per-call unit costs."
platforms:
  - swift
  - macos
  - ios
tags:
  - gmail
  - mail-sync
  - rate-limit
  - quota
depends-on: []
related:
  - c448c9f4-195d-4625-a49d-22dd5468a914
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references:
  - https://developers.google.com/workspace/gmail/api/reference/quota
approved-by: ""
approved-date: ""
---

# Gmail Quota Pacer

## Overview

`GmailQuotaPacer` is a public Swift `actor` that keeps Gmail API calls under Google's per-user quota of 15,000 units a minute, which Google enforces as a moving average of about 250 units a second (see [Gmail API quota](https://developers.google.com/workspace/gmail/api/reference/quota)). A caller asks it to `reserve` the quota cost of a call before sending the call, and the pacer returns how long the caller must wait first. The pacer never sleeps and never sends anything itself; the caller performs the wait.

The arithmetic is the generic cell rate algorithm. The pacer keeps one value, `drainedAt`, the instant when every unit reserved so far would have drained at `unitsPerSecond`. A call waits only for the part of that backlog which lies beyond the burst allowance, so the first `burstUnits` units go out back to back and later calls are spaced to the configured average rate.

The same file holds `GmailQuotaCost`, an internal `enum` of `static let` constants giving each Gmail call's cost in units, taken from [Google's published quota table](https://developers.google.com/workspace/gmail/api/reference/quota). [GmailRESTClient](cookbook:c448c9f4-195d-4625-a49d-22dd5468a914) is the consumer: every request attempt, retries included, reserves its cost, sleeps for any returned wait, and then sends. The REST client (and the [mail integration service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) above it), its retry and backoff policy and the Gmail response types are separate components.

## Behavioral Requirements

Contract: `public actor GmailQuotaPacer` with `public init(unitsPerSecond: Double, burstUnits: Double, now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now })`, `public func reserve(_ units: Int) -> Duration` and `public static let shared`. The only mutable state is `drainedAt: ContinuousClock.Instant?`, which starts nil.

### Reservation

- **reserve-returns-wait**: `reserve(_:)` MUST return a `Duration` that is the time the caller has to wait before sending the call whose cost is `units`.
- **no-sleep**: `reserve(_:)` MUST return without suspending or sleeping; waiting is left to the caller.
- **wait-formula**: `reserve(_:)` MUST return `max(.zero, drainedAt' - now - burstUnits / unitsPerSecond)`, where `drainedAt'` is the value set by this reservation and `now` is the single clock read. It therefore never returns a negative `Duration`, and reservations that total no more than `burstUnits` from an idle pacer each return `.zero`.
- **drain-advance**: Each reservation MUST set `drainedAt` to `max(previous drainedAt, current time)` plus `units / unitsPerSecond` seconds, where a nil `drainedAt` counts as the current time.
- **idle-credit-capped**: Time spent idle MUST NOT build up credit beyond the burst allowance, because a `drainedAt` already in the past is replaced by the current time on the next reservation.
- **zero-units**: Reserving 0 units MUST leave `drainedAt` unchanged when it is at or after the current time, and MUST return the wait that backlog still implies.
- **nanosecond-rounding**: Each conversion of units, or of the burst allowance, to a `Duration` MUST round to the nearest whole unit of the platform's `Duration` resolution (a whole nanosecond in Swift).
- **units-nonnegative**: NEEDS REVIEW: Not implemented in source. `reserve(_:)` takes an `Int` and never checks its sign, so a negative `units` moves `drainedAt` earlier and shortens the backlog; the only callers pass `GmailQuotaCost` constants, which are all positive. Settling it needs a decision whether a negative reservation is a caller error to trap, clamp or accept as a refund.
- **reservation-final**: The pacer MUST offer no cancel or release operation, so a call that fails, is retried, or is cancelled while its caller sleeps keeps the units it reserved. A negative `units` is not a designed release; see the open question on `units-nonnegative`.
- **serialised-reservations**: Concurrent `reserve(_:)` calls MUST be serialised by the actor so each one reads and updates `drainedAt` as a single step and no two calls read the same prior value.

### Configuration and clock

- **rate-precondition**: The initializer MUST trap with the message "the pacer needs a positive rate" unless `unitsPerSecond > 0` and `burstUnits >= 0`; the one message is used for both checks, so it names the rate even when the burst is the bad argument.
- **clock-injected**: The pacer MUST read the time through the `now` closure, which defaults to `ContinuousClock.now`, so a test controls time by passing its own closure.
- **clock-read-once**: `reserve(_:)` MUST read the clock exactly once per call and use that single instant for every step of the calculation.
- **sendable-clock**: The `now` closure MUST be `@Sendable` because the actor stores and calls it from its own isolation.
- **zero-burst**: A `burstUnits` of 0 MUST be accepted, and the pacer then spaces every call, including the first, by its own cost divided by `unitsPerSecond`.

### Shared instance

- **shared-defaults**: `GmailQuotaPacer.shared` MUST be created with `unitsPerSecond` 200 and `burstUnits` 200, below Google's 250 units a second ([quota page](https://developers.google.com/workspace/gmail/api/reference/quota)) to leave room for other clients.
- **shared-process-wide**: `shared` MUST be one instance for the whole process, so every account paced through it shares one `drainedAt`.
- **in-memory-only**: The pacer MUST keep `drainedAt` in memory only; nothing is persisted, so a new process starts idle and processes do not coordinate.

### Quota costs

- **cost-table**: `GmailQuotaCost` MUST define these unit costs, taken from [Google's quota table](https://developers.google.com/workspace/gmail/api/reference/quota): `profile` 1, `labelsList` 1, `historyList` 2, `messagesList` 5, `messagesGet` 5, `threadsGet` 10, `messagesBatchModify` 50.
- **cost-type**: Each `GmailQuotaCost` constant MUST be an `Int`, so it can be passed directly to `reserve(_:)`.
- **cost-visibility**: `GmailQuotaCost` MUST be module-internal; only code inside the SDK module names it.

## Appearance

Not applicable — this is a rate-limiting engine and a table of constants, not a visual component.

## States

Not applicable — this is a rate-limiting engine and a table of constants, not a visual component. Its runtime state is a single optional instant, described under Behavioral Requirements: nil before the first reservation, then the instant the reserved backlog drains.

## Accessibility

Not applicable — this is a rate-limiting engine and a table of constants, not a visual component.

## Conformance Test Vectors

All vectors use a stopped clock unless they say the clock moves. Vectors marked "Derived" follow from the source arithmetic; the others come from `GmailRESTClientTests`, the only test file that exercises the pacer (`eachCallWaitsForTheQuotaItCosts` and `theBurstAllowanceGoesOutWithoutWaiting`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pacer-001 | wait-formula, drain-advance | Test `theBurstAllowanceGoesOutWithoutWaiting`: rate 10, burst 10; `reserve(5)`, `reserve(5)`, `reserve(5)` | `.zero`, `.zero`, then 500 ms |
| pacer-002 | zero-burst, wait-formula, reserve-returns-wait | Test `eachCallWaitsForTheQuotaItCosts`: rate 5, burst 0; `reserve(1)` then `reserve(2)` | 200 ms, then 600 ms (the 2-unit call waits 0.2 s of backlog plus 0.4 s of its own) |
| pacer-003 | no-sleep, reserve-returns-wait | Derived: rate 5, burst 0, stopped clock; time one `reserve(5)` call | The call returns 1 s immediately; it does not suspend for that second |
| pacer-004 | shared-defaults, wait-formula | Derived: rate 200, burst 200; `reserve(50)` four times | `.zero` each time |
| pacer-005 | shared-defaults, wait-formula | Derived: rate 200, burst 200; `reserve(50)` five times | The first four `.zero`; the fifth 250 ms |
| pacer-006 | idle-credit-capped, drain-advance | Derived: rate 10, burst 0; `reserve(10)` returns 1 s; clock then moves 5 s; `reserve(10)` | 1 s, because the stale backlog is replaced by the current time and credit is not banked |
| pacer-007 | zero-units | Derived: rate 10, burst 0; `reserve(10)` returns 1 s; then `reserve(0)` on the same instant | 1 s; `drainedAt` is unchanged |
| pacer-008 | zero-units, wait-formula | Derived: fresh pacer, rate 10, burst 0; `reserve(0)` | `.zero` |
| pacer-009 | nanosecond-rounding | Derived: rate 3, burst 0; `reserve(1)` | 333,333,333 ns on Swift; a port rounds to its own finest `Duration` resolution |
| pacer-010 | wait-formula | Derived: rate 10, burst 100; `reserve(5)` | `.zero`, not a negative duration |
| pacer-011 | clock-injected, clock-read-once | Derived: rate 10, burst 0; pass `now` as a closure that returns a fixed instant and counts calls; `reserve(1)` | 100 ms, and `now` was called exactly once |
| pacer-012 | rate-precondition | Derived: construct with `unitsPerSecond` 0 | The process traps with "the pacer needs a positive rate" |
| pacer-013 | rate-precondition | Derived: construct with `burstUnits` -1 | The process traps with "the pacer needs a positive rate" |
| pacer-014 | serialised-reservations | Derived: rate 10, burst 0, stopped clock; ten concurrent `reserve(1)` from a task group | The returned waits are the ten distinct values 100 ms, 200 ms, up to 1 s, in some order |
| pacer-015 | reservation-final | Derived: rate 10, burst 0; `reserve(10)`, the caller is cancelled during its sleep, then `reserve(10)` on the same instant | 1 s, then 2 s; the first reservation's units are still counted |
| pacer-016 | cost-table, cost-type | Derived: read each `GmailQuotaCost` constant | profile 1, labelsList 1, historyList 2, messagesList 5, messagesGet 5, threadsGet 10, messagesBatchModify 50 |
| pacer-017 | shared-process-wide | Derived: read `GmailQuotaPacer.shared` twice | The same instance both times; a reservation made through one read is seen by the other |
| pacer-018 | units-nonnegative | Derived: rate 10, burst 0; `reserve(10)` returns 1 s; `reserve(-5)` | 500 ms: the unvalidated negative value shortened the backlog by half; this records the code, not a designed refund |

## Edge Cases

- **Null and empty input**: There is no optional input. `drainedAt` is nil before the first reservation and is treated as the current time, so the first call is paced only by its own cost beyond the burst allowance. This MUST hold.
- **Zero units**: A reservation of 0 units adds nothing to the backlog and returns the wait the existing backlog implies, or `.zero` when there is none. This MUST hold.
- **Negative units**: The sign of `units` is never validated; a negative value moves `drainedAt` earlier and returns a reduced wait. This is what the code does, and the open question on `units-nonnegative` records it.
- **Boundary at the burst allowance**: Reservations that total exactly `burstUnits` still return `.zero`; the first unit past it returns a positive wait. This MUST hold.
- **Zero burst**: `burstUnits` of 0 is valid and makes even the first call wait its own cost divided by the rate. This MUST hold.
- **Invalid configuration**: A rate of 0 or below, or a negative burst, traps in the initializer through `precondition`. A `NaN` for either value also traps, because the comparisons are false. A release build compiled with unchecked optimisation removes the check. This is what the code does.
- **Unbounded configuration**: A burst or rate that makes a duration exceed the range of `Int64` nanoseconds (about 9.2 billion seconds, which includes an infinite burst) passes the precondition and then traps in the conversion to `Duration`. The source does not guard this; callers pass finite constants.
- **Very large rate**: An infinite `unitsPerSecond` passes the precondition, makes every cost zero seconds, and so turns pacing off. This is what the code does.
- **Clock moves backward**: With an injected clock that returns an earlier instant than before, `drainedAt` stays ahead of the current time, so the backlog is longer than real time implies. The default `ContinuousClock` never moves backward.
- **Clock moves forward**: Time passing drains the backlog, and once the clock passes `drainedAt` the backlog is gone and no credit beyond the burst allowance remains. This MUST hold.
- **Concurrent access**: Calls arriving together from many tasks are serialised by the actor; each sees the `drainedAt` left by the one before. This MUST hold. The pacer does not decide who is first.
- **Cancellation**: The pacer cannot be cancelled mid-call because `reserve(_:)` is synchronous inside the actor. A caller cancelled while it sleeps out the returned wait keeps its reservation, so quota is over-counted rather than exceeded.
- **Failed or retried requests**: The pacer cannot tell a failed request from a successful one. `GmailRESTClient` reserves once per attempt, so each retry after a 429, a 5xx or a transient network error reserves its cost again.
- **Error states, network and offline**: Not applicable: the pacer performs no I/O and has no dependency that can fail; it raises no errors and returns a `Duration` on every call.
- **Other processes and other clients**: The pacer paces only its own process. Other processes, devices or Google clients sharing the same account quota are not seen; the 200-unit shared rate leaves headroom for them but cannot guarantee it.
- **Server-side enforcement**: Whether Google applies the quota exactly as described is outside this source. A call that still exceeds the quota is answered with 429 or a rate-limit 403, which `GmailRESTClient` handles by backoff and retry.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `unitsPerSecond` | `Double` | none; `shared` uses 200 | Average rate the pacer allows. Must be greater than 0. Google's own limit is about 250. |
| `burstUnits` | `Double` | none; `shared` uses 200 | Units that may go out back to back before spacing starts. Must be 0 or greater. |
| `now` | `@Sendable () -> ContinuousClock.Instant` | `ContinuousClock.now` | The clock; injected so tests control time. |
| `units` (argument to `reserve`) | `Int` | none | Quota cost of the next call; callers pass a `GmailQuotaCost` constant. |

There are no environment variables or settings keys. [GmailRESTClient](cookbook:c448c9f4-195d-4625-a49d-22dd5468a914) takes the pacer as an initializer parameter that defaults to `GmailQuotaPacer.shared`, and its tests pass their own pacer with a very high rate (1,000,000 units a second and burst) to switch pacing off.

## Deep Linking

Not applicable: the source has no URLs or routes.

## Localization

Not applicable: the source produces no user-facing strings; the one message, "the pacer needs a positive rate", is a developer-facing `precondition` text.

## Accessibility Options

Not applicable: the source has no display and responds to no accessibility setting.

## Feature Flags

Not applicable: the source reads no flag and has no switchable behavior.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the pacer holds one instant in memory and handles no account, message or credential data; it stores nothing and transmits nothing.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: Not a view, so nothing to translate. A SwiftUI app reaches the pacer only through `GmailRESTClient`; the pacer has no `Observable` or `ObservableObject` dependency and no UI state.
- **Compose**: Port as a Kotlin class whose non-suspending `reserve` is guarded by a `synchronized` block (a coroutine `Mutex` would make it `suspend`, which conflicts with `no-sleep`), because Kotlin has no actor type and the read-then-write of `drainedAt` must be one step. Use `kotlin.time.TimeSource.Monotonic` (a `TimeMark` per reservation) and `kotlin.time.Duration` (`Duration.Companion.seconds`, rounded to nanoseconds with `toLong(DurationUnit.NANOSECONDS)`). Inject the clock as a `() -> TimeMark` or a `TimeSource`. Callers `delay(wait)` for the returned wait. For the rate precondition use `require`, which throws `IllegalArgumentException` instead of trapping.
- **React/Web**: Port as a TypeScript class with a synchronous `reserve(units: number): number` returning milliseconds. JavaScript runs one task at a time, so no lock is needed as long as `reserve` does not `await`. Use `performance.now()` as the default clock (monotonic) and accept a `() => number` for tests. Callers `await new Promise(resolve => setTimeout(resolve, wait))`. Use a plain `number` in milliseconds and round only at the sleep, since a double holds fractional milliseconds; there is no `Int64` trap to match. `throw new RangeError` for the precondition.
- **AppKit / UIKit**: Source platform. The code is `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailQuotaPacer.swift`. It uses Foundation only for the file import and relies on the Swift standard library: `actor` for isolation, `ContinuousClock` and `ContinuousClock.Instant` for time, `Duration` with `.nanoseconds(Int64)` for the result, and `precondition` for the configuration check. `GmailQuotaCost` is a caseless internal `enum` in the same file, compiled into the SDK target (see the Xcode project file in `packages/apple/AgenticDeveloperHubSDK`). `GmailRESTClientTests` in `Tests/AgenticDeveloperHubSDKIntegrationsTests` holds the only pacer tests.
- **WinUI 3**: Write a `sealed class GmailQuotaPacer` in C#. .NET has no actor, so guard `Reserve` with a `lock` on a private object (a synchronous method, so `lock` is enough and `SemaphoreSlim` is not needed), keeping `drainedAt` as a nullable `long` of `Stopwatch` ticks. Take the clock as a `Func<long>` returning `Stopwatch.GetTimestamp()` by default; `Stopwatch` is monotonic like `ContinuousClock`, and `Stopwatch.Frequency` converts ticks to `TimeSpan` (use `TimeSpan.FromTicks`, which has 100 ns resolution, so the nanosecond rounding differs: 1 unit at 3 units a second returns 3,333,333 ticks, or 333,333,300 ns, not 333,333,333 ns). Return a `TimeSpan` clamped with `TimeSpan.Zero`, and have callers `await Task.Delay(wait, cancellationToken)`. Throw `ArgumentOutOfRangeException` for the rate precondition rather than trapping. Expose `static GmailQuotaPacer Shared { get; } = new(200, 200)` and `internal static class GmailQuotaCost` with `const int` fields. Register `Shared` as a singleton in `Microsoft.Extensions.DependencyInjection` if the app uses it. The pacer holds no observable state, so no `INotifyPropertyChanged` or `ObservableCollection` belongs in it.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailQuotaPacer.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Pace with the generic cell rate algorithm, one `drainedAt` instant, rather than a token bucket with a refill timer or a per-minute counter.
**Rationale**: The doc comment says Google enforces "a moving average of about 250 units a second". One instant gives that average exactly, needs no timer or background task, and makes `reserve` a pure calculation over the injected clock, which is why the tests can use a stopped clock.
**Approved**: pending

**Decision**: `reserve` returns a wait and the caller sleeps; the pacer does not sleep itself.
**Rationale**: The REST client already has an injected `sleep` that tests replace to record delays. Keeping the wait outside the actor means the actor is never suspended while holding a reservation, so concurrent callers are not blocked behind one sleeper.
**Approved**: pending

**Decision**: The shared instance runs at 200 units a second with a 200-unit burst, not Google's 250.
**Rationale**: The doc comment on `shared` says the figure is "below Google's 250 units a second, leaving room for ... other clients" (the comment also says clock drift, which does not apply to the monotonic `ContinuousClock`). The burst equals one second of rate. The cited Google figure is on its [quota page](https://developers.google.com/workspace/gmail/api/reference/quota). The 200 and 250 values are the source's choices; whether 200 leaves enough headroom for other clients is outside the source.
**Approved**: pending

**Decision**: One pacer is shared by every account in the process.
**Rationale**: The doc comment explains that each account has its own 250-unit allowance, so sharing only slows down syncing several accounts together and never lets one account exceed its quota. The cost is lost throughput when several accounts sync, in return for a single simple object.
**Approved**: pending

**Decision**: Reservations are final: a failed, retried or cancelled call keeps its reserved units.
**Rationale**: The source has no release operation, and the REST client reserves again for each retry. This over-counts rather than under-counts, which keeps the process under quota at the cost of some throughput after errors. This is non-obvious, so a port must not add a refund.
**Approved**: pending

**Decision**: The initializer traps on a non-positive rate instead of throwing.
**Rationale**: A bad rate is a programming error in code that passes constants, and a throwing initializer would force `shared` to be a throwing or optional value. The cost is that the check disappears under unchecked optimisation, and an overflowing duration is not checked at all.
**Approved**: pending

**Decision**: `reserve` takes a signed `Int` and does not validate its sign.
**Rationale**: A negative reservation shortens the backlog, which is behavior the source does not intend and its callers do not use. The open question on `units-nonnegative` records it so a port either copies or rejects it deliberately. It is settled when the owner decides whether to trap, clamp or accept it.
**Approved**: pending

**Decision**: The cost table is a set of `Int` constants in the same file, from Google's published table.
**Rationale**: The doc comment cites developers.google.com/workspace/gmail/api/reference/quota. Keeping costs beside the pacer keeps the unit scale and the rate in one place. The table covers only the calls `GmailRESTClient` makes; other Gmail methods have no entry.
**Approved**: pending

**Decision**: `shared` and `reserve` are public while `GmailQuotaCost` is internal.
**Rationale**: In the source only code inside the SDK module reserves quota, and it uses the cost constants. An outside caller of `shared` cannot name the costs and must supply its own unit counts; the source has no public cost table. This is what the code does, not a designed extension point.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.rate-limit-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/aed555ee-66e3-5f99-88ab-24674ed5c789) | partial | access-patterns |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

The pacer separates concerns cleanly: it computes a wait from an injected clock and leaves sleeping, sending, retrying and backoff to `GmailRESTClient`. Unit-test coverage is partial because no `GmailQuotaPacerTests` file exists; the only tests are two in `GmailRESTClientTests`, covering a burst and a zero burst with two sequential calls, and vectors pacer-003 to pacer-018 are derived from the code and are the backlog for a `GmailQuotaPacerTests` file. Rate-limit handling is partial: the pacer spaces calls ahead of time, while reacting to a 429 or a rate-limit 403 belongs to the REST client, and the pacer never learns that one happened. Explicit error handling is partial because the pacer raises no error, and a bad rate or an overflowing duration traps, while a negative `units` is accepted silently.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
