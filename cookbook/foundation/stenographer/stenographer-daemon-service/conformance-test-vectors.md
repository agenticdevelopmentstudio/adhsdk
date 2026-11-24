
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| daemon-service-001 | reads-nil-when-unreachable, impl-unreachable-mapping | Stub transport with no daemon (StenographerHTTPClientTests `testUnreachableDaemonReturnsNil`) | `sessions` and `oversightFindings` answer nil and `setSummaryPreferences` answers false (`health()` takes the same path) |
| daemon-service-002 | op-sessions, since-hours-nonpositive-omitted | Call `sessions(status: "active")` (StenographerHTTPClientTests `testSessionsBuildsQueryAndDecodes`) | The request carries `status=active`; the body decodes into `[SessionDTO]` |
| daemon-service-003 | session-doubly-optional, impl-unreachable-mapping | The daemon answers 404 for `GET /sessions/<id>` (`testSessionNotFoundIsInnerNil`) | `session(id:)` answers the inner nil (not found), not the outer nil |
| daemon-service-004 | session-doubly-optional | No daemon reachable (no test of its own) | `session(id:)` answers the outer nil |
| daemon-service-005 | op-summarize, failure-distinct | The daemon answers 500 with `{"error": "Summarize failed: model too large"}` (`testSummarizeThrowsDaemonReason`) | `summarize` throws `SummarizeDaemonFailure` whose `reason` is `Summarize failed: model too large`, and its `errorDescription` is that text |
| daemon-service-006 | op-summarize, impl-summarize-errors | No reply from the daemon (no test of its own) | `summarize` throws a URL error with code `cannotConnectToHost` |
| daemon-service-007 | op-act-on-finding, impl-act-result | The daemon answers 409 to the act route (`testActOnFindingMapsConflictToFailure`) | A result with `succeeded` false and the daemon's error text as `reason` |
| daemon-service-008 | impl-act-result | The daemon answers 200 with a finding body whose status is `acted` (`testActOnFindingSuccess`) | `succeeded` true and `status` `acted` |
| daemon-service-009 | op-delete-script | The daemon answers 204 to the delete route (`testDeleteScriptIs204`) | `deleteOversightScript(id:)` answers true |
| daemon-service-010 | op-summary-preferences-write, impl-wire-spelling, encoders-not-unified | `setSummaryPreferences` with a request (`testSetSummaryPreferencesPostsSnakeCase`) | The posted body has snake_case keys |
| daemon-service-011 | op-set-ai-preferences, impl-ai-prefs-camelcase, encoders-not-unified | `setAIPreferences` with a config set (`testSetAIPreferencesPostsTheRegistryAsCamelCase`) | The posted body has camelCase keys and the call answers true on a 2xx |
| daemon-service-012 | writes-false-or-nil-when-unreachable | `setAIPreferences` against an error status and against no daemon (`testSetAIPreferencesIsFalseOnAnErrorStatusOrNoDaemon`) | Both answer false |
| daemon-service-013 | op-on-reconnect, impl-reconnect-poll, reconnect-strictly-lower, poll-starts-once | Health polls report uptimes 500, 600, 3, 10 (`testReconnectFiresWhenUptimeDrops`) | The registered handler fires when the uptime falls from 600 to 3 |
| daemon-service-014 | default-conversations, default-ai-interactions | Call `conversations()` and `aiInteractions()` (no test of its own) | They call the full operations with limit 200, includeWorkOutput false, before nil, sessionId nil, and limit 200 |
| daemon-service-015 | impl-timeouts | Timeout for POST `/sessions/x/summarize`, GET `/conversations`, GET `/ai/interactions/3`, GET `/health` (no test of its own) | 605, 15, 15 and 10 seconds |
| daemon-service-016 | config-wire-keys | (no test of its own) Decode `{"id":"<uuid>","name":"n","plugin_identifier":"p","template_id":"t"}` with the wire decoder | A `DaemonProviderConfig` with those four values |
| daemon-service-017 | impl-summarize-errors | The summarize request exceeds its 605-second timeout so the transport throws (no test of its own) | `summarize` throws a URL error with code `cannotConnectToHost`, the same as for no reply |
| daemon-service-018 | impl-act-result | The daemon answers 200 to the act route with a body that does not decode as a finding (no test of its own) | `succeeded` true and `status` `acted` from the fallback |
| daemon-service-019 | default-sessions | Call `sessions()` with no arguments (no test of its own) | The full operation runs with status nil, project nil, sinceHours 0 and includeCounts true |
| daemon-service-020 | since-hours-nonpositive-omitted | Call `sessions` with `sinceHours` 0 and then 6 | The first request has no `since_hours` item; the second carries `since_hours=6` |
