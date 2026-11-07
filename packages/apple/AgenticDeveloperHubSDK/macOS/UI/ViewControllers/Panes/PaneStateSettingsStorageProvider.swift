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

    /// Names written through this instance. `PaneStateStore` cannot enumerate,
    /// so this is all `keys(withPrefix:)` can list beyond an exact-name probe.
    private var writtenNames: Set<String> = []

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
              let text = String(data: data, encoding: .utf8) else { return }
        store.setPaneStateValue(text, forKey: storageKey(key.name))
        writtenNames.insert(key.name)
        changeSubject.send(key.name)
    }

    public func remove<Value: ValueType>(_ key: any StorableSetting<Value>) {
        store.setPaneStateValue(nil, forKey: storageKey(key.name))
        writtenNames.remove(key.name)
        changeSubject.send(key.name)
    }

    public func contains<Value: ValueType>(_ key: any StorableSetting<Value>) -> Bool {
        decoded(key) != nil
    }

    /// Names written this session that start with `prefix`, plus `prefix`
    /// itself when the store holds a value under exactly that name, which is
    /// how a caller asks about one key without a typed handle.
    public func keys(withPrefix prefix: String) -> [String] {
        var names = writtenNames.filter { $0.hasPrefix(prefix) }
        if store.paneStateValue(forKey: storageKey(prefix)) != nil {
            names.insert(prefix)
        }
        return names.sorted()
    }

    private func storageKey(_ name: String) -> String { prefix + name }

    private func decoded<Value: ValueType>(_ key: any StorableSetting<Value>) -> Value? {
        guard let text = store.paneStateValue(forKey: storageKey(key.name)),
              let data = text.data(using: .utf8),
              let wrapped = try? JSONDecoder().decode([Value].self, from: data) else { return nil }
        return wrapped.first
    }
}
