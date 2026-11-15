---
id: 704d4ae9-e344-44d4-b19c-eadfec082077
title: "Status Line Capture"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Runs on every Claude Code status-line render: renders the caller's line, then feeds the payload to the daemon from a detached process, dropping a file when the daemon is unreachable."
platforms:
  - swift
  - macos
tags:
  - claude-hooks
  - status-line
  - capture
  - detached-feed
depends-on:
  - 866770e9-cc76-452f-8216-ee98a8fa1390
  - e75d7d1e-2a25-452d-9c26-ea5f7cd7fa6d
  - 826153e3-cae8-4917-a1d3-c298a54ab558
  - f3326f3a-cccd-4ac5-8dc1-84d660ed4581
  - 9eb46f78-0ceb-455f-9584-b6b43ddf0871
related: []
references: []
approved-by: ""
approved-date: ""
---

# Status Line Capture

## Overview

`StatusLineCapture` is the capture half of a status-line command: what runs on every Claude Code status-line render, around whatever the caller renders. Claude Code pipes the status-line payload, the only carrier of `rate_limits`, to the registered command on every render. Each invocation does two things. The FEED posts the payload to the daemon as a `StatusLine` event, with a git-state fingerprint added on the way out; when the daemon does not accept it, the feed writes a drop envelope for the daemon to scan in later. The RENDER calls the caller's `render` closure, which prints the line. A configuration that shows no status line (a tap) runs the feed alone with `captureOnly`.

The render returns as soon as its line is printed; the feed is handed to a detached copy of the helper run with `--capture-only`. The source comment gives the reason: the claudehelpers dispatcher kills a renderer still running after 3 seconds, a feed can take up to 17 (three `git` watchdogs and the post), and waiting for it threw the line away and killed the post with it. A detached feed is out of the dispatcher's reach and bounded by its own 20 second deadline.

The toolkit core links no daemon client, so the transport is injected: `post` sends one hook event and says whether the daemon accepted it. It collaborates with DetachedProcess ([adhsdk.ingredient.foundation.claude-hooks.detached-process](cookbook:866770e9-cc76-452f-8216-ee98a8fa1390)) (and its `FeedLock`), GitContextFingerprint ([adhsdk.ingredient.foundation.claude-hooks.git-context-fingerprint](cookbook:e75d7d1e-2a25-452d-9c26-ea5f7cd7fa6d)), `ProcessEnv`, HookCaptureCommand ([adhsdk.ingredient.foundation.claude-hooks.hook-capture-command](cookbook:826153e3-cae8-4917-a1d3-c298a54ab558)), HookDropWriter ([adhsdk.ingredient.foundation.claude-hooks.hook-drop-writer](cookbook:f3326f3a-cccd-4ac5-8dc1-84d660ed4581)) and ClaudeHookConfiguration ([adhsdk.ingredient.foundation.sessions.claude-hook-configuration](cookbook:9eb46f78-0ceb-455f-9584-b6b43ddf0871)).

## Behavioral Requirements

### Run

- **run-status**: `run` MUST return the render closure's exit status when `captureOnly` is false.
- **capture-only-exit**: `run` MUST return 0 when `captureOnly` is true, whatever the feed does, because a status line must never break Claude Code.
- **capture-only-no-render**: `run` MUST NOT call `render` when `captureOnly` is true.
- **capture-only-no-print**: `run` MUST print nothing when `captureOnly` is true.
- **sigpipe-ignored**: `run` MUST ignore the broken-pipe signal before doing anything else, so a child that exits before draining its stdin surfaces as a write error rather than killing the process before the line renders.
- **render-before-feed**: When `captureOnly` is false, `run` MUST call `render` before it starts the feed, and MUST flush standard output after `render` returns and before the feed starts.
- **render-args**: `run` MUST call `render` with the payload and the recovered token (nil when none was recovered).
- **feed-always**: When `captureOnly` is false, `run` MUST start a feed after the render whatever the render's status.
- **detach-first**: When `captureOnly` is false, `run` MUST first try to detach the feed, and MUST run the feed in-process, through `feedOnce`, only when detaching reports false.
- **capture-only-feeds-inline**: When `captureOnly` is true, `run` MUST run the feed in-process through `feedOnce`, and MUST NOT detach another.

### Token recovery

- **token-walk**: `run` MUST recover the OAuth token once per invocation by walking up the process tree from the parent pid (at most 16 hops, the `maxHops` default of `ProcessEnv.oauthTokenWalkingUp`; stopping at pid 1 or below; with a result cached per start pid for 30 seconds, the `ttl` of `ProcessEnv`), because Claude Code scrubs `CLAUDE_CODE_OAUTH_TOKEN` from the environment it hands the command.
- **token-carried**: When `captureOnly` is true and the walk finds no token, `run` MUST use `CLAUDE_CODE_OAUTH_TOKEN` from its own environment when that is non-empty, because a detached feed carries the token its renderer recovered for the time `claude` is gone.
- **token-walk-first**: A token found by the walk MUST take precedence over the carried one.
- **token-carried-only-capture**: When `captureOnly` is false, `run` MUST NOT use `CLAUDE_CODE_OAUTH_TOKEN` from its own environment as the recovered token.
- **injected-token**: `injected` MUST return the base environment unchanged when the token is nil, and otherwise a copy with `CLAUDE_CODE_OAUTH_TOKEN` set to the token, replacing any existing value.

### Parent pid

- **parent-pid-variable**: The parent-pid environment variable MUST be named `CLAUDEHELPERS_STATUSLINE_PARENT_PID`.
- **parent-pid-live**: `parentPID` MUST return the value of that variable when it parses as a 32-bit integer greater than 1.
- **parent-pid-fallback**: `parentPID` MUST return the process's own parent pid when the variable is absent, not an integer, or 1 or less (including 0 and negative values).

### Detached feed

- **detach-helper-only**: `detachFeed` MUST return false, and start nothing, when the executable path is nil or its last path component differs from the last path component of the configuration's `hookBinaryPath`, so an in-process test or a foreign host feeds in-process.
- **detach-command**: `detachFeed` MUST start the executable with the configuration's `statusLineArguments` followed by `--capture-only`.
- **detach-payload**: `detachFeed` MUST pass the payload on the detached process's standard input.
- **detach-environment**: `detachFeed` MUST pass the caller's environment with the token injected and `CLAUDEHELPERS_STATUSLINE_PARENT_PID` set to the decimal parent pid, because a detached feed has been reparented to launchd, so its own parent leads nowhere.
- **detach-result**: `detachFeed` MUST return what `DetachedProcess.spawn` returns.
- **detach-default-executable**: `detachFeed` MUST default the executable to the main bundle's executable path.

### Feed, one at a time

- **feed-parse**: `feedOnce` MUST read `session_id` from the payload when the payload is a JSON object with a string `session_id`.
- **feed-lock**: When the payload has a string `session_id`, `feedOnce` MUST acquire a `FeedLock` for that session and the configuration's `name`, and MUST return without feeding when another feed holds it, because the next render brings a newer snapshot.
- **lock-name-sanitised**: A feed lock's file name MUST keep at most the first 128 Unicode scalars of the session id and MUST replace every scalar that is not an ASCII letter, an ASCII digit or `-` with `_`, so a session id never escapes the lock directory.
- **feed-lock-release**: `feedOnce` MUST release the lock when the feed ends or its deadline passes, even when the queued work is still running, so a second feed for the session may overlap work the first has not finished; the overlap is accepted.
- **feed-unlocked**: When the payload is not a JSON object, or has no string `session_id`, `feedOnce` MUST feed without a lock.
- **feed-deadline**: `feedOnce` MUST wait for the feed no longer than `feedDeadline`, which MUST be 20 seconds, and MUST then return and release the lock even when the feed has not finished.
- **feed-own-thread**: `feedOnce` MUST run the feed on a global background queue, not on the calling thread.

### Feed

- **feed-fingerprint**: `feed` MUST add the git-context fingerprint to the payload by `GitContextFingerprint.enriched(payload:)` before the payload leaves the process, because the sample must be taken in the session's working directory at render time and drop-file ingest can be minutes later.
- **feed-post**: `feed` MUST send the enriched payload by `post` as the event `StatusLine`, and MUST do nothing further when `post` returns true.
- **feed-no-drop-on-accept**: `feed` MUST NOT write a drop file when `post` returns true.
- **feed-drop-on-refusal**: When `post` returns false, `feed` MUST build an envelope for the event `StatusLine` with the enriched payload on standard input, no `ppid` string, the environment with the token injected, and the injected `accountName` and `oauthEmail`, using `HookCaptureCommand.buildEnvelope`.
- **feed-drop-directory**: `feed` MUST write that envelope into the directory `HookDropWriter.dropDirectory` chooses for the configuration and the environment.
- **feed-headless-skip**: `feed` MUST write no drop file when `HookCaptureCommand.buildEnvelope` returns nil, which it does when the environment holds `ADH_SDK_HEADLESS`, so a headless `claude` is never tracked.
- **feed-drop-silent**: NEEDS REVIEW: Not implemented in source. A failure to write the drop file ends the feed with no signal (the write error is discarded by `try?`) and the event is lost; the source states no log, return value or counter for it, so evidence of whether the daemon needs to learn of lost events would settle it.
- **feed-token-source**: `feed` MUST inject the token it was given into the drop envelope's environment, and MUST NOT recover one itself.

### Transport and configuration

- **post-injected**: The caller MUST supply `post` as a `@Sendable` closure taking an event name and payload bytes and returning true on acceptance.
- **account-injected**: The caller MUST supply `accountName` as a `@Sendable` closure from an optional token to an account name; `oauthEmail` is `@Sendable` and defaults to the empty string.
- **no-daemon-client**: `StatusLineCapture` MUST NOT link a daemon client; every call to the daemon goes through `post`.

## Appearance

Not applicable — this is a command-side capture and feed routine whose only output is the caller's own rendered line, not a visual component.

## States

Not applicable — this is a stateless static routine, not a visual component. The feed lock is described under Behavioral Requirements.

## Accessibility

Not applicable — this is a process-level routine with no user interface, not a visual component.

## Conformance Test Vectors

Vectors `capture-001` to `capture-006`, `capture-008`, `capture-009` and `capture-016` are named for tests in `HookCaptureTests` and `DetachedProcessTests`; the rest, including `capture-022` to `capture-031`, are derived from the source, because no test calls `feedOnce`, `detachFeed` or `injected`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| capture-001 | feed-drop-on-refusal, feed-drop-directory, feed-post (test `testAFeedTheDaemonRefusesIsDroppedInTheConfigurationsDirectory`) | `feed` with payload `{"session_id":"sl-1","cwd":"/nonexistent-dir"}`, `post` returning false, configuration `adkd`, environment `ADKD_DROP_DIR` set to a fresh directory | The drop directory holds exactly one file; it parses as a JSON object whose `event` is `StatusLine` |
| capture-002 | feed-post, feed-no-drop-on-accept (test `testAFeedTheDaemonAcceptsLeavesNoDropFile`) | `feed` with the same payload, `post` recording and returning true, configuration `stenographer`, `STENOGRAPHER_DROP_DIR` set to a path that does not exist | `post` was called once with the event `StatusLine`; the drop path still does not exist |
| capture-003 | capture-only-exit, capture-only-no-render (test `testCaptureOnlySkipsTheRenderAndExitsZero`) | `run` with `captureOnly` true, `post` returning true, `render` that sets a flag and returns 7 | Returns 0; the flag is unset |
| capture-004 | run-status, feed-always, detach-helper-only (test `testARenderReturnsItsOwnStatusAndStillFeeds`) | `run` with `captureOnly` false, `render` returning 3, `post` that records and returns true, from a test process that is not the helper | Returns 3; `post` was called, because the feed ran in-process |
| capture-005 | feed-lock (test `testTheFeedLockIsNamedForTheConfiguration`) | `FeedLock.acquire` with session `s`, name `adkd` | A file `adkd-statusline-feed-s.lock` exists in the lock directory |
| capture-006 | feed-lock | `FeedLock.acquire` twice for one session and name while the first is held; then for another session | The second returns nil for the same session and a lock for the other (`DetachedProcessTests.testASecondFeedForTheSameSessionIsRefusedUntilTheFirstEnds`); `feedOnce` for that session posts nothing |
| capture-007 | feed-unlocked | `feedOnce` with payload `not json` and `post` recording | `post` called once; no lock file created |
| capture-008 | parent-pid-live | `parentPID` with the variable set to `4242` (test `testTheWalkStartsFromTheDispatchersParent`) | 4242 |
| capture-009 | parent-pid-fallback | `parentPID` with an empty environment; with the variable `1`; with `junk` (same test) | The process's own parent pid in each case |
| capture-010 | parent-pid-fallback | `parentPID` with the variable `0`, then `-5` | The process's own parent pid |
| capture-011 | injected-token | `injected` of `{A: 1}` with token nil | `{A: 1}` |
| capture-012 | injected-token | `injected` of `{A: 1, CLAUDE_CODE_OAUTH_TOKEN: old}` with token `new` | `{A: 1, CLAUDE_CODE_OAUTH_TOKEN: new}` |
| capture-013 | detach-helper-only | `detachFeed` with `hookBinaryPath` `/x/helper` and executable `/y/other-tool` | False; nothing started |
| capture-014 | detach-helper-only | `detachFeed` with executable nil | False |
| capture-015 | detach-command, detach-payload, detach-environment, detach-result | `detachFeed` with `hookBinaryPath` `/x/helper`, executable `/y/helper`, `statusLineArguments` `["statusline"]`, token `t`, parent 99 | `DetachedProcess.spawn` called with arguments `statusline --capture-only`, stdin the payload, an environment holding `CLAUDE_CODE_OAUTH_TOKEN` `t` and `CLAUDEHELPERS_STATUSLINE_PARENT_PID` `99`; the call returns the spawn result |
| capture-016 | detach-result (test `testANonexistentCommandStillReturnsAtOnce`, in `DetachedProcessTests`) | `DetachedProcess.spawn` of a nonexistent executable | Returns at once |
| capture-017 | token-carried | `run` with `captureOnly` true, environment `CLAUDE_CODE_OAUTH_TOKEN` `carried`, and a parent whose tree holds no token | The feed's injected environment carries `carried` |
| capture-018 | feed-deadline | `feedOnce` with a `post` that sleeps beyond 20 seconds | `feedOnce` returns after about 20 seconds and the lock file can be acquired again |
| capture-019 | feed-fingerprint | `feed` with a payload whose `cwd` is a git work tree and `post` capturing the payload | The posted payload is the output of `GitContextFingerprint.enriched` for the original payload |
| capture-020 | feed-drop-silent | `feed` with `post` false and a drop directory that cannot be created | Returns normally; no error; no file |
| capture-022 | token-walk-first | `run` with `captureOnly` true, environment `CLAUDE_CODE_OAUTH_TOKEN` `carried`, and a parent whose tree holds token `walked` | The token used is `walked` |
| capture-023 | token-carried-only-capture | `run` with `captureOnly` false, environment `CLAUDE_CODE_OAUTH_TOKEN` `carried`, and a parent whose tree holds no token | `render` receives a nil token; the variable is ignored |
| capture-024 | capture-only-no-print, capture-only-feeds-inline, capture-only-exit | `run` with `captureOnly` true and `post` recording | Nothing is written to standard output; the feed ran in-process through `feedOnce`; no second feed was detached; returns 0 |
| capture-025 | detach-first | `run` with `captureOnly` false where `detachFeed` reports true, then where it reports false | The first leaves `post` uncalled in this process; the second runs the feed in-process through `feedOnce` |
| capture-026 | feed-headless-skip | `feed` with environment `ADH_SDK_HEADLESS` set and `post` returning false | No drop file is written |
| capture-027 | feed-token-source | `feed` with a token `t` given and `post` returning false | The drop envelope's environment holds `CLAUDE_CODE_OAUTH_TOKEN` `t`; no process-tree walk is made by `feed` |
| capture-028 | feed-lock-release | `feedOnce` with a `post` that sleeps beyond the deadline, then a second `feedOnce` for the same session | The lock is free after the deadline and the second feed starts |
| capture-029 | token-walk | A process chain 17 hops deep with the token only on the 17th; and two walks from one start pid within 30 seconds | The first finds no token; the second reads the process table once |
| capture-030 | feed-own-thread | `feedOnce` with a `post` that records whether it ran on the calling thread | `post` ran on a global-queue thread, not the calling thread |
| capture-031 | sigpipe-ignored | `run` with a detached child that exits before draining its stdin | The process survives and the line was already rendered |
| capture-021 | render-before-feed, render-args | `run` with `captureOnly` false and a `render` that records its arguments and the time | `render` was given the payload and the recovered token (nil if none), and returned before `post` or `detachFeed` was called |

`post-injected`, `account-injected`, `no-daemon-client`, `detach-default-executable`, `feed-parse` and `parent-pid-variable` are verified by reading the signatures or by the vectors above rather than by a dedicated one; `feed-parse` by `capture-007` and `capture-001`, and `parent-pid-variable` by `capture-008`.

## Edge Cases

- **Null and empty input**: a payload that is empty, not JSON, or not an object makes `feedOnce` feed without a lock (MUST). A payload with a `session_id` that is not a string is treated as having none (MUST). An empty carried token is ignored (MUST), because the carried value is used only when non-empty.
- **Boundary values**: a parent pid of 1 or less is ignored (MUST). A lock file name keeps at most the first 128 scalars of the session id, with every other character replaced by `_`, so a session id never escapes the lock directory (MUST, tested by `testASessionIDNeverEscapesTheLockDirectory`).
- **Concurrent access**: two renders of one session can overlap. A feed that finds its session's previous one running skips (MUST), so feeds cannot pile up. The lock is a non-blocking exclusive file lock; it is released when the feed ends and also dies with the process, so a killed feed never leaves its session locked (the `FeedLock` comment). A second render for another session is unaffected.
- **Error states**: a refused post becomes a drop file. A drop file that cannot be written is lost without a signal: `try?` discards the write error. An environment holding `ADH_SDK_HEADLESS` yields no envelope and so no drop file, by design (MUST). The source makes the loss deliberate, since the line never breaks Claude Code, but the daemon is not told (see the open question on `feed-drop-silent`). A lock file that cannot be created makes `FeedLock` a no-op and the feed runs unguarded rather than not at all. A broken pipe on the payload write is ignored. A spawn failure makes `detachFeed` return false and the feed runs in-process after the line is printed.
- **Offline or disconnected state**: when the daemon is unreachable, `post` returns false and the feed drops an envelope for the daemon to scan in later (MUST); there is no retry and no backoff in this component, so a dropped file is the only record.
- **Timeouts**: the feed has a 20 second deadline (MUST). When it passes, `feedOnce` returns and releases the lock while the global-queue work may still be running; in a detached process the process exits on return, and in the in-process fallback the render has already returned.
- **Renderer killed by the dispatcher**: a renderer running over 3 seconds is killed by the dispatcher. Because the feed is detached, the post survives; an in-process fallback feed does not (the source documents the first and states nothing about whether the second can be reached).
- **Helper not the host**: when the running executable is not named like the configuration's helper, the feed runs in-process after the render, and blocks `run`'s return for up to 20 seconds (MUST).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `captureOnly` | boolean | none | Runs the feed only; prints nothing and exits 0 |
| `payload` | bytes | none | The status-line JSON Claude Code piped in |
| `environment` | string map | none | This process's environment |
| `configuration` | `ClaudeHookConfiguration` | none | Supplies `name` (the lock name), `hookBinaryPath` (the helper name), `statusLineArguments` (default `["statusline"]`) and the drop directory |
| `post` | `@Sendable` closure from event and payload to boolean | none | Sends one hook event; true when the daemon accepted it |
| `accountName` | `@Sendable` closure from optional token to string | none | The account lookup the drop envelope carries |
| `oauthEmail` | `@Sendable` closure returning string | returns the empty string | The machine login's account |
| `render` | closure from payload and optional token to exit status | none | Prints the status line; not called with `captureOnly` |
| `executable` | optional string | main bundle's executable path | The program `detachFeed` starts |
| `feedDeadline` | seconds | 20 | The longest a feed may run |
| `captureOnlyFlag` | string | `--capture-only` | The argument that selects the feed-only run |
| token walk hop limit | integer | 16 | `maxHops` of `ProcessEnv.oauthTokenWalkingUp` |
| token walk cache | seconds | 30 | `ttl` in `ProcessEnv`, per start pid |
| session id cut | scalars | 128 | Scalars of the session id kept in the lock file name; see `lock-name-sanitised` |
| `CLAUDEHELPERS_STATUSLINE_PARENT_PID` | environment variable | absent | The pid that ran the status line, set by the dispatcher and by this command for the feed it detaches |
| `CLAUDE_CODE_OAUTH_TOKEN` | environment variable | scrubbed by Claude Code | Carried to a detached feed |
| `<NAME>_DROP_DIR` | environment variable | the configuration's `dropDirectory` | Overrides the drop directory for the configuration when set and non-empty (`HookDropWriter`) |

## Deep Linking

Not applicable: the routine registers no URL scheme or route.

## Localization

Not applicable: the routine produces no user-facing text; the status line is the caller's `render` closure.

## Accessibility Options

Not applicable: the routine has no visual or motion output.

## Feature Flags

Not applicable: the source reads no feature-flag service; `--capture-only` is a command-line argument, not a flag.

## Analytics

Not applicable: the routine sends no analytics events; `post` carries a hook event to the daemon, which is a data feed.

## Privacy

- **Data collected**: the status-line payload (which carries `rate_limits`, the session id and the working directory), the git-context fingerprint of the session's repository, the account name and OAuth login email from the injected closures, and the curated environment context `HookCaptureCommand.buildEnvelope` adds.
- **Storage**: a drop file in the configuration's drop directory, only when the daemon refuses the post; the lock file in the temporary directory holds no data.
- **Transmission**: the payload goes to the local daemon by the injected `post`; nothing leaves the machine from this component.
- **Retention**: a drop file stays until the daemon scans it in; this component does not delete it.
- **OAuth token**: the token is recovered from the `claude` process and carried to the detached feed in its environment, which a process listing by the same user can show for the life of the feed; it is not written to a file by this component, and the drop envelope carries only the account name derived from it.

## Logging

Not applicable: the routine makes no log call; its failure paths are silent by design.

## Platform Notes

- **SwiftUI**: not used; this is a Foundation-level command routine with no view layer.
- **Compose**: not used. A JVM port feeds from a `ProcessBuilder`-started detached process (`nohup`-style through `/bin/sh -c`), reads the payload with `System.in.readAllBytes()`, uses a `java.nio.channels.FileChannel.tryLock()` for the one-feed-per-session lock, `Future.get(20, SECONDS)` for the deadline, and `ProcessHandle.current().parent()` for the parent pid.
- **React/Web**: a Node.js status-line command reads stdin, prints the line, then starts the feed with `child_process.spawn(helper, args, { detached: true, stdio: ['pipe', 'ignore', 'ignore'] })`, writes the payload and calls `child.unref()`. A per-session lock uses an exclusive-create lock file with `fs.openSync(path, 'wx')`, because Node has no `flock`; a stale file after a crash must be cleared by age or by checking the owning pid.
- **AppKit / UIKit**: this is the source platform. Files: `Core/ClaudeHooks/StatusLineCapture.swift`, with `DetachedProcess` and `FeedLock` in `Core/ClaudeHooks/DetachedProcess.swift`. It uses `posix_spawn` with `POSIX_SPAWN_SETSID` through a `/bin/sh` trampoline so the child is reparented to launchd, `flock` for the lock, `DispatchSemaphore` with a timeout for the deadline, `JSONSerialization` for the session id and `getppid()` for the fallback pid. Swift 6 concurrency requires `@Sendable` on the injected closures. It is macOS only; nothing touches AppKit or UIKit.
- **WinUI 3**: implement `StatusLineCapture` as a static class in a .NET console helper that Claude Code runs as the status-line command. Read the payload from `Console.OpenStandardInput()`, call the caller's render delegate, then `Console.Out.Flush()`. Detach the feed by P/Invoke of `CreateProcess` on the same executable with `--capture-only`, with the flags `CREATE_NEW_PROCESS_GROUP | DETACHED_PROCESS` and an inherited stdin pipe (`Process.Start` cannot set those flags; there is no `setsid` or launchd; a detached process is outside the console and survives its parent, but a Job Object that the dispatcher assigns with kill-on-close would still end it, so start the feed outside that job with `CREATE_BREAKAWAY_FROM_JOB` where the job allows it). Write the payload to the child's stdin pipe and close it. Find the parent pid through `NtQueryInformationProcess` (`ProcessBasicInformation`) or `Process.GetCurrentProcess()` with a toolhelp snapshot, because .NET has no parent-pid property, and walk it up for the token; reading another process's environment needs `OpenProcess` with `PROCESS_QUERY_INFORMATION | PROCESS_VM_READ`, the process's PEB and `ReadProcessMemory`. For the one-feed-per-session lock use a named `Mutex` (`Global\<name>-statusline-feed-<session>`) with `WaitOne(0)`, or a `FileStream` opened with `FileShare.None` on `Path.GetTempPath()`; a named mutex dies with the process, as the source's `flock` does. Sanitise the session id to ASCII letters, digits and `-` and cut it to 128 characters, as the source does. Bound the feed with `Task.Run` plus `Task.WaitAsync(TimeSpan.FromSeconds(20))` and a `CancellationToken`. `post` is a `Func<string, byte[], bool>` over `HttpClient` or a `NamedPipeClientStream` with a 2 second timeout; the drop file is `File.WriteAllBytes` to a temporary name then `File.Move` to the final name. Where the source ignores the broken-pipe signal, catch `IOException` on the child's stdin write.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/StatusLineCapture.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/ClaudeHooks/DetachedProcessTests.swift` | confirmed (1.0.2) |

## Design Decisions

**Decision**: `feedDeadline` bounds the whole feed at 20 seconds.
**Rationale**: Each step has its own timeout (5 seconds per `git` call, 2 seconds for the post), so the deadline is the outer bound that keeps feeds from piling up; it is a rationale, and the testable requirement is `feed-deadline`.
**Approved**: pending

**Decision**: Make `feedDeadline` injectable with 20 seconds as the default.
**Rationale**: `feedDeadline` is a fixed constant today, so the deadline vector needs a test that waits more than 20 seconds; an injected value would let it run in milliseconds.
**Approved**: pending

**Decision**: Carry the OAuth token to the detached feed on standard input instead of its environment, or accept the environment.
**Rationale**: A process listing by the same user (`ps -E`) can read the environment for the life of the feed; the source uses the environment today, which is why Token lifecycle is partial.
**Approved**: pending

**Decision**: The feed is run by a detached copy of the helper, and the render returns as soon as its line is printed.
**Rationale**: The source comment explains that the dispatcher kills a renderer still running after 3 seconds while a feed can take up to 17 seconds (three `git` watchdogs and the post); waiting for it threw the line away and killed the post. A detached process is out of the dispatcher's reach and bounded by its own deadline.
**Approved**: pending

**Decision**: The detach uses a `/bin/sh` trampoline that backgrounds the command and exits, with the process in its own session.
**Rationale**: The dispatcher kills a timed-out renderer by walking its descendants with `pgrep -P`, so a process reparented to launchd is out of that walk; leaving the session means a signal to the terminal's process group misses it too (the `DetachedProcess` comment).
**Approved**: pending

**Decision**: The feed runs in-process when this process is not the configuration's helper.
**Rationale**: The source comment names the in-process tests as the case; the helper-name check is also what stops a host that embeds the toolkit from spawning itself with a flag it does not understand.
**Approved**: pending

**Decision**: A new feed skips while the session's previous one runs.
**Rationale**: A render finds the next one carrying a newer snapshot anyway, so skipping loses nothing and stops feeds piling up behind a slow `git` call.
**Approved**: pending

**Decision**: The git fingerprint is taken inside the feed, before the post.
**Rationale**: The sample must be taken in the session's working directory at render time, and on the drop-file path ingest can be minutes later (the `feed` comment).
**Approved**: pending

**Decision**: The OAuth token is recovered by walking up the process tree and carried to a detached feed through its environment.
**Rationale**: Claude Code scrubs `CLAUDE_CODE_OAUTH_TOKEN`; the detached feed has been reparented, so it cannot walk to `claude` itself and receives the token its renderer recovered.
**Approved**: pending

**Decision**: `--capture-only` always exits 0.
**Rationale**: The status-line display can be switched off while Claude Code is still the only carrier of `rate_limits`, and a status line must never break Claude Code (the `captureOnlyFlag` comment).
**Approved**: pending

**Decision**: The feed lock degrades to a no-op when its file cannot be created.
**Rationale**: The `FeedLock` comment states the feed runs unguarded rather than not at all.
**Approved**: pending

**Decision**: A dropped envelope that cannot be written is lost without a signal.
**Rationale**: The source discards the write error with `try?` (a nil envelope is the deliberate headless guard, not a failure); a status line must never break Claude Code, and the next render sends a newer snapshot. The source states neither the rationale nor an alternative signal, so this is recorded here as the observed behavior.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | performance |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security |

Separation of concerns is passed: transport, account lookups and rendering are injected, and the process spawning and locking sit in their own types. Unit-test coverage is partial: `HookCaptureTests`, `DetachedProcessTests` and `StatusLineCaptureConformanceTests.swift` cover 26 of 31 vectors. Skipped: capture-018 and capture-028 (need more than the 20 second `feedDeadline` of real time), capture-025 (the detach-succeeds branch needs the test process to be the configured helper binary) and capture-029 (needs a live 17-deep process chain and a count of process-table reads) and capture-022 (the test runner cannot read the environment of a child it spawned, so a walked token cannot be planted; the test skips itself at run time). Vectors that depend on the token reaching the account lookup skip themselves when the test process's own ancestry already holds an OAuth token. Graceful degradation is passed because a refused post becomes a drop file, a missing lock file becomes a no-op, a failed detach becomes an in-process feed and `--capture-only` always exits 0. Timeout handling is passed because the whole feed is bounded by a 20 second deadline and each step has its own. Main-thread freedom is passed because the feed runs on a global queue and the render returns before a detached feed starts. Token lifecycle is partial: the token is recovered per invocation and never written to a file, but it travels through the detached feed's environment, and the source states no limit on how long that process lives beyond the 20 second deadline.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (StatusLineCaptureConformanceTests.swift, 27 of 31 vectors); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved source paths out of references, linked dependencies, moved the deadline rationale to Design Decisions, stated the accepted lock overlap, added ten vectors and split capture-017, tabled the tunables, and removed drafting residue and the WinUI mixed mechanism. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
