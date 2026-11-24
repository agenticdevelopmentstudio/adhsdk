//
//  WKWebView+QuietPresentation.swift
//  AgenticDeveloperHubSDK
//

import WebKit
import AgenticDeveloperHubSDKCoreMacOS

extension WKWebView {

    /// Keeps the page painting while the app's windows are sunk behind the
    /// desktop picture.
    ///
    /// WebKit stops drawing into a window the window server reports occluded —
    /// it logs `window occluded 1`, `isViewVisible()` goes false, and what a
    /// screenshot picks up is whatever was last painted, which for a page that
    /// was never on screen is nothing at all. Quiet presentation sinks every
    /// window below the desktop *on purpose*, so under automation every webview
    /// is occluded by definition. JavaScript keeps running throughout — the
    /// page loads, scripts run, state persists — which is why this stayed
    /// invisible until something had to be photographed.
    ///
    /// One helper for every `WKWebView` the toolkit puts in a pane — the
    /// extension webview panel and the browser pane both call it — so the
    /// debug-only guard is spelled once (`dry`).
    ///
    /// Debug-only: a shipping binary never turns detection off for this
    /// reason — there is no automation driving a released app, and a real
    /// user's occluded window *should* stop painting rather than burn the
    /// battery drawing frames nobody can see. (The browser pane's activation
    /// shield turns it off in every build, but only when the user asks.)
    func keepPaintingUnderQuietPresentation() {
        guard keepsPaintingUnderQuietPresentation else { return }
        setWindowOcclusionDetectionEnabled(false)
    }

    /// Whether `keepPaintingUnderQuietPresentation` holds occlusion detection
    /// off in this process: a Debug build under quiet presentation. Anything
    /// else that turns detection back on (the browser's activation shield)
    /// asks this first, so it never undoes what the screenshots depend on.
    /// Always `false` in a shipping binary.
    var keepsPaintingUnderQuietPresentation: Bool {
        #if DEBUG
        QuietWindowPresentation.isEnabled
        #else
        false
        #endif
    }

    /// Turns WebKit's window-occlusion detection for this web view on or off.
    ///
    /// Off, the page goes on painting, and goes on seeing itself as visible,
    /// while its window is sunk, covered or minimized. Quiet presentation
    /// needs that in Debug builds and the browser pane's activation shield
    /// needs it in every build, so the SPI is spelled here once (`dry`).
    ///
    /// SPI: `_setWindowOcclusionDetectionEnabled:` is not API, so it is asked
    /// for by name and skipped where this WebKit has no such selector.
    func setWindowOcclusionDetectionEnabled(_ enabled: Bool) {
        let selector = NSSelectorFromString("_setWindowOcclusionDetectionEnabled:")
        guard responds(to: selector) else { return }
        // Called through the implementation rather than `perform(_:with:)`,
        // which takes an object: the parameter is a `BOOL`, and the only way to
        // pass a false one through `perform` is a nil argument that reads as
        // zero by accident (`explicit-over-implicit`).
        typealias Setter = @convention(c) (AnyObject, Selector, ObjCBool) -> Void
        let implementation = unsafeBitCast(method(for: selector), to: Setter.self)
        implementation(self, selector, ObjCBool(enabled))
    }
}
