import AppKit
import Combine

import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKCore

/// The CLI settings panel: how a command-line agent (Claude Code) reaches the
/// app's MCP endpoint. Whether models may drive browser panes is the browser's
/// own setting, in its Agent Privacy group (`AgentPrivacySettingsGroup`).
@MainActor
public final class CLISettingsPanelViewController: ComposableSettings.SettingsPanelViewController {

    static let keywords = ["cli", "endpoint", "port", "token", "claude code", "register", "mcp", "command line"]
    public override var searchKeywords: [String] { Self.keywords }

    private let status: AutomationServerStatus
    private let pasteboard: NSPasteboard
    private let line = NSTextField(labelWithString: "")
    private let copyButton = NSButton(title: "Copy Claude Code Command", target: nil, action: nil)
    private var cancellables: Set<AnyCancellable> = []

    /// - Parameters:
    ///   - status: the endpoint's port, registration command and registration.
    ///   - pasteboard: where Copy puts the registration command.
    public init(status: AutomationServerStatus, pasteboard: NSPasteboard = .general) {
        self.status = status
        self.pasteboard = pasteboard
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "CLI",
            icon: NSImage(systemSymbolName: "apple.terminal", accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "MCP Endpoint",
                  body: "The app serves its tools over MCP on this Mac only. Claude Code run from a "
                      + "terminal pane finds it through the shell's environment; Claude Code run "
                      + "anywhere else needs the copied command, once. Whether a model may drive "
                      + "browser panes is set in Web Browser > Privacy and Security, under Agent "
                      + "Privacy.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "MCP Endpoint")

        line.lineBreakMode = .byWordWrapping
        line.maximumNumberOfLines = 0
        _ = line.accessibilityID("settings.automation.status")
        group.addSettingSubview(line)

        copyButton.target = self
        copyButton.action = #selector(copyCommand)
        _ = copyButton.accessibilityID("settings.automation.copy-command")
        group.addSettingSubview(copyButton)

        settingsView.addGroup(group)

        // @Published publishes the new value before it is stored, so render
        // from the published values themselves: reading `status` here would
        // show the old ones.
        Publishers.CombineLatest4(status.$port, status.$command, status.$isRegistered, status.$failureReason)
            .sink { [weak self] port, command, isRegistered, failureReason in
                self?.render(port: port, command: command, isRegistered: isRegistered, failureReason: failureReason)
            }
            .store(in: &cancellables)
    }

    private func render(port: UInt16?, command: String?, isRegistered: Bool, failureReason: String?) {
        line.stringValue = AutomationServerStatus.line(
            port: port, isRegistered: isRegistered, failureReason: failureReason)
        copyButton.isEnabled = port != nil && command != nil
    }

    @objc private func copyCommand() {
        guard status.port != nil, let command = status.command else { return }
        pasteboard.clearContents()
        pasteboard.setString(command, forType: .string)
    }
}
