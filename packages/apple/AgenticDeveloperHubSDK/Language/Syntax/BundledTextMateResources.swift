import Foundation
import os
import AgenticDeveloperHubSDKCore

/// The TextMate resources an app bundle carries in `Contents/Resources/TextMate/`
/// — the one place the lookup in a bundle lives, so every app that
/// highlights code finds its directory the same way.
public enum BundledTextMateResources {

    /// The folder's name inside the bundle's resources.
    public static let folderName = "TextMate"

    /// The bundle's TextMate directory, or nil — logged — when the bundle has
    /// no such folder or the folder lacks a required file.
    public static func load(from bundle: Bundle) -> TextMateResources? {
        guard let directory = bundle.resourceURL?.appendingPathComponent(folderName, isDirectory: true) else {
            return nil
        }
        do {
            return try TextMateResources(directory: directory)
        } catch {
            logger.error("No bundled TextMate resources: \(String(describing: error), privacy: .public)")
            return nil
        }
    }
}

extension BundledTextMateResources: Loggable {
    public static nonisolated let logger = makeLogger()
}
