---
id: ed460f60-2a13-4a3c-b7eb-53c531bf0741
title: "MCP Registration"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Builds the one-time claude mcp add command that registers the local MCP endpoint with Claude Code, and checks the Claude config to see whether it is registered."
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

MCP Registration is how a Claude Code install learns about the host app's local MCP endpoint. It is a stateless namespace with two operations. The first builds the text of a single `claude mcp add` command that the user runs once. The second reads Claude Code's configuration file and reports whether a server named `adkitchen` is already registered against a given port. It performs no process execution, no network access and no writes.

The command writes the endpoint URL, the bearer token and the caller-pane header as shell-style defaults (`${NAME:-default}`) rather than as bare values. A shell running inside the app, where those variables are set, therefore wins over the values baked in at registration time. The endpoint it registers is served by the MCP HTTP endpoint ingredient (ai/mcp/mcphttp-endpoint); the sibling [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56) covers the client side of MCP.

The source is one file, `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPRegistration.swift`, a public `enum MCPRegistration` with no cases, one constant and two static functions.

## Behavioral Requirements

The server name

- **server-name**: `MCPRegistration.serverName` MUST be the string `adkitchen`.

Building the command: `claudeCommand(port:token:)`

- **command-is-text-only**: `claudeCommand` MUST return the command as a string and MUST NOT execute it, read any file, or touch the network.
- **command-prefix**: The command MUST begin with `claude mcp add --transport http --scope user adkitchen ` (the server name followed by one space).
- **command-url-argument**: The command's URL argument MUST be a single-quoted string of the form `${ADKITCHEN_MCP_URL:-http://127.0.0.1:<port>/mcp}`, where `<port>` is the decimal value of the `port` parameter and the path is the endpoint's path constant, `MCPHTTPEndpoint.path` (`/mcp`).
- **command-url-host**: The default URL MUST name the loopback address `127.0.0.1` and the scheme `http`.
- **command-authorization-header**: The command MUST carry the header `--header 'Authorization: Bearer ${ADKITCHEN_MCP_TOKEN:-<token>}'`, where `<token>` is the `token` parameter inserted as given.
- **command-pane-header**: The command MUST carry the header `--header 'X-ADKitchen-Pane: ${ADKITCHEN_PANE_ID:-}'`, whose header name is the endpoint server's caller-header constant (`HostMCPServer.callerHeader`) and whose default value is empty.
- **command-header-order**: The command's two headers MUST appear after the URL argument, the Authorization header first and the pane header last.
- **command-defaults-let-the-environment-win**: Each of the three values (URL, token, pane id) MUST be written as `${VARIABLE:-default}` so that, where Claude Code resolves the variable to a non-empty value, that value takes precedence over the value baked in at registration time. The expansion itself is performed by Claude Code when it reads its configuration, which is outside this source.
- **command-single-quoted**: The URL argument and each header argument MUST be wrapped in single quotes, so a shell run by the user does not expand the `${...}` forms before Claude Code stores them.
- **command-token-not-escaped**: NEEDS REVIEW: Not implemented in source. `claudeCommand` inserts `token` (and the decimal `port`) into a single-quoted shell string with no quoting or validation, so a token containing a single quote would end the quoted string early. The shipped token source, `MCPBearerToken.generate()`, yields 64 hex characters, but `MCPBearerToken.load(from:)` returns whatever non-empty text its file holds, and nothing in `MCPRegistration` or its signature restricts the character set. A decision from the owner of the token contract (reject, escape, or document a hex-only precondition) would settle it.

Checking registration: `isRegistered(claudeConfig:port:)`

- **registered-reads-config-file**: `isRegistered` MUST read the file at `claudeConfig` (normally `~/.claude.json`) and MUST NOT modify it.
- **registered-needs-server-entry**: `isRegistered` MUST return true only when the file's top level is a JSON object whose `mcpServers` value is an object containing a key equal to `serverName` whose value is itself an object.
- **registered-needs-url-string**: `isRegistered` MUST return false when the `adkitchen` entry has no `url` key or its `url` value is not a string.
- **registered-port-match**: `isRegistered` MUST return true when the entry's `url` string contains the substring `127.0.0.1:<port><path>` (for example `127.0.0.1:51477/mcp`), whether the URL is the literal URL or the `${ADKITCHEN_MCP_URL:-...}` default form written by `claudeCommand`.
- **registered-port-mismatch**: `isRegistered` MUST return false when the entry's `url` names a different port.
- **registered-ignores-token-and-headers**: `isRegistered` MUST NOT consider the entry's `type`, headers or token; only its `url` decides the answer.
- **registered-failure-is-false**: `isRegistered` MUST return false, without throwing, when the file is missing, unreadable, not valid JSON, or not a JSON object. It reports all of these as plain "not registered", with no signal that distinguishes them.

Concurrency and side effects

- **stateless**: `MCPRegistration` MUST hold no state; both functions are pure apart from `isRegistered`'s synchronous file read, so they MAY be called from any thread concurrently.

## Appearance

Not applicable — this is a command builder and a config-file reader, not a visual component.

## States

Not applicable — this is a command builder and a config-file reader, not a visual component; it has no runtime state, so there is no state machine to record either.

## Accessibility

Not applicable — this is a command builder and a config-file reader with no user interface of its own.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mcp-registration-001 | server-name, command-prefix, command-url-argument, command-authorization-header, command-pane-header, command-header-order, command-single-quoted | `claudeCommand(port: 51477, token: "abc")` | Exactly `claude mcp add --transport http --scope user adkitchen '${ADKITCHEN_MCP_URL:-http://127.0.0.1:51477/mcp}' --header 'Authorization: Bearer ${ADKITCHEN_MCP_TOKEN:-abc}' --header 'X-ADKitchen-Pane: ${ADKITCHEN_PANE_ID:-}'` (`MCPRegistrationTests.testClaudeCommandNamesTheServerTheURLTheTokenAndThePaneHeader`) |
| mcp-registration-002 | registered-reads-config-file, registered-needs-server-entry, registered-port-match | A config file `{"mcpServers":{"adkitchen":{"type":"http","url":"http://127.0.0.1:51477/mcp"}}}` and port 51477 | `isRegistered` returns true (`MCPRegistrationTests.testRegisteredWhenTheServerPointsAtThisPort`) |
| mcp-registration-003 | registered-port-match | A config file whose `url` is `${ADKITCHEN_MCP_URL:-http://127.0.0.1:51477/mcp}` and port 51477 | `isRegistered` returns true (`MCPRegistrationTests.testRegisteredWhenTheURLIsTheEnvironmentForm`) |
| mcp-registration-004 | registered-needs-server-entry | A config file whose only `mcpServers` key is `other`, pointing at `http://127.0.0.1:51477/mcp`, and port 51477 | `isRegistered` returns false (`MCPRegistrationTests.testNotRegisteredWhenTheServerIsMissing`) |
| mcp-registration-005 | registered-port-mismatch | A config file whose `adkitchen` url is `http://127.0.0.1:51000/mcp` and port 51477 | `isRegistered` returns false (`MCPRegistrationTests.testNotRegisteredWhenThePortDiffers`) |
| mcp-registration-006 | registered-failure-is-false | `claudeConfig` is `/nonexistent/.claude.json`, then a file containing `not json` | `isRegistered` returns false in both cases, with no thrown error (`MCPRegistrationTests.testNotRegisteredWhenTheFileIsMissingOrNotJSON`) |
| mcp-registration-007 | registered-needs-url-string | A config file `{"mcpServers":{"adkitchen":{"type":"http"}}}` and port 51477 | `isRegistered` returns false because the entry has no `url` (derived from the `guard` on the `url` string; no test) |
| mcp-registration-008 | registered-needs-server-entry, registered-failure-is-false | A config file `[]` (valid JSON, not an object), then `{"mcpServers":[]}` | `isRegistered` returns false in both cases (derived from the object casts; no test) |
| mcp-registration-009 | registered-ignores-token-and-headers | A config file whose `adkitchen` entry has the right `url` and a `headers` object naming a different token | `isRegistered` returns true (derived from the single `url` check; no test) |
| mcp-registration-010 | command-defaults-let-the-environment-win | `claudeCommand(port: 1, token: "")` | The Authorization argument ends `${ADKITCHEN_MCP_TOKEN:-}'` and the URL default is `http://127.0.0.1:1/mcp` (derived from string interpolation; no test) |
| mcp-registration-011 | command-token-not-escaped | `claudeCommand(port: 51477, token: "a'b")` | The returned text contains `${ADKITCHEN_MCP_TOKEN:-a'b}` verbatim, with the single quote unescaped (derived from the source; the open question on `command-token-not-escaped` decides whether this should change) |

## Edge Cases

- **Null and empty input**: An empty `token` MUST produce `${ADKITCHEN_MCP_TOKEN:-}`, a valid but credential-less default (MUST; nothing rejects it). An empty config file or a file with no `mcpServers` key MUST yield false (MUST).
- **Boundary values**: `port` is a `UInt16`, so the command's URL carries any value from 0 to 65535 as a plain decimal; port 0 produces `127.0.0.1:0/mcp` with no validation (MUST, per the type and the unvalidated interpolation). Because the match string begins `127.0.0.1:` and ends with the path, a registered port of 51477 does not match a query for port 1477, and a registered port of 1477 does not match a query for 51477 (MUST).
- **Substring match leniency**: The check is a substring test, so a URL such as `http://127.0.0.1:51477/mcp/extra` or one with a longer host ending in `127.0.0.1` also counts as registered (a consequence of `registered-port-match`; the source documents the match as "names `port`").
- **Concurrent access**: Both functions are free of shared state. `isRegistered` reads the file once, synchronously; if Claude Code rewrites `~/.claude.json` mid-read and the read sees partial JSON, the call reports false (MUST, per `registered-failure-is-false`). Not an ordering concern otherwise: nothing is serialised because nothing is shared.
- **Error states**: A missing, unreadable or malformed config file is reported as false; the source swallows the underlying error (`try?`) and returns no reason, so a caller cannot tell "never registered" from "config unreadable" (MUST, per `registered-failure-is-false`).
- **Offline or disconnected state**: Not applicable — neither function uses the network; the only I/O is one local file read.
- **Cancellation, timeouts**: Not applicable — both functions are synchronous and run to completion.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `port` (parameter to `claudeCommand` and `isRegistered`) | `UInt16` | none — required | The port the endpoint is listening on; baked into the URL default, or matched against the registered URL. |
| `token` (parameter to `claudeCommand`) | `String` | none — required | The bearer token baked in as the default of `ADKITCHEN_MCP_TOKEN`. |
| `claudeConfig` (parameter to `isRegistered`) | `URL` | none — required | The Claude Code configuration file to read; the doc comment says "normally `~/.claude.json`". |
| `serverName` | `String` constant | `adkitchen` | The server name used in the command and as the key looked up under `mcpServers`. |
| `MCPHTTPEndpoint.path` | `String` constant (owned by the endpoint) | `/mcp` | The URL path of the registered endpoint. |
| `HostMCPServer.callerHeader` | `String` constant (owned by the endpoint's server) | `X-ADKitchen-Pane` | The name of the caller-pane header. |
| `ADKITCHEN_MCP_URL`, `ADKITCHEN_MCP_TOKEN`, `ADKITCHEN_PANE_ID` | environment variables named in the command | unset — the baked-in defaults apply | Read by Claude Code, not by this component; the source says a shell inside the app is where they are set. |

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

- **Data collected**: The bearer token, a credential that authorises calls to the local endpoint, is embedded in the command text `claudeCommand` returns.
- **Storage**: This component stores nothing. Running the returned command makes Claude Code store the token default inside its own configuration file (the file `isRegistered` reads); that storage is outside this source.
- **Transmission**: The command is returned as text; whatever shows or copies it (the caller) decides where it goes. `isRegistered` reads one local file and sends nothing.
- **Retention**: Not defined here. The token has no expiry or rotation in this component; its lifecycle belongs to the token's owner, `MCPBearerToken`.
- **Token in the command line**: The token appears in cleartext in the command string, so a shell's history or a clipboard may retain it. The source does not mask it.

## Logging

Not applicable: the source makes no logging call.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPRegistration.swift`, built into the macOS framework target, importing `AgenticDeveloperHubSDKCore` for `HostMCPServer`. It is a caseless `public enum` of statics, with no UI. A SwiftUI view reads `claudeCommand` into a `Text` or a copy button and `isRegistered` into a status line (`AutomationServerStatus` publishes the result); the file read is synchronous, so call it off the main thread if the config file can be slow.
- **Compose**: Port `MCPRegistration` as a Kotlin `object` with two pure functions. Build the string with a template and parse the config with `org.json.JSONObject` or `kotlinx.serialization.json.Json.parseToJsonElement`, mapping every failure to `false` with a `runCatching`. The config file lives under the user's home directory on desktop targets; an Android app has no `~/.claude.json` to read.
- **React/Web**: A browser cannot read `~/.claude.json`, so only `claudeCommand` ports there, as a pure function returning a template string. In a Node.js or Electron host, `isRegistered` is `JSON.parse(fs.readFileSync(path, "utf8"))` inside a `try`, followed by property checks and `String.prototype.includes`; a thrown error becomes `false`.
- **AppKit / UIKit**: Identical to the SwiftUI note — the component has no UI; only the surface that displays the command or status differs (an `NSTextField` plus an `NSPasteboard` copy button in AppKit).
- **WinUI 3**: Implement as a `static class McpRegistration` with a `const string ServerName = "adkitchen"`, `ClaudeCommand(ushort port, string token)` using a C# interpolated string, and `IsRegistered(string claudeConfigPath, ushort port)` using `System.Text.Json.JsonDocument.Parse(File.ReadAllBytes(...))` with `TryGetProperty("mcpServers", ...)`, `TryGetProperty("adkitchen", ...)` and `TryGetProperty("url", ...)` and a `string.Contains` check, wrapped in a `try`/`catch (JsonException)` and `IOException` that return `false`. Resolve the config path with `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)` joined to `.claude.json`. The single-quoted command targets POSIX shells: `cmd.exe` does not treat single quotes as quoting, so a Windows presentation needs a PowerShell or double-quote form, and the `${NAME:-default}` text is expanded by Claude Code, not by the shell, so it can stay as written. Show the command in a read-only `TextBox` with `IsReadOnly="True"` and a `Button` that calls `Clipboard.SetContent(DataPackage)`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPRegistration.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The URL, token and pane id are written as `${VARIABLE:-default}` shell-style defaults instead of fixed values.
**Rationale**: The type's doc comment says this lets a shell inside the app, where the variables are set, win over the values baked in at registration time, so one registration keeps working when the port, token or pane changes inside the app.
**Approved**: pending

**Decision**: `isRegistered` matches the port with a substring test and accepts both the literal URL and the `${ADKITCHEN_MCP_URL:-...}` form.
**Rationale**: The doc comment says the check must succeed "literally, or as the `${ADKITCHEN_MCP_URL:-…}` default the command above writes", so a substring test covers both with one comparison; the cost is the leniency listed under Edge Cases.
**Approved**: pending

**Decision**: Every failure of `isRegistered` (missing file, bad JSON, wrong shape) is reported as false with no reason.
**Rationale**: The caller's only use is a "Registered" or "Not registered" status line (`AutomationServerStatus`), for which a missing or unreadable file correctly means "not registered".
**Approved**: pending

**Decision**: The command is built with the loopback host fixed as `127.0.0.1` and plain `http`.
**Rationale**: The endpoint it targets binds only the loopback address and speaks plain HTTP guarded by a bearer token, so the registered URL cannot name any other host.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because command construction and config inspection live in one small stateless type that leaves token generation, the endpoint and the UI to other types. `unit-test-coverage` is partial: `MCPRegistrationTests` covers the command text and five `isRegistered` cases, but no test covers an entry with no `url`, a non-object `mcpServers`, or a token with a quote in it. `explicit-error-handling` is partial because `isRegistered` collapses every failure into false with no signal, a deliberate lossy projection recorded under Design Decisions. `input-sanitization` is partial because `claudeCommand` interpolates the token and port into a quoted shell string unescaped; see the open question on `command-token-not-escaped`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
