import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Help is reference prose a window can show beside itself. It was spelled as
/// though it belonged to settings; these tests pin the new spelling and, just
/// as importantly, that the old one still works.
@MainActor
final class HelpContentTests: XCTestCase {

    func testHelpContentCarriesItsTopicsInOrder() {
        let content = HelpContent(topics: [
            HelpContent.Topic(title: "First", body: "One."),
            HelpContent.Topic(title: "Second", body: "Two.")
        ])
        XCTAssertEqual(content.topics.map(\.title), ["First", "Second"])
        XCTAssertEqual(content.topics.map(\.body), ["One.", "Two."])
    }

    func testHelpContentIsEquatable() {
        // swiftlint:disable:next identifier_name
        let a = HelpContent(topics: [HelpContent.Topic(title: "T", body: "B")])
        // swiftlint:disable:next identifier_name
        let b = HelpContent(topics: [HelpContent.Topic(title: "T", body: "B")])
        XCTAssertEqual(a, b)
    }

    /// The whole reason the rename is safe: 28 files still say `PanelHelp`.
    func testTheOldSettingsSpellingsStillNameTheSameTypes() {
        let viaAlias: ComposableSettings.PanelHelp = HelpContent(
            topics: [ComposableSettings.PanelHelp.Topic(title: "T", body: "B")])
        XCTAssertEqual(viaAlias.topics.count, 1)
        XCTAssertTrue(ComposableSettings.HelpDrawerView.self == HelpContentView.self)
    }

    func testEmptyContentRendersTheHonestEmptyStateRatherThanBlank() {
        let view = HelpContentView()
        view.setHelp(nil)
        XCTAssertTrue(
            Self.labels(in: view).contains("No Help Yet"),
            "A drawer that no longer closes itself on an empty panel has to say why it is empty")
    }

    func testSetHelpRendersOneGroupPerTopic() {
        let view = HelpContentView()
        view.setHelp(HelpContent(topics: [
            HelpContent.Topic(title: "Frames", body: "How panes are spaced."),
            HelpContent.Topic(title: "Tabs", body: "How tabs work.")
        ]))
        let labels = Self.labels(in: view)
        XCTAssertTrue(labels.contains("Frames"))
        XCTAssertTrue(labels.contains("Tabs"))
        XCTAssertFalse(labels.contains("No Help Yet"))
    }

    // MARK: - Conformance vectors help-content-view-001 ... 012

    private final class StubThemeStorage: ThemeStorage {
        var customThemes: [ColorTheme] = []
        var activeThemeID: String?
        var onExternalChange: (() -> Void)?
    }

    private static let tallContent = HelpContent(topics: (0..<30).map {
        HelpContent.Topic(
            title: "Topic \($0)",
            body: String(repeating: "A long line of help prose. ", count: 12))
    })

    /// The view pinned inside a container of a known size, laid out.
    private func host(_ view: HelpContentView, width: CGFloat = 320, height: CGFloat = 240) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        container.layoutSubtreeIfNeeded()
        return container
    }

    private func heading(of view: HelpContentView) throws -> NSTextField {
        try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first { $0.stringValue == "Help" })
    }

    private func scrollView(of view: HelpContentView) throws -> NSScrollView {
        try XCTUnwrap(view.subviews.compactMap { $0 as? NSScrollView }.first)
    }

    private static func descendants<T: NSView>(of type: T.Type, in view: NSView) -> [T] {
        var found: [T] = []
        for subview in view.subviews {
            if let match = subview as? T { found.append(match) }
            found.append(contentsOf: descendants(of: type, in: subview))
        }
        return found
    }

    /// The (title, explanation texts) of every group in the scrolled panel, in order.
    private func groups(of view: HelpContentView) throws -> [(title: String?, rows: [String])] {
        let document = try XCTUnwrap(try scrollView(of: view).documentView)
        return Self.descendants(of: ComposableSettings.GroupView.self, in: document).map { group in
            (group.title, Self.descendants(of: ComposableSettings.ExplanationView.self, in: group).map(\.text))
        }
    }

    private static let emptySentence = "This panel doesn't have any help written for it. "
        + "Its controls each carry their own explanation underneath."

    func testV1_headingIsFixedHelpLabelInsetFromTopAndLeading() throws {
        let view = HelpContentView()
        _ = host(view)
        let label = try heading(of: view)
        let inset = ComposableSettings.SettingsLayout.default[.panelInset]
        // Anchors place the text's alignment rect; the field's frame carries
        // its padding beyond that.
        let text = label.alignmentRect(forFrame: label.frame)
        XCTAssertEqual(text.minX, inset, accuracy: 0.5)
        XCTAssertEqual(view.bounds.height - text.maxY, inset, accuracy: 0.5)
        XCTAssertLessThanOrEqual(text.maxX, view.bounds.width - inset + 0.5)
        let scroll = try scrollView(of: view)
        XCTAssertFalse(label.isDescendant(of: scroll), "the heading must sit outside the scroll view")
    }

    func testV2_headingStaysPutWhileContentScrolls() throws {
        let view = HelpContentView()
        _ = host(view)
        view.setHelp(Self.tallContent)
        view.layoutSubtreeIfNeeded()
        let label = try heading(of: view)
        let before = label.frame
        let scroll = try scrollView(of: view)
        let document = try XCTUnwrap(scroll.documentView)
        XCTAssertGreaterThan(document.frame.height, scroll.contentView.bounds.height)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: 200))
        scroll.reflectScrolledClipView(scroll.contentView)
        view.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(scroll.contentView.bounds.origin.y, 0)
        XCTAssertEqual(label.frame, before)
    }

    func testV3_oneGroupPerTopicInOrderWithBodyRow() throws {
        let view = HelpContentView()
        view.setHelp(HelpContent(topics: [
            HelpContent.Topic(title: "A", body: "a"),
            HelpContent.Topic(title: "B", body: "b")
        ]))
        let found = try groups(of: view)
        XCTAssertEqual(found.map { $0.title }, ["A", "B"])
        XCTAssertEqual(found.map { $0.rows }, [["a"], ["b"]])
    }

    func testV4_nilContentShowsTheEmptyState() throws {
        let view = HelpContentView()
        view.setHelp(nil)
        let found = try groups(of: view)
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.first?.title, "No Help Yet")
        XCTAssertEqual(found.first?.rows, [Self.emptySentence])
    }

    func testV5_emptyTopicsShowTheSameEmptyState() throws {
        let view = HelpContentView()
        view.setHelp(HelpContent(topics: []))
        let found = try groups(of: view)
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.first?.title, "No Help Yet")
        XCTAssertEqual(found.first?.rows, [Self.emptySentence])
    }

    func testV6_secondCallReplacesTheFirstWholesale() throws {
        let view = HelpContentView()
        view.setHelp(HelpContent(topics: [
            HelpContent.Topic(title: "Old1", body: "old one"),
            HelpContent.Topic(title: "Old2", body: "old two")
        ]))
        view.setHelp(HelpContent(topics: [HelpContent.Topic(title: "New", body: "new body")]))
        let found = try groups(of: view)
        XCTAssertEqual(found.map { $0.title }, ["New"])
        XCTAssertEqual(found.map { $0.rows }, [["new body"]])
        let labels = Self.labels(in: view)
        XCTAssertFalse(labels.contains("Old1"))
        XCTAssertFalse(labels.contains("old two"))
    }

    func testV7_settingHelpAgainScrollsBackToTheTop() throws {
        let view = HelpContentView()
        _ = host(view)
        view.setHelp(Self.tallContent)
        view.layoutSubtreeIfNeeded()
        let scroll = try scrollView(of: view)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: 300))
        scroll.reflectScrolledClipView(scroll.contentView)
        XCTAssertGreaterThan(scroll.contentView.bounds.origin.y, 0, "precondition: scrolled away from the top")
        view.setHelp(HelpContent(topics: [HelpContent.Topic(title: "Fresh", body: "new")]))
        view.layoutSubtreeIfNeeded()
        XCTAssertEqual(scroll.contentView.bounds.origin.y, 0, accuracy: 0.5)
    }

    func testV8_themeIsAppliedOnConstruction() throws {
        let storage = StubThemeStorage()
        storage.activeThemeID = BuiltInThemes.dracula.id
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        let view = HelpContentView()
        let palette = manager.currentPalette
        let label = try heading(of: view)
        XCTAssertEqual(view.layer?.backgroundColor, palette.windowBackgroundColor.cgColor)
        XCTAssertEqual(label.font, palette.font(.heading))
        XCTAssertEqual(label.textColor, palette.primaryTextColor)
        withExtendedLifetime(manager) {}
    }

    func testV9_themeChangeUpdatesAllThreeProperties() throws {
        let storage = StubThemeStorage()
        storage.activeThemeID = BuiltInThemes.dracula.id
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        let view = HelpContentView()
        let label = try heading(of: view)
        let themeA = manager.currentPalette

        manager.selectTheme(id: BuiltInThemes.nord.id)
        let themeB = manager.currentPalette

        XCTAssertNotEqual(themeA.windowBackgroundColor, themeB.windowBackgroundColor)
        XCTAssertEqual(view.layer?.backgroundColor, themeB.windowBackgroundColor.cgColor)
        XCTAssertEqual(label.font, themeB.font(.heading))
        XCTAssertEqual(label.textColor, themeB.primaryTextColor)
        withExtendedLifetime(manager) {}
    }

    func testV10_codingInitIsRefusedByInspectionOnly() throws {
        throw XCTSkip("init(coder:) is marked unavailable and calls fatalError; the refusal cannot be caught")
    }

    func testV11_headingColorIsThePrimaryTextColorWithNoContrastAdjustment() throws {
        let grey = RGBAColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        let nearGrey = RGBAColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
        let theme = ColorTheme(
            name: "Low contrast", appearance: .dark, foreground: nearGrey, background: grey,
            cursor: nearGrey, selection: grey, ansi: Array(repeating: grey, count: 16))
        let storage = StubThemeStorage()
        storage.customThemes = [theme]
        storage.activeThemeID = theme.id
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        let view = HelpContentView()
        let label = try heading(of: view)
        let palette = manager.currentPalette
        XCTAssertEqual(label.textColor, palette.primaryTextColor)
        withExtendedLifetime(manager) {}
    }

    func testV12_confinementToTheUIThread() throws {
        throw XCTSkip("@MainActor: off-thread use is rejected at build time, so no test can express it")
    }

    private static func labels(in view: NSView) -> [String] {
        var found: [String] = []
        if let field = view as? NSTextField { found.append(field.stringValue) }
        for subview in view.subviews { found.append(contentsOf: labels(in: subview)) }
        return found
    }
}
