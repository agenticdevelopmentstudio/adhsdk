import AppKit
import AgenticDeveloperHubSDKCore

/// Titles and the provider picker the summaries UI uses in more than one place
/// (the AI Summaries settings pane and the Sessions window's gear dialog). Both
/// edit the same prefs; `StenographerSummaryPrefsPush` pushes them to the daemon.
@MainActor
enum AISummariesPluginControls {

    static let enableToggleTitle = "Generate AI session summaries"
    static let defaultProviderLabel = "Default (Claude CLI)"
    /// Empty selection == the daemon's zero-config claude_cli path.
    static let defaultProviderValue = ""

    /// A group holding the summaries on/off switch alone, for the panels that
    /// offer it beside their own settings (Coding Projects, Sessions,
    /// Conversations). Every copy writes the one setting.
    static func makeSummariesGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "AI Summaries")
        group.addSettingSubview(ComposableSettings.CheckboxView(
            with: ComposableSettings.ViewModel<Bool>(
                title: enableToggleTitle,
                setting: UserSettings.stenographerAISummariesEnabled
            )
        ))
        return group
    }

    /// A picker bound to the summaries selection. The caller must retain it.
    static func makePicker(service: any StenographerDaemonService) -> DaemonProviderPickerView {
        DaemonProviderPickerView(
            service: service,
            selectedSetting: UserSettings.stenographerAISummariesProviderConfigId,
            leadingChoices: [.init(label: defaultProviderLabel, value: defaultProviderValue)]
        )
    }
}
