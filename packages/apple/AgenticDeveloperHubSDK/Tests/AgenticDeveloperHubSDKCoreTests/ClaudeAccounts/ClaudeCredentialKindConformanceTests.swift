@testable import AgenticDeveloperHubSDKCore
import XCTest

final class ClaudeCredentialKindConformanceTests: XCTestCase {

    func testV001_rawValues() {
        XCTAssertEqual(ClaudeCredentialKind.oauth.rawValue, "oauth")
        XCTAssertEqual(ClaudeCredentialKind.longLived.rawValue, "long-lived")
        XCTAssertEqual(ClaudeCredentialKind.allCases.count, 2)
    }

    func testV002_titles() {
        XCTAssertEqual(ClaudeCredentialKind.oauth.title, "OAuth")
        XCTAssertEqual(ClaudeCredentialKind.longLived.title, "Long-lived")
    }

    func testV003_oauthKey() {
        XCTAssertEqual(ClaudeCredentialKind.oauth.key(for: "alice@example.com"), "oauth:alice@example.com")
    }

    func testV004_longLivedKeyIsDistinct() {
        let long = ClaudeCredentialKind.longLived.key(for: "alice@example.com")
        XCTAssertEqual(long, "long-lived:alice@example.com")
        XCTAssertNotEqual(long, ClaudeCredentialKind.oauth.key(for: "alice@example.com"))
    }

    func testV005_absentOrEmptyRawKindGivesBareAccount() {
        XCTAssertEqual(ClaudeCredentialKind.key(account: "alice@example.com", kindRawValue: nil), "alice@example.com")
        XCTAssertEqual(ClaudeCredentialKind.key(account: "alice@example.com", kindRawValue: ""), "alice@example.com")
    }

    func testV006_unknownRawKindStillGivesDistinctKey() {
        XCTAssertEqual(ClaudeCredentialKind.key(account: "alice@example.com", kindRawValue: "future-kind"),
                       "future-kind:alice@example.com")
    }

    func testV007_parseOAuthKey() throws {
        let parsed = try XCTUnwrap(ClaudeCredentialKind.parse(itemKey: "oauth:alice@example.com"))
        XCTAssertEqual(parsed.kind, .oauth)
        XCTAssertEqual(parsed.name, "alice@example.com")
    }

    func testV008_legacyAndUnknownKeysParseToNothing() {
        XCTAssertNil(ClaudeCredentialKind.parse(itemKey: "alice@example.com"))
        XCTAssertNil(ClaudeCredentialKind.parse(itemKey: "future-kind:alice@example.com"))
    }

    func testV009_nameKeepsColonsAfterTheFirst() throws {
        let parsed = try XCTUnwrap(ClaudeCredentialKind.parse(itemKey: "long-lived:team:alice"))
        XCTAssertEqual(parsed.kind, .longLived)
        XCTAssertEqual(parsed.name, "team:alice")
    }
}
