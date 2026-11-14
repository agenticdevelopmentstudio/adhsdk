import AppKit
import AgenticDeveloperHubSDKCore

/// Told the diff target of the working-copy file selected, or nil when nothing is.
@MainActor public protocol GitWorkingCopyDelegate: AnyObject {
    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didSelect target: GitDiffTarget?)
}

/// The git window's working copy (recipe `workspace/git/git-views`, "Working copy"): the
/// staged files above the unstaged ones, each a changed-files list under a counted
/// header, read from a `GitWorkingCopyDataSource`.
///
/// The owner calls `reload()` when the model reports a status change. One file is
/// selected across both lists. Used on the main thread.
@MainActor
public final class GitWorkingCopyViewController: NSViewController {

    public weak var delegate: GitWorkingCopyDelegate?

    let stagedList = GitFileListViewController(identifier: "staged")
    let unstagedList = GitFileListViewController(identifier: "unstaged")
    let stagedHeader = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    let unstagedHeader = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)

    let splitView = ThemedSplitView()
    private let source: GitWorkingCopyDataSource

    public init(source: GitWorkingCopyDataSource) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
        stagedList.delegate = self
        unstagedList.delegate = self
        stagedHeader.accessibilityID("git.workingCopy.stagedHeader")
        unstagedHeader.accessibilityID("git.workingCopy.unstagedHeader")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.workingCopy")

        splitView.accessibilityID("git.workingCopy.split")
        splitView.isVertical = false
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        addChild(stagedList)
        addChild(unstagedList)
        splitView.addArrangedSubview(pane("staged", header: stagedHeader, list: stagedList))
        splitView.addArrangedSubview(pane("unstaged", header: unstagedHeader, list: unstagedList))
        root.addSubview(splitView)
        NSLayoutConstraint.activate([
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: root.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
        reload()
    }

    /// Re-reads both lists. A selected file still in its list stays selected, without a
    /// delegate call unless its status changed, when the delegate is told its new target;
    /// one that left its list is deselected and the delegate is told nil.
    public func reload() {
        let staged = source.staged.map(GitFileListItem.init(change:))
        let unstaged = source.unstaged.map(GitFileListItem.init(change:))
        stagedHeader.stringValue = "Staged (\(staged.count))"
        unstagedHeader.stringValue = "Unstaged (\(unstaged.count))"
        stagedList.files = staged
        unstagedList.files = unstaged
    }

    private func pane(_ name: String, header: ThemedLabel, list: GitFileListViewController) -> NSView {
        let pane = NSView()
        pane.accessibilityID("git.workingCopy.\(name)Pane")
        let listView = list.view
        header.translatesAutoresizingMaskIntoConstraints = false
        listView.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(header)
        pane.addSubview(listView)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 8),
            header.trailingAnchor.constraint(lessThanOrEqualTo: pane.trailingAnchor, constant: -8),
            header.topAnchor.constraint(equalTo: pane.topAnchor, constant: 6),
            listView.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: pane.trailingAnchor),
            listView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4),
            listView.bottomAnchor.constraint(equalTo: pane.bottomAnchor),
            pane.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        return pane
    }

    /// The diff a selected item of `list` shows.
    private func target(for item: GitFileListItem, in list: GitFileListViewController) -> GitDiffTarget {
        if list === stagedList { return .staged(paths: [item.path]) }
        if item.status == .untracked { return .untracked(path: item.path) }
        return .unstaged(paths: [item.path])
    }
}

extension GitWorkingCopyViewController: GitFileListDelegate {
    public func fileList(_ list: GitFileListViewController, didSelect item: GitFileListItem?) {
        guard let item else {
            delegate?.workingCopy(self, didSelect: nil)
            return
        }
        let other = list === stagedList ? unstagedList : stagedList
        other.clearSelection()
        delegate?.workingCopy(self, didSelect: target(for: item, in: list))
    }
}
