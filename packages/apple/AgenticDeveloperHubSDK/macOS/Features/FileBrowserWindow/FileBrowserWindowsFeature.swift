//
//  FileBrowserWindowsFeature.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit
import os

/// File ▸ New File Browser Window…: a composable-tabs window over any
/// directory — the file browser and a Document pane, with terminals the user
/// may add, which start in that directory.
///
/// A directory is a `GitRepo` row of kind `.fileBrowser`, found by its path,
/// so the window's tabs and panes persist like a project's while the scan,
/// the Project Browser and every project list (`ProjectDatabase.allRepos()`)
/// never see it. One window per directory: opening one that already has a
/// window brings that window forward.
///
/// What reopens at launch is this feature's own list
/// (`UserSettings.openFileBrowserDirectories`), not the project window's
/// open flag: a File Browser window belongs to no project window group.
@MainActor
public final class FileBrowserWindowsFeature: AppFeature {

    public enum CommandID {
        public static let newWindow = "fileBrowser.action.newWindow"
    }

    private let database: ProjectDatabase
    private let layout: ComposableTabsLayout
    private let windows: ProjectWindowManager

    /// - Parameter layout: the File Browser window's layout, built by the
    ///   host over the same pane registry as the project window's.
    public init(
        commandRegistry registry: CommandRegistry,
        database: ProjectDatabase,
        layout: ComposableTabsLayout,
        windows: ProjectWindowManager = .shared
    ) {
        self.database = database
        self.layout = layout
        self.windows = windows
        super.init()
        registry.register(AppCommand(
            id: CommandID.newWindow,
            title: "New File Browser Window…",
            category: "File Browser",
            run: { [weak self] _ in self?.chooseAndOpen() }
        ))
        menuContributions = [
            MenuContribution(
                slot: .fileNew, title: "New File Browser…",
                commandID: CommandID.newWindow, registry: registry,
                order: 40
            )
        ]
    }

    /// Asks for a directory and opens a File Browser window on it.
    public func chooseAndOpen() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Open"
        panel.message = "Choose a folder to browse."
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            MainActor.assumeIsolated { _ = self?.open(directory: url) }
        }
    }

    /// Opens a File Browser window on `directory`, or brings forward the one
    /// already open on it.
    ///
    /// - Parameter activates: false for launch restore, which reopens what
    ///   was open without taking the foreground.
    /// - Returns: the window, or `nil` when `directory` is not a directory or
    ///   its row could not be read or written (logged).
    @discardableResult
    public func open(directory: URL, activates: Bool = true) -> ComposableTabsWindowController? {
        let url = Self.canonical(directory)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            Self.logger.error("Not a directory: \(url.path, privacy: .public)")
            return nil
        }
        let repo: GitRepo
        do {
            repo = try row(for: url)
        } catch {
            Self.logger.error("Could not record File Browser row for \(url.path, privacy: .public): \(error)")
            return nil
        }
        let controller = windows.openFileBrowserWindow(
            repo,
            layout: layout,
            activates: activates,
            onClose: { [weak self] closed in self?.forget(closed.path) }
        )
        if controller != nil { remember(url.path) }
        return controller
    }

    /// Reopens the File Browser windows that were open when the app last
    /// quit, without taking the foreground. A directory that has gone is
    /// dropped from the list.
    public func restoreOpenWindows() {
        let paths = UserSettings.openFileBrowserDirectories.currentValue
        for path in paths where open(directory: URL(fileURLWithPath: path), activates: false) == nil {
            forget(path)
        }
    }

    // MARK: - Rows

    /// The `.fileBrowser` row for `url`, inserted the first time.
    private func row(for url: URL) throws -> GitRepo {
        if let existing = try database.repo(path: url.path, kind: .fileBrowser) {
            return existing
        }
        let name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let repo = GitRepo(path: url.path, name: name, kind: .fileBrowser)
        try database.insert(repo)
        return repo
    }

    /// One spelling per directory, so `/tmp/x` and `/private/tmp/x` are one
    /// row and one window.
    static func canonical(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }

    // MARK: - Restore list

    private func remember(_ path: String) {
        var paths = UserSettings.openFileBrowserDirectories.currentValue
        guard !paths.contains(path) else { return }
        paths.append(path)
        UserSettings.openFileBrowserDirectories.value = paths
    }

    private func forget(_ path: String) {
        let paths = UserSettings.openFileBrowserDirectories.currentValue
        guard paths.contains(path) else { return }
        UserSettings.openFileBrowserDirectories.value = paths.filter { $0 != path }
    }
}

extension FileBrowserWindowsFeature: Loggable {
    public static nonisolated let logger = makeLogger()
}

extension UserSettings {
    /// The directories whose File Browser windows were open, as absolute
    /// paths in the order they were opened; reopened at launch.
    public static let openFileBrowserDirectories =
        UserSetting<[String]>("open_file_browser_directories", default: [])
}
