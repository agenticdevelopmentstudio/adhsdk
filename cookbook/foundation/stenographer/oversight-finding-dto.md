---
id: 7d2280c6-ae67-4ecc-9aae-dbee574b1eab
title: "Oversight Finding DTO"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The read-only record of one oversight finding the Stenographer daemon recorded about a live session, shared by daemon, app and CLI."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - dto
  - wire
depends-on:
  - e8286557-84ee-4f45-b78c-f1d184c51a37
related:
  - 96f73261-cf32-42cc-92f3-f8b58542382a
  - 1088e4ae-f6ee-4174-8ba5-a913587af3be
references: []
approved-by: ""
approved-date: ""
---

# Oversight Finding DTO

## Overview

`OversightFindingDTO` is one persisted observation the AI-oversight subsystem recorded about a live Claude Code session, for example "context 88% used, compact". The daemon's observers write findings into its database; the app (over XPC) and the CLI (over HTTP `GET /oversight/findings`) read and display them. The type is a plain immutable value with twelve string or integer fields. It lives in the shared package, not in the daemon, so the daemon's database layer and the app decode the identical shape. It carries no behavior: it does not validate, normalize, order or mutate anything. The lifecycle (`pending`, `acted`, `dismissed`, `stale`) and the writes that move a finding between states belong to the daemon. The daemon serves findings as a JSON array from `GET /oversight/findings` (optionally filtered by `status`) and returns the updated finding from `POST /oversight/findings/{id}/act`; those routes are specified by the stenographer daemon service ([adhsdk.ingredient.foundation.stenographer.stenographer-daemon-service](cookbook:96f73261-cf32-42cc-92f3-f8b58542382a)). The wire spelling comes from the stenographer wire coders ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37)), and script-driven findings use the script's `id` as the observer ([adhsdk.ingredient.foundation.stenographer.oversight-script-dto](cookbook:1088e4ae-f6ee-4174-8ba5-a913587af3be)). The type does not enforce the producer rules under Field meaning (`session-id`, `model-empty-for-rule`, `reason-line`); they bind the daemon that writes findings.

## Behavioral Requirements

**Shape**

- **value-conformances**: `OversightFindingDTO` MUST be an immutable value type that is `Codable`, `Sendable` and `Equatable`.
- **field-set**: `OversightFindingDTO` MUST carry exactly these fields: `id` (Int), `sessionId`, `observer`, `kind` (String), `severity` (Int), `status`, `source`, `model`, `reason`, `detail` (String), `createdAt` and `updatedAt` (String).
- **fields-immutable**: Every field MUST be read-only after construction; the type MUST NOT expose a mutating member.
- **init-all-fields**: The public initializer MUST take all twelve fields in the order `id`, `sessionId`, `observer`, `kind`, `severity`, `status`, `source`, `model`, `reason`, `detail`, `createdAt`, `updatedAt`, and MUST NOT give any of them a default value.
- **no-identifiable**: The type MUST NOT declare `Identifiable`; a consumer that needs row identity keys on `id` itself.

**Field meaning**

- **session-id**: The producer (the daemon) MUST set `sessionId` to the session the finding is about. The DTO does not enforce this.
- **observer-namespace**: `observer` MUST name the observer that produced the finding (example in the source: `"context"`) and namespaces the finding. For a script-driven finding the daemon uses the script's `id` as the observer, as the OversightScript doc comment states.
- **kind-dispatch**: `kind` MUST be the actionable category an actor can dispatch on (example in the source: `"compact"`).
- **severity-hint**: `severity` MUST be an Int described as a coarse 0 to 100 urgency and an ordering hint; the type MUST NOT clamp or reject a value outside that range.
- **status-lifecycle**: `status` MUST be a free String documented to take one of `pending`, `acted`, `dismissed` or `stale`; the type MUST NOT be an enum and MUST NOT reject another spelling.
- **source-values**: `source` MUST be a free String documented to take `rule` or `llm`; the type MUST NOT reject another spelling.
- **model-empty-for-rule**: The producer (the daemon) MUST set `model` to the model behind an `llm`-sourced finding and to the empty string for a `rule` finding. The DTO does not enforce this; it carries whatever string it is given.
- **reason-line**: The producer (the daemon) MUST set `reason` to one human-readable line explaining the finding. The DTO does not enforce this.
- **detail-opaque**: `detail` MUST be an opaque string documented as an optional JSON blob of extra structured context, empty when there is none; the type MUST NOT parse it.
- **timestamps-opaque**: `createdAt` and `updatedAt` MUST be carried as the strings the daemon stored; the type MUST NOT parse, reformat or compare them.

**Wire**

- **wire-spelling**: The finding MUST travel in the stenographer-wide wire spelling (snake_case keys through the shared `StenographerWire` encoder and decoder), so the fields appear as `id`, `session_id`, `observer`, `kind`, `severity`, `status`, `source`, `model`, `reason`, `detail`, `created_at` and `updated_at`.
- **decode-strict**: Decoding MUST fail when any of the twelve keys is missing; the type has no hand-written decoder and no key is optional.
- **decode-lenient-values**: Decoding MUST accept any String for `status` and `source`, and MUST accept the empty string for every string field.
- **equality-all-fields**: Two findings MUST compare equal exactly when all twelve fields are equal.
- **read-only-for-clients**: A client MUST treat a finding as read-only; the daemon is the only writer, and a client changes a finding's state only by calling the daemon's act operation.

**Delivery**

- **ordering-owner**: The type MUST NOT impose an order. Ordering and row caps belong to the daemon routes spec.

## Appearance

Not applicable — this is a non-visual data transfer object, not a visual component.

## States

Not applicable — this is a non-visual data transfer object, not a visual component. The finding lifecycle is a field value (`status`), not a visual state.

## Accessibility

Not applicable — this is a non-visual data transfer object, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| oversight-finding-dto-001 | field-set, init-all-fields | Construct with id 1, sessionId `abcdefgh-1234-5678`, observer `context`, kind `compact`, severity 88, status `pending`, source `rule`, model empty, reason `Context 88% used`, detail empty, createdAt and updatedAt `2026-01-01T00:00:00Z` | Every field reads back as given (provenance: `OversightFindingsListSourceTests` `testCellsMapsShortSessionAndKeepsFields` constructs this value) |
| oversight-finding-dto-002 | model-empty-for-rule, detail-opaque | Construct a rule finding with model `""` and detail `""` | Both fields are the empty string; nothing substitutes a placeholder |
| oversight-finding-dto-003 | severity-hint, decode-lenient-values | Construct with severity 0 and every string field empty | severity stays 0 and no field is rejected; every string field holds the empty string (provenance: `testCellsUsesDashForEmptyFields`) |
| oversight-finding-dto-004 | severity-hint | Construct with severity 250 | severity is 250; the type does not clamp |
| oversight-finding-dto-005 | wire-spelling | Encode a finding with the wire encoder | The JSON object has the keys `id`, `session_id`, `observer`, `kind`, `severity`, `status`, `source`, `model`, `reason`, `detail`, `created_at`, `updated_at` |
| oversight-finding-dto-006 | wire-spelling, equality-all-fields | Encode then decode a finding with the wire encoder and decoder | The decoded value equals the original |
| oversight-finding-dto-007 | decode-strict | Decode the body `{"id":7,"session_id":"s","observer":"compact","kind":"k","severity":1,"status":"acted","reason":"r","created_at":"2026-10-12T00:00:00Z"}` (the body in StenographerHTTPClientTests `testActOnFindingSuccess`) | Decoding throws because `model`, `detail` and `updated_at` are absent (provenance: the HTTP client's `try?` then yields no finding; that fallback is the client's behavior, not the DTO's). Known test gap: because this fixture cannot decode, `testActOnFindingSuccess` never covers an act reply that decodes into a finding; vector 012 covers that case |
| oversight-finding-dto-008 | decode-lenient-values, status-lifecycle | Decode a full body with status `reopened` and source `human` | Decoding succeeds and the strings are kept as given |
| oversight-finding-dto-009 | equality-all-fields | Two findings identical except status `pending` versus `acted` | They are not equal |
| oversight-finding-dto-010 | timestamps-opaque | Decode a body with created_at `2026-11-14 09:30:00` (the SQLite `datetime` form the daemon column holds) | The string is kept verbatim; no date parsing occurs |
| oversight-finding-dto-011 | decode-strict | Decode a full body that has all twelve keys except `"model": null` | Decoding throws; JSON `null` is not accepted for a string key |
| oversight-finding-dto-012 | decode-strict, wire-spelling | Decode a full act reply with all twelve snake_case keys present (for example `{"id":7,"session_id":"s","observer":"compact","kind":"k","severity":1,"status":"acted","source":"rule","model":"","reason":"r","detail":"","created_at":"2026-10-12T00:00:00Z","updated_at":"2026-10-12T00:00:00Z"}`) | Decoding succeeds and each field holds the given value |

## Edge Cases

- **Null and empty input**: Every string field MAY be empty (MUST be accepted); `model` and `detail` are empty for a rule finding with no extra context. JSON `null` for any of the twelve keys is not accepted: decoding MUST fail, as for a missing key.
- **Boundary values**: `severity` of 0 and of any Int is accepted with no clamp (MUST); the 0 to 100 range is documentation, not enforcement. `id` is the daemon's autoincrement integer.
- **Concurrent access**: The value is immutable and `Sendable`, so it MAY be shared across threads and actors without synchronization. Concurrent writes to the underlying finding (a double-submit of act, a dismiss racing an act) are resolved by the daemon, which guards the `acted` update on `pending`; the DTO takes no part.
- **Error states**: A body that fails decoding is dropped by the client: the HTTP client reads a list that does not decode as an unreachable daemon (nil), and reads a single act reply that does not decode as no finding, falling back to status `acted` (MUST, per the client). The DTO raises the decoding error; it never swallows it.
- **Offline or disconnected state**: Not applicable: the type performs no I/O. The client that fetches it returns nil when the daemon is unreachable.
- **Unknown values**: An unknown `status` or `source` spelling from a newer daemon decodes without error (MUST); a consumer that switches on `status` needs its own default branch.
- **Stale findings**: A `stale` finding is still returned when no status filter is sent; filtering is the daemon's job, not the type's.

## Configuration
Not applicable: the type has no configuration options. The initializer takes every field with no defaults (see init-all-fields), and the wire coding is fixed by wire-spelling.
## Deep Linking

Not applicable: this type defines no URL or deep link; the only routes in play (`GET /oversight/findings`, `POST /oversight/findings/{id}/act`) are daemon API routes, not app links.

## Localization

Not applicable: the type holds no user-facing literal. `reason` is a human-readable line the daemon writes (in the source's examples, English) and the type carries it without translating it.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag. Whether findings are produced at all is a daemon setting outside this type.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: `sessionId`, `reason` and `detail` describe a user's live coding session and may name projects or contain structured context.
- **Storage**: The type stores nothing; the daemon persists findings in its own database.
- **Transmission**: Over XPC to the app and over HTTP on the daemon's loopback address (`http://127.0.0.1:22847` by default) to the CLI and app.
- **Retention**: Not set by this type; the daemon's findings table owns it.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: The source is plain Swift with no view code. A SwiftUI list over findings must supply `id: \.id` because the type is not `Identifiable`. Render `status` and `kind` from the strings with a default branch for unknown values.
- **Compose**: A Kotlin `data class` with `kotlinx.serialization`, `@SerialName` snake_case for the multiword keys, and no default values so a missing key fails as in the source. Keep `status` and `source` as `String`, not enums, to keep unknown values decodable.
- **React/Web**: A TypeScript interface with snake_case keys exactly as listed under wire-spelling. Do not rename to camelCase unless a mapping layer sits at the boundary; treat timestamps as opaque strings.
- **AppKit / UIKit**: Foundation-only, `public struct` with a public memberwise initializer written out by hand. The macOS AI Oversight table maps one finding to cells in `OversightFindingsListSource` (a short session id, a dash for empty fields).
- **WinUI 3**: Use a C# `record` (for example `OversightFindingDto`) with `init`-only properties and `required` members so `System.Text.Json` fails on a missing key as the source does, and set `JsonNamingPolicy.SnakeCaseLower` on `JsonSerializerOptions` for the key spelling. Read with `HttpClient.GetFromJsonAsync` against the daemon's loopback URL. Keep `CreatedAt` and `UpdatedAt` as `string`, not `DateTimeOffset`, because the daemon's SQLite form has no zone. Bind a `ListView` to an `ObservableCollection` of the record with an `x:Bind` DataTemplate; because the record is immutable, replace the item in the collection when a finding changes rather than mutating it, and use the `Id` property for item identity.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/OversightFindingDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `status` and `source` are plain strings on the DTO, although the daemon has `FindingStatus` and `FindingSource` enums and a database CHECK constraint on status.
**Rationale**: A string keeps the wire forward compatible: an older client decodes a finding from a newer daemon instead of failing the whole list. The cost is that a client switching on status needs a default branch.
**Approved**: pending

**Decision**: All twelve keys are required on decode; there is no tolerant decoder as on the session DTO.
**Rationale**: The doc comment says the daemon's database layer and the app decode the identical shape, and the app, daemon and CLI ship together. The cost shows in the HTTP client's act path, which expects the full body and otherwise falls back to status `acted`.
**Approved**: pending

**Decision**: `severity` is documented as 0 to 100 but is neither clamped nor validated by the DTO.
**Rationale**: It is an ordering hint; the script observer builds every finding in the source, including script-driven ones whose observer is the script's `id`, and passes the session's context-used percentage as severity, which is already a percentage. A future producer would set its own severity.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | Privacy and Data |

separation-of-concerns passes: the file declares the value and nothing else; storage, the lifecycle writes, ordering and transport all live in the daemon database, its routes and the HTTP client. unit-test-coverage passes: `OversightFindingDTOConformanceTests` has one test for each of vectors 001 to 012, including the direct encode and decode ones. secure-data-storage passes because the type stores nothing and its transport is XPC or the loopback address.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (OversightFindingDTOConformanceTests.swift, 12 of 12 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Producer-only rules restated as daemon obligations, delivery routes moved to a link to the daemon spec, vectors 011 (null key) and 012 (full act reply) added, stale DatabaseManager decision and source path dropped, depends-on and related linked. |
