---
id: 9dfb3209-066d-43bf-acdb-ad8b71959858
title: "ProgressSummary"
type: recipe
version: 1.0.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The overall progress line: \"x of y items done\" and a whole percentage over a Progress bar that turns green when everything is done."
platforms:
  - typescript
  - web
tags:
  - block
  - progress
  - summary
  - ui
ingredients:
  - b3a92adc-a28e-4a33-8120-c33f8f0abdf6
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# ProgressSummary
## Overview

`ProgressSummary` in `@adh-sdk/ui` is a count line over a `Progress` bar. It takes `done` and `total`, shows "`{done} of {total} {label} done`" (`label` defaults to "items") and the percentage rounded down (0 when `total` is 0). The bar's accessible name is the same sentence, and its indicator is green when `done === total` and `total > 0`.
## Ingredients

| Name | rdid | Role | Required | Configuration |
|---|---|---|---|---|
| Progress | [adhsdk.ingredient.progress](cookbook:b3a92adc-a28e-4a33-8120-c33f8f0abdf6) | The bar; its value is the percentage | yes | `value` = percent, `aria-label` = the count sentence, `indicatorClassName` green when complete |
## Integration Requirements

- **render-count-text**: The block MUST render the text "`{done} of {total} {label} done`", with `label` defaulting to "items".
- **render-percent**: The block MUST render the percentage as "`{percent}%`" where percent is `floor(done*100/total)`, and 0 when `total` is 0.
- **label-bar**: The block MUST render a `Progress` bar whose value is the percentage and whose `aria-label` is the count sentence.
- **green-when-complete**: The bar's indicator MUST use the `bg-apt-green` token class when `done === total` and `total > 0`, and MUST NOT otherwise.
- **forward-host-attributes**: The block MUST forward `className` and remaining host attributes to its root element.
## Layout

```
{done} of {total} {label} done                 {percent}%
[=========-------------------]  Progress (role=progressbar, aria-label)
```

- Text row: `flex items-baseline justify-between`; count in `text-apt-text`, percentage `font-mono text-apt-text-muted`.
- Complete: `indicatorClassName="bg-apt-green"`; otherwise Progress's default gold.
## Shared State

The block holds no state; every prop flows down into a composed part.
## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-count-text, render-percent | `<ProgressSummary done={1} total={3} />` | "1 of 3 items done" and "33%" |
| T2 | render-count-text | `done={2} total={4} label="steps"` | "2 of 4 steps done" |
| T3 | label-bar | `done={2} total={4}` | a progressbar named "2 of 4 items done", `aria-valuenow` 50 |
| T4 | render-percent, green-when-complete | `done={0} total={0}` | "0%", indicator not green |
| T5 | green-when-complete | `done={3} total={3}` and `done={2} total={3}` | green only for the first |
| T6 | render-percent | `done={199} total={200}` | "99%" |
| T7 | forward-host-attributes | `className="mt-4" data-testid="ps"` | the root carries both |
## Edge Cases

- **0 of 0** is 0% and never green: nothing done is not complete.
- **Percent rounds down** so 100% means everything is done.
- **done above total** is clamped by `Progress` to a full bar.
## Platform Notes

- **Swift / SwiftUI**: Not applicable until a SwiftUI port; translate ProgressSummary as a stack of `Text` and `ProgressView`/`Image(systemName:)` views.
- **Kotlin / Compose**: Not applicable until a Compose port; use `Column`, `Text`, `LinearProgressIndicator`.
- **React / Web (TypeScript)**: Exported from `@adh-sdk/ui` (`@adh-sdk/ui/blocks/progress-summary`). Counts come from `countProgress` in `@adh-sdk/ui/lib/progress-count`.
- **AppKit / UIKit**: Not applicable until a native port; use `NSStackView`/`UIStackView` with `NSProgressIndicator`/`UIProgressView`.
- **WinUI 3**: Not applicable until a WinUI port; use `StackPanel`, `TextBlock`, `ProgressBar`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/progress-summary.tsx` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Percent is floored.
**Rationale**: A rounded 100% could appear while one item is still open.
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
