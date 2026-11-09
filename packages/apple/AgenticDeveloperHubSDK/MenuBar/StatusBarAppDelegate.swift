import AppKit
import Foundation
import AgenticDeveloperHubSDKCore

/// Generic status-bar app driver. Polls a daemon's `/health` on a timer,
/// assembles a menu via ``MenuComposer``, and keeps an `NSStatusItem`
/// up-to-date.
///
/// The delegate knows nothing about how the daemon is reached: the host hands
/// it a `healthProbe` (``DaemonHealthProbe/http(baseURL:timeout:)`` for the
/// usual loopback HTTP) and providers that close over whatever client they need.
///
/// Typical `main.swift`:
///
///     let delegate = StatusBarAppDelegate(
///         healthProbe: DaemonHealthProbe.http(baseURL: "http://127.0.0.1:22847"),
///         menuIcon: "⚙",
///         composer: MenuComposer(sections: [
///             HealthMenuSection(daemonName: "mydaemon"),
///             TimingStrategyMenuSection(onTrigger: { /* XPC call */ }),
///             ControlsMenuSection(onQuit: { NSApp.terminate(nil) })
///         ])
///     )
///     let app = NSApplication.shared
///     app.delegate = delegate
///     app.setActivationPolicy(.accessory)
///     app.run()
@MainActor
public final class StatusBarAppDelegate: NSObject, NSApplicationDelegate {
    private let healthProbe: @Sendable () async -> Data?
    private let composer: MenuComposer
    private let menuIcon: String
    /// The status item's image, `nil` for a text `menuIcon` instead.
    ///
    /// Settable after launch so the host app can swap the ink when the menu bar's
    /// appearance changes — a green olylo on a dark bar, a template on a light
    /// one. The new image is pushed through ``applyIconState`` rather than
    /// straight onto the button, so the unreachable/alert/count badges are laid
    /// out over it again exactly as they would be on a normal refresh.
    public var menuImage: NSImage? {
        didSet {
            if let state = lastIconState {
                // The `==` guard in `applyIconState` would swallow a redraw the
                // state didn't change and the ink did — so clear the memo and
                // re-apply the same state, badges and all.
                lastIconState = nil
                applyIconState(state)
                return
            }
            // No state applied yet, which is not only the moment before launch:
            // `lastIconState` is also cleared on a screen reconfigure and on
            // waking from sleep. Returning outright dropped the ink in exactly
            // those windows, and since the host app changes `menuImage` when the
            // *menu bar's appearance* changes, what it dropped was a green icon
            // left on a light bar until the refresh timer next came round. The
            // badges are `applyIconState`'s to lay out and the next poll will;
            // the image is this property's, so put it on now — if there is a
            // button yet. Before launch there is not, and
            // `applicationDidFinishLaunching` reads whatever is current.
            guard let button = statusItem?.button else { return }
            button.image = menuImage
            button.title = menuImage == nil ? menuIcon : ""
        }
    }
    private let refreshInterval: TimeInterval
    private let userInfoProvider: (@Sendable () async -> [String: any Sendable])?
    /// ``userInfoProvider`` with the poll's context: whether this refresh's
    /// `/health` probe answered and whether the menu is open. A host whose
    /// user info costs a request of its own uses it to skip that request when
    /// nobody can see the result — the menu closed — or when it cannot
    /// succeed — the daemon did not answer `/health` — and hand back what it
    /// last had. Opening the menu refreshes at once (``menuWillOpen(_:)``), so
    /// a closed-menu skip never shows stale data for longer than that poll.
    /// When set, it is used instead of `userInfoProvider`.
    private let pollingUserInfoProvider: (@Sendable (MenuPoll) async -> [String: any Sendable])?
    /// Whether the status item's menu is on screen, tracked through the
    /// `NSMenuDelegate` this class installs on every menu it builds.
    private(set) var menuIsOpen = false
    /// Optional async check, run each refresh, for an alert condition (e.g.
    /// ingestion errors). When it returns true and the daemon is reachable, the
    /// status item shows a red alert badge.
    private let alertProvider: (@Sendable () async -> Bool)?
    /// Optional async count (e.g. number of active sites), run each refresh and
    /// rendered as a green numeric badge in the corner ``badgeLayout`` names
    /// (top right by default). A count of 0 hides the badge.
    private let countProvider: (@Sendable () async -> Int)?

    private var statusItem: NSStatusItem?

    /// Which corner of the status item each badge sits in. Settable after
    /// launch: the badge views are torn down and laid out again in their new
    /// corners at the state already showing.
    public var badgeLayout: MenuBarBadgeLayout {
        didSet {
            guard badgeLayout != oldValue else { return }
            for slot in [unreachableBadge, alertBadge, countBadge] { slot?.removeFromSuperview() }
            unreachableBadge = nil
            alertBadge = nil
            countBadge = nil
            // Same reason as `menuImage`: the state has not moved, so the `==`
            // guard in `applyIconState` would swallow the re-layout.
            if let state = lastIconState {
                lastIconState = nil
                applyIconState(state)
            }
        }
    }

    private var timer: Timer?
    private var unreachableBadge: NSImageView?
    private var alertBadge: NSImageView?
    private var countBadge: NSImageView?

    /// The last icon state actually applied to the button. Redrawing the status
    /// item is expensive — every write to `button.title`/`.image`/a badge marks it
    /// needing display, and on a multi-display setup AppKit then re-renders the
    /// item's replicant snapshot for every additional menu bar. We keep the
    /// last state and only touch the button when it changes (see ``applyIconState``).
    private var lastIconState: IconState?
    /// Signature of the last snapshot the menu was built from. The menu is rebuilt
    /// only when the snapshot actually changes, so an unchanged poll no longer
    /// allocates a fresh NSMenu tree every refresh (it captures every input a section
    /// renders — isReachable/health/userInfo — but not `now`, which no section reads).
    private var lastMenuSignature: String?
    /// Bumped each refresh. A refresh Task that finishes after a newer refresh has
    /// started is stale, and applies nothing — otherwise a slow poll landing after a
    /// fast one would write an older state over the current one (icon flicker / a
    /// wrong value cached until the next change).
    private var refreshGeneration = 0
    /// Consecutive `/health` polls that returned nothing, since the last success.
    /// Reachability is DEBOUNCED on this: a slow/timed-out poll — routine when the
    /// machine is under load — must NOT flip the badge, because every flip forces an
    /// expensive status-item redraw (on multi-display setups AppKit re-renders the
    /// item's replicant snapshot for every menu bar). See ``debouncedReachability``.
    private var consecutiveHealthMisses = 0
    /// Whether `/health` has EVER succeeded. Until the first success there is no
    /// last-known-good state to debounce against, so a miss reads as unreachable
    /// immediately — a daemon that's down when the app launches isn't shown as up.
    private var hasBeenReachable = false
    /// Consecutive failed polls before the badge shows "unreachable". Derived (in
    /// `init`) from a TIME budget (``unreachableGrace``) and the caller's
    /// `refreshInterval`, so the debounce WINDOW is ~constant regardless of how often a
    /// consumer polls — a raw poll count would mean wildly different durations at
    /// different intervals.
    private let unreachableThreshold: Int
    /// Seconds of sustained `/health` failure before the badge shows "unreachable" —
    /// long enough to ride out a transient load spike, short enough to reflect a real
    /// outage promptly. Converted to a poll count in `init` via `refreshInterval`.
    private static let unreachableGrace: TimeInterval = 15
    /// Observers that drop the caches when the OS may have reset the status item out
    /// from under us (display reconfigure, wake) — see applicationDidFinishLaunching.
    private var invalidationObservers: [NSObjectProtocol] = []
    #if DEBUG
    /// Count of icon redraws actually performed (state-changing refreshes). Test-only
    /// observability — compiled out of release; the running app never reads it.
    private(set) var iconRedraws = 0
    #endif

    public init(
        healthProbe: @escaping @Sendable () async -> Data?,
        composer: MenuComposer,
        menuIcon: String = "⚙",
        menuImage: NSImage? = nil,
        refreshInterval: TimeInterval = 5,
        userInfoProvider: (@Sendable () async -> [String: any Sendable])? = nil,
        alertProvider: (@Sendable () async -> Bool)? = nil,
        countProvider: (@Sendable () async -> Int)? = nil,
        pollingUserInfoProvider: (@Sendable (MenuPoll) async -> [String: any Sendable])? = nil,
        badgeLayout: MenuBarBadgeLayout = .standard
    ) {
        self.healthProbe = healthProbe
        self.badgeLayout = badgeLayout
        self.composer = composer
        self.menuIcon = menuIcon
        self.menuImage = menuImage
        self.refreshInterval = refreshInterval
        // Debounce window as a poll count derived from the time budget and THIS
        // consumer's interval, so ~unreachableGrace holds whatever the interval is.
        let interval = refreshInterval > 0 ? refreshInterval : 5
        self.unreachableThreshold = max(1, Int((Self.unreachableGrace / interval).rounded()))
        self.userInfoProvider = userInfoProvider
        self.alertProvider = alertProvider
        self.countProvider = countProvider
        self.pollingUserInfoProvider = pollingUserInfoProvider
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let menuImage {
            item.button?.image = menuImage
        } else {
            item.button?.title = menuIcon
        }
        self.statusItem = item
        install(composer.build(snapshot: MenuSnapshot(isReachable: false)))

        refresh()

        let timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)

        // Redrawing is now conditional (applyIconState / the menu-signature gate), so
        // if the OS resets the status item out from under us — a display reconfigure
        // or a wake from sleep can drop the button's title/subviews — nothing would
        // repaint it until the daemon's state next changed. Drop the caches on those
        // events so the next poll repaints ONCE (not the old per-poll storm).
        let invalidate: @Sendable (Notification) -> Void = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.lastIconState = nil
                self?.lastMenuSignature = nil
                self?.consecutiveHealthMisses = 0   // fresh debounce window after wake/reconfigure
            }
        }
        let center = NotificationCenter.default
        invalidationObservers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main, using: invalidate))
        invalidationObservers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main, using: invalidate))
    }

    public func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
        for token in invalidationObservers {
            NotificationCenter.default.removeObserver(token)
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        invalidationObservers.removeAll()
    }

    /// Force a refresh. Safe to call from tests via a direct-constructed
    /// delegate (without launching the app).
    ///
    /// Reachability is whether `/health` returned any response (HTTP 200) —
    /// not whether the body decodes into ``DaemonHealthReport`` (some daemons emit a
    /// different health schema and should still show reachable when their HTTP
    /// server responds) — DEBOUNCED over `unreachableThreshold` consecutive polls
    /// so a single slow or timed-out poll under load doesn't flip the badge and
    /// trigger a costly wide-display redraw (see ``consecutiveHealthMisses``).
    public func refresh() {
        let healthProbe = self.healthProbe
        let composer = self.composer
        let userInfoProvider = self.userInfoProvider
        let pollingUserInfoProvider = self.pollingUserInfoProvider
        let menuIsOpen = self.menuIsOpen
        let alertProvider = self.alertProvider
        let countProvider = self.countProvider
        refreshGeneration += 1
        let generation = refreshGeneration
        Task { [weak self] in
            let healthData = await healthProbe()
            let probeSucceeded = healthData != nil
            let health = healthData.flatMap(DaemonHealthReport.decode)
            let userInfo: [String: any Sendable]
            if let pollingUserInfoProvider {
                userInfo = await pollingUserInfoProvider(
                    MenuPoll(probeSucceeded: probeSucceeded, menuIsOpen: menuIsOpen))
            } else {
                userInfo = await userInfoProvider?() ?? [:]
            }
            let hasAlert = await alertProvider?() ?? false
            let count = await countProvider?() ?? 0
            await MainActor.run { [weak self] in
                // Drop a result that raced a newer refresh (out-of-order completion),
                // so an older state never overwrites the current one.
                guard let self, generation == self.refreshGeneration else { return }
                // Fold this poll into the debounced reachability (updated after the
                // generation guard so only the latest in-order result moves the counter).
                let isReachable = self.debouncedReachability(probeSucceeded: probeSucceeded)
                // A miss that's still being debounced (isReachable stayed true even
                // though this poll failed) means the machine is loaded and THIS poll's
                // health/count/alert are all suspect — so repaint nothing, keeping the
                // last icon and menu, rather than redrawing from data we don't trust.
                // That's what stops a flapping `count` or `health` from re-triggering
                // the very redraw the debounce exists to prevent. A successful poll or a
                // confirmed outage (isReachable flipped false) carries reliable state and
                // is applied; so is a first paint / post-wake repaint, when there's no
                // cached icon to keep (lastIconState == nil).
                guard probeSucceeded || !isReachable || self.lastIconState == nil else { return }
                let snapshot = MenuSnapshot(
                    isReachable: isReachable,
                    health: health,
                    userInfo: userInfo
                )
                let signature = Self.menuSignature(snapshot)
                if signature != self.lastMenuSignature {
                    self.lastMenuSignature = signature
                    self.install(composer.build(snapshot: snapshot))
                }
                self.applyIconState(
                    IconState(isReachable: isReachable, hasAlert: hasAlert, count: count))
            }
        }
    }

    /// Put a freshly built menu in front of the user. While the menu is open,
    /// assigning `statusItem.menu` would change nothing on screen — AppKit
    /// keeps tracking the menu it opened — so the new items move into the
    /// open menu instead, which is what lets the refresh ``menuWillOpen(_:)``
    /// starts land while the user is looking.
    private func install(_ built: NSMenu) {
        if menuIsOpen, let open = statusItem?.menu {
            Self.moveItems(from: built, into: open)
            return
        }
        built.delegate = self
        statusItem?.menu = built
    }

    /// Replace `menu`'s items with `built`'s. An `NSMenuItem` belongs to one
    /// menu at a time, so each is taken out of `built` before it is added.
    /// Not private, so AgenticDeveloperHubSDKMenuBarTests can drive it without a status item.
    static func moveItems(from built: NSMenu, into menu: NSMenu) {
        let items = built.items
        built.removeAllItems()
        menu.autoenablesItems = built.autoenablesItems
        menu.removeAllItems()
        for item in items { menu.addItem(item) }
    }

    /// A stable string of everything the menu is built from, so an unchanged snapshot
    /// skips the rebuild. Keys are sorted (a dictionary's own description is
    /// order-unstable) and values stringified; `now` is excluded because no section
    /// renders it. A spurious "changed" only costs a redundant rebuild — this never
    /// reports "unchanged" for a real change, since it hashes every rendered input.
    static func menuSignature(_ snapshot: MenuSnapshot) -> String {
        let info = snapshot.userInfo.keys.sorted()
            .map { "\($0)=\(String(describing: snapshot.userInfo[$0]!))" }
            .joined(separator: ",")
        return "\(snapshot.isReachable)|\(String(describing: snapshot.health))|\(info)"
    }

    /// Everything the status-item's appearance depends on. Two equal states render
    /// identically, so an unchanged state needs no redraw.
    struct IconState: Equatable {
        let isReachable: Bool
        let hasAlert: Bool
        let count: Int
    }

    /// Fold a raw `/health` probe result into the debounced reachability the badge
    /// shows, updating the miss counter. A success resets the counter and marks us
    /// reachable. A miss counts up; while the run of misses stays below
    /// ``unreachableThreshold`` (and we've been reachable at least once) the last
    /// reachable state holds — riding out a transient slow poll so the badge doesn't
    /// flip (and force a costly redraw) on every blip. Before the first success there
    /// is nothing to debounce against, so a miss is unreachable at once (no false "up"
    /// for a daemon that's down at launch). Not private, so AgenticDeveloperHubSDKMenuBarTests drive it.
    func debouncedReachability(probeSucceeded: Bool) -> Bool {
        if probeSucceeded {
            consecutiveHealthMisses = 0
            hasBeenReachable = true
            return true
        }
        consecutiveHealthMisses += 1
        guard hasBeenReachable else { return false }
        return consecutiveHealthMisses < unreachableThreshold
    }

    /// Redraw the status item only when `new` differs from the last applied state.
    /// The refresh timer fires every few seconds and the state is usually identical
    /// between polls (nothing changed); re-applying it would re-trigger AppKit's
    /// costly status-item redraw (replicant re-snapshot per additional display) for
    /// no visible change. Idempotent by the `==` guard.
    func applyIconState(_ new: IconState) {
        guard new != lastIconState else { return }
        lastIconState = new
        #if DEBUG
        iconRedraws += 1
        #endif
        updateIcon(isReachable: new.isReachable, hasAlert: new.hasAlert, count: new.count)
    }

    private func updateIcon(isReachable: Bool, hasAlert: Bool, count: Int = 0) {
        guard let button = statusItem?.button else { return }
        guard menuImage != nil else {
            button.title = isReachable ? menuIcon : "●"
            return
        }
        button.image = menuImage
        button.title = ""
        let badge = MenuBarBadge.resolve(isReachable: isReachable, hasAlert: hasAlert)
        setBadge(
            &unreachableBadge, on: button, visible: badge == .unreachable,
            tint: .systemYellow, accessibility: "daemon unreachable"
        )
        setBadge(
            &alertBadge, on: button, visible: badge == .alert,
            tint: .systemRed, accessibility: "ingestion errors"
        )
        updateCountBadge(on: button, count: count)
    }

    /// Show or hide a small green numeric badge in the ``badgeLayout`` count
    /// corner of the status item button — e.g. the number of active sites. Lazily created and retained in
    /// `countBadge`; hidden (not removed) when the count is 0.
    ///
    /// The badge is an `NSImageView` showing a pre-rendered image — NEVER a live
    /// text view. On macOS 26 a text-drawing subview (`NSTextField`) inside an
    /// `NSStatusBarButton` re-dirties itself while the status item's replicant
    /// snapshot is rendered (the copies shown on additional displays' menu bars),
    /// locking AppKit into an endless re-snapshot loop that pins most of a core
    /// for the app's whole lifetime. `NSImageView` subviews don't retrigger the
    /// snapshot and are safe.
    private func updateCountBadge(on button: NSStatusBarButton, count: Int) {
        guard count > 0 else {
            countBadge?.isHidden = true
            return
        }
        let badge: NSImageView
        if let existing = countBadge {
            badge = existing
        } else {
            let view = NSImageView()
            view.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(view)
            // Width/height come from the image's intrinsic size, which tracks the
            // rendered count (wider for multi-digit values).
            // Overhangs the corner by a point, as a notification badge does.
            NSLayoutConstraint.activate(Self.cornerConstraints(
                for: view, in: button, corner: badgeLayout.count, inset: -1))
            countBadge = view
            badge = view
        }
        badge.image = Self.countBadgeImage(count: count)
        badge.isHidden = false
    }

    /// Renders `count` as the green rounded status-item badge: white bold 8 pt
    /// text centered on a systemGreen capsule, 10 pt tall, at least 10 pt wide.
    /// Colors resolve inside the drawing handler, so the badge re-renders
    /// correctly if the effective appearance changes. Not private, so
    /// AgenticDeveloperHubSDKMenuBarTests can pin its geometry.
    static func countBadgeImage(count: Int) -> NSImage {
        let text = "\(count)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let textSize = text.size(withAttributes: attributes)
        let height: CGFloat = 10
        let width = max(height, ceil(textSize.width) + 6)
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            NSColor.systemGreen.setFill()
            NSBezierPath(roundedRect: rect, xRadius: height / 2, yRadius: height / 2).fill()
            text.draw(
                at: NSPoint(x: (rect.width - textSize.width) / 2, y: (rect.height - textSize.height) / 2),
                withAttributes: attributes)
            return true
        }
        image.isTemplate = false
        return image
    }

    /// Show or hide an `exclamationmark.circle.fill` overlay in the
    /// ``badgeLayout`` status corner of the status bar button. We keep the base image as a template (so AppKit
    /// handles light/dark inversion) and layer the badge as a tinted subview,
    /// which preserves its color without fighting the menubar's appearance
    /// heuristics. `slot` retains the lazily-created subview between refreshes.
    private func setBadge(
        _ slot: inout NSImageView?,
        on button: NSStatusBarButton,
        visible: Bool,
        tint: NSColor,
        accessibility: String
    ) {
        if visible {
            if slot == nil {
                let badge = NSImageView()
                badge.translatesAutoresizingMaskIntoConstraints = false
                let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .heavy)
                badge.image = NSImage(
                    systemSymbolName: "exclamationmark.circle.fill",
                    accessibilityDescription: accessibility
                )?.withSymbolConfiguration(config)
                badge.contentTintColor = tint
                button.addSubview(badge)
                NSLayoutConstraint.activate([
                    badge.widthAnchor.constraint(equalToConstant: 11),
                    badge.heightAnchor.constraint(equalToConstant: 11)
                ] + Self.cornerConstraints(for: badge, in: button, corner: badgeLayout.drawnStatusCorner, inset: 1))
                slot = badge
            }
            slot?.isHidden = false
        } else {
            slot?.isHidden = true
        }
    }

    /// Pins `badge` into `corner` of `button`. `inset` is how far inside the
    /// corner it sits, on both axes; negative overhangs the edge. Not private,
    /// so AgenticDeveloperHubSDKMenuBarTests can pin the geometry.
    static func cornerConstraints(
        for badge: NSView,
        in button: NSView,
        corner: MenuBarBadgeCorner,
        inset: CGFloat
    ) -> [NSLayoutConstraint] {
        let horizontal = corner.isLeading
            ? badge.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: inset)
            : badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -inset)
        let vertical = corner.isTop
            ? badge.topAnchor.constraint(equalTo: button.topAnchor, constant: inset)
            : badge.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -inset)
        return [horizontal, vertical]
    }
}

extension StatusBarAppDelegate: NSMenuDelegate {
    /// The menu is about to show: note it, and refresh at once so a host that
    /// skips work while the menu is closed (``MenuPoll/menuIsOpen``) has
    /// fresh data on screen within one poll rather than one tick.
    public func menuWillOpen(_ menu: NSMenu) {
        menuIsOpen = true
        refresh()
    }

    public func menuDidClose(_ menu: NSMenu) {
        menuIsOpen = false
    }
}

/// What a ``StatusBarAppDelegate`` refresh knows when it asks the host's
/// `pollingUserInfoProvider` for user info.
public struct MenuPoll: Sendable, Equatable {
    /// This refresh's `/health` probe got an answer (not debounced).
    public let probeSucceeded: Bool
    /// The status item's menu was on screen when the refresh started.
    public let menuIsOpen: Bool

    public init(probeSucceeded: Bool, menuIsOpen: Bool) {
        self.probeSucceeded = probeSucceeded
        self.menuIsOpen = menuIsOpen
    }
}

/// A corner of the status item's button.
public enum MenuBarBadgeCorner: String, Sendable, CaseIterable, Codable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    var isLeading: Bool { self == .topLeading || self == .bottomLeading }
    var isTop: Bool { self == .topLeading || self == .topTrailing }

    /// The corner above or below this one, on the same side.
    public var verticalNeighbor: MenuBarBadgeCorner {
        switch self {
        case .topLeading: .bottomLeading
        case .bottomLeading: .topLeading
        case .topTrailing: .bottomTrailing
        case .bottomTrailing: .topTrailing
        }
    }

    /// The corner's name for a settings popup ("Top Right"). Kept here, beside
    /// the enum, so every app that offers the choice labels it the same way.
    public var displayName: String {
        switch self {
        case .topLeading: "Top Left"
        case .topTrailing: "Top Right"
        case .bottomLeading: "Bottom Left"
        case .bottomTrailing: "Bottom Right"
        }
    }
}

/// Where a ``StatusBarAppDelegate`` puts its badges: the green count, and the
/// one status badge (unreachable or alert) it shows at a time.
public struct MenuBarBadgeLayout: Sendable, Equatable {
    public var count: MenuBarBadgeCorner
    public var status: MenuBarBadgeCorner

    public init(count: MenuBarBadgeCorner, status: MenuBarBadgeCorner) {
        self.count = count
        self.status = status
    }

    /// Count top right, status bottom right.
    public static let standard = MenuBarBadgeLayout(count: .topTrailing, status: .bottomTrailing)

    /// Where the status badge is drawn: its own corner, unless the count
    /// already holds it, in which case the corner above or below on the same
    /// side. Two badges pinned into one corner would cover each other, and the
    /// hidden one may be the failure signal.
    public var drawnStatusCorner: MenuBarBadgeCorner {
        status == count ? status.verticalNeighbor : status
    }

    /// This layout with the two badges kept apart, for a settings UI: when
    /// the badge that just moved landed on the other's corner, the other takes
    /// the corner the moved one left. A layout whose corners differ is
    /// returned as is.
    public func separated(from previous: MenuBarBadgeLayout) -> MenuBarBadgeLayout {
        guard count == status else { return self }
        if count != previous.count {
            return MenuBarBadgeLayout(count: count, status: previous.count)
        }
        if status != previous.status {
            return MenuBarBadgeLayout(count: previous.status, status: status)
        }
        return MenuBarBadgeLayout(count: count, status: drawnStatusCorner)
    }
}

/// Which overlay badge the status item shows. Unreachable wins over alert — when
/// the daemon is down we can't trust an alert signal anyway.
public enum MenuBarBadge: Sendable, Equatable {
    case none
    case unreachable
    case alert

    public static func resolve(isReachable: Bool, hasAlert: Bool) -> MenuBarBadge {
        if !isReachable { return .unreachable }
        return hasAlert ? .alert : .none
    }
}
