
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

