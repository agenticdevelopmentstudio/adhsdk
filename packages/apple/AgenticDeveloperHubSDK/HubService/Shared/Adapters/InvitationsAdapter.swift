import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `InvitationsDataSource` over `/v1/invitation_requests`, `/v1/pending_users`, `/v1/invitations`,
/// `/v1/admin_notes` and `/v1/entity_history`, each scoped by `ecosystem` (a query key, or a body field
/// on a POST).
@MainActor
public final class InvitationsAdapter: InvitationsDataSource {
    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    private struct UsersBody: Encodable { let users: [DraftUser] }
    private struct NotesBody: Encodable {
        let ecosystem: String
        let subjectTable: String
        let subjectId: String
        let notes: [AdminNoteInput]
    }

    /// The workspace query plus extra pairs; nil values are dropped.
    private func query(_ extra: [String: String?]) -> [String: String] {
        workspace.query.merging(HubAPI.query(extra)) { _, new in new }
    }

    private func ecosystemQuery(_ ecosystemID: String) -> [String: String] {
        query(["ecosystem": ecosystemID])
    }

    private func subjectQuery(
        _ ecosystemID: String, _ subject: AdminNoteSubject, _ subjectID: String
    ) -> [String: String] {
        query(["ecosystem": ecosystemID, "subject_table": subject.rawValue, "subject_id": subjectID])
    }

    public func requests(ecosystemID: String) async throws -> [InvitationRequest] {
        try await api.list("/v1/invitation_requests", query: ecosystemQuery(ecosystemID), as: InvitationRequest.self)
    }

    public func deleteRequest(ecosystemID: String, id: String) async throws {
        try await api.send(.delete, "/v1/invitation_requests/\(id)", query: ecosystemQuery(ecosystemID))
    }

    public func pendingUsers(ecosystemID: String) async throws -> [PendingUser] {
        try await api.list("/v1/pending_users", query: ecosystemQuery(ecosystemID), as: PendingUser.self)
    }

    public func addPendingUsers(ecosystemID: String, _ users: [DraftUser]) async throws {
        try await api.send(
            .post, "/v1/pending_users", query: workspace.query,
            body: HubAPI.body(UsersBody(users: users), adding: ["ecosystem": ecosystemID])
        )
    }

    public func deletePendingUser(ecosystemID: String, id: String) async throws {
        try await api.send(.delete, "/v1/pending_users/\(id)", query: ecosystemQuery(ecosystemID))
    }

    public func invites(ecosystemID: String) async throws -> [Invite] {
        try await api.list("/v1/invitations", query: ecosystemQuery(ecosystemID), as: Invite.self)
    }

    public func sendInvitation(ecosystemID: String, _ send: InvitationSend) async throws {
        try await api.send(
            .post, "/v1/invitations", query: workspace.query,
            body: HubAPI.body(send, adding: ["ecosystem": ecosystemID])
        )
    }

    public func deleteInvite(ecosystemID: String, id: String) async throws {
        try await api.send(.delete, "/v1/invitations/\(id)", query: ecosystemQuery(ecosystemID))
    }

    public func notes(
        ecosystemID: String, subject: AdminNoteSubject, subjectID: String
    ) async throws -> [AdminNote] {
        try await api.list(
            "/v1/admin_notes", query: subjectQuery(ecosystemID, subject, subjectID), as: AdminNote.self
        )
    }

    /// `/v1` answers `{object, ok}`; callers re-fetch via `notes(...)` for the current list.
    public func saveNotes(
        ecosystemID: String, subject: AdminNoteSubject, subjectID: String, _ notes: [AdminNoteInput]
    ) async throws {
        try await api.send(
            .post, "/v1/admin_notes", query: workspace.query,
            body: NotesBody(ecosystem: ecosystemID, subjectTable: subject.rawValue, subjectId: subjectID, notes: notes)
        )
    }

    public func history(
        ecosystemID: String, subject: AdminNoteSubject, subjectID: String
    ) async throws -> [HistoryEntry] {
        try await api.list(
            "/v1/entity_history", query: subjectQuery(ecosystemID, subject, subjectID), as: HistoryEntry.self
        )
    }
}
