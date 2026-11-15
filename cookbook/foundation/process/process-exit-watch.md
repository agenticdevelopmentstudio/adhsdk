---
id: cfe3d3d4-1149-4fb6-8d77-47554026f389
title: "Process Exit Watch"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Learns that a child process has exited through a termination handler installed before launch, with a bounded wait and a terminate-then-kill stop."
platforms:
  - swift
  - macos
tags:
  - process
  - subprocess
  - concurrency
depends-on: []
related:
  - 705082e9-8fad-4c20-95a3-4cf843cc6b97
references: []
approved-by: ""
approved-date: ""
---

# Process Exit Watch

## Overview

Process Exit Watch tells a caller that a child process has exited, by the one route that always arrives: a termination handler installed on the process before it is launched. It exists because the obvious route does not always arrive. The doc comment on the `ProcessExitWatch` type in `ProcessExitWatch.swift` records that on macOS 26.6 a blocking wait-until-exit call can miss its wake-up for a child that exits within a few milliseconds, and park its thread for good: about one call in five against `/usr/bin/true`. The child is already reaped by then, so a timeout that polls `isRunning` never fires either. The termination handler, posted by the same reaping, was not seen to miss in 500 runs where the blocking wait missed 89. One missed wake-up can hold a caller's operation open for good and freeze everything queued behind it.

The type offers three things: installing the watch (`init`), a bounded wait (`waitForExit(timeout:)`), and an ending sequence (`stop(_:)`): terminate, a grace, kill, a second grace. `CommandRunner` is the whole-output form built on it. A caller that owns the process's streams (a pty transcript it scans as it arrives, or a stdout passed straight through) uses this type directly. See [adhsdk.ingredient.foundation.processes.command-runner](cookbook:705082e9-8fad-4c20-95a3-4cf843cc6b97), the ingredient for the command runner.

It is a final class, `ProcessExitWatch`, declared `@unchecked Sendable`, in the core framework.

## Behavioral Requirements

- **install-before-launch**: The watch MUST be created before the process is launched, and creating one for a process that is already running MUST fail a precondition with the message "ProcessExitWatch must be installed before run()".
- **handler-installed**: Creating the watch MUST install a termination handler on the process that signals the watch's exit signal when the process terminates.
- **handler-replaces**: Creating the watch MUST replace any termination handler already set on the process.
- **wait-signalled**: `waitForExit(timeout:)` MUST return true when the exit arrives within `timeout` seconds.
- **wait-timeout**: `waitForExit(timeout:)` MUST return false when the exit has not arrived after `timeout` seconds.
- **wait-sticky**: Once `waitForExit(timeout:)` has returned true, every later call MUST return true at once, whatever the `timeout`.
- **wait-already-exited**: `waitForExit(timeout:)` MUST return true without blocking when the exit has already been recorded.
- **wait-zero-timeout**: A `timeout` of 0 MUST give a non-blocking check: true when the exit signal is already waiting, otherwise false.
- **concurrent-waiters**: NEEDS REVIEW: Not implemented in source. The doc comment promises that once the exit has arrived every later call answers true at once, but the exit signal is a counting semaphore holding one count, so when two callers are blocked in `waitForExit(timeout:)` together only one is woken and the other waits out its whole timeout and returns false even though the process has exited. A test with two concurrent waiters, or a ruling that the type has one waiter, would settle it.
- **stop-same-process**: `stop(_:)` MUST be given the same process the watch was created for; the behavior with any other process is undefined, because the watch checks only its own exit signal and the source does not guard it.
- **stop-already-exited**: `stop(_:)` MUST return true without signalling the process when the exit has already been recorded.
- **stop-terminate-first**: `stop(_:)` MUST send the process `terminate()` (SIGTERM) first and then wait up to `terminationGrace` seconds for the exit.
- **stop-kill-second**: When the exit has not arrived after the first grace, `stop(_:)` MUST send SIGKILL to the process identifier and then wait up to `terminationGrace` more seconds.
- **stop-result**: `stop(_:)` MUST return true when the exit arrived during either grace and false when it did not.
- **stop-false-is-real**: When `stop(_:)` returns false the caller MUST NOT read the process's `terminationStatus`: a process blocked in an uninterruptible kernel wait (for example a read against a hung network mount) neither dies nor reaps.
- **grace-value**: `terminationGrace` MUST be 2 seconds.
- **stop-worst-case**: `stop(_:)` MUST NOT block for more than twice `terminationGrace` (4 seconds) plus the time to send the two signals, from the call.
- **exit-recorded-once-seen**: The watch MUST record that the exit has arrived only when a wait observes the signal, so a process that exited with no wait yet made is still reported by the next `waitForExit(timeout:)` or `stop(_:)`.
- **thread-safety**: The exit flag MUST be read and written under a lock, so `waitForExit(timeout:)`, `stop(_:)` and the flag can be used from any thread.
- **no-status-api**: The type MUST NOT expose the exit code or termination reason; callers read `terminationStatus` from the process themselves after a true result.

## Appearance

Not applicable — this is a process-lifecycle utility, not a visual component.

## States

Not applicable — this is a process-lifecycle utility, not a visual component. Its runtime state (not seen, exit seen) is covered under Behavioral Requirements.

## Accessibility

Not applicable — this is a process-lifecycle utility, not a visual component.

## Conformance Test Vectors

`ProcessExitWatchConformanceTests.swift` tests this type directly, skipping vectors 001, 009 and 012 with a reason; `CommandRunner`'s tests also exercise it through the runner. The vectors below follow the code and its doc comments, and a port should assert them with a short-lived child such as `/usr/bin/true` and a sleeping child.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| process-exit-watch-001 | install-before-launch | Create the watch for a process that is already running | The precondition fails with "ProcessExitWatch must be installed before run()" (a failed precondition ends the process, so this needs an exit test such as Swift Testing `#expect(processExitsWith:)` or a subprocess harness) |
| process-exit-watch-002 | handler-installed, wait-signalled | Create the watch, launch `/usr/bin/true`, call `waitForExit(timeout: 5)` | true, well before the 5 seconds |
| process-exit-watch-003 | wait-timeout | Create the watch, launch a child that sleeps 30 seconds, call `waitForExit(timeout: 0.2)` | false after about 0.2 seconds |
| process-exit-watch-004 | wait-sticky, wait-already-exited | After vector 002 returned true, call `waitForExit(timeout: 0)` and `waitForExit(timeout: 10)` | true both times, immediately |
| process-exit-watch-005 | wait-zero-timeout | Create the watch, launch a sleeping child, call `waitForExit(timeout: 0)` | false without blocking |
| process-exit-watch-006 | stop-terminate-first, stop-result | Launch a child that sleeps 30 seconds and call `stop(_:)` | true, within `terminationGrace`, and the child is gone |
| process-exit-watch-007 | stop-kill-second, stop-result, grace-value | Launch a shell that traps and ignores SIGTERM and sleeps, call `stop(_:)` | true after about 2 seconds (the first grace lapsed, SIGKILL ended it) |
| process-exit-watch-008 | stop-already-exited | After the child exited and `waitForExit` returned true, call `stop(_:)` | true at once, and no signal is sent |
| process-exit-watch-009 | stop-false-is-real, stop-worst-case | A process that neither dies on SIGTERM nor on SIGKILL (blocked in an uninterruptible wait). Manual or inspection-only: no portable setup produces one, so run it by hand against a read on a hung network mount, or inspect the code path | `stop(_:)` returns false after about 4 seconds, plus signal time |
| process-exit-watch-010 | exit-recorded-once-seen | Launch `/usr/bin/true`, sleep 1 second, then call `waitForExit(timeout: 0)` | true |
| process-exit-watch-011 | handler-replaces | Set a termination handler on the process, create the watch, launch, wait | `waitForExit` returns true and the earlier handler is not called |
| process-exit-watch-012 | no-status-api | Inspect the public interface | no member returns an exit code or a termination reason |

The requirement `concurrent-waiters` is an open question and has no vector.

## Edge Cases

- **Null and empty input**: There are no optional inputs. A `timeout` of 0 MUST give a non-blocking check. A negative `timeout` is not guarded: the deadline is already past, so the call behaves as a non-blocking check.
- **Boundary values**: A `timeout` large enough to overflow the dispatch deadline is not guarded by the source. The worst case of `stop(_:)` is two graces (4 seconds) plus the time to send the signals.
- **Concurrent access**: The exit flag is lock-protected, so reading it from several threads is safe. Two threads blocked in `waitForExit(timeout:)` together are covered by the open question on `concurrent-waiters`. A call made after one wait has returned true is answered at once.
- **Error states**: A process that cannot be reaped makes `stop(_:)` return false rather than throw; the caller decides what to do with a process it could not end. A `process.terminate()` on a process that was never launched is not guarded.
- **Handler timing**: A handler installed after launch can miss an exit that already happened; this is why the creation precondition exists and why the watch must be built before `run()`.
- **Lost wake-ups**: The wait MUST NOT depend on the blocking wait-until-exit call, which can miss its wake-up on macOS 26.6.
- **Reuse**: One watch serves one process; the exit flag is never reset, so a watch is not reusable across processes.
- **Offline or disconnected state**: Not applicable — this type does no network access.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `terminationGrace` | `TimeInterval` static constant | 2 seconds (not configurable; fixed by `grace-value`) | How long a terminated process is given to die before SIGKILL, and how long SIGKILL is given. |
| `init(_:)` argument | `Process` | none | The process to watch. It MUST NOT have been launched. |
| `timeout` | `TimeInterval` | none | The argument of `waitForExit(timeout:)`, in seconds. |
| `stop(_:)` argument | `Process` | none | The process to end; the same one the watch was built for. |

## Deep Linking

Not applicable: this component defines no URL scheme or route; it watches a child process.

## Localization

Not applicable: this component has no user-facing string; the one precondition message is a developer diagnostic.

## Accessibility Options

Not applicable: this component presents no UI, so it responds to no display-accessibility setting.

## Feature Flags

Not applicable: this component reads no feature flag or settings key.

## Analytics

Not applicable: this component contains no analytics or event-tracking call.

## Privacy

Not applicable: this component holds no user data, credential or environment; it sees only the process object and the exit event.

## Logging

Not applicable: this component contains no log call; a false result from `stop(_:)` is returned to the caller.

## Platform Notes

- **SwiftUI**: Not applicable: there is no UI. Use the Foundation type as it is. It is Foundation only and uses `Foundation.Process.terminationHandler`, a `DispatchSemaphore` with a zero start count for the signal, and an `NSLock` for the exit flag; `stop` sends SIGKILL through `kill(_:_:)`. The class is `@unchecked Sendable`, with all mutable state behind the lock.
- **Compose**: Use `java.lang.Process`: `onExit()` returns a `CompletableFuture` that completes on reaping, so `waitFor(timeout, unit)` or `onExit().get(timeout, unit)` gives the bounded wait; `destroy()` is the SIGTERM step and `destroyForcibly()` the SIGKILL step. A JVM process has no lost wake-up of this kind that the source records, so the watch can be a thin wrapper.
- **React/Web**: Node `child_process.spawn` returns a `ChildProcess`; attach the `'exit'` listener before the process can exit (spawn emits it asynchronously, so attaching right after `spawn` is safe), wrap it in a promise raced with `setTimeout`, and use `child.kill('SIGTERM')` then `child.kill('SIGKILL')` for the stop sequence. A browser cannot start processes.
- **AppKit / UIKit**: The same `Process` API is used on macOS. iOS cannot launch child processes, so this does not port to UIKit.
- **WinUI 3**: Use `System.Diagnostics.Process`. Set `EnableRaisingEvents = true` and subscribe to `Exited` before `Start()`, completing a `TaskCompletionSource<bool>` there (the counterpart of installing the termination handler before `run()`). Build `WaitForExit(timeout)` with `Task.WhenAny(tcs.Task, Task.Delay(timeout))` or the synchronous `Process.WaitForExit(int milliseconds)`. Windows has no SIGTERM: for the first step call `CloseMainWindow()` for a windowed process or send a console control event (`GenerateConsoleCtrlEvent` with `CTRL_BREAK_EVENT` for a process in its own group), then `Kill()` (or `Kill(entireProcessTree: true)`) as the second step. Keep the two 2-second graces, and keep the exit flag in a `volatile bool` or behind a `lock`. Several concurrent waiters are free with a `TaskCompletionSource`, which every awaiter shares, unlike the single-count semaphore of the source.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Process/ProcessExitWatch.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The exit is learned from a termination handler installed before launch, not from the blocking wait-until-exit call.
**Rationale**: See the Overview for the macOS 26.6 lost wake-up and its figures. As a past incident, one miss held a credential round open for good and froze every later account switch behind it.
**Approved**: pending

**Decision**: The watch is created before `run()`, and the initialiser traps with a precondition if the process is already running.
**Rationale**: A handler installed after launch can be installed after the exit it was meant to catch, so the caller error is made loud instead of a silent hang.
**Approved**: pending

**Decision**: `stop(_:)` has two steps: SIGTERM, then SIGKILL after a 2-second grace, each with its own wait.
**Rationale**: The doc comment on `terminationGrace` says a tool that ignores SIGTERM is exactly the tool a timeout exists for, so there has to be a second step; two seconds is long enough for an honest cleanup handler and short enough that nobody notices.
**Approved**: pending

**Decision**: `stop(_:)` returns false instead of throwing when the process is still there after both graces.
**Rationale**: The doc comment on `stop(_:)` says this is real: a process in an uninterruptible kernel wait neither dies nor reaps, and the caller must then not read `terminationStatus`. The caller owns the decision on what to do.
**Approved**: pending

**Decision**: The class is `@unchecked Sendable` with a lock around the exit flag.
**Rationale**: The semaphore and lock are thread-safe, and the one mutable field is guarded; the compiler cannot see that, so the conformance is stated by hand.
**Approved**: pending

**Decision**: The type reports only whether the exit arrived, not its status.
**Rationale**: The caller already holds the `Process` and reads `terminationStatus` from it after a true result; `CommandRunner` is the whole-output form that does this.
**Approved**: pending

**Decision**: Creating the watch replaces any termination handler already on the process.
**Rationale**: A `Process` has one termination handler slot, and the watch's guarantee that the exit signal arrives depends on owning it; chaining or failing on a set handler would add a second path for the exit to be lost. A caller that needs its own handler composes it after the watch reports the exit.
**Approved**: pending

**Decision**: `stop(_:)` takes the `Process` as an argument even though the watch was built for one.
**Rationale**: The watch does not store the process, so it needs one to signal; the shape is kept as the source has it, and passing a different process is undefined (`stop-same-process`). A parameterless `stop()` is the cleaner shape for a port that stores the process.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

`separation-of-concerns` passes: the type only watches an exit and ends a process; collecting output and deciding what a timeout means belong to `CommandRunner` and the callers. `unit-test-coverage` is partial: `ProcessExitWatchConformanceTests.swift` covers vectors 002 to 008, 010 and 011; vectors 001 (a failed precondition ends the test process), 009 (no portable setup makes a process survive SIGKILL) and 012 (an inspection of the public interface) are skipped. `timeout-handling` passes: every wait takes a timeout and the stop sequence is bounded at two graces. `fault-tolerance` is partial: it works around the lost wake-up and reports an unkillable process, but concurrent waiters are not handled (the open question on `concurrent-waiters`). `explicit-error-handling` passes: an unkillable process is returned as false, and a caller error is a precondition.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ProcessExitWatchConformanceTests.swift, 9 of 12 vectors; 001, 009, 012 skipped with reasons); unit-test-coverage stays partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Cited the lost wake-up once in Overview, added Design Decisions for handler replacement and the stop argument, added a stop-same-process requirement, linked the command runner, settled the stop bound, and clarified vectors 001 and 009, the Configuration row and the SwiftUI note. |
