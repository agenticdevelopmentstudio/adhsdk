
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plugin` (parameter of `init(wrapping:)`) | `any AIPlugin` | none — required | The plugin whose request building, decoder, validation and error description are wrapped. |
| `AIPluginConfig.builtInToolsKey` | config key, value `builtInTools` | set to `none` when tools are described | Switches the wrapped plugin's own built-in tools off for the turn. |
| `openTag`, `closeTag` | `String` constants | `<tool_call>` and `</tool_call>` | The delimiters of a call block. |
| Call id prefix | constant inside the source | `prompted-` plus a counter from 1 | The ids given to lifted calls. |

