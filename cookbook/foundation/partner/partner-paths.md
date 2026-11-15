---
id: 0a3f46c1-aa22-4af3-91f0-6631c9fdddfd
title: "Partner Paths"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Where the partner keeps its files, derived from a home directory and the app's storage token: the partner directory, its files and the per-job skill file."
platforms:
  - swift
  - macos
tags:
  - foundation
  - partner
  - paths
  - file-system
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Partner Paths

## Overview

`PartnerPaths` is a value type that answers one question: where the partner keeps its files. Given a home directory and the app's storage token it derives the partner directory, the MCP config file, the system prompt file, the jobs and reviews directories, the shared Claude skills directory and the skill file for a job. It performs no file access; it only builds locations.

## Behavioral Requirements

- **value-semantics**: `PartnerPaths` MUST be a value type that is `Sendable`, holding exactly the two stored values `home` (a URL) and `token` (a string) given to its initializer.
- **equality**: `PartnerPaths` MUST be `Equatable`, and two values MUST be equal when their `home` and `token` are equal.
- **partner-directory**: `directory` MUST be `home`, then a path component of a dot followed by `token`, then the component `partner`.
- **mcp-config-file**: `mcpConfig` MUST be the file `mcp.json` inside `directory`.
- **system-prompt-file**: `systemPrompt` MUST be the file `system-prompt.md` inside `directory`.
- **jobs-directory**: `jobsDirectory` MUST be the directory `jobs` inside `directory`.
- **reviews-directory**: `reviewsDirectory` MUST be the directory `reviews` inside `directory`.
- **skills-directory**: `skillsDirectory` MUST be `home`, then `.claude`, then `skills`; it MUST NOT depend on `token`.
- **skill-file**: `skillFile(jobID:)` MUST be the file `SKILL.md` inside a directory named `adkitchen-partner-` followed by the job ID, inside `skillsDirectory`.
- **no-file-access**: Every derived location MUST be computed from the two stored values alone; no property or function MAY read, create or check the file system.
- **no-validation**: The type MUST NOT validate `home`, `token` or `jobID`; a caller that takes any of them from outside the app owns checking it before use.

## Appearance

Not applicable — this is a pure value type that derives file locations, not a visual component.

## States

Not applicable — this is a pure value type that derives file locations, not a visual component.

## Accessibility

Not applicable — this is a pure value type that derives file locations, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-paths-001 | mcp-config-file, partner-directory | `home` `/h`, `token` `tok`; read `mcpConfig.path`. | `/h/.tok/partner/mcp.json` (test: pathsDeriveFromHomeAndToken). |
| partner-paths-002 | skill-file, skills-directory | `home` `/h`, `token` `tok`; read `skillFile(jobID: "x").path`. | `/h/.claude/skills/adkitchen-partner-x/SKILL.md` (test: pathsDeriveFromHomeAndToken). |
| partner-paths-003 | partner-directory | `home` `/h`, `token` `tok`; read `directory.path`. | `/h/.tok/partner`. |
| partner-paths-004 | system-prompt-file, jobs-directory, reviews-directory | `home` `/h`, `token` `tok`. | `systemPrompt.path` is `/h/.tok/partner/system-prompt.md`; `jobsDirectory.path` is `/h/.tok/partner/jobs`; `reviewsDirectory.path` is `/h/.tok/partner/reviews`. |
| partner-paths-005 | skills-directory | Two values with the same `home` and different tokens. | Both `skillsDirectory` values are `<home>/.claude/skills`. |
| partner-paths-006 | equality | `PartnerPaths(home: /h, token: a)` against `PartnerPaths(home: /h, token: a)` and against `PartnerPaths(home: /h, token: b)`. | The first pair is equal; the second pair is not. |
| partner-paths-007 | no-file-access | `home` is a directory that does not exist; read every property. | Each returns a URL and nothing is created on disk. |
| partner-paths-008 | no-validation, skill-file | `home` `/h`; read `skillFile(jobID: "../x").path`. | `/h/.claude/skills/adkitchen-partner-../x/SKILL.md`, pinning the unvalidated result so a later decision to validate shows as a deliberate change. |

## Edge Cases

- **Null / empty input**: An empty `token` is not rejected; `directory` is built from the component `.` followed by `partner`, so the result is `/h/./partner` for a home of `/h` (URL path joining keeps the `.` component). An empty `jobID` gives the directory name `adkitchen-partner-`. The type does not guard either (MUST NOT validate, per no-validation).
- **Boundary values**: A `token` or `jobID` that contains a path separator or `..` is joined as written and can place the result outside the intended directory. The type neither detects nor refuses it; the caller owns the check, and `skillFile(jobID:)` takes a raw string, so nothing in the type stops a separator in the job ID from adding path levels.
- **Concurrent access**: The type is an immutable value; copies are safe to read from any thread or actor (it is `Sendable`).
- **Error states**: Nothing can fail; no property or function throws or returns an optional.
- **Offline / disconnected state**: Not applicable: the type performs no network or file access.
- **Cancellation**: Not applicable: every member is a synchronous computation with no suspension point.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `home` | URL | none, required | The directory everything is derived from; the user's home directory in the app. |
| `token` | String | none, required | The app's storage token; the partner directory is `.<token>/partner` under `home`. |
| `jobID` | String | none, required by `skillFile(jobID:)` | Names the per-job skill directory. |

## Deep Linking

Not applicable: it defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the source contains no user-facing string literal; every string is a file or directory name.

## Accessibility Options

Not applicable: it presents no UI, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Only the home URL, the storage token and job IDs a caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: the source calls no logging API.

## Platform Notes

- **SwiftUI**: Source is `Core/Partner/PartnerPaths.swift`, a `public struct` importing only `Foundation`; it uses `URL.appendingPathComponent`. Nothing is SwiftUI-specific, so a SwiftUI host passes it to whatever creates files.
- **Compose**: A Kotlin data class holding a `java.nio.file.Path` home and a string token, with computed properties built by `Path.resolve`; data-class equality matches the `Equatable` requirement.
- **React/Web**: An immutable object or class with getters that join segments using a path utility such as `path.join`; Node only, because a browser has no home directory.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic and uses only `Foundation` URLs.
- **WinUI 3**: A C# `record` (value equality for free) over a `string` home path and `string` token, with expression-bodied properties built by `Path.Combine`; the `Windows.Storage` APIs are not needed because nothing is opened. A Windows port decides what the home directory is (`Environment.GetFolderPath` with `SpecialFolder.UserProfile`), and the shared `.claude/skills` location is the one the `claude` CLI reads, so it must stay under that folder.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerPaths.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The partner directory sits at a dot-prefixed folder named by the token, then `partner`.
**Rationale**: The token is the app's own storage token, so the partner's files live beside the app's other per-user data; the dot keeps the folder hidden under the home directory.
**Approved**: pending

**Decision**: The skills directory ignores the token and lives under `.claude/skills`.
**Rationale**: The skills are read by the `claude` command line tool, which looks in its own folder, not the app's; each job's directory is prefixed `adkitchen-partner-` so the app can recognise its own. The prefix is fixed to the app's name and is not a template value.
**Approved**: pending

**Decision**: `skillFile(jobID:)` takes a raw `String`, not a parsed job-ID type.
**Rationale**: The type is a pure location builder with no notion of a valid ID; the caller that takes an ID from outside the app checks it before calling, so one parsed type would have to live in a layer that owns job identity rather than here.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because the type only computes locations; creating, reading and removing files is left to callers such as the guidelines installer. `input-sanitization` is partial: `token` and `jobID` are joined as written, so a path separator in either changes the result, and the type leaves the check to the caller (see no-validation). `unit-test-coverage` passes: `PartnerPathsConformanceTests` covers all 8 vectors, including the system prompt, jobs, reviews and skills directory locations, equality, the absence of file access and the unvalidated job id.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerPathsConformanceTests.swift, 8 of 8 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Pinned the empty-token and traversal results, recorded the raw-string and fixed-prefix decisions, added an input-sanitization compliance row and removed the duplicated Equatable and installer text. |
