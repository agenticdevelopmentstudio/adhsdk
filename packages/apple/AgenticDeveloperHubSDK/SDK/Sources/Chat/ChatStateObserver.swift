import Foundation

/// `@MainActor` for the same reason as `ChatViewModel`, which posts to it:
/// an observer's job is to update a view, and the updates it receives are
/// produced on the main actor.
@MainActor
public protocol ChatStateObserver: AnyObject, Sendable {
    func chatDidUpdate(_ update: ChatUpdate)
}
