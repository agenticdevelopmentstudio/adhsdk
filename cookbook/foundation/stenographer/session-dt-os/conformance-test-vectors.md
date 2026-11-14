
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-dtos-001 | session-optional-keys | Decode a session body with only the twelve required keys | Succeeds; `projectRoot`, `termSessionId`, `transcriptTitle`, `lastOutput`, `lastEventType`, `summaryAt` and `turnStateAt` are `""` and `subagentWorking` is false |
| session-dtos-002 | session-required-keys | Decode a session body with `event_count` removed, then another with `git_branch` removed | Each throws a key-not-found error for the removed key; both are required on `SessionDTO` |
| session-dtos-004 | dto-wire-spelling, session-encode-synthesized | Encode a session with the wire encoder | All twenty keys appear, snake_case, including empty strings and `subagent_working` false |
| session-dtos-005 | session-null-optional | Decode a body with `"project_root": null` | Succeeds with `projectRoot` equal to `""` |
| session-dtos-006 | session-init-defaults | Construct a session with only the twelve required arguments | Optional strings are `""` and `subagentWorking` is false |
| session-dtos-007 | event-decode-strict | Decode an event body without `git_branch` | Throws, although the initializer defaults it |
| session-dtos-008 | event-field-set, dto-wire-spelling | Encode then decode an event with the wire coders | Keys `id`, `session_id`, `event_type`, `timestamp`, `cwd`, `detail`, `git_branch`; fields round-trip |
| session-dtos-009 | detail-field-set | Decode `{"session": ..., "recent_events": []}` | `recentEvents` is empty and `session` decodes; a body without `recent_events` throws |
| session-dtos-010 | health-init-defaults | Construct `HealthDTO(status: "ok", uptime: 1, version: "test")` (as DaemonProviderPickerViewTests does) | Every optional field is nil |
| session-dtos-011 | health-mb-casing | Decode `{"status":"ok","uptime":5,"version":"1","memory_footprint_mb":812,"memory_peak_mb":900}` with the from-snake-case decoder | `memoryFootprintMb` is 812 and `memoryPeakMb` is 900 |
| session-dtos-012 | health-decode | Decode a health body with `version` removed | Throws a key-not-found error for `version` |
| session-dtos-014 | dto-wire-spelling, session-last-event-type, session-subagent-working | Decode a session body with `last_event_type` `PreToolUse` and `subagent_working` true | `lastEventType` is `PreToolUse` and `subagentWorking` is true |
| session-dtos-015 | health-decode | Decode a health body with `status`, `uptime` and `version` present and `status_line_error` absent | Succeeds and `statusLineError` is nil |
| session-dtos-016 | dto-conformances | Pass a `SessionDTO`, `SessionEventDTO`, `SessionDetailDTO` and `HealthDTO` to a generic function constrained to `Codable & Sendable` | Compiles; no type needs `Equatable`, `Hashable` or `Identifiable` |
| session-dtos-017 | dto-timestamps-opaque | Decode a session body with `started_at` `2026-11-14 09:30:00` | `startedAt` is that exact string; no date parsing occurs |
| session-dtos-018 | session-field-set | Construct a session passing all twenty fields | Each field reads back as given |
| session-dtos-019 | event-init-default | Construct an event with the six required arguments and no `gitBranch` | `gitBranch` is `""` |
| session-dtos-020 | health-field-set | Construct a health value passing all nine fields | Each field reads back as given |
| session-dtos-021 | detail-ordering-owner | Decode a detail body whose `recent_events` holds events with ids 3, 1, 2 | `recentEvents` holds ids 3, 1, 2 in that order; the type neither sorts nor truncates |
