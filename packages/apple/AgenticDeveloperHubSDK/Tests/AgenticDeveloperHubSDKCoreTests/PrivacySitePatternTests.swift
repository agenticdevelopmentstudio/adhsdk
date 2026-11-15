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

    @Test("X/* covers X, stars in X or not")
    func starPrefixCoversItself() {
        #expect(PrivacySitePattern.matches("foo.com/*/hi/*", url: url("https://foo.com/x/hi/")))
        #expect(PrivacySitePattern.matches("github.com/*/settings/*", url: url("https://github.com/o/r/settings")))
        #expect(PrivacySitePattern.matches("github.com/*/settings/*", url: url("https://github.com/o/r/settings/")))
        #expect(PrivacySitePattern.matches(
            "github.com/*/settings/*", url: url("https://github.com/o/r/settings/branches")))
        #expect(!PrivacySitePattern.matches("github.com/*/settings/*", url: url("https://github.com/o/r/set")))
    }

    @Test("a port matches that port, the scheme's default standing in; no port matches every port")
    func ports() {
        #expect(PrivacySitePattern.matches("localhost:3000/*", url: url("http://localhost:3000/admin")))
        #expect(PrivacySitePattern.matches("localhost:3000", url: url("http://localhost:3000/admin")))
        #expect(!PrivacySitePattern.matches("localhost:3000", url: url("http://localhost:3001/admin")))
        #expect(PrivacySitePattern.matches("127.0.0.1:8080", url: url("http://127.0.0.1:8080/")))
        #expect(PrivacySitePattern.matches("example.com:443", url: url("https://example.com/")))
        #expect(PrivacySitePattern.matches("localhost/*", url: url("http://localhost:3000/x")))
        #expect(PrivacySitePattern.matches("localhost:*", url: url("http://localhost:3000/x")))
    }

    @Test("a scheme is ignored only in front; a URL in the path stays in the path")
    func schemes() {
        #expect(PrivacySitePattern.matches("http://localhost:3000/admin", url: url("http://localhost:3000/admin")))
        #expect(PrivacySitePattern.matches("https://google.com", url: url("https://google.com/x")))
        let archived = "web.archive.org/web/*/https://example.com/*"
        #expect(PrivacySitePattern.matches(
            archived, url: url("https://web.archive.org/web/2020/https://example.com/")))
        #expect(!PrivacySitePattern.matches(archived, url: url("https://example.com/")))
    }

    @Test("IPv6 with or without brackets, IDN in Unicode or punycode")
    func hostForms() {
        #expect(PrivacySitePattern.matches("[::1]:3000/*", url: url("http://[::1]:3000/a")))
        #expect(PrivacySitePattern.matches("::1", url: url("http://[::1]:3000/a")))
        #expect(!PrivacySitePattern.matches("[::1]:3001", url: url("http://[::1]:3000/a")))
        #expect(PrivacySitePattern.matches("münchen.de/*", url: url("https://xn--mnchen-3ya.de/")))
        #expect(PrivacySitePattern.matches("xn--mnchen-3ya.de", url: url("https://münchen.de/x")))
        #expect(PrivacySitePattern.matches("*.MÜNCHEN.de", url: url("https://www.münchen.de/x")))
    }

    @Test("a path matches as the address reads: trailing slash, query, fragment, escapes")
    func addressForms() {
        #expect(PrivacySitePattern.matches("foo.com/docs/", url: url("https://foo.com/docs/")))
        #expect(PrivacySitePattern.matches("foo.com/docs/", url: url("https://foo.com/docs")))
        let pasted = "docs.google.com/document/d/ID/edit?tab=t.0"
        #expect(PrivacySitePattern.matches(pasted, url: url("https://docs.google.com/document/d/ID/edit?tab=t.0")))
        #expect(!PrivacySitePattern.matches(pasted, url: url("https://docs.google.com/document/d/ID/edit?tab=t.1")))
        #expect(PrivacySitePattern.matches("foo.com/a/b#sec", url: url("https://foo.com/a/b?x=1#sec")))
        #expect(PrivacySitePattern.matches("foo.com/a/b", url: url("https://foo.com/a/b?x=1#sec")))
        #expect(PrivacySitePattern.matches("foo.com/a%20b", url: url("https://foo.com/a%20b/")))
        #expect(PrivacySitePattern.matches("foo.com/a b", url: url("https://foo.com/a%20b")))
    }

    @Test("the site patterns' glob: * crosses /, everything else is literal")
    func wildcardGlob() {
        #expect(GlobPattern(wildcard: "/hi/*").matches("/hi/a/b"))
        #expect(GlobPattern(wildcard: "/a?b").matches("/a?b"))
        #expect(!GlobPattern(wildcard: "/a?b").matches("/axb"))
        #expect(GlobPattern(wildcard: "{a,b}").matches("{a,b}"))
        #expect(GlobPattern(wildcard: "**").matches(""))
        #expect(!GlobPattern(wildcard: "a*b").matches("a/c"))
        // The workspace syntax's `*` still stops at `/`.
        #expect(GlobPattern("src/*")?.matches("src/a/b") == false)
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
        #expect(PrivacySitePattern.defaultPattern(for: url("http://[::1]:3000/a")) == "[::1]/*")
        #expect(PrivacySitePattern.defaultPattern(for: url("http://localhost:3000/a")) == "localhost/*")
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
