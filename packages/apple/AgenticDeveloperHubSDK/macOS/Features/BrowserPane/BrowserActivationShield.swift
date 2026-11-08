//
//  BrowserActivationShield.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import os
import WebKit

/// Hides focus and visibility changes from the page in one web view, so a
/// site cannot tell the user switched away from it (spec section 6).
///
/// Two halves, both best-effort:
/// - **Native**: WebKit's window-occlusion detection is turned off while the
///   shield is up, so a sunk or covered window neither stops painting nor
///   reports itself hidden. It applies at once.
/// - **Page script** (`BrowserActivationShield.js`): `document.hasFocus()`,
///   `visibilityState` and `hidden` always answer focused and visible, and the
///   window-level `focus`/`blur` and `visibilitychange`/`pagehide`/`freeze`
///   events are swallowed before the page's own listeners see them. It
///   applies from the next page load, plus one immediate run on a page that
///   is already showing when the shield goes up — over the main frame and
///   every same-origin frame below it — and one immediate run that takes it
///   off those same frames when the shield comes down (Pause Events, spec
///   section 7: pausing and unpausing act on the live page, not on the next
///   one). A cross-origin frame cannot be reached from the main frame and
///   WebKit has no public way to list frames, so a cross-origin frame that is
///   already loaded follows only from its next load.
///
/// The shield does not install its script itself. `WKUserContentController`
/// can only remove *every* user script at once, so one owner — the pane's
/// `installUserScripts()` — puts back everything the pane wants, and asks
/// the shield for `userScript` to do it (`dry`, one place that owns scripts).
///
/// One shield per web view: a pane that rebuilds its web view makes a new
/// shield with it.
@MainActor
public final class BrowserActivationShield {

    /// The comment the script starts with, so its presence among a
    /// controller's user scripts can be counted.
    public static let marker = "/* adk-activation-shield */"

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    /// The script's text as bundled, placeholders and all, read once from
    /// the framework's resources; `nil` when the resource is missing, which
    /// leaves only the native half.
    private static let template: String? = {
        guard let url = Bundle(for: BrowserActivationShield.self)
            .url(forResource: "BrowserActivationShield", withExtension: "js"),
            let text = try? String(contentsOf: url, encoding: .utf8) else {
            logger.error("BrowserActivationShield.js is missing from the framework; only the native half applies")
            return nil
        }
        return text
    }()

    /// Chosen per shield, so per web view, and written into every copy of
    /// the script this shield hands out — the document-start one, the
    /// immediate raise and the lift — so they recognise each other's record
    /// on a window, and a value the page put under the same name is not
    /// taken for one (see the script). The page never sees it: the script
    /// carries it as bytes and hands out only digests keyed to a fresh
    /// challenge. It is still one per web view, so even a flaw in that
    /// handshake could not link two jars (spec section 4). A rebuilt web
    /// view gets a new shield and a new token.
    let token = UUID().uuidString

    private func script(mode: String) -> String? {
        Self.script(mode: mode, token: token)
    }

    /// The shield script with `token` written in, set to `"raise"` or
    /// `"lift"`. Public for an engine that is not WebKit: Chromium injects
    /// the same script over the DevTools protocol, so both engines hide
    /// focus and visibility the same way (`dry`). The token must be one per
    /// page view, never shared, for the reason `token` gives. It goes in as
    /// a literal array of its UTF-8 bytes, never as text.
    public static func script(mode: String, token: String) -> String? {
        let bytes = "[" + token.utf8.map(String.init).joined(separator: ",") + "]"
        return template?
            .replacingOccurrences(of: "__ADK_SHIELD_TOKEN_BYTES__", with: bytes)
            .replacingOccurrences(of: "__ADK_SHIELD_MODE__", with: mode)
    }

    /// The script that shields: the document-start user script, and the
    /// immediate run when the shield goes up over a page already showing.
    private(set) lazy var source: String? = script(mode: "raise")

    /// The same script set to take the shim off every frame the immediate
    /// run can reach, when the shield comes down. A window the shim never
    /// reached has no record, and is left as it is.
    private(set) lazy var liftSource: String? = script(mode: "lift")

    private weak var webView: WKWebView?
    /// Whether the shield is up.
    public private(set) var isActive = false
    private lazy var builtUserScript: WKUserScript? = source.map {
        WKUserScript(source: $0, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page)
    }

    public init(webView: WKWebView) {
        self.webView = webView
    }

    /// The document-start user script to install while the shield is up, in
    /// the page world and every frame; `nil` while it is down.
    public var userScript: WKUserScript? {
        isActive ? builtUserScript : nil
    }

    /// Raises or lowers the shield. The caller reinstalls its user scripts
    /// when `isActive` changed, so the script follows on the next load; the
    /// page already showing is shielded, or unshielded, at once.
    public func apply(active: Bool) {
        guard active != isActive else { return }
        isActive = active
        guard let webView else { return }
        // A Debug build under quiet presentation holds detection off for its
        // screenshots; lowering the shield must not undo that.
        webView.setWindowOcclusionDetectionEnabled(!active && !webView.keepsPaintingUnderQuietPresentation)
        guard webView.url != nil, let source = active ? source : liftSource else { return }
        webView.evaluateJavaScript(source, in: nil, in: .page) { result in
            if case .failure(let error) = result {
                let reason = error.localizedDescription
                Self.logger.debug(
                    "activation shield did not change on the current page: \(reason, privacy: .public)")
            }
        }
    }
}
