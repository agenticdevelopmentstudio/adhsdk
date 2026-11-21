---
id: 8b6eb57b-458b-4901-9591-01736f0e4153
title: "PhaseChecklist"
type: recipe
version: 1.0.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A checklist grouped by phase: each phase a section with its own \"done / total\", each item a row with a status icon and accessible status name; stopped items struck through and muted."
platforms:
  - typescript
  - web
tags:
  - block
  - checklist
  - progress
  - ui
ingredients: []
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# PhaseChecklist
## Overview

`PhaseChecklist` in `@adh-sdk/ui` renders `phases` (`ProgressPhase[]`). Each phase is a `<section>` whose heading is the phase title with its own count "`{done} / {total}`" from `countProgress` (stopped items leave the total). Each item is an `<li>` with a lucide icon for its status and a visually hidden status name. The types and the counting rule live in `@adh-sdk/ui/lib/progress-count`.
## Ingredients

None: the block composes lucide icons and the shared counting rule directly.
## Integration Requirements

- **render-section-per-phase**: The block MUST render one `<section>` per phase, headed by the phase title.
- **render-phase-count**: Each phase heading MUST show "`{done} / {total}`" computed by `countProgress` over that phase's items only, so stopped items are not in the total.
- **render-row-per-item**: Each phase MUST render a `<ul>` with one `<li>` per item showing the item text.
- **render-status-icon**: Each row MUST show a distinct icon per status (done, in progress, to do, stopped), marked `aria-hidden`.
- **name-status**: Each row MUST carry its status name ("done", "in progress", "to do", "stopped") as visually hidden text.
- **mute-stopped**: A stopped item's text MUST be struck through and use the dim text token.
- **forward-host-attributes**: The block MUST forward `className` and remaining host attributes to its root element.
## Layout

```
Phase title                          1 / 3
  [check]  Renamed                 (done)
  [dot]    Migrating               (in progress)
  [box]    Docs                    (to do)
  [x]      Old shim  (struck, dim) (stopped)
```

- Icons (lucide): done `SquareCheck` (`text-apt-green`), in progress `CircleDot` (`text-apt-gold`), to do `Square` (`text-apt-text-muted`), stopped `SquareX` (`text-apt-text-dim`); all `aria-hidden`, static.
- Status name in `sr-only`: "done", "in progress", "to do", "stopped".
- Stopped text: `line-through text-apt-text-dim`.
## Shared State

The block holds no state; every prop flows down into a composed part.
## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-section-per-phase, render-phase-count | two phases, the first with done/in-progress/todo/stopped items, the second empty | two sections; counts "1 / 3" and "0 / 0" |
| T2 | render-row-per-item | the same phases | four list items |
| T3 | name-status | the same phases | rows carry "done", "in progress", "to do", "stopped" |
| T4 | render-status-icon | the same phases | four `aria-hidden` svg icons |
| T5 | mute-stopped | the same phases | "Old shim" has `line-through` and `text-apt-text-dim`; "Renamed" does not |
| T6 | forward-host-attributes | `phases={[]} className="mt-2" data-testid="pc"` | the root carries both |
## Edge Cases

- **No phases** renders an empty container.
- **A phase with no items** shows "0 / 0" and an empty list.
- **All items stopped** shows "0 / 0".
- **Keys are indices**: the lists are display-only and have no stable ids.
## Platform Notes

- **Swift / SwiftUI**: Not applicable until a SwiftUI port; translate PhaseChecklist as a stack of `Text` and `ProgressView`/`Image(systemName:)` views.
- **Kotlin / Compose**: Not applicable until a Compose port; use `Column`, `Text`, `LinearProgressIndicator`.
- **React / Web (TypeScript)**: Exported from `@adh-sdk/ui` (`@adh-sdk/ui/blocks/phase-checklist`). Types and `countProgress` are in `@adh-sdk/ui/lib/progress-count`; icons come from `lucide-react`.
- **AppKit / UIKit**: Not applicable until a native port; use `NSStackView`/`UIStackView` with `NSProgressIndicator`/`UIProgressView`.
- **WinUI 3**: Not applicable until a WinUI port; use `StackPanel`, `TextBlock`, `ProgressBar`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/phase-checklist.tsx` | confirmed (1.0.0) |
| web | `packages/web/packages/ui/src/lib/progress-count.ts` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The phase count uses the shared counting rule.
**Rationale**: One rule (`countProgress`) keeps every count in a page consistent.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the block's source and its test file in `packages/web/packages/ui/src/__tests__/`, which asserts every requirement above.
## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-11-21 | Mike Fullerton | Initial recipe. |
