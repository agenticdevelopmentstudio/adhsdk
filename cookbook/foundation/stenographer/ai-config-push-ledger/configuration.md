
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| key | `String` | none, required | The `UserDefaults` key that holds this host's last-pushed ids; each host uses its own (the HTTP push in `StenographerAIConfigPush` uses `stenographer.aiConfigPush.http.lastPushedIds`). |
| defaults | `UserDefaults` | `.standard` | The store the ledger reads and writes; injectable for tests. |

