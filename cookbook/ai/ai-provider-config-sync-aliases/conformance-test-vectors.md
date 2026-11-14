
The plugin layer's own test target imports only the plugin layer and exercises the aliases (`AIProviderConfigSyncTests`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-provider-config-sync-aliases-001 | import-compatibility, sync-alias, resolved-config-alias | Build a sync envelope with `enabled: true`, a selected id and one resolved configuration ("Groq", "com.x.openai-compatible", "custom", model "llama-3.3-70b", values with a base URL, secrets with an API key), encode it and decode it again (`testRoundTrip`) | The decoded value equals the original |
| ai-provider-config-sync-aliases-002 | inherited-contract | Decode `{"enabled":false,"configs":[]}` through the alias (`testDecodesMissingSelectionAsNil`) | `selectedConfigId` is absent, `enabled` is false, `configs` is empty |
| ai-provider-config-sync-aliases-003 | inherited-contract | Construct a sync envelope without passing `removedConfigIds` | `removedConfigIds` is nil |
| ai-provider-config-sync-aliases-004 | alias-identity | Pass a value built through the alias to the Core HTTP client's AI preferences call, which takes the Core type | The call compiles and accepts the value with no conversion |
| ai-provider-config-sync-aliases-005 | inherited-contract | Decode `{"enabled":true,"configs":[],"removedConfigIds":["11111111-2222-3333-4444-555555555555"]}` | `removedConfigIds` holds that one identifier |
| ai-provider-config-sync-aliases-006 | core-ownership | Search the plugin layer for a declaration of a type named `AIProviderConfigSync` or `ResolvedProviderConfig` | Only the two aliases exist there; the struct declarations are in the Core framework |

