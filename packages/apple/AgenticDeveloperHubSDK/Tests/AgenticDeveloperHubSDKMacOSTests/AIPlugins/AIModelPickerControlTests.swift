import XCTest
import AgenticDeveloperHubSDKCore
import AIPluginKit
@testable import AgenticDeveloperHubSDKMacOS

/// The model row builds its chooser context (which reads the provider's API
/// key) once, not on every refresh.
@MainActor
final class AIModelPickerControlTests: XCTestCase {

    private func control(builds: @escaping () -> Void) -> AIModelPickerControl {
        let template = AIPluginDescriptor.ProviderTemplate(
            id: "t-\(UUID().uuidString)", displayName: "Test", models: ["alpha"], secretRequired: false)
        return AIModelPickerControl(
            displayName: { "alpha" },
            context: {
                builds()
                return ModelChooserContext(
                    pluginIdentifier: "test.plugin", template: template, baseURL: "", apiKey: nil,
                    currentModel: "alpha")
            },
            onChoose: { _ in })
    }

    func testRefreshReusesTheContext() {
        var builds = 0
        let row = control { builds += 1 }
        row.refresh()
        row.refresh()
        XCTAssertEqual(builds, 1)
        XCTAssertTrue(row.isEnabled)
    }

    func testInvalidatingBuildsANewContextOnTheNextRefresh() {
        var builds = 0
        let row = control { builds += 1 }
        row.invalidateContext()
        row.refresh()
        XCTAssertEqual(builds, 2)
    }

    func testAModelListLandingRedrawsWithoutANewContext() {
        var builds = 0
        let row = control { builds += 1 }
        let saved = ProviderModelCache.setting.value
        defer { ProviderModelCache.setting.value = saved }
        ProviderModelCache.setting.value = saved.merging(["test|\(UUID().uuidString)": .init(models: [])]) { $1 }
        XCTAssertEqual(builds, 1)
        XCTAssertEqual(row.nameText, "alpha")
    }
}
