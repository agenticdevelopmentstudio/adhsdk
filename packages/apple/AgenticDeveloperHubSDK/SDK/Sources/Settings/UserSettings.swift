//
//  UserSettings.swift
//  AgenticDeveloperHubSDK
//
//  Created by Mike Fullerton on 4/27/26.
//
import Foundation
import Combine

@MainActor
public class UserSettings: SettingsStore {
    /// Client apps should create and set this
    public static var shared = UserSettings()

    /// Sends the shared store's non-secure keys to `routedProvider`.
    ///
    /// For a provider that serves some keys from elsewhere (the suite's
    /// shared settings, through adhd) and passes the rest to the provider it
    /// wraps: build it over `shared.settingsStorageProvider`, then install it.
    /// `shared` stays the same instance, so settings made before the install
    /// keep working and hear its changes.
    public static func install(routedProvider: SettingsStorageProvider) {
        shared.installSettingsProvider(routedProvider)
    }

    /// Sends the shared store's secure keys to `secureProvider`, as
    /// ``install(routedProvider:)`` does for the non-secure ones.
    public static func install(secureProvider: SecureSettingsStorageProvider) {
        shared.installSecureSettingsProvider(secureProvider)
    }
}

extension StorableSetting {
    public var value: Value {
        get { UserSettings.shared.get(self) }
        nonmutating set { UserSettings.shared.set(newValue, for: self) }
    }

    public func remove() {
        UserSettings.shared.remove(self)
    }

    public func existsInStore() -> Bool {
        UserSettings.shared.contains(self)
    }
}
