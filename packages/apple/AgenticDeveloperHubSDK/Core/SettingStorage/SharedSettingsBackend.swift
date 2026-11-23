import Foundation

/// Where an app's shared settings live: adhd's `SharedSettingsStore`, reached
/// through the daemon's client in the apps, or anything else that keeps JSON
/// values by key and says when one changes.
///
/// Values are JSON (`Data` of one JSON value, a fragment included), the same
/// encoding the store keeps, so a backend passes them through untouched.
public protocol SharedSettingsBackend: Sendable {

    /// Every shared value, by key.
    func load() async throws -> [String: Data]

    /// One key's value, or nil when it is not set.
    func value(forKey key: String) async throws -> Data?

    /// Stores `value` (JSON) for `key`.
    func set(_ value: Data, forKey key: String) async throws

    /// Removes `key`, so readers fall back to the setting's default.
    func remove(forKey key: String) async throws

    /// The key of every change, whoever made it. Each read of this property
    /// is a new stream; it ends when the backend goes away.
    var changes: AsyncStream<String> { get }
}
