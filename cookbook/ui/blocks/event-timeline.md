---
id: 890b37b6-fbbe-4e65-a13a-bae923766daa
title: "EventTimeline"
type: recipe
version: 1.0.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A vertical timeline of events: each row a state-toned status dot on a connector line, the time, the title and an optional markdown detail; the state is also named in text."
platforms:
  - typescript
  - web
tags:
  - block
  - timeline
  - events
  - ui
ingredients: []
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---
# EventTimeline
## Overview
`EventTimeline` in `@adh-sdk/ui` renders `events` (`TimelineEvent[]`) as an `<ol>` in the order given. Each row has a `StatusDot` toned by the event's `state`, a thin connector to the next row, the time (formatted by `formatTime`, default `toLocaleString`) inside a `<time>`, the title, and the `detail` markdown under it. `ui` has no markdown dependency: the caller passes `renderMarkdown`, and without one the detail is plain text.
## Ingredients
None: the block composes `StatusDot`, `EmptyState` and the shared `cn` helper directly.
## Integration Requirements
- **render-row-per-event**: The block MUST render an `<ol>` with one `<li>` per event, in the order given (no sorting).
- **tone-by-state**: Each row's `StatusDot` MUST use a tone from the state: info is neutral, running is blue, done is success, warning is orange, failed is error. A missing state means info.
- **pulse-running**: A running event's dot MUST pulse; no other state pulses.
- **name-state**: Each row MUST carry its state name ("info", "running", "done", "warning", "failed") as visually hidden text, and the dot MUST be decorative.
- **render-time**: Each row MUST show the time inside `<time dateTime={iso}>` in mono dim text, formatted by `formatTime`, default `new Date(iso).toLocaleString()`.
- **render-detail**: A detail MUST render through `renderMarkdown` when given, else as plain text in a `<p>`; no detail renders nothing.
- **connect-rows**: Rows MUST be joined by a thin vertical connector line; the last row has none.
- **show-empty**: An empty list MUST show `emptyLabel` (default "No events yet.") in the shared `EmptyState` and no `<ol>`.
- **forward-class**: The block MUST merge `className` into its root element.
## Layout
```
 o  2026-11-21, 9:00 AM         (done)
 |  Built the page
 |  detail markdown...
 o  2026-11-21, 9:05 AM         (running, pulsing)
    Publishing
```

- Dot (`StatusDot`, size 10): info `neutral`, running `blue` plus `animate-pulse`, done `success`, warning `orange`, failed `error`; decorative.
- Connector: `w-px flex-1 bg-apt-border` in the dot's column, absent on the last row.
- Time: `font-mono text-xs text-apt-text-dim`. Title: `text-sm text-apt-text`. Detail: `text-sm text-apt-text-muted`.
- State name in `sr-only`.
## Shared State
The block holds no state; every prop flows down into a composed part.
## Integration Test Vectors
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-row-per-event | three events | an `<ol>` with three items in the given order |
| T2 | tone-by-state, name-state | one event per state | rows carry "info", "running", "done", "warning", "failed"; dot classes follow the tone table |
| T3 | pulse-running | one running and one done event | only the running dot has `animate-pulse` |
| T4 | render-time | an ISO time | a `<time>` with that `dateTime`; with `formatTime` the formatted text shows |
| T5 | render-detail | an event with a detail, with and without `renderMarkdown` | the renderer's output, else a `<p>` with the text |
| T6 | connect-rows | three events | two connectors |
| T7 | show-empty | `events={[]}`, with and without `emptyLabel` | the label shown, no list |
| T8 | forward-class | `className="mt-2"` | the root carries it |
## Edge Cases
- **No state** reads as info.
- **No detail** renders no detail element.
- **An unparseable time** is passed through `formatTime` as given; the default shows what `Date` produces.
- **Keys are indices**: the list is display-only and has no stable ids.
## Platform Notes
- **Swift / SwiftUI**: Not applicable until a SwiftUI port; translate EventTimeline as a `VStack` of rows.
- **Kotlin / Compose**: Not applicable until a Compose port; use `Column` with one row composable per item.
- **React / Web (TypeScript)**: Exported from `@adh-sdk/ui` (`@adh-sdk/ui/blocks/event-timeline`). `StatusDot` and `EmptyState` come from `@adh-sdk/ui`.
- **AppKit / UIKit**: Not applicable until a native port; use `NSStackView`/`UIStackView`.
- **WinUI 3**: Not applicable until a WinUI port; use `StackPanel`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/event-timeline.tsx` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Markdown rendering is injected by the caller.
**Rationale**: `ui` stays free of a markdown dependency, the same way `DescriptionCard` does it.
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
