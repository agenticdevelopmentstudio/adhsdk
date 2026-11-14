
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stateStore` | `PaneStateStore` | required | Where the pane's four choices are kept |
| `pluginManager` | `AIPluginManager` | required | Loads provider plugins and resolves templates |
| `browserTools` | `(any ChatToolSource)?` | `nil` | Tools for driving the Browser pane, offered beside the terminal tools |
| `paneID` | `UUID?` | `nil` | Named as the caller of every tool call |
| `connected` (state key) | `1` or absent | absent (off) | Connect to the tab's Terminal Chat |
| `configurationID` (state key) | provider id string | absent | Chosen LLM provider configuration |
| `model` (state key) | string | absent | Model for this pane; absent uses the provider's |
| `persona` (state key) | string | absent (default persona) | The persona's instructions |

