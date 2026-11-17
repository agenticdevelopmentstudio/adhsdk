import AppKit
import AgenticDeveloperHubSDKCore

/// The Undo button (recipe `workspace/git/git-window`, "Undo"): always in the toolbar,
/// enabled only while the session's model has an `undoTarget`, and titled after the reflog
/// step it takes back (`undoneEntry`) in its tooltip. It follows the model, so it is current after every refresh.
extension GitWindowToolbar {

    static let undoIdentifier = "git.toolbar.undo"

    /// "Undo <action>: <message>" for the step Undo takes back, "Undo <action>" when its
    /// message is empty, and "Undo" when there is none (the reflog lags the ref).
    static func undoToolTip(for entry: GitReflogEntry?) -> String {
        guard let entry else { return "Undo" }
        return entry.message.isEmpty ? "Undo \(entry.action)" : "Undo \(entry.action): \(entry.message)"
    }

    /// The Undo button in `window`'s toolbar, when it has been built.
    var undoButton: NSButton? {
        undoItem?.view as? NSButton
    }

    private var undoItem: NSToolbarItem? {
        window?.toolbar?.items.first { $0.itemIdentifier.rawValue == Self.undoIdentifier }
    }

    /// Enables Undo when the session's model has an `undoTarget` and sets its tooltip from
    /// the step it takes back; without a session it is disabled.
    func updateUndo() {
        let model = session?.model
        let enabled = model?.undoTarget != nil
        let toolTip = Self.undoToolTip(for: model?.undoneEntry)
        undoItem?.isEnabled = enabled
        undoItem?.toolTip = toolTip
        undoButton?.isEnabled = enabled
        undoButton?.toolTip = toolTip
    }

    /// Keeps Undo current with the session's model from now on, and sets it at once.
    func followUndo() {
        undoObservation = session?.model.observe { [weak self] changes in
            // Signatures and reviews landing say nothing about the reflog.
            guard changes != [.annotations] else { return }
            self?.updateUndo()
        }
        updateUndo()
    }
}
