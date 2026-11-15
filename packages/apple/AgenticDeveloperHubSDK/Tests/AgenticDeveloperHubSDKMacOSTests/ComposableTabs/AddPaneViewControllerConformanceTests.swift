import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors for `ComposableTabsAddPaneViewController` (the add-pane-view recipe).
@MainActor
final class AddPaneViewControllerConformanceTests: XCTestCase {

    private typealias Picker = ComposableTabsAddPaneViewController

    private let plainID = ComposableTabsViewID("test.add.plain")
    private let iconID = ComposableTabsViewID("test.add.icon")

    private var plainChoice: Picker.Choice {
        Picker.Choice(viewID: plainID, displayName: "Plain", symbolName: nil)
    }

    private var iconChoice: Picker.Choice {
        Picker.Choice(viewID: iconID, displayName: "Iconic", symbolName: "plus")
    }

    private func makePicker(
        _ choices: [Picker.Choice],
        onAdd: @escaping (ComposableTabsViewID, Picker.Direction) -> Void = { _, _ in }
    ) -> Picker {
        let picker = Picker(choices: choices, onAdd: onAdd)
        picker.loadViewIfNeeded()
        return picker
    }

    private func descendants(of root: NSView) -> [NSView] {
        root.subviews + root.subviews.flatMap { descendants(of: $0) }
    }

    private func find<T: NSView>(_ type: T.Type, id identifier: String, in picker: Picker) throws -> T {
        let match = descendants(of: picker.view).first { $0.accessibilityIdentifier() == identifier }
        return try XCTUnwrap(match as? T, "no \(T.self) with identifier \(identifier)")
    }

    private func grid(of picker: Picker) throws -> NSGridView {
        try XCTUnwrap(picker.view.subviews.compactMap { $0 as? NSGridView }.first)
    }

    private func viewPopUp(_ picker: Picker) throws -> NSPopUpButton {
        try find(NSPopUpButton.self, id: "composable-tabs.add-pane.view", in: picker)
    }

    private func wherePopUp(_ picker: Picker) throws -> NSPopUpButton {
        try find(NSPopUpButton.self, id: "composable-tabs.add-pane.where", in: picker)
    }

    private func okButton(_ picker: Picker) throws -> NSButton {
        try find(NSButton.self, id: "composable-tabs.add-pane.ok", in: picker)
    }

    private func cancelButton(_ picker: Picker) throws -> NSButton {
        try find(NSButton.self, id: "composable-tabs.add-pane.cancel", in: picker)
    }

    /// Runs the button's action whether or not the button is enabled.
    private func forceInvoke(_ button: NSButton) throws {
        let action = try XCTUnwrap(button.action)
        _ = (try XCTUnwrap(button.target as? NSObject)).perform(action, with: button)
    }

    /// Presents the picker as a sheet on an on-screen window so dismissal is observable.
    private func present(_ picker: Picker) -> NSViewController {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let host = NSViewController()
        host.view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        window.contentViewController = host
        window.orderFront(nil)
        addTeardownBlock { @MainActor in window.orderOut(nil) }
        host.presentAsSheet(picker)
        return host
    }

    // MARK: Choice list

    func testAddPane001_populatesViewPopUpFromChoices() throws {
        let picker = makePicker([plainChoice, iconChoice])
        let popUp = try viewPopUp(picker)
        XCTAssertEqual(popUp.numberOfItems, 2)
        XCTAssertEqual(popUp.itemTitles, ["Plain", "Iconic"])
    }

    func testAddPane002_setsChoiceIconWhenSymbolPresent() throws {
        let picker = makePicker([plainChoice, iconChoice])
        let item = try XCTUnwrap(try viewPopUp(picker).item(at: 1))
        let image = try XCTUnwrap(item.image)
        XCTAssertEqual(image.accessibilityDescription, "Iconic")
    }

    func testAddPane003_omitsChoiceIconWhenSymbolAbsent() throws {
        let picker = makePicker([plainChoice, iconChoice])
        XCTAssertNil(try viewPopUp(picker).item(at: 0)?.image)
    }

    func testAddPane004_populatesWherePopUpInFixedOrder() throws {
        for choices in [[plainChoice], [iconChoice, plainChoice]] {
            let picker = makePicker(choices)
            XCTAssertEqual(try wherePopUp(picker).itemTitles, ["Left", "Right", "Above", "Below"])
        }
    }

    func testAddPane005_defaultsWhereSelectionToRight() throws {
        let picker = makePicker([plainChoice])
        XCTAssertEqual(try wherePopUp(picker).titleOfSelectedItem, "Right")
    }

    // MARK: Layout

    func testAddPane006_arrangesAddAndWhereAsTwoRowGrid() throws {
        let picker = makePicker([plainChoice])
        let grid = try grid(of: picker)
        XCTAssertEqual(grid.numberOfRows, 2)
        XCTAssertEqual(grid.numberOfColumns, 2)
    }

    func testAddPane007_addRowPrecedesWhereRow() throws {
        let picker = makePicker([plainChoice])
        let grid = try grid(of: picker)
        let addLabel = try XCTUnwrap(grid.cell(atColumnIndex: 0, rowIndex: 0).contentView as? NSTextField)
        let whereLabel = try XCTUnwrap(grid.cell(atColumnIndex: 0, rowIndex: 1).contentView as? NSTextField)
        XCTAssertEqual(addLabel.stringValue, "Add:")
        XCTAssertEqual(whereLabel.stringValue, "Where:")
        XCTAssertIdentical(grid.cell(atColumnIndex: 1, rowIndex: 0).contentView, try viewPopUp(picker))
        XCTAssertIdentical(grid.cell(atColumnIndex: 1, rowIndex: 1).contentView, try wherePopUp(picker))
    }

    // MARK: OK button state

    func testAddPane008_okButtonDisabledWhenChoicesEmpty() throws {
        let picker = makePicker([])
        XCTAssertFalse(try okButton(picker).isEnabled)
    }

    func testAddPane009_okButtonEnabledWhenChoicesPresent() throws {
        let picker = makePicker([plainChoice])
        XCTAssertTrue(try okButton(picker).isEnabled)
    }

    func testAddPane010_okButtonEnabledStateFixedAtLoad() throws {
        let picker = makePicker([plainChoice])
        let okBtn = try okButton(picker)
        try wherePopUp(picker).selectItem(at: 0)
        XCTAssertTrue(okBtn.isEnabled)
        try viewPopUp(picker).selectItem(at: 0)
        XCTAssertTrue(okBtn.isEnabled)
    }

    func testAddPane011_cancelPrecedesOkInButtonOrder() throws {
        let picker = makePicker([plainChoice])
        let cancel = try cancelButton(picker)
        let okBtn = try okButton(picker)
        let stack = try XCTUnwrap(cancel.superview as? NSStackView)
        XCTAssertIdentical(okBtn.superview, stack)
        let cancelIndex = try XCTUnwrap(stack.arrangedSubviews.firstIndex { $0 === cancel })
        let okIndex = try XCTUnwrap(stack.arrangedSubviews.firstIndex { $0 === okBtn })
        XCTAssertLessThan(cancelIndex, okIndex)
    }

    func testAddPane012_cancelBoundToEscapeKey() throws {
        let picker = makePicker([plainChoice])
        XCTAssertEqual(try cancelButton(picker).keyEquivalent, "\u{1b}")
    }

    func testAddPane013_okBoundToReturnKey() throws {
        let picker = makePicker([plainChoice])
        XCTAssertEqual(try okButton(picker).keyEquivalent, "\r")
    }

    // MARK: Cancel and confirm

    func testAddPane014_cancelDismissesWithoutInvokingOnAdd() throws {
        var added: [(ComposableTabsViewID, Picker.Direction)] = []
        let picker = makePicker([plainChoice]) { added.append(($0, $1)) }
        _ = present(picker)
        XCTAssertNotNil(picker.presentingViewController, "the sheet must be up before cancel dismisses it")
        try cancelButton(picker).performClick(nil)
        XCTAssertNil(picker.presentingViewController)
        XCTAssertTrue(added.isEmpty)
    }

    func testAddPane015_confirmDismissesBeforeInvokingOnAdd() throws {
        var order: [String] = []
        var picker: Picker?
        picker = makePicker([plainChoice]) { _, _ in
            order.append(picker?.presentingViewController == nil ? "dismissed" : "still-presented")
        }
        let shown = try XCTUnwrap(picker)
        _ = present(shown)
        XCTAssertNotNil(shown.presentingViewController)
        try okButton(shown).performClick(nil)
        XCTAssertEqual(order, ["dismissed"])
        picker = nil
    }

    func testAddPane016_confirmInvokesOnAddWithSelection() throws {
        var added: [(ComposableTabsViewID, Picker.Direction)] = []
        let picker = makePicker([plainChoice, iconChoice]) { added.append(($0, $1)) }
        try viewPopUp(picker).selectItem(at: 1)
        try wherePopUp(picker).selectItem(withTitle: "Above")
        // Confirm dismisses the picker before it adds, so it has to be on screen.
        _ = present(picker)
        try okButton(picker).performClick(nil)
        XCTAssertEqual(added.count, 1)
        XCTAssertEqual(added.first?.0, iconID)
        XCTAssertEqual(added.first?.1, .above)
    }

    func testAddPane017_confirmDismissesWithoutOnAddOnInvalidSelection() throws {
        var added = 0
        let picker = makePicker([]) { _, _ in added += 1 }
        _ = present(picker)
        XCTAssertNotNil(picker.presentingViewController)
        try forceInvoke(try okButton(picker))
        XCTAssertNil(picker.presentingViewController)
        XCTAssertEqual(added, 0)
    }

    // MARK: Container and identifiers

    func testAddPane018_enforcesMinimumContainerWidth() throws {
        let picker = makePicker([plainChoice])
        let widthConstraints = picker.view.constraints.filter {
            $0.firstAttribute == .width && $0.secondItem == nil && $0.relation == .greaterThanOrEqual
        }
        XCTAssertEqual(widthConstraints.map(\.constant), [320])
    }

    func testAddPane019_rootViewAccessibilityIdentifier() {
        let picker = makePicker([plainChoice])
        XCTAssertEqual(picker.view.accessibilityIdentifier(), "composable-tabs.add-pane")
    }

    func testAddPane020_viewPopUpAccessibilityIdentifier() throws {
        let picker = makePicker([plainChoice])
        XCTAssertEqual(try viewPopUp(picker).accessibilityIdentifier(), "composable-tabs.add-pane.view")
    }

    func testAddPane021_wherePopUpAccessibilityIdentifier() throws {
        let picker = makePicker([plainChoice])
        XCTAssertEqual(try wherePopUp(picker).accessibilityIdentifier(), "composable-tabs.add-pane.where")
    }

    func testAddPane022_cancelButtonAccessibilityIdentifier() throws {
        let picker = makePicker([plainChoice])
        XCTAssertEqual(try cancelButton(picker).accessibilityIdentifier(), "composable-tabs.add-pane.cancel")
    }

    func testAddPane023_okButtonAccessibilityIdentifier() throws {
        let picker = makePicker([plainChoice])
        XCTAssertEqual(try okButton(picker).accessibilityIdentifier(), "composable-tabs.add-pane.ok")
    }

    func testAddPane024_addRowLabelText() throws {
        let picker = makePicker([plainChoice])
        let label = try XCTUnwrap(try grid(of: picker).cell(atColumnIndex: 0, rowIndex: 0).contentView as? NSTextField)
        XCTAssertEqual(label.stringValue, "Add:")
        XCTAssertEqual(label.alignment, .right)
    }

    func testAddPane025_whereRowLabelText() throws {
        let picker = makePicker([plainChoice])
        let label = try XCTUnwrap(try grid(of: picker).cell(atColumnIndex: 0, rowIndex: 1).contentView as? NSTextField)
        XCTAssertEqual(label.stringValue, "Where:")
        XCTAssertEqual(label.alignment, .right)
    }

    func testAddPane026_confinesToUIThread() throws {
        throw XCTSkip("@MainActor isolation is enforced at build time; no runtime check to exercise")
    }
}
