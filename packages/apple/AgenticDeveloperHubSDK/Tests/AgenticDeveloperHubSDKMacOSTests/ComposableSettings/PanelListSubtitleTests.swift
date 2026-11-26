import XCTest
import AppKit
@testable import AgenticDeveloperHubSDKMacOS

/// The descriptor's subtitle and how the settings sidebar follows it
/// (settings-panel spvc-017–018, settings-panel-list cts-panel-list-018–021).
@MainActor
final class PanelListSubtitleTests: XCTestCase {

    /// Records every row set the list is handed.
    private final class RecordingList: ComposableSettings.PanelListViewController {
        var handed: [[TopicListSection]] = []
        override func setSections(_ sections: [TopicListSection]) {
            handed.append(sections)
            super.setSections(sections)
        }
        var lastItems: [any TopicListItemProtocol] { handed.last?.flatMap(\.items) ?? [] }
    }

    private func panel(_ title: String, subtitle: String? = nil) -> ComposableSettings.SettingsPanelViewController {
        ComposableSettings.SettingsPanelViewController(with: .init(title: title, subtitle: subtitle))
    }

    private func makeList() -> RecordingList {
        let list = RecordingList(nibName: nil, bundle: nil)
        _ = list.view
        return list
    }

    /// Lets the list's next-turn rebuild run.
    ///
    /// The rebuild is a `DispatchQueue.main.async` block, and the main queue
    /// runs its blocks in order, so a marker enqueued after the change has run
    /// only once the rebuild has. A fixed 50 ms spin was a guess at the
    /// machine's load: on a parallel run the block had not run yet, and a
    /// burst read as no rebuild at all.
    private func drainMainQueue() {
        var drained = false
        DispatchQueue.main.async { drained = true }
        let deadline = Date().addingTimeInterval(10)
        while !drained && Date() < deadline {
            RunLoop.main.run(mode: .default, before: deadline)
        }
        XCTAssertTrue(drained, "the main queue never reached the marker")
    }

    /// spvc-017
    func testADescriptorHasNoSubtitleByDefault() {
        XCTAssertNil(ComposableSettings.SettingsPanelDescriptor(title: "General").subtitle)
    }

    /// cts-panel-list-018
    func testARowCarriesItsDescriptorsSubtitle() {
        let list = makeList()
        list.setPanels([panel("Claude", subtitle: "Anthropic - API Key"), panel("General")])

        XCTAssertEqual(list.lastItems.map(\.subtitle), ["Anthropic - API Key", nil])
    }

    /// cts-panel-list-019, spvc-018
    func testChangingTheSubtitleRebuildsTheRows() {
        let list = makeList()
        let claude = panel("Claude", subtitle: "Anthropic")
        list.setPanels([claude])

        claude.descriptor.subtitle = "Anthropic - API Key"
        drainMainQueue()

        XCTAssertEqual(list.lastItems.first?.subtitle, "Anthropic - API Key")
    }

    /// cts-panel-list-020
    func testChangingTheTitleRebuildsTheRows() {
        let list = makeList()
        let claude = panel("Claude")
        list.setPanels([claude])

        claude.descriptor.title = "Claude Work"
        drainMainQueue()

        XCTAssertEqual(list.lastItems.first?.title, "Claude Work")
    }

    func testABurstOfChangesRebuildsOnce() {
        let list = makeList()
        let claude = panel("Claude")
        list.setPanels([claude])
        let before = list.handed.count

        claude.descriptor.title = "Claude Work"
        claude.descriptor.subtitle = "Anthropic"
        drainMainQueue()

        XCTAssertEqual(list.handed.count, before + 1)
    }

    /// cts-panel-list-021
    func testAPanelThatLeftTheListIsNoLongerObserved() {
        let list = makeList()
        let gone = panel("Gone")
        list.setPanels([gone])
        list.setPanels([panel("Kept")])
        let before = list.handed.count

        gone.descriptor.title = "Renamed"
        drainMainQueue()

        XCTAssertEqual(list.handed.count, before)
        XCTAssertEqual(list.lastItems.map(\.title), ["Kept"])
    }
}
