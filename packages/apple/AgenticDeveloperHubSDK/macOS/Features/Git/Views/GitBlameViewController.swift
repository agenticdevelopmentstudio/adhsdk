import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKLanguage
import os

/// Told when a commit's sha is clicked in the blame gutter.
@MainActor public protocol GitBlameDelegate: AnyObject {
    func blame(_ blame: GitBlameViewController, didSelectCommit id: String)
}

/// A blame as one `LineViewerDataSource`: the file's lines, syntax coloured, with the
/// short sha, the author's initials and the day of the commit in three gutter columns on
/// the first line of each run of lines from one commit.
@MainActor
final class GitBlameLineModel: LineViewerDataSource {

    let rows: [LineViewerRow]
    /// Each row's commit, by row.
    let commitIDs: [String]

    static let dayWidth = 10

    /// The gutter's day, `yyyy-MM-dd` in the local time zone; one for every model.
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(blame: GitBlame, colours: [StyledLine]?) {
        let formatter = Self.dayFormatter
        let firstLines = Set(blame.runs.map(\.finalLines.lowerBound))
        var rows: [LineViewerRow] = []
        for (index, line) in blame.lines.enumerated() {
            var gutter: [String?] = []
            if firstLines.contains(line.finalLine) {
                let commit = blame.commits[line.commitID]
                let initials = commit.map { PersonInitials.of(name: $0.author.name, fallback: $0.author.email) } ?? ""
                let day = commit.map { formatter.string(from: $0.author.date) } ?? ""
                gutter = [String(line.commitID.prefix(8)), initials, day]
            }
            let runs = (colours.flatMap { index < $0.count ? $0[index].runs : nil } ?? []).map {
                LineViewerRun(range: $0.range, foreground: $0.foreground, fontStyle: $0.fontStyle)
            }
            rows.append(LineViewerRow(text: line.text, runs: runs, gutter: gutter))
        }
        self.rows = rows
        commitIDs = blame.lines.map(\.commitID)
    }

    var gutterColumnCount: Int { 3 }
    var rowCount: Int { rows.count }
    func row(at index: Int) -> LineViewerRow { rows[index] }
    func gutterColumnWidth(_ column: Int) -> Int {
        switch column {
        case 0: 8
        case 1: 2
        default: Self.dayWidth
        }
    }
}

/// The git window's blame (recipe `workspace/git/git-views`, "Blame"): a file at a
/// revision in the toolkit's line viewer, its text syntax coloured, with sha, initials
/// and date in the gutter on the first line of each run. A click on a sha selects that
/// commit through the delegate; the uncommitted run selects nothing.
///
/// The latest `show(path:at:)` wins, decided by the controller's own counter. A blame
/// that fails is logged and its description shown in place of the lines. Used on the
/// main thread.
@MainActor
public final class GitBlameViewController: NSViewController {

    public weak var delegate: GitBlameDelegate?

    let viewer = LineViewerViewController(identifier: "git.blame.lines")
    /// The failed blame's description, over the empty viewer; hidden otherwise.
    let errorLabel = ThemedLabel.wrapping("", width: 400, role: .danger, textRole: .body)

    /// The blame (and its colouring) in flight or last finished; tests await it.
    private(set) var loadTask: Task<Void, Never>?
    /// Bumped by every `show` and `clear` before anything awaits.
    private(set) var generation = 0

    private let source: GitContentSource
    private let coloring: GitSyntaxColoring?
    /// The viewer holds its data source weakly; this keeps it alive.
    private var model: GitBlameLineModel?
    /// The path and revision last asked for, or nil after `clear()`.
    private var shown: (path: String, revision: String?)?

    /// Git's id for lines not yet committed: all zeros, at whichever hash length.
    static func isUncommitted(_ id: String) -> Bool {
        !id.isEmpty && id.allSatisfy { $0 == "0" }
    }

    public init(source: GitContentSource, coloring: GitSyntaxColoring?) {
        self.source = source
        self.coloring = coloring
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.blame")
        addChild(viewer)
        viewer.delegate = self
        errorLabel.accessibilityID("git.blame.error")
        errorLabel.isSelectable = true
        errorLabel.isHidden = true
        let viewerView = viewer.view
        for view in [viewerView, errorLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            viewerView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            viewerView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            viewerView.topAnchor.constraint(equalTo: root.topAnchor),
            viewerView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -12),
            errorLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 10)
        ])
        view = root
    }

    /// Blames `path` at `revision` (nil: the working file). The previous lines stay until
    /// the blame arrives; it shows uncoloured, then coloured from its own text, each only
    /// if no later `show` or `clear` has been made.
    public func show(path: String, at revision: String?) {
        shown = (path, revision)
        generation += 1
        let generation = self.generation
        loadTask?.cancel()
        errorLabel.show(error: nil)
        loadTask = Task { [weak self, source, coloring] in
            let result: Result<GitBlame, Error>
            do {
                result = .success(try await source.blame(path: path, at: revision))
            } catch {
                result = .failure(error)
            }
            guard let self, generation == self.generation else { return }
            switch result {
            case .failure(let error):
                self.setModel(nil)
                let description = GitClientError.logDescription(of: error)
                Self.logger.error("Git blame failed: \(description, privacy: .public)")
                self.errorLabel.show(error: error)
            case .success(let blame):
                self.setModel(GitBlameLineModel(blame: blame, colours: nil))
                guard let coloring, !blame.lines.isEmpty else { return }
                let text = blame.lines.map(\.text).joined(separator: "\n")
                let colours = await coloring.lines(for: Data(text.utf8), path: path)
                guard generation == self.generation, let colours else { return }
                self.setModel(GitBlameLineModel(blame: blame, colours: colours))
            }
        }
    }

    /// Blames the shown path at the shown revision again (the working file changed, or
    /// a Refresh); the latest `show`, `reload` or `clear` wins. Nothing shown, nothing read.
    public func reload() {
        guard let shown else { return }
        show(path: shown.path, at: shown.revision)
    }

    /// Whether the shown blame is of the working file, which changes as it is edited.
    public var isShowingWorkingFile: Bool { shown != nil && shown?.revision == nil }

    /// Shows nothing and drops any blame in flight.
    public func clear() {
        shown = nil
        generation += 1
        loadTask?.cancel()
        loadTask = nil
        errorLabel.show(error: nil)
        setModel(nil)
    }

    private func setModel(_ model: GitBlameLineModel?) {
        self.model = model
        viewer.dataSource = model
        viewer.reloadData()
    }
}

extension GitBlameViewController: LineViewerDelegate {
    public func lineViewer(_ viewer: LineViewerViewController, didSelectRows rows: IndexSet) {}

    public func lineViewer(_ viewer: LineViewerViewController, didClickGutterColumn column: Int, row: Int) {
        guard column == 0, let model, model.commitIDs.indices.contains(row) else { return }
        let id = model.commitIDs[row]
        guard !Self.isUncommitted(id) else { return }
        delegate?.blame(self, didSelectCommit: id)
    }
}

extension GitBlameViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}
