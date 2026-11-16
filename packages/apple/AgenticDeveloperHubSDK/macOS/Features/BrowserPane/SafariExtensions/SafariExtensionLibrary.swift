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

    /// The first symbolic link anywhere under `folder`, as a path relative to
    /// it; nil when there is none. A link is not followed, so one pointing
    /// out of the folder (at the home folder, say) is reported, not walked.
    ///
    /// It fails closed: a folder that is itself a link, or one that cannot be
    /// read, is reported as `"."`, and an item whose type cannot be read is
    /// reported as if it were a link, since a check that cannot look must not
    /// say there is nothing there.
    public static func symbolicLink(in folder: URL) -> String? {
        let fileManager = FileManager.default
        // `attributesOfItem` does not follow a link, so this is an lstat.
        guard let rootType = (try? fileManager.attributesOfItem(atPath: folder.path))?[.type] as? FileAttributeType,
              rootType == .typeDirectory else { return "." }
        var failed: String?
        guard let walk = fileManager.enumerator(
            at: folder, includingPropertiesForKeys: [.isSymbolicLinkKey], options: [],
            errorHandler: { url, _ in
                failed = relativePath(of: url, in: folder)
                return false
            }) else { return "." }
        for case let url as URL in walk {
            let relative = relativePath(of: url, in: folder)
            guard let isLink = (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink else {
                return relative
            }
            if isLink { return relative }
        }
        return failed
    }

    /// `url`'s path below `folder`, or its last component when it is not
    /// spelled under it.
    private static func relativePath(of url: URL, in folder: URL) -> String {
        let base = folder.path.hasSuffix("/") ? folder.path : folder.path + "/"
        return url.path.hasPrefix(base) ? String(url.path.dropFirst(base.count)) : url.lastPathComponent
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
        let data = try await download(from: WebStoreExtension.downloadURL(id: id), session: session)
        guard !data.isEmpty else { throw WebStoreExtension.Failure.download("the store sent nothing") }
        return data
    }

    /// The most an extension download may be: a package larger than this is
    /// refused rather than read into memory.
    public static let maximumDownloadSize = 128 * 1024 * 1024

    /// The body at `url`, read no further than `limit` bytes: a larger body,
    /// announced or not, throws `Failure.download` and is not read on. A
    /// non-2xx status throws too. Runs off the main actor (nonisolated).
    public static func download(
        from url: URL, limit: Int = maximumDownloadSize, session: URLSession = .shared
    ) async throws -> Data {
        let (bytes, response) = try await session.bytes(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            bytes.task.cancel()
            throw WebStoreExtension.Failure.download("HTTP \(http.statusCode)")
        }
        let tooLarge = WebStoreExtension.Failure.download(
            "it is larger than \(ByteCountFormatter.string(fromByteCount: Int64(limit), countStyle: .file))")
        if response.expectedContentLength > Int64(limit) {
            bytes.task.cancel()
            throw tooLarge
        }
        var data = Data()
        if response.expectedContentLength > 0 { data.reserveCapacity(Int(response.expectedContentLength)) }
        for try await byte in bytes {
            guard data.count < limit else {
                bytes.task.cancel()
                throw tooLarge
            }
            data.append(byte)
        }
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
