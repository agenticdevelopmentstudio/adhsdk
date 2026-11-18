import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("PrivacyTerminalPattern")
struct PrivacyTerminalPatternTests {

    private let home = FileManager.default.homeDirectoryForCurrentUser.path

    @Test("no patterns is no terminal")
    func empty() {
        #expect(!PrivacyTerminalPattern.matches([], directory: "/tmp"))
        #expect(!PrivacyTerminalPattern.matches([], directory: nil))
    }

    @Test("* is every terminal, including one with no directory")
    func everywhere() {
        #expect(PrivacyTerminalPattern.matches(["*"], directory: "/Users/someone/project"))
        #expect(PrivacyTerminalPattern.matches(["*"], directory: nil))
        #expect(!PrivacyTerminalPattern.matches(["adkitchen"], directory: nil))
    }

    @Test("a bare name matches a directory of that name and everything inside it")
    func bareName() {
        #expect(PrivacyTerminalPattern.matches(["adkitchen"], directory: "/src/apps/adkitchen"))
        #expect(PrivacyTerminalPattern.matches(["adkitchen"], directory: "/src/apps/adkitchen/App/Sources"))
        #expect(!PrivacyTerminalPattern.matches(["adkitchen"], directory: "/src/apps/other"))
    }

    @Test("~ is the home folder, and ** reaches everything below")
    func homeAnchored() {
        #expect(PrivacyTerminalPattern.matches(["~/work/**"], directory: home + "/work/client/repo"))
        #expect(!PrivacyTerminalPattern.matches(["~/work/**"], directory: home + "/play/repo"))
    }

    @Test("! takes a directory back out; the last match decides")
    func negation() {
        let patterns = ["~/work/**", "!~/work/public/**"]
        #expect(PrivacyTerminalPattern.matches(patterns, directory: home + "/work/client"))
        #expect(!PrivacyTerminalPattern.matches(patterns, directory: home + "/work/public/site"))
    }

    @Test("parse trims and drops empties; format joins")
    func parseAndFormat() {
        #expect(PrivacyTerminalPattern.parse(" a , ,~/b/** ") == ["a", "~/b/**"])
        #expect(PrivacyTerminalPattern.format(["a", "~/b/**"]) == "a, ~/b/**")
    }
}

@Suite("PrivacyWord terminals")
struct PrivacyWordTerminalsTests {

    @Test("a word saved before terminals existed keeps * only if its sites had *")
    func decodeDefault() throws {
        let everywhere = #"{"alias":"A","real":"R","isEnabled":true,"sites":["*"]}"#
        let onSite = #"{"alias":"A","real":"R","isEnabled":true,"sites":["google.com/*"]}"#
        let decoder = JSONDecoder()
        #expect(try decoder.decode(PrivacyWord.self, from: Data(everywhere.utf8)).terminals == ["*"])
        #expect(try decoder.decode(PrivacyWord.self, from: Data(onSite.utf8)).terminals.isEmpty)
    }

    @Test("terminals round-trip")
    func roundTrip() throws {
        let word = PrivacyWord(alias: "A", real: "R", sites: ["google.com/*"], terminals: ["adkitchen"])
        let decoded = try JSONDecoder().decode(PrivacyWord.self, from: JSONEncoder().encode(word))
        #expect(decoded.terminals == ["adkitchen"])
    }

    @Test("a disabled word applies in no terminal")
    func disabled() {
        let word = PrivacyWord(alias: "A", real: "R", isEnabled: false, terminals: ["*"])
        #expect(!word.appliesInTerminal(at: "/tmp"))
    }
}
