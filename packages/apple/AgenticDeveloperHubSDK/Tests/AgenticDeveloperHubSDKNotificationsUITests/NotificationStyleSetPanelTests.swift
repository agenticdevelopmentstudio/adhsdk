import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class NotificationStyleSetPanelTests: XCTestCase {

    private var store = makeTestStore()
    /// The window the panel sits in, so its editor has a window to sheet on.
    private var window: NSWindow?

    override func setUp() async throws {
        try await super.setUp()
        _ = NSApplication.shared
        store = makeTestStore()
    }

    private func makePanel(_ urgency: Notice.Urgency = .soon) -> NotificationStyleSetPanel {
        let panel = NotificationStyleSetPanel(urgency: urgency, handler: RecordingHandler(), store: store)
        panel.loadViewIfNeeded()
        let host = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 900),
            styleMask: [.titled], backing: .buffered, defer: true)
        host.contentView = panel.view
        window = host
        return panel
    }

    private func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(storedRules(store))
    }

    private func rowTexts(_ panel: NotificationStyleSetPanel) -> [String] {
        let table = panel.itemsTable.tableView
        return (0..<table.numberOfRows).map { row in
            let cell = table.view(atColumn: 0, row: row, makeIfNecessary: true)
            return (cell as? NSTableCellView)?.textField?.stringValue ?? ""
        }
    }

    private func set(_ urgency: Notice.Urgency = .soon) -> NoticeStyleSet {
        NotificationStylesSettingsPanel.baseStyle(for: urgency, in: storedRules(store))
    }

    private func seed(_ urgency: Notice.Urgency = .soon, _ change: (inout NoticeStyleSet) -> Void) {
        var rules = storedRules(store)
        var value = NotificationStylesSettingsPanel.baseStyle(for: urgency, in: rules)
        change(&value)
        rules.styles[urgency] = value
        store.set(rules, for: NoticeSettings.routingRules)
    }

    // MARK: Items

    func testPlusAppendsToastBottomRightAndOpensEditor() {
        let panel = makePanel()
        XCTAssertEqual(set().items.count, 1)
        panel.itemsTable.press(0)
        XCTAssertEqual(set().items.count, 2)
        XCTAssertEqual(set().items.last, NoticeProfile(style: .toast, position: .bottomRight))
        XCTAssertNotNil(panel.activeEditor)
        XCTAssertEqual(panel.activeEditor?.draft.style, .toast)
        XCTAssertEqual(panel.itemsTable.tableView.numberOfRows, 2)
    }

    // MARK: Edit flow

    func testPlusThenAlertThenDoneStoresAnAlertAndUpdatesTheRow() throws {
        let panel = makePanel()
        panel.itemsTable.press(0)
        let editor = try XCTUnwrap(panel.activeEditor)
        choose("Alert", in: editor.stylePopup)
        fire(editor.doneButton)
        let items = set().items
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.last?.style, .alert)
        XCTAssertEqual(rowTexts(panel).last, NotificationStylesSettingsPanel.describe(try XCTUnwrap(items.last)))
        XCTAssertTrue(try XCTUnwrap(rowTexts(panel).last).hasPrefix("Alert"))
        XCTAssertNil(panel.activeEditor)
    }

    func testEditingAnExistingRowThenCancelLeavesTheStoreByteIdentical() throws {
        seed { $0.items = [NoticeProfile(style: .toast), NoticeProfile(style: .crawl)] }
        let panel = makePanel()
        let before = try encoded()
        let table = panel.itemsTable.tableView
        table.selectRowIndexes([1], byExtendingSelection: false)
        table.sendAction(table.doubleAction, to: table.target)
        let editor = try XCTUnwrap(panel.activeEditor, "double-click opens the editor")
        XCTAssertEqual(editor.draft.style, .crawl)
        choose("Full Screen", in: editor.stylePopup)
        fire(editor.cancelButton)
        XCTAssertEqual(try encoded(), before)
        XCTAssertNil(panel.activeEditor)
    }

    func testReturnOnASelectedRowOpensTheEditor() throws {
        seed { $0.items = [NoticeProfile(style: .toast), NoticeProfile(style: .system)] }
        let panel = makePanel()
        panel.itemsTable.tableView.selectRowIndexes([1], byExtendingSelection: false)
        panel.itemsTable.tableView.onReturn?()
        XCTAssertEqual(try XCTUnwrap(panel.activeEditor).draft.style, .system)
    }

    func testReturnWithNothingSelectedOpensNothing() {
        let panel = makePanel()
        panel.itemsTable.tableView.onReturn?()
        XCTAssertNil(panel.activeEditor)
    }

    func testEditorDoneKeepsTheEditAsANewItemWhenTheRowChangedUnderIt() throws {
        seed { $0.items = [NoticeProfile(style: .toast), NoticeProfile(style: .crawl)] }
        let panel = makePanel()
        panel.itemsTable.tableView.selectRowIndexes([0], byExtendingSelection: false)
        panel.itemsTable.tableView.onReturn?()
        let editor = try XCTUnwrap(panel.activeEditor)
        // The set changes while the sheet is open: row 0 is now a different item.
        seed { $0.items = [NoticeProfile(style: .system), NoticeProfile(style: .crawl)] }
        choose("Alert", in: editor.stylePopup)
        fire(editor.doneButton)
        XCTAssertEqual(set().items.map(\.style), [.system, .crawl, .alert])
    }

    func testNoWindowMeansNoEditor() {
        let panel = NotificationStyleSetPanel(urgency: .soon, handler: RecordingHandler(), store: store)
        panel.loadViewIfNeeded()
        panel.itemsTable.press(0)
        XCTAssertNil(panel.activeEditor)
    }

    func testFractionalCustomSecondsShowAsStored() {
        seed { $0.autoDismiss = 12.5 }
        let panel = makePanel()
        XCTAssertEqual(panel.customSecondsField.stringValue, "12.5")
        XCTAssertEqual(DismissAfterChoice.secondsText(12), "12")
    }

    func testChoosingAPresetHidesTheSecondsField() {
        seed { $0.autoDismiss = 12 }
        let panel = makePanel()
        choose("8 seconds", in: panel.dismissAfterPopup)
        XCTAssertTrue(panel.customSecondsRow.isHidden)
    }

    func testMinusRemovesSelectedAndIsDisabledWithoutSelection() {
        seed { $0.items = [NoticeProfile(style: .toast), NoticeProfile(style: .system), NoticeProfile(style: .crawl)] }
        let panel = makePanel()
        let table = panel.itemsTable
        XCTAssertFalse(table.segmented.isEnabled(forSegment: 1), "no selection")
        table.tableView.selectRowIndexes([0, 2], byExtendingSelection: false)
        XCTAssertTrue(table.segmented.isEnabled(forSegment: 1))
        table.press(1)
        XCTAssertEqual(set().items.map(\.style), [.system])
        XCTAssertEqual(table.tableView.numberOfRows, 1)
    }

    func testEmptySetShowsPlaceholder() {
        seed { $0.items = [] }
        let panel = makePanel()
        XCTAssertFalse(panel.itemsTable.placeholder.isHidden)
        XCTAssertEqual(panel.itemsTable.placeholder.stringValue, "Not shown — add a notification with +")
        panel.itemsTable.press(0)
        XCTAssertTrue(panel.itemsTable.placeholder.isHidden)
    }

    func testTableIsPinnedToGroupEdges() throws {
        let panel = makePanel()
        let scroll = panel.itemsTable.scrollView
        let card = try XCTUnwrap(scroll.superview)
        XCTAssertTrue(card.superview != nil, "the card of the Notifications group")
        let pinned = card.constraints.filter { $0.firstItem === scroll && $0.secondItem === card }
        let attributes = Set(pinned.map(\.firstAttribute))
        XCTAssertTrue(attributes.isSuperset(of: [.leading, .trailing, .bottom]), "\(attributes)")
        for constraint in pinned where [.leading, .trailing, .bottom].contains(constraint.firstAttribute) {
            XCTAssertEqual(constraint.constant, 0)
            XCTAssertEqual(constraint.relation, .equal)
        }
    }

    func testTableFillsTheHeightThePanelLeaves() {
        let panel = makePanel()
        panel.view.layoutSubtreeIfNeeded()
        let height = panel.itemsTable.scrollView.frame.height
        XCTAssertGreaterThan(height, NotificationItemsTable.minimumTableHeight + 100, "grows with the panel")
        window?.setContentSize(NSSize(width: 700, height: 300))
        panel.view.layoutSubtreeIfNeeded()
        XCTAssertGreaterThanOrEqual(
            panel.itemsTable.scrollView.frame.height, NotificationItemsTable.minimumTableHeight)
    }

    func testRowsDescribeEachItem() {
        seed {
            $0.items = [
                NoticeProfile(style: .toast, position: .bottomRight),
                NoticeProfile(style: .fullScreen),
                NoticeProfile(style: .system)
            ]
        }
        let panel = makePanel()
        let texts = (0..<3).map { row -> String in
            let cell = panel.itemsTable.tableView.view(atColumn: 0, row: row, makeIfNecessary: true)
            return (cell as? NSTableCellView)?.textField?.stringValue ?? ""
        }
        XCTAssertEqual(texts, [
            "Toast · Bottom Right · Floating", "Full Screen · Blur 60 % · System 55 %", "Notification Center"
        ])
    }

    func testEveryStyleHasASymbol() {
        for style in NoticeProfile.Style.allCases {
            let name = NotificationStylesSettingsPanel.symbol(for: style)
            XCTAssertNotNil(NSImage(systemSymbolName: name, accessibilityDescription: nil), "\(style)")
        }
    }

    // MARK: Dismiss

    func testCustomDismissRevealsSecondsField() {
        let panel = makePanel()
        XCTAssertTrue(panel.customSecondsRow.isHidden)
        choose("Custom…", in: panel.dismissAfterPopup)
        XCTAssertFalse(panel.customSecondsRow.isHidden)
        XCTAssertNil(set().autoDismiss, "revealing stores nothing")
        panel.customSecondsField.stringValue = "42"
        fire(panel.customSecondsField)
        XCTAssertEqual(set().autoDismiss, 42)
        choose("8 seconds", in: panel.dismissAfterPopup)
        XCTAssertTrue(panel.customSecondsRow.isHidden)
        XCTAssertEqual(set().autoDismiss, 8)
        choose("Never", in: panel.dismissAfterPopup)
        XCTAssertNil(set().autoDismiss)
    }

    func testStoredNonPresetDismissShowsAsCustom() {
        seed { $0.autoDismiss = 12 }
        let panel = makePanel()
        XCTAssertEqual(panel.dismissAfterPopup.titleOfSelectedItem, "Custom…")
        XCTAssertFalse(panel.customSecondsRow.isHidden)
        XCTAssertEqual(panel.customSecondsField.stringValue, "12")
    }

    func testInvalidSecondsReverts() {
        seed { $0.autoDismiss = 12 }
        let panel = makePanel()
        for bad in ["abc", "0", "3601", "2.5", ""] {
            panel.customSecondsField.stringValue = bad
            fire(panel.customSecondsField)
            XCTAssertEqual(panel.customSecondsField.stringValue, "12", "\(bad) reverts")
            XCTAssertEqual(set().autoDismiss, 12)
        }
    }

    // MARK: Snooze

    func testSnoozeOptionCheckboxesDisabledWhenSnoozeOff() {
        let panel = makePanel()
        XCTAssertEqual(panel.snoozeOptionCheckboxes.count, SnoozeOption.allCases.count)
        XCTAssertTrue(panel.snoozeOptionCheckboxes.values.allSatisfy(\.isEnabled))
        panel.canBeSnoozedCheckbox.state = .off
        fire(panel.canBeSnoozedCheckbox)
        XCTAssertFalse(set().snooze.isEnabled)
        XCTAssertTrue(panel.snoozeOptionCheckboxes.values.allSatisfy { !$0.isEnabled })
        panel.canBeSnoozedCheckbox.state = .on
        fire(panel.canBeSnoozedCheckbox)
        XCTAssertTrue(panel.snoozeOptionCheckboxes.values.allSatisfy(\.isEnabled))
    }

    func testStoredSnoozeOffLoadsDisabled() {
        seed { $0.snooze.isEnabled = false }
        let panel = makePanel()
        XCTAssertEqual(panel.canBeSnoozedCheckbox.state, .off)
        XCTAssertTrue(panel.snoozeOptionCheckboxes.values.allSatisfy { !$0.isEnabled })
    }

    func testOptionCheckboxWritesTheSetsOptions() throws {
        let panel = makePanel()
        let box = try XCTUnwrap(panel.snoozeOptionCheckboxes[.oneHour])
        box.state = .off
        fire(box)
        XCTAssertFalse(set().snooze.options.contains(.oneHour))
        box.state = .on
        fire(box)
        XCTAssertEqual(set().snooze.options, SnoozeOption.allCases)
    }
}
