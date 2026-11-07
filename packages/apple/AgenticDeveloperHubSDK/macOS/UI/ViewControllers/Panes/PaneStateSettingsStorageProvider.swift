import Foundation
import Combine
import AgenticDeveloperHubSDKCore

/// Settings held in a pane's own state, one JSON string per key.
///
/// The override layer for a `LayeredSettingsStore`: a pane keeps its
/// overrides with the rest of its state, so they travel and die with the pane.
/// Each value is JSON in a one-element array, because a bare scalar is not a
/// JSON document. A stored string that no longer decodes (an enum lost a
/// case, say) reads as absent, so the layer above falls back instead of
/// crashing.
@MainActor
public final class PaneStateSettingsStorageProvider: SettingsStorageProvider {

    private let store: PaneStateStore
    private let prefix: String
    private let changeSubject = PassthroughSubject<String, Never>()

    public init(store: PaneStateStore, prefix: String = "settings.") {
        self.store = store
        self.prefix = prefix
    }

    public var changes: AnyPublisher<String, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    public func get<Value: ValueType>(_ key: any StorableSetting<Value>) -> Value {
        decoded(key) ?? key.defaultValue
    }

    public func set<Value: ValueType>(_ value: Value, for key: any StorableSetting<Value>) {
        guard let data = try? JSONEncoder().encode([value]),
              let text = String(data: data, encoding: .utf8) else {
            assertionFailure("Setting \(key.name) could not be encoded as JSON; the value was not stored")
            return
        }
        store.setPaneStateValue(text, forKey: storageKey(key.name))
        var names = indexedNames()
        if !names.contains(key.name) {
            names.append(key.name)
            writeIndex(names)
        }
        changeSubject.send(key.name)
    }

    public func remove<Value: ValueType>(_ key: any StorableSetting<Value>) {
        let hadValue = store.paneStateValue(forKey: storageKey(key.name)) != nil
        store.setPaneStateValue(nil, forKey: storageKey(key.name))
        let names = indexedNames()
        if names.contains(key.name) {
            writeIndex(names.filter { $0 != key.name })
        }
        if hadValue {
            changeSubject.send(key.name)
        }
    }

    public func contains<Value: ValueType>(_ key: any StorableSetting<Value>) -> Bool {
        decoded(key) != nil
    }

    /// The indexed names that start with `prefix` and still hold a stored
    /// value of the shape this provider writes. The index is what makes the
    /// answer survive a relaunch, since `PaneStateStore` cannot enumerate. A
    /// value that is not a one-element JSON array reads as absent here, as it
    /// does in `contains`; whether it is the right element type is only known
    /// to a typed caller, which is the one place the two can still differ.
    public func keys(withPrefix prefix: String) -> [String] {
        indexedNames()
            .filter { $0.hasPrefix(prefix) && hasWellFormedValue(named: $0) }
            .sorted()
    }

    private var indexKey: String { prefix + "__keys" }

    private func indexedNames() -> [String] {
        guard let text = store.paneStateValue(forKey: indexKey),
              let data = text.data(using: .utf8),
              let names = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return names
    }

    private func writeIndex(_ names: [String]) {
        guard !names.isEmpty else {
            store.setPaneStateValue(nil, forKey: indexKey)
            return
        }
        guard let data = try? JSONEncoder().encode(names),
              let text = String(data: data, encoding: .utf8) else {
            assertionFailure("The settings index could not be encoded as JSON")
            return
        }
        store.setPaneStateValue(text, forKey: indexKey)
    }

    private func hasWellFormedValue(named name: String) -> Bool {
        guard let text = store.paneStateValue(forKey: storageKey(name)),
              let data = text.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [Any] else { return false }
        return parsed.count == 1
    }

    private func storageKey(_ name: String) -> String { prefix + name }

    private func decoded<Value: ValueType>(_ key: any StorableSetting<Value>) -> Value? {
        guard let text = store.paneStateValue(forKey: storageKey(key.name)),
              let data = text.data(using: .utf8),
              let wrapped = try? JSONDecoder().decode([Value].self, from: data) else { return nil }
        return wrapped.first
    }
}
