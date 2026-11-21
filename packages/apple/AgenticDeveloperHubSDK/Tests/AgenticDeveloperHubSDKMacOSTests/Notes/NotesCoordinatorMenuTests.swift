import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Task 10 (spec §8): the Notes menu items — New Folder, Import Markdown
/// File…, Delete Note, Delete Folder. They began in the File menu and moved to
/// the Notes menu's `.notes` slot in 562d5624b ("menu slots and commands for
/// File/Projects/Notes"). All four use `isEnabled` rather than `isHidden`
/// (task-10-grounding G1 — a merely unavailable item stays visible and
/// disables itself), and are enabled only while a notes view is in the key
/// window.
@MainActor
final class NotesCoordinatorMenuTests: XCTestCase {

    private struct EmptyNoteStorage: NoteStorage {
        func fetchAllNotes() throws -> [Note] { [] }
        @discardableResult func insertNote(_ note: Note) throws -> Int64 { 1 }
        @discardableResult func updateNote(_ note: Note) throws -> Int64 { note.version + 1 }
        func deleteNote(id: UUID) throws {}
    }

    private func makeCoordinator() -> NotesCoordinator {
        let coordinator = NotesCoordinator(
            storage: EmptyNoteStorage(),
            commandRegistry: CommandRegistry()
        )
        addTeardownBlock { @MainActor in
            coordinator.notesWindowController.window?.close()
            coordinator.unregister()
        }
        return coordinator
    }

    /// The four items, out of the Notes menu. That menu also opens the Notes
    /// window — its "Notes" item, first at order 0 — which is not one of them.
    private func notesMenuItems(_ coordinator: NotesCoordinator) -> [MenuContribution] {
        coordinator.menuContributions.filter {
            guard case .notes = $0.slot else { return false }
            return $0.title != "Notes"
        }
    }

    // MARK: - The four contributions exist, in the spec's order

    func testNotesMenuHasFourItemsInTheSpecOrder() {
        let coordinator = makeCoordinator()
        let items = notesMenuItems(coordinator)

        XCTAssertEqual(items.map(\.title), [
            "New Folder", "Import Markdown File…", "Delete Note", "Delete Folder"
        ])
        XCTAssertEqual(
            items.map(\.order), items.map(\.order).sorted(),
            "orders must already sequence as the spec table, not dictionary order")
    }

    func testNoneOfTheFourUseIsHidden() {
        let coordinator = makeCoordinator()

        for item in notesMenuItems(coordinator) {
            XCTAssertNil(item.isHidden, "\(item.title) must disable itself, not disappear")
        }
    }

    // MARK: - Key equivalents

    func testNewFolderIsShiftCommandN() {
        let coordinator = makeCoordinator()
        let newFolder = notesMenuItems(coordinator).first { $0.title == "New Folder" }

        XCTAssertEqual(newFolder?.key, "n")
        XCTAssertEqual(newFolder?.modifiers, [.command, .shift])
    }

    func testTheOtherThreeItemsHaveNoKeyEquivalent() {
        let coordinator = makeCoordinator()
        let others = notesMenuItems(coordinator).filter { $0.title != "New Folder" }

        XCTAssertEqual(others.map(\.key), Array(repeating: "", count: others.count))
    }

    // MARK: - Enabled only while the Notes window is key

    func testAllFourAreDisabledWhenTheNotesWindowIsNotKey() {
        let coordinator = makeCoordinator()
        XCTAssertNil(coordinator.notesWindowController.window)

        for item in notesMenuItems(coordinator) {
            XCTAssertFalse(item.isEnabled(), "\(item.title) must be disabled with no Notes window")
        }
    }

    /// `AgenticDeveloperHubSDKMacOSTests` is a non-hosted unit-test bundle (no
    /// `NSApplication` main-run-loop process backs it), so `NSWindow.isKeyWindow`
    /// never flips true here even after `makeKeyAndOrderFront(nil)` — there is no
    /// reliable way in this bundle to assert the enabled side of the check.
    /// Showing the window (still not key) must not accidentally flip it either.
    func testAllFourStayDisabledWhenTheWindowIsShownButNotKey() {
        let coordinator = makeCoordinator()
        coordinator.notesWindowController.showWindow()
        XCTAssertNotNil(coordinator.notesWindowController.window)

        for item in notesMenuItems(coordinator) {
            XCTAssertFalse(item.isEnabled(), "\(item.title) must stay disabled while the window is not key")
        }
    }
}
