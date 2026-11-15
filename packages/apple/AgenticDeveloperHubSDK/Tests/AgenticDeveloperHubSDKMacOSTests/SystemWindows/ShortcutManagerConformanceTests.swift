import AppKit
import Foundation
import Testing
import KeyboardShortcuts
import AgenticDeveloperHubSDKCoreMacOS
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

private let noFireReason = Comment(
    rawValue: "KeyboardShortcuts offers no public way to fire a key-down; it needs a real Carbon hotkey")

/// Conformance tests for `SystemWindowShortcutManager`.
///
/// The `KeyboardShortcuts` library delivers key-downs only from a real Carbon hotkey event and
/// exposes no way to fire one, so the dispatch vectors are skipped with that reason.
@MainActor
@Suite("SystemWindowShortcutManager conformance", .serialized)
struct ShortcutManagerConformanceTests {

    private static var windowContextsChord: KeyboardShortcuts.Shortcut {
        KeyboardShortcuts.Shortcut(.a, modifiers: [.control, .option])
    }

    /// Builds a manager over in-memory fakes, runs `body`, and clears the registry reservation after.
    private func withManager(_ body: (SystemWindowShortcutManager) throws -> Void) throws {
        let previous = UserSettings.shared
        UserSettings.shared = UserSettings(with: InMemorySettingsStorageProvider())
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            KeyCommandRegistry.shared.releaseExternal(KeyboardShortcuts.Name.allWindowContextShortcuts)
            UserSettings.shared = previous
            try? FileManager.default.removeItem(at: root)
        }
        let control = SystemWindowContextManagerTests.MockWindowControl()
        let contextManager = SystemWindowContextManager(
            windowManager: control,
            stateStore: SystemWindowContextStore(rootDirectory: root),
            windowMatcher: SystemWindowMatcher(registry: HeuristicRegistry())
        )
        let configuration = SystemWindowContextsConfiguration(
            settingsKey: "shortcutmanager.\(UUID().uuidString)",
            notificationTitle: "Test",
            notificationIdentifier: "test"
        )
        let model = SystemWindowContextsModel(
            contextManager: contextManager,
            windowManager: control,
            configuration: configuration,
            isTestEnvironment: true
        )
        try body(SystemWindowShortcutManager(model: model))
    }

    @Test("wms-010: key-down for switchToContext2 switches to the second context", .disabled(noFireReason))
    func dispatchIndex() {}

    @Test("wms-011: index beyond the context count is a no-op", .disabled(noFireReason))
    func indexOutOfRange() {}

    @Test("wms-012: index with zero contexts is a no-op", .disabled(noFireReason))
    func indexWithNoContexts() {}

    @Test("wms-013: the context list is read at fire time", .disabled(noFireReason))
    func indexReadAtFireTime() {}

    @Test("wms-014: key-down for addWindow adds the frontmost window", .disabled(noFireReason))
    func dispatchAdd() {}

    @Test("wms-015: key-down for removeWindow removes the frontmost window", .disabled(noFireReason))
    func dispatchRemove() {}

    @Test("wms-016: key-down for nextContext switches to the next context", .disabled(noFireReason))
    func dispatchNext() {}

    @Test("wms-017: key-down for previousContext switches to the previous context", .disabled(noFireReason))
    func dispatchPrevious() {}

    @Test("wms-018: key-down for contextPicker twice toggles the picker back", .disabled(noFireReason))
    func dispatchPicker() {}

    @Test("wms-019: constructing the manager reserves the scheme chords in the key-command registry")
    func reservesExternalChords() throws {
        try withManager { _ in
            let availability = KeyCommandRegistry.shared.availability(
                of: Self.windowContextsChord, for: "unrelated.\(UUID().uuidString)")
            #expect(availability == .unavailable("taken by window contexts"))
        }
    }

    @Test("wms-020: customizing a shortcut moves the reservation with it",
          .disabled("KeyboardShortcuts persists customizations only in UserDefaults.standard; tests must not write it"))
    func reservationFollowsCustomization() {}

    @Test("wms-021: a released manager no longer dispatches but its chords stay reserved",
          .disabled(noFireReason))
    func releasedManagerKeepsReservation() {}

    @Test("wms-022: construction logs one info line in the manager's category",
          .disabled("The unified log is not reliably readable back inside a unit test process"))
    func initLog() {}
}
