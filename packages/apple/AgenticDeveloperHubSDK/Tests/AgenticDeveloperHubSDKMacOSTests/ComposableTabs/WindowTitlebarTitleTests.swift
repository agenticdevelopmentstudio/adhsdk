import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The title's size is worked out from its icon and label rather than asked
/// of the stack, because asking the stack once it is in a title bar stalls
/// the main queue for seconds. These pin the hand computation to what the
/// stack itself answers while it is detached, where asking is cheap.
@MainActor
final class WindowTitlebarTitleTests: XCTestCase {

    func testTheComputedSizeIsTheStacksFittingSize() {
        for symbol in ["dollarsign.circle", nil] {
            for text in ["", "Billing Activity", String(repeating: "A long project name ", count: 6)] {
                let title = WindowTitlebarTitle()
                title.setSymbol(symbol)
                title.text = text
                let computed = WindowTitlebarTitle.contentSize(
                    label: title.titleLabel.intrinsicContentSize, showsIcon: !title.iconView.isHidden,
                    insets: NSEdgeInsets(top: 0, left: 6, bottom: 0, right: 6), spacing: 5)
                let fitting = title.view.fittingSize
                XCTAssertEqual(computed.width, ceil(fitting.width), accuracy: 0.5,
                               "width for symbol \(symbol ?? "none"), text \"\(text)\"")
                XCTAssertEqual(computed.height, ceil(fitting.height), accuracy: 0.5,
                               "height for symbol \(symbol ?? "none"), text \"\(text)\"")
            }
        }
    }

    /// Installed, the title is as wide as its content, at most the window's
    /// width less what the trailing accessories keep, and as tall as the bar.
    func testAnInstalledTitleFitsItsTextAndFillsTheTitleBar() {
        let detached = WindowTitlebarTitle()
        detached.setSymbol("dollarsign.circle")
        detached.text = "Billing Activity"
        let expectedWidth = ceil(detached.view.fittingSize.width)

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        defer { window.close() }
        window.isReleasedWhenClosed = false
        let title = WindowTitlebarTitle()
        title.setSymbol("dollarsign.circle")
        title.text = "Billing Activity"
        title.install(in: window)

        XCTAssertEqual(title.view.frame.width, expectedWidth, accuracy: 0.5)
        XCTAssertEqual(title.view.frame.height, WindowTitlebarTitle.titlebarHeight(of: window), accuracy: 0.5)
        XCTAssertEqual(window.title, "Billing Activity")
        XCTAssertEqual(window.titleVisibility, .hidden)
    }

    /// Under a unified toolbar the bar is taller than a plain title bar's
    /// 28pt, and the title fills all of it from the moment it is installed.
    func testAnInstalledTitleFillsAUnifiedToolbarsBar() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        defer { window.close() }
        window.isReleasedWhenClosed = false
        window.toolbar = NSToolbar(identifier: "window-titlebar-title-tests")
        window.toolbarStyle = .unified
        let bar = WindowTitlebarTitle.titlebarHeight(of: window)
        XCTAssertGreaterThan(bar, 28, "the toolbar should make the bar taller than a plain title bar")

        let title = WindowTitlebarTitle()
        title.text = "Billing Activity"
        title.install(in: window)

        XCTAssertEqual(title.view.frame.height, bar, accuracy: 0.5)
    }

    func testALongTitleIsCappedToTheRoomTheWindowLeaves() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        defer { window.close() }
        window.isReleasedWhenClosed = false
        let title = WindowTitlebarTitle()
        title.text = String(repeating: "A long project name ", count: 6)
        title.install(in: window)

        XCTAssertEqual(title.view.frame.width, window.frame.width - 160, accuracy: 0.5)
    }

    /// A window narrower than the room the trailing accessories keep (one
    /// whose default frame is still being applied) leaves the title only its
    /// icon and insets. Narrower than that, the stack's own constraints
    /// conflicted and AppKit broke the icon's width to recover.
    func testANarrowWindowKeepsTheIconWhole() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 120, height: 200),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        defer { window.close() }
        window.isReleasedWhenClosed = false
        let title = WindowTitlebarTitle()
        title.setSymbol("dollarsign.circle")
        title.text = "Billing Activity"
        title.install(in: window)

        let minimum = WindowTitlebarTitle.contentSize(
            label: NSSize(width: 0, height: title.titleLabel.intrinsicContentSize.height), showsIcon: true,
            insets: NSEdgeInsets(top: 0, left: 6, bottom: 0, right: 6), spacing: 5).width
        XCTAssertEqual(title.view.frame.width, minimum, accuracy: 0.5)
        title.view.layoutSubtreeIfNeeded()
        XCTAssertEqual(title.iconView.frame.width, WindowTitlebarTitle.iconSize, accuracy: 0.5,
                       "the icon's width constraint was broken to fit the title")
    }
}
