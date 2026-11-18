import AppKit
import AgenticDeveloperHubSDKCore

/// Titles and the provider picker the summaries UI uses in more than one place
/// (each feature's AI Summaries settings pane and the Sessions window's gear
/// dialog); `StenographerSummaryPrefsPush` pushes what they edit to the daemon.
@MainActor
enum AISummariesPluginControls {

    static let enableToggleTitle = "Generate AI summaries"
    static let defaultProviderLabel = "Default (Claude CLI)"
    /// Empty selection == the daemon's zero-config claude_cli path.
    static let defaultProviderValue = ""

    /// A picker bound to one feature's summaries selection. The caller must retain it.
    static func makePicker(
        service: any StenographerDaemonService,
        settings: SummaryFeatureSettings = .for(.sessions)
    ) -> DaemonProviderPickerView {
        DaemonProviderPickerView(
            service: service,
            selectedSetting: settings.providerConfigId,
            leadingChoices: [.init(label: defaultProviderLabel, value: defaultProviderValue)]
        )
    }
}
