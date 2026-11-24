import Foundation

/// URLProtocol stub. State is a lock-protected registry keyed by a per-test id carried in a
/// session header, so tests running in parallel never see each other's replies or requests.
/// Each test unregisters its stub when it is done (`defer { stub.unregister() }`), so the
/// registry does not grow across the run.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    enum Reply: Sendable {
        case http(status: Int, body: Data, headers: [String: String] = [:])
        case failure(URLError.Code)
    }

    /// One registered stub: the session to hand the code under test, and its id.
    struct Stub: Sendable {
        let session: URLSession
        let id: String

        /// Every request the session has made, in order.
        var requests: [URLRequest] { StubURLProtocol.requests(id) }

        func unregister() { StubURLProtocol.unregister(id) }
    }

    nonisolated(unsafe) private static var replies: [String: [Reply]] = [:]
    nonisolated(unsafe) private static var seen: [String: [URLRequest]] = [:]
    private static let lock = NSLock()
    static let headerName = "X-Stub-Id"

    /// A session that answers with `replies` in order; the last reply repeats once the
    /// others are used up.
    static func stub(_ replies: [Reply]) -> Stub {
        precondition(!replies.isEmpty, "a stub needs at least one reply")
        let id = UUID().uuidString
        lock.withLock { self.replies[id] = replies }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        config.httpAdditionalHeaders = [headerName: id]
        return Stub(session: URLSession(configuration: config), id: id)
    }

    /// A session that answers every request with `status` and `body`.
    static func stub(status: Int, body: Data) -> Stub {
        stub([.http(status: status, body: body)])
    }

    static func requests(_ id: String) -> [URLRequest] { lock.withLock { seen[id] ?? [] } }

    static func unregister(_ id: String) {
        lock.withLock {
            replies[id] = nil
            seen[id] = nil
        }
    }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let id = request.value(forHTTPHeaderField: Self.headerName) ?? ""
        let reply = Self.lock.withLock { () -> Reply? in
            Self.seen[id, default: []].append(request)
            guard var queue = Self.replies[id], let next = queue.first else { return nil }
            if queue.count > 1 {
                queue.removeFirst()
                Self.replies[id] = queue
            }
            return next
        }
        switch reply {
        case .http(let status, let body, let headers):
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                                 headerFields: headers)
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
        }
    }

    override func stopLoading() {}

    /// Reads a request body that URLSession moved into a stream.
    static func body(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
