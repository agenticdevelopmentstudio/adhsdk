import AppKit
import KeyboardShortcuts
import OSLog
import AgenticDeveloperHubSDKCore
import AIPluginKit

/// The AI Oversight window as an app feature: a Window-menu item and a
/// status-item entry that open the findings and scripts of stenographerd's
/// oversight observers. Starting it also installs the oversight preference push.
@MainActor
public final class OversightCoordinator: AppFeature {

    public enum CommandID {
        public static let showWindow = "stenographer.oversight.showWindow"
    }

    /// The window's stable id — what Stenographer's scripting called it — and
    /// the key its key command's binding is stored under (`window.ai-oversight`).
    public static let windowID = "ai-oversight"

    /// The system-wide key command that opens this window. The host installs
    /// it through `StenographerWindowKeyCommands.install(commands:)`.
    public func keyCommand() -> KeyCommandDescriptor {
        StenographerWindowKeyCommands.descriptor(
            windowID: Self.windowID, title: "AI Oversight",
            defaultShortcut: nil,
            present: { [weak self] in self?.showWindow() })
    }

    private let service: any StenographerDaemonService
    /// Resolves the daemon's provider templates for the provider-and-model
    /// pickers; nil (Stenographer) shows the stored model only.
    private let pluginManager: AIPluginManager?
    /// Whether `start()` starts `StenographerOversightPrefsPush`. False for a host
    /// whose service reaches no daemon (the Kitchen under `APP_TEST_HOME`),
    /// where every push would fail and retry for as long as the app runs.
    public let pushesPreferences: Bool

    public init(service: any StenographerDaemonService, commandRegistry: CommandRegistry,
                pluginManager: AIPluginManager? = nil, pushesPreferences: Bool = true) {
        self.service = service
        self.pluginManager = pluginManager
        self.pushesPreferences = pushesPreferences
        super.init()
        featureName = "AI Oversight"
        commandRegistry.register(AppCommand(
            id: CommandID.showWindow, title: "AI Oversight", category: "Stenographer",
            run: { [weak self] in self?.showWindow() }))
        menuContributions = [
            MenuContribution(slot: .ai, title: "AI Oversight", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 60, key: ""),
            MenuContribution(slot: .statusItem(section: 1), title: "AI Oversight", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 50)
        ]
    }

    public override func start() throws {
        // Registered unopened so the toolkit's restore-on-launch can reopen it.
        OversightFindingsWindowController.ensureCurrent(service: service, pluginManager: pluginManager)
        if pushesPreferences {
            StenographerOversightPrefsPush.startObserving(service: service)
        }
    }

    public func showWindow() {
        OversightFindingsWindowController.present(service: service, pluginManager: pluginManager)
    }

    /// The AI Oversight settings pane, every setting on one row, for a host
    /// with one row per feature.
    public func settingsPanel() -> AIOversightSettingsPanel {
        AIOversightSettingsPanel(service: service, pluginManager: pluginManager)
    }

    /// The AI Oversight settings as two rows, General and AI Config, for a host
    /// that lists several panels under a feature.
    public func settingsPanels() -> [AIOversightSettingsPanel] {
        [AIOversightSettingsPanel(service: service, part: .general, pluginManager: pluginManager),
         AIOversightSettingsPanel(service: service, part: .aiConfig, pluginManager: pluginManager)]
    }
}

extension OversightCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
