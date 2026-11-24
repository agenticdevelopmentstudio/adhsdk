import AppKit
import AgenticDeveloperHubSDKCore

/// An LFS pointer diff (recipe `workspace/git/git-views`, "LFS"): when both sides of the
/// file are LFS pointers, or one is and the other side is missing, the viewer shows one
/// summary row, "LFS object <short oid> · <size>" (old → new when both exist), instead of
/// the pointer text.
extension GitDiffViewController {

    static func makeLFSLabel() -> ThemedLabel {
        let label = ThemedLabel(role: .secondaryText, textRole: .body)
        label.accessibilityID("git.diff.lfs")
        label.isSelectable = true
        label.isHidden = true
        return label
    }

    /// Adds `label` to `root` over the viewers, at the error label's place under the controls.
    func place(_ label: ThemedLabel, in root: NSView, under viewers: NSView) {
        label.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: viewers.topAnchor, constant: 10)
        ])
    }

    /// Shows `summary`'s row, or hides it for nil.
    func showLFS(_ summary: GitLFSDiffSummary?) {
        lfsLabel.stringValue = summary?.text ?? ""
        lfsLabel.isHidden = summary == nil
    }
}
