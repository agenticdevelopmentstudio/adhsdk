import Foundation
import Testing
@testable import AgenticDeveloperHubSDK

@Suite("Loggable conformance")
struct LoggableConformanceTests {

    struct LoggableFixture {}

    @Test("fc-035: subsystem is the bundle identifier and category is the type name")
    func fc035_defaultSubsystemAndCategory() {
        #expect(LoggableFixture.subsystem == (Bundle.main.bundleIdentifier ?? "nil"))
        #expect(LoggableFixture.category == "LoggableFixture")
    }

    @Test("fc-036: an instance's logger is the type-level logger",
          .disabled("Logger is an opaque value type with no equality, so identity cannot be asserted"))
    func fc036_instanceForwarding() {}
}

extension LoggableConformanceTests.LoggableFixture: Loggable {
    public static nonisolated let logger = makeLogger()
}
