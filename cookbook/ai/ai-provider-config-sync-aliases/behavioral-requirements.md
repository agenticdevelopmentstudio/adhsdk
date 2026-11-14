
- **sync-alias**: The plugin layer MUST expose `AIProviderConfigSync` as a public type alias for the Core framework's `AIProviderConfigSync`.
- **resolved-config-alias**: The plugin layer MUST expose `ResolvedProviderConfig` as a public type alias for the Core framework's `ResolvedProviderConfig`.
- **alias-identity**: A value created through either alias MUST be interchangeable, with no conversion, with a value of the Core type, because an alias is another name for one type and not a new type.
- **import-compatibility**: A call site that imports only the plugin layer MUST be able to name both types, construct them with their Core initializers and encode or decode them, so call sites written before the move compile unchanged.
- **core-ownership**: The wire shape MUST be defined once, in the Core framework, so an HTTP client can send it without importing the plugin layer; the plugin layer MUST NOT redeclare either type.
- **inherited-contract**: Every field, default and conformance (`Codable`, `Sendable`, `Equatable`) of the aliased types is the Core type's: `AIProviderConfigSync` carries `enabled`, `selectedConfigId`, `configs` and `removedConfigIds` (optional, default nil), and `ResolvedProviderConfig` carries `id`, `name`, `pluginIdentifier`, `templateId`, `model`, `values` and `secrets`.
- **no-behavior**: The file MUST contain no function, property or logic; it declares only the two aliases and imports the Core framework.
- **no-error-domain**: The component MUST NOT define or throw an error; decode errors come from the Core types' synthesized decoding.

