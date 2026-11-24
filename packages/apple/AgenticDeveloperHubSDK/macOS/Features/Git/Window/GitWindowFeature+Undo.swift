import AppKit
import AgenticDeveloperHubSDKCore

/// "Undo Last Git Action" (recipe `workspace/git/git-window`, "Undo"): the toolbar's Undo
/// offered through the command registry, acting on the key Git window's session and
/// enabled only while that session's model has an `undoTarget`.
extension GitWindowFeature {

    /// The command id of "Undo Last Git Action".
    static let undoCommandID = "git.action.undoLastAction"

    /// Registers "Undo Last Git Action" and returns its menu contribution.
    func registerUndoCommand(in registry: CommandRegistry) -> MenuContribution {
        registry.register(AppCommand(
            id: Self.undoCommandID,
            title: "Undo Last Git Action",
            category: "Git",
            isEnabled: { [weak self] in self?.keySession?.model.undoTarget != nil },
            run: { [weak self] _ in
                self?.keySession?.undo()
                return nil
            }
        ))
        return MenuContribution(
            slot: .git, title: "Undo Last Git Action",
            commandID: Self.undoCommandID, registry: registry,
            order: 10
        )
    }

    /// The session of the Git window that is key (or main); nil when neither is one.
    var keySession: GitWindowSession? {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow else { return nil }
        return toolbars.values.first { $0.window === window }?.session
    }
}
