import Testing
import Foundation
import CoreGraphics
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@Suite("WindowDiscovery matching")
struct WindowDiscoveryMatchingTests {

    private func makeWindow(app: String, title: String) -> SystemWindowInfo {
        SystemWindowInfo(
            id: 1,
            app: app,
            pid: 1,
            title: title,
            frame: .zero,
            display: 0,
            isOnScreen: true,
            layer: 0
        )
    }

    @Test("wdisc-001: Xcode title matches the project via the heuristic, not just a raw substring")
    func xcodeHeuristicMatch() {
        let window = makeWindow(app: "Xcode", title: "MyApp — ContentView.swift")
        #expect(WindowDiscoveryViewModel.matches(window: window, projectName: "MyApp"))
    }

    @Test("wdisc-002: raw-title substring still matches when no heuristic applies")
    func rawTitleFallback() {
        let window = makeWindow(app: "SomeEditor", title: "Working on MyApp now")
        #expect(WindowDiscoveryViewModel.matches(window: window, projectName: "MyApp"))
    }

    @Test("wdisc-003: a different project does not match")
    func nonMatch() {
        let window = makeWindow(app: "Xcode", title: "OtherProject — File.swift")
        #expect(!WindowDiscoveryViewModel.matches(window: window, projectName: "MyApp"))
    }

    @Test("wdisc-004: empty project never matches")
    func emptyProject() {
        let window = makeWindow(app: "Xcode", title: "MyApp — File.swift")
        #expect(!WindowDiscoveryViewModel.matches(window: window, projectName: ""))
    }

    @Test("wdisc-005: Unknown project never matches")
    func unknownProject() {
        let window = makeWindow(app: "Xcode", title: "MyApp — File.swift")
        #expect(!WindowDiscoveryViewModel.matches(window: window, projectName: "Unknown"))
    }

    @Test("wdisc-006: matching is case-insensitive")
    func caseInsensitive() {
        let window = makeWindow(app: "SomeEditor", title: "MYAPP notes")
        #expect(WindowDiscoveryViewModel.matches(window: window, projectName: "myapp"))
    }
}
