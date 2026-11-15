---
id: 78390c0c-2610-4480-8a93-0a2dad559126
title: "Command Running"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A seam for running an external command to completion and reporting its exit status and output, with a real child-process implementation and a double-friendly default."
platforms:
  - swift
  - macos
tags:
  - process
  - subprocess
  - testing-seam
depends-on:
  - 705082e9-8fad-4c20-95a3-4cf843cc6b97
related: []
references: []
approved-by: ""
approved-date: ""
---

# Command Running

## Overview

Command Running is the seam launch jobs use to run an external command (`launchctl`, `pkgutil` and similar) and learn two things: the exit status and the text the command wrote. It has two parts. The `CommandRunning` protocol is the contract a caller depends on, so tests can substitute a recorder. `ProcessCommandRunner` is the real implementation: it starts a child process off the cooperative thread pool, reads both of the child's output streams while it runs, and gives up on a child that does not finish within a backstop time.

The protocol has two operations. `run` reports one merged text (stdout followed by stderr, not interleaved). `capture` keeps stdout and stderr apart and can replace the child's environment. A double that implements only `run` still gets a working `capture` from a protocol default. The name is `CommandRunning` because `CommandRunner` is the synchronous process runner that `ProcessCommandRunner` wraps (see [adhsdk.ingredient.foundation.processes.command-runner](cookbook:705082e9-8fad-4c20-95a3-4cf843cc6b97)).

## Behavioral Requirements

- **sendable-seam**: A `CommandRunning` implementation MUST be safe to share across concurrency domains (the protocol is `Sendable`), and both operations MUST be asynchronous.
- **run-result-shape**: `run` MUST return a pair of the child's exit status and an output string.
- **run-merged-output-order**: `run` MUST build its output as the child's stdout text followed by the child's stderr text, never interleaved.
- **capture-result-shape**: `capture` MUST return the exit status, the stdout text and the stderr text as three separate values.
- **capture-streams-apart**: `capture` MUST NOT place any stderr text in `stdout`, so a caller that parses stdout never sees stderr noise.
- **capture-environment-replacement**: When `capture` is given a non-nil `environment`, `ProcessCommandRunner` MUST give the child exactly that dictionary as its whole environment, with no variable inherited from the calling process.
- **capture-environment-inherited**: When `capture` is given a nil `environment`, the child MUST inherit the calling process's environment.
- **capture-default-from-run**: The protocol's default `capture` MUST call `run` and return its status, its whole output as `stdout`, and `""` as `stderr`.
- **capture-overload-default**: The one-argument `capture(_:)` MUST behave exactly as `capture(_:environment:)` called with a nil `environment`.
- **run-inherits-environment**: `run` MUST run the child with the calling process's environment.
- **empty-command**: An empty `argv` MUST NOT launch anything and MUST report status -1 with the text `empty command` (as the whole output for `run`, as `stderr` with an empty `stdout` for `capture`).
- **argv-split**: The first element of `argv` MUST be the executable and the remaining elements MUST be its arguments, passed without a shell.
- **path-lookup**: A first element with no `/` MUST be looked up directory by directory on the child's `PATH` (the replacement environment's `PATH` when one is given, otherwise the calling process's), and the first directory holding an executable file of that name MUST win.
- **path-default**: When there is no `PATH` value to search, the lookup MUST search `/usr/bin:/bin:/usr/sbin:/sbin`.
- **path-empty-entries**: Empty entries in the `PATH` value MUST be skipped.
- **path-miss**: When no `PATH` directory holds an executable of that name, the name MUST be used unchanged, so the launch fails and reports the launch error.
- **slash-verbatim**: A first element that contains a `/` MUST be used as the executable path without any lookup.
- **launch-failure**: A command that cannot be launched MUST report status -1 and the launch error's localized description, and MUST NOT crash.
- **exit-status-passthrough**: A command that ran MUST report its own exit status, whether zero or not.
- **stream-draining**: Both output streams MUST be read while the child writes, so output larger than a 64 KB pipe buffer is returned in full and the call does not deadlock.
- **utf8-decoding**: Each stream MUST be decoded as UTF-8, and a stream whose bytes are not valid UTF-8 MUST contribute an empty string rather than an error.
- **backstop-default**: `ProcessCommandRunner` MUST give a command at most `backstop` seconds, defaulting to 600.
- **backstop-timeout-report**: A command that outlives the backstop MUST be terminated (`SIGTERM`, then `SIGKILL` after a 2-second grace if it is still alive) and reported with status -1 and the text `timed out after <backstop>s` appended on a new line after the collected text (to the merged output for `run`, to `stderr` for `capture`).
- **timeout-never-success**: A command that outlives the backstop MUST report status -1 even if it later exits with status 0 (a child that traps `SIGTERM` can).
- **off-pool-execution**: `ProcessCommandRunner` MUST run the blocking process work off the cooperative thread pool, on a thread whose quality-of-service class is the default class regardless of the caller's class.
- **stdin-not-supplied**: `ProcessCommandRunner` MUST NOT supply input to the child, so the child's stdin is the calling process's stdin.
- **no-cancellation**: Cancelling the awaiting task MUST NOT stop a running child; only the backstop ends it early.

## Appearance

Not applicable — this is a process-running seam, not a visual component.

## States

Not applicable — this is a process-running seam, not a visual component. Each call runs once from launch to result with no state kept between calls; the runtime outcomes (ran, could not launch, timed out) are covered under Behavioral Requirements.

## Accessibility

Not applicable — this is a process-running seam, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| command-running-001 | run-result-shape, run-merged-output-order, argv-split, exit-status-passthrough | `run(["/bin/echo", "hi"])` (test: echo returns its output and status 0) | status 0, output `hi\n` |
| command-running-002 | capture-result-shape, capture-streams-apart, capture-environment-inherited, exit-status-passthrough | `capture(["/bin/sh", "-c", "echo out; echo err 1>&2; exit 3"], environment: nil)` (test: capture keeps stdout and stderr apart) | status 3, stdout `out\n`, stderr `err\n` |
| command-running-003 | capture-environment-replacement | `capture(["/usr/bin/env"], environment: ["ONLY_THIS": "1"])` (test: capture replaces the environment) | status 0, stdout exactly `ONLY_THIS=1\n` |
| command-running-004 | path-lookup, run-inherits-environment | `run(["echo", "bare"])` (test: a name without a slash resolves through env) | status 0, output `bare\n` |
| command-running-005 | exit-status-passthrough | `run(["/usr/bin/false"])` (test: false returns a non-zero status) | status is non-zero |
| command-running-006 | stream-draining | `run(["/usr/bin/head", "-c", "200000", "/dev/zero"])` (test: large output is returned in full) | status 0, output holds exactly 200000 UTF-8 bytes |
| command-running-007 | launch-failure | `run(["/nonexistent/definitely-not-here"])` (test: a missing executable fails without crashing) | status -1 and the call returns |
| command-running-008 | backstop-timeout-report, timeout-never-success | `ProcessCommandRunner(backstop: 0.2).run(["/bin/sleep", "30"])` (test: a timed-out run reports failure) | status -1, output ends with `\ntimed out after 0.2s` |
| command-running-009 | capture-default-from-run, capture-overload-default | A double implementing only `run`, returning status 7 and output `a b` for the arguments `a` and `b`; call `capture(["a", "b"])` (test: the default capture is built on run) | status 7, stdout `a b`, stderr empty |
| command-running-010 | empty-command | `run([])` and `capture([], environment: nil)` | `run` gives status -1 and output `empty command`; `capture` gives status -1, empty stdout, stderr `empty command` |
| command-running-011 | path-miss | The lookup on name `nope` with search path `/usr/bin` | returns `nope` unchanged |
| command-running-012 | slash-verbatim | The lookup on name `/bin/echo` with search path `/nonexistent` | returns `/bin/echo` |
| command-running-013 | path-default, path-empty-entries | A temporary directory `D` holding an executable file `tool`; the lookup on name `tool` with search path `::D`; then the lookup on name `sh` with no search path | `D/tool`; then the path of `sh` in the first of `/usr/bin`, `/bin`, `/usr/sbin`, `/sbin` (in that order) that holds an executable `sh` |
| command-running-014 | backstop-timeout-report | `ProcessCommandRunner(backstop: 0.2).capture(["/bin/sh", "-c", "echo before; sleep 30"], environment: nil)` | status -1, stdout `before\n`, stderr ends with `\ntimed out after 0.2s` |
| command-running-015 | utf8-decoding | `run(["/usr/bin/printf", "\\377"])` (one byte that is not valid UTF-8) | status 0, output empty |
| command-running-016 | backstop-default | `ProcessCommandRunner().backstop` | 600 |

The requirements `sendable-seam`, `off-pool-execution`, `stdin-not-supplied` and `no-cancellation` have no vector: they are scheduling and stream-wiring facts that a unit test cannot observe without instrumenting the thread or the child's stdin, and the source has no test for them. A port copies the behavior from the requirement text.

## Edge Cases

- **Null and empty input**: An empty `argv` MUST report status -1 and `empty command` without launching (`empty-command`). A command that writes nothing MUST return an empty string for each stream. A nil `environment` MUST mean inherit, while an empty dictionary MUST be applied as the child's whole (empty) environment, and with no `PATH` in it the lookup MUST use the default search directories.
- **Boundary values**: A bare name found in no `PATH` directory MUST fall through to the launch failure path. An output of 200,000 bytes MUST be returned whole. A `backstop` of 0 or less is not validated by this type; it passes straight to the process runner, so such a run is treated as already out of time and reports status -1 with the timeout text unless the child has already exited.
- **Concurrent access**: `ProcessCommandRunner` is a value type with one immutable property (`backstop`) and keeps no state between calls, so concurrent calls MUST be independent. Each call runs its own child on its own thread.
- **Error states**: A launch error (missing file, no permission) MUST be reported as status -1 with the error text, never thrown. A timeout MUST be reported as status -1 with the timeout text appended. Both use the same status, so a caller can tell them apart only by the text.
- **Undecodable output**: A stream that is not valid UTF-8 MUST be replaced by an empty string; the status is still reported, and the result does not say a stream was dropped.
- **Cancellation**: There is no cancellation. Cancelling the awaiting task leaves the child running until it exits or the backstop fires (`no-cancellation`).
- **Offline or disconnected state**: Not applicable — this type does no network access of its own; a command that does reports its own failure through its exit status and output.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `backstop` (initializer) | `TimeInterval` seconds | 600 | The longest a command may run before it is terminated and reported with status -1. The source calls it "far past any legitimate helper run". |
| `argv` (each call) | array of strings | none, required | Executable first, then its arguments. |
| `environment` (`capture` only) | optional dictionary of strings | nil (inherit) | When non-nil, replaces the child's whole environment and supplies the `PATH` used for the lookup. |
| search `PATH` | string | `/usr/bin:/bin:/usr/sbin:/sbin` when none is available | Colon-separated directories searched for a bare name. |
| built-on dependencies | `CommandRunner.runToCompletion` and `BlockingWork.run` | fixed (static calls, not injectable) | The process runner and the off-pool hop `ProcessCommandRunner` is built on; the seam for substitution is the `CommandRunning` protocol, not these. |

## Deep Linking

Not applicable: this component defines no URL scheme or route; it runs operating-system processes.

## Localization

Not applicable: the only strings this component authors are the fixed English markers `empty command` and `timed out after <backstop>s`, which are machine-readable parts of a result for a calling job, not text shown to a person; launch errors carry the system's own localized description.

## Accessibility Options

Not applicable: this component presents no UI, so it responds to no display-accessibility setting.

## Feature Flags

Not applicable: this component reads no feature flag or settings key.

## Analytics

Not applicable: this component contains no analytics or event-tracking call.

## Privacy

Not applicable: this component stores nothing and transmits nothing. It keeps a command's output in memory for the duration of one call and returns it to the caller; the command line and environment it is handed are the caller's to choose.

## Logging

Not applicable: this component contains no log call; a caller that wants a failed command logged does so from the returned status and text.

## Platform Notes

- **SwiftUI**: It imports only Foundation, so nothing in it is SwiftUI-specific; a view model holds a `CommandRunning` value and awaits it. The protocol is `Sendable` so a test can pass a recorder across tasks.
- **Compose**: Define an interface with a suspend `run(argv)` and a suspend `capture(argv, environment)` returning a data class of status, stdout and stderr. Implement it with `ProcessBuilder` on `Dispatchers.IO`, reading both streams on separate coroutines, and `withTimeoutOrNull` for the backstop. Call `environment().clear()` then `putAll` for the replace-the-environment behavior. `ProcessBuilder` resolves a bare name against the parent's `PATH`, not the replacement's, so the source's explicit lookup has to be written out.
- **React/Web**: In Node, an object with async `run` and `capture` over `child_process.spawn` with an `env` option (a plain object replaces the environment, matching the source). Collect `stdout` and `stderr` from their `data` events, use `setTimeout` plus `kill` for the backstop, and map a spawn `error` event to status -1. A browser has no equivalent and needs a server endpoint.
- **AppKit / UIKit**: `Foundation.Process` exists only on macOS; iOS has no way to run an external command, so this does not port to UIKit. On AppKit, the hop through `BlockingWork.run` at default quality of service avoids the priority inversion a direct launch-and-wait on the main thread would cause.
- **WinUI 3**: Define an `ICommandRunning` interface with `Task<(int Status, string Output)> RunAsync(IReadOnlyList<string> argv)` and `Task<(int Status, string Stdout, string Stderr)> CaptureAsync(IReadOnlyList<string> argv, IDictionary<string, string>? environment)`. Implement with `System.Diagnostics.Process` and `ProcessStartInfo` (`RedirectStandardOutput`, `RedirectStandardError`, `UseShellExecute = false`, and `ArgumentList` so the argv goes without a shell). Replace the environment with `psi.Environment.Clear()` and then fill it. Read both streams at once with `StandardOutput.ReadToEndAsync` and `StandardError.ReadToEndAsync` to avoid the pipe deadlock. Use a `CancellationTokenSource` with a `TimeSpan` plus `Process.Kill(entireProcessTree: true)` for the backstop. A bare name resolves through `PATH` and `PATHEXT` on Windows, so the source's rule that a `/` marks a path becomes a check for a directory separator. A launch failure surfaces as `Win32Exception`, which maps to status -1 with its `Message`. .NET tasks can be cancelled, but the source has no cancellation, so adding it is a deliberate divergence.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Process/CommandRunning.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `capture` has a protocol default built on `run` that returns the merged output as stdout.
**Rationale**: Per the source comment, doubles that only implement `run` still need a working `capture`; the default keeps a one-method test recorder valid. The cost is that such a double never shows a separate stderr.
**Approved**: pending

**Decision**: Launch failure and timeout both report status -1, with the cause in the text.
**Rationale**: The result is a simple pair, and launch jobs treat any non-zero status as failure. The source states "a timeout is never success", because a child that traps `SIGTERM` can still exit 0. The cost is that a caller must read the text to tell a launch failure from a timeout, and an undecodable stream becomes an empty string with no signal. This is accepted debt; it is revisited with a typed outcome on the result when a caller needs to branch on the cause instead of reading text.
**Approved**: pending

**Decision**: The backstop is 600 seconds and is a constructor setting, not a per-call argument.
**Rationale**: The source calls it a "backstop for a wedged helper so a caller fails instead of hanging forever; the default is far past any legitimate helper run". It is a safety net, not a tuned limit for any one command.
**Approved**: pending

**Decision**: A bare command name is resolved by this type against the child's `PATH`, not left to the operating system.
**Rationale**: The launcher takes a path only. The lookup runs against the replacement environment's `PATH` when one is given, so a command is found as a shell would find it with that environment. A miss keeps the name so the launch error carries the failure text.
**Approved**: pending

**Decision**: The blocking work runs at default quality of service, enforced.
**Rationale**: The source comment says the drain threads run at default, and waiting on them from the caller's (often main-thread) class is a priority inversion.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | performance |

`separation-of-concerns` passes: the protocol is the seam, the struct only launches and collects, and what to run and what to do with a result belong to the calling jobs. `unit-test-coverage` passes: `ProcessCommandRunnerTests.swift` covers all 16 vectors, including the empty command, undecodable output, the path lookup and the timed-out `capture` text. `explicit-error-handling` is partial: every failure is reported rather than thrown or crashed, but launch failure and timeout share status -1 and an undecodable stream becomes an empty string with no signal. `timeout-handling` passes through the backstop. `main-thread-freedom` passes because the blocking work is moved off the cooperative pool.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ProcessCommandRunnerTests.swift, 16 of 16 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Dropped 'injected' wording, recorded launch/timeout status sharing as accepted debt, fixed vectors 007/008/009/013, added a backstop-default vector, moved the command-runner link to depends-on and removed the source path from the SwiftUI note. |
