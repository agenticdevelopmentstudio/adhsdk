
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
| daemon-health-report-015 | probe-request, probe-nil-on-failure, probe-default-timeout | A server that accepts the connection and sends no data for longer than 2 seconds | The closure returns `nil` after about 2 seconds of silence |
| daemon-health-report-016 | probe-nil-on-failure | No server listening at `baseURL` | The closure returns `nil` |
| daemon-health-report-017 | probe-nil-on-bad-url | `baseURL` set to a string `URL(string:)` rejects, such as the empty string | The closure returns `nil` and issues no request |
| daemon-health-report-018 | probe-url | `baseURL` `http://127.0.0.1:9000` | The request is a GET to `http://127.0.0.1:9000/health` |
| daemon-health-report-019 | probe-no-retry | Invoke the closure twice against a server that answers 500 | Two requests are made, one per invocation, and both return `nil` |
| daemon-health-report-020 | kind-open | Body with a strategy whose `kind` is `"custom"` | Decodes; `kind == "custom"` |
| daemon-health-report-021 | probe-request | A server that sends a valid 200 response body in small pieces, one piece every second, for longer than 2 seconds in total | The closure returns the complete body bytes; the idle timeout never fires |
| daemon-health-report-022 | probe-non-http-response | A probe over a transport whose response is not an `HTTPURLResponse` (for example a `file:` URL as `baseURL`) | The closure returns `nil` |
| daemon-health-report-023 | strategy-memberwise-default | `DaemonStrategyReport(name: "t", kind: "timing", workUnits: [])` | `children == []` |
| daemon-health-report-024 | children-recursive | A composite strategy with one child that itself has one child; a leaf strategy | The composite's `children` holds the child, whose `children` holds the grandchild; the leaf's `children` is empty |
| daemon-health-report-025 | status-opaque | A well-formed body whose `status` is `"degraded"` | Decodes; `status == "degraded"` |
| daemon-health-report-026 | decode-iso8601, decode-nil-on-mismatch | A well-formed body whose `nextActivation` is the number `1767225600` rather than an ISO-8601 string | `decode` returns `nil` for the whole report |
| daemon-health-report-027 | probe-url | `baseURL` `http://127.0.0.1:9000/` and, separately, `http://127.0.0.1:9000/api` | The requests are GETs to `http://127.0.0.1:9000/health` and `http://127.0.0.1:9000/api/health` |
