import AppKit
import AgenticDeveloperHubSDKCore

/// The shared Key Commands panel: every command any part of the app declared,
/// grouped by the section that declared it, each rebindable in place.
///
/// The panel knows nothing about what the commands *do* — it reads
/// ``KeyCommandRegistry``, so an app that declares three commands and one that
/// declares thirty get the same panel without either of them writing a view.
/// That is what lets this live in the shared framework while the command list
/// stays the property of whoever can actually perform the commands.
@MainActor
public final class KeyCommandsSettingsPanelViewController: ComposableSettings.SettingsPanelViewController {

    private let registry: KeyCommandRegistry
    private let leadingGroups: [@MainActor () -> ComposableSettings.GroupView]
    private let leadingHelp: [ComposableSettings.PanelHelp.Topic]
    private let leadingKeywords: [String]
    private var sectionsObserver: NSObjectProtocol?

    /// - Parameters:
    ///   - title: the panel's name; an app that folds other shortcuts in
    ///     calls it something broader than "Key Commands".
    ///   - leadingGroups: groups drawn above the registry's commands, for
    ///     shortcuts the registry does not own (the command palette's
    ///     recorder). Builders, because the panel is redrawn whenever the
    ///     registry gains a section.
    ///   - leadingHelp: help topics for those groups, before the panel's own.
    ///   - leadingKeywords: search words for those groups.
    public init(
        registry: KeyCommandRegistry = .shared,
        title: String = "Key Commands",
        leadingGroups: [@MainActor () -> ComposableSettings.GroupView] = [],
        leadingHelp: [ComposableSettings.PanelHelp.Topic] = [],
        leadingKeywords: [String] = []
    ) {
        self.registry = registry
        self.leadingGroups = leadingGroups
        self.leadingHelp = leadingHelp
        self.leadingKeywords = leadingKeywords
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: title,
            icon: NSImage(systemSymbolName: "command", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The rows carry the command titles, but none of them contain the words a
    /// user actually searches the sidebar with.
    public override var searchKeywords: [String] {
        ["key", "keys", "command", "commands", "shortcut", "shortcuts", "hotkey", "keyboard", "binding"]
            + leadingKeywords
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        // What a section says about itself is the declaring app's own prose, so
        // it follows the registry rather than being written here.
        let sectionTopics: [ComposableSettings.PanelHelp.Topic] = registry.sections.compactMap { section in
            section.caption.map { .init(title: section.title, body: $0) }
        }
        return ComposableSettings.PanelHelp(topics: leadingHelp + [
            .init(
                title: "Recording a key command",
                body: "Click the field beside a command and press the keys you want. "
                    + "Underneath, the combination reads available or unavailable — "
                    + "unavailable names what already has it, which is either another "
                    + "command in this list or a menu item. Click the checkmark to save "
                    + "it, or the ✗ (or Escape) to leave the command as it was. A "
                    + "combination needs at least one of ⌘, ⌃ or ⌥, so it can never "
                    + "swallow ordinary typing."
            ),
            .init(
                title: "Switching a command off",
                body: "The switch beside a command turns it off without forgetting what "
                    + "it was bound to, so turning it back on gives you your combination "
                    + "back. A command with no combination recorded has nothing to "
                    + "switch on, which is why its switch is dimmed."
            ),
            .init(
                title: "App and system-wide commands",
                body: "An app command works while this app is frontmost. A system-wide "
                    + "command works whatever you are doing — which also means it is "
                    + "taken away from whatever app you are in at the time. That is why "
                    + "the system-wide ones ship switched off: turn on the ones you want "
                    + "and leave the rest alone."
            )
        ] + sectionTopics)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        rebuild()
        // Commands are installed as the app starts, and a panel built before
        // that — a section's first panel is built with the section — would
        // otherwise say the app has none.
        sectionsObserver = NotificationCenter.default.addObserver(
            forName: KeyCommandRegistry.sectionsDidChangeNotification,
            object: registry,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        }
    }

    isolated deinit {
        if let sectionsObserver { NotificationCenter.default.removeObserver(sectionsObserver) }
    }

    private func rebuild() {
        settingsView.removeAllContent()
        for makeGroup in leadingGroups {
            settingsView.addGroup(makeGroup())
        }

        guard !registry.sections.isEmpty else {
            if leadingGroups.isEmpty { settingsView.addGroup(makeEmptyGroup()) }
            return
        }

        // Scope first, then the window, then the feature inside it: a command is
        // only understandable once you know where it fires and what it acts on,
        // and a flat list of titles said neither.
        for scope in KeyCommandScope.allCases {
            let sections = registry.sections(in: scope)
            guard !sections.isEmpty else { continue }

            // What a scope means is in the "App and system-wide commands" help topic.
            settingsView.addHeading(scope.settingsHeading)
            for section in sections {
                settingsView.addGroup(makeGroup(for: section))
            }
        }
    }

    private func makeGroup(for section: KeyCommandSection) -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: section.title)

        for command in section.commands {
            group.addSettingSubview(KeyCommandRowView(command: command, registry: registry))
        }

        for feature in section.features {
            group.addSettingSubview(ComposableSettings.HeaderView(title: feature.title))
            for command in feature.commands {
                group.addSettingSubview(KeyCommandRowView(command: command, registry: registry))
            }
        }

        return group
    }

    /// A consuming app that declared no commands should be told that, rather
    /// than shown a panel that looks like it failed to load.
    private func makeEmptyGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Key Commands")
        group.addSettingSubview(ComposableSettings.ExplanationView(
            withText: "This app has not declared any bindable key commands."))
        return group
    }
}
