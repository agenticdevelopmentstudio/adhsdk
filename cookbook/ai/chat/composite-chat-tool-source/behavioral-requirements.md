
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

