import Foundation

/// One entry of a `GRDBSyncStore`'s change feed (`_change_log`): a record of
/// `resource` with this `id` was written or deleted, locally or by a pull,
/// and now has `version` as its `local_version`. `seq` orders the feed and
/// is never reused.
public struct RecordChange: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case upsert
        case delete
    }

    public let seq: Int64
    public let resource: String
    public let id: String
    public let kind: Kind
    public let version: Int64

    public init(seq: Int64, resource: String, id: String, kind: Kind, version: Int64) {
        self.seq = seq
        self.resource = resource
        self.id = id
        self.kind = kind
        self.version = version
    }
}

/// The observers a store tells, after a transaction that appended to the
/// change feed has committed. Lock-protected so the store holding it stays
/// honestly `Sendable`.
final class ChangeCommitSignal: @unchecked Sendable {
    private let lock = NSLock()
    private var observers: [@Sendable () -> Void] = []

    func add(_ observer: @escaping @Sendable () -> Void) {
        lock.withLock { observers.append(observer) }
    }

    func fire() {
        let snapshot = lock.withLock { observers }
        for observer in snapshot { observer() }
    }
}
