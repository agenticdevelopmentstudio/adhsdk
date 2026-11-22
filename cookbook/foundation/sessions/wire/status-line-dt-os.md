---
id: 94bac7a5-3fc6-463d-86d1-7c59350cd7cb
title: "Status Line DTOs"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Wire records for the session daemon's usage and status-line endpoints, with tolerant decoders for version skew and the one record that carries a secret."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - dto
  - wire
depends-on:
  - e8286557-84ee-4f45-b78c-f1d184c51a37
  - d457c4d4-005c-4fcb-a3a6-3e1680bcb561
  - 2b552bde-d0bd-425a-9e79-fc624b52f516
related:
  - ea580796-8b16-4832-b11d-ad3cae991ecd
  - 704d4ae9-e344-44d4-b19c-eadfec082077
references: []
approved-by: ""
approved-date: ""
---

# Status Line DTOs

## Overview

`StatusLineDTOs.swift` declares, inside the `Sessions` namespace, the records the session daemon's usage and status-line endpoints return and its clients decode: the Python status line, the menu-bar app's Usage window and HUD, and the CLI. The file's own comment states the wire rule: "Snake-case JSON on the wire; camelCase Swift on this side." Every type is a `Codable`, `Sendable` struct with `let` fields.

The records fall into four groups:

- **Raw query rows**: `TurnAggregateDTO` (one row of a `/turns` aggregation), `ActiveHoursDTO` (the `/insights/active-hours` reply), `RateLimitSnapshotDTO` (one `rate_limit_snapshots` row) and `ClaudeVersionDTO` (one `/claude-versions` row).
- **The rendered usage table**: `UsageRowsDTO` (the `GET /insights/usage-rows` reply) and the rows it holds: `UsageQuotaRowDTO`, `UsageWeekRowDTO`, `UsageHoursRowDTO` with its per-metric `UsageHoursMetricDTO`, the HUD projection `UsageHUDDTO`, and per-account `UsageAccountSectionDTO`. The daemon formats every display string so the Python status line and the Swift Usage window render byte-identical text; clients only add color or dim styling.
- **Per-account quota**: `AccountQuotaReadingDTO`, one live reading built straight from an Anthropic response's `anthropic-ratelimit-unified-*` headers.
- **The credential hand-off**: `ClaudeCredentialDTO`, the one record that carries a secret: a saved login the app pushes to the daemon so the daemon can refresh and probe it.

A few behaviors live on the types themselves: the tolerant decoders of `RateLimitSnapshotDTO`, `UsageRowsDTO`, `UsageHoursRowDTO` and `UsageHoursMetricDTO`; the header parser `AccountQuotaReadingDTO.init(account:credentialKind:headers:)`; the de-duplication `UsageAccountSectionDTO.oneSectionPerAccount(_:)` and the key `UsageAccountSectionDTO.identity`; the window-width fallback `UsageQuotaRowDTO.resolvedWindowSeconds`; and the credential projections `ClaudeCredentialDTO.carrying(_:)` and `probeOnly`. Everything else (queries, formatting, thresholds, probing, refresh) belongs to the daemon, specified by the database recipe ([adhsdk.ingredient.data.storage.database](cookbook:ea580796-8b16-4832-b11d-ad3cae991ecd)). The JSON coders are the shared wire spelling ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37)); the credential kind is specified by [adhsdk.ingredient.foundation.claude-accounts.claude-credential-kind](cookbook:d457c4d4-005c-4fcb-a3a6-3e1680bcb561) and the login by [adhsdk.ingredient.foundation.claude-accounts.claude-o-auth-credential](cookbook:2b552bde-d0bd-425a-9e79-fc624b52f516).

## Behavioral Requirements

**Common**

- **dto-conformances**: Every type in the file MUST be a `Codable` and `Sendable` immutable value; none declares `Equatable`, `Hashable` or `Identifiable`.
- **dto-wire-spelling**: The records MUST travel with snake_case keys and camelCase properties, so `groupKey` is `group_key`, `idleThresholdS` is `idle_threshold_s`, `totalCostUsd` is `total_cost_usd`, `hudQuota` is `hud_quota` and `fableLimitPct` is `fable_limit_pct`. The conversion belongs to the caller's coder (the types' own coding keys are the camelCase names, so a plain `JSONDecoder` reads camelCase keys, as the decode tests in `AccountQuotaTests` do).
- **dto-timestamps-opaque**: String timestamps (`since`, `until`, `timestamp`, `weekStart`, `firstSeen`) MUST be carried exactly as given; no type here parses them.
- **dto-epoch-seconds**: Every `...ResetsAt` field and `UsageQuotaRowDTO.resetsAt` MUST hold Unix epoch seconds as an Int.
- **dto-nil-omitted-on-encode**: Encoding MUST omit the key of a nil optional field and MUST write every non-optional field, empty strings and `false` included (the synthesized encoders).

**Raw query rows**

- **turn-aggregate-fields**: `TurnAggregateDTO` MUST carry `groupKey` (String), `turnCount`, `inputTokens`, `outputTokens`, `cacheReadTokens`, `cacheCreationTokens` (Int) and `totalCostUsd` (Double), all required on decode.
- **turn-aggregate-group-key**: `groupKey` holds whatever the caller grouped by: a model name, a session id, or `"all"` when no grouping was asked for. Token columns are sums and cost is computed by the server from its pricing table; the DTO computes neither.
- **active-hours-fields**: `ActiveHoursDTO` MUST carry `since`, `until` (String), `idleThresholdS` (Int), `activeSeconds` (Double) and `turnCount` (Int), all required on decode.
- **claude-version-fields**: `ClaudeVersionDTO` MUST carry `claudeVersion`, `fieldsJson`, `fieldsCount`, `firstSeen` and `fieldPaths` (a list of Strings), all required on decode. `fieldsJson` is the first-seen payload as text; `fieldPaths` is the merged set of dotted paths seen across every capture of the version.
- **snapshot-fields**: `RateLimitSnapshotDTO` MUST carry `id` (Int64), `timestamp`, `sessionId`, `weekStart` (String), `elapsedHours` (Int), `elapsedDay`, `weeklyPct`, `dailyAvgPct`, `fiveHourPct` (Double), `fiveHourResetsAt`, `sevenDayResetsAt` (Int), `projectedPct` (Double), `accountEmail` (String), `spendPct` (Double) and `spendResetsAt` (Int).
- **snapshot-required-keys**: Decoding a snapshot MUST fail when any of its first twelve keys (`id` through `projected_pct`) is missing.
- **snapshot-tolerant-keys**: Decoding a snapshot MUST succeed when `account_email`, `spend_pct` or `spend_resets_at` is missing or `null`, defaulting them to `""`, `0` and `0`.
- **snapshot-init-defaults**: The snapshot initializer MUST default `accountEmail` to `""`, `spendPct` to `0` and `spendResetsAt` to `0`.
- **snapshot-spend-unclamped**: `spendPct` MUST be carried unclamped; it runs from 0 to 100 and above 100 once the spend limit is exceeded, and a consumer MUST NOT clamp it.
- **snapshot-spend-presence**: A consumer MUST treat `spendResetsAt == 0` as "no spend limit reported for this row" and MUST NOT read `spendPct` as a real 0 in that case; `spendResetsAt` is the presence sentinel for the whole spend window.

**UsageRowsDTO**

- **usage-rows-fields**: `UsageRowsDTO` MUST carry `available` (Bool), `quotaRows`, `weekRows`, `hoursRows`, `accountSections` (lists of the row types), `hudQuota` (optional `UsageHUDDTO`) and `oauthEmail` (String).
- **usage-rows-required-keys**: Decoding MUST fail when `available`, `quota_rows` or `week_rows` is missing.
- **usage-rows-tolerant-keys**: Decoding MUST succeed when `hours_rows`, `hud_quota`, `account_sections` or `oauth_email` is missing or `null`, yielding `[]`, nil, `[]` and `""`.
- **usage-rows-init-defaults**: The initializer MUST require `available`, `quotaRows` and `weekRows` and MUST default `hoursRows` and `accountSections` to `[]`, `hudQuota` to nil and `oauthEmail` to `""`.
- **usage-rows-available**: `available` is false when the daemon has no rate-limit snapshots yet; a client SHOULD then show a no-data state (the type's doc comment; the client owns the rendering).
- **usage-rows-hud-key**: The HUD payload MUST travel under the key `hud_quota`, never `hud`: the retired `hud` key had a different shape, and an older app's decoder requires that shape's keys.
- **usage-rows-oauth-email**: `oauthEmail` holds the OAuth account email the daemon resolved from `~/.claude.json`, or `""` when unknown or for an API-key user.

**Usage rows**

- **quota-row-fields**: `UsageQuotaRowDTO` MUST carry `label`, `pctText`, `secondaryText`, `trailingText` (String), `secondaryDimmed`, `trailingDimmed` (Bool), and the optionals `pctColor`, `trailingColor` (String), `resetsAt`, `runOutSeconds`, `windowSeconds` (Int) and `pct` (Double).
- **quota-row-decode**: Decoding a quota row MUST fail when `label`, `pct_text`, `secondary_text`, `secondary_dimmed`, `trailing_text` or `trailing_dimmed` is missing, and MUST yield nil for any absent optional key.
- **quota-row-init-defaults**: The quota-row initializer MUST require `label` and `pctText`, default the two other Strings to `""` and the two Bools to `false`, and default every optional to nil.
- **quota-row-color-hints**: `pctColor` and `trailingColor` are hints carried as any String; the source documents `"red"` or `"yellow"` for `pctColor` and `"red"` for `trailingColor`, and the type does not check them.
- **quota-row-labels**: The type MUST expose the shared label spellings `fableLabel = "fable quota"`, `spendLabel = "spend"`, `sevenDayLabel = "7d quota"` and `fiveHourLabel = "5h quota"`, and the window widths `sevenDayWindowSeconds = 604800` and `fiveHourWindowSeconds = 18000`.
- **quota-row-min-projection**: The type MUST expose `minimumProjectionElapsed = 0.01`: the share of a window that must have elapsed before a pace or run-out is projected.
- **quota-row-spend-not-window**: A consumer MUST NOT treat a row labelled `spend` as window consumption; its `pct` is a share of a dollar cap and MAY exceed 100. The label is the only marker on the wire.
- **quota-row-fable-not-window**: A consumer MUST NOT treat a row labelled `fable quota` as window consumption; it measures Fable's spend against the 50 points of the weekly window it may use.
- **resolved-window-explicit**: `resolvedWindowSeconds` MUST return `windowSeconds` when it is set.
- **resolved-window-label-fallback**: When `windowSeconds` is nil, `resolvedWindowSeconds` MUST return 604800 for the label `7d quota`, 18000 for `5h quota` and nil for any other label (`spend`, `today`, `fable quota`).
- **week-row-fields**: `UsageWeekRowDTO` MUST carry `label`, `tokensText`, `costText`, `deltaText` (String) and `deltaColor` (optional String); the four Strings are required on decode, and the initializer defaults `deltaText` to `""` and `deltaColor` to nil.
- **hours-metric-fields**: `UsageHoursMetricDTO` MUST carry `hoursText`, `avgText`, `deltaText` (String) and `deltaColor` (optional String).
- **hours-metric-decode**: Decoding a metric MUST fail when `hours_text` or `avg_text` is missing and MUST succeed when `delta_text` or `delta_color` is missing, yielding `""` and nil.
- **hours-row-fields**: `UsageHoursRowDTO` MUST carry `label`, `hoursText`, `avgText`, `deltaText`, `weekLabel` (String), `deltaColor` (optional String) and `session`, `wallClock` (optional `UsageHoursMetricDTO`).
- **hours-row-decode**: Decoding an hours row MUST fail when `label`, `hours_text` or `avg_text` is missing and MUST succeed when `delta_text`, `delta_color`, `week_label`, `session` or `wall_clock` is missing, yielding `""`, nil, `""`, nil and nil.
- **hours-row-week-label-fallback**: A consumer SHOULD fall back to `label` when `weekLabel` is `""`, which is what a daemon predating the per-metric split sends.
- **hud-fields**: `UsageHUDDTO` MUST carry `sevenDayPctText` and `accountEmail` (String) and the optionals `sevenDayPctColor`, `fiveHourPctText`, `fiveHourPctColor` (String), `sevenDayResetsAt` and `fiveHourResetsAt` (Int).
- **hud-decode**: Decoding a HUD payload MUST fail when `seven_day_pct_text` or `account_email` is missing; its decoder is synthesized, so the initializer's `accountEmail = ""` default does not apply on decode.
- **hud-no-five-hour**: A nil `fiveHourPctText` means the account has no five-hour window on record; a consumer MUST drop the 5h part rather than draw 0%.
- **hud-reset-instants**: The HUD reset instants MUST be numbers, not text, so a client can recompute both countdowns every second; nil means no trustworthy reset instant.

**Account sections**

- **section-fields**: `UsageAccountSectionDTO` MUST carry `accountEmail` (String), `credentialKind` (optional String), `rows` (a list of `UsageQuotaRowDTO`), `errorText` (optional String) and `isCurrent` (Bool).
- **section-is-current-false**: The initializer MUST set `isCurrent` to `false` and offer no parameter for it, and encoding MUST write `is_current`.
- **section-decode**: Decoding a section MUST fail when `account_email`, `rows` or `is_current` is missing (the synthesized decoder), and MUST yield nil for a missing `credential_kind` or `error_text`.
- **section-kind-raw-string**: `credentialKind` MUST stay a raw String so a kind this build does not know decodes instead of failing the whole payload.
- **section-identity**: `identity` MUST return `"<credentialKind>:<accountEmail>"` when `credentialKind` is non-empty, and `accountEmail` alone when it is nil or empty, the same spelling as the keychain item key.
- **one-section-key**: `oneSectionPerAccount(_:)` MUST group sections by `accountEmail` with leading and trailing spaces and tabs trimmed and the result lower-cased.
- **one-section-login-wins**: For an address with more than one section, `oneSectionPerAccount(_:)` MUST keep the first login section, where a login is any section whose `credentialKind` is not `"long-lived"` (nil and unknown kinds count as logins).
- **one-section-token-only**: An address whose sections are all `"long-lived"` MUST keep its first section.
- **one-section-order**: `oneSectionPerAccount(_:)` MUST return one section per address in the order each address first appears in the input; a replacement takes the replaced section's position.

**Account quota readings**

- **reading-fields**: `AccountQuotaReadingDTO` MUST carry `account` (String) and the optionals `credentialKind`, `fiveHourStatus`, `sevenDayStatus`, `fableLimitStatus`, `errorText` (String), `fiveHourPct`, `sevenDayPct`, `fableLimitPct` (Double) and `fiveHourResetsAt`, `sevenDayResetsAt`, `fableLimitResetsAt` (Int). Only `account` is required on decode.
- **reading-header-names**: The header initializer MUST read, for each window prefix `5h`, `7d` and `7d_oi`, the headers `anthropic-ratelimit-unified-<prefix>-utilization`, `-reset` and `-status`, by exact lower-case key; the caller MUST lower-case the keys first.
- **reading-pct-times-100**: A utilization header that parses as a Double MUST become that value times 100, with no branch on its size, so `0.27` is 27 and `1.05` is 105.
- **reading-pct-unparsable**: A missing or non-numeric utilization header MUST leave its percentage nil.
- **reading-reset-millis**: A reset header whose value is above 1e12 MUST be divided by 1000; the result MUST be truncated toward zero.
- **reading-reset-unrepresentable**: A reset that is not an exactly representable Int after that step (`inf`, `-inf`, `nan`, `1e400`, `1e300`) MUST leave its reset nil rather than trap.
- **reading-status-verbatim**: Each `-status` header MUST be carried verbatim, nil when absent.
- **reading-fable-window**: The `7d_oi` window MUST fill `fableLimitPct`, `fableLimitResetsAt` and `fableLimitStatus`, which are nil when the response does not carry that window.
- **reading-no-windows-error**: When neither the `5h` nor the `7d` utilization yields a percentage, `errorText` MUST be `"no usage readings in response"`; otherwise it MUST be nil. A `7d_oi` reading alone does not count.
- **reading-pct-non-finite**: NEEDS REVIEW: Not implemented in source. A utilization of `nan` or `inf` parses as a Double and becomes a non-finite percentage with no guard, unlike the reset path, and it counts as a reading, so `errorText` stays nil. `StenographerWire.encoder()` keeps `JSONEncoder`'s default non-conforming-float strategy, which throws on a non-finite Double, so such a reading cannot be encoded by the wire coder; whether the parser should yield nil instead needs a decision from the toolkit owner.

**ClaudeCredentialDTO**

- **credential-fields**: `ClaudeCredentialDTO` MUST carry `account` and `token` (String, required on decode) and the optionals `credentialKind`, `itemKey` (String), `oauth` (`ClaudeOAuthCredential`) and `refreshWithin` (Double).
- **credential-init-defaults**: The initializer MUST require `account` and `token` and default the four optionals to nil.
- **credential-item-key-carried**: `itemKey` MUST be carried as given, not re-derived from `credentialKind` and `account`, because a legacy keychain item is addressed by its bare account name; a credential with a nil `itemKey` cannot have a rotation written back.
- **credential-carrying**: `carrying(_:)` MUST return a credential with the same `account`, `credentialKind` and `itemKey`, `token` set to the rotated login's `accessToken`, `oauth` set to the rotated login, and `refreshWithin` nil.
- **credential-probe-only**: `probeOnly` MUST return a credential with the same `account`, `credentialKind`, `token` and `itemKey`, and with `oauth` and `refreshWithin` nil.
- **credential-refresh-within**: `refreshWithin` is a one-evaluation override, in seconds, of the margin below which the access token counts as expired; the daemon owns the default margin (five minutes per the source comment).
- **credential-encodes-secret**: Encoding a `ClaudeCredentialDTO` MUST write `token` and, when present, the whole `oauth` login, refresh token included; the type offers no redacted encoding.

## Appearance

Not applicable — these are wire data transfer objects, not a visual component.

## States

Not applicable — these are wire data transfer objects, not a visual component.

## Accessibility

Not applicable — these are wire data transfer objects, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-line-dtos-001 | reading-pct-times-100, reading-no-windows-error | Header init with `5h-utilization` `"0.18"` and `7d-utilization` `"0.27"` (`AccountQuotaTests.testReadingNormalizesFractionToPercent`) | `fiveHourPct` 18.0, `sevenDayPct` 27.0, `errorText` nil |
| status-line-dtos-002 | reading-pct-times-100 | Header init with `5h-utilization` `"1.05"` and `7d-utilization` `"1.0"` (`testReadingOverQuotaFractionIsNotTruncated`) | `fiveHourPct` 105.0, `sevenDayPct` 100.0 |
| status-line-dtos-003 | reading-reset-millis | Header init with `5h-utilization` `"0.5"` and `5h-reset` `"1750000000000"` (`testReadingNormalizesMillisecondResets`) | `fiveHourResetsAt` 1750000000 |
| status-line-dtos-004 | reading-no-windows-error, reading-pct-unparsable | Header init with an empty header map (`testReadingWithoutUsageHeadersCarriesError`) | Both percentages nil; `errorText` `"no usage readings in response"` |
| status-line-dtos-005 | reading-reset-unrepresentable, reading-reset-millis | `5h-utilization` `"0.5"` with `5h-reset` each of `inf`, `-inf`, `nan`, `1e400`, `1e300`; then `5h-reset` `"1700000000123"` (`AccountQuotaObserveTests.testAMalformedResetIsNoReadingRatherThanATrap`) | `fiveHourResetsAt` nil and `fiveHourPct` 50 for each malformed value; 1700000000 for the millisecond value |
| status-line-dtos-006 | reading-fable-window, reading-status-verbatim | `7d-utilization` `"0.4"`, `7d_oi-utilization` `"0.37"`, `7d_oi-reset` `"1800000000000"`, `7d_oi-status` `"allowed"` (`testTheReadingCarriesTheFableBucketWhenTheGatewaySendsIt`) | `fableLimitPct` 37.0, `fableLimitResetsAt` 1800000000, `fableLimitStatus` `"allowed"` |
| status-line-dtos-007 | reading-fable-window | Only `7d-utilization` `"0.4"` (`testAReadingWithoutTheFableBucketCarriesNone`) | All three `fableLimit` fields nil |
| status-line-dtos-008 | reading-no-windows-error | Only `7d_oi-utilization` `"0.5"` | `fableLimitPct` 50; `errorText` `"no usage readings in response"` |
| status-line-dtos-009 | reading-header-names | Header `Anthropic-Ratelimit-Unified-5h-Utilization: 0.5` (mixed case), nothing else | `fiveHourPct` nil; `errorText` set |
| status-line-dtos-010 | snapshot-tolerant-keys, snapshot-required-keys | Decode a snapshot body with the twelve required snake_case keys only; then one with `projected_pct` removed | First succeeds with `accountEmail` `""`, `spendPct` 0, `spendResetsAt` 0; second throws key-not-found |
| status-line-dtos-011 | snapshot-init-defaults, snapshot-spend-presence | Construct a snapshot with the twelve required arguments | `spendResetsAt` 0, so the spend window reads as absent |
| status-line-dtos-012 | usage-rows-tolerant-keys, usage-rows-required-keys | Decode `{"available": false, "quota_rows": [], "week_rows": []}`; then `{"available": true, "quota_rows": []}` | First succeeds with `hoursRows` `[]`, `hudQuota` nil, `accountSections` `[]`, `oauthEmail` `""`; second throws for `week_rows` |
| status-line-dtos-013 | usage-rows-hud-key, dto-nil-omitted-on-encode | Encode `UsageRowsDTO(available: true, quotaRows: [], weekRows: [], hudQuota: UsageHUDDTO(sevenDayPctText: "48.0%", fiveHourPctText: nil))` with the snake_case encoder | JSON has `hud_quota` with `seven_day_pct_text` and `account_email`, no `hud` key and no `five_hour_pct_text` key |
| status-line-dtos-014 | hours-row-decode, hours-metric-decode | Decode an hours row `{"label": "hrs this week", "hours_text": "86.1h / 42.0h", "avg_text": "12.3h/d / 6.0h/d", "session": {"hours_text": "86.1h", "avg_text": "12.3h/d"}}` | Succeeds; `deltaText` `""`, `weekLabel` `""`, `wallClock` nil, `session.deltaText` `""`, `session.deltaColor` nil |
| status-line-dtos-015 | hours-metric-decode | Decode a metric `{"hours_text": "86.1h"}` | Throws key-not-found for `avg_text` |
| status-line-dtos-016 | quota-row-decode, quota-row-init-defaults | Decode `{"label": "7d quota", "pct_text": "48.0%"}`; then encode `UsageQuotaRowDTO(label: "7d quota", pctText: "48.0%")` | Decode throws for `secondary_text`; the encoding writes `secondary_text` `""`, `secondary_dimmed` false, `trailing_text` `""`, `trailing_dimmed` false and no optional keys |
| status-line-dtos-017 | resolved-window-explicit, resolved-window-label-fallback | `resolvedWindowSeconds` for rows labelled `7d quota`, `5h quota`, `spend`, `fable quota` with `windowSeconds` nil; then `spend` with `windowSeconds` 100 | 604800, 18000, nil, nil; then 100 |
| status-line-dtos-018 | section-identity | `identity` for `accountEmail` `a@x.com` with `credentialKind` `"oauth"`, `"long-lived"`, `""` and nil (the first two from `AccountQuotaTests.testTwoCredentialsForOneEmailAreTwoSections`) | `oauth:a@x.com`, `long-lived:a@x.com`, `a@x.com`, `a@x.com` |
| status-line-dtos-019 | one-section-login-wins, one-section-order, one-section-key | `oneSectionPerAccount` of `[B (long-lived, "b@x.com"), A (long-lived, " A@x.com"), B' (oauth, "B@X.com"), A' (nil, "a@x.com")]` | `[B', A']`: two sections in first-seen address order, each login replacing the token |
| status-line-dtos-020 | one-section-token-only, one-section-login-wins | `oneSectionPerAccount` of `[T1 (long-lived, "c@x.com"), T2 (long-lived, "c@x.com")]`; then `[L1 (oauth), L2 (oauth)]` for one address | `[T1]`; then `[L1]` |
| status-line-dtos-021 | section-is-current-false, section-decode | Construct a section and encode it; then decode a section body without `is_current` | Encoding has `is_current` false; decoding throws key-not-found |
| status-line-dtos-022 | hud-decode | Decode `{"seven_day_pct_text": "48.0%"}` as `UsageHUDDTO` | Throws key-not-found for `account_email` |
| status-line-dtos-023 | credential-probe-only | `probeOnly` of a credential with `oauth` set and `refreshWithin` 3600 | Same `account`, `credentialKind`, `token`, `itemKey`; `oauth` nil; `refreshWithin` nil |
| status-line-dtos-024 | credential-carrying | `carrying(rotated)` of a credential with `refreshWithin` 3600, where `rotated.accessToken` is `"new"` | `token` `"new"`, `oauth` equal to `rotated`, `itemKey` unchanged, `refreshWithin` nil |
| status-line-dtos-025 | credential-fields, credential-encodes-secret | Decode `{"account": "a@x.com", "token": "t"}`; encode a credential with `oauth` set | Decode succeeds with the four optionals nil; the encoding contains the login's refresh token |
| status-line-dtos-026 | turn-aggregate-fields, active-hours-fields, claude-version-fields, dto-wire-spelling | Encode one of each with the snake_case encoder, remove one key from each, decode | Keys include `group_key`, `total_cost_usd`, `idle_threshold_s`, `fields_json`, `field_paths`; each decode with a removed key throws |
| status-line-dtos-027 | dto-conformances | Pass each type to a generic function constrained to `Codable & Sendable` | Compiles |
| status-line-dtos-028 | quota-row-labels, quota-row-min-projection | Read the static constants | `"fable quota"`, `"spend"`, `"7d quota"`, `"5h quota"`, 604800, 18000, 0.01 |

## Edge Cases

- **Null and empty input**: A tolerant key present with JSON `null` MUST decode as its default, because the hand-written decoders read present-or-nil and then default. An empty `quotaRows`, `weekRows` or `hoursRows` list MUST decode. `oneSectionPerAccount([])` MUST return `[]`. A header map with no usage headers MUST yield a reading whose `errorText` is set (vector 004).
- **Version skew, newer daemon and older app**: An older app decoding a newer payload ignores unknown keys. A newly added key MUST stay optional on decode, which is why `hudQuota` is a new key rather than a reshaped `hud` and why `isCurrent` is still encoded (see Design Decisions).
- **Version skew, older daemon and newer app**: A payload missing `account_email`, the spend pair, `hours_rows`, `hud_quota`, `account_sections`, `oauth_email`, the per-metric fields, or the quota-row optionals MUST decode with defaults. A payload missing a required key fails the whole decode, including the enclosing `UsageRowsDTO`.
- **Nested strictness**: A key missing inside a nested type's own required set propagates out through the enclosing tolerant decoder. A present `hud_quota` without `account_email`, or an account section without `is_current`, MUST fail the whole `UsageRowsDTO` decode.
- **Boundary values**: Percentages are not clamped anywhere: a reading of `1.05` is 105, `spendPct` MAY exceed 100, and negative utilizations pass through. A reset at exactly 1e12 is not divided; only values above it are. A negative reset is kept as a negative Int.
- **Malformed headers**: A non-numeric utilization or reset MUST yield nil for that field. A non-finite utilization is the open question on `reading-pct-non-finite`.
- **Whitespace in addresses**: `oneSectionPerAccount` trims spaces and tabs only; an address with a trailing newline is a different key from the same address without one.
- **Unknown credential kinds**: A section or reading whose `credentialKind` this build does not know MUST still decode; in `oneSectionPerAccount` it counts as a login.
- **Concurrent access**: The values are immutable and `Sendable`, so they MAY be shared across threads and actors; `oneSectionPerAccount` is a pure function.
- **Error states**: Decoding errors are the standard decoding errors and are thrown, not swallowed. A failed probe is data, not an error: `errorText` is set on the reading or section.
- **Offline or disconnected state**: Not applicable: the types perform no I/O; the clients that fetch them and the daemon that probes Anthropic own connectivity.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| wire coding strategy | snake_case keys | caller's coder | The types expect a coder that converts snake_case wire keys to the camelCase property names, such as `StenographerWire`. |
| `RateLimitSnapshotDTO` optional initializer parameters | String, Double, Int | `""`, `0`, `0` | `accountEmail`, `spendPct`, `spendResetsAt`. |
| `UsageRowsDTO` optional initializer parameters | lists, optional, String | `[]`, nil, `""` | `hoursRows`, `accountSections`, `hudQuota`, `oauthEmail`. |
| `UsageQuotaRowDTO` optional initializer parameters | String, Bool, optionals | `""`, `false`, nil | Everything except `label` and `pctText`. |
| `ClaudeCredentialDTO.refreshWithin` | Double (seconds) | nil | Per-evaluation expiry margin override, set only when a token is handed to a terminal. |
| `UsageQuotaRowDTO.minimumProjectionElapsed` | Double | `0.01` | Share of a window elapsed before pace and run-out are projected. |
| `headers` (`AccountQuotaReadingDTO`) | String-to-String map | required | One probe's response headers with lower-cased keys. |

## Deep Linking

Not applicable: the types define no URL or deep link; the routes they ride (`/turns`, `/insights/active-hours`, `/insights/usage-rows`, `/claude-versions`, `/rate-limits`) are daemon API routes.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none) | `no usage readings in response` | `AccountQuotaReadingDTO.errorText` when neither window answered; a hardcoded English literal |
| (none) | `fable quota`, `spend`, `7d quota`, `5h quota` | Row labels used as wire markers and shown as row text; hardcoded English |

The display strings in the usage rows (`pctText`, `secondaryText`, `tokensText` and the rest) are formatted by the daemon and carried verbatim; the labels double as wire identifiers, so localizing them would change the wire contract.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: `ClaudeCredentialDTO` carries a bearer token and, for an OAuth login, the whole `ClaudeOAuthCredential` with its refresh token. `accountEmail`, `oauthEmail`, `account` and `sessionId` identify the user and their sessions. `ClaudeVersionDTO.fieldsJson` is a captured status-line payload.
- **Storage**: The types store nothing. Per the source comments, the app keeps credentials in its keychain items and the daemon keeps pushed credentials in memory, keeping only `probeOnly` (no refresh token) after an evaluation.
- **Transmission**: The credential travels from the app to the daemon over the shared XPC listener, and a rotation travels back in the reply on the same connection; the usage records travel over XPC and the daemon's loopback HTTP.
- **Retention**: Not set by these types. The source states the daemon exposes no way to read a token back and holds a refresh token only for the evaluation that might spend it.
- **Token lifetimes**: The source comments put a bearer access token at eight hours and the default refresh margin at five minutes; both are the daemon's, and `refreshWithin` overrides the margin for one evaluation. A `claude setup-token` token never expires and never rotates, so its `oauth` is nil.
- **Revocation**: Not handled by these types; a failed probe surfaces as `errorText` (an expired token is the source's example).

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: `StatusLineDTOs.swift` in `Core/Sessions/Wire` is Foundation-only and holds no view code. A SwiftUI Usage view uses the pre-formatted strings as given and maps `pctColor` and `deltaColor` hints to colors; the records are not `Identifiable`, so a `ForEach` needs an explicit id such as `\.label` or `\.identity`. A live countdown recomputes from `resetsAt` with a `TimelineView` rather than re-reading `secondaryText`.
- **Compose**: `kotlinx.serialization` data classes with `@SerialName` snake_case keys and `ignoreUnknownKeys = true`. Give the tolerant fields default values and enable `coerceInputValues` so `null` takes the default; leave the strict fields without defaults so a missing key throws, as in the source. Port the header parser with `toDoubleOrNull()` and a finite, in-range check before `toLong()`.
- **React/Web**: TypeScript interfaces with snake_case keys and the tolerant keys optional, defaulted when read. Parse headers with `Number()` and `Number.isSafeInteger` after `Math.trunc` for resets; note that `JSON.stringify` writes `NaN` as `null`, unlike Swift. `oneSectionPerAccount` ports as a `Map` keyed by the trimmed, lower-cased address, which keeps insertion order.
- **AppKit / UIKit**: Same Foundation types. The hand-written decoders read present-or-nil and then default; a port to Objective-C or a manual parser keeps that split between strict and tolerant keys exactly, because the strict set is what fails an older client.
- **WinUI 3**: Use C# `record` types with `System.Text.Json` and `JsonNamingPolicy.SnakeCaseLower` (.NET 8 or later), with `UnmappedMemberHandling.Skip` so unknown keys are ignored. Mark the strict properties `required` so a missing key throws, and give the tolerant ones initializers (`public string AccountEmail { get; init; } = "";`, `public IReadOnlyList<UsageHoursRowDto> HoursRows { get; init; } = [];`); a JSON `null` for a non-nullable property needs a small `JsonConverter` that returns the default. Set `DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull` to match the omitted nil keys. Use `long` for `Id`, `int?` for reset instants, `double?` for percentages. Port the header parser over `HttpResponseMessage.Headers` (case-insensitive already, so the lower-casing step is free) with `double.TryParse(..., CultureInfo.InvariantCulture)`, `double.IsFinite`, and a range check before casting to `int`. Hold `ClaudeCredentialDto` only in memory, never in `ApplicationData.LocalSettings`; Windows Credential Manager (`PasswordVault`) is the keychain counterpart on the app side. Surface rows in the UI through an `ObservableCollection` on a view model that implements `INotifyPropertyChanged`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/StatusLineDTOs.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Newly added keys are optional on decode, through hand-written decoders on `RateLimitSnapshotDTO`, `UsageRowsDTO`, `UsageHoursRowDTO` and `UsageHoursMetricDTO`.
**Rationale**: The source comments state that `./install` swaps the daemon while an older menu-bar app keeps running until relaunched, so a newly required key would throw and blank the whole Usage window during that window.
**Approved**: pending

**Decision**: `UsageHoursMetricDTO` has its own tolerant decoder even though its parent reads it with a present-or-nil call.
**Rationale**: The source comment explains that present-or-nil only catches an absent key; a missing key inside a nested type's synthesized decoder propagates straight through the outer tolerant decoder.
**Approved**: pending

**Decision**: The HUD payload is the new key `hud_quota`, not the old `hud`.
**Rationale**: The old `hud` had a different shape and an older app's synthesized decoder requires its retired keys; an absent key decodes to nil, which every shipped client already shows as a dash.
**Approved**: pending

**Decision**: `UsageAccountSectionDTO.isCurrent` is still encoded, always `false`, although no current client reads it.
**Rationale**: App builds up to 2.28.x have a synthesized decoder that requires the key; removing it blanked that app's Usage window during the daemon/app skew. The source says to keep emitting it until every shipped client tolerates its absence.
**Approved**: pending

**Decision**: Row kinds are told apart by shared label constants (`spend`, `fable quota`, `7d quota`, `5h quota`), and `resolvedWindowSeconds` falls back to the label when `windowSeconds` is absent.
**Rationale**: The label is the only marker on the wire for a spend or Fable row, and the only other window marker on a row from a daemon too old to send `windowSeconds`; one spelling shared by producer and consumer keeps the fallback working.
**Approved**: pending

**Decision**: Windows are ordered by `windowSeconds`, not by `resetsAt`.
**Rationale**: The 7d reset falls sooner than the 5h reset for most of every five-hour period, so an order built from reset instants swaps the columns under the reader; a window's width never changes.
**Approved**: pending

**Decision**: Utilization headers are always multiplied by 100.
**Rationale**: The header is a 0 to 1 fraction that exceeds 1 when over quota; the earlier "multiply only when at most 1" heuristic rendered 105% as 1.0%. `AccountQuotaTests.testReadingOverQuotaFractionIsNotTruncated` records the evidence.
**Approved**: pending

**Decision**: `oneSectionPerAccount` keeps the login over a setup token for one address.
**Rationale**: A usage display is a list of accounts, and the login is the credential Claude Code runs as, so its bucket is the one the next session draws down; an address with only a token keeps the token so it is not dropped from the display.
**Approved**: pending

**Decision**: `ClaudeCredentialDTO` carries the whole login, refresh token included, from the app to the daemon, and `probeOnly` is what the daemon keeps.
**Rationale**: The keychain items belong to the app because macOS shows the requesting process in the permission dialog and only a UI process can answer it; every judgment about the credential belongs to the daemon. Dropping the refresh token after the evaluation leaves the daemon holding only a short-lived bearer token.
**Approved**: pending

**Decision**: `credentialKind` is a raw String on sections, readings and credentials, not the enum.
**Rationale**: A kind this build has never heard of must degrade to one unlabeled section, not throw the whole payload away during version skew.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | passed | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |

separation-of-concerns passes: the file declares shapes, the tolerant decoders, one header parser, one de-duplication, the section `identity` and the two credential projections; queries, formatting, thresholds, probing and refresh live in the daemon. unit-test-coverage is partial: `AccountQuotaTests` and `AccountQuotaObserveTests` cover the header parser (vectors 001 to 007), `AccountQuotaTests` decodes a `UsageRowsDTO` without `accountSections` and a `RateLimitSnapshotDTO` without `accountEmail`, and asserts `identity` for an oauth and a long-lived section, but no test exercises the `UsageHoursRowDTO` and `UsageHoursMetricDTO` decoders, the spend-pair defaults, `oneSectionPerAccount`, `resolvedWindowSeconds`, `carrying(_:)` or `probeOnly`. graceful-degradation passes because every later-added key decodes to a default for an older peer. secure-storage is partial: the type keeps the refresh token out of what the daemon retains through `probeOnly`, but its synthesized encoder writes the token and refresh token in clear to any encoder it is handed, with no redacted form. input-sanitization is partial: reset headers are guarded against non-finite and out-of-range values, but utilization headers are not, which is the open question on `reading-pct-non-finite`. token-lifecycle passes for this layer: `carrying(_:)` swaps in a rotated login and clears the one-shot `refreshWithin`, and `probeOnly` drops the refresh token once an evaluation is done; refresh timing and revocation belong to the daemon's probe. data-minimization passes: `probeOnly` is the smallest credential that still probes, and the usage records carry display text rather than raw transcripts. no-hardcoded-strings is partial: display text comes pre-formatted from the daemon, but `"no usage readings in response"` and the row labels are English literals, and the labels double as wire markers.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
