---
id: d6ff4cf9-05b9-43f0-96d2-b4c8454dd6d1
title: "Partner Attention"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The value types for something the partner needs the owner to look at, and for each owner action on it kept as history."
platforms:
  - swift
  - macos
tags:
  - foundation
  - partner
  - attention
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Partner Attention

## Overview

The data shapes for the partner's attention list: something the partner needs the owner to look at (`AttentionItem`), what it asks (`AttentionKind`), where it is in its life (`AttentionState`), and one owner action on an item kept as history (`AttentionAction`, with `AttentionActionKind`). The file is Foundation only and holds values and their initializers; it has no storage, no transitions between states and no behavior beyond construction, `Codable`, `Equatable` and `Identifiable` conformance. Whatever moves an item between states, and whatever persists the items, lives outside this file.

## Behavioral Requirements

**Enumerations**

- **kind-values**: `AttentionKind` MUST be a String-backed enum with exactly the raw values `question`, `blocked` and `notification`, and MUST be `Codable`, `Sendable` and `CaseIterable`; `AttentionKind.allCases` MUST list the three kinds in declaration order. `AttentionState` and `AttentionActionKind` need not be `CaseIterable`.
- **state-values**: `AttentionState` MUST be a String-backed enum with exactly the raw values `open`, `discussing`, `sent` and `done`, and MUST be `Codable` and `Sendable`.
- **action-kind-values**: `AttentionActionKind` MUST be a String-backed enum with exactly the raw values `discuss`, `resolved`, `confirm` and `reopen`, and MUST be `Codable` and `Sendable`.

**Attention item**

- **item-fields**: `AttentionItem` MUST carry `id` (String), `kind` (`AttentionKind`), `text` (String), `reference` (a String-to-String dictionary), `state` (`AttentionState`), `createdBy` (String), `createdAt` (Date), `updatedAt` (Date) and `completedAt` (optional Date).
- **item-conformances**: `AttentionItem` MUST be `Codable`, `Sendable`, `Equatable` and `Identifiable`, with `id` as the identity.
- **item-mutable**: Every `AttentionItem` field MUST be a mutable stored property, so a holder updates an item in place.
- **item-init-required**: The `AttentionItem` initializer MUST require `kind`, `text` and `createdBy`.
- **item-init-id-default**: The `AttentionItem` initializer MUST default `id` to a fresh `UUID().uuidString`.
- **item-init-explicit**: Every `AttentionItem` initializer parameter MUST be stored exactly as passed.
- **item-init-defaults**: The `AttentionItem` initializer MUST default `reference` to an empty dictionary, `state` to `.open` and `completedAt` to `nil`.
- **item-init-dates**: The `AttentionItem` initializer MUST default both `createdAt` and `updatedAt` to the current date at the time of the call; when both default, `createdAt` and `updatedAt` MAY differ slightly.
- **item-completed-optional**: `completedAt` MUST be `nil` until a holder sets it, and an `AttentionItem` MUST NOT set it or tie it to the `done` state on its own.

**Attention action**

- **action-fields**: `AttentionAction` MUST carry `id` (String), `itemID` (String), `action` (`AttentionActionKind`), `at` (Date) and `messageID` (optional String).
- **action-conformances**: `AttentionAction` MUST be `Codable`, `Sendable`, `Equatable` and `Identifiable`, with `id` as the identity.
- **action-init-required**: The `AttentionAction` initializer MUST require `itemID` and `action`.
- **action-init-defaults**: The `AttentionAction` initializer MUST default `id` to a fresh `UUID().uuidString`, `at` to the current date and `messageID` to `nil`.
- **action-references-item-by-id**: `AttentionAction.itemID` MUST name its item by the item's `id`, and an `AttentionAction` MUST NOT check that such an item exists.

**Wire form**

- **wire-keys**: Encoding MUST use the Swift property names as JSON keys (`id`, `kind`, `text`, `reference`, `state`, `createdBy`, `createdAt`, `updatedAt`, `completedAt`; `id`, `itemID`, `action`, `at`, `messageID`), because neither type declares custom coding keys.
- **wire-enum-strings**: Each enum MUST encode as its raw String value.
- **wire-required-on-decode**: Decoding MUST fail when a non-optional field is missing, because the initializer defaults do not apply to decoding.
- **wire-optional-on-decode**: Decoding MUST accept a missing `completedAt` or `messageID` as `nil`.
- **wire-unknown-enum-fails**: Decoding MUST fail for a `kind`, `state` or `action` value outside its enum's raw values; there is no fallback case.
- **wire-dates-strategy**: An encoder and a decoder of these types MUST share one date strategy; the types set no `dateEncodingStrategy` or `dateDecodingStrategy` of their own, so each store chooses one.

## Appearance

Not applicable — these are data types, not a visual component.

## States

Not applicable — these are data types, not a visual component. `AttentionState` is a data value the item carries (specified under Behavioral Requirements), not a visual state.

## Accessibility

Not applicable — these are data types, not a visual component.

## Conformance Test Vectors

The vectors are derived from the initializers, the declared conformances and the standard `Codable` rules for the declared shapes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-attention-001 | item-init-defaults, item-init-id-default | `AttentionItem(kind: .question, text: "Ship it?", createdBy: "partner")` | `state == .open`, `reference == [:]`, `completedAt == nil`, and `id` is a non-empty UUID string |
| partner-attention-002 | item-init-id-default | Two items built with the same arguments | The two `id` values differ and the items are not equal |
| partner-attention-003 | item-init-dates | One item built with no dates | `createdAt` and `updatedAt` are both within a second of the call time |
| partner-attention-004 | item-init-explicit | `AttentionItem(id: "a", kind: .blocked, text: "t", reference: ["file": "x"], state: .discussing, createdBy: "p", createdAt: d1, updatedAt: d2, completedAt: d3)` | Every field holds exactly the value passed |
| partner-attention-005 | kind-values | `AttentionKind.allCases.map(\.rawValue)` | `["question", "blocked", "notification"]` |
| partner-attention-006 | state-values | Raw values of `.open`, `.discussing`, `.sent`, `.done` | `"open"`, `"discussing"`, `"sent"`, `"done"` |
| partner-attention-007 | action-kind-values | Raw values of `.discuss`, `.resolved`, `.confirm`, `.reopen` | `"discuss"`, `"resolved"`, `"confirm"`, `"reopen"` |
| partner-attention-008 | wire-keys, wire-enum-strings | Encode an item with `kind: .notification` and `state: .sent` | JSON object whose `kind` is `"notification"`, `state` is `"sent"` and keys include `createdBy`, `createdAt` and `updatedAt` |
| partner-attention-009 | item-conformances, wire-optional-on-decode | Encode then decode an item with `completedAt == nil` and whole-second dates, using `.iso8601` for both the encoder and the decoder (it drops sub-second precision) | The decoded item equals the original |
| partner-attention-010 | wire-required-on-decode | JSON for an item with `text` removed | Decoding throws |
| partner-attention-011 | wire-unknown-enum-fails | JSON for an item whose `state` is `"archived"` | Decoding throws |
| partner-attention-012 | action-init-defaults, action-init-required | `AttentionAction(itemID: "a", action: .confirm)` | `messageID == nil`, `at` is within a second of the call time and `id` is a fresh non-empty UUID string |
| partner-attention-013 | action-fields, wire-keys | Encode `AttentionAction(itemID: "a", action: .resolved, messageID: "m1")` | JSON keys `id`, `itemID`, `action`, `at`, `messageID`, with `action` equal to `"resolved"` |
| partner-attention-014 | wire-optional-on-decode, action-conformances | JSON for an action with no `messageID` | Decodes with `messageID == nil` |
| partner-attention-015 | item-mutable | Build an item, then set `state = .done` and `completedAt = Date()` | The item holds the new values and `updatedAt` is unchanged |
| partner-attention-016 | action-conformances, wire-dates-strategy | Encode then decode `AttentionAction(id: "x", itemID: "a", action: .confirm, at: d, messageID: "m1")` with a whole-second `d`, using `.iso8601` for both the encoder and the decoder | The decoded action equals the original |
| partner-attention-017 | wire-required-on-decode | JSON for an action with `itemID` removed, and likewise one with `action` removed and one with `at` removed | Decoding throws in each case |
## Edge Cases

- **Empty and null input**: An empty `text`, an empty `createdBy` and an empty `reference` are all accepted; the file validates nothing.
- **Duplicate ids**: Two items or two actions with the same `id` are accepted; `Identifiable` identity is then ambiguous. The caller owns uniqueness; the default `UUID().uuidString` makes a collision negligible.
- **Dangling action**: An `AttentionAction` whose `itemID` matches no item is accepted; the types do not link the two.
- **Completion date**: The types never set `completedAt` and do not tie it to the `done` state; a holder sets it.
- **Default dates**: When an item is built with no dates, `createdAt` and `updatedAt` come from two separate clock reads and may differ slightly.
- **Inconsistent timestamps**: `updatedAt` earlier than `createdAt`, or a `completedAt` on an item that is not `done`, is accepted and not corrected.
- **State changes do not touch dates**: Changing `state` does not update `updatedAt` or `completedAt`; a holder sets them.
- **Unknown enum value on the wire**: A newer writer's new `kind`, `state` or `action` raw value makes decoding of that whole item or action fail on an older reader.
- **Date strategy mismatch**: Encoding and decoding with different date strategies fails or corrupts dates; this file does not choose one.
- **Concurrent access**: All types are `Sendable` value types with no shared mutable state, so copies are safe on any thread; serialisation of updates to a shared collection is the holder's.
- **Error states and offline state**: Not applicable: the types perform no I/O and raise no errors beyond `Codable` decoding failures.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `AttentionItem.id` | String | fresh UUID string | Identity of the item. |
| `AttentionItem.reference` | `[String: String]` | `[:]` | Free-form pointers (what the item is about), opaque to this file. |
| `AttentionItem.state` | `AttentionState` | `.open` | Starting state. |
| `AttentionItem.createdAt` / `updatedAt` | Date | now | Timestamps taken at construction. |
| `AttentionItem.completedAt` | Date? | `nil` | Completion time, set by a holder. |
| `AttentionAction.id` | String | fresh UUID string | Identity of the action. |
| `AttentionAction.at` | Date | now | When the owner acted. |
| `AttentionAction.messageID` | String? | `nil` | The chat message the action relates to, if any. |

## Deep Linking

Not applicable: The file defines value types only; `reference` carries opaque strings and this code opens nothing.

## Localization

Not applicable: The file has no user-facing strings; `text` is content supplied by the caller and the enum raw values are wire identifiers.

## Accessibility Options

Not applicable: The file has no visual surface, so no Reduce Motion, Increase Contrast or Differentiate Without Color behavior exists.

## Feature Flags

Not applicable: The source reads no flag.

## Analytics

Not applicable: The source emits no analytics events.

## Privacy

- **Data collected**: Whatever the caller puts in `text`, `reference` and `createdBy`, which may include owner-facing questions about a project.
- **Storage**: None here; persistence belongs to the holder of the items.
- **Transmission**: None; the file performs no network access.
- **Retention**: None here; the file never deletes or expires an item.

## Logging

Not applicable: The source calls no logging API.

## Platform Notes

- **SwiftUI**: The source is `Core/Partner/Attention.swift` and imports only `Foundation`. All types are `public`; the structs have `var` properties with explicit public initializers and the enums are `String` raw-value enums. `Identifiable` lets items drive a `List` or `ForEach` directly.
- **Compose**: Kotlin `data class`es (`AttentionItem`, `AttentionAction`) with `@Serializable`, defaults in the primary constructor (`id = UUID.randomUUID().toString()`, `createdAt = Instant.now()`), and `enum class`es with `@SerialName` per case; use `copy` instead of in-place mutation. An unknown enum value throws `SerializationException`, matching the Swift decode failure.
- **React/Web**: TypeScript interfaces with string-literal unions for the three enums; a factory function supplies the defaults (`crypto.randomUUID()`, `new Date().toISOString()`). `JSON.parse` does not validate, so write a decoder that rejects a missing required key or an unknown enum value to match the source.
- **AppKit / UIKit**: Identical to the SwiftUI note: the types carry no UI. An `NSTableView` or `UICollectionView` diffable data source keys on the item `id`.
- **WinUI 3**: C# `record`s (or classes implementing `INotifyPropertyChanged` when edited in place) with `System.Text.Json`: `JsonStringEnumConverter` with `allowIntegerValues: false` so an unknown value throws, `required` members for the non-optional fields, `DateTimeOffset` for dates (ISO-8601 by default), `Dictionary<string, string>` for `Reference` and `Guid.NewGuid().ToString()` for the default ids. Bind a list through `ObservableCollection<AttentionItem>` in an `ItemsRepeater` or `ListView`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/Attention.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The file holds only data shapes; there is no transition logic between `AttentionState` values.
**Rationale**: The source defines the vocabulary (`open`, `discussing`, `sent`, `done` and the actions `discuss`, `resolved`, `confirm`, `reopen`) and no function maps an action to a state, so a port must not invent one from this file; the mapping belongs to whatever holds the items.
**Approved**: pending

**Decision**: Item and action ids default to a fresh UUID string and are plain Strings.
**Rationale**: Callers may supply their own ids (for example when decoding or replaying), while new items need no caller effort; a String keeps the wire form simple.
**Approved**: pending

**Decision**: Enums decode strictly, with no unknown-value fallback.
**Rationale**: This is how the source behaves, since the enums are plain raw-value enums. An older reader rejects an item carrying a value it does not know.
**Approved**: pending

**Decision**: `AttentionAction.at` is named `at` despite a short identifier.
**Rationale**: The source silences the identifier-length lint rule at the property and at the initializer parameter with a `swiftlint:disable:next identifier_name` comment, so the short name is deliberate and is part of the wire key.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

`separation-of-concerns` passes because the file holds only value types; storage, state transitions and presentation live in the macOS partner feature. `unit-test-coverage` passes because `AgenticDeveloperHubSDKCoreTests/Partner/AttentionConformanceTests.swift` has a test for each of the seventeen vectors: initializer defaults, enum raw values, wire keys, round trips and the decode failures. `data-integrity` is partial because the types validate nothing (duplicate ids, dangling `itemID` values and inconsistent timestamps are all accepted), so integrity rests on the holder.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (AttentionConformanceTests.swift, 17 of 17 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Merged kind-enumerable into kind-values, rewrote the date, completed-at and item-reference requirements as MUST/MUST NOT with the notes moved to Edge Cases, added item-init-explicit, relaxed the two-clock-read clause, added action round-trip and missing-field vectors, and named the .iso8601 strategy in vector 009. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
