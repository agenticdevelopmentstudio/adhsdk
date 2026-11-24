---
id: 2eda149b-21d4-44cb-a1b4-67e2938659a4
title: "AI Feature"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The two-case discriminator naming which daemon feature asked for an AI completion; it keys the interaction log and selects the provider settings reader."
platforms:
  - swift
  - macos
tags:
  - ai-plugin
  - enum
  - ai-log
depends-on: []
related:
  - 4d7ed9a3-c6d8-491b-911a-cf257fde1c38
  - ef2a5ca9-04a4-46ab-8fef-3fdc6db2041d
references: []
approved-by: ""
approved-date: ""
---

# AI Feature

## Overview

`AIFeature` is a string-backed enumeration with two cases, `summarize` and `oversight`. Its own doc comment states its purpose: "Which daemon feature asked for a completion — the `ai_interactions` log discriminator." A daemon caller passes one value to the logged completion overload of the daemon AI chat component, which uses it for two things: the `feature` column of the `ai_interactions` log row (the case's raw string), and the choice of which provider settings reader resolves the provider for that completion. The type carries no behavior of its own; it is a closed set of names shared between the caller, the provider settings lookup and the log writer. It performs no I/O.

## Behavioral Requirements

- **case-set**: The type MUST declare exactly two cases, `summarize` and `oversight`, and no others.
- **raw-value-type**: The type MUST be backed by `String`.
- **raw-values-equal-case-names**: The raw value of each case MUST equal the case name: `summarize` has raw value "summarize" and `oversight` has raw value "oversight".
- **log-discriminator**: The raw value MUST be the text written to the `feature` column of an `ai_interactions` log row; the log writer stores the case's raw value, and the interaction log tests read back "summarize" and "oversight".
- **provider-settings-selection**: A lookup of provider settings for a feature MUST return the oversight-specific reader for `oversight` and the general reader for every other case; the source is a single equality test against `oversight`.
- **equality**: Two values MUST compare equal if and only if they are the same case, so a caller can test a feature with an equality comparison (the provider settings lookup does exactly that).
- **concurrency-safe**: The type MUST be declared `Sendable`, so a value can cross an actor or task boundary without a diagnostic.
- **no-additional-conformances-declared**: The type MUST NOT declare `Codable` or `CaseIterable`; it declares only `String` backing and `Sendable`. A caller that needs to enumerate the cases or encode the value must use the raw value.
- **no-error-domain**: The type MUST NOT define or throw any error; the only construction paths are the two literals and the failable raw-value initializer the language synthesizes for a string-backed enumeration, which returns nothing for an unknown string.

## Appearance

Not applicable — this is a two-case logic enumeration, not a visual component.

## States

Not applicable — this is a two-case logic enumeration with no lifecycle, no visual states and no runtime state machine; a value is one of its two cases.

## Accessibility

Not applicable — this is a two-case logic enumeration, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-feature-001 | raw-values-equal-case-names | Read the raw value of `summarize` | "summarize" |
| ai-feature-002 | raw-values-equal-case-names | Read the raw value of `oversight` | "oversight" |
| ai-feature-003 | log-discriminator | Record a completion with feature `oversight` through the logged completion overload and read the stored log row (`AIInteractionLogTests`) | The row's `feature` is "oversight" |
| ai-feature-004 | log-discriminator | Record a completion with feature `summarize` through the logged completion overload and read the stored log row (`AIInteractionLogTests`) | The row's `feature` is "summarize" |
| ai-feature-005 | provider-settings-selection | Ask the daemon database for provider settings with feature `oversight` (no test in source asserts this) | The oversight-specific provider settings reader is returned |
| ai-feature-006 | provider-settings-selection | Ask the daemon database for provider settings with feature `summarize` (no test in source asserts this) | The general provider settings reader is returned |
| ai-feature-007 | no-error-domain | Construct the type from the string "unknown" using the raw-value initializer | The result is nothing; no error is thrown |
| ai-feature-008 | equality | Compare `summarize` with `summarize`, then `summarize` with `oversight` | Equal, then not equal |

## Edge Cases

- **Unknown raw string**: the synthesized raw-value initializer MUST return nothing for any string other than "summarize" or "oversight", including the empty string and differently-cased spellings; the source adds no fallback case.
- **A new case added later**: the provider settings lookup sends every case other than `oversight` to the general reader, so a third case would silently use the general reader and be written to the log under its own raw value; the source documents no rule beyond that.
- **Null and empty input**: Not applicable — the type has no stored data and no optional input; a value is always one of two cases.
- **Boundary values**: Not applicable — a closed two-case set has no numeric or size boundary.
- **Concurrent access**: Not applicable as a hazard — the type is `Sendable` and immutable, so concurrent reads need no synchronization.
- **Error states and offline state**: Not applicable — the type performs no network, database or file-system call; the callers that do are described by the daemon AI chat component.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `feature` argument | `AIFeature` | none (required by the logged completion overload) | The caller's choice of which daemon feature the completion is for; it selects the provider settings reader and the log discriminator. |

## Deep Linking

Not applicable: the source defines no URL, route or navigable destination.

## Localization

Not applicable: the raw values are machine identifiers written to a log column, not user-facing text, and the source contains no display string.

## Accessibility Options

Not applicable: the type renders nothing and reads no accessibility display setting.

## Feature Flags

Not applicable: the source declares no feature-flag key and contains no conditional gating; the name "feature" refers to a daemon capability that requests completions, not to a flag.

## Analytics

Not applicable: the source contains no analytics or event-emission call.

## Privacy

- **Data collected**: None; the type holds one of two fixed names. The log rows it keys do carry full prompts and replies, which belongs to the daemon AI chat component.
- **Storage**: None in this type.
- **Transmission**: None in this type.
- **Retention**: None in this type.

## Logging

Not applicable: the type contains no logging call; it is the discriminator that the log writer records, and the writer is described by the daemon AI chat component.

## Platform Notes

- **SwiftUI**: not applicable to this file; it imports only `Foundation`. A SwiftUI view that filters the AI log by feature would bind to the raw string or iterate the two cases by hand, since `CaseIterable` is not declared.
- **Compose**: model it as a Kotlin `enum class AiFeature(val wire: String)` with `SUMMARIZE("summarize")` and `OVERSIGHT("oversight")`, and look a case up from a string with a `firstOrNull` over `entries`, returning null for unknown text to match the failable raw-value initializer.
- **React/Web**: model it as a string-literal union type `type AIFeature = "summarize" | "oversight"`; a runtime guard function replaces the failable initializer, and the settings lookup is a plain conditional on `"oversight"`.
- **AppKit / UIKit**: this is the source. The file is `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/AIFeature.swift`, a `public enum AIFeature: String, Sendable` inside the `AIPluginKit` framework. Callers are the logged completion overload in `Database/Daemon/AILog/DaemonAIChat+Log.swift`, the settings lookup in `DaemonDatabase+AIProviderSettings.swift` and the interaction store in `AIInteractionStore.swift`, which writes `feature.rawValue`.
- **WinUI 3**: model it as a C# `enum AIFeature { Summarize, Oversight }` with a small extension method returning the lowercase wire string, because a C# enum serializes by name or number rather than by a string raw value. With `System.Text.Json`, add `[JsonConverter(typeof(JsonStringEnumConverter))]` plus a camel-case naming policy, or a custom converter, so the stored `feature` column text stays "summarize" or "oversight". The enum is a value type, so it is safe to pass between `Task`s with no extra step. Use `Enum.TryParse` with `ignoreCase: false` to reproduce the failable initializer.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/AIFeature.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The feature discriminator is a closed enumeration rather than a free-form string.
**Rationale**: The source types the `feature` argument as `AIFeature` and writes `feature.rawValue` to the log, so a misspelled feature cannot reach the log or the settings lookup. The cost is that a new feature needs a code change and a decision about its settings reader.
**Approved**: pending

**Decision**: Provider settings selection special-cases only `oversight`; every other case uses the general reader.
**Rationale**: The source gives oversight its own provider selection (its remapped reader) while summaries use the general one, and expresses that as one equality test. This keeps the common path unchanged and means a new case defaults to the general reader.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the type only names two features; the logging, the settings lookup and the completion all live in other components. `unit-test-coverage` is partial because no test sits beside the enumeration itself; its raw values are exercised indirectly by the interaction log tests (`AIInteractionLogTests`), and the oversight provider reader tests (`OversightProviderReaderTests`) exercise `oversightAIProviderSettings` directly, not the equality test that selects it, and nothing asserts the raw values on their own, the selection by feature, or the raw-value initializer's failure on unknown text.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
