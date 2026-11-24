import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKLanguage
import os

/// What the diff's row menu asks for: some of the shown file's lines staged, unstaged or
/// discarded. The diff never runs git; its delegate does.
public enum GitDiffIntent: Equatable, Sendable {
    case stage(GitPatchSelection)
    case unstage(GitPatchSelection)
    case discard(GitPatchSelection)
}

/// Told when the diff's Blame or History button is pressed for the shown file, and when a
/// row menu asks for lines to be staged, unstaged or discarded.
@MainActor public protocol GitDiffDelegate: AnyObject {
    /// Blame `path` at `revision`; nil means the working file.
    func diff(_ diff: GitDiffViewController, didRequestBlameFor path: String, at revision: String?)
    func diff(_ diff: GitDiffViewController, didRequestHistoryFor path: String)
    func diff(_ diff: GitDiffViewController, didRequest intent: GitDiffIntent)
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
/// shown in place of the rows. On a staged or unstaged diff read with the default options,
/// a row's context menu stages, unstages or discards its hunk or the selected lines, each a
/// `GitDiffIntent` sent to the delegate. Used on the main thread.
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
    /// The one summary row of an LFS pointer diff, in place of the pointer text; hidden otherwise.
    let lfsLabel = GitDiffViewController.makeLFSLabel()

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
    /// The options `fileDiff` was read with. A patch only applies to hunks read with the
    /// defaults: ignoring whitespace gives hunks git cannot apply against the real files.
    private var fileDiffOptions: GitDiffOptions?
    private var colouredSides: (old: [StyledLine]?, new: [StyledLine]?)?
    /// The word highlighting last worked out, reused while the diff and the toggle stay the
    /// same, so colouring a diff in does not run its word diff a second time.
    private var emphasis: GitDiffEmphasis?
    /// The target and file the viewers' rows were last built for; a selection is kept
    /// across a rebuild only for the same one.
    private var renderedRequest: (target: GitDiffTarget, file: String)?
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
        place(lfsLabel, in: root, under: inlineView)
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
        errorLabel.show(error: nil)
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

    /// Whether the shown target is the working copy (staged, unstaged, untracked or conflicted),
    /// whose diff changes as files are edited.
    public var isShowingWorkingCopy: Bool {
        switch request?.target {
        case .unstaged, .staged, .untracked, .conflicted: true
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
        emphasis = nil
        errorLabel.show(error: nil)
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
                self.errorLabel.show(error: error)
                return
            case .success(let diff):
                let fileDiff = Self.file(request.file, in: diff)
                // A reload that read the same diff keeps its rows (and their colours) until
                // the recolouring lands, rather than building them uncoloured first.
                let unchanged = fileDiff != nil && fileDiff == self.fileDiff && options == self.fileDiffOptions
                    && self.fileDiffRequest.map { $0.target == request.target && $0.file == request.file } == true
                self.fileDiff = fileDiff
                self.fileDiffRequest = request
                self.fileDiffOptions = options
                if !unchanged {
                    self.colouredSides = nil
                    self.render()
                }
                guard let fileDiff, let coloring, !fileDiff.isBinary, GitLFSDiffSummary.of(fileDiff) == nil else {
                    return
                }
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

    /// Rebuilds the shown layout's rows from the diff and colours already read. A viewer's
    /// selection survives when every selected row shows the same hunk line, with the same
    /// text, afterwards; otherwise it is cleared, so no stale row is ever selected.
    private func render() {
        guard isViewLoaded else { return }
        let words = settings.get(UserSettings.gitDiffWordHighlight)
        let sides = colouredSides
        let viewers = [inlineViewer, leftViewer, rightViewer]
        let current = fileDiff == nil ? nil : fileDiffRequest
        let sameFile = current != nil && renderedRequest?.target == current?.target
            && renderedRequest?.file == current?.file
        let before = viewers.map { sameFile ? selectedLineRows(in: $0) : [:] }
        renderedRequest = current
        inlineModel = nil
        sideModels = nil
        let lfsSummary = fileDiff.flatMap(GitLFSDiffSummary.of)
        showLFS(lfsSummary)
        if let fileDiff, lfsSummary == nil {
            let emphasis = emphasis(for: fileDiff, enabled: words)
            switch layout {
            case .inline:
                inlineModel = GitInlineDiffModel(diff: fileDiff, oldLines: sides?.old, newLines: sides?.new,
                                                 emphasis: emphasis)
            case .sideBySide:
                sideModels = GitSideBySideDiffModel.make(diff: fileDiff, oldLines: sides?.old,
                                                         newLines: sides?.new, emphasis: emphasis)
            }
        }
        inlineViewer.dataSource = inlineModel
        leftViewer.dataSource = sideModels?.left
        rightViewer.dataSource = sideModels?.right
        for (viewer, selected) in zip(viewers, before) {
            viewer.reloadData()
            guard !selected.isEmpty, selectedLineRows(in: viewer, rows: IndexSet(selected.keys)) == selected else {
                continue
            }
            viewer.selectRows(IndexSet(selected.keys))
        }
    }

    /// What `viewer`'s selected rows (or `rows`) show, by row: each one's line ref and
    /// text. A row past the end is left out, so the comparison after a reload fails.
    private func selectedLineRows(in viewer: LineViewerViewController,
                                  rows: IndexSet? = nil) -> [Int: SelectedLine] {
        let refs = lineRefs(for: viewer)
        guard let source = viewer.dataSource else { return [:] }
        var result: [Int: SelectedLine] = [:]
        for row in rows ?? viewer.selectedRows where refs.indices.contains(row) && row < source.rowCount {
            result[row] = SelectedLine(ref: refs[row], text: source.row(at: row).text)
        }
        return result
    }

    private struct SelectedLine: Equatable {
        let ref: GitDiffLineRef?
        let text: String
    }

    /// The cached word highlighting when it was worked out for `fileDiff` and `enabled`,
    /// else a fresh one, which becomes the cache.
    private func emphasis(for fileDiff: GitFileDiff, enabled: Bool) -> GitDiffEmphasis {
        if let emphasis, emphasis.matches(fileDiff, enabled: enabled) { return emphasis }
        let fresh = GitDiffEmphasis(diff: fileDiff, enabled: enabled)
        emphasis = fresh
        return fresh
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
        spacer.accessibilityID("git.diff.spacer")
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
        for viewer in [inlineViewer, leftViewer, rightViewer] {
            viewer.menuProvider = { [weak self, weak viewer] row, rows in
                guard let self, let viewer else { return nil }
                return self.stagingMenu(in: viewer, clickedRow: row, selectedRows: rows)
            }
        }
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
        errorLabel.show(error: nil)
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
        case .unstaged, .staged, .untracked, .conflicted: deleted ? "HEAD" : nil
        }
    }

    // MARK: - Staging menu

    /// The row menu: on an unstaged diff Stage and Discard, on a staged one Unstage, each of
    /// the clicked row's hunk and of the selected changed lines. None for any other target,
    /// a file no patch can be built for, a diff read ignoring whitespace, a row with no
    /// hunk, or while a different file is loading.
    private func stagingMenu(in viewer: LineViewerViewController, clickedRow: Int,
                             selectedRows: IndexSet) -> NSMenu? {
        guard let file = requestedFileDiff, let target = fileDiffRequest?.target,
              fileDiffOptions == GitDiffOptions(), GitPatchBuilder.canBuild(for: file),
              let hunk = hunk(at: clickedRow, in: viewer) else { return nil }
        let lines = selectedLines(selectedRows, in: viewer, of: file)
        let hunkSelection = GitPatchSelection.hunk(hunk, of: file)
        let lineSelection = lines.isEmpty ? nil : GitPatchSelection(file: file, lines: lines)
        let menu = NSMenu()
        switch target {
        case .unstaged:
            menu.addItem(menuItem("Stage Hunk", "stageHunk", .stage(hunkSelection)))
            if let lineSelection { menu.addItem(menuItem("Stage Lines", "stageLines", .stage(lineSelection))) }
            menu.addItem(.separator())
            menu.addItem(menuItem("Discard Hunk…", "discardHunk", .discard(hunkSelection)))
            if let lineSelection {
                menu.addItem(menuItem("Discard Lines…", "discardLines", .discard(lineSelection)))
            }
        case .staged:
            menu.addItem(menuItem("Unstage Hunk", "unstageHunk", .unstage(hunkSelection)))
            if let lineSelection {
                menu.addItem(menuItem("Unstage Lines", "unstageLines", .unstage(lineSelection)))
            }
        case .commit, .range, .untracked, .conflicted:
            return nil
        }
        return menu
    }

    /// The line refs of the rows `viewer` shows, its own side's alone: the two side-by-side
    /// viewers keep separate selections, so the left one's rows stand for removed lines and
    /// the right one's for added lines, never for the other side's partner.
    private func lineRefs(for viewer: LineViewerViewController) -> [GitDiffLineRef?] {
        if viewer === inlineViewer { return inlineModel?.lineRefs ?? [] }
        if viewer === leftViewer { return sideModels?.left.lineRefs ?? [] }
        return sideModels?.right.lineRefs ?? []
    }

    /// The hunk of row `row` of `viewer`: its own ref's, else (a filler) the nearest row
    /// above it with one.
    private func hunk(at row: Int, in viewer: LineViewerViewController) -> Int? {
        let refs = lineRefs(for: viewer)
        guard refs.indices.contains(row) else { return nil }
        return refs[...row].last { $0 != nil }??.hunk
    }

    /// Every added or removed line among `viewer`'s selected `rows`, by hunk.
    private func selectedLines(_ rows: IndexSet, in viewer: LineViewerViewController,
                               of file: GitFileDiff) -> [Int: IndexSet] {
        let refs = lineRefs(for: viewer)
        var lines: [Int: IndexSet] = [:]
        for row in rows where refs.indices.contains(row) {
            guard let ref = refs[row], let index = ref.line, file.hunks.indices.contains(ref.hunk),
                  file.hunks[ref.hunk].lines.indices.contains(index),
                  GitPatchBuilder.isChange(file.hunks[ref.hunk].lines[index]) else { continue }
            lines[ref.hunk, default: IndexSet()].insert(index)
        }
        return lines
    }

    private func menuItem(_ title: String, _ name: String, _ intent: GitDiffIntent) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(performMenuIntent(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = MenuPayload(intent)
        item.accessibilityID("git.diff.menu.\(name)")
        return item
    }

    /// Sends the item's intent, then clears the selection the intent was made from.
    @objc private func performMenuIntent(_ sender: NSMenuItem) {
        guard let intent = sender.payload(GitDiffIntent.self) else { return }
        delegate?.diff(self, didRequest: intent)
        for viewer in [inlineViewer, leftViewer, rightViewer] { viewer.clearSelection() }
    }

    // MARK: - Failure

    /// Logs a failed diff by its case and fields, never git's own output.
    private func logFailure(_ error: Error) {
        let description = GitClientError.logDescription(of: error)
        Self.logger.error("Git diff failed: \(description, privacy: .public)")
    }
}

extension GitDiffViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}
