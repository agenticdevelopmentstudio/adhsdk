// The mail vocabulary's own names (to, cc, ok) are shorter than the
// identifier_name minimum; renaming them would read worse than the rule.
// swiftlint:disable identifier_name
import Foundation
import AgenticDeveloperHubClient

/// What the hub answered for one send.
public struct HubMailSendResult: Sendable, Equatable {
    public let ok: Bool
    /// The provider's id for the sent message (Gmail's message id).
    public let externalId: String?
    /// True when the hub recognised a repeat of an earlier send and did not send again.
    public let deduped: Bool
    public let error: String?

    public init(ok: Bool, externalId: String?, deduped: Bool, error: String?) {
        self.ok = ok
        self.externalId = externalId
        self.deduped = deduped
        self.error = error
    }
}

public enum HubMailSendError: Error, Equatable, Sendable {
    /// The hub answered with a status other than 200.
    case rejected(statusCode: Int)
}

/// Sends mail through the hub's `send` integration action, so the hub's worker
/// talks to Gmail and the app never does.
public struct HubMailSender: Sendable {

    public typealias API = AgenticDeveloperHubClient.APIProtocol
    typealias Operation = AgenticDeveloperHubClient.Operations.PostV1IntegrationsConnectionsByIdActionsByActionType

    private let client: any API

    public init(client: any API) {
        self.client = client
    }

    public func send(
        connectionId: String, to: [String], cc: [String]? = nil, bcc: [String]? = nil,
        subject: String, bodyText: String? = nil, bodyHtml: String? = nil
    ) async throws -> HubMailSendResult {
        let request = AgenticDeveloperHubClient.Components.Schemas.IntegrationActionRequest.case1(.init(
            to: to, cc: cc, bcc: bcc, subject: subject, bodyText: bodyText, bodyHtml: bodyHtml
        ))
        let output = try await client.postV1IntegrationsConnectionsByIdActionsByActionType(Operation.Input(
            path: .init(id: connectionId, actionType: "send"),
            body: .json(request)
        ))
        guard case .ok(let ok) = output else {
            throw HubMailSendError.rejected(statusCode: Self.statusCode(of: output))
        }
        let result = try ok.body.json.value2
        return HubMailSendResult(
            ok: result.ok, externalId: result.externalId, deduped: result.deduped, error: result.error
        )
    }

    static func statusCode(of output: Operation.Output) -> Int {
        switch output {
        case .ok: return 200
        case .badRequest: return 400
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .conflict: return 409
        case .unprocessableContent: return 422
        case .serviceUnavailable: return 503
        case .undocumented(let statusCode, _): return statusCode
        }
    }
}
// swiftlint:enable identifier_name
