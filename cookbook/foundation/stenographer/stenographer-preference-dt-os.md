---
id: eaa5d7f1-c35d-4fe6-91a0-06b6e48b8ba2
title: "Stenographer Preference DTOs"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The request and response bodies of the daemon's oversight and summary preference routes: partial-update requests with optional fields, and full-state responses."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - preferences
  - dto
depends-on:
  - e8286557-84ee-4f45-b78c-f1d184c51a37
related:
  - 9c7c78d3-23ca-4ca6-a519-9968b440b8c6
  - 844fde57-2231-4516-bcc9-a93c56d74a2d
references: []
approved-by: ""
approved-date: ""
---

# Stenographer Preference DTOs

## Overview

The source is `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerPreferenceDTOs.swift`, which imports only `Foundation`. It holds four `public struct` types with synthesized `Codable`, a hand-written public initializer each, and a `var` property for each request field so a caller can set only what it wants to change. They carry the daemon's two preference groups across the wire. `OversightPreferenceRequest` and `OversightPreferenceResponse` are the body and reply of `POST /preferences/oversight` and the reply of `GET /preferences/oversight`. `SummaryPreferenceRequest` and `SummaryPreferenceResponse` are the body and reply of `POST /preferences/summaries` and the reply of `GET /preferences/summaries`.

A request is a partial update: every field is optional, and the daemon reads an omitted field as "leave the stored value alone" (that is the daemon's rule, the HTTP client recipe, [adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6), covers the routes that carry it; the snapshot push always sends all of them). A response is the full state the daemon runs with. They are encoded and decoded in the `StenographerWire` spelling ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37): snake_case keys), so Swift's `maxWords` travels as `max_words`.

`SummaryPreferenceRequest.enabled` and `selectedConfigId` are the summaries switch and provider choice, owned by the app that hosts the summaries pane; the remaining fields are tuning knobs whose accepted ranges are `SummaryLimits` ([adhsdk.ingredient.foundation.stenographer.summary-preference-dt-os](cookbook:844fde57-2231-4516-bcc9-a93c56d74a2d)).
## Behavioral Requirements

- **codable-sendable**: All four types MUST conform to `Codable` and `Sendable`, and the two responses MUST also conform to `Equatable`; the requests are not `Equatable`.
- **oversight-request-fields**: `OversightPreferenceRequest` MUST carry the optional fields `enabled` (Bool), `contextThresholdPct` (Int), `llmEnabled` (Bool), `selectedConfigId` (String) and `model` (String), all variables, all defaulting to nil in its initializer.
- **oversight-response-fields**: `OversightPreferenceResponse` MUST carry the non-optional constants `enabled` (Bool), `contextThresholdPct` (Int), `llmEnabled` (Bool), `selectedConfigId` (String) and `model` (String), all supplied to its initializer.
- **summary-request-fields**: `SummaryPreferenceRequest` MUST carry the optional fields `enabled` (Bool), `selectedConfigId` (String), `prompt` (String), `maxWords`, `activityLines`, `detailChars`, `intervalMinutes`, `maxPerRun` and `timeoutSeconds` (all Int), all variables, all defaulting to nil in its initializer.
- **summary-response-fields**: `SummaryPreferenceResponse` MUST carry `enabled` (Bool, optional), `selectedConfigId` (String, optional), `prompt` (String) and the non-optional Ints `maxWords`, `activityLines`, `detailChars`, `intervalMinutes`, `maxPerRun` and `timeoutSeconds`, all constants and all supplied to its initializer (the two optional fields are supplied as `nil` or a value).
- **omitted-means-unchanged**: A request field that is nil MUST be absent from the encoded body. (What the daemon does with an absent field is the daemon's rule and is described in the Overview.)
- **tuning-not-clamped**: The initializers and the decoders MUST NOT clamp or validate any value; the daemon clamps the tuning values through `SummaryLimits`, and the reply carries the stored result.
- **older-daemon-tolerance**: `SummaryPreferenceResponse` MUST decode when `enabled` and `selected_config_id` are absent, leaving both nil, because older daemons (before the toolkit's shared daemon core) returned neither and a missing field must not make the whole reply undecodable.
- **other-fields-required**: `SummaryPreferenceResponse` and `OversightPreferenceResponse` MUST fail to decode when any non-optional field is absent, including `prompt` on the summary response.
- **response-equality**: The two responses MUST compare equal when every field is equal, so a caller can tell whether a pushed value came back unchanged.
- **wire-spelling**: The types MUST be encoded and decoded with `StenographerWire` coders; they declare no `CodingKeys`, and their property names have no acronym runs, so the snake_case conversion round-trips.
- **public-initializers**: Each type MUST expose a public memberwise initializer, because the synthesized one is not public.

## Appearance

Not applicable — these are data-transfer types, not visual components.

## States

Not applicable — these are data-transfer types, not visual components.

## Accessibility

Not applicable — these are data-transfer types, not visual components.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stenographer-preference-dt-os-001 | omitted-means-unchanged, wire-spelling | Encode a `SummaryPreferenceRequest` with `enabled` false, `selectedConfigId` `abc` and `maxWords` 12. | Keys `enabled` (false), `selected_config_id` (`abc`) and `max_words` (12); `prompt` is absent (test: testSummaryRequestEncodesSnakeCaseAndOmitsNils). |
| stenographer-preference-dt-os-002 | summary-response-fields, wire-spelling | Decode a snake_case body with all keys, `enabled` true and `selected_config_id` empty. | A `SummaryPreferenceResponse` equal to one built with the same values, `selectedConfigId` `""` (test: testSummaryResponseDecodesSnakeCase). |
| stenographer-preference-dt-os-003 | older-daemon-tolerance | Decode a body without `enabled` and `selected_config_id`. | Decodes; `enabled` and `selectedConfigId` are nil; `maxWords` 8 and `timeoutSeconds` 60 (test: testSummaryResponseFromAnOlderDaemonDecodesWithoutEnabledOrSelection). |
| stenographer-preference-dt-os-004 | oversight-response-fields, response-equality | Encode and decode an `OversightPreferenceResponse` with `enabled` true, `contextThresholdPct` 80, `llmEnabled` false, `selectedConfigId` `claude-cli`, `model` empty. | The decoded value equals the original (test: testOversightRoundTrip). |
| stenographer-preference-dt-os-005 | other-fields-required | Decode a summary reply missing `max_words`. | Throws a `DecodingError` (derived from the source; no test). |
| stenographer-preference-dt-os-006 | oversight-request-fields, omitted-means-unchanged | Encode `OversightPreferenceRequest()` with no values set. | The empty object `{}` (derived from the source; no test). |
| stenographer-preference-dt-os-007 | oversight-request-fields, wire-spelling | Encode `OversightPreferenceRequest(enabled: true, contextThresholdPct: 75)`. | Keys `enabled` true and `context_threshold_pct` 75 only (derived from the source; no test). |
| stenographer-preference-dt-os-008 | other-fields-required | Decode an oversight reply missing `model`. | Throws a `DecodingError` (derived from the source; no test). |
| stenographer-preference-dt-os-009 | summary-request-fields | Build `SummaryPreferenceRequest()` and read each property. | All nine properties are nil (derived from the source; no test). |
| stenographer-preference-dt-os-010 | wire-spelling | Decode a snake_case oversight reply with an extra key `future_field`. | Decodes; the unknown key is ignored (derived from the source; no test). |
| stenographer-preference-dt-os-011 | codable-sendable | Encode and decode each of the four types, and compare two equal responses. | All four round-trip; the two responses compare equal and a differing field makes them unequal (derived from the source; no test). |
| stenographer-preference-dt-os-012 | public-initializers | From another module, build each of the four types with its initializer. | Each compiles and sets its fields (derived from the source; no test). |
| stenographer-preference-dt-os-013 | tuning-not-clamped | `SummaryPreferenceRequest(maxWords: 1000)` encoded, and a reply body with `max_words` 1000 decoded. | `max_words` 1000 is encoded, and `maxWords` is 1000 after decoding (derived from the source; no test). |
| stenographer-preference-dt-os-014 | other-fields-required | Decode a summary reply missing `prompt`. | Throws a `DecodingError` (derived from the source; no test). |
## Edge Cases

- **Null / empty input**: A request with no field set encodes to an empty object, which the daemon reads as "change nothing". An empty `prompt` or `selectedConfigId` is a value, not an omission, and is sent as an empty string (vector 002 shows an empty `selected_config_id` decoding as `""`, not nil).
- **Boundary values**: The Int fields carry no range check here; `contextThresholdPct`, `maxWords`, `activityLines`, `detailChars`, `intervalMinutes`, `maxPerRun` and `timeoutSeconds` are clamped by the daemon, so a value sent outside its range comes back changed in the reply. The summary ranges are `SummaryLimits` (in the sibling `SummaryPreferenceDTOs.swift`, described by the `SummaryLimits` recipe): `maxWords` 4...20, `activityLines` 10...400, `detailChars` 40...500, `intervalMinutes` 1...240, `maxPerRun` 1...50, `timeoutSeconds` 10...600. The daemon's `PreferencesService.setOversight` (in `PreferencesService.swift`) clamps `contextThresholdPct` to 1...100.
- **Concurrent access**: The types are `Sendable` value types with no shared state, so they may be created and read from any task. Two simultaneous pushes are ordered by the daemon, not by these types.
- **Error states**: A reply with a missing non-optional field, a wrong type or a non-JSON body fails to decode; the HTTP client's getters return nil and its setters return `false`, the same result as an unreachable daemon or a non-2xx status. The only tolerated absence is `enabled` and `selected_config_id` on the summary response.
- **Offline / disconnected state**: Not applicable: the types perform no network access; the HTTP client owns it.
- **Version skew**: A newer daemon that adds fields to a reply is tolerated because the decoder ignores unknown keys; an older daemon that lacks `enabled` or `selected_config_id` is tolerated as above, but one that lacks any other field makes the reply undecodable.

## Configuration

Not applicable: the types take their values from the caller and read no environment variable or settings key; the defaults are nil for every request field.

## Deep Linking

Not applicable: the types define no URL scheme or route; the route paths are owned by the HTTP client.

## Localization

Not applicable: the types define no user-facing string; `prompt` is user-supplied text passed through.

## Accessibility Options

Not applicable: the types present no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference; `enabled` and `llmEnabled` are preference values, not flags.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Preference values, including the user's summary `prompt` text and the identifier of the selected provider configuration; no credential or secret appears in these types (provider secrets travel in a different type).
- **Storage**: None here; the daemon stores the values.
- **Transmission**: Sent to the local daemon over the loopback HTTP route by the HTTP client.
- **Retention**: Not applicable: the types keep nothing; the daemon owns retention.

## Logging

Not applicable: the types call no logging API.

## Platform Notes

- **SwiftUI**: Bind each settings control to a property of an `ObservableObject` or `@Observable` view model, build a request from only the controls the user changed, and show the response (the daemon's clamped result) back in the controls after a push.
- **Compose**: Use Kotlin `data class` types with `@Serializable`, nullable properties defaulting to null for the requests and `explicitNulls = false` so omitted fields stay omitted, and `ignoreUnknownKeys = true` because kotlinx.serialization rejects unknown keys by default, which would break the newer-daemon tolerance in Version skew. Make the two nullable response fields default to null so an older daemon's reply decodes.
- **React/Web**: Use TypeScript interfaces with optional properties for requests and a required shape for responses with `enabled?` and `selectedConfigId?` optional; omit `undefined` keys when serializing, and convert keys with the key-mapping functions of the `StenographerWire` recipe.
- **AppKit / UIKit**: The preference panes on macOS build a request from the control values and push it through the HTTP client.
- **WinUI 3**: Use C# `record` types with `System.Text.Json` and `JsonNamingPolicy.SnakeCaseLower`, nullable properties (`bool?`, `int?`, `string?`) on the request records with `JsonIgnoreCondition.WhenWritingNull`, and init-only properties on the response records (`record` value equality replaces `Equatable`). Mark the two optional summary response fields nullable and leave the others `required` so a missing field throws a `JsonException`, matching the source. A settings page binds to an `INotifyPropertyChanged` view model that copies into a request on save.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerPreferenceDTOs.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Request fields are all optional, and an omitted field leaves the stored value alone.
**Rationale**: A partial update lets each app push only the fields it owns, so one app does not overwrite a value another app set; the snapshot push sends all of them when it wants a full write. The alternative, a full-state request, would force every caller to read the stored values first.
**Approved**: pending

**Decision**: `SummaryPreferenceResponse.enabled` and `selectedConfigId` are optional.
**Rationale**: The doc comment on `SummaryPreferenceResponse` in `StenographerPreferenceDTOs.swift` states that older daemons did not return them, and a missing field must not make the whole reply undecodable. Making every field optional would also tolerate those daemons, but it would hide a genuinely malformed reply.
**Approved**: pending

**Decision**: The DTOs do not clamp tuning values.
**Rationale**: The daemon is the single owner of the ranges (`SummaryLimits`), so a second copy of the clamp here could drift from it; a value sent out of range comes back changed in the reply, which the caller can see.
**Approved**: pending

**Decision**: Requests are not `Equatable`; responses are.
**Rationale**: A response is the stored state a caller compares to see whether a pushed value came back unchanged, while a request is a transient update nobody needs to compare.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the types only hold values; routes, coding strategy and clamping belong to the HTTP client, `StenographerWire` and the daemon. `unit-test-coverage` is partial because `StenographerPreferenceDTOsTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/StenographerPreferenceDTOsTests.swift`) covers every vector except stenographer-preference-dt-os-012 (public initializers used from another module), which is skipped: the test target imports the module with `@testable`, so a unit test cannot show that the initializers are public.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (StenographerPreferenceDTOsTests.swift, 13 of 14 vectors, 012 skipped: @testable import cannot prove public initializers); unit-test-coverage now partial. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Moved daemon semantics out of the requirements, linked the wire, HTTP client and summary limits specs, wrote real rationales, added four vectors, and rewrote the platform notes. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
