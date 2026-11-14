import Foundation
import Combine

/// A settings store whose values can be overridden in a narrower scope (one
/// browser pane, say) while everything it does not override reads through to a
/// broader store.
///
/// Reads answer the override when one exists and the `fallback` otherwise;
/// writes always land in the overrides, so the broader store is never touched
/// from here. Secure keys skip the layering entirely and go straight to the
/// fallback: a secret has one home, and a per-pane copy would be a second place
/// to leak it from.
///
/// `changes` publishes override changes, plus fallback changes for keys the
/// overrides do not hold, so a pane never sees a global change it is hiding.
@MainActor
public final class LayeredSettingsStore: SettingsStore {

    public let fallback: SettingsStore
    private let overrides: SettingsStorageProvider

    public init(overrides: SettingsStorageProvider, fallback: SettingsStore) {
        self.fallback = fallback
        self.overrides = overrides
        super.init(
            with: LayeredSettingsStorageProvider(overrides: overrides, fallback: fallback),
            secureSettingsProvider: FallbackSecureSettingsStorageProvider(fallback: fallback)
        )
    }

    /// Whether this layer holds its own value for `key`.
    public func hasOverride<Value>(_ key: any StorableSetting<Value>) -> Bool
    where Value: Decodable, Value: Encodable, Value: Sendable {
        !key.isSecure && overrides.contains(key)
    }

    /// Drops this layer's value, so reads show the fallback's again.
    public func removeOverride<Value>(_ key: any StorableSetting<Value>)
    where Value: Decodable, Value: Encodable, Value: Sendable {
        remove(key)
    }

    /// Drops every override whose name starts with `prefix`, except the
    /// names in `keeping` — overrides that define what the layer is (the
    /// private browser window's private browsing) rather than a preference.
    public func removeAllOverrides(withPrefix prefix: String, keeping: Set<String> = []) {
        for name in overrides.keys(withPrefix: prefix) where !keeping.contains(name) {
            overrides.remove(NamedSetting(name: name))
        }
    }
}

/// A key known only by name, for removing what `keys(withPrefix:)` lists.
/// Providers remove by name, so the value type never matters.
@MainActor
private struct NamedSetting: StorableSetting {
    let name: String
    var isSecure: Bool { false }
    var defaultValue: Bool { false }
}

/// Overrides over a fallback, for the non-secure half of the store.
@MainActor
private final class LayeredSettingsStorageProvider: SettingsStorageProvider {

    private let overrides: SettingsStorageProvider
    private let fallback: SettingsStore

    init(overrides: SettingsStorageProvider, fallback: SettingsStore) {
        self.overrides = overrides
        self.fallback = fallback
    }

    var changes: AnyPublisher<String, Never> {
        let hidden = fallback.changes.filter { [weak self] name in
            // An exact-name probe: a provider that cannot enumerate still
            // answers whether it holds this one name.
            self?.overrides.keys(withPrefix: name).contains(name) != true
        }
        return Publishers.Merge(overrides.changes, hidden).eraseToAnyPublisher()
    }

    func get<Value: ValueType>(_ key: any StorableSetting<Value>) -> Value {
        overrides.contains(key) ? overrides.get(key) : fallback.get(key)
    }

    func set<Value: ValueType>(_ value: Value, for key: any StorableSetting<Value>) {
        overrides.set(value, for: key)
    }

    func remove<Value: ValueType>(_ key: any StorableSetting<Value>) {
        overrides.remove(key)
    }

    /// An override is "contained"; the fallback's values are inherited, not held.
    func contains<Value: ValueType>(_ key: any StorableSetting<Value>) -> Bool {
        overrides.contains(key)
    }

    func keys(withPrefix prefix: String) -> [String] {
        overrides.keys(withPrefix: prefix)
    }
}

/// Forwards secure keys to the fallback store, which owns the real secure provider.
@MainActor
private final class FallbackSecureSettingsStorageProvider: SecureSettingsStorageProvider {

    private let fallback: SettingsStore

    init(fallback: SettingsStore) {
        self.fallback = fallback
    }

    /// Silent on purpose: `SettingsStore.changes` merges this with the layered
    /// provider's, which already relays every fallback change (secure ones
    /// included). Relaying them here too would publish each one twice, and
    /// would skip the override filter.
    var changes: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    func get<Value: ValueType>(_ key: any StorableSetting<Value>) -> Value { fallback.get(key) }

    func set<Value: ValueType>(_ value: Value, for key: any StorableSetting<Value>) {
        fallback.set(value, for: key)
    }

    func remove<Value: ValueType>(_ key: any StorableSetting<Value>) { fallback.remove(key) }

    func contains<Value: ValueType>(_ key: any StorableSetting<Value>) -> Bool { fallback.contains(key) }
}
