import Foundation
import AgenticDeveloperHubSDK

/// A read-only rendered markdown document.
///
/// It holds source, not an attributed string: re-rendering on a palette change
/// is what keeps a document in a themed window from going stale, and the
/// renderer is cheap enough that caching would be the more complicated option.
@MainActor
public final class MarkdownViewerController: PlatformViewController {

    let pane: MarkdownTextPane
    private let renderer: MarkdownDocumentRenderer

    public var palette: SemanticPalette {
        didSet { refresh() }
    }

    public var content: String = "" {
        didSet { refresh() }
    }

    public init(palette: SemanticPalette, highlighter: (any CodeHighlighter)? = nil) {
        self.palette = palette
        self.renderer = MarkdownDocumentRenderer(highlighter: highlighter)
        self.pane = MarkdownTextPane(editable: false)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        view = pane
        refresh()
    }

    private func refresh() {
        guard isViewLoaded else { return }
        pane.applyTheme(palette)
        pane.setAttributedText(renderer.render(
            content,
            palette: palette,
            textColor: palette.platformColor(.primaryText)))
    }
}
