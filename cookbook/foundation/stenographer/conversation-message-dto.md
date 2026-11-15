---
id: f7338580-0738-46d8-a0c3-528794c045be
title: "Conversation Message DTOs"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Per-session conversation message, cursor page, range query and unknown-id error for steno conversation fetch."
platforms:
  - swift
  - macos
tags:
  - stenographer
  - foundation
  - dto
  - wire
depends-on:
  - 08d59319-de4b-438a-a144-dcf3912aa2e5
related: []
references: []
approved-by: ""
approved-date: ""
---

# Conversation Message DTOs

## Overview

These are the shapes `steno conversation fetch` exchanges with a reader that follows one session's conversation: `ConversationMessageDTO` (one message), `ConversationMessagesPageDTO` (one page, oldest first), `ConversationMessagesQueryDTO` (what the reader asks for) and `ConversationRangeError` (why a range cannot be read). A message is the per-session twin of the merged-feed `ConversationEntryDTO`: the feed entry carries attribution for a many-session timeline, while a message belongs to one session and carries only what the message says. Paging is by message id, not by time, so it stays exact where two transcript entries share a timestamp. This code holds shapes, one kind-to-type fold and one error; the query that reads the transcript lives in the daemon's `ConversationStore`, outside these sources.

## Behavioral Requirements

- **message-fields**: A `ConversationMessageDTO` MUST carry `id` (Int), `type` (String), `kind` (String), `content` (String), `time` (String) and `agentId` (optional String).
- **message-id-identity**: A message `id` MUST be the same value as the `id` of the feed `ConversationEntryDTO` for the same row, so a message and its feed entry are one row.
- **message-id-is-cursor**: A message `id` MUST be treated as a cursor and not a count: ids grow within one transcript entry but are not ordered across a resumed session's files.
- **message-type-values**: `type` MUST say who is talking, one of `user` (the human typed it), `model` (the agent said it) or `notice` (an interruption or other transcript event).
- **message-kind-values**: `kind` MUST carry the extractor's finer kind; the known values are `prompt`, `reply`, `progress`, `thinking` and `notice`, and the type accepts any other string (see **no-validation**).
- **message-time-format**: `time` MUST be ISO-8601 text as written in the transcript.
- **message-agent-id**: `agentId` MUST name the subagent that said the message when it comes from a subagent's transcript (read only with work output), and MUST be nil for the session's own agent.
- **message-agent-id-optional**: `agentId` MUST be optional so a reader built before the field existed still decodes a message.
- **message-memberwise-init**: `ConversationMessageDTO.init(id:type:kind:content:time:agentId:)` MUST default `agentId` to nil.
- **message-from-entry**: `ConversationMessageDTO.init(entry:)` MUST copy the entry's `id` to `id`, `kind` to `kind`, `text` to `content` and `timestamp` to `time`.
- **message-from-entry-type**: `ConversationMessageDTO.init(entry:)` MUST set `type` by folding the entry's `kind` through `type(forKind:)`.
- **message-from-entry-agent**: `ConversationMessageDTO.init(entry:)` MUST leave `agentId` nil, because a feed entry carries no subagent attribution.
- **type-for-kind-prompt**: `type(forKind:)` MUST return `user` for the kind `prompt`.
- **type-for-kind-notice**: `type(forKind:)` MUST return `notice` for the kind `notice`.
- **type-for-kind-default**: `type(forKind:)` MUST return `model` for every other kind, including `reply`, `progress`, `thinking` and any kind it does not know.
- **fold-single-place**: The user / model / notice fold MUST live only in `type(forKind:)`; the doc comment on `init(entry:)` calls it "the one place the extractor's kinds fold into the user / model / notice split".
- **page-fields**: A `ConversationMessagesPageDTO` MUST carry `sessionId` (String), `messages` (array of `ConversationMessageDTO`), `nextAfterId` (optional Int) and `isComplete` (Bool).
- **page-order**: `messages` MUST be oldest first.
- **page-next-after-id**: `nextAfterId` MUST be the id to ask after for the next page: the last message's `id`, or the `afterId` the page was asked with when the page is empty, and nil when neither exists.
- **page-is-complete**: `isComplete` MUST be true when the page reached the end of the range, meaning the conversation's newest message or the `throughId` asked for.
- **page-paging-by-id**: A reader MUST page by holding the last id it fetched and asking for what comes after it; the page is not cut on time.
- **query-fields**: A `ConversationMessagesQueryDTO` MUST carry `sessionId` (String), `afterId` (optional Int), `throughId` (optional Int), `limit` (Int) and `includeWorkOutput` (Bool).
- **query-after-exclusive**: `afterId` MUST bound the range exclusively: the message with that id is not returned.
- **query-through-inclusive**: `throughId` MUST bound the range inclusively: the message with that id may be returned.
- **query-nil-cursors**: A nil `afterId` MUST open the range at the conversation's first message, and a nil `throughId` MUST end the range at the conversation's newest message.
- **query-limit**: `limit` MUST be the most messages one page returns, counted in whole transcript entries: an entry that alone holds more messages than `limit` is returned whole. The shape does not bound `limit`; the daemon's handling of a `limit` below 1 is in Edge Cases.
- **query-include-work-output**: `includeWorkOutput` MUST select whether work output (`progress` and `thinking` lines, and the session's subagent transcripts) is read; the query shape carries the flag and a producer MUST honour it.
- **range-error-case**: `ConversationRangeError` MUST have one case, `unknownMessageId(Int)`, for a cursor id that names no message of the session.
- **range-error-description**: `ConversationRangeError.unknownMessageId(id)` MUST describe itself as `No message <id> in this conversation.` through `errorDescription`.
- **range-error-equatable**: `ConversationRangeError` MUST be `Equatable` so a caller can match a thrown case.
- **conformance-protocols**: The message, page and query types MUST each be `Codable`, `Sendable` and `Equatable`; the error MUST be `Error`, `LocalizedError` and `Equatable`.
- **no-validation**: The initializers MUST NOT validate: they accept any `limit`, any `kind` string and any cursor pair; a cursor is validated only in the daemon, which raises `unknownMessageId` (see the Design Decisions).

## Appearance

Not applicable — this is a set of data shapes, not a visual component.

## States

Not applicable — this is a set of data shapes, not a visual component.

## Accessibility

Not applicable — this is a set of data shapes, not a visual component.

## Conformance Test Vectors

The shapes have no test beside them. The vectors come from the source's own logic, and from `ConversationMessagesTests` (in the database test target), which asserts these shapes as the daemon's `ConversationStore.conversationMessages` returns them.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conversation-message-dto-001 | type-for-kind-prompt | `type(forKind: "prompt")` | `user` |
| conversation-message-dto-002 | type-for-kind-notice | `type(forKind: "notice")` | `notice` |
| conversation-message-dto-003 | type-for-kind-default | `type(forKind: "reply")`, `"progress"`, `"thinking"`, `"mystery"` | `model` for each |
| conversation-message-dto-004 | message-from-entry, message-from-entry-type, message-from-entry-agent | a `ConversationEntryDTO` with id 5000, kind `reply`, text `hi`, timestamp `2026-09-01T10:00:00Z`; `init(entry:)` | id 5000, type `model`, kind `reply`, content `hi`, time `2026-09-01T10:00:00Z`, agentId nil |
| conversation-message-dto-005 | range-error-description | `ConversationRangeError.unknownMessageId(42).errorDescription` | `No message 42 in this conversation.` |
| conversation-message-dto-006 | range-error-case, range-error-equatable | a page asked after id 999999000 in a session with four messages (`testAnIdFromNowhereIsRefused`) | the thrown error equals `ConversationRangeError.unknownMessageId(999999000)` |
| conversation-message-dto-007 | page-order, message-type-values, page-is-complete, page-next-after-id | the whole four-line dialogue (`testTheWholeConversationComesBackOldestFirstWithUserAndModelTypes`) | contents `hello claude`, `hello`, `how can I help`, `thanks`; types `user`, `model`, `model`, `user`; `isComplete` true; `nextAfterId` is the last message's id |
| conversation-message-dto-008 | query-after-exclusive, query-through-inclusive | `afterId` = first message's id, `throughId` = second message's id (`testAfterIsExclusiveAndThroughIsInclusive`) | one message, `hello` |
| conversation-message-dto-009 | query-limit, page-is-complete, page-paging-by-id | `limit` 1 over four messages, then ask after the returned `nextAfterId` (`testAFullPageSaysWhereToContinue`) | first page `hello claude` with `isComplete` false; second page `hello`, `how can I help`, `thanks` with `isComplete` true |
| conversation-message-dto-010 | page-next-after-id, page-is-complete | ask after the newest message's id (`testTheNewestIdAsksForNothingMore`) | empty `messages`, `isComplete` true, `nextAfterId` equals the id asked with |
| conversation-message-dto-011 | page-next-after-id, page-is-complete | a session with no transcript lines (`testAnEmptyConversationIsCompleteAndEmpty`) | empty `messages`, `isComplete` true, `nextAfterId` nil |
| conversation-message-dto-012 | query-include-work-output | `includeWorkOutput` false, then true, over a dialogue with a progress line (`testWorkOutputIsLeftOutUnlessAskedFor`) | `looking around` absent when false, present when true |
| conversation-message-dto-013 | message-agent-id | work output over a session with one subagent transcript (`testWorkOutputWeavesInTheSubagentsTranscripts`) | `agentId` values nil for the session's own message and `a48` for the subagent's |
| conversation-message-dto-014 | message-agent-id-optional | decode a message JSON object with no `agentId` key | decodes with `agentId` nil |
| conversation-message-dto-015 | message-memberwise-init | `ConversationMessageDTO(id: 1, type: "user", kind: "prompt", content: "x", time: "t")` | `agentId` nil |

## Edge Cases

- **Empty conversation**: a session with no lines yields an empty `messages`, `isComplete` true and `nextAfterId` nil. The page MUST say so, per `testAnEmptyConversationIsCompleteAndEmpty`.
- **Cursor at the newest message**: asking after the newest id yields an empty page that is complete, with `nextAfterId` echoing the cursor asked with. This MUST hold so a follower can poll with the same id.
- **Unknown cursor id**: an `afterId` or `throughId` that names no message of the session is refused with `unknownMessageId`; it MUST NOT return an empty page. The daemon checks the transcript line the id falls in (the id divided by the block stride of 1000, per **row-identity** in Conversation Entry DTO ([adhsdk.ingredient.foundation.stenographer.conversation-entry-dto](cookbook:08d59319-de4b-438a-a144-dcf3912aa2e5)): id = line id × 1000 + block index), not the block index, so only an id whose line is absent from the session is refused.
- **Unknown kind**: a `kind` string the fold does not know maps to `model`, never to an error. This is the fold's default branch.
- **Shared timestamp**: two transcript entries with one timestamp are told apart by id, so paging stays exact; `testWalkingPageByPageGivesTheWholeConversation` walks across a shared second.
- **Cursor ordering**: ids are not ordered across a resumed session's files, so a reader MUST NOT compare ids as a measure of age or count.
- **Boundary limit**: this code does not bound `limit`; a limit of 0 or a negative value is not rejected here. The daemon's `ConversationStore.conversationMessages` raises it to 1 (`max(limit, 1)`), and an entry larger than the limit is returned whole.
- **Concurrent access**: all four types are immutable value types marked `Sendable`; there is no shared mutable state, so concurrent reads are safe.
- **Error and offline states**: these types make no network or database call; a failed read surfaces as the daemon's error, of which `ConversationRangeError` is the one case this code defines.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| afterId | Int? | none (caller supplies) | Exclusive lower cursor; nil starts at the first message. |
| throughId | Int? | none (caller supplies) | Inclusive upper cursor; nil runs to the newest message. |
| limit | Int | none (caller supplies) | Most messages per page, in whole transcript entries; the daemon raises a value below 1 to 1. |
| includeWorkOutput | Bool | none (caller supplies) | Whether `progress` and `thinking` lines and subagent transcripts are read. |
| agentId | String? | nil | Set only for a subagent's message. |

## Deep Linking

Not applicable: these shapes define no URL or deep link.

## Localization

`ConversationRangeError.errorDescription` is a hardcoded English sentence, `No message <id> in this conversation.`, with no string table; message `content` is transcript text and is not translated.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: message `content` is the user's prompts and the agent's replies, and `agentId` and `sessionId` identify the source.
- **Storage**: none here; the daemon reads the content from its transcript store.
- **Transmission**: the shapes cross the local boundary between the daemon and `steno conversation fetch`; this code opens no connection.
- **Retention**: none defined by this code.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: A follower view model binds to `messages` and keeps `nextAfterId` as its cursor; the types themselves are UI-agnostic values.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; model `agentId` and `nextAfterId` as nullable properties with a default of null so an older payload still decodes, and fold `kind` in one `when` with an else branch of `model`.
- **React/Web**: TypeScript interfaces; `agentId?: string` and `nextAfterId: number | null`; keep ids as numbers (they are Swift `Int`, 64-bit, so confirm the range is within `Number.MAX_SAFE_INTEGER`).
- **AppKit / UIKit**: The types are UI-agnostic; an AppKit or UIKit follower feeds `messages` to its list and keeps `nextAfterId` as the cursor. Swift's synthesized `Codable` decodes a missing `agentId` as nil, and the error is a `LocalizedError` enum a controller can show as is.
- **WinUI 3**: Use C# records with `System.Text.Json` (`long` for the ids, `string?` for `agentId`, `long?` for `nextAfterId`); an `Exception` subclass such as `ConversationRangeException` carrying the id and overriding `Message` to return the same sentence replaces `LocalizedError`; a `switch` expression with a discard arm models `type(forKind:)`; there is no `Sendable`, so make the records immutable (`init`-only properties); a follower page drives an `ObservableCollection` of messages while keeping the last id as its cursor.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/ConversationMessageDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A message is a separate shape from the feed entry rather than reusing `ConversationEntryDTO`.
**Rationale**: Adding project, branch and session-name attribution to every message would distort a per-session shape: a feed entry carries the attribution a merged, many-session timeline needs on every row, while a message belongs to one session and every row would repeat the same values.
**Approved**: pending

**Decision**: Paging is by message id, not by time.
**Rationale**: A time cursor cannot separate two transcript entries that share a timestamp, while a message id can, so a follower never skips or repeats a message.
**Approved**: pending

**Decision**: The user / model / notice split is a fold of the extractor's kind in `type(forKind:)`, with every unknown kind falling to `model`.
**Rationale**: Keeping the fold in one function means a new extractor kind needs no change elsewhere; the cost is that an unknown kind reads as the agent speaking.
**Approved**: pending

**Decision**: `agentId` is optional.
**Rationale**: The field was added after the first release, and an optional value lets a reader built before it still decode.
**Approved**: pending


**Decision**: The query shape validates nothing; the daemon clamps `limit` and checks cursors.
**Rationale**: Only the daemon can see the transcript, so it is the one place that can tell an unknown cursor from a valid one; validating `limit` in the shape too would put the same rule in two places that could disagree.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | Access Patterns |

separation-of-concerns passes: the file holds shapes, one pure fold and one error; reading the transcript is the daemon's `ConversationStore`. unit-test-coverage is partial: `ConversationMessageDTOConformanceTests` (`AgenticDeveloperHubSDKCoreTests/Stenographer/ConversationMessageDTOConformanceTests.swift`) tests vectors 001 to 006, 014 and 015; vectors 007 to 013 are skipped there because they need the daemon's `ConversationStore` and are covered by `ConversationMessagesTests`. pagination-support passes: the page carries `nextAfterId` and `isComplete`, and the cursor is exact across shared timestamps.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ConversationMessageDTOConformanceTests.swift, 8 of 15 vectors tested, 7 skipped); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Stated the id encoding, loosened kind to known values, gave real rationales plus a no-validation decision, fixed cursor wording, shortened the summary and linked the entry DTO. |
