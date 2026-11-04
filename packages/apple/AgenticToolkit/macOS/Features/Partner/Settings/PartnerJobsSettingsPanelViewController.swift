import AppKit

import AgenticToolkitCore

/// Jobs: the partner's jobs listed down the left and the selected one's settings on the right, the way
/// Themes lists its themes. Code Review is the only job so far.
@MainActor
public final class PartnerJobsSettingsPanelViewController: ComposableSettings.SettingsPanelSplitViewController {

    private let controller: PartnerController
    private let projects: @MainActor () -> [PartnerToolSource.Project]
    private let settings: SettingsStore

    public init(controller: PartnerController,
                projects: @escaping @MainActor () -> [PartnerToolSource.Project] = { [] },
                settings: SettingsStore = UserSettings.shared) {
        self.controller = controller
        self.projects = projects
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Jobs", icon: NSImage(systemSymbolName: "list.bullet.rectangle", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] { ["jobs", "partner", "coding partner"] }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Reading the jobs seeds the built-in one, so Code Review has something to show on a fresh install.
        _ = controller.jobs()
        let editor = PartnerJobsEditorModel(
            store: controller.store, guidelines: PartnerGuidelinesInstaller(paths: controller.paths))
        setPanels([
            PartnerCodeReviewJobSettingsViewController(
                model: editor, store: controller.store, projects: projects, settings: settings)
        ])
        selectPanel(at: 0)
    }
}
