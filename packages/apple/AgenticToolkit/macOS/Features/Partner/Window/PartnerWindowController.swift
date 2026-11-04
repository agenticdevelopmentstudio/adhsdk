import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

import AppKit

/// Singleton window controller for the Coding Partner window: tab cards, the
/// partner's transcript and its sessions' terminals, and "Notifications".
///
/// The Conversations window's recipe: built by ``ensureCurrent(controller:)``
/// without showing so `restoreOnLaunch()` can reopen it, always-on-top from a
/// setting kept live by an observer, and the gear in the title bar. Dressed as
/// a Projects window is: the integrated title bar with the tab column running
/// up behind it, the window's title in bold over the panes, and the
/// arrange-mode button beside the gear.
@MainActor
public final class PartnerWindowController: SingleWindowController {
    public private(set) static var current: PartnerWindowController?

    public static let windowID = "coding-partner"

    /// The window's contents, for the app's wiring and for key commands.
    public let splitViewController: PartnerSplitViewController

    private let toolbar: PartnerToolbar
    private let configDialog: WindowOptionsDialog
    private var floatingObserver: UserSettingObserver<Bool>?
    private let arrangeButton = ArrangeModeTitlebarButton(accessibilityID: "partner-window.arrange-button")
    private var backdropObserver: ThemePaletteObserver?

    public static func present(controller: PartnerController) {
        ensureCurrent(controller: controller)
        current?.showWindow()
    }

    /// Constructs the singleton (registering it with `WindowManager.registry`) without showing it.
    public static func ensureCurrent(controller: PartnerController) {
        if current == nil {
            current = PartnerWindowController(controller: controller)
        }
    }

    public override func close() {
        // performClose NSBeeps on a window that isn't visible.
        guard window?.isVisible == true else { return }
        window?.performClose(nil)
    }

    public override func configureWindow(_ window: NSWindow) {
        setFloating(UserSettings.partnerAlwaysOnTop.value)
        floatingObserver = UserSettingObserver(UserSettings.partnerAlwaysOnTop) { [weak self] floating in
            self?.setFloating(floating)
        }
        toolbar.install(in: window)
        WindowTitlebarAccessory.applyIntegratedTitlebar(to: window)
        // The title is drawn over the content, left-aligned in the heading
        // font, as a project window's is; the system's centred grey one goes.
        window.titleVisibility = .hidden
        // The window's own background is what shows through the clear title
        // bar, so it follows the theme as a Projects window's does.
        backdropObserver = ThemePaletteObserver { [weak window] palette in
            window?.backgroundColor = NSColor(palette.projectPaneBackdrop)
        }
        window.addTitlebarAccessoryViewController(
            configDialog.makeTitlebarAccessory(leading: [arrangeButton.button], width: 120))
        arrangeButton.attach(to: window)
    }

    private init(controller: PartnerController) {
        let split = PartnerSplitViewController(controller: controller)
        splitViewController = split
        toolbar = PartnerToolbar(controller: controller, commands: split.commands)
        configDialog = WindowOptionsDialog(title: "Coding Partner Window") {
            [
                ComposableSettings.CheckboxView(
                    with: ComposableSettings.ViewModel<Bool>(
                        title: "Always show above other windows",
                        setting: UserSettings.partnerAlwaysOnTop
                    )
                )
            ]
        }

        // Full height, behind the title bar: the tab column rises up behind the
        // traffic lights while the panes start below it (the split's own job).
        super.init(windowID: Self.windowID,
                   contentViewController: SafeAreaHostViewController(child: split, pinsToSafeArea: false))

        self.windowTitle = "Coding Partner"
        self.windowStyleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
        self.windowSpec = WindowSpec(
            defaultSize: NSSize(width: 1100, height: 720),
            minSize: NSSize(width: 800, height: 420),
            defaultPosition: .center,
            persistsFrame: true
        )
    }
}
