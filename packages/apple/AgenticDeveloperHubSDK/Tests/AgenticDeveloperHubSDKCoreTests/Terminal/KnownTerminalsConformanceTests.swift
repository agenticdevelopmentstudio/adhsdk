import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for `KnownTerminals` and `KnownTerminal`.
final class KnownTerminalsConformanceTests: XCTestCase {

    func testV001_matchesITerm2() {
        let entry = KnownTerminals.match(termProgram: "iTerm.app")
        XCTAssertEqual(entry?.bundleID, "com.googlecode.iterm2")
        XCTAssertEqual(entry?.displayName, "iTerm2")
    }

    func testV002_matchesTerminalApp() {
        XCTAssertEqual(KnownTerminals.match(termProgram: "Apple_Terminal")?.bundleID, "com.apple.Terminal")
    }

    func testV003_matchesWarp() {
        XCTAssertEqual(KnownTerminals.match(termProgram: "WarpTerminal")?.bundleID, "dev.warp.Warp-Stable")
    }

    func testV004_matchesVSCode() {
        XCTAssertEqual(KnownTerminals.match(termProgram: "vscode")?.bundleID, "com.microsoft.VSCode")
    }

    func testV005_unknownTerminalReturnsNil() {
        XCTAssertNil(KnownTerminals.match(termProgram: "ghostty"))
    }

    func testV006_matchIsCaseSensitive() {
        XCTAssertNil(KnownTerminals.match(termProgram: "iterm.app"))
    }

    func testV008_emptyTermProgramReturnsNil() {
        XCTAssertNil(KnownTerminals.match(termProgram: ""))
    }

    func testV009_customCatalogMatchesAnyOfItsValues() {
        let custom = [
            KnownTerminal(displayName: "Custom", bundleID: "com.example.custom", termProgramValues: ["a", "b"])
        ]
        XCTAssertEqual(KnownTerminals.match(termProgram: "b", in: custom), custom[0])
    }

    func testV010_emptyCatalogReturnsNil() {
        XCTAssertNil(KnownTerminals.match(termProgram: "iTerm.app", in: []))
    }

    func testV011_catalogOrder() {
        XCTAssertEqual(KnownTerminals.all.map(\.displayName), ["iTerm2", "Terminal.app", "Warp", "VS Code"])
    }

    func testV012_firstOfTwoMatchingEntriesWins() {
        let first = KnownTerminal(displayName: "First", bundleID: "com.example.first", termProgramValues: ["x"])
        let second = KnownTerminal(displayName: "Second", bundleID: "com.example.second", termProgramValues: ["x"])
        XCTAssertEqual(KnownTerminals.match(termProgram: "x", in: [first, second]), first)
    }

    func testV013_entriesBuiltFromTheSameArgumentsAreEqual() {
        let left = KnownTerminal(displayName: "T", bundleID: "com.example.t", termProgramValues: ["t"])
        let right = KnownTerminal(displayName: "T", bundleID: "com.example.t", termProgramValues: ["t"])
        XCTAssertEqual(left, right)
    }

    func testV014_noTermProgramValueAppearsTwice() {
        let values = KnownTerminals.all.flatMap(\.termProgramValues)
        XCTAssertEqual(values.count, Set(values).count)
    }
}
