
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| daemon-health-report-001 | decode-iso8601, children-optional-on-wire, workunit-optional-keys, report-fields | Test `decodesWireFormat`: body `{"status":"ok","version":"2.1.0","uptimeSeconds":90,"strategy":{"name":"root","kind":"composite","workUnits":[],"children":[{"name":"jobs","kind":"timing","workUnits":[{"name":"sync","state":"idle","nextActivation":"2026-01-01T00:00:00Z","consecutiveFailures":2,"isBlocklisted":false}]}]}}` passed to `decode` | A non-nil report; `version` is `"2.1.0"`; `first(ofKind: "timing")` finds `jobs`, whose `children` is empty, whose first work unit has `state == .idle`, `consecutiveFailures == 2` and a non-nil `nextActivation` |
| daemon-health-report-002 | decode-nil-on-mismatch, strategy-required-keys | Test `otherSchemaIsNil`: body `{"status":"ok"}` passed to `decode` | `nil` |
| daemon-health-report-003 | decode-nil-on-mismatch, decode-no-error-detail | Bytes that are not JSON (for example `not json`) passed to `decode` | `nil`, with no error raised |
| daemon-health-report-004 | unknown-state-fails | A well-formed body whose one work unit has `"state":"paused"` | `decode` returns `nil` for the whole report |
| daemon-health-report-005 | workunit-required-keys | A well-formed body whose work unit omits `consecutiveFailures` | `decode` returns `nil` |
| daemon-health-report-006 | workunit-optional-keys | A work unit with only `name`, `state`, `consecutiveFailures` and `isBlocklisted` | Decodes; `nextActivation` and `lastMessage` are `nil` |
| daemon-health-report-007 | children-optional-on-wire | A strategy object with `name`, `kind` and `workUnits` and no `children` key | Decodes with `children == []` |
| daemon-health-report-008 | first-of-kind-self | `DaemonStrategyReport(name: "t", kind: "timing", workUnits: [])` and `first(ofKind: "timing")` | Returns the receiver |
| daemon-health-report-009 | first-of-kind-depth-first | A composite with children `a` (kind `timing`, containing a child `a1` of kind `event`) then `b` (kind `event`); `first(ofKind: "event")` | Returns `a1`, not `b` |
| daemon-health-report-010 | first-of-kind-none | A leaf strategy of kind `timing`; `first(ofKind: "composite")` | `nil` |
| daemon-health-report-011 | workunit-memberwise-defaults | `DaemonWorkUnitReport(name: "x", state: .running)` | `nextActivation == nil`, `consecutiveFailures == 0`, `isBlocklisted == false`, `lastMessage == nil` |
| daemon-health-report-012 | kind-constants | Read the three static constants | `"timing"`, `"event"` and `"composite"` |
| daemon-health-report-013 | probe-200-only, probe-body-raw | A server answering `GET /health` with status 200 and a JSON body | The closure returns the exact body bytes |
| daemon-health-report-014 | probe-nil-on-failure | A server answering `GET /health` with status 503 | The closure returns `nil` |
| daemon-health-report-015 | probe-nil-on-failure, probe-default-timeout | A server that accepts the connection and sends nothing for longer than 2 seconds | The closure returns `nil` after about 2 seconds |
| daemon-health-report-016 | probe-nil-on-failure | No server listening at `baseURL` | The closure returns `nil` |
| daemon-health-report-017 | probe-nil-on-bad-url | `baseURL` set to a string `URL(string:)` rejects, such as the empty string | The closure returns `nil` and issues no request |
| daemon-health-report-018 | probe-url | `baseURL` `http://127.0.0.1:9000` | The request is a GET to `http://127.0.0.1:9000/health` |
| daemon-health-report-019 | probe-ephemeral-session, probe-no-retry | Invoke the closure twice against a server that answers 500 | Two requests are made, one per invocation, and both return `nil` |
| daemon-health-report-020 | kind-open | Body with a strategy whose `kind` is `"custom"` | Decodes; `kind == "custom"` |

