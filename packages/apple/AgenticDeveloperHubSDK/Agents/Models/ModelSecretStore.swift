import Foundation
import AgenticDeveloperHubSDKCore
import AIPluginKit

/// Where a model entry's secret field values live, one value per entry and
/// field. The seam tests replace; the live one is `SharedGroupModelSecrets`.
public protocol ModelSecretStore: Sendable {
    func value(for entry: UUID, field: String) -> String?
    func set(_ value: String, for entry: UUID, field: String) throws
    /// Removes the secret; an absent one is not an error.
    func remove(for entry: UUID, field: String) throws
}

public enum ModelSecretStoreError: Error, LocalizedError, Equatable {
    case writeFailed(field: String)
    case removeFailed(field: String)

    public var errorDescription: String? {
        switch self {
        case .writeFailed(let field): return "Could not store the secret '\(field)' in the Keychain"
        case .removeFailed(let field): return "Could not remove the secret '\(field)' from the Keychain"
        }
    }
}

/// The registry's secrets in the studio's shared Keychain group, under the
/// same service and account names the apps' own AI provider settings use
/// (`AIProviderConfigKeys.fieldKey(config:field:)`), so an app that imported a
/// configuration and the daemon read the same item. A write posts the apps'
/// change notification, so an app memoizing a secret re-reads it.
public struct SharedGroupModelSecrets: ModelSecretStore {

    private let keychain: any AIProviderSecretKeychain
    private let changeNotificationName: String?

    /// - Parameters:
    ///   - keychain: where the values go. Nil picks the shared group when this
    ///     process is entitled to it, else the same service in the process's
    ///     own Keychain (a build without the entitlement still works, alone).
    ///   - changeNotificationName: the Darwin notification posted after a
    ///     write; nil posts nothing.
    public init(
        keychain: (any AIProviderSecretKeychain)? = nil,
        changeNotificationName: String? = AIProviderSharedSecretsProvider.changeNotificationName
    ) {
        if let keychain {
            self.keychain = keychain
        } else if let group = KeychainHelper.entitledAccessGroup(SharedGroupAIProviderKeychain.groupName) {
            self.keychain = SharedGroupAIProviderKeychain(accessGroup: group)
        } else {
            self.keychain = ServiceKeychain(service: SharedGroupAIProviderKeychain.service)
        }
        self.changeNotificationName = changeNotificationName
    }

    public func value(for entry: UUID, field: String) -> String? {
        keychain.value(forAccount: AIProviderConfigKeys.fieldKey(config: entry, field: field))
    }

    public func set(_ value: String, for entry: UUID, field: String) throws {
        guard keychain.set(value, forAccount: AIProviderConfigKeys.fieldKey(config: entry, field: field)) else {
            throw ModelSecretStoreError.writeFailed(field: field)
        }
        announce()
    }

    public func remove(for entry: UUID, field: String) throws {
        guard keychain.delete(forAccount: AIProviderConfigKeys.fieldKey(config: entry, field: field)) else {
            throw ModelSecretStoreError.removeFailed(field: field)
        }
        announce()
    }

    private func announce() {
        guard let changeNotificationName else { return }
        DarwinNotificationSignal(name: changeNotificationName).post()
    }

    /// One service in the process's default Keychain, for a binary without the
    /// shared-group entitlement.
    struct ServiceKeychain: AIProviderSecretKeychain {
        let service: String

        func value(forAccount account: String) -> String? {
            KeychainHelper.get(forKey: account, service: service)
        }

        func set(_ value: String, forAccount account: String) -> Bool {
            KeychainHelper.set(value, forKey: account, service: service)
        }

        func delete(forAccount account: String) -> Bool {
            KeychainHelper.delete(forKey: account, service: service)
        }

        func exists(forAccount account: String) -> Bool {
            value(forAccount: account) != nil
        }
    }
}
