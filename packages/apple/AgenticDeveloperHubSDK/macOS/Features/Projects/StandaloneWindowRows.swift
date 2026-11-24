//
//  StandaloneWindowRows.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import Foundation

/// The bookkeeping every standalone window kind shares (File Browser and
/// Document windows): one canonical spelling per path, the `GitRepo` row a
/// window's workspace is found by, and the list of paths whose windows
/// reopen at launch.
///
/// One copy, so a fix to any of it — how a path is spelled, how a row is
/// found, when one is thrown away — reaches every kind at once.
@MainActor
public struct StandaloneWindowRows {

    public let kind: GitRepo.Kind
    private let database: ProjectDatabase
    private let openPaths: UserSetting<[String]>?

    /// - Parameter openPaths: the setting holding the paths whose windows of
    ///   this kind were open, in the order they were opened; `nil` for a kind
    ///   with one fixed row, whose open state is a flag of its own.
    public init(kind: GitRepo.Kind, database: ProjectDatabase, openPaths: UserSetting<[String]>?) {
        self.kind = kind
        self.database = database
        self.openPaths = openPaths
    }

    /// One spelling per path, so `/tmp/x` and `/private/tmp/x` — or a
    /// symlink and the file it names — are one row and one window.
    public static func canonical(_ url: URL) -> URL { url.canonicalFileURL }

    // MARK: - Rows

    /// The row of this kind at `url`, if there is one.
    public func existingRow(for url: URL) throws -> GitRepo? {
        try database.repo(path: url.path, kind: kind)
    }

    /// The row of this kind at `url`, inserted the first time.
    ///
    /// - Parameter name: the new row's name; the last path component (the
    ///   path itself for `/`) when `nil`.
    public func row(for url: URL, name: String? = nil) throws -> GitRepo {
        if let existing = try existingRow(for: url) { return existing }
        let fallback = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let repo = GitRepo(path: url.path, name: name ?? fallback, kind: kind)
        try database.insert(repo)
        return repo
    }

    /// Deletes `repo`'s row — its tabs, layout, state and pane state go with
    /// it by cascade — and its saved window frame, which lives in
    /// `UserDefaults` under an id nothing would ask for again.
    ///
    /// Call it a turn after the window closes, so whatever its panes write on
    /// the way out lands before the row is gone rather than after.
    public func discard(_ repo: GitRepo) {
        do {
            try database.delete(id: repo.id)
        } catch {
            StandaloneWindowRowsLog.logger.error(
                "Could not delete the row for \(repo.path, privacy: .public): \(error)")
        }
        let windowID = ComposableTabsWindowController.windowID(for: repo.id)
        WindowManager.shared.frames.clearSavedState(for: windowID)
        WindowManager.shared.frames.clearVisibility(for: windowID)
    }

    /// Deletes every row of this kind whose path is not in the restore list:
    /// rows whose windows were closed before closing discarded them, and
    /// rows for files that have gone. Run at launch, before any window of
    /// this kind is open.
    public func discardForgottenRows() {
        let kept = Set(rememberedPaths)
        do {
            for repo in try database.repos(kind: kind) where !kept.contains(repo.path) {
                discard(repo)
            }
        } catch {
            StandaloneWindowRowsLog.logger.error("Could not list \(kind.rawValue, privacy: .public) rows: \(error)")
        }
    }

    // MARK: - Restore list

    /// The paths whose windows reopen at launch.
    public var rememberedPaths: [String] { openPaths?.currentValue ?? [] }

    public func remember(_ path: String) {
        guard let openPaths else { return }
        var paths = openPaths.currentValue
        guard !paths.contains(path) else { return }
        paths.append(path)
        openPaths.value = paths
    }

    public func forget(_ path: String) {
        guard let openPaths else { return }
        let paths = openPaths.currentValue
        guard paths.contains(path) else { return }
        openPaths.value = paths.filter { $0 != path }
    }
}

enum StandaloneWindowRowsLog: Loggable {
    static nonisolated let logger = makeLogger()
}
