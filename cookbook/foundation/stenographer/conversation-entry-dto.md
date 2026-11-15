---
id: 08d59319-de4b-438a-a144-dcf3912aa2e5
title: "Conversation Entry DTO"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One line of the human-and-agent conversation across observed sessions, with attribution carried per row and a tolerant decode for an app newer than its daemon."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - conversations
  - dto
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Conversation Entry DTO

## Overview

`ConversationEntryDTO` is one line of the conversation between a human and an observed Claude session, extracted from the captured transcript (`transcript_lines`) rather than from any summarization pass. The Conversations window renders these as a group chat: every observed session's dialogue interleaved on one timeline, each row labelled with the project, branch and session name it came from.

Attribution (`projectName`, `gitBranch`, `sessionName`, `termProgram`) travels with the entry rather than being looked up per row, because the feed spans many sessions and the join that supplies it costs nothing at query time.

The type is an immutable `Codable`, `Sendable`, `Equatable` struct that crosses the app-to-daemon boundary over XPC and HTTP. It has a hand-written tolerant `Decodable` because the app and daemon are installed separately, so an app can be newer than the daemon answering it. Two derived members fold the `kind` vocabulary: `isFromUser` and `isWorkOutput`, plus the static `workOutputKinds` set.

## Behavioral Requirements

- **field-set**: The DTO MUST carry `id` (`Int`), `sessionId`, `kind`, `text`, `timestamp`, `projectName`, `gitBranch`, `sessionName` and `termProgram` (all `String` except `id`).
- **immutable**: Every field MUST be a constant set once by the initializer or decoder.
- **row-identity**: `id` MUST be the row's stable identity: the `transcript_lines` row id times 1000 plus the block's index within that entry, because one captured entry can yield more than one line.
- **row-identity-unfiltered-index**: The block index MUST be the block's position in the unfiltered entry, so `id` does not change when the caller changes what it asks to see.
- **identity-not-paging**: `id` MUST be used for identity only; pages are cut on `timestamp`, not on `id`.
- **kind-vocabulary**: `kind` is documented as `prompt` (the human typed it), `reply` (the agent addressed the human), `progress` (the agent narrating its own work mid-turn), `thinking` (extended thinking) or `notice` (an interruption or other transcript event worth showing); the type MUST NOT reject any other string.
- **kind-single-field**: The line's role MUST be carried in the single `kind` field, not in boolean flags, because the combinations are mutually exclusive.
- **timestamp-iso**: `timestamp` MUST be the ISO-8601 text as written in the transcript, with no reformatting by the DTO.
- **project-name**: `projectName` MUST be the last path component of the session's project root, or the empty string when unknown.
- **git-branch**: `gitBranch` MUST be the session's git branch, or the empty string when not in a repository.
- **session-name**: `sessionName` MUST be the session's title, or the empty string when it has none, and MUST NOT be its summary.
- **term-program**: `termProgram` MUST be the session's `TERM_PROGRAM`, or the empty string when unknown, so a row can be headed with that application's icon.
- **initializer-default**: The public initializer MUST take every field, with `termProgram` defaulting to the empty string.
- **is-from-user**: `isFromUser` MUST be true exactly when `kind` is `prompt`.
- **work-output-kinds**: `workOutputKinds` MUST be the set of `progress` and `thinking`.
- **is-work-output**: `isWorkOutput` MUST be true exactly when `kind` is a member of `workOutputKinds`.
- **shared-work-list**: The daemon's filter and the app's mapping MUST both read `workOutputKinds`, so a kind added to one cannot be missed by the other. The daemon's `ConversationExtractor.Kind.isWorkOutput` reads it.
- **work-output-default-hidden**: The Conversations window hides work output by default, because it outnumbers replies roughly three to one; the DTO itself filters nothing.
- **tolerant-decode-required-keys**: Decoding MUST fail with `keyNotFound` when `id`, `sessionId`, `kind`, `text`, `timestamp`, `projectName`, `gitBranch` or `sessionName` is missing; these are the fields that have always been there.
- **tolerant-decode-term-program**: Decoding MUST treat a missing or null `termProgram` as the empty string, which is the same value the daemon sends when it has nothing to say.
- **tolerant-decode-reason**: Fields added later MUST decode to their absence rather than throw, so one missing field cannot blank the whole feed.
- **coding-keys**: The wire keys MUST be the property names `id`, `sessionId`, `kind`, `text`, `timestamp`, `projectName`, `gitBranch`, `sessionName` and `termProgram`.
- **encode-synthesized**: Encoding MUST write all nine keys, using the synthesized `Encodable` conformance with the declared coding keys.

## Appearance

Not applicable — this is a data transfer type, not a visual component.

## States

Not applicable — this is a data transfer type, not a visual component.

## Accessibility

Not applicable — this is a data transfer type, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conversation-entry-dto-001 | is-from-user | `kind` is `prompt`. | `isFromUser` is true (derived from the source expression; no direct test). |
| conversation-entry-dto-002 | is-from-user | `kind` is `reply`. | `isFromUser` is false (derived from the source expression; no direct test). |
| conversation-entry-dto-003 | work-output-kinds, is-work-output | `kind` is `progress`, then `thinking`. | `isWorkOutput` is true for both (derived from the source; no direct test). |
| conversation-entry-dto-004 | is-work-output | `kind` is `prompt`, `reply` or `notice`. | `isWorkOutput` is false for each (derived from the source; no direct test). |
| conversation-entry-dto-005 | tolerant-decode-term-program | Decode JSON with all eight always-present keys and no `termProgram`. | Decoding succeeds and `termProgram` is the empty string (derived from the source; no direct test). |
| conversation-entry-dto-006 | tolerant-decode-required-keys | Decode JSON lacking `gitBranch`. | Decoding throws `keyNotFound` (derived from the source; no direct test). |
| conversation-entry-dto-007 | coding-keys, encode-synthesized | Encode a DTO with `termProgram` of `iTerm.app` and decode it back. | The result equals the original (derived from the conformances; no direct test). |
| conversation-entry-dto-008 | initializer-default | Build with no `termProgram` argument. | `termProgram` is the empty string (derived from the source default; no direct test). |
| conversation-entry-dto-009 | row-identity, row-identity-unfiltered-index | The daemon builds entries from a `transcript_lines` row with id 7 that yields blocks at offsets 0 and 2 after filtering. | The entries have ids 7000 and 7002 (source: the daemon's `ConversationStore`, which computes the id as the row id times its maximum lines per entry of 1000 plus the offset; tests in `ConversationFeedTests`: testIdsAreUniqueAcrossBlocksOfTheSameEntry and testAnIdDoesNotMoveWhenTheWorkOutputFilterChanges). |
| conversation-entry-dto-010 | shared-work-list | The daemon's `ConversationExtractor.Kind.progress.isWorkOutput` and `.reply.isWorkOutput`. | True and false, read from `workOutputKinds` (source: `ConversationExtractor`; no direct test). |
| conversation-entry-dto-011 | tolerant-decode-term-program | Decode JSON with `termProgram` set to null. | `termProgram` is the empty string (derived from `decodeIfPresent`; no direct test). |

## Edge Cases

- **Null / empty input**: Missing context is carried as the empty string (`projectName`, `gitBranch`, `sessionName`, `termProgram`), never as null in the model. `text` may be empty. A decoder MUST NOT treat these empty strings as missing.
- **Boundary values**: `id` is the row id times 1000 plus an offset, so an offset of 1000 would collide with the next row's first id. The daemon prevents it by keeping only the first 1000 blocks of an entry, counted before the work-output filter (`maxLinesPerConversationEntry`, a private constant in `ConversationStore`); later blocks are dropped (test: testAnEntryLongerThanTheIdStrideCannotCollideWithTheNextOne). The DTO itself does not check.
- **Concurrent access**: Not applicable: the type is an immutable value and `Sendable`.
- **Error states**: A missing always-present key fails decoding, and with a list payload that fails the whole decode of the array, not only one row. A missing `termProgram` is tolerated. An unknown `kind` decodes, and `isFromUser` and `isWorkOutput` are false for it.
- **Offline / disconnected state**: Not applicable: the type does no networking; transport failures belong to the HTTP client and XPC service.
- **Older daemon, newer app**: The app can be newer than the daemon answering it; the tolerant decode keeps the feed rendering with an empty `termProgram` rather than blanking it. A daemon newer than the app simply sends keys the app ignores.
- **Page boundaries**: Pages are cut on `timestamp`, and every block of one transcript entry carries the same timestamp, so a page holds whole entries, except that an entry larger than the page limit is emitted whole. This is the daemon's rule and not the DTO's; the DTO's `id` is never a page cursor.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| termProgram | `String` | empty string | The only initializer parameter with a default; the other eight are required. |

The type reads no environment variable or settings key.

## Deep Linking

Not applicable: the type defines no URL scheme or route; the conversations route that serves it is outside this file.

## Localization

Not applicable: the type holds no user-facing string of its own; `text` is transcript content carried verbatim and the window supplies its own labels.

## Accessibility Options

Not applicable: the type presents no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Transcript text of human prompts and agent replies, plus the project folder name, git branch, session title and terminal program for each row.
- **Storage**: None by the type; the daemon stores the transcript lines the entries are extracted from.
- **Transmission**: The entry crosses XPC and loopback HTTP from daemon to app; the type applies no redaction or encryption.
- **Retention**: Not applicable to the type; retention is the daemon store's concern.

## Logging

Not applicable: the type calls no logging API.

## Platform Notes

- **SwiftUI**: Source is `Core/Stenographer/ConversationEntryDTO.swift`, importing only `Foundation`. A `public struct` conforming to `Codable`, `Sendable` and `Equatable` with `let` properties, two computed properties, a `static let` set, a memberwise `init` and a custom `init(from:)` using a private `CodingKeys` enum. The tolerant decode is `decodeIfPresent(String.self, forKey: .termProgram) ?? ""`. The daemon builds it in `ConversationStore`; the macOS Conversations feed consumes it.
- **Compose**: Use a Kotlin `@Serializable data class` with `val termProgram: String = ""` and `Json { coerceInputValues = true }` or a null-tolerant default so a missing key decodes. kotlinx.serialization uses property defaults for missing keys, so the tolerant decode is the default behavior; required fields stay without defaults.
- **React/Web**: A TypeScript interface with `termProgram?: string`, and a decoding function that applies `?? ""` and throws on a missing always-present key, since structural typing alone does not enforce them. Export `isFromUser(entry)` and `isWorkOutput(entry)` using a shared `WORK_OUTPUT_KINDS` set.
- **AppKit / UIKit**: Identical to the SwiftUI note: the DTO is UI-framework-agnostic; the AppKit Conversations feed maps it to chat bubbles using `isFromUser` and `isWorkOutput`.
- **WinUI 3**: Use a C# `record` with `System.Text.Json`. Mark the eight always-present properties `[JsonRequired]` and give `TermProgram` a default of `""` so a missing key deserializes without error; use camelCase property naming to match the wire keys. Add `IsFromUser` and `IsWorkOutput` as computed `[JsonIgnore]` properties over a static `FrozenSet<string>` or `HashSet<string>` for the work-output kinds. Bind a `ListView` with a `DataTemplateSelector` that picks the bubble side from `IsFromUser`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/ConversationEntryDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The conversation comes from the captured transcript, not from a summarization pass.
**Rationale**: The source comment says the transcript already is the conversation, and a summary would be one sentence per ended session rather than a running feed.
**Approved**: pending

**Decision**: Attribution travels with each entry.
**Rationale**: The feed spans many sessions, so a row without it cannot be labelled, and the join that supplies it costs nothing at query time.
**Approved**: pending

**Decision**: `id` is the transcript row id times 1000 plus the block index, and it is for identity only.
**Rationale**: One captured entry can yield several lines, and the index is taken from the unfiltered entry so it does not shift when filters change. Pages are cut on `timestamp`.
**Approved**: pending

**Decision**: The role is one `kind` string, not three flags.
**Rationale**: The source comment states the combinations are mutually exclusive, and a boolean triple would admit states that cannot happen.
**Approved**: pending

**Decision**: `isFromUser` and `isWorkOutput` are the single places the `kind` vocabulary is folded, and `workOutputKinds` is the one list.
**Rationale**: The source comments say the bubble's side selection and icon share the first, and the daemon's filter and the app's mapping both read the set, so a kind added to one cannot be missed by the other.
**Approved**: pending

**Decision**: Decoding is tolerant of a missing `termProgram` only.
**Rationale**: The two binaries install separately, so an app can be newer than its daemon, and the synthesized decode would throw on a missing key and blank the whole feed over one field. The always-present fields stay required.
**Approved**: pending

**Decision**: Work output is off by default in the window.
**Rationale**: The source comment says progress and thinking lines outnumber the replies roughly three to one.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`separation-of-concerns` passes because the type only carries a row and folds `kind` into two derived flags; extraction, filtering, paging and rendering stay in the daemon and the window. `unit-test-coverage` is partial because `ConversationEntryDTOConformanceTests` (`AgenticDeveloperHubSDKCoreTests/Stenographer/ConversationEntryDTOConformanceTests.swift`) tests vectors 001 to 008 and 011; vector 009 is skipped there (the daemon builds the ids; covered by `ConversationFeedTests`) and vector 010 is skipped (`ConversationExtractor` lives in the daemon target, not Core). `graceful-degradation` passes because a missing `termProgram` from an older daemon decodes to the empty string instead of failing the feed.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ConversationEntryDTOConformanceTests.swift, 9 of 11 vectors tested, 2 skipped); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Softened unmeasured claims, named the source symbols in rationales, added empty-not-missing, fixed the WinUI null and Compose notes, and set Configuration to not applicable. |
