---
id: 750fe184-d20a-4b58-867b-3edd094d59b4
title: "Commit Graph Layout"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Lane layout for a commit history's graph column: a column, a lane and top and bottom line segments per commit, stateful across pages."
platforms:
  - swift
  - macos
tags:
  - foundation
  - graph
  - commit-history
  - layout
  - git
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/Core/Graph/CommitGraphLayout.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Graph/CommitGraphLayoutTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Commit Graph Layout

## Overview

The lane layout behind a commit history's graph column. Given commits newest first, each with its parent IDs, it places every commit in a column, gives it a lane (a colour index) and describes the line segments to draw in its row: from the row's top edge to the commit's centre, and from the centre to the bottom edge. It is pure Foundation, generic over the commit ID, and stateful so a history loaded page by page lays out exactly as it would in one pass. A view draws from the rows; it never re-derives the layout.

## Behavioral Requirements

- **open-slots**: The layout MUST keep an ordered array of open slots, each expecting one commit ID and carrying a lane.
- **leftmost-expecting-slot**: A commit MUST take the leftmost slot expecting its ID; every other slot expecting it MUST close into it, routing from its own column to the commit's column in the row's top segments.
- **new-commit-slot**: A commit no slot expects MUST take the first empty slot, or a new slot at the right when none is empty, and that slot MUST open with a new lane.
- **first-parent-slot**: The first parent MUST take the leftmost of the commit's own slot and any other slot already expecting it: it inherits the commit's slot, or, when a slot to the left already expects it, the commit's slot closes and its line joins that slot.
- **further-parent-slot**: Each further parent MUST reuse the leftmost slot already expecting it, or else take the first empty slot or a new slot at the right, opening it with a new lane.
- **root-closes-slot**: A commit with no parents MUST close its slot.
- **missing-parent-stays-open**: A parent that never appears MUST leave its slot open for the rest of the layout (a shallow clone) without failing.
- **trim-right**: Empty slots at the right MUST be removed after every commit; empty slots between open ones stay, so open slots never shift columns.
- **monotonic-lanes**: Lanes MUST come from a counter that only increases from 0, assigned when a slot opens and carried with the slot until it closes, so no lane is reused while the layout lives; a view takes it modulo its palette.
- **top-segments**: A row's top segments MUST hold one segment per slot open at the row's top edge, in column order: a slot expecting the commit routes from its column to the commit's column, every other slot passes straight through; each carries its slot's lane.
- **bottom-segments**: A row's bottom segments MUST hold the first-parent edge from the commit's column to its slot, carrying the commit's lane; each further-parent edge from the commit's column to its slot, carrying that slot's lane; and a straight segment for every other open slot, carrying its lane; sorted by `from`, then `to`.
- **row-width**: A row's width MUST be the largest of the slot count at its top edge, the slot count at its bottom edge (both right-trimmed) and the commit's column plus one.
- **stateful-paging**: Appending commits in several calls MUST yield the same rows, in order, as appending them in one call; rows already returned are never revised.

## Appearance

Not applicable: The layout is not a visual component; the view that draws its rows owns the appearance.

## States

Not applicable: The layout is not a visual component; its open slots and lane counter are described under Behavioral Requirements.

## Accessibility

Not applicable: The layout presents no UI.

## Conformance Test Vectors

Segments are written `from→to@lane`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| commit-graph-layout-001 | new-commit-slot, first-parent-slot, root-closes-slot | `C(B)`, `B(A)`, `A()` | Every row column 0, lane 0, width 1. C: top `[]`, bottom `[0→0@0]`; B: top and bottom `[0→0@0]`; A: top `[0→0@0]`, bottom `[]` (test: linearHistoryStaysInColumnZero). |
| commit-graph-layout-002 | further-parent-slot, first-parent-slot | `M(A,B)`, `A(P)`, `B(P)`, `P()` | M col 0 lane 0, bottom `[0→0@0, 0→1@1]`, width 2; A col 0, top and bottom `[0→0@0, 1→1@1]`; B col 1 lane 1, top `[0→0@0, 1→1@1]`, bottom `[0→0@0, 1→0@1]`, width 2; P col 0 lane 0, top `[0→0@0]`, bottom `[]`, width 1 (test: branchAndMergeOpensAndClosesALane). |
| commit-graph-layout-003 | leftmost-expecting-slot, first-parent-slot | `M(A,B)`, `B(P)`, `A(P)`, `P()` | B keeps column 1 with bottom `[0→0@0, 1→1@1]`; A bottom `[0→0@0, 1→1@1]`; P col 0 lane 0, top `[0→0@0, 1→0@1]`, bottom `[]`, width 2 (test: laterSlotExpectingACommitClosesIntoIt). |
| commit-graph-layout-004 | further-parent-slot, trim-right | `O(A,B,C)`, `A(R)`, `B(R)`, `C(R)`, `R()` | O bottom `[0→0@0, 0→1@1, 0→2@2]`, width 3; B bottom `[0→0@0, 1→0@1, 2→2@2]`; C col 2 lane 2, top `[0→0@0, 2→2@2]`, bottom `[0→0@0, 2→0@2]`, width 3; R top `[0→0@0]`, width 1 (test: octopusMergeOpensThreeLanes). |
| commit-graph-layout-005 | missing-parent-stays-open, monotonic-lanes | `A(X)`, `B()`, `C()` with `X` never appended | A col 0 lane 0, bottom `[0→0@0]`; B col 1 lane 1, top and bottom `[0→0@0]`, width 2; C col 1 lane 2, same segments (test: missingParentLeavesLaneOpenWithoutCrash). |
| commit-graph-layout-006 | root-closes-slot, trim-right, monotonic-lanes | `A()`, `B()` | A col 0 lane 0; B col 0 lane 1; both with no segments and width 1 (test: twoRootsBothColumnZeroAfterTrim). |
| commit-graph-layout-007 | stateful-paging | `M(A,B)`, `A(C)`, `C(D)`, `B(D)`, `D(E)`, `E()` appended as 3 + 3 | The same six rows as one append of all six (test: pagingMatchesOneShot). |

## Edge Cases

- **Null / empty input**: Appending no commits returns no rows and leaves the state unchanged.
- **Boundary values**: A commit whose parents are all already expected opens no slot; a history of independent roots stays in column 0 with a new lane each.
- **Concurrent access**: A value type; each copy has its own slots and lane counter. `append` is `mutating`, so callers serialise it through the owner of the value.
- **Error states**: The layout cannot fail. A parent that never appears keeps its slot open; a commit appended twice is laid out again from the current slots.
- **Offline / disconnected state**: Not applicable: The layout has no network access.
- **Cancellation**: Not applicable: The layout runs synchronously over the commits it is given.

## Configuration

None — The layout reads no environment variable or settings key.

## Deep Linking

Not applicable: The layout defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The layout contains no user-facing string.

## Accessibility Options

Not applicable: The layout presents no UI.

## Feature Flags

Not applicable: The layout contains no feature-flag reference.

## Analytics

Not applicable: The layout contains no analytics call.

## Privacy

- **Data handled**: Only the commit IDs and parent IDs its caller appends.
- **Storage**: In memory, for the lifetime of the value.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: The layout calls no logging API.

## Platform Notes

- **SwiftUI**: `CommitGraphLayout<ID: Hashable & Sendable>` in `AgenticDeveloperHubSDKCore` imports only `Foundation`; a view model holds it and appends each page of history, keeping the returned `Row`s beside its commits.
- **Compose**: A class holding a `MutableList<Slot?>` and an `Int` lane counter; `append` returns an immutable list of rows.
- **React/Web**: A class with an array of slots and a lane counter, kept in a ref across page loads so paging stays stateful.
- **AppKit / UIKit**: Identical to the SwiftUI note: the history list's graph column draws each `Row` in its cell, lane modulo its palette.
- **WinUI 3**: A class with a `List<Slot?>`; rows are records with value equality.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Graph/` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The first parent joins a slot to its left that already expects it, rather than always inheriting the commit's slot.
**Rationale**: A branch that forks from a commit already on the main line rejoins it at once, which keeps the graph narrow and the main line in column 0.
**Approved**: pending

**Decision**: First-parent edges carry the commit's lane; further-parent edges carry the lane of the slot they reach.
**Rationale**: A line keeps its colour until it ends, and a merge edge is drawn in the colour of the branch it brings in.
**Approved**: pending

**Decision**: Lanes come from a counter that only increases.
**Rationale**: A colour index is never reused while the layout lives, so two lines that are both visible never share an index by reuse; the view maps the index onto its palette.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the type only lays out IDs it is given; loading history and drawing rows belong to its callers. `unit-test-coverage` passes because `AgenticDeveloperHubSDKCoreTests/Graph/CommitGraphLayoutTests.swift` pins the column, lane, segments and width of every row in each vector above.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
