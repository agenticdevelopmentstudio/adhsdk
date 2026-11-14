
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

