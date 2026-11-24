import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("PartnerMCPConfig conformance") struct PartnerMCPConfigConformanceTests {
    private let files = FileManager.default

    private func makeTempDirectory() throws -> URL {
        let url = files.temporaryDirectory.appendingPathComponent("mcpcfg-" + UUID().uuidString)
        try files.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func mode(_ url: URL) throws -> Int? {
        try files.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int
    }

    private func text(_ data: Data) -> String { String(bytes: data, encoding: .utf8) ?? "" }

    private func decoded(_ data: Data) throws -> (url: String?, headers: [String: String]) {
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let servers = try #require(root["mcpServers"] as? [String: Any])
        let server = try #require(servers["adkitchen"] as? [String: Any])
        return (server["url"] as? String, server["headers"] as? [String: String] ?? [:])
    }

    @Test("V1: write creates a 0600 file with headers and url")
    func testV1_writeHeadersAndMode() throws {
        let root = try makeTempDirectory()
        defer { try? files.removeItem(at: root) }
        let target = root.appendingPathComponent("mcp.json")
        try PartnerMCPConfig.write(port: 51477, token: "tok", callerID: "c1", to: target)
        #expect(try mode(target) == 0o600)
        let body = text(try Data(contentsOf: target))
        #expect(body.contains("\"X-ADKitchen-Pane\":\"c1\""))
        #expect(body.contains("http://127.0.0.1:51477/mcp"))
    }

    @Test("V2: write overwrites a loose file and secures the directory")
    func testV2_overwriteTightensDirectory() throws {
        let root = try makeTempDirectory()
        defer { try? files.removeItem(at: root) }
        let folder = root.appendingPathComponent("loose")
        try files.createDirectory(at: folder, withIntermediateDirectories: true,
                                  attributes: [.posixPermissions: 0o755])
        let target = folder.appendingPathComponent("mcp.json")
        try Data("old".utf8).write(to: target)
        try files.setAttributes([.posixPermissions: 0o644], ofItemAtPath: target.path)
        try PartnerMCPConfig.write(port: 1, token: "new", callerID: "c1", to: target)
        #expect(try mode(target) == 0o600)
        #expect(try mode(folder) == 0o700)
        #expect(text(try Data(contentsOf: target)).contains("new"))
        #expect(try files.contentsOfDirectory(atPath: folder.path) == ["mcp.json"])
    }

    @Test("V3: json has the exact compact sorted shape")
    func testV3_jsonShape() {
        let body = text(PartnerMCPConfig.json(port: 8080, token: "t", callerID: "c"))
        let expected = "{\"mcpServers\":{\"adkitchen\":{\"headers\":{\"Authorization\":\"Bearer t\","
            + "\"X-ADKitchen-Pane\":\"c\"},\"type\":\"http\",\"url\":\"http://127.0.0.1:8080/mcp\"}}}"
        #expect(body == expected)
    }

    @Test("V4: server name and caller header constants")
    func testV4_constants() {
        #expect(PartnerMCPConfig.serverName == "adkitchen")
        #expect(PartnerMCPConfig.callerHeader == "X-ADKitchen-Pane")
    }

    @Test("V5: json is byte-identical for equal inputs")
    func testV5_jsonIsPure() {
        let first = PartnerMCPConfig.json(port: 7, token: "t", callerID: "c")
        let second = PartnerMCPConfig.json(port: 7, token: "t", callerID: "c")
        #expect(first == second)
    }

    @Test("V6: empty token and caller id and port 0 are written as given")
    func testV6_noValidation() throws {
        let parsed = try decoded(PartnerMCPConfig.json(port: 0, token: "", callerID: ""))
        #expect(parsed.url == "http://127.0.0.1:0/mcp")
        #expect(parsed.headers["Authorization"] == "Bearer ")
        #expect(parsed.headers["X-ADKitchen-Pane"] == "")
    }

    @Test("V7: a quote in the token is JSON-escaped")
    func testV7_tokenIsEscaped() throws {
        let data = PartnerMCPConfig.json(port: 1, token: "a\"b", callerID: "c")
        #expect(text(data).contains("Bearer a\\\"b"))
        #expect(try decoded(data).headers["Authorization"] == "Bearer a\"b")
    }

    @Test("V8: the highest port is written in the url")
    func testV8_maxPort() throws {
        let parsed = try decoded(PartnerMCPConfig.json(port: 65535, token: "t", callerID: "c"))
        #expect(parsed.url == "http://127.0.0.1:65535/mcp")
    }

    @Test("V9: missing parent directories are created, the parent is 0700")
    func testV9_createsNestedParents() throws {
        let root = try makeTempDirectory()
        defer { try? files.removeItem(at: root) }
        let parent = root.appendingPathComponent("one").appendingPathComponent("two")
        let target = parent.appendingPathComponent("mcp.json")
        try PartnerMCPConfig.write(port: 1, token: "t", callerID: "c", to: target)
        #expect(files.fileExists(atPath: root.appendingPathComponent("one").path))
        #expect(try mode(parent) == 0o700)
    }

    @Test("V10: the written bytes equal json")
    func testV10_writeContentEqualsJSON() throws {
        let root = try makeTempDirectory()
        defer { try? files.removeItem(at: root) }
        let target = root.appendingPathComponent("mcp.json")
        try PartnerMCPConfig.write(port: 9, token: "t", callerID: "c", to: target)
        #expect(try Data(contentsOf: target) == PartnerMCPConfig.json(port: 9, token: "t", callerID: "c"))
    }

    @Test("V11: a setAttributes failure propagates", .disabled("""
        Needs a parent directory owned by another user; a unit test cannot create one, and running as \
        root would instead change a real system directory's mode.
        """))
    func testV11_setAttributesErrorPropagates() {}

    @Test("V12: a failed rename throws fileWriteUnknown and leaves no temp file")
    func testV12_renameFailureCleansUp() throws {
        let root = try makeTempDirectory()
        defer { try? files.removeItem(at: root) }
        let target = root.appendingPathComponent("mcp.json")
        try files.createDirectory(at: target, withIntermediateDirectories: true)
        try Data("keep".utf8).write(to: target.appendingPathComponent("inner.txt"))
        var thrown: CocoaError?
        do {
            try PartnerMCPConfig.write(port: 1, token: "t", callerID: "c", to: target)
        } catch let error as CocoaError {
            thrown = error
        }
        #expect(thrown?.code == .fileWriteUnknown)
        let leftovers = try files.contentsOfDirectory(atPath: root.path).filter { $0.hasSuffix(".tmp") }
        #expect(leftovers.isEmpty)
    }

    @Test("V13: writing twice replaces the first file")
    func testV13_writeTwice() throws {
        let root = try makeTempDirectory()
        defer { try? files.removeItem(at: root) }
        let target = root.appendingPathComponent("mcp.json")
        try PartnerMCPConfig.write(port: 1, token: "first", callerID: "c", to: target)
        try PartnerMCPConfig.write(port: 2, token: "second", callerID: "c", to: target)
        #expect(try Data(contentsOf: target) == PartnerMCPConfig.json(port: 2, token: "second", callerID: "c"))
        #expect(try files.contentsOfDirectory(atPath: root.path) == ["mcp.json"])
    }

    @Test("V14: rewrite swaps the file, an open handle still reads the old content")
    func testV14_atomicRename() throws {
        let root = try makeTempDirectory()
        defer { try? files.removeItem(at: root) }
        let target = root.appendingPathComponent("mcp.json")
        try PartnerMCPConfig.write(port: 1, token: "old", callerID: "c", to: target)
        let oldNumber = try files.attributesOfItem(atPath: target.path)[.systemFileNumber] as? Int
        let handle = try FileHandle(forReadingFrom: target)
        defer { try? handle.close() }
        try PartnerMCPConfig.write(port: 2, token: "new", callerID: "c", to: target)
        let newNumber = try files.attributesOfItem(atPath: target.path)[.systemFileNumber] as? Int
        #expect(oldNumber != nil && oldNumber != newNumber)
        #expect(try Data(contentsOf: target) == PartnerMCPConfig.json(port: 2, token: "new", callerID: "c"))
        let oldBytes = try handle.readToEnd() ?? Data()
        #expect(oldBytes == PartnerMCPConfig.json(port: 1, token: "old", callerID: "c"))
    }
}
