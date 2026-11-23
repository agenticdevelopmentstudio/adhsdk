#if canImport(AgenticDeveloperHubSDKCore)
//
//  LocalSafariExtensionCatalog.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// The Safari extension catalog as plain files under `root`
/// (`SafariExtensionCatalog`'s layout): what an app keeps in its own storage,
/// and what adhd keeps in its data directory and serves.
///
/// One lock orders every read and write, so a save cannot interleave with an
/// install, and the work runs on the caller's task, off the main actor.
public final class LocalSafariExtensionCatalog: SafariExtensionCatalog, @unchecked Sendable {
    public let root: URL
    private let lock = NSLock()

    public init(root: URL) {
        self.root = root
    }

    /// The catalog's folder under `home`'s app storage.
    public static func defaultRoot(inHome home: URL) -> URL {
        AppStorageLocation.directory(inHome: home).appendingPathComponent("SafariExtensions", isDirectory: true)
    }

    /// `scope`'s records file.
    public func recordsFile(of scope: SafariExtensionScope) -> URL {
        directory(of: scope).appendingPathComponent("extensions.json")
    }

    public func records(scope: SafariExtensionScope) async throws -> [SafariExtensionRecord] {
        try locked { try readRecords(scope) }
    }

    public func save(_ records: [SafariExtensionRecord], scope: SafariExtensionScope) async throws {
        try locked { try writeRecords(records, scope) }
        SafariExtensionCatalogChange.post(scope, from: self)
    }

    @discardableResult
    public func install(stagedAt staged: URL, scope: SafariExtensionScope) async throws -> URL {
        let id = staged.lastPathComponent
        guard !id.isEmpty, id != ".", id != "..", !id.contains("/") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: staged.path])
        }
        let destination = directory(of: id, scope: scope)
        try locked { try Self.move(staged, replacing: destination) }
        SafariExtensionCatalogChange.post(scope, from: self)
        return destination
    }

    public func remove(id: String, scope: SafariExtensionScope) async throws {
        try locked {
            let files = directory(of: id, scope: scope)
            if FileManager.default.fileExists(atPath: files.path) {
                try FileManager.default.removeItem(at: files)
            }
            let records = try readRecords(scope)
            let kept = records.filter { $0.id != id }
            if kept.count != records.count { try writeRecords(kept, scope) }
        }
        SafariExtensionCatalogChange.post(scope, from: self)
    }

    // MARK: - Files

    private func locked<T>(_ work: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }

    private func readRecords(_ scope: SafariExtensionScope) throws -> [SafariExtensionRecord] {
        let file = recordsFile(of: scope)
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        return try JSONDecoder().decode([SafariExtensionRecord].self, from: Data(contentsOf: file))
    }

    private func writeRecords(_ records: [SafariExtensionRecord], _ scope: SafariExtensionScope) throws {
        try FileManager.default.createDirectory(at: directory(of: scope), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(records).write(to: recordsFile(of: scope), options: .atomic)
    }

    /// Moves `source` to `destination`, replacing what is there.
    public static func move(_ source: URL, replacing destination: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destination.path) { try fileManager.removeItem(at: destination) }
        try fileManager.moveItem(at: source, to: destination)
    }
}
#endif
