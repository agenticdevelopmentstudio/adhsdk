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

/// A payload-free signal between processes: one process posts it, every
/// process observing it hears it, the poster included. A protocol so a test
/// can fire it by hand.
public protocol CrossProcessSignal: AnyObject, Sendable {
    func post()
    /// Calls `handler` on every post, from any process, on any thread. One
    /// handler per signal; a second call replaces the first.
    func observe(_ handler: @escaping @Sendable () -> Void)
}

/// A `CrossProcessSignal` over a Darwin notification, which reaches every
/// process of the user's session and carries no data.
public final class DarwinNotificationSignal: CrossProcessSignal, @unchecked Sendable {

    public let name: String
    private let lock = NSLock()
    private var handler: (@Sendable () -> Void)?
    private var isObserving = false

    public init(name: String) {
        self.name = name
    }

    deinit {
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque())
    }

    public func post() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(name as CFString), nil, nil, true)
    }

    public func observe(_ handler: @escaping @Sendable () -> Void) {
        let alreadyObserving = lock.withLock { () -> Bool in
            self.handler = handler
            let was = self.isObserving
            self.isObserving = true
            return was
        }
        guard !alreadyObserving else { return }
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                Unmanaged<DarwinNotificationSignal>.fromOpaque(observer).takeUnretainedValue().fire()
            },
            name as CFString, nil, .deliverImmediately)
    }

    private func fire() {
        lock.withLock { handler }?()
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
/// resolved in bulk on the main thread. Because another app writes the same
/// items, a write here posts `changeSignal` and a post from any app re-reads
/// the memoized items (``reloadFromSharedGroup()``), announcing those that
/// changed.
@MainActor
public final class AIProviderSharedSecretsProvider: SecureSettingsStorageProvider {

    /// The Darwin notification the suite's apps post after writing a secret.
    public nonisolated static let changeNotificationName = SharedGroupAIProviderKeychain.service + ".changed"

    public let sharedGroup: AIProviderSecretKeychain
    public let fallback: SecureSettingsStorageProvider
    public let prefix: String
    private let changeSignal: (any CrossProcessSignal)?

    private var cache: [String: String?] = [:]
    private let changeSubject = PassthroughSubject<String, Never>()
    private var fallbackChanges: AnyCancellable?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        sharedGroup: AIProviderSecretKeychain,
        fallback: SecureSettingsStorageProvider,
        prefix: String = SharedSettingKeys.aiProviderConfigPrefix,
        changeSignal: (any CrossProcessSignal)? = nil
    ) {
        self.sharedGroup = sharedGroup
        self.fallback = fallback
        self.prefix = prefix
        self.changeSignal = changeSignal
        let subject = changeSubject
        let prefix = prefix
        fallbackChanges = fallback.changes
            .filter { !$0.hasPrefix(prefix) }
            .sink { subject.send($0) }
        changeSignal?.observe { [weak self] in
            Task { @MainActor in self?.reloadFromSharedGroup() }
        }
    }

    /// Re-reads every memoized item from the shared group and announces each
    /// one whose value another app changed. This app's own write comes back
    /// equal, and silent.
    public func reloadFromSharedGroup() {
        for (name, memoized) in Array(cache) {
            let current = sharedGroup.value(forAccount: name)
            guard current != memoized else { continue }
            // Removed elsewhere reads as removed here too: the memo holds the
            // absence, so a legacy copy in this app's own service is not
            // copied forward again.
            cache.updateValue(current, forKey: name)
            changeSubject.send(name)
        }
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
        changeSignal?.post()
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
        changeSignal?.post()
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
            fallback: UserSettings.shared.secureSettingsStorageProvider,
            changeSignal: DarwinNotificationSignal(name: AIProviderSharedSecretsProvider.changeNotificationName)
        ))
        return true
    }
}
