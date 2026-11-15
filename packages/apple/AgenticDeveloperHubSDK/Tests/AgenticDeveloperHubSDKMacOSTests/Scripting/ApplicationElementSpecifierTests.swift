import Testing
import AppKit
import Foundation
@testable import AgenticDeveloperHubSDKMacOS

/// `applicationElementSpecifier` reads `NSApp`'s own scripting class
/// description, so these run against the test host's application object.
@Suite("applicationElementSpecifier")
@MainActor
struct ApplicationElementSpecifierTests {

    @Test("scripting-016: builds a unique-id locator hanging directly off the application")
    func scripting016BuildsTheLocator() throws {
        _ = NSApplication.shared
        let applicationClass = try #require(
            NSApp.classDescription as? NSScriptClassDescription,
            "the host application has no scripting class description")
        var calls = 0
        var calledOnMain = false

        let specifier = applicationElementSpecifier(key: "panes") {
            calls += 1
            calledOnMain = Thread.isMainThread
            return "some-uuid"
        }

        let unique = try #require(specifier as? NSUniqueIDSpecifier)
        #expect(unique.key == "panes")
        #expect(unique.uniqueID as? String == "some-uuid")
        #expect(unique.container == nil)
        #expect(unique.containerClassDescription === applicationClass)
        #expect(calls == 1)
        #expect(calledOnMain)
    }

    @Test(.disabled(Comment(rawValue:
        "scripting-017: NSApp's class description always resolves to a scripting class description "
            + "in a running application, so the nil fallback cannot be reached without replacing NSApp")))
    func scripting017NilFallback() {}
}
