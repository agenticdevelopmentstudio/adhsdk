import AppKit
import AgenticDeveloperHubSDKCore

/// The Undo button (recipe `workspace/git/git-window`, "Undo"): always in the toolbar,
/// enabled only while the session's model has an `undoTarget`, and titled after HEAD@{0}
/// in its tooltip. It follows the model, so it is current after every refresh.
extension GitWindowToolbar {

    static let undoIdentifier = "git.toolbar.undo"

    /// "Undo <action>: <message>" for HEAD@{0}; "Undo" when there is none.
    static func undoToolTip(for entry: GitReflogEntry?) -> String {
        guard let entry else { return "Undo" }
        return "Undo \(entry.action): \(entry.message)"
    }

    /// The Undo button in `window`'s toolbar, when it has been built.
    var undoButton: NSButton? {
        undoItem?.view as? NSButton
    }

    private var undoItem: NSToolbarItem? {
        window?.toolbar?.items.first { $0.itemIdentifier.rawValue == Self.undoIdentifier }
    }

    /// Enables Undo when the session's model has an `undoTarget` and sets its tooltip from
    /// HEAD@{0}; without a session it is disabled.
    func updateUndo() {
        let model = session?.model
        let enabled = model?.undoTarget != nil
        let toolTip = Self.undoToolTip(for: model?.lastReflogEntry)
        undoItem?.isEnabled = enabled
        undoItem?.toolTip = toolTip
        undoButton?.isEnabled = enabled
        undoButton?.toolTip = toolTip
    }

    /// Keeps Undo current with the session's model from now on, and sets it at once.
    func followUndo() {
        undoObservation = session?.model.observe { [weak self] _ in
            self?.updateUndo()
        }
        updateUndo()
    }
}
