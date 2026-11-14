---
id: e8a2d3a3-259f-43ac-94eb-051d08a42fb1
title: "Tracking Preference Response"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The reply to reading or changing whether Claude session tracking is on: the enabled state, whether the disabled marker is present, and what the change did."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - dto
  - wire
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Tracking Preference Response

## Overview

`TrackingPreferenceResponse` is the one reply shape for both reading and writing the tracking preference, the switch that decides whether Claude's hooks capture session activity. It carries three values: `enabled` (is tracking on), `disabledMarkerPresent` (is the cross-process tracking-disabled marker present) and `outcome` (what the call just did, as a short word). The daemon builds it in `PreferencesService.setTracking(enabled:)` and `currentTracking()` and returns it from `GET` and `POST /preferences/tracking`. This code holds the shape only; installing or uninstalling hooks, reading the marker and mapping failures to HTTP statuses live in `PreferencesService`, `ClaudeHookInstaller` and `PreferenceRoutes`, outside these sources.

## Behavioral Requirements

- **response-fields**: A `TrackingPreferenceResponse` MUST carry `enabled` (Bool), `disabledMarkerPresent` (Bool) and `outcome` (String), all immutable.
- **response-conformance**: The type MUST be a `public struct` that is `Encodable` and `Sendable`; it is written to a reply and never decoded by this code.
- **response-memberwise-init**: `init(enabled:disabledMarkerPresent:outcome:)` MUST be public and MUST require all three values, with no defaults.
- **enabled-meaning**: `enabled` MUST say whether tracking is on after the call.
- **marker-meaning**: `disabledMarkerPresent` MUST report whether the cross-process tracking-disabled marker was present when the reply was built, read from the hook installer.
- **write-enabled-echoes-request**: After a write, `enabled` MUST echo the value that was asked for, not a re-read of the marker, because the app owns the marker and a write through the daemon may run before the app updates it.
- **read-enabled-follows-marker**: After a read, `enabled` MUST be the inverse of `disabledMarkerPresent`.
- **outcome-installed**: A write of `enabled: true` that installed the hooks MUST return outcome `installed`.
- **outcome-already-installed**: A write of `enabled: true` when the hooks were already installed MUST return outcome `already_installed`.
- **outcome-uninstalled**: A write of `enabled: false` that removed the hooks MUST return outcome `uninstalled`.
- **outcome-not-installed**: A write of `enabled: false` MUST return outcome `not_installed` whenever `uninstallHooks()` returns false, which is when there were no hooks to remove and also when the uninstall threw (the installer logs the error and returns false, so the failure is not told apart in the reply).
- **outcome-current**: A read MUST return outcome `current`.
- **outcome-open-string**: `outcome` MUST be an open string, not a closed enum; the five values above are the ones the source writes, and a reader MUST tolerate a value it does not know.
- **failed-install-no-response**: A failed hook install (including an installer whose helper is not an executable file) MUST NOT produce a `TrackingPreferenceResponse`; `setTracking` throws `PreferencesError.hookInstallFailed` and the route replies with the message `Hook install failed: <message>` and status 500.
- **no-logic-here**: The struct MUST hold no logic: no validation, no derived values and no I/O.

## Appearance

Not applicable — this is a data shape, not a visual component.

## States

Not applicable — this is a data shape, not a visual component.

## Accessibility

Not applicable — this is a data shape, not a visual component.

## Conformance Test Vectors

The tests named below drive the daemon code that builds this response; none sits beside the shape. Vectors without a test name follow from the source's logic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tracking-preference-response-001 | outcome-installed, enabled-meaning | `setTracking(enabled: true)` on a fresh installer (`testTrackingInstallsAndUninstallsThroughTheHookInstaller`) | `enabled` true, `outcome` `installed`, the hook settings file exists |
| tracking-preference-response-002 | outcome-already-installed | a second `setTracking(enabled: true)` (same test) | `outcome` `already_installed` |
| tracking-preference-response-003 | outcome-uninstalled | `setTracking(enabled: false)` after an install (same test) | `outcome` `uninstalled` |
| tracking-preference-response-004 | outcome-not-installed | a second `setTracking(enabled: false)` (same test) | `outcome` `not_installed` |
| tracking-preference-response-005 | read-enabled-follows-marker, outcome-current | `currentTracking()` with no marker (`testCurrentTrackingFollowsTheDisabledMarker`) | `enabled` true |
| tracking-preference-response-006 | read-enabled-follows-marker, marker-meaning, outcome-current | `currentTracking()` after `setTrackingDisabled(true)` (same test) | `enabled` false, `disabledMarkerPresent` true, `outcome` `current` |
| tracking-preference-response-007 | write-enabled-echoes-request | `setTracking(enabled: true)` while the marker is present | `enabled` true and `disabledMarkerPresent` true in the same reply |
| tracking-preference-response-008 | response-memberwise-init, response-fields | `TrackingPreferenceResponse(enabled: true, disabledMarkerPresent: false, outcome: "current")` | the three fields hold the values passed |
| tracking-preference-response-009 | response-conformance | encode the value with `JSONEncoder` | the output holds the three fields with Bool, Bool and String values |
| tracking-preference-response-010 | failed-install-no-response | `setTracking(enabled: true)` when `installHooks()` returns `.failed` | throws `PreferencesError.hookInstallFailed`; no response value |
| tracking-preference-response-011 | outcome-open-string | a reader decodes `outcome` `something_new` | the reader accepts it without failing |

## Edge Cases

- **Empty or missing input**: not applicable to the shape; the route rejects an empty body for `POST` with status 400 and the message `Missing body: expected {"enabled": Bool}` (`testTrackingPreferenceRequiresABody`), before any response is built.
- **Malformed body**: the route replies with status 400 and an `Invalid tracking preference body` message; no response shape is built.
- **Marker and request disagree**: after a write, `enabled` may differ from the inverse of `disabledMarkerPresent`, because `enabled` echoes the request and the marker is owned by the app; the source's route comment says the app's marker self-heals at the daemon's next boot. A reader MUST NOT assume the two are always opposites.
- **Repeated writes**: writing the same value twice MUST succeed and report `already_installed` or `not_installed` the second time, so the call is idempotent.
- **Hook install failure**: no response; status 500 with the message `Hook install failed: <installer message>`. Any other thrown error replies 500 with `Tracking update failed: <description>`.
- **Uninstall failure**: `uninstallHooks()` returns false when its work throws, so a write of `enabled: false` that failed to remove the hooks reports `not_installed` with `enabled` false; the installer logs the error.
- **Unknown outcome**: a reader MUST tolerate an `outcome` it does not know.
- **Concurrent access**: the struct is immutable and `Sendable`, so it is safe to share; two simultaneous writes are ordered by the hook installer, outside this code.
- **Error and offline states**: while the daemon is offline there is no response; the app's marker still records the preference and the daemon enforces it at its next boot.

## Configuration

Not applicable: this shape has no configurable option.

## Deep Linking

Not applicable: this shape defines no URL or deep link; it is the body of `GET` and `POST /preferences/tracking`.

## Localization

`outcome` is a machine value for programs to branch on and MUST NOT be shown to the user as written; a UI that reports the result maps each outcome to its own localized text.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag; the value it reports is the tracking preference itself.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: none; the reply holds two Bools and a short status word and names no session, path or person.
- **Storage**: none here; the marker the reply reports is a file the hook installer owns.
- **Transmission**: the reply goes only to the caller of the daemon's local route.
- **Retention**: none defined by this code.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used here; a settings toggle posts `{"enabled": Bool}` and reads this reply to confirm the new state.
- **Compose**: a Kotlin `data class TrackingPreferenceResponse(val enabled: Boolean, val disabledMarkerPresent: Boolean, val outcome: String)` with a serialization annotation; decode `outcome` as a plain string.
- **React/Web**: a TypeScript interface of two booleans and a string; narrow `outcome` with a union plus a fallback for unknown values.
- **AppKit / UIKit**: The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/TrackingPreferenceResponse.swift`: a `public struct` conforming to `Encodable` and `Sendable` with a public memberwise `init`.
- **WinUI 3**: Use a C# `record TrackingPreferenceResponse(bool Enabled, bool DisabledMarkerPresent, string Outcome)` with `System.Text.Json` attributes matching the daemon's property names; bind a `ToggleSwitch` on the settings page to `Enabled` and treat `Outcome` as an opaque string with a fallback for unknown values.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/TrackingPreferenceResponse.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One response shape serves both the read and the write.
**Rationale**: A caller that toggles the preference and a caller that reads it want the same three facts; the `outcome` word (`current` for a read) tells them which call produced it.
**Approved**: pending

**Decision**: `outcome` is a free string rather than an enum.
**Rationale**: The wire stays open to new outcomes without breaking an older reader; the cost is that readers must handle values they do not know.
**Approved**: pending

**Decision**: A write reports the requested `enabled` and, separately, the marker's real state.
**Rationale**: The route's comment says the app owns the cross-process marker so a toggle while the daemon is offline self-heals at the next boot; reporting both lets the caller see when they differ.
**Approved**: pending

**Decision**: A failed install returns an error, not a response with a failure outcome.
**Rationale**: The failure is a thrown error mapped to status 500 with the installer's message, so a caller never mistakes a failed enable for a state.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

separation-of-concerns passes: the struct holds three immutable values and an init; hook installation, marker reading and the HTTP mapping live in `PreferencesService`, `ClaudeHookInstaller` and `PreferenceRoutes`. unit-test-coverage is partial: the five outcome words and the marker-following read are asserted through `PreferencesServiceTests`, but no test constructs the struct directly, checks its encoded form, or covers a write while the marker is present or a failed install, so vectors 007 to 011 rest on the source alone. data-minimization passes: the reply holds two Bools and one status word and no session data.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
