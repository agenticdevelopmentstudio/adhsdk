
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allowUnclassified` (parameter of `ModelRequestKindDTO.isValidId`) | `Bool` | `false` | Whether the reserved id `unclassified` counts as valid. |
| `ModelRouteConditionsDTO.init` parameters | optional fields | all nil | Unset conditions are ignored. |
| `ModelRouterPreferencesDTO.init` parameters | optional fields | all nil | A nil field leaves the stored value untouched. |
| `ModelRouterProviderDTO.init` `models` | `[String]?` | nil | The provider's catalog of models, when the daemon sends one. |
| `ModelRouterStatusDTO.init` optional parameters | optional fields | all nil | `templates`, `preferred`, `skipped`, `clientVersion`, `inUse`, `inUseIsFallback`. |
| `ModelRouterTemplateDTO.init` `format` | `Int` | `3` | The template's format number. |
| `ModelRouterTemplateDTO.init` `tiers` | `[ModelTierDTO]` | `defaultTiers` | Light, Standard, Heavy. |
| `ModelRouterTemplateDTO.init` `requestTiers` | `[String: String]?` | `defaultRequestTiers(for: requests)` | Request id to tier id. |
| `ModelRouterTemplateDTO.init` `tierTargets` | `[String: String]` | `defaultTierTargets` | Tier id to target text. |
| `select` `preferred` | `Set<String>` | none (required) | Template ids the user prefers; first in the selection order. |
| `select` `version` | `ClaudeCodeVersion?` | none (required) | The client's version; nil selects the latest-reaching template as a fallback. |
| `problem` `others` | `[ModelRouterTemplateDTO]` | none (required) | Templates whose names a new name must not repeat. |
| Encoder / decoder key strategy | caller-supplied | property names | The wire spelling of every DTO key; the template accepts both snake and converted camel keys and always writes snake keys. |
| Model id length cap (`ModelTierTarget`) | constant | 200 characters | Longest model id a `provider:` target accepts. |
| `maxNameLength` | constant | 80 | Longest template, tier or request name. |
| `maxMatchTextLength` | constant | 400 | Longest `system` or `message` match text. |
| `builtInPrefix` | constant | `builtin.` | Id prefix of a built-in template. |

No environment variables, settings keys or injected dependencies are read. `removalProblem` reads the current locale through the system list formatter.

