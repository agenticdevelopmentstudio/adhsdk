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
    public static var shared = UserSettings() {
        didSet { sharedRelay.follow(shared) }
    }

    /// The changes of whichever store is ``shared`` now: a key name when that
    /// store changes a value, and `nil` when ``shared`` itself is replaced, so
    /// every key may hold a different value.
    ///
    /// A mirror of a setting subscribes here rather than to one store's
    /// ``SettingsStore/changes``. Subscribed to the store that happened to be
    /// `shared` when the mirror was made, it would stay bound to that store
    /// after `shared` was replaced, and never again see a write.
    public static var sharedChanges: AnyPublisher<String?, Never> {
        sharedRelay.subject.eraseToAnyPublisher()
    }

    private static let sharedRelay = SharedStoreRelay(following: shared)

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

/// Forwards the current ``UserSettings/shared`` store's changes, and announces
/// each replacement of it, for ``UserSettings/sharedChanges``.
@MainActor
private final class SharedStoreRelay {
    let subject = PassthroughSubject<String?, Never>()
    private var cancellable: AnyCancellable?

    init(following store: UserSettings) {
        cancellable = Self.forward(store, to: subject)
    }

    func follow(_ store: UserSettings) {
        cancellable = Self.forward(store, to: subject)
        subject.send(nil)
    }

    private static func forward(_ store: UserSettings,
                                to subject: PassthroughSubject<String?, Never>) -> AnyCancellable {
        store.changes.sink { subject.send($0) }
    }
}
