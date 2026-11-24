---
id: 9d6600fa-7b75-40fd-8beb-ab5ad3d1bc3b
title: "Terminal Text Injector"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Types a line into the exact live iTerm2 or Terminal.app pane a session runs in, then presses Return on its own; fails loudly rather than guess a pane."
platforms:
  - swift
  - macos
tags:
  - foundation
  - terminal
  - applescript
  - automation
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Text Injector

## Overview

`TerminalTextInjector` types a line of text (for example `/compact`) into the live terminal pane a session is running in, by scripting iTerm2 or Terminal.app through `NSAppleScript`. It runs only in a process that holds a user's GUI session and the TCC Automation grant: the app, or the command-line tool from a terminal. A daemon can drive neither.

It targets the exact pane so it never types into the wrong session. iTerm2 is matched by session id (from `TERM_SESSION_ID`) or, failing that, by the pane's TTY. Terminal.app is matched by the tab's TTY. A terminal it cannot target precisely fails with `unsupportedTerminal` instead of a guess. The pane resolution and the AppleScript builders are pure `static` functions, unit-tested without driving a terminal; only `inject` and `run` execute AppleScript. `SessionWatcher.SessionWatcherActionHandler` shares the same builders, passing `text: nil`, for its select-and-raise click actions.

## Behavioral Requirements

- **namespace**: The component MUST be a caseless public `enum` named `TerminalTextInjector` with no stored instance state.
- **supported-terminals**: `isSupported(termProgram:)` MUST return true for exactly `iTerm.app` and `Apple_Terminal`, and false for every other value, including the empty string.
- **supported-kept-in-step**: The set of terminals `isSupported` accepts MUST stay equal to the set `resolveTarget` can resolve: for each `termProgram` that `isSupported` accepts, `resolveTarget` returns non-nil given a non-empty session id (iTerm) or a live pid, and for every other value it returns nil.
- **target-cases**: `Target` MUST have three cases: `iTermSession(uuid:)`, `iTermTTY(tty:)` and `terminalTTY(tty:)`; it is `Equatable` and `Sendable`.
- **target-app**: `Target.app` MUST return `("iTerm2", "com.googlecode.iterm2")` for both iTerm cases and `("Terminal", "com.apple.Terminal")` for `terminalTTY`.
- **resolve-iterm-session**: For `iTerm.app`, `resolveTarget` MUST take the text after the last `:` of `termSessionId` as the uuid, and return `iTermSession(uuid:)` when that text is non-empty.
- **resolve-iterm-split**: The `termSessionId` split MUST omit empty pieces, so an id with no colon is used whole as the uuid and an id ending in `:` yields the piece before the colon.
- **resolve-iterm-tty-fallback**: For `iTerm.app` with an empty uuid, `resolveTarget` MUST return `iTermTTY(tty:)` using `ttyForPid`, and return nil when `ttyForPid` returns nil.
- **resolve-terminal-tty**: For `Apple_Terminal`, `resolveTarget` MUST ignore `termSessionId`, return `terminalTTY(tty:)` using `ttyForPid`, and return nil when `ttyForPid` returns nil.
- **resolve-unsupported**: For any other `termProgram`, `resolveTarget` MUST return nil.
- **tty-for-pid**: `ttyForPid` MUST return the controlling-terminal device path (`/dev/` plus the `devname` of the process's `e_tdev`) read with the `proc_pidinfo` libproc call (`PROC_PIDTBSDINFO`), with no subprocess.
- **tty-for-pid-nil**: `ttyForPid` MUST return nil for a pid of 0 or below, for a failed or short `proc_pidinfo` read, for a process whose `e_tdev` is 0, and when `devname` yields no name.
- **tty-main-thread-safe**: `ttyForPid` MUST NOT fork a subprocess, so it is safe to call on the main thread.
- **normalize-tty**: `normalizeTTY` MUST return its argument unchanged when it starts with `/dev/`, and otherwise prefix `/dev/`.
- **escape-order**: `escape` MUST double every backslash first and then turn every double quote into a backslash and a quote, so its own escapes are not escaped twice.
- **escape-line-breaks**: `escape` MUST replace every character for which `Character.isNewline` is true (a `\r\n` pair is one character) with one space, never delete it, so that adjacent words are not glued.
- **escape-tab**: `escape` MUST replace a tab with a space, because a tab typed at an agent's prompt is a completion key and not text.
- **escape-controls**: `escape` MUST drop every other character whose Unicode scalars are all in the `.control` general category (NUL, ESC, ^C, ^D, DEL), because each would reach the pane as a keystroke.
- **escape-text-kept**: `escape` MUST leave non-control text, including accented letters, symbols and CJK characters, unchanged.
- **script-iterm**: For an iTerm target, `script(for:text:raising:)` MUST build a script that begins with `tell application id "com.googlecode.iterm2"`, searches every session of every tab of every window, and tests `id of s is "<escaped uuid>"` or `tty of s is "<escaped normalized tty>"`.
- **script-iterm-bundle-id**: The iTerm script MUST address iTerm by bundle id, not by the name "iTerm" or "iTerm2".
- **script-terminal**: For a `terminalTTY` target, `script(for:text:raising:)` MUST build a script that begins with `tell application "Terminal"`, searches every tab of every window, and tests `tty of t is "<escaped normalized tty>"`.
- **script-sentinels**: Every built script MUST return the string `found` from inside the matching branch and fall through to return the string `not_found` when no pane matches.
- **script-iterm-typing**: With a non-nil `text`, the iTerm script MUST write `tell s to write text "<escaped text>" newline no`, so the text is typed without a newline.
- **script-terminal-typing**: With a non-nil `text`, the Terminal.app script MUST run `do script "<escaped text>" in t`, which runs the text in the existing tab and does not open a window.
- **script-text-escaped**: The text and the uuid or TTY interpolated into a script MUST pass through `escape` first.
- **script-text-nil**: With `text: nil` the script MUST contain no `write text` and no `do script`, and so MUST NOT type into or run anything in the pane.
- **script-no-delay**: A typing script MUST NOT contain an AppleScript `delay`, because a `delay` inside the script froze the caller's UI.
- **script-raising-off**: With `raising: false` the script MUST NOT select, activate or bring forward the pane or its application: for iTerm no `select s`, `select t` or `activate`; for Terminal no `set selected tab`, `set frontmost` or `activate`.
- **script-raising-on-iterm**: With `raising: true` the iTerm script MUST run `select s`, `select t` and `activate` inside the matching branch only, before any write.
- **script-raising-on-terminal**: With `raising: true` the Terminal.app script MUST run `set selected tab of w to t`, `set frontmost of w to true` and `activate` inside the matching branch only, before any run.
- **return-script**: `returnScript(for:)` MUST build a script that finds the same pane and presses Return alone: `tell s to write text ""` for iTerm and `do script "" in t` for Terminal.app.
- **return-never-raises**: `returnScript(for:)` MUST NOT raise the terminal.
- **return-delay**: `returnDelay` MUST be 300 milliseconds, so the Return lands as its own keystroke after the paste rather than inside it.
- **split-submit**: The typing script MUST NOT include the Return. The text is typed without a newline so that the Return arrives as its own keystroke (see Design Decisions).
- **terminal-return-extra**: For Terminal.app, which has no `newline no`, Return MUST still follow as a separate `do script ""`; after a line that did submit, it meets an empty prompt, which ignores it.
- **inject-order**: `inject(_:termProgram:termSessionId:pid:raising:)` MUST, in order, check `isSupported`, resolve the target, run the typing script, wait `returnDelay`, then run the Return script, and return the result of the Return script.
- **inject-unsupported**: `inject` MUST return `.failure(.unsupportedTerminal(name))` when the terminal is unsupported, where name is `termProgram`, or `an unknown terminal` when `termProgram` is empty.
- **inject-unresolvable**: `inject` MUST return `.failure(.paneUnresolvable)` when `resolveTarget` returns nil.
- **inject-stops-on-first-failure**: `inject` MUST NOT wait or press Return when the typing script fails; it MUST return that failure.
- **inject-fresh-lookup**: Each half of `inject` MUST find the pane afresh, so a pane closed between the two halves fails the Return half as `paneNotFound`.
- **inject-raising-default**: `inject` MUST default `raising` to false. Sending a line to a session is not a request to watch it, and a terminal jumping in front of the sender's window takes away what they were reading.
- **inject-wait-off-main**: The wait between the halves MUST be an `await` on `Task.sleep(for: returnDelay)`, so the main thread is free during it.
- **main-actor**: `inject` and `run` MUST be `@MainActor`; `escape`, `script`, `returnScript`, `resolveTarget`, `normalizeTTY` and `ttyForPid` are nonisolated pure or syscall functions.
- **run-compile**: `run(script:target:)` MUST return `.failure(.scriptFailed("could not compile the AppleScript"))` when `NSAppleScript(source:)` returns nil.
- **run-execute**: `run` MUST execute the script with `executeAndReturnError` and, when an error dictionary comes back, return `.permissionDenied` if it is an Automation denial and `.scriptFailed(message)` otherwise.
- **run-error-message**: The `scriptFailed` message MUST be the dictionary's `NSAppleScript.errorMessage` string, or the dictionary's description when that key is missing or not a string.
- **run-not-found**: `run` MUST return `.failure(.paneNotFound)` when the script's output string, trimmed of whitespace and newlines, equals `not_found`.
- **run-success**: `run` MUST return `.success(())` when the script ran without error and did not return `not_found`.
- **permission-detection**: An error MUST be mapped to `permissionDenied` when its error number is -1743 or -1744, or its message contains `not authorized` or `privilege violation` compared case-insensitively.
- **permission-payload**: `permissionDenied` MUST carry the message `Automation permission is required to control <app name>. Grant it in System Settings ▸ Privacy & Security ▸ Automation.` and the target's bundle id, which an app maps onto its permission UI.
- **error-cases**: `InjectionError` MUST be `Error`, `LocalizedError` and `Equatable` with five cases: `unsupportedTerminal(String)`, `paneUnresolvable`, `paneNotFound`, `permissionDenied(String, targetBundleID: String)` and `scriptFailed(String)`.
- **error-descriptions**: `errorDescription` MUST be, in order: `Injecting text isn't supported for <name> yet — only iTerm2 and Terminal.app.`; `Couldn't identify the session's terminal pane.`; `The session's terminal pane wasn't found — it may have been closed.`; the permission message unchanged; and `Terminal automation failed: <message>`.
- **no-retry**: The component MUST NOT retry a failed script, apply a timeout or cancel a running script; each call runs each half once.
- **foundation-only**: The component MUST depend only on Foundation and Darwin (`NSAppleScript` and libproc), so the app and the CLI share one copy of the escaping.

## Appearance

Not applicable — this is a scripting helper that types into another application's terminal, not a visual component.

## States

Not applicable — this is a scripting helper, not a visual component; it holds no state between calls.

## Accessibility

Not applicable — this is a scripting helper, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-text-injector-001 | supported-terminals | `isSupported` for `iTerm.app`, `Apple_Terminal`, `WarpTerminal`, and the empty string (test: testSupportedTerminals). | true, true, false, false. |
| terminal-text-injector-002 | resolve-iterm-session | `resolveTarget(termProgram: "iTerm.app", termSessionId: "w0t1p0:ABC-123", pid: 0)` (test: testResolvesITermBySessionUUID). | `iTermSession(uuid: "ABC-123")`; no live pid needed. |
| terminal-text-injector-003 | resolve-iterm-tty-fallback, tty-for-pid-nil | `iTerm.app`, empty session id, pid 0 (test: testITermWithoutSessionIdAndDeadPidIsUnresolvable). | nil. |
| terminal-text-injector-004 | resolve-terminal-tty, tty-for-pid-nil | `Apple_Terminal`, empty session id, pid 0 (test: testTerminalWithoutLivePidIsUnresolvable). | nil. |
| terminal-text-injector-005 | resolve-unsupported | `WarpTerminal`, session id `x:y`, pid 4242 (test: testUnsupportedTerminalHasNoTarget). | nil. |
| terminal-text-injector-006 | script-iterm, script-iterm-typing, script-sentinels | `script(for: .iTermSession(uuid: "ABC"), text: "/compact", raising: false)` (test: testITermScriptWritesTextToMatchedSession). | Contains `com.googlecode.iterm2`, `id of s is "ABC"`, `write text "/compact"` and `return "not_found"`. |
| terminal-text-injector-007 | script-iterm, normalize-tty | `script(for: .iTermTTY(tty: "/dev/ttys003"), text: "/compact", raising: false)` (test: testITermTTYScriptMatchesByTTY). | Contains `tty of s is "/dev/ttys003"` and `write text "/compact"`. |
| terminal-text-injector-008 | script-terminal, script-terminal-typing, normalize-tty | `script(for: .terminalTTY(tty: "ttys004"), text: "/compact", raising: false)` (test: testTerminalScriptRunsDoScriptInMatchedTab). | Contains `tell application "Terminal"`, `tty of t is "/dev/ttys004"` and `do script "/compact" in t`. |
| terminal-text-injector-009 | script-text-escaped, escape-order | iTerm session script with text `say "hi"` (test: testScriptEscapesInjectedText). | Contains `write text "say \"hi\""`. |
| terminal-text-injector-010 | script-raising-off | iTerm and Terminal typing scripts with `raising: false` (tests: testITermInjectionDoesNotRaiseTheTerminal, testTerminalInjectionDoesNotRaiseTheTerminal). | The line is still written; no `activate`, `select s`, `select t`, `set frontmost` or `set selected tab`. |
| terminal-text-injector-011 | script-raising-on-iterm | iTerm session script with `raising: true` (test: testITermInjectionCanRaiseWhenAsked). | Contains `write text "/compact"`, `activate` and `select s`. |
| terminal-text-injector-012 | script-text-nil, script-raising-on-iterm | iTerm session script with `text: nil`, `raising: true` (test: testITermSelectOnlyScriptOmitsWriteText). | Contains `id of s is "ABC"`, `select s` and `activate`; contains no `write text`. |
| terminal-text-injector-013 | script-text-nil, script-raising-on-terminal | Terminal script with `text: nil`, `raising: true` (test: testTerminalSelectOnlyScriptOmitsDoScript). | Contains `tty of t is "/dev/ttys004"` and `set selected tab of w to t`; contains no `do script`. |
| terminal-text-injector-014 | escape-order | `escape(#"a"b\c"#)` (test: testEscapeQuotesAndBackslashes). | `a\"b\\c`. |
| terminal-text-injector-015 | escape-line-breaks | `escape("first\nsecond")` and `escape("a\nb\rc\r\nd")` (test: testEscapeTurnsNewlinesIntoSpaces). | `first second` and `a b c d`. |
| terminal-text-injector-016 | escape-controls | `escape("a\0b")` (test: testEscapeDropsNulls). | `ab`. |
| terminal-text-injector-017 | escape-controls, escape-tab, escape-text-kept | `escape` of `a`, ESC, `[0mb`, ^C, `c`, ^D, `d`, DEL, `e`; of `col1<TAB>col2`; of `café ✓ 日本` (test: testEscapeDropsKeystrokeControlCharacters). | `a[0mbcde`; `col1 col2`; `café ✓ 日本`. |
| terminal-text-injector-018 | normalize-tty | `normalizeTTY("ttys001")` and `normalizeTTY("/dev/ttys001")` (test: testNormalizeTTYAddsDevPrefix). | `/dev/ttys001` for both. |
| terminal-text-injector-019 | split-submit, script-no-delay, return-script, return-never-raises | iTerm typing script with text `hello`; `returnScript(for: .iTermSession(uuid: "ABC"))` (test: testITermTypesWithoutReturnAndPressesReturnSeparately). | Typing script contains `write text "hello" newline no`, no `write text ""` and no `delay`; the return script contains `id of s is "ABC"` and `tell s to write text ""`, and no `activate`. |
| terminal-text-injector-020 | terminal-return-extra, script-no-delay, return-script | Terminal typing script with text `hello`; `returnScript(for: .terminalTTY(tty: "ttys004"))` (test: testTerminalTypesThenPressesReturnSeparately). | Typing script contains `do script "hello" in t`, no `do script "" in t` and no `delay`; the return script contains `tty of t is "/dev/ttys004"` and `do script "" in t`, and no `activate`. |
| terminal-text-injector-021 | return-script, normalize-tty | `returnScript(for: .iTermTTY(tty: "ttys003"))` (test: testITermTTYReturnScriptMatchesByTTY). | Contains `tty of s is "/dev/ttys003"`. |
| terminal-text-injector-022 | resolve-iterm-split | `resolveTarget(termProgram: "iTerm.app", termSessionId: "ABC", pid: 0)`, and with `termSessionId: "w0t0p0:"` (derived from the source; no test). | `iTermSession(uuid: "ABC")`, and `iTermSession(uuid: "w0t0p0")`. |
| terminal-text-injector-023 | inject-unsupported | `await inject("x", termProgram: "", termSessionId: "", pid: 1)` (derived from the source; no test). | `.failure(.unsupportedTerminal("an unknown terminal"))`; no script runs. |
| terminal-text-injector-024 | inject-unresolvable | `await inject("x", termProgram: "Apple_Terminal", termSessionId: "", pid: 0)` (derived from the source; no test). | `.failure(.paneUnresolvable)`. |
| terminal-text-injector-025 | run-not-found | `run` on a script whose output is `not_found` (derived from the source; the test file states `run` has no unit-testable surface). | `.failure(.paneNotFound)`. |
| terminal-text-injector-026 | permission-detection, permission-payload | An AppleScript error with number -1743, then one with number -1 and message `Privilege Violation occurred`, against a Terminal target (derived from the source; no test). | Both give `.permissionDenied(message, targetBundleID: "com.apple.Terminal")` with the message `Automation permission is required to control Terminal. Grant it in System Settings ▸ Privacy & Security ▸ Automation.` |
| terminal-text-injector-027 | error-descriptions | `InjectionError.unsupportedTerminal("WarpTerminal").errorDescription` (derived from the source; no test). | `Injecting text isn't supported for WarpTerminal yet — only iTerm2 and Terminal.app.` |
| terminal-text-injector-028 | tty-for-pid-nil | `ttyForPid(0)` and `ttyForPid(-5)` (derived from the source; no test). | nil for both. |
| terminal-text-injector-029 | supported-kept-in-step | `resolveTarget` for `iTerm.app` with session id `x:ABC` and for `Apple_Terminal` with pid 0 (derived from the source; no test). | `iTermSession(uuid: "ABC")`, and nil because no TTY resolves for pid 0; `isSupported` is true for both. |
| terminal-text-injector-030 | permission-detection | An AppleScript error with number -1744, then one with number -1 and message `Not authorized to send Apple events` (derived from the source; no test). | Both map to `permissionDenied`. |
| terminal-text-injector-031 | run-error-message | An AppleScript error dictionary with `NSAppleScript.errorMessage` `boom`, then one with no message key (derived from the source; no test). | `.failure(.scriptFailed("boom"))`, then `.scriptFailed` carrying the dictionary's description. |
| terminal-text-injector-032 | inject-stops-on-first-failure | `inject` where the typing script returns `not_found` (derived from the source; no test). | `.failure(.paneNotFound)` at once; no wait and no Return script. |
| terminal-text-injector-033 | inject-fresh-lookup, run-not-found | `inject` where the pane exists for the typing script and is closed before the Return script (derived from the source; no test). | `.failure(.paneNotFound)` from the Return half. |
| terminal-text-injector-034 | error-descriptions | `errorDescription` of `paneUnresolvable`, `paneNotFound` and `scriptFailed("boom")` (derived from the source; no test). | `Couldn't identify the session's terminal pane.`; `The session's terminal pane wasn't found — it may have been closed.`; `Terminal automation failed: boom`. |
| terminal-text-injector-035 | inject-order | `inject("", ...)` against a resolvable pane (derived from the source; no test). | The typing script runs with an empty string, then the Return script runs; the result is the Return script's result. |
## Edge Cases

- **Null / empty input**: An empty `termProgram` is unsupported and reports the name `an unknown terminal` (MUST). An empty `text` (non-nil) produces a script that writes an empty string: for Terminal.app `do script "" in t` is a Return, while for iTerm `write text "" newline no` types nothing. Through `inject` the Return half still runs on both terminals, so an empty `text` presses Return once and submits whatever the pane's prompt holds; `escape("")` is empty. A `termSessionId` that is empty or only colons yields no uuid and falls back to the TTY (MUST).
- **Boundary values**: A pid of 0 or below has no TTY (MUST). When `resolveTarget` needs the TTY (iTerm with no uuid, or Terminal.app) it converts the `Int` pid with `Int32(pid)` and no range check, so a pid above `Int32.max` traps; real pids never reach that, and the signature leaves the range to the caller.
- **Line breaks in text**: Any line break becomes a single space, so a multi-line message is sent as one line and submitted once (MUST).
- **Embedded control keys**: ESC, ^C, ^D, DEL and NUL are dropped so they cannot interrupt, clear or exit the agent (MUST).
- **Pane closed between halves**: The Return half finds the pane afresh and fails `paneNotFound`; the text already typed stays in the pane's input (MUST).
- **Cancellation**: `try? await Task.sleep` discards the cancellation error, so a cancelled caller still presses Return immediately without the 300 ms wait. The source has no other cancellation path; this is a fact about the code, not a contract it declares.
- **Concurrent access**: `inject` and `run` are `@MainActor`, so calls are serialised on the main actor; the `await` between the halves lets other main-actor work, including another `inject`, interleave between one call's typing and its Return. The source adds no lock or per-pane queue.
- **Retry and logging**: The component never retries a failed script, applies no timeout and logs nothing; each caller decides what to do with the returned `InjectionError`.
- **Error states**: Every failure is returned as an `InjectionError` in a `Result`; none is thrown or logged. A compile failure, an AppleScript error and a miss each surface as a distinct case.
- **Automation denied**: An error with number -1743 or -1744, or a "not authorized" or "privilege violation" message, becomes `permissionDenied` carrying the terminal's bundle id (MUST).
- **Unsupported terminal**: Warp, VS Code and unknown terminals fail with `unsupportedTerminal` and nothing is typed (MUST).
- **Blocking**: `NSAppleScript.executeAndReturnError` is synchronous and runs on the main actor, so a slow terminal holds the main thread for that script's duration; the source has no timeout.
- **Offline / disconnected state**: Not applicable: the component makes no network request; it talks to a local application over Apple events.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `String` | none | The line to type; escaped before use. `nil` on `script(for:text:raising:)` builds the select-only variant. |
| `termProgram` | `String` | none | The terminal's `TERM_PROGRAM` value; only `iTerm.app` and `Apple_Terminal` are accepted. |
| `termSessionId` | `String` | none | The `TERM_SESSION_ID` value; the part after the last `:` is the iTerm session uuid. Ignored for Terminal.app. |
| `pid` | `Int` | none | A process in the session, used to find its controlling TTY when no iTerm session id is known and always for Terminal.app. |
| `raising` | `Bool` | `false` on `inject`; required on `script(for:text:raising:)` | Whether the pane is selected and its application brought forward. |
| `returnDelay` | `Duration` | 300 milliseconds | The pause between typing and the Return. It is internal (not public) and constant. |

The component reads no environment variable and no settings key; the caller passes the `TERM_PROGRAM` and `TERM_SESSION_ID` values in.

## Deep Linking

Not applicable: The component defines no URL scheme, route or navigation destination.

## Localization

The component has user-facing strings, all hardcoded English with no localization lookup. They are the `errorDescription` texts under the `error-descriptions` requirement and the `permissionDenied` message under `permission-payload`; the `scriptFailed` message embeds the text AppleScript supplies.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (unsupportedTerminal) | `Injecting text isn't supported for <name> yet — only iTerm2 and Terminal.app.` | Error description. |
| none (paneUnresolvable) | `Couldn't identify the session's terminal pane.` | Error description. |
| none (paneNotFound) | `The session's terminal pane wasn't found — it may have been closed.` | Error description. |
| none (permissionDenied) | `Automation permission is required to control <app name>. Grant it in System Settings ▸ Privacy & Security ▸ Automation.` | Carried message. |
| none (scriptFailed) | `Terminal automation failed: <message>` | Error description. |
| none (compile failure) | `could not compile the AppleScript` | `scriptFailed` message. |

## Accessibility Options

Not applicable: The component presents no UI of its own.

## Feature Flags

Not applicable: The source contains no feature-flag reference.

## Analytics

Not applicable: The source contains no analytics call.

## Privacy

- **Data handled**: The text it types into the pane, which may be a user's message, a log line or a command's output, and the session's TTY and session id.
- **Storage**: None; it persists nothing.
- **Transmission**: The text goes to the terminal application over local Apple events; nothing leaves the machine.
- **Retention**: None beyond the lifetime of the call; the terminal keeps what it was typed.

## Logging

Not applicable: The source calls no logging API; failures are returned as `InjectionError` values.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalTextInjector.swift`, imports only `Darwin` and `Foundation`, and has no SwiftUI dependency. A SwiftUI host calls `inject` from a `@MainActor` task and maps `permissionDenied`'s bundle id onto its permission UI. Tests are in `TerminalTextInjectorTests.swift` under `AgenticDeveloperHubSDKCoreMacOSTests`.
- **Compose**: Android has no terminal panes to script. A port would pick a different transport (for example tmux `send-keys` over SSH) behind the same target choice and keep the `escape` rules: line breaks to a space, controls dropped, a separate Return after a 300 ms `kotlinx.coroutines.delay`.
- **React/Web**: A browser cannot drive a local terminal. A Node or Electron host would run `osascript` through `child_process.execFile` with the script as an argument (not a shell string) and port `escape`, the builders and the two-step Return; `await new Promise(r => setTimeout(r, 300))` replaces `Task.sleep`.
- **AppKit / UIKit**: AppKit is where the source runs. `NSAppleScript` executes synchronously on the calling thread and needs the Automation grant and an `NSAppleEventsUsageDescription` string in the host's Info.plist. UIKit has no equivalent; iOS cannot script another app.
- **WinUI 3**: Windows has no AppleScript, so a port keeps the pure `escape` rules and replaces the transport. For a console the app owns, create a pseudoconsole (`CreatePseudoConsole`) and write to its input pipe through a `System.IO.Stream`. For a foreign console window, resolve it from a process id (`GetConsoleWindow` after `AttachConsole`, or `GetWindowThreadProcessId`) in place of `ttyForPid`, and send keystrokes with `SendInput` or UI Automation (`InvokePattern`, `ValuePattern`). Model `InjectionError` as a sealed class hierarchy or a result type with five cases. Wait with `await Task.Delay(TimeSpan.FromMilliseconds(300))` so the UI thread is not blocked, and run any call that needs the UI thread through the window's `DispatcherQueue.TryEnqueue`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalTextInjector.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Target the exact pane (iTerm session id, else TTY; Terminal.app TTY) and fail with `unsupportedTerminal` or `paneUnresolvable` rather than guess.
**Rationale**: The source calls typing into the wrong session "the whole hazard this guards".
**Approved**: pending

**Decision**: Press Return as a second, separate script after a 300 ms `await`, not in the typing script and not through an AppleScript `delay`.
**Rationale**: Handed in one write, the newline arrives inside the paste and Claude Code's input box keeps it as part of the paste, so the line is typed but never submitted. A `delay` inside one script froze the caller's UI, so the wait is an `await` on the main actor.
**Approved**: pending

**Decision**: Terminal.app also gets a separate `do script ""` for Return even though its own newline exists.
**Rationale**: Seen live: a short line submits, a line of about 200 characters sat in the input until a separate Return. After a line that did submit, the extra Return meets an empty prompt and is ignored.
**Approved**: pending

**Decision**: `escape` turns every line break and tab into a space and drops every other control character.
**Rationale**: `write text` and `do script` press Return at the end of what they are handed, so an embedded newline would submit half the message. Deleting breaks glued words ("the fileare you sure"). A tab is a completion key, and ESC, ^C and ^D are interrupt, clear and exit keystrokes that script-supplied text carries by accident.
**Approved**: pending

**Decision**: `inject` does not raise the terminal by default (`raising: false`); the select-and-raise variant is `script` with `raising: true` and `text: nil`.
**Rationale**: Sending a line is not a request to watch the session, and a terminal jumping forward takes away the window the sender was reading. Raising does not change delivery.
**Approved**: pending

**Decision**: The pane lookup uses `proc_pidinfo` rather than a forked `ps`.
**Rationale**: It is a syscall, near-instant, and safe on the main thread, whereas a forked process with `waitUntilExit` blocks the caller.
**Approved**: pending

**Decision**: The pane-script builders and `escape` are public pure functions, and only `run` executes AppleScript.
**Rationale**: The string assembly and escaping are the risky part and are unit-tested without a real terminal; the app, the CLI and the session click actions share one copy.
**Approved**: pending

**Decision**: Address iTerm2 by its bundle id `com.googlecode.iterm2`, not by the application name.
**Rationale**: The application's name has varied across versions, while the bundle id has not.
**Approved**: pending

**Decision**: Error descriptions are English literals; callers localise by matching the `InjectionError` case, and a later version may move the texts to string keys.
**Rationale**: This is a Foundation-tier helper with no localization bundle, and the typed cases give an app everything it needs to show its own text.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.platform-compliance.platform-permissions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90cb6a83-7544-53ea-8d2c-30851b253122) | passed | Platform Compliance |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | partial | Performance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

separation-of-concerns passes: the type resolves a pane, builds scripts and runs them, while the choice of what to type and when belongs to its callers (the session watcher and the app). unit-test-coverage is partial: `TerminalTextInjectorTests` (`Tests/AgenticDeveloperHubSDKCoreMacOSTests/TerminalTextInjectorTests.swift`) covers every vector except 032, 033 and 035, including `run` and the permission mapping through in-process AppleScript errors. Vectors 032, 033 and 035 are skipped because `inject` needs a live iTerm2 or Terminal.app pane to answer the scripts, and vector 031 covers only the `boom` message, since AppleScript always supplies one. explicit-error-handlingexplicit-error-handling passes: every failure is a typed `InjectionError` returned in a `Result`. input-sanitization passes: the text, uuid and TTY are escaped before interpolation and line breaks and control keys are removed. platform-permissions passes: an Automation denial is detected and returned with the terminal's bundle id for the app's permission UI. main-thread-freedom is partial: the wait is an `await` and the TTY lookup is a syscall, but `NSAppleScript` executes synchronously on the main actor. no-hardcoded-strings fails: the error texts are English literals with no localization lookup.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (TerminalTextInjectorTests.swift, 32 of 35 vectors); unit-test-coverage now partial (032, 033, 035 skipped: need a live terminal pane). |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Restated several requirements as plain contract statements, replaced a rationale-free decision with a Retry and logging edge case, added a localization decision and a bundle-id decision, clarified empty-text injection, and added seven test vectors. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
