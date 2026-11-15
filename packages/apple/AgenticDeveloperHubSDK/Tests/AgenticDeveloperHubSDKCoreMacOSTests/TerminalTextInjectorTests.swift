import XCTest
@testable import AgenticDeveloperHubSDKCore

/// The pure pane-resolution + AppleScript-building used to inject text into (or select)
/// a live terminal pane. Covers the risky string assembly and escaping without driving a
/// real terminal (only `inject`/`run` execute AppleScript, which has no unit-testable
/// surface).
final class TerminalTextInjectorTests: XCTestCase {

    // MARK: - isSupported

    func testSupportedTerminals() {
        XCTAssertTrue(TerminalTextInjector.isSupported(termProgram: "iTerm.app"))
        XCTAssertTrue(TerminalTextInjector.isSupported(termProgram: "Apple_Terminal"))
        XCTAssertFalse(TerminalTextInjector.isSupported(termProgram: "WarpTerminal"))
        XCTAssertFalse(TerminalTextInjector.isSupported(termProgram: ""))
    }

    // MARK: - resolveTarget

    func testResolvesITermBySessionUUID() {
        let target = TerminalTextInjector.resolveTarget(
            termProgram: "iTerm.app", termSessionId: "w0t1p0:ABC-123", pid: 0
        )
        XCTAssertEqual(target, .iTermSession(uuid: "ABC-123"), "iTerm prefers its session id (no live pid needed)")
    }

    func testITermWithoutSessionIdAndDeadPidIsUnresolvable() {
        // pid 0 → ttyForPid returns nil → nothing precise to target.
        XCTAssertNil(TerminalTextInjector.resolveTarget(termProgram: "iTerm.app", termSessionId: "", pid: 0))
    }

    func testTerminalWithoutLivePidIsUnresolvable() {
        XCTAssertNil(TerminalTextInjector.resolveTarget(termProgram: "Apple_Terminal", termSessionId: "", pid: 0))
    }

    func testUnsupportedTerminalHasNoTarget() {
        XCTAssertNil(TerminalTextInjector.resolveTarget(termProgram: "WarpTerminal", termSessionId: "x:y", pid: 4242))
    }

    // MARK: - script (inject)

    func testITermScriptWritesTextToMatchedSession() {
        let script = TerminalTextInjector.script(
            for: .iTermSession(uuid: "ABC"), text: "/compact", raising: false)
        XCTAssertTrue(script.contains("com.googlecode.iterm2"))
        XCTAssertTrue(script.contains("id of s is \"ABC\""))
        XCTAssertTrue(script.contains("write text \"/compact\""))
        XCTAssertTrue(script.contains("return \"not_found\""), "falls through to a miss signal")
    }

    func testITermTTYScriptMatchesByTTY() {
        let script = TerminalTextInjector.script(
            for: .iTermTTY(tty: "/dev/ttys003"), text: "/compact", raising: false)
        XCTAssertTrue(script.contains("tty of s is \"/dev/ttys003\""))
        XCTAssertTrue(script.contains("write text \"/compact\""))
    }

    func testTerminalScriptRunsDoScriptInMatchedTab() {
        let script = TerminalTextInjector.script(
            for: .terminalTTY(tty: "ttys004"), text: "/compact", raising: false)
        XCTAssertTrue(script.contains("tell application \"Terminal\""))
        XCTAssertTrue(script.contains("tty of t is \"/dev/ttys004\""), "a bare tty gets the /dev/ prefix")
        XCTAssertTrue(script.contains("do script \"/compact\" in t"))
    }

    func testScriptEscapesInjectedText() {
        let script = TerminalTextInjector.script(
            for: .iTermSession(uuid: "x"), text: #"say "hi""#, raising: false)
        XCTAssertTrue(script.contains(#"write text "say \"hi\"""#), script)
    }

    // MARK: - script (raising: false — typing into a session nobody asked to visit)

    func testITermInjectionDoesNotRaiseTheTerminal() {
        let script = TerminalTextInjector.script(
            for: .iTermSession(uuid: "ABC"), text: "/compact", raising: false)
        XCTAssertTrue(script.contains("write text \"/compact\""), "the line is still delivered")
        XCTAssertFalse(script.contains("activate"), "sending a line must not take the screen")
        XCTAssertFalse(script.contains("select s"))
        XCTAssertFalse(script.contains("select t"))
    }

    func testTerminalInjectionDoesNotRaiseTheTerminal() {
        let script = TerminalTextInjector.script(
            for: .terminalTTY(tty: "ttys004"), text: "/compact", raising: false)
        XCTAssertTrue(script.contains("do script \"/compact\" in t"), "the line is still delivered")
        XCTAssertFalse(script.contains("activate"), "sending a line must not take the screen")
        XCTAssertFalse(script.contains("set frontmost"))
        XCTAssertFalse(script.contains("set selected tab"))
    }

    func testITermInjectionCanRaiseWhenAsked() {
        let script = TerminalTextInjector.script(
            for: .iTermSession(uuid: "ABC"), text: "/compact", raising: true)
        XCTAssertTrue(script.contains("write text \"/compact\""))
        XCTAssertTrue(script.contains("activate"), "raising is still available to a caller that wants it")
        XCTAssertTrue(script.contains("select s"))
    }

    // MARK: - script (select-only, text: nil — the click-action variant)

    func testITermSelectOnlyScriptOmitsWriteText() {
        let script = TerminalTextInjector.script(
            for: .iTermSession(uuid: "ABC"), text: nil, raising: true)
        XCTAssertTrue(script.contains("id of s is \"ABC\""))
        XCTAssertTrue(script.contains("select s"))
        XCTAssertTrue(script.contains("activate"))
        XCTAssertFalse(script.contains("write text"), "select-only must never type into the pane")
    }

    func testTerminalSelectOnlyScriptOmitsDoScript() {
        let script = TerminalTextInjector.script(
            for: .terminalTTY(tty: "ttys004"), text: nil, raising: true)
        XCTAssertTrue(script.contains("tty of t is \"/dev/ttys004\""))
        XCTAssertTrue(script.contains("set selected tab of w to t"))
        XCTAssertFalse(script.contains("do script"), "select-only must never run anything in the tab")
    }

    // MARK: - escape / normalizeTTY

    func testEscapeQuotesAndBackslashes() {
        XCTAssertEqual(TerminalTextInjector.escape(#"a"b\c"#), #"a\"b\\c"#)
    }

    /// A newline becomes a space, not nothing. Deleting it welded the last word
    /// of one line to the first of the next — "…the fileimport it" — and the
    /// session was sent a line it was never shown. A space is what a terminal
    /// line-edit buffer can hold and what the sender meant by the break.
    func testEscapeTurnsNewlinesIntoSpaces() {
        XCTAssertEqual(TerminalTextInjector.escape("first\nsecond"), "first second")
        XCTAssertEqual(TerminalTextInjector.escape("a\nb\rc\r\nd"), "a b c d")
    }

    /// A NUL still goes: nothing can carry it, and it has no width to preserve.
    func testEscapeDropsNulls() {
        XCTAssertEqual(TerminalTextInjector.escape("a\0b"), "ab")
    }

    /// ESC, ^C, ^D and DEL would reach the agent as keystrokes (interrupt, clear,
    /// exit), so they go; a tab becomes a space; ordinary text is untouched.
    func testEscapeDropsKeystrokeControlCharacters() {
        XCTAssertEqual(TerminalTextInjector.escape("a\u{1B}[0mb\u{03}c\u{04}d\u{7F}e"), "a[0mbcde")
        XCTAssertEqual(TerminalTextInjector.escape("col1\tcol2"), "col1 col2")
        XCTAssertEqual(TerminalTextInjector.escape("café ✓ 日本"), "café ✓ 日本")
    }

    func testNormalizeTTYAddsDevPrefix() {
        XCTAssertEqual(TerminalTextInjector.normalizeTTY("ttys001"), "/dev/ttys001")
        XCTAssertEqual(TerminalTextInjector.normalizeTTY("/dev/ttys001"), "/dev/ttys001")
    }

    // MARK: - returnScript (Return pressed on its own, after the text)

    /// The typing script never submits and never waits: the wait is the caller's
    /// `await`, so the main thread is free during it, and Return is a script of its own.
    func testITermTypesWithoutReturnAndPressesReturnSeparately() {
        let typing = TerminalTextInjector.script(for: .iTermSession(uuid: "ABC"), text: "hello", raising: false)
        XCTAssertTrue(typing.contains(#"write text "hello" newline no"#), typing)
        XCTAssertFalse(typing.contains(#"write text """#), "Return belongs to returnScript")
        XCTAssertFalse(typing.contains("delay"), "a delay inside the script blocks the main thread")

        let returnKey = TerminalTextInjector.returnScript(for: .iTermSession(uuid: "ABC"))
        XCTAssertTrue(returnKey.contains(#"id of s is "ABC""#), returnKey)
        XCTAssertTrue(returnKey.contains(#"tell s to write text """#), returnKey)
        XCTAssertFalse(returnKey.contains("activate"), "pressing Return never raises")
    }

    /// A long line handed to `do script` arrives as a paste whose newline Claude
    /// Code keeps; Return pressed on its own afterwards is what submits it.
    func testTerminalTypesThenPressesReturnSeparately() {
        let typing = TerminalTextInjector.script(for: .terminalTTY(tty: "ttys004"), text: "hello", raising: false)
        XCTAssertTrue(typing.contains(#"do script "hello" in t"#), typing)
        XCTAssertFalse(typing.contains(#"do script "" in t"#), "Return belongs to returnScript")
        XCTAssertFalse(typing.contains("delay"), "a delay inside the script blocks the main thread")

        let returnKey = TerminalTextInjector.returnScript(for: .terminalTTY(tty: "ttys004"))
        XCTAssertTrue(returnKey.contains(#"tty of t is "/dev/ttys004""#), returnKey)
        XCTAssertTrue(returnKey.contains(#"do script "" in t"#), returnKey)
        XCTAssertFalse(returnKey.contains("activate"), "pressing Return never raises")
    }

    func testITermTTYReturnScriptMatchesByTTY() {
        let returnKey = TerminalTextInjector.returnScript(for: .iTermTTY(tty: "ttys003"))
        XCTAssertTrue(returnKey.contains(#"tty of s is "/dev/ttys003""#), returnKey)
    }

    // MARK: - Derived vectors (V22 to V35)

    private func failure(_ result: Result<Void, TerminalTextInjector.InjectionError>)
        -> TerminalTextInjector.InjectionError? {
        if case .failure(let error) = result { return error }
        return nil
    }

    func testV22_itermSessionIdSplit() {
        XCTAssertEqual(
            TerminalTextInjector.resolveTarget(termProgram: "iTerm.app", termSessionId: "ABC", pid: 0),
            .iTermSession(uuid: "ABC"))
        XCTAssertEqual(
            TerminalTextInjector.resolveTarget(termProgram: "iTerm.app", termSessionId: "w0t0p0:", pid: 0),
            .iTermSession(uuid: "w0t0p0"))
    }

    @MainActor
    func testV23_injectUnsupportedTerminal() async {
        let result = await TerminalTextInjector.inject("x", termProgram: "", termSessionId: "", pid: 1)
        XCTAssertEqual(failure(result), .unsupportedTerminal("an unknown terminal"))
    }

    @MainActor
    func testV24_injectUnresolvablePane() async {
        let result = await TerminalTextInjector.inject(
            "x", termProgram: "Apple_Terminal", termSessionId: "", pid: 0)
        XCTAssertEqual(failure(result), .paneUnresolvable)
    }

    @MainActor
    func testV25_runNotFound() {
        let result = TerminalTextInjector.run(script: "return \"not_found\"", target: .terminalTTY(tty: "ttys004"))
        XCTAssertEqual(failure(result), .paneNotFound)
    }

    @MainActor
    func testV26_permissionDetectionAndPayload() {
        let target = TerminalTextInjector.Target.terminalTTY(tty: "ttys004")
        let message = "Automation permission is required to control Terminal."
            + " Grant it in System Settings ▸ Privacy & Security ▸ Automation."
        let expected = TerminalTextInjector.InjectionError.permissionDenied(
            message, targetBundleID: "com.apple.Terminal")
        XCTAssertEqual(
            failure(TerminalTextInjector.run(script: "error \"denied\" number -1743", target: target)), expected)
        XCTAssertEqual(
            failure(TerminalTextInjector.run(
                script: "error \"Privilege Violation occurred\" number -1", target: target)),
            expected)
    }

    func testV27_unsupportedTerminalDescription() {
        XCTAssertEqual(
            TerminalTextInjector.InjectionError.unsupportedTerminal("WarpTerminal").errorDescription,
            "Injecting text isn't supported for WarpTerminal yet — only iTerm2 and Terminal.app.")
    }

    func testV28_ttyForPidNilForInvalidPids() {
        XCTAssertNil(TerminalTextInjector.ttyForPid(0))
        XCTAssertNil(TerminalTextInjector.ttyForPid(-5))
    }

    func testV29_supportKeptInStepWithResolve() {
        XCTAssertEqual(
            TerminalTextInjector.resolveTarget(termProgram: "iTerm.app", termSessionId: "x:ABC", pid: 0),
            .iTermSession(uuid: "ABC"))
        XCTAssertNil(TerminalTextInjector.resolveTarget(termProgram: "Apple_Terminal", termSessionId: "", pid: 0))
        XCTAssertTrue(TerminalTextInjector.isSupported(termProgram: "iTerm.app"))
        XCTAssertTrue(TerminalTextInjector.isSupported(termProgram: "Apple_Terminal"))
    }

    @MainActor
    func testV30_permissionDetectionByNumberAndMessage() {
        let target = TerminalTextInjector.Target.terminalTTY(tty: "ttys004")
        for source in ["error \"denied\" number -1744",
                       "error \"Not authorized to send Apple events\" number -1"] {
            guard case .failure(.permissionDenied) = TerminalTextInjector.run(script: source, target: target) else {
                return XCTFail("expected permissionDenied for \(source)")
            }
        }
    }

    @MainActor
    func testV31_runErrorMessage() {
        let result = TerminalTextInjector.run(script: "error \"boom\"", target: .terminalTTY(tty: "ttys004"))
        XCTAssertEqual(failure(result), .scriptFailed("boom"))
    }

    func testV32_injectStopsOnFirstFailure() throws {
        throw XCTSkip("needs a live iTerm2 or Terminal.app pane to answer the typing script with not_found")
    }

    func testV33_injectFreshLookupPerHalf() throws {
        throw XCTSkip("needs a live terminal pane closed between the typing and Return scripts")
    }

    func testV34_errorDescriptions() {
        typealias Failure = TerminalTextInjector.InjectionError
        XCTAssertEqual(Failure.paneUnresolvable.errorDescription, "Couldn't identify the session's terminal pane.")
        XCTAssertEqual(
            Failure.paneNotFound.errorDescription,
            "The session's terminal pane wasn't found — it may have been closed.")
        XCTAssertEqual(Failure.scriptFailed("boom").errorDescription, "Terminal automation failed: boom")
    }

    func testV35_injectOrderWithEmptyText() throws {
        throw XCTSkip("needs a live terminal pane to run the typing script then the Return script")
    }
}
