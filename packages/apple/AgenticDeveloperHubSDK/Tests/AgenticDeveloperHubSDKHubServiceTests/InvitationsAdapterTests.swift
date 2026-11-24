import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class InvitationsAdapterTests: XCTestCase {
    private var stub: StubClientTransport!
    private var adapter: InvitationsAdapter!
    private let base = "/v1"

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
        adapter = InvitationsAdapter(
            environment: environment,
            workspace: HubWorkspace(slug: "acme", name: "Acme", type: .organization)
        )
    }

    private let requestJSON = #"""
    {"id":"req-1","pending_user_id":"pu-1","name":"Sam Lee","email":"sam@example.com","phone":null,"source":"web",
     "note":"Please",
     "created":1788220800,"user_number":7}
    """#
    private let pendingJSON = #"""
    {"id":"pu-1","user_number":7,"name":"Ada Park","email":"ada@example.com","phone":"+15555550123",
     "invited_count":1,"request_count":2,
     "last_request_at":"2026-09-02T00:00:00.000Z","last_invite_sent_at":null,
     "first_requested_at":"2026-09-01T00:00:00.000Z","last_source":"web","last_note":null,"status":"pending"}
    """#
    private let inviteJSON = #"""
    {"id":"inv-1","name":"Ada Park","channel":"email","destination":"ada@example.com",
     "sent_by":"owner@acme.test","sent_at":"2026-09-03T00:00:00.000Z","status":"sent"}
    """#
    private let noteJSON = #"""
    {"id":"n-1","content":"Met at the meetup","created_by":"owner@acme.test","subject_table":"pending_users",
     "subject_id":"pu-1",
     "created":1788220800,"updated":1788220800}
    """#

    func testRequestsList() async throws {
        stub.on(.get, "\(base)/invitation_requests", json: StubClientTransport.list([requestJSON]))
        let rows = try await adapter.requests(ecosystemID: "org.acme.shop")
        XCTAssertEqual(rows.map(\.id), ["req-1"])
        XCTAssertEqual(rows.first?.userNumber, 7)
        XCTAssertEqual(
            stub.lastRequest(.get, "\(base)/invitation_requests")?.path,
            "\(base)/invitation_requests?ecosystem=org.acme.shop&limit=100&workspace=acme"
        )
    }

    func testDeleteRequest() async throws {
        stub.on(.delete, "\(base)/invitation_requests/req-1", status: 204, json: "")
        try await adapter.deleteRequest(ecosystemID: "org.acme.shop", id: "req-1")
        XCTAssertEqual(stub.requestCount(.delete, "\(base)/invitation_requests/req-1"), 1)
        XCTAssertEqual(
            stub.lastRequest(.delete, "\(base)/invitation_requests/req-1")?.path,
            "\(base)/invitation_requests/req-1?ecosystem=org.acme.shop&workspace=acme"
        )
    }

    func testPendingUsersListAndAdd() async throws {
        stub.on(.get, "\(base)/pending_users", json: StubClientTransport.list([pendingJSON]))
        stub.on(.post, "\(base)/pending_users", status: 201, json: StubClientTransport.list([pendingJSON]))
        let rows = try await adapter.pendingUsers(ecosystemID: "org.acme.shop")
        XCTAssertEqual(rows.first?.contact, "ada@example.com")
        XCTAssertEqual(
            stub.lastRequest(.get, "\(base)/pending_users")?.path,
            "\(base)/pending_users?ecosystem=org.acme.shop&limit=100&workspace=acme"
        )

        try await adapter.addPendingUsers(
            ecosystemID: "org.acme.shop",
            [DraftUser(name: "Ada Park", email: "ada@example.com", phone: nil, note: nil)]
        )
        XCTAssertEqual(
            stub.lastRequest(.post, "\(base)/pending_users")?.path, "\(base)/pending_users?workspace=acme"
        )
        let sent = stub.lastBody(.post, "\(base)/pending_users")
        XCTAssertEqual(sent?["ecosystem"] as? String, "org.acme.shop")
        let users = sent?["users"] as? [[String: Any]]
        XCTAssertEqual(users?.count, 1)
        XCTAssertEqual(users?.first?["name"] as? String, "Ada Park")
        XCTAssertEqual(users?.first?["email"] as? String, "ada@example.com")
        XCTAssertNil(users?.first?["phone"] ?? nil)
    }

    func testDeletePendingUser() async throws {
        stub.on(.delete, "\(base)/pending_users/pu-1", status: 204, json: "")
        try await adapter.deletePendingUser(ecosystemID: "org.acme.shop", id: "pu-1")
        XCTAssertEqual(
            stub.lastRequest(.delete, "\(base)/pending_users/pu-1")?.path,
            "\(base)/pending_users/pu-1?ecosystem=org.acme.shop&workspace=acme"
        )
    }

    func testInvitesListSendAndDelete() async throws {
        stub.on(.get, "\(base)/invitations", json: StubClientTransport.list([inviteJSON]))
        stub.on(.post, "\(base)/invitations", status: 201, json: "{}")
        stub.on(.delete, "\(base)/invitations/inv-1", status: 204, json: "")
        let rows = try await adapter.invites(ecosystemID: "org.acme.shop")
        XCTAssertEqual(rows.first?.channelTitle, "Email")
        XCTAssertEqual(stub.lastRequest(.get, "\(base)/invitations")?.path,
            "\(base)/invitations?ecosystem=org.acme.shop&limit=100&workspace=acme")

        try await adapter.sendInvitation(
            ecosystemID: "org.acme.shop",
            InvitationSend(pendingUserIds: ["pu-1"], email: InvitationChannelNote(note: "Welcome!"), sms: nil)
        )
        XCTAssertEqual(stub.lastRequest(.post, "\(base)/invitations")?.path, "\(base)/invitations?workspace=acme")
        let sent = stub.lastBody(.post, "\(base)/invitations")
        XCTAssertEqual(sent?["ecosystem"] as? String, "org.acme.shop")
        XCTAssertEqual(sent?["pendingUserIds"] as? [String], ["pu-1"])
        XCTAssertEqual((sent?["email"] as? [String: Any])?["note"] as? String, "Welcome!")
        XCTAssertNil(sent?["sms"] ?? nil)

        try await adapter.deleteInvite(ecosystemID: "org.acme.shop", id: "inv-1")
        XCTAssertEqual(stub.requestCount(.delete, "\(base)/invitations/inv-1"), 1)
        XCTAssertEqual(
            stub.lastRequest(.delete, "\(base)/invitations/inv-1")?.path,
            "\(base)/invitations/inv-1?ecosystem=org.acme.shop&workspace=acme"
        )
    }

    func testNotesGetAndSave() async throws {
        stub.on(.get, "\(base)/admin_notes", json: StubClientTransport.list([noteJSON]))
        stub.on(.post, "\(base)/admin_notes", json: #"{"object":"admin_notes","ok":true}"#)
        let notes = try await adapter.notes(ecosystemID: "org.acme.shop", subject: .pendingUsers, subjectID: "pu-1")
        XCTAssertEqual(notes.map(\.id), ["n-1"])
        XCTAssertEqual(
            stub.lastRequest(.get, "\(base)/admin_notes")?.path,
            "\(base)/admin_notes?ecosystem=org.acme.shop&limit=100&subject_id=pu-1"
            + "&subject_table=pending_users&workspace=acme"
        )

        // `InvitationsDataSource.saveNotes` (as landed in Task 11) returns `Void`, not `[AdminNote]` —
        // see task-13-report.md "Deviations from the brief". Assert on the request body only.
        try await adapter.saveNotes(
            ecosystemID: "org.acme.shop", subject: .pendingUsers, subjectID: "pu-1",
            [AdminNoteInput(id: "n-1", content: "Met at the meetup"), AdminNoteInput(content: "Follow up")]
        )
        // The POST carries the subject in its BODY, so only `workspace` belongs in its query.
        XCTAssertEqual(stub.lastRequest(.post, "\(base)/admin_notes")?.path, "\(base)/admin_notes?workspace=acme")
        let body = stub.lastBody(.post, "\(base)/admin_notes")
        XCTAssertEqual(body?["ecosystem"] as? String, "org.acme.shop")
        XCTAssertEqual(body?["subjectTable"] as? String, "pending_users")
        XCTAssertEqual(body?["subjectId"] as? String, "pu-1")
        let sentNotes = body?["notes"] as? [[String: Any]]
        XCTAssertEqual(sentNotes?.count, 2)
        XCTAssertEqual(sentNotes?[0]["id"] as? String, "n-1")
        XCTAssertNil(sentNotes?[1]["id"] ?? nil)
        XCTAssertEqual(sentNotes?[1]["content"] as? String, "Follow up")
    }

    private let historyJSON = #"""
    {"id":"h-1","actor_label":"Mike","actor_id":"u-1","action":"sent an invitation",
      "created":1788220800}
    """#

    func testHistory() async throws {
        stub.on(.get, "\(base)/entity_history", json: StubClientTransport.list([historyJSON]))
        let rows = try await adapter.history(ecosystemID: "org.acme.shop", subject: .invitations, subjectID: "inv-1")
        XCTAssertEqual(rows.first?.actor, "Mike")
        XCTAssertEqual(
            stub.lastRequest(.get, "\(base)/entity_history")?.path,
            "\(base)/entity_history?ecosystem=org.acme.shop&limit=100&subject_id=inv-1"
            + "&subject_table=invitations&workspace=acme"
        )
    }

    func testErrorsMapToHubError() async throws {
        stub.on(.get, "\(base)/invitation_requests", status: 403, json: StubClientTransport.error("nope"))
        do {
            _ = try await adapter.requests(ecosystemID: "org.acme.shop")
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .forbidden)
        }
        XCTAssertEqual(
            stub.lastRequest(.get, "\(base)/invitation_requests")?.path,
            "\(base)/invitation_requests?ecosystem=org.acme.shop&limit=100&workspace=acme"
        )
    }
}
