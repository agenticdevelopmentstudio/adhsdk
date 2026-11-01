import AppKit

import AgenticToolkitCore

/// General: whether the partner runs, which claude it runs, and how its process and window behave.
@MainActor
public final class PartnerGeneralSettingsViewController: ComposableSettings.SettingsPanelViewController {

    private let settings: SettingsStore
    private let claudeLine = NSTextField(labelWithString: "Looking for claude...")

    public init(settings: SettingsStore = UserSettings.shared) {
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "General", icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["partner", "coding partner", "claude", "session", "timeout", "idle", "always on top", "notifications pane"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Coding Partner",
                  body: "The partner is one long-running Claude Code process that watches your sessions and "
                      + "raises items for you. Changes to the model, permission mode, allowed tools and "
                      + "timeouts apply the next time the partner starts.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let settings = self.settings

        let run = ComposableSettings.GroupView(withTitle: "Partner")
        let enabled = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Run the coding partner",
            get: { settings.get(UserSettings.partnerEnabled) },
            set: { settings.set($0, for: UserSettings.partnerEnabled) },
            explanation: "Off, no partner process runs and nothing is watched."))
        _ = enabled.toggle.accessibilityID("settings.partner.enabled")
        run.addSettingSubview(enabled)
        claudeLine.lineBreakMode = .byTruncatingMiddle
        claudeLine.isSelectable = true
        _ = claudeLine.accessibilityID("settings.partner.claude")
        run.addSettingSubview(claudeLine)
        addGroup(run)
        loadClaudeLine()

        let session = ComposableSettings.GroupView(withTitle: "Timing")
        session.addSettingSubview(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Idle settle (seconds)", minValue: 5, maxValue: 3_600,
                get: { settings.get(UserSettings.partnerIdleSettleSeconds) },
                set: { settings.set($0, for: UserSettings.partnerIdleSettleSeconds) },
                explanation: "How long a session must be quiet before the partner is told it went idle.")))
        session.addSettingSubview(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Turn timeout (minutes)", minValue: 1, maxValue: 240,
                get: { settings.get(UserSettings.partnerTurnTimeoutMinutes) },
                set: { settings.set($0, for: UserSettings.partnerTurnTimeoutMinutes) },
                explanation: "How long one partner turn may run before it is abandoned.")))
        addGroup(session)

        let window = ComposableSettings.GroupView(withTitle: "Window")
        window.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Keep the partner window on top",
            get: { settings.get(UserSettings.partnerAlwaysOnTop) },
            set: { settings.set($0, for: UserSettings.partnerAlwaysOnTop) })))
        window.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Show the Notifications pane",
            get: { settings.get(UserSettings.partnerAttentionPaneVisible) },
            set: { settings.set($0, for: UserSettings.partnerAttentionPaneVisible) })))
        addGroup(window)
    }

    /// The claude path and its version, found once off the main thread's critical path.
    private func loadClaudeLine() {
        guard let path = ClaudeCLI.findBinary() else {
            claudeLine.stringValue = "claude: not found"
            return
        }
        claudeLine.stringValue = "claude: \(path)"
        Task { [weak self] in
            let version = await Self.version(of: path)
            self?.claudeLine.stringValue = "claude: \(path)" + (version.map { " (\($0))" } ?? "")
        }
    }

    private nonisolated static func version(of path: String) async -> String? {
        let configuration = SubprocessChannel.Configuration(
            executableURL: URL(fileURLWithPath: path), arguments: ["--version"], environmentPolicy: .mergeOverParent)
        guard let result = try? await SubprocessChannel.run(configuration, budget: 5), result.exitStatus == 0 else {
            return nil
        }
        let text = (String(data: result.standardOutput, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
