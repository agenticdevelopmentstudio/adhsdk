// Tests/AgenticDeveloperHubSDKMacOSTests/ConversationsWindow/ConversationsKeyCommandsConformanceTests.swift
import AppKit
import XCTest
import KeyboardShortcuts
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The conversations-key-commands recipe's vectors. The panel outline itself is
/// covered by `KeyCommands/KeyCommandsPanelHierarchyTests`; these cover the
/// shortcuts, what each command asks of the window, and when the window is
/// resolved.
@MainActor
final class ConversationsKeyCommandsConformanceTests: XCTestCase {

    private final class ResolveCounter {
        var count = 0
    }

    private var windows: [NSWindow] = []

    override func tearDown() async throws {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        try await super.tearDown()
    }

    private func emptySection() -> KeyCommandSection {
        ConversationsKeyCommands.section(resolve: { nil })
    }

    private func command(_ identifier: String, in section: KeyCommandSection) throws -> KeyCommandDescriptor {
        try XCTUnwrap(section.allCommands.first { $0.id == identifier }, "no command \(identifier)")
    }

    private func controller() -> ConversationsSplitViewController {
        let split = ConversationsSplitViewController(
            feed: ConversationsViewController { _, _, _ in [] })
        _ = split.view
        return split
    }

    private func host(_ split: ConversationsSplitViewController) -> NSWindow {
        let window = NSWindow(contentViewController: split)
        windows.append(window)
        return window
    }

    // MARK: - Declarations

    func testV001_theSectionIsTitledConversationsWindowWithAppScope() {
        let section = emptySection()

        XCTAssertEqual(section.title, "Conversations Window")
        XCTAssertEqual(section.scope, .app)
    }

    func testV002_theCommandsHaveTheirStableIdentifiers() {
        XCTAssertEqual(ConversationsKeyCommands.toggleShelfID, "conversations.toggleShelf")
        XCTAssertEqual(ConversationsKeyCommands.moveSelectionUpID, "conversations.moveSelectionUp")
        XCTAssertEqual(ConversationsKeyCommands.moveSelectionDownID, "conversations.moveSelectionDown")
        XCTAssertEqual(
            emptySection().allCommands.map(\.id),
            ["conversations.toggleShelf", "conversations.moveSelectionUp", "conversations.moveSelectionDown"])
    }

    func testV003_theOnlyDirectCommandIsShowConversationListOnCommandZero() {
        let direct = emptySection().commands

        XCTAssertEqual(direct.map(\.id), ["conversations.toggleShelf"])
        XCTAssertEqual(direct.first?.title, "Show Conversation List")
        XCTAssertEqual(direct.first?.defaultShortcut, KeyboardShortcuts.Shortcut(.zero, modifiers: .command))
    }

    func testV004_theSelectionCommandsSitUnderTheSingleModeHeadingAfterTheToggle() {
        let registry = KeyCommandRegistry()
        registry.install(emptySection())

        let installed = registry.sections.first { $0.title == "Conversations Window" }
        XCTAssertEqual(installed?.features.map(\.title), ["Single Conversation Mode"])
        XCTAssertEqual(
            installed?.features.first?.commands.map(\.id),
            ["conversations.moveSelectionUp", "conversations.moveSelectionDown"])
        XCTAssertEqual(
            installed?.allCommands.map(\.id).first, "conversations.toggleShelf",
            "the toggle does not come before the single mode commands")
    }

    func testV005_theSelectionCommandsAreTitledAndBoundToCommandUpAndDown() throws {
        let section = emptySection()
        let previous = try command("conversations.moveSelectionUp", in: section)
        let next = try command("conversations.moveSelectionDown", in: section)

        XCTAssertEqual(previous.title, "Previous Conversation")
        XCTAssertEqual(previous.defaultShortcut, KeyboardShortcuts.Shortcut(.upArrow, modifiers: .command))
        XCTAssertEqual(next.title, "Next Conversation")
        XCTAssertEqual(next.defaultShortcut, KeyboardShortcuts.Shortcut(.downArrow, modifiers: .command))
    }

    func testV005_theSelectionCommandsMoveByMinusOneAndPlusOne() throws {
        let split = controller()
        let window = host(split)
        split.shelf.sessions = ["a", "b", "c"].map {
            ConversationsSessionFilter.Session(id: $0, name: $0.uppercased(), context: [])
        }
        split.selectionMode = .single
        split.soloSessionID = "b"
        window.makeKeyAndOrderFront(nil)
        guard KeyCommandRegistry.shared.commandWindow === window else {
            throw XCTSkip("the test runner could not make a window key, which the commands require")
        }
        let section = ConversationsKeyCommands.section(resolve: { split })

        XCTAssertTrue(try command("conversations.moveSelectionUp", in: section).perform())
        XCTAssertEqual(split.soloSessionID, "a", "Previous Conversation did not move by -1")
        XCTAssertTrue(try command("conversations.moveSelectionDown", in: section).perform())
        XCTAssertTrue(try command("conversations.moveSelectionDown", in: section).perform())
        XCTAssertEqual(split.soloSessionID, "c", "Next Conversation did not move by +1")
    }

    // MARK: - Resolution and ownership

    func testV006_theWindowIsResolvedWhenACommandRunsNotWhenTheSectionIsBuilt() throws {
        let counter = ResolveCounter()
        let section = ConversationsKeyCommands.section(resolve: { counter.count += 1; return nil })
        let registry = KeyCommandRegistry()
        registry.install(section)
        XCTAssertEqual(counter.count, 0, "the controller was resolved before any command ran")

        _ = try command("conversations.toggleShelf", in: section).perform()
        XCTAssertEqual(counter.count, 1)
        _ = try command("conversations.moveSelectionUp", in: section).perform()
        _ = try command("conversations.moveSelectionDown", in: section).perform()
        XCTAssertEqual(counter.count, 3, "the controller was not resolved afresh for each run")
    }

    func testV007_withNoWindowEveryCommandPassesTheKeyOn() {
        for descriptor in emptySection().allCommands {
            XCTAssertFalse(descriptor.perform(), "\(descriptor.id) took a key with no window to act on")
        }
    }

    func testV008_aControllerThatDeclinesPassesTheKeyOn() throws {
        let split = controller()
        // In a window that is not the command window: the controller declines.
        let window = host(split)
        window.orderOut(nil)
        XCTAssertFalse(KeyCommandRegistry.shared.commandWindow === window)
        let section = ConversationsKeyCommands.section(resolve: { split })
        let shelfBefore = split.isShelfVisible

        for descriptor in section.allCommands {
            XCTAssertFalse(descriptor.perform(), "\(descriptor.id) reported taken for a controller that declined")
        }
        XCTAssertEqual(split.isShelfVisible, shelfBefore, "a declined toggle still toggled the shelf")
    }

    func testV008_aControllerThatAcceptsTakesTheKey() throws {
        let split = controller()
        let window = host(split)
        window.makeKeyAndOrderFront(nil)
        guard KeyCommandRegistry.shared.commandWindow === window else {
            throw XCTSkip("the test runner could not make a window key, which the commands require")
        }
        let section = ConversationsKeyCommands.section(resolve: { split })
        let shelfBefore = split.isShelfVisible

        XCTAssertTrue(try command("conversations.toggleShelf", in: section).perform())
        XCTAssertNotEqual(split.isShelfVisible, shelfBefore,
                          "the toggle was reported taken but the list did not change")
    }

    func testV009_confinesToTheUIThread() throws {
        throw XCTSkip("""
            The component is @MainActor, so a use from another thread is rejected at build time; \
            there is no runtime behavior a test could observe.
            """)
    }
}
