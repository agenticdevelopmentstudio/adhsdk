import Testing
import Foundation
import AgenticDeveloperHubSDKCore

@Suite("Heuristics")
struct HeuristicTests {

    @Test("window-matching-010: Xcode extracts the project before the em dash")
    func xcode() {
        #expect(XcodeHeuristic().extractPattern(from: "MyApp \u{2014} ContentView.swift") == "MyApp")
    }

    @Test("window-matching-010: Xcode also handles the en-dash separator variant")
    func xcodeEnDash() {
        #expect(XcodeHeuristic().extractPattern(from: "MyApp \u{2013} ContentView.swift") == "MyApp")
    }

    @Test("VSCode extracts the workspace name")
    func vscode() {
        #expect(VSCodeHeuristic().extractPattern(from: "temporal \u{2014} api.go") == "temporal")
    }

    @Test("Warp extracts the last path component")
    func warpPath() {
        #expect(WarpHeuristic().extractPattern(from: "mike - ~/projects/myapp (develop)") == "myapp")
    }

    @Test("Warp root directory yields no pattern (not a literal slash)")
    func warpRoot() {
        #expect(WarpHeuristic().extractPattern(from: "user - / (main)") == nil)
    }

    @Test("window-matching-011: a regex custom heuristic fingerprints by the pattern, not the captured value")
    func regexFingerprint() {
        let rule = CustomHeuristicRule(appName: "Jira", titlePattern: "JIRA-\\d+", matchMode: .regex)
        let heuristic = CustomHeuristic(rule: rule)

        let fingerprint = heuristic.fingerprintPattern(for: "JIRA-1234 \u{2014} details")
        #expect(fingerprint?.pattern == "JIRA-\\d+")
        #expect(fingerprint?.strategy == .appAndTitleRegex)

        // A title the rule doesn't match produces no fingerprint.
        #expect(heuristic.fingerprintPattern(for: "no ticket here") == nil)
    }

    @Test("window-matching-012: a substring custom heuristic fingerprints by the substring with the substring strategy")
    func substringFingerprint() {
        let rule = CustomHeuristicRule(appName: "Notes", titlePattern: "Daily", matchMode: .substring)
        let heuristic = CustomHeuristic(rule: rule)
        let fingerprint = heuristic.fingerprintPattern(for: "Daily Standup")
        #expect(fingerprint?.pattern == "Daily")
        #expect(fingerprint?.strategy == .appAndTitleSubstring)
    }

    @Test("window-matching-013: registry treats a custom override of a built-in app as user-defined")
    func isBuiltInOverride() {
        let registry = HeuristicRegistry()
        #expect(registry.isBuiltIn(appName: "Xcode"))

        registry.registerCustomRules([
            CustomHeuristicRule(appName: "Xcode", titlePattern: "X", matchMode: .substring)
        ])
        #expect(!registry.isBuiltIn(appName: "Xcode"))
    }

    // MARK: - Custom rule matching

    @Test("window-matching-014: an empty pattern matches no title")
    func ruleEmptyPattern() {
        let rule = CustomHeuristicRule(appName: "Notes", titlePattern: "", matchMode: .substring)
        #expect(rule.matchTitle("anything") == nil)
    }

    @Test("window-matching-015: substring mode returns the pattern, not the title's slice")
    func ruleSubstringMatch() {
        let rule = CustomHeuristicRule(appName: "Notes", titlePattern: "dash", matchMode: .substring)
        #expect(rule.matchTitle("My DASHBOARD") == "dash")
    }

    @Test("window-matching-016: a zero-length regex match yields nil")
    func ruleRegexNonEmpty() {
        let rule = CustomHeuristicRule(appName: "Notes", titlePattern: ".*", matchMode: .regex)
        #expect(rule.matchTitle("") == nil)
    }

    @Test("window-matching-017: an invalid regex yields nil")
    func ruleRegexInvalid() {
        let rule = CustomHeuristicRule(appName: "Notes", titlePattern: "(", matchMode: .regex)
        // The vector also expects one logged error; os_log output is not observable from a unit test.
        #expect(rule.matchTitle("x") == nil)
    }

    @Test("window-matching-018: an empty name defaults to app and pattern")
    func ruleDefaultName() {
        let rule = CustomHeuristicRule(appName: "Safari", titlePattern: "Docs")
        #expect(rule.name == "Safari - Docs")
    }

    // MARK: - Registry

    private struct StubHeuristic: AppHeuristic {
        let name: String
        let appNames: [String]
        func extractPattern(from title: String) -> String? { title }
    }

    @Test("window-matching-025: lookup is case-insensitive and the later registration wins")
    func registryCaseInsensitiveLastWins() {
        let registry = HeuristicRegistry(heuristics: [])
        registry.register(StubHeuristic(name: "H1", appNames: ["Foo"]))
        registry.register(StubHeuristic(name: "H2", appNames: ["foo"]))
        #expect(registry.heuristic(for: "FOO")?.name == "H2")
        #expect(registry.heuristic(for: "Bar") == nil)
    }

    @Test("window-matching-026: registering an empty custom rule list restores the built-in lookup")
    func registryCustomClear() {
        let registry = HeuristicRegistry()
        registry.registerCustomRules([
            CustomHeuristicRule(appName: "Xcode", titlePattern: "X", matchMode: .substring)
        ])
        #expect(registry.heuristic(for: "Xcode") is CustomHeuristic)

        registry.registerCustomRules([])
        #expect(registry.heuristic(for: "Xcode") is XcodeHeuristic)
        #expect(registry.customRules.isEmpty)
    }

    // MARK: - Title parser

    @Test("window-matching-032: a title with no separator is trimmed and returned whole")
    func parserTrimNoSeparator() {
        #expect(HeuristicTitleParser.components(of: "  solo  ") == ["solo"])
    }
}
