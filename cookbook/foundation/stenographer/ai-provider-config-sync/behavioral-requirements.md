
- **sync-fields**: `AIProviderConfigSync` MUST carry `enabled` (`Bool`), `selectedConfigId` (`UUID?`), `configs` (`[ResolvedProviderConfig]`) and `removedConfigIds` (`[UUID]?`).
- **enabled-ignored**: `enabled` is kept for wire compatibility only: the daemon ignores it, and whether summaries run is set through `POST /preferences/summaries`.
- **selected-ignored**: `selectedConfigId` is kept for wire compatibility only: the daemon ignores it, and the summaries configuration is set through `POST /preferences/summaries`.
- **whole-registry**: `configs` MUST hold every configured provider, fully resolved (values and secrets).
- **nil-removed-full-sync**: When `removedConfigIds` is nil or absent, as an older host sends, `configs` MUST be the complete registry and the daemon deletes every stored configuration it lists no longer.
- **non-nil-removed-partial-sync**: When `removedConfigIds` is non-nil, the sync is partial: the daemon upserts `configs`, deletes exactly the listed ids and leaves every other stored configuration alone.
- **empty-removed-is-partial**: An empty non-nil `removedConfigIds` MUST count as a partial sync that deletes nothing, not as a full sync.
- **sync-initializer**: The initializer MUST take `enabled`, `selectedConfigId` and `configs` without defaults, and `removedConfigIds` defaulting to nil.
- **sync-decode-tolerance**: A payload with no `removedConfigIds` key MUST decode with that field nil, and a payload with no `selectedConfigId` key MUST decode with that field nil.
- **sync-decode-required**: A payload missing `enabled` or `configs` MUST fail to decode, because the synthesized conformance requires non-optional keys.
- **config-fields**: `ResolvedProviderConfig` MUST carry `id` (`UUID`), `name`, `pluginIdentifier`, `templateId`, `model` (all `String`), `values` and `secrets` (both `[String: String]`).
- **config-initializer**: The `ResolvedProviderConfig` initializer MUST take every field with no defaults.
- **values-secrets-split**: Non-secret entries MUST travel in `values` and credentials in `secrets`.
- **empty-secret-clears**: An empty secret value MUST mean "clear this credential".
- **config-keyed-by-id**: The daemon persists each configuration under `AIProviderConfigKeys` keyed by `id`, so `id` MUST be the configuration's stable identity across pushes.
- **round-trip**: Encoding then decoding a sync MUST produce an equal value, including `selectedConfigId`, each configuration and its `values` and `secrets`.
- **aliases**: `AIPluginKit` MUST re-export `AIProviderConfigSync` and `ResolvedProviderConfig` as type aliases of the Core types.

