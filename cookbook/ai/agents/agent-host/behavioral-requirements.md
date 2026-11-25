
### Identity and isolation

- **host-is-actor**: `AgentHost` MUST be an actor, so every operation on its agents, sessions, running turns and event streams is serialised on the actor.
- **tools-exposed**: The host MUST expose the tools it was constructed with as the immutable, non-isolated array `tools`, in construction order.
- **agent-caller-constant**: `AgentHost.agentCaller` MUST equal `"agent"`; it is the caller name a tool sees when an agent's turn runs it.

### Errors

- **host-error-cases**: A refused request MUST throw an `AgentHostError` with one of the cases `agentNotFound(String)`, `agentDisabled(String)`, `sessionNotFound(UUID)`, `turnInProgress(UUID)` or `invalidAgent(String)`; the type MUST be `Equatable`.
- **host-error-descriptions**: `AgentHostError.errorDescription` MUST be `No agent with id '<id>'` for `agentNotFound`, `The agent '<id>' is disabled` for `agentDisabled`, `No session with id <UUID string>` for `sessionNotFound`, `Session <UUID string> already has a turn running` for `turnInProgress`, and the carried reason itself for `invalidAgent`.

### Construction

- **init-migrates-store**: The initializer MUST create the host's three tables (`agent_definitions`, `agent_sessions`, `agent_messages`) on the given database by running a migrator whose identifiers all start `agents-` (`agents-v1`), so it can sit beside the owner's own migrator.
- **init-inserts-defaults**: The initializer MUST insert each `defaults` definition whose `id` is absent and MUST NOT overwrite a stored definition with the same `id`, so a user's edit to a default survives the next launch.
- **init-throws**: The initializer MUST throw when migration or the default insert fails, and the host is then not created.
- **max-tool-rounds-default**: `maxToolRounds` MUST default to 16 and `runtime` MUST default to `DaemonAIChat.PluginRuntime.live`.

### Agents

- **agents-listing**: `agents()` MUST return every stored definition ordered by `id`.
- **agent-lookup**: `agent(_:)` MUST return the stored definition for an id, or nil when none is stored.
- **save-requires-id**: `save(_:)` MUST throw `invalidAgent("An agent needs an id")` when the agent's `id` is empty after trimming `.whitespacesAndNewlines` characters.
- **save-requires-name**: `save(_:)` MUST throw `invalidAgent("An agent needs a name")` when the agent's `name` is empty after trimming `.whitespacesAndNewlines` characters.
- **save-upserts**: `save(_:)` MUST insert the definition, or replace the stored one with the same `id`, and record its update time.
- **save-validates-nothing-else**: `save(_:)` MUST NOT validate any field other than `id` and `name`; `prompt`, `model`, `deadlineSeconds` and the rest are stored as given.

### Sessions

- **create-session-requires-agent**: `createSession(agentId:title:)` MUST throw `agentNotFound(agentId)` when no definition has that id.
- **create-session-fields**: `createSession` MUST return an `AgentSessionInfo` with a new random UUID, the given `agentId`, the given `title` (nil allowed) and equal `createdAt` and `updatedAt`.
- **create-session-ignores-enabled**: `createSession` MUST NOT check `enabled`; a disabled agent can have a session, and `send` is where a disabled agent is refused.
- **sessions-listing**: `sessions(agentId:)` MUST return the sessions most recently updated first, only those of `agentId` when it is non-nil and every agent's when it is nil.
- **session-detail**: `session(_:)` MUST return nil when the session does not exist, otherwise an `AgentSessionDetail` of its `AgentSessionInfo` and every stored `AgentMessage`, oldest first.
- **delete-session-effects**: `deleteSession(_:)` MUST cancel the session's running turn and finish its `send` stream, delete the session's messages and then the session row, finish every live tail on the session, and discard the session's event counter. Deleting a session that does not exist is not an error.
- **delete-session-running-turn**: A turn running when its session is deleted MUST be cancelled, its `send` stream MUST be finished at once with no final event, and the cancelled turn MUST emit no further event and store no further message (a tool mid-run when the session is deleted has its result dropped), so the session's event counter is not recreated.

### Turns: starting

- **send-refusal-order**: `send(_:to:)` MUST check, in this order, that the session exists (`sessionNotFound`), that its agent exists (`agentNotFound` with the session's `agentId`), that the agent is `enabled` (`agentDisabled`) and that the session has no running turn (`turnInProgress`), throwing the first failure.
- **send-refusal-stores-nothing**: A refused `send` MUST NOT store a message or start a turn.
- **send-stores-user-message**: `send` MUST append `text` verbatim as a `user` message before the turn starts; empty text is stored like any other.
- **send-turn-stream**: `send` MUST return an `AsyncStream<AgentEnvelope>` carrying this turn's events, and the stream MUST end after the turn's `turn_finished` or `turn_failed`.
- **send-stream-detach**: Ending the returned stream early (the consumer stops iterating) MUST NOT stop the turn; only `interrupt` stops it.
- **one-turn-per-session**: A session MUST run at most one turn at a time; turns of different sessions MAY run concurrently, interleaving at their suspension points on the actor.
- **turn-agent-snapshot**: A turn MUST run with the agent definition read when `send` was called; a `save` during the turn does not change the running turn.

### Turns: events and streams

- **events-tail**: `events(_:)` MUST return a stream of every event on the session from the moment of the call, across turns, including the activity events of direct tool runs, until the session is deleted or the consumer stops listening.
- **events-tail-no-replay**: `events(_:)` MUST NOT replay events emitted before the call.
- **events-tail-unchecked-session**: `events(_:)` MUST accept a session id it has no record of and MUST NOT throw; it simply never receives events until something emits on that id.
- **events-tail-removal**: When a tail's consumer stops listening, the host MUST remove that tail, and MUST drop the session's tail table when no tail remains.
- **envelope-numbering**: Every emitted event MUST be wrapped in an `AgentEnvelope` carrying the session id and a `seq` that starts at 0 and increases by one per event across the session's turns, and the per-turn stream and every tail MUST receive the same envelope for an event.
- **envelope-seq-memory-only**: The `seq` counter MUST be held in memory only; it starts again at 0 for a session after the host is recreated, and it is distinct from the stored `AgentMessage.seq`. The envelope carries no host-instance epoch, so a client MUST treat a `seq` that goes back to 0 after its connection to the host drops or the host restarts as a new numbering and MUST reset its gap and repeat tracking on every reconnect.

### Turns: interrupting

- **interrupt-cancels-turn**: `interrupt(_:)` MUST cancel the session's running turn.
- **interrupt-idle-noop**: `interrupt(_:)` on a session with no running turn MUST do nothing and MUST NOT throw; it is synchronous and does not wait for the turn to end.
- **interrupt-stop-reason**: A turn ended by `interrupt` MUST end with `turn_finished` whose stop reason is `"interrupted"`, not with `turn_failed`.
- **interrupt-drops-round-text**: A round cancelled before its stream ends MUST NOT store the assistant text it had accumulated; the `text_delta` events already emitted are not retracted.
- **interrupt-then-send**: A new `send` MUST succeed once the interrupted turn has ended, and MUST throw `turnInProgress` while it has not.

### Turns: the model loop

- **model-resolution**: A turn MUST resolve the agent's `ModelSelector` through the model registry; a selector that resolves to an enabled entry runs that entry's plugin and model.
- **model-role-fallback**: When the selector is a `role` that no enabled entry holds, the turn MUST fall back to the first enabled entry in the registry's list order, with no model override.
- **model-config-no-fallback**: A `config` selector that does not resolve (absent or disabled entry) MUST NOT fall back to another entry.
- **model-none-available**: When no model resolves, the turn MUST end with `turn_failed("No model is available: add and enable one in the model registry")` without starting a model round.
- **plugin-load-per-turn**: A turn MUST load the entry's plugin once through `runtime.load(pluginIdentifier, searchPaths)`, and MUST end with `turn_failed` carrying the error's description when loading throws.
- **context-contents**: Each round MUST build an `AIChatContext` from the session's stored messages (those whose role this build knows, oldest first), the resolved model name, the system prompt, the max tokens, the tool specs, the agent's `thinkingBudgetTokens` and the resolved plugin config.
- **context-tools**: The tool specs MUST list every host tool in order as its `name`, `description` and `inputSchemaJSON` encoded as UTF-8 data.
- **system-prompt-omitted-when-empty**: The context's system prompt MUST be nil when the agent's `prompt` is empty, otherwise the prompt itself.
- **max-tokens-formula**: `AgentHost.maxTokens(thinking:)` MUST return 4096 plus the thinking budget, with a nil budget counting as 0, and the context's `maxTokens` MUST be that value for the agent's `thinkingBudgetTokens`.
- **plugin-choice**: With no tools the loaded plugin MUST be used as is. With tools, the loaded plugin MUST be used as is only when its descriptor declares native tool support for the model and template and its built request is HTTP; otherwise it MUST be wrapped in `PromptedToolCallingPlugin`, so a subprocess provider never receives native tool definitions.
- **plugin-choice-once**: A turn MUST choose its plugin on the first round and reuse that choice for every later round.
- **round-stream-handling**: For each event of the round's stream the turn MUST emit `text_delta` and `thinking_delta` as they arrive, collect `toolUse` events in order, keep only the latest `usage`, and keep the `end` stop reason.
- **assistant-text-stored**: When a round completes, the turn MUST append the concatenated text as one `assistant` message if it is non-empty, and MUST NOT append one when it is empty; thinking text is never stored.
- **usage-emitted**: When a round completes and reported usage, the turn MUST emit one `usage` event (the latest reported) before running any of the round's tools.
- **turn-completes-without-tools**: A round that asks for no tool MUST end the turn with `turn_finished` carrying that round's stop reason, which can be nil.
- **round-limit**: When `maxToolRounds` rounds have all asked for tools, the turn MUST end with `turn_failed("The agent used tools for <maxToolRounds> rounds without answering")`; the tools of the last round have by then run.
- **max-tool-rounds-bounds**: A `maxToolRounds` below 1 MUST be taken as 1, so every turn makes at least one model round trip.

### Turns: tool calls

- **tool-calls-sequential**: A round's tool uses MUST run one at a time, in the order the model produced them, each finishing before the next starts.
- **tool-call-recorded**: Before running a tool use the turn MUST append a `tool_use` message holding the call id, tool name and arguments, and emit `tool_started` with the call id, tool name and arguments as a JSON string; arguments that are not valid UTF-8 MUST be given as the empty string in the event.
- **tool-context**: A tool run by a turn MUST receive a `ToolCallContext` with caller `"agent"`, the agent's id and the session id.
- **tool-success**: When a tool returns an outcome, the turn MUST emit `tool_finished` with the outcome's summary and no error, and append a `tool_result` message with the outcome's `resultJSON` and `toolIsError` false.
- **tool-activity**: After a successful run of a tool whose `isMutating` is true, the turn MUST emit an `activity` event after its `tool_finished`; a non-mutating tool MUST NOT produce one.
- **tool-failure-to-model**: When a tool throws any error other than cancellation, or the named tool does not exist (`AgentToolError.unknownTool`), the turn MUST emit `tool_finished` with summary `<name> failed` and the error's localized description, append a `tool_result` with `{"error":"<description>"}` (sorted keys) and `toolIsError` true, and continue the turn.
- **tool-cancel-ends-turn**: When cancellation reaches a tool call, the turn MUST rethrow it so the turn ends as interrupted; the stored `tool_use` is then left with no matching `tool_result`.

### Turns: ending

- **turn-failure-mapping**: An error thrown anywhere in a turn other than cancellation MUST end it with `turn_failed` carrying the error's localized description, unless the task has been cancelled, in which case it ends as `turn_finished("interrupted")`.
- **turn-cancellation-mapping**: A `CancellationError` MUST end the turn with `turn_finished("interrupted")`.
- **turn-completion-order**: When a turn ends the host MUST emit the final event, finish the per-turn stream, and only then mark the session as having no running turn.
- **turn-one-terminal-event**: A turn MUST emit exactly one terminal event (`turn_finished` or `turn_failed`) and it MUST be the last event of the turn.

### Direct tool runs

- **run-tool-lookup**: `runTool(_:argumentsJSON:context:)` MUST run the first host tool with that name and return its `ToolOutcome`, and MUST throw `AgentToolError.unknownTool(name)` when there is none.
- **run-tool-errors**: `runTool` MUST propagate an error the tool throws unchanged, without emitting an event.
- **run-tool-activity**: After a mutating tool returns, `runTool` MUST emit an `activity` event on `context.sessionId` when the context has one, and MUST emit nothing when it has none or the tool is not mutating.
- **run-tool-no-record**: `runTool` MUST NOT store a message, emit `tool_started`/`tool_finished`, check that the session exists, or consult the agent's `enabled` flag or `toolPermissions`.
- **activity-entry-fields**: An activity entry MUST carry `agentId` (the context's `agentId`, else its `caller`), the context's `sessionId`, the tool name, the arguments JSON, the `reason` found in the arguments and the outcome's summary; its `id` is a new UUID and `occurredAt` the time it was made.
- **reason-extraction**: `AgentHost.reason(in:)` MUST return the `reason` string of a JSON-object argument string, and nil when the text is not JSON, is not an object, has no `reason`, has a non-string `reason` or has an empty one.

### Policy fields

- **policy-fields-not-enforced**: The host MUST NOT consult `AgentDefinition.toolPermissions`, `arrival` or `deadlineSeconds`; every tool the model asks for runs. The definition's doc comments declare `toolPermissions` as "stored now, enforced in phase 2". A port MUST NOT enforce them either until a change that enforces them is approved.

### Data shapes

- **definition-decoding**: `AgentDefinition` MUST decode from `id`, `name`, `prompt` and `model` alone, defaulting `toolPermissions` to empty, `arrival` to `off`, `deadlineSeconds` to 30, `thinkingBudgetTokens` to nil and `enabled` to true, and MUST fail to decode when one of the four required fields is missing.
- **event-cases**: `AgentEvent` MUST have the cases `textDelta`, `thinkingDelta`, `toolStarted`, `toolFinished`, `activity`, `usage`, `turnFinished` and `turnFailed`; `isTerminal` MUST be true only for `turnFinished` and `turnFailed`.
- **event-wire-format**: An event MUST encode as flat JSON with snake_case keys and its case in `type` (`text_delta`, `thinking_delta`, `tool_started`, `tool_finished`, `activity`, `usage`, `turn_finished`, `turn_failed`): `text` for both delta cases, `call_id`/`tool`/`arguments` for `tool_started`, `call_id`/`tool`/`summary`/`error` for `tool_finished`, `id`/`at`/`agent_id`/`session_id`/`tool`/`arguments`/`reason`/`summary` for `activity`, the four `*_tokens` counts for `usage`, `stop_reason` for `turn_finished` and `message` for `turn_failed`; nil optional values MUST be omitted.
- **event-unknown-type**: Decoding an event whose `type` is not one of the eight MUST throw a `DecodingError`; a missing `usage` count decodes as 0.
- **envelope-wire-format**: An `AgentEnvelope` MUST encode as `session_id`, `seq` and `event`.
- **message-storage**: A stored `AgentMessage` MUST carry its position `seq` from 0, the role's raw value, content, optional tool id, name, arguments (as a UTF-8 string, empty when not UTF-8) and error flag, and creation time; `chatMessage` MUST be nil for a role this build does not know, so history building skips it.

### Persistence

- **message-sequence**: `AgentStore.append` MUST give a message the next consecutive `seq` for its session (0 for the first) and update the session's `updatedAt` in the same database write.
- **store-json-form**: Definitions and messages MUST be stored as JSON text encoded with ISO 8601 dates and sorted keys; sessions MUST be stored in columns with times as seconds since 1970.
- **store-session-skip**: A stored session row whose id is not a UUID MUST be skipped by session reads.
- **store-delete-order**: `AgentStore.deleteSession` MUST delete the session's messages and then the session row; the tables declare no foreign key.
- **persistence-durability**: Definitions, sessions and messages MUST survive a host restart because they live in the handed database; the running-turn map, the per-turn streams, the tails and the `seq` counters MUST NOT survive it.

