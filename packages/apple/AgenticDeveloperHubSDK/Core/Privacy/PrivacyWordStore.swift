import Foundation
import LocalAuthentication
import Security

/// One privacy word as the keychain holds it: the pair, whether it is
/// applied at all, and where.
///
/// - `isEnabled`: off keeps the word in the list but applies it nowhere.
/// - `sites`: the site patterns it applies on (``PrivacySitePattern``); `*`
///   is everywhere, private terminals included. Never empty: a word with no
///   sites would be concealed nowhere while it still reads as enabled, so no
///   sites at all (an emptied editor cell, a stored `[]`) becomes `*`
///   (``PrivacySitePattern/normalized(_:)``).
///
/// **The JSON is load-bearing**: it is what the keychain item already holds,
/// and other apps signed by the team read it. Words saved before `sites`
/// existed decode from the old fields: bare `{"alias", "real"}` objects and
/// global words become `*`, and so do words that belonged to one browser pane
/// (`"global": false, "pane": …`) — a pane cannot be mapped to a site, and
/// concealing more is the safe direction.
///
/// **Concealing more is also the rule across versions, both ways.** Saving
/// writes `sites` beside `alias`, `real`, `enabled` and `"global": true`, and
/// never a `pane`. A build from before `sites` therefore applies every word
/// everywhere: the pane-era builds read `global` (a missing one reads as true
/// too), and the builds before them read the pair alone. Writing `global` as
/// whether `sites` holds `*` would make a pane-era build conceal a site word
/// nowhere, not even on its site. The other way, a build from before `sites`
/// that saves the list writes each word back without the key it does not
/// know, so the word decodes here as `*`: its sites are lost, but it is
/// concealed on every page instead of on none. Nothing this build writes can
/// stop an older writer dropping a key, so both directions widen and neither
/// narrows.
public struct PrivacyWord: Sendable, Equatable, Hashable, Codable {
    /// What the user writes and reads.
    public var alias: String
    /// What the program is given and prints.
    public var real: String
    public var isEnabled: Bool
    public var sites: [String] {
        didSet { sites = PrivacySitePattern.normalized(sites) }
    }

    public init(
        alias: String, real: String, isEnabled: Bool = true, sites: [String] = [PrivacySitePattern.everywhere]
    ) {
        self.alias = alias
        self.real = real
        self.isEnabled = isEnabled
        self.sites = PrivacySitePattern.normalized(sites)
    }

    /// The word as a substitution pair.
    public var pair: TextSubstitutionFilter.Pair { .init(alias: alias, real: real) }

    /// Whether the word applies everywhere, private terminals included.
    public var isEverywhere: Bool { sites.contains(PrivacySitePattern.everywhere) }

    /// Whether the word applies at `url`; `nil` asks for a place with no
    /// address (a private terminal), where only `*` words apply.
    public func applies(at url: URL?) -> Bool {
        guard isEnabled else { return false }
        return sites.contains { PrivacySitePattern.matches($0, url: url) }
    }

    private enum CodingKeys: String, CodingKey {
        case alias, real, sites
        case isEnabled = "enabled"
        case isGlobal = "global"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alias = try container.decode(String.self, forKey: .alias)
        real = try container.decode(String.self, forKey: .real)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        // Before `sites`, global and pane words alike become `*`; so does a
        // stored `[]`, which an earlier editor could save.
        sites = PrivacySitePattern.normalized(
            try container.decodeIfPresent([String].self, forKey: .sites) ?? [PrivacySitePattern.everywhere])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(alias, forKey: .alias)
        try container.encode(real, forKey: .real)
        try container.encode(isEnabled, forKey: .isEnabled)
        // Always true, for older builds (see the type's doc); never read here.
        try container.encode(true, forKey: .isGlobal)
        try container.encode(sites, forKey: .sites)
    }
}

extension Array where Element == PrivacyWord {

    /// The enabled words that apply at `url`, as one filter. `nil` gives the
    /// enabled `*` words alone: what a private terminal uses.
    public func filter(for url: URL?) -> TextSubstitutionFilter {
        TextSubstitutionFilter(pairs: self.filter { $0.applies(at: url) }.map(\.pair))
    }

    /// Every enabled word whatever its sites, as one filter: what conceals a
    /// list that spans sites, such as the browser's history, where the words
    /// of the page in front are not the words of each line.
    public var everySiteFilter: TextSubstitutionFilter {
        TextSubstitutionFilter(pairs: self.filter(\.isEnabled).map(\.pair))
    }
}

/// The privacy words (``PrivacyWord``) kept in the keychain and nowhere
/// else: no defaults, no database, no file.
///
/// One item, its value the words as JSON, readable by the apps in its access
/// group without a prompt while the Mac is unlocked. That is deliberate: a
/// private terminal needs the words from its first byte — they are what
/// conceals its output — so starting one must not ask. What asks is the app:
/// showing a private terminal and opening the words editor each take
/// ``authenticate(reason:)`` first. Saving from an editor that was opened
/// that way does not ask again.
///
/// Items saved before that were guarded by `userPresence`, which the keychain
/// will not hand over silently. ``load(context:)`` without a context reports
/// one as ``StoreError/needsAuthentication``; read with an authenticated
/// context and saved again, it is rewritten without the guard.
///
/// `ThisDeviceOnly` and never synchronizable: the words name the user, and
/// they stay on the Mac they were typed on.
///
/// The access group is the caller's, because it is what lets several apps
/// signed by one team share the list, and which group that is belongs to the
/// app's entitlements, not to this type (`dependency-injection`). Access
/// control needs the data-protection keychain, so the binary must carry a
/// `keychain-access-groups` entitlement either way.
public struct PrivacyWordStore: Sendable {

    public enum StoreError: Error, LocalizedError, Equatable {
        case authenticationFailed(String)
        /// The item is still guarded by `userPresence` and cannot be read
        /// without authenticating.
        case needsAuthentication
        case keychain(OSStatus)
        case unreadable

        public var errorDescription: String? {
            switch self {
            case .authenticationFailed(let reason): reason
            case .needsAuthentication: "The privacy words need you to authenticate once before they can be read."
            case .keychain(let status):
                (SecCopyErrorMessageString(status, nil) as String?) ?? "Keychain error \(status)."
            case .unreadable: "The privacy words in the keychain could not be read."
            }
        }
    }

    public let accessGroup: String?
    public let service: String
    public let account: String

    public init(
        accessGroup: String?,
        service: String = "com.agenticdevelopmentstudio.privacy-words",
        account: String = "privacy-words"
    ) {
        self.accessGroup = accessGroup
        self.service = service
        self.account = account
    }

    /// Asks the user to prove they are the Mac's owner — Touch ID, or the
    /// account password — and returns the context that proved it.
    public static func authenticate(reason: String) async throws -> LAContext {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw StoreError.authenticationFailed(
                error?.localizedDescription ?? "This Mac cannot authenticate its owner.")
        }
        nonisolated(unsafe) let unsafeContext = context
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            unsafeContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: StoreError.authenticationFailed(
                        error?.localizedDescription ?? "Authentication failed."))
                }
            }
        }
        return context
    }

    /// The stored words. Empty when nothing has been saved yet.
    ///
    /// - Parameter context: An authenticated context, for reading an item
    ///   saved under the old `userPresence` guard. Without one the read never
    ///   prompts, and such an item throws ``StoreError/needsAuthentication``.
    public func load(context: LAContext? = nil) throws -> [PrivacyWord] {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let silent = LAContext()
        silent.interactionNotAllowed = true
        query[kSecUseAuthenticationContext as String] = context ?? silent
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        if status == errSecInteractionNotAllowed || status == errSecAuthFailed { throw StoreError.needsAuthentication }
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
        guard let data = result as? Data,
              let words = try? JSONDecoder().decode([PrivacyWord].self, from: data) else {
            throw StoreError.unreadable
        }
        return words
    }

    /// Replaces the stored words. An empty list removes the item.
    public func save(_ words: [PrivacyWord]) throws {
        let deleted = SecItemDelete(baseQuery as CFDictionary)
        guard deleted == errSecSuccess || deleted == errSecItemNotFound else {
            throw StoreError.keychain(deleted)
        }
        guard !words.isEmpty else { return }

        var query = baseQuery
        query[kSecValueData as String] = try JSONEncoder().encode(words)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        query[kSecAttrLabel as String] = "Privacy words"
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
    }

    private var baseQuery: [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrSynchronizable as String: false
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }
}
