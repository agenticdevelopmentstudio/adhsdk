import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("PrivacySitePattern")
struct PrivacySitePatternTests {

    private func url(_ text: String) -> URL { URL(string: text)! }

    @Test("* matches every page and the place with no address")
    func everywhere() {
        #expect(PrivacySitePattern.matches("*", url: url("https://example.com/a")))
        #expect(PrivacySitePattern.matches("*", url: nil))
    }

    @Test("only * applies where there is no address")
    func noAddress() {
        #expect(!PrivacySitePattern.matches("google.com/*", url: nil))
        #expect(!PrivacySitePattern.matches("*.google.com", url: nil))
    }

    @Test("a host with no path matches every path, ignoring case")
    func hostOnly() {
        #expect(PrivacySitePattern.matches("google.com", url: url("https://Google.COM/search?q=1")))
        #expect(PrivacySitePattern.matches("GOOGLE.com", url: url("https://google.com")))
        #expect(!PrivacySitePattern.matches("google.com", url: url("https://mail.google.com/")))
    }

    @Test("host globs")
    func hostGlob() {
        #expect(PrivacySitePattern.matches("*.google.com", url: url("https://mail.google.com/x")))
        #expect(!PrivacySitePattern.matches("*.google.com", url: url("https://google.com/x")))
        #expect(PrivacySitePattern.matches("*google.com", url: url("https://google.com/")))
    }

    @Test("path globs")
    func pathGlob() {
        #expect(PrivacySitePattern.matches("google.com/*", url: url("https://google.com/")))
        #expect(PrivacySitePattern.matches("google.com/*", url: url("https://google.com")))
        #expect(PrivacySitePattern.matches("foo.com/hi/*", url: url("https://foo.com/hi/there")))
        #expect(PrivacySitePattern.matches("foo.com/hi/*", url: url("https://foo.com/hi")))
        #expect(!PrivacySitePattern.matches("foo.com/hi/*", url: url("https://foo.com/high")))
        #expect(!PrivacySitePattern.matches("foo.com/hi/*", url: url("https://foo.com/")))
        #expect(PrivacySitePattern.matches("foo.com/*/edit", url: url("https://foo.com/doc/edit")))
    }

    @Test("parse and format the editor's comma-separated text")
    func parseFormat() {
        #expect(PrivacySitePattern.parse(" google.com/* , ,foo.com/hi/*") == ["google.com/*", "foo.com/hi/*"])
        #expect(PrivacySitePattern.format(["*", "a.com"]) == "*, a.com")
    }

    @Test("a word never has no sites: none at all is *")
    func emptySitesAreEverywhere() throws {
        #expect(PrivacySitePattern.normalized([]) == ["*"])
        #expect(PrivacySitePattern.normalized([" ", ""]) == ["*"])
        #expect(PrivacySitePattern.normalized([" a.com ", ""]) == ["a.com"])

        // An emptied Sites cell: what the editor sets from parse("").
        var word = PrivacyWord(alias: "A", real: "a", sites: ["a.com"])
        word.sites = PrivacySitePattern.parse(" , ")
        #expect(word.sites == ["*"])
        #expect(word.applies(at: nil))
        #expect(PrivacyWord(alias: "A", real: "a", sites: []).sites == ["*"])

        // A `[]` an earlier editor saved.
        let stored = Data(#"[{"alias":"A","real":"a","enabled":true,"global":false,"sites":[]}]"#.utf8)
        #expect(try JSONDecoder().decode([PrivacyWord].self, from: stored).first?.sites == ["*"])
    }

    @Test("a new word's default pattern is the page's host")
    func defaultPattern() {
        #expect(PrivacySitePattern.defaultPattern(for: url("https://WWW.Google.com/search")) == "www.google.com/*")
        #expect(PrivacySitePattern.defaultPattern(for: nil) == "*")
        #expect(PrivacySitePattern.defaultPattern(for: url("about:blank")) == "*")
    }

    @Test("words filter by the address")
    func filterByURL() {
        let words = [
            PrivacyWord(alias: "E", real: "Everywhere"),
            PrivacyWord(alias: "O", real: "Off", isEnabled: false),
            PrivacyWord(alias: "G", real: "Google", sites: ["google.com/*"]),
            PrivacyWord(alias: "F", real: "Foo", sites: ["bar.com", "foo.com/hi/*"])
        ]
        #expect(words.filter(for: url("https://google.com/a")).pairs.map(\.real).sorted() == ["Everywhere", "Google"])
        #expect(words.filter(for: url("https://foo.com/hi/x")).pairs.map(\.real).sorted() == ["Everywhere", "Foo"])
        #expect(words.filter(for: nil).pairs.map(\.real) == ["Everywhere"])
    }

    @Test("old JSON migrates to *, and new JSON keeps the old fields")
    func migration() throws {
        let old = Data(#"[{"alias":"A","real":"a"},{"alias":"B","real":"b","global":false,"pane":"x"}]"#.utf8)
        let words = try JSONDecoder().decode([PrivacyWord].self, from: old)
        #expect(words.map(\.sites) == [["*"], ["*"]])

        // A site word is written global, so a pane-era build, which reads
        // `global` and `pane` and not `sites`, conceals it everywhere rather
        // than nowhere.
        let saved = try JSONEncoder().encode([PrivacyWord(alias: "C", real: "c", sites: ["a.com"])])
        let object = try #require(try JSONSerialization.jsonObject(with: saved) as? [[String: Any]]).first
        #expect(object?["global"] as? Bool == true)
        #expect(object?["enabled"] as? Bool == true)
        #expect(object?["sites"] as? [String] == ["a.com"])
        #expect(object?["pane"] == nil)
        #expect(try JSONDecoder().decode([PrivacyWord].self, from: saved).first?.sites == ["a.com"])
    }

    @Test("an older build's re-save drops sites, and the word widens to *")
    func olderBuildResave() throws {
        // What a pane-era build writes back after reading a site word: its
        // own keys, `sites` gone.
        let resaved = Data(#"[{"alias":"C","real":"c","enabled":true,"global":true}]"#.utf8)
        let word = try #require(try JSONDecoder().decode([PrivacyWord].self, from: resaved).first)
        #expect(word.sites == ["*"])
        #expect(word.applies(at: nil))
        #expect(word.applies(at: url("https://a.com/")))
    }
}
