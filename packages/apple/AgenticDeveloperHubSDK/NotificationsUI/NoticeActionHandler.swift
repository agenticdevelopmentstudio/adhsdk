import Foundation
import AgenticDeveloperHubSDKNotifications

/// How the presentation center talks back to its host. The center decides what
/// is on screen; everything that changes a notice's stored state goes through
/// here, so the center never knows how the host stores or transports notices
/// (Rooster implements it over XPC; another app might call a server).
@MainActor
public protocol NoticeActionHandler: AnyObject {
    /// Record a new lifecycle state (`read`, `archived`, …) for the notice.
    func setState(_ id: String, _ state: Notice.Lifecycle)
    /// Snooze the notice until the given time.
    func snooze(_ id: String, until: Date)
    /// Tell the poster the user chose `actionID`, with the reply text if any.
    func respond(_ id: String, actionID: String, text: String?)
    /// Open a URL an action carried.
    func openURL(_ url: URL)
    /// Bring up the host's notice history.
    func showHistory()
    /// Send a sample notice through the host's real path (settings "Send test").
    func sendTest(_ notice: Notice)
}
