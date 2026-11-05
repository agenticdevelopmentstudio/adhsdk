import XCTest
@testable import AgenticDeveloperHubSDKCore

final class GitProjectRootDisplayLabelTests: XCTestCase {

    func testAbbreviatesHomeAndAppendsTheBranch() {
        let root = NSHomeDirectory() + "/src/site"
        XCTAssertEqual(GitProjectRoot.displayLabel(root: root, branch: "main"), "~/src/site · main")
    }

    func testNoBranchIsJustThePath() {
        XCTAssertEqual(GitProjectRoot.displayLabel(root: "/opt/repo", branch: ""), "/opt/repo")
    }
}
