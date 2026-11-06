import Foundation
import AgenticDeveloperHubSDKCore

/// Indirection over the Keychain so tests can substitute an in-memory store and
/// never touch the real login keychain. The secret-storage abstraction is a
/// separate concern from key naming — hosts bring their own key convention.
public protocol SecretStoring: Sendable {
    func get(forKey key: String) -> String?
    /// Like `get`, but a store failure (a locked Keychain) throws rather than reading as an
    /// absent secret, so a caller can tell "no secret" from "could not look".
    func read(forKey key: String) throws -> String?
    @discardableResult func set(_ value: String, forKey key: String) -> Bool
    /// Removes a stored secret. The removal path: when the host clears a credential
    /// field it pushes an empty value, and the daemon deletes the entry rather than
    /// keeping a stale key. Idempotent — deleting an absent key is not an error.
    @discardableResult func delete(forKey key: String) -> Bool

    /// Removes a secret written by a PRE-pin daemon, which had no bundle id and so
    /// stored under the `KeychainHelper` fallback service (`com.mikefullerton.agenticdeveloperhubsdk`)
    /// rather than today's pinned daemon service. Used only by the one-time legacy
    /// cleanup — the current `delete` targets the pinned service, where these
    /// pre-upgrade credentials never lived, so without this the real old key would
    /// linger. Idempotent.
    @discardableResult func deleteLegacy(forKey key: String) -> Bool
}

extension SecretStoring {
    /// Stores that cannot fail to read report through `get`.
    public func read(forKey key: String) throws -> String? { get(forKey: key) }
}

/// Production `SecretStoring` backed by `KeychainHelper`.
///
/// With no `service` it uses the host process's `KeychainHelper.service`,
/// read at each call (so a host that pins that global after building the
/// store still gets the pinned one). With a `service` it keeps its items under
/// that service alone, without touching the process-wide global, so one
/// process can hold stores for different services side by side.
public struct KeychainSecretStore: SecretStoring {
    /// The pre-pin fallback service a bundle-id-less daemon used before hosts
    /// pinned an explicit one. Mirrors `KeychainHelper`'s own default fallback.
    public static let legacyService = "com.agentictoolkit"

    /// The Keychain service this store reads and writes, or nil for the
    /// process-wide `KeychainHelper.service`.
    public let service: String?

    public init(service: String? = nil) {
        self.service = service
    }

    private var resolvedService: String { service ?? KeychainHelper.service }

    public func get(forKey key: String) -> String? { KeychainHelper.get(forKey: key, service: resolvedService) }

    public func read(forKey key: String) throws -> String? {
        try KeychainHelper.read(forKey: key, service: resolvedService)
    }

    @discardableResult
    public func set(_ value: String, forKey key: String) -> Bool {
        KeychainHelper.set(value, forKey: key, service: resolvedService)
    }

    @discardableResult
    public func delete(forKey key: String) -> Bool { KeychainHelper.delete(forKey: key, service: resolvedService) }

    @discardableResult
    public func deleteLegacy(forKey key: String) -> Bool {
        // Delete under the old fallback service by briefly retargeting the global
        // service. Callers must serialize this with their other Keychain access
        // (stenographer runs it only inside its one-time, lock-serialized legacy
        // cleanup), so no concurrent access races the swap.
        let pinned = KeychainHelper.service
        KeychainHelper.service = Self.legacyService
        defer { KeychainHelper.service = pinned }
        return KeychainHelper.delete(forKey: key)
    }
}
