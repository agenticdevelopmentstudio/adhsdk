---
id: 9e4aba28-ae2b-4733-b6a5-62e9ad5c7a19
title: "Hook Envelope Builder"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Builds a parsed hook event from a daemon's socket wire format or an http hook payload, recovering env and token from the live claude process, with a short-TTL env cache."
platforms:
  - swift
  - macos
tags:
  - claude-hooks
  - hook
  - envelope
  - wire-format
  - cache
depends-on:
  - 826153e3-cae8-4917-a1d3-c298a54ab558
  - fa0fce58-5e17-41da-b3eb-0d2de9e89b46
  - 8ec76506-7cb3-4aca-a9a0-07f014500e7e
  - a8bfcd0b-0759-4801-aaf6-a14d7aa3fe49
related: []
references: []
approved-by: ""
approved-date: ""
---

# Hook Envelope Builder

## Overview

`HookEnvelopeBuilder` is the daemon-side counterpart of the hook capture command. A daemon that listens for hooks receives them in one of two forms: over its Unix socket, as the wire format a hook script sends (event, `ppid`, `KEY=value` environment lines, a `---` line, then the payload), or over an `http` hook, which carries only the payload JSON. The builder turns either into a `ParsedEvent` ready for ingestion, with the same context shape the capture command writes into a drop file, so events that arrive over the socket and through drop files are queryable identically.

The file holds two types. `HookEnvelopeBuilder` has two `build` overloads (the payload-only http form and the full socket form), `buildContext`, `parseWire` and the stored `daemonWorkingDirectory`; it builds on HookCaptureCommand ([adhsdk.ingredient.foundation.claude-hooks.hook-capture-command](cookbook:826153e3-cae8-4917-a1d3-c298a54ab558)), ProcessEnv ([adhsdk.ingredient.foundation.process.process-env](cookbook:fa0fce58-5e17-41da-b3eb-0d2de9e89b46)), ProcessLiveness ([adhsdk.ingredient.foundation.process.process-liveness](cookbook:8ec76506-7cb3-4aca-a9a0-07f014500e7e)) and RawSetting ([adhsdk.ingredient.foundation.raw-setting](cookbook:a8bfcd0b-0759-4801-aaf6-a14d7aa3fe49)). `HookEnvCache` is a lock-guarded memo, with a three-second time to live, for the two expensive lookups the http form needs: which `claude` process owns a working directory, and what that process's environment is. The account lookups are injected closures because the toolkit core has no account store; both default to the empty string, the "no answer" value.

The system fields (`hostname`, `os`, `arch`, `uid`, `euid`, `gid`) are computed in the calling process. The doc comment on `HookEnvelopeBuilder` states that a daemon runs as the same user as the hook-firing process, so they match.

## Behavioral Requirements

### Payload-only build (http hook)

- **http-event-required**: The payload-only `build(event:payload:...)` MUST return nil when `event` is the empty string.
- **http-daemon-cwd-dropped**: The payload-only build MUST return nil, before reading any process environment, when the payload's `cwd` canonicalises to the daemon's own working directory, because the headless `claude` the daemon spawns inherits that directory and never sets its own.
- **http-daemon-cwd-guards**: The daemon-directory check MUST NOT apply when the daemon directory is the empty string or `/`, and MUST NOT apply when the payload has no `cwd` string.
- **http-env-recovery**: When the payload has a `cwd`, the build MUST locate the `claude` pid through the injected `claudePid` resolver for that `cwd`, read that pid's environment through the injected `environment` resolver, and pass the pid on as the `ppid`.
- **http-env-degrades**: When no `cwd`, no pid or no environment can be found, the build MUST continue with an empty environment and a `ppid` of 0, so the event is still built when the payload carries a `session_id`; token and terminal fields are then simply absent.

### Full build (socket or recovered environment)

- **event-required**: The full `build(event:ppid:env:payload:...)` MUST return nil when `event` is the empty string.
- **headless-env-dropped**: The full build MUST return nil when `env` contains the key `ADH_SDK_HEADLESS` with any value, including an empty one.
- **headless-before-session**: The headless check MUST run before the `session_id` check, so a headless event is dropped whether or not it carries a session.
- **hook-data-from-payload**: `hookData` MUST be the supplied parsed payload when given, otherwise the payload bytes parsed as a JSON object, and MUST be an empty object when the bytes are empty, invalid or not an object.
- **term-lifted**: `hookData.term_program` and `hookData.term_session_id` MUST be set from `TERM_PROGRAM` and `TERM_SESSION_ID` in `env`, each to the empty string when absent, overwriting any payload key of that name.
- **session-start-pid**: For the event `SessionStart` only, `hookData.pid` MUST be set to the supplied `ppid`.
- **session-id-required**: The full build MUST return nil when `hookData.session_id` is missing, not a string, or the empty string.
- **context-built**: The `context` of the result MUST be the value of `buildContext` for the same `ppid` and `env`.
- **timestamp-format**: The `timestamp` MUST be the current time as an ISO 8601 internet date-time string in UTC at whole-second precision, produced by the capture command's formatter.
- **token-recovery**: The token passed to `accountName` MUST be `CLAUDE_CODE_OAUTH_TOKEN` from `env` when that is non-empty, otherwise the token found by walking up the process tree from the `ppid`, because Claude Code scrubs the variable from the environment it hands hook commands.
- **account-email**: `accountEmail` MUST be the result of `accountName` called with that token.
- **oauth-email-at-capture**: `oauthAccountEmail` MUST be the result of `oauthEmail` called during the build, not at ingest, because an event may wait in a spool for a migration or in the drop directory across a reboot, and the sessions upsert keeps the first OAuth stamp.
- **result-fields**: The result MUST be a `ParsedEvent` carrying `eventType` (the event unchanged), `timestamp`, `hookData`, `context`, `accountEmail` and `oauthAccountEmail`.
- **ppid-range**: NEEDS REVIEW: Not implemented in source. When `env` has no non-empty `CLAUDE_CODE_OAUTH_TOKEN`, the full build converts the supplied `ppid` to a 32-bit integer for the token walk without a range check, so a `ppid` larger than the 32-bit range, which `parseWire` accepts from the wire, would trap; a test passing such a value would show whether the daemon aborts.

### Context

- **context-groups**: `buildContext` MUST group facts under `claude`, `process`, `system`, `shell`, `session` and `terminal`, omitting every group except `process` and `system` when it is empty.
- **context-omits-unset**: A variable that is absent or the empty string in `env` MUST NOT appear in `context`.
- **context-claude**: `context.claude` MUST carry `running` (from `CLAUDECODE`) and `yolo` (from `CLAUDE_YOLO`) as booleans, with the values `1`, `true`, `yes` and `on` read as true and `0`, `false`, `no` and `off` as false, case and surrounding whitespace ignored, and any other non-empty value read as false; and `entrypoint`, `exec_path` and `project_dir` as strings.
- **context-process-subset**: `context.process` MUST carry only `ppid`, `uid`, `euid` and `gid`, and MUST NOT carry `argv`, `cwd` or `pid`, because the hook-firing process has exited by ingest time and a hook script's argv is only its name and the event.
- **context-system**: `context.system` MUST be the capture command's system information: `hostname`, `os` and `arch`, or an empty object when the system call fails.
- **context-shell-session-terminal**: `context.shell` MUST carry `shell`, `shlvl` (only when an integer), `lang` and `path`; `context.session` MUST carry `user`, `home`, `logname`, `tmpdir` and `pwd`; `context.terminal` MUST carry `term`, `term_program`, `term_version`, `term_session_id` and `lc_terminal`, each only when set in `env`.

### Wire parsing

- **wire-separator**: `parseWire` MUST split the input at the first occurrence of the bytes newline, three hyphens, newline, taking everything before it as the header and everything after it as the payload, and MUST return nil when no separator exists.
- **wire-header-utf8**: `parseWire` MUST return nil when the header is not valid UTF-8.
- **wire-header-lines**: `parseWire` MUST split the header on newline keeping empty lines, MUST return nil when there are fewer than two lines, and MUST take the first line as the event and the second as the `ppid`.
- **wire-ppid-lenient**: The `ppid` line that does not parse as an integer MUST become 0.
- **wire-env-lines**: Every later non-empty header line MUST be split at its first `=` into key and value, so the value may itself contain `=`; a line without `=` MUST be skipped, and a repeated key keeps the last value.
- **wire-payload-verbatim**: The payload MUST be returned as the exact bytes after the separator, including when empty, and MAY itself contain the separator.
- **wire-empty-event**: An empty first line MUST be returned as an empty event string; rejection happens later, in `build`.

### Working-directory reference

- **daemon-cwd-once**: `daemonWorkingDirectory` MUST be the canonical form of the calling process's working directory, computed once at first access and not updated afterwards; a daemon changes into its support directory early in start-up, before first read.

### Environment cache

- **cache-ttl**: `HookEnvCache` MUST serve a cached value for three seconds after it was stored and MUST resolve again once that time has passed.
- **cache-pid-key**: `pid(inCwd:)` MUST key its entries by the canonical form of the working directory, so two spellings of one existing directory share an entry (a path that does not exist canonicalises to itself).
- **cache-nil-pid**: `pid(inCwd:)` MUST cache a nil result as well as a pid, and MUST delegate resolution to `ProcessLiveness.claudePid(inCwd:)`, which returns nil rather than guess when more than one `claude` shares the directory.
- **cache-empty-env**: `env(forPid:)` MUST cache the empty dictionary when the read fails, so a transient failure does not trigger a rescan on every render.
- **cache-eviction**: When either map holds more than 128 entries after an insert, `HookEnvCache` MUST remove the expired entries; unexpired entries are never evicted by that rule.
- **cache-thread-safety**: Every access to both maps MUST happen under one lock; the resolution on a miss MUST run outside the lock, so two concurrent misses for one key may both resolve and the later store wins.
- **default-resolvers**: The default `claudePid` and `environment` resolvers of the payload-only build MUST be the cache; tests inject their own resolvers and bypass it.

## Appearance

Not applicable — this is a parsing and event-building component with no visible output, not a visual component.

## States

Not applicable — this is a stateless builder (the cache is described under Behavioral Requirements), not a visual component.

## Accessibility

Not applicable — this is a non-interactive component with no user interface, not a visual component.

## Conformance Test Vectors

No test in the repository exercises `HookEnvelopeBuilder` or `HookEnvCache` directly; the source states tests inject their own resolvers, and the vectors below are derived from the source. The context shape is shared with the capture command, whose tests are in `HookCaptureTests`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| builder-001 | event-required, http-event-required | `build` with event `""` (either overload) and a valid payload | nil |
| builder-002 | headless-env-dropped, headless-before-session | Full build for `SessionStart`, env `ADH_SDK_HEADLESS=1`, payload with a `session_id`; and again with the value empty and no `session_id` | nil both times |
| builder-003 | session-id-required | Full build, env empty, payload `{}`; payload `{"session_id":""}`; payload `{"session_id":5}` | nil for each |
| builder-004 | hook-data-from-payload, term-lifted, session-start-pid, result-fields | Full build for `SessionStart`, ppid 123, env `TERM_PROGRAM=iTerm.app`, `TERM_SESSION_ID=w0t1p0:U`, payload `{"session_id":"s1"}` | `eventType` `SessionStart`; `hookData.pid` 123, `term_program` `iTerm.app`, `term_session_id` `w0t1p0:U`, `session_id` `s1` |
| builder-005 | session-start-pid, term-lifted | Full build for `Stop`, env empty, payload `{"session_id":"s1"}` | `hookData.pid` absent; `term_program` and `term_session_id` are the empty string |
| builder-006 | token-recovery, account-email | Full build with env `CLAUDE_CODE_OAUTH_TOKEN=tok` and `accountName` that returns its argument | `accountEmail` is `tok` |
| builder-007 | account-email, oauth-email-at-capture | Defaults for both closures | `accountEmail` and `oauthAccountEmail` are the empty string |
| builder-008 | oauth-email-at-capture | `oauthEmail` returning `login@example.com` | `oauthAccountEmail` is `login@example.com` |
| builder-009 | http-daemon-cwd-dropped | Payload-only build with `daemonCwd` `/var/support` and payload `cwd` `/var/support` | nil; neither resolver is called |
| builder-010 | http-daemon-cwd-guards | Payload-only build with `daemonCwd` `/`, payload `cwd` `/`, `session_id` present, resolvers returning pid 9 and an empty env | An event is returned |
| builder-011 | http-env-recovery, http-env-degrades | Payload-only build with `claudePid` returning 9, `environment` returning `TERM_PROGRAM=Apple_Terminal`, payload with `cwd` and `session_id`, event `SessionStart` | `hookData.pid` 9; `context.process.ppid` 9; `context.terminal.term_program` `Apple_Terminal` |
| builder-012 | http-env-degrades | Payload-only build with both resolvers returning nil and a payload with `session_id` and `cwd` | An event with `context.process.ppid` 0 and no `terminal` group |
| builder-013 | http-env-degrades | Payload-only build with a payload that has a `session_id` and no `cwd` | The resolvers are not called; `ppid` 0 |
| builder-014 | context-claude | env `CLAUDECODE=yes`, `CLAUDE_YOLO=off`, `CLAUDE_CODE_ENTRYPOINT=cli` | `claude.running` true, `claude.yolo` false, `claude.entrypoint` `cli` |
| builder-015 | context-claude | env `CLAUDECODE=maybe` | `claude.running` false |
| builder-016 | context-groups, context-omits-unset | `buildContext` with an empty env | Keys are exactly `process` and `system` |
| builder-017 | context-omits-unset, context-shell-session-terminal | env `SHLVL=abc`, `LANG=` (empty), `HOME=/Users/a` | `shell` group absent; `session.home` `/Users/a` |
| builder-018 | context-process-subset | `buildContext` for ppid 7 | `process` has `ppid` 7, `uid`, `euid`, `gid` and no `argv`, `cwd` or `pid` |
| builder-019 | wire-separator, wire-header-lines, wire-payload-verbatim | `Stop`, newline, `55`, newline, `TERM=xterm`, newline, `---`, newline, `{"a":1}` | event `Stop`, ppid 55, env `TERM` `xterm`, payload bytes `{"a":1}` |
| builder-020 | wire-separator | Bytes with no newline-hyphen-newline separator | nil |
| builder-021 | wire-header-lines | `Stop`, newline, `---`, newline, payload (a one-line header) | nil |
| builder-022 | wire-ppid-lenient | Header lines `Stop` and `abc` | ppid 0 |
| builder-023 | wire-env-lines | Env lines `A=b=c`, `NOEQ`, an empty line, `A=d` | env is `A` = `d` only |
| builder-024 | wire-payload-verbatim | A payload that itself contains the separator | Returned unchanged |
| builder-025 | wire-header-utf8 | Header bytes that are not valid UTF-8 | nil |
| builder-026 | wire-empty-event | First line empty | event is the empty string; passing it to `build` returns nil |
| builder-027 | cache-ttl, cache-nil-pid, default-resolvers | Two `HookEnvCache.pid(inCwd:)` calls for one directory within three seconds | The underlying resolver runs once, including when it returned nil |
| builder-028 | cache-pid-key | `pid(inCwd:)` for an existing directory `/tmp/x` then for `/private/tmp/x` on macOS | One resolution |
| builder-029 | cache-empty-env | `env(forPid:)` twice within three seconds where the read fails | One read; both return the empty dictionary |
| builder-030 | cache-eviction | 128 distinct cwds resolved and left to expire (more than three seconds), then a 129th cwd resolved | The insert of the 129th takes the map past 128 entries, so the 128 expired entries are removed and only the 129th remains |
| builder-031 | cache-thread-safety | Concurrent `env(forPid:)` calls for different pids | No crash; each caller receives a dictionary |
| builder-032 | daemon-cwd-once | Read `daemonWorkingDirectory`, change the working directory, read again | The same value both times |
| builder-033 | timestamp-format | Any built event | `timestamp` matches `YYYY-MM-DDTHH:MM:SSZ` |
| builder-034 | context-built, context-system | Any built event | `context` equals `buildContext(event, ppid, env)` and `context.system` has `hostname`, `os`, `arch` |
| builder-035 | wire-payload-verbatim | A message whose payload after the separator is empty | The payload is empty `Data` |

SHOULD requirements: the document contains none. The open question on `ppid-range` has no vector because the behavior it asks about is undefined. The payload is parsed once on the http path and the parsed object is handed to the inner build; that is an internal efficiency detail, not a requirement.

## Edge Cases

- **Null and empty input**: an empty event, a payload that is not a JSON object, a missing `session_id` and an empty `session_id` each yield nil (MUST). Empty payload bytes with an injected parsed payload still build from the parsed payload (MUST, per `hook-data-from-payload`).
- **Boundary values**: `daemonCwd` of the empty string or `/` disables the daemon-directory drop (MUST). A cache that exceeds 128 entries drops only expired entries, so a burst of more than 128 distinct live keys keeps them all until they expire (MUST). A wire `ppid` that overflows a 32-bit integer is the open question on `ppid-range`.
- **Concurrent access**: a daemon may service hook posts concurrently. `HookEnvCache` guards both maps with one lock, resolves outside the lock, and lets duplicate resolution happen (MUST); the declared Swift opt-out `nonisolated(unsafe)` is justified by that lock. `daemonWorkingDirectory` is a once-initialised static. The `build` functions are otherwise pure.
- **Error states**: a failed process lookup, an unreadable environment, a malformed wire message and a payload that does not parse never raise; they produce nil, an empty environment or an empty `hookData`. A transient read failure is cached for three seconds as an empty environment, so the token and terminal fields are absent for events in that window; the source notes a sessions upsert that coalesces never clobbers an earlier good value.
- **Stale cache**: because entries live three seconds, an account switch in the middle of a window self-heals within one window, and a pid reused by another process inside the window would return the earlier process's environment; the source documents the first and states nothing about the second (see the pending decision on pid reuse).
- **Ambiguous directory**: two `claude` processes in one working directory make `ProcessLiveness.claudePid(inCwd:)` return nil, so the event is built with an empty environment and a `ppid` of 0 rather than attributed to the wrong account (MUST pass the nil through).
- **Headless race**: the env marker `ADH_SDK_HEADLESS` is only readable while the short-lived headless process is alive; the working-directory check is timing-independent and is why it runs first in the http path (MUST).
- **Offline or disconnected state**: not applicable — the builder performs no network I/O; the socket and http transports that call it belong to the daemon.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `event` | string | none | The hook event type; empty yields nil |
| `payload` | bytes | none | The hook payload JSON |
| `ppid` | integer | none (full build); recovered pid or 0 (payload-only) | Claude's pid |
| `env` | string map | none | The environment the hook script forwarded or recovered from the process |
| `parsedPayload` | optional string-keyed map | nil | A payload already parsed, to avoid a second parse |
| `claudePid` | closure from cwd to optional Int32 | `HookEnvCache.pid(inCwd:)` | Finds the `claude` process for a working directory |
| `environment` | closure from pid to optional string map | `HookEnvCache.env(forPid:)` | Reads a process's environment |
| `daemonCwd` | string | `daemonWorkingDirectory` | The daemon's own canonical working directory |
| `accountName` | closure from optional token to string | returns the empty string | Maps a token to its account |
| `oauthEmail` | closure returning string | returns the empty string | The machine login's account |
| `HookEnvCache` time to live | seconds | 3 | How long a cached lookup is served |
| `HookEnvCache` size threshold | entries | 128 | Above this, expired entries are purged |
| `ADH_SDK_HEADLESS` | environment key | absent | Any value drops the event |

## Deep Linking

Not applicable: the builder constructs in-memory events and registers no URL scheme or route.

## Localization

Not applicable: the builder produces no user-facing text; its output is a machine-readable event.

## Accessibility Options

Not applicable: the builder has no visual or motion output.

## Feature Flags

Not applicable: the source reads no feature-flag service; `ADH_SDK_HEADLESS` is a process marker, not a flag.

## Analytics

Not applicable: the builder sends no analytics events.

## Privacy

- **Data collected**: the hook payload, the account name and OAuth login email from the injected closures, and the curated context (home directory, user name, `PATH`, terminal identifiers, host name, operating system and architecture).
- **Storage**: only in memory. `HookEnvCache` holds a process's entire environment, which may include secrets, for three seconds; the built event carries only the curated subset.
- **Transmission**: none by this component; the caller ingests the event.
- **Retention**: a cached entry is no longer served after three seconds (the token walk itself is memoised per pid for 30 seconds inside `ProcessEnv`), but it is removed only when a map grows past 128 entries, so an expired entry, with a whole process environment that may hold secrets, can stay in memory until then.
- **OAuth token**: the token is recovered only to be passed to `accountName`; it is not placed in `hookData` or `context`.

## Logging

Not applicable: the builder makes no log call; a rejected event is signalled by a nil result.

## Platform Notes

- **SwiftUI**: not used; this is a Foundation-level builder with no view layer.
- **Compose**: not used. A JVM daemon port parses with `kotlinx.serialization.json.Json.parseToJsonElement`, uses `ProcessHandle` to enumerate processes (there is no portable way to read another process's environment, so read `/proc/<pid>/environ` on Linux), a `ConcurrentHashMap` with timestamps or Caffeine with `expireAfterWrite(3, SECONDS)` for the cache, and `java.time.Instant` truncated to seconds for the timestamp.
- **React/Web**: a Node.js daemon port uses `JSON.parse` in try/catch, `Buffer.indexOf` for the separator bytes, a `Map` with expiry timestamps for the cache (single-threaded, so no lock), `fs.realpathSync` for canonical paths and `new Date().toISOString()` with the milliseconds trimmed. Reading another process's environment needs a platform command (`ps eww` on macOS, `/proc/<pid>/environ` on Linux).
- **AppKit / UIKit**: this is the source platform. File: `Core/ClaudeHooks/HookEnvelopeBuilder.swift`; collaborators `ProcessEnv` (token walk and `KERN_PROCARGS2` environment read), `ProcessLiveness` (`claudePid(inCwd:)` and `canonicalPath` through `realpath`), `RawSetting.bool` and `HookCaptureCommand.systemInfo`. The cache uses `NSLock` with `nonisolated(unsafe)` statics under Swift 6 strict concurrency. It reads other processes' environments through macOS sysctl calls, so it is macOS only; nothing touches AppKit or UIKit.
- **WinUI 3**: implement `HookEnvelopeBuilder` as a static class in a .NET library and call it from ASP.NET Core minimal API routes or a `BackgroundService` that serves the socket. Parse with `System.Text.Json.JsonDocument` or `JsonNode`; return a record equivalent to `ParsedEvent`. Accept the wire format on a `UnixDomainSocketEndPoint` (supported on Windows 10 1803 and later) or a `NamedPipeServerStream`, and split with `ReadOnlySpan<byte>.IndexOf` over the separator bytes; use `int.TryParse` for the `ppid` line and a checked conversion so an oversized value is rejected rather than thrown. Windows has no `KERN_PROCARGS2`: find a process by working directory and read its environment by opening it with `OpenProcess` (`PROCESS_QUERY_INFORMATION` and `PROCESS_VM_READ`), `NtQueryInformationProcess` for the PEB, and `ReadProcessMemory` for `RTL_USER_PROCESS_PARAMETERS` (`CurrentDirectory` and `Environment`); this works only for same-user processes at the same integrity level. For `HookEnvCache` use `Microsoft.Extensions.Caching.Memory.MemoryCache` with `AbsoluteExpirationRelativeToNow` of three seconds and a `SizeLimit`, which also supplies the lock, or a `ConcurrentDictionary` with expiry timestamps; resolve outside any lock as the source does. Canonical paths come from `Path.GetFullPath` plus `FileSystemInfo.ResolveLinkTarget(returnFinalTarget: true)`; Windows paths compare case-insensitively, which the source's `realpath` does not. `RawSetting.bool` maps to a small `switch` over the lower-cased trimmed string. There is no `uid`, `euid` or `gid`; omit them or substitute the user SID.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/HookEnvelopeBuilder.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The http build drops an event whose `cwd` equals the daemon's own working directory before it reads any process environment.
**Rationale**: The comment on the http `build` overload explains that the headless `claude` a daemon spawns inherits the daemon's directory and never sets its own; the `ADH_SDK_HEADLESS` marker is only recoverable while that short-lived process is alive, so relying on it alone races the summarizer's exit and lets a phantom session in. The working-directory match does not depend on timing.
**Approved**: pending

**Decision**: `daemonWorkingDirectory` is read once, lazily.
**Rationale**: A daemon changes into its support directory early in start-up, before the first read, so the first read captures the directory the headless child will inherit. A later change of directory would not be reflected.
**Approved**: pending

**Decision**: A recovered `claude` pid stands in for `ppid` on the http path.
**Rationale**: An http hook carries no `$PPID`; the located pid is Claude's own, which is what the socket path's `ppid` is.
**Approved**: pending

**Decision**: The cache lives for three seconds and caches failures.
**Rationale**: A status-line post arrives on every render, many times per second per session; without a cache each would scan the whole process table. Three seconds collapses a burst to one scan while a mid-window account switch still self-heals within one window; caching the empty result stops a transient read failure from re-scanning each render.
**Approved**: pending

**Decision**: Resolution on a cache miss runs outside the lock.
**Rationale**: Holding the lock during a process-table scan would serialise every hook post; the cost is occasional duplicate scans for one key. The source documents the lock but not this trade-off, so it is recorded here.
**Approved**: pending

**Decision**: `context.process` omits `argv`, `cwd` and `pid` relative to the capture command's envelope.
**Rationale**: The comment in `buildContext` says the hook-firing process has exited by ingest time and a hook script's argv is only its name and the event, which is already top-level; `cwd` is omitted without a stated reason. Other divergences from `HookCaptureCommand` are boolean parsing through `RawSetting.bool` (broader than `1` and `true`), the `session_id` requirement, the daemon-directory check, and the order of token sources (the forwarded environment first here; the process walk first in the capture command).
**Approved**: pending

**Decision**: Account lookups are injected and default to the empty string.
**Rationale**: The toolkit core has no account store; the empty string is the documented "no answer" value, and the caller supplies the real lookups.
**Approved**: pending

**Decision**: The full build requires a `session_id` and rejects events without one.
**Rationale**: The doc comment states it returns nil when a required field is missing, currently the session id; a later session upsert needs it. The source discards the value after checking it.
**Approved**: pending

**Decision**: Remove the unused `event` parameter of `buildContext`.
**Rationale**: The parameter has no effect on the result today; keeping it is dead surface, and removing it is a source cleanup, not a behavior ports must copy.
**Approved**: pending

**Decision**: Accept that a pid reused by another process inside the three-second window returns the earlier process's environment, or key the cache by pid plus process start time.
**Rationale**: The source documents the account-switch case but says nothing about pid reuse; a reused pid could attribute an event to the wrong account for up to one window, so this is recorded as an open choice.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |
| [adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc) | passed | performance |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | passed | security |

Separation of concerns is partial: one file holds the event builder, the context builder, the wire parser and the cache, though each is a distinct type or function with its own comment. Unit-test coverage is partial: `HookEnvelopeBuilderConformanceTests.swift` covers 31 of 35 vectors. builder-027, builder-028, builder-029 and builder-030 are skipped because `HookEnvCache` has no injectable resolver and keeps its maps private, so resolution counts and eviction cannot be observed (builder-030 also needs more than three real seconds). builder-031 is tested for no-crash only. The caching strategy and resource efficiency are passed: the cache bounds a process-table scan to once per three seconds per key and is size-checked. Graceful degradation is passed because every lookup failure leaves a built event with fields absent rather than an error. Input sanitization is partial because the wire parser is lenient but the unchecked `ppid` conversion is the open question on `ppid-range`. Token lifecycle is passed because the token is recovered per event, used only for the account lookup and never stored in the event.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (HookEnvelopeBuilderConformanceTests.swift, 31 of 35 vectors); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved the source path out of references, linked its dependencies, turned context-event-unused into a pending decision, dropped http-payload-parsed-once, split and corrected vectors, and corrected the retention wording. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
