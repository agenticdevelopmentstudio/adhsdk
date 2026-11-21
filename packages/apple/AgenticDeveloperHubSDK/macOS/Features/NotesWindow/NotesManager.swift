import Foundation
import os
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMarkdown
import AgenticDeveloperHubSDKDatabase

/// Coordinates in-memory note state and storage persistence.
/// All access must happen on the main actor.
@MainActor
public final class NotesManager {

    // MARK: - Observation

    /// Posted after `notes` changes — a create, an edit, a pin toggle, a
    /// delete, or a load. The manager is the sole owner of that array and had
    /// no way to say it had changed, so every view holding one asked its own
    /// caller to remember to call `reload()`: the split view controller does
    /// it after each of its own actions, and anything that mutated notes from
    /// somewhere else (Quick Note's save, a scripting command, a second
    /// window) left every other view stale until it was reopened.
    ///
    /// The notification carries no payload. `object` is the posting manager,
    /// so a host with more than one can tell them apart, and observers read
    /// `notes` from it — a snapshot in `userInfo` would be a second source of
    /// truth that is already stale by the time it is read.
    ///
    /// Posted on the main queue, always, because both the poster and every
    /// observer are `@MainActor`: `NotificationCenter` delivers synchronously
    /// on the posting thread, and this class is main-actor-isolated, so a post
    /// from here is already a main-queue delivery.
    public static let notesDidChangeNotification = Notification.Name(
        "AgenticDeveloperHubSDK.NotesManager.notesDidChange")

    /// Posted when a read or write against storage fails, right after
    /// `storageFailure` is set. Same shape and same reasoning as
    /// `notesDidChangeNotification`: no payload, `object` is the manager, and
    /// delivery is already on the main queue because this class is
    /// `@MainActor` and `NotificationCenter` delivers synchronously.
    ///
    /// A notification rather than a delegate because the manager has more than
    /// one host — a notes window, a notes pane, Quick Note — and a failure
    /// belongs to the manager, not to whichever of them happened to trigger it.
    public static let storageDidFailNotification = Notification.Name(
        "AgenticDeveloperHubSDK.NotesManager.storageDidFail")

    /// Posted when the storage's taxonomy (`NoteTaxonomy`) changed under this
    /// manager — another writer's category edit, or a resync that may have
    /// carried one. Same shape as `notesDidChangeNotification`. The folders
    /// pane reloads its tree on it; this window's own category edits reload it
    /// directly and do not come through here.
    public static let taxonomyDidChangeNotification = Notification.Name(
        "AgenticDeveloperHubSDK.NotesManager.taxonomyDidChange")

    /// Posted when a note's text in `notes` was replaced by another writer's
    /// — a feed upsert, or a stale save that kept the other writer's note —
    /// so a host showing that note in an editor re-shows it.
    ///
    /// `notesDidChangeNotification` cannot carry this: it refreshes lists,
    /// and a list deliberately leaves the editor alone, since most changes it
    /// reports came *from* the editor. Without this the editor kept showing
    /// the old text over a note the manager now held at the other writer's
    /// version, and the next keystroke saved the old text on top of theirs
    /// with no conflict check.
    ///
    /// `userInfo[noteIDUserInfoKey]` is the note's `UUID`; `object` is the
    /// manager. Observers read the note from `notes`.
    public static let noteReplacedNotification = Notification.Name(
        "AgenticDeveloperHubSDK.NotesManager.noteReplaced")

    /// The `userInfo` key of `noteReplacedNotification`: the replaced note's
    /// `UUID`.
    public static let noteIDUserInfoKey = "noteID"

    private func postNotesDidChange() {
        NotificationCenter.default.post(name: Self.notesDidChangeNotification, object: self)
    }

    private func postNoteReplaced(_ id: UUID) {
        NotificationCenter.default.post(
            name: Self.noteReplacedNotification, object: self,
            userInfo: [Self.noteIDUserInfoKey: id])
    }

    // MARK: - State

    public private(set) var notes: [Note] = []
    public private(set) var isLoaded: Bool = false

    /// The last read or write that failed, or `nil` if none has since it was
    /// last cleared.
    ///
    /// It exists because the alternative was worse than no error handling: the
    /// UI went on asserting a write had succeeded. A failed insert left a note
    /// in `notes` and in the sidebar, every keystroke after it scheduled a save
    /// that threw `.notFound`, and the whole session's writing was gone at the
    /// next launch with nothing having said a word. Logging is not a user
    /// interface.
    ///
    /// Deliberately one value, not a queue: a failing database fails every
    /// operation, and the second alert would say the same thing as the first.
    /// Deliberately not an error-reporting framework either — this is the
    /// smallest thing that makes a failed write visible.
    public private(set) var storageFailure: NotesStorageFailure?

    /// Called by whichever host showed the failure, so a second host does not
    /// show it again.
    public func clearStorageFailure() {
        storageFailure = nil
    }

    private func record(_ operation: NotesStorageFailure.Operation, _ error: any Error) {
        logger.error(
            "\(operation.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        storageFailure = NotesStorageFailure(
            operation: operation, message: error.localizedDescription)
        NotificationCenter.default.post(name: Self.storageDidFailNotification, object: self)
    }

    /// The same recording `record(_:_:)` does for this manager's own CRUD
    /// methods, exposed for a caller that wrote to the manager's storage
    /// directly — `NotesSplitViewController.moveSelectedNote(toFolder:)`
    /// writes taxonomy assignments straight to the `MarkdownStore` this
    /// manager wraps, not through any method here, but a failure there is
    /// still a failed write and deserves the same sheet (M2 in the review
    /// this fixes): logged, stashed as `storageFailure`, and announced on
    /// `storageDidFailNotification` so whichever host has a window on screen
    /// can show it.
    public func reportStorageFailure(_ operation: NotesStorageFailure.Operation, _ error: any Error) {
        record(operation, error)
    }

    // MARK: - Dependencies

    /// `nonisolated` so the detached task in `performStorage(_:)` can capture
    /// it without a main-actor hop. Safe because `NoteStorage` is `Sendable`
    /// (M1(b) in the review this fixes) and this is a `let`: the reference
    /// never changes after `init`, only what it points to does I/O.
    private nonisolated let storage: NoteStorage

    /// The storage version of each note's `baseContent`: what the next write
    /// of that note must send as `Note.version`.
    ///
    /// Read and written *inside* the storage chain (`performStorage(_:)`),
    /// not from the snapshot a save was scheduled with. Saves queue behind
    /// one another, so a snapshot taken on the main actor carries the version
    /// from before the save ahead of it in the queue lands, and would be
    /// refused as stale against this manager's own write. The ledger is
    /// updated by that earlier write before the later one reads it.
    ///
    /// It only advances when the manager adopts the matching content: a feed
    /// change skipped because the note is being edited leaves it alone, so
    /// the edit's save is refused as stale and takes Decision 10's path
    /// rather than overwriting the other writer's text.
    private nonisolated let versions = VersionLedger()

    /// A lock-guarded `[UUID: Int64]`, shareable with the detached storage
    /// tasks.
    final class VersionLedger: Sendable {
        private let state = OSAllocatedUnfairLock(initialState: [UUID: Int64]())

        subscript(id: UUID) -> Int64? {
            get { state.withLock { $0[id] } }
            set { state.withLock { $0[id] = newValue } }
        }

        func replaceAll(with notes: [Note]) {
            let map = Dictionary(notes.map { ($0.id, $0.version) }, uniquingKeysWith: max)
            state.withLock { $0 = map }
        }
    }
    /// Per-note debounced autosave.
    ///
    /// The dictionary of per-key `Task`s this used to be lived here, in
    /// `TextDocumentSaveScheduler`, and (in a one-shot variant) in
    /// `SemanticTokenHighlightProvider` — three copies of the same
    /// cancel-and-reschedule-then-flush-once pattern, each independently wrong
    /// in the same place. `KeyedDebouncer` is the extraction; the correction
    /// it carries is that a note whose write *throws* stays pending and is
    /// retried with backoff instead of being dropped with only a log line.
    /// This copy dropped it the same way the editor's did.
    private lazy var saveDebouncer = KeyedDebouncer<UUID>(
        debounce: Self.saveDebounce
    ) { [weak self] _, error in
        self?.record(.save, error)
    }

    /// The tail of the storage queue: the task every next storage call waits
    /// for before it starts. See `performStorage(_:)`.
    private var storageChain: Task<Void, Never> = Task {}

    /// Runs a storage call off the main actor, after every storage call this
    /// manager issued before it.
    ///
    /// Two things have to be true at once, and each is why the other cannot
    /// be dropped.
    ///
    /// **Off the main actor**, because the I/O in `NoteStorage`'s conformers
    /// (`MarkdownNoteStorage`, backed by SQLite) would otherwise block
    /// whichever host — Quick Note, a second notes window, this manager's own
    /// caller — shares the main actor while a note is read or written (M1(b)
    /// in the review this fixes). `storage` is `Sendable`, so capturing it
    /// into a detached task is sound, and awaiting `.value` from a main-actor
    /// caller is what hops the result back for the call sites below to
    /// publish.
    ///
    /// **In issue order**, because the calls are not independent: each writer
    /// hands `updateNote` a *whole* `Note` snapshot taken on the main actor,
    /// so a pin toggle issued after a content save carries the pre-save
    /// content, and landing first would resurrect it. Before the work moved
    /// off the main actor that could not happen — every call ran to
    /// completion with no suspension point, so issue order *was* execution
    /// order — and detaching each call independently silently gave that up.
    /// This restores it: the chain is read and replaced synchronously here on
    /// the main actor, so the order calls line up in is the order they were
    /// issued, and only one of them is ever in flight.
    ///
    /// This orders *this manager's* calls, which is the whole scope of the
    /// snapshot problem today: a snapshot only races writes made from the same
    /// `notes` array, and there is one manager in the process —
    /// `NotesCoordinator` builds it once and gives the same instance to the
    /// notes window and to Quick Note. Should a second writer ever appear, the
    /// chain would not reach it, and neither would fix it: storage makes each
    /// read-merge-write one transaction
    /// (`MarkdownStore.mutateDocument`), which is atomicity, not ordering —
    /// two writers there resolve last-writer-wins over the whole note.
    private func performStorage<Value: Sendable>(
        _ operation: @escaping @Sendable (NoteStorage) async throws -> Value
    ) async throws -> Value {
        let previous = storageChain
        let work = Task.detached { [storage] () async throws -> Value in
            await previous.value
            return try await operation(storage)
        }
        storageChain = Task { _ = try? await work.value }
        return try await work.value
    }

    /// The taxonomy behind this manager's storage, when there is one.
    ///
    /// `NoteStorage` does not know about categories, so this asks whether the
    /// concrete storage backing this manager happens to also be
    /// `NoteTaxonomyProviding` — `MarkdownNoteStorage` is, an in-memory or
    /// file-based test double is not. `nil` here is what keeps the folders
    /// pane optional rather than a hard dependency on a `MarkdownStore`.
    public var taxonomy: (any NoteTaxonomy)? { (storage as? NoteTaxonomyProviding)?.taxonomy }

    /// Debounce interval for auto-save.
    private static let saveDebounce: Duration = .seconds(1)

    // MARK: - Initialization

    public init(storage: NoteStorage) {
        self.storage = storage
        if let observable = storage as? ObservableNoteStorage {
            let stream = observable.changes()
            observation.task = Task { [weak self] in
                for await change in stream {
                    guard let self else { return }
                    await self.apply(change)
                }
            }
        }
    }

    deinit {
        observation.task?.cancel()
    }

    // MARK: - Live changes and conflicts

    /// Holds the feed subscription so the nonisolated `deinit` can cancel it.
    /// A `let` reference to a box rather than a `var Task` because `deinit`
    /// cannot touch main-actor state; the box is written once, in `init`.
    private final class ObservationBox: @unchecked Sendable {
        var task: Task<Void, Never>?
    }
    private let observation = ObservationBox()

    /// The content each note had when it last matched storage — loaded,
    /// created, saved, or replaced from the feed. A stale save compares the
    /// stored content against this to tell "the other writer only bumped the
    /// version" from "the other writer changed the text" (Decision 10).
    private var baseContent: [UUID: String] = [:]

    /// The pin each note had when it last matched storage, kept beside
    /// `baseContent`. A stale save that re-saves on top of the other writer's
    /// version takes their pin unless the pin was toggled here — the other
    /// writer's pin toggle is exactly what bumps a version without its text.
    private var basePinned: [UUID: Bool] = [:]

    /// Notes with an edit not yet saved. A feed change for one of them is not
    /// applied over the editor: its save takes the conflict path instead.
    private var dirty: Set<UUID> = []

    /// Applies one change another writer made.
    func apply(_ change: NoteChange) async {
        switch change {
        case .resync:
            await loadNotes()
            NotificationCenter.default.post(name: Self.taxonomyDidChangeNotification, object: self)
        case .taxonomyChanged:
            NotificationCenter.default.post(name: Self.taxonomyDidChangeNotification, object: self)
        case .deleted(let id):
            guard let held = notes.first(where: { $0.id == id }) else { return }
            if dirty.contains(id) {
                // Typed into and not yet saved: the text becomes a note of
                // its own, as a stale save onto a deleted note does. Stored
                // before the note is dropped, so if the insert fails the note
                // stays, dirty, and its pending save resolves the same way.
                do {
                    try await insertConflictedCopy(following: id, from: held)
                } catch {
                    record(.save, error)
                    return
                }
                saveDebouncer.cancel(key: id)
            }
            forget(id)
            postNotesDidChange()
        case .upserted(let id):
            guard !dirty.contains(id) else { return }
            let fetched: Note?
            do {
                fetched = try await performStorage { try await $0.fetchNote(id: id) }
            } catch {
                record(.load, error)
                return
            }
            // The editor may have been typed into while the read was out.
            guard !dirty.contains(id) else { return }
            guard let fetched else {
                guard notes.contains(where: { $0.id == id }) else { return }
                forget(id)
                postNotesDidChange()
                return
            }
            // At or below what is held: this manager's own echo.
            if let held = versions[id], fetched.version <= held { return }
            let replaced: Bool
            if let idx = notes.firstIndex(where: { $0.id == id }) {
                notes[idx] = fetched
                replaced = true
            } else {
                notes.append(fetched)
                replaced = false
            }
            baseContent[id] = fetched.content
            basePinned[id] = fetched.isPinned
            versions[id] = fetched.version
            notes.sort(by: Note.defaultSort)
            postNotesDidChange()
            // The editor shows the text at the version the ledger now holds,
            // or its next keystroke overwrites this one unchecked.
            if replaced { postNoteReplaced(id) }
        }
    }

    private func forget(_ id: UUID) {
        notes.removeAll(where: { $0.id == id })
        baseContent[id] = nil
        basePinned[id] = nil
        versions[id] = nil
        dirty.remove(id)
    }

    /// Writes `note`, and resolves a stale refusal without losing text.
    private func persist(_ note: Note) async throws {
        do {
            let written = try await write(note, version: nil)
            markSaved(note, version: written)
        } catch NoteStorageError.stale(let current) {
            try await resolveStale(note, current: current)
        }
    }

    /// Updates `note` in storage at `version`, or at the ledger's version
    /// when nil, and records the version the write produced — both inside
    /// the storage chain (see `versions`).
    private func write(_ note: Note, version: Int64?) async throws -> Int64 {
        let ledger = versions
        return try await performStorage { storage in
            var toSave = note
            if let held = version ?? ledger[note.id] { toSave.version = held }
            let written = try await storage.updateNote(toSave)
            ledger[note.id] = written
            return written
        }
    }

    /// Inserts `note` and records its first version.
    private func insert(_ note: Note) async throws -> Int64 {
        let ledger = versions
        return try await performStorage { storage in
            let written = try await storage.insertNote(note)
            ledger[note.id] = written
            return written
        }
    }

    private func markSaved(_ note: Note, version: Int64) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].version = version
        }
        baseContent[note.id] = note.content
        basePinned[note.id] = note.isPinned
        if notes.first(where: { $0.id == note.id })?.content == note.content {
            dirty.remove(note.id)
        }
    }

    /// Decision 10: if storage still holds the text this editor started from,
    /// re-save on top of its version; otherwise keep the other writer's note
    /// and put this editor's text in a new "(conflicted copy)" note.
    private func resolveStale(_ note: Note, current: Note?) async throws {
        var stored = current
        if stored == nil {
            stored = try await performStorage { try await $0.fetchNote(id: note.id) }
        }
        // The editor's text as it stands now, not as `note` captured it: the
        // user may have typed on while the refused write and the re-read were
        // out, and that text is what must not be lost.
        let latest = notes.first(where: { $0.id == note.id }) ?? note
        guard let stored else {
            // Deleted underneath the editor: the editor's text becomes a note
            // of its own rather than vanishing. Not when the note has already
            // left `notes`: then it was deleted here, or the feed's delete
            // already stored its text as a copy (`apply(.deleted)`).
            guard notes.contains(where: { $0.id == note.id }) else { return }
            try await insertConflictedCopy(following: note.id, from: latest)
            forget(note.id)
            postNotesDidChange()
            return
        }
        if stored.content == baseContent[note.id] {
            // Only the version moved (a pin toggle, a hub echo elsewhere):
            // this editor's text still applies on top of it — with the
            // other writer's pin, unless the pin was toggled here.
            var rebased = note
            if note.isPinned == basePinned[note.id] {
                rebased.isPinned = stored.isPinned
            }
            let written = try await write(rebased, version: stored.version)
            markSaved(rebased, version: written)
            if let idx = notes.firstIndex(where: { $0.id == note.id }),
               notes[idx].isPinned != rebased.isPinned {
                notes[idx].isPinned = rebased.isPinned
                notes.sort(by: Note.defaultSort)
                postNotesDidChange()
            }
            return
        }
        let textEdited = latest.content != baseContent[note.id]
        if textEdited {
            // The copy first, the other writer's note second: until the copy
            // is stored, the editor's text lives only in `notes` and on
            // screen, so a failed insert leaves both alone (and the save
            // pending, to come back here) instead of discarding the text.
            try await insertConflictedCopy(following: note.id, from: latest)
        }
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = stored
        } else {
            notes.append(stored)
        }
        baseContent[note.id] = stored.content
        basePinned[note.id] = stored.isPinned
        versions[note.id] = stored.version
        dirty.remove(note.id)
        notes.sort(by: Note.defaultSort)
        postNotesDidChange()
        postNoteReplaced(note.id)
        if textEdited {
            return
        } else if latest.isPinned != stored.isPinned {
            // Only the pin was changed here: the other writer's text stands,
            // and the pin goes on top of it rather than into a copy.
            var pinned = stored
            pinned.isPinned = latest.isPinned
            dirty.insert(note.id)
            let written = try await write(pinned, version: stored.version)
            markSaved(pinned, version: written)
            if let idx = notes.firstIndex(where: { $0.id == note.id }) {
                notes[idx].isPinned = latest.isPinned
            }
        }
    }

    @discardableResult
    private func insertConflictedCopy(of note: Note) async throws -> Note {
        var copy = Note.new(content: Self.conflictedCopyContent(of: note.content))
        copy.version = try await insert(copy)
        notes.append(copy)
        baseContent[copy.id] = copy.content
        basePinned[copy.id] = copy.isPinned
        notes.sort(by: Note.defaultSort)
        postNotesDidChange()
        return copy
    }

    /// Stores the editor's text for `id` as a conflicted copy, and keeps the
    /// copy in step with any typing that lands in `id` while the writes are
    /// out — the editor still shows `id` until the caller replaces it, so a
    /// keystroke there is text the copy must not miss. `latest` is the text
    /// to start from when `id` is no longer in `notes`.
    private func insertConflictedCopy(following id: UUID, from latest: Note) async throws {
        var copied = notes.first(where: { $0.id == id }) ?? latest
        var copy = try await insertConflictedCopy(of: copied)
        while let now = notes.first(where: { $0.id == id }), now.content != copied.content {
            copied = now
            copy.content = Self.conflictedCopyContent(of: now.content)
            copy.modifiedDate = Date()
            copy.version = try await write(copy, version: nil)
            if let idx = notes.firstIndex(where: { $0.id == copy.id }) {
                notes[idx] = copy
            }
            baseContent[copy.id] = copy.content
            basePinned[copy.id] = copy.isPinned
        }
    }

    /// The text of a conflicted copy: `content` with "(conflicted copy)"
    /// marked on wherever its title comes from, and nothing else changed.
    ///
    /// A frontmatter block stays first, or its keys become body text. A title
    /// the frontmatter names (`title`, else `name`, as `MarkdownText` derives
    /// it) is marked in place; a leading `# Heading` is marked in place rather
    /// than repeated; otherwise a heading carrying the title is inserted right
    /// after the frontmatter.
    static func conflictedCopyContent(of content: String) -> String {
        let marker = " (conflicted copy)"
        for key in ["title", "name"] {
            guard let named = Frontmatter.stringValue(key, in: content)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !named.isEmpty else { continue }
            return Frontmatter.setting(key, to: .string(named + marker), in: content)
        }
        let parts = Frontmatter.split(content)
        var lines = parts.body.components(separatedBy: "\n")
        if let first = lines.firstIndex(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }), lines[first].hasPrefix("# ") {
            let heading = lines[first]
            let trailing = heading.hasSuffix("\r") ? "\r" : ""
            lines[first] = String(heading.dropLast(trailing.count)) + marker + trailing
            return parts.prefix + lines.joined(separator: "\n")
        }
        let title = MarkdownText.deriveTitle(content)
        return parts.prefix + "# \(title)\(marker)\n\n" + parts.body
    }

    // MARK: - Load

    public func loadNotes() async {
        do {
            let ledger = versions
            let loaded = try await performStorage { storage in
                let all = try await storage.fetchAllNotes()
                ledger.replaceAll(with: all)
                return all
            }
            notes = loaded.sorted(by: Note.defaultSort)
            baseContent = Dictionary(loaded.map { ($0.id, $0.content) }, uniquingKeysWith: { first, _ in first })
            basePinned = Dictionary(loaded.map { ($0.id, $0.isPinned) }, uniquingKeysWith: { first, _ in first })
            dirty = []
            isLoaded = true
            postNotesDidChange()
            logger.info("Loaded \(loaded.count) notes")
        } catch {
            isLoaded = true
            record(.load, error)
        }
    }

    // MARK: - CRUD

    /// `nil` when the note could not be persisted — and in that case the note
    /// is not in `notes` either.
    ///
    /// A note that exists only in an array is not a note. Keeping it visible
    /// was the whole defect: the user typed into it all session, every save
    /// threw `.notFound` because nothing was ever inserted, and it was gone at
    /// the next launch. Removing it costs the user the text they had typed so
    /// far, which is at most a title on a brand-new note, and it is the only
    /// answer that leaves the screen telling the truth.
    @discardableResult
    public func createNote(content: String) async -> UUID? {
        var note = Note.new(content: content)
        do {
            note.version = try await insert(note)
        } catch {
            record(.create, error)
            return nil
        }
        baseContent[note.id] = note.content
        basePinned[note.id] = note.isPinned
        notes.append(note)
        notes.sort(by: Note.defaultSort)
        postNotesDidChange()
        return note.id
    }

    /// Updates content with a 1-second debounce to avoid excessive writes.
    /// Title and excerpt are derived from `content`, so nothing else here
    /// needs to change.
    public func updateNote(_ note: Note, content: String) async {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updated = notes[idx]
        updated.content = content
        updated.modifiedDate = Date()
        notes[idx] = updated
        dirty.insert(note.id)
        notes.sort(by: Note.defaultSort)
        postNotesDidChange()
        scheduleSave(updated)
    }

    public func togglePin(note: Note) async {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updated = notes[idx]
        updated.isPinned.toggle()
        updated.modifiedDate = Date()
        notes[idx] = updated
        // Dirty until the write lands, so a feed change arriving meanwhile is
        // not adopted over the toggle (`markSaved` clears it).
        dirty.insert(note.id)
        notes.sort(by: Note.defaultSort)
        // `updated` is a `var`; the `@Sendable` closure below cannot capture
        // it by reference, only a snapshot — `toSave` is that snapshot.
        let toSave = updated
        do {
            try await persist(toSave)
        } catch {
            // Not retried, so stop holding feed changes off: the next one
            // brings the screen back to what storage holds.
            if notes.first(where: { $0.id == note.id })?.content == baseContent[note.id] {
                dirty.remove(note.id)
            }
            record(.save, error)
        }
        postNotesDidChange()
    }

    public func deleteNote(id: UUID) async {
        forget(id)
        do {
            try await performStorage { try await $0.deleteNote(id: id) }
        } catch {
            record(.delete, error)
        }
        postNotesDidChange()
    }

    // MARK: - Debounced Save

    /// Schedules a save after `saveDebounce`. Subsequent calls for the same
    /// note ID replace the pending work and restart the debounce.
    ///
    /// The note is looked up again *inside* the work rather than captured, so
    /// a save that runs late — or that is retried after a failure — persists
    /// the note as it stands now, not as it stood when the keystroke landed.
    private func scheduleSave(_ note: Note) {
        let noteID = note.id
        saveDebouncer.schedule(key: noteID) { [weak self] in
            guard let self, let current = self.notes.first(where: { $0.id == noteID }) else { return }
            try await self.persist(current)
        }
    }

    /// Immediately persists any pending debounced saves, and answers with the
    /// note IDs whose write still failed.
    ///
    /// Call before app termination. A failed write leaves its note pending
    /// rather than dropping it, so a transient failure here is retried and a
    /// permanent one is at least reportable — which the previous shape could
    /// not do, having already cleared the note from its pending map.
    @discardableResult
    public func flushPendingSaves() async -> [UUID] {
        await saveDebouncer.flushAll()
    }
}

extension NotesManager: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// A storage read or write that failed, in the terms the user needs to hear it
/// in: which of their actions did not happen, and what the system said.
public struct NotesStorageFailure: Equatable, Sendable {

    public enum Operation: String, Sendable {
        case load
        case create
        case save
        case delete

        /// The sentence the alert leads with. Phrased as the user's action
        /// rather than the API's — "Couldn't Save Note", not "updateNote
        /// threw" — because that is the part they can act on.
        public var title: String {
            switch self {
            case .load: return "Couldn't Load Notes"
            case .create: return "Couldn't Create Note"
            case .save: return "Couldn't Save Note"
            case .delete: return "Couldn't Delete Note"
            }
        }

        /// What the failure means for what is on screen. `create` is the one
        /// that removed something, so it is the one that has to say so.
        public var consequence: String {
            switch self {
            case .load: return "Your notes could not be read from disk."
            case .create: return "The new note was not saved and has been removed."
            case .save: return "Your most recent changes are not saved to disk yet."
            case .delete: return "The note may reappear the next time \(AppStorageLocation.displayName) starts."
            }
        }
    }

    public let operation: Operation

    /// `localizedDescription` of the underlying error, shown verbatim. A
    /// paraphrase would drop exactly the detail that distinguishes a full disk
    /// from a locked database.
    public let message: String

    public init(operation: Operation, message: String) {
        self.operation = operation
        self.message = message
    }
}
