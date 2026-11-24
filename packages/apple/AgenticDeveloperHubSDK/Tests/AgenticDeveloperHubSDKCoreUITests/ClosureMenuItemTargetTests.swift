import AppKit
import Testing
import AgenticDeveloperHubSDKCoreUI

@MainActor
@Suite("ClosureMenuItemTarget")
struct ClosureMenuItemTargetTests {

    @Test func test_performMenuAction_runsClosure_and_validate_setsCheckState() {
        var count = 0
        let target = ClosureMenuItemTarget(
            action: { count += 1 },
            isEnabled: { false },
            isChecked: { true }
        )
        target.performMenuAction(nil)
        #expect(count == 1)

        let item = NSMenuItem(title: "x", action: nil, keyEquivalent: "")
        let enabled = target.validateMenuItem(item)
        #expect(item.state == .on)
        #expect(enabled == false)
    }
}
