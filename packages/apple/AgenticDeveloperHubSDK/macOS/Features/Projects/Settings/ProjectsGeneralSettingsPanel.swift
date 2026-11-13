import AppKit

import AgenticDeveloperHubSDKCore

/// How a Coding Project window behaves: how a pane shows it is the active one,
/// and whether its branch cards get AI summaries. The General row of the
/// Coding Projects topic; where projects come from is
/// `ProjectsSettingsPanelViewController`, its Directories row.
@MainActor
public final class ProjectsGeneralSettingsPanel: ComposableSettings.SettingsPanelViewController {

    public init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "General",
            icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["project", "active pane", "outline", "highlight", "follows mouse", "summary", "summaries"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Active Pane",
                body: "A Coding Project window is split into panes, and one of them is the one you "
                    + "are working in. With this on, that pane is drawn with a border in a "
                    + "tone one step lighter than the others — enough to find it, not enough "
                    + "to compete with what is inside it."
            ),
            .init(
                title: "Active Pane Follows the Mouse",
                body: "With this on, the pane under the pointer becomes the active one as "
                    + "soon as the pointer is over it, and the keyboard goes with it — so a "
                    + "window that is already in front can be typed into without clicking "
                    + "first. Only the front window follows the pointer: passing over a "
                    + "window behind it changes nothing, because that window is not the one "
                    + "taking the keys. Off, the active pane is the one you last clicked in."
            ),
            .init(
                title: "Themes Override This",
                body: "A theme can carry its own answer for whether the active pane is "
                    + "outlined, and in what color, under the theme's Project topic in Theme "
                    + "settings. When it does, the theme wins over the switch here."
            ),
            .init(
                title: "AI Summaries",
                body: "The same switch as Settings › AI › Summaries: with it on, the daemon "
                    + "writes a short summary of each Claude Code session, and a branch card "
                    + "shows the summary of the session working in its checkout."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(createActivePaneGroup())
        addGroup(AISummariesPluginControls.makeSummariesGroup())
    }

    private func createActivePaneGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Active Pane")
        group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Outline the active pane",
            setting: UserSettings.highlightActivePane
        )))
        group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Active pane follows the mouse",
            setting: UserSettings.activePaneFollowsMouse
        )))
        return group
    }
}
