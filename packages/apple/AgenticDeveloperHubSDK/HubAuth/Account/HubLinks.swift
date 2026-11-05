import Foundation

/// Web URLs on the hub's site. The workspace-scoped form,
/// `HubLinks.workspaceURL(_:path:)`, is the hub UI's extension of this.
public enum HubLinks {
    public static let webBase: URL = {
        guard let url = URL(string: "https://agenticdeveloperhub.com") else { preconditionFailure("static URL") }
        return url
    }()

    public static func url(path: String) -> URL {
        webBase.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}
