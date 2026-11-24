//
//  SafariAppExtension.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// A Safari web extension installed on this Mac: the app extension (`.appex`)
/// a Mac App Store app carries for Safari, as the system's plug-in registry
/// lists it. A Safari pane copies the web extension inside it (the
/// `Contents/Resources` folder, which holds its `manifest.json`) into its
/// own library, and copies it again when the app updates.
///
/// Only the rules live here: which extensions the registry's answer names,
/// and where their pieces are. Asking the registry is `installed()`.
public struct SafariAppExtension: Equatable, Sendable {
    /// The app extension's bundle identifier, which is also the record's ID
    /// and the copy's folder name.
    public let bundleID: String
    /// The version the registry reports, compared with the copy's to decide
    /// whether to copy again.
    public let version: String
    /// The `.appex` bundle.
    public let appexURL: URL
    /// The extension's name: the app extension's display name, else its
    /// bundle identifier.
    public var name: String
    /// The name of the app that carries it.
    public var appName: String

    public init(bundleID: String, version: String, appexURL: URL, name: String? = nil, appName: String? = nil) {
        self.bundleID = bundleID
        self.version = version
        self.appexURL = appexURL
        self.name = name ?? bundleID
        self.appName = appName ?? Self.appURL(containing: appexURL)?.deletingPathExtension().lastPathComponent
            ?? appexURL.deletingPathExtension().lastPathComponent
    }

    /// The extension point Safari's web extensions are registered under.
    public static let extensionPoint = "com.apple.Safari.web-extension"

    /// The Mac App Store's Safari Extensions page.
    public static let storeURL = URL(string: "itms-apps://safariExtensions")!

    /// The web extension's own folder inside the app extension.
    public var resourcesURL: URL {
        appexURL.appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
    }

    /// The app the app extension at `appex` is inside: its nearest enclosing
    /// `.app` bundle, or nil for one that is in none.
    public static func appURL(containing appex: URL) -> URL? {
        var url = appex.deletingLastPathComponent()
        while url.pathComponents.count > 1 {
            if url.pathExtension == "app" { return url }
            url = url.deletingLastPathComponent()
        }
        return nil
    }

    /// The extensions `pluginkit -m -v -p <extensionPoint>` lists, one per
    /// bundle identifier, in the order listed. Each line it prints for a
    /// plug-in is
    ///
    ///     <flags> <bundle id>(<version>)<TAB><UUID><TAB><date><TAB><path>
    ///
    /// with the flags (`+`, `-`, `!`, `=`) present only for some plug-ins.
    /// Any other line (its closing count, a blank) is skipped, as is a
    /// plug-in whose path is not an `.appex`.
    public static func parse(pluginkitOutput output: String) -> [SafariAppExtension] {
        var seen = Set<String>()
        var found: [SafariAppExtension] = []
        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count >= 4 else { continue }
            let path = fields[fields.count - 1].trimmingCharacters(in: .whitespaces)
            guard path.hasPrefix("/"), path.hasSuffix(".appex") else { continue }
            let head = fields[0].trimmingCharacters(in: .whitespaces)
            // The flags, when present, are separated from the identifier by
            // spaces; the identifier itself has none.
            let identity = head.split(separator: " ").last.map(String.init) ?? head
            guard let open = identity.lastIndex(of: "("), identity.hasSuffix(")") else { continue }
            let bundleID = String(identity[..<open])
            let version = String(identity[identity.index(after: open)..<identity.index(before: identity.endIndex)])
            guard !bundleID.isEmpty, seen.insert(bundleID).inserted else { continue }
            found.append(SafariAppExtension(
                bundleID: bundleID, version: version, appexURL: URL(fileURLWithPath: path, isDirectory: true)))
        }
        return found
    }

    /// The Safari web extensions installed now, with their names read from
    /// their bundles; nil when the registry could not be asked, which is not
    /// the same as nothing installed.
    public static func installed() async -> [SafariAppExtension]? {
        await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
            process.arguments = ["-m", "-v", "-p", extensionPoint]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            do { try process.run() } catch { return nil }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            guard let text = String(bytes: data, encoding: .utf8) else { return nil }
            return parse(pluginkitOutput: text).map(\.named)
        }.value
    }

    /// This extension with the names its bundles give.
    private var named: SafariAppExtension {
        var copy = self
        if let name = Self.bundleName(at: appexURL) { copy.name = name }
        if let app = Self.appURL(containing: appexURL), let name = Self.bundleName(at: app) { copy.appName = name }
        return copy
    }

    private static func bundleName(at url: URL) -> String? {
        guard let info = Bundle(url: url)?.infoDictionary else { return nil }
        let name = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String)
        return name?.isEmpty == false ? name : nil
    }
}
