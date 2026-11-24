import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

public protocol WorkspacesProviding: Sendable {
    func listWorkspaces() async throws -> [HubWorkspace]
    func preferredSlug() async throws -> String?
    func setPreferredSlug(_ slug: String) async throws
}

/// `GET /v1/workspaces`, and the preferred workspace as the account's `workspace_prefs`
/// sub-resource (`GET /v1/account?include[]=workspace_prefs`, `POST /v1/account`), all through the
/// generated client (spec §7.2). Errors surface as `HubError`.
@MainActor
public final class WorkspacesAdapter: WorkspacesProviding {
    private let environment: HubEnvironment

    public init(environment: HubEnvironment) {
        self.environment = environment
    }

    /// One page of the widest size. Workspaces carry no `id`, so `/v1` cannot page past it; more than
    /// 100 throws rather than hiding the rest.
    public func listWorkspaces() async throws -> [HubWorkspace] {
        do {
            let query = Operations.GetV1Workspaces.Input.Query(limit: HubAPI.pageLimit)
            switch try await environment.client.api.getV1Workspaces(.init(query: query)) {
            case .ok(let response):
                let page = try response.body.json
                if page.hasMore {
                    throw HubError.unexpected("More than \(HubAPI.pageLimit) workspaces; /v1 cannot page them")
                }
                return page.data.map { row in
                    let generated = row.value2
                    return HubWorkspace(
                        slug: generated.slug,
                        name: generated.name,
                        type: HubWorkspaceType(rawValue: generated._type.rawValue) ?? .individual
                    )
                }
            case .badRequest(let response):
                throw HubError.v1(400, try response.body.json)
            case .unauthorized:
                throw HubError.unauthorized
            case .undocumented(let status, _):
                throw HubError.fromStatus(status, body: Data())
            }
        } catch {
            throw HubError.from(error)
        }
    }

    public func preferredSlug() async throws -> String? {
        do {
            let query = Operations.GetV1Account.Input.Query(include_lbrack__rbrack_: [.workspacePrefs])
            switch try await environment.client.api.getV1Account(.init(query: query)) {
            case .ok(let response):
                let slug = try response.body.json.value2.workspacePrefs?.prefs.slug
                return (slug?.isEmpty ?? true) ? nil : slug
            case .badRequest(let response):
                throw HubError.v1(400, try response.body.json)
            case .unauthorized:
                throw HubError.unauthorized
            case .notFound:
                throw HubError.notFound
            case .undocumented(let status, _):
                throw HubError.fromStatus(status, body: Data())
            }
        } catch {
            throw HubError.from(error)
        }
    }

    public func setPreferredSlug(_ slug: String) async throws {
        do {
            let body = Operations.PostV1Account.Input.Body.JsonPayload(
                value1: .init(),
                value2: .init(workspacePrefs: .init(slug: slug))
            )
            switch try await environment.client.api.postV1Account(body: .json(body)) {
            case .ok:
                return
            case .badRequest(let response):
                throw HubError.v1(400, try response.body.json)
            case .unauthorized:
                throw HubError.unauthorized
            case .notFound:
                throw HubError.notFound
            case .conflict(let response):
                throw HubError.v1(409, try response.body.json)
            case .undocumented(let status, _):
                throw HubError.fromStatus(status, body: Data())
            }
        } catch {
            throw HubError.from(error)
        }
    }
}
