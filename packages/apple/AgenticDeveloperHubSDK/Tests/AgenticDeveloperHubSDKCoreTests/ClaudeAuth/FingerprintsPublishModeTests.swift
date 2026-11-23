@testable import AgenticDeveloperHubSDKCore
import XCTest

/// `publish-permissions-failure`: the fingerprints file is published 0600 or
/// not at all. A failure to set the mode throws and leaves the previous file
/// and no temporary file behind.
final class FingerprintsPublishModeTests: XCTestCase {

    private var tmpDir: URL!
    private var path: String!

    private struct ModeRefused: Error {}

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fingerprints-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        path = tmpDir.appendingPathComponent("account-fingerprints.json").path
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func mode(_ path: String) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        return (attributes[.posixPermissions] as? NSNumber)?.intValue ?? -1
    }

    func testPublishedFileIsOwnerOnly() throws {
        try AccountFingerprints.publish(["digest-a": "a@x.com"], atPath: path)

        XCTAssertEqual(try mode(path), 0o600)
    }

    /// The temporary file is already 0600, and already holds the contents,
    /// before the mode is set: there is no window in which it is readable by
    /// others.
    func testTheTemporaryFileIsOwnerOnlyBeforeTheModeIsSet() throws {
        var seen: [(mode: Int, size: Int)] = []
        try AccountFingerprints.publish(
            ["digest-a": "a@x.com"], atPath: path, now: Date(),
            setOwnerOnly: { temporary in
                let size = (try FileManager.default.attributesOfItem(atPath: temporary)[.size] as? NSNumber)?
                    .intValue ?? -1
                seen.append((try self.mode(temporary), size))
            })

        XCTAssertEqual(seen.count, 1)
        XCTAssertEqual(seen.first?.mode, 0o600)
        XCTAssertGreaterThan(seen.first?.size ?? 0, 0)
    }

    /// The owner-only writer refuses a path that already exists rather than
    /// writing through it.
    func testTheOwnerOnlyWriterRefusesAnExistingFile() throws {
        let existing = tmpDir.appendingPathComponent("existing").path
        FileManager.default.createFile(atPath: existing, contents: Data("x".utf8))

        XCTAssertThrowsError(try AccountFingerprints.writeOwnerOnly(Data("y".utf8), toNewFile: existing))
        XCTAssertEqual(FileManager.default.contents(atPath: existing), Data("x".utf8))
    }

    func testAFailureToSetTheModeThrowsAndKeepsThePreviousFile() throws {
        try AccountFingerprints.publish(["digest-a": "a@x.com"], atPath: path)
        let before = try Data(contentsOf: URL(fileURLWithPath: path))

        XCTAssertThrowsError(try AccountFingerprints.publish(
            ["digest-b": "b@x.com"], atPath: path, now: Date(),
            setOwnerOnly: { _ in throw ModeRefused() })) { error in
            XCTAssertTrue(error is ModeRefused)
        }

        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: path)), before, "the previous file is untouched")
        XCTAssertEqual(try mode(path), 0o600)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: tmpDir.path)
        XCTAssertEqual(leftovers, ["account-fingerprints.json"], "no temporary file is left behind")
    }

    func testAFailureToSetTheModeOnAFirstPublishLeavesNoFile() throws {
        XCTAssertThrowsError(try AccountFingerprints.publish(
            ["digest-a": "a@x.com"], atPath: path, now: Date(),
            setOwnerOnly: { _ in throw ModeRefused() }))

        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: tmpDir.path), [])
    }
}
