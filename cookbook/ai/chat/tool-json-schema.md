---
id: 84c313c7-5204-4955-bca7-46f6c6cd63a8
title: "Tool JSON Schema"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Builds the parametersJSONSchema Data of a ToolDefinition: an object schema with sorted keys, plus string, integer, number and boolean property fragments."
platforms:
  - swift
  - macos
tags:
  - chat-tool-source
  - json-schema
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Tool JSON Schema

## Overview

`ToolJSONSchema` is a caseless `enum` of static helpers that build the `parametersJSONSchema` value of a `ToolDefinition`. Its doc comment gives the reason: "One place, so every tool source spells an object schema the same way." A tool source describes each argument with one of four fragment helpers (`string`, `integer`, `number`, `boolean`), then wraps the fragments with `object(properties:required:)`, which returns the finished schema as UTF-8 JSON `Data`.

## Behavioral Requirements

- **namespace-only**: The component MUST be a stateless namespace (a caseless enum) with only static members; it MUST NOT be instantiable and MUST hold no state.
- **object-shape**: `object(properties:required:)` MUST produce a JSON object with exactly three top-level keys: `type` equal to `"object"`, `properties` holding the supplied map, and `required` holding the supplied array.
- **required-default-empty**: When `required` is omitted, `object` MUST emit `required` as an empty array, not omit the key.
- **properties-passthrough**: `object` MUST emit each supplied property fragment unchanged under its name, with no validation of fragment contents.
- **sorted-keys-output**: `object` MUST serialize with sorted keys, so the same inputs always produce byte-identical `Data`.
- **required-order-preserved**: `object` MUST emit the `required` names in the order given, with no sorting or de-duplication.
- **required-not-checked-against-properties**: `object` MUST NOT check that each `required` name exists in `properties`; a missing name is emitted as given.
- **empty-properties**: `object(properties: [:])` MUST produce a valid object schema with an empty `properties` object and an empty `required` array.
- **schema-serialization-fallback**: NEEDS REVIEW: Not implemented in source. When serialization throws, `object` returns the two-byte JSON `{}` through `try?` with no log, error or other signal, so the tool is advertised with a schema that has no `type`, `properties` or `required`. Evidence that would settle it: whether any property map a caller can build is non-serializable (a test with a fragment holding a non-JSON value), and whether callers should learn of the fallback.
- **fragment-string**: `string(_:)` MUST return a fragment with `type` equal to `"string"` and `description` equal to the argument.
- **fragment-integer**: `integer(_:)` MUST return a fragment with `type` equal to `"integer"` and `description` equal to the argument.
- **fragment-number**: `number(_:)` MUST return a fragment with `type` equal to `"number"` and `description` equal to the argument.
- **fragment-boolean**: `boolean(_:)` MUST return a fragment with `type` equal to `"boolean"` and `description` equal to the argument.
- **fragment-description-verbatim**: Each fragment helper MUST carry its description text unmodified, including the empty string.
- **no-side-effects**: The component MUST NOT perform file, network, process or notification side effects.
- **thread-safety**: Every member MUST be safe to call concurrently, since all are pure functions of their arguments.

## Appearance

Not applicable — this is a schema builder for tool definitions, not a visual component.

## States

Not applicable — this is a schema builder for tool definitions, not a visual component. It has no runtime state machine and holds no state.

## Accessibility

Not applicable — this is a schema builder for tool definitions, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tool-json-schema-001 | object-shape, required-default-empty, empty-properties, sorted-keys-output | `object(properties: [:])` | Bytes decode to `{"properties":{},"required":[],"type":"object"}` with keys in that sorted order |
| tool-json-schema-002 | fragment-string, object-shape, properties-passthrough | `object(properties: ["x": string("x")])` (the schema used by `HostMCPServerTests`) | Decodes to an object whose `properties.x` is `{"description":"x","type":"string"}` |
| tool-json-schema-003 | fragment-integer, fragment-number, fragment-boolean | Call `integer("n")`, `number("n")`, `boolean("n")` | Each returns a two-key dictionary with `type` `integer`, `number`, `boolean` respectively and `description` `n` |
| tool-json-schema-004 | required-order-preserved | `object(properties: ["b": string("b"), "a": string("a")], required: ["b", "a"])` | `required` decodes as `["b", "a"]`; `properties` keys appear sorted `a`, `b` in the bytes |
| tool-json-schema-005 | required-not-checked-against-properties | `object(properties: [:], required: ["ghost"])` | `required` decodes as `["ghost"]`; no error |
| tool-json-schema-006 | sorted-keys-output | Call `object` twice with the same multi-property input | The two `Data` values are byte-equal |
| tool-json-schema-007 | fragment-description-verbatim | `string("")` | `description` is the empty string, key still present |
| tool-json-schema-008 | object-shape | `object(properties: ["u": string("a url")], required: ["u"])` | Top-level keys are exactly `properties`, `required`, `type`; `required` is `["u"]` |

The schema is exercised indirectly as a fixture by `CompositeChatToolSourceTests`, `HostMCPServerTests`, `HostMCPServerDrainTests`, `LocalChatSessionTests`, `MCPHTTPEndpointTests` and `PersonaTerminalChatToolsTests`; `ToolJSONSchemaConformanceTests` asserts its output bytes directly, one test per vector.

## Edge Cases

- **Empty properties**: `object(properties: [:])` MUST return a valid schema, never `{}`. MUST.
- **Empty or duplicate required names**: `required` entries are emitted as given, so duplicates and names absent from `properties` appear in the output. MUST.
- **Empty description**: A fragment with an empty description MUST still carry the `description` key. MUST.
- **Unusual property names**: A property name is a dictionary key and is passed to the serializer as is, with no check for emptiness or characters. MUST.
- **Serialization failure**: The failure path of `object` returns `{}` silently; see the open question on `schema-serialization-fallback`.
- **Concurrent access**: Not applicable — every member is a pure function with no shared state.
- **Offline or disconnected state**: Not applicable — the component performs no networking.
- **Large inputs**: No size limit exists; output size grows with the input and nothing is truncated. MUST.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `properties` | `[String: [String: Any]]` | none (required) | Map of argument name to schema fragment, as built by `string`, `integer`, `number` or `boolean`. |
| `required` | `[String]` | `[]` | Names of arguments the model MUST supply. |
| description argument of each fragment helper | `String` | none (required) | Text shown to the model for that argument. |

The component defines no environment variable and no settings key.

## Deep Linking

Not applicable: the component defines no URL scheme, route or navigation destination.

## Localization

- **description-text-from-caller**: The component localizes nothing; every description string is supplied by the caller and embedded verbatim. A caller that passes an English literal produces an English schema. The model, not a person, is the reader.

## Accessibility Options

Not applicable: the component presents no UI, so it responds to no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: the component contains no feature-flag or settings-key reference.

## Analytics

Not applicable: the component contains no analytics or event-tracking call.

## Privacy

- **Data collected**: None. The component transforms caller-supplied names and descriptions into JSON.
- **Storage**: None.
- **Transmission**: None by the component; the `Data` it returns is advertised to the model by the tool source that holds the `ToolDefinition`.
- **Retention**: None.

## Logging

Not applicable: the component contains no logging call, including on the serialization fallback.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/Chat/ToolJSONSchema.swift`, in the Foundation-only `AgenticDeveloperHubSDKCore` module. It has no UI dependency, so SwiftUI and AppKit hosts use it identically.
- **Compose**: Build the schema with `kotlinx.serialization.json.buildJsonObject` and `JsonObject`/`JsonPrimitive`; fragment helpers return `JsonObject`. `kotlinx.serialization` keeps insertion order, so sort property names with a `sortedMap` before building to match the source's sorted-key output. Decide explicitly whether a serialization failure should throw; the source returns `{}`.
- **React/Web**: Return plain objects from the fragment helpers and `JSON.stringify` the result. `JSON.stringify` keeps insertion order, so sort keys with a replacer or build with sorted entries to reproduce byte-identical output; encode to UTF-8 with `TextEncoder`.
- **AppKit / UIKit**: The reference is `Core/Chat/ToolJSONSchema.swift`, a caseless `enum` over `JSONSerialization.data(withJSONObject:options:)` with `.sortedKeys`. The `try?` turns any failure into `Data("{}".utf8)`. Fragments are `[String: Any]` dictionaries, so the schema is only as typed as the caller makes it. Helpers are used by tool sources such as the host-app, browser, terminal, mail and partner tool sources.
- **WinUI 3**: Use `System.Text.Json`: build the schema with `JsonObject` and `JsonArray` (`System.Text.Json.Nodes`), with static methods `String(description)`, `Integer(...)`, `Number(...)`, `Boolean(...)` on a `static class ToolJsonSchema`. `JsonObject` preserves insertion order, so add properties in sorted order (for example from a `SortedDictionary<string, JsonNode>`) to match the source's `.sortedKeys`. Serialize with `JsonSerializer.SerializeToUtf8Bytes` to get `byte[]` in place of `Data`. Unlike Swift's silent `{}` fallback, serialization of `JsonNode` values does not fail for these types; a port that wants the same fallback must add an explicit try/catch.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Chat/ToolJSONSchema.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: All tool sources build parameter schemas through this one helper instead of hand-writing JSON.
**Rationale**: The doc comment says it exists so "every tool source spells an object schema the same way". A single builder keeps the `type`, `properties` and `required` shape uniform across sources, and the sorted-key output makes a schema's bytes stable.
**Approved**: pending

**Decision**: `required` is always emitted, as an empty array when no argument is required.
**Rationale**: Some schema consumers expect the key to be present; always emitting it removes a case. The source does it by giving the parameter a default of `[]`.
**Approved**: pending

**Decision**: Serialization failure falls back to the bytes `{}` with no signal.
**Rationale**: The source uses `try?` with a `?? Data("{}".utf8)` default, favoring a non-optional return type over reporting an error. The cost is that a failure produces a schema with no `type`; see the open question on `schema-serialization-fallback`.
**Approved**: pending

**Decision**: Fragments are untyped `[String: Any]` dictionaries rather than a schema type.
**Rationale**: The source keeps the helper tiny; any valid JSON-schema fragment (for example one with `enum` or `items`) can be passed to `object`, at the price that `object` cannot validate it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

The enum does one job, building schema bytes, and has no dependencies beyond Foundation, which satisfies separation of concerns. `ToolJSONSchemaConformanceTests` asserts every conformance vector against the output bytes and the fragments, so coverage passes. The serialization failure is converted to `{}` with no error or log, so explicit error handling is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (ToolJSONSchemaConformanceTests.swift, 8 of 8 vectors); unit-test-coverage now passed. |
