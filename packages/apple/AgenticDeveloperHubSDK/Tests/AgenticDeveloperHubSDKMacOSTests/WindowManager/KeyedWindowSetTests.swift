//
//  KeyedWindowSetTests.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS
import Testing

/// `KeyedWindowSet` against fake controllers and a `UserSetting` bound to an
/// in-memory `UserSettings.shared`, so nothing touches the real defaults.
/// Every test body is synchronous on the main actor, so the swap of the
/// shared store cannot interleave with another main-actor test.
@MainActor
@Suite struct KeyedWindowSetTests {

    final class FakeController {
        let key: String
        let onClose: () -> Void
        init(key: String, onClose: @escaping () -> Void) {
            self.key = key
            self.onClose = onClose
        }
    }

    /// Records every call the set makes to its closures.
    @MainActor
    final class Harness {
        var opens: [(key: String, activates: Bool)] = []
        var broughtForward: [FakeController] = []
        var declines: Set<String> = []
        var made: [String: FakeController] = [:]

        func makeSet(_ setting: UserSetting<[String]>) -> KeyedWindowSet<FakeController> {
            KeyedWindowSet(
                setting: setting,
                open: { [unowned self] key, activates, onClose in
                    self.opens.append((key, activates))
                    guard !self.declines.contains(key) else { return nil }
                    let controller = FakeController(key: key, onClose: onClose)
                    self.made[key] = controller
                    return controller
                },
                bringForward: { [unowned self] controller in self.broughtForward.append(controller) }
            )
        }
    }

    /// Runs `body` with `UserSettings.shared` pointed at an in-memory store
    /// and a fresh setting created against it, restoring the shared store after.
    private func withSetting(
        stored: [String]? = nil,
        _ body: (UserSetting<[String]>) throws -> Void
    ) rethrows {
        let previous = UserSettings.shared
        UserSettings.shared = UserSettings(with: InMemorySettingsStorageProvider())
        defer { UserSettings.shared = previous }
        let setting = UserSetting<[String]>("keyed_window_set_tests", default: [])
        if let stored { setting.value = stored }
        try body(setting)
    }

    @Test func openTwiceBringsForward() {
        withSetting { setting in
            let harness = Harness()
            let set = harness.makeSet(setting)

            let first = set.open(key: "a")
            let second = set.open(key: "a")

            #expect(first != nil)
            #expect(first === second)
            #expect(harness.opens.map(\.key) == ["a"])
            #expect(harness.opens.map(\.activates) == [true])
            #expect(harness.broughtForward.count == 1)
            #expect(harness.broughtForward.first === first)
            #expect(set.controller(for: "a") === first)
            #expect(set.keys == ["a"])
            #expect(setting.value == ["a"])
        }
    }

    @Test func closeForgets() throws {
        try withSetting { setting in
            let harness = Harness()
            let set = harness.makeSet(setting)
            let controller = try #require(set.open(key: "a"))
            _ = set.open(key: "b")

            controller.onClose()

            #expect(set.controller(for: "a") == nil)
            #expect(set.keys == ["b"])
            #expect(setting.value == ["b"])

            let reopened = set.open(key: "a")
            #expect(reopened != nil)
            #expect(reopened !== controller)
            #expect(harness.opens.map(\.key) == ["a", "b", "a"])
            #expect(harness.broughtForward.isEmpty)
            #expect(set.keys == ["b", "a"])
        }
    }

    @Test func restoreDropsFailures() {
        withSetting(stored: ["a", "gone", "b"]) { setting in
            let harness = Harness()
            harness.declines = ["gone"]
            let set = harness.makeSet(setting)

            set.restore()

            #expect(harness.opens.map(\.key) == ["a", "gone", "b"])
            #expect(harness.opens.allSatisfy { !$0.activates })
            #expect(set.keys == ["a", "b"])
            #expect(setting.value == ["a", "b"])
            #expect(set.controller(for: "a") === harness.made["a"])
            #expect(set.controller(for: "b") === harness.made["b"])
            #expect(set.controller(for: "gone") == nil)
            #expect(harness.broughtForward.isEmpty)
        }
    }

    @Test func orderIsPreserved() {
        withSetting { setting in
            let harness = Harness()
            harness.declines = ["x"]
            let set = harness.makeSet(setting)

            _ = set.open(key: "b")
            _ = set.open(key: "a")
            _ = set.open(key: "b")
            let declined = set.open(key: "x")

            #expect(declined == nil)
            #expect(set.controller(for: "x") == nil)
            #expect(set.keys == ["b", "a"])
            #expect(setting.value == ["b", "a"])
        }
    }
}
