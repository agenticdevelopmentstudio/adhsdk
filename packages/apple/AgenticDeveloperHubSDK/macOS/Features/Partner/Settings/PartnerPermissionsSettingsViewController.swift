import AppKit

import AgenticDeveloperHubSDKCore

/// Permissions: the permission mode, and the tools the partner may use without asking.
@MainActor
public final class PartnerPermissionsSettingsViewController: ComposableSettings.SettingsPanelViewController {

    private static let toolColumn = "tool"
    private static let newToolName = "NewTool"

    private let settings: SettingsStore
    /// Internal for tests.
    let toolsCard = ComposableSettings.EditableTableCard(
        title: "Allowed Tools",
        columns: [.init(id: PartnerPermissionsSettingsViewController.toolColumn, title: "Tool", width: 420,
                        kind: .text(editable: true))],
        emptyMessage: "No allowed tools yet. Add one with +.",
        visibleRows: 8,
        accessibilityPrefix: "settings.partner.tools")

    public init(settings: SettingsStore = UserSettings.shared) {
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Permissions", icon: NSImage(systemSymbolName: "lock.shield", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["permission", "mode", "allowed tools", "allowedTools", "dontAsk", "bypassPermissions"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Allowed tools",
                  body: "One claude --allowedTools entry per row, such as Read or Bash(git log *). "
                      + "Changes apply the next time the partner starts.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let settings = self.settings

        let mode = ComposableSettings.GroupView(withTitle: "Permission Mode")
        let modes = ["default", "acceptEdits", "dontAsk", "bypassPermissions"]
        mode.addSettingSubview(ComposableSettings.PopupMenuChoiceView(
            viewModel: ComposableSettings.ChoiceViewModel<String>(
                title: "Permission mode",
                choices: modes.map { .init(label: $0, value: $0) },
                get: { settings.get(UserSettings.partnerPermissionMode) },
                set: { settings.set($0, for: UserSettings.partnerPermissionMode) },
                explanation: "dontAsk refuses anything not in the allowed tools instead of asking.")))
        addGroup(mode)

        toolsCard.onAdd = { [weak self] in self?.addTool() }
        toolsCard.onRemove = { [weak self] rowID in self?.removeTool(rowID: rowID) }
        toolsCard.onEdit = { [weak self] rowID, _, text in self?.editTool(rowID: rowID, to: text) }
        addGroup(toolsCard)
        reloadRows()
    }

    // MARK: - Tools

    /// Rows are identified by position: the same entry twice is two rows, and a rename keeps its row.
    private func reloadRows() {
        let rows = settings.get(UserSettings.partnerAllowedToolsList).enumerated().map { index, tool in
            ComposableSettings.EditableTableRow(
                id: String(index), cells: [Self.toolColumn: .text(tool)])
        }
        toolsCard.setRows(rows)
    }

    func addTool() {
        var tools = settings.get(UserSettings.partnerAllowedToolsList)
        tools.append(Self.newToolName)
        settings.set(tools, for: UserSettings.partnerAllowedToolsList)
        reloadRows()
        _ = toolsCard.selectRow(id: String(tools.count - 1))
    }

    func removeTool(rowID: String) {
        var tools = settings.get(UserSettings.partnerAllowedToolsList)
        guard let index = Int(rowID), tools.indices.contains(index) else { return }
        tools.remove(at: index)
        settings.set(tools, for: UserSettings.partnerAllowedToolsList)
        reloadRows()
    }

    /// An emptied cell removes its entry: an empty tool name means nothing to claude.
    func editTool(rowID: String, to text: String) {
        var tools = settings.get(UserSettings.partnerAllowedToolsList)
        guard let index = Int(rowID), tools.indices.contains(index) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != tools[index] else { return }
        if trimmed.isEmpty { tools.remove(at: index) } else { tools[index] = trimmed }
        settings.set(tools, for: UserSettings.partnerAllowedToolsList)
        reloadRows()
    }
}
