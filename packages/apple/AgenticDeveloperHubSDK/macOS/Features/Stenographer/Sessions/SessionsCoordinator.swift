import AppKit
import KeyboardShortcuts
import OSLog
import AgenticDeveloperHubSDKCore
import AIPluginKit

/// The Sessions window as an app feature: a Window-menu item and a status-item
/// entry that open the live list of Claude Code sessions stenographerd knows.
@MainActor
public final class SessionsCoordinator: AppFeature {

    public enum CommandID {
        public static let showWindow = "stenographer.sessions.showWindow"
    }

    /// The window's stable id — what Stenographer's scripting called it — and
    /// the key its key command's binding is stored under (`window.sessions`).
    public static let windowID = "sessions"

    /// The system-wide key command that opens this window. The host installs
    /// it through `StenographerWindowKeyCommands.install(commands:)`.
    public func keyCommand() -> KeyCommandDescriptor {
        StenographerWindowKeyCommands.descriptor(
            windowID: Self.windowID, title: "Sessions",
            defaultShortcut: .init(.s, modifiers: [.command, .control, .option]),
            present: { [weak self] in self?.showWindow() })
    }

    private let service: any StenographerDaemonService
    /// Resolves the daemon's provider templates for the provider-and-model
    /// pickers; nil (Stenographer) shows the stored model only.
    private let pluginManager: AIPluginManager?
    /// Whether `start()` starts `StenographerSummaryPrefsPush`. False for a host
    /// whose service reaches no daemon (the Kitchen under `APP_TEST_HOME`),
    /// where every push would fail and retry for as long as the app runs.
    public let pushesPreferences: Bool

    public init(service: any StenographerDaemonService, commandRegistry: CommandRegistry,
                pluginManager: AIPluginManager? = nil, pushesPreferences: Bool = true) {
        self.service = service
        self.pluginManager = pluginManager
        self.pushesPreferences = pushesPreferences
        super.init()
        featureName = "Sessions"
        commandRegistry.register(AppCommand(
            id: CommandID.showWindow, title: "Sessions", category: "Stenographer",
            run: { [weak self] in self?.showWindow() }))
        menuContributions = [
            MenuContribution(slot: .ai, title: "Sessions", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 40, key: ""),
            MenuContribution(slot: .statusItem(section: 1), title: "Sessions", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 30)
        ]
    }

    public override func start() throws {
        // Registered unopened so the toolkit's restore-on-launch can reopen it.
        SessionsWindowController.ensureCurrent(service: service, pluginManager: pluginManager)
        if pushesPreferences {
            StenographerSummaryPrefsPush.startObserving(service: service)
        }
        // Coding Project windows show Coding Projects' own summaries, under its switch.
        ProjectSessionMonitor.shared.attach(
            StenographerSessionListSource(service: service, summaryFeature: .projects),
            summariesEnabled: SummaryFeatureSettings.for(.projects).enabled)
    }

    /// One feature's AI Summaries settings pane, for the host's settings window.
    public func settingsPanel(feature: SummaryFeature = .sessions) -> AISummariesSettingsPanel {
        AISummariesSettingsPanel(service: service, feature: feature, pluginManager: pluginManager)
    }

    public func showWindow() {
        SessionsWindowController.present(service: service, pluginManager: pluginManager)
    }
}

extension SessionsCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
