import XCTest
import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class SessionWatcherActivityIconViewTests: XCTestCase {

    private typealias IconView = SessionWatcher.SessionWatcherActivityIconView

    /// Hosts `icon` in a window at `origin` and lays it out, the way a row does.
    private func host(_ icon: IconView, at origin: NSPoint) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        let content = NSView(frame: window.contentLayoutRect)
        content.wantsLayer = true
        window.contentView = content
        content.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: origin.x),
            icon.topAnchor.constraint(equalTo: content.topAnchor, constant: origin.y)
        ])
        content.layoutSubtreeIfNeeded()
        return window
    }

    private func assertSpinsAboutItsCentre(_ icon: IconView, file: StaticString = #filePath, line: UInt = #line) {
        let glyph = icon.glyphLayer
        XCTAssertEqual(glyph.anchorPoint, CGPoint(x: 0.5, y: 0.5), file: file, line: line)
        XCTAssertEqual(glyph.bounds.size, icon.bounds.size, file: file, line: line)
        XCTAssertEqual(glyph.position, CGPoint(x: icon.bounds.midX, y: icon.bounds.midY), file: file, line: line)
    }

    /// The spin was installed on the view's own layer, whose anchor AppKit keeps
    /// resetting to the corner, so the arrows orbited down over the line below.
    func testWorkingGlyphSpinsAboutItsCentre() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 150, y: 10))
        defer { window.close() }

        XCTAssertNotNil(icon.glyphLayer.animation(forKey: "session-activity-rotation"))
        XCTAssertNil(icon.layer?.animation(forKey: "session-activity-rotation"),
                     "the view's own layer pivots on its corner; the spin must not live there")
        assertSpinsAboutItsCentre(icon)
    }

    /// AppKit re-syncs a backing layer whenever the frame moves; the glyph must stay
    /// centred through that.
    func testGlyphStaysCentredWhenTheRowMovesIt() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 150, y: 10))
        defer { window.close() }

        icon.setFrameOrigin(NSPoint(x: 40, y: 60))
        window.contentView?.layoutSubtreeIfNeeded()
        icon.layout()
        assertSpinsAboutItsCentre(icon)
    }

    func testStateChangesSwapTheAnimation() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 150, y: 10))
        defer { window.close() }

        icon.update(activity: .waiting, isSummarizing: false)
        XCTAssertNil(icon.glyphLayer.animation(forKey: "session-activity-rotation"))
        XCTAssertNotNil(icon.glyphLayer.animation(forKey: "session-activity-pulse"))

        icon.update(activity: .idle, isSummarizing: false)
        XCTAssertNil(icon.glyphLayer.animation(forKey: "session-activity-pulse"))
        XCTAssertNotNil(icon.glyphLayer.contents, "an idle session still shows its dot")
        XCTAssertEqual(icon.accessibilityLabel(), "Idle")
    }

    // MARK: - Conformance vectors

    private static let rotationKey = "session-activity-rotation"
    private static let pulseKey = "session-activity-pulse"

    /// The glyph's pixels, premultiplied RGBA, so two renders compare byte for byte.
    private struct Bitmap: Equatable {
        let width: Int
        let height: Int
        let bytes: [UInt8]

        func alpha(x column: Int, y row: Int) -> UInt8 { bytes[(row * width + column) * 4 + 3] }
    }

    /// Draws `contents` the way the glyph layer shows it — a 13-point square at
    /// `scale` under `appearance` — and reads the pixels back. AppKit hands layers an
    /// opaque wrapper (`_NSImageLayerContents`), not a CGImage, so only Core Animation
    /// can draw it, and it resolves dynamic colors when drawn, as the screen does.
    private func bitmap(of contents: Any?, scale: CGFloat, appearance: NSAppearance) throws -> Bitmap {
        let contents = try XCTUnwrap(contents, "the glyph layer holds no image")
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 13, height: 13)
        layer.contentsGravity = .resizeAspect
        layer.contentsScale = scale
        layer.contents = contents
        let width = Int((13 * scale).rounded())
        let height = width
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.scaleBy(x: scale, y: scale)
            appearance.performAsCurrentDrawingAppearance { layer.render(in: context) }
            return true
        }
        XCTAssertTrue(drawn, "could not read the glyph's pixels")
        XCTAssertTrue(bytes.contains { $0 != 0 }, "the glyph drew nothing")
        return Bitmap(width: width, height: height, bytes: bytes)
    }

    private func renderedGlyph(of icon: IconView) throws -> Bitmap {
        try bitmap(of: icon.glyphLayer.contents, scale: icon.glyphLayer.contentsScale,
                   appearance: icon.effectiveAppearance)
    }

    /// What the glyph for `symbol` filled with `tint` looks like, drawn the way the
    /// view draws it, under the appearance the view is in.
    private func expectedGlyph(_ symbol: String, tint: NSColor, for icon: IconView) throws -> Bitmap {
        let configuration = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let symbolImage = try XCTUnwrap(
            NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(configuration)
        )
        let tinted = NSImage(size: symbolImage.size, flipped: false) { rect in
            symbolImage.draw(in: rect)
            tint.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        let scale = icon.glyphLayer.contentsScale
        var contents: Any?
        icon.effectiveAppearance.performAsCurrentDrawingAppearance {
            contents = tinted.layerContents(forContentsScale: scale)
        }
        return try bitmap(of: contents, scale: scale, appearance: icon.effectiveAppearance)
    }

    private let palette = SemanticPalette(theme: BuiltInThemes.dracula)

    func testV001_widthAndHeightResolveToThirteenPoints() {
        let icon = IconView(activity: .waiting, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }
        XCTAssertEqual(icon.frame.size, NSSize(width: 13, height: 13))
        let widths = icon.constraints.filter { $0.firstAttribute == .width && $0.constant == 13 }
        let heights = icon.constraints.filter { $0.firstAttribute == .height && $0.constant == 13 }
        XCTAssertEqual(widths.count, 1)
        XCTAssertEqual(heights.count, 1)
    }

    func testV002_horizontalCompressionResistanceIsRequired() {
        let icon = IconView(activity: .working, isSummarizing: false)
        XCTAssertEqual(icon.contentCompressionResistancePriority(for: .horizontal), .required)
    }

    func testV003_summarizingShowsSparkleNotDoubleArrow() throws {
        let icon = IconView(activity: .working, isSummarizing: true)
        let sparkle = try expectedGlyph("sparkles", tint: .tertiaryLabelColor, for: icon)
        let arrows = try expectedGlyph("arrow.triangle.2.circlepath", tint: .tertiaryLabelColor, for: icon)
        XCTAssertNotEqual(sparkle, arrows, "the two glyphs render alike, so this proves nothing")
        let rendered = try renderedGlyph(of: icon)
        XCTAssertEqual(rendered, sparkle)
        XCTAssertNotEqual(rendered, arrows)
    }

    func testV003b_waitingShowsCircledExclamationMark() throws {
        let icon = IconView(activity: .waiting, isSummarizing: false)
        let expected = try expectedGlyph("exclamationmark.circle.fill", tint: .tertiaryLabelColor, for: icon)
        let dot = try expectedGlyph("circle.fill", tint: .tertiaryLabelColor, for: icon)
        XCTAssertNotEqual(expected, dot)
        XCTAssertEqual(try renderedGlyph(of: icon), expected)
    }

    func testV003c_idleShowsFilledDot() throws {
        let icon = IconView(activity: .idle, isSummarizing: false)
        let expected = try expectedGlyph("circle.fill", tint: .tertiaryLabelColor, for: icon)
        let arrows = try expectedGlyph("arrow.triangle.2.circlepath", tint: .tertiaryLabelColor, for: icon)
        XCTAssertNotEqual(expected, arrows)
        XCTAssertEqual(try renderedGlyph(of: icon), expected)
    }

    func testV003d_workingShowsDoubleArrow() throws {
        let icon = IconView(activity: .working, isSummarizing: false)
        let expected = try expectedGlyph("arrow.triangle.2.circlepath", tint: .tertiaryLabelColor, for: icon)
        let sparkle = try expectedGlyph("sparkles", tint: .tertiaryLabelColor, for: icon)
        XCTAssertNotEqual(expected, sparkle)
        XCTAssertEqual(try renderedGlyph(of: icon), expected)
    }

    func testV004_idleWithoutSummarizingIsHidden() {
        XCTAssertTrue(IconView(activity: .idle, isSummarizing: false).isHidden)
        XCTAssertFalse(IconView(activity: .working, isSummarizing: false).isHidden)
        XCTAssertFalse(IconView(activity: .waiting, isSummarizing: false).isHidden)
    }

    func testV004b_idleWhileSummarizingIsVisible() {
        XCTAssertFalse(IconView(activity: .idle, isSummarizing: true).isHidden)
    }

    /// The glyph for `symbol` filled with `tint` is what the themed view shows, and
    /// each of `others` would have drawn something else.
    private func assertTint(
        _ activity: SessionWatcher.SessionWatcherActivity, summarizing: Bool, symbol: String,
        tint: NSColor, others: [NSColor],
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let icon = IconView(activity: activity, isSummarizing: summarizing)
        icon.applyTheme(palette)
        let expected = try expectedGlyph(symbol, tint: tint, for: icon)
        for other in others {
            let wrong = try expectedGlyph(symbol, tint: other, for: icon)
            XCTAssertNotEqual(expected, wrong, "the theme's colors are indistinguishable here", file: file, line: line)
        }
        XCTAssertEqual(try renderedGlyph(of: icon), expected, file: file, line: line)
    }

    func testV005_waitingIsFilledWithTheWarningColor() throws {
        try assertTint(.waiting, summarizing: false, symbol: "exclamationmark.circle.fill",
                       tint: palette.warningColor, others: [palette.accentColor, palette.tertiaryTextColor])
    }

    func testV005b_idleIsFilledWithTheTertiaryTextColor() throws {
        try assertTint(.idle, summarizing: false, symbol: "circle.fill",
                       tint: palette.tertiaryTextColor, others: [palette.accentColor, palette.warningColor])
    }

    func testV005c_workingIsFilledWithTheAccentColor() throws {
        try assertTint(.working, summarizing: false, symbol: "arrow.triangle.2.circlepath",
                       tint: palette.accentColor, others: [palette.warningColor, palette.tertiaryTextColor])
    }

    func testV005d_summarizingIsFilledWithTheAccentColorForEveryActivity() throws {
        for activity in [SessionWatcher.SessionWatcherActivity.working, .idle, .waiting] {
            try assertTint(activity, summarizing: true, symbol: "sparkles",
                           tint: palette.accentColor, others: [palette.warningColor, palette.tertiaryTextColor])
        }
    }

    func testV006_beforeAnyThemeTheGlyphIsFilledWithTheSystemTertiaryLabelColor() throws {
        let icon = IconView(activity: .working, isSummarizing: false)
        let expected = try expectedGlyph("arrow.triangle.2.circlepath", tint: .tertiaryLabelColor, for: icon)
        let other = try expectedGlyph("arrow.triangle.2.circlepath", tint: palette.accentColor, for: icon)
        XCTAssertNotEqual(expected, other)
        XCTAssertEqual(try renderedGlyph(of: icon), expected)
    }

    func testV007_theExclamationMarkStaysDistinctFromItsRing() throws {
        let icon = IconView(activity: .waiting, isSummarizing: false)
        icon.applyTheme(palette)
        let waiting = try renderedGlyph(of: icon)
        let flatDot = try expectedGlyph("circle.fill", tint: palette.warningColor, for: icon)

        func clearPixelsAtCentre(_ image: Bitmap) -> Int {
            var count = 0
            for row in (image.height * 2 / 5)..<(image.height * 3 / 5) {
                for column in (image.width * 2 / 5)..<(image.width * 3 / 5) where image.alpha(x: column, y: row) < 64 {
                    count += 1
                }
            }
            return count
        }
        XCTAssertGreaterThan(clearPixelsAtCentre(waiting), 0, "the exclamation mark was filled in with the ring")
        XCTAssertEqual(clearPixelsAtCentre(flatDot), 0, "the control glyph should be solid at its centre")
        let ringPixels = waiting.bytes.enumerated().filter { $0.offset % 4 == 3 && $0.element == 255 }.count
        XCTAssertGreaterThan(ringPixels, 0, "the ring is not solid")
    }

    func testV008_unresolvableSymbolFallback() throws {
        throw XCTSkip("the source looks its symbol up with NSImage(systemSymbolName:) and exposes no seam to fail it")
    }

    func testV009_updateMovesTheSameInstanceToTheNewState() throws {
        let icon = IconView(activity: .working, isSummarizing: false)
        let reference = icon
        icon.update(activity: .waiting, isSummarizing: false)
        XCTAssertTrue(icon === reference)
        let expected = try expectedGlyph("exclamationmark.circle.fill", tint: .tertiaryLabelColor, for: icon)
        XCTAssertEqual(try renderedGlyph(of: icon), expected)
        XCTAssertEqual(icon.accessibilityLabel(), "Waiting for you")
    }

    func testV010_aRedundantUpdateTouchesNothing() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }
        XCTAssertNotNil(icon.glyphLayer.animation(forKey: Self.rotationKey))

        // Stand-ins the real update would overwrite: a slower spin under the spin's key,
        // a label, and an emptied glyph.
        let marker = CABasicAnimation(keyPath: "transform.rotation.z")
        marker.duration = 5
        icon.glyphLayer.add(marker, forKey: Self.rotationKey)
        icon.setAccessibilityLabel("marker")
        icon.glyphLayer.contents = nil

        icon.update(activity: .working, isSummarizing: false)

        XCTAssertEqual(icon.glyphLayer.animation(forKey: Self.rotationKey)?.duration, 5, "the spin was restarted")
        XCTAssertEqual(icon.accessibilityLabel(), "marker", "the state was described again")
        XCTAssertNil(icon.glyphLayer.contents, "the glyph was drawn again")
    }

    func testV011_goingFromIdleToWorkingOnScreenShowsAndSpins() {
        let icon = IconView(activity: .idle, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }
        XCTAssertTrue(icon.isHidden)
        XCTAssertNil(icon.glyphLayer.animation(forKey: Self.rotationKey))

        icon.update(activity: .working, isSummarizing: false)

        XCTAssertFalse(icon.isHidden)
        XCTAssertNotNil(icon.glyphLayer.animation(forKey: Self.rotationKey))
    }

    private func assertPulse(_ icon: IconView, file: StaticString = #filePath, line: UInt = #line) {
        let pulse = icon.glyphLayer.animation(forKey: Self.pulseKey) as? CABasicAnimation
        XCTAssertNotNil(pulse, "no pulse is running", file: file, line: line)
        XCTAssertEqual(pulse?.keyPath, "opacity", file: file, line: line)
        XCTAssertEqual(pulse?.fromValue as? Double, 1.0, file: file, line: line)
        XCTAssertEqual(pulse?.toValue as? Double, 0.25, file: file, line: line)
        XCTAssertEqual(pulse?.duration, 0.7, file: file, line: line)
        XCTAssertEqual(pulse?.autoreverses, true, file: file, line: line)
        XCTAssertEqual(pulse?.repeatCount, .greatestFiniteMagnitude, file: file, line: line)
    }

    func testV012_waitingPulses() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }
        icon.update(activity: .waiting, isSummarizing: false)
        assertPulse(icon)
    }

    func testV012b_idleWhileSummarizingPulses() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }
        icon.update(activity: .idle, isSummarizing: true)
        assertPulse(icon)
    }

    func testV013_workingSpinsOneTurnOver1Point1SecondsLinear() throws {
        let icon = IconView(activity: .idle, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }
        icon.update(activity: .working, isSummarizing: false)

        let spin = try XCTUnwrap(icon.glyphLayer.animation(forKey: Self.rotationKey) as? CABasicAnimation)
        XCTAssertEqual(spin.keyPath, "transform.rotation.z")
        XCTAssertEqual(spin.fromValue as? Double, 0)
        XCTAssertEqual(try XCTUnwrap(spin.toValue as? Double), -Double.pi * 2, accuracy: 0.0001)
        XCTAssertEqual(spin.duration, 1.1)
        XCTAssertEqual(spin.repeatCount, .greatestFiniteMagnitude)
        XCTAssertEqual(spin.timingFunction, CAMediaTimingFunction(name: .linear))
    }

    func testV014_startingAgainDoesNotReplaceARunningSpin() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }
        let marker = CABasicAnimation(keyPath: "transform.rotation.z")
        marker.duration = 5
        icon.glyphLayer.add(marker, forKey: Self.rotationKey)

        // Re-entering the window starts the animation again with no stop in between.
        icon.viewDidMoveToWindow()

        XCTAssertEqual(icon.glyphLayer.animation(forKey: Self.rotationKey)?.duration, 5)
        XCTAssertEqual(icon.glyphLayer.animationKeys()?.count, 1)
    }

    func testV015_leavingTheWindowRemovesTheSpin() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }
        XCTAssertNotNil(icon.glyphLayer.animation(forKey: Self.rotationKey))

        icon.removeFromSuperview()

        XCTAssertNil(icon.glyphLayer.animation(forKey: Self.rotationKey))
        XCTAssertNil(icon.glyphLayer.animation(forKey: Self.pulseKey))
    }

    func testV016_enteringAWindowRedrawsAndSpins() {
        let icon = IconView(activity: .working, isSummarizing: false)
        XCTAssertNil(icon.glyphLayer.animation(forKey: Self.rotationKey))
        icon.glyphLayer.contents = nil

        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }

        XCTAssertNotNil(icon.glyphLayer.contents)
        XCTAssertNotNil(icon.glyphLayer.animation(forKey: Self.rotationKey))
    }

    func testV017_anAppearanceChangeRedrawsWithTheNewAppearancesColor() throws {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }

        icon.appearance = NSAppearance(named: .aqua)
        icon.viewDidChangeEffectiveAppearance()
        let light = try renderedGlyph(of: icon)
        XCTAssertEqual(light, try expectedGlyph("arrow.triangle.2.circlepath", tint: .tertiaryLabelColor, for: icon))

        icon.appearance = NSAppearance(named: .darkAqua)
        icon.viewDidChangeEffectiveAppearance()
        let dark = try renderedGlyph(of: icon)
        XCTAssertEqual(dark, try expectedGlyph("arrow.triangle.2.circlepath", tint: .tertiaryLabelColor, for: icon))
        XCTAssertNotEqual(light, dark, "the fill kept the color it resolved against the old appearance")
    }

    func testV018_displayScaleRerender() throws {
        throw XCTSkip("needs a second display with another pixel density; a unit test cannot move the window to one")
    }

    func testV019_layoutKeepsTheGlyphFillingAndCenteredWithoutAnimating() {
        let icon = IconView(activity: .working, isSummarizing: false)
        let window = host(icon, at: NSPoint(x: 10, y: 10))
        defer { window.close() }

        icon.glyphLayer.removeAllAnimations()
        icon.glyphLayer.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        icon.glyphLayer.position = CGPoint(x: 3, y: 4)
        icon.layout()

        XCTAssertEqual(icon.glyphLayer.bounds, icon.bounds)
        XCTAssertEqual(icon.glyphLayer.position, CGPoint(x: icon.bounds.midX, y: icon.bounds.midY))
        XCTAssertNil(icon.glyphLayer.animation(forKey: "bounds"))
        XCTAssertNil(icon.glyphLayer.animation(forKey: "position"))
    }

    func testV020_reportsAnImageRoleAndIsAnAccessibilityElement() {
        let icon = IconView(activity: .working, isSummarizing: false)
        XCTAssertEqual(icon.accessibilityRole(), .image)
        XCTAssertTrue(icon.isAccessibilityElement())
    }

    func testV021_waitingLabelAndTooltipReadWaitingForYou() {
        let icon = IconView(activity: .waiting, isSummarizing: false)
        XCTAssertEqual(icon.accessibilityLabel(), "Waiting for you")
        XCTAssertEqual(icon.toolTip, "Waiting for you")
    }

    func testV021b_summarizingOverridesTheActivityInLabelAndTooltip() {
        let icon = IconView(activity: .working, isSummarizing: true)
        XCTAssertEqual(icon.accessibilityLabel(), "Summarizing")
        XCTAssertEqual(icon.toolTip, "Summarizing")
    }

    func testV022_idleIdentifier() {
        let icon = IconView(activity: .idle, isSummarizing: false)
        XCTAssertEqual(icon.accessibilityIdentifier(), "session-panel.activity.idle")
    }

    func testV022b_summarizingIdentifier() {
        let icon = IconView(activity: .idle, isSummarizing: true)
        XCTAssertEqual(icon.accessibilityIdentifier(), "session-panel.activity.summarizing")
    }

    func testV023_decodingFromAnArchiveTraps() throws {
        throw XCTSkip("init(coder:) is a fatalError; it ends the test process and cannot be asserted on")
    }
}
