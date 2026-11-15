import AppKit
import AgenticDeveloperHubSDKCore

/// View ▸ Tab Position ▸ Top, Left, Right, Bottom: one checked item per edge
/// over the app-wide tab positions (`UserSettings.tabsPositions`). Choosing
/// an item turns its edge on or off; turning off the last enabled edge is
/// refused with a beep, and the item stays checked (`edges-never-empty`).
@MainActor
public enum TabPositionMenu {

    /// The submenu the items share.
    public static let submenuTitle = "Tab Position"

    /// The four items, in `TabPositions.primaryOrder`, reading and writing
    /// `UserSettings.tabsPositions` in `settings`.
    public static func contributions(settings: UserSettings = .shared) -> [MenuContribution] {
        TabPositions.primaryOrder.enumerated().map { index, edge in
            MenuContribution(
                slot: .view,
                title: edge.displayName,
                order: index,
                isChecked: { settings.get(UserSettings.tabsPositions).edges.contains(edge) },
                identifier: edge.rawValue,
                submenu: submenuTitle,
                action: { toggle(edge, in: settings) }
            )
        }
    }

    /// Flips `edge` in the setting, or beeps when that would leave no edge.
    private static func toggle(_ edge: Edge, in settings: UserSettings) {
        let current = settings.get(UserSettings.tabsPositions)
        guard let next = current.setting(edge, enabled: !current.edges.contains(edge)) else {
            NSSound.beep()
            return
        }
        settings.set(next, for: UserSettings.tabsPositions)
    }
}

/// Puts `TabPositionMenu`'s items in the host's View menu.
@MainActor
public final class TabPositionMenuFeature: AppFeature {

    public init(settings: UserSettings = .shared) {
        super.init()
        menuContributions = TabPositionMenu.contributions(settings: settings)
    }
}
