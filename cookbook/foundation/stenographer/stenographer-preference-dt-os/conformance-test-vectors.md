
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stenographer-preference-dt-os-001 | omitted-means-unchanged, wire-spelling | Encode a `SummaryPreferenceRequest` with `enabled` false, `selectedConfigId` `abc` and `maxWords` 12. | Keys `enabled` (false), `selected_config_id` (`abc`) and `max_words` (12); `prompt` is absent (test: testSummaryRequestEncodesSnakeCaseAndOmitsNils). |
| stenographer-preference-dt-os-002 | summary-response-fields, wire-spelling | Decode a snake_case body with all keys, `enabled` true and `selected_config_id` empty. | A `SummaryPreferenceResponse` equal to one built with the same values, `selectedConfigId` `""` (test: testSummaryResponseDecodesSnakeCase). |
| stenographer-preference-dt-os-003 | older-daemon-tolerance | Decode a body without `enabled` and `selected_config_id`. | Decodes; `enabled` and `selectedConfigId` are nil; `maxWords` 8 and `timeoutSeconds` 60 (test: testSummaryResponseFromAnOlderDaemonDecodesWithoutEnabledOrSelection). |
| stenographer-preference-dt-os-004 | oversight-response-fields, response-equality | Encode and decode an `OversightPreferenceResponse` with `enabled` true, `contextThresholdPct` 80, `llmEnabled` false, `selectedConfigId` `claude-cli`, `model` empty. | The decoded value equals the original (test: testOversightRoundTrip). |
| stenographer-preference-dt-os-005 | other-fields-required | Decode a summary reply missing `max_words`. | Throws a `DecodingError` (derived from the source; no test). |
| stenographer-preference-dt-os-006 | oversight-request-fields, omitted-means-unchanged | Encode `OversightPreferenceRequest()` with no values set. | The empty object `{}` (derived from the source; no test). |
| stenographer-preference-dt-os-007 | oversight-request-fields, wire-spelling | Encode `OversightPreferenceRequest(enabled: true, contextThresholdPct: 75)`. | Keys `enabled` true and `context_threshold_pct` 75 only (derived from the source; no test). |
| stenographer-preference-dt-os-008 | other-fields-required | Decode an oversight reply missing `model`. | Throws a `DecodingError` (derived from the source; no test). |
| stenographer-preference-dt-os-009 | summary-request-fields | Build `SummaryPreferenceRequest()` and read each property. | All nine properties are nil (derived from the source; no test). |
| stenographer-preference-dt-os-010 | wire-spelling, older-daemon-tolerance | The HTTP client posts a summary request and the daemon replies with a snake_case body. | The client returns true only when the reply decodes (test: testSetSummaryPreferencesPostsSnakeCase in the HTTP client's tests). |

