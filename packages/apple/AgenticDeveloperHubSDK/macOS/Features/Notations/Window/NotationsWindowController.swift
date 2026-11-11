import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// Notes ▸ Notations: every branch's notes, active and archived, by project.
/// One window, non-modal, its frame remembered.
@MainActor
public final class NotationsWindowController: SingleWindowController {

    public private(set) static var current: NotationsWindowController?

    public static let windowID = "notations"

    private var backdropObserver: ThemePaletteObserver?

    public static func present(store: NotationsStore, goToProject: @escaping (Notation) -> Void) {
        ensureCurrent(store: store, goToProject: goToProject)
        current?.showWindow()
    }

    /// Constructs the singleton (registering it with the window registry)
    /// without showing it, so restore-on-launch can reopen it.
    public static func ensureCurrent(store: NotationsStore, goToProject: @escaping (Notation) -> Void) {
        if current == nil {
            current = NotationsWindowController(store: store, goToProject: goToProject)
        }
    }

    public override func close() {
        // performClose beeps on a window that isn't visible.
        guard window?.isVisible == true else { return }
        window?.performClose(nil)
    }

    public override func configureWindow(_ window: NSWindow) {
        WindowTitlebarAccessory.applyIntegratedTitlebar(to: window)
        window.titleVisibility = .hidden
        backdropObserver = ThemePaletteObserver { [weak window] palette in
            window?.backgroundColor = NSColor(palette.projectPaneBackdrop)
        }
    }

    private init(store: NotationsStore, goToProject: @escaping (Notation) -> Void) {
        let host = NotationsHostViewController(store: store, goToProject: goToProject)
        super.init(windowID: Self.windowID,
                   contentViewController: SafeAreaHostViewController(child: host, pinsToSafeArea: true))
        self.windowTitle = "Notations"
        self.accessibilityIdentifier = "notations-window"
        self.windowStyleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
        self.windowSpec = WindowSpec(
            defaultSize: NSSize(width: 900, height: 560),
            minSize: NSSize(width: 620, height: 360),
            defaultPosition: .center,
            persistsFrame: true
        )
    }
}
