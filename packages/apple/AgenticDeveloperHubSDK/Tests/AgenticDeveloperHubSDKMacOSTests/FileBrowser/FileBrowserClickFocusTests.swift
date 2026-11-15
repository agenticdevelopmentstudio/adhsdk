import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// A click that activates the file browser skips the filter refocus only when
/// it lands on a view that takes the keyboard itself. Anywhere else — the
/// breadcrumb strip, a divider, the padding round the filter — takes no first
/// responder, so the filter has to take it or the keys stay in the pane the
/// reader left.
@MainActor
final class FileBrowserClickFocusTests: XCTestCase {
    private var root: URL!
    private var browser: FileBrowserViewController!

    override func setUp() async throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("fbcf-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        browser = FileBrowserViewController(
            rootURL: root,
            excludedURL: root.appendingPathComponent(".build"),
            documentStore: TextDocumentStore()
        )
        browser.view.frame = NSRect(x: 0, y: 0, width: 260, height: 400)
        browser.view.layoutSubtreeIfNeeded()
    }

    override func tearDown() async throws {
        browser = nil
        try? FileManager.default.removeItem(at: root)
    }

    private func subview(_ identifier: String, in view: NSView) -> NSView? {
        if view.accessibilityIdentifier() == identifier { return view }
        for child in view.subviews {
            if let found = subview(identifier, in: child) { return found }
        }
        return nil
    }

    /// The centre of `view`, in the coordinates a mouse-down reports.
    private func windowPoint(atCentreOf view: NSView) -> NSPoint {
        view.convert(NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
    }

    func testAClickOnTheBreadcrumbDoesNotSkipTheRefocus() throws {
        let breadcrumb = try XCTUnwrap(subview("file-browser.breadcrumb", in: browser.view))
        XCTAssertFalse(browser.clickTakesFocus(atWindowPoint: windowPoint(atCentreOf: breadcrumb)))
    }

    func testAClickOnTheFilterSkipsTheRefocus() throws {
        let filter = try XCTUnwrap(subview("file-browser.filter", in: browser.view))
        XCTAssertTrue(browser.clickTakesFocus(atWindowPoint: windowPoint(atCentreOf: filter)))
    }

    func testAClickInTheFilterBarPaddingDoesNotSkipTheRefocus() throws {
        let filter = try XCTUnwrap(subview("file-browser.filter", in: browser.view))
        // Two points beside the field's leading edge: inside its bar, outside
        // the field.
        let beside = filter.convert(NSPoint(x: -2, y: filter.bounds.midY), to: nil)
        XCTAssertFalse(browser.clickTakesFocus(atWindowPoint: beside))
    }

    func testAClickInTheTreeSkipsTheRefocus() throws {
        let breadcrumb = try XCTUnwrap(subview("file-browser.breadcrumb", in: browser.view))
        let filter = try XCTUnwrap(subview("file-browser.filter", in: browser.view))
        // Midway between the breadcrumb and the filter is the tree.
        let top = windowPoint(atCentreOf: breadcrumb)
        let bottom = windowPoint(atCentreOf: filter)
        let middle = NSPoint(x: top.x, y: (top.y + bottom.y) / 2)
        XCTAssertTrue(browser.clickTakesFocus(atWindowPoint: middle))
    }
}
