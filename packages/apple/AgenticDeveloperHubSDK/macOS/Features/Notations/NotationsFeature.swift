import AppKit
import Combine
import os
import AgenticDeveloperHubSDKCore

/// Notations as an app feature: Notes ▸ Notations, the window's restore, the
/// `notations_*` tools, and the reconcile passes that archive a merged
/// branch's notes and delete archived ones past the retention setting.
///
/// A pass runs at launch, every hour, and for one project whenever that
/// project's window becomes key. The host says which project a window shows
/// and how to bring a notation's project forward; everything else is here.
@MainActor
public final class NotationsFeature: AppFeature {

    public enum CommandID {
        public static let showWindow = "notations.showWindow"
    }

    /// How often the background pass runs while the app is up.
    public static let reconcileInterval: TimeInterval = 60 * 60

    public let store: NotationsStore

    private let reconciler: NotationsReconciler
    private let toolSource: NotationsToolSource
    private let settings: SettingsStore
    private let registerTools: @MainActor (any ChatToolSource) -> Void
    private let goToProject: @MainActor (Notation) -> Void
    private let projectIDForWindow: @MainActor (NSWindow) -> UUID?
    private var timer: Timer?
    private var keyObserver: NSObjectProtocol?
    private var toolsRegistered = false

    nonisolated private static let logger = Logger(subsystem: "com.agenticdeveloperhubsdk", category: "Notations")

    /// - Parameters:
    ///   - callerPlace: The project and working directory of the pane with
    ///     this id, for the tools that act on "this branch".
    ///   - projectAtPath: The project a directory belongs to.
    ///   - projectIDForWindow: The project a window shows, or `nil` for a
    ///     window that is not a Coding Project window.
    ///   - goToProject: Brings the notation's project window forward,
    ///     opening it if needed.
    public init(
        store: NotationsStore,
        commandRegistry: CommandRegistry,
        registerTools: @escaping @MainActor (any ChatToolSource) -> Void,
        callerPlace: @escaping @MainActor @Sendable (String) -> NotationsPlace?,
        projectAtPath: @escaping @MainActor @Sendable (String) -> NotationsPlace?,
        projectIDForWindow: @escaping @MainActor (NSWindow) -> UUID?,
        goToProject: @escaping @MainActor (Notation) -> Void,
        settings: SettingsStore = UserSettings.shared,
        git: NotationsGit = NotationsGit()
    ) {
        self.store = store
        self.settings = settings
        self.registerTools = registerTools
        self.goToProject = goToProject
        self.projectIDForWindow = projectIDForWindow
        reconciler = NotationsReconciler(store: store, git: git)
        toolSource = NotationsToolSource(store: store, git: git, callerPlace: callerPlace,
                                         projectAtPath: projectAtPath)
        super.init()
        featureName = "Notations"
        commandRegistry.register(AppCommand(
            id: CommandID.showWindow, title: "Notations", category: "Notes",
            run: { [weak self] in self?.showWindow() }))
        menuContributions = [
            MenuContribution(slot: .notes, title: "Notations", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 50, key: "")
        ]
        scriptingKeys = [Self.scriptingKey]
    }

    /// The application element key the `.sdef` declares for `notation`.
    public static let scriptingKey = "notations"

    public override func value(forScriptingKey key: String) -> Any? {
        guard key == Self.scriptingKey else { return nil }
        return ((try? store.all()) ?? []).map { ScriptableNotation(notationID: $0.id, store: store) }
    }

    /// For the host's unique-id lookup (`notation id "…"`).
    public func scriptableNotation(uniqueID: String) -> ScriptableNotation? {
        guard let id = UUID(uuidString: uniqueID), (try? store.notation(id: id)) != nil else { return nil }
        return ScriptableNotation(notationID: id, store: store)
    }

    public func showWindow() {
        NotationsWindowController.present(store: store) { [weak self] in self?.goToProject($0) }
    }

    public override func start() throws {
        // Registered unopened so the toolkit's restore-on-launch can reopen it.
        NotationsWindowController.ensureCurrent(store: store) { [weak self] in self?.goToProject($0) }
        if !toolsRegistered {
            toolsRegistered = true
            registerTools(toolSource)
        }
        reconcile(projectID: nil)
        timer = Timer.scheduledTimer(withTimeInterval: Self.reconcileInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.reconcile(projectID: nil) }
        }
        keyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { [weak self] _ in
            // The key window is the one that just became key; reading it here
            // keeps the non-`Sendable` notification out of the isolated closure.
            MainActor.assumeIsolated {
                guard let self, let window = NSApp.keyWindow,
                      let projectID = self.projectIDForWindow(window) else { return }
                self.reconcile(projectID: projectID)
            }
        }
    }

    /// Posted at quit: every pane and the window write their debounced edit
    /// now and wait for it, before the process ends.
    public static let flushPendingSavesNotification = Notification.Name("NotationsFlushPendingSaves")

    public override func terminate() async {
        NotificationCenter.default.post(name: Self.flushPendingSavesNotification, object: nil)
        await super.terminate()
    }

    public override func stop() {
        timer?.invalidate()
        timer = nil
        if let keyObserver { NotificationCenter.default.removeObserver(keyObserver) }
        keyObserver = nil
    }

    /// One pass, off the main actor. `projectID` limits it to one project.
    public func reconcile(projectID: UUID?) {
        let days = settings.get(UserSettings.notationsArchivedRetentionDays)
        let reconciler = reconciler
        Task.detached(priority: .utility) {
            let summary = await reconciler.reconcile(retentionDays: days, projectID: projectID)
            if summary.archived > 0 || summary.deleted > 0 {
                Self.logger.info(
                    "Notations: archived \(summary.archived), deleted \(summary.deleted), skipped \(summary.skipped)")
            }
        }
    }
}
