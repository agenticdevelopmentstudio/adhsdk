import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

/// Opt-in integration test against the **live** backend. Skipped unless
/// `ADH_LIVE_TESTS=1` is set, so the default suite stays hermetic and offline.
///
/// Run with: `ADH_LIVE_TESTS=1 xcodebuild test -scheme AgenticDeveloperHubClient`.
@Suite("Live smoke (opt-in)")
struct LiveSmokeTests {

    @Test(
        "Direct transport gets 200 from the live GET /health",
        .enabled(if: ProcessInfo.processInfo.environment["ADH_LIVE_TESTS"] == "1")
    )
    func liveHealth() async throws {
        let adh = ADHClient.direct(credentials: InMemoryCredentialStore())
        let output = try await adh.api.getHealth()
        _ = try output.ok  // throws unless the backend answered 200
    }
}
