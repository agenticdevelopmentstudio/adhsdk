import AppKit
import OSLog
import KeyboardShortcuts
import AgenticDeveloperHubSDKCore

/// Owns the command palette: the global shortcut that opens it, the panel it
/// opens, and the command and menu item that name it.
///
/// The palette is the one feature whose subject is the other features, so it
/// takes the same `CommandRegistry` they were handed and reads it — there is no
/// singleton here and must not be one, or a second app embedding this framework
/// would inherit this app's commands.
@MainActor
public final class CommandPaletteCoordinator: AppFeature {

    // MARK: - Public API

    /// The ids this feature's actions answer to.
    ///
    /// `workbench.action.showCommands` is VS Code's own id, kept verbatim: a
    /// JavaScript extension calling `vscode.commands.executeCommand` with it,
    /// or a `contributes.menus` entry naming it, must land here without a
    /// translation table (`principle-of-least-astonishment`).
    public enum CommandID {
        public static let showCommands = "workbench.action.showCommands"
    }

    // MARK: - Dependencies

    private let registry: CommandRegistry

    /// Where the global shortcut lives: an ordinary system-wide key command,
    /// so Settings lists, records and switches it like every other one.
    private let keyCommands: KeyCommandRegistry

    /// Built on first `showPalette()`, not in `init`. A menu-bar app launches
    /// on every login and most launches never open the palette, so its panel,
    /// table and search field are work worth not doing until they are asked
    /// for. Retained afterwards: reopening reuses the one panel.
    private var windowController: CommandPaletteWindowController?

    /// Whether `start()` has claimed the global shortcut and `stop()` has not
    /// yet given it back. Kept here because the library cannot be asked how
    /// many handlers it is holding — see `start()`.
    private var hasClaimedGlobalShortcut = false

    // MARK: - Lifecycle

    /// - Parameter commandRegistry: The registry to list and to dispatch
    ///   through — the same instance every other coordinator registered into.
    public init(commandRegistry registry: CommandRegistry, keyCommands: KeyCommandRegistry = .shared) {
        self.registry = registry
        self.keyCommands = keyCommands
        super.init()

        registry.register(AppCommand(
            id: CommandID.showCommands,
            title: "Show All Commands",
            category: "View",
            run: { [weak self] in self?.showPalette() }
        ))

        self.menuContributions = [
            MenuContribution(
                slot: .view, title: "Command Palette…",
                commandID: CommandID.showCommands, registry: registry,
                order: 0, key: "p", modifiers: [.command, .shift]
            )
        ]
        // ⇧⌘P is safe as a menu key equivalent where it could not be as the
        // global shortcut below: a key equivalent only fires while this app is
        // frontmost, so VS Code's own binding is not taken away from anything.
    }

    // MARK: - AppFeature

    /// Claim the system-global shortcut, by declaring it as a global key
    /// command.
    ///
    /// Here and not in `init` because a global key command registers a real,
    /// machine-wide Carbon hotkey: constructing a coordinator must not take
    /// ⌃⌥C away from every other app, which is exactly what a test bundle that
    /// builds one would otherwise do for the length of its run. `start()` is
    /// the lifecycle hook for a long-running service, and the host calls it
    /// once per launch on every registered feature.
    ///
    /// Guarded so that `start()` and `stop()` pair up: installing a section
    /// twice only replaces it, but a second `start()` must not leave `stop()`
    /// thinking there is something left to give back (`idempotency`).
    public override func start() {
        guard !hasClaimedGlobalShortcut else { return }
        hasClaimedGlobalShortcut = true
        adoptLegacyShortcut()
        keyCommands.install(KeyCommandSection(
            title: Self.shortcutSectionTitle,
            caption: Self.shortcutCaption,
            scope: .global,
            commands: [KeyCommandDescriptor(
                id: Self.shortcutCommandID,
                title: "Command Palette",
                defaultShortcut: KeyboardShortcuts.Name.showCommandPalette.defaultShortcut,
                run: { [weak self] in self?.showPalette() })]))
    }

    /// Give the shortcut back: withdrawing the section hands its chord back
    /// to the system, which is what makes `start()` reversible.
    public override func stop() {
        guard hasClaimedGlobalShortcut else { return }
        hasClaimedGlobalShortcut = false
        keyCommands.uninstall(sectionTitled: Self.shortcutSectionTitle)
    }

    /// Whether the global shortcut is claimed right now.
    ///
    /// Internal, and the tests are the reason: the property worth asserting
    /// about this feature is that *constructing* it claims no machine-wide
    /// hotkey, and there is no other way to see that from outside.
    var isGlobalShortcutInstalled: Bool {
        keyCommands.descriptor(for: Self.shortcutCommandID) != nil
    }

    static let shortcutSectionTitle = "Command Palette"
    static let shortcutCommandID = "commandPalette.show"

    static let shortcutCaption = "Opens the command palette: a search field listing every "
        + "command in the app, including the ones extensions add."

    /// Carry the shortcut over from where it lived before it was a key command.
    ///
    /// It was a `KeyboardShortcuts` name of its own, recorded by a separate
    /// control and on out of the box. A global key command ships off, so
    /// without this every user would lose the palette's hotkey on upgrade, and
    /// one who rebound it would lose their chord too. Once only: after this the
    /// key command's binding is what the user authored, and the old entry is
    /// cleared so its hotkey never fires beside the new one.
    private func adoptLegacyShortcut() {
        guard !keyCommands.hasAuthoredBinding(for: Self.shortcutCommandID) else { return }
        let legacy = KeyboardShortcuts.getShortcut(for: .showCommandPalette)
        keyCommands.setBinding(
            KeyCommandBinding(shortcut: legacy, isEnabled: legacy != nil),
            for: Self.shortcutCommandID)
        KeyboardShortcuts.setShortcut(nil, for: .showCommandPalette)
    }

    // MARK: - Showing

    /// Bring the palette up, building it the first time.
    ///
    /// Idempotent: a second call while it is open re-positions and re-focuses
    /// the same panel rather than stacking another.
    public func showPalette() {
        paletteWindow().show()
    }

    /// Bring the palette up in picker mode: another feature's chooser in place
    /// of the command list, in the same panel.
    ///
    /// The palette knows nothing about what is being picked. `makePicker` is
    /// handed the palette's dismissal and builds the chooser around it, so a
    /// feature's picker can put the palette away before it acts on the choice
    /// — and the palette never imports the feature (`dependency-injection`).
    /// Built fresh on every call, so a picker never opens on the last visit's
    /// filter.
    public func showPicker(_ makePicker: (_ dismiss: @escaping () -> Void) -> NSViewController) {
        let controller = paletteWindow()
        let picker = makePicker { [weak controller] in controller?.close() }
        controller.show(picker: picker)
    }

    private func paletteWindow() -> CommandPaletteWindowController {
        let controller = windowController ?? makeWindowController()
        windowController = controller
        return controller
    }

    private func makeWindowController() -> CommandPaletteWindowController {
        logger.debug("Building the command palette panel")
        return CommandPaletteWindowController(model: CommandPaletteModel(registry: registry))
    }
}

extension CommandPaletteCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// Where the palette's shortcut lived before it was a global key command, and
/// still the source of its default.
///
/// The default is ⌃⌥C rather than VS Code's ⇧⌘P because the shortcut is a
/// *system-global* hotkey: ⇧⌘P taken globally would be stolen from every other
/// app on the machine, VS Code included. ⌃⌥ is this toolkit's established
/// global family (see `SystemWindowShortcutNames`) and `.c` is the one letter
/// in reach that family has not already spent.
extension KeyboardShortcuts.Name {

    /// The raw value is a persisted `UserDefaults` key holding a user's
    /// rebinding from before the move, read once by `adoptLegacyShortcut` —
    /// renaming it silently discards that customisation.
    public static let showCommandPalette = Self(
        "showCommandPalette",
        default: .init(.c, modifiers: [.control, .option]))
}
