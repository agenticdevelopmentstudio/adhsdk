
`AIProviderConfigSync` is the app-to-daemon wire contract for AI provider configuration. It replaces the old flattened untyped dictionary push and carries the whole set of configurations, so the daemon mirrors the full registry keyed by configuration identity rather than a single plugin-keyed slot. `ResolvedProviderConfig` is one configuration on the wire: its identity plus the resolved value bag, split into non-secret `values` and `secrets`.

The summaries switch and the summaries configuration are not part of this contract: `POST /preferences/summaries` is their only writer. The two fields that once carried them, `enabled` and `selectedConfigId`, stay for wire compatibility and the daemon ignores them.

Both types are `Codable`, `Sendable` and `Equatable` structs with `var` properties. They live in Core so an HTTP client can send them without importing the plugin layer; `AIPluginKit` re-exports them as type aliases so existing `import AIPluginKit` call sites compile unchanged.

