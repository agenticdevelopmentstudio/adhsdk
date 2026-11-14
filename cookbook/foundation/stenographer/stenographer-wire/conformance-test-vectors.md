
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stenographer-wire-001 | encoder-factory, nil-omitted | Encode a `SummaryPreferenceRequest` with `enabled` false, `selectedConfigId` `abc`, `maxWords` 12 and nothing else. | Keys `enabled`, `selected_config_id` and `max_words` are present with those values; `prompt` is absent (test: testSummaryRequestEncodesSnakeCaseAndOmitsNils). |
| stenographer-wire-002 | decoder-factory | Decode a snake_case summary preference reply. | `SummaryPreferenceResponse` with `maxWords` 8, `activityLines` 60 and the other fields from the body (test: testSummaryResponseDecodesSnakeCase). |
| stenographer-wire-003 | round-trip | Encode then decode an `OversightPreferenceResponse`. | The decoded value equals the original (test: testOversightRoundTrip). |
| stenographer-wire-004 | decoder-factory | Decode a `SessionDTO` from daemon JSON with `session_id` `s1`, `event_count` 3 and `started_at` `2026-10-12T00:00:00Z`. | `sessionId` `s1` and `eventCount` 3; `SessionDTO.startedAt` is a `String`, so the timestamp is carried as text and the date strategy is not exercised (test: testSessionDTOStillDecodesFromDaemonJSON). |
| stenographer-wire-005 | fresh-instance | Call `encoder()` twice. | Two different instances (unverified: derived from the source; no test). |
| stenographer-wire-006 | encoder-factory | Encode a struct with a `Date` of 2026-10-12 00:00:00 UTC. | The field is the string `2026-10-12T00:00:00Z` (unverified: derived from the strategy; no test). |
| stenographer-wire-007 | decoder-factory | Decode a date written with fractional seconds, `2026-10-12T00:00:00.123Z`. | Decoding throws a `DecodingError`, because Foundation's `iso8601` strategy accepts only whole seconds (unverified: derived from the strategy; no test). |
| stenographer-wire-008 | no-validation | Decode `{}` as `SummaryPreferenceResponse` with `decoder()`. | Throws a `DecodingError` for the missing keys (unverified: derived from the source; no test). |

