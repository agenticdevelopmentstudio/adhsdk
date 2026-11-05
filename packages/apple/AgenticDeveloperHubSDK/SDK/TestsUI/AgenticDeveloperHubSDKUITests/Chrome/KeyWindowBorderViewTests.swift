import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The hairline that tells a chromeless window where it ends, and which of
/// several open ones is listening.
@MainActor
@Suite("Key window border")
struct KeyWindowBorderViewTests {

    private func makeManager() -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: terminalThemeID))
    }

    /// A test process is not the active application, so `makeKeyAndOrderFront`
    /// leaves `isKeyWindow` false and there is no way to ask AppKit for the
    /// state the border is drawn from. The window says whether it is key
    /// instead, which is the one thing the border actually reads.
    private final class StubWindow: NSWindow {
        var pretendKey = false
        override var isKeyWindow: Bool { pretendKey }
    }

    private func hosted() -> (KeyWindowBorderView, StubWindow) {
        let window = StubWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false)
        let border = KeyWindowBorderView()
        border.frame = window.contentView?.bounds ?? .zero
        window.contentView?.addSubview(border)
        return (border, window)
    }

    @Test("the line is the theme's accent, not a colour of its own")
    func lineIsTheThemesAccent() {
        let manager = makeManager()
        let (border, window) = hosted()
        let accent = ThemePaletteObserver.currentPalette.nsColor(.accent)

        let drawn = border.strokeColor.usingColorSpace(.sRGB)!
        let expected = accent.usingColorSpace(.sRGB)!
        #expect(abs(drawn.redComponent - expected.redComponent) < 0.001)
        #expect(abs(drawn.greenComponent - expected.greenComponent) < 0.001)
        #expect(abs(drawn.blueComponent - expected.blueComponent) < 0.001)
        withExtendedLifetime((manager, window)) {}
    }

    /// The whole signal: same line, brighter, when this is the window you are
    /// typing into.
    @Test("the line brightens while the window is key")
    func keyWindowIsBrighter() {
        let manager = makeManager()
        let (border, window) = hosted()

        #expect(border.strokeColor.alphaComponent == border.inactiveAlpha)

        window.pretendKey = true
        #expect(border.strokeColor.alphaComponent == border.activeAlpha)
        #expect(border.activeAlpha > border.inactiveAlpha)

        withExtendedLifetime(manager) {}
    }


    /// Key state arrives as a notification about *this* window, so a border
    /// that subscribed to the wrong object — or forgot to re-subscribe when it
    /// was moved into one — would keep drawing the state it was born with.
    @Test("becoming key repaints the line")
    func keyChangeRepaints() {
        let (border, window) = hosted()

        border.needsDisplay = false
        window.pretendKey = true
        NotificationCenter.default.post(
            name: NSWindow.didBecomeKeyNotification, object: window)
        #expect(border.needsDisplay)
    }

    /// It covers the whole window, so if it ever answered a hit test the chat
    /// underneath would stop receiving clicks entirely.
    @Test("the border never takes a click")
    func clickThrough() {
        let (border, window) = hosted()
        #expect(border.hitTest(NSPoint(x: 10, y: 10)) == nil)
        withExtendedLifetime(window) {}
    }

    @Test("a chat window is given one")
    func chatWindowInstallsABorder() {
        let manager = makeManager()
        let viewModel = ObservableChatViewModel(backend: FakeBackend(), localParticipantID: "user")
        let controller = ChatWindowController(
            viewModel: viewModel,
            localParticipantID: "user",
            configuration: ChatWindowConfiguration(
                title: "Test", defaultsNamespace: "test.border", appearanceTitle: "Test Window"))

        let root = controller.window?.contentView
        #expect(root?.subviews.contains { $0 is KeyWindowBorderView } == true)
        // Above the chat, or the chat's own surface would paint over it.
        let views = root?.subviews ?? []
        let chatIndex = views.firstIndex { $0 is InlineChatView }
        let borderIndex = views.firstIndex { $0 is KeyWindowBorderView }
        #expect(chatIndex != nil && borderIndex != nil && borderIndex! > chatIndex!)
        withExtendedLifetime(manager) {}
    }
}
