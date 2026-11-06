import AppKit
import Testing
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
@Suite("SectionTopicsPanel")
struct SectionTopicsPanelTests {

    private func panel(_ title: String) -> ComposableSettings.SettingsPanelViewController {
        ComposableSettings.SettingsPanelViewController(with: .init(title: title))
    }

    private func isListCollapsed(_ section: ComposableSettings.SectionTopicsPanel) -> Bool? {
        section.splitViewItems.first?.isCollapsed
    }

    @Test("A section with one panel shows no topic list")
    func onePanelHidesList() {
        let section = ComposableSettings.SectionTopicsPanel(section: "Web Browser", icon: nil)
        section.setSectionPanels([panel("Web Browser")])
        _ = section.view
        #expect(section.showsSidebar == false)
        #expect(isListCollapsed(section) == true)
    }

    @Test("A section with two panels lists them vertically, and hides the list when one is left")
    func twoPanelsShowList() {
        let section = ComposableSettings.SectionTopicsPanel(section: "AI", icon: nil)
        let first = panel("Providers")
        section.setSectionPanels([first, panel("Summaries")])
        _ = section.view
        #expect(section.showsSidebar == true)
        #expect(isListCollapsed(section) == false)
        #expect(section.containedPanels.map(\.descriptor.title) == ["Providers", "Summaries"])

        section.setSectionPanels([first])
        #expect(section.showsSidebar == false)
        #expect(isListCollapsed(section) == true)
    }

    @Test("The selected topic survives a panel arriving late")
    func selectionSurvivesAddition() {
        let section = ComposableSettings.SectionTopicsPanel(section: "File Browser", icon: nil)
        let editor = panel("Editor")
        let excluded = panel("Excluded")
        section.setSectionPanels([editor, excluded])
        _ = section.view
        section.selectContainedPanel(excluded)
        section.setSectionPanels([editor, excluded, panel("File Types")])
        #expect(section.selectedContainedPanel === excluded)
    }
}
