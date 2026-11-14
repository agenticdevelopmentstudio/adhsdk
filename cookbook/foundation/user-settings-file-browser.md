---
id: bad10d4b-c190-40e7-8571-62e4357b2616
title: "User Settings: File Browser"
type: ingredient
version: 1.0.0
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
  - logic
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
- **entry-duplicates-allowed**: The setting MUST accept duplicate entries, because it stores the list as given; the excluded-files panel relies on this by giving each row its own identity instead of using the pattern text.

### Inherited behavior

- **inherits-read-default**: Reading the setting MUST return the empty list when no value has been stored, or when the stored value cannot be decoded as a list of strings, per the get-fallback contract in settings-storage.
- **inherits-write-publishes**: Writing the setting MUST publish its key name on the settings change stream after the new value is readable, per settings-storage, so a subscriber such as a file browser can re-apply its exclusions.
- **inherits-main-actor**: The setting MUST be read and written on the main actor, because `UserSetting` is declared `@MainActor`.
- **inherits-lazy-construction**: The setting MUST be created on first access of `UserSettings.fileBrowserExcludedPatterns`, and at that point it MUST read its current value from `UserSettings.shared`, because `fileBrowserExcludedPatterns` is a `static var` initialised from `UserSetting.init`.
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

The source has no test file for the setting itself. The vectors below are traced to the declaration and to the settings-storage contract it inherits. The pattern-semantics vectors are traced to `GitIgnoreMatcherTests` and show what a stored list means to the code that consumes it.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| user-settings-file-browser-001 | setting-key-name | Read the setting's `name` | `file_browser.excluded_patterns` |
| user-settings-file-browser-002 | setting-default-empty, setting-value-type | Read `defaultValue` | The empty list of strings |
| user-settings-file-browser-003 | setting-not-secure | Read `isSecure` | `false` |
| user-settings-file-browser-004 | inherits-read-default, no-migration | Read `currentValue` on a store holding nothing under the key | The empty list |
| user-settings-file-browser-005 | inherits-write-publishes, inherits-live-mirror | Set `value` to `["*.log", "build/"]`, then read `currentValue` | The list `["*.log", "build/"]` in that order, and the key name `file_browser.excluded_patterns` appears on the change stream |
| user-settings-file-browser-006 | inherits-read-default | Store holds bytes under the key that are not a list of strings, then read | The empty list, no error |
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
- **Large list (SHOULD)**: The source sets no limit on the number of entries; the whole list is read and written as one value, so each edit rewrites the full list.
- **Stored value undecodable (MUST)**: A stored value that is not a list of strings reads as the empty list, per the settings-storage get-fallback; nothing is thrown or logged by this component.
- **Concurrent access (MUST NOT interleave)**: `UserSetting` is `@MainActor`, so reads and writes are serialised on the main actor; concurrent calls from another thread are not part of the contract. Two writers on the main actor each replace the whole list, and the last write wins; the setting has no merge step.
- **Own-write echo (SHOULD)**: A writer that also observes the setting receives its own write back through the change stream. `ExcludedFilesSettingsPanelViewController` handles this by remembering the list it last wrote and ignoring the matching echo. The setting itself does not suppress echoes.
- **Offline or disconnected (not applicable)**: The setting is read from a local store and makes no network request. With a cloud-synced backend behind `UserSettings.shared` the list could change from another device; that is a property of the store, specified in settings-storage.
- **Missing file or unreachable server (not applicable)**: The setting never opens a file or contacts a server; the paths in the patterns are matched as strings and never looked up.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `file_browser.excluded_patterns` | list of strings | `[]` | `.gitignore`-style patterns, one per entry, matched against paths relative to each browser root. |
| `isSecure` | boolean | `false` | Not passed by the declaration; the generic setting type's default routes the key to the plain store. |
| `UserSettings.shared` | settings store | process-wide instance | The store the setting reads from and writes through; the injection point for tests and for a different backend. |
| `exclusions` (consumer parameter) | `UserSetting` of a list of strings | `UserSettings.fileBrowserExcludedPatterns` | A file browser view controller accepts any setting of this type, defaulting to this one. |

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

- **SwiftUI**: The setting is a `UserSetting`, which is already an `ObservableObject` with a `@Published` `currentValue`, so a SwiftUI view binds to it with an `@ObservedObject` and edits `value`. The excluded-files editor in the source is AppKit, not SwiftUI, and a SwiftUI port would use a `List` with `ForEach` over rows that carry their own ids and an `onDelete`/`onMove` or a `TextField` per row.
- **Compose**: Model it as a `Preferences` key of a string set in Jetpack `DataStore`, except that a `Set` loses order and duplicates, which this setting keeps; store a JSON array in a string key or use a proto `DataStore`. Expose it as a `StateFlow` of a list of strings with a default of an empty list.
- **React/Web**: Back it with a key in `localStorage` or `IndexedDB` holding a JSON array, expose it through a `useSyncExternalStore` hook, and treat a missing or unparseable value as an empty array.
- **AppKit / UIKit**: The declaration is `Core/SettingStorage/UserSettings+FileBrowser.swift`, a Foundation-only file in the core target that extends `UserSettings` with one `public static var` of `UserSetting<[String]>` constructed with the name `file_browser.excluded_patterns` and an empty default. It is `@MainActor` through `UserSetting`. Consumers are `FileBrowserViewController` (default `exclusions` argument, observed with a `UserSettingObserver`) and `ExcludedFilesSettingsPanelViewController` (an editable table whose every edit is written to the setting). The matcher is `Core/FileSystem/GitIgnoreMatcher.swift`.
- **WinUI 3**: Model the setting as a typed key with name `file_browser.excluded_patterns` and a default of an empty `IReadOnlyList<string>`, stored in `Windows.Storage.ApplicationData.Current.LocalSettings` (an `ApplicationDataContainer`). Its values are limited to simple types, so serialise the list with `System.Text.Json` into a string value, and fall back to an empty list when `JsonSerializer.Deserialize` throws a `JsonException` or returns null. Expose it as an `INotifyPropertyChanged` wrapper (or a CommunityToolkit.Mvvm `ObservableObject`) whose `Value` setter writes the store and raises a change event carrying the key name; marshal that event to the UI with `DispatcherQueue.TryEnqueue`, as the source hops to the main dispatch queue. The editor maps to a `ListView` with an `ObservableCollection` of row view models that hold their own id and a `TextBox` in the item template, and `AppBarButton` add and remove commands; keep the "ignore own echo" guard so editing a `TextBox` does not rebuild the collection. The pattern evaluation needs a ported matcher, because .NET has no gitignore matcher in the framework; `Regex` can implement the translation the source performs, and its tests carry over as the conformance suite.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/SettingStorage/UserSettings+FileBrowser.swift` | confirmed (1.0.0) |
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
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

The declaration holds only a key, a type and a default, and leaves storage to the settings store, matching to `GitIgnoreMatcher`, and display to the macOS view controllers (separation-of-concerns: passed). The matcher that interprets the list has its own `GitIgnoreMatcherTests`, and `LayeredSettingsStoreTests` covers the store, but no test in the source reads or writes `fileBrowserExcludedPatterns` itself, so the key name and default are asserted by no test (unit-test-coverage: partial). The setting stores only what the user types, with an empty default (data-minimization: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
