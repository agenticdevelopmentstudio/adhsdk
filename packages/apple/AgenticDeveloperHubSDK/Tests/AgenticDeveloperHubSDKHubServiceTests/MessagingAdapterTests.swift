import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class MessagingAdapterTests: XCTestCase {
    private var stub: StubClientTransport!
    private var adapter: MessagingAdapter!
    private let statusPath = "/v1/messaging/status"
    private let messagesPath = "/v1/messaging/messages"
    private let templatesPath = "/v1/messaging/templates"

    override func setUp() async throws {
        try await super.setUp()
        stub = StubClientTransport()
        let store = InMemorySessionStore(
            HubSession(credentials: Credentials(token: "jwt", kind: .jwt), refreshToken: "r")
        )
        let environment = HubEnvironment(
            sessionStore: store,
            transportSource: StaticTransportSource(.direct(transport: stub)),
            initialTransport: .direct(transport: stub)
        )
        adapter = MessagingAdapter(
            environment: environment,
            workspace: HubWorkspace(slug: "acme", name: "Acme", type: .organization)
        )
    }

    private let entryJSON = #"""
    {"id":"m-1","object":"messaging.message","owner_kind":"customer","owner_id":"c-jane",
     "ecosystem_id":"org.acme.shop","channel":"email","recipient":"jane@example.com","subject":"Your order",
     "body":"Shipped.","template_id":null,"status":"sent","provider_id":"pm-1","error_message":null,
     "sent_by":"owner@acme.test","origin":"ecosystem","created_at":"2026-09-03T12:00:00.000Z"}
    """#

    func testStatus() async throws {
        stub.on(.get, statusPath, json: #"{"object":"messaging.status","email":true,"sms":false}"#)
        let status = try await adapter.status(ecosystemID: "org.acme.shop")
        XCTAssertEqual(status, MessagingStatus(email: true, sms: false))
        XCTAssertEqual(
            stub.lastRequest(.get, statusPath)?.path, "\(statusPath)?ecosystem=org.acme.shop&workspace=acme"
        )
    }

    private let templateJSON = #"""
    {"id":"tpl-welcome","object":"messaging.template","name":"Welcome","subject":"Hi {{name}}",
     "html_body":"<p>x</p>","text_body":"Hi {{name}}","sms_body":null,"category":"onboarding"}
    """#

    func testTemplates() async throws {
        stub.on(.get, templatesPath, json: StubClientTransport.list([templateJSON]))
        let templates = try await adapter.templates()
        XCTAssertEqual(templates.map(\.id), ["tpl-welcome"])
        XCTAssertEqual(templates.first?.textBody, "Hi {{name}}")
        XCTAssertEqual(templates.first?.placeholders, ["name"])
        XCTAssertEqual(
            stub.lastRequest(.get, templatesPath)?.path, "\(templatesPath)?limit=100&workspace=acme"
        )
    }

    func testLogPassesCursorPaging() async throws {
        stub.on(.get, messagesPath, json: StubClientTransport.list([entryJSON], hasMore: true))
        let page = try await adapter.log(ecosystemID: "org.acme.shop", limit: 50, startingAfter: "m-0")
        XCTAssertEqual(page.items.map(\.id), ["m-1"])
        XCTAssertEqual(page.items.first?.channel, .email)
        XCTAssertEqual(page.items.first?.ecosystemId, "org.acme.shop")
        XCTAssertEqual(page.items.first?.providerId, "pm-1")
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(
            stub.lastRequest(.get, messagesPath)?.path,
            "\(messagesPath)?ecosystem=org.acme.shop&limit=50&starting_after=m-0&workspace=acme"
        )
    }

    func testFirstLogPageSendsNoCursor() async throws {
        stub.on(.get, messagesPath, json: StubClientTransport.list([]))
        let page = try await adapter.log(ecosystemID: "org.acme.shop", limit: 50, startingAfter: nil)
        XCTAssertTrue(page.items.isEmpty)
        XCTAssertFalse(page.hasMore)
        XCTAssertEqual(
            stub.lastRequest(.get, messagesPath)?.path,
            "\(messagesPath)?ecosystem=org.acme.shop&limit=50&workspace=acme"
        )
    }

    func testSendPostsBodyWithEcosystemAndWithoutNils() async throws {
        stub.on(.post, messagesPath, json: #"{"status":"sent","provider_id":"pm-9","error":null}"#)
        let result = try await adapter.send(
            ecosystemID: "org.acme.shop",
            MessagingSend(userId: "c-jane", channel: .email, subject: "S", body: "B")
        )
        XCTAssertEqual(result, MessagingSendResult(status: "sent", providerId: "pm-9"))
        XCTAssertEqual(stub.lastRequest(.post, messagesPath)?.path, "\(messagesPath)?workspace=acme")
        let sent = stub.lastBody(.post, messagesPath)
        XCTAssertEqual(sent?["ecosystem"] as? String, "org.acme.shop")
        XCTAssertEqual(sent?["userId"] as? String, "c-jane")
        XCTAssertEqual(sent?["channel"] as? String, "email")
        XCTAssertEqual(sent?["subject"] as? String, "S")
        XCTAssertNil(sent?["templateId"] ?? nil)
        XCTAssertNil(sent?["recipient"] ?? nil)
    }

    func testSendTemplateVars() async throws {
        stub.on(.post, messagesPath, json: #"{"status":"sent"}"#)
        _ = try await adapter.send(
            ecosystemID: "org.acme.shop",
            MessagingSend(
                userId: "c-jane", channel: .sms, templateId: "tpl-welcome",
                templateVars: ["name": "Jane"], recipient: "+15555550123"
            )
        )
        let sent = stub.lastBody(.post, messagesPath)
        XCTAssertEqual(sent?["templateId"] as? String, "tpl-welcome")
        XCTAssertEqual(sent?["templateVars"] as? [String: String], ["name": "Jane"])
        XCTAssertEqual(sent?["recipient"] as? String, "+15555550123")
    }

    /// The gateway rewrites a 422 to the `/v1` error envelope; its message is the provider's reason.
    func testFailedSendReturnsTheProviderReasonAsAResult() async throws {
        stub.on(.post, messagesPath, status: 422, json: StubClientTransport.error("Recipient rejected"))
        let result = try await adapter.send(
            ecosystemID: "org.acme.shop",
            MessagingSend(userId: "c-jane", channel: .email, subject: "S", body: "B")
        )
        XCTAssertEqual(result, MessagingSendResult(status: "failed", error: "Recipient rejected"))
    }

    func testUnreadable422StillReturnsAFailedResult() async throws {
        stub.on(.post, messagesPath, status: 422, json: "not json")
        let result = try await adapter.send(
            ecosystemID: "org.acme.shop",
            MessagingSend(userId: "", channel: .email, subject: "S", body: "B")
        )
        XCTAssertEqual(result, MessagingSendResult(status: "failed", error: "The provider refused the message."))
    }

    /// F-17: `send()` does NOT go through `HubAPI` — it drives `rawJSON` itself and maps errors in its
    /// own `catch` ladder, so its non-422 branches need their own coverage.
    func testSendNon422ErrorMapsThroughSendsOwnLadder() async throws {
        stub.on(.post, messagesPath, status: 403, json: StubClientTransport.error("messaging disabled"))
        do {
            _ = try await adapter.send(
                ecosystemID: "org.acme.shop",
                MessagingSend(userId: "c-jane", channel: .email, subject: "S", body: "B")
            )
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .forbidden)
        }
    }

    func testSendServerErrorMapsThroughSendsOwnLadder() async throws {
        stub.on(
            .post, messagesPath, status: 500,
            json: StubClientTransport.error("provider exploded", type: "api_error")
        )
        do {
            _ = try await adapter.send(
                ecosystemID: "org.acme.shop",
                MessagingSend(userId: "c-jane", channel: .email, subject: "S", body: "B")
            )
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .transport("HTTP 500"))
        }
    }

    func testOtherErrorsMapToHubError() async throws {
        stub.on(.get, statusPath, status: 401, json: StubClientTransport.error("no session"))
        do {
            _ = try await adapter.status(ecosystemID: "org.acme.shop")
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .unauthorized)
        }
    }
}
