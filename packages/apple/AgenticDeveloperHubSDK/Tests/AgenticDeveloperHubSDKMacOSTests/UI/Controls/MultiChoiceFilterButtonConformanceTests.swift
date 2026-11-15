import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS
@testable import AgenticDeveloperHubSDKUI

/// Conformance vectors for the `ui/controls/multi-choice-filter-button` recipe.
@MainActor
final class MultiChoiceFilterButtonConformanceTests: XCTestCase {

    private typealias Choice = MultiChoiceFilterButton.Choice

    private let alpha = Choice(id: "a", title: "Coding", detail: "Runs code")
    private let beta = Choice(id: "b", title: "Writing")

    private func makeButton(label: String = "Good for", choices: [Choice]? = nil) -> MultiChoiceFilterButton {
        MultiChoiceFilterButton(label: label, choices: choices ?? [alpha, beta])
    }

    private func items(of button: MultiChoiceFilterButton) throws -> [NSMenuItem] {
        try XCTUnwrap(button.menu).items
    }

    /// Fires the item's action the way a menu pick does.
    private func invoke(_ item: NSMenuItem) throws {
        let action = try XCTUnwrap(item.action)
        let target = try XCTUnwrap(item.target as? NSObject)
        target.perform(action, with: item)
    }

    func testV001_buildsFixedMenuStructure() throws {
        let button = makeButton()
        let menuItems = try items(of: button)
        // The title slot, Any, a separator, then one item per choice.
        XCTAssertEqual(menuItems.count, 3 + 2)
        // The pop-up gives an item handed to it with no action its own private
        // one; what matters is that the title slot does none of the filter's.
        let titleAction = menuItems[0].action.map(NSStringFromSelector)
        XCTAssertFalse(["clearSelection", "toggleChoice:"].contains(titleAction ?? ""),
                       "the title slot changes the filter when picked")
        // Item 0 is the pull-down's displayed-title slot, so it carries the summary title.
        XCTAssertEqual(menuItems[0].title, "Good for: Any")
        XCTAssertEqual(menuItems[1].title, "Any")
        XCTAssertNotNil(menuItems[1].action)
        XCTAssertTrue(menuItems[2].isSeparatorItem)
        XCTAssertEqual(menuItems[3].title, alpha.title)
        XCTAssertEqual(menuItems[4].title, beta.title)
    }

    func testV001_choiceItemsFollowChoiceOrder() throws {
        let button = makeButton(choices: [alpha, beta, Choice(id: "c", title: "Reading")])
        let titles = try items(of: button).dropFirst(3).map(\.title)
        XCTAssertEqual(titles, ["Coding", "Writing", "Reading"])
    }

    func testV002_setsChoiceTooltip() throws {
        let menuItems = try items(of: makeButton())
        XCTAssertEqual(menuItems[3].toolTip, "Runs code")
        XCTAssertNil(menuItems[4].toolTip)
    }

    func testV003_clearsSelectionOnAny() throws {
        let button = makeButton()
        button.setSelection(["a"])
        XCTAssertEqual(button.selection, ["a"])
        try invoke(try items(of: button)[1])
        XCTAssertEqual(button.selection, [])
    }

    func testV004_togglesChoiceOnSelectAdds() throws {
        let button = makeButton()
        try invoke(try items(of: button)[3])
        XCTAssertEqual(button.selection, ["a"])
    }

    func testV005_togglesChoiceOnSelectRemoves() throws {
        let button = makeButton()
        let item = try items(of: button)[3]
        try invoke(item)
        try invoke(item)
        XCTAssertEqual(button.selection, [])
    }

    func testV006_restrictsSelectionToKnownIds() {
        let button = makeButton()
        button.setSelection(["a", "z"])
        XCTAssertEqual(button.selection, ["a"])
    }

    func testV007_reflectsCheckmarks() throws {
        let button = makeButton()
        let menuItems = try items(of: button)
        try invoke(menuItems[3])
        XCTAssertEqual(menuItems[3].state, .on)
        XCTAssertEqual(menuItems[4].state, .off)
    }

    func testV008_resyncsCheckmarksOnNoOpSelection() throws {
        let button = makeButton()
        button.setSelection(["a"])
        let menuItems = try items(of: button)
        menuItems[3].state = .off
        button.setSelection(["a"])
        XCTAssertEqual(menuItems[3].state, .on)
    }

    func testV009_firesOnChangeOnActualChange() throws {
        let button = makeButton()
        var calls: [Set<String>] = []
        button.onChange = { calls.append($0) }
        try invoke(try items(of: button)[3])
        XCTAssertEqual(calls, [["a"]])
    }

    func testV010_doesNotFireOnChangeWhenAnyIsNoOp() throws {
        let button = makeButton()
        var calls: [Set<String>] = []
        button.onChange = { calls.append($0) }
        try invoke(try items(of: button)[1])
        XCTAssertTrue(calls.isEmpty)
    }

    func testV011_formatsTitleNoneSelected() {
        XCTAssertEqual(makeButton().title, "Good for: Any")
    }

    func testV012_formatsTitleFewSelected() {
        let button = makeButton()
        button.setSelection(["b", "a"])
        XCTAssertEqual(button.title, "Good for: Coding, Writing")
    }

    func testV013_formatsTitleManySelected() {
        let choices = (1...5).map { Choice(id: "id\($0)", title: "Title \($0)") }
        let button = makeButton(choices: choices)
        button.setSelection(["id1", "id2", "id3", "id4"])
        XCTAssertEqual(button.title, "Good for: 4 selected")
    }

    func testV014_refreshesTitleSynchronously() throws {
        let button = makeButton()
        try invoke(try items(of: button)[3])
        XCTAssertEqual(button.title, "Good for: \(alpha.title)")
    }

    func testV015_resizesForLongerTitles() {
        let longA = Choice(id: "a", title: "A considerably long choice title")
        let longB = Choice(id: "b", title: "Another considerably long choice title")
        let button = makeButton(choices: [longA, longB])
        let before = button.intrinsicContentSize.width
        button.setSelection(["a", "b"])
        let after = button.intrinsicContentSize.width
        XCTAssertGreaterThan(after, before)
    }

    func testV016_exposesReadonlySelection() throws {
        throw XCTSkip("Compile-time vector: `private(set)` on selection cannot be exercised at run time")
    }

    func testV017_themesTextAppearance() {
        let button = makeButton()
        button.contentTintColor = .systemPink
        button.font = .systemFont(ofSize: 31)
        NotificationCenter.default.post(name: ThemeManager.didChangeNotification, object: nil)
        let palette = button.resolvedThemeScope.palette
        XCTAssertEqual(button.contentTintColor, palette.primaryTextColor)
        XCTAssertEqual(button.font, palette.font(.body))
    }

    func testV021_labelAndAnyNeverChecked() throws {
        let button = makeButton()
        let menuItems = try items(of: button)
        try invoke(menuItems[3])
        XCTAssertEqual(menuItems[0].state, .off)
        XCTAssertEqual(menuItems[1].state, .off)
        XCTAssertEqual(menuItems[3].state, .on)
        XCTAssertEqual(menuItems[4].state, .off)
    }

    func testV022_initializesSelectionEmpty() {
        XCTAssertEqual(makeButton().selection, [])
    }

    func testV023_rejectsCoderInitialization() throws {
        throw XCTSkip("Verified by inspection only: the refusal is a fatalError that cannot be caught")
    }

    func testV024_confinesToUiThread() throws {
        throw XCTSkip("Verified by inspection only: @MainActor isolation is enforced at build time")
    }

    func testV025_disablesAutoresizingMaskTranslation() {
        XCTAssertFalse(makeButton().translatesAutoresizingMaskIntoConstraints)
    }

    func testV026_contrastAppliesNoAdjustment() {
        let button = makeButton()
        XCTAssertEqual(button.contentTintColor, button.resolvedThemeScope.palette.primaryTextColor)
    }
}
