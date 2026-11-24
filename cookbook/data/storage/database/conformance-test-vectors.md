
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sed-001 | token-filter | the display name `"Coffee Grinder"` | `"CoffeeGrinder"` |
| sed-002 | token-order | the display name `"Percolator"` | `"Percolator"` |
| sed-003 | token-filter | the display name `"Coffee/Grinder 2.0"` | `"CoffeeGrinder20"` |
| sed-004 | token-empty-fallback, fallback-token | an input of only spaces, and separately an empty string | `"AgenticDeveloperHubSDK"` in both cases |
| sed-005 | token-non-ascii | the display name `"Café"` | `"Café"` |
| sed-006 | directory-shape | home directory `/tmp/home`, token `"CoffeeGrinder"` | path `/tmp/home/.coffeegrinder` |
| sed-007 | directory-case-fold | tokens `"COFFEEgrinder"` and `"CoffeeGrinder"` under `/tmp/home` | identical paths |
| sed-008 | directory-no-io | the storage-directory operation for a home with no such dotfolder | a location is returned; the directory still does not exist afterward |
| sed-009 | display-name-fallback | no declared display name available | display name and token both resolve to `"AgenticDeveloperHubSDK"` |
| sed-010 | write-transaction, read-reader, file-backed-pool | a file-backed database configured with 2 readers; a write creates a table and inserts the value `42`; then a top-level read selects it back | `42` |
| sed-011 | read-your-writes, reentrant-inline | inside one write: create a table, insert the value `7`, then a nested read selects it back | the nested read returns `7` before the write commits |
| sed-012 | eviction-error, progress-interval | a table of 1500 rows; a read with a 200ms deadline runs a triple self-join count | raises the deadline-exceeded error for lane `"read"` in under 3 seconds |
| sed-013 | in-memory-queue | an in-memory database (`":memory:"`); a write creates a table and inserts the value `5`; then a read | `5` |
| sed-014 | completion-record, in-flight-accounting, stats-shape | one write then one read, both returning normally | the write lane's and read lane's completed counts are both greater than `0`; the read lane's evicted count is `0`; both lanes' in-flight counts are `0` |
| sed-015 | open-transaction-rollback, swallowed-eviction | a transaction-free write that begins a transaction, creates a table, then runs a runaway select whose interruption is caught inside the body | the call does not raise; a following write creating another table succeeds |
| sed-016 | eviction-record, percentile-window | running sed-012, then reading the metrics snapshot | the read lane's evicted count is `1`; the read lane's completed count and 50th-percentile duration are unchanged by the ejected call |
| sed-017 | non-positive-deadline | a read with a deadline of zero, on a statement that needs more than 1000 low-level execution steps | raises the deadline-exceeded error for lane `"read"`; no crash |
| sed-018 | nested-deadline-inherited, nested-eviction-error | a write with a 200ms deadline whose body runs a nested read with a 60-second deadline on the runaway join | raises the deadline-exceeded error for lane `"read"` with an elapsed value of `0`, about 200ms in; the write lane's evicted count increments by `1`, the read lane is unchanged |
| sed-019 | default-deadlines | a bounded database configured with a 100ms read deadline; a read with no explicit deadline on the runaway join | raises the deadline-exceeded error for lane `"read"` |
| sed-020 | is-reentrant | reading the reentrancy indicator outside any operation, then inside a write's body | `false`, then `true` |
| sed-021 | other-errors-unrecorded | a read whose body raises a custom error | the custom error propagates; the read lane's completed and evicted counts are unchanged; its in-flight count is `0` |
| sed-022 | percentile-empty | a freshly opened database, reading the metrics snapshot | both lanes report a completed count of `0` and both percentile durations of `0`; lane order is `["write", "read"]` |
| sed-023 | write-transaction | a write whose body inserts a row then raises | the error propagates; a later read does not see the row |
| sed-024 | router-unavailable | `GET /router/status`, `/router/report` and `/router/exchanges` on a table with no router | 503 each, `status` is `"unavailable"` (`AccountRouterRoutesTests.testNoRouterIs503NotAnEmptyAnswer`) |
| sed-025 | router-report | `GET /router/report` with no query | 200, `since_hours` is `24` (`testReportDefaultsToTwentyFourHours`) |
| sed-026 | router-report-window | `since_hours` of `abc`, `-1`, `1.5`, `+5`, `%20` | 400 each (`testAMalformedWindowIs400`) |
| sed-027 | router-report-window | `since_hours` of `99999999999999999999` and `Int.max` | 200, `since_hours` is `maxReportHours` (`testAHugeWindowIsClampedToACentury`) |
| sed-028 | router-exchanges | three exchanges; `?before_id=3&limit=1` | ids `[2]` (`testExchangesFilterByEveryParameter`) |
| sed-029 | router-exchanges-rule | `?rule=bogus` | 400 whose message names every `AccountRouterRuleFilter` value (`testAnUnknownRuleIs400ListingTheValidOnes`) |
| sed-030 | router-status | a saved account `oauth:a@x.com` whose token is `sk-ant-...` | 200, `saved_credentials` is `["oauth:a@x.com"]`, the body never contains `sk-ant` (`testStatusIsSnakeCaseAndNamesNoSecret`) |
| sed-031 | credential-relay, credential-relay-no-echo | one long-lived credential posted to an empty in-memory store | 200, `changed` is `true`, the store holds the token and saved once, the reply does not contain it (`testRelayStoresTheSetAndEchoesNoToken`) |
| sed-032 | set-credentials-change | the same body posted twice | the second reply has `changed: false`; `saves` stays `1` (`testRelayingTheSameSetAgainChangesNothing`) |
| sed-033 | credential-relay-no-echo | a truncated array carrying a token, an empty body, a JSON object | 400 each, no token or account in the reply, nothing saved (`testAnUndecodableBodyIs400AndEchoesNothing`) |
| sed-034 | follower-syncs-then-applies | a registry holding one project, then an insert, an update and a delete | the local file holds the first project after `start`, then each change (`testStartMirrorsTheProjectsAlreadyRegistered`, `testARegistryChangeReachesTheLocalFile`) |
| sed-035 | follower-keeps-local-path | a registry project at the kept path | the local file never holds it (`testTheKeptPathIsNeverMirrored`) |
| sed-036 | follower-stop | `stop()`, then an insert in the registry | the earlier rows stay; the insert never arrives (`testStopLeavesTheMirroredRowsAndFollowsNoFurther`) |
| sed-037 | heal-after-clean-drain, heal-keeps-record-failures | two records quarantined by a failed sink and one by invalid JSON, then the sink recovers and a heal runs | the two sink records are requeued and stored; the invalid one stays quarantined (`testHealRequeuesTransientQuarantineAndLeavesRecordFailures`) |
| sed-038 | heal-interval | a heal that requeued, then a second heal 1 minute later and a third after `quarantineHealInterval` | the second requeues nothing; the third requeues (`testHealRunsAtMostOncePerInterval`) |
| sed-039 | heal-interval | a heal over an empty quarantine, then a sink-failure quarantine and a heal 1 second later | the second heal requeues (`testAnEmptyHealDoesNotStartTheInterval`) |
| sed-040 | heal-after-clean-drain, heal-drains-promptly | a started worker whose sink fails until records are quarantined, then recovers | the quarantine empties and every record is stored with no manual retry (`testTheWorkerHealsAQuarantineOnItsOwn`) |
