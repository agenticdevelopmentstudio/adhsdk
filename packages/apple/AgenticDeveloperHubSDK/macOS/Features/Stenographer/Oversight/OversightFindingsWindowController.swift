import AgenticDeveloperHubSDKCore
import AIPluginKit
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

import AppKit

/// Singleton window controller for the AI Oversight window.
@MainActor
public final class OversightFindingsWindowController: SingleWindowController {
    public private(set) static var current: OversightFindingsWindowController?

    public static func present(service: any StenographerDaemonService, pluginManager: AIPluginManager? = nil) {
        ensureCurrent(service: service, pluginManager: pluginManager)
        current?.showWindow()
    }

    /// Constructs the singleton (registering it with `WindowManager.registry`)
    /// without showing it. `main.swift` registers this with `WindowManager`, which
    /// reopens the window at launch if its spec says so and it was open at quit.
    public static func ensureCurrent(service: any StenographerDaemonService,
                                     pluginManager: AIPluginManager? = nil) {
        if current == nil {
            current = OversightFindingsWindowController(service: service, pluginManager: pluginManager)
        }
    }

    public override func close() {
        window?.performClose(nil)
    }

    /// Hoist the oversight config gear into the title bar (Usage Details pattern) so
    /// every window's gear is in the same place.
    public override func configureWindow(_ window: NSWindow) {
        if let host = contentViewController as? OversightHostViewController {
            window.addTitlebarAccessoryViewController(host.makeTitlebarAccessory())
        }
    }

    private init(service: any StenographerDaemonService, pluginManager: AIPluginManager?) {
        super.init(windowID: "oversight-findings",
                   contentViewController: OversightHostViewController(
                       service: service, pluginManager: pluginManager))
        self.windowTitle = "Stenographer — AI Oversight"
        self.windowTitleSymbolName = "eye"
        self.windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]
        self.windowSpec = WindowSpec(
            defaultSize: NSSize(width: 760, height: 460),
            minSize: NSSize(width: 520, height: 300),
            defaultPosition: .center,
            persistsFrame: true
        )
    }
}
