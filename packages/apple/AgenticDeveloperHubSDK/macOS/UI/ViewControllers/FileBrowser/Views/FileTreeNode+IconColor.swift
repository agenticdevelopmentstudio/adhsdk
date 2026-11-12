import AppKit
import AgenticDeveloperHubSDKCore

extension FileTreeNode {

    /// The tint the file tree draws this node's icon in, shared with every
    /// other place that shows the same icon (the breadcrumb and its menus), so
    /// a file looks the same wherever it appears (`dry`).
    func iconColor(palette: SemanticPalette) -> NSColor {
        if isPackage { return palette.nsColor(.warning) }
        if isDirectory {
            return palette.nsColor(name == ".claude" ? .info : .accent)
        }
        switch url.pathExtension.lowercased() {
        case "swift", "json":
            return palette.nsColor(.warning)
        case "md", "markdown":
            return palette.nsColor(.accent)
        default:
            return palette.nsColor(.secondaryText)
        }
    }
}
