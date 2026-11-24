//
//  SafariExtensionSettings.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Which sites an extension may read and change, as Chrome's details page
/// offers it.
public enum SafariExtensionSiteAccess: String, Codable, CaseIterable, Sendable {
    /// Only the page in front, and only once the person clicks its button.
    case onClick
    /// The sites the person listed.
    case specificSites
    /// Every site the extension asks for.
    case allSites

    public var title: String {
        switch self {
        case .onClick: "On click"
        case .specificSites: "On specific sites"
        case .allSites: "On all sites"
        }
    }
}

/// The rules behind an extension's details page, kept apart from WebKit so
/// they can be tested: which sites a mode grants, what a typed site means,
/// whether file access is worth offering, and how a permission reads.
public enum SafariExtensionSettings {

    /// The match pattern that stands for every `file://` page.
    public static let fileURLPattern = "file:///*"

    /// The match patterns to grant for `mode`: everything requested for all
    /// sites, the listed sites for specific ones, nothing for on-click (the
    /// click grants the page in front).
    public static func grantedOrigins(
        for mode: SafariExtensionSiteAccess, requested: [String], sites: [String]
    ) -> [String] {
        switch mode {
        case .allSites: Array(Set(requested)).sorted()
        case .specificSites: Array(Set(sites)).sorted()
        case .onClick: []
        }
    }

    /// The match pattern a typed site means, or nil for text that names no
    /// site. A host (`example.com`, `*.example.com`, a link to a page on one)
    /// becomes every page on it over any scheme; a match pattern is kept as
    /// it is.
    public static func sitePattern(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else { return nil }
        if trimmed == "<all_urls>" { return trimmed }
        var host = trimmed
        if let range = trimmed.range(of: "://") {
            let scheme = String(trimmed[..<range.lowerBound]).lowercased()
            let rest = trimmed[range.upperBound...]
            let validSchemes: Set<String> = ["*", "http", "https", "ws", "wss", "file", "ftp"]
            guard validSchemes.contains(scheme) else { return nil }
            let slash = rest.firstIndex(of: "/")
            var patternHost = String(slash.map { rest[..<$0] } ?? rest)
            // A port names no site of its own, and a match pattern has none.
            if let colon = patternHost.firstIndex(of: ":") { patternHost = String(patternHost[..<colon]) }
            patternHost = patternHost.lowercased()
            let path = slash.map { String(rest[$0...]) } ?? ""
            if scheme == "file" { return path.isEmpty ? nil : "file://" + path }
            guard isHost(patternHost) else { return nil }
            // A pattern already (a `*` anywhere): keep it, with a path.
            if trimmed.contains("*") { return "\(scheme)://\(patternHost)" + (path.isEmpty ? "/*" : path) }
            host = patternHost
        } else if let slash = trimmed.firstIndex(of: "/") {
            host = String(trimmed[..<slash])
        }
        // A port names no site of its own.
        if let colon = host.firstIndex(of: ":") { host = String(host[..<colon]) }
        host = host.lowercased()
        guard isHost(host) else { return nil }
        return "*://\(host)/*"
    }

    /// Each line or comma-separated item of `text` as a pattern, in order,
    /// once each; `invalid` is the items that named no site.
    public static func sitePatterns(from text: String) -> (patterns: [String], invalid: [String]) {
        var patterns: [String] = []
        var invalid: [String] = []
        let items = text.split(whereSeparator: { $0.isNewline || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        for item in items {
            if let pattern = sitePattern(from: item) {
                if !patterns.contains(pattern) { patterns.append(pattern) }
            } else {
                invalid.append(item)
            }
        }
        return (patterns, invalid)
    }

    /// Whether any of `requested` could reach a `file://` page, which is
    /// when the file access switch means anything.
    public static func offersFileAccess(requested: [String]) -> Bool {
        requested.contains { $0 == "<all_urls>" || $0.lowercased().hasPrefix("file://") }
    }

    /// A Chrome permission as a person reads it; an unknown one as itself.
    public static func describe(permission: String) -> String {
        permissionDescriptions[permission] ?? permission
    }

    private static let permissionDescriptions: [String: String] = [
        "activeTab": "The page in front, when you click it",
        "alarms": "Scheduled tasks",
        "clipboardRead": "Read the clipboard",
        "clipboardWrite": "Write to the clipboard",
        "contextMenus": "Items in the right-click menu",
        "cookies": "Read and change cookies",
        "declarativeNetRequest": "Block or change network requests",
        "declarativeNetRequestFeedback": "See which requests it blocked or changed",
        "declarativeNetRequestWithHostAccess": "Block or change network requests on the sites it can reach",
        "menus": "Items in the right-click menu",
        "nativeMessaging": "Talk to apps on this Mac",
        "notifications": "Show notifications",
        "scripting": "Run scripts in pages",
        "storage": "Store its own data",
        "tabs": "See your tabs' addresses and titles",
        "unlimitedStorage": "Store unlimited data",
        "webNavigation": "See where your tabs go",
        "webRequest": "See network requests",
        "sidePanel": "A side panel",
        "offscreen": "Hidden pages of its own",
        "downloads": "Manage downloads",
        "history": "Read and change your history",
        "bookmarks": "Read and change your bookmarks",
        "identity": "Sign you in to sites",
        "idle": "Know when the Mac is idle",
        "management": "Manage other extensions",
        "privacy": "Change privacy settings",
        "proxy": "Change proxy settings",
        "sessions": "See recently closed tabs",
        "topSites": "See your most visited sites",
        "tts": "Speak text aloud",
        "geolocation": "Your location"
    ]

    /// A pattern's sites as a person reads them: `*://*.example.com/*` as
    /// `*.example.com`, every site as "All sites".
    public static func describe(origin pattern: String) -> String {
        if pattern == "<all_urls>" { return "All sites" }
        guard let range = pattern.range(of: "://") else { return pattern }
        let scheme = pattern[..<range.lowerBound]
        let rest = pattern[range.upperBound...]
        if scheme == "file" { return "Files on this Mac" }
        let host = rest.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            .first.map(String.init) ?? ""
        if host == "*" { return "All sites" }
        return host
    }

    private static func isHost(_ host: String) -> Bool {
        if host == "*" { return true }
        var body = Substring(host)
        if body.hasPrefix("*.") { body = body.dropFirst(2) }
        guard !body.isEmpty, !body.hasPrefix("."), !body.hasSuffix(".") else { return false }
        return body.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." }
    }
}
