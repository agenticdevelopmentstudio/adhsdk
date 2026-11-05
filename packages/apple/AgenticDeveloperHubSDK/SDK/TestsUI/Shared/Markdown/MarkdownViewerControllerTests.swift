import Testing
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
@Suite("MarkdownViewerController")
struct MarkdownViewerControllerTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }

    private func loadedViewer(_ content: String) -> MarkdownViewerController {
        let viewer = MarkdownViewerController(palette: palette)
        viewer.content = content
        _ = viewer.view              // force loadView
        return viewer
    }

    @Test("the viewer shows the rendered document, not its source")
    func showsRenderedText() {
        let viewer = loadedViewer("# Title\n\nbody")
        #expect(viewer.pane.text == "Title\n\nbody")
    }

    @Test("the viewer never lets the reader type into it")
    func viewerIsReadOnly() {
        #expect(loadedViewer("body").pane.isEditable == false)
    }

    @Test("setting content after load re-renders the pane")
    func contentUpdatesAfterLoad() {
        let viewer = loadedViewer("# One")
        viewer.content = "# Two"
        #expect(viewer.pane.text == "Two")
    }

    @Test("frontmatter never reaches the reader")
    func hidesFrontmatter() {
        #expect(loadedViewer("---\ntitle: x\n---\nbody").pane.text == "body")
    }

    @Test("changing the palette re-renders rather than leaving stale colors")
    func paletteChangeRerenders() {
        let viewer = loadedViewer("# Title")
        viewer.palette = SemanticPalette(theme: BuiltInThemes.dracula)
        let color = viewer.pane.attributedText.attributes(at: 0, effectiveRange: nil)[.foregroundColor]
        #expect(color as? PlatformColor == SemanticPalette(theme: BuiltInThemes.dracula).platformColor(.primaryText))
    }
}

/// The half of the pane's behaviour that is the same on both platforms.
/// Driving the platform text view to prove the `delegate = self` wiring is
/// genuinely platform-specific and stays in each bundle's own
/// `MarkdownTextPaneInputTests`.
@MainActor
@Suite("MarkdownTextPane")
struct MarkdownTextPaneTests {

    @Test("setting text programmatically never fires onTextChange")
    func settingTextDoesNotFireOnTextChange() {
        let pane = MarkdownTextPane(editable: true)
        var fired = false
        pane.onTextChange = { _ in fired = true }
        pane.text = "x"
        #expect(fired == false)
    }
}
