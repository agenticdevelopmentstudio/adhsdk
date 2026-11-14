import XCTest
import Foundation
import HTTPTypes
import OpenAPIRuntime
import AgenticDeveloperHubClient
@testable import AgenticDeveloperHubSDKHubMail

/// Vectors hub-mail-011 and 012: send goes through the hub's `send` action.
final class HubMailSenderTests: XCTestCase {

    /// Answers every request with one canned response and records what it saw.
    private final class OneAnswerTransport: ClientTransport, @unchecked Sendable {
        let status: Int
        let json: String
        private let lock = NSLock()
        private var seen: [(path: String, body: Data?)] = []

        init(status: Int, json: String) {
            self.status = status
            self.json = json
        }

        var requests: [(path: String, body: Data?)] { lock.withLock { seen } }

        func send(
            _ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String
        ) async throws -> (HTTPResponse, HTTPBody?) {
            var data: Data?
            if let body { data = try await Data(collecting: body, upTo: 1024 * 1024) }
            lock.withLock { seen.append((request.path ?? "", data)) }
            var fields = HTTPFields()
            fields[.contentType] = "application/json"
            return (HTTPResponse(status: .init(code: status), headerFields: fields), HTTPBody(json))
        }
    }

    private func sender(_ transport: OneAnswerTransport) throws -> HubMailSender {
        let client = AgenticDeveloperHubClient.Client(
            serverURL: try XCTUnwrap(URL(string: "https://hub.test")),
            transport: transport
        )
        return HubMailSender(client: client)
    }

    // 011
    func testSendNamesTheConnectionAndActionAndReturnsTheResult() async throws {
        let transport = OneAnswerTransport(status: 200, json: """
            {"object":"action","ok":true,"status":"ok","action_log_id":"log1","external_id":"g1","deduped":false}
            """)
        let result = try await sender(transport).send(
            connectionId: "conn-1", to: ["a@x"], cc: ["b@x"], subject: "Hi", bodyText: "Hello"
        )
        XCTAssertEqual(result, HubMailSendResult(ok: true, externalId: "g1", deduped: false, error: nil))

        let request = try XCTUnwrap(transport.requests.first)
        XCTAssertTrue(request.path.hasSuffix("/integrations/connections/conn-1/actions/send"), request.path)
        let body = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try XCTUnwrap(request.body)) as? [String: Any]
        )
        XCTAssertEqual(body["to"] as? [String], ["a@x"])
        XCTAssertEqual(body["cc"] as? [String], ["b@x"])
        XCTAssertEqual(body["subject"] as? String, "Hi")
        XCTAssertEqual(body["body_text"] as? String, "Hello")
        XCTAssertNil(body["bcc"])
    }

    // 012
    func testANon200AnswerThrowsRejectedWithItsStatus() async throws {
        let transport = OneAnswerTransport(
            status: 401, json: #"{"error":{"type":"authentication_error","message":"unauthorized"}}"#
        )
        do {
            _ = try await sender(transport).send(connectionId: "conn-1", to: ["a@x"], subject: "Hi")
            XCTFail("expected a rejection")
        } catch {
            XCTAssertEqual(error as? HubMailSendError, .rejected(statusCode: 401))
        }
    }

    func testAnUndocumentedStatusKeepsItsCode() async throws {
        let transport = OneAnswerTransport(status: 418, json: "{}")
        do {
            _ = try await sender(transport).send(connectionId: "conn-1", to: ["a@x"], subject: "Hi")
            XCTFail("expected a rejection")
        } catch {
            XCTAssertEqual(error as? HubMailSendError, .rejected(statusCode: 418))
        }
    }
}
