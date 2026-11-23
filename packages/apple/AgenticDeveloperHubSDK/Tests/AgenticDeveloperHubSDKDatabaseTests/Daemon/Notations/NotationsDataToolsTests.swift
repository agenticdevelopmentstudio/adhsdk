import XCTest
import Foundation
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The notations data tools over a real `NotationsStore` and a real git
/// repository on disk: `notations_write` resolves the branch's fork point with
/// git, so a fake would test nothing that matters.
final class NotationsDataToolsTests: XCTestCase {

    private var tempRoot: URL!
    private var repoDirectory: URL!
    private var store: NotationsStore!
    private var tools: NotationsDataTools!
    private let projectID = UUID()

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("notations-tools-test-\(UUID().uuidString)")
        repoDirectory = tempRoot.appendingPathComponent("whippet", isDirectory: true)
        try FileManager.default.createDirectory(at: repoDirectory, withIntermediateDirectories: true)
        try initRepo(repoDirectory)

        store = try NotationsStore(path: tempRoot.appendingPathComponent("Notations.db").path)
        let project = GitRepo(id: projectID, path: repoDirectory.path, name: "whippet")
        tools = NotationsDataTools(
            store: store,
            git: NotationsGit(client: GitClient(configuration: .default)),
            projectAtPath: { path in NotationsPlace.project(containing: path, in: [project]) })
    }

    override func tearDownWithError() throws {
        tools = nil
        store = nil
        try? FileManager.default.removeItem(at: tempRoot)
        try super.tearDownWithError()
    }

    // MARK: - Definitions

    func testTheDefinitionsNameEveryToolTheSourceAnswers() async {
        let names = await tools.toolDefinitions().map(\.name)
        XCTAssertEqual(Set(names), NotationsDataTools.toolNames)
        XCTAssertEqual(names.count, NotationsDataTools.toolNames.count)
    }

    func testAnUnknownToolIsAnError() async {
        let result = await call("notations_frobnicate", [:])
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.content, "unknown tool notations_frobnicate")
    }

    // MARK: - Argument validation

    func testListRefusesAnUnknownState() async {
        let result = await call("notations_list", ["state": "deleted"])
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.content, "state must be active or archived")
    }

    func testIDToolsRefuseAnArgumentThatIsNotANotationID() async {
        for name in ["notations_get", "notations_archive", "notations_delete"] {
            let missing = await call(name, [:])
            XCTAssertTrue(missing.isError, name)
            XCTAssertEqual(missing.content, "id must be a notation id", name)

            let malformed = await call(name, ["id": "not-a-uuid"])
            XCTAssertTrue(malformed.isError, name)
            XCTAssertEqual(malformed.content, "id must be a notation id", name)
        }
    }

    func testWriteRequiresAProjectPathABranchAndContent() async {
        let arguments: [[String: Any]] = [
            ["branch": "feature", "content": "x"],
            ["project_path": repoDirectory.path, "content": "x"],
            ["project_path": repoDirectory.path, "branch": "feature"],
            ["project_path": "  ", "branch": "feature", "content": "x"],
            ["project_path": repoDirectory.path, "branch": "  ", "content": "x"]
        ]
        for args in arguments {
            let result = await call("notations_write", args)
            XCTAssertTrue(result.isError, "\(args)")
            XCTAssertEqual(result.content, "project_path, branch and content are required", "\(args)")
        }
    }

    func testWriteOutsideEveryProjectIsRefused() async {
        let elsewhere = tempRoot.appendingPathComponent("elsewhere").path
        let result = await call("notations_write", [
            "project_path": elsewhere, "branch": "feature", "content": "x"
        ])
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.content, "no project at \(elsewhere)")
    }

    func testWriteToABranchThatDoesNotExistIsRefused() async {
        let result = await call("notations_write", [
            "project_path": repoDirectory.path, "branch": "no-such-branch", "content": "x"
        ])
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.content, "there is no local branch no-such-branch in whippet")
    }

    // MARK: - Writing

    /// One active notation per branch: a second write to the same branch
    /// replaces the content of the notation the first one made.
    func testTwoWritesToOneBranchLeaveOneActiveNotation() async throws {
        let first = await call("notations_write", [
            "project_path": repoDirectory.path, "branch": "feature", "content": "one"
        ])
        XCTAssertFalse(first.isError, first.content)
        let second = await call("notations_write", [
            "project_path": repoDirectory.path, "branch": "feature", "content": "two"
        ])
        XCTAssertFalse(second.isError, second.content)

        XCTAssertEqual(try field("id", of: second), try field("id", of: first))
        let active = try store.activeNotations(projectID: projectID, branch: "feature")
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.content, "two")
        XCTAssertEqual(active.first?.projectPath, repoDirectory.path)
    }

    /// A worktree or subdirectory of the project resolves to the project.
    func testWriteFromInsideTheProjectFindsTheProject() async throws {
        let inside = repoDirectory.appendingPathComponent("Sources", isDirectory: true)
        try FileManager.default.createDirectory(at: inside, withIntermediateDirectories: true)
        let result = await call("notations_write", [
            "project_path": inside.path, "branch": "feature", "content": "deep"
        ])
        XCTAssertFalse(result.isError, result.content)
        let active = try store.activeNotations(projectID: projectID, branch: "feature")
        XCTAssertEqual(active.map(\.content), ["deep"])
    }

    // MARK: - Reading

    func testGetReturnsTheNotationWithItsContent() async throws {
        let written = await call("notations_write", [
            "project_path": repoDirectory.path, "branch": "feature", "content": "# Plan"
        ])
        let id = try field("id", of: written)
        let result = await call("notations_get", ["id": id])
        XCTAssertFalse(result.isError, result.content)
        XCTAssertEqual(try field("content", of: result), "# Plan")
    }

    func testGetOfAMissingNotationIsAnError() async {
        let id = UUID()
        let result = await call("notations_get", ["id": id.uuidString])
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.content, "no notation \(id.uuidString)")
    }

    func testListLeavesOutTheContent() async throws {
        _ = await call("notations_write", [
            "project_path": repoDirectory.path, "branch": "feature", "content": "secret"
        ])
        let result = await call("notations_list", ["state": "active"])
        XCTAssertFalse(result.isError, result.content)
        let rows = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(result.content.utf8)) as? [[String: Any]])
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?["branch"] as? String, "feature")
        XCTAssertNil(rows.first?["content"])
    }

    // MARK: - Archiving and deleting

    func testDeletingAnActiveNotationIsRefused() async throws {
        let written = await call("notations_write", [
            "project_path": repoDirectory.path, "branch": "feature", "content": "x"
        ])
        let id = try field("id", of: written)
        let result = await call("notations_delete", ["id": id])
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.content, "notation \(id) is active; archive it first")
        XCTAssertNotNil(try store.notation(id: try XCTUnwrap(UUID(uuidString: id))))
    }

    func testArchiveThenDeleteRemovesTheNotation() async throws {
        let written = await call("notations_write", [
            "project_path": repoDirectory.path, "branch": "feature", "content": "x"
        ])
        let id = try field("id", of: written)

        let archived = await call("notations_archive", ["id": id])
        XCTAssertFalse(archived.isError, archived.content)
        XCTAssertEqual(try field("state", of: archived), "archived")

        let again = await call("notations_archive", ["id": id])
        XCTAssertTrue(again.isError)
        XCTAssertEqual(again.content, "no active notation \(id)")

        let deleted = await call("notations_delete", ["id": id])
        XCTAssertFalse(deleted.isError, deleted.content)
        XCTAssertEqual(deleted.content, "deleted \(id)")
        XCTAssertNil(try store.notation(id: try XCTUnwrap(UUID(uuidString: id))))
    }

    func testDeletingAMissingNotationIsAnError() async {
        let id = UUID()
        let result = await call("notations_delete", ["id": id.uuidString])
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.content, "no notation \(id.uuidString)")
    }

    // MARK: - Helpers

    private func call(_ name: String, _ args: [String: Any]) async -> (content: String, isError: Bool) {
        let data = (try? JSONSerialization.data(withJSONObject: args)) ?? Data("{}".utf8)
        return await tools.callTool(name: name, argumentsJSON: data, caller: "tests")
    }

    /// One string field of a tool's JSON object result.
    private func field(_ key: String, of result: (content: String, isError: Bool)) throws -> String {
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(result.content.utf8)) as? [String: Any], result.content)
        return try XCTUnwrap(object[key] as? String, "\(key) in \(result.content)")
    }

    /// `main` with one commit, and a `feature` branch forked from it.
    private func initRepo(_ directory: URL) throws {
        try git(["init", "-q", "-b", "main"], in: directory)
        try Data("seed\n".utf8).write(to: directory.appendingPathComponent("README.md"))
        try git(["add", "README.md"], in: directory)
        try git(["commit", "-q", "-m", "seed"], in: directory)
        try git(["branch", "feature"], in: directory)
    }

    private func git(_ args: [String], in directory: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", directory.path] + args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        // A fixed identity, so commits succeed without a global gitconfig.
        var environment = ProcessInfo.processInfo.environment
        environment["GIT_AUTHOR_NAME"] = "Test"
        environment["GIT_AUTHOR_EMAIL"] = "test@example.com"
        environment["GIT_COMMITTER_NAME"] = "Test"
        environment["GIT_COMMITTER_EMAIL"] = "test@example.com"
        process.environment = environment
        try process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertEqual(process.terminationStatus, 0, "git \(args.joined(separator: " ")): \(output)")
    }
}
