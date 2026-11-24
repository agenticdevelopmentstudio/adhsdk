@testable import AgenticDeveloperHubSDKCore
import XCTest

final class ClaudeOAuthCredentialConformanceTests: XCTestCase {

    func testV001_defaultsWhenOnlyTokensGiven() {
        let credential = ClaudeOAuthCredential(accessToken: "a", refreshToken: "r")
        XCTAssertNil(credential.expiresAt)
        XCTAssertNil(credential.refreshTokenExpiresAt)
        XCTAssertEqual(credential.scopes, [])
        XCTAssertNil(credential.subscriptionType)
        XCTAssertNil(credential.rateLimitTier)
    }

    func testV002_expiryStaysMillisecondsAndSecondsAreDerived() {
        let credential = ClaudeOAuthCredential(accessToken: "a", refreshToken: "r", expiresAt: 1_750_000_000_000)
        XCTAssertEqual(credential.expirySeconds, 1_750_000_000)
        XCTAssertEqual(credential.expiresAt, 1_750_000_000_000)
    }

    func testV003_absentRefreshExpiryHasNoSeconds() {
        let credential = ClaudeOAuthCredential(accessToken: "a", refreshToken: "r")
        XCTAssertNil(credential.refreshExpirySeconds)
    }

    func testV004_differentRefreshTokenIsNotEqual() {
        XCTAssertNotEqual(ClaudeOAuthCredential(accessToken: "a", refreshToken: "r1"),
                          ClaudeOAuthCredential(accessToken: "a", refreshToken: "r2"))
    }

    func testV005_copyIsEqual() {
        let credential = ClaudeOAuthCredential(accessToken: "a", refreshToken: "r", expiresAt: 5)
        let copy = credential
        XCTAssertEqual(credential, copy)
    }

    func testV006_codableRoundTrip() throws {
        let credential = ClaudeOAuthCredential(accessToken: "a", refreshToken: "r", expiresAt: 1000,
                                               refreshTokenExpiresAt: 2000, scopes: ["user:inference"],
                                               subscriptionType: "max", rateLimitTier: "t1")
        let data = try JSONEncoder().encode(credential)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["accessToken"] as? String, "a")
        XCTAssertEqual(object["refreshToken"] as? String, "r")
        XCTAssertEqual(try JSONDecoder().decode(ClaudeOAuthCredential.self, from: data), credential)
    }

    func testV007_rotatedCredentialIsNotEqualToSaved() {
        let live = ClaudeOAuthCredential(accessToken: "a2", refreshToken: "r2", expiresAt: 2000)
        let saved = ClaudeOAuthCredential(accessToken: "a1", refreshToken: "r1", expiresAt: 1000)
        XCTAssertNotEqual(live, saved)
    }
}
