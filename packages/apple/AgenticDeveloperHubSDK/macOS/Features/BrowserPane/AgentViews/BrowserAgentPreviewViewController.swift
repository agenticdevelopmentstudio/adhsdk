//
//  BrowserAgentPreviewViewController.swift
//  AgenticDeveloperHubSDK
//
//  Recipe: workspace/browser/agent-views (spec section 2.4).
//

import AppKit
import WebKit

/// Agent preview: the agent's page (`AgentPage.html()`) rendered in a sealed
/// web view of its own.
///
/// Sealed three ways (`preview-blocks-network`, `preview-has-javascript-off`,
/// `preview-cancels-navigation`): content JavaScript is off, a
/// block-everything content rule list is installed before anything loads,
/// and every navigation but the controller's own load is cancelled. The page
/// carries no `src` to begin with; the rule list is there for anything the
/// page's markup could still name. If the rule list cannot be compiled the
/// preview loads nothing at all rather than load unsealed.
@MainActor
final class BrowserAgentPreviewViewController: NSViewController, WKNavigationDelegate {

    /// The rule list every preview installs: `BrowserContentRules.blockEverything()`.
    static let defaultRuleList: @MainActor () async throws -> WKContentRuleList = {
        try await BrowserContentRules.blockEverything()
    }

    /// The preview's web view. Internal so the element picker can reach it.
    let webView: WKWebView

    /// The installed block-everything list, `nil` until it compiles (and for
    /// good, should it fail).
    private(set) var ruleList: WKContentRuleList?

    /// The HTML last handed to the web view.
    private(set) var shownHTML: String?

    /// The agent page last handed to the web view: what a pick's
    /// `data-adk-ref` resolves against (recipe `workspace/browser/hide-from-agent`).
    private(set) var shownPage: AgentPage?

    /// Called each time a document finishes loading, so the agent list's
    /// picker can install itself again in the new document.
    var onPageLoad: (() -> Void)?

    /// Whether the controller's own latest load has yet to be asked about:
    /// 1 lets exactly one `about:blank` navigation through, 0 lets none.
    /// Set (never added to) by each load, so a load superseded before
    /// WebKit asked about it leaves no credit behind, and cleared when the
    /// load it was for finishes or fails.
    private var allowedLoads = 0
    /// The load `allowedLoads` is for.
    private var ownNavigation: WKNavigation?
    private var waitingPage: AgentPage?

    init(ruleList makeRuleList: @escaping @MainActor () async throws -> WKContentRuleList = defaultRuleList) {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        webView.setAccessibilityIdentifier("browser.agent-preview")
        webView.keepPaintingUnderQuietPresentation()
        Task { @MainActor [weak self] in
            let list = try? await makeRuleList()
            guard let self, let list else { return }
            self.webView.configuration.userContentController.add(list)
            self.ruleList = list
            if let page = self.waitingPage {
                self.waitingPage = nil
                self.load(page)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() { view = webView }

    /// Shows `page`, once the rule list is installed.
    func show(_ page: AgentPage) {
        guard ruleList != nil else {
            waitingPage = page
            return
        }
        load(page)
    }

    private func load(_ page: AgentPage) {
        let html = page.html()
        shownHTML = html
        shownPage = page
        allowedLoads = 1
        ownNavigation = webView.loadHTMLString(html, baseURL: nil)
    }

    /// The controller's own load ended: no credit outlives it.
    private func ownLoadEnded(_ navigation: WKNavigation?) {
        guard let navigation, navigation === ownNavigation else { return }
        ownNavigation = nil
        allowedLoads = 0
    }

    /// Whether a navigation may proceed: only a load this controller
    /// started — WebKit reports it as `.other` to `about:blank` (or no URL)
    /// — and only while one is outstanding.
    static func policy(allowedLoads: Int, url: URL?, navigationType: WKNavigationType) -> WKNavigationActionPolicy {
        guard allowedLoads > 0, navigationType == .other else { return .cancel }
        guard let url else { return .allow }
        return url.absoluteString == "about:blank" ? .allow : .cancel
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction)
        async -> WKNavigationActionPolicy {
        // A subframe's load is never the controller's own.
        guard navigationAction.targetFrame?.isMainFrame ?? false else { return .cancel }
        let decision = Self.policy(allowedLoads: allowedLoads, url: navigationAction.request.url,
                                   navigationType: navigationAction.navigationType)
        if decision == .allow { allowedLoads -= 1 }
        return decision
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ownLoadEnded(navigation)
        onPageLoad?()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        ownLoadEnded(navigation)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        ownLoadEnded(navigation)
    }
}

/// The Agent preview as the agent list's picker sees it.
extension BrowserAgentPreviewViewController: BrowserAgentPickSurface {
    var pickWebView: WKWebView { webView }
}
