---
id: 5d0f6a3e-2b8c-4e71-9a4d-7c3e1f9b2a60
title: "Executable Locator"
type: ingredient
version: 1.0.0
status: draft
language: en
created: 2026-11-16
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Finds a command-line tool by name on PATH, then in the install directories a GUI app's PATH leaves out, each directory once."
platforms:
  - swift
  - macos
tags:
  - foundation
  - process
  - path
  - executables
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/Core/Process/ExecutableLocator.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Executable Locator

## Overview

Finds a command-line tool by bare name the way a shell would, then in the install locations a GUI app's inherited `PATH` leaves out. An app started from the Dock or by launchd inherits only the system directories, so a tool installed by Homebrew or into `/usr/local/bin` is invisible to a plain `PATH` walk. `ExecutableLocator` is a `Sendable` value with no knowledge of any particular tool: `find(_:)` answers the first executable of that name, `searchDirectories` says where it looked.

## Behavioral Requirements

- **path-first**: `find(name)` MUST try each `PATH` entry of `environment`, in order, before any extra directory.
- **extra-directories-after**: `find(name)` MUST try `extraDirectories`, in order, after every `PATH` entry.
- **default-extras**: The default `extraDirectories` MUST be `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `/bin`, in that order.
- **de-duplicated**: A directory that appears more than once across `PATH` and `extraDirectories` MUST be tried only at its first place. A trailing `/` MUST NOT make a directory distinct, and an empty or relative (not `/`-led) entry MUST be dropped.
- **first-executable-wins**: `find(name)` MUST return the first `<directory>/<name>` for which `isExecutable` answers true, and MUST NOT test any later candidate.
- **nil-when-absent**: `find(name)` MUST return nil when no candidate is executable.
- **bare-name-only**: `find(name)` MUST return nil without testing any path when `name` is empty or contains `/`.
- **injected-check**: Whether a path is executable MUST be answered only by the injected `isExecutable`, which defaults to `FileManager.isExecutableFile(atPath:)` for a path that is not a directory. The locator MUST NOT run a process.
- **tool-agnostic**: The locator MUST NOT hold any tool-specific location; a tool with locations of its own passes them as `extraDirectories`.

## Appearance

Not applicable: `ExecutableLocator` presents no UI.

## States

Not applicable: the locator is an immutable value; each `find` is computed from its stored fields.

## Accessibility

Not applicable: `ExecutableLocator` presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| executable-locator-001 | path-first, first-executable-wins | PATH `/custom/one:/custom/two`; executable: `/custom/one/gh`, `/custom/two/gh`, `/opt/homebrew/bin/gh` | `/custom/one/gh`, and only that path tested (test: pathEntriesComeFirstInOrder). |
| executable-locator-002 | path-first | PATH `/custom/one:/custom/two`; executable: `/custom/two/gh`, `/opt/homebrew/bin/gh` | `/custom/two/gh` (test: laterPathEntryWinsOverExtraDirectories). |
| executable-locator-003 | extra-directories-after, default-extras | PATH `/usr/bin:/bin`; executable: `/usr/local/bin/gh` | `/usr/local/bin/gh`, after testing `/usr/bin/gh`, `/bin/gh`, `/opt/homebrew/bin/gh` (test: extraDirectoriesAreSearchedAfterPath). |
| executable-locator-004 | extra-directories-after | no PATH; executable: `/opt/homebrew/bin/gh` | `/opt/homebrew/bin/gh` (test: extraDirectoriesAloneWithoutPath). |
| executable-locator-005 | de-duplicated | PATH `/usr/bin:/opt/homebrew/bin/::/usr/bin` | `searchDirectories` is `/usr/bin`, `/opt/homebrew/bin`, `/usr/local/bin`, `/bin`, each tested once (test: repeatedDirectoriesAreSearchedOnce). |
| executable-locator-006 | nil-when-absent | PATH `/usr/bin`; executable: `/usr/bin/git` | `find("gh")` is nil (test: nilWhenAbsent). |
| executable-locator-007 | bare-name-only | `find("")`, `find("bin/gh")` | nil, no path tested (test: nameWithSlashOrEmptyFindsNothing). |
| executable-locator-008 | de-duplicated | PATH `.:bin:/usr/bin`; executable: `./gh`, `bin/gh` | `searchDirectories` starts at `/usr/bin`, and `find(\"gh\")` is nil (test: relativeEntriesAreDropped). |

## Edge Cases

- **Null / empty input**: An empty name finds nothing. A missing or empty `PATH` leaves only `extraDirectories`.
- **Boundary values**: The root directory `/` is kept as `/` and its candidate is `/<name>`.
- **Malformed input**: A name holding `/` is refused rather than resolved relative to a directory, so the locator cannot be steered to an arbitrary path.
- **Concurrent access**: The locator is an immutable `Sendable` value; `isExecutable` MUST itself be safe to call from any thread.
- **Error states**: Not applicable: nothing throws; absence is nil.
- **Offline / disconnected state**: Not applicable: no network access.
- **Cancellation and timeouts**: Not applicable: each call is a bounded, synchronous file-system check per directory.

## Configuration

None beyond the initialiser: `environment` (default: the process environment), `extraDirectories` and `isExecutable`. It reads no settings key.

## Deep Linking

Not applicable: no URL scheme or route.

## Localization

Not applicable: no user-facing string.

## Accessibility Options

Not applicable: no UI.

## Feature Flags

Not applicable: no feature flag.

## Analytics

Not applicable: no analytics call.

## Privacy

- **Data handled**: The `PATH` value of the environment it is given, and the tool name asked for.
- **Storage**: None.
- **Transmission**: None.
- **Retention**: None beyond the value's lifetime.

## Logging

Not applicable: the locator logs nothing; a caller that runs what it found logs that run.

## Platform Notes

- **SwiftUI**: `Core/Process/ExecutableLocator.swift` imports only Foundation; a SwiftUI host uses it unchanged. It is a `public struct ExecutableLocator: Sendable` whose `isExecutable` is an `@Sendable (String) -> Bool`.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic. On iOS there is no `PATH` worth walking and no process to spawn, so the type has no use there.
- **Compose**: A data class holding the environment map, the extra directories and a `(String) -> Boolean` check; `File(dir, name).canExecute()` is the default check.
- **React/Web**: Not applicable in a browser. In Node, split `process.env.PATH` on `path.delimiter` and test with `fs.accessSync(candidate, fs.constants.X_OK)`.
- **WinUI 3**: Split `PATH` on `;`, try each `PATHEXT` extension per directory, and replace the default extra directories with the platform's install roots.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Process/ExecutableLocator.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: `PATH` first, then the extra directories.
**Rationale**: A user who put a tool earlier on their own `PATH` meant that copy; the extra directories only rescue a GUI app whose inherited `PATH` lacks them.
**Approved**: pending

**Decision**: The locator holds no tool-specific location.
**Rationale**: It is a shared foundation component (Build From Shared Components); a caller that knows its own tool keeps its installer and version-manager locations beside its own lookup and can pass them in.
**Approved**: pending

**Decision**: `isExecutable` is injected.
**Rationale**: Tests answer from a set of paths and record what was asked, so order and de-duplication are asserted without touching the file system.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |

`separation-of-concerns` passes because the locator only answers where a tool is; running it is the caller's. `unit-test-coverage` passes: `ExecutableLocatorTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Process/ExecutableLocatorTests.swift`) covers all 7 vectors. `input-sanitization` passes because a name holding `/` or an empty name is refused.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-16 | Mike Fullerton | Initial creation |
