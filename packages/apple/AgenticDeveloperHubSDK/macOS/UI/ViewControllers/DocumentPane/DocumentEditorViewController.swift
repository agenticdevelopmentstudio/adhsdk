import AppKit
import Combine
import SwiftUI

import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKLanguage

/// One editor inside one pane of one tab.
///
/// Holds its own selection rather than sharing the browser's: two editors side
/// by side show two different files, so "what is selected" cannot be one value
/// for the window. The tree's selection drives *which editor gets told*, not
/// what every editor shows.
@MainActor
public final class DocumentEditorViewController: NSViewController {

    /// Stored under the pane's own prefix, beside `EditorOptionsOverride`.
    public static let fileURLKey = "fileURL"

    public let options: EditorOptionsOverride

    private let store: PaneStateStore
    private let selection = FileBrowserSelection()
    private let documentStore: TextDocumentStore
    private let saveScheduler: TextDocumentSaveScheduler
    private let languageServices: ProjectLanguageServices?

    /// The project root the breadcrumb reads its crumbs relative to.
    private let rootURL: URL
    private let breadcrumb: BreadcrumbView

    /// Every file this editor has shown, for the `‹ ›` before the breadcrumb.
    /// Per editor, because an editor is its tab's document: each open pushes,
    /// and stepping back or forward moves along the trail without pushing.
    private var history = NavigationHistory<URL>()

    /// The `‹ ›` that walks `history`, first in the row above the editor.
    /// Internal so a test can read its segments.
    let backForward = BackForwardControl()

    /// Fires when the displayed file changes, so the tab bar can retitle.
    public var onTitleChange: (() -> Void)?

    /// The rows the options popover is showing, if one is open.
    ///
    /// Weak, and deliberately not an array: the options dialog owns its views and
    /// takes them with it when it closes, so these go nil on their own rather
    /// than keeping a dismissed dialog's checkboxes alive to be written to.
    private weak var lineNumbersRow: WindowOptionsToggle?
    private weak var overviewRow: WindowOptionsToggle?
    private weak var invisiblesRow: WindowOptionsToggle?
    private weak var resetRow: NSButton?

    /// Watches both scopes at once. `EditorOptionsOverride.publish()` fires for
    /// a pane-local edit, for `reset()`, and for a change to the app-wide
    /// setting — and it mutates its stored value *before* sending, so reading
    /// the resolved values from here gives the new ones.
    private var optionsObserver: AnyCancellable?

    /// Asked to show a file the editor itself resolved — a go-to-definition
    /// target in another file, or a file chosen from the breadcrumb's
    /// popover. Routed out rather than handled here, because the browser's
    /// selection is the one place that decides what is open.
    public var onOpenRequest: ((URL) -> Void)?

    /// The file shown, whichever editor shows it: the code editor reads
    /// `selection`, the Markdown editor does not, so neither alone is the answer.
    private var displayedURL: URL?

    /// Markdown files open in the app's Markdown editor — the same one
    /// Notations uses — rather than the code editor. Created on first use;
    /// hidden while any other file is shown.
    private var markdownEditor: MarkdownPaneViewController?
    private var markdownDocument: TextDocument?
    private var markdownLoad: Task<Void, Never>?
    private weak var codeEditorView: NSView?
    private weak var editorContainer: NSView?
    /// The bar row; the Markdown editor's layout control joins it, at the end.
    private weak var navigationRow: NSStackView?

    public var fileURL: URL? {
        get { displayedURL }
        set { show(newValue, persist: true) }
    }

    /// Keeps the breadcrumb inside `rootURL`, as a project's editor does.
    public var confinesBreadcrumbToRoot = false {
        didSet { breadcrumb.confiningRoots = confinesBreadcrumbToRoot ? [rootURL] : [] }
    }

    public init(
        store: PaneStateStore,
        documentStore: TextDocumentStore,
        saveScheduler: TextDocumentSaveScheduler,
        languageServices: ProjectLanguageServices?,
        rootURL: URL
    ) {
        self.store = store
        self.options = EditorOptionsOverride(store: store)
        self.documentStore = documentStore
        self.saveScheduler = saveScheduler
        self.languageServices = languageServices
        self.rootURL = rootURL
        self.breadcrumb = BreadcrumbView(rootURL: rootURL, style: .homeRelative)
        super.init(nibName: nil, bundle: nil)
        breadcrumb.onSelect = { [weak self] url in self?.onOpenRequest?(url) }
        backForward.controlSize = .small
        backForward.accessibilityID("document.back-forward")
        backForward.onBack = { [weak self] in self?.goBack() }
        backForward.onForward = { [weak self] in self?.goForward() }
        optionsObserver = options.objectWillChange.sink { [weak self] _ in
            self?.refreshOptionRows()
        }
        restoreStoredDocument()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// A stored path whose file has since gone restores as an empty editor:
    /// the pane and its tab survive, the document does not.
    private func restoreStoredDocument() {
        guard let path = store.paneStateValue(forKey: Self.fileURLKey) else { return }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            store.setPaneStateValue(nil, forKey: Self.fileURLKey)
            return
        }
        show(url, persist: false)
    }

    /// Whether there is an earlier file in this editor's trail.
    public var canGoBack: Bool { history.canGoBack }

    /// Whether a back step has left a later file to return to.
    public var canGoForward: Bool { history.canGoForward }

    /// Shows the previous file in this editor's trail, without pushing it.
    public func goBack() {
        guard let url = history.goBack() else { return }
        show(url, persist: true, recordsHistory: false)
    }

    /// Shows the next file in this editor's trail, without pushing it.
    public func goForward() {
        guard let url = history.goForward() else { return }
        show(url, persist: true, recordsHistory: false)
    }

    /// `recordsHistory` is false only for a step along the trail itself; every
    /// other way a file arrives — the tree, a breadcrumb, go-to-definition, a
    /// restore — is a new place, and pushes. Emptying the editor pushes
    /// nothing: there is nowhere to go back *to* in an empty editor.
    private func show(_ url: URL?, persist: Bool, recordsHistory: Bool = true) {
        // Asked rather than asserted. Every caller here hands over a bare URL —
        // a restored path, a breadcrumb choice, a go-to-definition target, the
        // tree's own open request — and a directory is among the things they can
        // legitimately name: a package is a directory the tree shows as one
        // item, and so is a folder chosen from a breadcrumb's popover. Told it
        // was a file, `FileEditorView.openableNode` let it through and the
        // editor read a directory off disk.
        displayedURL = url
        let isMarkdown = url.map { !Self.isDirectory($0) && Self.isMarkdown($0) } ?? false
        selection.selectedNode = isMarkdown ? nil : url.map {
            FileTreeNode(url: $0, isDirectory: Self.isDirectory($0))
        }
        showMarkdown(isMarkdown ? url : nil)
        breadcrumb.fileURL = url
        if recordsHistory, let url {
            history.record(url)
        }
        backForward.canGoBack = history.canGoBack
        backForward.canGoForward = history.canGoForward
        if persist {
            store.setPaneStateValue(url?.path, forKey: Self.fileURLKey)
        }
        onTitleChange?()
    }

    private static func isMarkdown(_ url: URL) -> Bool {
        ["md", "markdown"].contains(url.pathExtension.lowercased())
    }

    /// Shows `url` in the Markdown editor, or hides it for nil. The outgoing
    /// Markdown document's pending save is flushed before it is closed, the
    /// same order `FileEditorState` keeps for the code editor.
    private func showMarkdown(_ url: URL?) {
        markdownLoad?.cancel()
        let outgoing = markdownDocument
        markdownDocument = nil
        if let outgoing {
            let scheduler = saveScheduler
            let store = documentStore
            let uri = outgoing.uri
            Task { @MainActor in
                await scheduler.flushPendingSave(uri: uri)
                store.close(uri: uri)
            }
        }
        // Before the view exists (a restore from init), `loadView` calls back.
        guard isViewLoaded else { return }
        codeEditorView?.isHidden = url != nil
        guard let url else {
            markdownEditor?.view.isHidden = true
            markdownEditor?.layoutControl.isHidden = true
            return
        }
        let editor = ensureMarkdownEditor()
        editor.view.isHidden = false
        editor.layoutControl.isHidden = false
        editor.text = ""
        markdownLoad = Task { @MainActor [weak self] in
            let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            guard let self, !Task.isCancelled, self.displayedURL == url else { return }
            let language = LanguageDetection.language(for: url)
            let document = self.documentStore.open(
                uri: url.documentUri,
                languageId: LanguageDetection.lspLanguageId(for: language),
                text: text
            )
            self.markdownDocument = document
            editor.text = document.text
        }
    }

    private func ensureMarkdownEditor() -> MarkdownPaneViewController {
        if let markdownEditor { return markdownEditor }
        let editor = MarkdownPaneViewController(accessibilityID: "document.markdown-layout")
        editor.onTextChange = { [weak self] text in
            guard let self, let document = self.markdownDocument, document.text != text else { return }
            document.replaceAll(with: text)
            self.saveScheduler.schedule(document)
        }
        addChild(editor)
        if let container = editorContainer {
            let editorView = editor.view
            editorView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(editorView)
            NSLayoutConstraint.activate([
                editorView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                editorView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                editorView.topAnchor.constraint(equalTo: container.topAnchor),
                editorView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }
        if let navigationRow {
            editor.layoutControl.setContentHuggingPriority(.required, for: .horizontal)
            navigationRow.addArrangedSubview(editor.layoutControl)
        }
        markdownEditor = editor
        return editor
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    /// Empties the editor without taking the pane with it — what the close box
    /// does on the last pane of the last tab.
    public func clearDocument() {
        show(nil, persist: true)
    }

    public override func loadView() {
        let hosting = NSHostingView(
            rootView: DocumentEditorPaneView(
                selection: selection,
                options: options,
                documentStore: documentStore,
                saveScheduler: saveScheduler,
                languageServices: languageServices,
                openFile: { [weak self] url in self?.onOpenRequest?(url) }
            ).themedRoot()
        )

        // Held still while a shelf slides beside the pane: every new width
        // rewraps every line and rebuilds the find bar, which costs a slide
        // most of its frames.
        let codeEditor = FrameHoldingView(content: hosting)
        // The code editor and, for Markdown files, the Markdown editor share
        // this one slot; exactly one of them is visible.
        let editor = NSView()
        codeEditor.translatesAutoresizingMaskIntoConstraints = false
        editor.addSubview(codeEditor)
        NSLayoutConstraint.activate([
            codeEditor.leadingAnchor.constraint(equalTo: editor.leadingAnchor),
            codeEditor.trailingAnchor.constraint(equalTo: editor.trailingAnchor),
            codeEditor.topAnchor.constraint(equalTo: editor.topAnchor),
            codeEditor.bottomAnchor.constraint(equalTo: editor.bottomAnchor)
        ])
        codeEditorView = codeEditor
        editorContainer = editor
        // Where a pane's title bar would be: back/forward, then the breadcrumb.
        // The editor has no bar inside a Documents tab, so this row is its
        // only chrome.
        let navigationRow = NSStackView(views: [backForward, breadcrumb])
        navigationRow.orientation = .horizontal
        navigationRow.alignment = .centerY
        navigationRow.spacing = 4
        navigationRow.edgeInsets = NSEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        self.navigationRow = navigationRow
        backForward.setContentHuggingPriority(.required, for: .horizontal)
        backForward.setContentCompressionResistancePriority(.required, for: .horizontal)
        breadcrumb.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // The bar the row sits in: the pane's full width, no fill of its own,
        // and a one-point line under it where the editor starts.
        let navigationBar = NSView()
        let barBorder = NSView()
        barBorder.wantsLayer = true
        barBorder.observeTheme { border, palette in
            border.layer?.backgroundColor = palette.nsColor(.outline).cgColor
        }
        for subview in [navigationRow, barBorder] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            navigationBar.addSubview(subview)
        }
        navigationBar.setAccessibilityIdentifier("document-editor.navigation-bar")

        let stack = NSStackView(views: [navigationBar, editor])
        stack.orientation = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        breadcrumb.translatesAutoresizingMaskIntoConstraints = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationRow.topAnchor.constraint(equalTo: navigationBar.topAnchor),
            navigationRow.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            navigationRow.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            navigationRow.heightAnchor.constraint(equalToConstant: 24),
            barBorder.topAnchor.constraint(equalTo: navigationRow.bottomAnchor),
            barBorder.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            barBorder.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            barBorder.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            barBorder.heightAnchor.constraint(equalToConstant: 1),
            breadcrumb.heightAnchor.constraint(equalTo: navigationRow.heightAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            editor.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: stack.trailingAnchor)
        ])

        let root = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 424))
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
        if displayedURL.map(Self.isMarkdown) ?? false {
            showMarkdown(displayedURL)
        }
    }
}

// MARK: - Pane capabilities

extension DocumentEditorViewController: PaneTitleProviding {

    public var paneTitle: String { fileURL?.lastPathComponent ?? "Untitled" }

    public var onPaneTitleChange: (() -> Void)? {
        get { onTitleChange }
        set { onTitleChange = newValue }
    }
}

extension DocumentEditorViewController: PaneOptionsProviding {

    public func makePaneOptionRows() -> [NSView] {
        let lineNumbers = WindowOptionsToggle(
            title: "Show line numbers",
            isOn: options.showLineNumbers,
            onChange: { [weak self] value in self?.options.setShowLineNumbers(value) }
        ).checkboxAccessibilityID("document.options.line-numbers")
        let overview = WindowOptionsToggle(
            title: "Show overview",
            isOn: options.showOverview,
            onChange: { [weak self] value in self?.options.setShowOverview(value) }
        ).checkboxAccessibilityID("document.options.overview")
        let invisibles = WindowOptionsToggle(
            title: "Show invisibles",
            isOn: options.showInvisibles,
            onChange: { [weak self] value in self?.options.setShowInvisibles(value) }
        ).checkboxAccessibilityID("document.options.invisibles")

        let reset = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetOptions))
        reset.bezelStyle = .rounded
        reset.isEnabled = options.isOverridden
        reset.accessibilityID("document.options.reset")
        reset.setAccessibilityLabel("Reset Editor Options to Defaults")

        lineNumbersRow = lineNumbers
        overviewRow = overview
        invisiblesRow = invisibles
        resetRow = reset

        return [lineNumbers, overview, invisibles, reset]
    }

    /// Puts the resolved values back into an open dialog's rows.
    ///
    /// Without this the dialog was a photograph: `Reset to Defaults` cleared
    /// the override, the three checkboxes went on showing the values it had
    /// cleared, and its own button stayed enabled — so the pane and the dialog
    /// disagreed until it was closed and reopened. The app-wide setting moving
    /// while the dialog is open is the same problem arriving from the other side.
    private func refreshOptionRows() {
        lineNumbersRow?.isOn = options.showLineNumbers
        overviewRow?.isOn = options.showOverview
        invisiblesRow?.isOn = options.showInvisibles
        resetRow?.isEnabled = options.isOverridden
    }

    @objc private func resetOptions() {
        options.reset()
    }
}

private struct DocumentEditorPaneView: View {

    @ObservedObject var selection: FileBrowserSelection
    @ObservedObject var options: EditorOptionsOverride
    let documentStore: TextDocumentStore
    let saveScheduler: TextDocumentSaveScheduler
    let languageServices: ProjectLanguageServices?
    let openFile: @MainActor (URL) -> Void

    var body: some View {
        FileEditorView(
            selectedNode: selection.selectedNode,
            documentStore: documentStore,
            saveScheduler: saveScheduler,
            languageServices: languageServices,
            options: options,
            openFile: openFile
        )
    }
}
