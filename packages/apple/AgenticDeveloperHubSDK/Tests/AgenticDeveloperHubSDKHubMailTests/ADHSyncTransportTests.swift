import XCTest
import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKHubSync

/// Vectors hub-sync-transport-001 to 009.
final class ADHSyncTransportTests: XCTestCase {

    private actor Recorder {
        var pulls: [(String?, Int)] = []
        var pushes: [Data] = []
        func pulled(_ cursor: String?, _ limit: Int) { pulls.append((cursor, limit)) }
        func pushed(_ body: Data) { pushes.append(body) }
    }

    private static let pullBody = Data("""
        {"manifest":[{"resource":"integration.integration_email_messages","schemaVersion":1}],
         "changes":[{"resource":"integration.integration_email_messages","id":"m1","op":"upsert",
                     "syncVersion":"4","data":{"subject":"Hi"}}],
         "cursor":"c10","hasMore":false}
        """.utf8)

    private func failing(_ error: any Error) -> ADHSyncTransport {
        ADHSyncTransport(pull: { _, _ in throw error }, push: { _ in throw error })
    }

    private func pullError(_ transport: ADHSyncTransport) async -> (any Error)? {
        do {
            _ = try await transport.pull(cursor: nil, limit: 1)
            return nil
        } catch {
            return error
        }
    }

    // 001
    func testPullPassesTheCursorRawValueAndDecodesTheBody() async throws {
        let recorder = Recorder()
        let transport = ADHSyncTransport(
            pull: { cursor, limit in await recorder.pulled(cursor, limit); return Self.pullBody },
            push: { _ in Data() }
        )
        let response = try await transport.pull(cursor: SyncCursor(rawValue: "c9"), limit: 50)
        let pulls = await recorder.pulls
        XCTAssertEqual(pulls.count, 1)
        XCTAssertEqual(pulls.first?.0, "c9")
        XCTAssertEqual(pulls.first?.1, 50)
        XCTAssertEqual(response.cursor, "c10")
        XCTAssertEqual(response.changes, [SyncChange(
            resource: "integration.integration_email_messages", id: "m1", op: .upsert,
            syncVersion: "4", data: ["subject": .string("Hi")]
        )])
    }

    // 002
    func testPullWithoutACursorPassesNil() async throws {
        let recorder = Recorder()
        let transport = ADHSyncTransport(
            pull: { cursor, limit in await recorder.pulled(cursor, limit); return Self.pullBody },
            push: { _ in Data() }
        )
        _ = try await transport.pull(cursor: nil, limit: 10)
        let pulls = await recorder.pulls
        XCTAssertNil(pulls.first?.0)
        XCTAssertEqual(pulls.first?.1, 10)
    }

    // 003
    func testPushEncodesTheRequestAndDecodesTheResponse() async throws {
        let recorder = Recorder()
        let reply = SyncPushResponse(
            results: [SyncPushResult(opId: "o1", status: .applied, newVersion: "5")], watermark: "w1"
        )
        let replyBody = try JSONEncoder().encode(reply)
        let transport = ADHSyncTransport(
            pull: { _, _ in Data() },
            push: { body in await recorder.pushed(body); return replyBody }
        )
        let request = SyncPushRequest(deviceId: "d1", ops: [
            SyncPushOp(opId: "o1", resource: "personal.notes", rowId: "r1", type: .upsert,
                       baseVersion: "4", data: ["title": .string("t")])
        ])
        let response = try await transport.push(request)
        XCTAssertEqual(response, reply)
        let sent = await recorder.pushes
        XCTAssertEqual(sent.count, 1)
        XCTAssertEqual(try JSONDecoder().decode(SyncPushRequest.self, from: sent[0]), request)
    }

    // 004
    func testUnauthorizedMapsToUnauthorized() async {
        let error = await pullError(failing(ADHSyncAPI.Failure.unauthorized))
        XCTAssertEqual(error as? SyncTransportError, .unauthorized)
    }

    // 005
    func testResyncRequiredMapsToResyncRequired() async {
        let error = await pullError(failing(ADHSyncAPI.Failure.resyncRequired))
        XCTAssertEqual(error as? SyncTransportError, .resyncRequired)
    }

    // 006
    func testHTTPStatusMapsToInvalidResponse() async {
        let error = await pullError(failing(ADHSyncAPI.Failure.http(503)))
        XCTAssertEqual(error as? SyncTransportError, .invalidResponse(statusCode: 503))
    }

    // 007
    func testTransportFailureKeepsItsMessage() async {
        let error = await pullError(failing(ADHSyncAPI.Failure.transport("offline")))
        XCTAssertEqual(error as? SyncTransportError, .transport("offline"))
    }

    // 008
    func testABodyThatIsNotJSONBecomesATransportError() async {
        let transport = ADHSyncTransport(pull: { _, _ in Data("not json".utf8) }, push: { _ in Data() })
        let error = await pullError(transport)
        guard case .transport = error as? SyncTransportError else {
            return XCTFail("expected .transport, got \(String(describing: error))")
        }
    }

    // 009
    func testCancellationPassesThroughUnchanged() async {
        let error = await pullError(failing(CancellationError()))
        XCTAssertTrue(error is CancellationError)
    }
}
