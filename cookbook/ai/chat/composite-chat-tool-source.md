---
id: 3c0de3a7-a4ed-4eba-b7af-8f6a9cd899f1
title: "Composite Chat Tool Source"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Presents several ChatToolSource values as one: definitions concatenated in order, calls routed by tool name to the first source advertising it."
platforms:
  - swift
  - macos
tags:
  - chat-tool-source
  - tool-routing
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Composite Chat Tool Source

## Overview

`CompositeChatToolSource` is a `ChatToolSource` that wraps an ordered list of other `ChatToolSource` values and presents them to a chat session as one source. Its own doc comment states the role: "Several tool sources presented as one: definitions concatenated in order, calls routed to whichever source advertises the name." A host that has several independent sources of model-callable tools constructs one composite from them and hands that single value to the chat engine. The composite holds no tool logic of its own; it forwards `toolDefinitions()` and `callTool(name:argumentsJSON:caller:)` and nothing else.

## Behavioral Requirements

- **chat-tool-source-conformance**: The component MUST conform to `ChatToolSource` and MUST be `Sendable` (declared `@unchecked Sendable`).
- **construction-order**: `init(_ sources: [any ChatToolSource])` MUST store the given sources in the given order and MUST NOT filter or de-duplicate them.
- **definitions-concatenated-in-order**: `toolDefinitions()` MUST return the definitions of every source concatenated in source order, each source's own order preserved.
- **definitions-queried-per-call**: `toolDefinitions()` MUST query each source's `toolDefinitions()` on every call, with no caching.
- **definitions-awaited-sequentially**: `toolDefinitions()` MUST await the sources one after another, not in parallel.
- **definitions-not-deduplicated**: `toolDefinitions()` MUST NOT remove or rename a definition whose `name` appears in more than one source; duplicates are returned as they are.
- **empty-sources-empty-definitions**: A composite built from an empty array MUST return an empty array from `toolDefinitions()`.
- **call-routed-by-name**: `callTool(name:argumentsJSON:caller:)` MUST forward the call to the first source, in source order, whose `toolDefinitions()` contains a `ToolDefinition` with `name` equal to the requested `name`.
- **call-forwards-arguments-and-caller**: The forwarded call MUST pass `name`, `argumentsJSON` and `caller` to the chosen source unchanged, including a `nil` caller.
- **call-result-passthrough**: The composite MUST return the chosen source's `(content, isError)` result unchanged.
- **first-match-wins**: When two sources advertise the same `name`, the call MUST go to the earlier source only; the later source MUST NOT be called.
- **call-resolves-by-fresh-definitions**: Routing MUST be decided by querying each source's current `toolDefinitions()` at call time, in source order, stopping at the first source that advertises the name. A source after the match MUST NOT be queried.
- **unknown-tool-result**: When no source advertises `name`, `callTool` MUST return the content `unknown tool <name>` with `isError` true.
- **unknown-tool-calls-nothing**: When no source advertises `name`, the composite MUST NOT call any source's `callTool`, and MUST NOT throw.
- **two-argument-call-default**: A call to the two-argument `callTool(name:argumentsJSON:)` on a conforming type that implements only the three-argument form MUST reach the three-argument form with a `nil` caller. This comes from the default implementation in the `ChatToolSource` protocol extension, not from the composite.
- **no-side-effects**: The component MUST NOT perform file, network, process or notification side effects of its own.
- **sources-immutable**: The stored source list is a `let`; the composite MUST NOT add or remove sources after construction.
- **no-timeout-no-cancellation-handling**: The composite MUST NOT impose a timeout, retry or cancellation handling of its own; a slow wrapped source delays the composite equally.

## Appearance

Not applicable — this is a tool-routing model for a chat engine, not a visual component.

## States

Not applicable — this is a tool-routing model for a chat engine, not a visual component. It has no runtime state machine: its only stored value is the immutable source list.

## Accessibility

Not applicable — this is a tool-routing model for a chat engine, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| composite-tool-source-001 | definitions-concatenated-in-order | Sources `[A advertising a, b; B advertising c]` | `toolDefinitions()` names are `["a", "b", "c"]` (`CompositeChatToolSourceTests.concatenatesDefinitionsInOrder`) |
| composite-tool-source-002 | call-routed-by-name, call-forwards-arguments-and-caller, call-result-passthrough | Sources `[first advertising a; second advertising b]`; `callTool(name: "b", argumentsJSON: {}, caller: "pane-1")` | Result content is `b ok`; `second` records `("b", "pane-1")`; `first` records no call (`CompositeChatToolSourceTests.routesByNameAndPassesCaller`) |
| composite-tool-source-003 | unknown-tool-result, unknown-tool-calls-nothing | Sources `[one advertising a]`; `callTool(name: "zzz", argumentsJSON: empty, caller: nil)` | `isError` is true and content is exactly `unknown tool zzz` (`CompositeChatToolSourceTests.unknownToolIsASentence`) |
| composite-tool-source-004 | two-argument-call-default | One source advertising `a`; call `callTool(name: "a", argumentsJSON: empty)` on it | The source records one call with caller `nil` (`CompositeChatToolSourceTests.twoArgumentCallForwardsWithNilCaller`) |
| composite-tool-source-005 | empty-sources-empty-definitions | Composite built from `[]` | `toolDefinitions()` is `[]` |
| composite-tool-source-006 | unknown-tool-result | Composite built from `[]`; `callTool(name: "a", ...)` | Content `unknown tool a`, `isError` true |
| composite-tool-source-007 | first-match-wins, definitions-not-deduplicated | Sources `[A advertising x; B advertising x]` | `toolDefinitions()` has two entries named `x`; `callTool(name: "x", ...)` reaches A only and B records no call |
| composite-tool-source-008 | call-resolves-by-fresh-definitions, definitions-queried-per-call | Source A advertises `x` only after a flag is set; B always advertises `x`; call `x` before and after setting the flag | Before the flag the call reaches B; after it the call reaches A |
| composite-tool-source-009 | definitions-awaited-sequentially, definitions-concatenated-in-order | Sources whose `toolDefinitions()` record their start and finish | Each source finishes before the next starts, and results keep source order |
| composite-tool-source-010 | call-result-passthrough | Chosen source returns `("boom", true)` | Composite returns `("boom", true)` unchanged |

## Edge Cases

- **Empty source list**: The composite MUST return no definitions and answer every call with `unknown tool <name>`. MUST.
- **Empty or unknown name**: A name matching no definition, including the empty string, MUST produce `unknown tool <name>` with `isError` true; for the empty string the content is `unknown tool ` with a trailing space. MUST.
- **Duplicate names across sources**: The earlier source wins for calls; the advertised list still shows both definitions to the model. MUST.
- **Definitions changing between listing and call**: A tool advertised in an earlier `toolDefinitions()` result but no longer advertised at call time MUST be answered with `unknown tool <name>`, because routing re-queries. MUST.
- **Boundary arguments**: `argumentsJSON` of any content, including empty `Data`, is forwarded unparsed and unvalidated; the chosen source owns validation. MUST.
- **Concurrent access**: Concurrent `toolDefinitions()` and `callTool` calls on one composite MUST NOT interfere through the composite, since it holds only an immutable array; ordering and safety among calls into a wrapped source belong to that source.
- **Error states**: The composite has no dependency of its own that can fail. A wrapped source reports failure by returning `isError` true, which passes through unchanged; the composite itself reports only the unknown-tool case. MUST.
- **Offline or disconnected state**: Not applicable — the composite performs no networking; connectivity behavior belongs to the wrapped sources.
- **Cancellation and timeout**: The composite has none; cancellation of the surrounding task reaches the awaited source calls only as far as those sources honor it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sources` | `[any ChatToolSource]` | none (required) | The ordered tool sources to present as one. Order sets both the definition order and which source wins a duplicate name. |

The component defines no environment variable and no settings key.

## Deep Linking

Not applicable: the component defines no URL scheme, route or navigation destination; it is a headless routing type.

## Localization

- **unknown-tool-string**: The `unknown tool <name>` content is a hardcoded English literal with no localization mechanism. It is returned to the model as tool-result text, not rendered by this component. MUST (stated as an observed fact).

## Accessibility Options

Not applicable: the component presents no UI, so it responds to no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: the component contains no feature-flag or settings-key reference.

## Analytics

Not applicable: the component contains no analytics or event-tracking call.

## Privacy

- **Data collected**: None by the component. It forwards `argumentsJSON` and `caller` to a wrapped source and retains neither.
- **Storage**: None.
- **Transmission**: None of its own; the wrapped sources decide what leaves the process.
- **Retention**: None beyond the lifetime of the composite's source list.

## Logging

Not applicable: the component contains no logging call.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/Chat/CompositeChatToolSource.swift`, in the Foundation-only `AgenticDeveloperHubSDKCore` module. It imports no UI framework, so a SwiftUI host uses it exactly as an AppKit host does: build it from its tool sources and hand it to the chat session. The `ChatToolSource` protocol and `ToolDefinition` it relies on are in the same package.
- **Compose**: Model `ChatToolSource` as a Kotlin interface with `suspend fun toolDefinitions(): List<ToolDefinition>` and `suspend fun callTool(name: String, argumentsJson: ByteArray, caller: String?): ToolResult` (a data class of content and isError). Implement the composite over a `List<ChatToolSource>`; use a sequential `for` loop with early return over suspending lookups, not `async`, to keep the source's in-order, stop-at-first-match behavior. A default interface method reproduces the two-argument overload.
- **React/Web**: Model the source as an object with `toolDefinitions(): Promise<ToolDefinition[]>` and `callTool(name, argumentsJson, caller?): Promise<{content: string, isError: boolean}>`. Await each source in a `for...of` loop, not `Promise.all`, so definitions stay ordered and routing stops at the first match. Return `{content: "unknown tool " + name, isError: true}` when none match.
- **AppKit / UIKit**: The reference is `Core/Chat/CompositeChatToolSource.swift`, a `final class` declared `ChatToolSource, @unchecked Sendable`. `@unchecked Sendable` disables compiler checking; it is safe here because the only stored property is a `let` array. The routing loop is a `for source in sources where await source.toolDefinitions().contains(where:)` that returns on the first match, so definitions are re-queried per call. Results are a labeled tuple `(content: String, isError: Bool)`, not a throwing function. The tests are in `Tests/AgenticDeveloperHubSDKCoreTests/Chat/CompositeChatToolSourceTests.swift`.
- **WinUI 3**: Define `interface IChatToolSource { Task<IReadOnlyList<ToolDefinition>> ToolDefinitionsAsync(); Task<ToolResult> CallToolAsync(string name, ReadOnlyMemory<byte> argumentsJson, string? caller, CancellationToken ct); }` with `ToolResult` a `record(string Content, bool IsError)`. Implement `CompositeChatToolSource` over an `IChatToolSource[]` captured in the constructor (copy with `ToArray()` so it is effectively immutable, as the Swift `let` is). Await sources in a `foreach`, not `Task.WhenAll`. The Swift code passes no cancellation token; adding a `CancellationToken` is a .NET-side addition. Reproduce the two-argument overload as a C# 8 default interface method. Call the composite from a background `Task`, not the UI thread, since wrapped sources may do I/O.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Chat/CompositeChatToolSource.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Routing re-queries every source's `toolDefinitions()` on each `callTool`, instead of caching a name-to-source map built once.
**Rationale**: The `ChatToolSource` contract describes definitions as the tools to advertise "for this turn", so a source's tool set may change between turns. A fresh lookup keeps routing in step with what each source currently advertises, at the cost of one definitions query per earlier source per call. A port that caches a map would route to stale tools.
**Approved**: pending

**Decision**: When two sources advertise the same name, the first source in the list wins every call, and the advertised list still contains both definitions.
**Rationale**: The source neither de-duplicates definitions nor rejects duplicates; the early return in the routing loop makes order the only tie-break. The model may see two tools of the same name while only one is reachable. Callers control the outcome by source order.
**Approved**: pending

**Decision**: An unknown tool is reported as a result tuple (`isError` true, content `unknown tool <name>`), not as a thrown error.
**Rationale**: `ChatToolSource.callTool` is non-throwing, and the result goes back to the model as text, so the model can read the failure and recover. The test `unknownToolIsASentence` fixes this behavior.
**Approved**: pending

**Decision**: The class is declared `@unchecked Sendable` although all stored state is an immutable array.
**Rationale**: `ChatToolSource` itself inherits `Sendable`, so the stored existentials are already `Sendable` and the unchecked declaration is not hiding a mutable field. It is recorded here because `@unchecked` disables compiler verification and a port that adds mutable state would lose the guarantee.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |

The composite does one job, routing, and keeps no tool logic, which satisfies separation of concerns. `CompositeChatToolSourceTests.swift` covers every conformance vector: ordering, routing with caller pass-through, the unknown-tool result, the two-argument default, the empty composite, duplicate names, re-querying per call, sequential definition queries and result pass-through. The unknown-tool case is surfaced as an error result rather than swallowed. The `unknown tool` sentence is a hardcoded English literal, so the string check is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (CompositeChatToolSourceTests.swift, 10 of 10 vectors); unit-test-coverage now passed. |
