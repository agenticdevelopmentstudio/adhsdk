
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `appName` | String | none (required) | Written on the `Host:` line of `host_app_info` |
| `appVersion` | String | none (required) | Written on the `Version:` line of `host_app_info` |
| `pluginNames` | Array of String | empty | Written on the `Plugins:` line, joined with a comma and a space, or `(none)` when empty |
| `openChatWindow` | main-actor sendable closure returning nothing | does nothing | Invoked once per `host_open_chat_window` call |

