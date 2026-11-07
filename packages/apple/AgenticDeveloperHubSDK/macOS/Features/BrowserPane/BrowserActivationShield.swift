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

    /// The script's text, read once from the framework's resources; `nil`
    /// when the resource is missing, which leaves only the native half.
    static let source: String? = {
        guard let url = Bundle(for: BrowserActivationShield.self)
            .url(forResource: "BrowserActivationShield", withExtension: "js"),
            let text = try? String(contentsOf: url, encoding: .utf8) else {
            logger.error("BrowserActivationShield.js is missing from the framework; only the native half applies")
            return nil
        }
        return text
    }()

    /// Takes the shim off every frame the immediate run can reach, by calling
    /// the function each shielded window keeps under `__adkActivationShield`
    /// (see the script). A window the shim never reached has none, and is
    /// left as it is.
    static let liftSource = """
    (function () {
      'use strict';
      function visit(w) {
        try {
          var lift = w.__adkActivationShield;
          if (typeof lift === 'function') { lift(); }
        } catch (e) { return; }
        var count = 0;
        try { count = w.frames.length; } catch (e) { return; }
        for (var i = 0; i < count; i += 1) {
          try { visit(w.frames[i]); } catch (e) { /* cross-origin */ }
        }
      }
      visit(window);
    })();
    """

    private weak var webView: WKWebView?
    /// Whether the shield is up.
    public private(set) var isActive = false
    private lazy var builtUserScript: WKUserScript? = Self.source.map {
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
        guard webView.url != nil, let source = active ? Self.source : Self.liftSource else { return }
        webView.evaluateJavaScript(source, in: nil, in: .page) { result in
            if case .failure(let error) = result {
                let reason = error.localizedDescription
                Self.logger.debug(
                    "activation shield did not change on the current page: \(reason, privacy: .public)")
            }
        }
    }
}
