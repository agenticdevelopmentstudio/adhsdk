import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKUI

/// How a Markdown pane arranges its Markdown and Preview panes.
public enum MarkdownPaneLayout: String, Codable, Sendable, CaseIterable {
    /// One pane at a time, both as tabs of one frame.
    case singlePane
    /// Both panes, each in its own frame, next to each other.
    case sideBySide
}

/// A Markdown pane's two panes: the source and its rendering.
public enum MarkdownPaneContent: String, Codable, Sendable, CaseIterable {
    case markdown
    case preview

    /// The tab title, tooltip and accessibility label.
    public var title: String {
        switch self {
        case .markdown: return "Markdown"
        case .preview: return "Preview"
        }
    }
}

@MainActor
extension UserSettings {
    /// Whether a Markdown editor opens with one of its panes at a time or
    /// with Markdown and Preview side by side. The last choice made in any
    /// editor; each open editor keeps its own until it is changed there.
    public static let markdownPaneLayout = UserSetting<MarkdownPaneLayout>(
        "markdown.pane.layout", default: .singlePane)

    /// Which pane a single-pane Markdown editor opens on.
    public static let markdownPaneContent = UserSetting<MarkdownPaneContent>(
        "markdown.pane.content", default: .markdown)
}

/// The app's Markdown editor: Markdown, the editable source, and Preview, its
/// rendering, each framed by a tab bar the way the Document pane frames its
/// editors. Every Markdown surface in a pane uses this one — Notations and
/// `.md` documents alike — so a change to it reaches all of them.
///
/// `layoutControl` switches between both panes as tabs of one frame and side
/// by side, each in a frame of its own; the host puts it in its own chrome (a
/// pane's title bar, an editor's navigation bar). In a single pane the tabs
/// pick which pane shows. The tabs have no close buttons; neither pane is
/// ever closed. Both choices are remembered in `UserSettings.markdownPaneLayout`
/// and `.markdownPaneContent`.
@MainActor
public final class MarkdownPaneViewController: NSViewController {

    /// The single-pane / side-by-side control, for the host's chrome.
    public let layoutControl: IconTabBar

    /// Fires on every edit typed into the source.
    public var onTextChange: ((String) -> Void)?

    /// The source. Setting it shows it in both panes at once.
    public var text: String {
        get { source.pane.text }
        set {
            source.pane.text = newValue
            flushPendingRender()
        }
    }

    public var isEditable: Bool {
        get { source.pane.isEditable }
        set { source.pane.isEditable = newValue }
    }

    private let source = MarkdownSourceViewController()
    private let preview = MarkdownViewerController(palette: ThemeScope.app.palette)

    /// Single pane: one frame holding both panes as tabs.
    private let singleFrame = MultiTabbedViewController()
    /// Side by side: a frame per pane, each with its one tab.
    private let markdownFrame = MultiTabbedViewController()
    private let previewFrame = MultiTabbedViewController()
    private let splitView = ThemedSplitView(frame: .zero)

    private let markdownTabID = UUID()
    private let previewTabID = UUID()

    private var layout: MarkdownPaneLayout = UserSettings.markdownPaneLayout.value
    private var shownContent: MarkdownPaneContent = UserSettings.markdownPaneContent.value

    /// True while the panes are being moved between frames, whose removals
    /// and insertions report tab selections that are not the user's.
    private var isRearranging = false
    /// Set when the split view is shown, so the next layout pass with a real
    /// width gives the two frames half each.
    private var needsSplitEqualized = false
    private var pendingRender: DispatchWorkItem?

    /// `opensOn` picks the pane a single-pane editor starts on, for a surface
    /// that wants one regardless of the last choice (the file browser's `.md`
    /// documents open on Preview); nil starts on the remembered one.
    public init(accessibilityID: String = "markdown-pane.layout",
                opensOn initialContent: MarkdownPaneContent? = nil) {
        if let initialContent { shownContent = initialContent }
        layoutControl = IconTabBar(
            items: [
                .init(id: MarkdownPaneLayout.singlePane.rawValue, symbol: "square", title: "Single Pane"),
                .init(id: MarkdownPaneLayout.sideBySide.rawValue, symbol: "square.split.2x1", title: "Side by Side")
            ],
            accessibilityID: accessibilityID)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    isolated deinit {
        pendingRender?.cancel()
    }

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)
        layoutControl.onSelect = { [weak self] id in
            guard let self, let layout = MarkdownPaneLayout(rawValue: id) else { return }
            self.choose(layout: layout)
        }
        for frame in [singleFrame, markdownFrame, previewFrame] {
            frame.delegate = self
            frame.showsCloseButtons = false
            addChild(frame)
        }
        splitView.dividerStyle = .thin
        splitView.delegate = self
        // Neither pane holds its width over the other, so a drag moves the
        // divider rather than being refused by whichever holds harder.
        splitView.setHoldingPriority(.defaultLow, forSubviewAt: 0)
        splitView.setHoldingPriority(.defaultLow, forSubviewAt: 1)
        splitView.addArrangedSubview(markdownFrame.view)
        splitView.addArrangedSubview(previewFrame.view)

        let contentViews: [NSView] = [singleFrame.view, splitView]
        var constraints: [NSLayoutConstraint] = []
        for content in contentViews {
            content.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(content)
            constraints += [
                content.topAnchor.constraint(equalTo: container.topAnchor),
                content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ]
        }
        NSLayoutConstraint.activate(constraints)
        view = container
        applyArrangement()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        source.pane.onTextChange = { [weak self] text in
            self?.scheduleRender()
            self?.onTextChange?(text)
        }
        source.pane.applyTheme(ThemeScope.app.palette)
        view.observeTheme { [weak self] _, palette in
            self?.source.pane.applyTheme(palette)
            self?.preview.palette = palette
        }
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        guard needsSplitEqualized, !splitView.isHidden, splitView.bounds.width > 0 else { return }
        needsSplitEqualized = false
        splitView.setPosition((splitView.bounds.width - splitView.dividerThickness) / 2, ofDividerAt: 0)
    }

    // MARK: - Layout and content

    private func choose(layout: MarkdownPaneLayout) {
        guard layout != self.layout else {
            syncHeader()
            return
        }
        self.layout = layout
        UserSettings.markdownPaneLayout.value = layout
        applyArrangement()
    }

    private func choose(content: MarkdownPaneContent) {
        guard content != shownContent else {
            syncHeader()
            return
        }
        shownContent = content
        UserSettings.markdownPaneContent.value = content
        if layout == .singlePane {
            isRearranging = true
            singleFrame.selectTab(id: tabID(for: content), on: .top)
            isRearranging = false
        }
        syncHeader()
        if content == .preview { flushPendingRender() }
    }

    /// Puts the two panes in the frames `layout` calls for. Every tab is
    /// taken down first, so a pane is only ever in one frame and the frame it
    /// leaves unmounts it.
    private func applyArrangement() {
        isRearranging = true
        for frame in [singleFrame, markdownFrame, previewFrame] {
            for tab in frame.tabs(on: .top) { frame.removeTab(id: tab.id) }
        }
        let markdownTab = MultiTabbedViewController.Tab(
            id: markdownTabID, title: MarkdownPaneContent.markdown.title, viewController: source)
        let previewTab = MultiTabbedViewController.Tab(
            id: previewTabID, title: MarkdownPaneContent.preview.title, viewController: preview)
        switch layout {
        case .singlePane:
            singleFrame.addTab(markdownTab, on: .top)
            singleFrame.addTab(previewTab, on: .top)
            singleFrame.selectTab(id: tabID(for: shownContent), on: .top)
        case .sideBySide:
            markdownFrame.addTab(markdownTab, on: .top)
            previewFrame.addTab(previewTab, on: .top)
            needsSplitEqualized = true
        }
        singleFrame.view.isHidden = layout != .singlePane
        splitView.isHidden = layout != .sideBySide
        isRearranging = false
        syncHeader()
        flushPendingRender()
        view.needsLayout = true
    }

    private func syncHeader() {
        layoutControl.selectedID = layout.rawValue
    }

    private func tabID(for content: MarkdownPaneContent) -> UUID {
        content == .markdown ? markdownTabID : previewTabID
    }

    private func content(forTabID id: UUID) -> MarkdownPaneContent? {
        switch id {
        case markdownTabID: return .markdown
        case previewTabID: return .preview
        default: return nil
        }
    }

    /// Debounced like `MarkdownEditorController`'s preview: a rendering that
    /// repaints on every character makes typing feel slow.
    private func scheduleRender() {
        pendingRender?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.flushPendingRender() }
        }
        pendingRender = work
        DispatchQueue.main.asyncAfter(deadline: .now() + MarkdownEditorController.renderDebounce, execute: work)
    }

    private func flushPendingRender() {
        pendingRender?.cancel()
        pendingRender = nil
        preview.content = source.pane.text
    }
}

extension MarkdownPaneViewController: MultiTabbedViewControllerDelegate {

    /// A tab click in the single-pane frame picks which pane shows.
    public func multiTabbedViewController(
        _ controller: MultiTabbedViewController,
        didSelectTab id: UUID,
        on edge: Edge
    ) {
        guard !isRearranging, controller === singleFrame, let content = content(forTabID: id) else { return }
        choose(content: content)
    }

    /// Neither pane is ever closed. A close that arrives anyway (a menu or a
    /// key) on one of two side-by-side frames leaves the other as a single
    /// pane; in a single pane it is refused.
    public func multiTabbedViewController(
        _ controller: MultiTabbedViewController,
        didRequestCloseTab id: UUID,
        on edge: Edge
    ) {
        guard layout == .sideBySide, let closed = content(forTabID: id) else { return }
        shownContent = closed == .markdown ? .preview : .markdown
        UserSettings.markdownPaneContent.value = shownContent
        choose(layout: .singlePane)
    }

    /// File > New Tab reaches these frames first whenever the keyboard is in
    /// the editor, and they have no tabs to add: hand it on to the nearest
    /// enclosing tabbed container.
    public func multiTabbedViewControllerNeedsNewTab(_ controller: MultiTabbedViewController) {
        var ancestor = parent
        while let candidate = ancestor {
            if let tabbed = candidate as? MultiTabbedViewController {
                tabbed.newTab(nil)
                return
            }
            ancestor = candidate.parent
        }
    }
}

/// The source in a `MarkdownTextPane`, as a view controller so a tab can
/// hold it.
@MainActor
private final class MarkdownSourceViewController: NSViewController {

    let pane = MarkdownTextPane(editable: true)

    init() { super.init(nibName: nil, bundle: nil) }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() { view = pane }
}

/// The side-by-side divider: a thin line is a 1pt target, so its grab area is
/// widened the way the project window's dividers are, and neither pane may be
/// dragged narrower than `minimumPaneWidth`.
extension MarkdownPaneViewController: NSSplitViewDelegate {
    private static let minimumPaneWidth: CGFloat = 120

    public func splitView(
        _ splitView: NSSplitView,
        effectiveRect proposedEffectiveRect: NSRect,
        forDrawnRect drawnRect: NSRect,
        ofDividerAt dividerIndex: Int
    ) -> NSRect {
        let grab = PaneSpacing.minimumDividerGrab
        guard proposedEffectiveRect.width < grab else { return proposedEffectiveRect }
        return proposedEffectiveRect.insetBy(dx: -(grab - proposedEffectiveRect.width) / 2, dy: 0)
    }

    public func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        max(proposedMinimumPosition, Self.minimumPaneWidth)
    }

    public func splitView(
        _ splitView: NSSplitView,
        constrainMaxCoordinate proposedMaximumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        min(proposedMaximumPosition, splitView.bounds.width - splitView.dividerThickness - Self.minimumPaneWidth)
    }
}
