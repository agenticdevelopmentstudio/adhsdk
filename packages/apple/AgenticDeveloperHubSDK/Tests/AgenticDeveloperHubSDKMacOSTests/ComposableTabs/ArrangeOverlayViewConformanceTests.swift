import AppKit
import XCTest
import AgenticDeveloperHubSDKUI
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors for `ComposableTabsArrangeOverlayView` (the arrange-overlay-view recipe).
@MainActor
final class ArrangeOverlayViewConformanceTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // Writes UserSettings.shared, which suites in the other framework share.
        await ExclusiveAccess.Resource.userSettings.acquire()
    }

    override func tearDown() async throws {
        await ExclusiveAccess.Resource.userSettings.release()
        try await super.tearDown()
    }

    private typealias Overlay = ComposableTabsArrangeOverlayView
    private let prefix = "composable-tabs.arrange"

    /// Records every pointer event that reaches it, standing in for the pane's content.
    private func makeOverlay() -> Overlay {
        Overlay(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
    }

    private func descendants(of root: NSView) -> [NSView] {
        root.subviews + root.subviews.flatMap { descendants(of: $0) }
    }

    private func find<T: NSView>(_ type: T.Type, _ suffix: String, in overlay: Overlay) throws -> T {
        let identifier = "\(prefix).\(suffix)"
        let match = descendants(of: overlay).first { $0.accessibilityIdentifier() == identifier }
        return try XCTUnwrap(match as? T, "no \(T.self) with identifier \(identifier)")
    }

    private func button(_ suffix: String, in overlay: Overlay) throws -> NSButton {
        try find(NSButton.self, suffix, in: overlay)
    }

    private func moveButton(in overlay: Overlay) throws -> NSPopUpButton {
        try find(NSPopUpButton.self, "move", in: overlay)
    }

    private func moveItems(in overlay: Overlay) throws -> [NSMenuItem] {
        Array(try XCTUnwrap(try moveButton(in: overlay).menu).items.dropFirst())
    }

    private func symbolData(_ name: String) throws -> Data {
        let image = try XCTUnwrap(NSImage(systemSymbolName: name, accessibilityDescription: nil))
        return try XCTUnwrap(image.tiffRepresentation)
    }

    private func toolbar(of overlay: Overlay) throws -> NSView {
        let stack = try XCTUnwrap(try button("add", in: overlay).superview)
        return try XCTUnwrap(stack.superview)
    }

    private func column(of overlay: Overlay) throws -> NSStackView {
        try XCTUnwrap(overlay.subviews.compactMap { $0 as? NSStackView }.first)
    }

    private func scrimColor(_ palette: SemanticPalette) -> CGColor {
        palette.nsColor(.windowBackground).withAlphaComponent(0.72).cgColor
    }

    // MARK: Appearance

    func testOverlay001_dimsContentWithScrim() {
        let overlay = makeOverlay()
        let palette = overlay.resolvedThemeScope.palette
        XCTAssertEqual(overlay.layer?.backgroundColor, scrimColor(palette))
    }

    func testOverlay002_paintsToolbarSurface() throws {
        let overlay = makeOverlay()
        let palette = overlay.resolvedThemeScope.palette
        let layer = try XCTUnwrap(try toolbar(of: overlay).layer)
        XCTAssertEqual(layer.cornerRadius, 8)
        XCTAssertEqual(layer.borderWidth, 1)
        XCTAssertEqual(layer.backgroundColor, palette.nsColor(.elevatedSurface).cgColor)
        XCTAssertEqual(layer.borderColor, palette.nsColor(.border).cgColor)
    }

    func testOverlay003_appliesThemeImmediatelyAndOnChange() throws {
        let original = UserSettings.shared
        UserSettings.shared = UserSettings(with: InMemorySettingsStorageProvider())
        let manager = ThemeManager()
        addTeardownBlock { @MainActor in
            UserSettings.shared = original
            _ = manager
        }
        manager.selectTheme(id: BuiltInThemes.dracula.id)
        let overlay = makeOverlay()
        let paletteA = manager.currentPalette
        XCTAssertEqual(overlay.layer?.backgroundColor, scrimColor(paletteA))

        manager.selectTheme(id: BuiltInThemes.githubLight.id)
        let paletteB = manager.currentPalette
        XCTAssertNotEqual(scrimColor(paletteA), scrimColor(paletteB), "the two themes must differ")
        XCTAssertEqual(overlay.layer?.backgroundColor, scrimColor(paletteB))
        let layer = try XCTUnwrap(try toolbar(of: overlay).layer)
        XCTAssertEqual(layer.backgroundColor, paletteB.nsColor(.elevatedSurface).cgColor)
        XCTAssertEqual(layer.borderColor, paletteB.nsColor(.border).cgColor)
    }

    // MARK: Layout

    func testOverlay004_centersToolbarColumn() throws {
        let overlay = makeOverlay()
        let column = try column(of: overlay)
        let centerX = overlay.constraints.filter {
            $0.firstItem === column && $0.firstAttribute == .centerX
                && $0.secondItem === overlay && $0.secondAttribute == .centerX
        }
        let centerY = overlay.constraints.filter {
            $0.firstItem === column && $0.firstAttribute == .centerY
                && $0.secondItem === overlay && $0.secondAttribute == .centerY
        }
        XCTAssertEqual(centerX.count, 1)
        XCTAssertEqual(centerY.count, 1)
        XCTAssertEqual(column.spacing, 10)
    }

    func testOverlay005_capsNameLabelWidth() throws {
        let overlay = makeOverlay()
        let label = try find(NSTextField.self, "pane-name", in: overlay)
        let caps = overlay.constraints.filter {
            $0.firstItem === label && $0.firstAttribute == .width && $0.relation == .lessThanOrEqual
                && $0.secondItem === overlay && $0.secondAttribute == .width
                && $0.multiplier == 1 && $0.constant == -16
        }
        XCTAssertEqual(caps.count, 1)
    }

    func testOverlay006_truncatesNameLabelTail() throws {
        let overlay = makeOverlay()
        overlay.paneName = String(repeating: "A very long pane name ", count: 20)
        let label = try find(NSTextField.self, "pane-name", in: overlay)
        XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)
        XCTAssertEqual(label.alignment, .center)
    }

    func testOverlay007_toolbarCanOverhangNarrowPane() throws {
        let overlay = makeOverlay()
        let column = try column(of: overlay)
        let edges: Set<NSLayoutConstraint.Attribute> = [.leading, .trailing, .top, .bottom, .left, .right]
        let pins = overlay.constraints.filter { constraint in
            let involvesColumn = constraint.firstItem === column || constraint.secondItem === column
            return involvesColumn && edges.contains(constraint.firstAttribute)
        }
        XCTAssertTrue(pins.isEmpty)
        let centering = overlay.constraints.filter { $0.firstItem === column }
        XCTAssertEqual(Set(centering.map(\.firstAttribute)), [.centerX, .centerY])
    }

    // MARK: Pane name and anchor

    func testOverlay008_updatesPaneNameOnAssignment() throws {
        let overlay = makeOverlay()
        overlay.paneName = "Editor"
        XCTAssertEqual(try find(NSTextField.self, "pane-name", in: overlay).stringValue, "Editor")
    }

    func testOverlay009_exposesAddButtonAsAnchorView() throws {
        let overlay = makeOverlay()
        XCTAssertIdentical(overlay.addButtonView, try button("add", in: overlay))
    }

    // MARK: Callbacks

    func testOverlay010_invokesAddCallbackOnTap() throws {
        let overlay = makeOverlay()
        var count = 0
        overlay.onAdd = { count += 1 }
        try button("add", in: overlay).performClick(nil)
        XCTAssertEqual(count, 1)
    }

    func testOverlay011_addTapWithoutCallbackIsHarmless() throws {
        let overlay = makeOverlay()
        let add = try button("add", in: overlay)
        XCTAssertTrue(add.isEnabled)
        add.performClick(nil)
        XCTAssertTrue(add.isEnabled)
    }

    func testOverlay012_invokesRemoveCallbackOnTap() throws {
        let overlay = makeOverlay()
        var count = 0
        overlay.onRemove = { count += 1 }
        try button("remove", in: overlay).performClick(nil)
        XCTAssertEqual(count, 1)
    }

    func testOverlay013_removeTapWithoutCallbackIsHarmless() throws {
        let overlay = makeOverlay()
        let remove = try button("remove", in: overlay)
        XCTAssertTrue(remove.isEnabled)
        remove.performClick(nil)
        XCTAssertTrue(remove.isEnabled)
    }

    func testOverlay014_invokesDoneCallbackOnTap() throws {
        let overlay = makeOverlay()
        var count = 0
        overlay.onDone = { count += 1 }
        try button("done", in: overlay).performClick(nil)
        XCTAssertEqual(count, 1)
    }

    func testOverlay015_doneTapWithoutCallbackIsHarmless() throws {
        let overlay = makeOverlay()
        let done = try button("done", in: overlay)
        done.performClick(nil)
        XCTAssertTrue(done.isEnabled)
    }

    func testOverlay016_invokesMoveCallbackOnSelection() throws {
        let overlay = makeOverlay()
        var moves: [Overlay.Direction] = []
        overlay.onMove = { moves.append($0) }
        overlay.availableDirections = { [.left] }
        overlay.refreshAvailability()
        let menu = try XCTUnwrap(try moveButton(in: overlay).menu)
        let index = try XCTUnwrap(menu.items.firstIndex { $0.title == "Left" })
        menu.performActionForItem(at: index)
        XCTAssertEqual(moves, [.left])
    }

    func testOverlay017_moveSelectionWithoutCallbackIsHarmless() throws {
        let overlay = makeOverlay()
        overlay.availableDirections = { [.left] }
        overlay.refreshAvailability()
        let menu = try XCTUnwrap(try moveButton(in: overlay).menu)
        let index = try XCTUnwrap(menu.items.firstIndex { $0.title == "Left" })
        XCTAssertTrue(menu.items[index].isEnabled)
        menu.performActionForItem(at: index)
        XCTAssertTrue(menu.items[index].isEnabled)
    }

    // MARK: Availability

    func testOverlay018_addButtonEnablementTracksCanAdd() throws {
        let overlay = makeOverlay()
        overlay.canAdd = { false }
        overlay.refreshAvailability()
        XCTAssertFalse(try button("add", in: overlay).isEnabled)
    }

    func testOverlay019_removeButtonEnablementTracksCanRemove() throws {
        let overlay = makeOverlay()
        overlay.canRemove = { false }
        overlay.refreshAvailability()
        XCTAssertFalse(try button("remove", in: overlay).isEnabled)
    }

    func testOverlay020_moveMenuRebuiltOnRefresh() throws {
        let overlay = makeOverlay()
        let menu = try XCTUnwrap(try moveButton(in: overlay).menu)
        for _ in 0..<2 {
            overlay.refreshAvailability()
            XCTAssertEqual(menu.items.map(\.title), ["Move", "Left", "Right", "Up", "Down"])
        }
    }

    func testOverlay021_moveItemEnablementTracksAvailableDirections() throws {
        let overlay = makeOverlay()
        overlay.availableDirections = { [.left, .above] }
        overlay.refreshAvailability()
        let enabled = Dictionary(uniqueKeysWithValues: try moveItems(in: overlay).map { ($0.title, $0.isEnabled) })
        XCTAssertEqual(enabled, ["Left": true, "Right": false, "Up": true, "Down": false])
    }

    func testOverlay022_moveButtonDisabledWithNoDirections() throws {
        let overlay = makeOverlay()
        overlay.availableDirections = { [] }
        overlay.refreshAvailability()
        XCTAssertFalse(try moveButton(in: overlay).isEnabled)
    }

    func testOverlay023_moveButtonEnabledWithADirection() throws {
        let overlay = makeOverlay()
        overlay.availableDirections = { [.right] }
        overlay.refreshAvailability()
        XCTAssertTrue(try moveButton(in: overlay).isEnabled)
    }

    func testOverlay024_moveItemsIconsMatchDirection() throws {
        let overlay = makeOverlay()
        overlay.refreshAvailability()
        let item = try XCTUnwrap(try moveItems(in: overlay).first { $0.title == "Up" })
        let image = try XCTUnwrap(item.image)
        XCTAssertEqual(image.accessibilityDescription, "Up")
        XCTAssertEqual(try XCTUnwrap(image.tiffRepresentation), try symbolData("arrow.up"))
    }

    func testOverlay025_toolbarButtonsShowIconAndLabel() throws {
        let overlay = makeOverlay()
        let remove = try button("remove", in: overlay)
        let image = try XCTUnwrap(remove.image)
        XCTAssertEqual(image.accessibilityDescription, "Remove")
        XCTAssertEqual(try XCTUnwrap(image.tiffRepresentation), try symbolData("minus"))
        XCTAssertEqual(remove.imagePosition, .imageLeading)
        XCTAssertEqual(remove.title, "Remove")
    }

    func testOverlay026_refreshIsCallerDriven() throws {
        let overlay = makeOverlay()
        let add = try button("add", in: overlay)
        XCTAssertTrue(add.isEnabled)
        overlay.canAdd = { false }
        XCTAssertTrue(add.isEnabled, "assigning the callback alone must not recompute availability")
    }

    func testOverlay027_computesInitialAvailabilityAtConstruction() throws {
        // The callbacks are assigned after init, so construction computes availability from the
        // defaults (can add, can remove, no move directions); no refresh call is made here.
        let overlay = makeOverlay()
        XCTAssertTrue(try button("add", in: overlay).isEnabled)
        XCTAssertTrue(try button("remove", in: overlay).isEnabled)
        XCTAssertFalse(try moveButton(in: overlay).isEnabled)
        XCTAssertEqual(try moveButton(in: overlay).menu?.items.count, 5)
    }

    // MARK: Identifiers and key equivalents

    func testOverlay028_rootAndControlsCarryAccessibilityIdentifiers() throws {
        let overlay = makeOverlay()
        XCTAssertEqual(overlay.accessibilityIdentifier(), "composable-tabs.arrange.scrim")
        XCTAssertEqual(try button("add", in: overlay).accessibilityIdentifier(), "composable-tabs.arrange.add")
        XCTAssertEqual(try button("remove", in: overlay).accessibilityIdentifier(), "composable-tabs.arrange.remove")
        XCTAssertEqual(try moveButton(in: overlay).accessibilityIdentifier(), "composable-tabs.arrange.move")
        XCTAssertEqual(try button("done", in: overlay).accessibilityIdentifier(), "composable-tabs.arrange.done")
        let name = try find(NSTextField.self, "pane-name", in: overlay)
        XCTAssertEqual(name.accessibilityIdentifier(), "composable-tabs.arrange.pane-name")
    }

    func testOverlay029_moveItemsCarryPrefixedIdentifiers() throws {
        let overlay = makeOverlay()
        overlay.refreshAvailability()
        let left = try XCTUnwrap(try moveItems(in: overlay).first { $0.title == "Left" })
        XCTAssertEqual(left.accessibilityIdentifier(), "composable-tabs.arrange.move.left")
    }

    func testOverlay030_doneButtonHasNoKeyEquivalent() throws {
        let overlay = makeOverlay()
        XCTAssertEqual(try button("done", in: overlay).keyEquivalent, "")
    }

    // MARK: Event handling

    func testOverlay031_scrimBlocksClicksToContent() throws {
        let backdrop = ComposableTabsPaneBackgroundView(nodeID: UUID())
        backdrop.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        let content = NSView(frame: backdrop.bounds)
        let overlay = makeOverlay()
        backdrop.addSubview(content)
        backdrop.addSubview(overlay)

        // A point over the scrim, well clear of the centred toolbar.
        let point = NSPoint(x: 10, y: 10)
        let hit = try XCTUnwrap(backdrop.hitTest(point))
        XCTAssertTrue(hit === overlay || hit.isDescendant(of: overlay), "the scrim must take the click")

        // AppKit hands a click to the hit view and then up its responder chain,
        // so content the chain never passes through never sees the click.
        var chain: [NSResponder] = []
        var responder: NSResponder? = hit
        while let next = responder {
            chain.append(next)
            responder = next.nextResponder
        }
        XCTAssertFalse(chain.contains { $0 === content }, "the click must not reach the content behind the scrim")
        XCTAssertTrue(chain.contains { $0 === backdrop }, "the click still walks up to the pane's backdrop")
    }

    func testOverlay032_scrimClickStillReachesPaneSelection() throws {
        throw XCTSkip("Selection runs off an app-level event monitor; needs real window-server events")
    }

    func testOverlay033_confinesToUIThread() throws {
        throw XCTSkip("@MainActor isolation is enforced at build time; no runtime check to exercise")
    }
}
