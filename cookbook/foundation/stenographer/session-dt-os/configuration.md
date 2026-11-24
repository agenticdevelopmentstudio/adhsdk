
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `SessionDTO` optional initializer parameters | String and Bool | `""` and false | Eight fields default so a caller can build a session from the twelve required values. |
| `SessionEventDTO.gitBranch` | String | `""` | Defaults in the initializer only. |
| `HealthDTO` optional initializer parameters | Int and String optionals | nil | Six fields default to nil. |
| wire coding strategy | snake_case keys | `StenographerWire` | Callers use the shared encoder and decoder. |

