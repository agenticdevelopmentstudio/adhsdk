---
id: 8ec76506-7cb3-4aca-a9a0-07f014500e7e
title: "Process Liveness"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Finds the live Claude Code CLI processes with libproc and sysctl, their directory and session, and tells headless runs from terminal ones."
platforms:
  - swift
  - macos
tags:
  - process
  - liveness
  - sessions
depends-on:
  - fa0fce58-5e17-41da-b3eb-0d2de9e89b46
related: []
references: []
approved-by: ""
approved-date: ""
---

# Process Liveness

## Overview

Process Liveness answers questions about the Claude Code CLI (`claude`) processes running for the current user, with no subprocess: it reads the process table through libproc and sysctl. It is a case-less namespace (`ProcessLiveness`) in the core framework.

It answers these questions:

1. Which `claude` processes are alive, in which directory were they launched, which session is each running, and what is each one's parent (`liveClaudeProcesses()`). A session reconciler uses this: a session is active while its `claude` process exists and ended when it does not.
2. Which session does one pid run, read from the CLI's own session file (`currentSessionId(ofPid:environment:)`, `sessionId(fromSessionFile:pid:)`).
3. Which single live `claude` is in a given directory, refusing to guess when there are two (`claudePid(inCwd:)`, `uniqueClaude(among:inCwd:directory:isClaude:canonical:)`). An `http` hook carries only the payload, whose `cwd` locates the process whose environment is then read.
4. Whether a `claude` is a headless scripted run and whether it has a controlling terminal (`isHeadless(argv:sessionFile:)`, `terminalAttachment(ofPid:)`).
5. A real-path form of a path (`canonicalPath(_:)`).

Identity comes from the launched executable path, not from `proc_pidpath`. The source records why: the CLI's real image is a version-named binary (`~/.local/share/claude/versions/2.1.183`, whose basename is the version) and `proc_pidpath` fails outright once an update removes an old version's file. The launch path is recorded at exec time, so it is stable and present for every process, and the desktop app (`/Applications/Claude.app`) has a different launch path, so it is left out.

## Behavioral Requirements

- **claude-identity**: A process MUST count as a Claude Code CLI when the executable path it was launched with has the last path component exactly `claude` or contains the text `/claude/`, both compared case-sensitively. The test looks only at the path, so any non-CLI executable under a `/claude/` directory also counts; that false positive is accepted.
- **claude-identity-desktop**: A process whose launch path has neither the last component `claude` nor a `/claude/` component, such as the desktop app's main executable `/Applications/Claude.app/Contents/MacOS/Claude`, MUST NOT count as a Claude Code CLI; the desktop app is left out by this test, with no separate check for its path.
- **claude-identity-unreadable**: A process whose launch data cannot be read, is empty, or is no larger than the 4-byte argument count MUST NOT count as a Claude Code CLI.
- **claude-identity-same-user**: Only processes of the current user MUST be considered; a process of another user MUST count as not Claude.
- **enumeration-user-only**: The pid scan MUST ask the kernel for only the current user's processes, and MUST drop any pid that is not above 0.
- **enumeration-headroom**: The pid buffer MUST be sized from the kernel's count plus 256 spare entries, with its byte size clamped to the 32-bit range, so a burst of new processes between the sizing call and the fill call does not drop pids.
- **live-list**: `liveClaudeProcesses()` MUST return one `LiveClaudeProcess` for each `claude` process found, holding `pid`, `parentPid`, `cwd` and `sessionId`.
- **live-list-failed**: `liveClaudeProcesses()` MUST return nil when the pid scan fails (an empty pid list), so the caller skips reconciliation instead of ending every session on a bad scan.
- **live-list-empty**: `liveClaudeProcesses()` MUST return an empty, non-nil array when the scan worked and no `claude` is running.
- **live-list-skips**: A per-process query failure MUST skip only that process and MUST NOT fail the list.
- **live-list-session-keeps**: A `claude` process with a session id but an unreadable directory MUST stay in the list with an empty `cwd`, because the session id never consults the directory and dropping the process ended a live session on every tick.
- **live-list-drops-blank**: A `claude` process with neither a session id nor a readable directory MUST be left out of the list.
- **live-cwd-canonical**: The `cwd` of a listed process MUST be the real path of its launch directory.
- **live-cwd-empty**: The `cwd` of a listed process MUST be the empty string when the kernel would not name it (a revoked vnode, an unmounted volume), and such a process MUST claim nothing by directory.
- **live-cwd-launch**: The `cwd` MUST be the directory the process was launched in; it MUST NOT follow the agent, because `cd` and `EnterWorktree` move the hook's directory and never the process's.
- **live-parent**: `parentPid` MUST be nil when the parent cannot be read.
- **cwd-read**: A process's directory MUST be read from the kernel's per-process path info, and MUST be nil when the kernel does not return a full record or the path bytes are not valid UTF-8.
- **cwd-bounded**: The directory string MUST be read within the width of the path field, so a path field with no end marker cannot be over-read.
- **session-file-path**: The session file of a pid MUST be read from `<config dir>/sessions/<pid>.json`, where the config directory is the `CLAUDE_CONFIG_DIR` of the process's environment when that is non-empty, and `~/.claude` otherwise.
- **session-file-missing**: `currentSessionId(ofPid:environment:)` MUST return nil when there is no session file (the CLI's helper processes write none) or it cannot be read.
- **session-file-pid-match**: `sessionId(fromSessionFile:pid:)` MUST return the file's `sessionId` only when the file's own `pid` equals the given pid, so a file left by a dead process whose pid was reused names no session.
- **session-file-bad**: `sessionId(fromSessionFile:pid:)` MUST return nil when the data is not JSON, is not an object, has no `pid` number, or has an empty or missing `sessionId`.
- **session-current**: The session id MUST come from the session file the CLI rewrites on resume or clear, so it names the current session and not the first.
- **headless-entrypoint**: `isHeadless(argv:sessionFile:)` MUST, when the session file has a non-empty `entrypoint` string, answer true exactly when the entrypoint starts with `sdk`, and MUST ignore the arguments.
- **headless-kind-ignored**: `isHeadless(argv:sessionFile:)` MUST NOT use the file's `kind`, which reads `interactive` for both scripted and terminal runs.
- **headless-argv**: With no usable entrypoint, `isHeadless(argv:sessionFile:)` MUST answer true when an argument exactly equal to `-p` or `--print` appears among the arguments after the first and before any `--`. The match is on whole tokens: `--print=x` and a combined flag such as `-pv` do not count, while a `-p` token given as an option's value does count.
- **headless-after-separator**: An argument after `--` MUST NOT count as a switch.
- **headless-default**: `isHeadless(argv:sessionFile:)` MUST answer false with nil arguments and no usable entrypoint.
- **unique-match**: `claudePid(inCwd:)` MUST return the pid of the one live `claude` process whose directory equals the given directory after both are made real paths, and MUST return nil when there is none.
- **unique-ambiguous**: `claudePid(inCwd:)` MUST return nil when more than one `claude` process is in the directory, instead of choosing one, because the recovered pid's environment decides which account an event is billed to.
- **unique-two-passes**: `uniqueClaude(among:inCwd:directory:isClaude:canonical:)` MUST first compare each process's kernel-reported directory to the target and ask `isClaude` only for equal ones, and only when that finds no match MUST it run `canonical` on the directory of each process that `isClaude` accepts.
- **unique-no-realpath-unrelated**: `canonical` MUST NOT be run on the directory of a process that is not Claude, because resolving a real path blocks as long as a dead network mount does.
- **unique-exact-ambiguity**: When the first pass finds two matches, `uniqueClaude(among:inCwd:directory:isClaude:canonical:)` MUST return nil without running the second pass.
- **unique-seams**: The three probes (`directory`, `isClaude`, `canonical`) MUST be parameters so a test can see which processes each touched.
- **canonical-path**: `canonicalPath(_:)` MUST return the fully resolved real path, so a logical path such as `/tmp/x` equals the physical `/private/tmp/x`.
- **canonical-fallback**: `canonicalPath(_:)` MUST return its input unchanged when the path does not exist.
- **attachment-unknown**: `terminalAttachment(ofPid:)` MUST return nil when the pid is not above 0, is not a live Claude Code CLI, or the kernel does not describe it as exactly that pid.
- **attachment-headless**: `terminalAttachment(ofPid:)` MUST return `.detached` for a headless `claude` whether or not it has a terminal, because it takes its prompt from its arguments and typed keystrokes never reach it.
- **attachment-tty**: `terminalAttachment(ofPid:)` MUST return `.detached` when the process's controlling terminal device is all bits set (the kernel's no-device value), and `.attached` otherwise.
- **attachment-nil-is-maybe**: Callers MUST read a nil attachment as "might be attached", never as "detached".
- **env-minimal**: Only `CLAUDE_CONFIG_DIR` MUST be read from an inspected process's environment, and the environment MUST NOT be returned, stored or logged.
## Appearance

Not applicable — this is a process-inspection utility, not a visual component.

## States

Not applicable — this is a process-inspection utility, not a visual component. It keeps no state of its own; each call reads the live process table.

## Accessibility

Not applicable — this is a process-inspection utility, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| process-liveness-001 | unique-match, claude-identity (test: testFindsTheOneClaudeInADirectory) | One real child launched as `claude` in a temp directory; `claudePid(inCwd:)` of that directory | the child's pid |
| process-liveness-002 | unique-match, claude-identity (test: testAnotherProcessInTheDirectoryIsNotClaude) | A non-`claude` process in the directory | nil |
| process-liveness-003 | unique-ambiguous (test: testTwoClaudesInOneDirectoryAreAmbiguous) | Two `claude` children in the directory | nil (and the first alone gave its pid) |
| process-liveness-004 | unique-no-realpath-unrelated (test: testAnUnrelatedProcessesDirectoryIsNeverResolved) | Pids 10, 11, 12 in `/Volumes/share`, `/Users/me/app`, `/Users/me/other`; 11 and 12 are claude; target `/Users/me/app`, then `/Users/me/elsewhere` | 11, then nil; `canonical` never called with `/Volumes/share` |
| process-liveness-005 | unique-two-passes, canonical-path (test: testAClaudeFoundOnlyThroughItsResolvedPathStillMatches) | Pids 20, 21 both in `/tmp/x`; only 20 is claude; target `/private/tmp/x`; `canonical` adds `/private` to `/tmp/` paths | 20 |
| process-liveness-006 | unique-ambiguous, unique-two-passes (test: testTwoClaudesMatchingOnlyThroughTheirResolvedPathsAreAmbiguous) | Pids 30, 31 both claude in `/tmp/x`; target `/private/tmp/x` | nil |
| process-liveness-007 | unique-two-passes (test: testOnlyProcessesInTheDirectoryAreAskedIfTheyAreClaude) | Pids 40, 41, 42; only 41 is in the target directory | 41, and `isClaude` was asked only about 41 |
| process-liveness-008 | session-file-pid-match, session-file-bad (test: testSessionFileIsReadOnlyForItsOwnPid) | Data `{"pid":4242,"sessionId":"abc"}`; pid 4242, then pid 4243; then an empty `sessionId`; then `not json` | "abc"; nil; nil; nil |
| process-liveness-009 | session-file-path (test: testSessionFileIsFoundUnderTheProcessesConfigDirectory) | A file `sessions/777.json` in a temp config directory; `CLAUDE_CONFIG_DIR` set to it; `currentSessionId(ofPid: 777, ...)` | "from-config-dir" |
| process-liveness-010 | headless-entrypoint, headless-kind-ignored (no test in source; derived from the doc comment) | Session file with entrypoint `sdk-cli`; then `cli` with argv `claude -p x` | true; false (the file outranks the arguments) |
| process-liveness-011 | headless-argv (no test in source) | No session file; argv `claude -p ping`; argv `node cli.js --print ping` | true; true |
| process-liveness-012 | headless-after-separator, headless-default (no test in source) | No session file; argv `claude -- -p`; argv `claude`; nil argv | false; false; false |
| process-liveness-013 | attachment-unknown (test: testTerminalAttachmentIsUnknownForAProcessThatIsNotClaude) | `terminalAttachment(ofPid: 0)` and of the test runner's own pid | nil; nil |
| process-liveness-014 | live-list-empty, live-list-failed | `liveClaudeProcesses()`; the result depends on the host, so assert only its shape | nil only if the pid scan itself failed; otherwise an array (empty when no `claude` runs) |
| process-liveness-015 | canonical-fallback | `canonicalPath("/no/such/path")` | `/no/such/path` |
| process-liveness-016 | claude-identity, claude-identity-desktop (no test in source; derived from the doc comment) | Launch paths `/Applications/Claude.app/Contents/MacOS/Claude`, `/usr/local/bin/Claude`, `/opt/claude/bin/tool` and `/usr/local/bin/claude` | not Claude (case differs); not Claude (case differs); Claude (accepted false positive: a `/claude/` component); Claude |
| process-liveness-017 | headless-argv (no test in source) | No session file; argv `claude --print=x`; argv `claude -pv`; argv `claude --model -p` | false; false; true |

The requirements `claude-identity-desktop`, `live-list-session-keeps`, `live-cwd-empty`, `cwd-bounded`, `enumeration-headroom` and `attachment-tty` need a real process or a kernel record and have no unit vector in the source; a port should add integration checks for them.

## Edge Cases

- **Null and empty input**: A nil environment MUST fall back to `~/.claude` for the session file. An empty `CLAUDE_CONFIG_DIR` MUST be treated as unset. An empty `sessionId` in a session file MUST give nil. An empty launch path MUST count as not Claude.
- **Boundary values**: A pid at or below 0 MUST be dropped by the pid scan and MUST give nil from `terminalAttachment(ofPid:)`. A process with no session and no directory MUST be left out of the live list.
- **Concurrent access**: The type holds no state and takes no lock, so calls may run in parallel. The process table can change under a scan; a process that exits mid-scan is skipped, and the spare pid buffer covers a burst of new processes. A result is a snapshot.
- **Error states**: A failed pid scan MUST give nil, not an empty list. A failed per-process read MUST skip that process. A kernel call that fails inside `terminalAttachment(ofPid:)` MUST give nil. Nothing throws and nothing is logged.
- **Pid reuse**: A session file left by a dead process whose pid was reused MUST name no session, because its own `pid` field differs.
- **Slow file systems**: A real-path lookup on an unreachable network mount blocks; it MUST NOT be run on a process that is not Claude, so a shell parked in an unreachable share cannot stall the hook-ingest path.
- **Ambiguity**: Two `claude` processes in one directory MUST give nil; the caller falls back to the read-time OAuth account.
- **Directory is not the session**: A session that moved into a submodule or a worktree no longer sits where its process was launched, while an older session the same process left still does, so the directory MUST NOT be used to name the session.
- **Offline or disconnected state**: Not applicable — this type reads local kernel data and one local file only.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `CLAUDE_CONFIG_DIR` | environment variable of the inspected process | unset, meaning `~/.claude` | Where `sessions/<pid>.json` is read. |
| `environment` | `[String: String]` or nil | none | The inspected process's environment, passed to `currentSessionId(ofPid:environment:)`. |
| `argv` | `[String]` or nil | none | The inspected process's arguments, passed to `isHeadless(argv:sessionFile:)`. |
| `sessionFile` | `Data` or nil | none | The raw session file, passed to `isHeadless(argv:sessionFile:)`. |
| `directory`, `isClaude`, `canonical` | functions | the kernel path read, the launch-path test, `canonicalPath` | Probes of `uniqueClaude`. |

Constants, not options (no override exists): the pid headroom of 256 spare entries beyond the kernel's count, and the launch-path test for a Claude Code CLI (last component `claude`, or contains `/claude/`).
## Deep Linking

Not applicable: this component defines no URL scheme or route; it reads process and session-file data.

## Localization

Not applicable: this component has no user-facing string; it returns pids, paths and ids.

## Accessibility Options

Not applicable: this component presents no UI, so it responds to no display-accessibility setting.

## Feature Flags

Not applicable: this component reads no feature flag or settings key; the only configuration it reads is the inspected process's own `CLAUDE_CONFIG_DIR`.

## Analytics

Not applicable: this component contains no analytics or event-tracking call.

## Privacy

- **Data collected**: Process ids, launch directories, parent pids, session ids, arguments and the environment of the current user's `claude` processes. The environment is used for one value only (`CLAUDE_CONFIG_DIR`); the type reads no token itself.
- **Storage**: None. Nothing is written or cached; results are returned to the caller.
- **Transmission**: This component does not transmit anything. The pid it recovers is later used by callers to read an environment that decides the account an event is billed to, which is why an ambiguous directory returns nil.
- **Retention**: None.

## Logging

Not applicable: this component contains no log call; failures are returned as nil or skipped.

## Platform Notes

- **SwiftUI**: Not applicable: there is no UI. Use the Foundation type as it is.
- **Compose**: Android cannot list other apps' processes. Within one app, read `/proc` for the same uid: `/proc/<pid>/cmdline` for the launch path, `/proc/<pid>/cwd` (a symlink) with `File.canonicalPath` for the directory, and `/proc/<pid>/stat` for the parent and terminal device number. Parse the session file with `org.json.JSONObject` or kotlinx.serialization.
- **React/Web**: In Node on Linux use `/proc` as above; on macOS the conforming route is a native addon binding libproc and sysctl, since the type's no-subprocess property is part of its contract. Running `ps` or `lsof -a -d cwd -p <pid>` is a deliberate deviation from that property, acceptable only where cost does not matter. `fs.realpathSync.native` is the counterpart of `realpath`, and `JSON.parse` reads the session file. A browser cannot do this.
- **AppKit / UIKit**: The same libproc and sysctl calls work on macOS: `proc_listpids` (with `PROC_UID_ONLY`), `proc_pidinfo` (`PROC_PIDVNODEPATHINFO`), `sysctl` (`KERN_PROCARGS2`, `KERN_PROC_PID`), `realpath` and `JSONSerialization`, with `ProcessEnv` supplying the environment, arguments and parent pid. iOS sandboxing forbids inspecting other processes, so this does not port to UIKit.
- **WinUI 3**: Use `System.Diagnostics.Process.GetProcesses()` filtered to the current user (compare `WindowsIdentity` of the process token through `OpenProcessToken`), `Process.MainModule.FileName` for the launch path (it can throw `Win32Exception` for protected processes; treat as not Claude), and `NtQueryInformationProcess` with `ProcessBasicInformation` for the parent pid. The working directory comes from the PEB's `RTL_USER_PROCESS_PARAMETERS` through `ReadProcessMemory`. Resolve a real path with `Path.GetFullPath` plus `File.ResolveLinkTarget` (or `GetFinalPathNameByHandle`). Windows has no controlling terminal: replace `terminalAttachment` with a check of the console attached through `GetConsoleProcessList` or leave it unknown (nil). Read the session file with `System.Text.Json.JsonDocument`, at `%USERPROFILE%\.claude\sessions\<pid>.json` unless `CLAUDE_CONFIG_DIR` is set in the process's environment block.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Process/ProcessLiveness.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A process is a Claude Code CLI by its launched executable path from the argument read, not by `proc_pidpath`.
**Rationale**: The type's doc comment on `ProcessLiveness` and the `isClaudeProcess(_:)` comment say the CLI's real image is a version-named binary whose basename is the version, and `proc_pidpath` fails once an update removes an old version's file. The launch path is recorded at exec time, so it is stable and present for every process.
**Approved**: pending

**Decision**: The pid scan is limited to the current user's processes and the buffer has 256 spare entries.
**Rationale**: A live `claude` is always the same user, so the narrower scan avoids a launch-data probe of every root and other-user process each tick. The spare room covers a burst of new processes between the sizing and the fill call, which would otherwise truncate the list.
**Approved**: pending

**Decision**: An unreadable directory does not drop a process that names its session.
**Rationale**: The doc comment on `liveClaudeProcesses()` says the directory lookup fails durably for a revoked vnode or an unmounted volume (a deleted worktree, an ejected disk), and dropping the whole process hid a live `claude` from liveness on every tick, which ended its session while it was still running.
**Approved**: pending

**Decision**: A failed pid scan returns nil, not an empty list.
**Rationale**: A Mac always has processes, so an empty pid list means the scan failed; the caller skips reconciliation rather than ending every session on a bad scan.
**Approved**: pending

**Decision**: The session comes from the CLI's own session file, never from the directory.
**Rationale**: The directory is not a link: a session records wherever its agent last ran a command, so one that moved into a submodule or a worktree no longer sits where its process was launched, while an older session the same process left still does. The file's `pid` check guards against a reused pid.
**Approved**: pending

**Decision**: Ambiguity in a directory is a refusal, not a guess.
**Rationale**: The recovered pid's environment decides which account an event is billed to; choosing a first match among two sessions could bill session B's event to session A's account. Returning nil makes the caller use the read-time OAuth account, the safe fallback, so an ambiguous event is never attributed to the wrong account.
**Approved**: pending

**Decision**: The directory match is two passes, cheapest first, and the real-path lookup only runs on `claude` processes.
**Rationale**: The kernel path is answered from kernel state and is already physical, and the launch-data read pages in the process's memory, so it runs only for the few processes in the directory. A real-path lookup walks the file system and blocks as long as a dead network mount does; a shell parked in an unreachable share must not stall the hook-ingest path.
**Approved**: pending

**Decision**: `canonicalPath` uses `realpath`, not `URL.resolvingSymlinksInPath`.
**Rationale**: The doc comment on `canonicalPath(_:)` says the URL form deliberately leaves `/tmp`, `/var` and `/etc` unresolved, so a stored logical `$PWD` would not equal the physical path the kernel reports (`/private/tmp/x`).
**Approved**: pending

**Decision**: Headless detection trusts the session file's `entrypoint` first, then the arguments, and ignores `kind`.
**Rationale**: The doc comment on `isHeadless(argv:sessionFile:)` says every scripted entry starts with `sdk` (`claude -p` is `sdk-cli`) where a terminal session is `cli`, while `kind` reads `interactive` for both. Without an entrypoint (an older CLI, or the moment before the file is written) `-p` or `--print` decides.
**Approved**: pending

**Decision**: A headless `claude` is detached even when it has a terminal, and an unknown attachment is nil.
**Rationale**: A `claude -p` started from an interactive shell inherits the shell's tty yet takes its prompt from its arguments, so typed keystrokes reach the shell or another claude in the pane. Callers read nil as "might be attached", never as "detached".
**Approved**: pending

**Decision**: The directory string is read within the field width.
**Rationale**: The comment on the directory read in `ProcessLiveness.swift` says a path field with no end marker (a kernel bug) must not make the string read run into adjacent struct memory.
**Approved**: pending

**Decision**: Whether a parent that is itself a live `claude` marks a process as that CLI's helper is the caller's reading of `parentPid`, not something this type decides.
**Rationale**: The doc comment on `LiveClaudeProcess.parentPid` says such a process is that CLI's helper, not a session. The type only reports the parent; a session reconciler applies the interpretation.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc) | passed | performance |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

`separation-of-concerns` passes: the type only reads the process table and a session file and answers questions; deciding what a missing process means is left to the caller. `unit-test-coverage` passes: every vector has a test in `ProcessLivenessTests.swift` (vectors 008 to 017 are the conformance additions, with the identity vector run against real copies of `sleep`); the pid scan, the directory read and the terminal-device test beyond those vectors need a kernel record and are left to integration checks. `graceful-degradation` passes: every kernel failure becomes nil or a skipped process and a bad scan is told apart from an empty one. `resource-efficiency` passes: the scan is user-only, the cheaper kernel path runs first and the real-path lookup is limited to `claude` processes. `explicit-error-handling` is partial: failures are returned as nil or skipped, which callers must read correctly, and nothing is logged.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ProcessLivenessTests.swift, 17 of 17 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Pinned case-sensitive identity and whole-token headless matching with new vectors, added an env-minimal requirement, moved the helper interpretation to a Design Decision, cited doc comments, added the ProcessEnv dependency, and fixed the Configuration and platform notes. |
