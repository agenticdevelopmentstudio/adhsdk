import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// What the Crawl panel and the item editor write, and that opening them
/// again shows exactly what was written.
@MainActor
final class NotificationSettingsRoundTripTests: XCTestCase {

    private let teal = (red: 0.2, green: 0.4, blue: 0.6)

    override func setUp() async throws {
        try await super.setUp()
        _ = NSApplication.shared
    }

    private func assertColor(
        _ color: NoticeColor, _ expected: (red: Double, green: Double, blue: Double),
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(color.source, .custom, file: file, line: line)
        XCTAssertEqual(color.red, expected.red, accuracy: 0.002, file: file, line: line)
        XCTAssertEqual(color.green, expected.green, accuracy: 0.002, file: file, line: line)
        XCTAssertEqual(color.blue, expected.blue, accuracy: 0.002, file: file, line: line)
    }

    private func crawlPanel(_ store: SettingsStore) -> NotificationCrawlSettingsPanel {
        let panel = NotificationCrawlSettingsPanel(store: store)
        panel.loadViewIfNeeded()
        return panel
    }

    private func control<T: NSView>(_ type: T.Type, _ title: String, in view: NSView) throws -> T {
        let rowView = try XCTUnwrap(row(titled: title, in: view), title)
        return try XCTUnwrap(first(type, in: rowView), title)
    }

    private func editor(_ item: NoticeProfile, store: SettingsStore? = nil) -> NotificationItemEditor {
        let editor = NotificationItemEditor(item: item, store: store ?? makeTestStore(), onDone: { _ in })
        editor.loadViewIfNeeded()
        return editor
    }

    private func components(of well: NSColorWell) -> (red: Double, green: Double, blue: Double) {
        let rgb = well.color.usingColorSpace(.sRGB) ?? well.color
        return (rgb.redComponent, rgb.greenComponent, rgb.blueComponent)
    }

    // MARK: Custom colors

    func testCrawlBackgroundCustomColorRoundTrips() throws {
        let store = makeTestStore()
        let panel = crawlPanel(store)
        let popup = try control(NSPopUpButton.self, "Background color", in: panel.view)
        let well = try control(NSColorWell.self, "Background color", in: panel.view)
        XCTAssertFalse(well.isEnabled, "the default is Theme")
        choose("Custom", in: popup)
        XCTAssertTrue(well.isEnabled)
        well.color = NSColor(srgbRed: teal.red, green: teal.green, blue: teal.blue, alpha: 1)
        fire(well)
        assertColor(storedRules(store).crawl.background, teal)

        let reopened = crawlPanel(store)
        let popup2 = try control(NSPopUpButton.self, "Background color", in: reopened.view)
        let well2 = try control(NSColorWell.self, "Background color", in: reopened.view)
        XCTAssertEqual(popup2.titleOfSelectedItem, "Custom")
        XCTAssertTrue(well2.isEnabled)
        let shown = components(of: well2)
        XCTAssertEqual(shown.red, teal.red, accuracy: 0.002)
        XCTAssertEqual(shown.green, teal.green, accuracy: 0.002)
        XCTAssertEqual(shown.blue, teal.blue, accuracy: 0.002)
    }

    func testEditorFullScreenCustomColorRoundTrips() {
        var done: [NoticeProfile] = []
        let first = NotificationItemEditor(
            item: NoticeProfile(style: .fullScreen), store: makeTestStore(), onDone: { done.append($0) })
        first.loadViewIfNeeded()
        XCTAssertFalse(first.colorWell.isEnabled, "the default is System")
        choose("Custom", in: first.colorPopup)
        XCTAssertTrue(first.colorWell.isEnabled)
        first.colorWell.color = NSColor(srgbRed: teal.red, green: teal.green, blue: teal.blue, alpha: 1)
        fire(first.colorWell)
        fire(first.doneButton)
        guard let item = done.first else { return XCTFail("Done wrote nothing") }
        assertColor(item.fullScreen.color, teal)

        let reopened = editor(item)
        XCTAssertEqual(reopened.colorPopup.titleOfSelectedItem, "Custom")
        XCTAssertTrue(reopened.colorWell.isEnabled)
        let shown = components(of: reopened.colorWell)
        XCTAssertEqual(shown.red, teal.red, accuracy: 0.002)
        XCTAssertEqual(shown.blue, teal.blue, accuracy: 0.002)
    }

    func testSystemAndThemeSeedTheWellWithAVisibleColorNotBlack() throws {
        let editor = editor(NoticeProfile(style: .fullScreen))
        let shown = components(of: editor.colorWell)
        XCTAssertGreaterThan(shown.red + shown.green + shown.blue, 0.3, "not black")
        choose("Custom", in: editor.colorPopup)
        let chosen = editor.draft.fullScreen.color
        XCTAssertEqual(chosen.source, .custom)
        XCTAssertGreaterThan(chosen.red + chosen.green + chosen.blue, 0.3, "Custom starts from the gray")
    }

    // MARK: Reopen

    func testCrawlPanelReopensWithEverySeededValue() throws {
        let store = makeTestStore()
        var rules = storedRules(store)
        rules.crawl = CrawlSettings(
            edge: .top, showsBackground: false, background: NoticeColor.custom(red: 0.1, green: 0.2, blue: 0.3),
            backgroundOpacity: 0.7, speed: 150, leftToRight: true, textSize: 20, itemOpacity: 0.5)
        store.set(rules, for: NoticeSettings.routingRules)

        let view = crawlPanel(store).view
        XCTAssertEqual(try control(NSPopUpButton.self, "Edge", in: view).titleOfSelectedItem, "Top")
        XCTAssertEqual(try control(NSButton.self, "Show background", in: view).state, .off)
        XCTAssertEqual(try control(NSPopUpButton.self, "Background color", in: view).titleOfSelectedItem, "Custom")
        let well = try control(NSColorWell.self, "Background color", in: view)
        XCTAssertEqual(components(of: well).green, 0.2, accuracy: 0.002)
        XCTAssertEqual(try control(NSSlider.self, "Background transparency", in: view).doubleValue, 30, accuracy: 0.01)
        XCTAssertEqual(try control(NSSlider.self, "Speed", in: view).doubleValue, 150, accuracy: 0.01)
        XCTAssertEqual(try control(NSPopUpButton.self, "Direction", in: view).titleOfSelectedItem, "Left to Right")
        XCTAssertEqual(try control(NSSlider.self, "Text size", in: view).doubleValue, 20, accuracy: 0.01)
        XCTAssertEqual(try control(NSSlider.self, "Item transparency", in: view).doubleValue, 50, accuracy: 0.01)
    }

    func testEditorReopensAFullScreenItemWithEverySeededValue() {
        let item = NoticeProfile(
            style: .fullScreen,
            fullScreen: .init(blur: 0.25, color: NoticeColor.custom(red: 0.9, green: 0.1, blue: 0.1), opacity: 0.4))
        let editor = editor(item)
        XCTAssertEqual(editor.stylePopup.titleOfSelectedItem, "Full Screen")
        XCTAssertEqual(editor.blurSlider.doubleValue, 25, accuracy: 0.01)
        XCTAssertEqual(editor.opacitySlider.doubleValue, 40, accuracy: 0.01)
        XCTAssertEqual(editor.colorPopup.titleOfSelectedItem, "Custom")
        XCTAssertTrue(editor.colorWell.isEnabled)
        XCTAssertEqual(components(of: editor.colorWell).red, 0.9, accuracy: 0.002)
        XCTAssertTrue(editor.positionPopup.isHiddenOrHasHiddenAncestor)
        XCTAssertTrue(editor.layerPopup.isHiddenOrHasHiddenAncestor)
    }

    func testEditorReopensAToastItemWithItsPositionAndLayer() {
        let editor = editor(NoticeProfile(style: .toast, position: .bottomLeft, layer: .normal))
        XCTAssertEqual(editor.stylePopup.titleOfSelectedItem, "Toast")
        XCTAssertEqual(editor.positionPopup.titleOfSelectedItem, "Bottom Left")
        XCTAssertEqual(editor.layerPopup.titleOfSelectedItem, "Normal")
        XCTAssertFalse(editor.positionPopup.isHiddenOrHasHiddenAncestor)
        XCTAssertFalse(editor.layerPopup.isHiddenOrHasHiddenAncestor)
        XCTAssertTrue(editor.blurSlider.isHiddenOrHasHiddenAncestor)
    }

    func testEachEditorOwnsItsControls() {
        let store = makeTestStore()
        weak var weakEditor: NotificationItemEditor?
        autoreleasepool {
            let opened = editor(NoticeProfile(style: .toast), store: store)
            weakEditor = opened
            choose("Alert", in: opened.stylePopup)
        }
        XCTAssertNil(weakEditor, "nothing the editor made keeps it alive")
    }
}
