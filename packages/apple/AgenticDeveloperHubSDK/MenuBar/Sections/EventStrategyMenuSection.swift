import AppKit
import Foundation
import AgenticDeveloperHubSDKCore

/// Renders event-strategy status: a header listing the strategy's work units
/// (from the handler's snapshot), and an optional "Open Stream…" quick action
/// clients can wire to an external tool (Terminal, CLI, etc).
public struct EventStrategyMenuSection: MenuSection {
    public let onOpenStream: (@Sendable () -> Void)?

    public init(onOpenStream: (@Sendable () -> Void)? = nil) {
        self.onOpenStream = onOpenStream
    }

    public func items(snapshot: MenuSnapshot) -> [NSMenuItem] {
        guard let strategy = snapshot.health?.strategy.first(ofKind: DaemonStrategyReport.eventKind)
        else { return [] }

        var items: [NSMenuItem] = [
            MenuBarHelpers.headerItem("EVENTS — \(strategy.name)")
        ]
        for unit in strategy.workUnits {
            let marker = unit.state == .running ? "●" : "○"
            items.append(MenuBarHelpers.infoItem(
                label: "\(marker) \(unit.name)",
                value: unit.state.rawValue
            ))
        }
        if let onOpenStream {
            items.append(BlockMenuItem(title: "Open Event Stream…", action: onOpenStream))
        }
        return items
    }
}
