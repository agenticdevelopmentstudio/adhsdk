import XCTest
import MCP
@testable import AgenticDeveloperHubSDKCore

/// The handler driven directly, as adhd's route and `MCPHTTPEndpoint` drive
/// it: no socket, no network.
final class MCPStatelessHTTPHandlerTests: XCTestCase {

    private var server: HostMCPServer!
    private var source: EchoSource!
    private var handler: MCPStatelessHTTPHandler!

    override func setUp() async throws {
        source = EchoSource(names: ["a", "b"])
        server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(source)
        handler = try await MCPStatelessHTTPHandler(server: server)
    }

    override func tearDown() async throws {
        await server.stop()
    }

    private static let jsonHeaders = [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ]

    private func post(_ body: String, headers extra: [String: String] = [:]) async throws
        -> (status: Int, headers: [String: String], json: [String: Any]?) {
        let headers = Self.jsonHeaders.merging(extra) { _, new in new }
        let answer = await handler.handle(method: "POST", headers: headers, body: Data(body.utf8))
        let json = try? JSONSerialization.jsonObject(with: answer.body) as? [String: Any]
        return (answer.status, answer.headers, json)
    }

    private func rpc(_ method: String, params: String = "{}", id: String = "1") -> String {
        #"{"jsonrpc":"2.0","id":\#(id),"method":"\#(method)","params":\#(params)}"#
    }

    private func text(_ json: [String: Any]?) -> String? {
        let content = (json?["result"] as? [String: Any])?["content"] as? [[String: Any]]
        return content?.first?["text"] as? String
    }

    func testInitializeRoundTrip() async throws {
        let params = #"{"protocolVersion":"\#(Version.latest)","capabilities":{},"#
            + #""clientInfo":{"name":"test","version":"1"}}"#
        let reply = try await post(rpc("initialize", params: params, id: "7"))
        XCTAssertEqual(reply.status, 200)
        XCTAssertEqual(reply.json?["id"] as? Int, 7, "the caller's own id comes back")
        let result = reply.json?["result"] as? [String: Any]
        XCTAssertEqual((result?["serverInfo"] as? [String: Any])?["name"] as? String, "Test")
        XCTAssertNotNil((result?["capabilities"] as? [String: Any])?["tools"])
    }

    func testToolsListRoundTrip() async throws {
        let reply = try await post(rpc("tools/list"))
        XCTAssertEqual(reply.status, 200)
        XCTAssertEqual(reply.json?["id"] as? Int, 1)
        let tools = (reply.json?["result"] as? [String: Any])?["tools"] as? [[String: Any]]
        XCTAssertEqual(tools?.map { $0["name"] as? String }, ["a", "b"])
    }

    func testToolsCallRoundTrip() async throws {
        let reply = try await post(rpc("tools/call", params: #"{"name":"b","arguments":{"x":"y"}}"#, id: #""req-1""#))
        XCTAssertEqual(reply.status, 200)
        XCTAssertEqual(reply.json?["id"] as? String, "req-1")
        XCTAssertEqual(text(reply.json), "echo:b")
        XCTAssertEqual(source.calls.map(\.name), ["b"])
    }

    func testCallerHeaderReachesCallTool() async throws {
        let call = rpc("tools/call", params: #"{"name":"a","arguments":{}}"#)
        _ = try await post(call, headers: [HostMCPServer.callerHeader: "pane-7"])
        _ = try await post(call, headers: ["x-adhd-pane": "pane-lower"])
        _ = try await post(call, headers: [HostMCPServer.legacyCallerHeader: "pane-old"])
        _ = try await post(call)
        XCTAssertEqual(source.calls.map(\.caller), ["pane-7", "pane-lower", "pane-old", nil])
    }

    func testCallerIsReadFromEitherName() {
        XCTAssertEqual(MCPStatelessHTTPHandler.caller(in: ["X-ADHD-Pane": "new"]), "new")
        XCTAssertEqual(MCPStatelessHTTPHandler.caller(in: ["X-ADKitchen-Pane": "old"]), "old")
        XCTAssertEqual(MCPStatelessHTTPHandler.caller(in: ["X-ADKitchen-Pane": "old", "X-ADHD-Pane": "new"]), "new")
        XCTAssertNil(MCPStatelessHTTPHandler.caller(in: ["Accept": "application/json"]))
    }

    func testAMethodOtherThanPostIs405() async {
        for method in ["GET", "DELETE"] {
            let answer = await handler.handle(method: method, headers: Self.jsonHeaders, body: Data())
            XCTAssertEqual(answer.status, 405)
            XCTAssertEqual(answer.headers["Allow"], "POST")
        }
    }

    func testIdRewriteRoundTrips() throws {
        let body = Data(rpc("tools/list", id: "42").utf8)
        let rewrite = MCPStatelessHTTPHandler.rewriteID(in: body)
        let unique = try XCTUnwrap(rewrite.uniqueID)
        let sent = try XCTUnwrap(JSONSerialization.jsonObject(with: rewrite.body) as? [String: Any])
        XCTAssertEqual(sent["id"] as? String, unique)

        let answer = try JSONSerialization.data(withJSONObject: ["jsonrpc": "2.0", "id": unique, "result": [:]])
        let restored = MCPStatelessHTTPHandler.restoreID(in: answer, using: rewrite)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: restored) as? [String: Any])
        XCTAssertEqual(object["id"] as? Int, 42)
    }

    func testOnlyStringAndIntegerIdsAreRewritten() {
        for id in ["null", "true", "1.5"] {
            XCTAssertNil(MCPStatelessHTTPHandler.rewriteID(in: Data(rpc("tools/list", id: id).utf8)).uniqueID, id)
        }
    }

    func testACancellationNotificationIsRecognised() throws {
        let body = Data(#"{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":5}}"#.utf8)
        let cancellation = try XCTUnwrap(MCPStatelessHTTPHandler.cancellation(in: body))
        let renamed = try XCTUnwrap(JSONSerialization.jsonObject(with: cancellation.naming("u-1")) as? [String: Any])
        XCTAssertEqual((renamed["params"] as? [String: Any])?["requestId"] as? String, "u-1")
        XCTAssertNil(MCPStatelessHTTPHandler.cancellation(in: Data(rpc("tools/list").utf8)))
    }

    func testTwoRequestsUnderOneKeyAreBothKeptAndNeitherIsCancelledByGuess() async {
        // Two sessions outside any pane, both sending id 3.
        let key = MCPStatelessHTTPHandler.inFlightKey(caller: nil, originalIDJSON: Data("[3]".utf8))
        let inFlight = MCPStatelessHTTPHandler.InFlightRequests()
        await inFlight.begin(key, uniqueID: "a")
        let alone = await inFlight.uniqueID(for: key)
        XCTAssertEqual(alone, "a")

        await inFlight.begin(key, uniqueID: "b")
        let ambiguous = await inFlight.uniqueID(for: key)
        XCTAssertNil(ambiguous, "a cancellation that could mean either cancels neither")

        await inFlight.end(key, uniqueID: "a")
        let remaining = await inFlight.uniqueID(for: key)
        XCTAssertEqual(remaining, "b")
        await inFlight.end(key, uniqueID: "b")
        let none = await inFlight.uniqueID(for: key)
        XCTAssertNil(none)
    }
}
