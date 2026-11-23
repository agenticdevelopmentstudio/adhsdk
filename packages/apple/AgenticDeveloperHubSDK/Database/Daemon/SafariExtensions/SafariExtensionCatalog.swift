#if canImport(AgenticDeveloperHubSDKCore)
//
//  SafariExtensionCatalog.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Whose extensions: the global profile's, or one cookie jar's. A jar's
/// panes see only what was installed into that jar.
public enum SafariExtensionScope: Hashable, Sendable {
    case global
    case jar(UUID)

    /// The scope's folder under a catalog's root: `global`, or the jar's
    /// UUID.
    public var folderName: String {
        switch self {
        case .global: "global"
        case .jar(let id): id.uuidString
        }
    }

    /// The scope a folder name stands for; nil for a name that is neither.
    public init?(folderName: String) {
        if folderName == "global" {
            self = .global
        } else if let id = UUID(uuidString: folderName) {
            self = .jar(id)
        } else {
            return nil
        }
    }
}

/// The installed Safari extensions and their records, per scope, laid out
/// under `root` as
///
///     <root>/<scope>/extensions.json     the records, in install order
///     <root>/<scope>/Extensions/<id>/    each extension, unpacked
///
/// `LocalSafariExtensionCatalog` keeps it in the app's own storage; the
/// daemon's adapter in `ADHDClientMacOS` keeps it in adhd, which owns the
/// directory and moves installs into it itself. Either way an app reads the
/// unpacked files in place (`directory(of:scope:)`), because
/// `WKWebExtension` loads from a URL (`dependency-injection`).
///
/// Every method but the layout is async, because the daemon's answers are a
/// round trip. After every committed change a conformer posts
/// `Notification.Name.safariExtensionCatalogDidChange` with itself as the
/// object and the scope under `SafariExtensionCatalogChange.scopeKey`, and
/// ``changes`` yields that scope.
public protocol SafariExtensionCatalog: AnyObject, Sendable {
    /// Where the unpacked files are read.
    var root: URL { get }
    /// `scope`'s records, in install order; none when nothing was installed
    /// yet. Records that do not decode are an error, never an empty list, so
    /// the next save cannot overwrite them.
    func records(scope: SafariExtensionScope) async throws -> [SafariExtensionRecord]
    /// Replaces `scope`'s records.
    func save(_ records: [SafariExtensionRecord], scope: SafariExtensionScope) async throws
    /// Moves the unpacked extension at `staged` into `scope` as the
    /// extension named by its folder (`staged.lastPathComponent`), replacing
    /// an installed copy, and returns where it now is. The records are the
    /// caller's to save.
    @discardableResult
    func install(stagedAt staged: URL, scope: SafariExtensionScope) async throws -> URL
    /// Deletes `id`'s files and record from `scope`; other ids are left as
    /// they were. Removing one that is not there is not an error.
    func remove(id: String, scope: SafariExtensionScope) async throws
    /// The scope of each committed change, for as long as it is iterated.
    var changes: AsyncStream<SafariExtensionScope> { get }
}

extension SafariExtensionCatalog {
    /// `scope`'s folder.
    public func directory(of scope: SafariExtensionScope) -> URL {
        root.appendingPathComponent(scope.folderName, isDirectory: true)
    }

    /// Where `id`'s unpacked files are in `scope`.
    public func directory(of id: String, scope: SafariExtensionScope) -> URL {
        directory(of: scope)
            .appendingPathComponent("Extensions", isDirectory: true)
            .appendingPathComponent(id, isDirectory: true)
    }

    public var changes: AsyncStream<SafariExtensionScope> {
        SafariExtensionCatalogChange.stream(from: self)
    }
}

extension Notification.Name {
    /// Posted by every ``SafariExtensionCatalog``, with the catalog as its
    /// object and the changed scope under `SafariExtensionCatalogChange.scopeKey`,
    /// after each save, install and removal it committed.
    public static let safariExtensionCatalogDidChange = Notification.Name("SafariExtensionCatalog.didChange")
}

/// How a catalog announces a change, shared by every conformer so they
/// cannot disagree on it (`dry`).
public enum SafariExtensionCatalogChange {
    /// The `userInfo` key holding the changed `SafariExtensionScope`.
    public static let scopeKey = "scope"

    /// Posts `scope`'s change from `catalog`.
    public static func post(_ scope: SafariExtensionScope, from catalog: AnyObject) {
        NotificationCenter.default.post(
            name: .safariExtensionCatalogDidChange, object: catalog, userInfo: [scopeKey: scope])
    }

    /// One element per change `catalog` posts, in order, while iterated.
    public static func stream(from catalog: AnyObject) -> AsyncStream<SafariExtensionScope> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            let token = NotificationCenter.default.addObserver(
                forName: .safariExtensionCatalogDidChange, object: catalog, queue: nil
            ) { note in
                if let scope = note.userInfo?[scopeKey] as? SafariExtensionScope { continuation.yield(scope) }
            }
            let observer = Observer(token)
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer.token)
            }
        }
    }

    private final class Observer: @unchecked Sendable {
        let token: NSObjectProtocol
        init(_ token: NSObjectProtocol) { self.token = token }
    }
}
#endif
