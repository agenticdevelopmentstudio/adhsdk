//
//  DocumentWindowsFeature.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit
import os

/// Opens single files — one handed over by Finder's Open With, by a CLI, by
/// Open Location — in a Document window: a composable-tabs window holding
/// the Document pane and nothing else.
///
/// Where a file lands is `UserSettings.singleDocumentsOpenIn`:
///
/// - `.tabs`: one shared Document window, each file a tab of its Document
///   pane. Its workspace is the single `.documentTabs` row.
/// - `.windows`: a window per file, showing the Document pane's full tabs
///   like the shared window. Its workspace is a `.document` row found by
///   the file's path, so opening a file that already has a window brings
///   that window forward.
///
/// Inside a Document window a file chosen from an editor's breadcrumb loads
/// in the current tab, joining that editor's back/forward trail; with Option
/// held it opens in a new tab of the same window. The window's title is the
/// name of the file its focused editor shows.
///
/// A file already open — in a window of its own, or in a tab of the shared
/// window — comes forward there whatever the setting says: the setting
/// decides where a file *opens*, not where an open one is.
///
/// What reopens at launch is this feature's own record
/// (`UserSettings.openDocumentWindowFiles`, `UserSettings.documentTabsWindowOpen`),
/// as with File Browser windows. The shared window's tabs are the Document
/// pane's to restore.
@MainActor
public final class DocumentWindowsFeature: AppFeature {

    /// The per-file `.document` rows and the files whose windows reopen.
    private let rows: StandaloneWindowRows
    /// The one `.documentTabs` row, whose window reopens by its own flag.
    private let tabsRows: StandaloneWindowRows
    private let layout: ComposableTabsLayout
    private let windows: ProjectWindowManager

    /// The Document pane of each open Document window, by row id. Weak: the
    /// pane belongs to its window.
    private let panes = NSMapTable<NSUUID, DocumentTabsViewController>.strongToWeakObjects()

    /// Files opened into a window whose Document pane has not been built yet,
    /// by row id; shown when the pane attaches.
    private var pendingFiles: [UUID: [PendingFile]] = [:]

    /// A file on its way to a pane. `onlyIfEmpty` is launch restore: the
    /// editor brings back the file it was last showing, which the user may
    /// have navigated away from the one the window was opened on, and only an
    /// editor that restored nothing takes the row's file.
    private struct PendingFile {
        let url: URL
        let onlyIfEmpty: Bool
    }

    /// - Parameter layout: the Document window's layout — the Document pane
    ///   alone — built by the host over the same pane registry as the project
    ///   window's.
    public init(
        database: ProjectDatabase,
        layout: ComposableTabsLayout,
        windows: ProjectWindowManager = .shared
    ) {
        self.rows = StandaloneWindowRows(
            kind: .document, database: database,
            openPaths: UserSettings.openDocumentWindowFiles)
        self.tabsRows = StandaloneWindowRows(kind: .documentTabs, database: database, openPaths: nil)
        self.layout = layout
        self.windows = windows
        super.init()
    }

    // MARK: - Opening

    /// Opens `file` where `UserSettings.singleDocumentsOpenIn` says, or
    /// brings forward the window already showing it.
    ///
    /// - Parameter activates: false for launch restore, which reopens what
    ///   was open without taking the foreground.
    /// - Returns: the window, or `nil` when `file` is not an existing file or
    ///   its row could not be read or written (logged).
    @discardableResult
    public func open(file: URL, activates: Bool = true) -> ComposableTabsWindowController? {
        let url = StandaloneWindowRows.canonical(file)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            Self.logger.error("Not a file: \(url.path, privacy: .public)")
            return nil
        }
        do {
            if let own = try rows.existingRow(for: url),
               windows.isDocumentWindow(own.id) {
                return openWindow(own, showing: url, activates: activates)
            }
            if let shared = try openTabsRow(holding: url) {
                return openWindow(shared, showing: url, activates: activates)
            }
            switch UserSettings.singleDocumentsOpenIn.currentValue {
            case .tabs:
                return openWindow(try tabsRow(), showing: url, activates: activates)
            case .windows:
                return openWindow(try rows.row(for: url), showing: url, activates: activates)
            }
        } catch {
            Self.logger.error("Could not record Document window row for \(url.path, privacy: .public): \(error)")
            return nil
        }
    }

    /// Reopens the Document windows that were open when the app last quit,
    /// without taking the foreground. A file that has gone is dropped from
    /// the list.
    public func restoreOpenWindows() {
        for path in rows.rememberedPaths where !FileManager.default.fileExists(atPath: path) {
            rows.forget(path)
        }
        // A window per file means a row per file: keep only the ones that
        // are about to reopen.
        rows.discardForgottenRows()
        for path in rows.rememberedPaths {
            let url = URL(fileURLWithPath: path)
            let reopened = FileManager.default.fileExists(atPath: path)
                && (try? rows.row(for: url)).flatMap {
                    openWindow($0, showing: url, activates: false, onlyIfEmpty: true)
                } != nil
            if !reopened { rows.forget(path) }
        }
        if UserSettings.documentTabsWindowOpen.currentValue, let row = try? tabsRow() {
            _ = openWindow(row, showing: nil, activates: false)
        }
    }

    /// Opens (or brings forward) the window over `repo` and shows `file` in
    /// its Document pane. `file` is `nil` for the shared window at restore,
    /// whose pane brings its own tabs back.
    private func openWindow(
        _ repo: GitRepo,
        showing file: URL?,
        activates: Bool,
        onlyIfEmpty: Bool = false
    ) -> ComposableTabsWindowController? {
        let controller = windows.openDocumentWindow(
            repo,
            layout: layout,
            activates: activates,
            onClose: { [weak self] closed in self?.windowClosed(closed) }
        )
        guard controller != nil else { return nil }
        switch repo.kind {
        case .document: rows.remember(repo.path)
        default: UserSettings.documentTabsWindowOpen.value = true
        }
        if let file { show(PendingFile(url: file, onlyIfEmpty: onlyIfEmpty), in: repo) }
        return controller
    }

    private func windowClosed(_ repo: GitRepo) {
        pendingFiles.removeValue(forKey: repo.id)
        panes.removeObject(forKey: repo.id as NSUUID)
        switch repo.kind {
        case .document:
            rows.forget(repo.path)
            // A closed file's window is gone for good: its row and frame go
            // too, a turn later, once its panes have written what they write
            // on the way out.
            let rows = rows
            DispatchQueue.main.async { rows.discard(repo) }
        default:
            UserSettings.documentTabsWindowOpen.value = false
        }
    }

    // MARK: - The Document pane

    /// Called by the host's Document pane factory for a pane built in a
    /// Document window, so files opened into that window reach it. A window's
    /// panes are built after the window is, which is why a file can arrive
    /// first and wait in `pendingFiles`.
    public func attach(_ pane: DocumentTabsViewController, to project: ProjectWorkspace) {
        guard project.repo.kind.isDocument else { return }
        // A file opened by itself is read first: Markdown starts on its preview.
        pane.opensMarkdownOnSinglePreview = true
        // A file chosen in a breadcrumb stays in this window: the current tab
        // (and its editor's trail), or a new tab with Option held.
        pane.onOpenRequest = { [weak pane] url in
            if NSEvent.modifierFlags.contains(.option) {
                pane?.openInNewTab(url)
            } else {
                pane?.openInSelectedPane(url)
            }
        }
        // The window is titled for the file in front. Chained, because the
        // host's factory may already be listening.
        let repoID = project.id
        let previous = pane.onFocusedDocumentChange
        pane.onFocusedDocumentChange = { [weak self] url in
            previous?(url)
            self?.windows.windowController(for: repoID)?.titleDocumentURL = url
        }
        panes.setObject(pane, forKey: repoID as NSUUID)
        // The factory has not returned the pane yet, so it is in no view
        // hierarchy: deliver once this turn has put it there.
        let repo = project.repo
        DispatchQueue.main.async { [weak self, weak pane] in
            guard let self else { return }
            self.pendingFiles.removeValue(forKey: repoID)?.forEach { self.show($0, in: repo) }
            // What the editors restored was never announced: name it now.
            if let pane {
                self.windows.windowController(for: repoID)?.titleDocumentURL = pane.focusedEditor?.fileURL
            }
        }
    }

    private func show(_ file: PendingFile, in repo: GitRepo) {
        guard let pane = panes.object(forKey: repo.id as NSUUID) else {
            pendingFiles[repo.id, default: []].append(file)
            return
        }
        pane.loadViewIfNeeded()
        switch repo.kind {
        case .document:
            let showing = pane.focusedEditor?.fileURL
            if file.onlyIfEmpty, showing != nil { return }
            // A tab already holding the file is chosen over replacing the
            // selected tab's file with a second copy of it.
            if showing?.canonicalFileURL != file.url.canonicalFileURL,
               !pane.selectTab(showing: file.url) {
                pane.openInSelectedPane(file.url)
            }
        default:
            pane.show(file.url)
        }
    }

    // MARK: - Rows

    /// The one `.documentTabs` row, inserted the first time. Its path is the
    /// home directory: a real directory for the workspace to be rooted at,
    /// and one fixed value for the row to be found by.
    private func tabsRow() throws -> GitRepo {
        let home = StandaloneWindowRows.canonical(FileManager.default.homeDirectoryForCurrentUser)
        return try tabsRows.row(for: home, name: Self.tabsWindowName)
    }

    /// The shared window's row, when that window is open and one of its
    /// tabs already shows `url`: changing the setting never makes a second
    /// view of a file that is open.
    private func openTabsRow(holding url: URL) throws -> GitRepo? {
        let home = StandaloneWindowRows.canonical(FileManager.default.homeDirectoryForCurrentUser)
        guard let shared = try tabsRows.existingRow(for: home),
              windows.isDocumentWindow(shared.id),
              panes.object(forKey: shared.id as NSUUID)?.holds(url) == true else { return nil }
        return shared
    }

    static let tabsWindowName = "Documents"
}

extension DocumentWindowsFeature: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// Where a single document opens: Settings > General > Tab Behavior.
public enum SingleDocumentOpenMode: String, Codable, Sendable, CaseIterable, Equatable {
    /// A tab of the one shared Document window.
    case tabs
    /// A Document window of its own.
    case windows

    public var displayName: String {
        switch self {
        case .tabs: return "Tabs in Document Window"
        case .windows: return "Individual Document Windows"
        }
    }
}

extension UserSettings {
    /// Where a file opened on its own — from Finder, a CLI, Open Location —
    /// lands. Settings > General > Tab Behavior.
    public static let singleDocumentsOpenIn =
        UserSetting<SingleDocumentOpenMode>("documents.single_open_in", default: .tabs)

    /// The files whose own Document windows were open, as absolute paths in
    /// the order they were opened; reopened at launch.
    public static let openDocumentWindowFiles =
        UserSetting<[String]>("open_document_window_files", default: [])

    /// Whether the shared Document window was open; reopened at launch.
    public static let documentTabsWindowOpen =
        UserSetting<Bool>("document_tabs_window_open", default: false)
}
