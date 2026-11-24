import Foundation
import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKSync

/// The sync engine's `SyncTransport` over the hub client's `ADHSyncAPI`.
///
/// `ADHSyncAPI` owns the HTTP (routes, bearer token, status codes). This type
/// adds the two things it leaves out: JSON coding of the engine's wire types,
/// and the mapping of `ADHSyncAPI.Failure` onto `SyncTransportError`, the only
/// error vocabulary the engine reacts to.
public struct ADHSyncTransport: SyncTransport {

    typealias PullCall = @Sendable (String?, Int) async throws -> Data
    typealias PushCall = @Sendable (Data) async throws -> Data

    private let pullCall: PullCall
    private let pushCall: PushCall

    public init(api: ADHSyncAPI) {
        self.init(
            pull: { cursor, limit in try await api.pull(cursor: cursor, limit: limit) },
            push: { body in try await api.push(body: body) }
        )
    }

    /// Tests drive the transport through these two calls, without a network.
    init(pull: @escaping PullCall, push: @escaping PushCall) {
        self.pullCall = pull
        self.pushCall = push
    }

    public func pull(cursor: SyncCursor?, limit: Int) async throws -> SyncPullResponse {
        try await Self.mapping {
            let body = try await pullCall(cursor?.rawValue, limit)
            return try JSONDecoder().decode(SyncPullResponse.self, from: body)
        }
    }

    public func push(_ request: SyncPushRequest) async throws -> SyncPushResponse {
        try await Self.mapping {
            let payload = try JSONEncoder().encode(request)
            let body = try await pushCall(payload)
            return try JSONDecoder().decode(SyncPushResponse.self, from: body)
        }
    }

    private static func mapping<T>(_ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch {
            throw map(error)
        }
    }

    /// `CancellationError` passes through unchanged, so a stopped engine is not
    /// counted as a failed cycle. Every other error becomes a `SyncTransportError`.
    static func map(_ error: any Error) -> any Error {
        if error is CancellationError { return error }
        if let failure = error as? ADHSyncAPI.Failure {
            switch failure {
            case .unauthorized: return SyncTransportError.unauthorized
            case .resyncRequired: return SyncTransportError.resyncRequired
            case .http(let code): return SyncTransportError.invalidResponse(statusCode: code)
            case .transport(let message): return SyncTransportError.transport(message)
            }
        }
        if let already = error as? SyncTransportError { return already }
        return SyncTransportError.transport(String(describing: error))
    }
}
