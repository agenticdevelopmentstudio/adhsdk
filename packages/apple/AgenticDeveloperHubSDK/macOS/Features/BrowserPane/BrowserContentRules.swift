//
//  BrowserContentRules.swift
//  AgenticDeveloperHubSDK
//

import CryptoKit
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
/// different registrable domain from the page's. The top-level document is
/// never blocked, so a link to another site still opens; a frame's document
/// (`child-document`) is, under Block All.
public enum BrowserContentRules {

    /// What `blockAll` blocks: every resource type WebKit names except
    /// `document` and `top-document`, which cover the page itself.
    /// `child-document` is a frame's document: a third-party iframe is
    /// blocked before its request (and its cookies) leave, as Chrome panes
    /// block a third-party sub-frame.
    static let blockAllResourceTypes = [
        "image", "style-sheet", "script", "font", "raw", "svg-document",
        "media", "popup", "ping", "fetch", "websocket", "other", "child-document"
    ]

    /// The store identifier for a policy's list:
    /// `adk.third-party.<rawValue>.<first 12 hex of SHA-256(json)>`.
    ///
    /// Named after the value, so the two blocking values never overwrite each
    /// other's compiled list, and after the rules themselves, so a changed
    /// rule set is a new identifier and never picks up a list compiled from
    /// the old one that is still sitting in the store.
    static func identifier(for policy: BrowserThirdPartyContent, json: String) -> String {
        let digest = SHA256.hash(data: Data(json.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "adk.third-party.\(policy.rawValue).\(hex.prefix(12))"
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
    /// A list already in the store under the identifier is trusted as it is;
    /// the identifier carries a hash of the JSON, so it can only be a list
    /// compiled from these exact rules.
    @MainActor
    public static func ruleList(for policy: BrowserThirdPartyContent) async throws -> WKContentRuleList? {
        guard let json = json(for: policy) else { return nil }
        guard let store = WKContentRuleListStore.default() else { throw StoreUnavailable() }
        let identifier = identifier(for: policy, json: json)
        // Lookup throws when nothing is stored under the identifier, which is
        // the expected first-run answer. `try?` also swallows a real store
        // error; the compile below then meets the same store and reports it.
        if let cached = try? await store.contentRuleList(forIdentifier: identifier) {
            return cached
        }
        return try await store.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json)
    }
}
