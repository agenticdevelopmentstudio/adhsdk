#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

/// The browser history as its consumers see it: the panes that record
/// visits, the History window, the agent's history tool.
///
/// `BrowserHistoryStore` (the app's own SQLite file) conforms, and so does
/// the daemon's adapter in `ADHDClientMacOS`, so an app can keep its history
/// in either without a consumer knowing which (`dependency-injection`). Every
/// method is async because both answer off the caller's thread: a WAL commit
/// or a round trip to the daemon.
///
/// After every committed write a conformer posts
/// `Notification.Name.browserHistoryDidChange` with itself as the object, and
/// ``changes`` yields once for each.
public protocol BrowserHistoryStoring: AnyObject, Sendable {
    /// Records a visit and returns its id, so a title that arrives after the
    /// load can be filed against the right row.
    @discardableResult
    func record(_ url: URL, title: String, at date: Date) async throws -> Int64
    func updateTitle(ofVisit id: Int64, to title: String) async throws
    func remove(visit id: Int64) async throws
    /// Forgets every visit before `cutoff`.
    func removeVisits(before cutoff: Date) async throws
    func removeAll() async throws
    /// The latest visits, newest first, `limit` of them; `before` starts the
    /// page after that visit (keyset paging), and `excludingLocalFiles` leaves
    /// out `file:` visits before the limit is applied.
    func recent(limit: Int, before: BrowserVisit?, excludingLocalFiles: Bool) async throws -> [BrowserVisit]
    /// Visits whose address or title contains `text`, newest first.
    func search(_ text: String, limit: Int, excludingLocalFiles: Bool) async throws -> [BrowserVisit]
    func count() async throws -> Int
    /// One element per committed write, for as long as it is iterated.
    var changes: AsyncStream<Void> { get }
}

extension BrowserHistoryStoring {
    public var changes: AsyncStream<Void> {
        BrowserStoreChanges.stream(of: .browserHistoryDidChange, from: self)
    }
}
#endif
