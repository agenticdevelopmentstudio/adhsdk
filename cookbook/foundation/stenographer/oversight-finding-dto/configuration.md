
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| twelve initializer parameters | Int and String | none (all required) | The caller supplies every field; there are no defaults. |
| wire coding strategy | snake_case keys | `StenographerWire` | Callers encode and decode with the shared wire encoder and decoder so the spelling cannot drift. |

