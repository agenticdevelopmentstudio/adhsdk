@testable import AgenticDeveloperHubSDKCore
import XCTest

/// `router-set-marker-failure`: a suspension marker that exists but cannot be
/// deleted. `setRouterPointer` throws and saves nothing; uninstalling with
/// `removingRouterPointer` still removes the pointer.
final class RouterPointerMarkerFailureTests: XCTestCase {

    private var tmpDir: URL!
    private var settingsURL: URL!
    private var installer: ClaudeHookInstaller!
    private var lockedDirectory: URL?

    private static let routerBaseURL = "http://127.0.0.1:22848"

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("router-marker-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        settingsURL = tmpDir.appendingPathComponent("settings.json")
        let dispatcher = try StatusLineTestSupport.makeBundledDispatcher(in: tmpDir)
        installer = ClaudeHookInstaller(
            settingsURL: settingsURL, dropDirectory: "/tmp/test-events",
            stenoPath: "/Applications/Stenographer.app/Contents/Helpers/steno",
            bundledDispatcher: dispatcher, lockTimeout: 5, stenoIsExecutable: { _ in true })
    }

    override func tearDownWithError() throws {
        if let lockedDirectory {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: lockedDirectory.path)
        }
        try? FileManager.default.removeItem(at: tmpDir)
    }

    /// Makes the suspension marker a directory holding a read-only directory
    /// with a file in it, so `removeItem` on the marker fails while the
    /// settings directory itself stays writable.
    private func makeUndeletableMarker() throws {
        let marker = installer.routerPointerSuspendedMarkerURL
        let locked = marker.appendingPathComponent("locked", isDirectory: true)
        try FileManager.default.createDirectory(at: locked, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: locked.appendingPathComponent("file"))
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: locked.path)
        lockedDirectory = locked
    }

    private func writeSettings(_ dict: [String: Any]) throws {
        try JSONSerialization.data(withJSONObject: dict).write(to: settingsURL)
    }

    private var markerExists: Bool {
        FileManager.default.fileExists(atPath: installer.routerPointerSuspendedMarkerURL.path)
    }

    func testEnableThrowsAndSavesNothingWhenTheMarkerCannotBeDeleted() throws {
        try writeSettings(["model": "x"])
        try makeUndeletableMarker()
        let before = try Data(contentsOf: settingsURL)

        XCTAssertThrowsError(try installer.setRouterPointer(true, routerBaseURL: Self.routerBaseURL))

        XCTAssertEqual(try Data(contentsOf: settingsURL), before, "settings.json is untouched")
        XCTAssertEqual(installer.routerPointer(routerBaseURL: Self.routerBaseURL), .absent)
        XCTAssertTrue(markerExists)
    }

    func testDisableThrowsAndKeepsThePointerWhenTheMarkerCannotBeDeleted() throws {
        try writeSettings(["env": ["ANTHROPIC_BASE_URL": Self.routerBaseURL]])
        try makeUndeletableMarker()

        XCTAssertThrowsError(try installer.setRouterPointer(false, routerBaseURL: Self.routerBaseURL))

        XCTAssertEqual(installer.routerPointer(routerBaseURL: Self.routerBaseURL), .ours)
    }

    func testAMissingMarkerIsNotAnError() throws {
        try writeSettings([:])
        XCTAssertFalse(markerExists)

        XCTAssertEqual(try installer.setRouterPointer(true, routerBaseURL: Self.routerBaseURL), .ours)
    }

    func testUninstallStillRemovesThePointerWhenTheMarkerCannotBeDeleted() throws {
        try writeSettings(["env": ["ANTHROPIC_BASE_URL": Self.routerBaseURL]])
        try makeUndeletableMarker()

        XCTAssertTrue(installer.uninstallHooks(removingRouterPointer: true, routerBaseURL: Self.routerBaseURL))

        XCTAssertEqual(installer.routerPointer(routerBaseURL: Self.routerBaseURL), .absent)
    }
}
