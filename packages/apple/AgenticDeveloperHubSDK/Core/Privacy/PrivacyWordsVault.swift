import Combine
import Foundation

/// The privacy words while the app is running: read from the keychain when a
/// private terminal first needs them, held in memory and nowhere else.
///
/// One per app, shared by every private terminal, so an edit applies to all
/// of them at once. Reading the words to run a terminal never prompts;
/// *seeing* them does. Showing a terminal and opening the editor each go
/// through ``authenticate(reason:)``; the editor saves with ``save(_:)``,
/// which does not ask again — the editor was opened by whoever proved they
/// may see the words.
///
/// Private terminals read ``filter``: the enabled global words. A web
/// browser pane reads ``filter(forPane:)``: those plus its own enabled
/// words (``PrivacyWord``).
///
/// Every app that shares the keychain item keeps its own vault, so a save
/// announces itself with a distributed notification and every other vault
/// that holds the words reads them again — an edit in one app conceals in all
/// of them, and an editor opened in another starts from it rather than
/// writing back a list from before it. The notification names no words.
@MainActor
public final class PrivacyWordsVault: ObservableObject {

    public let store: PrivacyWordStore

    /// Every stored word, enabled or not, global or a pane's, or nil while
    /// they have not been read. What the editor shows and what a browser pane
    /// watches.
    @Published public private(set) var words: [PrivacyWord]?

    /// The enabled global words as a filter — what applies everywhere, and
    /// what a private terminal conceals with — or nil while the words have not
    /// been read. Set together with ``words``.
    @Published public private(set) var filter: TextSubstitutionFilter?

    public var isLoaded: Bool { words != nil }

    /// The words that apply in the browser pane `paneID` — the enabled global
    /// words and that pane's own enabled words — or nil while the words have
    /// not been read. `nil` for `paneID` gives ``filter``.
    public func filter(forPane paneID: String?) -> TextSubstitutionFilter? {
        words?.filter(forPane: paneID)
    }

    /// The upgrade in progress, so private terminals starting together share
    /// one prompt rather than stacking one each.
    private var pendingUpgrade: Task<Void, Error>?

    nonisolated(unsafe) private var changeObserver: NSObjectProtocol?

    public init(store: PrivacyWordStore) {
        self.store = store
        let ownProcess = Self.processTag
        changeObserver = DistributedNotificationCenter.default().addObserver(
            forName: Self.changedNotification(for: store), object: nil, queue: .main
        ) { [weak self] note in
            guard note.object as? String != ownProcess else { return }
            MainActor.assumeIsolated { self?.reloadIfLoaded() }
        }
    }

    deinit {
        if let changeObserver { DistributedNotificationCenter.default().removeObserver(changeObserver) }
    }

    /// Posted, across processes, when `store`'s words are saved.
    public static func changedNotification(for store: PrivacyWordStore) -> Notification.Name {
        Notification.Name("\(store.service).\(store.account).changed")
    }

    private static let processTag = String(ProcessInfo.processInfo.processIdentifier)

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

    /// Authenticates the user — every call prompts: this is what stands
    /// between the words and someone else at the keyboard, so success is never
    /// remembered — and makes sure the words are in memory. Words still under
    /// the old guard are read with that authentication and saved again
    /// without it, so they never need it to be read again.
    public func authenticate(reason: String) async throws {
        let context = try await PrivacyWordStore.authenticate(reason: reason)
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
    }

    /// Makes sure the words are in memory, for running a terminal. Silent,
    /// except for words still under the old guard: those ask once — saying
    /// so, since the user is not opening anything — and are saved again
    /// without it, so no later start asks.
    public func loadUpgradingIfNeeded() async throws {
        if try load() { return }
        if let pendingUpgrade { return try await pendingUpgrade.value }
        let task = Task {
            try await self.authenticate(
                reason: "upgrade how the privacy words are stored. This is asked once")
        }
        pendingUpgrade = task
        defer { pendingUpgrade = nil }
        try await task.value
    }

    /// Stores `words` in the keychain and applies them, dropping any with an
    /// empty side (which ``TextSubstitutionFilter`` would ignore anyway).
    /// Does not authenticate: the caller is the editor, which
    /// ``authenticate(reason:)`` opened.
    public func save(_ words: [PrivacyWord]) throws {
        let kept = words.filter { !$0.alias.isEmpty && !$0.real.isEmpty }
        try persist(kept)
        apply(kept)
    }

    private func apply(_ words: [PrivacyWord]) {
        self.words = words
        self.filter = words.filter(forPane: nil)
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
