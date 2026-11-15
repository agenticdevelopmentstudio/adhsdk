import AppKit
import AgenticDeveloperHubSDKCoreMacOS
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKMacOS

private let noEngineSeam: Comment = "engine and running-app list are created inside the model; no injection seam"

/// Conformance vectors wdisc-007 ... 019 for `WindowDiscoveryViewModel`.
///
/// The model builds its `SystemWindowManager` and reads `NSWorkspace` and Accessibility trust itself, with no
/// injection seam, so the vectors that need a fake engine or a fake running-app list are skipped.
@Suite("WindowDiscovery model conformance")
@MainActor
struct WindowDiscoveryModelConformanceTests {

    private func makeModel() -> WindowDiscoveryViewModel {
        WindowDiscoveryViewModel(session: SessionWatcher.SessionWatcherSession(sessionId: "s", cwd: "/tmp/demo"))
    }

    private func makeApp(pid: pid_t, name: String) -> DiscoveredApp {
        DiscoveredApp(id: pid, name: name, icon: nil, windows: [])
    }

    @Test("wdisc-007: denied permission keeps apps and stops loading",
          .enabled(if: !SystemAccessibilityPermission.isGranted,
                   "the test process is Accessibility-trusted, so the denied path is not reachable"))
    func deniedKeepsApps() {
        let model = makeModel()
        model.apps = [makeApp(pid: 1, name: "One"), makeApp(pid: 2, name: "Two")]

        model.discoverWindows()

        #expect(!model.isLoading)
        #expect(model.accessibilityDenied)
        #expect(model.apps.map(\.id) == [1, 2])
    }

    @Test("wdisc-008: granted discovery resets flags then finishes loading",
          .enabled(if: SystemAccessibilityPermission.isGranted, "needs Accessibility trust for the test process"))
    func grantedResetsFlags() async throws {
        let model = makeModel()
        model.accessibilityDenied = true

        model.discoverWindows()

        #expect(model.isLoading)
        #expect(!model.accessibilityDenied)
        let deadline = Date().addingTimeInterval(10)
        while model.isLoading && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        #expect(!model.isLoading)
    }

    @Test("wdisc-009: untitled and foreign windows dropped, windowless apps omitted",
          .disabled(noEngineSeam))
    func untitledAndForeignDropped() {}

    @Test("wdisc-010: accessory apps are excluded", .disabled(noEngineSeam))
    func regularAppsOnly() {}

    @Test("wdisc-011: matching apps sort first, then alphabetical", .disabled(noEngineSeam))
    func matchFirstSort() {}

    @Test("wdisc-012: hasMatch is true exactly when a window matches")
    func appHasMatch() {
        let miss = DiscoveredWindow(id: 1, title: "a", pid: 7, isMatch: false)
        let hit = DiscoveredWindow(id: 2, title: "b", pid: 7, isMatch: true)
        #expect(DiscoveredApp(id: 7, name: "App", icon: nil, windows: [miss, hit]).hasMatch)
        #expect(!DiscoveredApp(id: 7, name: "App", icon: nil, windows: [miss, miss]).hasMatch)
        #expect(!DiscoveredApp(id: 7, name: "App", icon: nil, windows: []).hasMatch)
    }

    @Test("wdisc-013: an app with no localized name is called Unknown", .disabled(noEngineSeam))
    func unknownAppName() {}

    @Test("wdisc-014: window order is preserved within an app", .disabled(noEngineSeam))
    func windowOrderPreserved() {}

    @Test("wdisc-015: successful focus invokes the callback once",
          .disabled("needs a real focusable window; the engine cannot be faked"))
    func activationSuccessCallback() {}

    @Test("wdisc-016: failed focus does not invoke the callback and does not throw")
    func activationFailureNoCallback() {
        let model = makeModel()
        var callbackCount = 0
        model.onWindowActivated = { callbackCount += 1 }
        let missing = DiscoveredWindow(id: 0xFFFF_FFF0, title: "gone", pid: 1, isMatch: false)

        model.activateWindow(missing)

        #expect(callbackCount == 0)
    }

    @Test("wdisc-017: opening settings requests permission once",
          .disabled("would show the real system Accessibility prompt"))
    func settingsRequest() {}

    @Test("wdisc-018: a deallocated model enumerates and publishes nothing", .disabled(noEngineSeam))
    func weakOwner() {}

    @Test("wdisc-019: the first snapshot wins for a duplicate pid", .disabled(noEngineSeam))
    func duplicatePidFirstWins() {}
}
