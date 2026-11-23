import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Partner process configuration") struct PartnerProcessConfigurationTests {
    @Test func argumentsForFirstStartAndResume() {
        var config = PartnerProcessConfiguration(
            executable: "/x/claude", sessionID: UUID(), resume: false, model: "", permissionMode: "dontAsk",
            allowedTools: ["mcp__adkitchen"], mcpConfigPath: "/m.json", systemPromptPath: "/p.md",
            workingDirectory: "/w")
        #expect(config.arguments.contains("--session-id") && !config.arguments.contains("--resume"))
        #expect(!config.arguments.contains("--model"))
        config.resume = true; config.model = "opus"
        #expect(config.arguments.contains("--resume") && config.arguments.contains("--model"))
        #expect(config.arguments.contains("--strict-mcp-config") && config.arguments.contains("--replay-user-messages"))
    }
    @Test func mcpConfigWritesHeadersAndMode0600() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("mcp.json")
        try PartnerMCPConfig.write(port: 51477, token: "tok", callerID: "c1", to: url)
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        #expect((attrs[.posixPermissions] as? Int) == 0o600)
        let text = String(bytes: try Data(contentsOf: url), encoding: .utf8) ?? ""
        #expect(text.contains("\"X-ADHD-Pane\":\"c1\"") || text.contains("\"X-ADHD-Pane\" : \"c1\""))
        #expect(text.contains("http://127.0.0.1:51477/mcp"))
    }
    @Test func mcpConfigOverwritesLooseFileAndSecuresDirectory() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o755])
        let url = dir.appendingPathComponent("mcp.json")
        try Data("old".utf8).write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
        try PartnerMCPConfig.write(port: 1, token: "new", callerID: "c1", to: url)
        let file = try FileManager.default.attributesOfItem(atPath: url.path)
        let folder = try FileManager.default.attributesOfItem(atPath: dir.path)
        #expect((file[.posixPermissions] as? Int) == 0o600)
        #expect((folder[.posixPermissions] as? Int) == 0o700)
        #expect(String(bytes: try Data(contentsOf: url), encoding: .utf8)?.contains("new") == true)
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.path) == ["mcp.json"])
    }
    @Test func argumentsAreExactlyOrdered() {
        let id = UUID()
        let config = PartnerProcessConfiguration(
            executable: "/x/claude", sessionID: id, resume: true, model: "opus", permissionMode: "dontAsk",
            allowedTools: ["a", "b"], mcpConfigPath: "/m.json", systemPromptPath: "/p.md", workingDirectory: "/w")
        #expect(config.arguments == ["-p", "--verbose", "--input-format", "stream-json", "--output-format",
            "stream-json", "--replay-user-messages", "--resume", id.uuidString.lowercased(), "--permission-mode",
            "dontAsk", "--mcp-config", "/m.json", "--strict-mcp-config", "--append-system-prompt-file", "/p.md",
            "--model", "opus", "--allowedTools", "a", "b"])
    }
    private func sampleConfig(resume: Bool = false, model: String = "", permissionMode: String = "dontAsk",
                              allowedTools: [String] = [], sessionID: UUID = UUID()) -> PartnerProcessConfiguration {
        PartnerProcessConfiguration(
            executable: "/exe-sentinel", sessionID: sessionID, resume: resume, model: model,
            permissionMode: permissionMode, allowedTools: allowedTools, mcpConfigPath: "/mcp-sentinel",
            systemPromptPath: "/prompt-sentinel", workingDirectory: "/work-sentinel")
    }
    @Test("V5: empty allowedTools omits the flag, model is present") func v5EmptyToolsNoAllowedToolsFlag() {
        let args = sampleConfig(model: "opus", allowedTools: []).arguments
        #expect(args.contains("--model") && args.contains("opus"))
        #expect(!args.contains("--allowedTools"))
    }
    @Test("V6: empty permissionMode yields an empty element after the flag") func v6EmptyPermissionMode() {
        let args = sampleConfig(permissionMode: "").arguments
        let index = args.firstIndex(of: "--permission-mode")
        #expect(index != nil)
        if let index { #expect(args[index + 1] == "") }
    }
    @Test("V7: workingDirectory and executable are not arguments") func v7WorkingDirectoryNotAnArgument() {
        let args = sampleConfig().arguments
        #expect(!args.contains("/work-sentinel") && !args.contains("/exe-sentinel"))
        #expect(args.filter { $0 == "/mcp-sentinel" }.count == 1)
        #expect(args.filter { $0 == "/prompt-sentinel" }.count == 1)
    }
    @Test("V8: --verbose immediately follows -p") func v8VerboseFollowsDashP() {
        let args = sampleConfig().arguments
        #expect(args.first == "-p")
        #expect(args[1] == "--verbose")
    }
    @Test("V9: exactly one session flag, followed by the lowercase id") func v9SessionFlagExclusive() {
        let id = UUID()
        for (resume, flag, other) in [(false, "--session-id", "--resume"), (true, "--resume", "--session-id")] {
            let args = sampleConfig(resume: resume, sessionID: id).arguments
            #expect(args.filter { $0 == flag }.count == 1)
            #expect(!args.contains(other))
            if let index = args.firstIndex(of: flag) { #expect(args[index + 1] == id.uuidString.lowercased()) }
        }
    }
    @Test func pathsDeriveFromHomeAndToken() {
        let paths = PartnerPaths(home: URL(fileURLWithPath: "/h"), token: "tok")
        #expect(paths.mcpConfig.path == "/h/.tok/partner/mcp.json")
        #expect(paths.skillFile(jobID: "x").path == "/h/.claude/skills/adkitchen-partner-x/SKILL.md")
    }
}
