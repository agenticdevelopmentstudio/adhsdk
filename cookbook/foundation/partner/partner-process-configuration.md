---
id: c77c4cfb-e9be-4339-b40d-3f7abc6a4543
title: "Partner Process Configuration"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Launch configuration for the partner's claude process and the exact argument list it produces."
platforms:
  - swift
  - macos
tags:
  - foundation
  - partner
  - process
  - claude-cli
depends-on: []
related:
  - d2213cbb-1a6e-452e-98f0-acd2007c8430
references: []
approved-by: ""
approved-date: ""
---

# Partner Process Configuration

## Overview

`PartnerProcessConfiguration` is a value type describing how the partner's long-running `claude` process is launched. It holds the executable, the session ID, whether to resume it, the model, the permission mode, the allowed tools, the MCP config path, the system prompt path and the working directory, and exposes `arguments`, the exact argument list handed to the process.

## Behavioral Requirements

- **value-semantics**: `PartnerProcessConfiguration` MUST be a `Sendable` and `Equatable` struct with the settable fields `executable`, `sessionID` (a UUID), `resume`, `model`, `permissionMode`, `allowedTools` (strings), `mcpConfigPath`, `systemPromptPath` and `workingDirectory`, all set by its initializer.
- **fixed-prefix**: `arguments` MUST begin with `-p`, `--verbose`, `--input-format`, `stream-json`, `--output-format`, `stream-json`, `--replay-user-messages`, in that order.
- **session-flag**: After the fixed prefix, `arguments` MUST contain `--session-id` when `resume` is false and `--resume` when `resume` is true, never both and never neither, followed by the session ID.
- **session-id-lowercase**: The session ID in `arguments` MUST be the UUID string in lowercase.
- **permission-mode**: `arguments` MUST contain `--permission-mode` followed by `permissionMode` unchanged and unconditionally, including when it is empty.
- **mcp-config**: `arguments` MUST contain `--mcp-config` followed by `mcpConfigPath`, then `--strict-mcp-config`.
- **system-prompt**: `arguments` MUST contain `--append-system-prompt-file` followed by `systemPromptPath`.
- **optional-model**: `arguments` MUST add `--model` followed by `model` only when `model` is not empty; an empty `model` MUST add neither element.
- **optional-tools**: `arguments` MUST add `--allowedTools` followed by each entry of `allowedTools` as its own element only when `allowedTools` is not empty; an empty list MUST add neither.
- **order**: The required groups MUST appear in this order after the session flag and ID: `--permission-mode` and its value, `--mcp-config` and its value, `--strict-mcp-config`, then `--append-system-prompt-file` and its value. The optional arguments MUST come after the required ones, the model option before the tools option.
- **pure-computation**: `arguments` MUST be computed from the stored fields alone; it MUST NOT touch the file system, check that the executable or paths exist, or validate any value.
- **working-directory-not-an-argument**: `workingDirectory` MUST NOT appear in `arguments`; it is the child's current directory, which `PartnerProcess` applies when it launches.

## Appearance

Not applicable — this is a value type that builds a command line, not a visual component.

## States

Not applicable — this is a value type that builds a command line, not a visual component.

## Accessibility

Not applicable — this is a value type that builds a command line, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-process-configuration-001 | session-flag, optional-model | Configuration with `resume` false and `model` empty; read `arguments`. | Contains `--session-id`, does not contain `--resume`, does not contain `--model` (test: argumentsForFirstStartAndResume). |
| partner-process-configuration-002 | session-flag, optional-model | The same configuration with `resume` true and `model` `opus`. | Contains `--resume` and `--model` (test: argumentsForFirstStartAndResume). |
| partner-process-configuration-003 | mcp-config, fixed-prefix | Read `arguments` of a configuration. | Contains `--strict-mcp-config` and `--replay-user-messages` (test: argumentsForFirstStartAndResume). |
| partner-process-configuration-004 | order, session-id-lowercase, optional-tools | `executable` `/x/claude`, a session ID, `resume` true, `model` `opus`, `permissionMode` `dontAsk`, tools `a` and `b`, `mcpConfigPath` `/m.json`, `systemPromptPath` `/p.md`. | `arguments` equals exactly: `-p`, `--verbose`, `--input-format`, `stream-json`, `--output-format`, `stream-json`, `--replay-user-messages`, `--resume`, the lowercase session ID, `--permission-mode`, `dontAsk`, `--mcp-config`, `/m.json`, `--strict-mcp-config`, `--append-system-prompt-file`, `/p.md`, `--model`, `opus`, `--allowedTools`, `a`, `b` (test: argumentsAreExactlyOrdered). |
| partner-process-configuration-005 | optional-tools, optional-model | `allowedTools` empty, `model` `opus`. | `arguments` has `--model` and `opus` and no `--allowedTools`. |
| partner-process-configuration-006 | permission-mode | `permissionMode` empty. | `--permission-mode` is followed by an empty string element. |
| partner-process-configuration-007 | working-directory-not-an-argument | `workingDirectory` `/work-sentinel`, with `mcpConfigPath` `/mcp-sentinel`, `systemPromptPath` `/prompt-sentinel` and `executable` `/exe-sentinel`. | No element of `arguments` equals `/work-sentinel` or `/exe-sentinel`; `/mcp-sentinel` and `/prompt-sentinel` each appear exactly once. |
| partner-process-configuration-008 | fixed-prefix | Any configuration. | `arguments` contains `--verbose` immediately after `-p`. |
| partner-process-configuration-009 | session-flag | `resume` false, then `resume` true, same session ID. | Each `arguments` has exactly one of `--session-id` and `--resume`, counted once, and never the other; the next element is the lowercase session ID. |

## Edge Cases

- **Null / empty input**: An empty `model` and an empty `allowedTools` each drop their option (MUST). An empty `permissionMode`, `mcpConfigPath`, `systemPromptPath` or `executable` is passed through as an empty element or path; nothing rejects it (MUST NOT validate).
- **Boundary values**: `allowedTools` of one entry gives one element after `--allowedTools`; every entry is a separate argument, so an entry containing spaces stays one element.
- **Odd tool entries**: An `allowedTools` entry that is empty, or starts with `-` or `--`, is passed through unchanged as its own element, like every other value (MUST NOT validate); the type does not guard against the CLI reading it as a flag.
- **Concurrent access**: The type is a `Sendable` value; a copy can be read from any thread or actor.
- **Error states**: `arguments` cannot fail; a configuration naming a missing executable or file is only discovered when the process is launched, which is `PartnerProcess`'s concern.
- **Offline / disconnected state**: Not applicable: the type performs no network or file access.
- **Cancellation**: Not applicable: `arguments` is a synchronous computation.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `executable` | String | none, required | Path to the `claude` executable. |
| `sessionID` | UUID | none, required | The conversation session; written lowercase. |
| `resume` | Bool | none, required | True resumes the session; false starts it under that ID. |
| `model` | String | none, required; empty omits the option | Model name passed to `--model`. |
| `permissionMode` | String | none, required | Passed to `--permission-mode`; the tests use `dontAsk`. |
| `allowedTools` | [String] | none, required; empty omits the option | Tool names passed after `--allowedTools`. |
| `mcpConfigPath` | String | none, required | The MCP config file; only this config is used because of `--strict-mcp-config`. |
| `systemPromptPath` | String | none, required | File appended to the system prompt. |
| `workingDirectory` | String | none, required | The child's current directory; not part of `arguments`. |

## Deep Linking

Not applicable: it defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the source contains no user-facing string literal; every string is a command-line flag.

## Accessibility Options

Not applicable: it presents no UI, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Paths, a session ID, a model name and tool names a caller passes in; no credential is held (the MCP token lives in the file at `mcpConfigPath`).
- **Storage**: None; it persists nothing.
- **Transmission**: None leaves the machine; the values are passed on the command line of a local process, so the session ID and file paths are visible to other processes on the machine (for example through `ps`).
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: the source calls no logging API.

## Platform Notes

- **SwiftUI**: Source is `Core/Partner/PartnerProcessConfiguration.swift`, a `public struct` importing only `Foundation`; nothing is UI-specific. Tests are in `PartnerProcessConfigurationTests`.
- **Compose**: A Kotlin data class with a computed `arguments` property returning `List<String>` built with `buildList`; `java.util.UUID.toString()` is already lowercase.
- **React/Web**: A plain object and a function returning `string[]`; a browser cannot launch a process, so this is Node only, and a UUID string is lowercased with `toLowerCase()`.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic.
- **WinUI 3**: A C# `record` with a computed `IReadOnlyList<string> Arguments` built into a `List<string>`; `Guid.ToString()` is lowercase by default (the `D` format). Hand the list to `ProcessStartInfo.ArgumentList` rather than joining it into `ProcessStartInfo.Arguments`, so entries with spaces stay single arguments; `ProcessStartInfo.WorkingDirectory` takes `workingDirectory`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerProcessConfiguration.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Required options come first and optional ones last, in the order model then tools.
**Rationale**: `--allowedTools` takes a variable number of values, so it goes last and nothing after it is read as a tool name; the exact-order test pins the order.
**Approved**: pending

**Decision**: `--strict-mcp-config` is always set together with `--mcp-config`.
**Rationale**: The partner then sees only the MCP server the app configured, not any the user has set up elsewhere.
**Approved**: pending

**Decision**: `--verbose` is always set.
**Rationale**: The source comment states that `-p` with stream-json output requires it, so the fixed prefix always carries `--verbose` in second place.
**Approved**: pending

**Decision**: `permissionMode` and `model` are free strings, and an empty `permissionMode` is passed through as `--permission-mode` followed by an empty element.
**Rationale**: The type only builds the argument list and must not validate (see pure-computation); which modes and model names the CLI accepts is the CLI's concern, so an empty mode is left for the CLI to reject when the process launches.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the type only describes a launch and builds the argument list; spawning the process belongs to `PartnerProcess` and the channel beneath it. `unit-test-coverage` passes: `PartnerProcessConfigurationTests` covers all nine vectors (001-004 by its existing tests, 005-009 by the `V5`-`V9` tests added in `Tests/AgenticDeveloperHubSDKCoreTests/Partner/PartnerProcessConfigurationTests.swift`).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerProcessConfigurationTests.swift, 9 of 9 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Marked test coverage partial, pinned the required argument order, added odd-tool and empty-permission-mode decisions, new vectors, an argv privacy note, a PartnerProcess link and a shorter summary. |
