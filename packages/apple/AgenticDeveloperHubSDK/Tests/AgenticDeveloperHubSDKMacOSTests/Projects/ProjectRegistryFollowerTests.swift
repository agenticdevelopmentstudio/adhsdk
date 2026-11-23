import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// An app with window state but no project coordinator (ADTerminal) keeps a
/// local row for every registry project through the follower. The registry
/// here is a second `ProjectDatabase`, a `ProjectRegistry` like adhd's.
@MainActor
final class ProjectRegistryFollowerTests: XCTestCase {

    private var registry: ProjectDatabase!
    private var windowState: ProjectDatabase!
    private var follower: ProjectRegistryFollower?

    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = TestTempDirectory.make(label: "project-registry-follower-test")
        registry = try ProjectDatabase(path: directory.appendingPathComponent("Registry.db").path)
        windowState = try ProjectDatabase(path: directory.appendingPathComponent("Projects.db").path)
    }

    override func tearDownWithError() throws {
        follower?.stop()
        follower = nil
        registry = nil
        windowState = nil
        try super.tearDownWithError()
    }

    func testStartMirrorsTheProjectsAlreadyRegistered() async throws {
        let alpha = GitRepo(path: "/tmp/follower-alpha", name: "alpha")
        try registry.insert(alpha)

        startFollowing()

        try await waitUntil("alpha mirrored") { try self.windowState.repo(id: alpha.id) != nil }
    }

    func testARegistryChangeReachesTheLocalFile() async throws {
        startFollowing()
        var beta = GitRepo(path: "/tmp/follower-beta", name: "beta")

        try registry.insert(beta)
        try await waitUntil("beta inserted") { try self.windowState.repo(id: beta.id) != nil }

        beta.name = "beta renamed"
        try registry.update(beta)
        try await waitUntil("beta renamed") { try self.windowState.repo(id: beta.id)?.name == "beta renamed" }

        try registry.delete(id: beta.id)
        try await waitUntil("beta deleted") { try self.windowState.repo(id: beta.id) == nil }
    }

    /// The row at the kept path is the app's own; a registry project there is
    /// never mirrored, so the local row and its layout stay.
    func testTheKeptPathIsNeverMirrored() async throws {
        let home = "/tmp/follower-home"
        let local = GitRepo(path: home, name: "home")
        try windowState.insert(local)
        let shared = GitRepo(path: home, name: "registered home")
        try registry.insert(shared)
        let other = GitRepo(path: "/tmp/follower-other", name: "other")

        startFollowing(keepingLocal: home)
        try registry.insert(other)

        try await waitUntil("other mirrored") { try self.windowState.repo(id: other.id) != nil }
        XCTAssertEqual(try windowState.repo(path: home, kind: .project)?.id, local.id)
        XCTAssertNil(try windowState.repo(id: shared.id))
    }

    func testStopLeavesTheMirroredRowsAndFollowsNoFurther() async throws {
        let kept = GitRepo(path: "/tmp/follower-kept", name: "kept")
        try registry.insert(kept)
        startFollowing()
        try await waitUntil("kept mirrored") { try self.windowState.repo(id: kept.id) != nil }

        follower?.stop()
        let late = GitRepo(path: "/tmp/follower-late", name: "late")
        try registry.insert(late)
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertNotNil(try windowState.repo(id: kept.id))
        XCTAssertNil(try windowState.repo(id: late.id))
    }

    // MARK: - Helpers

    private func startFollowing(keepingLocal path: String? = nil) {
        let follower = ProjectRegistryFollower(
            registry: registry, mirror: LocalProjectMirror(database: windowState), keepingLocal: path)
        follower.start(onFailure: { error in XCTFail("follower failed: \(error)") })
        self.follower = follower
    }

    private func waitUntil(
        _ what: String, timeout: Duration = .seconds(5), _ condition: () throws -> Bool
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while try !condition() {
            if ContinuousClock.now >= deadline { return XCTFail("timed out waiting for \(what)") }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}
