#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// `POST /import-legacy`: copies a retired daemon's store copies into this
/// runtime through ``LegacySessionImporter``. A daemon mounts it under its own
/// prefix (adhd: `/adhd/v1/sessions/import-legacy`).
///
/// The body names the directories, each optional but at least one required:
/// `{"stenographer": "<dir of stenographerd copies>", "adkd": "<dir of adkd copies>"}`.
/// stenographerd's is imported first. The reply is ``Response``: one
/// ``LegacyImportReport`` per directory given.
public enum LegacyImportRoutes {

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "POST /import-legacy"
    ]

    /// The request body.
    public struct Request: Codable, Sendable, Equatable {
        public let stenographer: String?
        public let adkd: String?

        public init(stenographer: String?, adkd: String?) {
            self.stenographer = stenographer
            self.adkd = adkd
        }
    }

    /// The reply: a report per directory imported.
    public struct Response: Codable, Sendable, Equatable {
        public let stenographer: LegacyImportReport?
        public let adkd: LegacyImportReport?

        public init(stenographer: LegacyImportReport?, adkd: LegacyImportReport?) {
            self.stenographer = stenographer
            self.adkd = adkd
        }
    }

    public static func table(importer: LegacySessionImporter) -> RouteTable {
        RouteTable([
            RouteTable.route("POST", where: { $0 == ["import-legacy"] }) { request, _ in
                guard !request.body.isEmpty,
                      let body = try? JSONDecoder().decode(Request.self, from: request.body) else {
                    return .error("Expected {\"stenographer\": path, \"adkd\": path}", status: 400)
                }
                let sources: [(LegacySessionImporter.SourceKind, String)] = [
                    body.stenographer.map { (.stenographerd, $0) },
                    body.adkd.map { (.adkd, $0) }
                ].compactMap { $0 }
                guard !sources.isEmpty else {
                    return .error("Name at least one of `stenographer` and `adkd`", status: 400)
                }
                for (_, path) in sources {
                    var isDirectory: ObjCBool = false
                    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                          isDirectory.boolValue else {
                        return .error("Not a directory: \(path)", status: 400)
                    }
                }
                do {
                    let reports = try await run {
                        try sources.map { kind, path in
                            try importer.importStores(kind: kind, directory: URL(fileURLWithPath: path))
                        }
                    }
                    return .json(Response(
                        stenographer: reports.first { $0.source == .stenographerd },
                        adkd: reports.first { $0.source == .adkd }
                    ))
                } catch {
                    return .failure(error)
                }
            }
        ])
    }

    /// An import holds a thread for as long as it copies, so it runs on a
    /// dispatch queue, never on a cooperative-pool thread.
    private static func run<T: Sendable>(_ body: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(with: Result { try body() })
            }
        }
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
