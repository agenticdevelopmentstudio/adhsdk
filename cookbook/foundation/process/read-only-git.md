---
id: 409f10cf-e42b-44bf-8439-27e113ec8b13
title: "Read Only Git"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Runs a read-only git command that never takes the index lock, with a 5-second cap, a repaired PATH and an empty string on any failure."
platforms:
  - swift
  - macos
tags:
  - process
  - git
  - subprocess
depends-on:
  - 705082e9-8fad-4c20-95a3-4cf843cc6b97
related: []
references: []
approved-by: ""
approved-date: ""
---

# Read Only Git

## Overview

Read Only Git runs a `git` command whose only purpose is to read repository state, for a status line or a hook helper. It is a case-less namespace (`ReadOnlyGit`) in the core framework, and the one spawn point for `git` on the hook and status-line path (the general git client in `Core/Git/` is the door for everything else).

Three things make it safe to call constantly:

1. It sets `GIT_OPTIONAL_LOCKS=0`, so `git status` and friends never take `index.lock` to refresh the stat cache. A status line re-renders all the time, and a background `git` holding the index lock would race the user's own commit, rebase or add in the same worktree ("Unable to create '…/index.lock'").
2. It gives each call a 5-second limit. A status line re-renders constantly, so a `git` that has not answered in time is dropped rather than waited on.
3. It repairs `PATH`, because a status line launched from the GUI inherits a minimal path (`/usr/bin:/bin:/usr/sbin:/sbin`, no Homebrew).

It offers two forms: `git(_:)`, which trims the output (the default, for any displayed value), and `rawGit(_:)`, which returns the bytes untouched for output where leading or trailing whitespace carries meaning (`git status --porcelain`). Any failure (a non-zero exit, a hang past the limit, a spawn error, output that is not UTF-8) collapses to the empty string. It runs the process through `CommandRunner.runToCompletion`, described by the command-runner recipe ([adhsdk.ingredient.foundation.processes.command-runner](cookbook:705082e9-8fad-4c20-95a3-4cf843cc6b97)).

## Behavioral Requirements

- **raw-output**: `rawGit(_:)` MUST return the standard output of the command byte-for-byte as a UTF-8 string, with no trimming.
- **trimmed-output**: `git(_:)` MUST return the same text as `rawGit(_:)` with leading and trailing whitespace and newlines removed.
- **failure-is-empty**: Both forms MUST return the empty string when the command exits with a non-zero status.
- **timeout-is-empty**: Both forms MUST return the empty string when the command is still running after 5 seconds, and the child MUST be stopped.
- **spawn-error-is-empty**: Both forms MUST return the empty string when the process cannot be started or run.
- **non-utf8-is-empty**: Both forms MUST return the empty string when the standard output is not valid UTF-8.
- **no-throw**: Both forms MUST NOT throw or trap on any failure listed above.
- **optional-locks-off**: The child's environment MUST set `GIT_OPTIONAL_LOCKS` to `0`, replacing any value the caller's environment holds.
- **environment-inherited**: The child MUST get the calling process's environment otherwise unchanged, except for `GIT_OPTIONAL_LOCKS` and `PATH`.
- **path-repaired**: The child's `PATH` MUST be the caller's `PATH` entries in their order, followed by each of `/usr/bin`, `/bin`, `/usr/local/bin` and `/opt/homebrew/bin` that is not already present, joined with `:`.
- **path-repaired-missing**: `repairedPath(_:)` MUST give `/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin` when the given path is nil or empty.
- **path-repaired-order**: `repairedPath(_:)` MUST NOT reorder or drop a non-empty entry already present, MUST drop empty entries (from `::`, a leading `:` or a trailing `:`), and MUST add each missing directory only once.
- **path-repaired-public**: `repairedPath(_:)` MUST be public so a test that spawns its own `git` to build a fixture can repair `PATH` the same way.
- **no-shell**: The command MUST be started as `/usr/bin/env git` followed by the given arguments, with no shell, so `git` is found on `PATH` and an argument is never reinterpreted by a shell.
- **arguments-verbatim**: The arguments MUST be passed to `git` as given, after the word `git`.
- **working-directory**: The command MUST run in the calling process's working directory unless the caller passes `-C <dir>` among the arguments.
- **stdin-closed**: The child's standard input MUST be at end-of-file from the start (an empty input), so it can never block waiting on a prompt.
- **output-drained**: Standard output MUST be read while `git` writes, so a large output (a long branch listing) cannot fill the pipe and deadlock the child.
- **stdout-only**: The result MUST contain only standard output; standard error MUST NOT be part of it.
- **read-only-by-contract**: Callers MUST pass only commands that read repository state; the type does not check the arguments.
- **blocking**: Both forms MUST block the calling thread until the command ends or times out.

## Appearance

Not applicable — this is a process-launching utility, not a visual component.

## States

Not applicable — this is a process-launching utility, not a visual component. It keeps no state between calls.

## Accessibility

Not applicable — this is a process-launching utility, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected | Test |
|----|-------------|-------|----------|------|
| read-only-git-001 | raw-output, trimmed-output | In a repo with one unstaged change to `README.md`, args `-C <repo> status --porcelain -unormal --no-renames` | `rawGit` returns ` M README.md\n` (leading space kept); `git` returns `M README.md` | `testRawGitKeepsWhitespaceThatGitTrimsAway` |
| read-only-git-002 | trimmed-output | `git(["rev-parse", "--abbrev-ref", "HEAD"])` in a repo on branch `fingerprint-branch` | `fingerprint-branch`, no newline | `testSampleReportsTheBranchAndACleanTree` (through the caller) |
| read-only-git-003 | failure-is-empty, no-throw | `git(["rev-parse", "--abbrev-ref", "HEAD"])` in a directory that is not a repository | `""` | `testSampleReturnsNilOutsideAGitRepository` (through the caller) |
| read-only-git-004 | failure-is-empty | `git(["no-such-subcommand"])` | `""` | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-005 | timeout-is-empty | `git(["-c", "alias.slow=!sleep 30", "slow"])`, a command that does not answer within 5 seconds | `""` after about 5 seconds, and the child is stopped | skipped in `ReadOnlyGitConformanceTests` (needs five real seconds) |
| read-only-git-006 | path-repaired-missing | `repairedPath(nil)` and `repairedPath("")` | `/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin` for both | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-007 | path-repaired, path-repaired-order | `repairedPath("/opt/homebrew/bin:/custom")` | `/opt/homebrew/bin:/custom:/usr/bin:/bin:/usr/local/bin` | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-008 | path-repaired | `repairedPath("/usr/bin:/bin:/usr/sbin:/sbin")` (a GUI-launched minimal path) | `/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin` | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-009 | optional-locks-off | In a tree whose index has stale stat data (a file touched after the last refresh), record the index file's modification time, run `git(["status"])`, then compare | the index file's modification time is unchanged, because the status call did not refresh the index | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-010 | optional-locks-off, environment-inherited | The caller's environment has `GIT_OPTIONAL_LOCKS=1` and an extra variable set (a test uses a uniquely named one, since `GIT_DIR` would redirect other tests' repositories); run `git(["-c", "alias.showenv=!env", "showenv"])` | the output contains `GIT_OPTIONAL_LOCKS=0` and the same extra variable | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-011 | output-drained | A command printing more than 1 MB (a repo with many branches, `branch --list`) | the full listing is returned and the call does not hang | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-012 | stdout-only | A command that writes to standard error and exits 0 | the standard error text is absent from the result | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-013 | working-directory | `git(["-C", dir, "rev-parse", "--show-toplevel"])` for a repository other than the caller's directory | the top level of `dir` | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |
| read-only-git-014 | path-repaired, path-repaired-order | `repairedPath("/a::/b:")` (empty segments) | `/a:/b:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin` | `ReadOnlyGitConformanceTests` (`V#` name matches the vector number) |

## Edge Cases

- **Null and empty input**: An empty argument list runs bare `git`, which exits non-zero and so yields `""`. A command with empty output returns `""`, which cannot be told apart from a failure; callers MUST treat `""` as "unknown or nothing".
- **Boundary values**: The limit is 5 seconds from the start; a git that finishes at 4.9 seconds MUST return its output. Output of any size MUST be returned, since it is drained as it arrives.
- **Concurrent access**: The type has no shared state, so calls may run in parallel, each with its own process. Several simultaneous calls on one repository MUST NOT contend for the index lock, because none takes it. A blocked call occupies its calling thread for up to 5 seconds, so callers on the main thread MUST NOT call it.
- **Error states**: A missing `git`, a non-zero exit, a hang, a spawn error and output that is not UTF-8 each MUST give `""` with no error and no log. A caller cannot tell which one happened.
- **Whitespace**: `git(_:)` removes leading and trailing whitespace and newlines, so output whose edges matter (the two-column status prefix of porcelain output, whose first column can be a space) MUST use `rawGit(_:)`; otherwise a 24-byte status becomes a 22-byte one that git never emitted and hashes differently for a cosmetic reason.
- **Empty PATH segments**: `repairedPath(_:)` drops empty entries (`::`, a leading `:` or a trailing `:`) and keeps every non-empty entry in order, so `/a::/b:` becomes `/a:/b:` plus the missing repaired directories (vector 014). A caller `PATH` therefore never keeps an empty entry, which a shell would read as the current directory.
- **Minimal environment**: A GUI-launched status line with a minimal `PATH` MUST still find `git`, through the added `/usr/bin` and the other repaired directories.
- **Not read-only arguments**: A caller that passes a writing command (commit, add) runs it; the lock-avoidance variable does not make it safe. This is a caller precondition: the type's doc comment says these calls only ever read git state, and the type does not check the arguments.
- **Offline or disconnected state**: Not applicable — the commands read the local repository; a command that contacts a remote is outside the read-only intent.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `args` | `[String]` | none | Arguments after `git`, including an optional `-C <dir>`. |
| timeout | seconds, private constant | 5 | Fixed, not configurable. Time a command is given before it is stopped and `""` is returned. |
| `GIT_OPTIONAL_LOCKS` | environment variable set on the child | `0` | Fixed, not configurable. Stops optional index-lock use. |
| `PATH` | environment variable of the child | caller's path plus repaired directories | Fixed, not configurable. See `repairedPath(_:)`. |
| repaired directories | list | `/usr/bin`, `/bin`, `/usr/local/bin`, `/opt/homebrew/bin` | Fixed, not configurable. Appended when missing. |
| launcher | path | `/usr/bin/env` | Fixed, not configurable. Resolves `git` on `PATH` without a shell. |

## Deep Linking

Not applicable: this component defines no URL scheme or route; it runs a command.

## Localization

Not applicable: this component has no user-facing string; it returns git's own output unchanged.

## Accessibility Options

Not applicable: this component presents no UI, so it responds to no display-accessibility setting.

## Feature Flags

Not applicable: this component reads no feature flag or settings key; it reads only the process environment it passes on.

## Analytics

Not applicable: this component contains no analytics or event-tracking call.

## Privacy

Not applicable: this component stores and sends nothing; it returns repository output (branch names, paths, commit subjects) to its caller and the child inherits the caller's environment without copying it anywhere else.

## Logging

Not applicable: this component contains no log call; every failure is collapsed to the empty string.

## Platform Notes

- **SwiftUI**: Not applicable. The type is Foundation-only and has no view code; a SwiftUI host calls the same `ReadOnlyGit` functions from a background task.
- **Compose**: Use `ProcessBuilder("/usr/bin/env", "git", ...)`, because `ProcessBuilder` looks up a bare executable name on the parent's `PATH`, not the repaired child `environment()`, with `environment()["GIT_OPTIONAL_LOCKS"] = "0"` and the PATH repair applied to `environment()["PATH"]`; `redirectInput` from `/dev/null` or close the stream, drain stdout on a coroutine (`Dispatchers.IO`), and use `waitFor(5, TimeUnit.SECONDS)` then `destroyForcibly()`. Android rarely has `git`; this belongs on the JVM desktop.
- **React/Web**: Node: use `child_process.spawn('git', args, { env, stdio: ['ignore', 'pipe', 'ignore'] })` with `env = { ...process.env, GIT_OPTIONAL_LOCKS: '0', PATH: repairedPath(process.env.PATH) }`, so the repair applies and standard input is closed. Collect the stdout chunks into a Buffer with no size cap (`execFile`'s `maxBuffer` would break "output of any size"), kill the child after 5000 ms, and decode with `new TextDecoder('utf-8', { fatal: true })`, returning the empty string on any error, a non-zero exit or a decode failure. A browser cannot run `git`.
- **AppKit / UIKit**: The same `Process` code runs on macOS, and iOS cannot spawn `git`, so this does not port to UIKit. The source is `packages/apple/AgenticDeveloperHubSDK/Core/Process/ReadOnlyGit.swift` in the `AgenticDeveloperHubSDKCore` target, Foundation only. It builds a `Foundation.Process` for `/usr/bin/env`, sets `Process.environment`, and runs it through `CommandRunner.runToCompletion` with an empty `Data()` as input and a 5-second timeout. A repository test (`GitProcessBottleneckTests`) allowlists this file, beside `Core/Git/`, as the spawn point for the hook and status-line path; it fails on any other file that spells a git command line.
- **WinUI 3**: Use `System.Diagnostics.Process` with `ProcessStartInfo { FileName = "git", ArgumentList = {...}, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true, RedirectStandardInput = true, CreateNoWindow = true }`. Set `psi.Environment["GIT_OPTIONAL_LOCKS"] = "0"`. Drop the `/usr/bin/env` launcher, because `UseShellExecute = false` resolves `git.exe` on `PATH`. Replace the Unix directory repair with the common install directories (for example `C:\Program Files\Git\cmd`) appended when missing, and join with `;` (`Path.PathSeparator`). Close standard input right after `Start()` (`StandardInput.Close()`). Drain standard output with `StandardOutput.ReadToEndAsync()` and standard error with `StandardError.ReadToEndAsync()` (discarding it) while waiting (`Process.WaitForExitAsync` with a `CancellationTokenSource` of 5 seconds), so a chatty `git` cannot fill the error pipe and hang, and call `Kill(entireProcessTree: true)` on timeout. Decode strictly with `new UTF8Encoding(false, throwOnInvalidBytes: true)` and return `""` on failure. Call it from a background `Task`, never from the UI thread.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Process/ReadOnlyGit.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `GIT_OPTIONAL_LOCKS=0` is set on every call.
**Rationale**: Per the `ReadOnlyGit` type doc comment in `ReadOnlyGit.swift`, a status line re-renders constantly and a background `git` that grabs the index lock to refresh the stat cache would race the user's own commit, rebase or add in the same worktree. These calls only read git state, so they never need the index.
**Approved**: pending

**Decision**: Every failure collapses to the empty string rather than throwing or returning a result type.
**Rationale**: The callers are display and fingerprint code that treat "no answer" and "nothing" alike; the `ReadOnlyGit` type doc comment in `ReadOnlyGit.swift` states the contract (a non-zero exit, a hang past the limit, or a spawn error collapse to the empty string). The cost is that a caller cannot tell a failure from empty output.
**Approved**: pending

**Decision**: The limit is 5 seconds.
**Rationale**: Per the comment on the private `timeout` constant in `ReadOnlyGit.swift`, a status line re-renders constantly, so a `git` that has not answered within five seconds is dropped rather than waited on.
**Approved**: pending

**Decision**: There are two forms, `git(_:)` that trims and `rawGit(_:)` that does not.
**Rationale**: Per the doc comment on `rawGit(_:)` in `ReadOnlyGit.swift`, `git status --porcelain` has a two-column `XY` prefix, so an unstaged-only change on the alphabetically first path starts with a literal space; trimming eats it and turns a 24-byte status into a 22-byte one that git never emitted and that hashes differently for a purely cosmetic reason. Every displayed value wants the trim, which is why the trimming form is the default.
**Approved**: pending

**Decision**: The command is started through `/usr/bin/env` with no shell, and `PATH` is repaired.
**Rationale**: Per the comments in `rawGit(_:)` and on `repairedPath(_:)` in `ReadOnlyGit.swift`, `env` resolves `git` on `PATH` without a shell. A GUI-launched status line inherits the minimal path `/usr/bin:/bin:/usr/sbin:/sbin` with no Homebrew; Apple's git shim lives at `/usr/bin/git`, but the common install directories are kept too.
**Approved**: pending

**Decision**: `repairedPath(_:)` is public.
**Rationale**: Per the doc comment on `repairedPath(_:)` in `ReadOnlyGit.swift`, a test that spawns its own `git` to build a fixture repository must repair `PATH` the same way; a fixture that cannot find `git` under Xcode's environment while the code under test can is a false failure with no bug behind it.
**Approved**: pending

**Decision**: Standard input is an empty, closed input, and the output is drained while `git` writes.
**Rationale**: Per the comments inside `rawGit(_:)` in `ReadOnlyGit.swift`, a read-only `git` never prompts, but an end-of-file guarantees it cannot block waiting on one; draining stops a large branch listing from filling the pipe buffer and deadlocking the child.
**Approved**: pending

**Decision**: Output that is not valid UTF-8 returns the empty string.
**Rationale**: Per the comment on the decode in `rawGit(_:)` in `ReadOnlyGit.swift`, git output is valid UTF-8, and a failable decode swallows anything else.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | partial | performance |

`separation-of-concerns` passes: the type only builds the command, its environment and its limit; running, draining and stopping the process belong to `CommandRunner`. `unit-test-coverage` is partial: `ReadOnlyGitConformanceTests.swift` covers every vector except 005 (the five-second timeout needs real time to pass, so it is skipped); `GitContextFingerprintTests` also covers the trimmed and untrimmed forms through its caller. `timeout-handling` passes with a fixed 5-second limit and a stopped child. `explicit-error-handling` is partial: failures are surfaced as the empty string by contract, which is lossy by design and cannot tell a failure from empty output. `main-thread-freedom` is partial: the call blocks its calling thread for up to 5 seconds and relies on callers to keep it off the main thread.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ReadOnlyGitConformanceTests.swift, 13 of 14 vectors; 005 skipped, needs 5 real seconds); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Cited source members in design decisions, moved the command-runner link to depends-on, fixed RFC 2119 wording, added a Test column, concrete vectors 005/009/010 and empty-PATH-segment vector 014, and corrected the Compose, Web, WinUI and SwiftUI platform notes. |
