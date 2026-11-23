---
id: ed460f60-2a13-4a3c-b7eb-53c531bf0741
title: "MCP Registration"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Builds the one-time claude mcp add-json command that registers a daemon channel's MCP endpoint with Claude Code, with a headersHelper in place of a token, and checks the Claude config to see whether it is registered."
platforms:
  - swift
  - macos
tags:
  - mcp
  - registration
  - claude-code
depends-on: []
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
references: []
approved-by: ""
approved-date: ""
---

# MCP Registration

## Overview

MCP Registration is how a Claude Code install learns about adhd's MCP endpoint. It is a stateless namespace with two operations. The first builds the text of a single `claude mcp add-json` command that the user runs once. The second reads Claude Code's configuration file and reports whether the channel's server is registered at the channel's address. It performs no process execution, no network access and no writes.

Each daemon channel has an entry of its own: `adhd-dev` for the dev daemon on port 22871 and `adhd` for the release daemon on port 22850, so a dev build never takes over the release entry. The entry carries no token: its `headersHelper` is a command line that runs `adhd mcp headers`, which prints the bearer header each time Claude Code connects, so no token is ever written into `~/.claude.json`, a shell history or a pane's environment. The endpoint it registers is served by adhd over [adhsdk.ingredient.ai.mcp.mcphttp-endpoint](cookbook:03ac452d-50c9-4438-9cfb-9cb2c2b65249)'s handler; the sibling [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56) covers the client side of MCP.

The source is one file, `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPRegistration.swift`, a public `enum MCPRegistration` with no cases, a nested `Channel` enum, one constant and three static functions.
## Behavioral Requirements

Channels

- **channel-cases**: `MCPRegistration.Channel` MUST have exactly two cases, `dev` and `release`, and be `Sendable` and `CaseIterable`.
- **channel-server-name**: `serverName` MUST be `adhd-dev` for `dev` and `adhd` for `release`.
- **channel-port**: `port` MUST be 22871 for `dev` and 22850 for `release`.
- **channel-url**: `url` MUST be `http://127.0.0.1:<port>` followed by the endpoint's path constant, `MCPHTTPEndpoint.path` (`/mcp`).

Building the entry and the command

- **headers-subcommand**: `headersSubcommand` MUST be `mcp headers`, the adhd subcommand that prints `{"Authorization":"Bearer <token>"}`.
- **entry-json**: `entryJSON(channel:adhdPath:)` MUST return a JSON object with exactly the keys `headersHelper`, `type` and `url`, keys sorted and slashes unescaped, where `type` is `http`, `url` is the channel's URL and `headersHelper` is the adhd path as one shell word, a space and `headersSubcommand`.
- **entry-path-quoting**: The adhd path MUST be left bare when it is non-empty and made only of letters, digits and `_-./:@+,`, and otherwise wrapped in single quotes with each single quote written `'\''` (`PartnerStepTemplate.shellQuoted`).
- **entry-no-token**: The entry MUST carry no token and no `Authorization` header.
- **command-is-text-only**: `claudeCommand(channel:adhdPath:)` MUST return the command as a string and MUST NOT execute it, read any file, or touch the network.
- **command-shape**: The command MUST be `claude mcp add-json --scope user <serverName> ` followed by the entry JSON quoted as one shell word by the same rule, so the helper's own single quotes survive.

Checking registration: `isRegistered(claudeConfig:channel:)`

- **registered-reads-config-file**: `isRegistered` MUST read the file at `claudeConfig` (normally `~/.claude.json`) and MUST NOT modify it.
- **registered-needs-server-entry**: `isRegistered` MUST return true only when the file's top level is a JSON object whose `mcpServers` value is an object containing a key equal to the channel's `serverName` whose value is itself an object with a string `url`.
- **registered-url-equal**: `isRegistered` MUST return true exactly when that `url` equals the channel's URL; a different port, another channel's URL or any other text is false.
- **registered-old-entry**: An `adkitchen` entry, the name the Kitchen registered before apps suite Phase 4, MUST NOT count as a registration of either channel.
- **registered-ignores-headers**: `isRegistered` MUST NOT consider the entry's `type`, `headers` or `headersHelper`; only its `url` decides the answer.
- **registered-failure-is-false**: `isRegistered` MUST return false, without throwing, when the file is missing, unreadable, not valid JSON, or not a JSON object, with no signal that distinguishes them.

Concurrency and side effects

- **stateless**: `MCPRegistration` MUST hold no state; its functions are pure apart from `isRegistered`'s synchronous file read, so they MAY be called from any thread concurrently.
## Appearance

Not applicable — this is a command builder and a config-file reader, not a visual component.

## States

Not applicable — this is a command builder and a config-file reader, not a visual component; it has no runtime state, so there is no state machine to record either.

## Accessibility

Not applicable — this is a command builder and a config-file reader with no user interface of its own.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mcp-registration-001 | channel-server-name, channel-port, channel-url | `Channel.dev` and `Channel.release` | `adhd-dev`, 22871, `http://127.0.0.1:22871/mcp`; `adhd`, 22850, `http://127.0.0.1:22850/mcp` (`MCPRegistrationTests.testEachChannelHasItsOwnNameAndPort`) |
| mcp-registration-002 | command-shape, entry-json, entry-no-token | `claudeCommand(channel: .dev, adhdPath: "/opt/adhd/adhd")` | Exactly `claude mcp add-json --scope user adhd-dev '{"headersHelper":"/opt/adhd/adhd mcp headers","type":"http","url":"http://127.0.0.1:22871/mcp"}'`, with no `Bearer` (`testClaudeCommandIsTheHeadersHelperForm`) |
| mcp-registration-003 | entry-path-quoting, command-shape | `entryJSON(channel: .release, adhdPath:)` with a path holding a space | `headersHelper` is `'<path>' mcp headers`; the command starts `claude mcp add-json --scope user adhd '` and contains `'\''` (`testAPathWithSpacesIsOneShellWordInTheHelper`) |
| mcp-registration-004 | registered-needs-server-entry, registered-url-equal | `{"mcpServers":{"adhd-dev":{"type":"http","url":"http://127.0.0.1:22871/mcp"}}}` | true for `.dev`, false for `.release` (`testRegisteredWhenTheEntryPointsAtTheChannel`) |
| mcp-registration-005 | registered-old-entry | `{"mcpServers":{"adkitchen":{"type":"http","url":"http://127.0.0.1:22871/mcp"}}}` | false for `.dev` (`testTheOldKitchenEntryIsNotARegistration`) |
| mcp-registration-006 | registered-url-equal | An `adhd-dev` entry whose url is `http://127.0.0.1:22850/mcp` | false for `.dev` (`testNotRegisteredWhenThePortDiffers`) |
| mcp-registration-007 | registered-failure-is-false | `/nonexistent/.claude.json`, then a file containing `not json` | false in both cases, with no thrown error (`testNotRegisteredWhenTheFileIsMissingOrNotJSON`) |
| mcp-registration-008 | registered-needs-server-entry | `{"mcpServers":{"adhd-dev":{"type":"http"}}}` | false, because the entry has no `url` (derived from the `guard`; no test) |
| mcp-registration-009 | registered-ignores-headers | An `adhd-dev` entry with the right `url` and any `headersHelper` | true (derived from the single `url` check; no test) |
## Edge Cases

- **Null and empty input**: An empty `adhdPath` MUST be quoted as `''`, giving the helper `'' mcp headers`, which fails when Claude Code runs it (MUST; nothing rejects it). An empty config file or a file with no `mcpServers` key MUST yield false (MUST).
- **Boundary values**: The ports are fixed per channel; the check is an exact string comparison, so a trailing slash, another host spelling such as `localhost`, or an environment-default form all count as not registered (MUST).
- **Paths with spaces or quotes**: The path is one shell word inside the helper, and the whole entry is one shell word in the command, so a path holding spaces or single quotes survives both levels of quoting (MUST).
- **Concurrent access**: The functions are free of shared state. `isRegistered` reads the file once, synchronously; if Claude Code rewrites `~/.claude.json` mid-read and the read sees partial JSON, the call reports false (MUST, per `registered-failure-is-false`).
- **Error states**: A missing, unreadable or malformed config file is reported as false; the source swallows the underlying error (`try?`) and returns no reason (MUST).
- **Offline or disconnected state**: Not applicable: no function uses the network; the only I/O is one local file read.
- **Cancellation, timeouts**: Not applicable: every function is synchronous and runs to completion.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `channel` (parameter to every function) | `MCPRegistration.Channel` | none — required | Which adhd the entry points at: its server name, port and URL. |
| `adhdPath` (parameter to `entryJSON` and `claudeCommand`) | `String` | none — required | The installed adhd executable the `headersHelper` runs. |
| `claudeConfig` (parameter to `isRegistered`) | `URL` | none — required | The Claude Code configuration file to read; normally `~/.claude.json`. |
| `headersSubcommand` | `String` constant | `mcp headers` | The adhd subcommand the helper runs. |
| `MCPHTTPEndpoint.path` | `String` constant (owned by the endpoint) | `/mcp` | The URL path of the registered endpoint. |
## Deep Linking

Not applicable: the registered URL addresses a loopback MCP endpoint for Claude Code, not an app deep link or navigation destination; the source defines no URL scheme or route of its own.

## Localization

Not applicable: the command text and the config keys are protocol literals, not user-facing strings, and the source contains no error or display strings.

## Accessibility Options

Not applicable: the source renders no UI, so it observes no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: the source reads no flag or setting; its only inputs are the function parameters.

## Analytics

Not applicable: the source contains no analytics or event-tracking call.

## Privacy

- **Data collected**: None. The command and the entry name a local executable path and a loopback URL; no credential is in either.
- **Storage**: This component stores nothing. Running the returned command makes Claude Code store the entry in its own configuration file (the file `isRegistered` reads); that storage is outside this source.
- **Transmission**: The command is returned as text; whatever shows or copies it decides where it goes. `isRegistered` reads one local file and sends nothing.
- **Retention**: Not defined here. The bearer token lives with adhd, which hands it to Claude Code through the helper on each connection.
- **Token never written**: Because the entry names a helper rather than a token, a shell history, a clipboard or `~/.claude.json` never holds the token, and a token adhd rotates needs no new registration.
## Logging

Not applicable: the source makes no logging call.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPRegistration.swift`, built into the macOS framework target, importing `AgenticDeveloperHubSDKCore` for `PartnerStepTemplate.shellQuoted`. It is a caseless `public enum` of statics, with no UI. A SwiftUI view reads `claudeCommand` into a `Text` or a copy button and `isRegistered` into a status line (`AutomationServerStatus` publishes both); the file read is synchronous, so call it off the main thread if the config file can be slow.
- **Compose**: Port `MCPRegistration` as a Kotlin `object` with an `enum class Channel` and pure functions. Build the entry with `kotlinx.serialization.json.buildJsonObject` and parse the config with `Json.parseToJsonElement`, mapping every failure to `false` with a `runCatching`. An Android app has no `~/.claude.json` to read.
- **React/Web**: A browser cannot read `~/.claude.json`, so only `claudeCommand` ports there, as a pure function over `JSON.stringify` of a key-sorted object. In a Node.js or Electron host, `isRegistered` is `JSON.parse(fs.readFileSync(path, "utf8"))` inside a `try`, then an equality check on `mcpServers[name].url`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the component has no UI; only the surface that displays the command or status differs (an `NSTextField` plus an `NSPasteboard` copy button in AppKit).
- **WinUI 3**: Implement as a `static class McpRegistration` with a nested `enum Channel`, `EntryJson` built with `System.Text.Json.JsonSerializer` over a `SortedDictionary`, and `IsRegistered` using `JsonDocument.Parse(File.ReadAllBytes(...))` with `TryGetProperty` and a `string.Equals` check, wrapped in a `try`/`catch` that returns `false`. The single-quoted command targets POSIX shells; a Windows presentation needs a PowerShell form.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPRegistration.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The entry names a `headersHelper` that runs `adhd mcp headers` instead of a baked-in token.
**Rationale**: No token is then ever written into `~/.claude.json`, a shell history or a pane's environment, and adhd can rotate it without the user registering again.
**Approved**: pending

**Decision**: Each channel has its own server name and fixed port (`adhd-dev` on 22871, `adhd` on 22850).
**Rationale**: A dev build never takes over the release entry, and with a fixed port the registration never goes stale, so the environment-default URL form the Kitchen used is no longer needed.
**Approved**: pending

**Decision**: `isRegistered` compares the `url` for equality.
**Rationale**: The port is fixed per channel, so equality is exact where the old substring test, needed for the `${ADKITCHEN_MCP_URL:-…}` form, matched longer URLs too.
**Approved**: pending

**Decision**: Every failure of `isRegistered` (missing file, bad JSON, wrong shape) is reported as false with no reason.
**Rationale**: The caller's only use is a "Registered" or "Not registered" status line (`AutomationServerStatus`), for which a missing or unreadable file correctly means "not registered".
**Approved**: pending

**Decision**: The URL is fixed as `http://127.0.0.1`.
**Rationale**: The endpoint binds only the loopback address and speaks plain HTTP guarded by a bearer token, so the registered URL cannot name any other host.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |

`separation-of-concerns` passes because command construction and config inspection live in one small stateless type that leaves the token, the endpoint and the UI to other types. `unit-test-coverage` is partial: `MCPRegistrationTests` covers both channels, the command text, path quoting and four `isRegistered` cases, but no test covers an entry with no `url`. `explicit-error-handling` is partial because `isRegistered` collapses every failure into false with no signal, a deliberate lossy projection recorded under Design Decisions. `input-sanitization` passes: the only free input, the adhd path, is shell-quoted inside the helper, and the entry is shell-quoted again in the command, and no token is interpolated at all.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-23 | Mike Fullerton | Apps suite Phase 4: per-channel adhd entries (adhd-dev on 22871, adhd on 22850) in the headersHelper form; no token in the command; isRegistered(claudeConfig:channel:) checks URL equality. |
