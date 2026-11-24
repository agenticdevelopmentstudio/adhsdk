---
id: 456bc5f5-b955-4844-906d-007506405d3d
title: "Automation Server Status"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Observable main-actor model of the MCP automation endpoint: port, bearer token, registration flag, failure reason, endpoint URL and a one-sentence status line."
platforms:
  - swift
  - macos
tags:
  - mcp
  - automation
  - status-model
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Automation Server Status

## Overview

`AutomationServerStatus` is an `ObservableObject` that holds what the Automation settings panel shows about the host's MCP endpoint. Its doc comment gives the division of labor: it is "filled by the host's automation feature when it starts, read by the panel." The host writes four published values (`port`, `token`, `isRegistered`, `failureReason`); the model derives the endpoint `url` and a one-sentence status `line` from them. It starts and stops nothing, performs no registration, and owns no I/O.

## Behavioral Requirements

- **main-actor-isolation**: The type MUST be `@MainActor`, so every property read and write, and the `url` and `line` accessors, run on the main actor. The static `line(port:isRegistered:failureReason:)` is a pure function of its arguments and is not tied to an instance.
- **observable-object**: The type MUST be an `ObservableObject` whose four stored values are `@Published`, so a view can observe changes.
- **initial-values**: A new instance MUST have `port` nil, `token` nil, `isRegistered` false and `failureReason` nil. `init()` takes no arguments.
- **port-meaning**: `port` MUST hold the port actually listening as a `UInt16`, nil until the endpoint starts or when it failed. The model does not set or clear it; the host does.
- **token-meaning**: `token` MUST hold the bearer token for the registration command, or nil. The model does not generate, store or redact it.
- **registered-meaning**: `isRegistered` MUST mean whether `~/.claude.json` lists this server on this port. The model does not read that file; the host sets the flag.
- **failure-reason-meaning**: `failureReason` MUST hold why the endpoint is not running, when it is not, or nil. The model does not clear it when `port` changes.
- **url-nil-without-port**: `url` MUST be nil when `port` is nil.
- **url-format**: When `port` is set, `url` MUST be `http://127.0.0.1:<port><MCPHTTPEndpoint.path>`, where `MCPHTTPEndpoint.path` is `/mcp`, so a port of 51477 gives `http://127.0.0.1:51477/mcp`.
- **url-ignores-failure**: `url` MUST depend on `port` alone; a set `failureReason` MUST NOT hide it.
- **line-failure-first**: The status sentence MUST be `Not running: <failureReason>` whenever `failureReason` is non-nil, regardless of `port` and `isRegistered`.
- **line-starting**: With `failureReason` nil and `port` nil, the sentence MUST be `Starting.`
- **line-listening-registered**: With `failureReason` nil and `port` set, the sentence MUST be `Listening on port <port>. Registered with Claude Code.` when `isRegistered` is true.
- **line-listening-unregistered**: With `failureReason` nil and `port` set, the sentence MUST be `Listening on port <port>. Not registered with Claude Code.` when `isRegistered` is false.
- **line-port-unformatted**: The port in the sentence MUST be printed as a plain integer with no grouping separator.
- **line-instance-delegates-to-static**: The instance `line` MUST return `AutomationServerStatus.line(port:isRegistered:failureReason:)` for its current values.
- **line-static-for-publisher-values**: The static `line(port:isRegistered:failureReason:)` MUST be callable with explicit values. The reason is the source's comment: the panel renders from the value a `@Published` property publishes, which "arrive before the property itself changes", so the sentence cannot be read back off `self` there.
- **no-io**: The component MUST NOT read or write files, open a network connection, spawn a process or post a notification.
- **no-validation**: The component MUST NOT validate its values: it accepts any `UInt16` port including 0, any string token or reason, and any combination of the four values.

## Appearance

Not applicable — this is an observable status model for a settings panel, not a visual component. The panel that renders `line` is `AutomationEndpointPanel` (in `AutomationSettingsPanelViewController.swift`), a separate type.

## States

Not applicable — this is an observable status model, not a visual component. Its runtime states (starting, listening, failed) are derived from the values and appear in the status sentence, specified under Behavioral Requirements. The model has no state machine of its own and enforces no transitions.

## Accessibility

Not applicable — this is an observable status model, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| automation-status-001 | initial-values, line-starting | `AutomationServerStatus()` | `port` nil, `token` nil, `isRegistered` false, `failureReason` nil, `line` is `Starting.`, `url` nil |
| automation-status-002 | line-listening-unregistered, line-port-unformatted | `port = 51477`, `isRegistered = false` | `line` is `Listening on port 51477. Not registered with Claude Code.` (`AutomationSettingsPanelTests.testStatusLineNamesThePortAndRegistration`) |
| automation-status-003 | line-listening-registered | Same instance, then `isRegistered = true` | `line` is `Listening on port 51477. Registered with Claude Code.` (same test) |
| automation-status-004 | line-failure-first | `failureReason = "could not write /x/mcp-token: Permission denied"` with `port` nil | `line` is `Not running: could not write /x/mcp-token: Permission denied` (`AutomationSettingsPanelTests.testFailureReasonIsTheStatusLine`) |
| automation-status-005 | line-failure-first | `port = 51477`, `isRegistered = true`, `failureReason = "x"` | `line` is `Not running: x` |
| automation-status-006 | url-format | `port = 51477` | `url` is `http://127.0.0.1:51477/mcp` |
| automation-status-007 | url-nil-without-port | `port = nil` | `url` is nil |
| automation-status-008 | line-static-for-publisher-values | `AutomationServerStatus.line(port: 8080, isRegistered: true, failureReason: nil)` | `Listening on port 8080. Registered with Claude Code.` |
| automation-status-009 | url-ignores-failure | `port = 51477`, `failureReason = "x"` | `url` is `http://127.0.0.1:51477/mcp` while `line` is `Not running: x` |
| automation-status-010 | no-validation, line-port-unformatted | `AutomationServerStatus.line(port: 0, isRegistered: false, failureReason: nil)` | `Listening on port 0. Not registered with Claude Code.` |
| automation-status-011 | observable-object | Subscribe to `objectWillChange`, then set `port = 1` | One change notification is received before the property reads back as 1 |

## Edge Cases

- **Nil values**: With every value nil or false the model reports `Starting.` and a nil `url`. MUST.
- **Boundary ports**: `UInt16` bounds the port to 0 through 65535. Port 0 is accepted and reported as listening on port 0, and 65535 formats as `65535`. MUST.
- **Failure with a port set**: A non-nil `failureReason` wins over a set `port` in `line` but not in `url`, so a stale port can leave `line` reporting failure while `url` still returns a URL. The host is responsible for clearing the port on failure. MUST.
- **Empty failure reason**: An empty string is still non-nil, so `line` is `Not running: ` with nothing after the colon-space. MUST.
- **Token handling**: A nil token is valid, and a token is never included in `line` or `url`. MUST.
- **Concurrent access**: The type is `@MainActor`, so the compiler keeps all access on the main actor; callers off the main actor must hop to it, and the static `line` function needs no isolation. MUST.
- **Value ordering**: `@Published` publishes the new value before the property changes, so an observer reading `self.line` inside the sink sees the old values; it must call the static `line` with the published value. MUST.
- **Error states, offline state and timeouts**: Not applicable — the component performs no I/O; failures are recorded by the host in `failureReason`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `port` | `UInt16?` | `nil` | Port the endpoint is listening on. |
| `token` | `String?` | `nil` | Bearer token for the registration command. |
| `isRegistered` | `Bool` | `false` | Whether `~/.claude.json` lists this server on this port. |
| `failureReason` | `String?` | `nil` | Why the endpoint is not running. |

The component defines no environment variable and no settings key. It reads `MCPHTTPEndpoint.path` (`/mcp`) to build `url`, and is injected into the Automation settings panel and `PartnerCoordinator`.

## Deep Linking

Not applicable: the component defines no URL scheme or navigation route. The `url` it exposes is the loopback address of the MCP endpoint, not an app deep link.

## Localization

- **hardcoded-status-sentences**: The strings `Not running: `, `Starting.`, `Listening on port `, `Registered`, `Not registered` and ` with Claude Code.` are hardcoded English literals with no localization mechanism, and they are shown to the user in the settings panel. MUST (stated as an observed fact). The `failureReason` text is supplied by the host and embedded as given.

## Accessibility Options

Not applicable: the component presents no UI, so it responds to no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: the component contains no feature-flag or settings-key reference.

## Analytics

Not applicable: the component contains no analytics or event-tracking call.

## Privacy

- **Data collected**: The model holds a bearer token for the MCP endpoint, a credential that lets a caller use the host's automation tools, plus a port and a free-text failure reason that may include a file path.
- **Storage**: In memory only, as a `@Published` `String?`. The model does not write the token to disk, Keychain or logs; where the token is persisted is up to the host feature that fills it.
- **Transmission**: None by the component. The token is made available to the registration command (see `MCPRegistration.claudeCommand(port:token:)`, which the panel copies to the pasteboard), and `url` is a `127.0.0.1` loopback URL.
- **Retention**: The token lives as long as the instance and is not cleared by the model. `line` and `url` never include the token, but the token property is readable by anything holding the instance.

## Logging

Not applicable: the component contains no logging call.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/AutomationServerStatus.swift`. It is already an `ObservableObject`, so a SwiftUI view holds it as `@ObservedObject` or `@StateObject` and reads `line` and `url` directly; the static `line` is needed only for Combine sinks, which receive values before the property changes.
- **Compose**: Model it as a `ViewModel` exposing a `StateFlow<AutomationStatus>` data class of `port: Int?`, `token: String?`, `isRegistered: Boolean`, `failureReason: String?`. Compute `line` and `url` as pure functions of the data class, so the Swift pre-change publication problem does not arise (a collected value is always the new one). Update the flow from the main dispatcher. Validate port range 0 to 65535 yourself, as Swift gets it from `UInt16`.
- **React/Web**: Hold the four values in a store (a React context, Zustand or `useReducer` state) and derive `line` and `url` with pure selector functions of the state. Rendering from the new state removes the need for a separate static helper. A web port has no `~/.claude.json`; `isRegistered` would come from a service call.
- **AppKit / UIKit**: The reference is `macOS/Features/MCP/AutomationServerStatus.swift`, `@MainActor public final class` conforming to `ObservableObject` with `Foundation` and `Combine`. `AutomationEndpointPanel` (the Endpoint topic panel, declared in `AutomationSettingsPanelViewController.swift`) subscribes to the published values with `Publishers.CombineLatest4` and calls `AutomationServerStatus.line(port:isRegistered:failureReason:)` with the received values because of the willSet-time publication noted in the source. The tests are in `Tests/AgenticDeveloperHubSDKMacOSTests/MCP/AutomationSettingsPanelTests.swift`.
- **WinUI 3**: Implement a class that implements `INotifyPropertyChanged` with `Port` (`ushort?`), `Token`, `IsRegistered`, `FailureReason`, and computed `Url` and `Line` properties. Raise `PropertyChanged` for `Url` and `Line` whenever one of the four inputs changes. Unlike Swift's `@Published`, `PropertyChanged` fires after the field is set, so `Line` can be read off the instance and the static helper is not needed (keep it for parity if tests call it). Update from the UI thread via `DispatcherQueue.TryEnqueue` to mirror `@MainActor`, and bind in XAML with `{x:Bind ViewModel.Line, Mode=OneWay}` to a `TextBlock`. Build the URL with `$"http://127.0.0.1:{Port}{McpHttpEndpoint.Path}"`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/AutomationServerStatus.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The status sentence is available as a static function of explicit values as well as an instance property.
**Rationale**: The source comment explains that the panel renders from the value a `@Published` property publishes, and that value arrives before the property itself changes, so an observer reading `self` would see stale values. The static function lets the observer compute the sentence from the published value. A port whose change event fires after the set does not need the split.
**Approved**: pending

**Decision**: `failureReason` takes precedence over every other value in the status sentence, but `url` ignores it.
**Rationale**: The sentence has to say the endpoint is not running when it failed, whatever a stale port says. `url` is defined only by `port`; the host is expected to leave `port` nil on failure, per the `port` comment "nil until started, or when it failed".
**Approved**: pending

**Decision**: The model holds values and derives text; it does not start the endpoint, read the Claude Code config or validate anything.
**Rationale**: Per the doc comment the host's automation feature fills it and the panel reads it. Keeping it passive lets the panel be tested with any combination of values, as `AutomationSettingsPanelTests` does.
**Approved**: pending

**Decision**: The model is `@MainActor` and publishes the bearer token as a plain `String?`.
**Rationale**: The panel is main-thread UI, so isolating the model there avoids locking. The token is published only so the panel can build the registration command; the model adds no protection for it, so where it is persisted and who can read it is decided by the host feature and the instance's holders.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | security |

The model keeps state apart from the host feature that fills it and the panel that renders it, which satisfies separation of concerns. Two panel tests cover the `line` sentence for the listening, registered and failure cases; no test asserts `url`, the starting sentence or the failure-over-port precedence, so coverage is partial. The user-visible sentences are hardcoded English, so the string check fails. The bearer token is held in memory as a plain `String?` and the model does not decide its persistence, so secure storage is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
