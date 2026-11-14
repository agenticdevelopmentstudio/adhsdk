import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKLanguage
import os

/// Told when the diff's Blame or History button is pressed for the shown file.
@MainActor public protocol GitDiffDelegate: AnyObject {
    /// Blame `path` at `revision`; nil means the working file.
    func diff(_ diff: GitDiffViewController, didRequestBlameFor path: String, at revision: String?)
    func diff(_ diff: GitDiffViewController, didRequestHistoryFor path: String)
}

/// The git window's diff (recipe `workspace/git/git-views`, "Diff"): one file's change in
/// the toolkit's line viewer, inline or side by side, with Ignore Whitespace and Word
/// Highlighting toggles and Blame and History buttons for the file.
///
/// `show(target:file:)` awaits the diff, shows its rows uncoloured, then reads both file
/// versions and recolours them. The latest call always wins, decided by the controller's
/// own counter. The layout and the two toggles are stored in `settings`; the layout and
/// word highlighting rebuild the rows from the diff already read, while ignoring
/// whitespace asks for the diff again. A diff that fails is logged and its description
/// shown in place of the rows. Used on the main thread.
@MainActor
public final class GitDiffViewController: NSViewController {

    enum Layout: String {
        case inline
        case sideBySide
    }

    public weak var delegate: GitDiffDelegate?

    let controlsRow = NSStackView()
    let layoutControl = NSSegmentedControl(labels: ["Inline", "Side by Side"], trackingMode: .selectOne,
                                           target: nil, action: nil)
    let ignoreWhitespaceButton = NSButton(checkboxWithTitle: "Ignore Whitespace", target: nil, action: nil)
    let wordHighlightButton = NSButton(checkboxWithTitle: "Word Highlighting", target: nil, action: nil)
    let blameButton = NSButton(title: "Blame", target: nil, action: nil)
    let historyButton = NSButton(title: "History", target: nil, action: nil)
    let inlineViewer = LineViewerViewController(identifier: "git.diff.inline")
    let leftViewer = LineViewerViewController(identifier: "git.diff.left")
    let rightViewer = LineViewerViewController(identifier: "git.diff.right")
    let splitView = ThemedSplitView()
    /// The failed diff's description, over the empty viewer; hidden otherwise.
    let errorLabel = ThemedLabel.wrapping("", width: 400, role: .danger, textRole: .body)

    /// The diff request (and its colouring) in flight or last finished; tests await it.
    private(set) var loadTask: Task<Void, Never>?
    /// Bumped by every `show` and `clear` before anything awaits; a result that returns to
    /// find it moved belongs to an older call and is dropped.
    private(set) var generation = 0

    private let source: GitContentSource
    private let coloring: GitSyntaxColoring?
    private let settings: SettingsStore
    /// The target and file shown, or nil.
    private var request: (target: GitDiffTarget, file: String)?
    /// The shown file's diff, once read; nil while nothing is shown or after a failure.
    /// It stays on screen while a later request loads, so it may answer an older one.
    private var fileDiff: GitFileDiff?
    /// The request `fileDiff` answers.
    private var fileDiffRequest: (target: GitDiffTarget, file: String)?
    private var colouredSides: (old: [StyledLine]?, new: [StyledLine]?)?
    /// The viewers hold their data sources weakly; these keep them alive.
    private var inlineModel: GitInlineDiffModel?
    private var sideModels: (left: GitDiffSideModel, right: GitDiffSideModel)?
    private var scrollSync: LineViewerScrollSync?

    public init(source: GitContentSource, coloring: GitSyntaxColoring?, settings: SettingsStore = UserSettings.shared) {
        self.source = source
        self.coloring = coloring
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
        configureControls()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.diff")

        addChild(inlineViewer)
        addChild(leftViewer)
        addChild(rightViewer)
        splitView.accessibilityID("git.diff.split")
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.addArrangedSubview(leftViewer.view)
        splitView.addArrangedSubview(rightViewer.view)
        scrollSync = LineViewerScrollSync([leftViewer, rightViewer])

        let inlineView = inlineViewer.view
        for view in [controlsRow, inlineView, splitView, errorLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            controlsRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            controlsRow.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
            controlsRow.topAnchor.constraint(equalTo: root.topAnchor, constant: 6),
            inlineView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            inlineView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            inlineView.topAnchor.constraint(equalTo: controlsRow.bottomAnchor, constant: 6),
            inlineView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: inlineView.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            leftViewer.view.widthAnchor.constraint(equalTo: rightViewer.view.widthAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -12),
            errorLabel.topAnchor.constraint(equalTo: inlineView.topAnchor, constant: 10)
        ])
        view = root
        applyLayout()
        render()
    }

    // MARK: - Showing a file

    /// Shows `file`'s change in `target`. The previous rows stay until the diff arrives;
    /// it lands only if no later `show` or `clear` has been made, then shows uncoloured
    /// until both sides are read and coloured, which land under the same check. The file
    /// is the diff's entry whose new path is `file`, else whose old path is; with neither,
    /// no rows. A diff that throws is logged and leaves the viewer empty under the error's
    /// description. Blame and History act on `file` from this call on, whatever is still
    /// on screen.
    public func show(target: GitDiffTarget, file: String) {
        request = (target, file)
        showFailure(nil)
        updateButtons()
        load()
    }

    /// Reads the shown target's diff again (the file changed on disk, or a Refresh),
    /// keeping the current rows until it lands; the latest `show`, `reload` or `clear`
    /// wins. Nothing shown, nothing read.
    public func reload() {
        guard request != nil else { return }
        load()
    }

    /// Whether the shown target is the working copy (staged, unstaged or untracked),
    /// whose diff changes as files are edited.
    public var isShowingWorkingCopy: Bool {
        switch request?.target {
        case .unstaged, .staged, .untracked: true
        case .commit, .range, .none: false
        }
    }

    /// Shows nothing and drops any request in flight.
    public func clear() {
        generation += 1
        loadTask?.cancel()
        loadTask = nil
        request = nil
        fileDiff = nil
        colouredSides = nil
        showFailure(nil)
        updateButtons()
        render()
    }

    /// Reads the current request's diff, then its colours. Bumps the counter first.
    private func load() {
        generation += 1
        let generation = self.generation
        loadTask?.cancel()
        loadTask = nil
        guard let request else { return }
        var options = GitDiffOptions()
        options.ignoreWhitespace = settings.get(UserSettings.gitDiffIgnoreWhitespace)
        loadTask = Task { [weak self, source, coloring] in
            let result: Result<GitDiff, Error>
            do {
                result = .success(try await source.diff(request.target, options: options))
            } catch {
                result = .failure(error)
            }
            guard let self, generation == self.generation else { return }
            switch result {
            case .failure(let error):
                self.fileDiff = nil
                self.colouredSides = nil
                self.render()
                self.logFailure(error)
                self.showFailure(error)
                return
            case .success(let diff):
                let fileDiff = Self.file(request.file, in: diff)
                self.fileDiff = fileDiff
                self.fileDiffRequest = request
                self.colouredSides = nil
                self.render()
                guard let fileDiff, let coloring, !fileDiff.isBinary else { return }
                let sides = await coloring.sides(of: fileDiff, target: request.target, source: source)
                guard generation == self.generation else { return }
                self.colouredSides = sides
                self.render()
            }
        }
    }

    static func file(_ path: String, in diff: GitDiff) -> GitFileDiff? {
        diff.files.first { $0.newPath == path } ?? diff.files.first { $0.oldPath == path }
    }

    /// Rebuilds the shown layout's rows from the diff and colours already read.
    private func render() {
        guard isViewLoaded else { return }
        let words = settings.get(UserSettings.gitDiffWordHighlight)
        let sides = colouredSides
        inlineModel = nil
        sideModels = nil
        if let fileDiff {
            switch layout {
            case .inline:
                inlineModel = GitInlineDiffModel(diff: fileDiff, oldLines: sides?.old, newLines: sides?.new,
                                                 wordHighlights: words)
            case .sideBySide:
                sideModels = GitSideBySideDiffModel.make(diff: fileDiff, oldLines: sides?.old,
                                                         newLines: sides?.new, wordHighlights: words)
            }
        }
        inlineViewer.dataSource = inlineModel
        leftViewer.dataSource = sideModels?.left
        rightViewer.dataSource = sideModels?.right
        for viewer in [inlineViewer, leftViewer, rightViewer] { viewer.reloadData() }
    }

    // MARK: - Controls

    private var layout: Layout {
        Layout(rawValue: settings.get(UserSettings.gitDiffLayout)) ?? .inline
    }

    private func configureControls() {
        controlsRow.orientation = .horizontal
        controlsRow.alignment = .centerY
        controlsRow.spacing = 12
        controlsRow.accessibilityID("git.diff.controls")

        layoutControl.target = self
        layoutControl.action = #selector(layoutChanged(_:))
        layoutControl.accessibilityID("git.diff.layout")
        ignoreWhitespaceButton.target = self
        ignoreWhitespaceButton.action = #selector(ignoreWhitespaceChanged(_:))
        ignoreWhitespaceButton.accessibilityID("git.diff.ignoreWhitespace")
        wordHighlightButton.target = self
        wordHighlightButton.action = #selector(wordHighlightChanged(_:))
        wordHighlightButton.accessibilityID("git.diff.wordHighlight")
        blameButton.target = self
        blameButton.action = #selector(blamePressed(_:))
        blameButton.bezelStyle = .push
        blameButton.accessibilityID("git.diff.blame")
        historyButton.target = self
        historyButton.action = #selector(historyPressed(_:))
        historyButton.bezelStyle = .push
        historyButton.accessibilityID("git.diff.history")
        for control in [layoutControl, ignoreWhitespaceButton, wordHighlightButton, blameButton, historyButton]
            as [NSControl] {
            control.controlSize = .small
        }

        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        for view in [layoutControl, ignoreWhitespaceButton, wordHighlightButton, spacer, blameButton, historyButton] {
            controlsRow.addArrangedSubview(view)
        }

        errorLabel.accessibilityID("git.diff.error")
        errorLabel.isSelectable = true
        errorLabel.isHidden = true

        layoutControl.selectedSegment = layout == .inline ? 0 : 1
        ignoreWhitespaceButton.state = settings.get(UserSettings.gitDiffIgnoreWhitespace) ? .on : .off
        wordHighlightButton.state = settings.get(UserSettings.gitDiffWordHighlight) ? .on : .off
        updateButtons()
    }

    private func applyLayout() {
        guard isViewLoaded else { return }
        inlineViewer.view.isHidden = layout != .inline
        splitView.isHidden = layout != .sideBySide
    }

    @objc func layoutChanged(_ sender: NSSegmentedControl) {
        let chosen: Layout = sender.selectedSegment == 1 ? .sideBySide : .inline
        settings.set(chosen.rawValue, for: UserSettings.gitDiffLayout)
        applyLayout()
        render()
    }

    @objc private func ignoreWhitespaceChanged(_ sender: NSButton) {
        settings.set(sender.state == .on, for: UserSettings.gitDiffIgnoreWhitespace)
        guard request != nil else { return }
        showFailure(nil)
        load()
    }

    @objc private func wordHighlightChanged(_ sender: NSButton) {
        settings.set(sender.state == .on, for: UserSettings.gitDiffWordHighlight)
        render()
    }

    private func updateButtons() {
        blameButton.isEnabled = request != nil
        historyButton.isEnabled = request != nil
    }

    /// The diff read for the current request; nil while it loads, so the buttons never act
    /// on the previous file still on screen.
    private var requestedFileDiff: GitFileDiff? {
        guard let request, let answered = fileDiffRequest,
              answered.target == request.target, answered.file == request.file else { return nil }
        return fileDiff
    }

    @objc private func blamePressed(_ sender: Any?) {
        guard let request else { return }
        let fileDiff = requestedFileDiff
        let deleted = fileDiff?.change == .deleted
        let path = deleted ? (fileDiff?.oldPath ?? request.file) : (fileDiff?.newPath ?? request.file)
        delegate?.diff(self, didRequestBlameFor: path, at: Self.blameRevision(for: request.target, deleted: deleted))
    }

    @objc private func historyPressed(_ sender: Any?) {
        guard let request else { return }
        let fileDiff = requestedFileDiff
        delegate?.diff(self, didRequestHistoryFor: fileDiff?.newPath ?? fileDiff?.oldPath ?? request.file)
    }

    /// The revision to blame a target's file at: the commit, or a range's far end; a
    /// deleted file at the revision before its deletion; nil (the working file) for the
    /// working copy, or `HEAD` when the working copy deleted it.
    static func blameRevision(for target: GitDiffTarget, deleted: Bool) -> String? {
        switch target {
        case .commit(let id, _): deleted ? id + "^1" : id
        case .range(let from, let until, _): deleted ? from : until
        case .unstaged, .staged, .untracked: deleted ? "HEAD" : nil
        }
    }

    // MARK: - Failure

    /// Shows `error`'s description over the viewer, or hides it for nil.
    private func showFailure(_ error: Error?) {
        errorLabel.stringValue = error?.localizedDescription ?? ""
        errorLabel.isHidden = error == nil
    }

    /// Logs a failed diff by its case and fields, never git's own output.
    private func logFailure(_ error: Error) {
        let description = GitClientError.logDescription(of: error)
        Self.logger.error("Git diff failed: \(description, privacy: .public)")
    }
}

extension GitDiffViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}
