#if canImport(AgenticDeveloperHubSDKCore)
//
//  BrowserHiddenItem.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import Foundation

/// Which hidden-item list an entry belongs to: the user's own ("Hide
/// distracting items", hidden from the person), or the agent's (hidden from
/// an agent reading the page). An entry is in exactly one.
public enum BrowserHiddenItemList: String, Codable, Sendable {
    case user
    case agent
}

/// How much an entry hides: the one element that was picked, or every
/// element like it.
public enum BrowserHiddenItemScope: String, Codable, Sendable {
    case thisItem
    case allLikeIt
}

/// One item hidden on a site: a CSS selector, the site pattern it applies on
/// (`PrivacySitePattern`'s rules), and the label the lists show it by.
/// `id` is nil until a store's `add(_:)` assigns one.
public struct BrowserHiddenItem: Codable, Hashable, Identifiable, Sendable {
    public var id: Int64?
    public var list: BrowserHiddenItemList
    public var site: String
    public var selector: String
    public var scope: BrowserHiddenItemScope
    public var label: String
    public var enabled: Bool
    public var created: Date

    public init(
        id: Int64? = nil,
        list: BrowserHiddenItemList,
        site: String,
        selector: String,
        scope: BrowserHiddenItemScope,
        label: String,
        enabled: Bool = true,
        created: Date = Date()
    ) {
        self.id = id
        self.list = list
        self.site = site
        self.selector = selector
        self.scope = scope
        self.label = label
        self.enabled = enabled
        self.created = created
    }

    /// An entry picked on `pageURL`'s page, its site defaulting to that
    /// page's host and every path under it, or `*` for a page with no host
    /// (`PrivacySitePattern.defaultPattern(for:)`).
    public init(
        list: BrowserHiddenItemList,
        pageURL: URL?,
        selector: String,
        scope: BrowserHiddenItemScope,
        label: String,
        enabled: Bool = true,
        created: Date = Date()
    ) {
        self.init(
            list: list, site: PrivacySitePattern.defaultPattern(for: pageURL), selector: selector,
            scope: scope, label: label, enabled: enabled, created: created)
    }
}
#endif
