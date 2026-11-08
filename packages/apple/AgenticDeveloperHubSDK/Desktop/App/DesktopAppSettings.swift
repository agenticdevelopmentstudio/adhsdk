import Combine
import Foundation
import AgenticDeveloperHubSDKCore

/// A setting key bound to a default, for reading and writing through a `UserSettings` store.
/// Lighter than `UserSetting`, which observes `UserSettings.shared`.
struct DesktopSettingKey<Value: Codable & Sendable>: StorableSetting {
    let name: String
    let defaultValue: Value
    var isSecure: Bool { false }
}

/// Per-App settings store: typed access to the fields an App's schema declares,
/// persisted in `UserSettings` under `desktopApp.<identifier>.<field key>`.
///
/// Reading or writing an undeclared key, or one of the wrong kind, is a programmer error.
@MainActor
public final class DesktopAppSettings {
    /// The kind of access a caller asks for, checked against the schema.
    enum Access: String {
        case bool, string, integer, choice
    }

    private let appIdentifier: String
    private let schema: DesktopAppSettingsSchema
    private let store: UserSettings

    public init(appIdentifier: String, schema: DesktopAppSettingsSchema, store: UserSettings = .shared) {
        self.appIdentifier = appIdentifier
        self.schema = schema
        self.store = store
    }

    public static func storageKey(appIdentifier: String, fieldKey: String) -> String {
        "\(keyPrefix(appIdentifier: appIdentifier))\(fieldKey)"
    }

    private static func keyPrefix(appIdentifier: String) -> String {
        "desktopApp.\(appIdentifier)."
    }

    /// Emits the field key whenever one of this App's settings changes.
    public var changes: AnyPublisher<String, Never> {
        let prefix = Self.keyPrefix(appIdentifier: appIdentifier)
        return store.changes
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .eraseToAnyPublisher()
    }

    // MARK: Bool

    public func bool(_ key: String) -> Bool {
        guard case .toggle(let fallback) = kind(of: key, access: .bool) else { preconditionFailure("unreachable") }
        return store.get(settingKey(key, default: fallback))
    }

    public func setBool(_ value: Bool, for key: String) {
        guard case .toggle(let fallback) = kind(of: key, access: .bool) else { preconditionFailure("unreachable") }
        store.set(value, for: settingKey(key, default: fallback))
    }

    // MARK: String

    public func string(_ key: String) -> String {
        guard case .text(let fallback, _) = kind(of: key, access: .string) else { preconditionFailure("unreachable") }
        return store.get(settingKey(key, default: fallback))
    }

    public func setString(_ value: String, for key: String) {
        guard case .text(let fallback, _) = kind(of: key, access: .string) else { preconditionFailure("unreachable") }
        store.set(value, for: settingKey(key, default: fallback))
    }

    // MARK: Integer

    /// Clamped to the field's range on read as well as on write, so a default
    /// outside the range still reads inside it.
    public func integer(_ key: String) -> Int {
        guard case .integer(let fallback, let range) = kind(of: key, access: .integer) else {
            preconditionFailure("unreachable")
        }
        let stored: Int = store.get(settingKey(key, default: fallback))
        return Self.clamp(stored, to: range)
    }

    public func setInteger(_ value: Int, for key: String) {
        guard case .integer(let fallback, let range) = kind(of: key, access: .integer) else {
            preconditionFailure("unreachable")
        }
        store.set(Self.clamp(value, to: range), for: settingKey(key, default: fallback))
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    // MARK: Choice

    /// The stored option id; a stored id no longer among the options reads as the default.
    public func choice(_ key: String) -> String {
        guard case .choice(let fallback, let options) = kind(of: key, access: .choice) else {
            preconditionFailure("unreachable")
        }
        let stored: String = store.get(settingKey(key, default: fallback))
        return options.contains { $0.id == stored } ? stored : fallback
    }

    public func setChoice(_ id: String, for key: String) {
        guard case .choice(let fallback, let options) = kind(of: key, access: .choice) else {
            preconditionFailure("unreachable")
        }
        guard options.contains(where: { $0.id == id }) else {
            preconditionFailure("DesktopAppSettings: '\(id)' is not an option of choice field '\(key)'")
        }
        store.set(id, for: settingKey(key, default: fallback))
    }

    // MARK: Reset

    /// Removes the stored value, so the field reads its schema default again.
    public func reset(_ key: String) {
        guard schema.fields.contains(where: { $0.key == key }) else {
            preconditionFailure("DesktopAppSettings: undeclared key '\(key)'")
        }
        // Removal goes by key name alone, so the value type is irrelevant.
        store.remove(settingKey(key, default: ""))
    }

    // MARK: Validation

    /// Why `access` to `key` is invalid for `schema`, or nil when it is valid.
    static func kindMismatch(key: String, access: Access, schema: DesktopAppSettingsSchema) -> String? {
        guard let field = schema.fields.first(where: { $0.key == key }) else {
            return "undeclared key '\(key)'"
        }
        let actual: Access
        switch field.kind {
        case .toggle: actual = .bool
        case .text: actual = .string
        case .integer: actual = .integer
        case .choice: actual = .choice
        }
        return actual == access ? nil : "key '\(key)' is a \(actual.rawValue) field, not \(access.rawValue)"
    }

    private func kind(of key: String, access: Access) -> DesktopAppSettingsSchema.Kind {
        if let problem = Self.kindMismatch(key: key, access: access, schema: schema) {
            preconditionFailure("DesktopAppSettings: \(problem)")
        }
        guard let field = schema.fields.first(where: { $0.key == key }) else { preconditionFailure("unreachable") }
        return field.kind
    }

    private func settingKey<Value: Codable & Sendable>(
        _ key: String,
        default fallback: Value
    ) -> DesktopSettingKey<Value> {
        DesktopSettingKey(name: Self.storageKey(appIdentifier: appIdentifier, fieldKey: key), defaultValue: fallback)
    }
}
