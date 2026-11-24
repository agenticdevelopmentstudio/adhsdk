---
id: 770a6a4c-6527-4e4d-a9d9-14e5b1cf25fd
title: "Known Terminals"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The catalog of macOS terminal apps the toolkit recognizes, each with a display name, bundle id and TERM_PROGRAM values, and the lookup that matches one by TERM_PROGRAM."
platforms:
  - swift
  - macos
tags:
  - foundation
  - terminal
  - catalog
depends-on: []
related:
  - 54413e61-d82d-4526-b496-5daf917ce877
  - e74bbbe4-cc41-40dc-a063-e262522c2301
references: []
approved-by: ""
approved-date: ""
---

# Known Terminals

## Overview

This is the one list of terminal applications the toolkit knows how to enumerate, match by the `$TERM_PROGRAM` environment value and bring to the front. `KnownTerminal` is one entry: a human-readable `displayName`, the macOS `bundleID` used to find a running instance, and the `termProgramValues` that identify it. `KnownTerminals.all` is the default catalog (iTerm2, Terminal.app, Warp and VS Code), and `KnownTerminals.match(termProgram:in:)` finds the entry whose values contain a given `TERM_PROGRAM`. Three callers read it: the window-activation tester ([adhsdk.ingredient.system.system-windows.window-activation](cookbook:54413e61-d82d-4526-b496-5daf917ce877)) lists every terminal in its inventory, the bring-terminal-to-front strategy matches a session's `TERM_PROGRAM` to a bundle id and activates the app, and the conversation summary ([adhsdk.ingredient.foundation.stenographer.conversation-summary-dto](cookbook:e74bbbe4-cc41-40dc-a063-e262522c2301)) names a session's terminal. This code holds a value type, a constant list and one lookup; running-app lookup and activation live in the window-activation code ([adhsdk.ingredient.system.system-windows.window-activation](cookbook:54413e61-d82d-4526-b496-5daf917ce877)), outside these sources.

## Behavioral Requirements

- **entry-fields**: A `KnownTerminal` MUST carry `displayName` (String), `bundleID` (String) and `termProgramValues` (array of String), all immutable.
- **entry-conformance**: `KnownTerminal` MUST be a `public struct` that is `Sendable` and `Equatable`.
- **entry-memberwise-init**: `init(displayName:bundleID:termProgramValues:)` MUST be public and MUST require all three values.
- **display-name-use**: `displayName` MUST be a human-readable product name.
- **bundle-id-use**: `bundleID` MUST be a macOS bundle identifier.
- **term-program-values-plural**: `termProgramValues` MUST allow more than one value for a terminal, because a terminal may expose distribution variants that share one bundle id.
- **catalog-single-source**: `KnownTerminals.all` MUST be the single source of truth for terminal enumeration, matching and activation; callers MUST NOT keep a second list.
- **catalog-iterm2**: `all` MUST contain iTerm2 with bundle id `com.googlecode.iterm2` and `TERM_PROGRAM` value `iTerm.app`.
- **catalog-terminal-app**: `all` MUST contain Terminal.app with bundle id `com.apple.Terminal` and `TERM_PROGRAM` value `Apple_Terminal`.
- **catalog-warp**: `all` MUST contain Warp with bundle id `dev.warp.Warp-Stable` and `TERM_PROGRAM` value `WarpTerminal`.
- **catalog-vscode**: `all` MUST contain VS Code with bundle id `com.microsoft.VSCode` and `TERM_PROGRAM` value `vscode`.
- **catalog-no-duplicates**: No `TERM_PROGRAM` value MAY appear in two entries of `all`, so the default catalog never depends on first-match order.
- **catalog-order**: `all` MUST list the terminals in the order iTerm2, Terminal.app, Warp, VS Code; the order is the order of enumeration and of a first-match win.
- **catalog-extensible**: A caller MAY pass its own list to `match(termProgram:in:)` instead of `all`, so more terminals can be supported without patching the toolkit.
- **match-contract**: `match(termProgram:in:)` MUST return the first entry whose `termProgramValues` contains `termProgram`, and nil when no entry does, including for an empty `termProgram` with the default catalog (no default entry lists an empty value) and for an empty catalog.
- **match-exact**: Matching MUST compare the whole value and be case sensitive; `iterm.app` does not match `iTerm.app`.
- **match-default-catalog**: `match` MUST default its catalog to `all`.
- **type-shape**: `KnownTerminals` MUST be a caseless `public enum` namespace that cannot be instantiated.
- **no-activation-here**: This code MUST NOT look up running apps or activate one; the callers do, using `bundleID`.

## Appearance

Not applicable — this is a data catalog and a lookup function, not a visual component.

## States

Not applicable — this is a data catalog and a lookup function, not a visual component.

## Accessibility

Not applicable — this is a data catalog and a lookup function, not a visual component.

## Conformance Test Vectors

No test sits beside the source file. Vector 007 comes from `testAppMatchesAgentOrTerminalByPrefix`, which reaches `match` through the conversation summary; the others follow from the source's own values and logic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| known-terminals-001 | match-contract, catalog-iterm2 | `match(termProgram: "iTerm.app")` | the iTerm2 entry, bundle id `com.googlecode.iterm2` |
| known-terminals-002 | match-contract, catalog-terminal-app | `match(termProgram: "Apple_Terminal")` | the Terminal.app entry, bundle id `com.apple.Terminal` |
| known-terminals-003 | match-contract, catalog-warp | `match(termProgram: "WarpTerminal")` | the Warp entry, bundle id `dev.warp.Warp-Stable` |
| known-terminals-004 | match-contract, catalog-vscode | `match(termProgram: "vscode")` | the VS Code entry, bundle id `com.microsoft.VSCode` |
| known-terminals-005 | match-contract | `match(termProgram: "ghostty")` | nil |
| known-terminals-006 | match-exact | `match(termProgram: "iterm.app")` | nil, because the comparison is case sensitive |
| known-terminals-007 | display-name-use, match-contract | a session with `TERM_PROGRAM` `iTerm.app`, app filter `ITERM` (`testAppMatchesAgentOrTerminalByPrefix`) | the filter matches (by prefix on the raw `TERM_PROGRAM` or the matched `displayName`, case ignored), and a filter of `ghostty` does not |
| known-terminals-008 | match-contract | `match(termProgram: "")` | nil |
| known-terminals-009 | catalog-extensible, term-program-values-plural | a custom catalog with one entry holding values `a` and `b`; `match(termProgram: "b", in: custom)` | that entry |
| known-terminals-010 | catalog-extensible | `match(termProgram: "iTerm.app", in: [])` | nil |
| known-terminals-011 | catalog-order | the `displayName` of each entry of `all` | iTerm2, Terminal.app, Warp, VS Code, in that order |
| known-terminals-012 | match-contract | a custom catalog with two entries that both list `x`; `match(termProgram: "x", in: custom)` | the first of the two |
| known-terminals-013 | entry-conformance | two `KnownTerminal` values built with the same three arguments | equal |
| known-terminals-014 | catalog-no-duplicates | every `termProgramValues` value across the entries of `all` | no value appears in two entries |
## Edge Cases

- **Empty or missing input**: an empty `TERM_PROGRAM`, as in a headless session with no terminal, returns nil (see `#requirements/match-contract`).
- **Unknown terminal**: a `TERM_PROGRAM` no entry lists, such as Ghostty, MUST return nil; callers fall back, for example the conversation summary shows the raw value as the terminal's name.
- **Case and whitespace**: matching is exact, so `Iterm.app` or `iTerm.app ` returns nil; the caller passes the environment value as read.
- **Duplicate values across entries**: the first entry in catalog order wins; the default catalog has no duplicates (`#requirements/catalog-no-duplicates`).
- **Empty custom catalog**: `match` returns nil (see `#requirements/match-contract`).
- **Terminal not running**: the lookup does not check for a running app; a caller that finds no running instance for the `bundleID` treats the terminal as not running (`BringTerminalToFrontStrategy` returns false).
- **Terminal embedded in another app**: VS Code's integrated terminal reports `vscode`, so a session there matches the VS Code entry and activation brings the editor forward, not a window or tab.
- **Variant with a shared `TERM_PROGRAM` value and a different bundle id**: `match` keys on `TERM_PROGRAM` alone and the entry supplies one `bundleID`, so a variant app that reports the same value as another entry but has a different bundle id matches that entry and activation looks up an app that may not be running. Support such a variant as its own entry only if it reports a distinct value; otherwise the entry would need several bundle ids, which `KnownTerminal` cannot hold.
- **Concurrent access**: the catalog is an immutable `static let` of `Sendable` values, so concurrent reads are safe.
- **Error and offline states**: this code makes no I/O call and has no error path.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| catalog | array of `KnownTerminal` | `KnownTerminals.all` | The list `match` searches; a caller passes a custom list to add terminals. |

## Deep Linking

Not applicable: this catalog defines no URL or deep link.

## Localization

`displayName` is a hardcoded product name (iTerm2, Terminal.app, Warp, VS Code) used in log output and conversation summaries; the names are brand names and carry no string-table entry.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: none; the catalog is static public data and `match` reads only the `TERM_PROGRAM` value passed in.
- **Storage**: none.
- **Transmission**: none.
- **Retention**: none defined by this code.

## Logging

Not applicable: this code makes no log calls; the callers write `displayName` into their own logs.

## Platform Notes

- **SwiftUI**: Not used here; a port would show `displayName` wherever it names a terminal to the user.
- **Compose**: a Kotlin `data class KnownTerminal(val displayName: String, val bundleId: String, val termProgramValues: List<String>)` and a `val all` list; Android has no bundle ids, so a port keys on the platform's package or process name.
- **React/Web**: a TypeScript interface plus a frozen array, and `catalog.find(t => t.termProgramValues.includes(v))` for the match.
- **AppKit / UIKit**: AppKit: feed `bundleID` to `NSRunningApplication.runningApplications(withBundleIdentifier:)` to find a running instance and activate it. UIKit: not applicable, since iOS has no bundle-id lookup of other running apps. The type is a `public struct` with a public memberwise `init` and a caseless `public enum` namespace, and the match is `first { ... }`.
- **WinUI 3**: Use a C# `record KnownTerminal(string DisplayName, string ProcessName, IReadOnlyList<string> TermProgramValues)` with the process name in place of a bundle id, and `catalog.FirstOrDefault(t => t.TermProgramValues.Contains(v))` for the match; Windows Terminal reports `WT_SESSION` rather than `TERM_PROGRAM`, so a port adds its own detection beside the match.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/KnownTerminals.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One catalog serves enumeration, matching and activation.
**Rationale**: Adding a terminal in one place updates the listing, the matching and the activation together, so the activation tester, the bring-to-front strategy and the conversation summary cannot disagree about which terminals exist.
**Approved**: pending

**Decision**: `match` takes the catalog as a parameter that defaults to `all`.
**Rationale**: A caller can pass a custom list to support more terminals without patching the toolkit; the default lets the conversation summary call it with one argument, while the bring-to-front strategy passes its own catalog, which itself defaults to `all`.
**Approved**: pending

**Decision**: Matching is by whole-value equality on `TERM_PROGRAM`.
**Rationale**: The environment value is a fixed token each terminal sets; exact matching cannot confuse two terminals, and the prefix search a user types lives in the conversation summary, not here.
**Approved**: pending

**Decision**: An entry lists several `TERM_PROGRAM` values.
**Rationale**: A terminal may expose more than one value, for distribution variants that share a bundle id; one entry then covers them all. A variant with a different bundle id needs its own entry and its own distinct value.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |

separation-of-concerns passes: the file holds a value type, a constant list and one lookup; running-app lookup and activation live in `BringTerminalToFrontStrategy` and `WindowActivationTester`. unit-test-coverage passes: every vector is covered. Vectors 001 to 006 and 008 to 014 are asserted in `KnownTerminalsConformanceTests.swift` (`Tests/AgenticDeveloperHubSDKCoreTests/Terminal/`), and vector 007 by `testAppMatchesAgentOrTerminalByPrefix`.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (KnownTerminalsConformanceTests.swift, 13 of 14 vectors; 007 already covered by testAppMatchesAgentOrTerminalByPrefix); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Rewrote decision rationales, folded the empty-input requirement into match-contract, added catalog-no-duplicates with a vector, a shared-TERM_PROGRAM edge case, related links and platform notes. |
