@testable import AgenticDeveloperHubSDKCore
import XCTest

/// `duplicate-login-in-one-round`: one login pushed under two item keys. Its
/// refresh token is spent once, and both items get the rotation.
final class ClaudeAuthEvaluatorDuplicateLoginTests: XCTestCase {

    /// Counts calls, and answers `.spent` for a refresh token it has already
    /// rotated, as the real token endpoint does.
    private actor FakeEndpoint {
        private(set) var calls = 0
        private var spentTokens: Set<String> = []

        func refresh(_ oauth: ClaudeOAuthCredential) async throws -> ClaudeOAuthCredential {
            calls += 1
            guard !spentTokens.contains(oauth.refreshToken) else { throw ClaudeOAuthRefreshError.spent }
            spentTokens.insert(oauth.refreshToken)
            // Let a racing second refresh reach the endpoint if nothing stops it.
            try await Task.sleep(nanoseconds: 50_000_000)
            return ClaudeOAuthCredential(
                accessToken: "access-\(calls)", refreshToken: "refresh-\(calls)",
                expiresAt: (Date().timeIntervalSince1970 + 8 * 3600) * 1000)
        }
    }

    private func expiredLogin(refreshToken: String) -> ClaudeOAuthCredential {
        ClaudeOAuthCredential(accessToken: "old-access", refreshToken: refreshToken, expiresAt: 0)
    }

    func testOneLoginUnderTwoItemKeysIsRefreshedOnceAndBothItemsAreRotated() async throws {
        let endpoint = FakeEndpoint()
        let login = expiredLogin(refreshToken: "shared-refresh")
        let credentials = [
            Sessions.ClaudeCredentialDTO(
                account: "a@x.com", credentialKind: "oauth", token: login.accessToken,
                itemKey: "oauth:a@x.com", oauth: login),
            Sessions.ClaudeCredentialDTO(
                account: "a@x.com", credentialKind: "oauth", token: login.accessToken,
                itemKey: "claude-code:a@x.com", oauth: login)
        ]

        let outcome = await ClaudeAuthEvaluator.evaluate(credentials, refresh: { try await endpoint.refresh($0) })

        let calls = await endpoint.calls
        XCTAssertEqual(calls, 1, "the shared refresh token is spent once")
        XCTAssertEqual(outcome.statuses.map(\.state), ["refreshed", "refreshed"], "neither copy is reported spent")
        XCTAssertEqual(Set(outcome.rotated.map(\.itemKey)), ["oauth:a@x.com", "claude-code:a@x.com"])
        XCTAssertEqual(Set(outcome.rotated.map(\.oauth.refreshToken)).count, 1, "both items get the same fresh pair")
        XCTAssertEqual(outcome.probeable.count, 2)
    }

    func testDifferentLoginsAreEachRefreshed() async throws {
        let endpoint = FakeEndpoint()
        let first = expiredLogin(refreshToken: "refresh-a")
        let second = expiredLogin(refreshToken: "refresh-b")
        let credentials = [
            Sessions.ClaudeCredentialDTO(account: "a", token: first.accessToken, itemKey: "oauth:a", oauth: first),
            Sessions.ClaudeCredentialDTO(account: "b", token: second.accessToken, itemKey: "oauth:b", oauth: second)
        ]

        let outcome = await ClaudeAuthEvaluator.evaluate(credentials, refresh: { try await endpoint.refresh($0) })

        let calls = await endpoint.calls
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(outcome.statuses.map(\.state), ["refreshed", "refreshed"])
    }

    func testAFailedSharedRefreshIsReportedTheSameForEveryCopy() async throws {
        let login = expiredLogin(refreshToken: "dead-refresh")
        let credentials = [
            Sessions.ClaudeCredentialDTO(account: "a", token: login.accessToken, itemKey: "one", oauth: login),
            Sessions.ClaudeCredentialDTO(account: "a", token: login.accessToken, itemKey: "two", oauth: login)
        ]

        let outcome = await ClaudeAuthEvaluator.evaluate(credentials, refresh: { _ in
            throw ClaudeOAuthRefreshError.rateLimited
        })

        XCTAssertEqual(outcome.statuses.map(\.state), ["rate_limited", "rate_limited"])
        XCTAssertTrue(outcome.rotated.isEmpty)
    }
}
