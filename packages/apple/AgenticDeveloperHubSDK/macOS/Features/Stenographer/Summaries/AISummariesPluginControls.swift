import AppKit
import AgenticDeveloperHubSDKCore
import AIPluginKit

/// Titles and the provider-and-model picker the summaries UI uses in more than
/// one place (each feature's AI Summaries settings pane and the Sessions
/// window's gear dialog); `StenographerSummaryPrefsPush` pushes what they edit
/// to the daemon.
@MainActor
enum AISummariesPluginControls {

    static let enableToggleTitle = "Generate AI summaries"
    static let defaultProviderLabel = "Default (Claude CLI)"
    /// Empty selection == the daemon's zero-config claude_cli path.
    static let defaultProviderValue = ""

    /// A picker bound to one feature's summaries provider and model, over the
    /// daemon's provider list. The caller must retain it.
    static func makePicker(
        service: any StenographerDaemonService,
        pluginManager: AIPluginManager? = nil,
        settings: SummaryFeatureSettings = .for(.sessions)
    ) -> ProviderModelPickerView {
        ProviderModelPickerView(
            source: DaemonProviderRegistrySource(service: service, pluginManager: pluginManager),
            selectedSetting: settings.providerConfigId,
            leadingChoices: [.init(label: defaultProviderLabel, value: defaultProviderValue)],
            // One model for the feature, whichever provider runs it.
            modelSetting: { _ in settings.model }
        )
    }
}
