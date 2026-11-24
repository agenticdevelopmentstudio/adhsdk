---
id: a6b177ee-dc1e-441d-9844-eee2ef48ed8d
title: "TrackedApp"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The set of development apps whose frontmost time is recorded: built-in defaults minus removed plus added bundle ids, with a path-resolver kind per app."
platforms:
  - swift
  - macos
tags:
  - foundation
  - work-tracking
  - allowlist
  - bundle-id
depends-on:
  - d525cc69-4d2c-4d17-a570-f71e8d5aa273
related: []
references: []
approved-by: ""
approved-date: ""
---

# TrackedApp

## Overview

`TrackedApp` is one app whose frontmost time is recorded: a bundle identifier, a display name and a `PathResolverKind` saying how the app's working path is found. `AppAllowlist` is the immutable set of tracked apps built from `WorkTrackingPreferences`: the built-in defaults, minus the bundle ids the user removed, plus the bundle ids the user added. Its own doc comment states the rule: anything not on the list is never stored. Callers ask it whether a bundle id is allowed and for the `TrackedApp` behind an id.

This is shared logic with no visual surface. It does no I/O and holds no mutable state; a new allowlist is built whenever the preferences change. The activity recorder holds an `AppAllowlist` and looks up the focused app's bundle id with `app(for:)`; an app that is not found is not recorded.

## Behavioral Requirements

- **path-resolver-kinds**: `PathResolverKind` MUST have exactly four cases, `document`, `editor`, `terminal` and `none`, each with a string raw value equal to its name.
- **path-resolver-codable**: `PathResolverKind` MUST be `Codable` and `Sendable`.
- **tracked-app-fields**: `TrackedApp` MUST carry `bundleId`, `name` and `resolver` as immutable fields set by its initializer.
- **tracked-app-identity**: `TrackedApp.id` MUST equal `bundleId`.
- **tracked-app-conformances**: `TrackedApp` MUST be `Equatable`, `Codable`, `Sendable` and `Identifiable`.
- **defaults-list**: `AppAllowlist.defaults` MUST list exactly the 32 built-in apps in the Default apps table below, each with the name and resolver given there.
- **defaults-unique-ids**: Every bundle id in `AppAllowlist.defaults` MUST be unique.
- **defaults-resolver-assignment**: Each default MUST use the resolver in the Default apps table below.
- **construct-from-preferences**: `AppAllowlist.init(preferences:defaults:)` MUST take a `WorkTrackingPreferences` and an optional `defaults` list that defaults to `AppAllowlist.defaults`.
- **removed-excluded**: The initializer MUST drop every default whose `bundleId` is in `preferences.removedBundleIds`.
- **added-appended**: The initializer MUST append a `TrackedApp` for each id in `preferences.addedBundleIds` that is not a `defaults` bundle id and is not in `removedBundleIds`.
- **added-app-shape**: An added `TrackedApp` MUST use the bundle id as its `name` and `PathResolverKind.editor` as its `resolver`.
- **removed-beats-added**: An id present in both `addedBundleIds` and `removedBundleIds` MUST NOT appear in the allowlist.
- **added-default-ignored**: An added id equal to a `defaults` bundle id MUST NOT create a second entry; the default entry, with its own name and resolver, stays.
- **added-duplicates-collapsed**: The same id listed more than once in `addedBundleIds` MUST yield one entry.
- **sorted-apps**: `apps` MUST be sorted ascending by the pair `(name, bundleId)`, comparing each string in Unicode scalar order after normalizing it to NFC (Swift's default `String` ordering), not by locale and not by UTF-16 code unit.
- **apps-immutable**: `apps` MUST be a `let`; an `AppAllowlist` MUST NOT change after it is built.
- **is-allowed**: `isAllowed(_:)` MUST return `true` exactly when the bundle id is in `apps`, compared as an exact string match.
- **app-lookup**: `app(for:)` MUST return the `TrackedApp` for the bundle id, or `nil` when the id is not in `apps`.
- **lookup-first-wins**: When the `defaults` argument repeats a bundle id, the lookup MUST return the first of those entries in the sorted `apps` order (the table is built after the sort), while `apps` still contains both.
- **allowlist-equatable**: `AppAllowlist` MUST be `Equatable` and `Sendable`.
- **pure-no-side-effects**: Building and querying an `AppAllowlist` MUST NOT read or write files, use the network, start processes or post notifications.
- **empty-id-not-validated**: The initializer MUST NOT validate or reject bundle ids; an empty string in `addedBundleIds` MUST become an entry whose bundle id and name are both empty.

### Default apps

| bundleId | name | resolver |
|----------|------|----------|
| `com.apple.dt.Xcode` | Xcode | `document` |
| `com.apple.iphonesimulator` | Simulator | `none` |
| `com.apple.dt.Instruments` | Instruments | `none` |
| `com.google.android.studio` | Android Studio | `editor` |
| `com.jetbrains.intellij` | IntelliJ IDEA | `editor` |
| `com.jetbrains.intellij.ce` | IntelliJ IDEA CE | `editor` |
| `com.jetbrains.pycharm` | PyCharm | `editor` |
| `com.jetbrains.pycharm.ce` | PyCharm CE | `editor` |
| `com.jetbrains.WebStorm` | WebStorm | `editor` |
| `com.jetbrains.goland` | GoLand | `editor` |
| `com.jetbrains.CLion` | CLion | `editor` |
| `com.jetbrains.rubymine` | RubyMine | `editor` |
| `com.jetbrains.rider` | Rider | `editor` |
| `com.jetbrains.PhpStorm` | PhpStorm | `editor` |
| `com.jetbrains.rustrover` | RustRover | `editor` |
| `com.jetbrains.fleet` | Fleet | `editor` |
| `com.microsoft.VSCode` | Visual Studio Code | `editor` |
| `com.microsoft.VSCodeInsiders` | VS Code Insiders | `editor` |
| `com.todesktop.230313mzl4w4u92` | Cursor | `editor` |
| `com.exafunction.windsurf` | Windsurf | `editor` |
| `dev.zed.Zed` | Zed | `document` |
| `com.panic.Nova` | Nova | `document` |
| `com.barebones.bbedit` | BBEdit | `document` |
| `com.sublimetext.4` | Sublime Text | `document` |
| `com.apple.Terminal` | Terminal | `terminal` |
| `com.googlecode.iterm2` | iTerm2 | `terminal` |
| `com.mitchellh.ghostty` | Ghostty | `terminal` |
| `dev.warp.Warp-Stable` | Warp | `terminal` |
| `com.fournova.Tower3` | Tower | `none` |
| `com.sublimemerge` | Sublime Merge | `none` |
| `com.DanPristupov.Fork` | Fork | `none` |
| `com.github.GitHubClient` | GitHub Desktop | `none` |
## Appearance

Not applicable — this is a data model and lookup table, not a visual component.

## States

Not applicable — this is a data model and lookup table, not a visual component. `AppAllowlist` has no runtime states; it is fully built by its initializer.

## Accessibility

Not applicable — this is a data model and lookup table, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tracked-app-001 | is-allowed, defaults-list | `AppAllowlist(preferences: .default)`, ids `com.apple.dt.Xcode` and `com.apple.Safari` | `isAllowed("com.apple.dt.Xcode")` is `true`; `isAllowed("com.apple.Safari")` is `false` |
| tracked-app-002 | removed-excluded | Preferences removing `com.apple.Terminal` | `isAllowed("com.apple.Terminal")` is `false` |
| tracked-app-003 | added-appended, added-app-shape | Preferences adding `org.example.Editor` | `isAllowed("org.example.Editor")` is `true`; `app(for:)?.resolver` is `.editor` (both asserted by the test); `name` is `org.example.Editor` (from the source, not asserted by the test) |
| tracked-app-004 | defaults-resolver-assignment | `app(for: "com.sublimemerge")` on default preferences | `resolver` is `PathResolverKind.none` |
| tracked-app-005 | defaults-unique-ids | `AppAllowlist.defaults` | the set of bundle ids has the same count as the list |
| tracked-app-006 | removed-beats-added | Preferences adding and removing `org.example.Editor` | `isAllowed("org.example.Editor")` is `false` |
| tracked-app-007 | added-default-ignored | Preferences adding `com.apple.dt.Xcode` | `apps` contains one Xcode entry; `app(for:)?.resolver` is `.document` |
| tracked-app-008 | sorted-apps | Default preferences | `apps` is ordered by `name` then `bundleId`; `Android Studio` precedes `BBEdit` |
| tracked-app-009 | app-lookup | `app(for: "com.apple.Safari")` | `nil` |
| tracked-app-010 | added-duplicates-collapsed | `addedBundleIds` of `["a.b", "a.b"]` | `apps` contains exactly one entry with bundle id `a.b` |
| tracked-app-011 | lookup-first-wins | `defaults` of two apps sharing a bundle id, names "B" then "A" | `apps` has both, sorted "A" then "B"; `app(for:)` returns the "A" entry, the first in sorted order |
| tracked-app-012 | tracked-app-identity | `TrackedApp(bundleId: "x.y", name: "N", resolver: .none)` | `id` is `"x.y"` |
| tracked-app-013 | construct-from-preferences | Empty `defaults` and `.default` preferences | `apps` is empty; `isAllowed("com.apple.dt.Xcode")` and `isAllowed("")` are both `false` |

Vector 001 is covered by `AppAllowlistTests.testDefaultsAreAllowedAndOthersAreNot`, vectors 002 and 003 by `AppAllowlistTests.testRemovedDefaultIsNotAllowedAndAddedAppIs`, vector 004 by `AppAllowlistTests.testSublimeMergeIsAGitClientWithNoPath` and vector 005 by `AppAllowlistTests.testDefaultBundleIdsAreUnique`. Vectors 006 to 013 are covered by `AppAllowlistTests.testV006_removedBeatsAdded` through `testV013_emptyDefaultsAllowNothing`, one test per vector.

## Edge Cases

- **Empty preferences**: With `WorkTrackingPreferences.default` (no added, no removed ids), the allowlist MUST equal the sorted defaults.
- **Empty bundle id**: The initializer does not validate ids. An empty string in `addedBundleIds` becomes an entry whose bundle id and name are both empty; `WorkTrackingPreferences.normalized()` de-duplicates and sorts ids but does not drop empty ones.
- **Unknown removed id**: A removed id that matches no default MUST have no effect.
- **Case sensitivity**: Bundle ids compare case-sensitively; `com.apple.dt.xcode` is not Xcode.
- **Duplicate ids in the injected defaults**: Both entries stay in `apps`; the lookup table is built from the sorted list and keeps the first in that order, so `isAllowed` and `app(for:)` see one id. The default list is checked unique by a test, so this arises only with a caller-supplied `defaults`.
- **Equal names**: Two apps with the same `name` are ordered by `bundleId`, so the order is total and deterministic. The added ids come from a `Set`, but the final sort removes any dependence on its iteration order.
- **Null input**: Not applicable: no parameter is optional; the types are non-optional `String` and a value type.
- **Boundary values**: Not applicable: there are no numeric inputs; `retentionDays` on the preferences is not read here.
- **Concurrent access**: `AppAllowlist`, `TrackedApp` and `PathResolverKind` are `Sendable` value types with only immutable stored properties, so concurrent reads are safe and nothing is serialised.
- **Error states**: Not applicable: neither initializer nor queries throw or return an error.
- **Offline or disconnected state**: Not applicable: the code uses no network.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `preferences` | `WorkTrackingPreferences` | none (required) | Supplies `removedBundleIds` and `addedBundleIds`; `enabled` and `retentionDays` are not read |
| `defaults` | `[TrackedApp]` | `AppAllowlist.defaults` | The built-in list the preferences are applied to; injectable for tests |

## Deep Linking

Not applicable: the code defines no URL, scheme or route; bundle ids are identifiers, not links.

## Localization

Not applicable: no user-facing string is produced for display. The default `name` values are English product names and an added app's `name` is its bundle id; the consumer that renders them, such as `TrackedAppsSettingsPanel`, owns any localization.

## Accessibility Options

Not applicable: the code has no visual output, motion or color.

## Feature Flags

Not applicable: the code reads no flag. Whether tracking runs at all is `WorkTrackingPreferences.enabled`, which this type does not read.

## Analytics

Not applicable: the code emits no event.

## Privacy

- **Data collected**: None. The allowlist holds bundle ids and display names only, and no user content.
- **Storage**: None. The type is in memory; the added and removed ids it reads are stored by `WorkTrackingPreferences`, outside this code.
- **Transmission**: None.
- **Retention**: Not applicable here; `retentionDays` belongs to `WorkTrackingPreferences`.
- **Purpose**: The allowlist is the gate on what gets recorded: only apps on it are stored, and anything else is never stored.

## Logging

Not applicable: the code calls no logging API.

## Platform Notes

- **SwiftUI**: `TrackedApp` is `Identifiable`, so a `List` or `ForEach` over `allowlist.apps` needs no `id:` argument.
- **Compose**: A `data class TrackedApp(val bundleId: String, val name: String, val resolver: PathResolverKind)` with an enum class for the resolver. Android has no bundle id; use the application package name. Build the list with `filter`, `plus` and `sortedWith(compareBy({ it.name }, { it.bundleId }))`, and a `Map` built from the sorted list with `putIfAbsent` to keep the first duplicate.
- **React/Web**: A `readonly` type and a frozen array, with a `Map` for lookup. Swift's default string ordering is not locale-aware, so normalize both names with `normalize("NFC")` and compare by code point, not with `localeCompare` and not by UTF-16 code unit.
- **AppKit / UIKit**: Match `NSRunningApplication.bundleIdentifier` against the allowlist on focus change. The allowlist itself imports only Foundation and has no AppKit dependency.
- **WinUI 3**: Model `TrackedApp` as a C# `record` (value equality) with `enum PathResolverKind` serialised as a string through `System.Text.Json` with `JsonStringEnumConverter`. Windows has no bundle id; use the process executable name or the packaged app's `AppUserModelId`. Build the list with LINQ (`Where`, `Concat`, `OrderBy` and `ThenBy` over NFC-normalized (`NormalizationForm.FormC`) strings compared by Unicode scalar (`Rune`), because `StringComparer.Ordinal` compares UTF-16 code units and differs for non-BMP text), expose it as `IReadOnlyList<TrackedApp>` and keep a `Dictionary<string, TrackedApp>` for lookup, built from the sorted list with `TryAdd` so the first duplicate wins. The class is immutable, so it needs no `INotifyPropertyChanged`; a settings page binds to an `ObservableCollection<TrackedApp>` rebuilt from a new allowlist when preferences change. Use `StringComparer.Ordinal` for the id lookup to match Swift's exact, case-sensitive matching.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/TrackedApp.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: An added bundle id becomes a `TrackedApp` named by the id itself with the `editor` resolver.
**Rationale**: The preferences store only ids, so no display name or resolver kind is known; the source falls back to the id and to `editor`, and the test testRemovedDefaultIsNotAllowedAndAddedAppIs asserts the `editor` resolver.
**Approved**: pending

**Decision**: A removal wins over an addition, and an addition never overrides a default.
**Rationale**: The initializer filters defaults by the removed set and skips added ids that are known defaults or removed, so a default keeps its curated name and resolver.
**Approved**: pending

**Decision**: The lookup table keeps the first, in sorted order, of any duplicate bundle id while `apps` keeps all.
**Rationale**: The dictionary is built with a merge that keeps the first value instead of trapping on a duplicate; the shipped defaults are tested unique, so this protects only injected lists.
**Approved**: pending

**Decision**: Every app on the allowlist is recorded and anything else is never stored.
**Rationale**: The doc comment states the allowlist is the recording boundary, which keeps tracking limited to development apps.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

The type separates the data model and lookup from recording, persistence and display, which live in the recorder, the preferences and the settings panel. `AppAllowlistTests` (`Tests/AgenticDeveloperHubSDKCoreTests/WorkTracking/AppAllowlistTests.swift`) covers every vector, including sort order, removed-beats-added, an added id that is already a default, and duplicate injected defaults, so coverage passes. The allowlist limits recording to a named set of apps and holds no user content.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (AppAllowlistTests.swift extended, 13 of 13 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added a table of the 32 default apps with resolvers, fixed the sort order to NFC Unicode scalar order across platform notes, recorded empty-id handling as a requirement, renamed the conformance requirement to include Identifiable, moved the recorder behavior to prose, made vector inputs concrete and platform-neutral, added depends-on for the preferences, and removed the source path. |
