import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKCore

/// Owns the chat object graph for one provider configuration — the live config
/// provider, the session, and the view model — so a host can drive the same
/// `AIChatViewModel` its transcript renders (e.g. to post model-change notices).
///
/// Named for the *provider configuration* it is pinned to, not the `ChatSession`
/// protocol. Values are read live on every turn, so an edit in the settings editor
/// (a new key, a new model) takes effect on the next message without rebuilding
/// this.
///
/// Two shapes, chosen by `toolSource`:
/// - **No tools** — the plugin backend bridged onto `ChatSession` via
///   `ChatBackendSession`, a plain conversation (the settings panel's Test Chat).
/// - **Tools** — a `LocalChatSession` over `PromptedToolCallingPlugin`, so any
///   provider, including one with no native tool calling, can reach the host's
///   tools (the AI Chat window, which carries the app's browser tools).
@MainActor
public final class AIProviderChatSession: ObservableObject {
    let provider: SingleConfigurationChatConfigProvider
    /// Kept alive here: `AIPluginChatBackend` holds `provider` weakly. Nil on the
    /// tool path, which reads `provider` itself.
    let backend: AIPluginChatBackend?
    public let viewModel: AIChatViewModel

    public init(configuration: AIProviderConfiguration,
                pluginManager: AIPluginManager,
                toolSource: (any ChatToolSource)? = nil) {
        let provider = SingleConfigurationChatConfigProvider(
            configuration: configuration, pluginManager: pluginManager)
        self.provider = provider
        guard let toolSource else {
            let backend = AIPluginChatBackend(pluginManager: pluginManager, configProvider: provider)
            self.backend = backend
            self.viewModel = AIChatViewModel(session: ChatBackendSession(backend: backend))
            return
        }
        self.backend = nil
        let session = LocalChatSession(
            resolvePlugin: { [weak provider] in
                try await MainActor.run {
                    guard let identifier = provider?.selectedPluginIdentifier, !identifier.isEmpty else { return nil }
                    // Thrown, not swallowed: the session reports why the chosen
                    // connection's plugin would not load.
                    let plugin = try pluginManager.loadPlugin(identifier: identifier)
                    return PromptedToolCallingPlugin(wrapping: plugin)
                }
            },
            makeContext: { [weak provider] history in
                await MainActor.run {
                    let model = provider?.selectedModel ?? ""
                    var values = provider?.pluginConfigValues ?? [:]
                    values["model"] = model
                    return AIChatContext(messages: history, model: model, config: AIPluginConfig(values))
                }
            },
            toolSource: toolSource)
        self.viewModel = AIChatViewModel(session: session)
    }
}
