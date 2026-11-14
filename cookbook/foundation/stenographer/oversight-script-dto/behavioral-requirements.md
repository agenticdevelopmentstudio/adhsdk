
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

