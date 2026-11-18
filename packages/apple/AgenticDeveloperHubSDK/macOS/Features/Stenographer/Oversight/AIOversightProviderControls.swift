import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// The oversight flavor of the toolkit's ``DaemonProviderPickerView``, its model
/// row, and the titles the oversight UI uses in both the settings panels and the
/// AI Oversight window's gear dialog.
///
/// Oversight has an AI configuration of its own: its selection leads with the
/// Claude CLI sentinel and otherwise names a provider configuration, and its
/// model (``UserSettings/stenographerAIOversightModel``) overrides that
/// configuration's model for oversight alone. Pushing to the daemon is owned by
/// `StenographerOversightPrefsPush`.
@MainActor
enum AIOversightProviderControls {

    static let enableToggleTitle = "Watch live sessions"
    static let llmToggleTitle = "Use AI judgment"
    static let claudeCLILabel = "Default (Claude CLI)"
    /// Shared with the daemon's wire contract so the two can't drift.
    static let claudeCLIValue = OversightProviderSelection.claudeCLISentinel

    /// A picker bound to the oversight prefs. The caller must retain it: it owns
    /// the setting observer that follows the selection, and it reloads the daemon's
    /// configurations each time its menu is about to open.
    static func makePicker(service: any StenographerDaemonService) -> DaemonProviderPickerView {
        DaemonProviderPickerView(
            service: service,
            selectedSetting: UserSettings.stenographerAIOversightProviderConfigId,
            leadingChoices: [.init(label: claudeCLILabel, value: claudeCLIValue)]
        )
    }

    /// The oversight model override, empty for the configuration's own model.
    static func makeModelField() -> ComposableSettings.TextEditView {
        let model = ComposableSettings.TextEditView(with: ComposableSettings.ViewModel<String>(
            title: "Model",
            setting: UserSettings.stenographerAIOversightModel
        ))
        model.textField.placeholderString = "Provider default"
        return model
    }

    /// Replaces a stored "inherit AI Summaries" selection ("") with the choice it
    /// resolved to — Sessions' summaries provider, or the Claude CLI — so oversight
    /// keeps the provider it was using once the inherit choice is gone from the
    /// picker. Idempotent: a concrete selection is left alone.
    static func adoptOwnSelection() {
        let setting = UserSettings.stenographerAIOversightProviderConfigId
        guard setting.value.isEmpty else { return }
        let summaries = UserSettings.stenographerAISummariesProviderConfigId.value
        setting.value = summaries.isEmpty ? claudeCLIValue : summaries
    }
}
