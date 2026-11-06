import Carbon.HIToolbox
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// Registers nothing with the system: a hotkey test must not grab real keys.
@MainActor
private final class FakeRegistrar: HotkeyRegistrar {
    private(set) var registered: [(keyCode: UInt32, modifiers: UInt32)] = []
    private var handlers: [@MainActor () -> Void] = []
    private(set) var unregisterCount = 0

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping @MainActor () -> Void) -> Bool {
        registered.append((keyCode, modifiers))
        handlers.append(handler)
        return true
    }

    func unregisterAll() {
        unregisterCount += 1
        registered = []
        handlers = []
    }

    func press(_ index: Int) { handlers[index]() }
}

@MainActor
final class NoticeHotkeysTests: XCTestCase {

    func testBindingsMatchSpec() {
        let bindings = NoticeHotkeys.bindings
        XCTAssertEqual(bindings.map(\.keyCode), [
            UInt32(kVK_Return), UInt32(kVK_Delete), UInt32(kVK_ANSI_S), UInt32(kVK_ANSI_H)
        ])
        XCTAssertEqual(bindings.map(\.command), [.act, .archive, .snooze, .history])
        let modifiers = UInt32(controlKey | optionKey | cmdKey)
        XCTAssertTrue(bindings.allSatisfy { $0.modifiers == modifiers })
    }

    private struct Env {
        let center: NoticePresentationCenter
        let handler: RecordingHandler
        let clock: Clock
    }

    private func makeEnv() -> Env {
        let handler = RecordingHandler()
        let clock = Clock()
        let center = NoticePresentationCenter(
            handler: handler, rules: { .defaults }, filter: { NoticeFilter() },
            idle: IdleMonitor(idleSeconds: { 0 }), clock: { clock.now })
        center.presenters = [.toast: RecordingPresenter(), .alert: RecordingPresenter()]
        return Env(center: center, handler: handler, clock: clock)
    }

    func testEnablingRegistersEveryBindingAndDisablingRemovesThem() {
        let env = makeEnv()
        let registrar = FakeRegistrar()
        let hotkeys = NoticeHotkeys(center: env.center, registrar: registrar)
        XCTAssertTrue(registrar.registered.isEmpty, "nothing is grabbed until enabled")

        hotkeys.setEnabled(true)
        XCTAssertEqual(registrar.registered.map(\.keyCode), NoticeHotkeys.bindings.map(\.keyCode))
        hotkeys.setEnabled(true)
        XCTAssertEqual(registrar.registered.count, 4, "enabling twice registers once")

        hotkeys.setEnabled(false)
        XCTAssertTrue(registrar.registered.isEmpty)
        XCTAssertEqual(registrar.unregisterCount, 1)
    }

    func testCommandsActOnTheNewestShownNotice() {
        let env = makeEnv()
        let registrar = FakeRegistrar()
        let hotkeys = NoticeHotkeys(center: env.center, registrar: registrar)
        hotkeys.setEnabled(true)
        for id in ["a", "b", "c", "d"] {
            env.center.receive(Notice(id: id, timestamp: env.clock.now, source: "ci", title: id, urgency: .soon))
        }

        registrar.press(1) // archive: d
        registrar.press(2) // snooze 15 minutes: c
        registrar.press(0) // act: b, which has no action, so it is marked read
        registrar.press(3) // history

        XCTAssertEqual(env.handler.calls, [
            .setState("d", .archived),
            .snooze("c", env.clock.now.addingTimeInterval(15 * 60)),
            .setState("b", .read),
            .showHistory
        ])
    }

    func testCommandsWithNothingShownDoNothingButHistory() {
        let env = makeEnv()
        let hotkeys = NoticeHotkeys(center: env.center, registrar: FakeRegistrar())
        hotkeys.perform(.act)
        hotkeys.perform(.archive)
        hotkeys.perform(.snooze)
        XCTAssertTrue(env.handler.calls.isEmpty)
        hotkeys.perform(.history)
        XCTAssertEqual(env.handler.calls, [.showHistory])
    }
}
