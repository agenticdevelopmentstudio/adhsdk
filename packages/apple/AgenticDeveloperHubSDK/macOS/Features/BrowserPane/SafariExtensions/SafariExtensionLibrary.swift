//
//  SafariExtensionLibrary.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import AgenticDeveloperHubSDKDatabase

extension SafariExtensionRecord.AppSource {
    /// The record of copying `source` as it is now.
    public init(_ source: SafariAppExtension) {
        self.init(appexPath: source.appexURL.path, version: source.version, appName: source.appName)
    }
}

extension BrowserExtensionProfile {
    /// The catalog scope a Safari pane's profile keeps its extensions in.
    public var catalogScope: SafariExtensionScope {
        switch self {
        case .global: .global
        case .jar(let id): .jar(id)
        }
    }
}

/// One profile's extensions: the installed ones and their records, kept by a
/// `SafariExtensionCatalog` under the profile's scope, and the downloads and
/// copies awaiting the person's answer, staged here first:
///
///     <stagingRoot>/<id>/        a download or copy awaiting the person's answer
///
/// The staging root is the app's to choose: beside the installed files for a
/// local catalog (`<root>/<scope>/Staging`, where it always was), and under
/// the system's temporary folder for the daemon's, which moves an install
/// into its own directory itself. A jar's panes see only what was installed
/// into that jar.
public struct SafariExtensionLibrary: Sendable {
    public let catalog: any SafariExtensionCatalog
    public let scope: SafariExtensionScope
    /// Where downloads and copies wait, one folder per id.
    public let stagingRoot: URL

    /// A library over `catalog`'s `scope`, staging under `stagingRoot`, or
    /// beside the installed files when it is nil.
    public init(catalog: any SafariExtensionCatalog, scope: SafariExtensionScope, stagingRoot: URL? = nil) {
        self.catalog = catalog
        self.scope = scope
        self.stagingRoot = stagingRoot ?? Self.localStagingRoot(of: catalog, scope: scope)
    }

    /// `<root>/<scope>/Staging`, the staging folder of a catalog in the app's
    /// own storage.
    public static func localStagingRoot(of catalog: any SafariExtensionCatalog, scope: SafariExtensionScope) -> URL {
        catalog.directory(of: scope).appendingPathComponent("Staging", isDirectory: true)
    }

    /// A staging root under the system's temporary folder, for a catalog the
    /// app does not own (adhd's): one per scope, so two profiles never stage
    /// over each other.
    public static func temporaryStagingRoot(scope: SafariExtensionScope) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("SafariExtensionStaging", isDirectory: true)
            .appendingPathComponent(scope.folderName, isDirectory: true)
    }

    /// Where `id`'s files are unpacked.
    public func directory(of id: String) -> URL {
        catalog.directory(of: id, scope: scope)
    }

    /// The records, or none when nothing was installed yet. Records that do
    /// not decode are reported rather than taken as empty, so they are never
    /// overwritten by the next save.
    public func records() async throws -> [SafariExtensionRecord] {
        try await catalog.records(scope: scope)
    }

    public func save(_ records: [SafariExtensionRecord]) async throws {
        try await catalog.save(records, scope: scope)
    }

    /// Where `id` waits between download and the person's answer.
    func stagingDirectory(of id: String) -> URL {
        stagingRoot.appendingPathComponent(id, isDirectory: true)
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

    /// Hands `id`'s staged files to the catalog, which moves them into
    /// place, replacing the installed copy.
    @discardableResult
    public func commitStaged(_ id: String) async throws -> URL {
        try await catalog.install(stagedAt: stagingDirectory(of: id), scope: scope)
    }

    /// Throws away `id`'s staged files.
    public func discardStaged(_ id: String) {
        try? FileManager.default.removeItem(at: stagingDirectory(of: id))
    }

    private static func move(_ source: URL, replacing destination: URL) throws {
        try LocalSafariExtensionCatalog.move(source, replacing: destination)
    }

    /// Deletes `id`'s files and record.
    public func remove(_ id: String) async throws {
        try await catalog.remove(id: id, scope: scope)
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
