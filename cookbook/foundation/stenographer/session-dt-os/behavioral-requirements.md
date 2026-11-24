
**Common**

- **dto-conformances**: `SessionDTO`, `SessionEventDTO`, `SessionDetailDTO` and `HealthDTO` MUST each be `Codable` and `Sendable` immutable value types; none declares `Equatable`, `Hashable` or `Identifiable`.
- **dto-wire-spelling**: The records MUST travel with snake_case keys through the shared wire encoder and decoder, so `sessionId` is `session_id`, `lastActivityAt` is `last_activity_at`, `recentEvents` is `recent_events` and so on.
- **dto-timestamps-opaque**: Every timestamp field MUST be carried as a String exactly as stored; no type here parses or compares it.

**SessionDTO**

- **session-field-set**: `SessionDTO` MUST carry these fields: `sessionId`, `cwd`, `model`, `startedAt`, `lastActivityAt`, `lastTool`, `status`, `gitBranch`, `summary`, `termProgram`, `projectRoot`, `termSessionId`, `transcriptTitle`, `lastOutput`, `lastEventType`, `summaryAt`, `turnStateAt` (all String), `pid` and `eventCount` (Int), and `subagentWorking` (Bool).
- **session-required-keys**: Decoding MUST fail when any of these twelve keys is missing: `session_id`, `cwd`, `model`, `started_at`, `last_activity_at`, `last_tool`, `status`, `git_branch`, `summary`, `pid`, `term_program`, `event_count`.
- **session-optional-keys**: Decoding MUST succeed when any of `project_root`, `term_session_id`, `transcript_title`, `last_output`, `last_event_type`, `summary_at`, `turn_state_at` is absent, defaulting each to the empty string, and MUST default an absent `subagent_working` to false.
- **session-init-defaults**: The public initializer MUST default `projectRoot`, `termSessionId`, `transcriptTitle`, `lastOutput`, `lastEventType`, `summaryAt` and `turnStateAt` to the empty string and `subagentWorking` to false, and MUST require the other twelve.
- **session-encode-synthesized**: Encoding MUST be the synthesized one: every field is written, including empty strings and false.
- **session-null-optional**: An optional key present with JSON `null` MUST decode as the default (the decoder uses a present-or-nil read followed by a default), not fail.
- **session-project-root**: `projectRoot` holds the top-level (non-submodule) git project root for `cwd`. The daemon fills it; it is empty until enrichment resolves it or when `cwd` is not in a git working tree.
- **session-term-session-id**: `termSessionId` MUST be the terminal's `TERM_SESSION_ID` (example in source: iTerm's `w0t1p0:UUID`) so the app can jump to the exact tab or pane; it is empty for terminals that do not set it.
- **session-transcript-title**: `transcriptTitle` MUST be the session's Claude Code title (the tab name or Claude's auto-title, from the transcript's `custom-title` and `ai-title` records), empty until the session is named. It MUST NOT carry the AI summary: the two live in separate fields.
- **session-last-output**: `lastOutput` holds the agent's most recent prose reply, which the daemon tails from the transcript when the Stop hook fires. It is empty for a session that has not answered.
- **session-last-event-type**: `lastEventType` MUST be the last hook event seen (examples: `PreToolUse`, `Notification`); the Sessions window reads it as working, idle or waiting on the user. It tracks the main agent's turn only.
- **session-summary-at**: `summaryAt` MUST be when `summary` was written in `datetime()` form, empty when never.
- **session-subagent-working**: `subagentWorking` MUST be a verdict, not a timestamp: true when a subagent of the session was doing something just now. The daemon owns the freshness window; a client MUST NOT re-derive it.
- **session-turn-state-at**: `turnStateAt` MUST be when `lastEventType` was recorded (the `turn_state_at` column, SQLite `datetime` form); it moves only when the turn state moves, unlike `lastActivityAt`, which ambient events also advance. It is empty from a daemon that predates the field.

**SessionEventDTO**

- **event-field-set**: `SessionEventDTO` MUST carry `id` (Int), and `sessionId`, `eventType`, `timestamp`, `cwd`, `detail`, `gitBranch` (String).
- **event-init-default**: The public initializer MUST default `gitBranch` to the empty string and require the other six.
- **event-decode-strict**: Decoding MUST fail when any of the seven keys is missing, including `git_branch`: the type has no tolerant decoder, so the initializer default does not apply on decode.

**SessionDetailDTO**

- **detail-field-set**: `SessionDetailDTO` MUST carry `session` (`SessionDTO`) and `recentEvents` (a list of `SessionEventDTO`), with wire keys `session` and `recent_events`, both required.
- **detail-ordering-owner**: The DTO MUST NOT impose an order or a count on `recentEvents`; the daemon decides how many and in what order.
- **detail-delivery**: The daemon returns a detail as the body of `GET /sessions/:id` and through the XPC `getSessionDetail`. The HTTP client's `session(id:includeCounts:)` returns `SessionDTO??`: for a 2xx reply whose body decodes as this type it returns `.some(detail.session)`; for a 404 it returns `.some(nil)` (the daemon answered and the session does not exist); for an unreachable daemon, a non-2xx reply other than 404, or a body that does not decode, it returns the outer `nil`. That client behavior belongs to the HTTP client spec and is described here for context.

**HealthDTO**

- **health-field-set**: `HealthDTO` MUST carry `status` (String), `uptime` (`TimeInterval`), `version` (String), `activeSessionCount`, `totalEventCount`, `startupDurationMs`, `memoryFootprintMb`, `memoryPeakMb` (all optional Int) and `statusLineError` (optional String).
- **health-status-values**: The daemon's `/health` route sets `status` to `ok` when its database is ready and to `migrating` when the schema is not current yet; it also fills `startupDurationMs`, the two memory figures and `statusLineError`, and leaves the two counts nil. This is daemon behavior; the DTO carries any String in `status`.
- **health-init-defaults**: The public initializer MUST require `status`, `uptime` and `version` and default every other field to nil.
- **health-decode**: Decoding MUST fail when `status`, `uptime` or `version` is missing, and MUST yield nil for any absent optional key (the synthesized decoder reads optionals with a present-or-nil read).
- **health-liveness-only**: `/health` is documented as a pure liveness probe that never touches the database; a consumer MUST treat `activeSessionCount` and `totalEventCount` as always nil from `/health`. They are retained for source compatibility, with `/insights/summary` as the DB-backed source of counts.
- **health-startup-duration**: `startupDurationMs` MUST be milliseconds from process start to HTTP-ready, nil until first startup completes.
- **health-memory-footprint**: `memoryFootprintMb` MUST be the daemon's `phys_footprint` in MB, nil if the kernel declined the reading.
- **health-memory-peak**: `memoryPeakMb` holds the highest footprint since the daemon process started; it never falls, and only a restart re-baselines it.
- **health-mb-casing**: The two memory properties MUST be spelled with a lowercase `b` (`Mb`), because clients decode with the from-snake-case strategy, which rebuilds `memory_footprint_mb` as `memoryFootprintMb`. An all-caps `MB` property would never match and, being optional, would decode to nil with no error. The wire keys are `memory_footprint_mb` and `memory_peak_mb`.
- **health-status-line-error**: `statusLineError` holds the status-line dispatcher's record of the renderer's last failure (why Claude Code's status line is missing Stenographer's part). The daemon reads it from a file, never the database; it is cleared on the next success and nil while the renderer works.

