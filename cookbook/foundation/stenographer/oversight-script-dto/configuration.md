
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ScriptTrigger.llmConfirmation` | `LLMConfirmation?` | nil | Optional model confirmation; also gated by the daemon's `oversight_llm_enabled` setting. |
| `OversightProviderSelection.claudeCLISentinel` | String | `claude-cli` | Value of `oversight_selected_config_id` that selects the zero-config `claude -p` path. |
| wire coding strategy | snake_case keys | `StenographerWire` | Struct keys use it; predicate and action keys are fixed and ignore it. |

