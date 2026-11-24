import Foundation

import AgenticDeveloperHubSDKCore

extension UserSettings {
    /// The project browser's folders the user has closed, by path. Every
    /// other folder opens, so a folder nobody has touched — a new one, say —
    /// is shown open.
    public static let projectBrowserCollapsedFolders = UserSetting<[String]>(
        "projects.browser.collapsed-folders", default: [])
}

/// Which folders of a tree the user has closed, kept across every rebuild of
/// the tree and across launches.
///
/// The tree is rebuilt whenever its contents or filter change, and a rebuilt
/// outline knows nothing of what was open. This holds the user's answer so
/// the outline can be put back. A folder changes state only when the user
/// opens or closes it, or when a project inside it is selected and its
/// folders open so it can be shown (`reveal`).
///
/// Keyed by path, which is stable across rebuilds where nodes are not. The
/// storage is injected, so a test hands it a setting of its own.
@MainActor
public final class FolderDisclosureMemory {

    private let setting: UserSetting<[String]>
    private var collapsed: Set<String>

    public init(setting: UserSetting<[String]> = UserSettings.projectBrowserCollapsedFolders) {
        self.setting = setting
        self.collapsed = Set(setting.value)
    }

    public func isCollapsed(_ path: String) -> Bool { collapsed.contains(path) }

    /// The user closed (`true`) or opened (`false`) the folder at `path`.
    public func note(_ path: String, collapsed isCollapsed: Bool) {
        let changed = isCollapsed ? collapsed.insert(path).inserted : collapsed.remove(path) != nil
        if changed { save() }
    }

    /// Opens every folder in `paths` — the folders above a project being
    /// selected.
    public func reveal(_ paths: [String]) {
        let before = collapsed.count
        collapsed.subtract(paths)
        if collapsed.count != before { save() }
    }

    private func save() {
        setting.value = collapsed.sorted()
    }
}
