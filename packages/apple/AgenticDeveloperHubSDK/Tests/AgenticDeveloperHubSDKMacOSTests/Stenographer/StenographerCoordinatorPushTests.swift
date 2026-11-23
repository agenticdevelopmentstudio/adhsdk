import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// `SessionsCoordinator` and `OversightCoordinator` start the summary and
/// oversight preference pushes in `start()` unless built with
/// `pushesPreferences: false`, which a host whose service reaches no daemon
/// (the Kitchen under `APP_TEST_HOME`) passes so nothing fails and retries.
@MainActor
final class StenographerCoordinatorPushTests: XCTestCase {

    override func tearDown() async throws {
        StenographerOversightPrefsPush.stopObserving()
        StenographerSummaryPrefsPush.stopObserving()
        UserSettings.stenographerAISummariesSeededFromDaemon.remove()
        UserSettings.stenographerAIOversightSeededFromDaemon.remove()
        for settings in SummaryFeatureSettings.all where settings.feature != .sessions {
            settings.seeded.remove()
        }
        try await super.tearDown()
    }

    func testBothCoordinatorsPushByDefault() {
        let service = StubDaemonService()
        let registry = CommandRegistry()

        XCTAssertTrue(SessionsCoordinator(service: service, commandRegistry: registry).pushesPreferences)
        XCTAssertTrue(OversightCoordinator(service: service, commandRegistry: registry).pushesPreferences)
    }

    func testOversightStartPushesWhenAsked() async throws {
        let daemon = StubDaemonService()
        let coordinator = OversightCoordinator(service: daemon, commandRegistry: CommandRegistry())

        try coordinator.start()
        await StenographerOversightPrefsPush.awaitPendingPush()

        XCTAssertEqual(daemon.oversightRequests.count, 1)
    }

    func testOversightStartWithoutPushesReachesNoDaemon() async throws {
        let daemon = StubDaemonService()
        let coordinator = OversightCoordinator(
            service: daemon, commandRegistry: CommandRegistry(), pushesPreferences: false)

        try coordinator.start()
        await StenographerOversightPrefsPush.awaitPendingPush()

        XCTAssertEqual(daemon.oversightGets, 0)
        XCTAssertTrue(daemon.oversightRequests.isEmpty)
    }

    func testSessionsStartWithoutPushesReachesNoDaemon() async throws {
        let daemon = StubDaemonService()
        let coordinator = SessionsCoordinator(
            service: daemon, commandRegistry: CommandRegistry(), pushesPreferences: false)

        try coordinator.start()
        await StenographerSummaryPrefsPush.awaitPendingPush()

        XCTAssertEqual(daemon.summaryGets, 0)
        XCTAssertTrue(daemon.summaryRequests.isEmpty)
    }
}
