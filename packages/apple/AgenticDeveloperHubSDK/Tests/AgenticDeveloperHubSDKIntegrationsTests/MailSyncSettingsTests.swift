import Testing
import Foundation
@testable import AgenticDeveloperHubSDKIntegrations

@Suite("MailSyncSettings")
struct MailSyncSettingsTests {

    @Test("the default carries the five constraint values")
    func defaultValues() {
        let value = MailSyncSettings.default
        #expect(value.includeArchived == false)
        #expect(value.includeSpam == false)
        #expect(value.includeTrash == false)
        #expect(value.windowDays == 30)
        #expect(value.pollIntervalMinutes == 15)
    }

    @Test("filed is always allowed; the rest follow the flags")
    func allows() {
        let value = MailSyncSettings.default
        #expect(value.allows(.filed))
        #expect(!value.allows(.archived))
        #expect(!value.allows(.spam))
        #expect(!value.allows(.trash))
        var open = value
        open.includeArchived = true
        open.includeSpam = true
        open.includeTrash = true
        #expect(open.allows(.archived) && open.allows(.spam) && open.allows(.trash))
    }

    @Test("validated rejects out-of-range numbers", arguments: [
        (0, 15), (3651, 15), (30, 0), (30, 1441)
    ])
    func rejects(window: Int, poll: Int) {
        var value = MailSyncSettings.default
        value.windowDays = window
        value.pollIntervalMinutes = poll
        #expect(throws: IntegrationError.self) { try value.validated() }
    }

    @Test("validated accepts the default and the boundaries")
    func accepts() throws {
        #expect(try MailSyncSettings.default.validated() == .default)
        var value = MailSyncSettings.default
        value.windowDays = 3650
        value.pollIntervalMinutes = 1440
        #expect(try value.validated() == value)
        value.windowDays = 1
        value.pollIntervalMinutes = 1
        #expect(try value.validated() == value)
    }

    @Test("an empty JSON object decodes to the default")
    func lenientDecode() throws {
        let decoded = try JSONDecoder().decode(MailSyncSettings.self, from: Data("{}".utf8))
        #expect(decoded == .default)
    }

    @Test("a partial object keeps the keys it has")
    func partialDecode() throws {
        let json = Data(#"{"includeSpam":true,"windowDays":10}"#.utf8)
        let decoded = try JSONDecoder().decode(MailSyncSettings.self, from: json)
        #expect(decoded.includeSpam && decoded.windowDays == 10)
        #expect(decoded.pollIntervalMinutes == 15)
    }

    @Test("the error descriptions are human-readable")
    func errorText() {
        #expect(IntegrationError.revoked.errorDescription == "Google access was revoked — sign in again")
        #expect(IntegrationError.notConfigured.errorDescription
            == "Gmail is not configured — import an OAuth client JSON first")
    }
}
