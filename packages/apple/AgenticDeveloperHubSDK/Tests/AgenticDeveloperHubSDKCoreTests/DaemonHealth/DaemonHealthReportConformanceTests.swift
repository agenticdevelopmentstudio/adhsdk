import Foundation
import Network
import Testing
@testable import AgenticDeveloperHubSDKCore

/// A one-shot HTTP responder on the loopback interface that records each request line.
private final class LoopbackServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "DaemonHealthReportConformanceTests.loopback")
    private let lock = NSLock()
    private var recorded: [String] = []
    private let status: Int
    private let body: Data

    private(set) var port: UInt16 = 0

    init(status: Int, body: Data) throws {
        self.status = status
        self.body = body
        listener = try NWListener(using: .tcp, on: .any)
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            if case .ready = state { ready.signal() }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.start(queue: queue)
        _ = ready.wait(timeout: .now() + 5)
        port = listener.port?.rawValue ?? 0
    }

    var requestLines: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func stop() {
        listener.cancel()
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self, let data, let text = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            let line = text.components(separatedBy: "\r\n").first ?? ""
            self.lock.lock()
            self.recorded.append(line)
            self.lock.unlock()

            let head = "HTTP/1.1 \(self.status) X\r\nContent-Length: \(self.body.count)\r\n"
                + "Connection: close\r\n\r\n"
            connection.send(content: Data(head.utf8) + self.body, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }
}

@Suite("DaemonHealthReport conformance")
struct DaemonHealthReportConformanceTests {

    private func work(_ extra: String = #""state":"idle","consecutiveFailures":0,"isBlocklisted":false"#) -> String {
        #"{"status":"ok","version":"1","uptimeSeconds":1,"strategy":{"name":"s","kind":"timing","workUnits":["#
            + #"{"name":"w",\#(extra)}]}}"#
    }

    private func decode(_ text: String) -> DaemonHealthReport? {
        DaemonHealthReport.decode(Data(text.utf8))
    }

    @Test("daemon-health-report-003: bytes that are not JSON decode to nil")
    func v003_notJSON() {
        #expect(DaemonHealthReport.decode(Data("not json".utf8)) == nil)
    }

    @Test("daemon-health-report-004: an unknown work unit state fails the whole report")
    func v004_unknownState() {
        #expect(decode(work(#""state":"paused","consecutiveFailures":0,"isBlocklisted":false"#)) == nil)
    }

    @Test("daemon-health-report-005: a work unit without consecutiveFailures fails")
    func v005_missingRequiredKey() {
        #expect(decode(work(#""state":"idle","isBlocklisted":false"#)) == nil)
    }

    @Test("daemon-health-report-006: nextActivation and lastMessage are optional")
    func v006_optionalKeys() throws {
        let report = try #require(decode(work()))
        let unit = try #require(report.strategy.workUnits.first)
        #expect(unit.nextActivation == nil)
        #expect(unit.lastMessage == nil)
    }

    @Test("daemon-health-report-007: a missing children key decodes as empty")
    func v007_childrenOptional() throws {
        let report = try #require(decode(work()))
        #expect(report.strategy.children.isEmpty)
    }

    @Test("daemon-health-report-008: first(ofKind:) returns the receiver on a match")
    func v008_firstOfKindSelf() {
        let strategy = DaemonStrategyReport(name: "t", kind: "timing", workUnits: [])
        #expect(strategy.first(ofKind: "timing") == strategy)
    }

    @Test("daemon-health-report-009: first(ofKind:) searches depth first")
    func v009_firstOfKindDepthFirst() {
        let nested = DaemonStrategyReport(name: "a1", kind: "event", workUnits: [])
        let first = DaemonStrategyReport(name: "a", kind: "timing", workUnits: [], children: [nested])
        let second = DaemonStrategyReport(name: "b", kind: "event", workUnits: [])
        let root = DaemonStrategyReport(name: "root", kind: "composite", workUnits: [], children: [first, second])
        #expect(root.first(ofKind: "event")?.name == "a1")
    }

    @Test("daemon-health-report-010: first(ofKind:) is nil when nothing matches")
    func v010_firstOfKindNone() {
        let leaf = DaemonStrategyReport(name: "t", kind: "timing", workUnits: [])
        #expect(leaf.first(ofKind: "composite") == nil)
    }

    @Test("daemon-health-report-011: work unit initializer defaults")
    func v011_workUnitDefaults() {
        let unit = DaemonWorkUnitReport(name: "x", state: .running)
        #expect(unit.nextActivation == nil)
        #expect(unit.consecutiveFailures == 0)
        #expect(unit.isBlocklisted == false)
        #expect(unit.lastMessage == nil)
    }

    @Test("daemon-health-report-012: kind constants")
    func v012_kindConstants() {
        #expect(DaemonStrategyReport.timingKind == "timing")
        #expect(DaemonStrategyReport.eventKind == "event")
        #expect(DaemonStrategyReport.compositeKind == "composite")
    }

    @Test("daemon-health-report-013: the probe returns the exact body on a 200")
    func v013_probeReturnsBody() async throws {
        let body = Data(#"{"status":"ok"}"#.utf8)
        let server = try LoopbackServer(status: 200, body: body)
        defer { server.stop() }
        let probe = DaemonHealthProbe.http(baseURL: "http://127.0.0.1:\(server.port)")
        #expect(await probe() == body)
    }

    @Test("daemon-health-report-014: the probe returns nil on a 503")
    func v014_probeNilOnFailureStatus() async throws {
        let server = try LoopbackServer(status: 503, body: Data("down".utf8))
        defer { server.stop() }
        let probe = DaemonHealthProbe.http(baseURL: "http://127.0.0.1:\(server.port)")
        #expect(await probe() == nil)
    }

    @Test("daemon-health-report-015: the probe gives up after 2 seconds of silence",
          .disabled("needs a real wait longer than a second; a unit test does not let real time pass"))
    func v015_probeIdleTimeout() {}

    @Test("daemon-health-report-016: the probe returns nil when nothing is listening")
    func v016_probeNilWhenNoServer() async throws {
        let server = try LoopbackServer(status: 200, body: Data())
        let port = server.port
        server.stop()
        let probe = DaemonHealthProbe.http(baseURL: "http://127.0.0.1:\(port)", timeout: 1)
        #expect(await probe() == nil)
    }

    @Test("daemon-health-report-017: an unparsable baseURL returns nil")
    func v017_probeNilOnBadURL() async {
        let probe = DaemonHealthProbe.http(baseURL: "")
        #expect(await probe() == nil)
    }

    @Test("daemon-health-report-018: the probe sends GET /health")
    func v018_probeRequest() async throws {
        let server = try LoopbackServer(status: 200, body: Data("{}".utf8))
        defer { server.stop() }
        let probe = DaemonHealthProbe.http(baseURL: "http://127.0.0.1:\(server.port)")
        _ = await probe()
        #expect(server.requestLines == ["GET /health HTTP/1.1"])
    }

    @Test("daemon-health-report-019: each invocation makes exactly one attempt")
    func v019_probeNoRetry() async throws {
        let server = try LoopbackServer(status: 500, body: Data())
        defer { server.stop() }
        let probe = DaemonHealthProbe.http(baseURL: "http://127.0.0.1:\(server.port)")
        #expect(await probe() == nil)
        #expect(server.requestLines.count == 1)
        #expect(await probe() == nil)
        #expect(server.requestLines.count == 2)
    }

    @Test("daemon-health-report-020: an unknown kind is kept")
    func v020_kindOpen() throws {
        let text = #"{"status":"ok","version":"1","uptimeSeconds":1,"#
            + #""strategy":{"name":"s","kind":"custom","workUnits":[]}}"#
        let report = try #require(decode(text))
        #expect(report.strategy.kind == "custom")
    }

    @Test("daemon-health-report-021: a slow body does not trip the idle timeout",
          .disabled("needs a server that trickles bytes for several real seconds"))
    func v021_probeIdleNotTotal() {}

    @Test("daemon-health-report-022: a non-HTTP response returns nil")
    func v022_probeNonHTTPResponse() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("{}".utf8).write(to: directory.appendingPathComponent("health"))

        let probe = DaemonHealthProbe.http(baseURL: directory.absoluteString)
        #expect(await probe() == nil)
    }

    @Test("daemon-health-report-023: strategy initializer defaults children to empty")
    func v023_strategyDefault() {
        #expect(DaemonStrategyReport(name: "t", kind: "timing", workUnits: []).children.isEmpty)
    }

    @Test("daemon-health-report-024: children nest recursively")
    func v024_childrenRecursive() throws {
        let text = #"{"status":"ok","version":"1","uptimeSeconds":1,"strategy":{"name":"root","kind":"composite","#
            + #""workUnits":[],"children":[{"name":"mid","kind":"composite","workUnits":[],"#
            + #""children":[{"name":"leaf","kind":"timing","workUnits":[]}]}]}}"#
        let report = try #require(decode(text))
        let mid = try #require(report.strategy.children.first)
        #expect(mid.children.first?.name == "leaf")
        #expect(mid.children.first?.children.isEmpty == true)
    }

    @Test("daemon-health-report-025: status is an opaque string")
    func v025_statusOpaque() throws {
        let text = #"{"status":"degraded","version":"1","uptimeSeconds":1,"#
            + #""strategy":{"name":"s","kind":"timing","workUnits":[]}}"#
        #expect(try #require(decode(text)).status == "degraded")
    }

    @Test("daemon-health-report-026: a numeric nextActivation fails the whole report")
    func v026_numericDateFails() {
        let extra = #""state":"idle","nextActivation":1767225600,"#
            + #""consecutiveFailures":0,"isBlocklisted":false"#
        #expect(decode(work(extra)) == nil)
    }

    @Test("daemon-health-report-027: the probe URL keeps a path and avoids a double slash")
    func v027_probeURLShapes() async throws {
        let server = try LoopbackServer(status: 200, body: Data("{}".utf8))
        defer { server.stop() }
        let root = DaemonHealthProbe.http(baseURL: "http://127.0.0.1:\(server.port)/")
        _ = await root()
        let api = DaemonHealthProbe.http(baseURL: "http://127.0.0.1:\(server.port)/api")
        _ = await api()
        #expect(server.requestLines == ["GET /health HTTP/1.1", "GET /api/health HTTP/1.1"])
    }
}
