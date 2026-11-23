#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

extension Notification.Name {
    /// Posted by every ``BrowserHistoryStoring``, with the store as its
    /// object, after each write it committed. Global so a reader that does not
    /// hold the store hears whichever one is in use.
    public static let browserHistoryDidChange = Notification.Name("BrowserHistoryStore.didChange")

    /// Posted by every ``BrowserHiddenItemsStoring``, with the store as its
    /// object, after each add, enable or disable, remove and site-switch
    /// change it committed. Global so a pane that does not hold the store
    /// (its privacy refresh) hears whichever one is in use.
    public static let browserHiddenItemsDidChange = Notification.Name("BrowserHiddenItemsStore.didChange")
}

/// The change stream a browser store hands out: one element per `name`
/// posted with `object`, in the order they were posted, for as long as the
/// stream is iterated. Shared by the local stores and the daemon's adapters,
/// which post the same names, so the two kinds of store cannot disagree on
/// what a change is (`dry`).
public enum BrowserStoreChanges {
    public static func stream(of name: Notification.Name, from object: AnyObject) -> AsyncStream<Void> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            let token = NotificationCenter.default.addObserver(
                forName: name, object: object, queue: nil
            ) { _ in
                continuation.yield()
            }
            let observer = ObserverToken(token)
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer.token)
            }
        }
    }

    /// The observer token, carried into the termination handler.
    private final class ObserverToken: @unchecked Sendable {
        let token: NSObjectProtocol
        init(_ token: NSObjectProtocol) { self.token = token }
    }
}
#endif
