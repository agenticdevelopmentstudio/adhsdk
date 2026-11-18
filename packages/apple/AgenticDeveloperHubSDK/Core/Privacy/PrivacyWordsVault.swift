import Combine
import Foundation
import LocalAuthentication

/// The privacy words while the app is running: read from their store when a
/// private terminal first needs them, held in memory and nowhere else.
///
/// One per app, shared by every private terminal, so an edit applies to all
/// of them at once. Reading the words to run a terminal never prompts;
/// *seeing* them does, and the vault enforces it rather than trusting its
/// callers to: ``authenticate(reason:)`` returns a ``PrivacyWordsGrant``, and
/// the words for display (``words(with:)``) and every save (``save(_:with:)``)
/// need one. A grant proves the owner authenticated for one store's words, so
/// ``replaceStore(_:authenticator:)`` revokes every grant (``grantGeneration``)
/// and whatever was showing under one hides until the owner authenticates
/// again — switching from testing words to the real ones never shows the real
/// ones on the strength of the testing words' no-prompt answer.
///
/// A private terminal reads ``filter(forTerminalAt:)`` with the directory it
/// started in: the enabled words whose terminals match it. ``filter`` is the
/// enabled words whose sites are `*`. A web browser pane reads ``filter(for:)`` with its page's address: the
/// enabled words whose sites match it (``PrivacyWord``).
///
/// Where the words live and who is asked before they are shown are both
/// handed in (``PrivacyWordStorage``, ``PrivacyOwnerAuthenticating``): the
/// keychain and Touch ID in every shipping build, a file of testing words and
/// no prompt for a Debug build exercising the features end to end
/// (``PrivacyTestingWords``), memory and a scripted answer in unit tests.
/// ``replaceStore(_:authenticator:)`` swaps both while the app runs.
///
/// Every app that shares a store keeps its own vault, so a save announces
/// itself with a distributed notification and every other vault that holds
/// the words reads them again — an edit in one app conceals in all of them,
/// and an editor opened in another starts from it rather than writing back a
/// list from before it. The notification names no words.
@MainActor
public final class PrivacyWordsVault: ObservableObject {

    /// Where the words are read from and saved to.
    public private(set) var store: any PrivacyWordStorage

    /// Who is asked before the words are shown.
    public private(set) var authenticator: any PrivacyOwnerAuthenticating

    /// Every stored word, enabled or not, whatever its sites, or nil while
    /// they have not been read. What a browser pane filters with — never what
    /// is shown: a view of the words reads ``words(with:)``.
    @Published public private(set) var words: [PrivacyWord]?

    /// Changes whenever every outstanding grant is revoked — on
    /// ``replaceStore(_:authenticator:)``. Whatever shows words or concealed
    /// content under a grant watches it and hides when it changes.
    @Published public private(set) var grantGeneration = 0

    /// The enabled global words as a filter — what applies everywhere, and
    /// what a private terminal conceals with — or nil while the words have not
    /// been read. Set together with ``words``.
    @Published public private(set) var filter: TextSubstitutionFilter?

    public var isLoaded: Bool { words != nil }

    /// The enabled words whose sites match `url`, or nil while the words have
    /// not been read. `nil` for `url` gives ``filter``.
    public func filter(for url: URL?) -> TextSubstitutionFilter? {
        words?.filter(for: url)
    }

    /// The words for a private terminal started in `directory`
    /// (``PrivacyWord/terminals``), or `nil` while the words have not been read.
    public func filter(forTerminalAt directory: String?) -> TextSubstitutionFilter? {
        words?.filter(forTerminalAt: directory)
    }

    /// Every enabled word whatever its sites, or nil while the words have not
    /// been read (``PrivacyWord`` array's `everySiteFilter`).
    public var everySiteFilter: TextSubstitutionFilter? {
        words?.everySiteFilter
    }

    /// The upgrade in progress, so private terminals starting together share
    /// one prompt rather than stacking one each.
    private var pendingUpgrade: Task<Void, Error>?

    nonisolated(unsafe) private var changeObserver: NSObjectProtocol?

    public init(
        store: any PrivacyWordStorage,
        authenticator: any PrivacyOwnerAuthenticating = SystemOwnerAuthenticator()
    ) {
        self.store = store
        self.authenticator = authenticator
        observeChanges()
    }

    deinit {
        if let changeObserver { DistributedNotificationCenter.default().removeObserver(changeObserver) }
    }

    /// Posted, across processes, when `store`'s words are saved:
    /// `<changeIdentity>.changed`, which for the keychain is the
    /// `service.account.changed` every sharing app already listens for.
    public nonisolated static func changedNotification(for store: any PrivacyWordStorage) -> Notification.Name {
        Notification.Name("\(store.changeIdentity).changed")
    }

    private static let processTag = String(ProcessInfo.processInfo.processIdentifier)

    /// Moves the vault onto other words: `store` from now on, asked about
    /// through `authenticator`. Words already in memory are replaced by
    /// `store`'s at once — every pane and terminal watching ``words`` follows
    /// — and words never read stay unread. If `store`'s words cannot be read
    /// silently, the old ones are dropped rather than left showing as if they
    /// were the new store's: the vault goes back to unread, and the next
    /// ``authenticate(reason:)`` reads them. Every grant is revoked first.
    public func replaceStore(
        _ store: any PrivacyWordStorage,
        authenticator: any PrivacyOwnerAuthenticating
    ) {
        let wasLoaded = isLoaded
        pendingUpgrade = nil
        self.store = store
        self.authenticator = authenticator
        // Before the words change: what proved access to the old words proves
        // nothing about the new ones.
        grantGeneration += 1
        observeChanges()
        guard wasLoaded else { return }
        do {
            apply(try store.load())
        } catch {
            words = nil
            filter = nil
        }
    }

    private func observeChanges() {
        if let changeObserver { DistributedNotificationCenter.default().removeObserver(changeObserver) }
        let ownProcess = Self.processTag
        changeObserver = DistributedNotificationCenter.default().addObserver(
            forName: Self.changedNotification(for: store), object: nil, queue: .main
        ) { [weak self] note in
            guard note.object as? String != ownProcess else { return }
            MainActor.assumeIsolated { self?.reloadIfLoaded() }
        }
    }

    /// Reads the words without prompting, if they are not in memory yet.
    /// Returns whether they are now — false only for words still saved under
    /// the old `userPresence` guard, which wait for ``authenticate(reason:)``.
    @discardableResult
    public func load() throws -> Bool {
        if isLoaded { return true }
        do {
            apply(try store.load())
            return true
        } catch PrivacyWordStore.StoreError.needsAuthentication {
            return false
        }
    }

    /// Authenticates the user — every call asks the authenticator: this is
    /// what stands between the words and someone else at the keyboard, so
    /// success is never remembered — makes sure the words are in memory, and
    /// returns the grant that shows and saves them. Words still under the old
    /// guard are read with that authentication and saved again without it, so
    /// they never need it to be read again.
    ///
    /// - Throws: ``PrivacyWordsGrant/Revoked`` when the store changed while
    ///   the prompt was up: what was proved was the right to see the old
    ///   words, and the new ones need an authentication of their own.
    @discardableResult
    public func authenticate(reason: String) async throws -> PrivacyWordsGrant {
        let store = self.store
        let generation = grantGeneration
        let context = try await authenticator.authenticate(reason: reason)
        guard generation == grantGeneration, store.changeIdentity == self.store.changeIdentity else {
            throw PrivacyWordsGrant.Revoked()
        }
        do {
            // Read again even when already in memory: whoever authenticates
            // is about to see or replace the words, and another app may have
            // saved since.
            apply(try store.load())
        } catch PrivacyWordStore.StoreError.needsAuthentication {
            let words = try store.load(context: context)
            try persist(words)
            apply(words)
        }
        return PrivacyWordsGrant(generation: generation, storeIdentity: store.changeIdentity)
    }

    /// Whether `grant` still shows and saves the words: issued for this
    /// store, and not revoked since.
    public func isValid(_ grant: PrivacyWordsGrant) -> Bool {
        grant.generation == grantGeneration && grant.storeIdentity == store.changeIdentity
    }

    /// The words, for showing them: every stored word, or `[]` when there are
    /// none yet.
    ///
    /// - Throws: ``PrivacyWordsGrant/Revoked`` when `grant` no longer holds.
    public func words(with grant: PrivacyWordsGrant) throws -> [PrivacyWord] {
        guard isValid(grant) else { throw PrivacyWordsGrant.Revoked() }
        return words ?? []
    }

    /// Makes sure the words are in memory, for running a terminal. Silent,
    /// except for words still under the old guard: those ask once — saying
    /// so, since the user is not opening anything — and are saved again
    /// without it, so no later start asks.
    public func loadUpgradingIfNeeded() async throws {
        if try load() { return }
        if let pendingUpgrade { return try await pendingUpgrade.value }
        let task = Task {
            _ = try await self.authenticate(
                reason: "upgrade how the privacy words are stored. This is asked once")
        }
        pendingUpgrade = task
        defer { pendingUpgrade = nil }
        try await task.value
    }

    /// Stores `words` and applies them, dropping any with an empty side
    /// (which ``TextSubstitutionFilter`` would ignore anyway). Does not
    /// prompt: `grant` is the authentication.
    ///
    /// - Throws: ``PrivacyWordsGrant/Revoked`` when `grant` no longer holds,
    ///   before anything is written; a store error from the write.
    public func save(_ words: [PrivacyWord], with grant: PrivacyWordsGrant) throws {
        guard isValid(grant) else { throw PrivacyWordsGrant.Revoked() }
        let kept = words.filter { !$0.alias.isEmpty && !$0.real.isEmpty }
        try persist(kept)
        apply(kept)
    }

    private func apply(_ words: [PrivacyWord]) {
        self.words = words
        self.filter = words.filter(for: nil)
    }

    private func persist(_ words: [PrivacyWord]) throws {
        try store.save(words)
        DistributedNotificationCenter.default().postNotificationName(
            Self.changedNotification(for: store), object: Self.processTag, userInfo: nil, deliverImmediately: true)
    }

    /// Another app saved the words. Only words already in memory are read
    /// again — a vault that never needed them has nothing to bring up to date.
    private func reloadIfLoaded() {
        guard isLoaded, let words = try? store.load() else { return }
        apply(words)
    }
}

/// Proof that the Mac owner authenticated to see one store's privacy words:
/// what ``PrivacyWordsVault/words(with:)`` and
/// ``PrivacyWordsVault/save(_:with:)`` ask for. Only
/// ``PrivacyWordsVault/authenticate(reason:)`` makes one, and
/// ``PrivacyWordsVault/replaceStore(_:authenticator:)`` revokes them all.
public struct PrivacyWordsGrant: Equatable, Sendable {

    /// A grant was used after it was revoked, or an authentication finished
    /// after the store it was for was replaced.
    public struct Revoked: LocalizedError, Equatable {
        public var errorDescription: String? {
            "The privacy words changed. Authenticate again to see them."
        }
    }

    let generation: Int
    let storeIdentity: String
}
