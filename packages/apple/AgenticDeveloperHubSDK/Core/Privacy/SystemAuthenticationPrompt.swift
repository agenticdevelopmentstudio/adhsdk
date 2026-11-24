import Foundation

/// Whether the system's authentication prompt (Touch ID, or the account
/// password) is up on the app's behalf.
///
/// The prompt is a window of the system's, not the app's, so while one of the
/// app's windows runs app-modal the prompt opens behind it and cannot be
/// answered — the modal window is the only one that takes clicks or keys. A
/// caller that asks for authentication brackets the request with ``begin()``
/// and ``end()``; an app-modal session (`AppModalWindowSession`) steps aside
/// while ``isShowing`` and comes back when it is not. Whoever asked — the
/// settings window's Edit Privacy Words, a private terminal being shown, the
/// one-off upgrade of the words' storage — need not know a modal window is
/// up.
@MainActor
public enum SystemAuthenticationPrompt {

    /// Posted on the main actor when ``isShowing`` changes.
    public static let didChangeNotification = Notification.Name("SystemAuthenticationPrompt.didChange")

    private static var depth = 0

    /// Whether at least one prompt is up.
    public static var isShowing: Bool { depth > 0 }

    /// A prompt is about to be shown.
    public static func begin() {
        depth += 1
        if depth == 1 { NotificationCenter.default.post(name: didChangeNotification, object: nil) }
    }

    /// A prompt begun with ``begin()`` has been answered or dismissed.
    public static func end() {
        guard depth > 0 else { return }
        depth -= 1
        if depth == 0 { NotificationCenter.default.post(name: didChangeNotification, object: nil) }
    }
}
