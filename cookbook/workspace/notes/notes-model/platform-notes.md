
- **SwiftUI**: These types are plain Swift/Foundation with no AppKit
  dependency, so a SwiftUI host can wrap `NotesManager` in an
  `@Observable` or `ObservableObject` adapter (it is neither itself — see
  Design Decisions) and drive a `List`/`ForEach` from `notes`, observing
  `notesDidChangeNotification` and `storageDidFailNotification` the same
  way an AppKit host does.
- **Compose**: Port `Note` as a `data class`, `NoteFolder` as a recursive
  `data class`, and `NoteStorage` as a Kotlin `interface` of five
  `suspend` functions, with the change stream as a `Flow<NoteChange>`
  (a sealed class whose cases include `TaxonomyChanged`). The note
  taxonomy stays a plain, non-`suspend` Kotlin `interface`, because the
  folders pane and the Move-to menu call it on the main thread while they
  build rows and menus; a remote storage implements it over a local copy
  it keeps current. The taxonomy-provider extension is a second interface
  exposing `val taxonomy: NoteTaxonomy`, checked with `as?`.
  `NotesManager` becomes a `ViewModel` holding a
  `StateFlow<List<Note>>` in place of the notification pair (and a
  `SharedFlow<Unit>` in place of the taxonomy-change notification), with the
  debounced save mapped onto a coroutine job keyed by note id (the role
  `KeyedDebouncer` plays here) and the storage-issue-ordering guarantee
  reproduced with a single-threaded dispatcher or a `Mutex`.
- **React/Web**: `Note`/`NoteFolder` become plain TypeScript interfaces;
  `NoteStorage` an interface of five `Promise`-returning methods, with the change stream as an async iterable
  (a discriminated union with a `taxonomyChanged` member). The note
  taxonomy stays synchronous (plain methods, no `Promise`), answered from
  a local copy by a remote storage, and the taxonomy-provider extension
  is an optional `taxonomy` property checked before use.
  `NotesManager` becomes a store (a hook backed by
  `useSyncExternalStore`, or a small class with subscribers in place of
  `NotificationCenter`), with the per-note debounce implemented via
  `setTimeout` keyed by note id and the write-ordering guarantee
  implemented as a per-instance promise chain, exactly mirroring
  `performStorage(_:)`'s `storageChain`.
- **AppKit / UIKit**: The sources given here — `Note.swift` and
  `MarkdownNoteMapping.swift` under
  `packages/apple/AgenticDeveloperHubSDK/Markdown/`, and `NoteFolder.swift`,
  `NoteStorage.swift`, `NoteTaxonomyProviding.swift`,
  `MarkdownNoteStorage.swift`, `NotesManager.swift` and
  `NotesMarkdownReExports.swift` under
  `packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/` — are the
  source platform, with the `NoteTaxonomy` protocol they consume in
  `Markdown/NoteTaxonomy.swift`: a macOS-only target consumed by
  `NotesCoordinator`/`NotesSplitViewController` (out of scope for this
  ingredient) via `NotificationCenter` observation and `@MainActor` calls.
  `Note`, `NoteFolder`, and `MarkdownNoteStorage` are `Sendable`;
  `NotesManager` is itself `@MainActor`, and every storage call it issues
  runs off the main actor through `Task.detached`, serialized into its
  own `storageChain`; the change stream is an `AsyncStream<NoteChange>` consumed by a `Task` the manager cancels in `deinit` (see `notesmanager-confined-to-primary-thread` and
  `notesmanager-storage-off-primary-thread`). `NoteTaxonomyProviding`
  declares `var taxonomy: any NoteTaxonomy`, which `MarkdownNoteStorage`
  answers with its `store`; `NotesManager.taxonomy` is
  `(any NoteTaxonomy)?`, and `NotesSplitViewController(taxonomy:)` and
  `NotesFolderListViewController(taxonomy:)` take the same optional
  existential. `NoteChange.taxonomyChanged` and a `.resync` each make
  `apply(_:)` post `NotesManager.taxonomyDidChangeNotification`, which
  `NotesSplitViewController` observes to call `folderVC.reload()`.
  `NotesManager.noteReplacedNotification` carries the id under
  `NotesManager.noteIDUserInfoKey`; `NotesSplitViewController` observes it
  and calls `editorVC.show(note:)` for the selected note when the editor's
  text differs. `MarkdownNoteStorage.fetchNote` reads
  `MarkdownStore.document(id:marker: .note)`. `loadNotes()` keeps dirty notes
  through `VersionLedger.replaceAll(with:keeping:)`, and `basePinned` sits
  beside `baseContent` for the stale re-save's pin rule. The version ledger is a
  `nonisolated let versions = VersionLedger()`, a `[UUID: Int64]` behind an
  `OSAllocatedUnfairLock`, read and advanced by the `write(_:version:)` and
  `insert(_:)` helpers from inside the `storageChain`, so a queued save
  never quotes a version read on the main actor before the save ahead of
  it landed (see `notesmanager-version-ledger`). `NoteFolder`'s explicit,
  non-accidental `Hashable` conformance exists because an `NSOutlineView`
  bridges a Swift value lacking that conformance to a boxed object whose
  hash falls back to that box's own identity, so two
  differently-boxed-but-equal folders from two separate `reload()`s would
  hash unequally and `isItemExpanded(_:)`/`row(forItem:)` could never
  match one across a reload (see `notefolder-value-semantics`).
  `MarkdownNoteStorage` persists through SQLite via GRDB, and neither it
  nor `NotesManager` add Keychain storage or any protection beyond what
  that store applies (see Privacy). Nothing in these files is itself
  AppKit-specific — they import only `Foundation`, `os`,
  `AgenticDeveloperHubSDKCore`, `AgenticDeveloperHubSDKMarkdown`, and
  `AgenticDeveloperHubSDKDatabase` — so the same files would compile unchanged
  into a UIKit iOS target. The notes list beside these types shows each
  note's `modifiedDate` through the shared
  [adhsdk.ingredient.foundation.formatting.relative-date](cookbook:873f79b1-444d-4c2c-8a5f-4fc01cd9022e)
  formatter (abbreviated, no cutoff), never a formatter of its own.
- **WinUI 3**: `Note`/`NoteFolder` become a `record`/`class` pair (or a
  lightweight `INotifyPropertyChanged` model if the folder tree needs to
  bind directly to a `TreeView`). `NoteStorage` becomes an interface
  returning `Task<T>` per method. `NotesManager` becomes a class backed
  by an `ObservableCollection<Note>` in place of `notes`, replacing
  `notesDidChangeNotification`/`storageDidFailNotification` with
  `INotifyCollectionChanged` and a plain C# event; a
  `SemaphoreSlim(1, 1)` awaited before each storage call reproduces the
  one-at-a-time, issue-ordered `storageChain`, and a
  `System.Threading.Timer` per note id, restarted on each edit,
  reproduces `KeyedDebouncer`'s per-key debounce-with-retry. The change
  stream becomes an `IAsyncEnumerable<NoteChange>` over a record hierarchy
  that includes a taxonomy-changed case, the note taxonomy a synchronous
  C# interface answered from a local copy, the taxonomy-provider extension
  a second interface checked with `is`, and the taxonomy-change
  notification a plain C# event.

