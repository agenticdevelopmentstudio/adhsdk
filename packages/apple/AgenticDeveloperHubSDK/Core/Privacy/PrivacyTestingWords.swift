import Combine
import Foundation

extension UserSettings {
    /// Debug builds: conceal with the testing words in
    /// ``privacyTestingWordsPath`` instead of the real ones in the keychain.
    public static let privacyTestingWordsEnabled = UserSetting<Bool>(
        "privacy.testing_words.enabled", default: false)

    /// Debug builds: the JSON file of testing words (`[PrivacyWord]`, the
    /// keychain item's own encoding). `~` is expanded. Created by the first
    /// save from Edit Privacy Words… if it is not there.
    public static let privacyTestingWordsPath = UserSetting<String>(
        "privacy.testing_words.path", default: "")
}

/// Puts a vault on testing words while ``UserSettings/privacyTestingWordsEnabled``
/// is on and ``UserSettings/privacyTestingWordsPath`` names a file, and back
/// on the real words when either goes — live, so every browser pane and
/// private terminal follows the switch.
///
/// The point is end-to-end testing: on testing words every privacy word
/// feature runs exactly as it does on the real ones — the browser's page,
/// title, address and tab names, private terminals, Edit Privacy Words… — but
/// over fake words a test wrote, in a file it can read back, with no Touch ID
/// prompt standing in the way (``UnattendedOwnerAuthenticator``). The real
/// words are never read while it is on. Because the testing words skip the
/// prompt, only a Debug build composes this; a release build has no way onto
/// them (`fail-fast`: a shipping app never silently drops its prompt).
///
/// Both settings are ordinary user settings, so a UI test turns them on with
/// launch arguments (`-privacy.testing_words.enabled "<true/>"
/// -privacy.testing_words.path /x/words.json`) without writing the real
/// preferences.
@MainActor
public final class PrivacyTestingWords {

    /// Whether a running app composed one — what shows the testing words'
    /// rows in Settings. False in every release build.
    public private(set) static var isAvailable = false

    private let vault: PrivacyWordsVault
    private let settings: SettingsStore
    private let realStore: any PrivacyWordStorage
    private let realAuthenticator: any PrivacyOwnerAuthenticating
    private var cancellable: AnyCancellable?

    /// - Parameters:
    ///   - vault: the app's one vault, on the real words.
    ///   - realStore, realAuthenticator: what to go back to when testing
    ///     words are turned off; the vault's own by default.
    public init(
        vault: PrivacyWordsVault,
        settings: SettingsStore = UserSettings.shared,
        realStore: (any PrivacyWordStorage)? = nil,
        realAuthenticator: (any PrivacyOwnerAuthenticating)? = nil
    ) {
        self.vault = vault
        self.settings = settings
        self.realStore = realStore ?? vault.store
        self.realAuthenticator = realAuthenticator ?? vault.authenticator
    }

    /// The testing words file the settings name, or nil when the vault
    /// should be on the real words.
    public static func fileURL(in settings: SettingsStore) -> URL? {
        guard settings.get(UserSettings.privacyTestingWordsEnabled) else { return nil }
        let path = settings.get(UserSettings.privacyTestingWordsPath)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return nil }
        return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    }

    /// Applies the settings now and follows them from here on. Call it right
    /// after making the vault, before anything reads it, so a launch on
    /// testing words never touches the real ones.
    public func start() {
        Self.isAvailable = true
        apply()
        let names: Set<String> = [
            UserSettings.privacyTestingWordsEnabled.name, UserSettings.privacyTestingWordsPath.name
        ]
        cancellable = settings.changes
            .filter { names.contains($0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.apply() } }
    }

    /// Moves the vault onto what the settings say, if it is not there already.
    public func apply() {
        let target: any PrivacyWordStorage
        let authenticator: any PrivacyOwnerAuthenticating
        if let url = Self.fileURL(in: settings) {
            target = JSONFilePrivacyWordStore(fileURL: url)
            authenticator = UnattendedOwnerAuthenticator()
        } else {
            target = realStore
            authenticator = realAuthenticator
        }
        guard target.changeIdentity != vault.store.changeIdentity else { return }
        vault.replaceStore(target, authenticator: authenticator)
    }

    /// Whether the vault is on testing words right now.
    public var isUsingTestingWords: Bool { vault.store.changeIdentity != realStore.changeIdentity }
}
