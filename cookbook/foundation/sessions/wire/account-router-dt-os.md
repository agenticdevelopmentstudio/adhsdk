---
id: c5231579-d9c0-412d-8ae0-4c9bfb7937d3
title: "Account Router DTOs"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Secret-free wire types for the account router: pool status, usage report, routing-log rows and queries, preference writes, and the routable-key test."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - account-router
  - wire
depends-on:
  - d457c4d4-005c-4fcb-a3a6-3e1680bcb561
related: []
references: []
approved-by: ""
approved-date: ""
---

# Account Router DTOs

## Overview

`AccountRouterDTOs.swift` declares, inside the `Sessions` namespace, the data shapes the account router exchanges between the daemon (its `/router/*` routes), the `steno router` CLI and the Settings panel. The account router pools saved Claude credentials and hands each routed request to one of them; these types are how its state, its usage report, its routing log and its preference writes cross a process boundary.

The file holds:

- `AccountRouterItemKey.isRoutable(_:)`: the single test for "an item key the account router may pool", shared by the daemon (which refuses anything else), the CLI and the Settings panel (which offer only these).
- `AccountRouterPoolEntryDTO`: one pool entry, as `steno router status`, `GET /router/status` and the Settings panel show it.
- `AccountRouterStatusDTO`: the router's whole state, with tolerant decoding of older daemons.
- `AccountRouterReportRowDTO` and `AccountRouterReportDTO`: the per-account usage report, plus `retriedAccount(in:status:)`, which pulls the account a retry hid out of a routing-rule string.
- `AccountRouterExchangeDTO`: one routing-log row.
- `AccountRouterRuleFilter`: the routing log's rule filter.
- `AccountRouterExchangeQueryDTO`: one routing-log question, with the effective page size and a decoder that refuses an unknown rule by name.
- `AccountRouterExchangePageDTO`: one page of the routing log.
- `AccountRouterPreferencesRequestDTO`: a partial settings write.

Every type here is secret-free by construction: none has a field that could hold a token, header value or request body. Item keys are spelled by [adhsdk.ingredient.foundation.claude-accounts.claude-credential-kind](cookbook:d457c4d4-005c-4fcb-a3a6-3e1680bcb561). The model-routing types these DTOs nest (`ModelRouterStatusDTO`, `ModelUsageRowDTO`, `ModelRouterPreferencesDTO`, `ModelThreadKind`) live in `ModelRouterDTOs.swift` and are outside this recipe.

## Behavioral Requirements

### Shared conformances

- **value-types-sendable**: Every DTO struct and `AccountRouterRuleFilter` MUST be `Sendable`, so a value can cross actors and threads without synchronisation; `AccountRouterItemKey` is a caseless namespace for a static function, has no instances and declares no `Sendable` conformance.
- **dtos-codable-equatable**: Every DTO struct (`AccountRouterPoolEntryDTO`, `AccountRouterStatusDTO`, `AccountRouterReportRowDTO`, `AccountRouterReportDTO`, `AccountRouterExchangeDTO`, `AccountRouterExchangeQueryDTO`, `AccountRouterExchangePageDTO`, `AccountRouterPreferencesRequestDTO`) MUST be `Codable` and `Equatable`.
- **camel-case-keys**: Each DTO's coding keys MUST be the Swift property names in camelCase; the snake_case wire form (`base_url`, `five_hour_ceiling`, `saved_credentials`) MUST come from the caller's key strategy (convert to and from snake case), not from the types.
- **base-url-spelling**: The status property MUST be spelled `baseUrl`, not `baseURL`, so the wire key `base_url` round-trips through convert-from-snake-case.
- **secret-free**: No DTO MUST have a field that holds a token, an HTTP header value or a request or response body.
- **optional-nil-omitted**: Encoding a DTO MUST omit each optional property whose value is nil rather than writing a JSON `null` (synthesised encoding of optionals).

### Routable item key

- **routable-needs-kind**: `AccountRouterItemKey.isRoutable(_:)` MUST return false for a key whose text before the first colon is not a `ClaudeCredentialKind` raw value (`oauth` or `long-lived`).
- **routable-rejects-bare-name**: `isRoutable` MUST return false for a legacy bare-name key with no colon, because it has no kind to route by.
- **routable-needs-name**: `isRoutable` MUST return false when the text after the first colon is empty (`oauth:`).
- **routable-accepts-kind-and-name**: `isRoutable` MUST return true for `oauth:<non-empty>` and `long-lived:<non-empty>`.
- **routable-name-unvalidated**: `isRoutable` MUST NOT inspect the name beyond emptiness: a name containing whitespace or further colons is routable.

### Pool entry

- **pool-entry-fields**: `AccountRouterPoolEntryDTO` MUST carry `account` (the saved credential's item key), `held`, `available`, `eligible` and `sessions` as non-optional values.
- **pool-entry-optionals**: `AccountRouterPoolEntryDTO` MUST carry `coolingDownFor`, `fiveHourUtilization`, `fiveHourResetsAt`, `fiveHourStatus`, `sevenDayUtilization`, `sevenDayResetsAt`, `sevenDayStatus` and `organizationId` as optionals.
- **pool-entry-cooling-nil**: `coolingDownFor` MUST be the seconds of cool-down left, and nil when the entry is not cooling down.
- **pool-entry-units**: Utilizations MUST be 0–1 fractions and resets MUST be epoch seconds, as last read; the type does not range-check either.
- **pool-entry-available-meaning**: `available` MUST mean held, not within the expiry margin (300 s by default), and not cooling down; `eligible` MUST mean passing the policy's `eligible` test at the time of the snapshot. The DTO carries both as computed by the daemon and does not derive them.
- **pool-entry-decode-strict**: Decoding a pool entry with any non-optional key missing MUST throw.

### Status

- **status-required-keys**: Decoding `AccountRouterStatusDTO` MUST throw when any of `enabled`, `port`, `listening`, `baseUrl`, `fiveHourCeiling`, `pool` or `savedCredentials` is missing.
- **status-cooldown-default**: Decoding MUST set `cooldownSeconds` to `defaultCooldownSeconds` (60) when the key is absent.
- **status-expiry-margin-default**: Decoding MUST set `expiryMarginSeconds` to `defaultExpiryMarginSeconds` (300) when the key is absent.
- **status-retry-default**: Decoding MUST set `retry` to true when the key is absent.
- **status-sticky-default**: Decoding MUST set `sticky` to true when the key is absent.
- **status-retention-default**: Decoding MUST set `retentionDays` to `defaultRetentionDays` (30) when the key is absent.
- **status-models-optional**: Decoding MUST set `models` to nil when the key is absent (a daemon older than model routing).
- **status-init-defaults**: The memberwise initializer MUST default `cooldownSeconds` to 60, `expiryMarginSeconds` to 300, `retry` to true, `sticky` to true, `retentionDays` to 30 and `models` to nil.
- **status-saved-credentials**: `savedCredentials` MUST be the item keys of every credential the daemon holds, the set the pool can be chosen from.
- **status-retention-zero**: A `retentionDays` of 0 MUST mean routing history is kept forever.

### Report

- **report-row-verbatim-nil**: `AccountRouterReportRowDTO.account` MUST be nil for the row counting requests forwarded verbatim.
- **report-row-rate-limited**: `rateLimited` MUST count 429s relayed from the account plus 429s it answered that a retry hid.
- **report-since-zero**: `AccountRouterReportDTO.sinceHours` MUST be the window asked for, with 0 meaning all time.
- **report-models-optional**: `AccountRouterReportDTO.models` MUST default to nil in the initializer and MUST decode as nil when absent (a daemon older than model routing).
- **retried-account-match**: `AccountRouterReportDTO.retriedAccount(in:status:)` MUST return the name between the last `(retry after ` and a trailing ` <status>)` when the rule ends with that suffix.
- **retried-account-status-mismatch**: `retriedAccount` MUST return nil when the rule does not end with ` <status>)` for the given status.
- **retried-account-no-marker**: `retriedAccount` MUST return nil when the rule contains no `(retry after ` marker.
- **retried-account-overlap**: `retriedAccount` MUST return nil when the marker and the suffix overlap (`x (retry after 429)`), because there is no name.
- **retried-account-empty-name**: `retriedAccount` MUST return nil when the name is empty.
- **retried-account-whitespace**: `retriedAccount` MUST return nil when the name contains any whitespace character.
- **retried-account-last-marker**: `retriedAccount` MUST search for the marker from the end of the rule, so only the trailing marker counts.

### Routing-log row and page

- **exchange-required-fields**: `AccountRouterExchangeDTO` MUST carry `id`, `startedAt`, `durationMs`, `method` and `path` as non-optional values.
- **exchange-started-at-verbatim**: `startedAt` MUST be the ISO-8601 string with fractional seconds exactly as stored, not a parsed date.
- **exchange-path-no-query**: `path` MUST be the request path without its query.
- **exchange-status-nil**: `status` MUST be nil when the client went away before a final status was relayed.
- **exchange-account-nil**: `account` MUST be nil when the request was forwarded verbatim.
- **exchange-routing-rule-nil**: `routingRule` MUST be nil when routing was off.
- **exchange-model-defaults**: The initializer MUST default every model-routing field (`requestedModel`, `routedModel`, `servedModel`, `modelRule`, `provider`, `threadKind`, `writes`, `inputTokens`, `outputTokens`, `cacheReadTokens`, `cacheCreationTokens`, `stopReason`) to nil.
- **exchange-routed-model**: `routedModel` MUST be set only when the body sent upstream named a model other than the one requested.
- **exchange-thread-kind**: `threadKind` MUST hold a `ModelThreadKind` raw value as a plain string.
- **exchange-error-scrubbed**: `error` MUST be the stored, already-scrubbed text; the DTO does not scrub it.
- **page-newest-first**: `AccountRouterExchangePageDTO.exchanges` MUST be one page of the routing log, newest first, as the daemon ordered it.

### Rule filter

- **rule-filter-cases**: `AccountRouterRuleFilter` MUST have exactly the cases `sticky`, `ranked`, `switched`, `allIneligible`, `passthrough`, `retried` and `off`, in that order.
- **rule-filter-raw-values**: Each case's raw value MUST be its name, except `allIneligible`, whose raw value MUST be `all-ineligible`.
- **rule-filter-valid-list**: `validList` MUST be every raw value in case order joined by `, ` (`sticky, ranked, switched, all-ineligible, passthrough, retried, off`).
- **rule-filter-unknown-message**: `unknown(_:)` MUST return `Unknown rule "<raw>"; use one of <validList>.`
- **rule-filter-off-is-null**: `off` MUST select rows whose routing rule is null (routing was off), and `retried` MUST overlap the other families; the matching itself is the daemon's (`DaemonDatabase.routerExchangePage` and `routerRuleCondition`; the source's doc comment calls it `DatabaseManager.routerExchangePage`).

### Routing-log query

- **query-all-optional**: Every field of `AccountRouterExchangeQueryDTO` (`afterId`, `beforeId`, `limit`, `account`, `rule`, `sinceHours`) MUST be optional, and nil MUST mean "no filter".
- **query-init-defaults**: The initializer MUST default every field to nil.
- **query-mutable**: The query's fields MUST be settable after construction (`var`).
- **query-effective-limit-default**: `effectiveLimit` MUST be `defaultLimit` (200) when `limit` is nil.
- **query-effective-limit-floor**: `effectiveLimit` MUST be 1 when `limit` is 0 or negative.
- **query-effective-limit-ceiling**: `effectiveLimit` MUST be `maxLimit` (1000) when `limit` exceeds 1000.
- **query-effective-limit-passthrough**: `effectiveLimit` MUST equal `limit` when it is between 1 and 1000 inclusive.
- **query-verbatim-account**: `verbatimAccount` MUST be `-`, the `account` value that selects rows forwarded verbatim.
- **query-since-hours**: A `sinceHours` of nil, 0 or less MUST mean all time.
- **query-unknown-rule-refused**: Decoding a query whose `rule` is a string that is not a raw value MUST throw a data-corrupted decoding error on the `rule` key whose debug description is `AccountRouterRuleFilter.unknown(raw)`.
- **query-rule-absent**: Decoding a query whose `rule` key is absent or null MUST set `rule` to nil.
- **query-wrong-type-throws**: Decoding a query whose field holds the wrong JSON type (a string `limit`) MUST throw a type-mismatch decoding error.

### Preference write

- **prefs-partial**: Every field of `AccountRouterPreferencesRequestDTO` (`enabled`, `accounts`, `fiveHourCeiling`, `cooldownSeconds`, `expiryMarginSeconds`, `retry`, `sticky`, `retentionDays`, `models`) MUST be optional, and a nil field MUST mean "leave that setting as it is".
- **prefs-init-defaults**: The initializer MUST default every field to nil.
- **prefs-models-whole**: `models`, when non-nil, MUST be written whole.
- **prefs-ranges-documented**: The documented ranges MUST be 1–3600 s for `cooldownSeconds`, 0–3600 s for `expiryMarginSeconds` and 0–3650 days for `retentionDays` (0 keeps history forever).
- **prefs-no-self-validation**: The DTO MUST NOT validate its own values; decoding and initializing accept any value, and the daemon's `AccountRouterPreferences.setAccountRouter` enforces the ranges, a 5-hour ceiling above 0 and at most 1, and `isRoutable` on each account.

## Appearance

Not applicable — this is a set of wire data types and pure helpers, not a visual component.

## States

Not applicable — this is a set of wire data types and pure helpers, not a visual component.

## Accessibility

Not applicable — this is a set of wire data types and pure helpers, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ardto-001 | routable-accepts-kind-and-name | `isRoutable("oauth:a@x.com")` | true |
| ardto-002 | routable-accepts-kind-and-name | `isRoutable("long-lived:b")` | true (both accepted by `AccountRouterPreferencesTests.testWritesEveryFieldItIsGiven`) |
| ardto-003 | routable-rejects-bare-name | `isRoutable("a@x.com")` | false |
| ardto-004 | routable-needs-name | `isRoutable("oauth:")` | false |
| ardto-005 | routable-needs-kind | `isRoutable("token:a@x.com")` | false |
| ardto-006 | routable-name-unvalidated | `isRoutable("oauth:a b:c")` | true |
| ardto-007 | retried-account-match, retried-account-last-marker | `retriedAccount(in: "ranked (retry after oauth:a@x.com 429)", status: 429)` | `"oauth:a@x.com"` (`AccountRouterRecordTests.testRetriedAccountParsesOnlyTheTrailingMarker`) |
| ardto-008 | retried-account-status-mismatch | `retriedAccount(in: "ranked (retry after oauth:a@x.com 401)", status: 429)` | nil (same test) |
| ardto-009 | retried-account-empty-name | `retriedAccount(in: "ranked (retry after  429)", status: 429)` (two spaces) | nil (same test) |
| ardto-010 | retried-account-no-marker | `retriedAccount(in: "ranked", status: 429)` | nil (same test) |
| ardto-011 | retried-account-overlap | `retriedAccount(in: "x (retry after 429)", status: 429)` | nil (same test) |
| ardto-012 | retried-account-whitespace | `retriedAccount(in: "r (retry after a b 429)", status: 429)` | nil |
| ardto-013 | query-effective-limit-default | `AccountRouterExchangeQueryDTO().effectiveLimit` | 200 (`AccountRouterRecordTests.testLimitIsClampedToOneThroughAThousand` returns `defaultLimit` rows) |
| ardto-014 | query-effective-limit-floor | `limit: 0`; `limit: -7` | `effectiveLimit` 1 in both (same test) |
| ardto-015 | query-effective-limit-ceiling | `limit: 5000` | `effectiveLimit` 1000 (same test) |
| ardto-016 | query-effective-limit-passthrough | `limit: 2` | `effectiveLimit` 2 (`AccountRouterRecordTests.testPageIsNewestFirstAndPagesByAfterAndBeforeId` returns `[5, 4]` for `limit: 2`) |
| ardto-017 | query-unknown-rule-refused, rule-filter-unknown-message | decode `{"rule":"bogus"}` | throws data-corrupted on `rule`, description `Unknown rule "bogus"; use one of sticky, ranked, switched, all-ineligible, passthrough, retried, off.` (not tested directly; `AccountRouterRoutesTests.testAnUnknownRuleIs400ListingTheValidOnes` checks every raw value appears in the daemon route's own 400, which is built from `validList`) |
| ardto-018 | query-rule-absent, query-all-optional | decode `{}` | every field nil; `effectiveLimit` 200 |
| ardto-019 | query-wrong-type-throws | decode `{"limit":"ten"}` | throws type-mismatch |
| ardto-020 | rule-filter-raw-values, rule-filter-valid-list | `AccountRouterRuleFilter.validList` | `"sticky, ranked, switched, all-ineligible, passthrough, retried, off"` |
| ardto-021 | query-verbatim-account | `AccountRouterExchangeQueryDTO.verbatimAccount` | `"-"` (`testAccountDashMeansVerbatimAndAnyOtherIsAnExactKey` selects only the verbatim row) |
| ardto-022 | status-cooldown-default, status-expiry-margin-default, status-retry-default, status-sticky-default, status-retention-default, status-models-optional | decode status JSON with only the seven required keys | `cooldownSeconds` 60, `expiryMarginSeconds` 300, `retry` true, `sticky` true, `retentionDays` 30, `models` nil |
| ardto-023 | status-required-keys | decode status JSON without `baseUrl` | throws key-not-found |
| ardto-024 | base-url-spelling, camel-case-keys | encode status with a convert-to-snake-case encoder | JSON has `base_url`, `five_hour_ceiling`, `saved_credentials` (`AccountRouterRoutesTests.testStatusIsSnakeCaseAndNamesNoSecret`) |
| ardto-025 | secret-free | encode a status whose pool holds a credential | output contains no `sk-ant` (same test) |
| ardto-026 | status-init-defaults | `AccountRouterStatusDTO(enabled:port:listening:baseUrl:fiveHourCeiling:pool:savedCredentials:)` | tuning fields equal the decode defaults in ardto-022 |
| ardto-027 | exchange-model-defaults | `AccountRouterExchangeDTO` built with only the fifteen leading arguments | every model-routing field nil |
| ardto-028 | optional-nil-omitted | encode `AccountRouterPreferencesRequestDTO(enabled: true)` | JSON has only `enabled` |
| ardto-029 | prefs-no-self-validation | decode `{"cooldownSeconds": 0}` into `AccountRouterPreferencesRequestDTO` | succeeds with `cooldownSeconds` 0 (refusal is the daemon's) |
| ardto-030 | pool-entry-decode-strict | decode a pool entry without `sessions` | throws key-not-found |
| ardto-031 | report-models-optional | decode a report without `models` | `models` nil |

## Edge Cases

- **Empty item key**: `isRoutable("")` MUST return false (no colon, so no kind).
- **Name with colons**: `isRoutable("oauth:a:b")` MUST return true; only the first colon splits kind from name.
- **Unknown kind prefix**: a key like `api:x` MUST be refused, even though it has a colon and a name.
- **Empty pool and credentials**: a status with `pool: []` and `savedCredentials: []` MUST decode and encode without error.
- **Older daemon**: a status missing every tuning key and `models` MUST decode with the defaults (60, 300, true, true, 30, nil); a report missing `models` MUST decode with nil.
- **Missing required status key**: a status missing any of the seven required keys MUST fail to decode rather than defaulting.
- **Limit boundaries**: `limit` 1 MUST yield 1, 1000 MUST yield 1000, 1001 MUST yield 1000, 0 MUST yield 1, and `Int.min` MUST yield 1, with no overflow (`max` then `min`).
- **sinceHours boundaries**: the query carries 0, negatives and `Int.max` unchanged; the DTO SHOULD NOT clamp them because the daemon interprets them (0 or less is all time; `AccountRouterRecordTests.testSinceHoursLimitsTheWindowAndZeroOrLessIsAllTime` shows the daemon clamps `Int.max` without overflow).
- **Account `-`**: `account: "-"` MUST be read as "verbatim rows", so a real item key `-` cannot be queried; `isRoutable("-")` is false, so no pooled credential has that key.
- **Rule as non-string**: a numeric `rule` MUST throw a type-mismatch decoding error, not the unknown-rule refusal.
- **Rule null**: `"rule": null` MUST decode as nil.
- **retriedAccount with the marker earlier in the rule**: only the last `(retry after ` counts; an earlier one followed by other text MUST NOT be matched.
- **retriedAccount with status 0 or negative**: the suffix is built from the integer as given (` 0)`, ` -1)`), so a rule ending that way MUST match it; no status validation is done.
- **Out-of-range preference values**: the DTO MUST carry them unchanged; refusal is the daemon's job.
- **Duplicate accounts in a preference write**: the DTO MUST carry duplicates unchanged; the daemon de-duplicates.
- **Concurrent access**: every DTO and the rule filter are immutable or value-semantics `Sendable` values, `AccountRouterItemKey` has no state, and every function is pure, so concurrent use needs no ordering rule.
- **Error states**: the only failures are decoding errors (key-not-found, type-mismatch, and the data-corrupted unknown rule), which MUST be thrown to the caller; nothing is swallowed.
- **Offline or disconnected state**: not applicable; these types perform no I/O. Transport failures belong to the client and daemon that carry them.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `AccountRouterStatusDTO.defaultCooldownSeconds` | `Int` | `60` | Cool-down used when a status omits `cooldownSeconds`, and the initializer's default. |
| `AccountRouterStatusDTO.defaultExpiryMarginSeconds` | `Int` | `300` | Expiry margin used when a status omits `expiryMarginSeconds`. |
| `AccountRouterStatusDTO.defaultRetentionDays` | `Int` | `30` | Retention used when a status omits `retentionDays`. |
| `AccountRouterStatusDTO.retry` default | `Bool` | `true` | Used when a status omits `retry`. |
| `AccountRouterStatusDTO.sticky` default | `Bool` | `true` | Used when a status omits `sticky`. |
| `AccountRouterExchangeQueryDTO.defaultLimit` | `Int` | `200` | Page size when `limit` is nil. |
| `AccountRouterExchangeQueryDTO.maxLimit` | `Int` | `1000` | Upper clamp for `effectiveLimit`. |
| `AccountRouterExchangeQueryDTO.verbatimAccount` | `String` | `"-"` | Account filter value for rows forwarded verbatim. |
| JSON key strategy | caller-supplied | none | The caller's encoder and decoder choose camelCase or snake_case on the wire; the daemon uses snake_case. |

## Deep Linking

Not applicable: the file declares data types and pure functions with no URL handling.

## Localization

`AccountRouterRuleFilter.unknown(_:)` returns a hardcoded English sentence, which the query decoder uses as the debug description of its data-corrupted error. The daemon's `GET /router/exchanges` route does not decode the DTO; it refuses an unknown `rule` query parameter with its own English 400 sentence built from `validList` (`rule must be one of <validList>`). Neither is localized.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none: inline literal) | `Unknown rule "<raw>"; use one of <validList>.` | Refusal for a routing-log rule filter that is not a known raw value |

## Accessibility Options

Not applicable: the file has no visual surface, so Reduce Motion, Increase Contrast and Differentiate Without Color have nothing to act on.

## Feature Flags

Not applicable: no type reads a flag. The router's `enabled` field and the optional `models` section are data the daemon reports, not flags these types evaluate.

## Analytics

Not applicable: the file emits no events.

## Privacy

- **Data collected**: The types carry, but do not collect, the following: item keys (`account`, `savedCredentials`, `accounts`), which embed an account email for OAuth credentials; `organizationId` / `organizationIds`; `sessionId`; request `method` and `path` without the query; quota utilizations; and token counts. They MUST NOT carry tokens, header values or bodies (secret-free).
- **Storage**: None. The types are in-memory values; the routing log they describe is stored by the daemon in its `account_router_exchange` table.
- **Transmission**: Values cross the loopback HTTP boundary between the daemon and its CLI and Settings clients; transport is the caller's.
- **Retention**: None in these types. `retentionDays` reports and sets how long the daemon keeps routing history (default 30, 0 forever).

## Logging

Not applicable: the file makes no log calls. `AccountRouterExchangeDTO.error` is text the daemon scrubbed before storing it.

## Platform Notes

- **SwiftUI**: Source platform (Swift, macOS). `Core/Sessions/Wire/AccountRouterDTOs.swift` nests every type in an extension of the `Sessions` namespace. Two types hand-write `init(from:)`: `AccountRouterStatusDTO` (`decodeIfPresent` with defaults for the tuning rows) and `AccountRouterExchangeQueryDTO` (decodes `rule` as a `String` first so an unknown value throws `DecodingError.dataCorruptedError` naming the valid list). Both keep a private `CodingKeys` that must list every property, or synthesised encoding drops it. `isRoutable` delegates to `ClaudeCredentialKind.parse(itemKey:)` in `Core/ClaudeAccounts`. SwiftUI views bind to these through the Settings panel's own model; the DTOs are not `ObservableObject`.
- **Compose**: Kotlin `@Serializable data class` per DTO with kotlinx.serialization and a `JsonNamingStrategy.SnakeCase` `Json` instance; tuning-row defaults become constructor default values with `explicitNulls = false` and `ignoreUnknownKeys`. `AccountRouterRuleFilter` is an `enum class` with `@SerialName("all-ineligible")`; refusing an unknown rule with the custom message needs a custom `KSerializer` that throws `SerializationException(unknown(raw))`.
- **React/Web**: TypeScript interfaces with snake_case keys or a camelCase mapping layer; validate with zod (`z.object` with `.default(60)` etc. for the tuning rows, `z.enum([...])` for the rule filter with a custom `errorMap` producing the unknown-rule sentence). `effectiveLimit` is `Math.min(Math.max(limit ?? 200, 1), 1000)`. JavaScript numbers lose integer precision above 2^53, unlike Swift `Int`.
- **AppKit / UIKit**: Same types as SwiftUI; an AppKit Settings panel or CLI uses `JSONEncoder`/`JSONDecoder` with `.convertToSnakeCase` / `.convertFromSnakeCase`, which is why `baseUrl` (not `baseURL`) is spelled as it is.
- **WinUI 3**: C# `record` types (immutable, value equality, matching `Equatable`) serialised with `System.Text.Json` using `JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower, DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull }`. Tuning-row defaults are property initializers (`public int CooldownSeconds { get; init; } = 60;`), which `System.Text.Json` keeps when the key is absent; required status keys use the `required` modifier so a missing one throws `JsonException`. `AccountRouterRuleFilter` is an `enum` with a custom `JsonConverter<T>` that maps `all-ineligible` and throws `JsonException(Unknown(raw))` for anything else (`JsonStringEnumConverter` cannot produce the custom sentence). `IsRoutable` splits at the first `:` with `string.IndexOf(':')` and checks the prefix against the kind values. `EffectiveLimit` is `Math.Clamp(Limit ?? 200, 1, 1000)`. A Settings page binds through a view model implementing `INotifyPropertyChanged` and an `ObservableCollection<PoolEntry>`, fetched with `HttpClient.GetFromJsonAsync` on `Task`/`async`; the records themselves stay plain data.

<!-- No `## Reference Implementations` section is authored. Record the code that implements this
ingredient with `cookr implements <uuid|rdid> <location> --platform <p>` and `cookr confirm <uuid|rdid>`;
a compiled doc or skill shows those rows as a derived section here. -->

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/AccountRouterDTOs.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Every DTO is secret-free by construction: no field can hold a token, header value or body, and the exchange's `error` is scrubbed before it is stored.
**Rationale**: The status, report and log are shown in a CLI, a Settings panel and over HTTP; a type with no place for a secret cannot leak one, which the routes test checks by asserting no `sk-ant` in the status body.
**Approved**: pending

**Decision**: `AccountRouterStatusDTO` decodes each tuning row and `models` with a default when absent, while the seven core keys stay required.
**Rationale**: "A daemon older than the tuning rows sends none of them: each reads as its default," so a newer client can read an older daemon; the core keys have no meaningful default.
**Approved**: pending

**Decision**: The status property is `baseUrl`, not Swift-idiomatic `baseURL`.
**Rationale**: Convert-from-snake-case turns `base_url` into `baseUrl`; `baseURL` would not round-trip.
**Approved**: pending

**Decision**: An unknown routing-log rule is refused with a sentence listing the valid ones, not a generic decoding error.
**Rationale**: A caller decoding a query sees which values are accepted rather than a bare type error; the daemon's route refuses an unknown query-string rule the same way, with a sentence built from `validList` (`testAnUnknownRuleIs400ListingTheValidOnes`).
**Approved**: pending

**Decision**: `effectiveLimit` lives on the query DTO and clamps to 1…1000 with a default of 200.
**Rationale**: "`limit` as the daemon applies it": clients can compute the page size the daemon will use without duplicating the clamp.
**Approved**: pending

**Decision**: `AccountRouterItemKey.isRoutable` is the one routable-key test, shared by the daemon, the CLI and the Settings panel, and a legacy bare-name key is never routable.
**Rationale**: One definition keeps what the UI offers and what the daemon accepts from drifting; a bare name has no kind to route by.
**Approved**: pending

**Decision**: `retriedAccount(in:status:)` is a port of model-router `cli.py`'s trailing-marker regex, matching only the last `(retry after <name> <status>)` and rejecting overlap, empty and whitespace-containing names.
**Rationale**: The report must count 429s a retry hid against the account that answered them, read from the stored rule string, matching the original tool's behavior.
**Approved**: pending

**Decision**: `AccountRouterPreferencesRequestDTO` documents ranges but does not enforce them.
**Rationale**: Validation, with user-facing sentences, is done once by the daemon's `AccountRouterPreferences.setAccountRouter`, so every client gets the same refusal; the DTO stays a plain partial-write shape where nil means "leave as is".
**Approved**: pending

**Decision**: `sinceHours` of nil, 0 or less means all time, and `account` `-` means verbatim rows.
**Rationale**: Sentinels keep the query flat and optional-only; `-` cannot collide with a routable key because `isRoutable("-")` is false.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | access-patterns |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | artifact-formatting |

The file holds only wire shapes and pure helpers, with no I/O, persistence or UI, so separation of concerns passes. Error handling is explicit: decoding failures throw, and the one custom refusal names the valid values. API conventions pass through consistent optional-means-absent semantics, backward-compatible defaults and a single key strategy. Pagination is supported with `afterId`/`beforeId` cursors and a clamped `limit`. Data minimisation passes because no type can hold a secret, though item keys still carry account emails. Unit test coverage is partial: `retriedAccount`, the effective limit, the rule filter cases, the verbatim account and the snake_case, secret-free status encoding are exercised by `AccountRouterRecordTests` and `AccountRouterRoutesTests`, but the status decoder's per-key defaults, `isRoutable`'s rejections and the query decoder's unknown-rule error are covered only indirectly through daemon routes or not at all. Input sanitisation is partial because the query clamps `limit` and refuses unknown rules, but the preference DTO carries out-of-range values unvalidated and relies on the daemon. The unknown-rule sentence is a hardcoded English literal, so no-hardcoded-strings fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
