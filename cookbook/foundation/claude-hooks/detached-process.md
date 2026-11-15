---
id: 866770e9-cc76-452f-8216-ee98a8fa1390
title: "Detached Process"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Starts a command that outlives the caller and hangs off launchd, with a payload on its input, plus a per-session non-blocking feed lock."
platforms:
  - swift
  - macos
tags:
  - claude-hooks
  - foundation
  - process
depends-on: []
related:
  - 517adfce-44e7-404e-8a7b-b1e304da32e7
references: []
approved-by: ""
approved-date: ""
---

# Detached Process

## Overview

`DetachedProcess` starts a command that outlives the process that started it and is no one's child but launchd's. A `/bin/sh` trampoline starts the command in the background and exits at once, so by the time `spawn` returns the command has been reparented. The motivating caller is the status-line dispatcher (see [adhsdk.ingredient.foundation.claude-hooks.claude-status-line](cookbook:517adfce-44e7-404e-8a7b-b1e304da32e7)), though nothing in the type ties it to that caller. The dispatcher kills a timed-out renderer by walking its descendants; a process reparented this way is out of that walk's reach, and it leaves the caller's session too, so a signal to the terminal's process group misses it as well.

`FeedLock` is its companion. Claude Code re-renders the status line often, and a feed can take seconds, so each session gets one non-blocking `flock` lock (the file name carries the fixed infix `-statusline-feed-`, a status-line-specific choice): a render that finds the previous feed still running skips its own, and the next render carries the newer snapshot.

## Behavioral Requirements

### Spawning

- **spawn-result**: `spawn(executable:arguments:environment:stdin:)` MUST return true once the trampoline was started and false when nothing could be started (the pipe could not be made or the spawn failed).
- **spawn-trampoline**: The command MUST be started by a `/bin/sh -c` trampoline that backgrounds it and exits, with the executable and its arguments passed as positional parameters (`exe=$1; shift; "$exe" "$@"`) so no argument is ever re-parsed by the shell.
- **spawn-reparent**: By the time `spawn` returns the trampoline MUST have exited (it is awaited, retrying on an interrupted wait), so the command has no parent but launchd.
- **spawn-new-session**: The trampoline MUST be started in a new session so a signal to the caller's terminal process group does not reach the command.
- **spawn-environment**: The command MUST receive exactly the environment passed in, with no variable inherited from the caller.
- **spawn-output-discarded**: Standard output and standard error MUST go to the null device, and the command MUST NOT hold any descriptor of the caller's open, the dispatcher's stdout among them: only descriptors 0 to 3 cross into the child.
- **spawn-payload-fd3**: The payload MUST reach the command as its standard input through descriptor 3 (`<&3`) because an asynchronous list in a non-interactive shell gets the null device on descriptor 0 unless told otherwise, and descriptor 3 MUST be closed in the command after it is redirected.
- **spawn-payload-closed**: The write end of the payload pipe MUST be closed after the payload is written, so the command sees end of input, and the read end MUST be closed in the caller on every path.
- **spawn-failure-cleanup**: When the spawn fails the write end MUST be closed before returning false, leaking no descriptor.
- **spawn-payload-write-failure**: NEEDS REVIEW: Not implemented in source. An error thrown by the payload write is discarded with `try?` and `spawn` still returns true, so the caller is told the feed started when the command may have received a partial payload or none. Evidence that would settle it: whether any write error can occur while the caller itself holds the read end open, or whether a caller must learn of one.
- **spawn-nonexistent-command**: A command that does not exist MUST NOT make `spawn` fail or block: the trampoline starts, the background command fails inside the shell, and `spawn` returns true at once.
- **spawn-blocking**: `spawn` MUST block only for the payload write and the trampoline's exit, never for the command itself. The payload write blocks while the pipe is full and the command is not reading, and because the caller holds the read end open until `spawn` returns, a command that exits without reading never ends the write with a broken-pipe error; callers MUST NOT pass a payload larger than the command will read promptly.

### Feed lock

- **lock-file-name**: `FeedLock.fileURL(sessionID:name:directory:)` MUST be `<name>-statusline-feed-<session>.lock` under `directory`, defaulting to the temporary directory.
- **lock-session-sanitised**: The session id MUST be truncated to its first 128 unicode scalars and every scalar that is not an ASCII letter, digit or `-` MUST become `_`, so a session id can never escape the lock directory.
- **lock-acquire**: `acquire` MUST open the file read-write with creation, close-on-exec and mode `0600`, then take an exclusive non-blocking `flock`, and return the lock when it is taken.
- **lock-contended**: `acquire` MUST return nil, closing its descriptor, when another holder has the lock, and MUST NOT block.
- **lock-unguarded-fallback**: When the lock file cannot be opened (an unwritable or missing directory) `acquire` MUST return a no-op lock, not nil, so the feed runs unguarded rather than not at all.
- **lock-release**: `release()` MUST close the descriptor, which releases the `flock`, and MUST do nothing for a no-op lock.
- **lock-dies-with-process**: The lock MUST be tied to the descriptor, so a killed feed never leaves its session locked.
- **lock-per-session-per-name**: Two sessions whose sanitised, truncated ids differ, or two daemon names, MUST NOT contend with each other; two session ids that sanitise to the same text (`a/b` and `a_b`, or ids equal in their first 128 scalars) name one lock file and do contend.

## Appearance

Not applicable — this is a process-launch helper, not a visual component.

## States

Not applicable — this is a process-launch helper, not a visual component.

## Accessibility

Not applicable — this is a process-launch helper, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| detached-process-001 | spawn-payload-fd3, spawn-environment, spawn-reparent | A script recording its stdin, environment and parent pid; `testTheCommandGetsThePayloadAndEnvironmentAndHangsOffLaunchd` | The command read the payload, saw only the given environment, and its parent pid was 1 |
| detached-process-002 | spawn-nonexistent-command | An executable path that does not exist; `testANonexistentCommandStillReturnsAtOnce` | `spawn` returns at once without hanging |
| detached-process-003 | lock-contended, lock-release | Acquire twice for one session, release, acquire again; `testASecondFeedForTheSameSessionIsRefusedUntilTheFirstEnds` | Second acquire is nil until the first is released, then succeeds |
| detached-process-004 | lock-session-sanitised, lock-file-name | A session id with path separators and non-ASCII scalars; `testASessionIDNeverEscapesTheLockDirectory` | The directory holds one file, `<name>-statusline-feed-______x__.lock`, for session id `../../x/é`; the test passes `name: "stenographer"`, so the file is `stenographer-statusline-feed-______x__.lock` |
| detached-process-005 | lock-unguarded-fallback | A lock directory that does not exist or is not writable; `testAnUnwritableLockDirectoryDoesNotStopTheFeed` | `acquire` returns a lock, not nil |
| detached-process-006 | spawn-trampoline | A command run with the single argument `a b'c$d` (derived from the positional-parameter script; no test covers it) | The command receives that argument as one unchanged word |
| detached-process-007 | lock-session-sanitised | Session ids of 128 and of 129 ASCII letters `a`, derived from the source (no test covers it) | The 128-scalar id appears whole in the file name; the 129-scalar id is cut to its first 128, so both name the same lock file when the first 128 scalars match |
| detached-process-008 | spawn-payload-fd3, spawn-environment | `stdin` empty `Data` and an empty `environment`, derived from the source (no test covers it) | The command sees immediate end of input and has no environment variables |
## Edge Cases

- Null and empty input: an empty payload is written as zero bytes and the command sees immediate end of input (MUST); an empty environment gives the command no variables (MUST); an executable path that is empty fails inside the shell and `spawn` still returns true (MUST).
- Malformed input: arguments holding spaces, quotes or `$` reach the command unchanged because they travel as positional parameters (MUST); an interior NUL in any string truncates it there (the strings are copied with `strdup`) and is not defended against.
- Boundary values: a session id of 128 scalars is kept whole, a longer one is truncated to 128 (MUST); a session id that is entirely non-ASCII becomes underscores (MUST).
- Concurrent access: two feeds for one session race on a non-blocking `flock`, exactly one wins and the loser skips (MUST); feeds for sessions whose sanitised ids differ never contend, while ids that sanitise to the same text share one lock (MUST).
- Error states: a failed `pipe` or `posix_spawn` returns false and closes its descriptors (MUST); a failed payload write is swallowed and `spawn` returns true, the gap marked in Behavioral Requirements.
- Interrupted wait: the wait for the trampoline retries on `EINTR` (MUST).
- Offline or disconnected state: not applicable; nothing here uses the network, though the command may.
- Lock file accumulation: `release()` only closes the descriptor and never unlinks the file, so one lock file per session stays in the lock directory; the source does no cleanup, so removal is left to the operating system's temporary-directory cleanup.
- Stale lock file: a lock file left on disk by a dead process is harmless because the lock is the `flock`, not the file's existence (MUST).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `executable` | `String` | required | Absolute path of the command to run detached |
| `arguments` | `[String]` | required | Arguments passed unmodified |
| `environment` | `[String: String]` | required | The command's whole environment |
| `stdin` | `Data` | required | The payload written to the command's standard input |
| `sessionID` | `String` | required | Identifies the feed lock |
| `name` | `String` | required | The daemon's name, part of the lock file name |
| `directory` | `URL` | the temporary directory | Where lock files live |

The session id limit (`128` scalars) and the lock file mode (`0600`) are fixed constants, not options; they are specified by **lock-session-sanitised** and **lock-acquire**.
## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing text.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: None of its own; it forwards the payload its caller passes (the status-line feed's snapshot, per the source's comments) to the command it starts.
- **Storage**: None beyond the empty lock file, which holds no content, mode `0600`, named from the sanitised session id.
- **Transmission**: None by this type; the payload goes to a local child process on a pipe, and its output is discarded.
- **Retention**: The lock file stays in the temporary directory until the system clears it.

## Logging

Not applicable: this code uses no OSLog and reports failure only through its return value.

## Platform Notes

- **SwiftUI**: Not used; there is no view layer.
- **Compose**: Port with `ProcessBuilder` redirecting output to `ProcessBuilder.Redirect.DISCARD`; the JVM cannot call `setsid`, so detaching needs a launcher shell (`setsid` from util-linux on Linux) or JNA, and the feed lock is `FileChannel.tryLock`.
- **React/Web**: Node `child_process.spawn` with `detached: true`, `stdio: ['pipe', 'ignore', 'ignore']` and `child.unref()`, writing the payload and ending stdin; the lock is `proper-lockfile` or an exclusive `fs.open` with the `wx` flag. Browsers cannot start processes.
- **AppKit / UIKit**: `Core/ClaudeHooks/DetachedProcess.swift`, using `posix_spawn` with `POSIX_SPAWN_SETSID` and `POSIX_SPAWN_CLOEXEC_DEFAULT`, `posix_spawn_file_actions_addopen` and `adddup2`, `FileHandle` for the payload write, and `flock(2)` for the lock. It uses Darwin APIs only (macOS), and iOS cannot spawn processes.
- **WinUI 3**: Use `System.Diagnostics.Process` with `ProcessStartInfo` (`UseShellExecute = false`, `RedirectStandardInput = true`, `CreateNoWindow = true`), or `CreateProcess` with `DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP` and a job object created without kill-on-close so the child survives. There is no reparenting to launchd; the child survives its parent on Windows anyway but stays in the parent's job unless it breaks away. Pass the environment through `ProcessStartInfo.Environment` after clearing it, write the payload with `StandardInput.WriteAsync` then `Close`, and wrap the work in a `Task` off the UI thread. Replace `flock` with a named `Mutex` or a `FileStream` opened with `FileShare.None`, tried once without waiting, and place lock files under `Windows.Storage.ApplicationData.Current.TemporaryFolder`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/DetachedProcess.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A `/bin/sh` trampoline backgrounds the command and exits, instead of spawning the command directly.
**Rationale**: The trampoline's exit reparents the command to launchd, putting it outside the dispatcher's descendant walk so a timeout kill cannot reach it.
**Approved**: pending

**Decision**: The payload travels on descriptor 3, not 0.
**Rationale**: An asynchronous list in a non-interactive shell gets the null device on descriptor 0 unless told otherwise.
**Approved**: pending

**Decision**: Only descriptors 0 to 3 cross into the child.
**Rationale**: A descendant that outlives the dispatcher must not hold open any pipe of the caller's, the dispatcher's stdout among them, or the dispatcher would wait on a pipe that never closes.
**Approved**: pending

**Decision**: The new session is created for the trampoline, so the command is in it too.
**Rationale**: A signal sent to the terminal's process group then misses the command.
**Approved**: pending

**Decision**: The feed lock is a non-blocking `flock` that skips rather than queues.
**Rationale**: Renders arrive faster than feeds finish; the next render carries a newer snapshot, so queueing would only deliver stale ones late.
**Approved**: pending

**Decision**: When no lock file can be made the lock is a no-op that reports success.
**Rationale**: Losing the guard costs duplicate feeds; failing closed would cost the feed itself.
**Approved**: pending

**Decision**: The lock file name carries the daemon name and a sanitised, length-limited session id.
**Rationale**: Daemons and sessions must not contend, and a session id is outside input that must never choose a path.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

separation-of-concerns passes: spawning and the per-session lock are each one small type with no knowledge of what is fed. `unit-test-coverage` passes: every vector is covered by `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/ClaudeHooks/DetachedProcessTests.swift`.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (DetachedProcessTests.swift extended with V006-V008; V001-V005 already covered, 8 of 8 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Linked the status-line recipe as related, framed the dispatcher as the motivating caller, moved fixed constants out of Configuration, tied vector 004 to the test's name, added two test vectors, and recorded that lock files are never removed. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
