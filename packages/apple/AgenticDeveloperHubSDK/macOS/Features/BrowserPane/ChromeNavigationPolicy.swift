//
//  ChromeNavigationPolicy.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Where a Chrome pane's page may not go.
///
/// Chrome's own settings pages would change things the Kitchen manages in
/// Settings > Web Browser, behind its back, so they are refused in every
/// pane. So are Chrome's history, downloads and password pages: the Kitchen
/// keeps its own history and downloads, and Chrome's password manager is
/// already hidden from its menu. A private pane has no extensions (its profile is in memory and
/// keeps nothing), so the Web Store and the extensions page are refused
/// there too. Engine-free and pure, so it is tested without CEF.
public enum ChromeNavigationPolicy {
    static let settingsRefusal = "Chrome settings are managed in Settings > Web Browser."
    static let kitchenPageRefusal = "This Chrome page is not available in the Kitchen."
    static let privateExtensionsRefusal = "Extensions are not available in private panes."

    /// Chrome pages whose job the Kitchen does itself, refused in every pane.
    static let kitchenOwnedHosts: Set<String> = ["history", "downloads", "password-manager", "passwords"]

    /// The domain of `refusalError`, by which a pane tells a refusal from a
    /// failed load.
    public static let errorDomain = "ChromeNavigationPolicy"

    /// A refusal as the engine reports it: the sentence is the description.
    public static func refusalError(_ sentence: String, address: String) -> NSError {
        var info: [String: Any] = [NSLocalizedDescriptionKey: sentence]
        info[NSURLErrorFailingURLErrorKey] = URL(string: address)
        return NSError(domain: errorDomain, code: 1, userInfo: info)
    }

    /// The sentence to show instead of loading `url`, or `nil` to load it.
    public static func refusal(for url: URL, isPrivate: Bool) -> String? {
        let scheme = url.scheme?.lowercased()
        let host = url.host?.lowercased()
        if scheme == "chrome", host == "settings" { return settingsRefusal }
        if scheme == "chrome", let host, kitchenOwnedHosts.contains(host) { return kitchenPageRefusal }
        guard isPrivate else { return nil }
        if scheme == "chrome", host == "extensions" { return privateExtensionsRefusal }
        if isWebStore(scheme: scheme, host: host, path: url.path) { return privateExtensionsRefusal }
        return nil
    }

    private static func isWebStore(scheme: String?, host: String?, path: String) -> Bool {
        guard scheme == "https" || scheme == "http" else { return false }
        if host == "chromewebstore.google.com" { return true }
        guard host == "chrome.google.com" else { return false }
        let lowered = path.lowercased()
        return lowered == "/webstore" || lowered.hasPrefix("/webstore/")
    }
}
