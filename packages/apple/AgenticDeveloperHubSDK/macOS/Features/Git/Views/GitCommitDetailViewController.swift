import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import os

/// Told which parent link and which changed file the commit detail chose.
@MainActor public protocol GitCommitDetailDelegate: AnyObject {
    /// A parent link was pressed; `id` is the parent's full sha.
    func commitDetail(_ detail: GitCommitDetailViewController, didSelectCommit id: String)
    /// A file of `commit` was selected, or nil when the selection cleared.
    func commitDetail(_ detail: GitCommitDetailViewController, didSelectFile file: GitFileListItem?,
                      in commit: GitCommit)
}

/// The git window's commit detail (recipe `workspace/git/git-views`, "Commit detail"):
/// a header with the message, author and committer, sha and parent links, above the
/// commit's changed files, read from a `GitContentSource`.
///
/// `show(commit:)` fills the header at once and then awaits the commit's diff for the
/// list; the latest call always wins, decided by the detail's own counter. A diff that
/// fails is logged and shown as the error's description in place of the list, so it
/// never reads as a commit with no changes. Used on the main thread.
@MainActor
public final class GitCommitDetailViewController: NSViewController {

    public weak var delegate: GitCommitDetailDelegate?

    /// The commit shown, or nil.
    public private(set) var commit: GitCommit?

    let fileList = GitFileListViewController(identifier: "commit")
    let headerScrollView = ThemedScrollView()
    let headerStack = NSStackView()
    let subjectLabel = ThemedLabel.wrapping("", width: 400, role: .primaryText, textRole: .heading)
    let bodyLabel = ThemedLabel.wrapping("", width: 400, role: .primaryText, textRole: .body)
    let authorRow = GitCommitDetailPersonRow(identifier: "git.detail.author")
    let committerRow = GitCommitDetailPersonRow(identifier: "git.detail.committer")
    let shaLabel = ThemedLabel(role: .secondaryText, textRole: .code)
    let copyButton = NSButton()
    let parentsRow = NSStackView()
    /// The failed diff's description, over the empty list; hidden otherwise.
    let errorLabel = ThemedLabel.wrapping("", width: 400, role: .danger, textRole: .body)
    private(set) var parentButtons: [NSButton] = []
    /// The diff request in flight or last finished; tests await it.
    private(set) var loadTask: Task<Void, Never>?
    /// Bumped by every `show(commit:)` before it awaits; a diff that returns to find it
    /// moved belongs to an older call and is dropped.
    private(set) var generation = 0

    private let source: GitContentSource
    private let pasteboard: NSPasteboard
    private let parentsCaption = ThemedLabel(string: "Parents", role: .secondaryText, textRole: .caption)
    private var wrappingLabels: [ThemedLabel] { [subjectLabel, bodyLabel, errorLabel] }
    /// Holds the header at zero height while nothing is shown.
    private var collapsedHeader: NSLayoutConstraint?

    public init(source: GitContentSource, pasteboard: NSPasteboard = .general) {
        self.source = source
        self.pasteboard = pasteboard
        super.init(nibName: nil, bundle: nil)
        configureHeaderViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.detail")

        let document = TopAnchoredFlippedView()
        document.accessibilityID("git.detail.headerDocument")
        document.translatesAutoresizingMaskIntoConstraints = false
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(headerStack)
        headerScrollView.documentView = document
        headerScrollView.accessibilityID("git.detail.header")
        headerScrollView.hasVerticalScroller = true
        headerScrollView.autohidesScrollers = true
        headerScrollView.drawsBackground = false
        headerScrollView.translatesAutoresizingMaskIntoConstraints = false

        let separator = ThemedSeparatorView()
        separator.accessibilityID("git.detail.separator")
        separator.translatesAutoresizingMaskIntoConstraints = false
        addChild(fileList)
        let listView = fileList.view
        listView.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        for view in [headerScrollView, separator, listView, errorLabel] { root.addSubview(view) }

        let clip = headerScrollView.contentView
        // The header is as tall as its content, but never more than half the detail.
        let fitsContent = headerScrollView.heightAnchor.constraint(equalTo: document.heightAnchor)
        fitsContent.priority = .defaultHigh
        let collapsed = headerScrollView.heightAnchor.constraint(equalToConstant: 0)
        collapsed.isActive = commit == nil
        collapsedHeader = collapsed
        NSLayoutConstraint.activate([
            document.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            document.topAnchor.constraint(equalTo: clip.topAnchor),
            document.widthAnchor.constraint(equalTo: clip.widthAnchor),
            headerStack.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: 12),
            headerStack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -12),
            headerStack.topAnchor.constraint(equalTo: document.topAnchor, constant: 10),
            headerStack.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -10),

            headerScrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            headerScrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            headerScrollView.topAnchor.constraint(equalTo: root.topAnchor),
            headerScrollView.heightAnchor.constraint(lessThanOrEqualTo: root.heightAnchor, multiplier: 0.5),
            fitsContent,
            separator.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            separator.topAnchor.constraint(equalTo: headerScrollView.bottomAnchor),
            listView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            listView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            listView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -12),
            errorLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 10)
        ])
        view = root
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        // Wrap the message at the header's width rather than the width it was built at.
        let width = max(headerScrollView.contentView.bounds.width - 24, 100)
        for label in wrappingLabels where label.preferredMaxLayoutWidth != width {
            label.preferredMaxLayoutWidth = width
        }
    }

    // MARK: - Showing a commit

    /// Shows `commit`, or nothing for nil. The header fills at once. A different commit
    /// empties the list straight away; the same commit keeps it until its diff arrives.
    /// The diff is then awaited, and lands only if no later call has been made: the
    /// check is this detail's own counter, taken before it awaits, never state the
    /// content source changes. A diff that throws is logged and leaves the list empty
    /// under the error's description. Nil also cancels the diff in flight.
    ///
    /// The previous request is cancelled too, but only to stop its work early: a
    /// cancelled request that still returns is dropped by the counter alone.
    public func show(commit newCommit: GitCommit?) {
        generation += 1
        let generation = self.generation
        loadTask?.cancel()
        loadTask = nil
        // Emptied while the old commit is still the shown one, so a selection it removes
        // is reported against the commit it belonged to.
        if newCommit?.id != commit?.id { fileList.files = [] }
        commit = newCommit
        fillHeader(newCommit)
        showFailure(nil)
        guard let newCommit else { return }
        let target = GitDiffTarget.commit(newCommit.id, paths: [])
        loadTask = Task { [weak self, source] in
            let result: Result<GitDiff, Error>
            do {
                result = .success(try await source.diff(target, options: GitDiffOptions()))
            } catch {
                result = .failure(error)
            }
            guard let self, generation == self.generation else { return }
            switch result {
            case .success(let diff):
                self.fileList.files = diff.files.map(GitFileListItem.init(diff:))
            case .failure(let error):
                self.fileList.files = []
                self.logFailure(error)
                self.showFailure(error)
            }
        }
    }

    /// Shows `error`'s description over the list, or hides it for nil.
    private func showFailure(_ error: Error?) {
        errorLabel.stringValue = error?.localizedDescription ?? ""
        errorLabel.isHidden = error == nil
    }

    /// Logs a failed diff by its case and fields, never git's own output.
    private func logFailure(_ error: Error) {
        let description = GitClientError.logDescription(of: error)
        Self.logger.error("Git commit diff failed: \(description, privacy: .public)")
    }

    // MARK: - Header

    private func configureHeaderViews() {
        fileList.delegate = self

        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 8
        headerStack.isHidden = true
        headerStack.accessibilityID("git.detail.headerStack")
        errorLabel.accessibilityID("git.detail.error")
        errorLabel.isSelectable = true
        errorLabel.isHidden = true

        subjectLabel.accessibilityID("git.detail.subject")
        subjectLabel.isSelectable = true
        bodyLabel.accessibilityID("git.detail.body")
        bodyLabel.isSelectable = true

        shaLabel.accessibilityID("git.detail.sha")
        shaLabel.isSelectable = true
        copyButton.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy SHA")
        copyButton.imagePosition = .imageOnly
        copyButton.isBordered = false
        copyButton.bezelStyle = .regularSquare
        copyButton.target = self
        copyButton.action = #selector(copySha(_:))
        copyButton.toolTip = "Copy SHA"
        copyButton.setAccessibilityLabel("Copy SHA")
        copyButton.accessibilityID("git.detail.copySha")
        copyButton.observeTheme { button, palette in button.contentTintColor = palette.nsColor(.secondaryText) }
        let shaRow = NSStackView(views: [shaLabel, copyButton])
        shaRow.orientation = .horizontal
        shaRow.alignment = .centerY
        shaRow.spacing = 6
        shaRow.accessibilityID("git.detail.shaRow")

        parentsRow.orientation = .horizontal
        parentsRow.alignment = .firstBaseline
        parentsRow.spacing = 8
        parentsRow.addArrangedSubview(parentsCaption)
        parentsRow.accessibilityID("git.detail.parents")
        parentsCaption.accessibilityID("git.detail.parentsCaption")

        for view in [subjectLabel, bodyLabel, authorRow, committerRow, shaRow, parentsRow] {
            headerStack.addArrangedSubview(view)
        }
    }

    private func fillHeader(_ commit: GitCommit?) {
        headerStack.isHidden = commit == nil
        collapsedHeader?.isActive = commit == nil
        subjectLabel.stringValue = commit?.subject ?? ""
        bodyLabel.stringValue = commit?.body ?? ""
        bodyLabel.isHidden = bodyLabel.stringValue.isEmpty
        authorRow.configure(commit?.author)
        committerRow.configure(commit?.committer)
        shaLabel.stringValue = commit?.id ?? ""
        copyButton.isHidden = commit == nil
        setParents(commit?.parents ?? [])
    }

    private func setParents(_ parents: [String]) {
        for button in parentButtons { button.removeFromSuperview() }
        parentButtons = parents.enumerated().map { index, parent in
            let button = NSButton(title: String(parent.prefix(8)), target: self, action: #selector(openParent(_:)))
            button.isBordered = false
            button.bezelStyle = .regularSquare
            button.tag = index
            button.toolTip = parent
            button.accessibilityID("git.detail.parent")
            button.observeTheme { button, palette in
                button.attributedTitle = NSAttributedString(string: button.title, attributes: [
                    .foregroundColor: palette.nsColor(.accent),
                    .font: palette.font(.code)
                ])
            }
            parentsRow.addArrangedSubview(button)
            return button
        }
        parentsRow.isHidden = parents.isEmpty
    }

    @objc private func copySha(_ sender: Any?) {
        guard let commit else { return }
        pasteboard.clearContents()
        pasteboard.setString(commit.id, forType: .string)
    }

    @objc private func openParent(_ sender: NSButton) {
        guard let parents = commit?.parents, parents.indices.contains(sender.tag) else { return }
        delegate?.commitDetail(self, didSelectCommit: parents[sender.tag])
    }
}

extension GitCommitDetailViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}

extension GitCommitDetailViewController: GitFileListDelegate {
    public func fileList(_ list: GitFileListViewController, didSelect item: GitFileListItem?) {
        guard let commit else { return }
        delegate?.commitDetail(self, didSelectFile: item, in: commit)
    }
}

/// An author or committer row in the commit detail: the person's initials in a 28-point
/// avatar, the name, `<email>`, and the absolute date with the relative one as its tooltip.
@MainActor
final class GitCommitDetailPersonRow: NSStackView {
    /// Initials only: the row never gives the avatar a picture URL, so it never fetches.
    let avatar = AvatarView(side: 28)
    let nameLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let emailLabel = ThemedLabel(role: .secondaryText, textRole: .body)
    let dateLabel = ThemedLabel(role: .secondaryText, textRole: .body)

    init(identifier: String) {
        super.init(frame: .zero)
        accessibilityID(identifier)
        orientation = .horizontal
        alignment = .centerY
        spacing = 6
        for label in [nameLabel, emailLabel, dateLabel] {
            label.lineBreakMode = .byTruncatingTail
            label.isSelectable = true
        }
        emailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        for view in [avatar, nameLabel, emailLabel, dateLabel] { addArrangedSubview(view) }
        setCustomSpacing(12, after: emailLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(_ person: GitPerson?) {
        avatar.content = person.map { AvatarContent(name: $0.name, seed: $0.email, imageURL: nil) }
        nameLabel.stringValue = person?.name ?? ""
        emailLabel.stringValue = person.map { "<\($0.email)>" } ?? ""
        dateLabel.stringValue = person?.date.formatted(date: .abbreviated, time: .shortened) ?? ""
        dateLabel.toolTip = person.map { RelativeDateFormatting.string(for: $0.date) }
    }
}
