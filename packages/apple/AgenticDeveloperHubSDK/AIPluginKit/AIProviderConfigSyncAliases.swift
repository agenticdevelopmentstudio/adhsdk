import AgenticDeveloperHubSDKCore

// The AI provider wire contract moved down to Core (`Core/Stenographer/`) so an
// HTTP client can send it without importing the plugin layer. These aliases keep
// every existing `import AIPluginKit` call site compiling unchanged.

/// See ``AgenticDeveloperHubSDKCore/AIProviderConfigSync``.
public typealias AIProviderConfigSync = AgenticDeveloperHubSDKCore.AIProviderConfigSync
/// See ``AgenticDeveloperHubSDKCore/ResolvedProviderConfig``.
public typealias ResolvedProviderConfig = AgenticDeveloperHubSDKCore.ResolvedProviderConfig
