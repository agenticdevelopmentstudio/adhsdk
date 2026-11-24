import AppKit
import AgenticDeveloperHubSDKCore

/// The icons and colours shared by every tree of folders the app draws, so the
/// File Browser and the Project Browser read as one vocabulary: a folder is
/// the same folder in both, and a project has a code-project icon of its own.
public enum TreeRowStyle {
    public static let folderSymbol = "folder.fill"
    public static let codeProjectSymbol = "curlybraces.square.fill"

    public static func folderColor(_ palette: SemanticPalette) -> NSColor {
        palette.nsColor(.accent)
    }

    public static func codeProjectColor(_ palette: SemanticPalette) -> NSColor {
        palette.nsColor(.warning)
    }
}
