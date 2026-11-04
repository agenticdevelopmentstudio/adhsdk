import AppKit
import Testing
@testable import AgenticToolkitMacOS

@MainActor
@Suite("SectionTabsPanel")
struct SectionTabsPanelTests {

    private func panel(_ title: String) -> ComposableSettings.SettingsPanelViewController {
        ComposableSettings.SettingsPanelViewController(with: .init(title: title))
    }

    private func tabBar(in section: ComposableSettings.SectionTabsPanel) -> NSSegmentedControl? {
        section.view.subviews.compactMap { $0 as? NSSegmentedControl }.first
    }

    @Test("A section with one panel shows no tab bar")
    func onePanelHidesTabs() {
        let section = ComposableSettings.SectionTabsPanel(section: "Coding Partner", icon: nil)
        section.setPanels([panel("Coding Partner")])
        _ = section.view
        #expect(section.showsTabs == false)
        #expect(tabBar(in: section)?.isHidden == true)
    }

    @Test("A section with two panels shows its tab bar, and hides it when one is left")
    func twoPanelsShowTabs() {
        let section = ComposableSettings.SectionTabsPanel(section: "AI", icon: nil)
        let first = panel("Providers")
        section.setPanels([first, panel("Summaries")])
        _ = section.view
        #expect(tabBar(in: section)?.isHidden == false)
        #expect(tabBar(in: section)?.segmentCount == 2)

        section.setPanels([first])
        #expect(tabBar(in: section)?.isHidden == true)
    }
}
