import AgenticToolkitHubService
import AgenticToolkitHub
import Foundation

/// Web URLs for the rows v1 does not implement natively (spec §5.4: Messages).
/// `HubLinks` itself, with `webBase` and `url(path:)`, lives in the sign-in tier.
extension HubLinks {
    public static func workspaceURL(_ workspace: HubWorkspace, path: String) -> URL {
        url(path: "\(workspace.slug)/\(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))")
    }
}
