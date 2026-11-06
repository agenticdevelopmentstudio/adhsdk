import AppKit

extension ComposableSettings {

    /// A panel that holds other panels and shows one of them at a time — what
    /// the window's search, toolbar title, help and back/forward look *through*
    /// to find the panel the reader is actually looking at.
    @MainActor
    public protocol SettingsPanelContainer: ComposableSettingsPanel {
        var containedPanels: [any ComposableSettingsPanel] { get }
        var selectedContainedPanel: (any ComposableSettingsPanel)? { get }
        func selectContainedPanel(_ panel: any ComposableSettingsPanel)
    }

    /// One sidebar topic for a whole section: a vertical topic list, one row
    /// per panel in the section, beside the selected panel — the same
    /// topic/detail split the Theme panel uses for its themes.
    ///
    ///     Workspace  | Git        | <the selected panel>
    ///                | Projects   |
    ///
    /// It replaced a row of horizontal tabs (`SectionTabsPanel`): a tab bar
    /// stacked a second kind of navigation over panels that already had a
    /// vertical one of their own, and ran out of width at four tabs.
    ///
    /// A section holding a single panel shows no list: one row chooses nothing.
    /// The panel fills the topic instead, and the list comes back when a second
    /// panel arrives.
    ///
    /// The rows keep the order they are handed over in; `AppCoordinator` hands
    /// them over alphabetised. The selected row survives `setPanels` when its
    /// panel is still among the new ones, so a panel added late never moves
    /// the reader off the row they were on.
    @MainActor
    public final class SectionTopicsPanel: SettingsPanelSplitViewController, SettingsPanelContainer {

        public var containedPanels: [any ComposableSettingsPanel] { panels }

        public var selectedContainedPanel: (any ComposableSettingsPanel)? { selectedPanel }

        public init(section: String, icon: NSImage?) {
            super.init(with: SettingsPanelDescriptor(title: section, icon: icon))
            // The topic list is a table of contents for the section; the
            // section's own name is already the selected sidebar row, so a
            // header repeating it above the list says nothing.
            sidebarTitle = nil
            // Every panel here carries the section's name as its own
            // `section`, which the list would otherwise show as a header.
            listViewController.showsSectionTitles = false
            showsSidebar = false
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError() }

        /// Replaces the rows, keeping the selected one when it is still here,
        /// and shows the list only when there is more than one row.
        public func setSectionPanels(_ panels: [any ComposableSettingsPanel]) {
            showsSidebar = panels.count > 1
            setPanels(panels)
            // A panel arriving after the section is already on screen has no
            // `viewWillAppear` to select it, and an empty detail pane beside a
            // list is a section that looks broken.
            if isViewLoaded, selectedPanel == nil, let first = panels.first {
                selectPanel(first)
            }
        }

        public func selectContainedPanel(_ panel: any ComposableSettingsPanel) {
            selectPanel(panel)
        }
    }
}
