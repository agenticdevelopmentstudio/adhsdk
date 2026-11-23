import Foundation
import Combine
import AgenticDeveloperHubSDKCore

/// One Keychain location for AI provider secrets: get, set and delete by
/// account (the setting's key name). A protocol so the shared-group provider
/// can be exercised against a fake.
public protocol AIProviderSecretKeychain: Sendable {
    func value(forAccount account: String) -> String?
    @discardableResult func set(_ value: String, forAccount account: String) -> Bool
    @discardableResult func delete(forAccount account: String) -> Bool
    func exists(forAccount account: String) -> Bool
}

/// The access group the studio's apps share, holding one copy of each AI
/// provider secret every app reads.
public struct SharedGroupAIProviderKeychain: AIProviderSecretKeychain {

    /// The group's name, without the team prefix the entitlement carries.
    public static let groupName = "com.agenticdevelopmentstudio.shared"
    /// The service the AI provider secrets are filed under inside the group.
    public static let service = "com.agenticdevelopmentstudio.ai-providers"

    public let accessGroup: String
    public let service: String

    /// - Parameter accessGroup: the entitled group, team prefix included
    ///   (`KeychainHelper.entitledAccessGroup(groupName)`).
    public init(accessGroup: String, service: String = Self.service) {
        self.accessGroup = accessGroup
        self.service = service
    }

    public func value(forAccount account: String) -> String? {
        KeychainHelper.value(forKey: account, service: service, accessGroup: accessGroup)
    }

    public func set(_ value: String, forAccount account: String) -> Bool {
        KeychainHelper.set(value, forKey: account, service: service, accessGroup: accessGroup)
    }

    public func delete(forAccount account: String) -> Bool {
        KeychainHelper.delete(forKey: account, service: service, accessGroup: accessGroup)
    }

    public func exists(forAccount account: String) -> Bool {
        KeychainHelper.exists(forKey: account, service: service, accessGroup: accessGroup)
    }
}

/// The secure-settings provider that keeps AI provider secrets in the shared
/// Keychain group, so every app in the suite reads the same item.
///
/// It serves the secure keys under `aiplugin.config.` and hands every other
/// secure key to `fallback`, the provider it replaces (the app's own
/// bundle-id Keychain service):
///
/// - **Read:** the shared group first. On a miss, the fallback; a value found
///   there is copied into the shared group and left where it was, never
///   deleted, so an older build of the app still finds it.
/// - **Write:** the shared group only.
/// - **Remove:** both places, so a cleared secret is not copied forward again
///   on the next read.
///
/// Reads are memoized like `KeychainSecureSettingsStorageProvider`'s: every
/// Keychain read is a round trip to `securityd`, and AI configurations are
/// resolved in bulk on the main thread.
@MainActor
public final class AIProviderSharedSecretsProvider: SecureSettingsStorageProvider {

    public let sharedGroup: AIProviderSecretKeychain
    public let fallback: SecureSettingsStorageProvider
    public let prefix: String

    private var cache: [String: String?] = [:]
    private let changeSubject = PassthroughSubject<String, Never>()
    private var fallbackChanges: AnyCancellable?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        sharedGroup: AIProviderSecretKeychain,
        fallback: SecureSettingsStorageProvider,
        prefix: String = SharedSettingKeys.aiProviderConfigPrefix
    ) {
        self.sharedGroup = sharedGroup
        self.fallback = fallback
        self.prefix = prefix
        let subject = changeSubject
        let prefix = prefix
        fallbackChanges = fallback.changes
            .filter { !$0.hasPrefix(prefix) }
            .sink { subject.send($0) }
    }

    public var changes: AnyPublisher<String, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    public func get<Value: Codable & Sendable>(_ key: any StorableSetting<Value>) -> Value {
        guard serves(key) else { return fallback.get(key) }
        guard let stored = storedString(for: key) else { return key.defaultValue }
        if Value.self == String.self, let bridged = stored as? Value {
            return bridged
        }
        guard let data = stored.data(using: .utf8), let value = try? decoder.decode(Value.self, from: data) else {
            return key.defaultValue
        }
        return value
    }

    public func set<Value: Codable & Sendable>(_ value: Value, for key: any StorableSetting<Value>) {
        guard serves(key) else {
            fallback.set(value, for: key)
            return
        }
        guard let string = encoded(value) else { return }
        guard sharedGroup.set(string, forAccount: key.name) else {
            cache.removeValue(forKey: key.name)
            return
        }
        cache[key.name] = string
        changeSubject.send(key.name)
    }

    public func remove<Value: Codable & Sendable>(_ key: any StorableSetting<Value>) {
        guard serves(key) else {
            fallback.remove(key)
            return
        }
        sharedGroup.delete(forAccount: key.name)
        fallback.remove(key)
        cache.updateValue(nil, forKey: key.name)
        changeSubject.send(key.name)
    }

    public func contains<Value: Codable & Sendable>(_ key: any StorableSetting<Value>) -> Bool {
        guard serves(key) else { return fallback.contains(key) }
        if let memoized = cache[key.name] { return memoized != nil }
        return sharedGroup.exists(forAccount: key.name) || fallback.contains(key)
    }

    // MARK: - Helpers

    private func serves<Value>(_ key: any StorableSetting<Value>) -> Bool {
        key.name.hasPrefix(prefix)
    }

    /// The raw string for a served key: the memo, else the shared group, else
    /// a copy forward from the fallback.
    private func storedString<Value: Codable & Sendable>(for key: any StorableSetting<Value>) -> String? {
        if let memoized = cache[key.name] { return memoized }
        if let shared = sharedGroup.value(forAccount: key.name) {
            cache.updateValue(shared, forKey: key.name)
            return shared
        }
        guard fallback.contains(key) else {
            cache.updateValue(nil, forKey: key.name)
            return nil
        }
        let legacy = encoded(fallback.get(key))
        if let legacy {
            // Copy forward, never move: the fallback's item stays for any
            // build of the app that still reads only its own service.
            sharedGroup.set(legacy, forAccount: key.name)
        }
        cache.updateValue(legacy, forKey: key.name)
        return legacy
    }

    /// A string as itself (an API key stays readable in Keychain Access),
    /// anything else as JSON, as `KeychainSecureSettingsStorageProvider` does.
    private func encoded<Value: Codable & Sendable>(_ value: Value) -> String? {
        if let string = value as? String { return string }
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension AIProviderConfigStore {

    /// Keeps the AI provider secrets in the studio's shared Keychain group
    /// from now on, by installing an `AIProviderSharedSecretsProvider` over
    /// the shared settings' current secure provider.
    ///
    /// - Parameter accessGroup: the entitled group
    ///   (`KeychainHelper.entitledAccessGroup(SharedGroupAIProviderKeychain.groupName)`).
    ///   Nil, for a binary without the entitlement, changes nothing: the
    ///   secrets stay in the app's own service.
    /// - Returns: whether the shared group is now in use. Calling it again
    ///   does not stack a second provider.
    @discardableResult
    public static func useSharedKeychainGroup(_ accessGroup: String?) -> Bool {
        guard let accessGroup else { return false }
        if UserSettings.shared.secureSettingsStorageProvider is AIProviderSharedSecretsProvider {
            return true
        }
        UserSettings.install(secureProvider: AIProviderSharedSecretsProvider(
            sharedGroup: SharedGroupAIProviderKeychain(accessGroup: accessGroup),
            fallback: UserSettings.shared.secureSettingsStorageProvider
        ))
        return true
    }
}
