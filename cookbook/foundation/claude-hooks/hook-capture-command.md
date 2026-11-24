---
id: 826153e3-cae8-4917-a1d3-c298a54ab558
title: "Hook Capture Command"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The command a hook helper runs when Claude Code fires a hook: reads the payload from stdin, adds a process-context snapshot, writes a drop file, and always exits 0."
platforms:
  - swift
  - macos
tags:
  - claude-hooks
  - hook
  - envelope
  - drop-file
depends-on:
  - f3326f3a-cccd-4ac5-8dc1-84d660ed4581
related:
  - 9e4aba28-ae2b-4733-b6a5-62e9ad5c7a19
  - 704d4ae9-e344-44d4-b19c-eadfec082077
  - 9eb46f78-0ceb-455f-9584-b6b43ddf0871
references: []
approved-by: ""
approved-date: ""
---

# Hook Capture Command

## Overview

`HookCaptureCommand` is what a hook helper executable runs when Claude Code fires a registered hook. The registered command line has the shape `<helper> hook --event <Type> [--ppid <int>]`. The command reads the hook payload that Claude Code piped to standard input, wraps it in an envelope together with a snapshot of the process context, and writes the envelope as a drop file that a daemon scans in later. It is the fallback transport: it writes the file whether or not a daemon is listening.

The contract of a hook is "never fail, never produce stdout". The entry point `run` therefore returns exit status 0 whatever goes wrong, so a broken hook never blocks Claude Code. Everything specific to one daemon (the drop directory and its override variable) comes from a `ClaudeHookConfiguration` (ClaudeHookConfiguration ([adhsdk.ingredient.foundation.sessions.claude-hook-configuration](cookbook:9eb46f78-0ceb-455f-9584-b6b43ddf0871))); the account lookups are injected closures because the toolkit core has no account store.

The type is a caseless enum with two public static entry points, `run` and `buildEnvelope`, plus an internal `systemInfo` and `iso8601UTC` that `HookEnvelopeBuilder` reuses. The directory and file mechanics live in the drop-writer component (HookDropWriter ([adhsdk.ingredient.foundation.claude-hooks.hook-drop-writer](cookbook:f3326f3a-cccd-4ac5-8dc1-84d660ed4581))); the socket-path twin of the envelope lives in the envelope-builder component (HookEnvelopeBuilder ([adhsdk.ingredient.foundation.claude-hooks.hook-envelope-builder](cookbook:9e4aba28-ae2b-4733-b6a5-62e9ad5c7a19))); the status-line command that reuses `buildEnvelope` lives in the status-line-capture component (StatusLineCapture ([adhsdk.ingredient.foundation.claude-hooks.status-line-capture](cookbook:704d4ae9-e344-44d4-b19c-eadfec082077))).

## Behavioral Requirements

### Entry point and exit status

- **exit-status-zero**: `run` MUST return 0 on every path: a missing event flag, a tracked-out event, a malformed payload and a failed drop-file write alike.
- **event-flag-required**: `run` MUST write nothing and return 0 when the arguments carry no `--event` value or an empty one.
- **no-stdout**: The command MUST NOT write to standard output or standard error.
- **write-failure-swallowed**: `run` MUST swallow any error thrown while writing the drop file and still return 0.
- **flag-parsing**: The argument parser MUST accept only `--key value` pairs, where a value is the next argument and does not begin with `--`; positional arguments and `--key=value` forms are ignored.
- **duplicate-flag-last-wins**: When the same `--key` appears more than once, the argument parser MUST keep the later value.
- **ppid-flag-optional**: `--ppid` MAY be omitted; the registered command does not pass it.

### Envelope content

- **headless-not-tracked**: `buildEnvelope` MUST return nil, so that no drop file is written, when the supplied environment contains the key `ADH_SDK_HEADLESS` with any value, including an empty one.
- **envelope-keys**: A built envelope MUST contain the keys `event`, `timestamp`, `hook_data`, `context`, `account_email` and `oauth_account_email`.
- **event-verbatim**: The `event` value MUST be the `--event` string unchanged.
- **timestamp-format**: The `timestamp` MUST be the current time as an ISO 8601 internet date-time string in UTC at whole-second precision.
- **hook-data-from-stdin**: `hook_data` MUST be the stdin payload parsed as a JSON object, and MUST be an empty object when stdin is empty, is not valid JSON, or parses to something other than an object.
- **term-program-lifted**: `hook_data.term_program` MUST be set from `TERM_PROGRAM` in the supplied environment, or to the empty string when absent; it overwrites any payload key of that name.
- **term-session-id-lifted**: `hook_data.term_session_id` MUST be set from `TERM_SESSION_ID` in the supplied environment, or to the empty string when absent, so an app can jump to the exact tab or pane even when the daemon was down.
- **session-start-pid**: For the event `SessionStart` only, `hook_data.pid` MUST be set to Claude's pid, or 0 when no pid is known; for every other event the key MUST NOT be added.
- **ppid-resolution**: Claude's pid MUST be the integer parsed from `--ppid` when that parses, otherwise the result of the injected `claudePid` closure, otherwise unknown; a non-numeric `--ppid` falls through to `claudePid`.
- **account-email**: `account_email` MUST be the result of the injected `accountName` closure called with the recovered OAuth token, or with nil when no token was recovered (the closure decides what nil maps to).
- **token-recovery**: The OAuth token passed to `accountName` MUST be recovered by walking up the process tree from this process's parent, falling back to `CLAUDE_CODE_OAUTH_TOKEN` in the supplied environment when the walk finds none, because Claude Code scrubs that variable from the environment it hands hook commands.
- **oauth-email-at-capture**: `oauth_account_email` MUST be the result of the injected `oauthEmail` closure, called while the hook fires and not deferred to the drain, because the sessions upsert keeps the first OAuth stamp and a backlog would otherwise be attributed to whoever is logged in at the drain.

### Context snapshot

- **context-groups**: `context` MUST group process facts under the keys `claude`, `process`, `system`, `shell`, `session` and `terminal`; every group except `process` and `system` MUST be omitted when it would be empty.
- **context-omits-unset**: An environment variable that is unset or the empty string MUST NOT appear in `context`.
- **context-claude-booleans**: `context.claude.running` (from `CLAUDECODE`) and `context.claude.yolo` (from `CLAUDE_YOLO`) MUST be true only for the value `1` or the value `true` in any letter case, and false for any other non-empty value.
- **context-claude-strings**: `context.claude` MUST also carry `entrypoint` (`CLAUDE_CODE_ENTRYPOINT`), `exec_path` (`CLAUDE_CODE_EXECPATH`) and `project_dir` (`CLAUDE_PROJECT_DIR`) as strings when set.
- **context-process**: `context.process` MUST carry `argv` (this process's arguments without the program name), `cwd` (the empty string when the working directory cannot be read), `pid`, `ppid`, `uid`, `euid` and `gid`; `ppid` MUST be the resolved Claude pid, or this process's parent pid when Claude's pid is unknown.
- **context-system**: `context.system` MUST carry `hostname`, `os` (the system name and release separated by one space) and `arch` (the machine type), and MUST be an empty object when the system call fails.
- **context-shell-session-terminal**: `context.shell` MUST carry `shell`, `shlvl` (only when it parses as an integer), `lang` and `path`; `context.session` MUST carry `user`, `home`, `logname`, `tmpdir` and `pwd`; `context.terminal` MUST carry `term`, `term_program`, `term_version`, `term_session_id` and `lc_terminal`, each only when set.
- **context-from-live-process**: The `claude`, `shell`, `session` and `terminal` groups MUST be read from the live process environment, not from the `environment` argument; only `hook_data`, the headless check and the token fallback are read from the supplied environment.

### Concurrency and persistence

- **independent-invocations**: Each invocation MUST be self-contained and hold no state between calls; the type has no stored properties, so concurrent hook processes do not coordinate through it.
- **drop-delegated**: The envelope MUST be handed to `HookDropWriter.writeDropFile` with the directory chosen by `HookDropWriter.dropDirectory` for the supplied configuration and environment.

## Appearance

Not applicable — this is a command-line hook capture routine with no visible output, not a visual component.

## States

Not applicable — this is a stateless command that runs once per invocation, not a visual component.

## Accessibility

Not applicable — this is a non-interactive command that never writes to stdout or stderr, not a visual component.

## Conformance Test Vectors

Derived from `HookCaptureTests` where a test is named, and from the source otherwise.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| capture-001 | exit-status-zero, drop-delegated, envelope-keys, event-verbatim | `run` with arguments `--event Stop --ppid 5`, stdin `{"session_id":"s1"}`, the configuration's drop-directory variable pointing at a fresh directory, `oauthEmail` returning `login@example.com` (test `testRunWritesADropFileForTheEvent`) | Returns 0; exactly one `.json` file appears in the directory; its `event` is `Stop` and its `oauth_account_email` is `login@example.com` |
| capture-002 | event-flag-required, exit-status-zero | `run` with no arguments and empty stdin (test `testRunWithoutAnEventWritesNothingAndStillSucceeds`) | Returns 0; the drop directory is not created |
| capture-003 | event-flag-required | `run` with arguments `--event` and no value, or `--event ""` | Returns 0; nothing is written |
| capture-004 | term-program-lifted, term-session-id-lifted, session-start-pid, ppid-resolution | `buildEnvelope` for `SessionStart`, ppid string `123`, env `TERM_PROGRAM=iTerm.app`, `TERM_SESSION_ID=w1t12p0:UUID-9` (test `testEnvelopeCarriesTermSessionIdAndSessionStartPid`) | `hook_data.term_session_id` is `w1t12p0:UUID-9`, `term_program` is `iTerm.app`, `pid` is 123 |
| capture-005 | session-start-pid, term-session-id-lifted | `buildEnvelope` for `PreToolUse`, no ppid, empty env (test `testOnlySessionStartCarriesAPid`) | `hook_data.term_session_id` is the empty string and `hook_data.pid` is absent |
| capture-006 | headless-not-tracked | `buildEnvelope` for `SessionStart` with env `ADH_SDK_HEADLESS=1` (test `testHeadlessEventsAreNotTracked`) | Returns nil |
| capture-007 | headless-not-tracked | `buildEnvelope` with env `ADH_SDK_HEADLESS` set to the empty string | Returns nil (presence of the key, not its value, decides) |
| capture-008 | ppid-resolution, session-start-pid | `buildEnvelope` for `SessionStart`, ppid nil, `claudePid` returning 4242; then `claudePid` returning nil (test `testClaudesPidIsFoundWhenNoPpidFlagIsGiven`) | `hook_data.pid` is 4242, then 0 |
| capture-009 | ppid-resolution | `buildEnvelope` for `SessionStart`, ppid string `abc`, `claudePid` returning 4242 | `hook_data.pid` is 4242 (the non-numeric flag falls through) |
| capture-010 | account-email, oauth-email-at-capture | `buildEnvelope` with `accountName` returning `named@example.com` and `oauthEmail` returning `x@example.com` (test `testTheAccountLookupsAreInjected`) | `account_email` is `named@example.com` and `oauth_account_email` is `x@example.com` |
| capture-011 | hook-data-from-stdin | `buildEnvelope` with stdin empty, then stdin `not json`, then stdin `[1,2]` | In each case `hook_data` holds only the lifted keys `term_program` and `term_session_id` |
| capture-012 | flag-parsing | arguments `--event=Stop` | No `--event` value is found; `run` writes nothing and returns 0 |
| capture-013 | flag-parsing, event-flag-required | arguments `--event --ppid 5` | `--event` has no value because the next argument starts with `--`; nothing is written |
| capture-014 | context-claude-booleans | integration-only (reads the live process environment, which `buildEnvelope` does not take as an argument); live environment `CLAUDECODE=TRUE`, `CLAUDE_YOLO=0` | `context.claude.running` is true and `context.claude.yolo` is false |
| capture-015 | context-omits-unset, context-groups | integration-only (reads the live process environment); live environment with no `LC_TERMINAL` and an empty `TMPDIR` | `context.terminal` has no `lc_terminal` key and `context.session` has no `tmpdir` key |
| capture-016 | write-failure-swallowed, exit-status-zero | `run` with a drop-directory variable naming a path under a regular file | Returns 0, writes nothing, prints nothing |
| capture-017 | timestamp-format | any built envelope | `timestamp` matches `YYYY-MM-DDTHH:MM:SSZ` |
| capture-018 | context-process | `buildEnvelope` with ppid string `99` | `context.process.ppid` is 99; with ppid nil and `claudePid` nil it is this process's parent pid |
| capture-019 | token-recovery | `buildEnvelope` with an environment holding `CLAUDE_CODE_OAUTH_TOKEN=tok` and a process tree that yields no token | `accountName` is called with `tok` |
| capture-020 | token-recovery, account-email | `buildEnvelope` with no token in the tree and none in the environment | `accountName` is called with nil |
| capture-021 | context-system | any built envelope | `context.system` has string keys `hostname`, `os` (two words separated by one space) and `arch` |
| capture-022 | duplicate-flag-last-wins | arguments `--event Stop --event Start` | The event is `Start` |

SHOULD requirements: the document contains none, so no omission needs a rationale.
## Edge Cases

- **Null and empty input**: empty stdin, non-JSON stdin and JSON that is not an object each yield an empty `hook_data` before the lifted keys are added, and the event is still captured (MUST, per `hook-data-from-stdin`). A payload without `session_id` is still captured; this command does not require one, unlike `HookEnvelopeBuilder`.
- **Empty event**: `--event ""` is treated as absent and nothing is written (MUST, per `event-flag-required`).
- **Boundary values**: `--ppid` that does not parse as an integer, including the empty string and values with trailing characters, falls through to `claudePid` (MUST, per `ppid-resolution`). `SHLVL` that does not parse as an integer is omitted from `context.shell`.
- **Duplicate flags**: when the same key appears twice the later value replaces the earlier (the parser assigns into a dictionary); see `duplicate-flag-last-wins`.
- **Error states**: a payload that cannot be parsed, an unreadable working directory (`cwd` becomes the empty string), a failed `uname` call (`system` becomes an empty object) and a failed drop-file write are all absorbed, and the exit status stays 0 (MUST). The write failure leaves no trace: nothing is logged and the event is lost for that invocation.
- **Concurrent access**: hook commands for different events can run as separate processes at the same time. The type holds no shared state, and unique drop-file names are the drop writer's responsibility (see `HookDropWriter`). Within one process the code is synchronous and single-threaded.
- **Offline or disconnected state**: not applicable — this command never opens a network connection or a socket; it only writes a file, which is how it behaves when no daemon is listening.
- **Headless sessions**: a programmatic `claude` that a daemon's own app runs exports `ADH_SDK_HEADLESS` and is never tracked, even when the command is invoked directly or the daemon was down, so no headless drop file can be quarantined and later replayed into a phantom session (MUST).
- **Token walk finds nothing**: the token falls back to the forwarded `CLAUDE_CODE_OAUTH_TOKEN`, which the source describes as likely empty; `accountName` then receives that value or nil and decides what to return (MUST pass it through).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `arguments` | list of strings | none | The arguments after the subcommand: `--event <Type>` and optionally `--ppid <int>` |
| `stdin` | bytes | none | The payload Claude Code piped in |
| `environment` | string map | none | The environment the headless check, `term_program`, `term_session_id`, token fallback and drop-directory override read |
| `configuration` | `ClaudeHookConfiguration` | none | Supplies the drop directory and the override variable name (see `HookDropWriter`) |
| `accountName` | closure from optional token to string | none | Maps an OAuth token to its account name, empty when unknown |
| `oauthEmail` | closure returning string | returns the empty string | Reads the machine login's account |
| `claudePid` | closure returning optional Int32 | `ProcessEnv.claudePid(aboveHookParent:)`: the hook's parent, or that parent's parent when it is a `sh`, `bash`, `zsh` or `dash` shell, accepted only when its name is `claude` or `node`, else nil | Finds Claude's pid when no `--ppid` was passed |
| `ADH_SDK_HEADLESS` | environment variable | unset | Any value, even empty, suppresses tracking |
| `TERM_PROGRAM`, `TERM_SESSION_ID` | environment variables | empty string | Lifted onto `hook_data` |
| `CLAUDE_CODE_OAUTH_TOKEN` | environment variable | absent | Fallback token source |

## Deep Linking

Not applicable: the command is a headless capture routine and registers no URL scheme or route.

## Localization

Not applicable: the command produces no user-facing text; the keys and values it writes are a machine wire format.

## Accessibility Options

Not applicable: the command has no visual or motion output that a display option could change.

## Feature Flags

Not applicable: the source reads no feature-flag service. The one switch it reads, `ADH_SDK_HEADLESS`, is a process marker described under Behavioral Requirements, not a flag.

## Analytics

Not applicable: the command sends no analytics events; its only output is a local drop file.

## Privacy

- **Data collected**: the hook payload as Claude Code sent it, the account name and OAuth login email returned by the injected closures, and a process snapshot that includes `argv`, the working directory, user and group ids, `hostname`, `PATH`, `HOME`, `USER`, `LOGNAME`, `TMPDIR`, `PWD` and terminal identifiers.
- **Storage**: one JSON file in the drop directory, written by `HookDropWriter` with the file system's default permissions; the command sets none of its own.
- **Transmission**: none by this command; the drop file stays on the machine until a daemon reads it.
- **Retention**: this command never deletes a drop file; the daemon that scans the directory owns removal.
- **OAuth token**: the recovered token is used only as the argument to `accountName` and is not written into the envelope; the source does not otherwise redact the payload or the environment values it captures.

## Logging

Not applicable: the command makes no log call and writes nothing to stderr by design, so a failure leaves no trace.

## Platform Notes

- **SwiftUI**: not used; this is a command-line routine with no view layer. A SwiftUI app only chooses the `ClaudeHookConfiguration` and installs the helper.
- **Compose**: not used. An Android or JVM port would be a small launcher program (`ProcessBuilder` or a Gradle application) that reads `System.in` with `readBytes`, builds the envelope with `kotlinx.serialization` or `org.json`, and writes it with `java.nio.file.Files.move` using `StandardCopyOption.ATOMIC_MOVE`; there is no `getppid`, so the process-tree walk uses `ProcessHandle.current().parent()`.
- **React/Web**: a Node.js port is a CLI script: read all of `process.stdin`, `JSON.parse` inside try/catch, take values from `process.env`, `process.ppid`, `os.hostname()`, `os.type()`, `os.release()`, `os.arch()` and `os.userInfo()`, and write with `fs.writeFileSync` then `fs.renameSync`. A browser has no equivalent. Environment values in Node are always strings, matching the empty-string rule here.
- **AppKit / UIKit**: this is the source platform. Files: `Core/ClaudeHooks/HookCaptureCommand.swift`, tested by `HookCaptureTests`. It is a Foundation-only enum using `JSONSerialization`, `ISO8601DateFormatter`, `uname`, `getcwd`, `getppid` and `ProcessEnv` for the process-tree walk. It is macOS only in practice because `ProcessEnv` reads `KERN_PROCARGS2`; nothing in it touches AppKit or UIKit.
- **WinUI 3**: build the helper as a small .NET console executable (`dotnet new console`) that Claude Code runs as the hook command. Read stdin with `Console.OpenStandardInput` into a `MemoryStream`, parse with `System.Text.Json.JsonDocument` or `JsonNode.Parse` inside try/catch (an empty or non-object payload becomes an empty `JsonObject`), read the environment with `Environment.GetEnvironmentVariable`, and take host facts from `Environment.MachineName`, `RuntimeInformation.OSDescription` and `RuntimeInformation.ProcessArchitecture`. There is no `getppid` or `SHLVL`; find the parent process with `NtQueryInformationProcess` (`PROCESS_BASIC_INFORMATION.InheritedFromUniqueProcessId`) or `System.Management` `Win32_Process.ParentProcessId`, and read another process's environment through `ReadProcessMemory` on its PEB, which needs matching rights. Uid, euid and gid have no Windows counterpart and should be omitted or replaced by the user SID from `WindowsIdentity.GetCurrent`. Wrap the whole `Main` in try/catch and return 0, and never write to `Console.Out` or `Console.Error`. Write the drop file with `File.WriteAllBytes` to a `.tmp` name in the same directory and `File.Move`; there is no `rename(2)`, but `File.Move` within one volume is a single rename in the file system, so a scan that filters on the `.json` extension never sees a partial file, but it throws when the target name already exists unless `overwrite: true` is passed.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/HookCaptureCommand.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/ClaudeHooks/HookCaptureTests.swift` | confirmed (1.0.2) |

## Design Decisions

**Decision**: The command swallows every failure and always returns 0 with no output.
**Rationale**: The source contains no print, log or stderr call, and the comment on the write says stderr from a hook can confuse Claude Code and that the next event brings the same information; the type comment states the contract as "never fail, never produce stdout". The cost is that a failed write leaves no trace.
**Approved**: pending

**Decision**: The headless check lives in this command as well as in the shell hook and the socket path.
**Rationale**: The source comment explains that guarding here means a headless drop file is never written even when the command is invoked directly or the daemon was down, so none can be quarantined and replayed into a phantom session.
**Approved**: pending

**Decision**: `oauth_account_email` is resolved when the hook fires.
**Rationale**: A drop file can sit in the directory through an update, a migration, a reboot or a stopped daemon; the sessions upsert keeps the first OAuth stamp, so resolving at drain time would bill the whole backlog to whoever is logged in then.
**Approved**: pending

**Decision**: The OAuth token is recovered by walking up the process tree rather than read from the environment.
**Rationale**: Claude Code scrubs `CLAUDE_CODE_OAUTH_TOKEN` from the environment it hands hook commands; the environment value is kept only as a fallback when the walk fails.
**Approved**: pending

**Decision**: Claude's pid is found by an injected closure when `--ppid` is absent.
**Rationale**: The registered command does not pass `--ppid`; the closure defaults to `ProcessEnv.claudePid(aboveHookParent:)`, which looks at the hook's parent (skipping one shell) and accepts it only by process name, and tests inject it to avoid depending on the real process tree.
**Approved**: pending

**Decision**: `buildEnvelope` is public and pure over the supplied environment and stdin for `hook_data`, while `context` is still captured from the live process.
**Rationale**: The type comment says this keeps the headless-drop and `term_session_id` behavior unit-testable without mutating the process environment or redirecting stdin. The consequence is that the supplied environment does not drive the `context` groups, so a test cannot control them.
**Approved**: pending

**Decision**: Wire compatibility with the version 4 envelope is preserved by lifting `term_program` onto `hook_data` and by giving `SessionStart` a `pid`.
**Rationale**: The source comment names this "v4 wire-compat"; the value is 0 when Claude's pid is unknown so the key is always present for that event.
**Approved**: pending

**Decision**: Divergences from `HookEnvelopeBuilder`, the socket-path twin, are intentional or inherited and are recorded here: this command does not require a `session_id`; it checks headless by environment only (the builder also checks the daemon's working directory); it treats only `1` and `true` as true for `CLAUDECODE` and `CLAUDE_YOLO` where the builder uses `RawSetting.bool`, which also accepts `yes` and `on` and the false words; it includes `argv`, `cwd` and `pid` in `context.process` where the builder omits them; and it walks for the token before using the environment value where the builder prefers the forwarded environment value.
**Rationale**: The two builders are described in their own comments as producing the same context shape, and the differences follow from where each runs (a short-lived hook process versus a daemon). A port MUST pick one behavior per side deliberately.
**Approved**: pending

**Decision**: The drop file is written with the file system's default permissions, not owner-only.
**Rationale**: The envelope holds the OAuth login email, `PATH`, `HOME`, `argv` and user ids, so owner-only permissions (0600 on the file, 0700 on the directory) may be warranted; the source sets none today and this is recorded as an open choice.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | partial | privacy-and-data |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | passed | security |

The component separates concerns: argument parsing, envelope building, context capture and file writing are distinct functions, and the file mechanics sit in `HookDropWriter`. Unit-test coverage passes: `HookCaptureTests` and `HookCaptureCommandConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/ClaudeHooks/HookCaptureCommandConformanceTests.swift`) cover every vector, capture-001 to capture-022; the two token-recovery tests (capture-019, capture-020) skip themselves only when an ancestor of the test runner carries a real OAuth token. Explicit error handling is partial: failures are deliberately swallowed per the hook contract, so the code never reports them. Fault tolerance is passed because no failure can change the exit status. Data integrity is passed because the file is written through the drop writer's temporary-then-rename sequence. Data minimization is partial because the snapshot captures `PATH`, `HOME`, `argv` and other host details without a filter. No-PII-in-logs is passed because the command logs nothing. Token lifecycle is passed because the token is recovered per invocation, used only for the account lookup and never written to the envelope.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (HookCaptureCommandConformanceTests.swift, 22 of 22 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved source paths out of references, linked sibling recipes in depends-on and related, added a duplicate-flag requirement and four vectors, downgraded unit-test coverage to partial, and corrected the WinUI File.Move claim. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
