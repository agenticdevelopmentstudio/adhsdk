//
//  BrowserSiteData.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import WebKit

/// A browser engine other than WebKit that keeps a project jar's data in a
/// store of its own — Chromium, in `Jar-<uuid>` profiles — as the project
/// jars panel reads and clears it. The engine's framework registers one with
/// `BrowserJarEngines.register(_:)`, since this tier cannot link it
/// (`dependency-inversion`), the way it registers its jar directories with
/// the reconciler.
@MainActor
public protocol BrowserJarEngineSiteData: AnyObject {
    /// What the engine keeps for a site, as the panel's Data column shows
    /// it: `Chrome: Cookies`.
    var siteDataLabel: String { get }
    /// The sites a jar holds data for, named the way WebKit names its
    /// records (the registrable domain) so one site in both engines is one
    /// row. Empty for a jar the engine has never used.
    func sites(inJar jarID: UUID) async -> [String]
    /// Forgets what one site keeps in a jar.
    func removeSite(_ site: String, fromJar jarID: UUID) async
    /// Empties a jar of every site.
    func removeAll(fromJar jarID: UUID) async
}

/// The engines registered beside WebKit.
@MainActor
public enum BrowserJarEngines {
    public private(set) static var siteData: [any BrowserJarEngineSiteData] = []

    /// Adds an engine to every later read of the project jars panel, once.
    public static func register(_ engine: any BrowserJarEngineSiteData) {
        guard !siteData.contains(where: { $0 === engine }) else { return }
        siteData.append(engine)
    }
}

/// What WebKit keeps for the sites the browser has visited — cookies, local
/// storage, caches — read and cleared through the one data store every
/// persistent browser pane shares.
///
/// A thin, async face over `WKWebsiteDataStore` so the settings panel and the
/// pane name the same store and the same type labels (`dry`), and so a test
/// can hand in a non-persistent store instead of the user's.
@MainActor
public final class BrowserSiteData {

    public let dataStore: WKWebsiteDataStore

    public init(dataStore: WKWebsiteDataStore = .default()) {
        self.dataStore = dataStore
    }

    /// Every kind of data WebKit can account for.
    public static var allTypes: Set<String> { WKWebsiteDataStore.allWebsiteDataTypes() }

    /// One row per site, the way WebKit groups them.
    public func records() async -> [WKWebsiteDataRecord] {
        await dataStore.dataRecords(ofTypes: Self.allTypes)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    public func remove(_ records: [WKWebsiteDataRecord]) async {
        await dataStore.removeData(ofTypes: Self.allTypes, for: records)
    }

    public func removeAll() async {
        await dataStore.removeData(ofTypes: Self.allTypes, modifiedSince: .distantPast)
    }

    /// Whether sites may set cookies at all. WebKit has exactly this switch
    /// and no finer one — there is no first-party-only policy to offer.
    public func setAcceptsCookies(_ accepts: Bool) async {
        await dataStore.httpCookieStore.setCookiePolicy(accepts ? .allow : .disallow)
    }

    /// A reader's name for a WebKit data type.
    public static func label(for dataType: String) -> String {
        switch dataType {
        case WKWebsiteDataTypeCookies: "Cookies"
        case WKWebsiteDataTypeLocalStorage: "Local storage"
        case WKWebsiteDataTypeSessionStorage: "Session storage"
        case WKWebsiteDataTypeIndexedDBDatabases: "IndexedDB"
        case WKWebsiteDataTypeWebSQLDatabases: "WebSQL"
        case WKWebsiteDataTypeDiskCache: "Disk cache"
        case WKWebsiteDataTypeMemoryCache: "Memory cache"
        case WKWebsiteDataTypeOfflineWebApplicationCache: "Offline cache"
        case WKWebsiteDataTypeFetchCache: "Fetch cache"
        case WKWebsiteDataTypeServiceWorkerRegistrations: "Service workers"
        case WKWebsiteDataTypeFileSystem: "File system"
        case WKWebsiteDataTypeSearchFieldRecentSearches: "Recent searches"
        case WKWebsiteDataTypeMediaKeys: "Media keys"
        case WKWebsiteDataTypeHashSalt: "Hash salt"
        default: dataType.replacingOccurrences(of: "WKWebsiteDataType", with: "")
        }
    }

    /// The labels for a record's data, in a stable order.
    public static func labels(for record: WKWebsiteDataRecord) -> String {
        record.dataTypes.map(label(for:)).sorted().joined(separator: ", ")
    }
}
