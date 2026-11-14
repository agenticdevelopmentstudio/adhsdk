---
id: 667825e5-d557-4410-b54e-29dcf98ca930
title: "RaceBox"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A one-shot, thread-safe result cell: racing tasks call finish, the first wins, and value() releases every waiter at once even if the losing tasks never end."
platforms:
  - swift
  - macos
tags:
  - concurrency
  - race
  - timeout
  - cancellation
depends-on: []
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - fafeef0d-c283-4ecf-92fb-b5de35d71f79
references: []
approved-by: ""
approved-date: ""
---

# RaceBox

## Overview

`RaceBox<T>` is a small internal class in `Integrations/Support/RaceBox.swift`. Several tasks race to settle it with a `Result<T, Error>`; the first call to `finish` wins and every later call is ignored. Any number of callers can wait on `value()`, and all of them are released the moment the box settles.

The source comment gives the reason it exists: unlike a task group, a waiter is released as soon as the box settles, even if the losing tasks never finish. The integration code uses it to put a deadline around work that may ignore cancellation: `withSignInDeadline` (Google sign-in) and `MailIntegrationService.stop(timeout:)` each race the work, a timer and, for sign-in, the caller's cancellation.

The type is generic over `T: Sendable`, is marked `@unchecked Sendable`, and guards its two pieces of mutable state (the settled result and the waiter list) with one `NSLock`. It does no I/O, starts no task, and logs nothing. It imports `Foundation` only and is internal to the SDK module. A Swift actor could replace the `NSLock` and the `@unchecked Sendable`, but `finish` would then be async; the synchronous `finish` is what lets a cancellation handler call it, so the source keeps the lock.

## Behavioral Requirements

### Construction and shape

- **generic-sendable-payload**: `RaceBox` MUST be generic over a payload type `T` that conforms to `Sendable`.
- **no-arguments-init**: `RaceBox` MUST be constructible with `init()` and no arguments, and a new box MUST be unsettled with no waiters.
- **cross-task-use**: `RaceBox` MUST be safe to call from any number of tasks and threads at once. Every read and write of the settled result and the waiter list is mutually exclusive (the Swift source declares `@unchecked Sendable` and backs this with one `NSLock`).

### finish

- **finish-signature**: `finish(_ outcome: Result<T, Error>)` MUST take the outcome as a `Result` (a value or an `Error`) and MUST return a `Bool`; the result is `@discardableResult`.
- **first-finish-wins**: The first call to `finish` on an unsettled box MUST store its outcome and MUST return `true`.
- **later-finish-ignored**: A call to `finish` on a box that is already settled MUST return `false` and MUST NOT change the stored outcome.
- **winner-decided-atomically**: Checking whether the box is settled and storing the outcome MUST be one atomic step, so exactly one of any set of concurrent `finish` calls returns `true`.
- **failure-is-an-outcome**: `finish(.failure(error))` MUST settle the box the same way a success does; a failure counts as the winning call.
- **release-all-waiters**: The winning `finish` MUST resume every waiter that was suspended in `value()` with the winning outcome, in the order they were added.
- **waiters-cleared**: The winning `finish` MUST empty the waiter list when it settles the box, so no continuation is resumed twice.
- **resume-outside-lock**: The winning `finish` MUST resume waiters after the lock is released, so a resumed continuation can call back into the box without deadlocking.
- **loser-resumes-nothing**: A losing `finish` MUST NOT resume any waiter.

### isFinished

- **is-finished-flag**: `isFinished` MUST return `false` on an unsettled box and `true` once any `finish` has won, and it MUST read the state atomically with respect to `finish`.

### value

- **value-signature**: `value()` MUST be `async throws` and MUST return `T`.
- **value-after-settle**: When the box is already settled, `value()` MUST return the stored success value at once, or throw the stored error, without waiting for a `finish`.
- **value-waits**: When the box is unsettled, `value()` MUST suspend until a `finish` wins.
- **value-delivers-outcome**: A waiter MUST receive the winning outcome: the value for `.success`, the thrown `Error` for `.failure`.
- **value-register-atomic**: `value()` MUST read the stored result and register its waiter as one atomic step, so a waiter registered concurrently with a settle is neither missed nor resumed twice.
- **value-many-callers**: Any number of callers MAY call `value()` on one box, before or after it settles; every one MUST get the same outcome.
- **value-repeatable**: A call to `value()` after the box has settled MUST return the same outcome each time; the outcome is not consumed.

### Lifetime and cancellation

- **one-shot**: A settled box MUST stay settled; there is no reset, and the outcome never changes.
- **losers-not-awaited**: The box MUST NOT wait for, track or cancel the tasks that lose the race; releasing waiters depends only on a winning `finish`.
- **value-not-cancellable**: `value()` itself MUST NOT react to cancellation of the calling task; the source registers a checked continuation and nothing else, so a caller that wants cancellation to end the wait must race a `finish` of its own (as `withSignInDeadline` does with `withTaskCancellationHandler`).
- **never-settled-never-returns**: If no `finish` is ever called, `value()` suspends for as long as the box lives. The box has no timeout of its own; the owner supplies one by racing a timer.

## Appearance

Not applicable — this is a concurrency primitive, not a visual component.

## States

Not applicable — this is a concurrency primitive, not a visual component. Its runtime states (unsettled, settled) are under Behavioral Requirements.

## Accessibility

Not applicable — this is a concurrency primitive, not a visual component.

## Conformance Test Vectors

The source has no `RaceBox` test file. The vectors come from the code and its doc comments; the rows that name a test are the existing tests of its two callers, which exercise the same race through `withSignInDeadline` and `MailIntegrationService.stop(timeout:)`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| race-box-001 | first-finish-wins, is-finished-flag | New `RaceBox<Int>`; call `finish(.success(1))` | Returns `true`; `isFinished` is `true`; `value()` returns `1` |
| race-box-002 | later-finish-ignored | After race-box-001, call `finish(.success(2))` then `finish(.failure(E))` | Both return `false`; `value()` still returns `1` |
| race-box-003 | value-waits, release-all-waiters, value-delivers-outcome | New box; start three tasks each awaiting `value()`; then `finish(.success(7))` | All three tasks return `7`; `finish` returned `true` |
| race-box-004 | failure-is-an-outcome, value-delivers-outcome | New box; a task awaits `value()`; `finish(.failure(E))` | The awaiting task throws `E`; a later `finish(.success(1))` returns `false` |
| race-box-005 | value-after-settle, value-repeatable | Settled box holding `.success(5)`; call `value()` twice | Both calls return `5` without waiting for a `finish` |
| race-box-006 | winner-decided-atomically | New box; 100 tasks each call `finish` with a distinct value at once | Exactly one call returns `true`; `value()` returns the value of that caller |
| race-box-007 | value-register-atomic | New box; one task calls `value()` while another calls `finish` at the same moment, repeated many times | Every `value()` returns the winning outcome; none hangs and none crashes with a double resume |
| race-box-008 | losers-not-awaited, release-all-waiters | A box raced by a work task that never returns and a timer that calls `finish(.failure(timeout))`. Source test: `deadlineIsPromptEvenWhenTheOperationIgnoresCancellation` in `GoogleOAuthTests.swift` | `value()` throws the timeout error promptly; the work task is still suspended |
| race-box-009 | first-finish-wins | Work and timer both race; the work finishes first with `.success(42)`. Source test: `deadlineReturnsOperationResult` | `value()` returns `42`; a later `finish` (from the timer, if it fires before the caller's `defer` cancels it) returns `false` and cancels nothing |
| race-box-010 | never-settled-never-returns | New box; a task awaits `value()`; no `finish` is ever called | The task is still suspended and `isFinished == false` after 200 ms; a later `finish` releases it |
| race-box-011 | value-not-cancellable | New box; a task awaits `value()` and is cancelled; no `finish` is called | The task is still suspended and `isFinished == false` after 200 ms; a later `finish` releases it |
| race-box-012 | resume-outside-lock | A waiter's continuation calls `isFinished` and `value()` as soon as it resumes | Both return at once; no deadlock |
| race-box-013 | first-finish-wins, losers-not-awaited | `MailIntegrationService.stop(timeout: .milliseconds(200))` with a sync that ignores cancellation and outlives the timeout. Both racers (the stop waiter and the stop timer) settle with `.success(())`, not a failure, unlike race-box-008. Source test: the stop-bound test in `MailIntegrationServiceTests.swift` (`stopGivesUpOnASyncThatIgnoresCancellation`) | `stop` returns after at least 150 ms and under 5 s, not when the sync ends |

## Edge Cases

- **Finish before any waiter**: `finish` on a box with no waiters MUST settle it and return `true`; a later `value()` returns the stored outcome (`value-after-settle`).
- **Finish with a `CancellationError`**: The box stores whatever `Error` it is given and does not interpret it; callers map cancellation to their own error before calling `finish` (`withSignInDeadline` does). The box MUST NOT rewrite the error.
- **Two finishes at the same instant**: Exactly one MUST win; the lock serialises them, and lock order alone decides which. The loser MUST get `false`.
- **Waiter added while `finish` is resuming others**: A `value()` call that takes the lock after the winner stored the result MUST see the result and resume itself; one that took it before is in the list the winner resumes. Neither MUST be resumed twice or missed (`value-register-atomic`).
- **Box never settled**: `value()` stays suspended. The box has no timeout, no deinit hook and no cancellation path, so a waiter on a box nobody finishes is never released. This is a fact of the source, not a gap: every caller in the repo pairs the box with a timer.
- **Dropped box with waiters**: A suspended `value()` call is a method running on the box, so it keeps the box alive; a box with waiters cannot be released by its other owners going away. It stays suspended until some `finish` wins, as in the never-settled case.
- **Payload copies**: `T` is stored once and handed to every waiter by value through `Result`; `T: Sendable` is the only constraint, so a large value type is copied per waiter.
- **Null and empty input**: `Result<T, Error>` has no empty form; `T` MAY itself be `Void` (the stop path uses `RaceBox<Void>`). An empty waiter list is the normal case for `finish` and MUST be accepted.
- **Boundary values**: Not applicable: the box has no size, count or time parameter.
- **Concurrent access**: Covered by `cross-task-use` and `winner-decided-atomically`; every read and write of `result` and `waiters` is inside `lock.withLock`.
- **Error states and offline state**: Not applicable: the box calls no network, file or other dependency; the only errors it carries are the ones passed to `finish`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `T` | `Sendable` generic parameter | none, required | The success value the box carries. |

Nothing else is configurable: there are no environment variables, settings keys, timeouts or injected dependencies. The deadline and cancellation hooks belong to the callers.

## Deep Linking

Not applicable: the type exposes no URL or navigation entry point.

## Localization

Not applicable: the file holds no user-facing string. The text `Sign-in timed out` in the sign-in race is written by `withSignInDeadline`, not by `RaceBox`.

## Accessibility Options

Not applicable: the type has no visual output, motion or colour, so no display option applies.

## Feature Flags

Not applicable: the source reads no flag or setting; behavior is fixed.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: None by the box. It holds whatever payload or error its callers give it for as long as the box lives.
- **Storage**: In memory only, in the `result` field.
- **Transmission**: None.
- **Retention**: The outcome lives as long as the box is referenced; nothing is written to disk.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: Not used directly by SwiftUI: a host never touches `RaceBox`. The source is `packages/apple/AgenticDeveloperHubSDK/Integrations/Support/RaceBox.swift`.
- **Compose**: Kotlin's equivalent is `CompletableDeferred<T>`: `complete(value)` and `completeExceptionally(error)` both return `false` once it is settled, and `await()` suspends until then, so first-wins is built in. Race a timer with `withTimeout` or `select`. `await()` does react to cancellation of the awaiting coroutine, which differs from the source's `value()`.
- **React/Web**: Use a `Promise` with its `resolve` and `reject` captured in a closure: the first call settles it and later calls are ignored, and `await` releases every waiter in registration order. Keep a settled flag if the caller needs the `Bool` that `finish` returns. JavaScript is single-threaded, so no lock is needed. `Promise.race` over a work promise and a timeout promise gives the same prompt release.
- **AppKit / UIKit**: Same Swift source as above; it compiles unchanged on macOS and iOS because it uses only `Foundation` and the concurrency runtime. A view controller reaches it only through the helpers that wrap it.
- **WinUI 3**: In C#, use `TaskCompletionSource<T>` created with `TaskCreationOptions.RunContinuationsAsynchronously`. `TrySetResult(value)` and `TrySetException(error)` return `false` once it is settled, which maps to `finish` returning `false`; the first caller wins atomically, so no `lock` is needed for the settle itself. `await tcs.Task` is `value()`, and many awaiters are allowed. `RunContinuationsAsynchronously` is the equivalent of the source resuming waiters outside its lock, so a continuation never runs inside the caller of `TrySet*`. `isFinished` is `tcs.Task.IsCompleted`. Map `Result.failure` to `TrySetException`, or to `TrySetCanceled` if you want an `OperationCanceledException`. Race the work against `Task.Delay(timeout)` with `Task.WhenAny`, or settle the box from a `CancellationToken.Register` callback, as the source does with `withTaskCancellationHandler`. A `TaskCompletionSource` does not observe the awaiter's cancellation, which matches `value-not-cancellable`. This is a plain class with no `ObservableCollection` or `INotifyPropertyChanged`, because nothing binds to it.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Support/RaceBox.swift` | unverified |
| web | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: First `finish` wins and later calls are ignored, and `finish` returns whether the caller won.
**Rationale**: The callers use the return value to decide who runs the cleanup: the timer in `withSignInDeadline` calls `cancel()` and cancels the work only if its `finish` won, and the cancellation handler calls `cancel()` only if its `finish` won (it cancels the work either way). A port MUST keep the winner signal, not only the first-wins rule.
**Approved**: pending

**Decision**: A box is used instead of a task group.
**Rationale**: The source comment says so: a task group waits for all its children, so a hung child would hold up the caller. The box releases waiters when it settles and does not wait for the losing tasks.
**Approved**: pending

**Decision**: `value()` registers the waiter and checks the stored result under one lock, and `finish` resumes waiters after the lock is released.
**Rationale**: This closes the window between "not settled yet" and "waiting" so a concurrent settle cannot be missed, and it keeps continuations from running while the lock is held. Both are required to avoid a hang and a deadlock.
**Approved**: pending

**Decision**: The class is `@unchecked Sendable` with a hand-written `NSLock`.
**Rationale**: The compiler cannot verify a mutable class, so the type asserts its own safety; every access to `result` and `waiters` goes through the lock. A port with a built-in settle-once primitive does not need this.
**Approved**: pending

**Decision**: `value()` does not respond to cancellation of the caller.
**Rationale**: Cancellation is the caller's job, so the sign-in race wires it to `finish` through `withTaskCancellationHandler`. This keeps the box a pure race cell with no knowledge of tasks.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | reliability |

The type does one job, settling a result once and releasing waiters, and leaves timers, cancellation and cleanup to its callers, so separation of concerns passes. There is no `RaceBox` test file beside the source, so vectors race-box-001 to 007 and 010 to 012 are not run by any test; the box is exercised only through the deadline tests of `withSignInDeadline` and the stop-bound test of `MailIntegrationService`, which makes unit-test coverage partial. The box is what lets those callers return at their deadline even when the work ignores cancellation, so timeout handling passes. It does not itself time out, and a box that is never finished leaves its waiters suspended, so fault tolerance is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
