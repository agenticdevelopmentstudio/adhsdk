//
//  BrowserExtension.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// The Chrome profile a set of extensions is installed into. Extensions live
/// in a profile, and each storage jar is a profile of its own, so a pane
/// sees the extensions of its jar's profile.
public enum BrowserExtensionProfile: Hashable, Sendable {
    /// The shared profile, behind every pane on the global jar.
    case global
    /// A worktree or pane jar's profile, named by its `browser_jars` row.
    case jar(UUID)

    /// nil for a jar whose profile is kept in memory: private browsing and a
    /// jar that failed closed, which have no extensions to manage.
    public init?(_ jar: BrowserResolvedJar) {
        if jar.isEphemeral { return nil }
        if jar.jar == .global {
            self = .global
            return
        }
        guard let id = jar.jarID else { return nil }
        self = .jar(id)
    }
}

/// Why an extension could not be listed or changed.
public enum BrowserExtensionError: Error, Equatable, LocalizedError {
    /// Chrome answered with something other than its extension list.
    case unexpectedShape(String)
    /// Chrome could not be asked: it did not start, the profile does not
    /// exist, or the page refused the call.
    case unavailable(String)

    public var errorDescription: String? {
        switch self {
        case .unexpectedShape(let detail): "Chrome's extension list was not understood: \(detail)"
        case .unavailable(let detail): detail
        }
    }
}

/// One installed Chrome extension, as Chrome's extensions page lists it.
public struct BrowserExtension: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let version: String
    public let summary: String
    public let isEnabled: Bool
    /// Off because an update asks for permissions the person has not
    /// accepted. Only Chrome's own prompt may turn it back on, shown where
    /// the person can read it: Chrome's extensions page in a pane.
    public let needsPermissionReview: Bool
    /// Installed from the Chrome Web Store, so Chrome keeps it updated.
    public let isFromWebStore: Bool
    public let iconPNG: Data?
    public let optionsURL: URL?
    /// Where it came from, when that is neither the Chrome Web Store nor
    /// unknown: a Safari extension copied from an app names the app.
    public let sourceName: String?

    public init(
        id: String, name: String, version: String, summary: String, isEnabled: Bool,
        needsPermissionReview: Bool = false, isFromWebStore: Bool, iconPNG: Data?, optionsURL: URL?,
        sourceName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.summary = summary
        self.isEnabled = isEnabled
        self.needsPermissionReview = needsPermissionReview
        self.isFromWebStore = isFromWebStore
        self.iconPNG = iconPNG
        self.optionsURL = optionsURL
        self.sourceName = sourceName
    }

    /// `chrome.developerPrivate.getExtensionsInfo`'s array, as Chrome sends
    /// it. Chrome encodes an extension's own icon into `iconUrl` as a `data:`
    /// URL; the generic icon is a `chrome://` address, which gives no icon.
    /// `disabledReason` is `chrome.management`'s, added to each entry by the
    /// caller.
    public static func decodeList(_ json: Any) throws -> [BrowserExtension] {
        guard let items = json as? [Any] else {
            throw BrowserExtensionError.unexpectedShape("expected an array, got \(type(of: json))")
        }
        return try items.enumerated().map { index, item in
            guard let fields = item as? [String: Any] else {
                throw BrowserExtensionError.unexpectedShape("element \(index) is not an object")
            }
            return try BrowserExtension(fields: fields, index: index)
        }
    }

    private init(fields: [String: Any], index: Int) throws {
        guard let id = fields["id"] as? String, !id.isEmpty else {
            throw BrowserExtensionError.unexpectedShape("element \(index) has no id")
        }
        self.id = id
        name = fields["name"] as? String ?? id
        version = fields["version"] as? String ?? ""
        summary = fields["description"] as? String ?? ""
        isEnabled = (fields["state"] as? String) == "ENABLED"
        needsPermissionReview = !isEnabled && (fields["disabledReason"] as? String) == "permissions_increase"
        isFromWebStore = (fields["location"] as? String) == "FROM_STORE"
        optionsURL = ((fields["optionsPage"] as? [String: Any])?["url"] as? String).flatMap(URL.init(string:))
        iconPNG = (fields["iconUrl"] as? String).flatMap(Self.dataURLBytes)
        sourceName = nil
    }

    /// Chrome's extensions page for this extension, where its own prompt
    /// for new permissions is shown to the person.
    public var reviewURL: URL? {
        var components = URLComponents()
        components.scheme = "chrome"
        components.host = "extensions"
        components.queryItems = [URLQueryItem(name: "id", value: id)]
        return components.url
    }

    /// Why a switch-on was refused: what turns it on instead.
    public static let permissionReviewRefusal =
        "This extension asks for new permissions. Review them on Chrome's extensions page to turn it on."

    /// The bytes of a base64 `data:` URL, or nil for anything else.
    private static func dataURLBytes(_ address: String) -> Data? {
        guard address.hasPrefix("data:"),
              let comma = address.firstIndex(of: ","),
              address[..<comma].hasSuffix(";base64")
        else { return nil }
        return Data(base64Encoded: String(address[address.index(after: comma)...]))
    }
}
