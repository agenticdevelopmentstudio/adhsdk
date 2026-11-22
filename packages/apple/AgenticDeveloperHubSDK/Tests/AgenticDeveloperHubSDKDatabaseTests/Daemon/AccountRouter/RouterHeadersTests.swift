import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The header rules both directions, request classification, the upstream URL
/// guard, and the plan's redaction.
final class RouterHeadersTests: XCTestCase {

    private func head(_ method: String, _ target: String, _ fields: [(String, String)]) -> RouterRequestHead {
        RouterRequestHead(method: method, target: target, version: "HTTP/1.1",
                          fields: fields.map { HTTPHeaderField(name: $0.0, value: $0.1) })
    }

    /// `POST /v1/messages`, the common case.
    private func head(_ fields: [(String, String)]) -> RouterRequestHead {
        head("POST", "/v1/messages", fields)
    }

    func testUpstreamFieldsDropHopByHopAndForceIdentity() {
        let request = head([
            ("Host", "127.0.0.1:22848"), ("Authorization", "Bearer own"), ("Connection", "keep-alive, X-Hop"),
            ("X-Hop", "1"), ("Keep-Alive", "timeout=5"), ("TE", "trailers"), ("Upgrade", "h2c"),
            ("Proxy-Authorization", "Basic x"), ("Proxy-Foo", "y"), ("Content-Length", "2"),
            ("Accept-Encoding", "gzip"), ("Expect", "100-continue"), ("X-Custom", "a"), ("x-custom", "b")
        ])
        let fields = RouterHeaders.upstreamFields(request, bearer: nil)
        XCTAssertEqual(fields.map(\.name), ["Authorization", "X-Custom", "x-custom", "accept-encoding"])
        XCTAssertEqual(fields.map(\.value), ["Bearer own", "a", "b", "identity"])
    }

    func testRoutedFieldsReplaceAuthorizationAndDropApiKey() {
        let request = head([("Anthropic-Version", "2023-06-01"), ("authorization", "Bearer sk-ant-oat01-client"),
                            ("X-Api-Key", "k"), ("X-After", "1")])
        let fields = RouterHeaders.upstreamFields(request, bearer: "sk-ant-oat01-pool")
        XCTAssertEqual(fields.map(\.name), ["Anthropic-Version", "authorization", "X-After", "accept-encoding"])
        XCTAssertEqual(fields[1].value, "Bearer sk-ant-oat01-pool")
    }

    func testCandidateTokenTable() {
        let oat = ("Authorization", "Bearer sk-ant-oat01-abc")
        let cases: [(RouterRequestHead, String?, String)] = [
            (head([oat]), "sk-ant-oat01-abc", "POST /v1/messages with a subscription bearer"),
            (head("POST", "/v1/messages/count_tokens?beta=true", [oat]), "sk-ant-oat01-abc", "prefix match"),
            (head([("authorization", "bearer   sk-ant-oat01-abc")]), "sk-ant-oat01-abc", "scheme is case-insensitive"),
            (head("GET", "/v1/messages", [oat]), nil, "not POST"),
            (head("POST", "/v1/models", [oat]), nil, "other path"),
            (head("POST", "/v1/messages/../models", [oat]), nil, "dot-dot"),
            (head("POST", "/v1/messages%2F..%2Fmodels", [oat]), nil, "percent-encoded"),
            (head([oat, ("X-Api-Key", "k")]), nil, "x-api-key present"),
            (head([oat, oat]), nil, "two authorization fields"),
            (head([("Authorization", "Bearer sk-ant-api03-abc")]), nil, "API key, not a subscription token"),
            (head([("Authorization", "Basic sk-ant-oat01-abc")]), nil, "not bearer"),
            (head([]), nil, "no credential")
        ]
        for (request, expected, name) in cases {
            XCTAssertEqual(RouterHeaders.candidateToken(request), expected, name)
        }
    }

    func testResponseFieldsDropFramingEncodingAndUnsafeValues() {
        let fields = RouterHeaders.responseFields([
            "content-type": "text/event-stream", "content-length": "10", "content-encoding": "gzip",
            "transfer-encoding": "chunked", "connection": "close, x-drop", "x-drop": "1", "keep-alive": "t",
            "x-bad": "a\r\nInjected: yes", "request-id": "req_1"
        ])
        XCTAssertEqual(fields.map(\.name), ["content-type", "request-id"])
    }

    func testHasBody() {
        XCTAssertTrue(RouterHeaders.hasBody(method: "POST", status: 200))
        XCTAssertFalse(RouterHeaders.hasBody(method: "HEAD", status: 200))
        XCTAssertFalse(RouterHeaders.hasBody(method: "POST", status: 204))
        XCTAssertFalse(RouterHeaders.hasBody(method: "GET", status: 304))
        XCTAssertFalse(RouterHeaders.hasBody(method: "POST", status: 103))
        XCTAssertEqual(RouterHeaders.reasonPhrase(429), "Too Many Requests")
        XCTAssertEqual(RouterHeaders.reasonPhrase(599), "Unknown")
    }

    func testQuotaColumnsTakeFiniteNumbersOnly() {
        let columns = RouterHeaders.quotaColumns([
            "anthropic-ratelimit-unified-5h-utilization": "0.25", "anthropic-ratelimit-unified-7d-utilization": "nan",
            "anthropic-ratelimit-unified-5h-status": "allowed", "anthropic-organization-id": "org-1"
        ])
        XCTAssertEqual(columns.fiveHour, 0.25)
        XCTAssertNil(columns.sevenDay)
        XCTAssertEqual(columns.fiveHourStatus, "allowed")
        XCTAssertEqual(columns.organizationId, "org-1")
    }

    func testUpstreamRequestStaysOnTheUpstreamHost() throws {
        let base = try XCTUnwrap(URL(string: "https://api.anthropic.com/"))
        let fields = [HTTPHeaderField(name: "X-A", value: "1")]
        let request = try XCTUnwrap(UpstreamCall.request(
            base: base, head: head("POST", "/v1/messages?beta=true", []), fields: fields, body: Data("{}".utf8)))
        XCTAssertEqual(request.url?.absoluteString, "https://api.anthropic.com/v1/messages?beta=true")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-A"), "1")
        XCTAssertEqual(request.httpBody, Data("{}".utf8))
        let sneaky = UpstreamCall.request(
            base: base, head: head("POST", "/@evil.example/x", []), fields: [], body: Data())
        XCTAssertEqual(sneaky?.url?.host, "api.anthropic.com")
        // Final review M7: legal on the wire but not in a URL is encoded and
        // forwarded, never refused.
        let odd = UpstreamCall.request(base: base, head: head("POST", "/a b{", []), fields: [], body: Data())
        XCTAssertEqual(odd?.url?.absoluteString, "https://api.anthropic.com/a%20b%7B")
    }

    func testWireSafeEncodesOnlyWhatAURLCannotHold() {
        XCTAssertEqual(UpstreamCall.wireSafe("/v1/messages?beta=true"), "/v1/messages?beta=true")
        XCTAssertEqual(UpstreamCall.wireSafe("/v1/x%2Fy?q=%41"), "/v1/x%2Fy?q=%41", "valid escapes are kept")
        XCTAssertEqual(UpstreamCall.wireSafe("/v1/x%zz%4"), "/v1/x%25zz%254", "a stray % is escaped")
        XCTAssertEqual(UpstreamCall.wireSafe("/v1?x={\"a\"|b}^`[]\\#"),
                       "/v1?x=%7B%22a%22%7Cb%7D%5E%60%5B%5D%5C%23")
        XCTAssertEqual(UpstreamCall.wireSafe("/-._~!$&'()*+,;=:@/?"), "/-._~!$&'()*+,;=:@/?")
    }

    func testExchangePlanNeverPrintsTheBearer() {
        let plan = ExchangePlan(account: "oauth:a@x.com", bearer: "sk-ant-oat01-secret", rule: "ranked")
        XCTAssertFalse(String(describing: plan).contains("sk-ant-"))
        XCTAssertFalse(String(reflecting: plan).contains("sk-ant-"))
        XCTAssertFalse(String(describing: [plan]).contains("sk-ant-"))
    }
}
