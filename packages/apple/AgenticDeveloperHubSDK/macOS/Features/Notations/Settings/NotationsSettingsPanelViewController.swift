import AppKit
import AgenticDeveloperHubSDKCore

/// Settings ▸ Workspace ▸ Notations: how long archived notations are kept.
@MainActor
public final class NotationsSettingsPanelViewController: ComposableSettings.SettingsPanelViewController {

    public init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Notations",
            icon: NSImage(systemSymbolName: "note.text", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["notations", "branch notes", "archived", "retention", "delete", "days"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Notations",
                  body: "A notation is the notes of one branch of one project, written in the Notations pane of a "
                      + "Development Project window and listed in Notes ▸ Notations."),
            .init(title: "Archiving",
                  body: "A notation is archived when its branch is deleted, or when the branch's commits have "
                      + "been merged into the default branch. A branch with no commits of its own stays active."),
            .init(title: "Delete archived notations after",
                  body: "An archived notation is deleted once it has been archived for this many days and no "
                      + "branch with its name and fork point exists, locally or on origin. Until then it stays "
                      + "in the Archived list, where it can also be deleted by hand.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let range = NotationsRetention.range
        let group = ComposableSettings.GroupView(withTitle: "Archived Notations")
        group.addSettingSubview(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Delete archived notations after (days)",
                setting: UserSettings.notationsArchivedRetentionDays,
                minValue: range.lowerBound,
                maxValue: range.upperBound)))
        addGroup(group)
    }
}
