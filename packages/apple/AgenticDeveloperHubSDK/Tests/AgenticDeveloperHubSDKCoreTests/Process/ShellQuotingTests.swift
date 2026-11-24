import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct ShellQuotingTests {

    @Test func emptyWordIsQuoted() {
        #expect(ShellQuoting.quoteIfNeeded("") == "''")
    }

    @Test func plainWordIsUnchanged() {
        #expect(ShellQuoting.quoteIfNeeded("/usr/local/bin/steno-1.2") == "/usr/local/bin/steno-1.2")
    }

    @Test func singleQuoteIsEscapedLikeShlex() {
        #expect(ShellQuoting.quoteIfNeeded("it's") == "'it'\"'\"'s'")
    }

    @Test func singleQuoteBeforeCombiningMarkIsEscaped() {
        #expect(ShellQuoting.quote("a'\u{301}b") == "'a'\"'\"'\u{301}b'")
    }

    @Test func spacesAreQuoted() {
        #expect(ShellQuoting.quoteIfNeeded("a b") == "'a b'")
    }

    @Test func nonASCIILetterIsQuoted() {
        #expect(ShellQuoting.quoteIfNeeded("caf\u{e9}") == "'caf\u{e9}'")
    }

    @Test func quoteAlwaysQuotes() {
        #expect(ShellQuoting.quote("plain") == "'plain'")
    }

    @Test func commandLineQuotesOnlyWordsThatNeedIt() {
        #expect(ShellQuoting.commandLine(["ls", "-la", "my dir"]) == "ls -la 'my dir'")
    }

    @Test("shell-quoting-009: a lone single quote")
    func shellQuoting009LoneSingleQuote() {
        #expect(ShellQuoting.quote("'") == "''\"'\"''")
    }

    @Test("shell-quoting-010: empty word list")
    func shellQuoting010EmptyCommandLine() {
        #expect(ShellQuoting.commandLine([]) == "")
    }

    @Test("shell-quoting-011: newline is preserved inside quotes")
    func shellQuoting011Newline() {
        #expect(ShellQuoting.quoteIfNeeded("a\nb") == "'a\nb'")
    }

    @Test("shell-quoting-012: shell metacharacter is quoted")
    func shellQuoting012Metacharacter() {
        #expect(ShellQuoting.quoteIfNeeded("$HOME") == "'$HOME'")
    }

    @Test("shell-quoting-013: command line round-trips through sh")
    func shellQuoting013RoundTrip() throws {
        let words = ["a b", "it's", "$HOME", ""]
        let shell = Process()
        shell.executableURL = URL(fileURLWithPath: "/bin/sh")
        shell.arguments = ["-c", "printf \"%s\\n\" " + ShellQuoting.commandLine(words)]
        let pipe = Pipe()
        shell.standardOutput = pipe
        try shell.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        shell.waitUntilExit()
        #expect(String(bytes: data, encoding: .utf8) == "a b\nit's\n$HOME\n\n")
    }
}
