import Testing
import AppKit
import Foundation
@testable import AgenticDeveloperHubSDKMacOS

/// `applicationElementSpecifier` reads `NSApp`'s own scripting class
/// description, so these run against the test host's application object.
///
/// Whether that description resolves depends on the host: an app with a
/// scripting definition has one, a bare `xctest` process does not. Each vector
/// states which of the two it needs and runs only where it holds. Never read
/// it through `NSApp.classDescription` — that property is imported as
/// non-optional, so a host without one traps instead of answering nil.
@MainActor
private func hostApplicationScriptDescription() -> NSScriptClassDescription? {
    let app = NSApplication.shared
    return NSScriptClassDescription(for: type(of: app))
}

/// The traits' form of the question: they run off the main actor, and the
/// description itself is not `Sendable`, so only the answer crosses back.
@MainActor
private func hostHasApplicationScriptDescription() -> Bool {
    hostApplicationScriptDescription() != nil
}

@Suite("applicationElementSpecifier")
@MainActor
struct ApplicationElementSpecifierTests {

    @Test(
        "scripting-016: builds a unique-id locator hanging directly off the application",
        .enabled("needs a host whose application resolves to a scripting class description") {
            await hostHasApplicationScriptDescription()
        })
    func scripting016BuildsTheLocator() throws {
        let applicationClass = try #require(
            hostApplicationScriptDescription(),
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

    @Test(
        "scripting-017: answers nil when the application has no scripting class description",
        .enabled("needs a host whose application has no scripting class description") {
            await !hostHasApplicationScriptDescription()
        })
    func scripting017NilFallback() {
        var calls = 0

        let specifier = applicationElementSpecifier(key: "panes") {
            calls += 1
            return "some-uuid"
        }

        #expect(specifier == nil)
        #expect(calls == 0)
    }
}
