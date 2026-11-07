//
//  BrowserContentRules.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import WebKit

/// The content blocker behind the Third-Party Content setting (spec section 9).
///
/// One `WKContentRuleList` per blocking value, compiled the first time it is
/// wanted and kept in WebKit's own `WKContentRuleListStore` after that, so
/// every pane and every launch after the first looks the list up instead of
/// compiling it again. Blocking is native — WebKit refuses the load before
/// the page sees a request — so unlike the page-script shims it is enforced,
/// not best-effort.
///
/// "Third party" is WebKit's `load-type: third-party`: a resource from a
/// different registrable domain from the page's. The page's own `document`
/// loads are never blocked, so a link to another site still opens.
public enum BrowserContentRules {

    /// What `blockAll` blocks: every resource type WebKit names except
    /// `document`, which is the page itself.
    static let blockAllResourceTypes = [
        "image", "style-sheet", "script", "font", "raw", "svg-document",
        "media", "popup", "ping", "fetch", "websocket", "other"
    ]

    /// The store identifier for a policy's list. Named after the value, so
    /// the two blocking values never overwrite each other's compiled list.
    static func identifier(for policy: BrowserThirdPartyContent) -> String {
        "adk.third-party.\(policy.rawValue)"
    }

    /// The content-blocker JSON for `policy`; `nil` for `.allow`, which is no
    /// list at all rather than an empty one.
    public static func json(for policy: BrowserThirdPartyContent) -> String? {
        let resourceTypes: [String]
        switch policy {
        case .allow: return nil
        case .blockScripts: resourceTypes = ["script"]
        case .blockAll: resourceTypes = blockAllResourceTypes
        }
        let types = resourceTypes.map { "\"\($0)\"" }.joined(separator: ",")
        return #"[{"trigger":{"url-filter":".*","resource-type":["#
            + types
            + #"],"load-type":["third-party"]},"action":{"type":"block"}}]"#
    }

    /// WebKit had no default rule-list store to give. Not expected on macOS;
    /// thrown rather than answered with `nil`, which means `.allow`.
    struct StoreUnavailable: Error {}

    /// The compiled list for `policy`: looked up in the default store first,
    /// compiled into it when absent. `nil` for `.allow`.
    ///
    /// A list already in the store under the policy's identifier is trusted
    /// as it is. If `json(for:)` ever changes, the identifier must change with
    /// it, or every Mac that compiled the old rules keeps them.
    @MainActor
    public static func ruleList(for policy: BrowserThirdPartyContent) async throws -> WKContentRuleList? {
        guard let json = json(for: policy) else { return nil }
        guard let store = WKContentRuleListStore.default() else { throw StoreUnavailable() }
        let identifier = identifier(for: policy)
        // Lookup throws when nothing is stored under the identifier; that is
        // the expected first-run answer, not a failure.
        if let cached = try? await store.contentRuleList(forIdentifier: identifier) {
            return cached
        }
        return try await store.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json)
    }
}
