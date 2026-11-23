#if canImport(AgenticDeveloperHubSDKCore)
//
//  SafariExtensionRecord.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Which sites an extension may read and change, as Chrome's details page
/// offers it. Its title is the macOS tier's (`SafariExtensionSettings.swift`).
public enum SafariExtensionSiteAccess: String, Codable, CaseIterable, Sendable {
    /// Only the page in front, and only once the person clicks its button.
    case onClick
    /// The sites the person listed.
    case specificSites
    /// Every site the extension asks for.
    case allSites
}

/// What a Safari pane's profile remembers about one installed extension,
/// beside the unpacked files: whether it is on, and what the person granted
/// or refused it. WebKit keeps neither across launches on its own.
///
/// Kept by a `SafariExtensionCatalog`, one list per `SafariExtensionScope`.
public struct SafariExtensionRecord: Codable, Equatable, Sendable {
    /// The Chrome Web Store ID, or a copied Safari extension's app extension
    /// bundle identifier; also the extension's folder and its
    /// `chrome.runtime.id`.
    public var id: String
    public var isEnabled: Bool
    public var isFromWebStore: Bool
    /// `WKWebExtension.Permission` raw values.
    public var grantedPermissions: [String]
    public var deniedPermissions: [String]
    /// Match pattern strings (`*://*.example.com/*`).
    public var grantedOrigins: [String]
    public var deniedOrigins: [String]
    /// Where a copied Safari extension came from; nil for a Chrome Web Store
    /// one. Absent from records written before it existed, which decode as
    /// nil.
    public var appSource: AppSource?
    /// Which sites it may read and change; nil (records written before it
    /// existed) is every site it asks for.
    public var siteAccess: SafariExtensionSiteAccess?
    /// The sites `.specificSites` allows, as match patterns.
    public var sites: [String]?
    /// May read `file://` pages; nil is no.
    public var allowsFileAccess: Bool?
    /// Runs in private browsing panes; nil is no.
    public var allowsPrivateBrowsing: Bool?
    /// Its button is on the toolbar rather than in the extensions menu; nil
    /// is yes.
    public var isPinned: Bool?

    /// The site access in force, with nil's meaning applied.
    public var effectiveSiteAccess: SafariExtensionSiteAccess { siteAccess ?? .allSites }

    /// The Safari extension a record's files were copied from, as it was
    /// when they were copied. Made from a `SafariAppExtension` in the macOS
    /// tier.
    public struct AppSource: Codable, Equatable, Sendable {
        /// The `.appex` bundle's path.
        public var appexPath: String
        /// The version copied. A different one installed means copy again.
        public var version: String
        public var appName: String

        public init(appexPath: String, version: String, appName: String) {
            self.appexPath = appexPath
            self.version = version
            self.appName = appName
        }
    }

    public init(
        id: String, isEnabled: Bool = true, isFromWebStore: Bool,
        grantedPermissions: [String] = [], deniedPermissions: [String] = [],
        grantedOrigins: [String] = [], deniedOrigins: [String] = [],
        appSource: AppSource? = nil
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.isFromWebStore = isFromWebStore
        self.grantedPermissions = grantedPermissions
        self.deniedPermissions = deniedPermissions
        self.grantedOrigins = grantedOrigins
        self.deniedOrigins = deniedOrigins
        self.appSource = appSource
    }
}
#endif
