import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKLanguage

/// What the merge view asks for: the resolved text written to `path`, or the view closed.
/// The view writes nothing; its delegate does.
public enum GitMergeIntent: Equatable, Sendable {
    case save(path: String, text: String)
    case cancel
}

@MainActor public protocol GitMergeViewDelegate: AnyObject {
    func mergeView(_ view: GitMergeViewController, didRequest intent: GitMergeIntent)
}

/// The git window's 3-way merge view (recipe `workspace/git/git-merge-view`): one
/// conflicted file's ours and theirs side by side, scroll-locked and aligned with filler
/// rows, over the result the choices made so far give.
///
/// Previous and Next step through the conflicts and scroll every pane to the current
/// one; Ours, Theirs, Both and Base choose it (Base only when the conflict recorded a
/// base). Save is enabled once every conflict has a choice and sends the resolved text;
/// Cancel sends `.cancel`. The panes are syntax-coloured by the file's language once the
/// colouring lands; a later `show` drops an earlier one's colours. Used on the main thread.
@MainActor
public final class GitMergeViewController: NSViewController {
    /// The largest working file the merge view opens; a larger one opens as its diff, so
    /// laying out three panes never stalls the main thread on a huge file.
    public static let maximumFileBytes = 1 << 20

    public weak var delegate: GitMergeViewDelegate?

    /// The choice made for each conflict so far, by conflict index.
    public private(set) var choices: [Int: GitConflictDocument.Choice] = [:]
    /// The conflict the controls act on, 0-based.
    public private(set) var currentConflict = 0
    /// The file shown, or nil before the first `show`.
    public private(set) var path: String?
    public private(set) var document: GitConflictDocument?

    let controlsRow = NSStackView()
    let previousButton = NSButton(title: "Previous", target: nil, action: nil)
    let nextButton = NSButton(title: "Next", target: nil, action: nil)
    let oursButton = NSButton(title: "Ours", target: nil, action: nil)
    let theirsButton = NSButton(title: "Theirs", target: nil, action: nil)
    let bothButton = NSButton(title: "Both", target: nil, action: nil)
    let baseButton = NSButton(title: "Base", target: nil, action: nil)
    let positionLabel = ThemedLabel(role: .secondaryText, textRole: .caption)
    let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    let saveButton = NSButton(title: "Save", target: nil, action: nil)

    let oursLabel = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    let theirsLabel = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    let resultLabel = ThemedLabel(string: "Result", role: .secondaryText, textRole: .caption, weight: .semibold)
    let oursViewer = LineViewerViewController(identifier: "git.merge.ours")
    let theirsViewer = LineViewerViewController(identifier: "git.merge.theirs")
    let resultViewer = LineViewerViewController(identifier: "git.merge.result")
    let splitView = ThemedSplitView()
    let sidesSplit = ThemedSplitView()

    /// The colouring in flight or last finished; tests await it.
    private(set) var colourTask: Task<Void, Never>?
    /// The rows shown; the viewers hold their data sources weakly, so this keeps them.
    private(set) var layout: GitMergeLayout?
    private var colours: GitMergeColours?
    private var generation = 0
    /// A scroll to the current conflict that `show` asked for and has not happened yet.
    private var scrollPending = false
    private var scrollSync: LineViewerScrollSync?
    private let coloring: GitSyntaxColoring?

    public init(coloring: GitSyntaxColoring?) {
        self.coloring = coloring
        super.init(nibName: nil, bundle: nil)
        configureControls()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.merge")
        for viewer in [oursViewer, theirsViewer, resultViewer] { addChild(viewer) }

        sidesSplit.accessibilityID("git.merge.sides")
        sidesSplit.isVertical = true
        sidesSplit.dividerStyle = .thin
        let oursPane = pane("ours", label: oursLabel, viewer: oursViewer)
        let theirsPane = pane("theirs", label: theirsLabel, viewer: theirsViewer)
        sidesSplit.addArrangedSubview(oursPane)
        sidesSplit.addArrangedSubview(theirsPane)
        splitView.accessibilityID("git.merge.split")
        splitView.isVertical = false
        splitView.dividerStyle = .thin
        splitView.addArrangedSubview(sidesSplit)
        splitView.addArrangedSubview(pane("result", label: resultLabel, viewer: resultViewer))
        // Ours and theirs are aligned row for row; the result is not, and scrolls alone.
        scrollSync = LineViewerScrollSync([oursViewer, theirsViewer])

        for view in [controlsRow, splitView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            controlsRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            controlsRow.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
            controlsRow.topAnchor.constraint(equalTo: root.topAnchor, constant: 6),
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: controlsRow.bottomAnchor, constant: 6),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            oursPane.widthAnchor.constraint(equalTo: theirsPane.widthAnchor)
        ])
        view = root
        render()
        updateControls()
    }

    /// Finishes a scroll `show` asked for before the panes had a size: a `show` that runs
    /// before the view is loaded, or before it is first laid out.
    public override func viewDidLayout() {
        super.viewDidLayout()
        if scrollPending { scrollToCurrent() }
    }

    // MARK: - Showing a file

    /// Shows `document`, the conflicted text of `path`, with no choices made and the first
    /// conflict current, uncoloured until its colours land.
    public func show(path: String, document: GitConflictDocument) {
        generation += 1
        colourTask?.cancel()
        self.path = path
        self.document = document
        choices = [:]
        currentConflict = 0
        colours = nil
        let labels = Self.labels(of: document)
        oursLabel.stringValue = labels.ours.isEmpty ? "Ours" : labels.ours
        theirsLabel.stringValue = labels.theirs.isEmpty ? "Theirs" : labels.theirs
        render()
        updateControls()
        scrollPending = true
        scrollToCurrent()
        loadColours()
    }

    private static func labels(of document: GitConflictDocument) -> (ours: String, theirs: String) {
        for segment in document.segments {
            if case let .conflict(_, _, _, ours, theirs) = segment { return (ours, theirs) }
        }
        return ("", "")
    }

    private func loadColours() {
        guard let coloring, let path, let document else { return }
        let generation = self.generation
        let texts = GitMergeLayout.texts(of: document)
        colourTask = Task { [weak self] in
            let ours = await coloring.lines(for: Data(texts.ours.utf8), path: path)
            let theirs = await coloring.lines(for: Data(texts.theirs.utf8), path: path)
            let base = await coloring.lines(for: Data(texts.base.utf8), path: path)
            guard let self, generation == self.generation else { return }
            self.colours = GitMergeColours(ours: ours, theirs: theirs, base: base)
            self.render()
        }
    }

    private func render() {
        guard isViewLoaded else { return }
        layout = document.map { GitMergeLayout.make(document: $0, choices: choices, colours: colours) }
        oursViewer.dataSource = layout?.ours
        theirsViewer.dataSource = layout?.theirs
        resultViewer.dataSource = layout?.result
        for viewer in [oursViewer, theirsViewer, resultViewer] { viewer.reloadData() }
    }

    // MARK: - Controls

    private var conflictCount: Int { document?.conflictCount ?? 0 }

    /// The current conflict's base, nil when it recorded none or nothing is shown.
    private var currentBase: [String]? {
        guard let document else { return nil }
        var index = 0
        for segment in document.segments {
            guard case let .conflict(_, base, _, _, _) = segment else { continue }
            if index == currentConflict { return base }
            index += 1
        }
        return nil
    }

    private func configureControls() {
        controlsRow.orientation = .horizontal
        controlsRow.alignment = .centerY
        controlsRow.spacing = 8
        controlsRow.accessibilityID("git.merge.controls")
        let buttons: [(NSButton, String, Selector)] = [
            (previousButton, "previous", #selector(previousPressed(_:))),
            (nextButton, "next", #selector(nextPressed(_:))),
            (oursButton, "useOurs", #selector(oursPressed(_:))),
            (theirsButton, "useTheirs", #selector(theirsPressed(_:))),
            (bothButton, "useBoth", #selector(bothPressed(_:))),
            (baseButton, "useBase", #selector(basePressed(_:))),
            (cancelButton, "cancel", #selector(cancelPressed(_:))),
            (saveButton, "save", #selector(savePressed(_:)))
        ]
        for (button, name, action) in buttons {
            button.target = self
            button.action = action
            button.bezelStyle = .push
            button.controlSize = .small
            button.accessibilityID("git.merge.\(name)")
        }
        positionLabel.accessibilityID("git.merge.position")
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        spacer.accessibilityID("git.merge.spacer")
        for view in [previousButton, nextButton, positionLabel, oursButton, theirsButton, bothButton, baseButton,
                     spacer, cancelButton, saveButton] {
            controlsRow.addArrangedSubview(view)
        }
        updateControls()
    }

    private func updateControls() {
        let total = conflictCount
        previousButton.isEnabled = currentConflict > 0
        nextButton.isEnabled = currentConflict + 1 < total
        for button in [oursButton, theirsButton, bothButton] { button.isEnabled = total > 0 }
        baseButton.isEnabled = currentBase != nil
        positionLabel.stringValue = total > 0 ? "\(currentConflict + 1) of \(total)" : ""
        saveButton.isEnabled = document?.resolved(choices) != nil
        cancelButton.isEnabled = document != nil
    }

    /// Scrolls ours (and theirs with it) and the result to the current conflict. Before
    /// the panes have a height there is nothing to scroll, so the scroll stays pending
    /// until `viewDidLayout`.
    private func scrollToCurrent() {
        guard isViewLoaded, let layout, layout.sideStarts.indices.contains(currentConflict) else { return }
        let laidOut = [oursViewer, resultViewer].allSatisfy { $0.scrollView.contentView.bounds.height > 0 }
        scrollPending = !laidOut
        guard laidOut else { return }
        oursViewer.scrollToRow(layout.sideStarts[currentConflict])
        resultViewer.scrollToRow(layout.resultStarts[currentConflict])
    }

    private func move(by step: Int) {
        let target = currentConflict + step
        guard target >= 0, target < conflictCount else { return }
        currentConflict = target
        updateControls()
        scrollToCurrent()
    }

    private func choose(_ choice: GitConflictDocument.Choice) {
        guard currentConflict < conflictCount else { return }
        if choice == .base, currentBase == nil { return }
        choices[currentConflict] = choice
        render()
        updateControls()
        scrollToCurrent()
    }

    @objc private func previousPressed(_ sender: Any?) { move(by: -1) }
    @objc private func nextPressed(_ sender: Any?) { move(by: 1) }
    @objc private func oursPressed(_ sender: Any?) { choose(.ours) }
    @objc private func theirsPressed(_ sender: Any?) { choose(.theirs) }
    @objc private func bothPressed(_ sender: Any?) { choose(.oursThenTheirs) }
    @objc private func basePressed(_ sender: Any?) { choose(.base) }

    @objc private func cancelPressed(_ sender: Any?) {
        delegate?.mergeView(self, didRequest: .cancel)
    }

    @objc private func savePressed(_ sender: Any?) {
        guard let path, let text = document?.resolved(choices) else { return }
        delegate?.mergeView(self, didRequest: .save(path: path, text: text))
    }

    private func pane(_ name: String, label: ThemedLabel, viewer: LineViewerViewController) -> NSView {
        let pane = NSView()
        pane.accessibilityID("git.merge.\(name)Pane")
        label.accessibilityID("git.merge.\(name)Label")
        let viewerView = viewer.view
        for view in [label, viewerView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            pane.addSubview(view)
        }
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: pane.trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: pane.topAnchor, constant: 4),
            viewerView.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            viewerView.trailingAnchor.constraint(equalTo: pane.trailingAnchor),
            viewerView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            viewerView.bottomAnchor.constraint(equalTo: pane.bottomAnchor),
            pane.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        return pane
    }
}
