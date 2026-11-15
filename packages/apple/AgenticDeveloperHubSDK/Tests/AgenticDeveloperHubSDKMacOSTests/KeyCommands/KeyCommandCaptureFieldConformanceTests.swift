import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import AppKit
import Carbon.HIToolbox
import XCTest
@preconcurrency import KeyboardShortcuts
@testable import AgenticDeveloperHubSDKMacOS

/// Hosts fields in real (never shown) windows and builds key and mouse events.
@MainActor
private final class CaptureFieldHarness {
    /// Records key presses that reach it: whatever the field's own `keyDown` hands up the responder chain.
    final class KeyProbeView: NSView {
        var keyDownCount = 0
        override func keyDown(with event: NSEvent) { keyDownCount += 1 }
    }

    final class ThemeStorageStub: ThemeStorage {
        var customThemes: [ColorTheme] = []
        var activeThemeID: String?
        var onExternalChange: (() -> Void)?
    }

    private(set) var windows: [NSWindow] = []

    func tearDown() {
        windows.forEach { $0.orderOut(nil) }
        windows = []
    }

    func hosted(_ field: KeyCommandCaptureField, in host: NSView = NSView()) -> KeyCommandCaptureField {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 120),
            styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        windows.append(window)
        host.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            field.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        host.layoutSubtreeIfNeeded()
        return field
    }

    func idleField() -> KeyCommandCaptureField { hosted(KeyCommandCaptureField()) }

    func recordingField() -> KeyCommandCaptureField {
        let field = idleField()
        field.window?.makeFirstResponder(field)
        return field
    }

    func label(of field: KeyCommandCaptureField) throws -> NSTextField {
        try XCTUnwrap(field.subviews.compactMap { $0 as? NSTextField }.first)
    }

    func keyEvent(
        _ keyCode: Int, modifiers: NSEvent.ModifierFlags = [], characters: String = "",
        type: NSEvent.EventType = .keyDown
    ) throws -> NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(
            with: type, location: .zero, modifierFlags: modifiers,
            timestamp: 0, windowNumber: windows.last?.windowNumber ?? 0, context: nil,
            characters: characters, charactersIgnoringModifiers: characters,
            isARepeat: false, keyCode: UInt16(keyCode)))
    }

    func clickEvent() throws -> NSEvent {
        try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseDown, location: NSPoint(x: 5, y: 5), modifierFlags: [],
            timestamp: 0, windowNumber: windows.last?.windowNumber ?? 0, context: nil,
            eventNumber: 0, clickCount: 1, pressure: 1))
    }
}

/// Conformance vectors kccf-003 ... kccf-023: focus, recording state and key handling.
@MainActor
final class KeyCaptureFieldFocusConformanceTests: XCTestCase {
    private let harness = CaptureFieldHarness()

    override func tearDown() async throws {
        harness.tearDown()
        try await super.tearDown()
    }

    func testKccf003_clickFocusesTheField() throws {
        let field = harness.idleField()
        XCTAssertFalse(field.window?.firstResponder === field)
        field.mouseDown(with: try harness.clickEvent())
        XCTAssertTrue(field.window?.firstResponder === field)
    }

    func testKccf004_gainingFocusStartsRecordingAndReportsIt() {
        let field = harness.idleField()
        var reported: [Bool] = []
        field.onRecordingChanged = { reported.append($0) }
        field.window?.makeFirstResponder(field)
        XCTAssertTrue(field.isRecording)
        XCTAssertEqual(reported, [true])
    }

    func testKccf005_losingFocusStopsRecordingAndReportsIt() {
        let field = harness.recordingField()
        var reported: [Bool] = []
        field.onRecordingChanged = { reported.append($0) }
        field.window?.makeFirstResponder(nil)
        XCTAssertFalse(field.isRecording)
        XCTAssertEqual(reported, [false])
    }

    func testKccf006_gainingFocusAgainDoesNotReportASecondTime() {
        let field = harness.idleField()
        var reported: [Bool] = []
        field.onRecordingChanged = { reported.append($0) }
        field.window?.makeFirstResponder(field)
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertEqual(reported, [true])
    }

    func testKccf007_focusOnThenOffReportsExactlyTrueThenFalse() {
        let field = harness.idleField()
        var reported: [Bool] = []
        field.onRecordingChanged = { reported.append($0) }
        field.window?.makeFirstResponder(field)
        field.window?.makeFirstResponder(nil)
        XCTAssertEqual(reported, [true, false])
    }

    func testKccf008_endRecordingOnAnIdleFieldChangesNothing() {
        let field = harness.idleField()
        var reported: [Bool] = []
        field.onRecordingChanged = { reported.append($0) }
        let responderBefore = field.window?.firstResponder
        field.endRecording()
        XCTAssertFalse(field.isRecording)
        XCTAssertTrue(field.window?.firstResponder === responderBefore)
        XCTAssertTrue(reported.isEmpty)
    }

    func testKccf009_endRecordingClearsTheWindowsFocus() {
        let field = harness.recordingField()
        XCTAssertTrue(field.window?.firstResponder === field)
        field.endRecording()
        XCTAssertFalse(field.window?.firstResponder === field)
        XCTAssertFalse(field.isRecording)
    }

    func testKccf010_endRecordingOnARecordingFieldThatLostFocusLeavesFocusAlone() {
        let field = harness.idleField()
        // Recording without being the window's first responder: focus was taken elsewhere.
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertTrue(field.isRecording)
        let other = NSTextField(frame: NSRect(x: 0, y: 40, width: 80, height: 20))
        field.superview?.addSubview(other)
        field.window?.makeFirstResponder(other)
        let responderBefore = field.window?.firstResponder
        XCTAssertFalse(responderBefore === field)

        field.endRecording()

        XCTAssertFalse(field.isRecording)
        XCTAssertTrue(field.window?.firstResponder === responderBefore)
    }

    func testKccf011_recordingFieldInterceptsAKeyEquivalent() throws {
        let field = harness.recordingField()
        var captured: [KeyboardShortcuts.Shortcut] = []
        field.onCapture = { captured.append($0) }
        let event = try harness.keyEvent(kVK_ANSI_K, modifiers: .command, characters: "k")
        XCTAssertTrue(field.performKeyEquivalent(with: event))
        XCTAssertEqual(captured, [KeyboardShortcuts.Shortcut(.k, modifiers: [.command])])
    }

    func testKccf012_idleFieldDefersAKeyEquivalent() throws {
        let field = harness.idleField()
        var captured = false
        field.onCapture = { _ in captured = true }
        let event = try harness.keyEvent(kVK_ANSI_K, modifiers: .command, characters: "k")
        XCTAssertEqual(field.performKeyEquivalent(with: event), false)
        XCTAssertFalse(captured)
    }

    func testKccf013_escapeWithCapsLockStillCancels() throws {
        let field = harness.recordingField()
        var cancelled = false
        field.onCancel = { cancelled = true }
        _ = field.performKeyEquivalent(with: try harness.keyEvent(kVK_Escape, modifiers: .capsLock))
        XCTAssertTrue(cancelled)
    }

    func testKccf014_returnWithCapsLockStillCommits() throws {
        let field = harness.recordingField()
        var committed = false
        field.onCommit = { committed = true }
        _ = field.performKeyEquivalent(with: try harness.keyEvent(kVK_Return, modifiers: .capsLock, characters: "\r"))
        XCTAssertTrue(committed)
    }

    func testKccf015_bareEscapeCancelsAndIsConsumed() throws {
        let field = harness.recordingField()
        var cancelled = false
        field.onCancel = { cancelled = true }
        XCTAssertTrue(field.performKeyEquivalent(with: try harness.keyEvent(kVK_Escape)))
        XCTAssertTrue(cancelled)
    }

    func testKccf016_bareReturnCommitsAndIsConsumed() throws {
        let field = harness.recordingField()
        var committed = false
        field.onCommit = { committed = true }
        XCTAssertTrue(field.performKeyEquivalent(with: try harness.keyEvent(kVK_Return, characters: "\r")))
        XCTAssertTrue(committed)
    }

    func testKccf017_bareKeypadEnterCommitsAndIsConsumed() throws {
        let field = harness.recordingField()
        var committed = false
        field.onCommit = { committed = true }
        XCTAssertTrue(field.performKeyEquivalent(with: try harness.keyEvent(kVK_ANSI_KeypadEnter, characters: "\r")))
        XCTAssertTrue(committed)
    }

    func testKccf018_unmodifiedTabIsDeclined() throws {
        let field = harness.recordingField()
        var fired = false
        field.onCapture = { _ in fired = true }
        field.onCancel = { fired = true }
        field.onCommit = { fired = true }
        XCTAssertFalse(field.performKeyEquivalent(with: try harness.keyEvent(kVK_Tab, characters: "\t")))
        XCTAssertFalse(fired)
    }

    func testKccf019_shiftTabIsNotConsumed() throws {
        let field = harness.recordingField()
        var captured = false
        field.onCapture = { _ in captured = true }
        XCTAssertFalse(field.performKeyEquivalent(
            with: try harness.keyEvent(kVK_Tab, modifiers: .shift, characters: "\t")))
        XCTAssertFalse(captured)
    }

    func testKccf020_optionTabIsCapturedAndConsumed() throws {
        let field = harness.recordingField()
        var captured: [KeyboardShortcuts.Shortcut] = []
        field.onCapture = { captured.append($0) }
        XCTAssertTrue(field.performKeyEquivalent(
            with: try harness.keyEvent(kVK_Tab, modifiers: .option, characters: "\t")))
        XCTAssertEqual(captured, [KeyboardShortcuts.Shortcut(.tab, modifiers: [.option])])
    }

    func testKccf021_everyChordIsReportedOnce() throws {
        let field = harness.recordingField()
        var captured: [KeyboardShortcuts.Shortcut] = []
        field.onCapture = { captured.append($0) }
        _ = field.performKeyEquivalent(
            with: try harness.keyEvent(kVK_ANSI_K, modifiers: [.command, .shift], characters: "k"))
        _ = field.performKeyEquivalent(
            with: try harness.keyEvent(kVK_ANSI_P, modifiers: [.option, .command], characters: "p"))
        XCTAssertEqual(captured, [
            KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .shift]),
            KeyboardShortcuts.Shortcut(.p, modifiers: [.option, .command])
        ])
    }

    func testKccf022_aBareModifierPressIsIgnored() throws {
        let field = harness.recordingField()
        var fired = false
        field.onCapture = { _ in fired = true }
        field.onCancel = { fired = true }
        field.onCommit = { fired = true }
        let event = try harness.keyEvent(kVK_Command, modifiers: .command, type: .flagsChanged)
        XCTAssertFalse(field.performKeyEquivalent(with: event))
        XCTAssertFalse(fired)
    }

    func testKccf023_aKeyPressWhileIdleGoesToTheDefaultKeyHandling() throws {
        let probe = CaptureFieldHarness.KeyProbeView()
        let field = harness.hosted(KeyCommandCaptureField(), in: probe)
        var captured = false
        field.onCapture = { _ in captured = true }
        field.keyDown(with: try harness.keyEvent(kVK_ANSI_K, characters: "k"))
        XCTAssertEqual(probe.keyDownCount, 1)
        XCTAssertFalse(captured)
    }
}

/// Conformance vectors kccf-024 ... kccf-034: what the field shows and how it is painted.
@MainActor
final class KeyCaptureFieldLookConformanceTests: XCTestCase {
    private let harness = CaptureFieldHarness()
    private let shortcutA = KeyboardShortcuts.Shortcut(.k, modifiers: [.command])
    private let shortcutB = KeyboardShortcuts.Shortcut(.p, modifiers: [.option, .shift])

    override func tearDown() async throws {
        harness.tearDown()
        try await super.tearDown()
    }

    func testKccf024_recordingWithNothingToShowReadsPressKeys() throws {
        let field = harness.recordingField()
        XCTAssertEqual(try harness.label(of: field).stringValue, "Press keys…")
    }

    func testKccf025_pendingShortcutBeatsTheDisplayedOne() throws {
        let field = harness.idleField()
        field.displayedShortcut = shortcutA
        field.pendingShortcut = shortcutB
        XCTAssertEqual(try harness.label(of: field).stringValue, shortcutB.description)
    }

    func testKccf026_recordingKeepsTheDisplayedShortcutText() throws {
        let field = harness.idleField()
        field.displayedShortcut = shortcutA
        field.window?.makeFirstResponder(field)
        XCTAssertEqual(try harness.label(of: field).stringValue, shortcutA.description)
    }

    func testKccf027_idleWithNothingToShowReadsClickToRecord() throws {
        let field = harness.idleField()
        XCTAssertEqual(try harness.label(of: field).stringValue, "Click to record")
    }

    func testKccf028_pointingHandCursorCoversTheBounds() throws {
        throw XCTSkip("AppKit cannot read back the cursor rects a view registered; needs a window server")
    }

    func testKccf029_aThemeChangeRepaintsTheField() throws {
        let storage = CaptureFieldHarness.ThemeStorageStub()
        storage.activeThemeID = BuiltInThemes.dracula.id
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        let field = harness.idleField()
        let before = field.layer?.backgroundColor

        manager.selectTheme(id: BuiltInThemes.nord.id)

        let palette = field.resolvedThemeScope.palette
        let label = try harness.label(of: field)
        XCTAssertNotEqual(before, field.layer?.backgroundColor)
        XCTAssertEqual(field.layer?.backgroundColor, palette.controlBackgroundColor.cgColor)
        XCTAssertEqual(field.layer?.borderColor, palette.borderColor.cgColor)
        XCTAssertEqual(label.font, palette.font(.button))
        XCTAssertEqual(label.textColor, palette.placeholderTextColor)
        withExtendedLifetime(manager) {}
    }

    func testKccf030_recordingSwitchesTheBorderToTheAccentColor() {
        let field = harness.idleField()
        let palette = field.resolvedThemeScope.palette
        XCTAssertEqual(field.layer?.borderColor, palette.borderColor.cgColor)
        field.window?.makeFirstResponder(field)
        XCTAssertEqual(field.layer?.borderColor, palette.accentColor.cgColor)
    }

    func testKccf031_textColorFollowsWhetherAShortcutIsShown() throws {
        let field = harness.idleField()
        let palette = field.resolvedThemeScope.palette
        let label = try harness.label(of: field)
        XCTAssertEqual(label.textColor, palette.placeholderTextColor)
        field.displayedShortcut = shortcutA
        XCTAssertEqual(label.textColor, palette.primaryTextColor)
    }

    func testKccf032_confinementToTheUIThread() throws {
        throw XCTSkip("@MainActor: off-thread use is rejected at build time, so no test can express it")
    }

    func testKccf033_codingInitializationIsRefusedByInspectionOnly() throws {
        throw XCTSkip("init(coder:) calls fatalError; the refusal terminates the process and cannot be caught")
    }

    func testKccf034_closeColorsAreNotAdjustedForContrast() throws {
        let grey = RGBAColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        let nearGrey = RGBAColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
        let theme = ColorTheme(
            name: "Close colors", appearance: .dark, foreground: nearGrey, background: grey,
            cursor: nearGrey, selection: grey, ansi: Array(repeating: grey, count: 16),
            roleOverrides: [ThemeRole.controlBackground.rawValue: grey])
        let storage = CaptureFieldHarness.ThemeStorageStub()
        storage.customThemes = [theme]
        storage.activeThemeID = theme.id
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        let field = harness.idleField()
        field.displayedShortcut = shortcutA

        let palette = manager.currentPalette
        XCTAssertEqual(try harness.label(of: field).textColor, palette.primaryTextColor)
        XCTAssertEqual(field.layer?.backgroundColor, palette.controlBackgroundColor.cgColor)
        withExtendedLifetime(manager) {}
    }
}
