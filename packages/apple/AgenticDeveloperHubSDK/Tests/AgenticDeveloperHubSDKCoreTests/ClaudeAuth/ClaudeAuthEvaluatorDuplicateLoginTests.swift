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

    func testACopyJudgedUsableByItsOwnMarginIsRotatedWithTheRefreshedCopy() async throws {
        let endpoint = FakeEndpoint()
        // Twenty minutes left: expired by the first copy's thirty-minute margin,
        // usable by the default five-minute one the other two copies carry.
        let expiresAt = (Date().timeIntervalSince1970 + 20 * 60) * 1000
        let login = ClaudeOAuthCredential(
            accessToken: "old-access", refreshToken: "shared-refresh", expiresAt: expiresAt)
        let credentials = [
            Sessions.ClaudeCredentialDTO(
                account: "a", token: login.accessToken, itemKey: "oauth:a", oauth: login,
                refreshWithin: 30 * 60),
            Sessions.ClaudeCredentialDTO(
                account: "a", token: login.accessToken, itemKey: "claude-code:a", oauth: login),
            Sessions.ClaudeCredentialDTO(account: "a", token: login.accessToken, oauth: login)
        ]

        let outcome = await ClaudeAuthEvaluator.evaluate(credentials, refresh: { try await endpoint.refresh($0) })

        let calls = await endpoint.calls
        XCTAssertEqual(calls, 1, "the shared refresh token is spent once")
        XCTAssertEqual(outcome.statuses.map(\.state), ["refreshed", "refreshed", "usable"],
                       "the usable copy with an item key takes the fresh pair; the keyless one cannot store it")
        XCTAssertEqual(outcome.rotated.map(\.itemKey), ["oauth:a", "claude-code:a"])
        XCTAssertEqual(Set(outcome.rotated.map(\.oauth.refreshToken)).count, 1, "both items get the same fresh pair")
        XCTAssertEqual(outcome.probeable.map(\.token), ["access-1", "access-1", "old-access"])
    }

    /// Two identical expired copies under one item key: the token is spent
    /// once and the item is rotated once, not twice.
    func testTwoIdenticalCopiesUnderOneItemKeyAreRotatedOnce() async throws {
        let endpoint = FakeEndpoint()
        let login = expiredLogin(refreshToken: "shared-refresh")
        let copy = Sessions.ClaudeCredentialDTO(
            account: "a@x.com", credentialKind: "oauth", token: login.accessToken,
            itemKey: "oauth:a@x.com", oauth: login)

        let outcome = await ClaudeAuthEvaluator.evaluate([copy, copy], refresh: { try await endpoint.refresh($0) })

        let calls = await endpoint.calls
        XCTAssertEqual(calls, 1, "the shared refresh token is spent once")
        XCTAssertEqual(outcome.rotated.map(\.itemKey), ["oauth:a@x.com"], "one rotation for the one item")
        XCTAssertEqual(outcome.statuses.map(\.state), ["refreshed", "refreshed"])
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
