import Foundation
import LocalAuthentication

/// Where the privacy words (``PrivacyWord``) are kept: the one seam between
/// ``PrivacyWordsVault`` and a backing store (`dependency-injection`).
///
/// - ``PrivacyWordStore``: the keychain. What every shipping build uses.
/// - ``JSONFilePrivacyWordStore``: a JSON file of fake words, for exercising
///   every privacy word feature end to end in a Debug build
///   (``PrivacyTestingWords``) without touching the real words.
/// - ``InMemoryPrivacyWordStore``: nothing on disk, for unit tests.
///
/// The file and the keychain hold the same JSON (`[PrivacyWord]`), so a file
/// of testing words is written exactly as the keychain item is.
public protocol PrivacyWordStorage: Sendable {

    /// The stored words; empty when nothing has been saved yet.
    ///
    /// - Parameter context: An authenticated context, for a store whose item
    ///   can be guarded (the keychain's old `userPresence` items). A store
    ///   that cannot be guarded ignores it. Without one a read never prompts,
    ///   and a guarded item throws ``PrivacyWordStore/StoreError/needsAuthentication``.
    func load(context: LAContext?) throws -> [PrivacyWord]

    /// Replaces the stored words. An empty list leaves the store empty.
    func save(_ words: [PrivacyWord]) throws

    /// Names this store's words across processes: every vault over the same
    /// words posts and hears the same change notification, and vaults over
    /// different stores never hear each other.
    var changeIdentity: String { get }
}

extension PrivacyWordStorage {
    /// Reads without prompting.
    public func load() throws -> [PrivacyWord] { try load(context: nil) }
}

/// Proves the person at the keyboard is the Mac's owner before the words are
/// shown — the vault's one prompt — and hands back the context that proved
/// it, which reads a keychain item still under the old guard.
public protocol PrivacyOwnerAuthenticating: Sendable {
    func authenticate(reason: String) async throws -> LAContext?
}

/// Touch ID or the account password, through LocalAuthentication. The prompt
/// is announced (``SystemAuthenticationPrompt``) for as long as it is up, so
/// an app-modal window steps aside for it instead of leaving it behind,
/// unanswerable.
public struct SystemOwnerAuthenticator: PrivacyOwnerAuthenticating {
    public init() {}

    public func authenticate(reason: String) async throws -> LAContext? {
        await MainActor.run { SystemAuthenticationPrompt.begin() }
        do {
            let context = try await PrivacyWordStore.authenticate(reason: reason)
            await MainActor.run { SystemAuthenticationPrompt.end() }
            return context
        } catch {
            await MainActor.run { SystemAuthenticationPrompt.end() }
            throw error
        }
    }
}

/// Never prompts, and always succeeds. Only for words that are not real —
/// testing words (``PrivacyTestingWords``) and unit tests — where a prompt
/// would stop the automation that is the point of them, and there is nothing
/// for it to protect.
public struct UnattendedOwnerAuthenticator: PrivacyOwnerAuthenticating {
    public init() {}

    public func authenticate(reason: String) async throws -> LAContext? { nil }
}

/// Privacy words in a JSON file: `[PrivacyWord]`, the keychain item's own
/// encoding, so a hand-written file reads exactly as saved words do — a bare
/// `{"alias", "real"}` is an enabled word on `*`.
///
/// A missing file is no words. A file that is there but is not that JSON
/// throws ``PrivacyWordStore/StoreError/unreadable`` rather than reading as
/// empty: an empty list conceals nothing, and a typo in a fixture must fail
/// the run, not pass it unconcealed (`fail-fast`). Saving writes the file
/// atomically, pretty-printed and with sorted keys so a test can diff it.
public struct JSONFilePrivacyWordStore: PrivacyWordStorage {

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL.standardizedFileURL
    }

    public var changeIdentity: String { "file:\(fileURL.path)" }

    public func load(context: LAContext? = nil) throws -> [PrivacyWord] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile, CocoaError.fileNoSuchFile {
            return []
        }
        guard let words = try? JSONDecoder().decode([PrivacyWord].self, from: data) else {
            throw PrivacyWordStore.StoreError.unreadable
        }
        return words
    }

    public func save(_ words: [PrivacyWord]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(words).write(to: fileURL, options: .atomic)
    }
}

/// Privacy words in memory and nowhere else, for unit tests. A class so the
/// copies a vault and a test hold see one list; `requiresAuthentication`
/// stands in for a keychain item under the old guard.
public final class InMemoryPrivacyWordStore: PrivacyWordStorage, @unchecked Sendable {

    private let lock = NSLock()
    private var stored: [PrivacyWord]
    private var guarded: Bool
    private var saves = 0

    public let changeIdentity: String

    /// - Parameters:
    ///   - words: what is stored to begin with.
    ///   - requiresAuthentication: reads without a context throw
    ///     ``PrivacyWordStore/StoreError/needsAuthentication`` until the next
    ///     save, as a keychain item under the old guard does.
    public init(words: [PrivacyWord] = [], requiresAuthentication: Bool = false,
                changeIdentity: String = "memory:\(UUID().uuidString)") {
        stored = words
        guarded = requiresAuthentication
        self.changeIdentity = changeIdentity
    }

    public var words: [PrivacyWord] { lock.withLock { stored } }

    /// How many times ``save(_:)`` ran.
    public var saveCount: Int { lock.withLock { saves } }

    public func load(context: LAContext? = nil) throws -> [PrivacyWord] {
        try lock.withLock {
            if guarded && context == nil { throw PrivacyWordStore.StoreError.needsAuthentication }
            return stored
        }
    }

    public func save(_ words: [PrivacyWord]) throws {
        lock.withLock {
            stored = words
            guarded = false
            saves += 1
        }
    }

    /// Replaces the words as another process would, without the vault.
    public func replaceFromOutside(_ words: [PrivacyWord]) {
        lock.withLock { stored = words }
    }
}
