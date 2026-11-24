---
id: 2a298bb0-d8af-40aa-8fec-42dd3b1d8f43
title: "Partner Review"
type: ingredient
version: 1.0.4
status: review
language: en
created: 2026-11-14
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The record of one commit the partner reviews or declines to review, its queued-to-done lifecycle state, and the start payload returned by partner_review_start."
platforms:
  - swift
  - macos
tags:
  - foundation
  - partner
  - review
  - data-model
depends-on:
  - 79810488-c613-4f9b-af2a-4ba9d8ee1c26
related: []
references: []
approved-by: ""
approved-date: ""
---

# Partner Review

## Overview

`PartnerReview` is the record of one commit the partner reviews, or declines to review: the repository and commit it names, who wrote it, where its review stands (`PartnerReviewState`), the session that ran it, its summary or skip reason, and the later commits on its branch that touch the same files. `PartnerReviewStart` is the payload `partner_review_start` returns: the review plus the worktree, fix branch, tip diff and steps the partner needs to do it. Both are plain data; the logic that moves a review through its states lives elsewhere. The `partner_review_start` tool is built by the macOS partner feature (`ReviewService`): it encodes the payload with sorted keys and ISO 8601 dates, fills `supersededBy` from the later commits on the branch that touch the same files, and cuts `tipDiff` at 8,000 bytes by default. The macOS store does not use `Codable` for reviews; it writes each field to its own column, with `supersededBy` as a JSON array of strings. None of that is part of this data model.

## Behavioral Requirements

- **state-values**: `PartnerReviewState` MUST be a string-backed, `Codable` and `Sendable` enum with exactly the cases `queued`, `running`, `done`, `failed` and `skipped`, whose raw values are the case names.
- **review-conformances**: `PartnerReview` MUST be a `Codable`, `Sendable`, `Equatable` and `Identifiable` struct whose identity is `id`.
- **review-fields**: `PartnerReview` MUST carry the required fields `id`, `repoID`, `repoPath`, `repoName`, `sha`, `parent`, `branch`, `subject` and `author` (strings), `committedAt` (a date), `state`, and `supersededBy` (strings).
- **review-optional-fields**: `PartnerReview` MUST carry `sessionID`, `startedAt`, `finishedAt`, `summary` and `skipReason` as optional values.
- **initializer-defaults**: The initializer MUST default `state` to `queued`, every optional field to nil and `supersededBy` to an empty list; all other fields are required.
- **superseded-by-meaning**: `supersededBy` MUST keep the SHAs it is given in the order given, through encode and decode, and the type MUST NOT add, drop or reorder them; the field is documented in `PartnerReview.swift` as the SHAs of later commits on the same branch that touch the same files, which the reviewer is told about; it does not mean the review was replaced.
- **no-lifecycle-rules**: The type MUST NOT enforce state transitions or tie optional fields to a state; it does not check that `skipReason` is set only when `state` is `skipped`, that `finishedAt` follows `startedAt`, or that `summary` is set only when `done`.
- **coding-keys**: Encoding and decoding MUST use the compiler-synthesised keys, equal to the property names; no custom keys or date strategy is set by the type, so the coder in use decides how `committedAt`, `startedAt` and `finishedAt` are written.
- **optional-omitted**: A nil optional field MUST be left out when encoded, as the synthesised encoder does, and a missing optional key MUST decode as nil.
- **required-keys**: Decoding MUST fail when a required key, including `supersededBy` and `state`, is missing, and when `state` holds a value that is not one of the five cases.
- **equality**: Two reviews MUST be equal only when every field is equal.
- **start-payload**: `PartnerReviewStart` MUST be a `Codable`, `Sendable` and `Equatable` struct with `review`, `worktreePath`, `fixBranch` and `tipDiff` (strings) and `steps`, a list of `PartnerJobStep`; its initializer MUST take all five with no defaults.
- **start-source**: `PartnerReviewStart` MUST allow an empty `worktreePath` and `tipDiff` and an empty `steps` list, because a skipped review comes back with those empty; the type MUST NOT reject them.

## Appearance

Not applicable — this is a data model, not a visual component.

## States

Not applicable — this is a data model, not a visual component.

## Accessibility

Not applicable — this is a data model, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-review-001 | initializer-defaults | `PartnerReview(id: "r", repoID: "repo", repoPath: "/r", repoName: "demo", sha: "abc", parent: "p", branch: "main", subject: "s", author: "a", committedAt: any date)`. | `state` is `queued`; `sessionID`, `startedAt`, `finishedAt`, `summary` and `skipReason` are nil; `supersededBy` is empty. |
| partner-review-002 | state-values | Encode each of the five states to JSON. | The strings `queued`, `running`, `done`, `failed`, `skipped`. |
| partner-review-003 | required-keys, state-values | Decode a state from the JSON string `"cancelled"`. | Decoding throws. |
| partner-review-004 | optional-omitted | Encode a review with nil optionals, then decode the result. | The JSON has no `sessionID`, `startedAt`, `finishedAt`, `summary` or `skipReason` key and decoding returns an equal review. |
| partner-review-005 | required-keys | Decode a review JSON object without `supersededBy`. | Decoding throws a missing-key error. |
| partner-review-006 | equality | Two reviews equal except `summary` is nil in one and `"x"` in the other. | They are not equal. |
| partner-review-007 | review-conformances | Read `id` on a review whose `id` is `r1`. | The `Identifiable` identity is `r1`. |
| partner-review-008 | no-lifecycle-rules | Construct a review with `state` `done` and `startedAt` nil and `skipReason` `"x"`. | It is accepted unchanged. |
| partner-review-009 | start-payload | Build a `PartnerReviewStart` with a review, `worktreePath` `/w`, `fixBranch` `fix/x`, `tipDiff` `d` and one step; encode and decode. | The decoded value equals the original. |
| partner-review-010 | superseded-by-meaning | A review with `supersededBy` `["s2", "s3"]`; encode and decode. | The decoded `supersededBy` equals `["s2", "s3"]` in that order. |
| partner-review-011 | review-fields | Build a review with every required field set to a distinct value and read each back. | Each of `id`, `repoID`, `repoPath`, `repoName`, `sha`, `parent`, `branch`, `subject`, `author`, `committedAt`, `state` and `supersededBy` returns the value given. |
| partner-review-012 | review-optional-fields | Build a review with `sessionID` `"s"`, `startedAt`, `finishedAt`, `summary` `"x"` and `skipReason` `"y"` set; encode and decode. | All five optionals decode to the values given. |
| partner-review-013 | coding-keys | Encode a review with every field set, with a plain `JSONEncoder` and read the object's keys. | The keys equal the property names: `id`, `repoID`, `repoPath`, `repoName`, `sha`, `parent`, `branch`, `subject`, `author`, `committedAt`, `state`, `sessionID`, `startedAt`, `finishedAt`, `summary`, `skipReason`, `supersededBy`. |
| partner-review-014 | required-keys | Decode a whole review JSON object whose `state` is `"cancelled"` and whose other keys are valid. | Decoding throws. |
| partner-review-015 | equality | Two reviews built from identical field values. | They are equal. |
## Edge Cases

- **Null / empty input**: Empty strings are accepted for every string field; `supersededBy` may be empty (the default); `summary` and `skipReason` are nil until something sets them. The type validates nothing.
- **Boundary values**: `supersededBy` may hold any number of SHAs and keeps their order; a review may name itself or an unknown SHA, because the type does not check.
- **Concurrent access**: Both structs are `Sendable` values; copies are independent. Which writer wins when two update the same review is decided by the store that holds the reviews, not by this type.
- **Error states**: Decoding a missing required key, a wrong-typed value or an unknown state raises a decoding error, as **required-keys** requires; encoding cannot fail for these field types.
- **Offline / disconnected state**: Not applicable: the type is data and performs no network access.
- **Cancellation**: Not applicable: the type has no asynchronous operation.
- **Inconsistent combinations**: A `skipped` review with no `skipReason`, a `done` review with no `summary` and a `running` review with no `startedAt` are all representable; consumers MUST handle the optional fields as possibly nil in every state.

## Configuration

None: the types read no environment variable or settings key. A caller supplies every field except those with the defaults set by **initializer-defaults**.

## Deep Linking

Not applicable: it defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the source contains no user-facing string literal; `subject`, `author` and `summary` are data supplied by callers.

## Accessibility Options

Not applicable: it presents no UI, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: A commit's repository path and name, SHA, parent, branch, subject and author, the review's summary and a diff of the branch tip in `PartnerReviewStart`; these are the user's source-control data and can include other people's names. `tipDiff` and `summary` can also contain secrets that were committed to source, such as keys or tokens, so consumers MUST treat them as sensitive and avoid logging or persisting `tipDiff`.
- **Storage**: None by these types; the macOS partner store persists reviews. The Git window reads a review's state, summary, skip reason and id from that store, read-only, through `PartnerGitReviews` (recipe `workspace/git/git-views`, "Reviews"), and shows every review, superseded included: when a sha has more than one row, the latest wins (finished, else started, else committed last; on a tie the one inserted last).
- **Transmission**: None by these types; `PartnerReviewStart` is returned by the `partner_review_start` tool to the partner process.
- **Retention**: None beyond the lifetime of the value; the store decides how long reviews are kept.

## Logging

Not applicable: the source calls no logging API.

## Platform Notes

- **SwiftUI**: Source is `Core/Partner/PartnerReview.swift`, plain structs and one enum importing only `Foundation`; they use synthesised `Codable`. `Identifiable` lets a SwiftUI `List` or `ForEach` use a review directly.
- **Compose**: Kotlin data classes with `kotlinx.serialization` `@Serializable`; the enum serialises by name; give optional fields `= null` defaults and use `Json { explicitNulls = false }` to omit nulls, and keep required fields free of defaults so a missing key fails; dates need a serializer for the chosen format.
- **React/Web**: TypeScript interfaces with a string-literal union for the state and optional properties; JSON omits absent optionals naturally; dates travel as strings and need parsing at the edge.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic.
- **WinUI 3**: C# `record` types with `System.Text.Json`; use `JsonStringEnumConverter` with camelCase naming for the state, `JsonNamingPolicy.CamelCase`, nullable reference or value types for the optional fields and `DefaultIgnoreCondition = WhenWritingNull` to omit nil. Require `supersededBy` and `state` with the `required` keyword so a missing key fails as in Swift. Swift's default `Date` coding (`deferredToDate`) is a number of seconds since 2001-01-01, while `System.Text.Json` writes ISO 8601 by default; the `partner_review_start` tool also encodes ISO 8601, so the default matches it, and a port that uses the default Swift coding needs a converter. Bind a list to an `ObservableCollection<PartnerReview>`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerReview.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The models carry no lifecycle rules.
**Rationale**: They are plain data; the store and the review service that move a review between states own the transitions, so the types stay valid for every state a database row can hold.
**Approved**: pending

**Decision**: `supersededBy` lists later SHAs on the older review.
**Rationale**: When a review starts, the commits after it on the branch that touch the same files are recorded on the review, so the reviewer sees what changed since and the record keeps a pointer to them.
**Approved**: pending

**Decision**: `PartnerReviewStart` has no default values.
**Rationale**: The payload is built whole by the review service and returned whole as the tool result; every part is always supplied, and a part with nothing to give (a skipped review) is passed empty rather than defaulted.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the file holds only data shapes; persistence, transitions and tool handling belong to the macOS partner store and review service. `unit-test-coverage` passes: `PartnerReviewConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Partner/PartnerReviewConformanceTests.swift`) has one test for each of the fifteen vectors.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.4 | 2026-11-16 | Mike Fullerton | Storage: which of a sha's reviews the Git window shows. |
| 1.0.3 | 2026-11-16 | Mike Fullerton | Git window Phase 4: reviews read by the Git window |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerReviewConformanceTests.swift, 15 of 15 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved ReviewService and store behavior to the Overview, made superseded-by-meaning and start-source testable, added vectors 011-015, added depends-on Partner Job, tightened Compose and WinUI notes, and added secret-handling guidance for tipDiff and summary. |
