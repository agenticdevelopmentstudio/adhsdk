import AppKit

import AgenticToolkitCore
import AIPluginKit

/// The Coding Partner's settings: one top-level topic whose sub-topics (General, Model, Permissions, Code
/// Review Job, Notifications) are listed down the left and shown on the right, the way Themes is.
@MainActor
public final class PartnerSettingsPanelViewController: ComposableSettings.SettingsPanelSplitViewController {

    private let controller: PartnerController
    private let pluginManager: AIPluginManager?
    private let projects: @MainActor () -> [PartnerToolSource.Project]
    private let settings: SettingsStore

    public init(controller: PartnerController, pluginManager: AIPluginManager?,
                projects: @escaping @MainActor () -> [PartnerToolSource.Project] = { [] },
                settings: SettingsStore = UserSettings.shared) {
        self.controller = controller
        self.pluginManager = pluginManager
        self.projects = projects
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Coding Partner",
            icon: NSImage(systemSymbolName: "checklist", accessibilityDescription: nil)))
        sidebarTitle = "Coding Partner"
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] { ["partner", "coding partner"] }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Reading the jobs seeds the built-in one, so the Code Review Job panel has something to show on a
        // fresh install.
        _ = controller.jobs()
        let editor = PartnerJobsEditorModel(
            store: controller.store, guidelines: PartnerGuidelinesInstaller(paths: controller.paths))
        setPanels([
            PartnerGeneralSettingsViewController(settings: settings),
            PartnerModelSettingsViewController(pluginManager: pluginManager, settings: settings),
            PartnerPermissionsSettingsViewController(settings: settings),
            PartnerCodeReviewJobSettingsViewController(
                model: editor, store: controller.store, projects: projects, settings: settings),
            PartnerNotificationsSettingsViewController(settings: settings)
        ])
        selectPanel(at: 0)
    }
}
