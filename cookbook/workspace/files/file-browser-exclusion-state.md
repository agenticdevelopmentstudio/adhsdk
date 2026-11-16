---
id: 5f54f265-0f62-49e6-a311-116863751eef
title: "File Browser Exclusion State"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Shared main-actor switch that says whether file browsers apply the app-wide Excluded patterns, with a change callback for the owner that persists it."
platforms:
  - swift
  - macos
tags:
  - file-browser
  - exclusions
  - observable-state
depends-on: []
related:
  - ab6d7655-9476-4318-8c36-f431686e2d23
  - fa6a7094-40c2-4302-8cf3-742a072f5bb3
references:
  - https://developer.apple.com/documentation/combine/observableobject
  - https://developer.apple.com/documentation/combine/published
  - https://developer.apple.com/documentation/swift/mainactor
approved-by: ""
approved-date: ""
---

# File Browser Exclusion State

## Overview

`FileBrowserExclusionState` is a small non-visual model: one boolean,
`hidesExcludedContent`, that says whether a file browser applies the app-wide
Excluded patterns (Settings, File Browser, Excluded) or sets them aside and
shows everything. The patterns themselves live elsewhere; this object is only
the switch that lets a reader see what the patterns hide without editing the
list to do it.

It is a class, not a value, so that one instance can be handed to several
browsers. A project hands the same instance to every one of its browser panes,
so turning the switch off in one pane shows the hidden files in every pane of
that project. A browser built without being given one creates its own instance
with the switch on, so by default excluded content stays hidden.

The object does not persist anything itself. It reports each real change to an
`onChange` callback, which the owner uses to save the answer (the project
owner saves it per project). Use it whenever several file-browser views must
agree on one show-or-hide-excluded choice and some owner must remember the
choice.

## Behavioral Requirements

- **default-hides-excluded**: Constructing the state with no argument MUST set
  `hidesExcludedContent` to `true`.
- **init-stores-given-value**: Constructing the state with an explicit
  `hidesExcludedContent` argument MUST store that value.
- **init-does-not-notify**: Constructing the state MUST NOT call `onChange`.
- **on-change-nil-by-default**: A newly constructed state MUST have a `nil`
  `onChange`, so a change made before an owner assigns one is not reported to
  anyone.
- **change-notifies-owner**: Assigning `hidesExcludedContent` a value different
  from its current value MUST call `onChange` exactly once, with the new value.
- **same-value-is-silent**: Assigning `hidesExcludedContent` a value equal to its
  current value MUST NOT call `onChange`.
- **notify-after-store**: The `onChange` call MUST happen after the new value is
  stored, so reading `hidesExcludedContent` inside the callback returns the new
  value.
- **notify-is-synchronous**: `onChange` MUST be called synchronously from the
  assignment, on the same actor that made the assignment, with no hop and no
  delay.
- **nil-callback-is-noop**: Assigning a changed value while `onChange` is `nil`
  MUST update `hidesExcludedContent` and MUST NOT fail.
- **callback-replaceable**: `onChange` MUST be a settable property, so an owner
  can assign it after construction and can replace it later.
- **publishes-for-observers**: `hidesExcludedContent` MUST be observable through
  the Combine `ObservableObject` machinery, so a view or controller can
  subscribe to its changes.
- **publisher-fires-before-store**: A subscriber to the published
  `hidesExcludedContent` publisher is notified before the stored value is
  updated, because the property wrapper publishes from the will-set step. A
  subscriber that reads the property back MUST defer the read (the file browser
  view controller hops to the main run loop for this reason, per its source
  comment).
- **publisher-fires-for-equal-values**: Every assignment to the published
  property MUST be visible on the publisher, including an assignment of the
  current value; only `onChange` is guarded against equal values, so a
  subscriber that must ignore repeats applies its own de-duplication (the file
  browser view controller applies `removeDuplicates`).
- **main-actor-isolated**: The type MUST be isolated to the main actor; every
  read, write and callback runs on the main actor.
- **shared-by-reference**: The type MUST be a reference type, so every holder of
  one instance sees the same value after any holder changes it.
- **no-persistence-here**: The type MUST NOT write the value anywhere on its own;
  persistence is the `onChange` owner's job.

## Appearance

Not applicable: `FileBrowserExclusionState` is a non-visual `ObservableObject`
with no view, so it has no corner radius, padding, font, colors, border, shadow
or size. The control that shows and flips the switch belongs to the file
browser view (a "Hide Excluded Content" menu item in the pane's options),
specified with that component.

## States

Not applicable: this object has no visual states. Its only state is the boolean
`hidesExcludedContent`, covered under Behavioral Requirements: `true` (the
default, patterns applied) and `false` (everything shown).

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: no visual surface; value is `true` |

## Accessibility

Not applicable: the object draws nothing and takes no input, so it has no role,
label, focus behavior or tap target. The accessible control that flips it is
part of the file browser view.

## Conformance Test Vectors

The source has no tests beside it, and a search of the package's tests finds
none that construct this type; the vectors below are derived from the
assertions the source itself makes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| exclusion-001 | default-hides-excluded | Construct with no argument | `hidesExcludedContent` is `true` |
| exclusion-002 | init-stores-given-value, init-does-not-notify | Assign `onChange` after constructing with `hidesExcludedContent: false` | `hidesExcludedContent` is `false`; the callback was never called |
| exclusion-003 | on-change-nil-by-default, nil-callback-is-noop | Construct, read `onChange`, then set `hidesExcludedContent = false` | `onChange` was `nil`; value is now `false`; no failure |
| exclusion-004 | change-notifies-owner, notify-after-store | `onChange` records `(arg, state.hidesExcludedContent)`; set `hidesExcludedContent = false` from `true` | One call recorded, `(false, false)` |
| exclusion-005 | same-value-is-silent | State is `true`; set `hidesExcludedContent = true` | `onChange` is not called |
| exclusion-006 | change-notifies-owner | Set `false`, then `true` | Two calls, in order `false` then `true` |
| exclusion-007 | publishes-for-observers, publisher-fires-for-equal-values | Subscribe to `$hidesExcludedContent`, drop the first value, set `true` while already `true` | The subscriber receives one value; `onChange` is not called |
| exclusion-008 | publisher-fires-before-store | Subscriber reads `hidesExcludedContent` synchronously inside its sink while the value changes from `true` to `false` | The read returns `true` (the old value) |
| exclusion-009 | shared-by-reference | Two holders keep one instance; one holder sets `false` | The other holder reads `false` |
| exclusion-010 | callback-replaceable | Set `onChange` to closure A, change the value, replace it with closure B, change it again | A is called once for the first change, B once for the second |
| exclusion-011 | main-actor-isolated, notify-is-synchronous | Change the value from a main-actor test | `onChange` has already run when the assignment statement returns |
| exclusion-012 | no-persistence-here | Change the value with no `onChange` set, then construct a fresh instance | The fresh instance is `true`; nothing was stored |

## Edge Cases

- **Null and empty input**: `onChange` is optional. With it `nil`, a change only
  updates the value (the callback is simply not called). The value is a plain
  `Bool`, so there is no null or empty input to validate. A holder MUST treat
  `nil` as "nobody persists this".
- **Boundary values**: A boolean has two values. Assigning the value the object
  already holds MUST NOT call `onChange`, and the published property still fires
  (see the requirement on equal values), so the two channels disagree on repeats
  by design.
- **Concurrent access**: The type is main-actor isolated, so the compiler keeps
  every access on one actor and changes are serialized. A caller off the main
  actor MUST hop to it first. Ordering of two changes is the order of the
  assignments.
- **Re-entrancy**: `onChange` runs inside the property's did-set. An owner that
  assigns `hidesExcludedContent` again from inside the callback goes through the
  property's observers a second time; the source does nothing to prevent this,
  and the nesting ends only when the nested assignment equals the current value
  (the same-value guard). Owners SHOULD NOT assign the property from the
  callback.
- **Callback retention**: `onChange` is a strong closure reference held by the
  state. An owner that also holds the state (the project owner does) SHOULD
  capture itself weakly in the closure to avoid a cycle; the project owner in
  the same package does so.
- **Error states**: The callback is non-throwing and its return is ignored, so
  the object has no error path. A failure to persist is the owner's concern and
  is invisible here.
- **Offline or disconnected state**: Not applicable: the object does no network,
  file or database access.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hidesExcludedContent` | `Bool` (init argument and published property) | `true` | On applies the Excluded patterns; off shows everything |
| `onChange` | `((Bool) -> Void)?` | `nil` | Called after each real change with the new value, for the owner that persists it |

## Deep Linking

Not applicable: the object is an in-process model with no screen or URL of its own.

## Localization

Not applicable: the object holds no user-facing string. The "Hide Excluded Content"
menu title that flips it is owned by the file browser view.

## Accessibility Options

Not applicable: the object draws and animates nothing, so Reduce Motion, Increase
Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the source reads no feature flag; the switch is a user-facing
setting, not a rollout gate.

## Analytics

Not applicable: the source records no analytics event for a change.

## Privacy

- **Data collected**: None. The object holds one boolean about a viewing
  preference.
- **Storage**: None in this object. The owner persists it through `onChange`
  (the project owner stores it per project, only while the value is off).
- **Transmission**: None; the value never leaves the process through this type.
- **Retention**: Not applicable here; retention is the owner's.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: The source is already an `ObservableObject` with a `@Published`
  property, so a SwiftUI view can hold it as `@ObservedObject` or
  `@EnvironmentObject` and bind a `Toggle` to `hidesExcludedContent`; SwiftUI
  reads the new value on the next render pass, so the will-set timing of the
  publisher does not bite. On newer SDKs the `@Observable` macro with a
  did-set observer is the equivalent.
- **Compose**: Hold a `MutableStateFlow<Boolean>` (or `mutableStateOf`) in a
  `ViewModel` shared by every screen that must agree, initialised to `true`,
  and expose an `onChange` lambda that fires only when the new value differs
  (use `distinctUntilChanged` for the persistence collector). Collection runs
  after the store, so there is no will-set quirk.
- **React/Web**: A single store object (a Zustand or Redux slice, or a context
  with `useSyncExternalStore`) shared by every browser component. Fire the
  persistence callback only on a real change by comparing to the previous
  value. Subscribers see the new value because stores update before notifying.
- **AppKit / UIKit**: Source files:
  `macOS/UI/ViewControllers/FileBrowser/FileBrowserExclusionState.swift` (the
  type), consumed by `FileBrowserViewController` (which subscribes through
  Combine with `removeDuplicates`, `dropFirst` and a main run loop hop, and
  toggles it from a pane-options menu item) and created per project by the
  project workspace. UIKit has no menu-item state to bind, so a port
  subscribes the same way and sets a switch or a menu action state itself.
- **WinUI 3**: Implement a `partial` class that implements
  `INotifyPropertyChanged` (or a `CommunityToolkit.Mvvm` `ObservableObject`
  with `[ObservableProperty] private bool hidesExcludedContent = true;`) and a
  public `Action<bool>? OnChange` field. In the setter, compare with the old
  value and call `OnChange?.Invoke(value)` only when different, after the
  backing field is set. Bind a `ToggleMenuFlyoutItem.IsChecked` or
  `ToggleSwitch.IsOn` with `{x:Bind ViewModel.HidesExcludedContent, Mode=TwoWay}`.
  Share the one instance through the project object. Unlike Combine,
  `PropertyChanged` is raised after the field changes, and WinUI requires
  UI-bound changes on the `DispatcherQueue` thread, which replaces the source's
  main-actor isolation.

## Design Decisions

**Decision**: The switch is a shared class instance, not a per-browser flag.
**Rationale**: The source comment states that a project hands one object to all
of its browser panes so that turning it off in one pane shows hidden files in
every pane of that project.
**Approved**: pending

**Decision**: The object reports changes through an `onChange` callback and does
no persistence itself.
**Rationale**: The source comment says "Called after each change, for the owner
that persists it", keeping storage out of the model so a browser built without
an owner works with an in-memory default.
**Approved**: pending

**Decision**: `onChange` is guarded against same-value assignments, while the
published property is not.
**Rationale**: The did-set guard compares with the old value before calling the
owner, so persistence is not rewritten on a no-op. The published channel is the
property wrapper's own and fires on every assignment; the file browser view
controller de-duplicates on its side.
**Approved**: pending

**Decision**: The default is on (excluded content hidden).
**Rationale**: The source comment says "the default is that excluded content
stays hidden", for both an explicit default argument and a browser that builds
its own state.
**Approved**: pending

**Decision**: Subscribers must not read the value synchronously from the
publisher.
**Rationale**: `@Published` publishes from will-set. The file browser view
controller's source comment records the workaround: it hops to the main run
loop so the new value has landed before the patterns are re-read.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | performance |

The type does one thing, holds a boolean and reports its changes, and leaves
persistence to the owner and display to the file browser view, so it meets
separation-of-concerns. A search of the package's tests finds no test that
constructs it, so unit-test-coverage fails; the conformance vectors above are
derived from the source and no test asserts them yet. The object does no
blocking work (a property assignment and one closure call), which meets
main-thread-freedom.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
