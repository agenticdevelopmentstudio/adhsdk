---
id: d711486e-1195-417b-9baf-7315354dae8d
title: "Agent Host"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-25
modified: 2026-11-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Actor that hosts agent definitions and sessions over one tool set, runs model turns with a bounded tool loop, and streams numbered events."
platforms:
  - swift
  - macos
tags:
  - ai
  - agents
  - actor
  - tool-calling
  - streaming
depends-on:
  - 4d7ed9a3-c6d8-491b-911a-cf257fde1c38
  - 5f18890e-5473-4315-9e69-dde7c64778bc
related:
  - 2067e249-4f97-4575-b8ed-8f55f6dc96df
  - 613d7a36-d0cd-4415-97be-d983b3d6c644
references: []
approved-by: ""
approved-date: ""
---

# Agent Host

## Overview

`AgentHost` is the headless engine behind agents. One host owns a set of agent definitions, their conversation sessions and one set of tools. It stores definitions, sessions and messages in a database it is handed (the daemon passes its own SQLite file), runs a turn by looping model round trips through the model registry's plugins until the model answers without asking for a tool, and streams everything that happens as numbered `AgentEnvelope` values. The same host also runs a tool outside any turn for a client of its HTTP handlers or its MCP bridge.

The host is an `actor`. It covers four concerns that this ingredient specifies together because they share one in-memory state: agent and session management, the turn loop, the event streams (a per-turn stream and a per-session live tail) and direct tool runs. It reads three companion types: `AgentDefinition`, `AgentEvent`/`AgentEnvelope` and the private `AgentStore`. Their contracts are specified in full here, in Data shapes and Persistence, because the host is their only producer and consumer in the SDK; a design decision records why they are not split into their own ingredients. The `AgentTool` protocol and the HTTP handlers have their own ingredients, [Agent Tool](cookbook:86788f50-7b85-4659-b7df-8c560e082f76) and [Agent Handlers](cookbook:f9f7ae23-0da9-41fb-a065-968a028d059e), and are referenced, not specified, here.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a headless agent host, not a visual component.

## States

Not applicable — this is a headless agent host, not a visual component.

## Accessibility

Not applicable — this is a headless agent host, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-host-001 | send-turn-stream, round-stream-handling, usage-emitted, envelope-numbering, assistant-text-stored, turn-completion-order (`AgentHostTests.plainTurn`) | A scripted round of `thinkingDelta("hmm")`, `textDelta("Hel")`, `textDelta("lo")`, `usage(inputTokens 10)`, `usage(inputTokens 10, outputTokens 2)`, `end("end_turn")`; `send("Hi")` | The stream's events are `thinking_delta("hmm")`, `text_delta("Hel")`, `text_delta("lo")`, `usage(10, 2)`, `turn_finished("end_turn")` with `seq` 0 through 4 and the session id on each; the session holds messages `user`, `assistant` with the assistant content `"Hello"` |
| agent-host-002 | context-contents, context-tools, system-prompt-omitted-when-empty, max-tokens-formula, plugin-load-per-turn (`AgentHostTests.buildsContext`) | An agent with prompt `"You help."` and thinking budget 1024, tools `echo`, `bump`, `broken`; `send("Hi")` | The built context has system prompt `"You help."`, messages `["Hi"]`, tools `["echo","bump","broken"]`, thinking budget 1024, `maxTokens == 5120`, model `fake-native` and `config.apiKey == "test-key"` |
| agent-host-003 | tool-calls-sequential, tool-call-recorded, tool-context, tool-success (`AgentHostTests.toolRound`) | Round 1 `toolUse("c1","echo",{"text":"x"})` then `end("tool_use")`; round 2 `textDelta("Done.")`, `end("end_turn")`; `send("Echo x")` | Events `tool_started(c1, echo, {"text":"x"})`, `tool_finished(c1, echo, "Echoed", nil)`, `text_delta("Done.")`, `turn_finished("end_turn")`; two rounds started; messages `user`, `tool_use`, `tool_result`, `assistant`; the result's content contains `"caller":"agent"` and `toolIsError == false` |
| agent-host-004 | tool-activity, activity-entry-fields, reason-extraction (`AgentHostTests.mutatingToolActivity`) | The mutating tool `bump` called with `{"reason":"testing"}` | An `activity` event with tool `bump`, agent id `helper`, the session id, reason `"testing"` and summary `"Bumped the counter"` |
| agent-host-005 | tool-failure-to-model, turn-completes-without-tools (`AgentHostTests.toolErrors`) | One round calling `broken` (throws "The tool broke") and `missing` (no such tool) | `tool_finished(c1, broken, "broken failed", "The tool broke")` and `tool_finished(c2, missing, "missing failed", "Unknown tool 'missing'")`; the last event is `turn_finished("end_turn")`; both `tool_result` messages have `toolIsError == true` and the first contains `"The tool broke"` |
| agent-host-006 | round-limit (`AgentHostTests.roundLimit`) | `maxToolRounds` 2 and three scripted rounds that each call `echo` | The last event is `turn_failed`; exactly 2 rounds started |
| agent-host-007 | model-role-fallback (`AgentHostTests.roleFallback`) | The agent's selector is `role("nobody-has-this")`; one enabled entry holds `smart` | The turn runs and ends `turn_finished("end_turn")` |
| agent-host-008 | model-none-available, model-config-no-fallback (`AgentHostTests.noModel`) | The agent's selector is `config(id: <random UUID>)` | The last event is `turn_failed`, and 0 model rounds started |
| agent-host-009 | send-refusal-order, host-error-cases, one-turn-per-session, interrupt-stop-reason (`AgentHostTests.sendRefusals`) | `send` to an unknown session, to a session of a disabled agent, and a second `send` to a session whose first turn hangs | `sessionNotFound(<id>)`, `agentDisabled("off")` and `turnInProgress(<id>)`; after `interrupt` the first stream ends with `turn_finished("interrupted")` |
| agent-host-010 | interrupt-cancels-turn, interrupt-stop-reason, interrupt-then-send, turn-one-terminal-event (`AgentHostTests.interrupts`) | A hanging turn, then `interrupt`, collect, then `send` and `interrupt` again | The first stream's events are exactly `[turn_finished("interrupted")]`; the second turn also ends `turn_finished("interrupted")` |
| agent-host-011 | events-tail, envelope-numbering, delete-session-effects (`AgentHostTests.liveTail`) | A tail opened before two turns of `"one"` and `"two"`; then `deleteSession` | The second turn's envelopes have `seq` `[2, 3]`; the tail, which ends at the delete, saw `text_delta("one")`, `turn_finished`, `text_delta("two")`, `turn_finished` |
| agent-host-012 | run-tool-lookup, run-tool-errors, run-tool-activity, run-tool-no-record (`AgentHostTests.runToolDirectly`) | `runTool("echo")` with caller `external` and no session; `runTool("nope")`; `runTool("bump")` with a session id, a tail open | The echo result contains `"caller":"external"`; the second throws `unknownTool("nope")`; the tail receives exactly one `activity` with reason `"cli"` |
| agent-host-013 | save-requires-id, save-requires-name, create-session-requires-agent, save-upserts, agents-listing (`AgentHostTests.agentManagement`) | `save` with id `""`, `save` with name `" "`, `createSession("ghost")`, `save(id: "new")` | `invalidAgent` twice; `agentNotFound("ghost")`; `agents()` ids sorted are `["helper","new"]` |
| agent-host-014 | plugin-choice (`AgentHostTests.choosesPlugin`) | The native model with tools and an HTTP plugin; the prompted model with tools; no tools; a command-transport plugin with the native model | The plugin itself; a `PromptedToolCallingPlugin`; the plugin itself; a `PromptedToolCallingPlugin` |
| agent-host-015 | max-tokens-formula (`AgentHostTests.maxTokens`) | `maxTokens(thinking: nil)` and `maxTokens(thinking: 2048)` | 4096 and 6144 |
| agent-host-016 | init-inserts-defaults, agent-lookup, agents-listing (`AgentStoreTests.defaultsKeepEdits`) | Defaults `a`, `b`; `save` an edited `a`; insert defaults `a`, `c` again | Ids `["a","b","c"]`; `a`'s prompt is still `"Edited."` |
| agent-host-017 | save-upserts, definition-decoding, agent-lookup (`AgentStoreTests.saveRoundTrips`) | Save a definition with every field set, including `.ask` permission and `enabled: false`; read it back; read `"absent"` | The read equals the saved value; `"absent"` is nil |
| agent-host-018 | sessions-listing, create-session-fields (`AgentStoreTests.sessionsOrder`) | Sessions `first` (title `"one"`) and `second` for agent `a`, one for `b`; a message appended to `first` | `sessions("a")` is `[first, second]`; `sessions(nil)` has 3; `b`'s session reports agent `b` |
| agent-host-019 | message-sequence, message-storage (`AgentStoreTests.appendSequences`) | Append a user, a tool-use (arguments `{"text":"x"}`) and a tool-result (error) message | `seq` 0, 1, 2; roles `["user","tool_use","tool_result"]`; the stored arguments string is `{"text":"x"}`; `chatMessage.toolName == "echo"`; `toolIsError == true` |
| agent-host-020 | store-delete-order, session-detail (`AgentStoreTests.deleteSession`) | Delete a session that has a message | `session(id)` is nil and `messages(id)` is empty |
| agent-host-021 | definition-decoding (`AgentStoreTests.minimalAgentDecodes`) | JSON with only `id`, `name`, `prompt` and `model` as role `fast` | `enabled` true, `arrival == off`, `deadlineSeconds == 30`, empty `toolPermissions` |
| agent-host-022 | event-wire-format, event-cases (`AgentEventTests.roundTrips`, `AgentEventTests.wireKeys`) | Each of ten sample events, including `turn_finished` with a nil stop reason | Each decodes equal to itself and its `type` equals `event.type`; `tool_started` has exactly the keys `type`, `call_id`, `tool`, `arguments`; usage has `input_tokens` 5 and `cache_write_tokens` 0 |
| agent-host-023 | event-cases (`AgentEventTests.terminal`) | `turn_finished`, `turn_failed`, `text_delta` | `isTerminal` is true, true, false |
| agent-host-024 | event-unknown-type (`AgentEventTests.unknownType`) | JSON `{"type":"mystery"}` | Decoding throws a `DecodingError` |
| agent-host-025 | envelope-wire-format (`AgentEventTests.envelope`) | An envelope with `seq` 7 | Its keys are `session_id`, `seq`, `event`, and it decodes equal |
| agent-host-026 | host-error-descriptions (derived from `errorDescription`; `AgentHostTests.sendRefusals` compares only the error cases) | `AgentHostError.turnInProgress(<id>)` | `errorDescription` is `Session <id> already has a turn running` |
| agent-host-027 | tool-cancel-ends-turn, turn-cancellation-mapping, interrupt-drops-round-text (`AgentHostTests.interrupts` asserts only the stop reason; the rest is derived from `loop`) | A round that has emitted `text_delta` events, then `interrupt` | The turn ends `turn_finished("interrupted")`; no `assistant` message is stored |
| agent-host-028 | send-stores-user-message, send-refusal-stores-nothing (derived from `send`; no test asserts it) | `send("")` to a valid session; `send` to a disabled agent's session | The empty text is stored as a `user` message; the refused send stores nothing |
| agent-host-029 | tool-activity (`AgentHostTests.toolRound`) | A non-mutating tool (`echo`) run in a turn | No `activity` event follows its `tool_finished` |
| agent-host-030 | reason-extraction (`AgentHostTests.mutatingToolActivity` asserts only `"testing"`; the other rows are derived from `reason(in:)`) | Arguments `not json`, `[]`, `{}`, `{"reason":3}`, `{"reason":""}`, `{"reason":"why"}` | nil, nil, nil, nil, nil, `"why"` |
| agent-host-031 | init-throws, init-migrates-store (derived from the initializer; no test asserts it) | A database whose migration throws | The initializer throws and no host exists |

| agent-host-032 | delete-session-running-turn, delete-session-effects (`AgentHostTests.deleteRunningSession`) | A turn hanging in a model round; `deleteSession` on its session | The `send` stream finishes with no final event; the cancelled turn emits no further event and stores no further message; the session's event counter is not recreated |
| agent-host-033 | max-tool-rounds-bounds (`AgentHostTests.roundLimitFloor`) | `maxToolRounds` 0, then -1, with a scripted round that calls `echo` | Each turn starts exactly 1 round and ends `turn_failed("The agent used tools for 1 rounds without answering")` |
| agent-host-034 | events-tail-no-replay (derived from `events(_:)`; no test asserts it) | A turn completes; then `events(session)` opens | The tail receives none of the finished turn's events; a later turn's events arrive |
| agent-host-035 | events-tail-unchecked-session (derived from `events(_:)`; no test asserts it) | `events(<random UUID>)` for a session that does not exist | It does not throw and yields nothing |
| agent-host-036 | events-tail-removal (derived from the tail's termination handler; no test asserts it) | Two tails on a session; stop the first, then the second | An event emitted after the first stops reaches only the second; after both stop the session's tail table is gone and a later event is dropped without error |
| agent-host-037 | send-stream-detach (derived from `send`; no test asserts it) | `send`, then stop iterating the returned stream before the turn ends | The turn keeps running, finishes, and stores its assistant message; a tail on the session sees its `turn_finished` |
| agent-host-038 | turn-agent-snapshot (derived from `send`; no test asserts it) | `send`, then `save` the agent with a different prompt while the turn is hanging | The running turn's context keeps the prompt read when `send` was called |
| agent-host-039 | plugin-choice-once (derived from the loop; no test asserts it) | A two-round tool turn with a native-tool HTTP plugin | The plugin is chosen on round 1 and the same choice is used for round 2 |
| agent-host-040 | turn-failure-mapping, plugin-load-per-turn (derived from the loop; no test asserts it) | A `runtime` whose `load` throws "no plugin" | The last event is `turn_failed("no plugin")` and no model round starts |
| agent-host-041 | store-session-skip (derived from `AgentStore`; no test asserts it) | A row in `agent_sessions` whose id is `"not-a-uuid"` | `sessions(nil)` omits it and does not throw |
| agent-host-042 | persistence-durability (derived from the initializer; no test asserts it) | Save an agent, create a session and send a turn; recreate the host on the same database | `agents()`, `sessions(nil)` and `session(_:)` return the stored rows; the new host has no running turn and `seq` starts at 0 |
| agent-host-043 | create-session-ignores-enabled (derived from `createSession`; no test asserts it) | `createSession` for an agent saved with `enabled` false; then `send` to it | The session is created; `send` throws `agentDisabled` |
| agent-host-044 | save-requires-id, save-requires-name (`AgentHostTests.agentManagement`) | `save` with id `"\n\t"`; `save` with name `"\n"` | `invalidAgent("An agent needs an id")`; `invalidAgent("An agent needs a name")` |
## Edge Cases

- **Null and empty input**: `send` with empty text MUST store it and run a turn (`send-stores-user-message`). A nil `title` MUST be stored as no title. An empty agent `prompt` MUST give a nil system prompt. A tool-argument string that is not a JSON object MUST give a nil `reason` and MUST NOT fail the run. A round with no text MUST store no assistant message.
- **Boundary values**: `maxToolRounds` of 2 MUST stop after exactly 2 rounds; 0 or a negative value MUST behave as 1 (`max-tool-rounds-bounds`). A nil thinking budget MUST give `maxTokens` 4096.
- **Unknown identifiers**: `send` to an unknown session MUST throw `sessionNotFound`; `createSession` for an unknown agent MUST throw `agentNotFound`; `runTool` with an unknown name MUST throw `unknownTool`; a model that calls an unknown tool MUST receive an error result and the turn MUST continue.
- **Disabled agent**: A disabled agent MUST keep its sessions and refuse new turns with `agentDisabled`; a turn already running when the agent is saved as disabled keeps running (`turn-agent-snapshot`).
- **Concurrent access**: The actor MUST serialise every state change; a second `send` on a session with a running turn MUST throw `turnInProgress`; turns of different sessions MAY interleave at their awaits. Two emits cannot interleave, so `seq` values are gapless per session.
- **Error states**: A throwing plugin load, request build, stream or store write inside a turn MUST end the turn with `turn_failed` and the error's description (`turn-failure-mapping`); a throwing tool MUST NOT end the turn (`tool-failure-to-model`); a failed store write inside `send` before the turn starts MUST propagate to the caller as a thrown error.
- **Cancellation**: `interrupt` during a model round MUST end the turn as `interrupted` and drop the round's unsaved text; during a tool run it MUST leave a `tool_use` with no `tool_result` in the stored history, which the next turn's context then contains.
- **Offline or unreachable provider**: The host has no timeout, retry or offline handling of its own; a provider that cannot be reached surfaces as the plugin stream's thrown error and becomes `turn_failed`, and a provider that never answers leaves the turn running until `interrupt`.
- **Wrong or stale data**: A stored message with a role this build does not know MUST be skipped when building the context; a stored session row whose id is not a UUID MUST be skipped in listings.
- **Events with no listener**: Events emitted with no stream and no tail MUST be dropped without error, so a `runTool` activity on a session nobody is watching is not retained.
- **Host restart**: After a restart a session's events restart at `seq` 0 and a turn that was running is gone; its stored messages remain and the session accepts a new `send`.
- **Deleting a running session**: The turn's stream MUST end with no final event, and the cancelled turn MUST emit and store nothing more (`delete-session-running-turn`).

- **Whitespace-only id or name**: `save` trims `.whitespacesAndNewlines`, so an id or name made only of spaces, tabs or newlines is refused with `invalidAgent`, the same as an empty one.
- **Client reconnect**: A client that reconnects to a host sees `seq` restart at 0 when the host was recreated and continue otherwise; it cannot tell which from the envelope, so it resets its tracking on every reconnect (`envelope-seq-memory-only`).
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | `BoundedDatabase` | required | Where the host keeps its tables; the daemon passes `events.sqlite`. |
| `registry` | `ModelRegistry` | required | Resolves model selectors and supplies the plugin search paths. |
| `tools` | array of `AgentTool` | required | The one tool set shared by every agent; exposed as `tools`. |
| `defaults` | array of `AgentDefinition` | required | Agents inserted when their id is absent; an edited one is kept. |
| `runtime` | `DaemonAIChat.PluginRuntime` | `.live` | Loads a plugin and runs a built request; tests inject a scripted one. |
| `maxToolRounds` | `Int` | 16 | Model round trips a turn may make before it fails; a value below 1 is taken as 1. |
| `AgentDefinition.defaultDeadlineSeconds` | `Double` | 30 | Default `deadlineSeconds` of a definition; the host does not use it. |

Two values are constants, not options: `AgentHost.agentCaller` (`"agent"`, the caller name tools see on a turn's tool runs) and the answer room (4096 tokens added to the thinking budget to make `maxTokens`).

The host reads no environment variable and no settings key.

## Deep Linking

Not applicable: the host has no URL, scheme or route of its own; its HTTP handlers ([Agent Handlers](cookbook:f9f7ae23-0da9-41fb-a065-968a028d059e)) and the MCP bridge have their own ingredients.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none | `No agent with id '<id>'` | `AgentHostError.agentNotFound` description |
| none | `The agent '<id>' is disabled` | `AgentHostError.agentDisabled` description |
| none | `No session with id <UUID>` | `AgentHostError.sessionNotFound` description |
| none | `Session <UUID> already has a turn running` | `AgentHostError.turnInProgress` description |
| none | `An agent needs an id`, `An agent needs a name` | `invalidAgent` reasons from `save` |
| none | `No model is available: add and enable one in the model registry` | `turn_failed` message |
| none | `The agent used tools for <N> rounds without answering` | `turn_failed` message |
| none | `<tool> failed` | `tool_finished` summary on a tool error |

Every string is a hardcoded English literal; none goes through a localization table. Error descriptions of other types and the `{"error":...}` result are passed on as they arrive.

## Accessibility Options

Not applicable: the host has no visual or motion output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag; the agent's `enabled` field is stored data that gates `send`, not a feature flag.

## Analytics

Not applicable: the source emits no analytics event. The `activity` event describes a mutating tool run for the host's feed and is not persisted by the host.

## Privacy

- **Data collected**: The host stores each session's user text, assistant text, tool-call arguments and tool results, and the agent definitions (prompts included), all as plaintext JSON.
- **Storage**: In the handed database's `agent_definitions`, `agent_sessions` and `agent_messages` tables; nothing is encrypted by the host. Thinking text and usage are streamed but not stored.
- **Transmission**: Each round sends the session's whole stored history, the system prompt and the tool specs to the provider through the chosen plugin; the host adds no redaction. Events leave the process only through whatever consumes the returned streams.
- **Retention**: A session and its messages are kept until `deleteSession`; the host defines no expiry or size limit.

## Logging

Not applicable: the source contains no logging call; failures are reported through thrown errors, `turn_failed` events and tool error results.

## Platform Notes
- **SwiftUI**: The host has no view dependency. Keep the host out of views: hold it in an app-level model, call `agents()` and `session(_:)` from a `Task` and iterate the `AsyncStream` from `send` or `events` there, and publish the rendered transcript through an `@Observable` model that views read. Apply envelopes on the main actor in `seq` order, and reset the tracked `seq` whenever the stream is reopened, since it restarts after a host restart.
- **AppKit / UIKit**: The host has no AppKit or UIKit dependency. A controller starts one `Task` per open session that iterates `events(_:)` and updates its view state on the main actor; cancelling that task stops the tail and the host removes it. A host on another platform injects its own `PluginRuntime` through the initializer in place of `.live`; the host is an `actor` and its public types are `Sendable`, so the compiler keeps the isolation.
- **Compose**: Model the host as a class that owns a single-threaded `CoroutineDispatcher` (or a `Mutex`) for the actor guarantee, with the per-turn stream and each tail as a `MutableSharedFlow` or `Channel` of envelopes, `send` returning a `Flow`, and `interrupt` cancelling the turn's `Job` (`CancellationException` maps to the `"interrupted"` stop reason). Persist with Room or SQLite using the same three tables; JSON columns map to `kotlinx.serialization` with snake_case names.
- **React/Web**: Model it as an async class in a service worker or backend, with the turn as an async function that cancels through `AbortController`, streams as `AsyncIterable<Envelope>`, and events delivered as server-sent events named by `type`. JavaScript's single thread gives the serialisation the actor gives here, but a turn's awaits still interleave, so the one-turn-per-session map is still required. A browser has no subprocess provider, so only the HTTP plugin path applies.
- **WinUI 3**: Model the host as a .NET class guarded by a `SemaphoreSlim(1,1)` in place of the actor, with `interrupt` calling `CancellationTokenSource.Cancel()` on the turn's token; `OperationCanceledException` maps to the `"interrupted"` stop reason. Run a turn as a `Task` started with `Task.Run` and track it in a `Dictionary<Guid, Task>` for one-turn-per-session. Use `System.Threading.Channels.Channel<AgentEnvelope>` per consumer, exposed as `IAsyncEnumerable<AgentEnvelope>`, in place of `AsyncStream`; a tail's removal on termination maps to disposing the enumerator. Persist with `Microsoft.Data.Sqlite` in the same three tables, with `System.Text.Json` using `JsonNamingPolicy.SnakeCaseLower` and a `JsonConverter` for the flat, `type`-discriminated `AgentEvent`. Dates are ISO 8601 (`DateTimeOffset`); `INotifyPropertyChanged` and `ObservableCollection<T>` belong in a view model that consumes the stream, not in the host. `HttpClient` replaces the plugin transport in a Windows App SDK app.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Agent/AgentHost.swift` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Agent/AgentDefinition.swift` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Agent/AgentEvent.swift` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Agent/AgentStore.swift` | unverified |

## Design Decisions

**Decision**: The host keeps two kinds of stream: a per-turn stream returned by `send`, and a per-session tail from `events(_:)` that spans turns, and both receive the same numbered envelope.
**Rationale**: Ending the per-turn stream does not stop the turn and the tail lasts until the session is deleted or the caller stops listening, so the requesting client can follow one turn while a second client watches the session; the shared `seq` lets a client detect a gap or a repeat.
**Approved**: pending

**Decision**: `seq` lives in memory and restarts at 0 for a session after the host is recreated, separate from the stored message `seq`.
**Rationale**: Events are a live feed, not a log, and the host persists only the messages.
**Approved**: pending

**Decision**: A tool that throws, or a tool that does not exist, is returned to the model as an error result and the turn continues; only cancellation and host-level failures end the turn.
**Rationale**: This lets the model correct a bad call itself instead of failing the whole turn.
**Approved**: pending

**Decision**: A `role` selector that no enabled entry holds falls back to the first enabled entry, but a `config` selector never falls back.
**Rationale**: The fallback makes an agent work as soon as any model is set up; a `config` selector names one entry on purpose, and the registry treats a disabled entry as out of service everywhere.
**Approved**: pending

**Decision**: The plugin is chosen on the first round and reused, and a provider that is not an HTTP provider with native tool support gets `PromptedToolCallingPlugin`.
**Rationale**: A subprocess provider never receives native tool definitions, and choosing once keeps a turn's rounds on one request shape.
**Approved**: pending

**Decision**: `toolPermissions`, `arrival` and `deadlineSeconds` are stored and returned but never enforced by the host.
**Rationale**: The definition's doc comments say they are enforced in a later phase, so phase 1 runs every tool the model asks for (the requirement is `policy-fields-not-enforced`).
**Approved**: pending

**Decision**: `runTool` reports activity only for mutating tools run in a session, and records nothing else.
**Rationale**: It serves a client of the host's handlers or its MCP bridge; the model's own view of a conversation is made only by turns, so a direct run must not add `tool_use` messages to it.
**Approved**: pending

**Decision**: A turn emits its terminal event before finishing the per-turn stream and clearing its running marker.
**Rationale**: Every consumer then sees the terminal event as the last one before the stream ends, and a `send` made after the stream ends does not meet a stale `turnInProgress`.
**Approved**: pending

**Decision**: The envelope carries no host-instance epoch; a client resets its `seq` tracking when it reconnects.
**Rationale**: Adding an epoch changes the wire format that clients already read; until that change is approved, the reset rule in `envelope-seq-memory-only` is how a client tells a restart from a repeat.
**Approved**: pending

**Decision**: This ingredient specifies the `AgentDefinition`, `AgentEvent`/`AgentEnvelope` and `AgentStore` contracts together with the host and does not split them into ingredients of their own.
**Rationale**: The host is the only producer of events and the only user of the store and definition in the SDK, the four types change together, and a split would put one behaviour across several ingredients with no second consumer to justify it; a split stays possible if another host appears.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | failed | Reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | partial | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

Separation-of-concerns passes: the host owns turn orchestration and event fan-out, persistence sits behind `AgentStore`, model resolution behind `ModelRegistry`, request building and transport behind the injected `PluginRuntime`, and tool behavior behind `AgentTool`. Unit-test-coverage is partial: `AgentHostTests.swift` drives the loop through a scripted runtime and fake tools (including `deleteRunningSession` and `roundLimitFloor`), `AgentStoreTests.swift` covers defaults, round trips, ordering, sequencing and deletion, and `AgentEventTests.swift` covers the wire; but these requirements have no test and their vectors are derived: `host-error-descriptions`, `send-stores-user-message`, `send-refusal-stores-nothing`, `reason-extraction` (all but the `"testing"` case), `init-throws`, `init-migrates-store`, `events-tail-no-replay`, `events-tail-unchecked-session`, `events-tail-removal`, `send-stream-detach`, `turn-agent-snapshot`, `plugin-choice-once`, `turn-failure-mapping`, `store-session-skip`, `persistence-durability` and `create-session-ignores-enabled`. Explicit-error-handling is partial: every failure either throws a typed `AgentHostError` or becomes a `turn_failed` or an error result, `maxToolRounds` is clamped to at least 1 (`max-tool-rounds-bounds`), and the deletion race is specified (`delete-session-running-turn`); it stays partial because a tool call cut short by an interrupt leaves a `tool_use` with no result. No-hardcoded-strings fails because every message the host authors is an English literal. Timeout-handling fails because no model round or tool run has a time limit; `interrupt` is the only way to stop a stalled one. State-recovery is partial: sessions and messages survive a restart, but the running turn, its streams and the event counters do not, and a tool call cut short leaves a `tool_use` with no result. Data-integrity is partial: a message's sequence number and its session's update time are written in one database write, but session deletion is two separate deletes with no foreign key; a turn running when its session is deleted is cancelled and stores nothing more, so it leaves no orphan rows.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-25 | Mike Fullerton | Initial creation |
