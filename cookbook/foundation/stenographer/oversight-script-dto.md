---
id: 1088e4ae-f6ee-4174-8ba5-a913587af3be
title: "Oversight Script DTO"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The shared wire model of one oversight script: its trigger predicate tree, optional LLM confirmation and response, plus the provider-selection sentinel."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - dto
  - wire
depends-on:
  - e8286557-84ee-4f45-b78c-f1d184c51a37
related:
  - 7d2280c6-ae67-4ecc-9aae-dbee574b1eab
  - 96f73261-cf32-42cc-92f3-f8b58542382a
references: []
approved-by: ""
approved-date: ""
---

# Oversight Script DTO

## Overview

`OversightScript` is the configuration record of AI oversight: a trigger (a boolean predicate over one live session, optionally confirmed by an LLM) and a response (the finding to record and the action a human can dispatch on it). The shipped "compact" script is the first one; users create their own. The types live in the shared package so the daemon (evaluation and storage), the app (the editor), HTTP and XPC all speak one shape.

The file holds the script value and its parts (`ScriptTrigger`, `LLMConfirmation`, `ScriptResponse`), the predicate tree (`ScriptPredicate` with `ConditionField` and `ConditionOperator`), the action (`ScriptAction`), and one constant namespace, `OversightProviderSelection`, with the provider-selection sentinel. It defines shapes and their wire spelling only. Predicate evaluation, reason rendering, save-time validation, storage, built-in upgrade and the LLM call belong to the daemon.

**Documented semantics.** These meanings come from the source's doc comments. The daemon enforces or applies them; the DTO only carries the values, so a DTO conformance test cannot check them.

- A script's `id` is a stable identifier: a slug for a built-in (example in source: `"compact"`) and a UUID string for a user script. It doubles as the `observer` namespace of the findings the script produces ([adhsdk.ingredient.foundation.stenographer.oversight-finding-dto](cookbook:7d2280c6-ae67-4ecc-9aae-dbee574b1eab)).
- `builtIn` means the script is shipped with the daemon: upgradeable, resettable and not deletable.
- `version` is the version of the shipped definition, bumped in code when a built-in's definition improves so upgrades can refresh unmodified rows.
- LLM confirmation is itself gated by the daemon's `oversight_llm_enabled` switch; `ScriptTrigger` carries no such switch.
- The confirmation reply contract is one line: `"<ACTKEYWORD>: reason"` to act, or `"WAIT: reason"` to skip this tick. The DTO declares the contract and does not parse replies.
- Numeric condition fields compare the condition's value parsed as a number; string fields support `eq`, `ne` and `contains`. The evaluator fails closed (false) for an ordering operator on a string field and for `contains` on a numeric field.
- `tokens_in_context` is derived: `context_used_pct` times `context_window_size` divided by 100.
- The type-discriminated action format is documented to accommodate future actions (notify, run-command) without a shape change; this version knows only `inject` and `none`.
- Injected text is typed into the session's terminal and is human-approved through the existing safety gate; the DTO does not send text anywhere.

The struct keys use the stenographer wire coders ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37)). The daemon routes that serve scripts are specified by the stenographer daemon service ([adhsdk.ingredient.foundation.stenographer.stenographer-daemon-service](cookbook:96f73261-cf32-42cc-92f3-f8b58542382a)).
## Behavioral Requirements

**OversightScript**

- **script-conformances**: `OversightScript` MUST be a value type that is `Codable`, `Sendable` and `Equatable`, with mutable (`var`) fields.
- **script-field-set**: `OversightScript` MUST carry `id` (String), `name` (String), `enabled` (Bool), `builtIn` (Bool), `version` (Int), `trigger` (`ScriptTrigger`) and `response` (`ScriptResponse`).
- **script-init**: The public initializer MUST take all seven fields in that order with no defaults.
- **script-wire-keys**: `OversightScript` MUST encode through the stenographer-wide snake_case strategy, so its keys are `id`, `name`, `enabled`, `built_in`, `version`, `trigger` and `response`.

**ScriptTrigger and LLMConfirmation**

- **trigger-field-set**: `ScriptTrigger` MUST carry `predicate` (`ScriptPredicate`) and `llmConfirmation` (optional `LLMConfirmation`, default nil in the initializer).
- **trigger-wire-keys**: `ScriptTrigger` MUST use the keys `predicate` and `llm_confirmation`; a nil confirmation MUST be omitted on encode and MUST decode as nil when the key is absent.
- **confirmation-field-set**: `LLMConfirmation` MUST carry `systemPrompt` (String) and `actKeyword` (String), both required, with wire keys `system_prompt` and `act_keyword`.
- **confirmation-act-keyword**: `actKeyword` MUST be the affirmative keyword the model replies with (example in source: `"COMPACT"`).

**ScriptPredicate**

- **predicate-cases**: `ScriptPredicate` MUST be an indirect enum with exactly three cases: `all` (a list of predicates), `any` (a list of predicates) and `condition` (a `field`, an `operation` and a String `value`).
- **predicate-conformances**: `ScriptPredicate` MUST be `Sendable`, `Equatable` and `Codable`.
- **predicate-wire-shape**: `ScriptPredicate` MUST encode as an object with a `type` discriminator of `all`, `any` or `condition`. A group carries a `predicates` array; a condition carries `field`, `op` and `value`.
- **predicate-fixed-keys**: The predicate's keys MUST be fixed single words (`type`, `predicates`, `field`, `op`, `value`) written by a hand-written coder, so the spelling does not depend on the encoder's key strategy.
- **predicate-op-key**: The operation MUST travel under the key `op`, not `operation`.
- **predicate-unknown-type**: Decoding a predicate whose `type` is not `all`, `any` or `condition` MUST throw a data-corrupted decoding error whose description is `Unknown predicate type '<type>'`.
- **predicate-nesting**: Groups MUST nest to any depth; a group's `predicates` decode recursively.
- **predicate-empty-group**: The documentation states an empty group evaluates to false and is rejected at save. The DTO MUST still encode and decode an empty group without error.

**ConditionField and ConditionOperator**

- **field-set**: `ConditionField` MUST have eight cases with these wire raw values: `tokens_in_context`, `context_used_pct`, `context_window_size`, `last_event_type`, `idle_minutes`, `session_status`, `model`, `project_path`. The Swift case names map to the raw values as follows.

  | Case | Raw value |
  |------|-----------|
  | `tokensInContext` | `tokens_in_context` |
  | `contextUsedPct` | `context_used_pct` |
  | `contextWindowSize` | `context_window_size` |
  | `lastEventType` | `last_event_type` |
  | `idleMinutes` | `idle_minutes` |
  | `sessionStatus` | `session_status` |
  | `model` | `model` |
  | `projectPath` | `project_path` |
- **field-is-numeric**: `ConditionField.isNumeric` MUST be true for `tokensInContext`, `contextUsedPct`, `contextWindowSize` and `idleMinutes`, and false for `lastEventType`, `sessionStatus`, `model` and `projectPath`.
- **operator-set**: `ConditionOperator` MUST have seven cases with these wire raw values: `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `contains`. The Swift case names map to the raw values as follows.

  | Case | Raw value |
  |------|-----------|
  | `equals` | `eq` |
  | `notEquals` | `ne` |
  | `greaterThan` | `gt` |
  | `greaterOrEqual` | `gte` |
  | `lessThan` | `lt` |
  | `lessOrEqual` | `lte` |
  | `contains` | `contains` |
- **enums-case-iterable**: Both enums MUST be `CaseIterable`, `Codable`, `Sendable` and String-backed, so an editor can list every choice.
- **unknown-field-or-op**: Decoding a `field` or `op` raw value outside the lists above MUST fail (the synthesized String-enum decoder throws).

**ScriptResponse and ScriptAction**

- **response-field-set**: `ScriptResponse` MUST carry `kind` (String), `reasonTemplate` (String) and `action` (`ScriptAction`), with wire keys `kind`, `reason_template` and `action`, all required.
- **response-kind**: `kind` MUST be the finding's actionable `kind` (example in source: `"compact"`).
- **response-reason-template**: `reasonTemplate` MUST be the reason line, in which placeholders written like `{{context_used_pct}}` substitute the session's current values. Substitution is done by the daemon, not by the DTO.
- **action-cases**: `ScriptAction` MUST have exactly two cases: `injectText` (a String) and `none`.
- **action-wire-shape**: `ScriptAction` MUST encode as an object with a `type` discriminator: `{"type":"inject","text":"..."}` for `injectText` and `{"type":"none"}` for `none`. The key spelling MUST NOT depend on the key strategy.
- **action-unknown-type**: Decoding an action whose `type` is neither `inject` nor `none` MUST throw a data-corrupted decoding error whose description is `Unknown action type '<type>'`.
- **action-inject-requires-text**: Decoding `{"type":"inject"}` without a `text` key MUST fail.

**OversightProviderSelection**

- **provider-sentinel-value**: `OversightProviderSelection.claudeCLISentinel` MUST be the String `"claude-cli"`.
- **provider-sentinel-meaning**: A stored `oversight_selected_config_id` equal to the sentinel MUST force the zero-config `claude -p` path; the empty string means inherit the AI Summaries selection; any other value is a configuration UUID. The app's provider picker and the daemon's oversight settings reader share the constant so they cannot drift.
- **provider-namespace**: `OversightProviderSelection` MUST be a caseless enum used only as a namespace.

## Appearance

Not applicable — this is a non-visual data transfer object, not a visual component.

## States

Not applicable — this is a non-visual data transfer object, not a visual component. The script's `enabled` flag is data, not a visual state.

## Accessibility

Not applicable — this is a non-visual data transfer object, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| oversight-script-dto-001 | predicate-wire-shape, predicate-op-key | Encode `.condition(field: .contextUsedPct, operation: .greaterOrEqual, value: "80")` | JSON object with `type` `condition`, `field` `context_used_pct`, `op` `gte`, `value` `80` |
| oversight-script-dto-002 | predicate-wire-shape, predicate-nesting | Encode `.all([.condition(...), .any([.condition(...)])])` then decode | Outer `type` `all` with a `predicates` array holding one condition object and one `any` object; decoded value equals the original |
| oversight-script-dto-003 | predicate-unknown-type | Decode `{"type":"xor","predicates":[]}` | Throws a data-corrupted error, description `Unknown predicate type 'xor'` |
| oversight-script-dto-004 | predicate-empty-group | Encode then decode `.all([])` | Round-trips to `.all([])` with no error (the save-time rejection is the daemon's and is not tested here) |
| oversight-script-dto-005 | action-wire-shape | Encode `.injectText("/compact")` and `.none` | `{"type":"inject","text":"/compact"}` and `{"type":"none"}` |
| oversight-script-dto-006 | action-unknown-type | Decode `{"type":"notify"}` | Throws a data-corrupted error, description `Unknown action type 'notify'` |
| oversight-script-dto-007 | action-inject-requires-text | Decode `{"type":"inject"}` | Throws a key-not-found error for `text` |
| oversight-script-dto-008 | script-wire-keys, trigger-wire-keys | Encode a script with builtIn true and nil llmConfirmation using the `StenographerWire` encoder | Keys include `built_in` and nest `trigger.predicate`; `llm_confirmation` is absent |
| oversight-script-dto-009 | trigger-wire-keys, confirmation-field-set | Decode a trigger body with `llm_confirmation` of `{"system_prompt":"p","act_keyword":"COMPACT"}` using the `StenographerWire` decoder | `llmConfirmation` equals `LLMConfirmation(systemPrompt: "p", actKeyword: "COMPACT")` |
| oversight-script-dto-010 | response-field-set | Decode a response body missing `reason_template` | Decoding throws; all three keys are required |
| oversight-script-dto-011 | field-is-numeric | Read `isNumeric` for every `ConditionField` case | True for the four numeric fields, false for the other four |
| oversight-script-dto-012 | field-set, operator-set, unknown-field-or-op | Decode field `cpu_pct` and operator `matches` | Both throw; the 8 and 7 known raw values decode |
| oversight-script-dto-013 | provider-sentinel-value | Read `OversightProviderSelection.claudeCLISentinel` | `"claude-cli"` |
| oversight-script-dto-014 | predicate-fixed-keys | Encode a condition with the camel-case key strategy and with the snake-case strategy | Identical bytes in both; the predicate keys do not change |
| oversight-script-dto-015 | script-init | Construct a script with id `compact`, builtIn true, version 1 and a response of kind `compact` | Every field reads back as given; two scripts with identical fields are equal and differing `enabled` makes them unequal |
| oversight-script-dto-016 | trigger-wire-keys, trigger-field-set | Decode a trigger body `{"predicate":{"type":"all","predicates":[]}}` with no `llm_confirmation` key using the `StenographerWire` decoder | Decoding succeeds and `llmConfirmation` is nil |

## Edge Cases

- **Null and empty input**: A nil `llmConfirmation` is valid (MUST encode with the key omitted). Empty strings are accepted by every String field at the DTO level; empty id, name, kind, inject text and act keyword are refused at save by the daemon's script store, not here. An empty group encodes and decodes without error (MUST).
- **Boundary values**: Predicate nesting has no depth limit in the type. `version` is any Int. A condition's `value` is always a String, including for numeric fields; whether it parses as a finite number is checked at save by the daemon.
- **Concurrent access**: The types are `Sendable` values with no shared mutable state, so they MAY be passed across threads and actors freely.
- **Error states**: Decoding failures are the standard `DecodingError` values: data-corrupted for an unknown `type` discriminator, key-not-found for a missing key, and a data-corrupted error for an unknown field or operator raw value. The DTO does not catch them.
- **Offline or disconnected state**: Not applicable: the types perform no I/O.
- **Forward compatibility**: A script containing a future action type or predicate type fails to decode as a whole under this version (MUST, per the unknown-type requirements); an older client cannot read a newer daemon's list of scripts that includes one.
- **Mutable value copies**: Fields are `var`, so an editor copies a script, edits the copy and sends it back; the type does not track dirtiness.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ScriptTrigger.llmConfirmation` | `LLMConfirmation?` | nil | Optional model confirmation; also gated by the daemon's `oversight_llm_enabled` setting. |
| `OversightProviderSelection.claudeCLISentinel` | String | `claude-cli` | Value of `oversight_selected_config_id` that selects the zero-config `claude -p` path. |
| wire coding strategy | snake_case keys | `StenographerWire` | Struct keys use it; predicate and action keys are fixed and ignore it. |

## Deep Linking

Not applicable: these types define no URL or deep link.

## Localization

Not applicable: the types hold no user-facing literal of their own; the strings a script carries (`name`, `reasonTemplate`, `systemPrompt`) are authored by the script's author and carried verbatim. The decoding error descriptions are developer-facing English.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no flag. The `oversight_llm_enabled` switch named in a doc comment is read by the daemon, not by these types.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: A script holds the author's rules and prompts; `systemPrompt` and `reasonTemplate` may contain user-written text, and `injectText` is text typed into a terminal session.
- **Storage**: None here; the daemon's script store persists scripts.
- **Transmission**: Over XPC and HTTP between app, CLI and daemon; the confirmation prompt is later sent to a model by the daemon.
- **Retention**: Not set by these types.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Plain Swift with no view code. A script editor binds to a copy of the `OversightScript` value; model the predicate tree as a recursive list view (a group row containing child rows) and switch over the three `ScriptPredicate` cases.
- **Compose**: Use a sealed interface for the predicate (`All`, `Any`, `Condition`) and for the action (`InjectText`, `None`) with `kotlinx.serialization` and a `classDiscriminator` of `type`, with the condition operation serialized as the key `op`. Give each sealed subclass a `@SerialName` equal to its discriminator (`all`, `any`, `condition` for the predicate; `inject`, `none` for the action), otherwise kotlinx.serialization writes the class name. Give each enum case a `@SerialName` equal to its raw value (for example `@SerialName("context_used_pct")` and `@SerialName("gte")`). Give `llmConfirmation` a default of null and set `explicitNulls = false` so a nil omits the key on encode and an absent key decodes as nil.
- **React/Web**: A TypeScript discriminated union on `type` for the predicate and the action, with snake_case struct keys (`built_in`, `llm_confirmation`, `reason_template`). Use string-literal unions for field and operator. A decoder must throw on an unknown `type` to match the source.
- **AppKit / UIKit**: Foundation-only; the predicate model is the NSPredicate-editor idiom (match all or any of field, operation, value) as a Codable value, with hand-written Codable on the two enums so their keys ignore the coder's key strategy.
- **WinUI 3**: Model the types as C# records. For the predicate and action, write a `JsonConverter<ScriptPredicate>` and `JsonConverter<ScriptAction>` for `System.Text.Json` that read the `type` property and dispatch to `All`, `Any`, `Condition` or `InjectText`, `None` record subclasses (or use `[JsonPolymorphic(TypeDiscriminatorPropertyName = "type")]` with `[JsonDerivedType]` attributes), throw `JsonException` on an unknown discriminator, and map the condition's operation property to the name `op` with `[JsonPropertyName("op")]`. Set `JsonNamingPolicy.SnakeCaseLower` on the options for the struct keys; because the converters write literal names, the enums and discriminators are unaffected by the policy. Serialize the field and operator enums with `JsonStringEnumConverter` and `[JsonStringEnumMemberName]` (or a custom converter) to get the raw values such as `context_used_pct` and `gte`. Mark `LlmConfirmation` nullable with `DefaultIgnoreCondition = WhenWritingNull`. For the editor, expose an `ObservableCollection` of child nodes per group in a `TreeView` with a `DataTemplateSelector`, and use `INotifyPropertyChanged` on a view-model wrapper because the records are immutable.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/OversightScriptDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `ScriptPredicate` and `ScriptAction` have hand-written Codable with fixed single-word keys, while the structs use the wire-wide snake_case strategy.
**Rationale**: The doc comment says the enums are strategy-invariant: a type discriminator with fixed keys survives any encoder configuration, so the daemon's storage encoding and the wire encoding of the same enum agree. The cost is a second spelling rule to port.
**Approved**: pending

**Decision**: The operation key on the wire is `op`, while the Swift case label is `operation`.
**Rationale**: Recorded as a naming divergence so a port uses the wire name; the source's `Keys` enum maps `operation` to `"op"`.
**Approved**: pending

**Decision**: Unknown `type` discriminators fail the whole decode instead of being skipped or kept as an unknown case.
**Rationale**: The source throws a data-corrupted error; the documentation states the discriminated format leaves room for new action types, but this version has no tolerant path, so a client older than the daemon cannot read a script list that holds a new action.
**Approved**: pending

**Decision**: A condition's `value` is a String for every field, numeric or not.
**Rationale**: One value slot keeps the editor and the wire simple; `isNumeric` tells the evaluator and the save-time validator which fields parse the string as a number.
**Approved**: pending

**Decision**: `OversightProviderSelection` lives in this file beside the script types although it concerns provider choice.
**Rationale**: The doc comment places it in the shared package so the app's picker and the daemon's settings reader use one constant. It is a one-constant namespace, not part of the script shape.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |

separation-of-concerns passes: the file declares shapes and their wire spelling only; evaluation, rendering, validation, storage and the LLM call live in the daemon. unit-test-coverage passes: `OversightScriptDTOConformanceTests` has one test for each of vectors 001 to 016, including the unknown-type errors, the `op` key spelling, the fixed-key independence from the key strategy and `OversightProviderSelection`. data-integrity passes because decoding is strict: an unknown discriminator or enum raw value fails loudly instead of producing a partial script.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (OversightScriptDTOConformanceTests.swift, 16 of 16 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Daemon-enforced and doc-comment-only meanings moved from Behavioral Requirements to a Documented semantics block in the Overview, case-name tables added for ConditionField and ConditionOperator, absent-key vector added, vectors 004/008/009 made precise, Compose SerialName guidance added, source path dropped, depends-on and related linked. |
