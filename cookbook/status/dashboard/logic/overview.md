---
id: ba5855cd-bd4c-49be-b7d3-4c3f7f35434e
title: "Overview Projections"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Pure client wording of the server board: wire-indicator translation, headline, window caption and still-unresolved row lookup"
platforms:
  - typescript
  - web
tags: []
depends-on:
  - 15c61cfc-543c-493d-b686-c605b773be83
related:
  - 66cf24b9-04bf-4767-8af9-f82d7e2b5268
  - 43d93a67-c469-40d1-8465-076cd782e1b2
references: []
approved-by: ""
approved-date: ""
---

# Overview Projections

## Overview

This module holds the status dashboard's wording and drawing vocabulary for the server-owned board. Its header comment is explicit that every verdict is the server's: the indicator and its environment-scoped twin (`scope`), which activity rows are unresolved or running (`unresolved` / `running` / `buildInFlight` on each row), the stats-strip counts (`deployCounts`) and the board's freshness all arrive on the wire. What remains here are small, pure, synchronous helpers that map those verdicts to the sign's vocabulary and to words:

- the sign / pill vocabulary — a sign state (one of three values) plus a count.
- the wire-indicator translation map — the one translation from the server's wire-level indicator vocabulary (`operational`/`degraded`/`outage`) to the sign-state vocabulary.
- the activity-window-caption operation — the "24h" / "7d" caption for the window the server chose.
- the headline operation — the headline shared by the mobile hero sign, the desktop top-bar pill and the wallboard pill.
- the still-unresolved operation — whether a feed row is still unresolved against the current board, by looking up the problems the server named as holding it open.

Consumers read the wire-indicator translation map and the still-unresolved operation for the overview tab and (the map alone) the portfolio indicator; the activity-window-caption operation for the stats strip; the headline operation for the hero sign, the top-bar pill and the wallboard pill; and the sign-state vocabulary for the status sign and its sublabel. Types come from Board Types (the activity row, indicator and problem shapes).
## Behavioral Requirements

### Types

- **indicator-state-union**: The sign-state value MUST be exactly one of `"ok"`, `"warn"` or `"down"`.
- **indicator-shape**: An indicator value MUST carry a sign state and a count (a whole number).

### Wire-indicator translation map

- **indicator-map-values**: The wire-indicator translation map MUST map `operational` to `"ok"`, `degraded` to `"warn"` and `outage` to `"down"`.
- **indicator-map-exhaustive**: The wire-indicator translation map MUST have exactly the three keys `degraded`, `operational` and `outage` — one per member of the server's wire-level indicator vocabulary, with no extras.
- **indicator-map-sole-translation**: The wire-indicator translation map MUST be the only place that translates the wire indicator into a sign state; the doc comment names it "The ONLY translation between the two."

### Activity-window-caption operation

- **window-signature**: The activity-window-caption operation MUST take a window-start time and a window-end time and MUST return a text caption.
- **window-hours**: The operation MUST compute the span in hours as the duration between the two times divided by 3,600,000 (milliseconds per hour), rounded to the nearest whole number, with a minimum of 1.
- **window-days**: When the hour count is 48 or more and is a whole multiple of 24, the operation MUST return the caption formed by dividing the hour count by 24 followed by the letter `d` (for example `"7d"`).
- **window-hours-label**: Otherwise the operation MUST return the caption formed by the hour count followed by the letter `h` (for example `"24h"`, `"47h"`).
- **window-min-one-hour**: A window shorter than 30 minutes, zero, or negative MUST be captioned `"1h"`, never `"0h"`.
- **window-server-boundary**: The caller MUST derive both bounds from the board's own reported activity window rather than a hardcoded span; the doc comment forbids a hardcoded caption because the server owns the window's length.

### Headline operation

- **headline-signature**: The headline operation MUST take a sign state and a count and MUST return a text headline.
- **headline-ok**: For sign state `"ok"` the operation MUST return `"ALL SYSTEMS OPERATIONAL"`, ignoring count.
- **headline-warn-singular**: For sign state `"warn"` and count `1` it MUST return `"1 SERVICE NEEDS ATTENTION"`.
- **headline-warn-plural**: For sign state `"warn"` and any other count it MUST return the count followed by `" SERVICES NEED ATTENTION"`.
- **headline-down-singular**: For sign state `"down"` and count `1` it MUST return `"1 PROBLEM"`.
- **headline-down-plural**: For sign state `"down"` and any other count it MUST return the count followed by `" PROBLEMS"`.
- **headline-single-wording**: Every surface that announces the sign's headline (hero sign, top-bar pill accessible name, wallboard pill) MUST obtain it from the headline operation, so they cannot word it differently. An "unknown" state is outside the sign-state vocabulary; callers word that case themselves (for example, showing "Status unknown" or "UNKNOWN").

### Still-unresolved operation

- **unresolved-signature**: The still-unresolved operation MUST take an activity row and a list of the board's current problems (each carrying a target and an onset time) and MUST return true or false.
- **unresolved-server-verdict**: A row whose `unresolved` field is not `true` MUST NOT be revived: the operation returns `false`. It never raises a row the server judged resolved.
- **unresolved-held-open**: For a row with `unresolved: true` and a non-empty `heldOpenBy` list, the operation MUST return true only while some current problem has the row's own target and an onset time listed in `heldOpenBy`. It only looks those problems up and judges nothing itself.
- **unresolved-in-flight**: A row with `unresolved: true` and an empty `heldOpenBy` (a row in flight) MUST keep the server's verdict and return true.
- **unresolved-no-held-open**: A row with `unresolved: true` and no `heldOpenBy` (a backend that sends none) MUST keep the server's verdict and return true.

### Purity and concurrency

- **pure-functions**: Every exported operation MUST be synchronous and pure: no I/O, no logging, no mutation of its inputs, no module state. The result depends only on the arguments.
- **no-throw**: No operation throws on inputs of its declared shapes; malformed values degrade as described under Edge Cases rather than raising.
- **single-threaded**: The module holds no state, so calls cannot interleave and no ordering rule is needed.

## Appearance

Not applicable — this is a pure projection-and-predicate module, not a visual component.

## States

Not applicable — this is a pure projection-and-predicate module, not a visual component.

## Accessibility

Not applicable — this is a pure projection-and-predicate module, not a visual component.

## Conformance Test Vectors

Vectors 001–005 and 006 are traced to the module's own test suite and the board-types parity test; the rest to the operations' own bodies. `H` = 3,600,000 ms (one hour). The problems-to-indicator, deploy-counts and real-environment-deploy operations are no longer in the client (the server judges them and ships `scope`, `deployCounts` and the row `environment`), so they have no vectors here. The module's one row-judging helper is the still-unresolved operation.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| overview-001 | indicator-map-exhaustive, indicator-map-values | Sorted keys of the wire-indicator translation map; its values | `["degraded","operational","outage"]`; `"warn"`, `"ok"`, `"down"` |
| overview-002 | window-hours, window-hours-label, window-days | The activity-window-caption operation on spans of `24H`, `7×24H` and `47H`, each from time `0` | `"24h"`; `"7d"`; `"47h"` |
| overview-003 | window-min-one-hour | The activity-window-caption operation on a span of `60000` ms, from time `0` | `"1h"` |
| overview-004 | window-days, window-hours-label | The caption operation on spans of `48H`, `72H` and `24H`, each from time `0` | `"2d"`; `"3d"`; `"24h"` (stays hours) |
| overview-005 | window-min-one-hour | The caption operation from time `10H` to time `0` (a negative span) | `"1h"` |
| overview-006 | headline-ok | The headline operation with sign state `"ok"` and count `5` | `"ALL SYSTEMS OPERATIONAL"` |
| overview-007 | headline-warn-singular, headline-warn-plural | The headline operation with sign state `"warn"` and count `1`; then count `3` | `"1 SERVICE NEEDS ATTENTION"`; `"3 SERVICES NEED ATTENTION"` |
| overview-008 | headline-down-singular, headline-down-plural | The headline operation with sign state `"down"` and count `1`; then count `4` | `"1 PROBLEM"`; `"4 PROBLEMS"` |
| overview-009 | unresolved-held-open | The still-unresolved operation on a deploy row with `unresolved: true` and `heldOpenBy: [S]`, with a problem on the row's target whose `since` is `S` | `true` |
| overview-010 | unresolved-held-open | The same row with no problems; with a problem on the same target with a different `since`; with a problem at `since` `S` on another target | `false` for all three |
| overview-011 | unresolved-in-flight, unresolved-no-held-open | A row with `unresolved: true`, tone `"progress"` and `heldOpenBy: []`, and a row with `unresolved: true` and no `heldOpenBy`, each against no problems | `true`, `true` |
| overview-012 | unresolved-server-verdict | A row with `unresolved: false` and `heldOpenBy: []` against a matching problem; a row with `unresolved` absent against a matching problem | `false`, `false` |
| overview-013 | pure-functions, no-throw | Call the headline operation, the caption operation and the still-unresolved operation twice on the same arguments, with the problems list and the row frozen | Same results both times; no exception; inputs unchanged |
## Edge Cases
- **Unresolved row without `heldOpenBy`**: A row with `unresolved: true` and no `heldOpenBy` field MUST keep the server's verdict and be reported unresolved.
- **Empty `heldOpenBy`**: A row with `unresolved: true` and `heldOpenBy: []` (a row in flight) MUST be reported unresolved against any problem list, including an empty one.
- **Held-open problem cleared or replaced**: A row with `unresolved: true` and a non-empty `heldOpenBy` MUST be reported resolved when the problem list is empty, when the matching target has a different onset time, or when the matching onset time is on another target.
- **Row not unresolved**: A row whose `unresolved` field is `false` or absent MUST be reported resolved, even when a matching problem exists.
- **Non-integer or huge windows**: The activity-window-caption operation rounds to the nearest hour (for example 23.6h to `"24h"`); a whole-day multiple of 48h or more MUST switch to days, and 24h MUST stay `"24h"`.
- **Invalid bounds**: If either bound given to the caption operation is invalid (for example from an unparseable time stamp upstream), the reference implementation performs no guard and returns the caption `"NaNh"`; a port whose numeric type has no equivalent invalid-number propagation should pick its own fallback (see Platform Notes).
- **Negative or zero window**: The activity-window-caption operation MUST return `"1h"`.
- **Headline with count 0 and a non-ok state**: The headline operation MUST return `"0 SERVICES NEED ATTENTION"` or `"0 PROBLEMS"`; the operation trusts the caller's pairing of state and count.
- **Negative or fractional count**: The headline operation MUST interpolate it verbatim with the plural form (for example `"-1 PROBLEMS"`).
- **Concurrent access**: Not applicable. The module is stateless, so calls cannot interleave.
- **Error states and offline**: Not applicable. The module performs no I/O; a missing or stale board is handled by its callers, which map it to an "unknown" state before the wire-indicator translation map is consulted.
## Configuration
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fromMs` / `toMs` | a number | none (required) | Window bounds; the caller passes the board's own reported window start and end. |
| `state` / `count` | a sign state / a number | none (required) | Inputs to the headline operation. |
| `row` | an activity row | none (required) | The feed row the still-unresolved operation judges. |
| `problems` | a list of problems (target and onset time) | none (required) | The board's current problems, looked up by the still-unresolved operation. |
| 48-hour day threshold | constant | 48 | Minimum hours before the caption switches to days, compiled in. |

The module reads no environment variables or settings keys and takes no injected dependencies. It imports only shapes/types from elsewhere.
## Deep Linking

Not applicable: the module exports pure operations and has no navigable surface.

## Localization

The headline operation returns hardcoded, uppercase English strings with no localization layer: `"ALL SYSTEMS OPERATIONAL"`, `"1 SERVICE NEEDS ATTENTION"`, `"{count} SERVICES NEED ATTENTION"`, `"1 PROBLEM"`, `"{count} PROBLEMS"`. Pluralization is a binary count-equals-one test. The activity-window-caption operation returns the English unit suffixes `h` and `d`.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `ALL SYSTEMS OPERATIONAL` | Headline when state is ok |
| (none; literal) | `1 SERVICE NEEDS ATTENTION` | Headline, warn, one problem |
| (none; literal) | `{count} SERVICES NEED ATTENTION` | Headline, warn, other counts |
| (none; literal) | `1 PROBLEM` | Headline, down, one problem |
| (none; literal) | `{count} PROBLEMS` | Headline, down, other counts |
| (none; literal) | `{n}h` / `{n}d` | Activity window caption |

## Accessibility Options

Not applicable: the module renders nothing, so display options have nothing to act on. (The headline operation supplies the pill's accessible name, but the module does not respond to any display setting.)

## Feature Flags

Not applicable: the source reads no flag.

## Analytics

Not applicable: the module emits no events.

## Privacy

Not applicable: the module handles problem severities, activity rows and deploy platform/environment strings; it stores and transmits nothing.

## Logging

Not applicable: the module makes no log calls.

## Platform Notes

- **SwiftUI**: Port as free functions or a caseless `enum OverviewProjection`. Model the sign-state vocabulary as `enum IndicatorState: String { case ok, warn, down }` and the indicator shape as a `Sendable` struct. The wire-indicator translation map becomes a `switch` over a wire `enum BoardIndicator`, which the compiler checks for exhaustiveness. The still-unresolved operation is a plain function over the row and a list of problems. Use `String(localized:)` with a plural variant if the headline is localized.
- **Compose**: Use a Kotlin `object` with an `enum class IndicatorState` and a `data class Indicator`. The wire-indicator translation map becomes an exhaustive `when`. Plurals map to `pluralStringResource` if localized.
- **React/Web**: This is the source: `src/lib/overview.ts`, tested by `src/lib/overview.test.ts` and `src/lib/board-types-parity.test.ts` (the latter pins `INDICATOR_STATE`'s keys to the server's indicator union). `IndicatorState`, `Indicator` and the wire `Indicator` union are TypeScript types; `INDICATOR_STATE` is typed `Record<BoardIndicator, IndicatorState>`, so a compile error catches a member removed from the wire union without a matching map key, or vice versa — the same guarantee the parity test's key check backs at runtime. The caption's hour computation is `Math.max(1, Math.round((toMs - fromMs) / 3_600_000))`, and an invalid `toMs`/`fromMs` propagates to the caption `"NaNh"` because template-literal interpolation of `NaN` is the string `"NaN"`. `stillUnresolved` returns false unless `a.unresolved === true`, keeps the verdict for a null or empty `heldOpenBy`, and otherwise checks `problems.some((p) => p.target === a.target && held.includes(p.since))`. Callers: `OverviewTab.tsx` (`INDICATOR_STATE`, `stillUnresolved`), `use-portfolio-indicator.ts` (`INDICATOR_STATE`, and its own fallback to an "unknown" state for a missing board), `OverviewStats.tsx` (`activityWindowLabel`, passing `board.activityFromMs` and `Date.parse(board.generatedAt)`), `BigIndicator.tsx`, `BoardShell.tsx` (`headlineFor`, wording its own "unknown" state as `"Status unknown"`) and `WallboardStatus.tsx` (`headlineFor`, wording its own "unknown" state as `"UNKNOWN"`), and `StatusSign.tsx` / `status-sublabel.ts` (the `IndicatorState` type). The module holds no state and runs on the single JavaScript thread, so calls cannot interleave.
- **AppKit / UIKit**: Same pure Swift port as SwiftUI, placed in a shared framework target; nothing is UI-bound.
- **WinUI 3**: Port as a `public static class OverviewProjection` in C#. The sign-state vocabulary becomes `public enum IndicatorState { Ok, Warn, Down }` (serialise lower-case with `JsonStringEnumConverter` and `JsonNamingPolicy.CamelCase` if it crosses `System.Text.Json`); the indicator shape becomes a `public readonly record struct Indicator(IndicatorState State, int Count)`. The wire-indicator translation map becomes a switch expression over a `BoardIndicator` enum, or a `FrozenDictionary<BoardIndicator, IndicatorState>`. The caption operation uses `Math.Round(x, MidpointRounding.AwayFromZero)` because the reference implementation's rounding rounds .5 up while .NET defaults to banker's rounding. The still-unresolved operation uses `problems.Any(p => p.Target == row.Target && held.Contains(p.Since))`. Headline strings go in `.resw` resources through `ResourceLoader` if localized. The view model binding the headline raises `INotifyPropertyChanged`; the operations stay synchronous, with no `Task`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-web/src/lib/overview.ts` | confirmed (2.0.0) |

## Design Decisions
**Decision**: The client no longer derives the indicator; the server ships it.
**Rationale**: The module once held a problems-to-indicator operation that mirrored the server's indicator rule for filtered panes, pinned by a parity test. The server now ships the indicator and its environment-scoped twin (`scope`), so the client keeps only the wire-to-sign translation, and `board-types-parity.test.ts` still pins that map's keys to the server's indicator union.
**Approved**: pending

**Decision**: `INDICATOR_STATE` is the single wire-to-sign translation.
**Rationale**: One typed `Record<BoardIndicator, IndicatorState>` is exhaustive at compile time, and a key test catches a member removed from both union and map together.
**Approved**: pending

**Decision**: Derive the window caption from the board's own bounds instead of hardcoding "24h".
**Rationale**: The server owns `ACTIVITY_WINDOW_MS`; a hardcoded caption would keep stating the old figure after a server change, "a label that lies without anything failing". Days are used only for whole-day windows of 48h or more, so 47h is never rounded to a window nobody configured.
**Approved**: pending

**Decision**: Judge no row-level verdict on the client beyond the held-open lookup.
**Rationale**: Deploy counts were once tallied here; the server now ships `deployCounts`, the row `environment` and the `unresolved` verdict. The one remaining row helper, `stillUnresolved`, only looks up the problems the server named in `heldOpenBy` against the current board, because a paged-in or retained history row outlives the read that judged it.
**Approved**: pending

**Decision**: One `headlineFor` shared by the hero sign and the top-bar pill.
**Rationale**: Sharing the function makes it impossible for the two surfaces to word the same state differently.
**Approved**: pending

**Decision**: The real-environment deploy predicate was removed from the client.
**Rationale**: It excluded Vercel preview builds (which report `environment=null`) from the deploy tally, and had no client caller outside its own test while the server carried its own copy. The server now judges the rule and ships the row `environment`, so the duplicate is gone.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

**Separation of concerns.** The module holds only presentation projections; derivation stays on the server and row construction in a separate module.

**Unit test coverage.** Every conformance vector has a passing test: the wire-indicator translation map, the activity-window caption, the headline operation and the still-unresolved operation, plus a purity check across the three functions.

**Explicit error handling.** Nothing throws, but invalid window bounds are not guarded: an invalid bound yields a `"NaNh"` caption.

**Data integrity.** The wire-indicator map's keys are pinned to the server's indicator union by a parity test, and no verdict is duplicated on the client.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-14 | Mike Fullerton | Match recipe to source: drop removed problems-to-indicator, deploy-counts and real-env operations; describe stillUnresolved |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to status/dashboard/logic/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation from source |
