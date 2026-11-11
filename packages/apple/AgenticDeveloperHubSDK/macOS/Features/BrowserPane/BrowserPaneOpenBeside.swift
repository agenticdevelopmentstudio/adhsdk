//
//  BrowserPaneOpenBeside.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit
import os

private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

extension WebBrowserPaneViewController {

    /// Opens `url` in a new pane on this pane's engine, split off to its
    /// right and on its jar, leaving this pane's page alone — the same split
    /// Browser Log and the automation's open-beside make. Returns the new
    /// pane; nil, logged, when this pane is in no project window or the
    /// layout has no room beside it.
    ///
    /// A new pane follows the shared jar setting, so a pane whose own jar
    /// override differs (a worktree jar in a project on the global one, say)
    /// hands the new pane the same override and the new pane moves onto it.
    /// A jar of the pane's own cannot be shared: the new pane gets one of
    /// its own.
    @discardableResult
    public func openInNewPaneBeside(_ url: URL) -> WebBrowserPaneViewController? {
        guard let (controller, host) = projectWindowHost() else {
            logger.info("page not opened beside a browser pane that is in no project window")
            return nil
        }
        guard let added = controller.splitPane(host, adding: engineKind.viewID, direction: .right),
              let pane = added.contentViewController as? WebBrowserPaneViewController else {
            logger.info("page not opened: the layout does not allow a browser pane beside this one")
            return nil
        }
        pane.adoptJar(of: self)
        pane.load(url)
        return pane
    }

    /// Whether `openInNewPaneBeside(_:)` has somewhere to put the new pane:
    /// this pane is in a project window whose layout allows another pane of
    /// its engine beside it.
    public var canOpenInNewPaneBeside: Bool {
        guard let (controller, host) = projectWindowHost() else { return false }
        return controller.canSplitPane(host, adding: engineKind.viewID)
    }

    private func projectWindowHost() -> (ComposableTabsWindowController, ComposableTabsPaneViewController)? {
        guard let nodeID = paneContext.paneNodeID,
              let window = viewIfLoaded?.window,
              let controller = window.windowController as? ComposableTabsWindowController,
              let host = controller.allPanes().first(where: { $0.nodeID == nodeID }) else { return nil }
        return (controller, host)
    }

    /// Moves this pane onto `other`'s jar when the shared setting put it on
    /// another one.
    private func adoptJar(of other: WebBrowserPaneViewController) {
        guard let wanted = other.resolvedJar.jar, wanted != .pane,
              resolvedJar.jar != wanted || resolvedJar.jarID != other.resolvedJar.jarID,
              let paneSettings else { return }
        paneSettings.set(wanted, for: UserSettings.browserPrivacyStorageJar)
        if needsRebuildForJar() { rebuildEngine() }
    }
}
