import XCTest
import ObjectiveC
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors of work-tracking-xpc-protocol. Vectors 001, 005, 007, 008 and 009 are covered by
/// `WorkTrackingXPCClientTests`; the rest are here.
final class WorkTrackingXPCProtocolConformanceTests: XCTestCase {

    /// A stub daemon that holds its status reply until `fire` is called.
    private final class LateReplyStub: NSObject, WorkTrackingXPCProtocol, @unchecked Sendable {
        private var pending: ((Data) -> Void)?
        func workTrackingSetPreferences(_ body: Data, reply: @escaping (Data) -> Void) {}
        func workTrackingStatus(reply: @escaping (Data) -> Void) { pending = reply }
        func workTrackingRecheckPermissions(reply: @escaping (Data) -> Void) {}
        func workTrackingSpans(since: String?, limit: Int, reply: @escaping ([Data]) -> Void) {}
        func fire(_ data: Data) { pending?(data) }
    }

    private func decodeStatus(_ literal: String) throws -> WorkTrackingStatus {
        try WorkTrackingXPCClient<NeverTransport>.makeReplyDecoder()
            .decode(WorkTrackingStatus.self, from: Data(literal.utf8))
    }

    private struct NeverTransport: WorkTrackingXPCTransport {
        func callData(
            timeout: TimeInterval??, retries: Int,
            _ invoke: @escaping @Sendable (Proxy, @escaping @Sendable (Data) -> Void) -> Void
        ) async throws -> Data { Data() }

        func callDecodingArray<T: Decodable>(
            _ type: T.Type, timeout: TimeInterval??, retries: Int,
            _ invoke: @escaping @Sendable (Proxy, @escaping @Sendable ([Data]) -> Void) -> Void
        ) async throws -> [T] { [] }
    }

    func testV002_setPreferencesReplyShapeDecodesToOnStatus() throws {
        let status = try decodeStatus(#"{"enabled":true,"accessibility":"granted","write_failures":0}"#)
        XCTAssertEqual(status.enabled, true)
        XCTAssertEqual(status.accessibility, .granted)
        XCTAssertEqual(status.writeFailures, 0)
    }

    func testV003_setPreferencesEmptyReplyWhenNotApplied() throws {
        throw XCTSkip("Daemon-side behavior: no daemon implementation of the protocol exists in this repo")
    }

    func testV004_statusEmptyReplyWhenDaemonCannotBuildIt() throws {
        throw XCTSkip("Daemon-side behavior: no daemon implementation of the protocol exists in this repo")
    }

    func testV006_recheckReplyShapeDecodesToDeniedStatus() throws {
        let status = try decodeStatus(#"{"enabled":true,"accessibility":"denied","write_failures":0}"#)
        XCTAssertEqual(status.enabled, true)
        XCTAssertEqual(status.accessibility, .denied)
    }

    func testV010_spansSinceNilIncludesAnyStart() throws {
        throw XCTSkip("Daemon-side behavior: no daemon implementation of the protocol exists in this repo")
    }

    func testV011_readFailedRowBytesAndKey() {
        XCTAssertEqual(WorkTrackingWire.readFailedKey, "work_tracking_read_failed")
        XCTAssertEqual(String(bytes: WorkTrackingWire.readFailedRow, encoding: .utf8),
                       #"{"work_tracking_read_failed":true}"#)
    }

    func testV012_selectorsAreStable() {
        XCTAssertEqual(NSStringFromSelector(
            #selector(WorkTrackingXPCProtocol.workTrackingSetPreferences(_:reply:))),
            "workTrackingSetPreferences:reply:")
        XCTAssertEqual(NSStringFromSelector(
            #selector(WorkTrackingXPCProtocol.workTrackingStatus(reply:))),
            "workTrackingStatusWithReply:")
        XCTAssertEqual(NSStringFromSelector(
            #selector(WorkTrackingXPCProtocol.workTrackingRecheckPermissions(reply:))),
            "workTrackingRecheckPermissionsWithReply:")
        XCTAssertEqual(NSStringFromSelector(
            #selector(WorkTrackingXPCProtocol.workTrackingSpans(since:limit:reply:))),
            "workTrackingSpansSince:limit:reply:")
        var count: UInt32 = 0
        let proto: Protocol = WorkTrackingXPCProtocol.self
        let methods = protocol_copyMethodDescriptionList(proto, true, true, &count)
        free(methods)
        XCTAssertEqual(count, 4)
    }

    func testV013_xpcInterfaceBuilds() {
        let proto: Protocol = WorkTrackingXPCProtocol.self
        let interface = NSXPCInterface(with: proto)
        XCTAssertTrue(protocol_isEqual(interface.protocol, proto))
    }

    func testV014_replyDeliveredAfterSelectorReturned() async {
        let stub = LateReplyStub()
        let expected = Data(#"{"enabled":false}"#.utf8)
        let received: Data = await withCheckedContinuation { continuation in
            stub.workTrackingStatus { continuation.resume(returning: $0) }
            stub.fire(expected)
        }
        XCTAssertEqual(received, expected)
    }

    func testV015_noErrorChannelInSelectorTypes() throws {
        throw XCTSkip("A static property of the declarations; no runtime check can see a missing Error")
    }
}
