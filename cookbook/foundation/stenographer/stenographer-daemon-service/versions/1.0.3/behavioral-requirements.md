
**Protocol shape**

- **service-sendable**: `StenographerDaemonService` MUST be `Sendable`, so one instance can be shared by every window and called from any actor.
- **service-async**: Every operation except `onReconnect` MUST be `async`; only `summarize` is `throws`.
- **service-seam**: Windows MUST depend on the protocol, not on the HTTP client, so a stub can replace it in tests.

**Unreachable-daemon contract**

- **reads-nil-when-unreachable**: Each read MUST answer nil when the daemon cannot be reached, so callers keep what is on screen.
- **writes-false-or-nil-when-unreachable**: Each write MUST answer `false` (for Bool returns) or nil (for value returns) in the same case.
- **session-doubly-optional**: `session(id:includeCounts:)` MUST answer `SessionDTO??`: the outer nil means the daemon is unreachable and the inner nil means there is no such session.

**Operations**

- **op-health**: `health()` MUST answer `HealthDTO?`.
- **op-sessions**: `sessions(status:project:sinceHours:includeCounts:)` MUST answer `[SessionDTO]?`, taking an optional status, an optional project, an Int `sinceHours` and a Bool `includeCounts`.
- **op-session**: `session(id:includeCounts:)` MUST answer one session by id.
- **op-summarize**: `summarize(sessionId:)` MUST be `async throws`, return nothing on success, throw `SummarizeDaemonFailure` carrying the daemon's reason when the daemon declines, and throw any other error for a transport failure.
- **op-conversations**: `conversations(limit:includeWorkOutput:before:sessionId:)` MUST answer `[ConversationEntryDTO]?`, taking an Int `limit`, a Bool `includeWorkOutput`, an optional `before` cursor and an optional session id.
- **op-oversight-findings**: `oversightFindings(status:)` MUST answer `[OversightFindingDTO]?` with an optional status filter.
- **op-oversight-action-target**: `oversightActionTarget(findingId:)` MUST answer `OversightActionTargetDTO?`.
- **op-act-on-finding**: `actOnOversightFinding(findingId:)` MUST answer `OversightActResultDTO?`.
- **op-oversight-scripts**: `oversightScripts()` MUST answer `[OversightScript]?`.
- **op-save-script**: `saveOversightScript(_:)` MUST answer the saved `OversightScript?`.
- **op-delete-script**: `deleteOversightScript(id:)` MUST answer a Bool, true when the daemon took the delete.
- **op-reset-script**: `resetOversightScript(id:)` MUST answer the reset `OversightScript?`.
- **op-ai-interactions**: `aiInteractions(limit:)` MUST answer `[AIInteractionDTO]?`.
- **op-ai-interaction**: `aiInteraction(id:)` MUST answer one `AIInteractionDTO?` by Int id.
- **op-provider-configs**: `aiProviderConfigs()` MUST answer `[DaemonProviderConfig]?`, the daemon's saved LLM provider configurations (what Stenographer's LLM Providers pane pushed), for the pickers in the preference panes.
- **op-summary-preferences-read**: `summaryPreferences()` MUST answer `SummaryPreferenceResponse?`.
- **op-oversight-preferences-read**: `oversightPreferences()` MUST answer `OversightPreferenceResponse?`.
- **op-summary-preferences-write**: `setSummaryPreferences(_:)` MUST answer a Bool for a `SummaryPreferenceRequest`.
- **op-oversight-preferences-write**: `setOversightPreferences(_:)` MUST answer a Bool for an `OversightPreferenceRequest`.
- **op-set-ai-preferences**: `setAIPreferences(_:)` MUST replace the daemon's LLM provider registry with the given `AIProviderConfigSync` (the whole set plus the active selection) and answer true when the daemon took it.
- **since-hours-nonpositive-omitted**: A `sinceHours` of 0 or less MUST send no `since_hours` query item (no age filter); only a positive value is sent.
- **op-on-reconnect**: `onReconnect(_:)` MUST register a `@Sendable` handler that fires when the daemon is seen to have restarted, so a preference push can re-send its snapshot. It is synchronous and not `async`.

**Default-argument overloads (protocol extension)**

- **default-sessions**: `sessions(status:sinceHours:includeCounts:)` MUST default `status` to nil, `sinceHours` to 0 and `includeCounts` to true, pass `project` as nil, and call the full operation.
- **default-session**: `session(id:)` MUST call `session(id:includeCounts:)` with `includeCounts` true.
- **default-findings**: `oversightFindings()` MUST call `oversightFindings(status:)` with nil.
- **default-ai-interactions**: `aiInteractions()` MUST call `aiInteractions(limit:)` with 200.
- **default-conversations**: `conversations(limit:includeWorkOutput:sessionId:)` MUST default `limit` to 200, `includeWorkOutput` to false and `sessionId` to nil, and call the full operation with `before` nil.

**SummarizeDaemonFailure**

- **failure-shape**: `SummarizeDaemonFailure` MUST be a `LocalizedError`, `Equatable` and `Sendable` struct with one `reason` String and a public initializer `init(reason:)`.
- **failure-description**: Its `errorDescription` MUST be the `reason` string.
- **failure-distinct**: It MUST be distinct from a transport failure so the list can show the daemon's reason.

**DaemonProviderConfig**

- **config-shape**: `DaemonProviderConfig` MUST be a `Codable`, `Sendable`, `Equatable` and `Identifiable` struct with `id` (UUID), `name`, `pluginIdentifier` and `templateId` (String), and a public initializer taking all four.
- **config-no-secrets**: `DaemonProviderConfig` MUST NOT carry secrets or a model; those are the daemon's own.
- **config-wire-keys**: Through the stenographer wire spelling `DaemonProviderConfig` MUST use the keys `id`, `name`, `plugin_identifier` and `template_id`; the type is one row of `GET /preferences/ai/configs`.

**Production implementation notes (StenographerHTTPClient)**

- **impl-wire-spelling**: The HTTP implementation MUST send and read JSON in the shared wire spelling (snake_case keys, ISO-8601 dates) over the daemon's loopback API, with the base URL taken from the `STENOGRAPHER_URL` environment variable when it is a valid URL and the stenographer HTTP base URL constant otherwise.
- **impl-unreachable-mapping**: A failed connection, a non-2xx reply or a body that does not decode MUST all read as unreachable (nil or false); the one exception is a 404 on a single session, which answers inner nil (no such session).
- **impl-summarize-errors**: `summarize` MUST throw a URL error `cannotConnectToHost` when no reply arrives, which includes the 605-second timeout expiring (the transport's own timeout error is discarded, so a timeout reads exactly like an unreachable daemon), and `SummarizeDaemonFailure` with the daemon's `error` message, or `HTTP <status>` when the body has none, on a non-2xx reply.
- **impl-act-result**: `actOnOversightFinding` MUST answer a succeeded result with status from the decoded finding, or `acted` when the body does not decode, on a 2xx reply, and a failed result carrying the daemon's error message or `HTTP <status>` otherwise.
- **impl-ai-prefs-camelcase**: `setAIPreferences` MUST be sent with a plain encoder (camelCase keys), not the wire encoder, because the daemon's `POST /preferences/ai` decodes the registry with a default decoder. This is the one write that differs from the others' snake_case body.
- **impl-timeouts**: Request timeouts MUST be 605 seconds for a POST ending in `/summarize` (a summary runs inline on the daemon for up to the user's largest give-up time of 600 seconds, plus 5), 15 seconds for GET `/conversations` and the AI interaction reads, and 10 seconds for everything else.
- **reconnect-strictly-lower**: A reconnect MUST fire only when a `/health` poll reports an `uptime` strictly lower than the previous successful poll's; an equal or higher uptime, the first successful poll and a failed poll fire nothing.
- **poll-starts-once**: The health polling task MUST start on the first `onReconnect` registration only; later registrations add handlers without starting another task.
- **encoders-not-unified**: `setSummaryPreferences` and `setOversightPreferences` MUST use the snake_case wire encoder and `setAIPreferences` MUST use a plain (camelCase) encoder; an implementation MUST NOT unify them.
- **impl-reconnect-poll**: The reconnect signal MUST come from polling `/health` (every 30 seconds by default) and treating an `uptime` that went down as a restart, firing every registered handler once; the daemon has no push channel to a client that is not an XPC subscriber.
- **impl-no-retry**: The implementation MUST NOT retry, back off, send an authentication header or offer cancellation beyond the polling task's own, and MUST send each request once.

