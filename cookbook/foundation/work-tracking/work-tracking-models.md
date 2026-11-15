---
id: aa775836-5679-4a22-9ff3-b2bdcb09cc20
title: "Work Tracking Models"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Value types for work tracking: the preferences, the daemon status, the list-failure wire row, the settings keys and the span-to-session id mapping."
platforms:
  - swift
  - macos
tags:
  - work-tracking
  - foundation
  - models
depends-on:
  - ed610aa4-2717-4242-a8b9-c4616377dbd9
  - 92a9546a-eec1-47ed-8420-7db51e8d0261
related:
  - a6b177ee-dc1e-441d-9844-eee2ef48ed8d
  - d525cc69-4d2c-4d17-a570-f71e8d5aa273
  - ba4dcadb-1225-4bcc-afca-bbb617e6e6c9
  - f3f1af27-6cd7-4b3f-9024-135c6f6e89da
  - 02cfb457-46da-4814-a1de-8962533ad78e
references: []
approved-by: ""
approved-date: ""
---

# Work Tracking Models

## Overview

The value types the app and the daemon share for work tracking, the feature that records which allowlisted development app has focus. They are `WorkTrackingPreferences` (what the user chose), `WorkTrackingAccessibility` and `WorkTrackingStatus` (what the daemon reports), `WorkTrackingWire` (how a failed list read replies), `WorkTrackingSettingsKeys` (the daemon's `settings` table keys) and `ActivitySpanSession` (the billing session id of an app span). The file is pure data and pure functions with no I/O. Persistence, transport and recording live in sibling types in the same directory.

## Behavioral Requirements

- **preferences-shape**: `WorkTrackingPreferences` MUST carry `enabled: Bool`, `addedBundleIds: [String]`, `removedBundleIds: [String]` and `retentionDays: Int`, and MUST be `Codable`, `Sendable` and `Equatable`.
- **preferences-default**: `WorkTrackingPreferences.default` MUST be disabled, with empty `addedBundleIds` and `removedBundleIds`, and `retentionDays` equal to `defaultRetentionDays`.
- **default-retention-days**: `WorkTrackingPreferences.defaultRetentionDays` MUST be 90.
- **retention-range**: `WorkTrackingPreferences.retentionDaysRange` MUST be 7 through 3650 inclusive.
- **normalized-id-order**: `normalized()` MUST return `addedBundleIds` and `removedBundleIds` each de-duplicated and sorted ascending.
- **normalized-retention-clamp**: `normalized()` MUST clamp `retentionDays` into `retentionDaysRange`, using `BillingLimits.clamp`.
- **normalized-enabled-unchanged**: `normalized()` MUST return `enabled` unchanged.
- **normalized-pure**: `normalized()` MUST return a new value and MUST NOT mutate the receiver.
- **init-no-validation**: The `WorkTrackingPreferences` initializer MUST store its arguments as given and MUST NOT sort, de-duplicate or clamp. Only `normalized()` does.
- **accessibility-cases**: `WorkTrackingAccessibility` MUST have exactly the cases `granted`, `denied` and `unknown`, with `String` raw values equal to the case names.
- **status-shape**: `WorkTrackingStatus` MUST carry `enabled`, `accessibility`, `currentSpan: ActivitySpanDTO?`, `writeFailures: Int` and `lastError: String?`, and MUST be `Codable`, `Sendable` and `Equatable`.
- **status-defaults**: The `WorkTrackingStatus` initializer MUST default to `enabled` false, `accessibility` `.unknown`, `currentSpan` nil, `writeFailures` 0 and `lastError` nil.
- **status-degraded**: `isDegraded` MUST be true exactly when `enabled` is true and `accessibility` is not `.granted`.
- **degraded-notice**: `WorkTrackingStatus.degradedNotice` MUST be the string `Tracking without Accessibility — time is unassigned.`.
- **wire-read-failed-key**: `WorkTrackingWire.readFailedKey` MUST be `work_tracking_read_failed`.
- **wire-read-failed-row**: `WorkTrackingWire.readFailedRow` MUST be the UTF-8 bytes of `{"work_tracking_read_failed":true}`. A failed list read replies with a one-element list holding this row, the same convention as `BillingWire.readFailedRow`.
- **settings-keys**: `WorkTrackingSettingsKeys` MUST name the daemon settings keys `activity_enabled`, `activity_added_bundle_ids`, `activity_removed_bundle_ids`, `activity_retention_days`, `activity_ax_last_status` and `activity_ax_signer`. The two bundle-id keys hold JSON arrays. Each is a static member of `WorkTrackingSettingsKeys`: `enabled` is `activity_enabled`, `addedBundleIds` is `activity_added_bundle_ids`, `removedBundleIds` is `activity_removed_bundle_ids`, `retentionDays` is `activity_retention_days`, `accessibilityLastStatus` is `activity_ax_last_status` and `accessibilitySigner` is `activity_ax_signer`. `activity_ax_signer` holds the designated requirement that `activity_ax_last_status` was answered under.
- **session-prefix**: `ActivitySpanSession.prefix` MUST be `app:`.
- **session-id-from-span**: `ActivitySpanSession.sessionId(spanId:)` MUST return the prefix followed by the span id.
- **span-id-from-session**: `ActivitySpanSession.spanId(sessionId:)` MUST return the text after the prefix when the session id starts with `app:`, and nil otherwise.
- **concurrency**: Every type in the file is a value type or a namespace enum. The structs and `WorkTrackingAccessibility` are `Sendable`. The namespace enums hold only constants and pure functions, so there is no shared mutable state.
- **errors**: No operation in the file throws. A failed list read is expressed as data through `WorkTrackingWire`, not as an error.
- **side-effects**: The file performs no file, network, process or notification effect.

## Appearance

Not applicable — this is a set of data models, not a visual component.

## States

Not applicable — this is a set of data models, not a visual component.

## Accessibility

Not applicable — this is a set of data models, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-models-001 | normalized-id-order, normalized-retention-clamp | `normalized()` on enabled preferences with added `["b","a","b"]`, removed `["z","z"]`, retentionDays 1 (test `testNormalizedSortsDedupsAndClamps`) | added `["a","b"]`, removed `["z"]`, retentionDays 7 |
| work-tracking-models-002 | normalized-retention-clamp | `normalized()` with retentionDays 99999 (same test) | retentionDays 3650 |
| work-tracking-models-003 | session-id-from-span | `ActivitySpanSession.sessionId(spanId: "X")` (test `testSpanSessionIdRoundTrips`) | `app:X` |
| work-tracking-models-004 | span-id-from-session | `spanId(sessionId: "app:X")` (same test) | `X` |
| work-tracking-models-005 | span-id-from-session | `spanId(sessionId: "claude-session")` (same test) | nil |
| work-tracking-models-006 | status-degraded | `WorkTrackingStatus(enabled: false, accessibility: .denied).isDegraded` (test `testDegradedOnlyWhenEnabledWithoutGrant`) | false |
| work-tracking-models-007 | status-degraded | enabled true with `.denied`, then enabled true with `.unknown` (same test) | true for both |
| work-tracking-models-008 | status-degraded | enabled true with `.granted` (same test) | false |
| work-tracking-models-009 | status-shape | A status with a `currentSpan`, `writeFailures` 2 and `lastError` `disk full`, encoded with snake-case keys and decoded with the matching strategy (test `testStatusRoundTripsSnakeCase`) | The decoded value equals the original |
| work-tracking-models-010 | preferences-default, default-retention-days | `WorkTrackingPreferences.default` | enabled false, both id lists empty, retentionDays 90 |
| work-tracking-models-011 | init-no-validation | `WorkTrackingPreferences(enabled: true, addedBundleIds: ["b","a","b"], removedBundleIds: [], retentionDays: 1)` | Fields stored exactly as given, with no sorting or clamping |
| work-tracking-models-012 | wire-read-failed-row, wire-read-failed-key | `String(decoding: WorkTrackingWire.readFailedRow, as: UTF8.self)` | `{"work_tracking_read_failed":true}` |
| work-tracking-models-013 | settings-keys | `WorkTrackingSettingsKeys.retentionDays` and `.accessibilitySigner` | `activity_retention_days` and `activity_ax_signer` |
| work-tracking-models-014 | status-defaults | `WorkTrackingStatus()` | enabled false, accessibility `.unknown`, currentSpan nil, writeFailures 0, lastError nil |

Vectors 010 to 014 are derived from the source and are tested in `WorkTrackingModelsTests` (`testV10_` to `testV14_`), including one that pins the exact bytes of `WorkTrackingWire.readFailedRow` for vector 012.
## Edge Cases

- **Empty id lists** (MUST): `normalized()` on empty `addedBundleIds` and `removedBundleIds` returns them empty.
- **Retention at the bounds** (MUST): 7 and 3650 are returned unchanged by `normalized()`. Values below 7 become 7 and values above 3650 become 3650. A negative value becomes 7.
- **An id in both lists** (MUST): `normalized()` keeps it in both. The source does not reconcile `addedBundleIds` against `removedBundleIds`. The layer that applies them owns that rule.
- **Empty or non-prefixed session id** (MUST): `spanId(sessionId:)` returns nil for an empty string and for any id without the `app:` prefix. For exactly `app:` it returns the empty string.
- **Span id that contains the prefix** (MUST): `spanId(sessionId: "app:app:X")` returns `app:X`, because only the first prefix is dropped.
- **Concurrent access**: not a concern in the file. The types are immutable-by-copy values, and the only mutation is on a caller's own variable.
- **Error states**: not applicable to the models. Nothing throws, and the failure signal for a list read is `WorkTrackingWire.readFailedRow`.
- **Offline or disconnected state**: not applicable to the models. The transport that carries them is a sibling type, not this file.
- **Malformed input** (SHOULD): the file does not parse text itself. Decoding a `WorkTrackingStatus` with an unknown `accessibility` string fails in the caller's `Decoder`, as the raw-value enum gives it no fallback.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `WorkTrackingPreferences.defaultRetentionDays` | `Int` | 90 | Retention the default preferences carry |
| `WorkTrackingPreferences.retentionDaysRange` | `ClosedRange<Int>` | 7...3650 | Bounds `normalized()` clamps retention into |
| `WorkTrackingStatus.degradedNotice` | `String` | `Tracking without Accessibility — time is unassigned.` | Sentence shown while tracking runs without Accessibility |
| `ActivitySpanSession.prefix` | `String` | `app:` | Prefix of a billing session id made by an app span |
| Hard dependency | `BillingLimits.clamp` | n/a | The static clamp helper `normalized()` calls directly, from the billing DTOs; nothing is injected |

## Deep Linking

Not applicable: the models define no URLs and no routes.

## Localization

`WorkTrackingStatus.degradedNotice` is a hardcoded English string, with no localization key or lookup in this file. Any translation is the display layer's job.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | Tracking without Accessibility — time is unassigned. | Shown when `isDegraded` is true |

## Accessibility Options

Not applicable: the models are not a visual surface and respond to no display option.

## Feature Flags

Not applicable: the file reads no flag. `WorkTrackingPreferences.enabled` is a user preference, not a feature flag.

## Analytics

Not applicable: the file emits no analytics event.

## Privacy

- **Data collected**: The models describe the data tracking holds: bundle ids the user added or removed, and a current `ActivitySpanDTO` that carries window title, working path, repo root and branch.
- **Storage**: Not in this file. `WorkTrackingSettingsKeys` names the daemon's `settings` keys that hold the preferences and the last Accessibility answer.
- **Transmission**: Not in this file. The models are the payloads the app and the daemon exchange.
- **Retention**: `retentionDays` is the user's retention setting, default 90 and clamped to 7 through 3650. This file only holds and clamps the number.

## Logging

Not applicable: the file makes no log call. `WorkTrackingStatus.lastError` and `writeFailures` carry failures reported by the daemon as data.

## Platform Notes

- **SwiftUI**: A port note: the types are Foundation-only, so a SwiftUI view can bind to `WorkTrackingStatus` and `WorkTrackingPreferences` directly, for example `isDegraded` driving a banner that shows `degradedNotice`.
- **Compose**: Use Kotlin `data class` values with `kotlinx.serialization` `@Serializable` and a `@SerialName` per snake-case key. `enum class` with `@SerialName` gives the raw values. Sort and de-duplicate with `toSortedSet().toList()` and clamp with `coerceIn(7, 3650)`. Collect a status through a `StateFlow` for the UI.
- **React/Web**: Use TypeScript `interface` types with snake-case JSON keys, a string-literal union for accessibility, `[...new Set(ids)].sort()` for the ids and `Math.min(Math.max(...))` for the clamp. Ordering and equality must match Swift: normalize every id with `normalize('NFC')` before de-duplicating, because Swift treats canonically equivalent strings (a composed and a decomposed accent) as equal and a plain JavaScript `Set` does not, then sort with an explicit comparator that compares by Unicode scalar (code point), not the default `sort()`, which compares UTF-16 code units and gives a different order for characters outside the Basic Multilingual Plane.
- **AppKit / UIKit**: The source's own platform family. These types are Foundation-only and UI-neutral, so AppKit code reads them as the Swift source does: for example a view controller shows `degradedNotice` in a label while `isDegraded` is true.
- **WinUI 3**: Use C# `record` types with `System.Text.Json` and `[JsonPropertyName]` (or `JsonNamingPolicy.SnakeCaseLower`) for the snake-case keys, and `JsonStringEnumConverter` with `JsonNamingPolicy.CamelCase` (the cases are single lower-case words) for `WorkTrackingAccessibility`. `Math.Clamp(days, 7, 3650)` replaces `BillingLimits.clamp`, and `ids.Distinct().OrderBy(x => x, StringComparer.Ordinal)` replaces the sort and de-duplication (ordinal comparison, not culture). Make `WorkTrackingStatus` bindable by implementing `INotifyPropertyChanged` in a view-model wrapper, and read `isDegraded` as a computed property. Persist the settings keys through `Windows.Storage.ApplicationData.Current.LocalSettings` or the daemon's own table, with the two bundle-id lists stored as JSON strings. Use `UTF8Encoding` bytes for `readFailedRow`. The daemon-side equivalent is an `IHostedService` that owns the settings table.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/WorkTrackingModels.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The initializer stores arguments verbatim, and sorting, de-duplication and clamping happen only in `normalized()`.
**Rationale**: Callers can build any value, and the layer that persists calls `normalized()` once. This keeps a half-edited form value representable.
**Approved**: pending

**Decision**: A failed list read replies with one element, `{"work_tracking_read_failed":true}`, instead of an error.
**Rationale**: A caller can tell a failed read from an empty list, and billing and work tracking list replies share one failure shape, the same convention as `BillingWire.readFailedRow`.
**Approved**: pending

**Decision**: `isDegraded` is true for `.unknown` as well as `.denied`.
**Rationale**: The source defines degraded as `enabled && accessibility != .granted`, so an unanswered Accessibility state is treated as not granted. `testDegradedOnlyWhenEnabledWithoutGrant` asserts both.
**Approved**: pending

**Decision**: The session id of an app span is `app:` plus the span id, so billing segments from app spans are told apart from other sessions by prefix.
**Rationale**: Billing sessions come from more than one source, so the prefix is the only marker that a segment came from an app span; `spanId(sessionId:)` returns nil for any other session id.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | reliability |

The file holds only data shapes and pure functions, and transport, storage and recording sit in sibling types, so separation of concerns passes. `WorkTrackingModelsTests` covers normalization, the session id mapping, degraded status and the snake-case round trip, and the same file now covers the default value, the constructor, the wire row bytes, the settings key strings and the status defaults, so unit-test coverage passes: all 14 vectors have a test. `degradedNotice` is a hardcoded English sentence, which is why the strings check fails. The wire row gives a failed list read a defined, machine-readable reply, so the error-recovery check passes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (WorkTrackingModelsTests.swift, 14 of 14 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Marked unit-test coverage partial, mapped each settings key member to its string, relabeled the clamp dependency, restated Design Decision rationales without doc-comment citations, dropped RFC keywords from not-applicable edge cases, rewrote the web ordering note, moved the source path out of Platform Notes, and added depends-on and related links. |
