
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `selectedPluginKey` | `String` constant | `ai_plugin_id` | Settings-table key for the identifier of the plugin to complete with; empty or absent means the claude_cli path. |
| `plugin` | `String` | none (required) | Plugin identifier, usually reverse-DNS, for `fieldKey` and `secretFieldsKey`. |
| `field` | `String` | none (required) | Descriptor field key for `fieldKey`. |

The component defines no environment variable. Its keys are stored by the daemon in its settings table and Keychain namespace.

