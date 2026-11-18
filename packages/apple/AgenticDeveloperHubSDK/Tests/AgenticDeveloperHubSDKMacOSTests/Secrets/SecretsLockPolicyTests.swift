import Foundation
import Testing
@testable import AgenticDeveloperHubSDKMacOS

@Suite("SecretsLockPolicy")
struct SecretsLockPolicyTests {

    private let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test("0 minutes never locks")
    func never() {
        #expect(!SecretsLockPolicy.isIdle(since: start, now: start.addingTimeInterval(86_400), minutes: 0))
    }

    @Test("locks once the minutes have passed, not before")
    func threshold() {
        #expect(!SecretsLockPolicy.isIdle(since: start, now: start.addingTimeInterval(299), minutes: 5))
        #expect(SecretsLockPolicy.isIdle(since: start, now: start.addingTimeInterval(300), minutes: 5))
    }

    @Test("the idle choices start with never")
    func choices() {
        #expect(SecretsSettingsPanel.idleLabel(0) == "Never")
        #expect(SecretsSettingsPanel.idleLabel(1) == "1 minute")
        #expect(SecretsSettingsPanel.idleLabel(15) == "15 minutes")
    }
}
