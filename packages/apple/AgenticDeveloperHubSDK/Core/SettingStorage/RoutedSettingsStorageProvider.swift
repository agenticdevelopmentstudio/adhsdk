import Foundation
import Combine
import os

/// A settings provider that sends an explicit set of keys to a
/// `SharedSettingsBackend` (adhd, for the suite's shared settings) and every
/// other key to the provider it wraps.
///
/// `UserSettings` is main-actor and synchronous and the backend is neither, so
/// the routed keys are served from a cache of their JSON values:
///
/// - **Reads** answer the cache once ``start()`` has loaded it; a key the
///   backend does not hold reads as its default. Until the load succeeds (or
///   if it fails) a routed key reads the fallback, so an app that cannot reach
///   adhd still shows the values it had.
/// - **Writes** land in the cache at once, publish a change, then go to the
///   backend in order. The fallback is never written for a routed key.
/// - **Backend changes** refetch the key; the cache is updated and a change
///   published only when the value differs, so an app's own write coming back
///   over the change feed is silent.
///
/// Install it with `UserSettings.install(routedProvider:)`, built over the
/// provider it replaces (`UserSettings.shared.settingsStorageProvider`).
@MainActor
public final class RoutedSettingsStorageProvider: SettingsStorageProvider {

    public let routed: SharedSettingKeys
    public let fallback: SettingsStorageProvider
    private let backend: SharedSettingsBackend

    /// Routed values by key. An entry holding nil is a key known to be unset;
    /// a key with no entry is unknown, and reads the fallback until loaded.
    private var cache: [String: Data?] = [:]
    /// Whether a load succeeded, which makes the cache the whole truth.
    public private(set) var isLoaded = false

    /// Writes not yet answered by the backend, by key. A change for such a
    /// key is the write's own echo or older than it, so it is not applied;
    /// the key is refetched when its last write is answered instead.
    private var pendingWrites: [String: Int] = [:]
    private var lastWrite: Task<Void, Never>?
    private var listening: Task<Void, Never>?

    private let changeSubject = PassthroughSubject<String, Never>()
    private var fallbackChanges: AnyCancellable?
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()
    private let decoder = JSONDecoder()

    public init(
        routed: SharedSettingKeys = .all,
        backend: SharedSettingsBackend,
        fallback: SettingsStorageProvider
    ) {
        self.routed = routed
        self.backend = backend
        self.fallback = fallback
        let subject = changeSubject
        fallbackChanges = fallback.changes.sink { [weak self] name in
            // A routed key's fallback value is only visible before the load.
            guard let self, !self.routed.contains(name) || !self.isKnown(name) else { return }
            subject.send(name)
        }
    }

    deinit {
        listening?.cancel()
    }

    public var changes: AnyPublisher<String, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    // MARK: - Connecting

    /// Loads every routed value from the backend, then follows its changes.
    ///
    /// Throws the load's error and leaves the fallback answering; call it
    /// again (on a reconnect, say) to retry. Each call replaces the previous
    /// call's change listener.
    public func start() async throws {
        listening?.cancel()
        listening = nil
        // Subscribe before loading, so a change made during the load is
        // buffered rather than missed.
        let stream = backend.changes
        let loaded = try await backend.load()
        apply(loaded: loaded)
        listening = Task { [weak self] in
            for await key in stream {
                guard let self else { return }
                await self.refresh(key)
            }
        }
    }

    /// Stops following the backend's changes. The cache keeps answering.
    public func stop() {
        listening?.cancel()
        listening = nil
    }

    /// Returns when every write made so far has been answered by the backend.
    public func waitForPendingWrites() async {
        await lastWrite?.value
    }

    private func apply(loaded: [String: Data]) {
        var changed: [String] = []
        var next: [String: Data?] = [:]
        for (key, value) in loaded where routed.contains(key) {
            next[key] = value
        }
        // Keys written here since the load began keep the local value.
        for key in pendingWrites.keys {
            next[key] = cache[key] ?? nil
        }
        let names = Set(next.keys).union(cache.keys)
        for name in names where (next[name] ?? nil) != (cache[name] ?? nil) || !isKnown(name) {
            changed.append(name)
        }
        cache = next
        isLoaded = true
        changed.sorted().forEach { changeSubject.send($0) }
    }

    private func refresh(_ key: String) async {
        guard routed.contains(key), pendingWrites[key] == nil else { return }
        let value: Data?
        do {
            value = try await backend.value(forKey: key)
        } catch {
            let reason = String(describing: error)
            Self.logger.error("Shared setting \(key, privacy: .public) refetch failed: \(reason, privacy: .public)")
            return
        }
        // A write made while the fetch was out is newer than what it brought.
        guard pendingWrites[key] == nil else { return }
        if isKnown(key), (cache[key] ?? nil) == value { return }
        cache[key] = value
        changeSubject.send(key)
    }

    // MARK: - SettingsStorageProvider

    public func get<Value: Codable & Sendable>(_ key: any StorableSetting<Value>) -> Value {
        guard routed.contains(key.name), isKnown(key.name) else {
            return fallback.get(key)
        }
        guard let data = cache[key.name] ?? nil else { return key.defaultValue }
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            let name = key.name, reason = String(describing: error)
            Self.logger.error("Shared setting \(name, privacy: .public) does not decode: \(reason, privacy: .public)")
            return key.defaultValue
        }
    }

    public func set<Value: Codable & Sendable>(_ value: Value, for key: any StorableSetting<Value>) {
        guard routed.contains(key.name) else {
            fallback.set(value, for: key)
            return
        }
        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            let name = key.name, reason = String(describing: error)
            Self.logger.error("Shared setting \(name, privacy: .public) does not encode: \(reason, privacy: .public)")
            return
        }
        let name = key.name
        cache[name] = data
        changeSubject.send(name)
        enqueueWrite(name) { backend in try await backend.set(data, forKey: name) }
    }

    public func remove<Value: Codable & Sendable>(_ key: any StorableSetting<Value>) {
        guard routed.contains(key.name) else {
            fallback.remove(key)
            return
        }
        let name = key.name
        cache.updateValue(nil, forKey: name)
        changeSubject.send(name)
        enqueueWrite(name) { backend in try await backend.remove(forKey: name) }
    }

    public func contains<Value: Codable & Sendable>(_ key: any StorableSetting<Value>) -> Bool {
        guard routed.contains(key.name), isKnown(key.name) else {
            return fallback.contains(key)
        }
        return (cache[key.name] ?? nil) != nil
    }

    public func keys(withPrefix prefix: String) -> [String] {
        let local = fallback.keys(withPrefix: prefix).filter { !routed.contains($0) || !isKnown($0) }
        let shared = cache.compactMap { name, value in
            name.hasPrefix(prefix) && value != nil ? name : nil
        }
        return Array(Set(local).union(shared)).sorted()
    }

    // MARK: - Helpers

    /// Whether the cache answers for `name`: everything routed once loaded,
    /// and before that, the keys written here.
    private func isKnown(_ name: String) -> Bool {
        isLoaded || cache.keys.contains(name)
    }

    /// Sends one write to the backend after every earlier one, so the
    /// backend sees them in the order they were made.
    private func enqueueWrite(
        _ name: String,
        _ write: @escaping @Sendable (SharedSettingsBackend) async throws -> Void
    ) {
        pendingWrites[name, default: 0] += 1
        let previous = lastWrite
        let backend = self.backend
        lastWrite = Task { [weak self] in
            await previous?.value
            do {
                try await write(backend)
            } catch {
                let reason = String(describing: error)
                Self.logger.error("Shared setting \(name, privacy: .public) write failed: \(reason, privacy: .public)")
            }
            await self?.finishWrite(name)
        }
    }

    private func finishWrite(_ name: String) async {
        let remaining = (pendingWrites[name] ?? 1) - 1
        if remaining > 0 {
            pendingWrites[name] = remaining
            return
        }
        pendingWrites.removeValue(forKey: name)
        // The backend's value is the truth once nothing of ours is in
        // flight: another app may have written in between, or this write
        // may have failed.
        if listening != nil || isLoaded {
            await refresh(name)
        }
    }
}

extension RoutedSettingsStorageProvider: Loggable {
    public static nonisolated let logger = makeLogger()
}
