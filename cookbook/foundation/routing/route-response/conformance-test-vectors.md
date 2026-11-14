
Tests named below are in the `RouteResponse` suite (`RouteResponseTests`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| route-response-001 | json-body, json-snake-case-keys, json-iso-dates, json-format-is-pretty-sorted | `json(Sample(fooBar: 1, at: 2026-01-31T00:00:00Z))` | Body is the text `{\n  "at" : "2026-01-31T00:00:00Z",\n  "foo_bar" : 1\n}`; `status` 200; `contentType` `application/json` (test: jsonUsesSnakeCaseIsoDatesPrettyPrintingAndSortedKeys). |
| route-response-002 | json-body | `json(sample, status: 201)` | `status` is 201 (test: jsonCarriesTheRequestedStatus). |
| route-response-003 | json-encode-failure-is-empty-object | `json(value)` where the value's `encode(to:)` throws. | Body is the text `{}` (test: aValueThatFailsToEncodeYieldsAnEmptyObject). |
| route-response-004 | error-body, error-body-is-valid-json, error-status | `error("a \"quoted\" msg\nwith a newline and a \\ backslash", status: 400)` | `status` 400; the body parses as JSON and `error` equals the exact message (test: errorBodyIsValidJSONThatDecodesBackToTheMessage). |
| route-response-005 | not-found | `notFound()` | `status` 404; the body decodes to `error` equal to `Not found` (test: notFoundIs404, which checks only that the body text contains `Not found`; the decoded check is stricter, like vector 007). |
| route-response-006 | no-content, no-content-content-type | `noContent` | `status` 204; body is empty; `contentType` is `application/json` (test: noContentIs204WithAnEmptyBody). |
| route-response-007 | not-found | `notFound("gone")` | `status` 404; the body decodes to `error` equal to `gone` (derived from the builder; no test beside the source covers a custom message). |
| route-response-008 | init-defaults | `RouteResponse(status: 200, body: Data())` | `contentType` is `application/json`; `headers` is empty (derived from the initializer defaults; no test beside the source). |
| route-response-009 | encoder-fresh-per-call | Two calls to `makeJSONEncoder()`. | Two distinct instances, each with the wire format (derived from the declaration; no test beside the source). |
| route-response-010 | status-unchecked | `RouteResponse(status: 999, body: Data()).status` | 999 (derived: `init` stores the argument without a check; no test beside the source). |
| route-response-011 | json-format-is-pretty-sorted | `json(Path(path: "a/b"))` for a struct with one `String` property `path`. | Body is the text `{\n  "path" : "a\/b"\n}`, with the slash escaped (derived from `JSONEncoder` defaults; no test beside the source). |
| route-response-012 | builders-empty-headers | `json(sample)`, `error("x", status: 400)`, `notFound()` and `noContent`. | `headers` is empty for each (derived from the initializer default; no test beside the source). |

