import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `MessagingDataSource` over `/v1/messaging/…`, scoped by `ecosystem` (a query key, or a body field on a
/// send). A failed send is HTTP 422. The legacy route answered it with a `MessagingSendResult`, but the
/// `/v1` gateway rewrites every error to `{error:{type, message}}`, so the provider's message is all that
/// survives: it is returned as a failed result (not thrown) so the topic can show the provider error.
@MainActor
public final class MessagingAdapter: MessagingDataSource {
    private let api: HubAPI
    private let environment: HubEnvironment
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.environment = environment
        self.workspace = workspace
    }

    private func query(_ ecosystemID: String, _ extra: [String: String] = [:]) -> [String: String] {
        workspace.query.merging(extra.merging(["ecosystem": ecosystemID]) { _, new in new }) { _, new in new }
    }

    public func status(ecosystemID: String) async throws -> MessagingStatus {
        try await api.get("/v1/messaging/status", query: query(ecosystemID), as: MessagingStatus.self)
    }

    public func templates() async throws -> [MessagingTemplate] {
        try await api.list("/v1/messaging/templates", query: workspace.query, as: MessagingTemplate.self)
    }

    public func log(ecosystemID: String, limit: Int, startingAfter: String?) async throws -> MessagingLogPage {
        let paging = HubAPI.query(["limit": String(limit), "starting_after": startingAfter])
        let page = try await api.get(
            "/v1/messaging/messages", query: query(ecosystemID, paging), as: HubAPI.ListPage<MessagingLogEntry>.self
        )
        return MessagingLogPage(items: page.data, hasMore: page.hasMore)
    }

    public func send(ecosystemID: String, _ message: MessagingSend) async throws -> MessagingSendResult {
        let sendPath = "/v1/messaging/messages"
        let body: Data
        do {
            body = try HubAPI.encoder.encode(HubAPI.body(message, adding: ["ecosystem": ecosystemID]))
        } catch {
            throw HubError.unexpected("Unencodable request for POST \(sendPath): \(error)")
        }
        do {
            let response = try await environment.client.rawJSON(
                method: .post, path: sendPath, query: workspace.query, body: body
            )
            return try HubAPI.decode(MessagingSendResult.self, from: response.body)
        } catch RawRequestError.http(let status, let data) where status == 422 {
            // The provider refused the message: a result to show, not a validation problem.
            let reason = HubError.message(fromBody: data, fallback: "The provider refused the message.")
            return MessagingSendResult(status: "failed", error: reason)
        } catch let error as DecodingError {
            throw HubError.unexpected("Unreadable response for POST \(sendPath): \(error)")
        } catch {
            throw HubError.from(error)
        }
    }
}
