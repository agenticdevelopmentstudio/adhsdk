---
id: 9baed0c1-00e0-4186-9fd3-410039dc9881
title: "Status Server Self-Check View"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Pure function that judges the integration checks into the dashboard self-check bar verdict: missing env vars, issues, severity and count"
platforms:
  - typescript
  - web
tags:
  - status
  - self-check
  - integrations
  - verdict
depends-on:
  - 4e32bf7a-b87a-44f6-aa16-f57a533e3b77
related: []
references: []
approved-by: ""
approved-date: ""
---

# Status Server Self-Check View

## Overview

`selfCheckView` turns the list of `IntegrationCheck` results into the one verdict the dashboard's self-check bar and the KPI pill render. The server publishes it on `GET /integrations` as `selfCheck`, so the bar and the pill each show a verdict instead of filtering the checks with their own copy of the rule (the source notes the rule moved here from status-web's `computeSelfCheck`). It returns a `SelfCheckView`, or `null` when there is nothing to show. It is a total, synchronous, side-effect-free function over its argument. Its caller is `runIntegrationsCheck` in `integrations.ts`, which passes the already-stabilised checks (see [adhsdk.ingredient.status.service.monitor.self-check-stability](cookbook:4e32bf7a-b87a-44f6-aa16-f57a533e3b77)).

## Behavioral Requirements

### Missing environment variables

- **missing-env-collection**: `selfCheckView` MUST gather the `missingEnv` arrays of every check whose `missingEnv` is present and non-empty, concatenated in check order.
- **missing-env-dedupe**: The result's `missingEnv` MUST contain each variable name once, at the position of its first occurrence in check order.
- **missing-env-error-flag**: The result's `missingEnvError` MUST be `true` if and only if at least one check that reports missing variables has `state === "error"`; a check with `state` `"warn"` that reports missing variables MUST NOT set it.
- **missing-env-not-an-issue**: A check that reports missing variables MUST NOT appear in `issues`, so it is shown once in the env chip and not chipped again as an issue.

### Issues

- **issue-selection**: `issues` MUST contain, in input order, exactly those checks that satisfy all four conditions: `state` is not `"ok"`, `id` is not `"cron"`, `missingEnv` is absent or empty, and `correlated` is not truthy.
- **cron-excluded**: A check with `id === "cron"` MUST NOT appear in `issues`, per the source comment that the internal cron check "is wallboard noise and never chipped". It still counts toward `missingEnv` if it reports missing variables.
- **correlated-excluded**: A check with a truthy `correlated` MUST NOT appear in `issues`, per the source comment that a correlated provider failure is collapsed into the backend's Connectivity chip. The synthetic `connectivity` check (an ordinary non-ok check) is therefore the one that appears.
- **issue-identity**: `issues` MUST hold the original check objects from the input, not copies.
- **warn-is-issue**: A check with `state === "warn"` that meets the other conditions MUST appear in `issues`; only `"ok"` is excluded by state.

### Verdict

- **null-when-clean**: The function MUST return `null` when `missingEnv` is empty and `issues` is empty.
- **result-shape**: Otherwise the function MUST return an object with exactly the fields `missingEnv`, `missingEnvError`, `issues`, `hasError` and `issueCount`, as declared by `SelfCheckView` in `types.ts`.
- **has-error**: `hasError` MUST be `true` if and only if `missingEnvError` is `true` or at least one entry of `issues` has `state === "error"`.
- **issue-count**: `issueCount` MUST equal `issues.length + missingEnv.length`, where `missingEnv.length` counts distinct variable names, not checks. It is the count the KPI pill shows.
- **severity-follows-state**: Severity MUST come only from the checks' own `state`; the function MUST NOT raise an unset-variable check to error on its own ("an unset variable is never forced red").
- **purity**: The function MUST NOT mutate `checks`, any check, or any `missingEnv` array, and MUST NOT perform I/O, read the clock or log.
- **readonly-input**: The function MUST accept a `readonly IntegrationCheck[]`.

## Appearance

Not applicable — this is a pure verdict function over check results, not a visual component.

## States

Not applicable — this is a pure verdict function over check results, not a visual component. The function holds no runtime state; its two outcomes are `null` and a `SelfCheckView`, described under Behavioral Requirements.

## Accessibility

Not applicable — this is a pure verdict function over check results, not a visual component.

## Conformance Test Vectors

The `selfCheckView` suite in `packages/web/packages/status-server/test/read-views.test.ts` carries a test for every vector below; each test title begins with its vector id, except the older tests for 001 ("is null when everything is ok"), 003 and 008, 004, 005 and 007, 006, and 009, whose titles name the vector ids they cover.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-server-monitor-self-check-001 | null-when-clean | `selfCheckView([])` | `null` |
| status-server-monitor-self-check-002 | null-when-clean | `selfCheckView([ok("vercel"), ok("railway")])` where both have `state: "ok"` | `null` |
| status-server-monitor-self-check-003 | issue-selection, has-error, issue-count, result-shape | `[ok("vercel"), err("railway")]` where `err` has `state: "error"`, no `missingEnv` | `{ missingEnv: [], missingEnvError: false, issues: [<railway>], hasError: true, issueCount: 1 }` |
| status-server-monitor-self-check-004 | warn-is-issue, has-error | `[warn("posthog")]` with `state: "warn"`, no `missingEnv` | `issues` has one entry, `hasError: false`, `issueCount: 1` |
| status-server-monitor-self-check-005 | missing-env-collection, missing-env-not-an-issue, missing-env-error-flag, severity-follows-state | `[{ id: "cloudflare", state: "warn", missingEnv: ["CLOUDFLARE_ACCOUNT_ID"] }]` | `{ missingEnv: ["CLOUDFLARE_ACCOUNT_ID"], missingEnvError: false, issues: [], hasError: false, issueCount: 1 }` |
| status-server-monitor-self-check-006 | missing-env-error-flag, has-error | Same check as 005 but `state: "error"` | `missingEnvError: true`, `hasError: true`, `issues: []`, `issueCount: 1` |
| status-server-monitor-self-check-007 | missing-env-dedupe | `[{ id: "a", state: "warn", missingEnv: ["A", "B"] }, { id: "b", state: "warn", missingEnv: ["B", "C"] }]` | `{ missingEnv: ["A", "B", "C"], missingEnvError: false, issues: [], hasError: false, issueCount: 3 }` |
| status-server-monitor-self-check-008 | cron-excluded | `[{ id: "cron", state: "error" }]` | `null` (the cron check is never an issue) |
| status-server-monitor-self-check-009 | correlated-excluded | `[{ id: "vercel", state: "warn", correlated: true }, { id: "connectivity", state: "warn" }]` | `issues` contains only the `connectivity` check; `issueCount: 1` |
| status-server-monitor-self-check-010 | issue-selection, missing-env-not-an-issue | `[{ id: "x", state: "error", missingEnv: [] }]` (empty array) | The check is an issue (empty `missingEnv` does not exclude it): `issues.length === 1`, `hasError: true` |
| status-server-monitor-self-check-011 | purity, issue-identity | Call with a frozen array `[ok("vercel"), err("railway")]` of frozen checks, where the non-ok check is at index 1 | No throw; `result.issues[0] === input[1]` |
| status-server-monitor-self-check-012 | missing-env-collection, missing-env-error-flag | `[{ id: "stats", state: "ok", missingEnv: ["STATS_TOKEN"] }]` (an ok check that reports a missing variable) | `{ missingEnv: ["STATS_TOKEN"], missingEnvError: false, issues: [], hasError: false, issueCount: 1 }` |
| status-server-monitor-self-check-013 | missing-env-collection, correlated-excluded, missing-env-not-an-issue | `[{ id: "vercel", state: "warn", correlated: true, missingEnv: ["VERCEL_API_TOKEN"] }]` | `{ missingEnv: ["VERCEL_API_TOKEN"], missingEnvError: false, issues: [], hasError: false, issueCount: 1 }` |
## Edge Cases

- **Null and empty input**: An empty `checks` array returns `null` — MUST. A check with `missingEnv: []` is treated as having no missing variables and can be an issue — MUST.
- **Boundary values**: One missing variable or one issue is enough to produce a view; zero of both returns `null` — MUST. A variable named by several checks counts once in `issueCount` — MUST.
- **Concurrent access**: Not applicable — the function holds no state and does not mutate its input, so concurrent calls cannot affect each other; the runtime is single-threaded JavaScript.
- **Error states**: Not applicable — the function performs no I/O and has no `throw` or `try`. It assumes well-typed input; a `null` array argument would throw a native `TypeError` from `filter`, and the source does not guard it, because the TypeScript signature requires an array.
- **Offline or disconnected state**: Not applicable — the function never touches the network. Unreachable providers reach it only as already-decided checks (`unreachable`, `correlated`) produced upstream.
- **Missing-env on an ok check**: A check with `state === "ok"` that still lists `missingEnv` contributes its variables to `missingEnv`, because env collection ignores `state`; `missingEnvError` stays `false` for it — MUST.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `checks` | `readonly IntegrationCheck[]` | none, required | The stabilised integration checks to judge. |

The function reads no environment variable and takes no other parameter.

## Deep Linking

Not applicable: the function defines no URL, route or navigable target; it returns a value to its in-process caller.

## Localization

Not applicable: the function produces no string of its own. Every `detail` or `label` in `issues` was produced upstream and is passed through unchanged, and the env variable names are literal identifiers.

## Accessibility Options

Not applicable: the function has no UI and responds to none of Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the function consults no feature-flag system.

## Analytics

Not applicable: the function emits no analytics or telemetry event.

## Privacy

Not applicable: the function collects, stores and transmits nothing; it reads only check fields (names of unset environment variables, never their values) and returns them to its caller.

## Logging

Not applicable: the function contains no `console.*` or logger call; its return value is its only signal.

## Platform Notes

- **SwiftUI**: not a view concern. A Swift port is a free function or static method `func selfCheckView(_ checks: [IntegrationCheck]) -> SelfCheckView?` returning `nil` for the clean case; dedupe in first-seen order with an `NSOrderedSet` or a `Set<String>` guard over an array, since a plain `Set` loses order.
- **Compose**: not a view concern. A Kotlin port is a top-level function returning `SelfCheckView?`; `flatMap { it.missingEnv.orEmpty() }.distinct()` keeps first-occurrence order, and `SelfCheckView` is a `data class`.
- **React/Web** (source platform): lives at `packages/web/packages/status-server/src/monitor/self-check.ts`, with its types in `monitor/types.ts`. `new Set([...])` preserves insertion order, which the dedupe requirement relies on. The only call site is `integrations.ts`, which assigns the result to the `selfCheck` field of `IntegrationsResponse`.
- **AppKit / UIKit**: same non-view framing as SwiftUI; a status-bar or banner controller in AppKit or UIKit would render from the `SelfCheckView?` value and never recompute the rule.
- **WinUI 3**: a .NET port is a static method `SelfCheckView? ComputeSelfCheckView(IReadOnlyList<IntegrationCheck> checks)` on a static class (the method is not named `SelfCheckView`, to avoid a clash with the record type it returns). Use `IReadOnlyList<T>` for the read-only input, `Enumerable.Where` and `SelectMany`, dedupe with a `HashSet<string>` guard while appending to a `List<string>` (the documentation does not guarantee `Enumerable.Distinct` order), and a `record SelfCheckView(IReadOnlyList<string> MissingEnv, bool MissingEnvError, IReadOnlyList<IntegrationCheck> Issues, bool HasError, int IssueCount)` as the result. Like the other platforms, it is not a view concern: a WinUI banner would render from the `SelfCheckView?` value and never recompute the rule. A nullable reference return replaces the source's `null`; unlike TypeScript, `Enumerable.Where` is lazy, so materialise with `ToList()` before storing.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/monitor/self-check.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

- **Decision**: Compute the verdict on the server and publish it as `selfCheck`.
  **Rationale**: Stated in the source comment: so the bar and the KPI pill "render a verdict instead of each filtering the checks with its own copy of the rule".
  **Approved**: pending
- **Decision**: Show missing env vars in one deduped chip and keep those checks out of `issues`.
  **Rationale**: Stated in the source comment: a check that reports them "is not chipped again as an issue".
  **Approved**: pending
- **Decision**: Never chip the internal `cron` check.
  **Rationale**: Stated in the source comment: it is "wallboard noise". It is a hardcoded id with no shared constant tying it to the code that creates the cron check, so a renamed check would reappear in the bar. This coupling is a known risk.
  **Approved**: pending
- **Decision**: Collapse correlated provider failures into the Connectivity chip by excluding them from `issues`.
  **Rationale**: Stated in the source comment; the `correlated` flag and the synthetic `connectivity` check come from `self-check-stability.ts`.
  **Approved**: pending
- **Decision**: Take severity from the checks' own state and never force an unset variable red.
  **Rationale**: Stated in the source comment ("an unset variable is never forced red"); `missingEnvError` is red only when a check already reported `error`.
  **Approved**: pending
- **Decision**: Count missing variables (distinct names) and issues together in `issueCount`.
  **Rationale**: The `SelfCheckView` doc comment says it is "how many things the bar lists (issues + missing variables) — the KPI pill's count".
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |

`separation-of-concerns` passes: the function only judges an already-computed list, leaving probing and debounce to `integrations.ts` and `self-check-stability.ts` and rendering to the dashboard. `unit-test-coverage` passes: the `selfCheckView` suite in `test/read-views.test.ts` has a passing test for every vector 001 through 013. `good-test-properties` passes: the function is pure, so they are fast, isolated and deterministic, and each asserts on the returned view. `fault-tolerance` passes: the function is total over any well-typed array and never throws, including for an empty one.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (read-views.test.ts, 13 of 13 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Compliance now says the selfCheckView suite exists (unit-test-coverage partial), the cron-id coupling is recorded as a known risk, the stability recipe is linked and in depends-on, tags added, the Excluded id row removed, vectors 007 and 011 made concrete, vectors 012 and 013 added, and the WinUI note renamed the method, dropped view wiring and fixed the article. |
