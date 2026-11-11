//
//  SafariExtensionLibrary.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import AgenticDeveloperHubSDKDatabase

/// What a Safari pane's profile remembers about one installed extension,
/// beside the unpacked files: whether it is on, and what the person granted
/// or refused it. WebKit keeps neither across launches on its own.
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

    /// The Safari extension (`SafariAppExtension`) a record's files were
    /// copied from, as it was when they were copied.
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

        public init(_ source: SafariAppExtension) {
            self.init(appexPath: source.appexURL.path, version: source.version, appName: source.appName)
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

/// One profile's extensions on disk:
///
///     <root>/extensions.json        the records, in install order
///     <root>/Extensions/<id>/       each extension, unpacked
///     <root>/Staging/<id>/          a download or copy awaiting the person's answer
///
/// The root is per profile (`global`, or a jar's UUID), so a jar's panes see
/// only what was installed into that jar.
public struct SafariExtensionLibrary: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    /// The profile's folder under `home`'s app storage.
    public static func root(inHome home: URL, profile: BrowserExtensionProfile) -> URL {
        let name = switch profile {
        case .global: "global"
        case .jar(let id): id.uuidString
        }
        return AppStorageLocation.directory(inHome: home)
            .appendingPathComponent("SafariExtensions", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
    }

    var recordsFile: URL { root.appendingPathComponent("extensions.json") }

    /// Where `id`'s files are unpacked.
    public func directory(of id: String) -> URL {
        root.appendingPathComponent("Extensions", isDirectory: true).appendingPathComponent(id, isDirectory: true)
    }

    /// The records, or none when nothing was installed yet. A file that does
    /// not decode is reported rather than taken as empty, so it is never
    /// overwritten by the next save.
    public func records() throws -> [SafariExtensionRecord] {
        guard FileManager.default.fileExists(atPath: recordsFile.path) else { return [] }
        return try JSONDecoder().decode([SafariExtensionRecord].self, from: Data(contentsOf: recordsFile))
    }

    public func save(_ records: [SafariExtensionRecord]) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(records).write(to: recordsFile, options: .atomic)
    }

    /// Where `id` waits between download and the person's answer.
    func stagingDirectory(of id: String) -> URL {
        root.appendingPathComponent("Staging", isDirectory: true).appendingPathComponent(id, isDirectory: true)
    }

    /// Unpacks `crx` into `id`'s staging folder, replacing an earlier
    /// staging. The zip goes through `ditto`, the system's own unzip, and
    /// the folder is kept only once it holds a manifest. The installed copy
    /// is not touched until `commitStaged`, so a download the person
    /// declines, or a package that fails, leaves it as it was.
    public func stage(_ crx: Data, as id: String) throws -> URL {
        let zip = try WebStoreExtension.zipPayload(ofCRX: crx)
        let fileManager = FileManager.default
        let scratch = fileManager.temporaryDirectory.appendingPathComponent("SafariExtension-\(UUID().uuidString)")
        try fileManager.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: scratch) }
        let zipFile = scratch.appendingPathComponent("extension.zip")
        let unpacked = scratch.appendingPathComponent("unpacked", isDirectory: true)
        try zip.write(to: zipFile)

        let ditto = Process()
        ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        ditto.arguments = ["-x", "-k", zipFile.path, unpacked.path]
        let errors = Pipe()
        ditto.standardError = errors
        try ditto.run()
        ditto.waitUntilExit()
        guard ditto.terminationStatus == 0 else {
            let detail = String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw WebStoreExtension.Failure.unpack(detail.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard fileManager.fileExists(atPath: unpacked.appendingPathComponent("manifest.json").path) else {
            throw WebStoreExtension.Failure.noManifest
        }
        // Chrome's own signature folder means nothing to WebKit.
        try? fileManager.removeItem(at: unpacked.appendingPathComponent("_metadata"))

        let staged = stagingDirectory(of: id)
        try Self.move(unpacked, replacing: staged)
        return staged
    }

    /// Copies the unpacked extension at `folder` (a Safari extension's
    /// `Contents/Resources`) into `id`'s staging folder, replacing an earlier
    /// staging. As with a download, the installed copy is not touched until
    /// `commitStaged`.
    public func stage(copyOf folder: URL, as id: String) throws -> URL {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: folder.appendingPathComponent("manifest.json").path) else {
            throw WebStoreExtension.Failure.noManifest
        }
        let scratch = fileManager.temporaryDirectory.appendingPathComponent("SafariExtension-\(UUID().uuidString)")
        try fileManager.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: scratch) }
        let copied = scratch.appendingPathComponent("copied", isDirectory: true)
        try fileManager.copyItem(at: folder, to: copied)
        let staged = stagingDirectory(of: id)
        try Self.move(copied, replacing: staged)
        return staged
    }

    /// Moves `id`'s staged files into place, replacing the installed copy.
    @discardableResult
    public func commitStaged(_ id: String) throws -> URL {
        let destination = directory(of: id)
        try Self.move(stagingDirectory(of: id), replacing: destination)
        return destination
    }

    /// Throws away `id`'s staged files.
    public func discardStaged(_ id: String) {
        try? FileManager.default.removeItem(at: stagingDirectory(of: id))
    }

    private static func move(_ source: URL, replacing destination: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destination.path) { try fileManager.removeItem(at: destination) }
        try fileManager.moveItem(at: source, to: destination)
    }

    /// Deletes `id`'s files.
    public func removeFiles(of id: String) throws {
        let directory = directory(of: id)
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    /// Downloads `id`'s package from the Chrome Web Store.
    public static func download(id: String, session: URLSession = .shared) async throws -> Data {
        let (data, response) = try await session.data(from: WebStoreExtension.downloadURL(id: id))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WebStoreExtension.Failure.download("HTTP \(http.statusCode)")
        }
        guard !data.isEmpty else { throw WebStoreExtension.Failure.download("the store sent nothing") }
        return data
    }

    /// The version the Chrome Web Store offers `id` at, when it is newer
    /// than `installed`; nil when there is nothing newer.
    public static func offeredUpdate(
        id: String, installed: String, session: URLSession = .shared
    ) async throws -> String? {
        let (data, response) = try await session.data(
            from: WebStoreExtension.updateCheckURL(id: id, version: installed))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WebStoreExtension.Failure.download("HTTP \(http.statusCode)")
        }
        guard let offered = WebStoreExtension.offeredVersion(inUpdateResponse: data),
              WebStoreExtension.isNewer(offered, than: installed) else { return nil }
        return offered
    }
}
