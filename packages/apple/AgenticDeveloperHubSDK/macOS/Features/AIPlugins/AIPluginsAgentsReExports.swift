// The headless AI provider stack (configuration store, resolver, shared secrets,
// `LocalChatSession`, `AIPluginChatBackend`, the MCP tool source) moved down to
// AgenticDeveloperHubSDKAgents so a daemon can run chats without AppKit.
// Re-exporting it here keeps every caller that reached those types through
// `AgenticDeveloperHubSDKMacOS` compiling unchanged.
@_exported import AgenticDeveloperHubSDKAgents
