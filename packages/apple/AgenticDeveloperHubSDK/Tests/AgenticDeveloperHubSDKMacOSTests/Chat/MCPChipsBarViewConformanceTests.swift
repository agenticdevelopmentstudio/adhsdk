// Tests/AgenticDeveloperHubSDKMacOSTests/Chat/MCPChipsBarViewConformanceTests.swift
import AppKit
import MCP
import SwiftUI
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors for `MCPChipsBarView`.
///
/// The view model and both SwiftUI views are `private` to their source file, so
/// the model is reached by reflection over the hosting view's tree and read
/// back through its `@Published` storage. Methods on it (`toggle`, `isActive`)
/// and the rendered SwiftUI content cannot be called or inspected from here.
@MainActor
final class MCPChipsBarViewConformanceTests: XCTestCase {

    private actor ChipsBarStubClient: MCPClientProtocol {
        nonisolated let id: UUID
        nonisolated let name: String
        var state: MCPClientState = .disconnected
        var cachedTools: [MCP.Tool] = []

        init(id: UUID, name: String) {
            self.id = id
            self.name = name
        }

        func connect() async throws { state = .connected }
        func disconnect() async { state = .disconnected }
        func refreshTools() async throws {}
        func callTool(
            name: String,
            arguments: [String: Value]?
        ) async throws -> (content: [MCP.Tool.Content], isError: Bool) {
            ([], false)
        }
    }

    private final class SelectionBox {
        var value: Set<UUID>
        init(_ value: Set<UUID>) { self.value = value }
    }

    private var store: SettingsStore!
    private var registry: MCPServerRegistry!

    override func setUp() async throws {
        try await super.setUp()
        store = SettingsStore(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        registry = MCPServerRegistry(store: store) { configuration, _ in
            ChipsBarStubClient(id: configuration.id, name: configuration.name)
        }
    }

    override func tearDown() async throws {
        registry = nil
        store = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func serverConfig(_ name: String) -> MCPServerConfiguration {
        MCPServerConfiguration(
            name: name,
            transport: .stdio(command: "\(name)-mcp", arguments: [], environment: [:]))
    }

    private func setServers(_ configs: [MCPServerConfiguration]) {
        store.set(configs, for: UserSettings.mcpServerConfigurations)
    }

    private func makeBar(active: SelectionBox = SelectionBox([])) -> MCPChipsBarView {
        let binding = Binding<Set<UUID>>(get: { active.value }, set: { active.value = $0 })
        return MCPChipsBarView(registry: registry, activeServerIds: binding)
    }

    private func hostingView(of bar: MCPChipsBarView) throws -> NSView {
        try XCTUnwrap(bar.subviews.first, "the bar hosts nothing")
    }

    /// The first object under `root` whose type name contains `name`, found by
    /// walking `Mirror` children.
    private func findObject(in root: Any, named name: String, depth: Int = 0) -> AnyObject? {
        if depth > 10 { return nil }
        if type(of: root) is AnyClass, String(describing: type(of: root)).contains(name) {
            return root as AnyObject
        }
        for child in Mirror(reflecting: root).children {
            if let found = findObject(in: child.value, named: name, depth: depth + 1) { return found }
        }
        return nil
    }

    private func viewModel(of bar: MCPChipsBarView) throws -> AnyObject {
        let hosting = try hostingView(of: bar)
        return try XCTUnwrap(
            findObject(in: hosting as Any, named: "MCPChipsBarViewModel"),
            "the hosted content has no view model")
    }

    /// The current value of a `@Published` property, whether its storage holds
    /// the value directly or a subject that has been subscribed to.
    private func publishedValue<Value>(
        _ type: Value.Type, of owner: AnyObject, property: String
    ) throws -> Value {
        let published = try XCTUnwrap(
            Mirror(reflecting: owner).children.first { $0.label == property }?.value,
            "no stored property \(property)")
        let found = findValue(in: published, labels: ["currentValue", "value"], depth: 0)
        return try XCTUnwrap(found as? Value, "could not read \(property) as \(Value.self)")
    }

    private func findValue(in root: Any, labels: Set<String>, depth: Int) -> Any? {
        if depth > 4 { return nil }
        for child in Mirror(reflecting: root).children {
            if let label = child.label, labels.contains(label) { return child.value }
            if let found = findValue(in: child.value, labels: labels, depth: depth + 1) { return found }
        }
        return nil
    }

    // MARK: - Vectors

    func testV1_themeIsAppliedToBarAndPopover() throws {
        throw XCTSkip("SwiftUI content is private and cannot be inspected for theme values from a unit test")
    }

    func testV3_hostedContentFillsTheBarOnAllFourEdges() throws {
        let bar = makeBar()
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
        container.addSubview(bar)
        // The bar is laid out by constraints, as its hosts place it; a frame
        // assigned by hand would be overwritten by the next layout pass. Hosts
        // give it a width and let its content decide its height, which SwiftUI
        // holds at the content's own.
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: container.topAnchor),
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        container.layoutSubtreeIfNeeded()
        let hosting = try hostingView(of: bar)
        XCTAssertEqual(hosting.frame, bar.bounds)

        container.setFrameSize(NSSize(width: 500, height: 60))
        container.layoutSubtreeIfNeeded()
        XCTAssertEqual(bar.bounds.width, 500)
        XCTAssertEqual(hosting.frame, bar.bounds, "the hosted content did not follow the bar's new bounds")
    }

    func testV5_barAndPickerShareOneViewModel() throws {
        throw XCTSkip("Needs to toggle a picker row, and the picker, its rows and the model's toggle are private")
    }

    func testV6_activeIdsAreSnapshottedAtInit() throws {
        let first = UUID()
        let second = UUID()
        let box = SelectionBox([first, second])
        let bar = makeBar(active: box)

        box.value = [UUID()]

        let model = try viewModel(of: bar)
        let active = try publishedValue(Set<UUID>.self, of: model, property: "_activeServerIds")
        XCTAssertEqual(active, [first, second])
    }

    func testV7_clientsAreSortedByNameIgnoringCaseAndNamesRebuilt() throws {
        let bravo = serverConfig("Bravo")
        let alpha = serverConfig("alpha")
        setServers([bravo, alpha])
        let bar = makeBar()

        let model = try viewModel(of: bar)
        let ids = try publishedValue([UUID].self, of: model, property: "_availableServerIds")
        let names = try publishedValue([UUID: String].self, of: model, property: "_serverNames")

        XCTAssertEqual(ids, [alpha.id, bravo.id])
        XCTAssertEqual(names, [bravo.id: "Bravo", alpha.id: "alpha"])
    }

    func testV7b_laterRegistryUpdatesAreFollowedWithoutReobserving() throws {
        let bravo = serverConfig("Bravo")
        setServers([bravo])
        let bar = makeBar()
        let model = try viewModel(of: bar)

        let alpha = serverConfig("alpha")
        setServers([bravo, alpha])

        let ids = try publishedValue([UUID].self, of: model, property: "_availableServerIds")
        let names = try publishedValue([UUID: String].self, of: model, property: "_serverNames")
        XCTAssertEqual(ids, [alpha.id, bravo.id])
        XCTAssertEqual(names, [bravo.id: "Bravo", alpha.id: "alpha"])
    }

    func testV8_missingNameFallsBackToEmptyString() throws {
        throw XCTSkip("Code-inspection vector: the branch is unreachable through the call site")
    }

    func testV9_isActiveReportsMembership() throws {
        throw XCTSkip("`isActive(_:)` is a method on a private view model and cannot be called from a test")
    }

    func testV10_toggleInsertsAndWritesBinding() throws {
        throw XCTSkip("`toggle(_:)` is a method on a private view model and cannot be called from a test")
    }

    func testV11_toggleRemovesAndWritesBinding() throws {
        throw XCTSkip("`toggle(_:)` is a method on a private view model and cannot be called from a test")
    }

    func testV12_serverRackIconIsShown() throws {
        throw XCTSkip("Rendered SwiftUI content is private and exposes no accessibility tree to a unit test")
    }

    func testV13_noServersLabel() throws {
        throw XCTSkip("The label is computed inside a private SwiftUI view and cannot be read from a unit test")
    }

    func testV14_noneActiveLabel() throws {
        throw XCTSkip("The label is computed inside a private SwiftUI view and cannot be read from a unit test")
    }

    func testV15_countActiveLabel() throws {
        throw XCTSkip("The label is computed inside a private SwiftUI view and cannot be read from a unit test")
    }

    func testV16_borderlessButtonStyle() throws {
        throw XCTSkip("A SwiftUI button style cannot be inspected from a unit test")
    }

    func testV17_tapTogglesThePicker() throws {
        throw XCTSkip("`showingPicker` is private SwiftUI state and a SwiftUI tap cannot be driven from a unit test")
    }

    func testV18_popoverPresentedBelowButton() throws {
        throw XCTSkip("A SwiftUI popover needs a live window server presentation and cannot be inspected")
    }

    func testV19_themeReappliedInsidePopover() throws {
        throw XCTSkip("The popover is a separate window presented by SwiftUI and cannot be inspected")
    }

    func testV20_barPaddingAndTrailingSpacer() throws {
        throw XCTSkip("SwiftUI layout modifiers cannot be inspected from a unit test")
    }

    func testV21_pickerHeading() throws {
        throw XCTSkip("The picker is a private SwiftUI view presented in a popover and cannot be inspected")
    }

    func testV22_emptyStateMessage() throws {
        throw XCTSkip("The picker is a private SwiftUI view presented in a popover and cannot be inspected")
    }

    func testV23_rowsAndUnknownFallback() throws {
        throw XCTSkip("The picker is a private SwiftUI view presented in a popover and cannot be inspected")
    }

    func testV24_rowToggleReflectsActiveState() throws {
        throw XCTSkip("The picker is a private SwiftUI view presented in a popover and cannot be inspected")
    }

    func testV25_rowToggleCallsViewModelToggle() throws {
        throw XCTSkip("The picker is a private SwiftUI view presented in a popover and cannot be driven")
    }

    func testV26_checkboxToggleStyle() throws {
        throw XCTSkip("A SwiftUI toggle style cannot be inspected from a unit test")
    }

    func testV27_pickerPaddingAndMinimumWidth() throws {
        throw XCTSkip("SwiftUI layout modifiers cannot be inspected from a unit test")
    }

    func testV28_confinedToTheUIThread() throws {
        throw XCTSkip("Compile-time vector: @MainActor isolation is enforced by the build, not at run time")
    }
}
