import AppKit
import CoreGraphics
import Foundation
import Testing
import AgenticDeveloperHubSDKCoreMacOS
@testable import AgenticDeveloperHubSDKCore

typealias ContextsMockControl = SystemWindowContextManagerTests.MockWindowControl

/// Builds live windows for the conformance suites below.
private func liveWindow(
    id: UInt32, app: String, title: String = "w", originX: CGFloat = 100, display: UInt32 = 0
) -> SystemWindowInfo {
    SystemWindowInfo(
        id: id, app: app, pid: 1, title: title,
        frame: CGRect(x: originX, y: 50, width: 400, height: 300),
        display: display, isOnScreen: true, layer: 0
    )
}

/// A dormant snapshot whose fingerprint is set directly, so the score it earns is known.
private func dormantSnapshot(
    app: String, pattern: String, strategy: MatchStrategy, display: UInt32
) -> SystemWindowSnapshot {
    SystemWindowSnapshot(
        windowID: nil,
        fingerprint: SystemWindowFingerprint(
            app: app, titlePattern: pattern, matchStrategy: strategy, display: display
        ),
        savedFrame: CGRect(x: 10, y: 20, width: 400, height: 300),
        display: display, app: app, title: ""
    )
}

@MainActor
@Suite("SystemWindowContextManager conformance")
struct ContextManagerConformanceTests {

    // MARK: - Helpers

    private struct Rig {
        let manager: SystemWindowContextManager
        let control: ContextsMockControl
        let store: SystemWindowContextStore
        let root: URL
    }

    private func makeRig(windows: [SystemWindowInfo] = []) -> Rig {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let control = ContextsMockControl(windows: windows)
        let store = SystemWindowContextStore(rootDirectory: root)
        let manager = SystemWindowContextManager(
            windowManager: control,
            stateStore: store,
            windowMatcher: SystemWindowMatcher(registry: HeuristicRegistry())
        )
        return Rig(manager: manager, control: control, store: store, root: root)
    }

    /// Persists a context holding `snapshot` and loads it into a fresh manager.
    private func makeRigSeeded(windows: [SystemWindowInfo], snapshot: SystemWindowSnapshot) throws -> (Rig, UUID) {
        let rig = makeRig(windows: windows)
        let context = SystemWindowContext(name: "Seeded", windowSnapshots: [snapshot])
        try rig.store.saveAll(contexts: [context], activeContextID: nil)
        try rig.manager.loadState()
        return (rig, context.id)
    }

    // MARK: - Reconcile

    @Test("contexts-006: a missing window of an app with no live windows keeps its id on load")
    func reconcileKeepsIDWhenAppAbsent() throws {
        let seed = makeRig(windows: [liveWindow(id: 99, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: seed.root) }
        let context = try seed.manager.createContext(name: "C")
        try seed.manager.addWindow(windowID: 99, to: context.id)

        let control = ContextsMockControl(windows: [liveWindow(id: 5, app: "Warp")])
        let manager = SystemWindowContextManager(windowManager: control, stateStore: seed.store)
        try manager.loadState()

        #expect(!manager.hasStaleWindows)
        #expect(manager.contexts.first?.windowSnapshots.first?.windowID == 99)
    }

    // MARK: - Window assignment

    @Test("contexts-018: adding a window already in another context throws windowAlreadyAssigned")
    func addWindowDuplicate() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let first = try rig.manager.createContext(name: "A")
        let second = try rig.manager.createContext(name: "B")
        try rig.manager.addWindow(windowID: 1, to: first.id)

        do {
            try rig.manager.addWindow(windowID: 1, to: second.id)
            Issue.record("addWindow should throw")
        } catch SystemWindowContextError.windowAlreadyAssigned(let windowID, let contextName) {
            #expect(windowID == 1)
            #expect(contextName == "A")
        } catch {
            Issue.record("expected windowAlreadyAssigned, got \(error)")
        }
    }

    @Test("contexts-019: adding a window already in the same context refreshes its snapshot")
    func addWindowRefresh() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let context = try rig.manager.createContext(name: "A")
        try rig.manager.addWindow(windowID: 1, to: context.id)

        let moved = liveWindow(id: 1, app: "Xcode", originX: 300)
        rig.control.windows = [moved]
        try rig.manager.addWindow(windowID: 1, to: context.id)

        let snapshots = try #require(rig.manager.contexts.first?.windowSnapshots)
        #expect(snapshots.count == 1)
        #expect(snapshots[0].savedFrame == moved.frame)
    }

    @Test("contexts-020: adding a window that is not live throws windowNotFound")
    func addWindowNotLive() throws {
        let rig = makeRig()
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let context = try rig.manager.createContext(name: "A")

        do {
            try rig.manager.addWindow(windowID: 555, to: context.id)
            Issue.record("addWindow should throw")
        } catch SystemWindowContextError.windowNotFound(let windowID) {
            #expect(windowID == 555)
        } catch {
            Issue.record("expected windowNotFound, got \(error)")
        }
    }

    // MARK: - Switching

    @Test("contexts-021: switching to an unknown context throws and touches no window")
    func switchUnknownContext() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let context = try rig.manager.createContext(name: "A")
        try rig.manager.addWindow(windowID: 1, to: context.id)
        rig.control.reset()

        do {
            try rig.manager.switchContext(to: UUID())
            Issue.record("switchContext should throw")
        } catch SystemWindowContextError.contextNotFound {
            // expected
        } catch {
            Issue.record("expected contextNotFound, got \(error)")
        }
        #expect(rig.control.moved.isEmpty)
        #expect(rig.control.framed.isEmpty)
    }

    @Test("contexts-022: switching to the active context only restores its windows")
    func switchSameContext() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let context = try rig.manager.createContext(name: "A")
        try rig.manager.addWindow(windowID: 1, to: context.id)
        try rig.manager.switchContext(to: context.id)
        rig.control.reset()

        try rig.manager.switchContext(to: context.id)

        #expect(rig.control.framed.contains { $0.id == 1 })
        #expect(rig.control.moved.isEmpty)
    }

    @Test("contexts-023: switching parks the old context, restores and focuses the new one, and commits")
    func switchRestoresAndFocuses() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode"), liveWindow(id: 2, app: "Warp")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let first = try rig.manager.createContext(name: "A")
        let second = try rig.manager.createContext(name: "B")
        try rig.manager.addWindow(windowID: 1, to: first.id)
        try rig.manager.addWindow(windowID: 2, to: second.id)
        try rig.manager.switchContext(to: first.id)
        rig.control.reset()

        try rig.manager.switchContext(to: second.id)

        #expect(rig.control.moved.contains { $0.id == 1 })
        let restored = rig.control.framed.first { $0.id == 2 }
        #expect(restored?.frame == CGRect(x: 100, y: 50, width: 400, height: 300))
        #expect(rig.control.focused == [2])
        #expect(rig.manager.activeContextID == second.id)
        #expect(try rig.store.loadState().activeContextID == second.id)
    }

    @Test("contexts-024: a parked window goes 30000 points left of the leftmost display, at its saved y")
    func parkingPosition() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode"), liveWindow(id: 2, app: "Warp")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let active = try rig.manager.createContext(name: "Active")
        let inactive = try rig.manager.createContext(name: "Inactive")
        try rig.manager.switchContext(to: active.id)
        rig.control.reset()

        try rig.manager.addWindow(windowID: 2, to: inactive.id)

        // The vector fixes a single screen at minX 0; the parking x is measured from the
        // host's leftmost display, which is 0 on that layout.
        let leftmost = NSScreen.screens.map(\.frame.minX).min() ?? 0
        let parked = try #require(rig.control.moved.first { $0.id == 2 })
        #expect(parked.point == CGPoint(x: leftmost - SystemWindowContextManager.parkingMargin, y: 50))
        #expect(SystemWindowContextManager.parkingMargin == 30_000)
    }

    @Test("contexts-025: a window already parked off-screen does not overwrite its saved frame")
    func frameCaptureGuard() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let first = try rig.manager.createContext(name: "A")
        let second = try rig.manager.createContext(name: "B")
        try rig.manager.addWindow(windowID: 1, to: first.id)
        try rig.manager.switchContext(to: first.id)
        let saved = try #require(rig.manager.contexts.first?.windowSnapshots.first?.savedFrame)

        rig.control.windows = [liveWindow(id: 1, app: "Xcode", originX: -30_000)]
        try rig.manager.switchContext(to: second.id)

        #expect(rig.manager.contexts.first?.windowSnapshots.first?.savedFrame == saved)
        #expect(saved.origin.x == 100)
    }

    // MARK: - Removal and focus

    @Test("contexts-026: removing a window from an inactive context restores it to its saved frame")
    func removeWindowRestores() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode"), liveWindow(id: 2, app: "Warp")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let active = try rig.manager.createContext(name: "A")
        let inactive = try rig.manager.createContext(name: "B")
        try rig.manager.switchContext(to: active.id)
        try rig.manager.addWindow(windowID: 2, to: inactive.id)
        rig.control.reset()

        let snapshot = try rig.manager.removeWindow(windowID: 2)

        #expect(snapshot.windowID == 2)
        let restored = rig.control.framed.first { $0.id == 2 }
        #expect(restored?.frame == snapshot.savedFrame)
    }

    @Test("contexts-027: removing a window that is in no context throws windowNotInAnyContext")
    func removeWindowUnknown() throws {
        let rig = makeRig()
        defer { try? FileManager.default.removeItem(at: rig.root) }
        do {
            try rig.manager.removeWindow(windowID: 777)
            Issue.record("removeWindow should throw")
        } catch SystemWindowContextError.windowNotInAnyContext(let windowID) {
            #expect(windowID == 777)
        } catch {
            Issue.record("expected windowNotInAnyContext, got \(error)")
        }
    }

    @Test("contexts-028: setting the last-focused window with no active context does nothing")
    func setLastFocusedNoActive() throws {
        let rig = makeRig()
        defer { try? FileManager.default.removeItem(at: rig.root) }

        try rig.manager.setLastFocusedWindow(windowID: 1)

        #expect(!FileManager.default.fileExists(atPath: rig.root.path))
    }

    // MARK: - Re-matching

    @Test("contexts-029: launch re-matching returns nothing when every snapshot is live")
    func launchRematchAllLive() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let context = try rig.manager.createContext(name: "A")
        try rig.manager.addWindow(windowID: 1, to: context.id)

        let result = try rig.manager.performLaunchReMatching()

        #expect(result == nil)
    }

    @Test("contexts-030: assigning a window to an unknown snapshot throws windowNotInAnyContext")
    func assignUnknownSnapshot() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let context = try rig.manager.createContext(name: "A")

        do {
            try rig.manager.assignWindowToSnapshot(windowID: 1, snapshotID: UUID(), contextID: context.id)
            Issue.record("assignWindowToSnapshot should throw")
        } catch SystemWindowContextError.windowNotInAnyContext(let windowID) {
            #expect(windowID == 1)
        } catch {
            Issue.record("expected windowNotInAnyContext, got \(error)")
        }
    }

    @Test("contexts-031: assigning an empty batch returns 0 and enumerates no windows")
    func assignBatchEmpty() throws {
        let rig = makeRig()
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let before = rig.control.listAllCount

        let applied = rig.manager.assignWindowsToSnapshots([])

        #expect(applied == 0)
        #expect(rig.control.listAllCount == before)
    }

    @Test("contexts-032: marking an app dormant compares the app name case-sensitively")
    func markAppDormantCase() throws {
        let rig = makeRig(windows: [liveWindow(id: 1, app: "Xcode")])
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let context = try rig.manager.createContext(name: "A")
        try rig.manager.addWindow(windowID: 1, to: context.id)

        #expect(rig.manager.markAppWindowsDormant(appName: "xcode") == 0)
        #expect(rig.manager.contexts.first?.windowSnapshots.first?.isLive == true)
    }

    @Test("contexts-033: re-matching dormant windows for an app is case-insensitive and attaches a window")
    func rematchApp() throws {
        // A fingerprint on display 1 against a window on display 0 scores 80, the threshold.
        let snapshot = dormantSnapshot(app: "Xcode", pattern: "", strategy: .appOnly, display: 1)
        let (rig, _) = try makeRigSeeded(windows: [liveWindow(id: 7, app: "Xcode")], snapshot: snapshot)
        defer { try? FileManager.default.removeItem(at: rig.root) }

        #expect(rig.manager.reMatchDormantWindowsForApp(appName: "XCODE") == 1)
        #expect(rig.manager.contexts.first?.windowSnapshots.first?.windowID == 7)
    }

    @Test("contexts-034: a new window scoring below the threshold does not claim a dormant snapshot")
    func newWindowBelowThreshold() throws {
        // A substring match (60) plus the same-display bonus (10) scores 70.
        let snapshot = dormantSnapshot(app: "Tool", pattern: "proj", strategy: .appAndTitleSubstring, display: 0)
        let window = liveWindow(id: 3, app: "Tool", title: "Project X")
        let (rig, _) = try makeRigSeeded(windows: [window], snapshot: snapshot)
        defer { try? FileManager.default.removeItem(at: rig.root) }

        let assigned = rig.manager.checkNewWindowForAutoAssignment(window)

        #expect(assigned == nil)
        #expect(rig.manager.contexts.first?.windowSnapshots.first?.isLive == false)
    }

    // MARK: - Custom rules

    @Test("contexts-035: a custom rule with auto-assign puts a matching new window in its target context")
    func customRuleAutoAssign() throws {
        let rig = makeRig()
        defer { try? FileManager.default.removeItem(at: rig.root) }
        let docs = try rig.manager.createContext(name: "Docs")
        let rule = CustomHeuristicRule(
            appName: "Safari", titlePattern: "docs", autoAssign: true, targetContextName: "docs"
        )
        try rig.manager.addCustomHeuristicRule(rule)

        let window = liveWindow(id: 9, app: "Safari", title: "Docs - Home")
        let target = rig.manager.checkCustomRulesForAutoAssignment(window)

        #expect(target == docs.id)
        #expect(rig.manager.contexts.first?.windowSnapshots.first?.windowID == 9)
    }

    @Test("contexts-036: a rule whose save fails is not added to the in-memory list")
    func customRuleWriteFirst() throws {
        let rig = makeRig()
        let blocker = FileManager.default.temporaryDirectory.appendingPathComponent("blocker-\(UUID().uuidString)")
        try Data("file".utf8).write(to: blocker)
        defer {
            try? FileManager.default.removeItem(at: rig.root)
            try? FileManager.default.removeItem(at: blocker)
        }
        let manager = SystemWindowContextManager(
            windowManager: rig.control,
            stateStore: rig.store,
            windowMatcher: SystemWindowMatcher(registry: HeuristicRegistry()),
            customHeuristicStore: CustomHeuristicStore(rootDirectory: blocker)
        )

        #expect(throws: (any Error).self) {
            try manager.addCustomHeuristicRule(CustomHeuristicRule(appName: "Safari", titlePattern: "docs"))
        }
        #expect(manager.customHeuristicRules.isEmpty)
    }

    // MARK: - Persistence

    @Test("contexts-041: a persistence failure is wrapped and the in-memory change stays")
    func persistErrorWrapped() throws {
        let rig = makeRig()
        let contextsDirectory = rig.root.appendingPathComponent("contexts")
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: contextsDirectory.path)
            try? FileManager.default.removeItem(at: rig.root)
        }
        let context = try rig.manager.createContext(name: "A")
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: contextsDirectory.path)

        do {
            try rig.manager.renameContext(id: context.id, to: "X")
            Issue.record("renameContext should throw")
        } catch SystemWindowContextError.persistenceFailed {
            // expected
        } catch {
            Issue.record("expected persistenceFailed, got \(error)")
        }
        #expect(rig.manager.contexts.first?.name == "X")
    }
}

@MainActor
@Suite("SystemWindowContextsModel conformance", .serialized)
struct ContextsModelConformanceTests {

    // MARK: - Helpers

    /// Runs `body` with the user settings swapped for an in-memory store, so the model's
    /// settings never touch the real defaults.
    private func withModel(
        windows: [SystemWindowInfo] = [],
        testEnvironment: Bool = true,
        defaultContexts: [SystemWindowContextsConfiguration.DefaultContext] = [],
        seed: SystemWindowSnapshot? = nil,
        _ body: (SystemWindowContextsModel, ContextsMockControl) throws -> Void
    ) throws {
        let previous = UserSettings.shared
        UserSettings.shared = UserSettings(with: InMemorySettingsStorageProvider())
        defer { UserSettings.shared = previous }

        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let control = ContextsMockControl(windows: windows)
        let store = SystemWindowContextStore(rootDirectory: root)
        if let seed {
            let context = SystemWindowContext(name: "Seeded", windowSnapshots: [seed])
            try store.saveAll(contexts: [context], activeContextID: nil)
        }
        let manager = SystemWindowContextManager(
            windowManager: control,
            stateStore: store,
            windowMatcher: SystemWindowMatcher(registry: HeuristicRegistry())
        )
        let configuration = SystemWindowContextsConfiguration(
            settingsKey: "conformance.\(UUID().uuidString)",
            notificationTitle: "Test",
            notificationIdentifier: "test",
            defaultContexts: defaultContexts
        )
        let model = SystemWindowContextsModel(
            contextManager: manager,
            windowManager: control,
            configuration: configuration,
            isTestEnvironment: testEnvironment
        )
        try body(model, control)
    }

    // MARK: - Tests

    @Test("contexts-037: adding the frontmost window with no active context reports it and returns false")
    func addFrontmostNoActive() throws {
        try withModel(windows: [liveWindow(id: 1, app: "Xcode")]) { model, _ in
            #expect(!model.addFrontmostWindow())
            #expect(model.lastError == "No active context. Switch to a context first.")
        }
    }

    @Test("contexts-038: switching to the next context wraps from the last to the first")
    func switchNextWraps() throws {
        try withModel { model, _ in
            model.createContext(name: "A")
            model.createContext(name: "B")
            model.createContext(name: "C")
            let third = try #require(model.contexts.last)
            model.switchContext(to: third.id)

            model.switchToNextContext()

            #expect(model.activeContextID == model.contexts.first?.id)
        }
    }

    @Test("contexts-039: hidden apps stay sorted and unique")
    func hiddenAppsSortedUnique() throws {
        try withModel { model, _ in
            model.addHiddenApp("Zed")
            model.addHiddenApp("Arc")
            model.addHiddenApp("Arc")

            #expect(model.settings.hiddenApps == ["Arc", "Zed"])
        }
    }

    @Test("contexts-040: unmatched items list only candidates that score above zero, best first")
    func unmatchedItemsCandidates() throws {
        // "proj" scores 90 (exact, same display), "Project X" on another display scores 60,
        // and "unrelated" scores 0 and is left out.
        let snapshot = dormantSnapshot(app: "Tool", pattern: "proj", strategy: .appAndTitleSubstring, display: 0)
        let windows = [
            liveWindow(id: 1, app: "Tool", title: "Project X", display: 1),
            liveWindow(id: 2, app: "Tool", title: "unrelated"),
            liveWindow(id: 3, app: "Tool", title: "proj")
        ]
        try withModel(windows: windows, seed: snapshot) { model, _ in
            model.loadState()
            model.refreshUnmatchedItems()

            #expect(model.unmatchedItems.count == 1)
            #expect(model.unmatchedItems.first?.candidates.map(\.score) == [90, 60])
        }
    }

    @Test("contexts-042: a test environment turns off notifications, observation and default seeding")
    func testEnvironmentFlags() throws {
        let defaults = [SystemWindowContextsConfiguration.DefaultContext(name: "Work", color: "#FF0000")]
        try withModel(testEnvironment: true, defaultContexts: defaults) { model, _ in
            #expect(!model.notificationsEnabled)
            #expect(!model.observationEnabled)
            model.loadState()
            #expect(model.contexts.isEmpty)
        }
    }
}
