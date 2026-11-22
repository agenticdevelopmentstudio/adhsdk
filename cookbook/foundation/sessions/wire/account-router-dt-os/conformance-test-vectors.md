
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

