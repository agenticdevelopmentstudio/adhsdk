#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

struct UpstreamHead: Equatable, Sendable {
    let status: Int
    /// Keys lowercased.
    let headers: [String: String]
}

enum UpstreamEvent: Equatable, Sendable {
    case head(UpstreamHead)
    case body(Data)
    case finished
    /// Already scrubbed.
    case failed(String)
}

/// One upstream request as a pull-based event stream.
///
/// - The head is held: the body is not requested until `allowBody()`, so a
///   401/429 that will be retried costs no download.
/// - Backpressure: a body chunk nobody is waiting for suspends the task, and
///   `next()` resumes it once the queue drains. A slow client therefore
///   slows upstream instead of filling memory.
/// - Redirects are handed back as responses, never followed.
/// - A response without a `Content-Type` is held back by URLSession's MIME
///   sniffing (up to about 512 bytes, or the end of the body), which delays
///   streaming. The Anthropic API always sets `Content-Type`, so only a
///   test fake that omits it sees the delay.
final class UpstreamCall: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let task: URLSessionDataTask
    private let lock = NSLock()
    private var queued: [UpstreamEvent] = []
    private var waiter: CheckedContinuation<UpstreamEvent?, Never>?
    private typealias DispositionHandler = @Sendable (URLSession.ResponseDisposition) -> Void

    private var disposition: DispositionHandler?
    private var suspended = false
    private var cancelled = false
    /// `fail` ended the call: nothing URLSession reports afterwards is delivered.
    private var ended = false
    private var eventCount = 0
    /// Starts at creation, so a head deadline counts from the send.
    private var lastEventAt = ContinuousClock.now

    init(session: URLSession, request: URLRequest) {
        task = session.dataTask(with: request)
        super.init()
        task.delegate = self
    }

    /// One session for the router's lifetime: ephemeral, no cookies, cache or
    /// credential storage, 600 s idle timeout, and `network`'s proxy and extra
    /// CA certificates (see `UpstreamNetwork`).
    static func makeSession(network: UpstreamNetwork = .none) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.urlCredentialStorage = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = 600
        config.httpMaximumConnectionsPerHost = 32
        if let proxies = network.proxyDictionary { config.connectionProxyDictionary = proxies }
        let callbacks = OperationQueue()
        callbacks.name = "account-router.upstream"
        callbacks.maxConcurrentOperationCount = 1
        return URLSession(configuration: config, delegate: UpstreamTrust(network: network), delegateQueue: callbacks)
    }

    /// The upstream request for `head`, or nil when the target would leave the
    /// upstream's scheme, host or port, or is not a valid URL.
    static func request(base: URL, head: RouterRequestHead, fields: [HTTPHeaderField], body: Data) -> URLRequest? {
        var root = base.absoluteString
        while root.hasSuffix("/") { root.removeLast() }
        guard let url = URL(string: root + wireSafe(head.target), encodingInvalidCharacters: false),
              url.scheme == base.scheme, url.host == base.host, url.port == base.port else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = head.method
        request.httpBody = body.isEmpty ? nil : body
        for field in fields { request.addValue(field.value, forHTTPHeaderField: field.name) }
        return request
    }

    /// A request to a fixed `url` (a provider endpoint), with exactly `fields`.
    static func request(url: URL, method: String, fields: [HTTPHeaderField], body: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body.isEmpty ? nil : body
        for field in fields { request.addValue(field.value, forHTTPHeaderField: field.name) }
        return request
    }

    /// `target` with only the bytes a URL cannot hold percent-encoded: a
    /// target that is legal on the wire but not in a `URL` (a `{`, `|`, `"`,
    /// `^`, a stray `%`, a `#`) is forwarded rather than refused. Everything
    /// already valid, including existing `%XX` escapes, is left exactly as sent.
    static func wireSafe(_ target: String) -> String {
        let bytes = Array(target.utf8)
        var out = ""
        out.reserveCapacity(bytes.count)
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            let isEscape = byte == 0x25 && index + 2 < bytes.count
                && isHexDigit(bytes[index + 1]) && isHexDigit(bytes[index + 2])
            if isEscape || allowedInTarget.contains(byte) {
                out.unicodeScalars.append(Unicode.Scalar(byte))
            } else {
                out += "%" + String(byte, radix: 16, uppercase: true).leftPadded(to: 2)
            }
            index += 1
        }
        return out
    }

    /// RFC 3986 unreserved, sub-delims, ":", "@", "/" and "?".
    private static let allowedInTarget = Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~!$&'()*+,;=:@/?".utf8)

    private static func isHexDigit(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x30...0x39, 0x41...0x46, 0x61...0x66: return true
        default: return false
        }
    }

    func start() { task.resume() }

    /// The data task's state. A session's `allTasks` omits a task never
    /// resumed, so this is how a test sees one that was left behind.
    var taskState: URLSessionTask.State { task.state }

    /// The next event, or nil once cancelled. After `.finished` or `.failed`, nil.
    func next() async -> UpstreamEvent? {
        await withCheckedContinuation { continuation in
            lock.lock()
            if cancelled {
                lock.unlock()
                continuation.resume(returning: nil)
                return
            }
            guard !queued.isEmpty else {
                waiter = continuation
                lock.unlock()
                return
            }
            let event = queued.removeFirst()
            if queued.isEmpty && suspended {
                suspended = false
                // Under the lock, like the suspend in `deliver`: the flag and
                // the task's state change together, so a resume can never land
                // before the suspend it answers and leave the task paused.
                task.resume()
            }
            lock.unlock()
            continuation.resume(returning: event)
        }
    }

    /// Lets the body flow after `.head`.
    func allowBody() {
        let pending = lock.withLock { () -> DispositionHandler? in
            defer { disposition = nil }
            return disposition
        }
        pending?(.allow)
    }

    func cancel() {
        let (pending, sleeper) = lock.withLock {
            () -> (DispositionHandler?, CheckedContinuation<UpstreamEvent?, Never>?) in
            guard !cancelled else { return (nil, nil) }
            cancelled = true
            queued.removeAll()
            defer {
                disposition = nil
                waiter = nil
            }
            return (disposition, waiter)
        }
        pending?(.cancel)
        task.cancel()
        sleeper?.resume(returning: nil)
    }

    /// How many events URLSession has reported, and when the last one came.
    var progress: (count: Int, at: ContinuousClock.Instant) {
        lock.withLock { (eventCount, lastEventAt) }
    }

    /// Ends the call, unless an event arrived after `progress` read `mark`:
    /// `.failed(reason)` is then its last event and the request is cancelled.
    /// Whatever acts on an event sees the count move first, so a watchdog
    /// that read a stale mark can never fail a call that has moved on.
    func fail(_ reason: String, unlessProgressSince mark: Int) {
        let failed = UpstreamEvent.failed(AccountRouterLog.scrub(reason))
        lock.lock()
        guard !cancelled, !ended, eventCount == mark else {
            lock.unlock()
            return
        }
        ended = true
        let sleeper = waiter
        waiter = nil
        if sleeper == nil { queued.append(failed) }
        lock.unlock()
        task.cancel()
        sleeper?.resume(returning: failed)
    }

    private func deliver(_ event: UpstreamEvent) {
        lock.lock()
        if cancelled || ended {
            lock.unlock()
            return
        }
        eventCount += 1
        lastEventAt = .now
        if let sleeper = waiter {
            waiter = nil
            lock.unlock()
            sleeper.resume(returning: event)
            return
        }
        queued.append(event)
        if case .body = event, !suspended {
            suspended = true
            // Under the lock; see `next()`. Neither call reenters this object.
            task.suspend()
        }
        lock.unlock()
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(
        _ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        guard let http = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            deliver(.failed("upstream sent a non-HTTP response"))
            return
        }
        let accepted = lock.withLock { () -> Bool in
            guard !cancelled else { return false }
            disposition = completionHandler
            return true
        }
        guard accepted else {
            completionHandler(.cancel)
            return
        }
        deliver(.head(UpstreamHead(status: http.statusCode, headers: RouterHeaders.lowercased(http))))
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        deliver(.body(data))
    }

    func urlSession(
        _ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error {
            deliver(.failed(AccountRouterLog.scrub(error.localizedDescription)))
        } else {
            deliver(.finished)
        }
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: "0", count: width - count) + self
    }
}
#endif
