---
id: bad10d4b-c190-40e7-8571-62e4357b2616
title: "User Settings: File Browser"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The shared user setting that holds the gitignore-style patterns every file browser in the app leaves out; an empty list by default."
platforms:
  - swift
  - macos
tags:
  - settings
  - file-browser
  - gitignore
depends-on:
  - 6363b5ff-f511-4e21-9ba7-6850787dba62
related:
  - 1b64553a-ab58-4154-b9d5-30f34eb33caf
references: []
approved-by: ""
approved-date: ""
---

# User Settings: File Browser

## Overview

This component is the file browser's slice of the app-wide user settings: one typed setting, `UserSettings.fileBrowserExcludedPatterns`, declared as an extension of the `UserSettings` namespace. Its value is a list of strings. Each string is one `.gitignore`-style pattern, matched against paths relative to each browser root; the source's doc comment points to `GitIgnoreMatcher` for the syntax. The setting is described as "What every file browser in the app leaves out", so one list applies to every browser, not one list per browser. It is stored under the key `file_browser.excluded_patterns`. Its default is the empty list, so the setting "changes nobody's tree until it is used".

The component declares no behavior of its own beyond the key, the value type and the default. Reading, writing, persistence, change notification and the main-actor isolation all come from the generic `UserSetting` type and the settings store, specified in [adhsdk.ingredient.foundation.settings-storage](cookbook:6363b5ff-f511-4e21-9ba7-6850787dba62). The file browser consumes the setting: `FileBrowserViewController` takes it as the default of its `exclusions` parameter and re-applies exclusions when it changes, and `ExcludedFilesSettingsPanelViewController` edits it. Both are in the macOS UI layer and are not part of this component. The tree model that applies the patterns is [adhsdk.ingredient.workspace.files.file-tree-model](cookbook:1b64553a-ab58-4154-b9d5-30f34eb33caf).

## Behavioral Requirements

### Setting declaration

- **setting-key-name**: The setting MUST be stored under the key name `file_browser.excluded_patterns`.
- **setting-value-type**: The setting's value type MUST be an ordered list of strings.
- **setting-default-empty**: The setting's default value MUST be the empty list.
- **setting-not-secure**: The setting MUST NOT be marked secure, so it is routed to the plain (non-secret) backing store; the declaration passes no secure flag and the generic setting type defaults it to false.
- **setting-shared-instance**: The setting MUST be a single shared, process-wide declaration on the `UserSettings` namespace, so every file browser and the excluded-files settings panel read and write the same list.

### Pattern entries

- **entry-gitignore-syntax**: Each entry MUST be interpreted as one `.gitignore`-style pattern, matched against a path relative to a browser root, with the syntax defined by `GitIgnoreMatcher`.
- **entry-order-significant**: The list MUST preserve entry order, because `GitIgnoreMatcher` lets the last matching pattern decide, so a later `!` pattern re-includes what an earlier pattern excluded.
- **entry-no-validation**: The setting MUST NOT validate, trim, deduplicate or reject entries; it stores whatever list it is given, and blank lines and `#` comment lines are ignored later by `GitIgnoreMatcher`, not by the setting.
- **entry-duplicates-allowed**: The setting MUST accept duplicate entries, because it stores the list exactly as given.

### Inherited behavior
- **inherits-settings-storage**: The setting MUST inherit the get, set, publish and isolation behavior of the generic `UserSetting` and the settings store, unchanged, as specified in [adhsdk.ingredient.foundation.settings-storage](cookbook:6363b5ff-f511-4e21-9ba7-6850787dba62). The only values specific to this setting are the key name, the value type and the empty-list fallback, so a read that finds nothing stored, or a value that cannot be decoded as a list of strings, MUST return the empty list.
- **inherits-lazy-construction**: The setting MUST read its current value from the shared store when it is first accessed, not before. (The Swift source achieves this with a `static var` initialised on first access.)
- **inherits-live-mirror**: The setting's `currentValue` MUST follow the store: whenever the store publishes this key's name, `currentValue` MUST be re-read from `UserSettings.shared`.

### Persistence and side effects

- **persists-through-store**: The component MUST NOT touch files, the network or processes itself; the stored list survives a restart exactly as far as the plain backing store of `UserSettings.shared` does.
- **no-migration**: The component MUST NOT perform a migration or seed any patterns; the first read of an untouched store yields the empty list.

## Appearance

Not applicable — this is a setting declaration, not a visual component.

## States

Not applicable — this is a setting declaration, not a visual component.

## Accessibility

Not applicable — this is a setting declaration, not a visual component.

## Conformance Test Vectors

The source has no test file for the setting itself; an implementer should add a `UserSettings+FileBrowser` test that asserts vectors 001 to 003, 007 and 012 (the key, the default, the secure flag, the unchanged round trip and the shared declaration). The vectors below are traced to the declaration and to the settings-storage contract it inherits. The pattern-semantics vectors are traced to `GitIgnoreMatcherTests` and show what a stored list means to the code that consumes it.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| user-settings-file-browser-001 | setting-key-name | Read the setting's `name` | `file_browser.excluded_patterns` |
| user-settings-file-browser-002 | setting-default-empty, setting-value-type | Read `defaultValue` | The empty list of strings |
| user-settings-file-browser-003 | setting-not-secure | Read `isSecure` | `false` |
| user-settings-file-browser-004 | inherits-settings-storage, no-migration | Read `currentValue` on a store holding nothing under the key | The empty list |
| user-settings-file-browser-005 | inherits-settings-storage | Set `value` to `["*.log", "build/"]`, then read `currentValue` | The list `["*.log", "build/"]` in that order, and the key name `file_browser.excluded_patterns` appears on the change stream |
| user-settings-file-browser-006 | inherits-settings-storage | Store holds bytes under the key that are not a list of strings, then read | The empty list, no error |
| user-settings-file-browser-007 | entry-no-validation, entry-duplicates-allowed | Set `value` to `["a", "a", ""]` and read it back | `["a", "a", ""]` unchanged: no trimming, no deduplication, no dropping of the blank entry |
| user-settings-file-browser-008 | entry-order-significant, entry-gitignore-syntax | List `["*.log", "!keep.log"]` given to `GitIgnoreMatcher`; test `testNegationAndLastMatchWins` | `a.log` excluded, `keep.log` not excluded |
| user-settings-file-browser-009 | entry-order-significant | List `["!keep.log", "*.log"]` given to `GitIgnoreMatcher`; test `testNegationAndLastMatchWins` | `keep.log` excluded: the later pattern wins |
| user-settings-file-browser-010 | entry-no-validation, entry-gitignore-syntax | List `["", "   ", "# *.log"]` given to `GitIgnoreMatcher`; test `testBlankLinesAndCommentsAreIgnored` | The matcher is empty and `a.log` is not excluded |
| user-settings-file-browser-011 | entry-gitignore-syntax | List `["*.log"]`; test `testUnanchoredNameMatchesAtAnyDepth` | `a.log` and `deep/er/a.log` excluded, `a.log.txt` not excluded |
| user-settings-file-browser-012 | setting-shared-instance | Two readers each access `UserSettings.fileBrowserExcludedPatterns` | Both receive the same declaration, so a write through one is the value the other reads |

## Edge Cases

- **Empty list (MUST)**: An empty list is the default and a legal stored value; consumers MUST treat it as "exclude nothing", per the default's doc comment. `GitIgnoreMatcher.empty` is that case for the matcher.
- **Blank and comment entries (MUST)**: Entries that are empty, whitespace only, or start with `#` are stored as given and ignored by `GitIgnoreMatcher`; the setting MUST NOT strip them. The one editor in the source, `ExcludedFilesSettingsPanelViewController`, trims surrounding spaces and never writes an empty row, but that is the panel's behavior, and a list written by anything else keeps its blanks.
- **Malformed or unmatchable pattern (MUST)**: The setting accepts any string. What a malformed pattern does is decided by `GitIgnoreMatcher`, not by the setting; the matcher treats regex characters as literal (`testRegexCharactersAreLiteral`).
- **Case sensitivity (MUST)**: Patterns are stored as typed and matched case-sensitively by `GitIgnoreMatcher` (`testMatchingIsCaseSensitive`), so `*.LOG` does not exclude `a.log`.
- **Large list**: The source sets no limit on the number of entries; the whole list is read and written as one value, so each edit rewrites the full list.
- **Concurrent access (MUST)**: `UserSetting` is `@MainActor`, so reads and writes are serialised on the main actor; concurrent calls from another thread are not part of the contract. Two writers on the main actor each replace the whole list, and the last write wins; the setting has no merge step.
- **Own-write echo (SHOULD)**: A writer that also observes the setting receives its own write back through the change stream. A writer that needs to ignore the echo has to remember the list it last wrote. The setting itself does not suppress echoes.
- **Offline or disconnected (not applicable)**: The setting is read from a local store and makes no network request. With a cloud-synced backend behind `UserSettings.shared` the list could change from another device; that is a property of the store, specified in settings-storage.
- **Missing file or unreachable server (not applicable)**: The setting never opens a file or contacts a server; the paths in the patterns are matched as strings and never looked up.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `file_browser.excluded_patterns` | list of strings | `[]` | `.gitignore`-style patterns, one per entry, matched against paths relative to each browser root. |

## Deep Linking

Not applicable: the component is a setting declaration with no screen, route or URL.

## Localization

Not applicable: the component holds no user-facing strings; the pattern list is user-entered data stored verbatim, and the key name is an internal identifier.

## Accessibility Options

Not applicable: the component is a setting declaration with no display, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the declaration has no flag; the default empty list is what keeps the setting inert until used.

## Analytics

Not applicable: the component emits no analytics events.

## Privacy

- **Data collected**: A list of file-name patterns the user types; patterns can reveal directory or project names.
- **Storage**: The plain (non-secure) backing store of `UserSettings.shared`; the key is not marked secure.
- **Transmission**: The component sends nothing; whether the list leaves the device depends on the backend behind `UserSettings.shared`, such as a cloud-synced one.
- **Retention**: Kept until the user edits the list or the store's value is removed; the component sets no expiry.

## Logging

Not applicable: the component makes no log calls; the declaration contains no logging.

## Platform Notes

- **SwiftUI**: The setting is a `UserSetting`, which is already an `ObservableObject` with a `@Published` `currentValue`, so a SwiftUI view binds to it with an `@ObservedObject` and edits `value`.
- **Compose**: Model it as a `Preferences` key of a string set in Jetpack `DataStore`, except that a `Set` loses order and duplicates, which this setting keeps; store a JSON array in a string key or use a proto `DataStore`. Expose it as a `StateFlow` of a list of strings with a default of an empty list.
- **React/Web**: Back it with a key in `localStorage` or `IndexedDB` holding a JSON array, expose it through a `useSyncExternalStore` hook, and treat a missing or unparseable value as an empty array.
- **AppKit / UIKit**: The declaration is a Foundation-only `UserSettings` extension holding one `public static var` of `UserSetting<[String]>` constructed with the name `file_browser.excluded_patterns` and an empty default, so it needs no UI framework and is `@MainActor` through `UserSetting`. A consumer takes a setting of this type as a parameter that defaults to this one, and the store behind `UserSettings.shared` is the injection point for tests and for a different backend.
- **WinUI 3**: Model the setting as a typed key with name `file_browser.excluded_patterns` and a default of an empty `IReadOnlyList<string>`, stored in `Windows.Storage.ApplicationData.Current.LocalSettings` (an `ApplicationDataContainer`). Its values are limited to simple types, so serialise the list with `System.Text.Json` into a string value, and fall back to an empty list when `JsonSerializer.Deserialize` throws a `JsonException` or returns null. Expose it as an `INotifyPropertyChanged` wrapper (or a CommunityToolkit.Mvvm `ObservableObject`) whose `Value` setter writes the store and raises a change event carrying the key name; marshal that event to the UI with `DispatcherQueue.TryEnqueue`, as the source hops to the main dispatch queue. The pattern evaluation needs a ported matcher, because .NET has no gitignore matcher in the framework; `Regex` can implement the translation the source performs, and its tests carry over as the conformance suite.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/SettingStorage/UserSettings+FileBrowser.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The excluded patterns are one shared setting for every file browser, not a per-browser or per-root setting.
**Rationale**: The doc comment reads "What every file browser in the app leaves out", and every browser takes the same setting as the default of its `exclusions` parameter. Per-root control is not offered by this setting.
**Approved**: pending

**Decision**: The default is the empty list, so nothing is hidden until the user adds a pattern.
**Rationale**: The doc comment says "Empty by default, so the setting changes nobody's tree until it is used."
**Approved**: pending

**Decision**: The patterns are stored as raw strings in gitignore syntax and are not parsed or validated at the setting.
**Rationale**: Parsing belongs to `GitIgnoreMatcher`, so the stored list stays editable text in order, comments and blanks included, and a list copied from a `.gitignore` behaves the same. Validation at write time would reject input the matcher already tolerates.
**Approved**: pending

**Decision**: The setting is a `static var` extension member on `UserSettings` rather than a constant.
**Rationale**: It follows the sibling declarations in `UserSettings+Git.swift`, `UserSettings+Editor.swift` and `UserSettings+Theme.swift`, which each add typed settings to the same namespace in their own file. The source gives no further reason for `var` over `let`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

The declaration holds only a key, a type and a default, and leaves storage to the settings store, matching to `GitIgnoreMatcher`, and display to the macOS view controllers (separation-of-concerns: passed). `UserSettingsFileBrowserTests` (`Tests/AgenticDeveloperHubSDKCoreTests/SettingStorage/UserSettingsFileBrowserTests.swift`) asserts every vector: the key name, default, secure flag, store round trips and shared declaration, and the matcher semantics through `GitIgnoreMatcher` (unit-test-coverage: passed). The setting stores only what the user types, with an empty default (data-minimization: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (UserSettingsFileBrowserTests.swift, 12 of 12 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Restore requirements lost in the lint pass: inherits-live-mirror |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Folded the inherited settings behavior into one requirement, trimmed editor and consumer detail from configuration, edge cases and platform notes, replaced the vague tag, and named the test that should cover the setting. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
