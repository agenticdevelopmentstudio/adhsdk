import AgenticDeveloperHubSDKCore
import Foundation

/// The suite's shared settings in one app: the theme, the terminal's four
/// settings and the AI provider configurations (`SharedSettingKeys.all`) go
/// to `backend` (adhd's), every other key stays in the app's own store, and
/// the AI providers' secrets move to the studio's shared Keychain group.
///
/// Built the same way by the Kitchen, ADTerminal, ADNotes, ADGit and
/// ADBrowser, so the five follow one theme. Which launches build one is the
/// caller's choice (adh-daemon's `SharedAppSettings.install(over:)`): Debug
/// only, and never under `APP_TEST_HOME`, since a Release build keeps its
/// own settings until the release cutover and a test run must not change the
/// owner's theme in every other app.
@MainActor
public final class SharedAppSettings {
    /// The provider `UserSettings.shared` now answers through.
    public let provider: RoutedSettingsStorageProvider
    private var loadTask: Task<Void, Never>?

    /// Installs the routed provider over `UserSettings.shared`'s current one
    /// and the shared Keychain group for the AI secrets. Until `start()` has
    /// loaded the backend's values, a routed key reads the app's own value,
    /// so an app that cannot reach adhd still looks as it did.
    public init(backend: SharedSettingsBackend) {
        let provider = RoutedSettingsStorageProvider(
            routed: .all, backend: backend, fallback: UserSettings.shared.settingsStorageProvider)
        self.provider = provider
        UserSettings.install(routedProvider: provider)
        AIProviderConfigStore.useSharedKeychainGroup(
            KeychainHelper.entitledAccessGroup(SharedGroupAIProviderKeychain.groupName))
    }

    /// Loads the backend's values, then follows its changes, retrying the
    /// load every `interval` until it succeeds or `stop()` is called. Each
    /// failure goes to `onFailure`.
    public func start(every interval: Duration = .seconds(2), onFailure: @escaping (any Error) -> Void) {
        guard loadTask == nil else { return }
        let provider = provider
        loadTask = Task { @MainActor in
            while !Task.isCancelled {
                do {
                    try await provider.start()
                    return
                } catch {
                    onFailure(error)
                    try? await Task.sleep(for: interval)
                }
            }
        }
    }

    /// Stops loading and following. The values already loaded keep answering.
    public func stop() {
        loadTask?.cancel()
        provider.stop()
    }

    /// Returns when every shared setting written so far has reached the
    /// backend.
    public func terminate() async {
        await provider.waitForPendingWrites()
    }
}
