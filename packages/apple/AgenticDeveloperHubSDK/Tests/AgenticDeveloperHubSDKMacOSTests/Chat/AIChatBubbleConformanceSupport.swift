// Tests/AgenticDeveloperHubSDKMacOSTests/Chat/AIChatBubbleConformanceSupport.swift
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKCoreMacOS
@testable import AgenticDeveloperHubSDKMacOS

/// Stands in for whatever holds a bubble in a window, and records the presses
/// the bubble hands on to it: a view that does not take a mouse-down passes it
/// up its responder chain, so this is how "was it forwarded" is seen.
final class BubblePressRecorder: NSView {
    var presses = 0
    override func mouseDown(with event: NSEvent) { presses += 1 }
}

/// The fixtures the chat-bubble conformance vectors share: a theme the test
/// installs itself, so no result depends on which theme the developer running
/// them has selected, and a bubble hosted in a window.
@MainActor
class AIChatBubbleConformanceCase: XCTestCase {

    private final class BubbleThemeStorage: ThemeStorage {
        var customThemes: [ColorTheme] = []
        var activeThemeID: String?
        var onExternalChange: (() -> Void)?
    }

    var windows: [NSWindow] = []
    var manager: ThemeManager?

    override func setUp() async throws {
        try await super.setUp()
        useTheme(BuiltInThemes.dracula)
    }

    override func tearDown() async throws {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        manager = nil
        // The terminal font is real user state, shared with the process.
        UserSettings.terminalFontName.value = UserSettings.terminalFontName.defaultValue
        UserSettings.terminalFontSize.value = UserSettings.terminalFontSize.defaultValue
        try await super.tearDown()
    }

    // MARK: - Fixtures

    /// Makes `theme` the app's theme for the rest of the test.
    @discardableResult
    func useTheme(_ theme: ColorTheme, alongside others: [ColorTheme] = []) -> ThemeManager {
        let storage = BubbleThemeStorage()
        storage.customThemes = ([theme] + others).filter { !$0.isBuiltIn }
        storage.activeThemeID = theme.id
        let made = ThemeManager(storage: storage, appearanceDriver: nil)
        manager = made
        return made
    }

    var palette: SemanticPalette { manager?.currentPalette ?? SemanticPalette(theme: BuiltInThemes.dracula) }

    /// A theme of the reader's own: `base` with the given overrides.
    func customTheme(
        from base: ColorTheme = BuiltInThemes.dracula,
        roles: [ThemeRole: RGBAColor] = [:],
        terminal: ThemeTerminalOptions? = nil,
        typography: ThemeTypography? = nil
    ) -> ColorTheme {
        var theme = base
        theme.id = UUID().uuidString
        theme.isBuiltIn = false
        for (role, color) in roles { theme.roleOverrides[role.rawValue] = color }
        if let terminal { theme.terminal = terminal }
        if let typography { theme.typography = typography }
        return theme
    }

    func lines(_ count: Int) -> String {
        (0..<count).map { "line \($0)" }.joined(separator: "\n")
    }

    let wrapping = String(repeating: "a long unbroken sentence that has to wrap. ", count: 3)

    func bubble(
        role: ChatMessage.Role = .assistant,
        text: String = "hello there",
        style: AIChatBubbleView.Style = .speaker,
        timestamp: Date = Date(),
        isWorkOutput: Bool = false,
        maxWidth: CGFloat = 300,
        showsInlineTimestamp: Bool = false,
        isTextSelectable: Bool = true,
        lineLimit: Int? = nil,
        fillsWidthWhenWrapped: Bool = false,
        isExpanded: Bool = false
    ) -> AIChatBubbleView {
        let message = ChatMessage(id: "m", role: role, text: text, timestamp: timestamp,
                                  isWorkOutput: isWorkOutput)
        let made = AIChatBubbleView(
            message: message, maxWidth: maxWidth, style: style,
            showsInlineTimestamp: showsInlineTimestamp, isTextSelectable: isTextSelectable,
            lineLimit: lineLimit, fillsWidthWhenWrapped: fillsWidthWhenWrapped, isExpanded: isExpanded)
        let host = BubblePressRecorder()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 800),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        windows.append(window)
        host.addSubview(made)
        NSLayoutConstraint.activate([
            made.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            made.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        host.layoutSubtreeIfNeeded()
        return made
    }

    func relayout(_ view: NSView) { view.window?.contentView?.layoutSubtreeIfNeeded() }

    func textView(of bubble: AIChatBubbleView) throws -> NSTextView {
        try XCTUnwrap(bubble.subviews.compactMap { $0 as? NSTextView }.first, "the bubble has no text view")
    }

    func toggle(of bubble: AIChatBubbleView) throws -> NSButton {
        try XCTUnwrap(
            bubble.subviews.compactMap { $0 as? NSButton }
                .first { $0.accessibilityIdentifier() == "chat-bubble.more" },
            "the bubble has no expand toggle")
    }

    func shownText(of bubble: AIChatBubbleView) throws -> String {
        try textView(of: bubble).string
    }

    func attribute(_ key: NSAttributedString.Key, at index: Int, in bubble: AIChatBubbleView) throws -> Any {
        let storage = try XCTUnwrap(textView(of: bubble).textStorage)
        XCTAssertLessThan(index, storage.length, "the bubble holds less text than the test expected")
        return try XCTUnwrap(storage.attribute(key, at: index, effectiveRange: nil))
    }

    func textColor(of bubble: AIChatBubbleView) throws -> NSColor {
        try XCTUnwrap(attribute(.foregroundColor, at: 0, in: bubble) as? NSColor)
    }

    func font(at index: Int, in bubble: AIChatBubbleView) throws -> NSFont {
        try XCTUnwrap(attribute(.font, at: index, in: bubble) as? NSFont)
    }

    func lineCount(of bubble: AIChatBubbleView) throws -> Int {
        let view = try textView(of: bubble)
        let layoutManager = try XCTUnwrap(view.layoutManager)
        layoutManager.ensureLayout(for: try XCTUnwrap(view.textContainer))
        var count = 0
        var glyph = 0
        while glyph < layoutManager.numberOfGlyphs {
            var range = NSRange()
            _ = layoutManager.lineFragmentUsedRect(forGlyphAt: glyph, effectiveRange: &range)
            count += 1
            guard range.length > 0 else { break }
            glyph = NSMaxRange(range)
        }
        return count
    }

    func mouseDown(clickCount: Int, in bubble: AIChatBubbleView) throws -> NSEvent {
        try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseDown, location: NSPoint(x: 4, y: 4), modifierFlags: [], timestamp: 0,
            windowNumber: bubble.window?.windowNumber ?? 0, context: nil, eventNumber: 0,
            clickCount: clickCount, pressure: 1))
    }

    func symbolBytes(_ name: String) throws -> Data {
        let image = try XCTUnwrap(NSImage(systemSymbolName: name, accessibilityDescription: nil))
        return try XCTUnwrap(image.tiffRepresentation)
    }

}
