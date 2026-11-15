---
id: 967a7c54-93e4-4181-bd8e-67bbeb26693d
title: "Errors Summary"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Pure function that judges the Errors card once on the server: active count, backlog, total events and the five loudest active issues."
platforms:
  - typescript
  - web
tags:
  - telemetry
  - errors
  - status-server
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Errors Summary

## Overview

`errorsSummary` is the server-side judgment behind the Errors card of the production-visibility
band. Given the live list of `ErrorDTO` rows (GlitchTip issues, each already stamped with the
board's own `active` verdict), it returns one `ErrorsSummary`: how many issues are active, how
many sit in the backlog behind them, how many events every issue carries, and the active issues
worth listing, loudest first. It exists so no client re-derives these figures. It is a
synchronous, pure function with no I/O. `GET /telemetry` in `routes/telemetry.ts` is its one
caller; it attaches the result to the `TelemetrySnapshot` as `errorsSummary` after the rows have
been judged. `TelemetrySnapshot.errorsSummary` is optional: a snapshot without it makes no claim
about errors, and a stored row has no verdict, so the summary exists on the live snapshot only.

## Behavioral Requirements

### Contract

- **function-shape**: `errorsSummary` MUST accept a read-only array of `ErrorDTO` and return an
  `ErrorsSummary` object with exactly the fields `active`, `backlog`, `events` and `top`.
- **purity**: `errorsSummary` MUST NOT mutate the input array or any of its rows.
- **no-side-effects**: `errorsSummary` MUST NOT perform I/O, read the clock, or consult any state
  other than its argument; the same input MUST yield an equal result.
- **no-errors-raised**: `errorsSummary` MUST NOT validate its input or raise an error; the
  caller MUST pass an array of rows shaped like `ErrorDTO` (the parameter type declares it).

### Figures

- **active-count**: `active` MUST equal the number of rows whose `active` field is strictly
  `true`.
- **unjudged-is-backlog**: A row whose `active` is `false` or absent MUST be counted in
  `backlog`, never in `active`: a row with no verdict counts as backlog, never as an incident and
  never as clear.
- **backlog-count**: `backlog` MUST equal the input length minus `active`.
- **events-total**: `events` MUST be the sum of `count` over every input row, active and backlog
  alike, treating a falsy `count` (zero, `NaN`, `undefined`) as 0.
- **empty-input**: For an empty array, `errorsSummary` MUST return all-zero figures and an empty
  `top` (`active` 0, `backlog` 0, `events` 0).

### Top list

- **top-active-only**: `top` MUST contain only rows whose `active` is strictly `true`.
- **top-order**: `top` MUST be ordered by `count` descending, so the list matches its `{count}×`
  labels; GlitchTip sends rows in last-seen order, not by volume.
- **top-tie-order**: Rows with equal `count` MUST keep their relative input order (the sort is a
  stable `Array.prototype.sort` over a copy of the active rows).
- **top-cap**: `top` MUST contain at most `ERRORS_TOP_COUNT` rows, the exported constant `5`.
- **top-rows-unchanged**: Each entry of `top` MUST be the original `ErrorDTO` row, unmodified; the
  summary adds no fields to it.

### Attachment rule (owned by the caller)

- **judged-rows-only**: The caller MUST pass only rows that have been judged, with each row's
  `active` verdict stamped. `errorsSummary` itself cannot tell a judged row from an unjudged one
  (both read as backlog), so the guarantee is the caller's. `GET /telemetry` passes the rows
  returned by its `judged` step and attaches the result every time.

## Appearance

Not applicable — this is a pure computation over data rows, not a visual component.

## States

Not applicable — this is a stateless function, not a visual component; it has no runtime state
machine.

## Accessibility

Not applicable — this is a pure computation with no visual surface or interaction.

## Conformance Test Vectors

Vectors 1 to 4 are the assertions of `telemetry-errors-summary.test.ts`; 5 to 10 are read from the
source. Rows are written id/count/active.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| errors-summary-001 | active-count, backlog-count, events-total (test: "splits active issues from the backlog and totals every event") | a/3/true, b/10/false, c/2/true | `active` 2, `backlog` 1, `events` 15 |
| errors-summary-002 | top-active-only, top-order, top-cap (test: "lists only active issues, loudest first, capped") | quiet/1/true, old-loud/99/false, x0 to x5 with counts 10 to 15, all active | `top` ids are x5, x4, x3, x2, x1; length 5; `old-loud` and `quiet` absent |
| errors-summary-003 | unjudged-is-backlog (test: "never counts an unjudged row as an incident") | one row u/4 with no `active` field | `active` 0, `backlog` 1, `top` empty |
| errors-summary-004 | empty-input (test: "is all zeros for no errors") | empty array | `active` 0, `backlog` 0, `events` 0, `top` empty |
| errors-summary-005 | unjudged-is-backlog | one row with `active: false`, count 7 | `active` 0, `backlog` 1, `events` 7, `top` empty |
| errors-summary-006 | top-tie-order | p/5/true then q/5/true | `top` ids are p, q |
| errors-summary-007 | top-cap | exactly five active rows | `top` has five rows, none dropped |
| errors-summary-008 | purity | Rows a/3/true, b/1/false, c/2/true; a deep copy of the array is taken before the call | After the call the array equals the copy: same order, same field values |
| errors-summary-009 | events-total | an active row with `count` `NaN` and one with count 4 | `events` 4 |
| errors-summary-010 | top-rows-unchanged | one active row | `top[0]` is the same object as the input row |
| errors-summary-011 | top-tie-order, top-cap, edge case equal counts at the cap boundary | Six active rows r1 to r6, all with count 5 | `top` ids are r1, r2, r3, r4, r5; `r6` is absent; `active` 6 |

## Edge Cases

- **Empty input**: an empty array MUST give all-zero figures and an empty `top`.
- **No verdicts at all**: every row without `active` MUST land in `backlog`; `active` MUST be 0 and
  `top` empty.
- **Fewer than five active rows**: `top` MUST hold all of them, loudest first, with no padding.
- **More than five active rows**: only the five with the highest `count` MUST appear; the rest are
  still counted in `active` and `events`.
- **Equal counts at the cap boundary**: the earlier rows in input order MUST win the last slots of
  `top`, because ties keep input order.
- **Falsy `count`**: contributes 0 to `events`. The sort compares `b.count - a.count` without the falsy guard used by
  `events`, so the order of `top` is only defined when every active row has a numeric `count`;
  `ErrorDTO.count` is typed `number`, which is the documented precondition.
- **Backlog volume**: backlog rows add to `events` but MUST NOT appear in `top`.
- **Concurrent access**: not applicable; the function is synchronous and shares no state, so calls
  cannot interleave.
- **Network or offline**: not applicable; the function performs no I/O. A frozen feed
  (`errorsFrozen`) is the caller's concern; the rows it passes are summarized as given.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ERRORS_TOP_COUNT` | number (exported constant) | 5 | Maximum number of active issues in `top`. A compile-time constant, not a runtime setting. |
| `errors` | `readonly ErrorDTO[]` | none (required) | The judged rows to summarize. The only argument. |

## Deep Linking

Not applicable: `errorsSummary` is a pure function with no routes or URLs. Each `ErrorDTO` in `top`
carries its own `permalink`, which passes through unchanged.

## Localization

Not applicable: the function produces numbers and passes rows through; it emits no user-facing
string. The `{count}×` labels mentioned in its doc comment are rendered by clients.

## Accessibility Options

Not applicable: no visual output, so no response to Reduce Motion, Increase Contrast or
Differentiate Without Color.

## Feature Flags

Not applicable: the source reads no flag; the summary is always computed when `GET /telemetry`
builds a snapshot.

## Analytics

Not applicable: the function emits no event and records no metric.

## Privacy

- **Data collected**: None. The function stores nothing.
- **Storage**: None; the result is a transient value attached to one response.
- **Transmission**: It does not transmit. `top` carries the original `ErrorDTO` rows (title,
  culprit, permalink and counts from GlitchTip) into the `GET /telemetry` response unchanged.
- **Retention**: None.

## Logging

Not applicable: the source contains no log call.

## Platform Notes

- **SwiftUI**: Port as a free function over an array of a `Codable` `ErrorDTO` struct returning an
  `ErrorsSummary` struct. `filter`, `reduce` and `sorted(by:)` map one to one (read a missing or NaN count as 0 in the `events` sum); sort an enumerated
  array with the index as the tie-break, because Swift's `sorted` is not documented as stable, to
  keep `top-tie-order`.
- **Compose**: Port as a Kotlin top-level function over `List<ErrorDTO>` returning a data class.
  `filter`, `sumOf` (with a missing or NaN count read as 0) and `sortedByDescending` (stable) plus `take(5)` give the same result.
- **React/Web**: The source is a pure module in `status-server`. `Array.sort` is stable in current
  engines, which `top-tie-order` relies on. Clients render the figures and must not recompute them.
- **AppKit / UIKit**: No UI. Same port as SwiftUI; the figures feed whatever view the Errors card
  uses.
- **WinUI 3**: Port as a static method in a C# class library: count with
  `errors.Count(e => e.Active == true)` using `bool? Active` on an `ErrorDto` record, total with
  `errors.Sum(e => e.Count)`, treating a missing or NaN count as 0 as `events-total` does (for a
  nullable field, `e.Count ?? 0`, and for a `double`, map NaN to 0; use `long` if counts can be large), and build `top` with
  `errors.Where(e => e.Active == true).OrderByDescending(e => e.Count).Take(5)`. LINQ
  `OrderByDescending` is stable, matching the source. In an ASP.NET Core minimal API, call it from
  the `/telemetry` handler and serialize with `System.Text.Json` (camelCase naming policy) so the
  field names `active`, `backlog`, `events` and `top` match the contract. A WinUI client binds to
  the result through an `INotifyPropertyChanged` view model and must not recompute the figures.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/errors-summary.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/status-server/src/routes/telemetry.ts` | confirmed (1.0.2) |
| web | `packages/web/packages/status-server/test/telemetry-errors-summary.test.ts` | confirmed (1.0.2) |

## Design Decisions

**Decision**: Judge the Errors card's figures once on the server, in one pure function.
**Rationale**: The doc comment says "so no client re-derives them"; the test header notes status-web
used to work them out from the raw rows. One copy removes drift between clients.
**Approved**: pending

**Decision**: A row with no `active` verdict counts as backlog.
**Rationale**: The doc comment: "never as an incident and never as clear". An unjudged row must not
raise an alarm or look resolved; the summary is only meant to be attached where every row was judged.
**Approved**: pending

**Decision**: Sort the active rows by `count` descending instead of keeping GlitchTip's order.
**Rationale**: GlitchTip sends issues in last-seen order, not by volume; the list must match its
`{count}×` labels. The cap of five (`ERRORS_TOP_COUNT`) keeps the card short.
**Approved**: pending

**Decision**: `events` totals every row including backlog, and guards falsy `count` there but not in the sort.
**Rationale**: The card reports "how many events all of them carry". The unguarded sort is a small
inconsistency in the source, recorded here so ports do not silently diverge; `ErrorDTO.count` is typed `number`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The function holds one rule and nothing else: it takes no storage, network or clock, so
`separation-of-concerns` passes. `telemetry-errors-summary.test.ts` covers the split, the ordering and
cap, the unjudged row and the empty case, so `unit-test-coverage` is partial: vectors 5 to 10 are
read from the source and have no test, and the falsy-count path has none either.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (telemetry-errors-summary.test.ts, 11 of 11 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Rewrote no-errors-raised and judged-rows-only as RFC 2119 requirements, moved the sort-guard note and the snapshot-field note to Edge Cases and the Overview, marked unit-test coverage partial, dropped the idempotent-operations check, added the cap-boundary tie vector and a concrete purity vector, and spelled out the falsy-count rule in every port note. |
