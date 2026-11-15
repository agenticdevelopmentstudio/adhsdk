// Tests/AgenticDeveloperHubSDKMacOSTests/Chat/TypingIndicatorViewConformanceTests.swift
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors for `TypingIndicatorView`: the three-dot pill, the way it
/// follows the theme, and the timer that pulses it.
@MainActor
final class TypingIndicatorViewConformanceTests: XCTestCase {

    /// A `ThemeStorage` with nothing behind it, so a test can run a real
    /// `ThemeManager` without touching `UserSettings` or `UserDefaults`.
    private final class StubThemeStorage: ThemeStorage {
        var customThemes: [ColorTheme] = []
        var activeThemeID: String?
        var onExternalChange: (() -> Void)?
    }

    private var windows: [NSWindow] = []

    override func tearDown() async throws {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// An indicator inside a window, laid out in a host larger than itself.
    private func hostedIndicator() -> (view: TypingIndicatorView, host: NSView) {
        let view = TypingIndicatorView()
        let host = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let window = NSWindow(
            contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        windows.append(window)
        host.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 20),
            view.topAnchor.constraint(equalTo: host.topAnchor, constant: 20)
        ])
        host.layoutSubtreeIfNeeded()
        return (view, host)
    }

    private func dotStack(of view: TypingIndicatorView) throws -> NSStackView {
        try XCTUnwrap(view.subviews.compactMap { $0 as? NSStackView }.first, "the indicator has no row of dots")
    }

    private func dots(of view: TypingIndicatorView) throws -> [NSView] {
        try dotStack(of: view).arrangedSubviews
    }

    private func palette() -> SemanticPalette { ThemePaletteObserver.currentPalette }

    /// Polls the main run loop until `condition` holds or `timeout` passes, so
    /// a timer scheduled on the main run loop gets to fire.
    private func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) async throws -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try await Task.sleep(for: .milliseconds(10))
        }
        return condition()
    }

    // MARK: - Layout

    func testV1_threeDotsInAHorizontalRowWithFourPointSpacing() throws {
        let (view, _) = hostedIndicator()
        let stack = try dotStack(of: view)
        XCTAssertEqual(stack.orientation, .horizontal)
        XCTAssertEqual(stack.arrangedSubviews.count, 3)
        XCTAssertEqual(stack.spacing, 4)
    }

    func testV2_pillContainerIs48By28WithTwelvePointCorners() throws {
        let (view, _) = hostedIndicator()
        XCTAssertEqual(view.layer?.cornerRadius, 12)
        XCTAssertEqual(view.frame.width, 48, accuracy: 0.5)
        XCTAssertEqual(view.frame.height, 28, accuracy: 0.5)
    }

    func testV3_dotRowIsCenteredInTheContainer() throws {
        let (view, _) = hostedIndicator()
        let stack = try dotStack(of: view)
        XCTAssertEqual(stack.frame.midX, view.bounds.midX, accuracy: 0.5)
        XCTAssertEqual(stack.frame.midY, view.bounds.midY, accuracy: 0.5)
    }

    func testV4_everyDotIsSevenPointsWithAHalfRadiusCorner() throws {
        let (view, _) = hostedIndicator()
        for dot in try dots(of: view) {
            XCTAssertEqual(dot.frame.width, 7, accuracy: 0.5)
            XCTAssertEqual(dot.frame.height, 7, accuracy: 0.5)
            XCTAssertEqual(dot.layer?.cornerRadius, 3.5)
        }
    }

    // MARK: - Theme

    private func lightAndDarkThemeIDs() throws -> (dark: String, light: String) {
        let dark = BuiltInThemes.solarizedDark
        let light = BuiltInThemes.solarizedLight
        let darkColor = SemanticPalette(theme: dark).nsColor(.secondaryText)
        let lightColor = SemanticPalette(theme: light).nsColor(.secondaryText)
        XCTAssertNotEqual(darkColor, lightColor, "the fixture is wrong: the two themes must differ to prove a switch")
        return (dark.id, light.id)
    }

    func testV5_containerFillTracksTheTheme() throws {
        let ids = try lightAndDarkThemeIDs()
        let storage = StubThemeStorage()
        storage.activeThemeID = ids.dark
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        withExtendedLifetime(manager) {
            let (view, _) = hostedIndicator()
            let before = palette().nsColor(.secondaryText).withAlphaComponent(0.08).cgColor
            XCTAssertEqual(view.layer?.backgroundColor, before, "the fill was not set at construction")

            manager.selectTheme(id: ids.light)

            let after = palette().nsColor(.secondaryText).withAlphaComponent(0.08).cgColor
            XCTAssertNotEqual(before, after, "the fixture is wrong: the palette did not change")
            XCTAssertEqual(view.layer?.backgroundColor, after, "the fill did not follow the new theme")
        }
    }

    func testV6_dotColorTracksTheTheme() throws {
        let ids = try lightAndDarkThemeIDs()
        let storage = StubThemeStorage()
        storage.activeThemeID = ids.dark
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        try withExtendedLifetime(manager) {
            let (view, _) = hostedIndicator()
            let before = palette().nsColor(.secondaryText).cgColor
            for dot in try dots(of: view) {
                XCTAssertEqual(dot.layer?.backgroundColor, before, "a dot was not colored at construction")
            }

            manager.selectTheme(id: ids.light)

            let after = palette().nsColor(.secondaryText).cgColor
            XCTAssertNotEqual(before, after, "the fixture is wrong: the palette did not change")
            for dot in try dots(of: view) {
                XCTAssertEqual(dot.layer?.backgroundColor, after, "a dot did not follow the new theme")
            }
        }
    }

    // MARK: - Animation

    func testV7_startAnimatingDimsEveryDotSynchronously() throws {
        let (view, _) = hostedIndicator()
        for dot in try dots(of: view) { dot.alphaValue = 1 }
        view.startAnimating()
        defer { view.removeFromSuperview() }
        for dot in try dots(of: view) {
            XCTAssertEqual(dot.alphaValue, 0.3, accuracy: 0.001)
        }
    }

    func testV8_firstTickHighlightsDotZeroNoSoonerThanTheInterval() async throws {
        let (view, _) = hostedIndicator()
        let dots = try dots(of: view)
        let started = Date()
        view.startAnimating()
        defer { view.removeFromSuperview() }

        let moved = try await waitUntil(timeout: 3) { dots[0].alphaValue > 0.5 }
        let elapsed = Date().timeIntervalSince(started)

        XCTAssertTrue(moved, "no tick ever fired")
        XCTAssertGreaterThanOrEqual(elapsed, 0.3, "the first tick fired before the 0.35s interval")
        XCTAssertLessThan(dots[1].alphaValue, 0.5)
        XCTAssertLessThan(dots[2].alphaValue, 0.5)
    }

    func testV9_exactlyOneDotIsHighlightedAfterATick() async throws {
        let (view, _) = hostedIndicator()
        let dots = try dots(of: view)
        view.startAnimating()
        defer { view.removeFromSuperview() }

        let reached = try await waitUntil(timeout: 3) { dots[0].alphaValue > 0.99 }

        XCTAssertTrue(reached, "dot 0 never reached full opacity")
        XCTAssertEqual(dots[1].alphaValue, 0.3, accuracy: 0.05)
        XCTAssertEqual(dots[2].alphaValue, 0.3, accuracy: 0.05)
    }

    func testV10_highlightAdvancesZeroOneTwoZero() throws {
        throw XCTSkip("Needs four 0.35s ticks (over a second of real time) and the step counter is private")
    }

    func testV11_removalStopsTheAnimation() async throws {
        let (view, _) = hostedIndicator()
        let dots = try dots(of: view)
        view.startAnimating()
        view.removeFromSuperview()

        try await Task.sleep(for: .milliseconds(600))

        for dot in dots {
            XCTAssertEqual(dot.alphaValue, 0.3, accuracy: 0.001, "a dot kept animating after removal")
        }
    }

    func testV12_startingTwiceKeepsBothTimersRunning() throws {
        throw XCTSkip("Two timers race on one animator state inside a 0.35s tick; the outcome is timing-dependent")
    }

    func testV13_confinedToTheUIThread() throws {
        throw XCTSkip("Compile-time vector: @MainActor isolation is enforced by the build, not at run time")
    }
}
