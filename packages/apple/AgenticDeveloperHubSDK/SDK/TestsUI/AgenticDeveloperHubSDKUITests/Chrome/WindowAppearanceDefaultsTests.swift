import Testing
import AppKit
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The four switches behind a chat window's gear: what they remember, and what
/// they do to the window when they come back.
@MainActor
@Suite("Window appearance")
struct WindowAppearanceDefaultsTests {

    /// A suite of its own per test, so nothing here can read or write the
    /// running app's real preferences.
    private func makeDefaults(_ namespace: String = "test.window") -> WindowAppearanceDefaults {
        let suite = UserDefaults(suiteName: "adt.tests.\(UUID().uuidString)")!
        return WindowAppearanceDefaults(namespace: namespace, defaults: suite)
    }

    private func makeManager() -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: terminalThemeID))
    }

    private func makeChat() -> InlineChatView {
        let viewModel = ObservableChatViewModel(backend: FakeBackend(), localParticipantID: "user")
        return InlineChatView(viewModel: viewModel, localParticipantID: "user")
    }

    // MARK: Storage

    @Test("an untouched window opens at the theme's own settings")
    func defaultsAreTheThemesOwn() {
        let defaults = makeDefaults()
        // `UserDefaults` answers 0 for an absent double, and a text scale of 0
        // lays a window out at no height at all — hence the explicit fallback.
        #expect(defaults.textScale == 1)
        // Zero *percent* transparency — the theme's own alpha, untouched.
        // Read as an alpha this used to be 1, which is the same window and
        // the opposite number; the slider now counts the way a reader does.
        #expect(defaults.transparency == 0)
        #expect(defaults.isFloating == false)
        // On, the way web's caret blinks unconditionally.
        #expect(defaults.blinksCaret)
    }

    @Test("each switch survives being written and read back")
    func valuesRoundTrip() {
        let defaults = makeDefaults()
        defaults.textScale = 1.25
        defaults.transparency = 60
        defaults.isFloating = true
        defaults.blinksCaret = false

        #expect(defaults.textScale == 1.25)
        #expect(defaults.transparency == 60)
        #expect(defaults.isFloating)
        #expect(defaults.blinksCaret == false)
    }

    @Test("a value edited outside the app is clamped rather than obeyed")
    func storedValuesAreClamped() {
        let suite = UserDefaults(suiteName: "adt.tests.\(UUID().uuidString)")!
        suite.set(9.0, forKey: "test.window.textScale")
        suite.set(-3.0, forKey: "test.window.transparencyPercent")
        let defaults = WindowAppearanceDefaults(namespace: "test.window", defaults: suite)

        #expect(defaults.textScale == WindowAppearanceDefaults.textScaleRange.upperBound)
        #expect(defaults.transparency == WindowAppearanceDefaults.transparencyRange.lowerBound)
    }

    /// The namespace is the whole reason two apps can build on this toolkit
    /// without one's gear moving the other's window.
    @Test("two namespaces in one suite do not see each other")
    func namespacesAreIndependent() {
        let suite = UserDefaults(suiteName: "adt.tests.\(UUID().uuidString)")!
        let first = WindowAppearanceDefaults(namespace: "app.one", defaults: suite)
        let second = WindowAppearanceDefaults(namespace: "app.two", defaults: suite)

        first.textScale = 1.5
        #expect(second.textScale == 1)
    }

    // MARK: Restoring

    @Test("what was saved is on the window and the chat before either is shown")
    func restoreReplaysEverySwitch() {
        let manager = makeManager()
        let defaults = makeDefaults()
        defaults.textScale = 1.5
        defaults.transparency = 50
        defaults.isFloating = true
        defaults.blinksCaret = false

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled], backing: .buffered, defer: true)
        let chat = makeChat()
        let controller = ChatWindowAppearanceController(
            window: window, chatView: chat, defaults: defaults, title: "Test Window")
        controller.restore()

        // The scale lands on this chat's own scope, not on the app-wide
        // manager: one window's slider must not resize another window's text.
        #expect(chat.themeScope.textScale == 1.5)
        #expect(manager.textScale == 1)
        // And transparency lands on the chat's surface, not the window's
        // `alphaValue`, which would fade the text and the gear with it.
        #expect(chat.surfaceTransparency == 50)
        #expect(window.alphaValue == 1)
        #expect(window.level == .floating)
        #expect(chat.inputField.caretBlinks == false)
        withExtendedLifetime(manager) {}
    }

    /// The gear's *position* is the convention this component exists to keep —
    /// a reader who finds it at the trailing edge of one window's title bar
    /// looks for it there in the next.
    @Test("installing puts a right-hand titlebar accessory on the window")
    func installAddsTheGear() {
        let manager = makeManager()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled], backing: .buffered, defer: true)
        let controller = ChatWindowAppearanceController(
            window: window, chatView: makeChat(), defaults: makeDefaults(), title: "Test Window")
        controller.install()

        let accessory = window.titlebarAccessoryViewControllers.first
        #expect(accessory != nil)
        #expect(accessory?.layoutAttribute == .right)
        withExtendedLifetime(manager) {}
    }

    /// Windows saved before the slider counted percentages hold an *alpha*
    /// under the old key. Read as a percentage it would be backwards — 0.2
    /// meaning nearly opaque — so the old key is converted rather than
    /// reinterpreted, once, on the way out.
    @Test("a window saved under the old alpha reads as the same window")
    func legacyAlphaMigrates() {
        let suite = UserDefaults(suiteName: "adt.tests.\(UUID().uuidString)")!
        suite.set(0.4, forKey: "test.window.transparency")
        let defaults = WindowAppearanceDefaults(namespace: "test.window", defaults: suite)

        #expect(defaults.transparency == 60)
    }

    @Test("writing a percentage wins over the old alpha")
    func writtenPercentWinsOverLegacy() {
        let suite = UserDefaults(suiteName: "adt.tests.\(UUID().uuidString)")!
        suite.set(0.4, forKey: "test.window.transparency")
        let defaults = WindowAppearanceDefaults(namespace: "test.window", defaults: suite)
        defaults.transparency = 10

        #expect(defaults.transparency == 10)
    }

    /// The switch a host surfaces as "Rain". On by default, because a window
    /// that was given a backdrop was given it to be seen.
    @Test("the backdrop switch defaults to on and is remembered off")
    func backdropDefaultsOn() {
        let defaults = makeDefaults()
        #expect(defaults.showsBackdrop)

        defaults.showsBackdrop = false
        #expect(defaults.showsBackdrop == false)
    }

    @Test("a backdrop turned off before the window opens stays off")
    func restoreReplaysTheBackdropSwitch() {
        let manager = makeManager()
        let defaults = makeDefaults()
        defaults.showsBackdrop = false

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled], backing: .buffered, defer: true)
        let chat = makeChat()
        chat.backdrop = NSView()
        let controller = ChatWindowAppearanceController(
            window: window, chatView: chat, defaults: defaults, title: "Test Window")
        controller.restore()

        #expect(chat.showsBackdrop == false)
        #expect(chat.backdrop?.isHidden == true)
        withExtendedLifetime(manager) {}
    }

    // MARK: ⌘+ / ⌘- / ⌘0

    private func makeController(
        _ defaults: WindowAppearanceDefaults, _ chat: InlineChatView
    ) -> ChatWindowAppearanceController {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled], backing: .buffered, defer: true)
        return ChatWindowAppearanceController(
            window: window, chatView: chat, defaults: defaults, title: "Test Window")
    }

    @Test("a nudge moves the saved scale by a tenth and lands on the chat")
    func nudgeStepsByATenth() {
        let manager = makeManager()
        let defaults = makeDefaults()
        let chat = makeChat()
        let controller = makeController(defaults, chat)
        controller.restore()

        controller.nudgeTextScale(by: 1)
        #expect(abs(defaults.textScale - 1.1) < 0.0001)
        #expect(abs(chat.themeScope.textScale - 1.1) < 0.0001)

        controller.nudgeTextScale(by: -1)
        #expect(abs(defaults.textScale - 1) < 0.0001)
        withExtendedLifetime(manager) {}
    }

    /// Zero is the reset, not a step of nothing — ⌘0 is what a reader reaches
    /// for after nudging too far.
    @Test("a nudge of zero returns to the theme's own size")
    func nudgeOfZeroResets() {
        let manager = makeManager()
        let defaults = makeDefaults()
        defaults.textScale = 1.6
        let chat = makeChat()
        let controller = makeController(defaults, chat)
        controller.restore()

        controller.nudgeTextScale(by: 0)
        #expect(defaults.textScale == 1)
        #expect(chat.themeScope.textScale == 1)
        withExtendedLifetime(manager) {}
    }

    @Test("nudging past the end stops at the end")
    func nudgeClampsAtTheRange() {
        let manager = makeManager()
        let defaults = makeDefaults()
        let chat = makeChat()
        let controller = makeController(defaults, chat)
        controller.restore()

        for _ in 0..<50 { controller.nudgeTextScale(by: 1) }
        #expect(defaults.textScale == WindowAppearanceDefaults.textScaleRange.upperBound)

        for _ in 0..<50 { controller.nudgeTextScale(by: -1) }
        #expect(defaults.textScale == WindowAppearanceDefaults.textScaleRange.lowerBound)
        withExtendedLifetime(manager) {}
    }
}
