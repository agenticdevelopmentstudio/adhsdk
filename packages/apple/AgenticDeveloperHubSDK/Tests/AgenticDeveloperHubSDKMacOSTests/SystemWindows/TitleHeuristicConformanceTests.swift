import Testing
import Foundation
import AgenticDeveloperHubSDKCore

/// Conformance vectors wmh-003 through wmh-038 of system-windows/matching/title-heuristics, except the ones
/// `HeuristicTests` already asserts (wmh-001, 002, 011, 012, 022).
@Suite("Title heuristic conformance")
struct TitleHeuristicConformanceTests {

    private let emDash = "\u{2014}"
    private let enDash = "\u{2013}"

    // MARK: Xcode

    @Test("wmh-003: Xcode with no separator returns the whole title")
    func wmh003() {
        #expect(XcodeHeuristic().extractPattern(from: "MyApp") == "MyApp")
    }

    @Test("wmh-004: Xcode drops the file and its edited marker")
    func wmh004() {
        let title = "QualityTime \(emDash) ContentView.swift (Edited)"
        #expect(XcodeHeuristic().extractPattern(from: title) == "QualityTime")
    }

    @Test("wmh-005: Xcode with a blank title yields nil")
    func wmh005() {
        #expect(XcodeHeuristic().extractPattern(from: "   ") == nil)
    }

    @Test("wmh-006: every heuristic yields nil for the empty title")
    func wmh006() {
        let heuristics: [any AppHeuristic] = [
            XcodeHeuristic(), WarpHeuristic(), BraveHeuristic(), VSCodeHeuristic(), TerminalHeuristic()
        ]
        for heuristic in heuristics {
            #expect(heuristic.extractPattern(from: "") == nil, "\(heuristic.name)")
        }
    }

    @Test("wmh-007: an ASCII hyphen is not a separator")
    func wmh007() {
        #expect(XcodeHeuristic().extractPattern(from: "MyApp - ContentView.swift") == "MyApp - ContentView.swift")
    }

    // MARK: Title parser

    @Test("wmh-008: the first separator in the list wins")
    func wmh008() {
        #expect(HeuristicTitleParser.components(of: "A \(emDash) B \(enDash) C") == ["A", "B \(enDash) C"])
    }

    @Test("wmh-009: no separator gives one trimmed component")
    func wmh009() {
        #expect(HeuristicTitleParser.components(of: "  zsh ") == ["zsh"])
    }

    @Test("wmh-010: components are trimmed and empty ones kept")
    func wmh010() {
        #expect(HeuristicTitleParser.components(of: "a \(emDash) ") == ["a", ""])
    }

    // MARK: Warp

    @Test("wmh-013: Warp strips the dirty indicator and the branch")
    func wmh013() {
        #expect(WarpHeuristic().extractPattern(from: "Claude - QualityTime (main) *") == "QualityTime")
    }

    @Test("wmh-014: Warp returns a plain remainder")
    func wmh014() {
        #expect(WarpHeuristic().extractPattern(from: "mike - Documents") == "Documents")
    }

    @Test("wmh-015: Warp needs the hyphen separator")
    func wmh015() {
        #expect(WarpHeuristic().extractPattern(from: "QualityTime \(emDash) main") == nil)
    }

    @Test("wmh-016: Warp keeps later separators in the remainder")
    func wmh016() {
        #expect(WarpHeuristic().extractPattern(from: "a - b - c") == "b - c")
    }

    @Test("wmh-017: Warp ignores a trailing slash")
    func wmh017() {
        #expect(WarpHeuristic().extractPattern(from: "mike - ~/projects/myapp/") == "myapp")
    }

    // MARK: Brave

    @Test("wmh-018: Brave strips the app suffix")
    func wmh018() {
        #expect(BraveHeuristic().extractPattern(from: "GitHub - Pull Requests - Brave") == "GitHub - Pull Requests")
    }

    @Test("wmh-019: Brave bare app name yields nil")
    func wmh019() {
        #expect(BraveHeuristic().extractPattern(from: "Brave") == nil)
    }

    @Test("wmh-020: Brave with only the suffix yields nil")
    func wmh020() {
        #expect(BraveHeuristic().extractPattern(from: " - Brave") == nil)
    }

    @Test("wmh-021: Brave suffix match is case-sensitive and exact")
    func wmh021() {
        #expect(BraveHeuristic().extractPattern(from: "Docs - Brave Browser") == "Docs - Brave Browser")
    }

    // MARK: VS Code

    @Test("wmh-023: VS Code prefers the last component after a filename")
    func wmh023() {
        #expect(VSCodeHeuristic().extractPattern(from: "settings.json \(emDash) myproject") == "myproject")
    }

    @Test("wmh-024: VS Code keeps the first when both look like filenames")
    func wmh024() {
        #expect(VSCodeHeuristic().extractPattern(from: "api.go \(emDash) main.ts") == "api.go")
    }

    @Test("wmh-025: VS Code generic single title yields nil")
    func wmh025() {
        #expect(VSCodeHeuristic().extractPattern(from: "Welcome") == nil)
    }

    @Test("wmh-026: VS Code generic last returns the first component")
    func wmh026() {
        #expect(VSCodeHeuristic().extractPattern(from: "Welcome \(emDash) Visual Studio Code") == "Welcome")
    }

    @Test("wmh-027: VS Code empty first component yields nil")
    func wmh027() {
        #expect(VSCodeHeuristic().extractPattern(from: " \(emDash) foo") == nil)
    }

    @Test("wmh-028: VS Code extension match is case-insensitive")
    func wmh028() {
        #expect(VSCodeHeuristic().extractPattern(from: "notes.JSON \(emDash) proj") == "proj")
    }

    // MARK: Terminal

    @Test("wmh-029: Terminal takes the second component and drops the login dash")
    func wmh029() {
        #expect(TerminalHeuristic().extractPattern(from: "mfullerton \(emDash) -zsh \(emDash) 80x24") == "zsh")
    }

    @Test("wmh-030: Terminal keeps a command with arguments")
    func wmh030() {
        #expect(TerminalHeuristic().extractPattern(from: "mfullerton \(emDash) ssh user@host") == "ssh user@host")
    }

    @Test("wmh-031: Terminal drops exactly one leading dash")
    func wmh031() {
        #expect(TerminalHeuristic().extractPattern(from: "u \(emDash) --x") == "-x")
    }

    @Test("wmh-032: Terminal with only a dash left yields nil")
    func wmh032() {
        #expect(TerminalHeuristic().extractPattern(from: "u \(emDash) -") == nil)
    }

    @Test("wmh-033: Terminal single component returns the title")
    func wmh033() {
        #expect(TerminalHeuristic().extractPattern(from: "bash") == "bash")
    }

    // MARK: Fingerprints and identity

    @Test("wmh-034: Terminal fingerprints with the app-only strategy")
    func wmh034() {
        let fingerprint = TerminalHeuristic().fingerprintPattern(for: "u \(emDash) vim \(emDash) 80x24")
        #expect(fingerprint?.pattern == "vim")
        #expect(fingerprint?.strategy == .appOnly)
    }

    @Test("wmh-035: Xcode fingerprints with the substring strategy")
    func wmh035() {
        let fingerprint = XcodeHeuristic().fingerprintPattern(for: "MyApp \(emDash) a.swift")
        #expect(fingerprint?.pattern == "MyApp")
        #expect(fingerprint?.strategy == .appAndTitleSubstring)
    }

    @Test("wmh-036: Brave fingerprint of the bare app name is nil")
    func wmh036() {
        #expect(BraveHeuristic().fingerprintPattern(for: "Brave") == nil)
    }

    @Test("wmh-037: built-in names and app names")
    func wmh037() {
        #expect(XcodeHeuristic().name == "Xcode")
        #expect(XcodeHeuristic().appNames == ["Xcode"])
        #expect(WarpHeuristic().name == "Warp")
        #expect(WarpHeuristic().appNames == ["Warp"])
        #expect(BraveHeuristic().name == "Brave Browser")
        #expect(BraveHeuristic().appNames == ["Brave Browser"])
        #expect(VSCodeHeuristic().name == "VS Code")
        #expect(VSCodeHeuristic().appNames == ["Code", "Visual Studio Code", "Cursor"])
        #expect(TerminalHeuristic().name == "Terminal")
        #expect(TerminalHeuristic().appNames == ["Terminal"])
    }

    @Test("wmh-038: concurrent calls on one shared heuristic agree")
    func wmh038() async {
        let heuristic = XcodeHeuristic()
        let title = "MyApp \(emDash) a.swift"
        let results = await withTaskGroup(of: String?.self) { group in
            for _ in 0..<50 {
                group.addTask { heuristic.extractPattern(from: title) }
            }
            var collected: [String?] = []
            for await result in group { collected.append(result) }
            return collected
        }
        #expect(results.count == 50)
        #expect(results.allSatisfy { $0 == "MyApp" })
    }
}
