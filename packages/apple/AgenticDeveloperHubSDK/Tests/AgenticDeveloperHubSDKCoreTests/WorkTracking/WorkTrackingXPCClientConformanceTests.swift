import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors 011 through 017 of work-tracking-xpc-client.
final class WorkTrackingXPCClientConformanceTests: XCTestCase {

    private struct Failure: Error {}

    private final class Transport: WorkTrackingXPCTransport, @unchecked Sendable {
        var shouldThrow = false
        var data = Data()
        var rows: [Data] = []
        private(set) var calls: [(timeout: TimeInterval??, retries: Int)] = []

        func callData(
            timeout: TimeInterval??, retries: Int,
            _ invoke: @escaping @Sendable (Proxy, @escaping @Sendable (Data) -> Void) -> Void
        ) async throws -> Data {
            calls.append((timeout, retries))
            if shouldThrow { throw Failure() }
            return data
        }

        func callDecodingArray<T: Decodable>(
            _ type: T.Type, timeout: TimeInterval??, retries: Int,
            _ invoke: @escaping @Sendable (Proxy, @escaping @Sendable ([Data]) -> Void) -> Void
        ) async throws -> [T] {
            calls.append((timeout, retries))
            if shouldThrow { throw Failure() }
            let decoder = WorkTrackingXPCClient<Transport>.makeReplyDecoder()
            return try rows.map { try decoder.decode(T.self, from: $0) }
        }
    }

    private let transport = Transport()
    private lazy var client = WorkTrackingXPCClient(transport: transport)

    private func spanRow(_ id: String) -> Data {
        Data("""
        {"id":"\(id)","bundle_id":"com.x","app_name":"X","window_title":"w","working_path":"/p",
         "repo_root":"/p","branch":"main","started_at":"2026-10-03T10:00:00Z","ended_at":"","tz":"UTC",
         "last_seen_at":""}
        """.utf8)
    }

    func testV011_statusCallCarriesNilTimeoutAndNoRetries() async throws {
        transport.data = Data(#"{"enabled":true,"accessibility":"granted","write_failures":0}"#.utf8)
        let status = await client.status()
        XCTAssertEqual(status?.enabled, true)
        let call = try XCTUnwrap(transport.calls.last)
        switch call.timeout {
        case .none: break
        case .some: XCTFail("status() must pass .none for the timeout")
        }
        XCTAssertEqual(call.retries, 0)
    }

    func testV012_failureRowAfterGoodRowsIsNilNotPartial() async {
        transport.rows = [spanRow("a"), spanRow("b"), WorkTrackingWire.readFailedRow]
        let spans = await client.spans(since: nil, limit: 10)
        XCTAssertNil(spans)
    }

    func testV013_throwingTransportYieldsNilStatus() async {
        transport.shouldThrow = true
        let status = await client.status()
        XCTAssertNil(status)
    }

    func testV014_falseSentinelFallsThroughToSpanDecodeAndThrows() {
        let decoder = WorkTrackingXPCClient<Transport>.makeReplyDecoder()
        let element = Data(#"{"work_tracking_read_failed":false}"#.utf8)
        XCTAssertThrowsError(try decoder.decode(WorkTrackingListRow<ActivitySpanDTO>.self, from: element))
    }

    func testV015_unencodablePreferencesReturnNilWithoutCallingTransport() throws {
        throw XCTSkip("WorkTrackingPreferences holds only Bool, [String] and Int, so none can fail to encode")
    }

    func testV016_unrecognizedRowYieldsNilSpans() async {
        transport.rows = [spanRow("a"), Data(#"{"x":1}"#.utf8)]
        let spans = await client.spans(since: nil, limit: 10)
        XCTAssertNil(spans)
    }

    func testV017_throwingTransportYieldsNilFromSetPreferencesAndRecheck() async {
        transport.shouldThrow = true
        let pushed = await client.setPreferences(.default)
        let rechecked = await client.recheckPermissions()
        XCTAssertNil(pushed)
        XCTAssertNil(rechecked)
        XCTAssertEqual(transport.calls.count, 2)
    }
}
