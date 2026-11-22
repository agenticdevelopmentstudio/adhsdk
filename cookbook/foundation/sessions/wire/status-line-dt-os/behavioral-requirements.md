
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

