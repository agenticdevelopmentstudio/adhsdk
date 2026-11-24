import AppKit

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// Settings panel for how a file browser pane behaves. It heads the File
/// Browser section, above Excluded.
///
/// Every change is written straight to its setting, and every file browser
/// observes it, so the panes on screen follow the checkbox at once.
@MainActor
public final class FileBrowserGeneralSettingsViewController: ComposableSettings.SettingsPanelViewController {

    public init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "General",
            icon: NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The sidebar's search only reads the controls of a panel already opened,
    /// so this panel names what it is about for a search made before that.
    public override var searchKeywords: [String] {
        ["file browser", "width", "adjust", "resize", "content", "automatic"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Automatically Adjust Width to Content",
                body: "With this on, a File Browser pane keeps itself as wide as its widest visible "
                    + "row (the indent, icon, name and git badge) plus a margin, and re-measures "
                    + "whenever a folder is expanded or collapsed, the tree reloads, the filter "
                    + "changes or the font changes. It never shrinks below the pane's minimum width. "
                    + "Off, the pane keeps the width you drag it to."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Width")
        let checkbox = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Automatically adjust width to content",
            setting: UserSettings.fileBrowserAdjustsWidthToContent
        ))
        _ = checkbox.accessibilityID("settings.fileBrowser.adjusts-width-to-content")
        group.addSettingSubview(checkbox)
        addGroup(group)
    }
}
