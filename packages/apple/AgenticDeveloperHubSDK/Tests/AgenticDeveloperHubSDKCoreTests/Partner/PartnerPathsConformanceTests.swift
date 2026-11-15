import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("PartnerPaths conformance") struct PartnerPathsConformanceTests {
    private let paths = PartnerPaths(home: URL(fileURLWithPath: "/h"), token: "tok")

    @Test("V1: mcp config sits in the partner directory")
    func testV1_mcpConfigPath() {
        #expect(paths.mcpConfig.path == "/h/.tok/partner/mcp.json")
    }

    @Test("V2: skill file derives from the job id")
    func testV2_skillFilePath() {
        #expect(paths.skillFile(jobID: "x").path == "/h/.claude/skills/adkitchen-partner-x/SKILL.md")
    }

    @Test("V3: directory is home, dot token, partner")
    func testV3_directoryPath() {
        #expect(paths.directory.path == "/h/.tok/partner")
    }

    @Test("V4: system prompt, jobs and reviews locations")
    func testV4_systemPromptJobsAndReviews() {
        #expect(paths.systemPrompt.path == "/h/.tok/partner/system-prompt.md")
        #expect(paths.jobsDirectory.path == "/h/.tok/partner/jobs")
        #expect(paths.reviewsDirectory.path == "/h/.tok/partner/reviews")
    }

    @Test("V5: skills directory does not depend on the token")
    func testV5_skillsDirectoryIgnoresToken() {
        let home = URL(fileURLWithPath: "/h")
        let first = PartnerPaths(home: home, token: "one")
        let second = PartnerPaths(home: home, token: "two")
        #expect(first.skillsDirectory.path == "/h/.claude/skills")
        #expect(second.skillsDirectory.path == "/h/.claude/skills")
    }

    @Test("V6: equality compares home and token")
    func testV6_equality() {
        let home = URL(fileURLWithPath: "/h")
        #expect(PartnerPaths(home: home, token: "a") == PartnerPaths(home: home, token: "a"))
        #expect(PartnerPaths(home: home, token: "a") != PartnerPaths(home: home, token: "b"))
    }

    @Test("V7: reading every property touches no file")
    func testV7_noFileAccess() {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let value = PartnerPaths(home: home, token: "tok")
        let urls = [value.directory, value.mcpConfig, value.systemPrompt, value.jobsDirectory,
                    value.reviewsDirectory, value.skillsDirectory, value.skillFile(jobID: "x")]
        #expect(urls.count == 7)
        #expect(!FileManager.default.fileExists(atPath: home.path))
    }

    @Test("V8: a job id is joined as written")
    func testV8_noValidation() {
        let value = PartnerPaths(home: URL(fileURLWithPath: "/h"), token: "tok")
        #expect(value.skillFile(jobID: "../x").path == "/h/.claude/skills/adkitchen-partner-../x/SKILL.md")
    }
}
