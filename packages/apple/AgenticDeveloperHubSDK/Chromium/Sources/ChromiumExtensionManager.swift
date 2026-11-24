//
//  ChromiumExtensionManager.swift
//  AgenticDeveloperHubSDKChromium
//

import AppKit
import os
import AgenticDeveloperHubSDKMacOS

/// Manages one profile's extensions through a hidden browser on Chrome's own
/// extensions page, calling the same APIs that page calls
/// (`chrome.developerPrivate`, `chrome.management`), so what the Kitchen
/// shows is exactly what Chrome has installed and every change goes through
/// Chrome's own code (`native-controls`).
///
/// The browser is never in a view hierarchy, so nothing attaches it to a
/// window and nothing shows. `close()` releases it.
@MainActor
final class ChromiumExtensionManager: NSObject {

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "Chromium")
    /// How long the extensions page and each call may take.
    private static let timeout: TimeInterval = 30
    private static let extensionsPage = "chrome://extensions"

    private let browserView: ChromiumBrowserView
    /// The extensions page's one load: its waiters, its timeout and whether
    /// it failed (`BrowserPageLoadGate`, tested without Chromium).
    private let page = BrowserPageLoadGate(
        pageName: "Chrome's extensions page", timeout: ChromiumExtensionManager.timeout)

    init(profile: BrowserExtensionProfile) throws {
        let options = ChromiumBrowserOptions()
        options.hidden = true
        options.showsToolbar = false
        // Its own requests only: a hidden browser never writes the
        // profile's cookie default, so this cannot undo a cookie block the
        // person set for the panes sharing the profile.
        options.acceptsCookies = true
        switch profile {
        case .global:
            options.cachePath = nil
        case .jar(let id):
            let directory = ChromiumLauncher.jarProfileDirectory(for: id)
            guard FileManager.default.fileExists(atPath: directory.path) else {
                throw BrowserExtensionError.unavailable(
                    "This jar has no Chrome profile yet; open a Chrome pane on it first.")
            }
            options.cachePath = directory.path
        }
        browserView = ChromiumBrowserView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), options: options)
        super.init()
        browserView.delegate = self
        browserView.loadAddress(Self.extensionsPage)
    }

    /// The extensions page did not load; a fresh manager may do better.
    var pageFailed: Bool { page.hasFailed }

    func close() {
        browserView.delegate = nil
        browserView.close()
        page.close()
    }

    // MARK: Calls

    /// `chrome.developerPrivate` has no field for an extension Chrome turned
    /// off because an update asks for new permissions; `chrome.management`
    /// does (`disabledReason`), so each entry carries that one field from it.
    func list() async throws -> [BrowserExtension] {
        let value = try await evaluate("""
            (async () => {
              \(Self.callHelper)
              const infos = await call(chrome.developerPrivate.getExtensionsInfo,
                                       { includeDisabled: true, includeTerminated: true });
              const reasons = {};
              for (const item of await call(chrome.management.getAll)) {
                if (item.disabledReason) { reasons[item.id] = item.disabledReason; }
              }
              return infos.map((info) => Object.assign({}, info,
                                                       { disabledReason: reasons[info.id] || null }));
            })()
            """)
        return try BrowserExtension.decodeList(value ?? NSNull())
    }

    /// Never re-enables an extension Chrome turned off for new permissions:
    /// Chrome would answer with its permissions prompt, over this hidden
    /// browser where nobody can see it, and the call would wait for it until
    /// the timeout. Those permissions are the person's to read and accept,
    /// on Chrome's extensions page in a pane (`BrowserExtension.needsPermissionReview`).
    func setEnabled(_ id: String, enabled: Bool) async throws {
        let value = try await evaluate("""
            (async () => {
              \(Self.callHelper)
              const id = \(try Self.json(id));
              if (\(enabled)) {
                const info = await call(chrome.management.get, id);
                if (info.disabledReason === "permissions_increase") { return "needsPermissionReview"; }
              }
              await call(chrome.management.setEnabled, id, \(enabled));
            })()
            """)
        if value as? String == "needsPermissionReview" {
            throw BrowserExtensionError.unavailable(BrowserExtension.permissionReviewRefusal)
        }
    }

    /// Chrome's uninstall wants a user gesture, which `Runtime.evaluate`
    /// supplies, and from a page it always opens Chrome's own confirmation,
    /// whatever `showConfirmDialog` says. That dialog sits over this hidden
    /// browser where nobody can see it, so it is accepted here: the caller
    /// has already asked the person the same question.
    /// The acceptor is disarmed as soon as the call is over, answered or
    /// not, so it can never press a dialog some later call opens.
    func remove(_ id: String) async throws {
        browserView.acceptNextDialog(within: Self.timeout)
        defer { browserView.stopAcceptingDialogs() }
        _ = try await evaluate("""
            (async () => {
              \(Self.callHelper)
              await call(chrome.management.uninstall, \(try Self.json(id)), { showConfirmDialog: false });
            })()
            """)
    }

    /// The extensions page's own Update button: every extension checks for
    /// an update now.
    func updateAll() async throws {
        _ = try await evaluate("""
            (async () => {
              \(Self.callHelper)
              await call(chrome.developerPrivate.autoUpdate);
            })()
            """)
    }

    /// Calls a callback-style extension API as a promise, rejecting with
    /// `chrome.runtime.lastError` when the API sets it.
    private static let callHelper = """
        const call = (fn, ...args) => new Promise((resolve, reject) => {
          fn(...args, (result) => {
            const error = chrome.runtime && chrome.runtime.lastError;
            if (error) { reject(new Error(error.message)); } else { resolve(result); }
          });
        });
        """

    /// `value` as a JavaScript literal, so an identifier can never become code.
    private static func json(_ value: String) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
        guard let literal = String(bytes: data, encoding: .utf8) else {
            throw BrowserExtensionError.unavailable("Could not quote the extension id.")
        }
        return literal
    }

    // MARK: DevTools

    private func evaluate(_ expression: String) async throws -> Any? {
        try await waitForPage()
        let response = try await send("Runtime.evaluate", [
            "expression": expression, "awaitPromise": true, "returnByValue": true, "userGesture": true
        ])
        if let details = response["exceptionDetails"] as? [String: Any] {
            let exception = details["exception"] as? [String: Any]
            let message = exception?["description"] as? String ?? details["text"] as? String ?? "script failed"
            throw BrowserExtensionError.unavailable(message)
        }
        guard let result = response["result"] as? [String: Any],
              result["type"] as? String != "undefined" else { return nil }
        return result["value"]
    }

    private func send(_ method: String, _ params: [String: Any]) async throws -> [String: Any] {
        try await browserView.devToolsCall(method, params, timeout: Self.timeout) {
            BrowserExtensionError.unavailable($0)
        }
    }

    private func waitForPage() async throws {
        try await page.wait()
    }
}

// MARK: - What the hidden browser reports

extension ChromiumExtensionManager: ChromiumBrowserViewDelegate {

    func chromiumBrowserViewDidFinishMainFrameLoad(_ view: ChromiumBrowserView) {
        page.pageDidLoad()
    }

    func chromiumBrowserView(_ view: ChromiumBrowserView, didFailLoadWithMessage message: String, address: String) {
        Self.logger.error("extensions page reported a load failure: \(message, privacy: .public)")
        page.pageDidFail(message)
    }

    func chromiumBrowserViewAddressDidChange(_ view: ChromiumBrowserView) {}
    func chromiumBrowserViewTitleDidChange(_ view: ChromiumBrowserView) {}
    func chromiumBrowserViewLoadingStateDidChange(_ view: ChromiumBrowserView) {}
    func chromiumBrowserViewDidStartMainFrameLoad(_ view: ChromiumBrowserView) {}
    func chromiumBrowserView(_ view: ChromiumBrowserView, didLogConsoleText text: String, level: String) {}
    func chromiumBrowserView(_ view: ChromiumBrowserView, didRaiseDialog kind: ChromiumDialogKind, message: String) {}

    func chromiumBrowserView(
        _ view: ChromiumBrowserView, destinationForDownloadNamed name: String,
        completion: @escaping (String?) -> Void
    ) { completion(nil) }

    func chromiumBrowserView(
        _ view: ChromiumBrowserView, allowsMediaCaptureForHost host: String,
        camera: Bool, microphone: Bool, completion: @escaping (NSNumber?) -> Void
    ) { completion(NSNumber(value: false)) }

    func chromiumBrowserView(
        _ view: ChromiumBrowserView, popupViewForAddress address: String, userGesture: Bool
    ) -> ChromiumBrowserView? { nil }

    func chromiumBrowserViewDidClose(_ view: ChromiumBrowserView) {}

    func chromiumBrowserView(
        _ view: ChromiumBrowserView, openTabForAddress address: String, background: Bool, userGesture: Bool
    ) {}

    func chromiumBrowserView(_ view: ChromiumBrowserView, refusalForNavigationTo address: String) -> String? {
        nil
    }

    func chromiumBrowserViewShouldAcceptDrag(_ view: ChromiumBrowserView) -> Bool { false }

    func chromiumBrowserView(_ view: ChromiumBrowserView, shouldPerformTextInput action: String) -> Bool { false }

    func chromiumBrowserView(
        _ view: ChromiumBrowserView, didReceiveDevToolsEvent method: String,
        params: [String: Any], sessionId: String?
    ) {}
}
