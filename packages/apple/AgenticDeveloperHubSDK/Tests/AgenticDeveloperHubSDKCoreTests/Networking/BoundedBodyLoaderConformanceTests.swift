import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// Serves the canned transfers the bounded-body conformance vectors describe,
/// chosen by URL path.
final class BoundedBodyStubProtocol: URLProtocol {

    private static let lock = NSLock()
    nonisolated(unsafe) private static var hangStarted = false
    nonisolated(unsafe) private static var hangStopped = false

    static func resetHang() {
        lock.withLock {
            hangStarted = false
            hangStopped = false
        }
    }

    static var didStartHanging: Bool { lock.withLock { hangStarted } }
    static var didStopHanging: Bool { lock.withLock { hangStopped } }

    static func payload(count: Int) -> Data {
        Data((0..<count).map { UInt8($0 % 251) })
    }

    override static func canInit(with request: URLRequest) -> Bool { true }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        switch url.path {
        case "/full": respond(url: url, status: 200, header: 512 * 1024, body: Self.payload(count: 512 * 1024))
        case "/exact": respond(url: url, status: 200, header: nil, body: Self.payload(count: 4096))
        case "/over": respond(url: url, status: 200, header: nil, body: Self.payload(count: 4097))
        case "/liar": respond(url: url, status: 200, header: 1 << 30, body: Self.payload(count: 10))
        case "/understated": respond(url: url, status: 200, header: 1, body: Self.payload(count: 4096))
        case "/unavailable": respond(url: url, status: 503, header: nil, body: Self.payload(count: 64 * 1024))
        case "/drop":
            send(url: url, status: 200, header: nil)
            client?.urlProtocol(self, didLoad: Self.payload(count: 100))
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
        case "/hang":
            send(url: url, status: 200, header: nil)
            Self.lock.withLock { Self.hangStarted = true }
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
        }
    }

    override func stopLoading() {
        if request.url?.path == "/hang" {
            Self.lock.withLock { Self.hangStopped = true }
        }
    }

    private func send(url: URL, status: Int, header: Int?) {
        let fields = header.map { ["Content-Length": String($0)] }
        let response = HTTPURLResponse(
            url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: fields)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }

    private func respond(url: URL, status: Int, header: Int?, body: Data) {
        send(url: url, status: status, header: header)
        var offset = 0
        let chunkSize = 1024
        while offset < body.count {
            let end = min(offset + chunkSize, body.count)
            client?.urlProtocol(self, didLoad: body.subdata(in: offset..<end))
            offset = end
        }
        client?.urlProtocolDidFinishLoading(self)
    }
}

@Suite("BoundedBodyLoader conformance", .serialized)
struct BoundedBodyLoaderConformanceTests {

    private let base = URL(string: "https://bounded.test")!

    private func makeLoader() -> BoundedBodyLoader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BoundedBodyStubProtocol.self]
        return BoundedBodyLoader(configuration: configuration)
    }

    private func url(_ path: String) -> URL { base.appendingPathComponent(path) }

    @Test("networking-001: a body under the limit is returned whole with its response")
    func testV1_fullBodyReturned() async throws {
        let result = try await makeLoader().body(at: url("full"), limit: 1_048_576)
        #expect(result.data == BoundedBodyStubProtocol.payload(count: 512 * 1024))
        #expect((result.response as? HTTPURLResponse)?.statusCode == 200)
    }

    @Test("networking-002: a body exactly at the limit is accepted")
    func testV2_bodyAtLimitAccepted() async throws {
        let result = try await makeLoader().body(at: url("exact"), limit: 4096)
        #expect(result.data.count == 4096)
    }

    @Test("networking-003: a body one byte past the limit throws too-large")
    func testV3_bodyOverLimitThrows() async {
        await #expect(throws: BoundedBodyLoader.Failure.self) {
            _ = try await makeLoader().body(at: url("over"), limit: 4096)
        }
    }

    @Test("networking-004: a declared length past the limit is refused")
    func testV4_declaredLengthRefused() async {
        await #expect(throws: BoundedBodyLoader.Failure.self) {
            _ = try await makeLoader().body(at: url("liar"), limit: 1000)
        }
    }

    @Test("networking-005: an understated declared length does not get a body past the limit")
    func testV5_understatedLengthNotBelieved() async {
        await #expect(throws: BoundedBodyLoader.Failure.self) {
            _ = try await makeLoader().body(at: url("understated"), limit: 1000)
        }
    }

    @Test("networking-006: too-large carries the response, whatever its status")
    func testV6_tooLargeCarriesResponse() async {
        do {
            _ = try await makeLoader().body(at: url("unavailable"), limit: 1024)
            Issue.record("an oversize body was accepted")
        } catch BoundedBodyLoader.Failure.tooLarge(let response) {
            #expect((response as? HTTPURLResponse)?.statusCode == 503)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("networking-007: a transport error mid-transfer is rethrown unchanged")
    func testV7_transportErrorPropagates() async {
        do {
            _ = try await makeLoader().body(at: url("drop"), limit: 4096)
            Issue.record("a dropped connection returned a body")
        } catch let error as URLError {
            #expect(error.code == .networkConnectionLost)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("networking-008: cancelling the caller cancels the transfer and throws")
    func testV8_cancellationCancelsTransfer() async throws {
        BoundedBodyStubProtocol.resetHang()
        let loader = makeLoader()
        let hangURL = url("hang")
        let task = Task { try await loader.body(at: hangURL, limit: 4096) }
        for _ in 0..<500 where !BoundedBodyStubProtocol.didStartHanging {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(BoundedBodyStubProtocol.didStartHanging)
        task.cancel()
        let outcome = await task.result
        #expect(throws: (any Error).self) { try outcome.get() }
        for _ in 0..<500 where !BoundedBodyStubProtocol.didStopHanging {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(BoundedBodyStubProtocol.didStopHanging)
    }

    @Test(
        "networking-009: a stale callback is a no-op",
        .disabled("the shared state and the session delegate are file-private, so a test cannot inject a callback")
    )
    func testV9_staleCallbackIsNoOp() {}
}
