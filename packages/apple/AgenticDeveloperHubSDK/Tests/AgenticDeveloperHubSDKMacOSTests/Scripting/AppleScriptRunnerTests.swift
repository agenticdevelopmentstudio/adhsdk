import Testing
import Foundation
@testable import AgenticDeveloperHubSDKMacOS

/// `AppleScriptRunner.run` compiles and executes scripts via `NSAppleScript`.
/// Tests here stick to scripts that don't touch other applications — a plain
/// `return` expression or an explicit `error` — so they don't trip the AppKit
/// sandbox / Automation permission prompts that `tell application ...` does.
@Suite("AppleScriptRunner", .serialized)
struct AppleScriptRunnerTests {

    // The `.compileFailed` path is unreachable in practice: `NSAppleScript(source:)`
    // never returns nil — it accepts any string and defers syntax/tokenizer errors
    // to `executeAndReturnError` (surfaced as `.runtimeFailed`). The enum case
    // exists as a defensive catch.

    @Test("simple return string yields .success with that string")
    func successReturnsString() {
        let result = AppleScriptRunner.run("return \"hello\"")
        #expect(result == .success("hello"))
    }

    @Test("numeric return is stringified by NSAppleScript")
    func successReturnsNumericString() {
        let result = AppleScriptRunner.run("return 42")
        #expect(result == .success("42"))
    }

    @Test("explicit error raises .runtimeFailed with the message")
    func runtimeFailed() {
        let result = AppleScriptRunner.run("error \"boom\" number -1728")
        switch result {
        case .runtimeFailed(let message, let number):
            #expect(message.contains("boom"))
            #expect(number == -1728)
        default:
            Issue.record("expected .runtimeFailed, got \(result)")
        }
    }

    @Test("empty source compiles and returns .success(nil)")
    func emptySourceSucceeds() {
        // NSAppleScript accepts empty source; execution returns a null descriptor
        // whose stringValue is nil.
        let result = AppleScriptRunner.run("")
        #expect(result == .success(nil))
    }

    @Test(.disabled(Comment(rawValue:
        "scripting-005: the fallback branch needs an error dictionary with no message or number entries, "
            + "and NSAppleScript always supplies both, so no source string reaches it through the public API")))
    func scripting005FallbackValues() {}

    @Test(.disabled(Comment(rawValue:
        "scripting-006: NSAppleScript(source:) never returns nil, so .compileFailed cannot be reached "
            + "(see the comment at the top of this suite)")))
    func scripting006CompileFailure() {}

    @Test("scripting-007: results compare by case and carried value")
    func scripting007ResultEquality() {
        #expect(AppleScriptRunner.Result.success("x") == .success("x"))
        #expect(AppleScriptRunner.Result.success(nil) == .success(nil))
        #expect(AppleScriptRunner.Result.success("x") != .success("y"))
        #expect(AppleScriptRunner.Result.success("x") != .compileFailed)
        #expect(AppleScriptRunner.Result.compileFailed == .compileFailed)
        #expect(AppleScriptRunner.Result.runtimeFailed(message: "m", number: 1)
            == .runtimeFailed(message: "m", number: 1))
        #expect(AppleScriptRunner.Result.runtimeFailed(message: "m", number: 1)
            != .runtimeFailed(message: "m", number: 2))
    }

    /// Runs a script synchronously and reports where it ran, relative to the calling thread.
    private static func runOffTheCallersThread() -> (offMain: Bool, sameThread: Bool, result: Bool) {
        let before = Thread.current
        let offMain = !Thread.isMainThread
        let result = AppleScriptRunner.run("return \"background\"")
        return (offMain, Thread.current === before, result == .success("background"))
    }

    @Test("scripting-008: run executes and returns on the thread it was called from")
    func scripting008RunsOnTheCallersThread() async {
        let outcome = await Task.detached { Self.runOffTheCallersThread() }.value

        #expect(outcome.offMain)
        #expect(outcome.sameThread)
        #expect(outcome.result)
    }

    @Test(.disabled(Comment(rawValue:
        "scripting-009: marshaling to the main thread is documented as the caller's job; "
            + "run performs no thread check, so there is no behavior to observe")))
    func scripting009CallerMarshaling() {}
}
