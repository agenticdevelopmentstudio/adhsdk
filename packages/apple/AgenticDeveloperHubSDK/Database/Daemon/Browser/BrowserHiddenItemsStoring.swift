#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

/// The user's and the agent's hidden-item lists and the user list's per-site
/// switch, as their consumers see them: the panes that apply them, the
/// selecting mode and popover that edit them, the agent's page reader that
/// leaves them out.
///
/// `BrowserHiddenItemsStore` (the app's own SQLite file) conforms, and so
/// does the daemon's adapter in `ADHDClientMacOS`; the one a host uses is
/// `BrowserHiddenItemsStore.current` (`dependency-injection`). Every method is
/// async because both answer off the caller's thread.
///
/// After every committed change a conformer posts
/// `Notification.Name.browserHiddenItemsDidChange` with itself as the object,
/// and ``changes`` yields once for each.
public protocol BrowserHiddenItemsStoring: AnyObject, Sendable {
    /// Every entry of `list` whose site matches `url`, enabled and disabled
    /// alike, oldest first. A nil `url` is a place with no address, which
    /// only `*` matches.
    func items(list: BrowserHiddenItemList, for url: URL?) async throws -> [BrowserHiddenItem]
    /// Every entry of `list`, on every site, oldest first.
    func allItems(list: BrowserHiddenItemList) async throws -> [BrowserHiddenItem]
    /// The selectors of `list`'s enabled entries that match `url`; for the
    /// user list, without the sites whose switch is off.
    func enabledSelectors(list: BrowserHiddenItemList, for url: URL?) async throws -> [String]
    /// Whether `list`'s switch for `site` is on; on when never set.
    func isSiteSwitchOn(list: BrowserHiddenItemList, site: String) async throws -> Bool
    /// Stores `item` and returns it with its assigned id. Refuses an empty
    /// selector (`BrowserHiddenItemsStoreError.emptySelector`).
    @discardableResult
    func add(_ item: BrowserHiddenItem) async throws -> BrowserHiddenItem
    func setEnabled(_ id: Int64, _ isOn: Bool) async throws
    func remove(_ id: Int64) async throws
    func setSiteSwitch(list: BrowserHiddenItemList, site: String, on isOn: Bool) async throws
    /// One element per committed change, for as long as it is iterated.
    var changes: AsyncStream<Void> { get }
}

extension BrowserHiddenItemsStoring {
    public var changes: AsyncStream<Void> {
        BrowserStoreChanges.stream(of: .browserHiddenItemsDidChange, from: self)
    }
}
#endif
