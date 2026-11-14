
**OversightScript**

- **script-conformances**: `OversightScript` MUST be a value type that is `Codable`, `Sendable` and `Equatable`, with mutable (`var`) fields.
- **script-field-set**: `OversightScript` MUST carry `id` (String), `name` (String), `enabled` (Bool), `builtIn` (Bool), `version` (Int), `trigger` (`ScriptTrigger`) and `response` (`ScriptResponse`).
- **script-init**: The public initializer MUST take all seven fields in that order with no defaults.
- **script-id-forms**: `id` MUST be a stable identifier: a slug for a built-in (example in source: `"compact"`) and a UUID string for a user script.
- **script-id-observer**: A script's `id` MUST double as the `observer` namespace of the findings it produces.
- **script-builtin-meaning**: `builtIn` MUST mean the script is shipped with the daemon: upgradeable, resettable and not deletable.
- **script-version-meaning**: `version` MUST be the version of the shipped definition, bumped in code when a built-in's definition improves so upgrades can refresh unmodified rows.
- **script-wire-keys**: `OversightScript` MUST encode through the stenographer-wide snake_case strategy, so its keys are `id`, `name`, `enabled`, `built_in`, `version`, `trigger` and `response`.

**ScriptTrigger and LLMConfirmation**

- **trigger-field-set**: `ScriptTrigger` MUST carry `predicate` (`ScriptPredicate`) and `llmConfirmation` (optional `LLMConfirmation`, default nil in the initializer).
- **trigger-wire-keys**: `ScriptTrigger` MUST use the keys `predicate` and `llm_confirmation`; a nil confirmation MUST be omitted on encode and MUST decode as nil when the key is absent.
- **trigger-llm-gating**: The type's documentation states that LLM confirmation is itself gated by the `oversight_llm_enabled` switch; the type MUST NOT carry or check that switch.
- **confirmation-field-set**: `LLMConfirmation` MUST carry `systemPrompt` (String) and `actKeyword` (String), both required, with wire keys `system_prompt` and `act_keyword`.
- **confirmation-reply-contract**: The documented reply contract of the confirmation MUST be one line: `"<ACTKEYWORD>: reason"` to act, or `"WAIT: reason"` to skip this tick. The DTO declares this contract; it does not parse replies.
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

- **field-set**: `ConditionField` MUST have eight cases with these wire raw values: `tokens_in_context`, `context_used_pct`, `context_window_size`, `last_event_type`, `idle_minutes`, `session_status`, `model`, `project_path`.
- **field-is-numeric**: `ConditionField.isNumeric` MUST be true for `tokensInContext`, `contextUsedPct`, `contextWindowSize` and `idleMinutes`, and false for `lastEventType`, `sessionStatus`, `model` and `projectPath`.
- **field-semantics**: Numeric fields compare the condition's value parsed as a number; string fields support `eq`, `ne` and `contains`. These are documented semantics for the evaluator, which fails closed (false) for an ordering operator on a string field and for `contains` on a numeric field; the DTO stores the value as a String.
- **field-derived-tokens**: `tokens_in_context` is documented as derived: `context_used_pct` times `context_window_size` divided by 100.
- **operator-set**: `ConditionOperator` MUST have seven cases with these wire raw values: `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `contains`.
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
- **action-future-cases**: The type-discriminated wire format is documented to accommodate future actions (notify, run-command) without a shape change; this version knows only `inject` and `none`.
- **action-inject-approval**: Per the doc comment, injected text is typed into the session's terminal and is human-approved through the existing safety gate; the DTO MUST NOT itself send text anywhere.

**OversightProviderSelection**

- **provider-sentinel-value**: `OversightProviderSelection.claudeCLISentinel` MUST be the String `"claude-cli"`.
- **provider-sentinel-meaning**: A stored `oversight_selected_config_id` equal to the sentinel MUST force the zero-config `claude -p` path; the empty string means inherit the AI Summaries selection; any other value is a configuration UUID. The app's provider picker and the daemon's oversight settings reader share the constant so they cannot drift.
- **provider-namespace**: `OversightProviderSelection` MUST be a caseless enum used only as a namespace.

