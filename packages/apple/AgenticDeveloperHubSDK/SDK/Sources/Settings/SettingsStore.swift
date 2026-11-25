//
//  SettingsStore.swift
//  AgenticDeveloperHubSDK
//
//  Created by Mike Fullerton on 4/27/26.
//
import Foundation
import Combine

@MainActor
open class SettingsStore: SettingsStorageProvider {

    private var settingsProvider: SettingsStorageProvider
    private var secureSettingsProvider: SecureSettingsStorageProvider

    /// One subject for the store's lifetime, fed from whichever providers are
    /// installed. Every `UserSetting` subscribes to `changes` once, when it is
    /// made, so swapping a provider must not hand out a new publisher: the
    /// settings made before the swap would never hear of a change again.
    private let relay = ChangeRelay()

    public init(
        with settingsProvider: SettingsStorageProvider = UserDefaultsSettingsStorageProvider(),
        secureSettingsProvider: SecureSettingsStorageProvider = KeychainSecureSettingsStorageProvider()
    ) {
        self.settingsProvider = settingsProvider
        self.secureSettingsProvider = secureSettingsProvider
        relay.settingsChanges = relay.forward(settingsProvider.changes)
        relay.secureChanges = relay.forward(secureSettingsProvider.changes)
    }

    /// Publishes the key name whenever any value changes in either backing provider.
    ///
    /// A subscriber keeps the relay, and so the providers' forwarding, alive:
    /// releasing the store does not silence a publisher someone still holds.
    public var changes: AnyPublisher<String, Never> {
        let relay = relay
        return relay.subject
            .map { name in withExtendedLifetime(relay) { name } }
            .eraseToAnyPublisher()
    }

    /// The provider non-secure keys go to now.
    public var settingsStorageProvider: SettingsStorageProvider { settingsProvider }

    /// The provider secure keys go to now.
    public var secureSettingsStorageProvider: SecureSettingsStorageProvider { secureSettingsProvider }

    /// Sends every non-secure key to `provider` from now on.
    ///
    /// The store stays the same object, so every `UserSetting` already made
    /// keeps working: it reads through the new provider on its next change. A
    /// provider that wraps the old one (`RoutedSettingsStorageProvider` does)
    /// reads `settingsStorageProvider` before installing itself.
    public func installSettingsProvider(_ provider: SettingsStorageProvider) {
        settingsProvider = provider
        relay.settingsChanges = relay.forward(provider.changes)
    }

    /// Sends every secure key to `provider` from now on, as
    /// ``installSettingsProvider(_:)`` does for the non-secure keys.
    public func installSecureSettingsProvider(_ provider: SecureSettingsStorageProvider) {
        secureSettingsProvider = provider
        relay.secureChanges = relay.forward(provider.changes)
    }

    public func get<Value: Codable & Sendable>(_ key: any StorableSetting<Value>) -> Value {
        storageProvider(for: key).get(key)
    }

    public func set<Value>(_ value: Value, for key: any StorableSetting<Value>)
    where Value: Decodable, Value: Encodable, Value: Sendable {
        storageProvider(for: key).set(value, for: key)
    }

    public func remove<Value>(_ key: any StorableSetting<Value>)
    where Value: Decodable, Value: Encodable, Value: Sendable {
        storageProvider(for: key).remove(key)
    }

    public func contains<Value>(_ key: any StorableSetting<Value>) -> Bool
    where Value: Decodable, Value: Encodable, Value: Sendable {
        storageProvider(for: key).contains(key)
    }

    /// Non-secure keys only: secure values are never enumerated.
    public func keys(withPrefix prefix: String) -> [String] {
        settingsProvider.keys(withPrefix: prefix)
    }
}

extension SettingsStore {
    private func storageProvider<Value>(for key: any StorableSetting<Value>) -> SettingsStorageProvider {
        key.isSecure ? secureSettingsProvider : settingsProvider
    }

}

/// The store's one change subject and the subscriptions that feed it.
///
/// Owned by the store and by every subscriber to `changes`, so the forwarding
/// lives exactly as long as someone can still hear it.
@MainActor
private final class ChangeRelay {
    let subject = PassthroughSubject<String, Never>()
    var settingsChanges: AnyCancellable?
    var secureChanges: AnyCancellable?

    func forward(_ publisher: AnyPublisher<String, Never>) -> AnyCancellable {
        let subject = subject
        return publisher.sink { name in subject.send(name) }
    }
}
