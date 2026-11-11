import Foundation

/// What File ▸ Open Location… does with the text typed into it: a web
/// address opens in a web browser, a directory in a File Browser window, a
/// file in a File Browser window on its parent with the file showing, and
/// anything else is refused with an alert.
///
/// Pure, apart from asking the file system whether a path exists, so the
/// rules are testable without a window (`separation-of-concerns`).
public enum OpenLocation: Equatable, Sendable {
    case web(URL)
    case directory(URL)
    case file(URL)
    case invalid

    /// - `http://…` / `https://…` → `.web`;
    /// - `file://…`, `~/…`, `/…` → `.directory` or `.file` when it exists,
    ///   else `.invalid`;
    /// - a bare host with a dot and no spaces (`example.com/page`) → `.web`
    ///   over https, as a browser's address field reads it;
    /// - anything else → `.invalid`.
    public static func resolve(_ text: String, fileManager: FileManager = .default) -> OpenLocation {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid }

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() {
            switch scheme {
            case "http", "https":
                guard let host = url.host, !host.isEmpty else { return .invalid }
                return .web(url)
            case "file":
                return existing(path: url.path, fileManager: fileManager)
            default:
                break
            }
        }
        if trimmed.hasPrefix("~") || trimmed.hasPrefix("/") {
            return existing(path: (trimmed as NSString).expandingTildeInPath, fileManager: fileManager)
        }
        if !trimmed.contains(where: \.isWhitespace),
           let host = trimmed.split(separator: "/", maxSplits: 1).first, host.contains("."),
           !host.hasPrefix("."), !host.hasSuffix("."),
           let url = URL(string: "https://\(trimmed)"), url.host != nil {
            return .web(url)
        }
        return .invalid
    }

    private static func existing(path: String, fileManager: FileManager) -> OpenLocation {
        guard !path.isEmpty else { return .invalid }
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else { return .invalid }
        let url = URL(fileURLWithPath: path).standardizedFileURL
        return isDirectory.boolValue ? .directory(url) : .file(url)
    }
}
