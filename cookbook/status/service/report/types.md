---
id: e2b50620-c7b1-4268-a56e-e039fea3349f
title: "Status Report Wire Types"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The versioned wire contract of GET /report and the get_report MCP tool: verdict, findings, coverage, per-source sections and validated query params."
platforms:
  - typescript
  - web
tags:
  - status
  - report
  - wire-contract
  - types
depends-on: []
related:
  - 77587f0b-5a27-44d9-a507-46bb90c9046a
  - ce157d5a-c145-4348-b58f-6a76c9fda1d6
  - 7984f592-a12d-49da-806c-ff39d9557998
  - a7c2b9e1-5d4f-4a2c-9e6f-8b3a1c5d7e2f
  - 5edf4567-65dd-40d7-814e-8604ee70f131
references: []
approved-by: ""
approved-date: ""
---

# Status Report Wire Types

## Overview

The type module that defines the one agent-ready digest of the whole fleet. `GET /report` and the MCP tool `get_report` both return a `ReportResponse`, and both accept a `ReportParams` query. The module holds declarations and three constants (`REPORT_SCHEMA`, `SEVERITIES`, `REPORT_SOURCES`). Every judgement in the payload (verdict, severity, order, staleness, completeness) is made on the server by the report rules; a client formats and lays out, and decides nothing. The payload carries a `schema` string, and a change a reader must adapt to is a new `status.report/N`.

A port reproduces these shapes exactly, because the CLI, the MCP clients and any agent parse them. The producers (`buildReport` and `parseReportParams`) are specified by their own recipes; this ingredient is the contract they meet. The parser behavior (defaults, coercion and the order of the checks) is specified by [adhsdk.ingredient.status.service.report.report-gather](cookbook:24b45917-4361-44d8-a3dc-224cc2807aa9), which owns `parseReportParams`; this module keeps only the `ReportParams` shape and its value ranges.

## Behavioral Requirements

- **schema-constant**: `ReportResponse.schema` MUST be the literal string `status.report/1`, exported as `REPORT_SCHEMA`.
- **schema-versioning**: A change a reader must adapt to MUST be published as a new schema string `status.report/N` and MUST NOT change `status.report/1` in place.
- **severity-set**: `Severity` MUST be exactly `critical`, `major` or `minor`, in that order, exported as `SEVERITIES`.
- **verdict-set**: `ReportVerdict` MUST be exactly one of `healthy`, `attention`, `degraded`, `down` or `unknown`.
- **verdict-mapping**: The verdict MUST come from the worst finding: `critical` gives `down`, `major` gives `degraded`, `minor` gives `attention`. With no findings it MUST be `healthy` when `complete` is true and `unknown` when it is false.
- **source-set**: `REPORT_SOURCES` MUST list `monitor`, `deploys`, `integrations`, `errors`, `runtimeErrors`, `analytics`, `uptime`, in that order, and `coverage` and `sections` MUST each carry exactly one key per source.
- **coverage-entry**: Each `SourceCoverage` MUST carry `ok`, and MAY carry `error` (why the source was not read, when `ok` is false), `notes` (the source was read but partial), `unconfigured` (providers with no credentials) and `updatedAt` (when the data behind the source was fetched, or null).
- **complete-rule**: `complete` MUST be true only when every source has `ok` true and no notes. Any note on any source MUST clear it. An `unconfigured` entry MUST NOT clear it, because it is a standing fact about the deployment, not a gap.
- **null-section-invariant**: A section in `sections` MUST be null exactly when its source could not be read, that is when `coverage[source].ok` is false.
- **finding-shape**: Each `Finding` MUST carry `severity`, `source` (such as `monitor:vercel`, `provider:railway`, `glitchtip`, `vercel-runtime`, `posthog`) and `title`. `Finding.source` is a label for where the finding came from, not a `REPORT_SOURCES` id: it is sometimes equal to one (`uptime`, `report`) and sometimes not (`monitor:vercel`, `glitchtip`), and a reader MUST NOT look it up in `coverage` or `sections`. It MAY carry `detail`, `since`, `link` (a provider page or live URL) and `issueKey` (the key `adh-status issues show` accepts, present only for a finding that is an open board issue).
- **finding-order**: `findings` MUST be sorted by severity (critical first), then by `source`, then by `title`.
- **counts-total**: `counts` MUST hold one number per severity, equal to the number of findings of that severity.
- **first-line-fields**: `FailingDeploy.commit` and `FailingDeploy.error` MUST hold only the first line of the commit message and of the provider's failure text.
- **log-fields**: `FailingDeploy.logTail`, `logLines` and `logError` MUST appear only when the request asked for `logs=1`. `logError` MUST say why there is no tail. When a tail is present it MUST hold at most 40 lines (`LOG_TAIL_LINES`), the last lines of the log.
- **monitor-section**: `MonitorReportSection` MUST carry `overall` (`healthy`, `degraded` or `down`), `checkedAt`, `lastCycleAt` (null when no cycle has completed), `stale` (the scheduler's own stale rule), `services`, `byStatus`, `openIssues` and `unprobed` (names of services with no probe yet).
- **deploys-section**: `DeploysReportSection.failing` MUST list the deploys the board holds as failed, newest build first, and MUST carry the `providers` map of `{ configured, ok }` per `ProviderKey`.
- **runtime-errors-section**: `RuntimeErrorsReportSection.window` MUST be the literal `24h`. `complete` MUST be false when the Vercel read was cut short. `total` counts groups seen in the window, which `groups` may cap below. `groups` MUST be ordered worst level first, then most frequent.
- **errors-section-order**: `ErrorsReportSection.active` MUST be fatal first then by event count, and `sites` MUST be most errors plus failures first. `summary` MUST be null when the issue list has never been read.
- **analytics-section**: `AnalyticsReportSection.range` MUST echo the requested `AnalyticsRange`. PostHog `sites` and Vercel `projects` MUST be most pageviews first, and each provider `totals` MUST be null when that provider could not be read.
- **uptime-section**: `UptimeReportSection` MUST carry `days` (the window), `floor` (the percent below which a service is a finding) and per-service `uptimePercent`, which is null when the service has no figure.
- **params-ranges**: `ReportParams.range` MUST be one of `24h`, `7d`, `30d`; `days` MUST be an integer 1 to 365; `wait` MUST be an integer 0 to 60 seconds; `logs` MUST be a boolean in the parsed `ReportParams`.
- **params-logs-forms**: On the wire (a query string) `logs` MUST be `0` or `1`. An in-process caller, such as the MCP tool, MAY pass the boolean `true` or `false` or the number `0` or `1` as well; the strings `true` and `false` MUST be rejected.
- **params-defaults**: When a param is absent, null or empty, it MUST take `range` `24h`, `days` 7, `wait` 20, `logs` false.
- **params-rejection**: A param outside its range, a non-integer `days` or `wait`, or a `logs` that is not `0` or `1` MUST be rejected with HTTP 400 and a message of the form `<name> must be an integer <min>-<max>`, `range must be one of 24h, 7d, 30d` or `logs must be 0 or 1`. The response body MUST be `{ "error": { "message": <that message> } }`.

## Appearance

Not applicable — this is a wire-type module, not a visual component.

## States

Not applicable — this is a wire-type module, not a visual component.

## Accessibility

Not applicable — this is a wire-type module, not a visual component.

## Conformance Test Vectors

The type module is declarations only; every vector is covered by a test in `report-types.test.ts` that drives the producers (`buildReport`, `gatherReport`, `parseReportParams`), and the route-level 400 body is also asserted by `report.int.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| report-types-001 | verdict-mapping, complete-rule | Every source read, no notes, no findings | `verdict` `healthy`, `complete` true, `counts` all zero |
| report-types-002 | complete-rule | A provider with no credentials | Listed in that source's `unconfigured`; `complete` stays true |
| report-types-003 | null-section-invariant, verdict-mapping | One source fails to read | Its section is null, `coverage[source].ok` false with `error`, a major finding titled `could not read <source>`, verdict not `healthy` |
| report-types-004 | complete-rule | A dashboard still refreshing at the deadline | A note in that source's coverage, `complete` false |
| report-types-005 | finding-order, verdict-mapping | One critical and one minor finding | Critical listed first, verdict `down` |
| report-types-006 | finding-order | Two minor findings with `source` `vercel-runtime` and `glitchtip` | `glitchtip` before `vercel-runtime` |
| report-types-007 | params-defaults | `parseReportParams({})` | `{ range: '24h', days: 7, wait: 20, logs: false }` |
| report-types-008 | params-ranges | `range=30d&days=14&wait=0&logs=1` | `{ range: '30d', days: 14, wait: 0, logs: true }` |
| report-types-009 | params-rejection | `range=1y` | HTTP 400, `range must be one of 24h, 7d, 30d` |
| report-types-010 | params-rejection | `logs=true` | HTTP 400, `logs must be 0 or 1` |
| report-types-011 | params-rejection | `days=0`, `days=366`, `wait=61`, `days=1.5` | HTTP 400, `days must be an integer 1-365` or `wait must be an integer 0-60` |
| report-types-012 | log-fields | `logs=1` with failing deploys | Each listed failing deploy carries `logTail` (at most 40 lines) and `logLines`; a failed read gives `logError` instead |
| report-types-013 | log-fields | `logs` absent | No `logTail`, `logLines` or `logError` on any deploy |
| report-types-014 | schema-constant, severity-set, source-set | Any `ReportResponse`, and the exported constants | `schema` is `status.report/1` (`REPORT_SCHEMA`); `SEVERITIES` is `['critical', 'major', 'minor']`; `REPORT_SOURCES` is the seven source ids in the listed order; `coverage` and `sections` each have exactly those keys |
| report-types-015 | verdict-mapping | A report whose only finding is major; then one whose only finding is minor | `verdict` `degraded`; then `verdict` `attention` |
| report-types-016 | counts-total | One critical, two major and three minor findings | `counts` is `{ critical: 1, major: 2, minor: 3 }` |
| report-types-017 | finding-order | Two minor findings with `source` `uptime` and titles `Shop: 90.00% up over 7d` and `API: 97.00% up over 7d` | The `API` finding is listed before the `Shop` finding |
| report-types-018 | first-line-fields | A failing deploy whose commit message is `fix: thing` plus a body line, and whose provider failure text is `Type error` plus a stack line | `commit` is `fix: thing` and `error` is `Type error` |
| report-types-019 | monitor-section | Two services, `Shop` with status `down` and `Blog` with status `unknown`, no completed cycle, no open issues | `services` 2, `byStatus` `{ down: 1, unknown: 1 }`, `openIssues` 0, `lastCycleAt` null, `stale` false, `unprobed` `['Blog']` |
| report-types-020 | deploys-section | Board problems for failed deploys `d1` (09:00) and `d2` (10:00); the Vercel provider configured and ok | `failing` ids are `['d2', 'd1']`; `providers.vercel` is `{ configured: true, ok: true }` |
| report-types-021 | runtime-errors-section | A Vercel read cut short with 30 groups seen and 23 kept, one fatal and the rest level `error` | `window` `24h`, `complete` false, `total` 30, `groups` has 23 entries with the fatal group first |
| report-types-022 | errors-section-order | Active issues: level `error` count 10, level `fatal` count 3, level `error` count 50; sites `a.dev` (3 errors, 2 failures) and `d.dev` (2 errors, 0 failures); issue list never read | `active` counts in order 3, 50, 10; `sites` lists `a.dev` before `d.dev`; `summary` is null |
| report-types-023 | analytics-section | `range` `7d`; PostHog sites with 10 and 30 pageviews; the Vercel read failed | `range` `7d`; the 30-pageview site is listed first; `vercel.totals` is null |
| report-types-024 | uptime-section | `days` 7; one service at 97.5% and one with no figure | `days` 7, `floor` 99.5, the first `uptimePercent` 97.5, the second null |
| report-types-025 | params-defaults | `parseReportParams({ days: '' })` | `days` is 7 (an empty string is absent) |
## Edge Cases

- A source that throws is uncovered, becomes one major finding, and clears `complete`; the other sources are still read and their sections stay populated.
- A report with no findings and `complete` false has verdict `unknown`, never `healthy`; "no findings" is not a clean bill of health when a source was not fully read.
- `logs` accepts the forms `true`, `false`, `1`, `0` from in-process callers, and only `0` or `1` from a query string; the strings `true` and `false` are rejected (see `params-logs-forms`).
- An empty string for any param is treated as absent, so `?days=` takes the default.
- `days` and `wait` accept only whole decimal digits with an optional minus sign; `1e1`, `1.5` and `0x10` are rejected.
- The type module's header comment names `src/report/build.ts` as the place the judgements are made; the code lives in the report rules module. The contract here is unaffected.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `range` | `24h`, `7d` or `30d` | `24h` | Analytics window for the analytics section |
| `days` | integer 1-365 | 7 | Uptime window in days |
| `wait` | integer 0-60 | 20 | Seconds to wait for cold dashboards to finish their first read |
| `logs` | boolean (`0` or `1` on the wire) | false | Attach the build-log tail to failing deploys |

## Deep Linking

Not applicable: the module declares data shapes and has no navigable surface; `Finding.link` carries a provider URL as data only.

## Localization

Not applicable: the module declares types and constants and holds no user-facing strings; the 400 messages belong to the param parser, specified by [adhsdk.ingredient.status.service.report.report-gather](cookbook:24b45917-4361-44d8-a3dc-224cc2807aa9).

## Accessibility Options

Not applicable: the module declares data shapes with no rendering.

## Feature Flags

Not applicable: the module reads no flag; the contract is the same in every deployment.

## Analytics

Not applicable: the module declares types and emits no events.

## Privacy

Not applicable: the module declares shapes and handles no credential; `unconfigured` names providers with no credentials but carries no secret value.

## Logging

Not applicable: the module declares types and constants and makes no log call.

## Platform Notes

- **SwiftUI**: Model the payload as `Codable` structs. `Severity`, `ReportVerdict` and `ReportSourceId` become `String`-backed enums with the same raw values, and `Record<K, V>` becomes `[K: V]`. Decode with `JSONDecoder` and treat an unknown `schema` as unreadable.
- **Compose**: Use `kotlinx.serialization` `@Serializable` data classes with enum classes carrying `@SerialName`. Nullable sections map to nullable properties, and optional fields default to null.
- **React/Web**: Keep the TypeScript declarations as the contract. `as const` tuples give the literal unions, and `typeof REPORT_SCHEMA` pins the schema field. A client should check `schema` before reading the rest.
- **AppKit / UIKit**: Same `Codable` models as SwiftUI; present `verdict` and `findings` as supplied and do not re-sort or re-derive severity.
- **WinUI 3**: Use `System.Text.Json` records with `JsonStringEnumConverter` and `JsonPropertyName` for camelCase names, `Dictionary<string, T>` for the keyed maps and nullable reference types for null sections. On the server side an ASP.NET Core minimal API binds `ReportParams` from the query string and returns a 400 with the same `{ error: { message } }` body for a rejected param.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/report/types.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: **server-side-judgement**: Compute verdict, severity, order and completeness on the server; clients format and lay out only.
**Rationale**: Verdict, severity, order and completeness are computed once on the server, so every client (CLI, MCP, agent) reports the same answer and none has to know the rules or keep its own copy in step.
**Approved**: pending

**Decision**: **null-section-for-unread-source**: Give an unread source a null section plus a coverage error, never an empty section.
**Rationale**: An empty list reads as "nothing wrong", so an unread source must not look like one; a null section plus a coverage error says "not read" and keeps an empty list from being mistaken for a healthy source.
**Approved**: pending

**Decision**: **unconfigured-is-not-a-gap**: List a provider with no credentials under `unconfigured` without clearing `complete`.
**Rationale**: A provider with no credentials is a fixed property of a deployment; counting it as a gap would make `complete` permanently false for deployments that never use that provider.
**Approved**: pending

**Decision**: **schema-in-payload**: Carry the version in the payload as a `schema` string.
**Rationale**: A client can refuse a shape it does not know by reading `schema` alone, without parsing the rest, and a breaking change gets a new string instead of silently changing the old one.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |

The module is declarations only, with validation and judgement in separate modules, so separation of concerns is met. Every conformance vector has a passing test in `test/report-types.test.ts`, which pins the contract through the rules and gather modules, so unit-test coverage is passed. The 400 body for a rejected param is stated in the contract and asserted by the route test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (report-types.test.ts, 25 of 25 vectors); unit-test coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added the 400 body to params-rejection, split logs into the parsed boolean and params-logs-forms, named the Design Decisions with fuller rationales, said "ingredient" in the overview, stated the 40-line log cap and how Finding.source relates to report sources, and added vectors 014 to 025 for every previously uncovered requirement. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
