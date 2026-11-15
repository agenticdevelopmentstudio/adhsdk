---
id: fa0fce58-5e17-41da-b3eb-0d2de9e89b46
title: "Process Env"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Reads another process's launch args/env and recovers a scrubbed Claude Code OAuth token from the parent `claude` process."
platforms:
  - swift
  - macos
tags:
  - process
  - environment
  - credentials
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Process Env

## Overview

Process Env reads facts about other running processes from the kernel: the arguments and environment a process was started with, its parent pid, and the names it answers to. On top of that it does three jobs for hook and status-line helpers.

1. It recovers `CLAUDE_CODE_OAUTH_TOKEN` from a parent `claude` process. Claude Code scrubs the token from the environment it gives hook and status-line commands, but the token is still in the `claude` process's own launch environment, which a same-user process can read.
2. It finds the pid of the `claude` process that ran a hook, from the hook's own parent pid, checking names rather than trusting position.
3. It remembers recovered tokens per pid for 30 seconds, in a bounded cache, so a daemon that asks on every event does not walk the process table each time.

It lives in the core framework so the daemons and the command-line tools all link one copy. It is a case-less namespace (`ProcessEnv`).

## Behavioral Requirements

- **environment-snapshot**: `environment(forPid:)` MUST return the environment the process was started with (the launch-time snapshot, not later changes made by the process), or nil when it cannot be read.
- **arguments-snapshot**: `arguments(forPid:)` MUST return the arguments the process was started with, program name first, or nil when they cannot be read.
- **unreadable-is-nil**: A pid whose launch data the kernel will not give (no such process, another user's process, or a result no larger than the 4-byte argument count) MUST yield nil from `environment(forPid:)` and `arguments(forPid:)`.
- **env-parse**: Each environment entry MUST be split at its first `=` into a key and a value, and an entry with no `=` or that is empty MUST be dropped.
- **env-duplicate-key**: When one key appears more than once in a process's environment, the later entry MUST win.
- **argv-count**: Exactly the number of arguments the process recorded (its argument count) MUST be returned as arguments, and everything after them MUST be read as the environment.
- **utf8-lossy**: An argument that is not valid UTF-8 MUST be returned as an empty string, and an environment entry that is not valid UTF-8 MUST be dropped.
- **process-names**: `processNames(of:)` MUST return the set of names formed from the last path component of the executable path and of the first argument, with a single leading `-` removed from each (a login shell's marker), and empty names left out; an argument 0 that is not valid UTF-8 reads as an empty string (`utf8-lossy`), so its name is left out the same way.
- **process-names-unreadable**: `processNames(of:)` MUST return an empty set when the process's launch data cannot be read.
- **parent-pid**: `parentPid(of:)` MUST return the parent pid of a process, and MUST return nil when the kernel gives no answer or the parent pid is not above 0.
- **claude-pid-shell-skip**: `claudePid(aboveHookParent:)` MUST, when the given parent's names include a hook shell (`sh`, `bash`, `zsh` or `dash`), step up exactly one level to that shell's parent before testing for `claude`.
- **claude-pid-shell-orphan**: `claudePid(aboveHookParent:)` MUST return nil when the given parent is a hook shell and its own parent cannot be found.
- **claude-pid-name-check**: `claudePid(aboveHookParent:)` MUST return the pid it settled on only when that pid is greater than 1 and its names include `claude` or `node`, and MUST return nil otherwise.
- **claude-pid-direct**: `claudePid(aboveHookParent:)` MUST accept a given parent that is itself a `claude` or `node` process without stepping up.
- **claude-pid-seams**: `claudePid(aboveHookParent:)` MUST take the parent lookup and the name lookup as replaceable functions, defaulting to `parentPid(of:)` and `processNames(of:)`, so a caller can supply a fake process table.
- **token-walk**: `oauthTokenWalkingUp(from:maxHops:)` MUST start at the given pid and return the first non-empty `CLAUDE_CODE_OAUTH_TOKEN` found in a process's launch environment while moving to the parent each step, and MUST return nil when none is found.
- **token-walk-bounds**: The walk MUST stop, returning nothing, when the pid is 1 or lower, once `maxHops` processes (default 16) have been tested, so a `maxHops` of 0 tests none, when a process has no readable parent, or when a process is its own parent.
- **token-empty-value**: A `CLAUDE_CODE_OAUTH_TOKEN` whose value is empty MUST be treated as absent and the walk MUST continue upward.
- **token-boundary**: `oauthTokenWalkingUp(from:below:maxHops:)` MUST stop before testing the `boundary` pid and MUST NOT read the boundary process's environment or any process above it.
- **token-boundary-uncached**: `oauthTokenWalkingUp(from:below:maxHops:)` MUST NOT read from or write to the cache.
- **token-cache-hit**: `oauthTokenWalkingUp(from:maxHops:)` MUST answer from the cache, with no process-table walk, when the start pid has an entry younger than 30 seconds.
- **token-cache-negative**: The cache MUST also remember a walk that found nothing, so a repeated lookup of the same pid for 30 seconds returns nil without walking again.
- **token-cache-ttl**: An entry that is 30 seconds old or older MUST NOT be used; the walk MUST be repeated and the entry replaced.
- **token-cache-ceiling**: After each insert that leaves more than `maxEntries` (128) entries, the cache MUST first drop every entry that is 30 seconds old or older, and if it is still over `maxEntries`, MUST keep only the newest `maxEntries` entries.
- **token-cache-thread-safe**: Reads and writes of the cache MUST be serialised by a lock, and the lock MUST NOT be held while the process table is walked.
- **token-memory-only**: A recovered token MUST be held only in memory, in the cache, and MUST NOT be written to disk or logged.
- **cache-test-seam**: `cachedTokenCountForTesting` MUST report the number of cache entries, and `resetCacheForTesting()` MUST remove every entry.

## Appearance

Not applicable — this is a process-inspection utility, not a visual component.

## States

Not applicable — this is a process-inspection utility, not a visual component. Its one piece of runtime state, the pid-to-token cache, is covered under Behavioral Requirements.

## Accessibility

Not applicable — this is a process-inspection utility, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| process-env-001 | environment-snapshot, env-parse | `environment(forPid:)` on the current process (test: testEnvironmentForCurrentProcessContainsExecTimeVars) | non-nil, and holds `HOME` or `PATH` |
| process-env-002 | parent-pid | `parentPid(of:)` on the current process (test: testParentPidOfCurrentProcessIsValid) | a pid greater than 1 |
| process-env-003 | token-walk | `oauthTokenWalkingUp(from:)` on the current process (test: testOauthTokenWalkingUpDoesNotCrash) | returns without trapping, nil or a token |
| process-env-004 | claude-pid-shell-skip, claude-pid-seams | Fake table: 600 is `sh` with parent 500; 500 is `claude`. `claudePid(aboveHookParent: 600)` (test: testClaudePidSkipsTheShellThatRanTheHookLine) | 500 |
| process-env-005 | claude-pid-direct, claude-pid-name-check | Table: 500 is `claude`; `claudePid(aboveHookParent: 500)`. Then table: 600 is `zsh` with parent 500, 500 is `node`; `claudePid(aboveHookParent: 600)` (test: testClaudePidAcceptsADirectClaudeParentAndNode) | 500 and 500 |
| process-env-006 | claude-pid-name-check | Table: 600 is `zsh` with parent 400, 400 is `login`; `claudePid(aboveHookParent: 600)` (test: testClaudePidIsNilWhenTheChainIsNotClaude) | nil |
| process-env-007 | claude-pid-name-check | Empty table; `claudePid(aboveHookParent: 600)` (test: testClaudePidIsNilWhenTheChainIsNotClaude) | nil |
| process-env-008 | process-names | `processNames(of:)` on the current process (test: testProcessNamesOfThisProcessIncludeItsExecutable) | contains the last component of the first argument |
| process-env-009 | token-cache-ceiling | After `resetCacheForTesting()`, look up 512 distinct pids starting at 2000000 (above the kernel pid ceiling) (test: testCacheStaysAtOrBelowItsCeilingUnderABurstOfDistinctPids) | `cachedTokenCountForTesting` is at most 128 |
| process-env-010 | token-cache-ceiling, token-cache-negative | After reset, look up 64 distinct pids from 2000000 (test: testEvictionOnlyStartsOnceTheCeilingIsReached) | `cachedTokenCountForTesting` equals 64 |
| process-env-011 | token-cache-hit, token-cache-negative | After reset, look up pid 2000000 once, then 50 more times (test: testRepeatedLookupsOfOnePidCacheOneEntry) | `cachedTokenCountForTesting` equals 1 |
| process-env-012 | unreadable-is-nil, token-walk-bounds | `environment(forPid: 2000000)`; `oauthTokenWalkingUp(from: 1)` (no source test) | nil; nil |
| process-env-013 | process-names-unreadable | `processNames(of: 2000000)` (no source test) | empty set |
| process-env-014 | token-boundary, token-boundary-uncached | After reset, `oauthTokenWalkingUp(from: 2000000, below: 2000000)` (no source test) | nil, and `cachedTokenCountForTesting` still equals 0 |
| process-env-015 | cache-test-seam | After reset, `cachedTokenCountForTesting` (no source test) | 0 |
| process-env-016 | claude-pid-shell-orphan, claude-pid-seams | Fake table: 600 is `sh` with no parent; `claudePid(aboveHookParent: 600)` (no source test) | nil |

Vectors 012 to 016 are derived from the source and are covered by `ProcessEnvTests.swift` and `ProcessEnvCacheTests.swift`. The requirements `token-memory-only`, `env-duplicate-key`, `argv-count`, `utf8-lossy`, `token-empty-value`, `token-cache-ttl`, `token-cache-thread-safe` and the real-token branch of `token-walk` have no vector: the parser is private and the source has no test that builds a launch-data buffer, and the 30-second clock cannot be advanced from outside. The source's own comments state each behavior and a port should add a parser test with a handcrafted buffer.

## Edge Cases

- **Null and empty input**: A pid with no readable launch data MUST give nil (or an empty name set). An environment entry with no `=` or with an empty body MUST be dropped. An empty-valued token MUST be treated as absent.
- **Boundary values**: Pid 1 or lower MUST end a walk, and `claudePid(aboveHookParent:)` MUST reject a settled pid of 1 or lower. `maxHops` of 0 MUST test no process (`token-walk-bounds`). The cache MUST allow exactly 128 entries without eviction and MUST evict only once it holds more.
- **Concurrent access**: The cache MUST be lock-protected; two threads may walk the same pid at once and each store a result, with the last store winning, since the lock is released during the walk. Both results are the same unless the process table changed between the walks.
- **Error states**: A failed kernel call MUST give nil (no error is thrown or logged). A walk that cannot read a process's environment MUST go on to its parent when it can.
- **Truncated or malformed launch data**: Parsing MUST stop at the end of the buffer without reading past it; arguments fewer than the recorded count are returned as found.
- **Stale data**: The environment is the launch-time snapshot. A token changed in the running process after launch is not seen. A cached entry older than 30 seconds MUST NOT be used, but it is removed only when an insert pushes the cache over 128 entries; an unread entry can stay in memory past 30 seconds while the cache is under its ceiling.
- **Pid reuse**: Entries are keyed by pid with no process start time, so within 30 seconds a reused pid answers with the earlier process's result.
- **Offline or disconnected state**: Not applicable — this type reads local kernel data only and does no network access.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `maxHops` | integer | 16 | Most parent steps one token walk takes. |
| `maxEntries` | integer constant | 128 | Cache ceiling; matches `HookEnvCache`. |
| token lifetime | seconds, private constant | 30 | How long a cached token or negative result is used. |
| `hookShellNames` | set of strings | `sh`, `bash`, `zsh`, `dash` | Shells a hook command line may run through. |
| `claudeProcessNames` | set of strings | `claude`, `node` | Names a `claude` process answers to (native binary or npm install). |
| `parentOf`, `namesOf` | functions | `parentPid(of:)`, `processNames(of:)` | Replaceable lookups for `claudePid(aboveHookParent:)`. |
| environment variable read | `CLAUDE_CODE_OAUTH_TOKEN` | none | The only variable the token walk looks for. |

## Deep Linking

Not applicable: this component defines no URL scheme or route; it reads process data from the kernel.

## Localization

Not applicable: this component has no user-facing string; it returns pids, names and the token.

## Accessibility Options

Not applicable: this component presents no UI, so it responds to no display-accessibility setting.

## Feature Flags

Not applicable: this component reads no feature flag or settings key.

## Analytics

Not applicable: this component contains no analytics or event-tracking call.

## Privacy

- **Data collected**: An OAuth credential (`CLAUDE_CODE_OAUTH_TOKEN`) read from a parent `claude` process's launch environment; the same call can read any variable of any same-user process.
- **Storage**: In memory only, in the pid-to-token cache, bounded to 128 entries and 30 seconds of use. Nothing is written to disk. The token is not revoked or refreshed here; it is whatever the `claude` process was started with.
- **Transmission**: This component does not transmit it; it returns it to the calling daemon or tool, which decides what to do with it.
- **Retention**: A negative result is also kept. An entry that is never read again is dropped when the cache goes over its ceiling, so a quiet daemon can hold the last few tokens past 30 seconds (see the `token-cache-ceiling` requirement).

## Logging

Not applicable: this component contains no log call, so a recovered token cannot reach a log from here.

## Platform Notes

- **SwiftUI**: Not applicable: there is no UI. The same Foundation code applies unchanged.
- **Compose**: Android cannot read another app's environment without root. For a process in the same app the parent and environment are already known, so there is nothing to recover; a rooted port can read `/proc/<pid>/environ`, `/proc/<pid>/cmdline` (NUL-separated) and `/proc/<pid>/stat` for the parent pid. Guard a `LinkedHashMap` cache with a `Mutex` and evict by timestamp as the source does.
- **React/Web**: Node: read `/proc/<pid>/environ` on Linux, or run `ps eww -p <pid>` on macOS (the source's comment cites it as proof the data is readable); `process.ppid` gives only the current process's parent. A browser cannot do this.
- **AppKit / UIKit**: The same `sysctl` calls work on macOS: launch data comes from `sysctl` (`KERN_PROCARGS2`, `KERN_PROC_PID`), the code imports only Foundation and Darwin, and the cache is a static dictionary marked `nonisolated(unsafe)` and guarded by an `NSLock`; tests use `cachedTokenCountForTesting` and `resetCacheForTesting()`. iOS sandboxing forbids reading another process's launch data, so this does not port to UIKit. Under the macOS app sandbox the read can fail and yield nil, which callers already treat as "unknown".
- **WinUI 3**: A process's environment and parent are not available through a simple .NET API. Use `NtQueryInformationProcess` with `ProcessBasicInformation` for the parent pid (`InheritedFromUniqueProcessId`) and read the PEB's `ProcessParameters` environment block with `ReadProcessMemory` (needs `PROCESS_QUERY_INFORMATION | PROCESS_VM_READ`, allowed for same-user processes); `System.Diagnostics.Process.GetProcessById` supplies names and the main module's file name. Parse the UTF-16 environment block (`KEY=VALUE` entries separated by NUL, ended by an empty entry) in place of the byte-offset walk. Keep the cache in a `Dictionary<int, (DateTime At, string Token)>` guarded by `lock`, with the same 128 and 30-second rules.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Process/ProcessEnv.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The token is read from the parent `claude` process's launch environment, not from the hook's own environment.
**Rationale**: The doc comment on `oauthTokenWalkingUp(from:maxHops:)` in `ProcessEnv.swift` and the type's overview comment say Claude Code scrubs the token from the environment it gives hook and status-line commands, but the process itself still carries it and a same-user read is allowed (as `ps eww` shows).
**Approved**: pending

**Decision**: The walk caches results, including "nothing found", for 30 seconds per start pid.
**Rationale**: The daemon calls per event, and each call would otherwise walk the process table with several kernel calls per hop.
**Approved**: pending

**Decision**: The cache is capped at 128 entries, evicted inline on insert: stale entries first, then all but the newest 128.
**Rationale**: The doc comment on the `cache` property in `ProcessEnv.swift` explains that a time limit checked only on read never frees an entry nobody reads again, and hook pids are short-lived and never looked up twice, so the dictionary would grow over weeks of daemon uptime while holding a token per entry. An evicted entry costs one walk to rebuild; an unevictable one costs a token held forever.
**Approved**: pending

**Decision**: `claudePid(aboveHookParent:)` checks names rather than trusting the parent's position.
**Rationale**: The doc comment on `claudePid(aboveHookParent:)` says a wrong pid would aim a text injection at someone else's terminal, while nil only leaves the session's pid unknown. The accepted shapes are the native install (name `claude`, found through argument 0 even though the executable is a version number) and the npm install (`node`).
**Approved**: pending

**Decision**: `processNames` returns the basenames of both the executable and argument 0.
**Rationale**: Neither alone names `claude` in both installs, as the doc comment on `processNames(of:)` explains.
**Approved**: pending

**Decision**: The boundary form of the walk is uncached and stops short of the boundary.
**Rationale**: A process's environment is its launch-time one, so a caller that has just changed the token in an ancestor shell sees that shell and everything above it still showing the older token; only a process started below it can show a new one. Such a caller asks once per run, so there is nothing to cache (doc comment on `oauthTokenWalkingUp(from:below:maxHops:)`).
**Approved**: pending

**Decision**: Short names (`i`, `s`, `eq`, `pp`) are kept in the launch-data parser.
**Rationale**: The comments in the launch-data parser in `ProcessEnv.swift` say they mirror the standard `KERN_PROCARGS2` parsing idiom and renaming them would make the byte-offset walk harder to check by eye.
**Approved**: pending

**Decision**: The cache is keyed by pid alone, with no process start time, and the pid-reuse risk is accepted.
**Rationale**: Hook pids are short-lived and a reused pid within 30 seconds would return the earlier process's token, which hands a credential to the wrong process. The accepted risk is bounded by the 30-second lifetime and the same-user read rule; revisit by keying on (pid, process start time) if a caller ever uses the token across users or for anything beyond identifying its own session.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | partial | privacy-and-data |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |

`separation-of-concerns` passes: the type only reads process data and holds one bounded cache; what a token is used for belongs to its callers. `unit-test-coverage` passes: `ProcessEnvTests.swift` and `ProcessEnvCacheTests.swift` cover all 16 vectors. The launch-data parser, the token-bearing walk and the 30-second expiry have no vector and no test. `secure-data-storage` is partial: the token stays in memory and is never written or logged, but it is held as a plain string for up to 30 seconds and a cache entry can outlive that when the cache is under its ceiling. `no-pii-in-logs` passes because the type has no log call. `token-lifecycle` is partial: lifetime in the cache is specified, but the token's own lifetime, refresh and revocation belong to the `claude` process and are not handled here. `caching-strategy` passes through the time limit and the hard ceiling.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ProcessEnvTests.swift, ProcessEnvCacheTests.swift, 16 of 16 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Tagged untested vectors, added a pid-reuse Design Decision, cited doc comments, fixed the stale-data and maxHops wording, added an orphan-shell vector, and cleaned the platform notes and summary. |
