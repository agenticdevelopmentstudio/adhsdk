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
/// ``LegacyImportReport`` per directory imported.
///
/// Each source commits on its own, so one that fails does not undo the one
/// before it. A failure answers 500 with the same ``Response``: the report of
/// every source that landed, the failed source's error, and `error`, one
/// sentence saying which failed and which landed. A source after the failed
/// one is not attempted (stenographerd goes first for a reason) and says so.
/// The import is idempotent, so the fix is to re-run it.
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

    /// The reply: a report per directory imported and, when one failed, why.
    /// The error fields are optional, so a reader written before them still
    /// decodes a reply.
    public struct Response: Codable, Sendable, Equatable {
        public let stenographer: LegacyImportReport?
        public let adkd: LegacyImportReport?
        /// Why stenographerd's directory was not imported (or not attempted).
        public let stenographerError: String?
        /// Why adkd's directory was not imported (or not attempted).
        public let adkdError: String?
        /// One sentence for a failed import: which source failed, which landed.
        public let error: String?

        public init(
            stenographer: LegacyImportReport?, adkd: LegacyImportReport?,
            stenographerError: String? = nil, adkdError: String? = nil, error: String? = nil
        ) {
            self.stenographer = stenographer
            self.adkd = adkd
            self.stenographerError = stenographerError
            self.adkdError = adkdError
            self.error = error
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
                let outcomes = await run { importEach(sources, with: importer) }
                let response = response(for: outcomes)
                return response.error == nil ? .json(response) : .json(response, status: 500)
            }
        ])
    }

    /// One source's outcome: its report, or why it was not imported.
    enum Outcome: Sendable {
        case imported(LegacyImportReport)
        case failed(String)
        case notAttempted

        var report: LegacyImportReport? {
            if case .imported(let report) = self { return report }
            return nil
        }

        var isNotAttempted: Bool {
            if case .notAttempted = self { return true }
            return false
        }
    }

    /// Imports `sources` in order, each committing on its own, and stops at
    /// the first that throws: the ones after it are `.notAttempted`.
    static func importEach(
        _ sources: [(LegacySessionImporter.SourceKind, String)],
        with importer: LegacySessionImporter
    ) -> [(LegacySessionImporter.SourceKind, Outcome)] {
        var outcomes: [(LegacySessionImporter.SourceKind, Outcome)] = []
        var failed = false
        for (kind, path) in sources {
            guard !failed else {
                outcomes.append((kind, .notAttempted))
                continue
            }
            do {
                outcomes.append((kind, .imported(
                    try importer.importStores(kind: kind, directory: URL(fileURLWithPath: path)))))
            } catch {
                failed = true
                outcomes.append((kind, .failed(error.localizedDescription)))
            }
        }
        return outcomes
    }

    /// The reply for `outcomes`: `error` is set when any source failed.
    static func response(for outcomes: [(LegacySessionImporter.SourceKind, Outcome)]) -> Response {
        func outcome(_ kind: LegacySessionImporter.SourceKind) -> Outcome? {
            outcomes.first { $0.0 == kind }?.1
        }
        func reason(_ kind: LegacySessionImporter.SourceKind) -> String? {
            switch outcome(kind) {
            case .failed(let message): return message
            case .notAttempted: return "Not attempted: an earlier source failed."
            case .imported, nil: return nil
            }
        }
        var error: String?
        for (kind, result) in outcomes {
            guard case .failed(let message) = result else { continue }
            let landed = outcomes.compactMap(\.1.report).map { "\(wireName($0.source)) (\($0.totalInserted) rows)" }
            let skipped = outcomes.filter { $0.1.isNotAttempted }.map { wireName($0.0) }
            let reason = message.hasSuffix(".") ? String(message.dropLast()) : message
            var sentence = "The \(wireName(kind)) import failed: \(reason)."
            sentence += landed.isEmpty
                ? " Nothing was imported."
                : " Imported and committed: \(landed.joined(separator: ", "))."
            if !skipped.isEmpty {
                sentence += " Not attempted: \(skipped.joined(separator: ", "))."
            }
            error = sentence + " Re-running the import is safe."
            break
        }
        return Response(
            stenographer: outcome(.stenographerd)?.report, adkd: outcome(.adkd)?.report,
            stenographerError: reason(.stenographerd), adkdError: reason(.adkd), error: error
        )
    }

    /// A source's name on the wire, as the request names it.
    private static func wireName(_ kind: LegacySessionImporter.SourceKind) -> String {
        switch kind {
        case .stenographerd: return "stenographer"
        case .adkd: return "adkd"
        }
    }

    /// An import holds a thread for as long as it copies, so it runs on a
    /// dispatch queue, never on a cooperative-pool thread.
    private static func run<T: Sendable>(_ body: @escaping @Sendable () -> T) async -> T {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: body())
            }
        }
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
