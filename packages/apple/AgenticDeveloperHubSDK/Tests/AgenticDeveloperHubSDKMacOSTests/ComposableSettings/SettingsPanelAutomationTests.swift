import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// What a UI driver relies on in the settings split view: a panel can be picked by
/// name, and a shown panel's view is an accessibility group with a stable identifier.
@MainActor
final class SettingsPanelAutomationTests: XCTestCase {

    private final class StubPanel: NSViewController, ComposableSettingsPanel {
        let descriptor: ComposableSettings.SettingsPanelDescriptor
        let presetIdentifier: String?
        var hostsOwnScroll: Bool { false }
        var helpContent: ComposableSettings.PanelHelp? { nil }
        var effectiveHelpContent: ComposableSettings.PanelHelp? { nil }
        init(_ title: String, identifier: String? = nil) {
            descriptor = ComposableSettings.SettingsPanelDescriptor(title: title)
            presetIdentifier = identifier
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError() }
        override func loadView() {
            view = NSView()
            if let presetIdentifier { view.setAccessibilityIdentifier(presetIdentifier) }
        }
    }

    private func makeSplit(_ panels: [StubPanel]) -> ComposableSettings.SplitViewController {
        let split = ComposableSettings.SplitViewController()
        _ = split.view
        split.setPanels(panels)
        return split
    }

    func testThePanelIdentifierIsTheSlugOfItsTitle() {
        XCTAssertEqual(
            ComposableSettings.SplitViewController.panelAccessibilityIdentifier(for: StubPanel("Mail Source")),
            "settings.panel.mail-source")
    }

    func testAPanelIsSelectedByItsTitleIgnoringCase() {
        let split = makeSplit([StubPanel("General"), StubPanel("Mail Source")])
        XCTAssertTrue(split.selectPanel(named: "mail source"))
        XCTAssertEqual(split.selectedPanel?.descriptor.title, "Mail Source")
    }

    func testAPanelIsSelectedByTheSlugOfItsTitle() {
        let split = makeSplit([StubPanel("General"), StubPanel("Mail Source")])
        XCTAssertTrue(split.selectPanel(named: "mail-source"))
        XCTAssertEqual(split.selectedPanel?.descriptor.title, "Mail Source")
    }

    func testAnUnknownNameSelectsNothingAndReturnsFalse() {
        let split = makeSplit([StubPanel("General"), StubPanel("Tracking")])
        split.selectPanel(at: 1)
        XCTAssertFalse(split.selectPanel(named: "No Such Panel"))
        XCTAssertEqual(split.selectedPanel?.descriptor.title, "Tracking")
    }

    func testAShownPanelViewBecomesAnIdentifiedGroup() {
        let panel = StubPanel("Tracking")
        let split = makeSplit([StubPanel("General"), panel])
        split.selectPanel(at: 1)
        XCTAssertEqual(panel.view.accessibilityIdentifier(), "settings.panel.tracking")
        XCTAssertTrue(panel.view.isAccessibilityElement())
        XCTAssertEqual(panel.view.accessibilityRole(), .group)
        XCTAssertEqual(panel.view.accessibilityLabel(), "Tracking")
    }

    private final class TwoControlRow: NSView, ComposableSettings.ExplainedSettingsView {
        let label = NSTextField(labelWithString: "Read mail from")
        let first = NSPopUpButton()
        let second = NSButton(title: "Refresh", target: nil, action: nil)
        var settingTitle: String? { "Read mail from" }
        var settingExplanation: String? { nil }
        init(presetSecond: String? = nil) {
            super.init(frame: .zero)
            let stack = NSStackView(views: [label, first, second])
            addSubview(stack)
            if let presetSecond { second.setAccessibilityIdentifier(presetSecond) }
        }
        required init?(coder: NSCoder) { fatalError() }
    }

    func testARowsControlsAreNamedForItsTitle() {
        let group = ComposableSettings.GroupView(withTitle: "Mail Source")
        let row = TwoControlRow()
        group.addSettingSubview(row)
        XCTAssertEqual(row.first.accessibilityIdentifier(), "settings.read-mail-from")
        XCTAssertEqual(row.second.accessibilityIdentifier(), "settings.read-mail-from.2")
        XCTAssertEqual(row.label.accessibilityIdentifier(), "")
    }

    func testARowControlsOwnIdentifierIsKept() {
        let group = ComposableSettings.GroupView(withTitle: "Mail Source")
        let row = TwoControlRow(presetSecond: "custom.refresh")
        group.addSettingSubview(row)
        XCTAssertEqual(row.first.accessibilityIdentifier(), "settings.read-mail-from")
        XCTAssertEqual(row.second.accessibilityIdentifier(), "custom.refresh")
    }

    func testACheckboxRowsSwitchIsNamedForItsTitle() {
        let group = ComposableSettings.GroupView(withTitle: "Startup")
        let row = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Start at Login", get: { false }, set: { _ in }))
        group.addSettingSubview(row)
        XCTAssertEqual(row.toggle.accessibilityIdentifier(), "settings.start-at-login")
    }

    // group-view-036
    func testATextAreaRowsEditorIsNamedNotItsScroller() {
        let group = ComposableSettings.GroupView(withTitle: "AI Summaries")
        let row = ComposableSettings.TextAreaEditView(with: ComposableSettings.ViewModel<String>(
            title: "Instructions sent to the model", get: { "" }, set: { _ in }))
        group.addSettingSubview(row)
        XCTAssertEqual(row.textView.accessibilityIdentifier(), "settings.instructions-sent-to-the-model")
        let scrollView = row.textView.enclosingScrollView
        XCTAssertNotNil(scrollView?.verticalScroller)
        for scroller in [scrollView?.verticalScroller, scrollView?.horizontalScroller].compactMap({ $0 }) {
            XCTAssertEqual(scroller.accessibilityIdentifier(), "")
        }
    }

    func testAPanelsOwnIdentifierIsKept() {
        let panel = StubPanel("Tracking", identifier: "custom.tracking")
        let split = makeSplit([StubPanel("General"), panel])
        split.selectPanel(at: 1)
        XCTAssertEqual(panel.view.accessibilityIdentifier(), "custom.tracking")
    }
}
