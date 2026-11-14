---
id: 274f0727-b9b3-4fd3-9dea-b7e1bfbe92fc
title: "Keyed Window Set"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One window per key: opening an open key brings its window forward, opened keys persist in order in a UserSetting, a closed window's key is forgotten, and restore reopens the list quietly, dropping keys that fail."
platforms:
  - swift
  - macos
tags:
  - window-management
  - restore
  - user-settings
depends-on: []
related:
  - 61c7b509-78d1-4407-9a4e-25b155f06fbb
  - 7f1b8bef-e78e-4cac-be55-c948fe9062e5
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/WindowManager/KeyedWindowSet.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Keyed Window Set

## Overview

One window per key, remembered across launches. A feature that opens a window per thing — a directory for the File Browser, a repository for the git window — keeps a `KeyedWindowSet`: opening a key that already has a window brings that window forward instead of opening a second, every key whose window opened is added to a persisted, ordered list, a key whose window the user closes leaves it, and `restore()` reopens the list at launch without taking the foreground. The set builds no window: the owner passes an `open` closure that makes one (or declines) and a `bringForward` closure that shows an existing one, so the set is generic over the controller type and the [window manager](cookbook:61c7b509-78d1-4407-9a4e-25b155f06fbb) or [project window manager](cookbook:7f1b8bef-e78e-4cac-be55-c948fe9062e5) underneath keeps building windows the way it already does.

## Behavioral Requirements

- **open-new**: `open(key:activates:)` for a key with no open window MUST call `open(key, activates, onClose)` once; when it returns a controller the set MUST record it as the key's controller, append the key to the persisted list if absent, and return it.
- **open-declined**: When `open` returns `nil`, the set MUST return `nil`, record no controller and leave the persisted list unchanged.
- **open-existing**: `open(key:activates:)` for a key whose window is open MUST call `bringForward` with that key's controller, MUST NOT call `open`, and MUST return the same controller.
- **close-forgets**: Calling the `onClose` handed to `open` for a key MUST drop the key's controller and remove the key from the persisted list; the next `open` of that key opens a new window.
- **order**: The persisted list MUST hold each key once, in the order the keys were first opened; `keys` MUST return it.
- **restore**: `restore()` MUST call `open(key:activates: false)` for every key in the persisted list, in list order, and MUST remove from the list every key whose `open` returned `nil`, keeping the order of the rest.
- **storage**: The list MUST be stored as `[String]` in the `UserSetting<[String]>` the owner passes, so an owner keeps its existing setting name and stored values.
- **main-actor**: The set MUST be used on the main actor only.

## Appearance

Not applicable: the set draws nothing; the windows are the owner's.

## States

Not applicable: the set is a non-visual component; its only state is the controllers it holds and the persisted list.

## Accessibility

Not applicable: the set presents no view; the windows it records carry their own identifiers.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| keyed-window-set-001 | open-new, open-existing | `open("a")` twice | `open` called once, `bringForward` once, the same controller both times, `keys` `["a"]`. |
| keyed-window-set-002 | close-forgets | `open("a")`, then its `onClose` | `controller(for: "a")` is `nil`, `keys` `[]`; a third `open("a")` calls `open` again. |
| keyed-window-set-003 | restore | stored `["a", "gone", "b"]`, `open` returns `nil` for `gone` | `open` called for `a`, `gone`, `b` with `activates` false; `keys` `["a", "b"]`. |
| keyed-window-set-004 | order, open-declined | `open("b")`, `open("a")`, `open("b")`, declined `open("x")` | `keys` `["b", "a"]`. |

## Edge Cases

- **Null / empty input**: An empty persisted list makes `restore()` open nothing; an empty-string key is a key like any other.
- **Boundary values**: A key already in the list when its window opens (restore, or a window closed while the app was quitting) is not appended twice.
- **Concurrent access**: Main actor only; `open`, `bringForward` and `onClose` run on it.
- **Error states**: The set has no errors of its own: an owner that cannot open a key returns `nil` (and logs why), and restore drops that key.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: Not applicable: every call is synchronous.
- **Quit with windows open**: An owner whose window manager suppresses `onClose` for closes made while the app terminates (the project window manager does) keeps those keys in the list, so they reopen at the next launch.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `setting` | `UserSetting<[String]>` | none | Where the ordered key list persists; the owner names it. |
| `open` | `(key, activates, onClose) -> Controller?` | none | Makes the key's window, or returns `nil` when it cannot. |
| `bringForward` | `(Controller) -> Void` | none | Shows the window already open for a key. |

## Deep Linking

Not applicable: the set defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the set has no user-facing text.

## Accessibility Options

Not applicable: the set presents nothing.

## Feature Flags

Not applicable: the set contains no feature-flag reference.

## Analytics

Not applicable: the set contains no analytics call.

## Privacy

The keys (for the File Browser, absolute directory paths) are stored in the app's local preference store and sent nowhere.

## Logging

Not applicable: the set logs nothing; an owner logs why its `open` declined.

## Platform Notes

- **SwiftUI**: `openWindow(id:value:)` with a value-keyed `WindowGroup` gives one window per value; the persisted list replaces scene restoration when the app restores on its own terms.
- **Compose**: Desktop: a `mutableStateMapOf<String, WindowState>` rendered as `Window`s, persisted to preferences.
- **React/Web**: Not applicable to a single-page app; an Electron host keeps a `Map<string, BrowserWindow>` and the list in its store.
- **AppKit / UIKit**: AppKit: `KeyedWindowSet<Controller: AnyObject>` in `AgenticDeveloperHubSDKMacOS`, over any window controller type. UIKit: one `UIScene` per key, keyed through `NSUserActivity`.
- **WinUI 3**: A `Dictionary<string, Window>` with the list in `ApplicationData.LocalSettings`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/WindowManager/KeyedWindowSet.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The set is generic over the controller and builds windows through closures rather than owning a window type.
**Rationale**: The File Browser opens its windows through the project window manager, which must keep knowing about them; the git window builds its own. Closures let both share the bookkeeping without the set depending on either.
**Approved**: pending

**Decision**: The persisted setting is passed in rather than named by the set.
**Rationale**: The File Browser's list already lives under `open_file_browser_directories`; taking the setting keeps remembered windows restoring across the upgrade that moved the File Browser onto the set.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |

`separation-of-concerns` passes because the set keeps the per-key bookkeeping only; building, showing and closing windows stay with the owner. `unit-test-coverage` passes: `KeyedWindowSetTests` covers open-twice, close, restore dropping failures, and order, against fake controllers and an in-memory settings store. `data-integrity` passes because the list never holds a key twice and drops only keys whose window failed to open.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
