import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class NotificationItemEditorTests: XCTestCase {

    private var done: [NoticeProfile] = []
    private var cancelled = 0

    override func setUp() async throws {
        try await super.setUp()
        _ = NSApplication.shared
        done = []
        cancelled = 0
    }

    private func makeEditor(_ item: NoticeProfile) -> NotificationItemEditor {
        let editor = NotificationItemEditor(
            item: item, store: makeTestStore(),
            onDone: { [unowned self] in done.append($0) },
            onCancel: { [unowned self] in cancelled += 1 })
        editor.loadViewIfNeeded()
        return editor
    }

    private struct Visible: Equatable {
        var position: Bool
        var layer: Bool
        var fullScreen: Bool
    }

    func testEditorShowsFieldsPerStyle() {
        let editor = makeEditor(NoticeProfile(style: .toast))
        func visible() -> Visible {
            Visible(
                position: !editor.positionPopup.isHiddenOrHasHiddenAncestor,
                layer: !editor.layerPopup.isHiddenOrHasHiddenAncestor,
                fullScreen: !editor.blurSlider.isHiddenOrHasHiddenAncestor)
        }
        XCTAssertEqual(visible(), Visible(position: true, layer: true, fullScreen: false))
        choose(NotificationStylesSettingsPanel.styleTitle(.alert), in: editor.stylePopup)
        XCTAssertEqual(visible(), Visible(position: true, layer: true, fullScreen: false))
        choose(NotificationStylesSettingsPanel.styleTitle(.crawl), in: editor.stylePopup)
        XCTAssertEqual(visible(), Visible(position: false, layer: true, fullScreen: false))
        choose(NotificationStylesSettingsPanel.styleTitle(.fullScreen), in: editor.stylePopup)
        XCTAssertEqual(visible(), Visible(position: false, layer: false, fullScreen: true))
        choose(NotificationStylesSettingsPanel.styleTitle(.system), in: editor.stylePopup)
        XCTAssertEqual(visible(), Visible(position: false, layer: false, fullScreen: false))
    }

    func testEditorDoneWritesItemCancelDoesNot() {
        let editor = makeEditor(NoticeProfile(style: .toast, position: .bottomRight))
        choose(NotificationStylesSettingsPanel.styleTitle(.alert), in: editor.stylePopup)
        fire(editor.cancelButton)
        XCTAssertEqual(cancelled, 1)
        XCTAssertTrue(done.isEmpty)
        fire(editor.doneButton)
        XCTAssertEqual(done.count, 1)
        XCTAssertEqual(done.first?.style, .alert)
        XCTAssertEqual(done.first?.position, .bottomRight)
    }

    func testPositionPopupHasNoTopRight() {
        let editor = makeEditor(NoticeProfile(style: .toast))
        XCTAssertFalse(editor.positionPopup.itemTitles.contains("Top Right"))
        XCTAssertEqual(
            editor.positionPopup.itemTitles,
            NoticeProfile.Position.allCases.map(NotificationStylesSettingsPanel.positionTitle))
    }

    func testFullScreenSlidersWriteTheDraft() {
        let editor = makeEditor(NoticeProfile(style: .fullScreen))
        editor.blurSlider.doubleValue = 25
        fire(editor.blurSlider)
        editor.opacitySlider.doubleValue = 40
        fire(editor.opacitySlider)
        XCTAssertEqual(editor.draft.fullScreen.blur, 0.25, accuracy: 0.001)
        XCTAssertEqual(editor.draft.fullScreen.opacity, 0.4, accuracy: 0.001)
    }

    /// "Blur" is narrower than "Opacity"; the two sliders still start and end
    /// at the same x, so they read as one column.
    func testFullScreenSlidersLineUp() {
        let editor = makeEditor(NoticeProfile(style: .fullScreen))
        let window = NSWindow(contentViewController: editor)
        window.layoutIfNeeded()
        editor.view.layoutSubtreeIfNeeded()
        let blur = editor.blurSlider.convert(editor.blurSlider.bounds, to: nil)
        let opacity = editor.opacitySlider.convert(editor.opacitySlider.bounds, to: nil)
        XCTAssertFalse(editor.view.hasAmbiguousLayout)
        XCTAssertGreaterThan(blur.width, 0)
        XCTAssertEqual(blur.minX, opacity.minX, accuracy: 0.5)
        XCTAssertEqual(blur.maxX, opacity.maxX, accuracy: 0.5)
    }

    /// Picking a style with fewer rows shrinks the sheet to them, rather than
    /// leaving the taller style's height as empty space under the buttons.
    func testSheetFitsTheRowsTheStyleShows() throws {
        let editor = makeEditor(NoticeProfile(style: .toast))
        let window = NSWindow(contentViewController: editor)
        func height() throws -> CGFloat {
            window.layoutIfNeeded()
            return try XCTUnwrap(window.contentView).frame.height
        }
        choose(NotificationStylesSettingsPanel.styleTitle(.fullScreen), in: editor.stylePopup)
        let tall = try height()
        XCTAssertEqual(tall, editor.view.fittingSize.height, accuracy: 0.5)
        choose(NotificationStylesSettingsPanel.styleTitle(.system), in: editor.stylePopup)
        let short = try height()
        XCTAssertLessThan(short, tall)
        XCTAssertEqual(short, editor.view.fittingSize.height, accuracy: 0.5)
        choose(NotificationStylesSettingsPanel.styleTitle(.fullScreen), in: editor.stylePopup)
        XCTAssertEqual(try height(), tall, accuracy: 0.5)
    }
}
