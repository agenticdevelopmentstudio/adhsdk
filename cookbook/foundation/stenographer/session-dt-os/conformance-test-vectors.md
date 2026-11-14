
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-dtos-001 | session-optional-keys | Decode a session body with only the twelve required keys | Succeeds; `projectRoot`, `termSessionId`, `transcriptTitle`, `lastOutput`, `lastEventType`, `summaryAt` and `turnStateAt` are `""` and `subagentWorking` is false |
| session-dtos-002 | session-required-keys | Decode a session body with `event_count` removed | Throws a key-not-found error for `event_count` |
| session-dtos-003 | session-required-keys | Decode a body missing `git_branch` | Throws; `git_branch` is required on `SessionDTO` |
| session-dtos-004 | dto-wire-spelling, session-encode-synthesized | Encode a session with the wire encoder | All twenty keys appear, snake_case, including empty strings and `subagent_working` false |
| session-dtos-005 | session-null-optional | Decode a body with `"project_root": null` | Succeeds with `projectRoot` equal to `""` |
| session-dtos-006 | session-init-defaults | Construct a session with only the twelve required arguments | Optional strings are `""` and `subagentWorking` is false |
| session-dtos-007 | event-decode-strict | Decode an event body without `git_branch` | Throws, although the initializer defaults it |
| session-dtos-008 | event-field-set, dto-wire-spelling | Encode then decode an event with the wire coders | Keys `id`, `session_id`, `event_type`, `timestamp`, `cwd`, `detail`, `git_branch`; fields round-trip |
| session-dtos-009 | detail-field-set | Decode `{"session": ..., "recent_events": []}` | `recentEvents` is empty and `session` decodes; a body without `recent_events` throws |
| session-dtos-010 | health-init-defaults | Construct `HealthDTO(status: "ok", uptime: 1, version: "test")` (as DaemonProviderPickerViewTests does) | Every optional field is nil |
| session-dtos-011 | health-mb-casing | Decode `{"status":"ok","uptime":5,"version":"1","memory_footprint_mb":812,"memory_peak_mb":900}` with the from-snake-case decoder | `memoryFootprintMb` is 812 and `memoryPeakMb` is 900 |
| session-dtos-012 | health-decode | Decode a health body with `version` removed | Throws; with `status_line_error` absent it decodes as nil when the three required keys are present |
| session-dtos-013 | health-liveness-only | Decode a body from the daemon's `/health` route | `activeSessionCount` and `totalEventCount` are nil |
| session-dtos-014 | dto-wire-spelling, session-last-event-type, session-subagent-working | Decode a session body with `last_event_type` `PreToolUse` and `subagent_working` true | `lastEventType` is `PreToolUse` and `subagentWorking` is true |

