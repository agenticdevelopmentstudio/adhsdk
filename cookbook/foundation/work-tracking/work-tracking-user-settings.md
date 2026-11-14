---
id: ba4dcadb-1225-4bcc-afca-bbb617e6e6c9
title: "Work Tracking User Settings"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The four work-tracking knobs as live, prefix-namespaced user settings on the main actor, with a normalized preferences snapshot."
platforms:
  - swift
  - macos
tags:
  - work-tracking
  - foundation
  - settings
depends-on: []
related:
  - c1caa827-f7f1-4e69-b4c6-adbfef22e636
  - 0175f0bb-f4bd-4f72-94c2-57b087ad9df9
references: []
approved-by: ""
approved-date: ""
---

# Work Tracking User Settings

## Overview

`WorkTrackingUserSettings` is a `@MainActor` final class holding the four work-tracking knobs as live `UserSetting` values: `enabled`, `addedBundleIds`, `removedBundleIds` and `retentionDays`. Per its doc comment each is stored under `prefix + WorkTrackingSettingsKeys.*`, so "the app decides only the prefix", the same way `BillingUserSettings` does. Defaults come from `WorkTrackingPreferences.default`, the same values the daemon falls back to. The `preferences` property reads the four current values into one `WorkTrackingPreferences` and normalizes it, which is the value an app pushes to the daemon.

## Behavioral Requirements

- **main-actor**: The class MUST be isolated to the main actor; every access, including `init`, MUST happen there.
- **four-settings**: The class MUST expose exactly four settings: `enabled` (`UserSetting<Bool>`), `addedBundleIds` (`UserSetting<[String]>`), `removedBundleIds` (`UserSetting<[String]>`) and `retentionDays` (`UserSetting<Int>`).
- **init-prefix**: `init(prefix:)` MUST take the key prefix as its only argument.
- **key-enabled**: `enabled` MUST be stored under `prefix` followed by `activity_enabled`.
- **key-added**: `addedBundleIds` MUST be stored under `prefix` followed by `activity_added_bundle_ids`.
- **key-removed**: `removedBundleIds` MUST be stored under `prefix` followed by `activity_removed_bundle_ids`.
- **key-retention**: `retentionDays` MUST be stored under `prefix` followed by `activity_retention_days`.
- **no-separator**: The class MUST concatenate prefix and key with no separator of its own; the caller supplies any separator in the prefix.
- **defaults-shared**: Each setting's default MUST be the matching field of `WorkTrackingPreferences.default`: `enabled` false, both id lists empty, `retentionDays` 90.
- **settings-public-live**: Each setting MUST be a `public let` `UserSetting`, so a caller reads and writes its `value` and the setting reflects changes the shared user-settings store publishes.
- **preferences-snapshot**: `preferences` MUST build a `WorkTrackingPreferences` from the four current `value`s on each read.
- **preferences-normalized**: `preferences` MUST return the snapshot after `normalized()`: ids sorted ascending and de-duplicated, retention clamped into 7 through 3650.
- **stored-values-raw**: The settings MUST hold exactly what a caller assigns; normalization applies only in `preferences`, not when a value is written.
- **accessibility-keys-excluded**: The class MUST NOT expose the Accessibility answer or signer keys; they are not user settings.
- **prefix-isolation**: Two instances built with different prefixes MUST NOT share values.

## Appearance

Not applicable — this is a non-visual settings holder, not a visual component.

## States

Not applicable — this is a non-visual settings holder, not a visual component.

## Accessibility

Not applicable — this is a non-visual settings holder, not a visual component.

## Conformance Test Vectors

Derived from `testUserSettingsSnapshotIsNormalized` in `WorkTrackingXPCClientTests` and from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-user-settings-001 | defaults-shared, preferences-snapshot | Fresh prefix, no values set | `preferences` equals `WorkTrackingPreferences.default` (disabled, no ids, 90 days) |
| work-tracking-user-settings-002 | preferences-normalized | enabled true; added `["com.b","com.a","com.b"]`; removed `["com.z","com.z"]`; retention 1 (test `testUserSettingsSnapshotIsNormalized`) | `preferences` is enabled true, added `["com.a","com.b"]`, removed `["com.z"]`, retention 7 |
| work-tracking-user-settings-003 | preferences-normalized | retention set to 99999 | `preferences.retentionDays` is 3650 |
| work-tracking-user-settings-004 | stored-values-raw | retention set to 1 | `retentionDays.value` is 1 while `preferences.retentionDays` is 7 |
| work-tracking-user-settings-005 | key-enabled, key-added, key-removed, key-retention | prefix `p_` | the four settings' `name` are `p_activity_enabled`, `p_activity_added_bundle_ids`, `p_activity_removed_bundle_ids`, `p_activity_retention_days` |
| work-tracking-user-settings-006 | no-separator | prefix `p` | `enabled.name` is `pactivity_enabled` |
| work-tracking-user-settings-007 | prefix-isolation | Two instances with prefixes `a_` and `b_`; set `enabled` true on the first | the second `enabled.value` stays false |
| work-tracking-user-settings-008 | preferences-snapshot | Read `preferences`, change `enabled`, read again | the second read shows the new value |
| work-tracking-user-settings-009 | four-settings | Inspect the class | exactly `enabled`, `addedBundleIds`, `removedBundleIds`, `retentionDays` |

## Edge Cases

- **Empty prefix**: An empty prefix MUST store under the bare keys, which are the daemon's own `settings` keys; the source does not forbid it.
- **Duplicate and unsorted ids**: Assigned lists MUST be stored as given and only the `preferences` snapshot MUST sort and de-duplicate them.
- **Out-of-range retention**: A value below 7 or above 3650 MUST be stored unchanged and clamped in `preferences`.
- **Stored text that does not decode**: Not decided here; decoding and fallback to the default belong to `UserSetting` and `UserSettings.shared`, outside the given source.
- **Concurrent access**: The class is `@MainActor`, so the compiler keeps access on the main actor and calls from elsewhere need `await`; there is no other ordering rule to state.
- **Cleanup**: Each setting can be removed (the test calls `remove()` on all four), which returns it to its default.
- **Errors, timeouts, offline, cancellation**: Not applicable — the class is synchronous, throws nothing and does no I/O of its own.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `prefix` | `String` | required | Namespace prepended to every key; the app's only decision. |
| `enabled` | `Bool` | `false` | Whether tracking is on. |
| `addedBundleIds` | `[String]` | `[]` | Bundle ids the user added. |
| `removedBundleIds` | `[String]` | `[]` | Bundle ids the user removed. |
| `retentionDays` | `Int` | `90` | Days of history kept; range 7 through 3650 on the snapshot. |

Storage is the shared `UserSettings.shared` store that `UserSetting` reads; no environment variables.

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing strings.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag; `enabled` is a user preference.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: The bundle ids the user added or removed and the retention length.
- **Storage**: The shared user-settings store, through `UserSetting`; this code adds none.
- **Transmission**: None by this code; the snapshot leaves the process only when the app pushes it to the daemon.
- **Retention**: Until the user changes or removes a setting.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Source platform. The file is `WorkTrackingUserSettings.swift` under `Core/WorkTracking`. `UserSetting` is an `ObservableObject`, so a SwiftUI settings view observes each setting individually or wraps the holder in its own view model; the holder itself is not observable.
- **Compose**: A ViewModel exposing four `StateFlow`s backed by a `DataStore<Preferences>` with keys built from a prefix, plus a `preferences` function normalizing on read; collect on the main dispatcher.
- **React/Web**: A hook returning four `useState`-like values synchronized with `localStorage` keys built from a prefix, and a `useMemo` selector sorting with `Array.from(new Set(ids)).sort()` and clamping with `Math.min(Math.max(n, 7), 3650)`.
- **AppKit / UIKit**: Same Swift type on macOS and iOS; a preferences window binds controls to the settings' `value`s and pushes `preferences` through the work-tracking service.
- **WinUI 3**: A class implementing `INotifyPropertyChanged` with four properties backed by `Windows.Storage.ApplicationData.Current.LocalSettings` (values keyed by prefix plus key; lists stored as JSON strings through `System.Text.Json`, since `ApplicationDataContainer` holds only simple types). Create it on the UI thread and mark main-thread access with `DispatcherQueue`; XAML binds with `x:Bind ... Mode=TwoWay`. A `Preferences` property builds a record, sorts with `StringComparer.Ordinal` after `Distinct()` and clamps with `Math.Clamp`. Unlike Swift's compiler-enforced main actor, nothing stops a background thread touching the properties, so check `DispatcherQueue.HasThreadAccess`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/WorkTrackingUserSettings.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The app supplies only a key prefix.
**Rationale**: The doc comment says "the app decides only the prefix, the same way `BillingUserSettings` does", so keys, defaults and normalization stay shared across apps.
**Approved**: pending

**Decision**: Defaults are read from `WorkTrackingPreferences.default`.
**Rationale**: One set of numbers serves the settings pane, the wire and the daemon's fallback, so the three cannot drift.
**Approved**: pending

**Decision**: Normalization happens in the `preferences` snapshot, not on each write.
**Rationale**: The settings stay faithful to what a control assigned (a retention field mid-edit is not clamped under the user's cursor), and the value that crosses to the daemon is always valid. The daemon and `WorkTrackingPrefs` normalize again on their side.
**Approved**: pending

**Decision**: The class is `@MainActor`.
**Rationale**: `UserSetting` is itself `@MainActor`, so a holder of them must be too.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

Separation of concerns passes: the class only names the keys, supplies defaults and builds a snapshot; storage and change publishing belong to `UserSetting`, and clamping to `WorkTrackingPreferences.normalized()`. Unit coverage is partial: `testUserSettingsSnapshotIsNormalized` covers the snapshot's sorting, de-duplication and low-end clamp, but no test asserts the key names, the defaults, the high-end clamp or prefix isolation.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
