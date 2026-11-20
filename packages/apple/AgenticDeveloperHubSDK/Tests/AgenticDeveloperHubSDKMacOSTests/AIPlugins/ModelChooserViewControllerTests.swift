import XCTest
import AgenticDeveloperHubSDKCore
import AIPluginKit
@testable import AgenticDeveloperHubSDKMacOS

/// The model chooser's commit rules, driven without a popover.
@MainActor
final class ModelChooserViewControllerTests: XCTestCase {

    private func chooser(models: [String], current: String) -> (ModelChooserViewController, () -> [String]) {
        let template = AIPluginDescriptor.ProviderTemplate(
            id: "t-\(UUID().uuidString)", displayName: "Test", models: models, secretRequired: false)
        let context = ModelChooserContext(
            pluginIdentifier: "test.plugin", template: template, baseURL: "", apiKey: nil,
            currentModel: current)
        let controller = ModelChooserViewController(context: context)
        _ = controller.view
        var chosen: [String] = []
        controller.onChoose = { chosen.append($0) }
        return (controller, { chosen })
    }

    /// A double-click sends the click action and then the double-click action
    /// for the same row: one choice, not two.
    func testTheSameRowCommittedTwiceIsChosenOnce() {
        let (controller, chosen) = chooser(models: ["alpha", "beta"], current: "alpha")
        controller.selectRow(1)
        controller.commit(thenClose: false)
        controller.commit(thenClose: true)
        XCTAssertEqual(chosen(), ["beta"])
    }

    func testAnotherRowAfterwardIsANewChoice() {
        let (controller, chosen) = chooser(models: ["alpha", "beta"], current: "alpha")
        controller.selectRow(1)
        controller.commit(thenClose: false)
        controller.selectRow(0)
        controller.commit(thenClose: false)
        XCTAssertEqual(chosen(), ["beta", "alpha"])
    }
}
