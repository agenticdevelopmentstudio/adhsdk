---
id: 7a776b77-a7b2-4ed5-a26f-94795434d675
title: "AI Interaction DTO"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The wire record of one daemon LLM call, shared by the AI Log window and the interactions HTTP route, with list reads truncated and a single failure split."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - ai-log
  - dto
depends-on: []
related:
  - 08d59319-de4b-438a-a144-dcf3912aa2e5
references: []
approved-by: ""
approved-date: ""
---

# AI Interaction DTO

## Overview

`AIInteractionDTO` is one LLM call the daemon made: a summarizer or oversight completion, logged at the shared `DaemonAIChat` chokepoint so the AI Log window (over XPC) and `GET /ai/interactions` (over HTTP) can show exactly what was asked and answered. It is an immutable, `Codable`, `Sendable`, `Equatable` value type with fourteen fields and one derived property, `isFailure`.

List reads truncate the three long text fields (`systemPrompt`, `userPrompt`, `response`) SQL-side, setting `truncated` to true when anything was cut. A by-id read returns the full text with `truncated` false. The type itself performs no truncation; it only carries the result.

## Behavioral Requirements

- **field-set**: The DTO MUST carry exactly these fields: `id` (`Int`), `feature`, `sessionId`, `providerKind`, `configName`, `model`, `systemPrompt`, `userPrompt`, `response` (all `String`), `durationMs` (`Int`), `outcome`, `error` (`String`), `truncated` (`Bool`) and `createdAt` (`String`).
- **immutable**: Every field MUST be a constant set once by the initializer.
- **codable-keys**: The DTO MUST encode and decode with its property names as the wire keys, using the synthesized `Codable` conformance.
- **decode-all-required**: Decoding MUST fail when any of the fourteen keys is missing; unlike its sibling `ConversationEntryDTO`, it has no tolerant decode.
- **initializer-complete**: The public memberwise initializer MUST take every field and MUST NOT give any field a default.
- **feature-vocabulary**: `feature` is documented as `summarize` or `oversight`, naming which feature asked; the type MUST NOT reject any other string.
- **provider-kind-vocabulary**: `providerKind` is documented as `plugin` (a selected provider configuration) or `cli` (the zero-config `claude -p` fallback); the type MUST NOT reject any other string.
- **outcome-vocabulary**: `outcome` is documented as `ok`, `error`, `guard_blocked` or `guard_deferred`; the type MUST NOT reject any other string.
- **is-failure**: `isFailure` MUST be true for every `outcome` other than the exact string `ok`, including a value outside the documented four.
- **is-failure-case-sensitive**: `isFailure` MUST compare `outcome` exactly, so `OK` counts as a failure.
- **truncated-list**: `truncated` MUST report whether the producer cut any of `systemPrompt`, `userPrompt` or `response`, so a viewer knows to fetch the full text by id. (The daemon store's list read is the producer that cuts and sets it.)
- **truncated-detail**: A producer that returns the full text (the daemon store's by-id read) MUST set `truncated` to false.
- **timestamp-text**: `createdAt` MUST be carried as the text the daemon stored, with no parsing or reformatting by the DTO.
- **verbatim-no-redaction**: The DTO MUST carry prompts and responses verbatim; it applies no redaction.
- **decoder-empty-string-present**: A decoder MUST NOT treat an empty string as a missing value.

### Producer contract

The type cannot enforce these; whoever builds the DTO (`AIInteractionStore`, `DaemonAIChat`) MUST honor them.

- **session-id-empty**: `sessionId` MUST be the empty string when the call was not scoped to a session.
- **config-name-empty-on-cli**: `configName` MUST be the empty string on the CLI path.
- **model-label**: `model` MUST be the model label the call resolved to: the configuration's model, the plugin id, or the CLI model.
- **failure-reason**: When the call did not complete, `error` MUST hold the reason and `response` MUST be empty; on success `error` MUST be the empty string.

### Consumer contract

The type cannot enforce this; the AI Log window is the consumer.

- **rendering-split**: List and detail rendering MUST derive their success/failure split from `isFailure` and not from comparing `outcome` themselves.
## Appearance

Not applicable — this is a data transfer type, not a visual component.

## States

Not applicable — this is a data transfer type, not a visual component.

## Accessibility

Not applicable — this is a data transfer type, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-interaction-dto-001 | is-failure | `outcome` is `ok`. | `isFailure` is false (test: testOkRowStillShowsResponse, through the result column). |
| ai-interaction-dto-002 | is-failure, failure-reason | `outcome` is `guard_blocked`, `response` empty, `error` a block-threshold message. | `isFailure` is true; the AI Log result column shows a warning glyph and the reason (test: testGuardBlockedRowShowsReasonWithWarningGlyph). |
| ai-interaction-dto-003 | is-failure, failure-reason | `outcome` is `guard_deferred`, `response` empty, `error` a memory-pressure message. | `isFailure` is true; the result column shows the warning glyph and the reason (test: testGuardDeferredRowShowsReason). |
| ai-interaction-dto-004 | is-failure | `outcome` is `error`. | `isFailure` is true (derived from the source; the AI Log result column's failure path). |
| ai-interaction-dto-005 | is-failure | `outcome` is `surprise`, outside the documented vocabulary. | `isFailure` is true (test: testV5_anOutcomeOutsideTheVocabularyIsAFailure). |
| ai-interaction-dto-006 | is-failure-case-sensitive | `outcome` is `OK`. | `isFailure` is true (test: testV6_theOutcomeComparisonIsCaseSensitive). |
| ai-interaction-dto-007 | codable-keys, field-set | Encode a DTO and decode the result. | The decoded value equals the original (test: testV7_encodingThenDecodingGivesTheOriginal). |
| ai-interaction-dto-008 | decode-all-required | Decode JSON that lacks `truncated`. | Decoding throws `keyNotFound` (test: testV8_decodingWithoutTruncatedThrowsKeyNotFound). |
| ai-interaction-dto-009 | truncated-list | List read of a row whose `userPrompt` is longer than the truncation length (default 300 characters, in the daemon's store). | `truncated` is true; each field longer than the limit is cut to it and each shorter field comes back unchanged (source: the daemon's `fetchAIInteractions`; test: testListTruncatesLongTextAndFlagsIt, which asserts a 400-character `userPrompt` reads back as 300 characters with `truncated` true). |
| ai-interaction-dto-010 | truncated-detail | By-id read of the same row. | Full text with `truncated` false (source: the daemon's `fetchAIInteraction`; test: testListTruncatesLongTextAndFlagsIt, which asserts the by-id text equals the original and `truncated` is false). |
| ai-interaction-dto-011 | truncated-list | List read of a row whose longest text field is exactly 300 characters, at the default truncation length. | `truncated` is false and the text is unchanged, because the store's check is a strict length greater than the limit (test: testV11_aFieldExactlyAtTheTruncationLengthIsNotCut). |
## Edge Cases

- **Null / empty input**: The DTO has no optionals; absent values are carried as empty strings (`sessionId` when not session-scoped, `configName` on the CLI path, `error` on success, `response` on failure); see `decoder-empty-string-present`.
- **Boundary values**: A row whose text is exactly at the truncation length is not marked truncated, because the daemon's check is a strict length greater than the limit. The DTO itself holds no limit.
- **Concurrent access**: Not applicable: the type is an immutable value and `Sendable`.
- **Error states**: A DTO whose `outcome` is not `ok` is a failure result, not a decoding error; the reason is in `error`. A missing key fails decoding for the whole payload, with no field fallback.
- **Offline / disconnected state**: Not applicable: the type does no networking; transport failures are the HTTP client's and XPC service's concern.
- **Unknown vocabulary**: A newer daemon may send a `feature`, `providerKind` or `outcome` this build does not list. It decodes, and any unrecognised `outcome` is treated as a failure by `isFailure`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| (none) | not applicable | not applicable | The type takes no configuration; its fields are all supplied to the initializer or decoded. |

## Deep Linking

Not applicable: the type defines no URL scheme or route; the `GET /ai/interactions` route that serves it is defined outside this file.

## Localization

Not applicable: the DTO holds no user-facing string of its own; the fields it carries are data, and the AI Log window supplies its own labels such as the failure glyph text.

## Accessibility Options

Not applicable: the type presents no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Full system prompts, user prompts and model responses for daemon LLM calls, plus a session id, a configuration display name and error text. These can contain session content.
- **Storage**: None by the type; the daemon stores the rows in its `ai_interactions` table.
- **Transmission**: The DTO crosses XPC and loopback HTTP between daemon and app; the type applies no redaction or encryption.
- **Retention**: Not applicable to the type; retention is the daemon store's concern.

## Logging

Not applicable: the type calls no logging API; recording an interaction is the daemon's `AIInteractionLog`, outside this file.

## Platform Notes

- **SwiftUI**: Framework-agnostic `struct`; same as AppKit.
- **Source**: `Core/Stenographer/AIInteractionDTO.swift`, importing only `Foundation`. A `public struct` conforming to `Codable`, `Sendable` and `Equatable` with `let` properties, a long explicit public initializer and one computed property, `isFailure`. The AI Log window reads it in `AILogListSource` and `AILogViewController`; the daemon builds it in `AIInteractionStore`.
- **Compose**: Use a Kotlin `data class` with `val` properties, annotated `@Serializable` for kotlinx.serialization, and a computed `val isFailure get() = outcome != OUTCOME_OK`, with one shared `OUTCOME_OK` constant. All fields are required, so give none a default value, matching the source.
- **React/Web**: Use a TypeScript `readonly` interface or `type` with the same fourteen keys, decoded from `GET /ai/interactions`. Validate presence of every key if parsing untyped JSON, since the source's decode fails on a missing key, and export `isFailure(dto)` as a function comparing against one shared `OUTCOME_OK` constant.
- **AppKit / UIKit**: The source description above applies as is: the DTO is UI-framework-agnostic, and the AppKit AI Log view controller consumes it.
- **WinUI 3**: Use a C# `record` (or `sealed record class`) with `init`-only properties and `System.Text.Json` attributes. Mark each property `[JsonRequired]` to match the source's missing-key failure, set `JsonSerializerDefaults.Web` naming to camelCase to match the wire keys, and add `public bool IsFailure => Outcome != OutcomeOk;` with one shared `OutcomeOk` constant with `[JsonIgnore]`. Bind a `ListView` or `DataGrid` row to the record, using `IsFailure` for a warning-glyph visual state.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/AIInteractionDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `isFailure` is the single place the outcome vocabulary is folded into success or failure.
**Rationale**: The source comment states it is shared by list and detail rendering, so a new failure outcome needs no change in either renderer.
**Approved**: pending

**Decision**: Any `outcome` other than `ok` is a failure, instead of listing the failure outcomes.
**Rationale**: A new or unknown outcome shows as a failure with its reason rather than as a success with an empty response; the source does not give a further reason.
**Approved**: pending

**Decision**: List reads truncate the three long fields in SQL and flag it with `truncated`.
**Rationale**: The source comment says the list stays light, while a by-id read returns the full text.
**Approved**: pending

**Decision**: The vocabularies for `feature`, `providerKind` and `outcome` are strings, not enums.
**Rationale**: The source documents the values in comments and does not validate them; this keeps the wire tolerant of values this build does not know. The source states no reason beyond the comments.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | partial | Privacy and Data |

`separation-of-concerns` passes because the type only carries a record and folds the outcome into one flag; storage, truncation and rendering stay in the daemon store and the window. `unit-test-coverage` passes: `AIInteractionDTOConformanceTests` (`AIInteractionDTOConformanceTests.swift`) covers `isFailure` for every outcome and the encode/decode round trip and missing-key failure; `AIInteractionLogTests` (`AIInteractionLogTests.swift`) covers the list truncation, the by-id read and the exact-length boundary through the daemon store. `AILogGuardOutcomeTests` exercises `isFailure` only through the AI Log result column, `AIInteractionLogTests` covers the list truncation and by-id read that fill the DTO through the daemon store, and the encode/decode round trip and missing-key failure have no test. `no-pii-in-logs` is partial because the type itself logs nothing but carries prompts and responses verbatim, with no redaction, for the AI Log window to display.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (AIInteractionDTOConformanceTests.swift, AIInteractionLogTests.swift, 11 of 11 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Recast truncation as the producer-reported truncated flag, grouped producer and consumer duties in their own subsections, made the decoder rule and no-default rule explicit, renamed no-secrets-handling to verbatim-no-redaction, added a boundary vector, shared OUTCOME_OK in ports, fixed the platform notes, and linked Conversation Entry DTO. |
