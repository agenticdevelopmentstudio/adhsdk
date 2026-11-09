import Testing
import Foundation
import AppKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMenuBar

// MARK: - Helpers

private func snapshot(
    reachable: Bool = true,
    strategy: DaemonStrategyReport? = nil,
    userInfo: [String: any Sendable] = [:]
) -> MenuSnapshot {
    let defaultStrategy = DaemonStrategyReport(name: "daemon", kind: "timing", workUnits: [])
    let health: DaemonHealthReport? = reachable ? DaemonHealthReport(
        status: "ok",
        version: "1.0.0",
        uptimeSeconds: 60,
        strategy: strategy ?? defaultStrategy
    ) : nil
    return MenuSnapshot(
        isReachable: reachable,
        health: health,
        userInfo: userInfo
    )
}

// MARK: - MenuComposer

@Suite("MenuComposer", .serialized)
@MainActor
struct MenuComposerTests {

    @Test("builds a menu from sections in order")
    func buildsInOrder() {
        let composer = MenuComposer(sections: [
            TitleSection(title: "First"),
            TitleSection(title: "Second")
        ])
        let menu = composer.build(snapshot: snapshot())
        let titles = menu.items.map(\.title)
        // Separator appears between sections
        #expect(titles == ["First", "", "Second"])
        #expect(menu.items.count == 3)
    }

    @Test("skips sections that return no items — no dangling separators")
    func skipsEmptySections() {
        let composer = MenuComposer(sections: [
            TitleSection(title: "A"),
            EmptySection(),
            TitleSection(title: "B")
        ])
        let menu = composer.build(snapshot: snapshot())
        let titles = menu.items.map(\.title)
        #expect(titles == ["A", "", "B"])
    }

    @Test("all-empty composer yields an empty menu")
    func allEmpty() {
        let composer = MenuComposer(sections: [EmptySection(), EmptySection()])
        let menu = composer.build(snapshot: snapshot())
        #expect(menu.items.isEmpty)
    }
}

// MARK: - HealthMenuSection

@Suite("HealthMenuSection", .serialized)
@MainActor
struct HealthMenuSectionTests {

    @Test("shows stopped header when daemon is not reachable")
    func unreachable() {
        let section = HealthMenuSection(daemonName: "mydaemon")
        let items = section.items(snapshot: snapshot(reachable: false))
        #expect(items.count == 1)
        #expect(items[0].title.contains("mydaemon not running"))
    }

    @Test("shows running header with uptime when reachable")
    func reachable() {
        let section = HealthMenuSection(daemonName: "mydaemon")
        let items = section.items(snapshot: snapshot(reachable: true))
        #expect(items.count >= 1)
        #expect(items[0].title.contains("mydaemon"))
        #expect(items[0].title.contains("uptime"))
    }
}

// MARK: - TimingStrategyMenuSection

@Suite("TimingStrategyMenuSection", .serialized)
@MainActor
struct TimingStrategyMenuSectionTests {

    @Test("hidden when no timing strategy in snapshot")
    func noTimingHides() {
        let section = TimingStrategyMenuSection()
        let snap = snapshot(strategy: DaemonStrategyReport(name: "e", kind: "event", workUnits: []))
        let items = section.items(snapshot: snap)
        #expect(items.isEmpty)
    }

    @Test("renders JOBS header + unit rows")
    func rendersJobs() {
        let strat = DaemonStrategyReport(name: "t", kind: "timing", workUnits: [
            DaemonWorkUnitReport(name: "a", state: .idle, nextActivation: Date(timeIntervalSinceNow: 30)),
            DaemonWorkUnitReport(name: "b", state: .running)
        ])
        let section = TimingStrategyMenuSection()
        let items = section.items(snapshot: snapshot(strategy: strat))
        #expect(items.count == 3)
        #expect(items[0].title.contains("JOBS"))
        #expect(items[1].title.contains("a"))
        #expect(items[2].title.contains("b"))
    }

    @Test("with onTrigger provided, unit items expose submenu")
    func submenuOnTrigger() {
        let strat = DaemonStrategyReport(name: "t", kind: "timing", workUnits: [
            DaemonWorkUnitReport(name: "job1", state: .idle, nextActivation: Date(timeIntervalSinceNow: 30))
        ])
        let section = TimingStrategyMenuSection(onTrigger: { _ in })
        let items = section.items(snapshot: snapshot(strategy: strat))
        let jobItem = items.last!
        #expect(jobItem.submenu != nil)
        let submenuTitles = jobItem.submenu?.items.map(\.title) ?? []
        #expect(submenuTitles.contains(where: { $0.contains("Trigger Now") }))
    }

    @Test("finds nested timing strategy inside composite")
    func findsNested() {
        let inner = DaemonStrategyReport(name: "inner", kind: "timing", workUnits: [
            DaemonWorkUnitReport(name: "x", state: .idle)
        ])
        let outer = DaemonStrategyReport(name: "outer", kind: "composite", workUnits: [], children: [inner])
        let section = TimingStrategyMenuSection()
        let items = section.items(snapshot: snapshot(strategy: outer))
        #expect(items.count == 2)
        #expect(items[1].title.contains("x"))
    }
}

// MARK: - EventStrategyMenuSection

@Suite("EventStrategyMenuSection", .serialized)
@MainActor
struct EventStrategyMenuSectionTests {

    @Test("hidden when no event strategy")
    func hidesWhenNone() {
        let section = EventStrategyMenuSection()
        let strat = DaemonStrategyReport(name: "t", kind: "timing", workUnits: [])
        let items = section.items(snapshot: snapshot(strategy: strat))
        #expect(items.isEmpty)
    }

    @Test("renders header + units")
    func rendersEventUnits() {
        let strat = DaemonStrategyReport(name: "ingest", kind: "event", workUnits: [
            DaemonWorkUnitReport(name: "handler", state: .idle)
        ])
        let section = EventStrategyMenuSection()
        let items = section.items(snapshot: snapshot(strategy: strat))
        #expect(items.count == 2)
        #expect(items[0].title.contains("EVENTS"))
    }

    @Test("includes Open Stream item when onOpenStream provided")
    func openStreamItem() {
        let strat = DaemonStrategyReport(name: "ingest", kind: "event", workUnits: [])
        let section = EventStrategyMenuSection(onOpenStream: {})
        let items = section.items(snapshot: snapshot(strategy: strat))
        #expect(items.contains(where: { $0.title.contains("Open Event Stream") }))
    }
}

// MARK: - ControlsMenuSection

@Suite("ControlsMenuSection", .serialized)
@MainActor
struct ControlsMenuSectionTests {

    @Test("shows Start when unreachable")
    func startWhenUnreachable() {
        let section = ControlsMenuSection(
            onStart: {},
            onQuit: {}
        )
        let items = section.items(snapshot: snapshot(reachable: false))
        #expect(items.contains(where: { $0.title == "Start Daemon" }))
        #expect(!items.contains(where: { $0.title == "Stop Daemon" }))
    }

    @Test("shows Restart/Stop when reachable")
    func stopWhenReachable() {
        let section = ControlsMenuSection(
            onStop: {},
            onRestart: {},
            onQuit: {}
        )
        let items = section.items(snapshot: snapshot(reachable: true))
        #expect(items.contains(where: { $0.title == "Restart Daemon" }))
        #expect(items.contains(where: { $0.title == "Stop Daemon" }))
    }

    @Test("always includes Quit")
    func alwaysQuit() {
        let section = ControlsMenuSection(onQuit: {})
        let unreachable = section.items(snapshot: snapshot(reachable: false))
        let reachable = section.items(snapshot: snapshot(reachable: true))
        #expect(unreachable.last?.title == "Quit")
        #expect(reachable.last?.title == "Quit")
    }
}

// MARK: - BlockMenuItem

@Suite("BlockMenuItem")
@MainActor
struct BlockMenuItemTests {

    @Test("invokes block when action fires")
    func invokesBlock() async {
        let fired = LockBool()
        let item = BlockMenuItem(title: "t") { fired.set(true) }
        _ = item.target?.perform(item.action)
        #expect(fired.value == true)
    }

    @Test("enabled state and checkmark are re-read each time the menu updates")
    func revalidatesOnUpdate() {
        // `NSMenu.update()` validates through `NSApp`; until something asks for
        // the shared application it is nil and every item reads disabled.
        _ = NSApplication.shared
        let running = LockBool()
        let item = BlockMenuItem(
            title: "Stop Timer",
            isEnabled: { running.value },
            isOn: { running.value },
            action: {}
        )
        let menu = NSMenu()
        menu.addItem(item)
        menu.update()
        #expect(item.isEnabled == false)
        #expect(item.state == .off)

        running.set(true)
        menu.update()

        #expect(item.isEnabled == true, "a timer started after the menu was built enables Stop Timer")
        #expect(item.state == .on)
    }

    @Test("an item with no checks stays enabled and unchecked")
    func defaultsToEnabled() {
        _ = NSApplication.shared
        let item = BlockMenuItem(title: "t") {}
        let menu = NSMenu()
        menu.addItem(item)
        menu.update()
        #expect(item.isEnabled)
        #expect(item.state == .off)
    }

    @Test("an explicit isEnabled = false survives validation")
    func explicitDisableSurvivesValidation() {
        _ = NSApplication.shared
        let item = BlockMenuItem(title: "Sync Now") {}
        item.isEnabled = false
        let menu = NSMenu()
        menu.addItem(item)
        menu.update()
        #expect(item.isEnabled == false)
    }
}

// MARK: - MenuComposer.build enablement

/// A section that disables the one `BlockMenuItem` it contributes, the same
/// shape `DaemonActionsSection.items(snapshot:)` uses for "Sync Now" while
/// the daemon is down.
private struct DisablingSection: MenuSection {
    func items(snapshot: MenuSnapshot) -> [NSMenuItem] {
        let item = BlockMenuItem(title: "Sync Now") {}
        item.isEnabled = false
        return [item]
    }
}

@Suite("MenuComposer.build enablement", .serialized)
@MainActor
struct MenuComposerEnablementTests {

    /// `NSMenuItem` with a target/action pair whose target does not
    /// implement `validateMenuItem(_:)` is force-enabled by AppKit whenever
    /// the owning `NSMenu.autoenablesItems` is `true` (AppKit's default) —
    /// silently overriding an `isEnabled = false` a section set deliberately.
    /// This was caught live (System Events on a real, tracked status-item
    /// menu showed "Sync Now" `enabled = true` while the daemon was down),
    /// not by any prior unit test.
    ///
    /// The obvious regression test — build a menu through `MenuComposer`,
    /// call `menu.update()` (the API that runs AppKit's validation pass),
    /// and assert the item is still disabled — was tried first and passed
    /// even *before* the fix below: `menu.update()` in a headless XCTest/
    /// swift-testing process does not reproduce the force-enable, which only
    /// happens under real menu tracking (a status item actually opened).
    /// So this asserts the fact this fix actually controls instead:
    /// `MenuComposer.build` opts the menu out of autoenabling. It proves the
    /// composer sets the flag that makes `isEnabled` authoritative; it does
    /// **not** exercise AppKit's force-enable behavior itself, which no
    /// automated test in this repo reproduces headless.
    @Test("MenuComposer.build turns off autoenablesItems, so isEnabled is authoritative")
    func buildDisablesAutoenabling() {
        let menu = MenuComposer(sections: [DisablingSection()]).build(snapshot: snapshot())
        #expect(menu.autoenablesItems == false)
    }
}

// MARK: - Test sections

private struct TitleSection: MenuSection {
    let title: String
    func items(snapshot: MenuSnapshot) -> [NSMenuItem] {
        [NSMenuItem(title: title, action: nil, keyEquivalent: "")]
    }
}

private struct EmptySection: MenuSection {
    func items(snapshot: MenuSnapshot) -> [NSMenuItem] { [] }
}

private final class LockBool: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = false
    var value: Bool { lock.withLock { _value } }
    func set(_ value: Bool) { lock.withLock { _value = value } }
}

// MARK: - StatusBarAppDelegate icon-redraw suppression

@Suite("StatusBarAppDelegate icon suppression", .serialized)
@MainActor
struct StatusBarIconStateTests {
    private func makeDelegate() -> StatusBarAppDelegate {
        StatusBarAppDelegate(
            healthProbe: { nil },
            composer: MenuComposer(sections: [])
        )
    }

    @Test("re-applying the same state redraws the icon only once")
    func suppressesRedundantRedraws() {
        let delegate = makeDelegate()
        let state = StatusBarAppDelegate.IconState(isReachable: true, hasAlert: false, count: 3)
        delegate.applyIconState(state)
        delegate.applyIconState(state)
        delegate.applyIconState(state)
        // The refresh timer re-applies an unchanged state every few seconds; only
        // the first application may touch the (costly-to-redraw) status item.
        #expect(delegate.iconRedraws == 1)
    }

    @Test("each field change triggers exactly one more redraw")
    func redrawsOnEveryChange() {
        let delegate = makeDelegate()
        delegate.applyIconState(.init(isReachable: false, hasAlert: false, count: 0))  // 1: first
        delegate.applyIconState(.init(isReachable: true, hasAlert: false, count: 0))   // 2: reachable
        delegate.applyIconState(.init(isReachable: true, hasAlert: true, count: 0))    // 3: alert
        delegate.applyIconState(.init(isReachable: true, hasAlert: true, count: 5))    // 4: count
        delegate.applyIconState(.init(isReachable: true, hasAlert: true, count: 5))    // no change
        #expect(delegate.iconRedraws == 4)
    }

    @Test("assigning menuImage redraws the icon at the state already applied")
    func menuImageAssignmentRedraws() {
        let delegate = makeDelegate()
        let state = StatusBarAppDelegate.IconState(isReachable: true, hasAlert: false, count: 3)
        delegate.applyIconState(state)
        #expect(delegate.iconRedraws == 1)

        // A host app swaps the ink when the menu bar's appearance changes. The
        // icon *state* has not moved, so the `==` guard would swallow the
        // redraw and leave the old image on the button — hence the `didSet`
        // clearing the memo. The badges are re-laid over the new image by the
        // same path a refresh uses.
        delegate.menuImage = NSImage(size: NSSize(width: 18, height: 18))
        #expect(delegate.iconRedraws == 2)

        // And the state is remembered, not lost: an unchanged poll after the
        // swap must still be suppressed.
        delegate.applyIconState(state)
        #expect(delegate.iconRedraws == 2)
    }

    @Test("assigning menuImage before launch redraws nothing")
    func menuImageBeforeLaunchIsInert() {
        let delegate = makeDelegate()
        delegate.menuImage = NSImage(size: NSSize(width: 18, height: 18))
        // Nothing has been applied yet, so there is no state to re-apply and no
        // status item to draw into; `applicationDidFinishLaunching` reads the
        // property when it makes the button.
        #expect(delegate.iconRedraws == 0)
    }

    @Test("menuSignature ignores key order and now, but reflects content changes")
    func menuSignatureStability() {
        // Same content, different dict order AND different `now` → same signature
        // (the menu-rebuild gate must not rebuild when nothing a section renders changed).
        let base = MenuSnapshot(isReachable: true, health: nil, userInfo: ["key": "v", "abc": 1])
        let reordered = MenuSnapshot(isReachable: true, health: nil, userInfo: ["abc": 1, "key": "v"])
        #expect(StatusBarAppDelegate.menuSignature(base) == StatusBarAppDelegate.menuSignature(reordered))
        // A real change to any rendered input flips the signature (no false "unchanged").
        let reach = MenuSnapshot(isReachable: false, health: nil, userInfo: ["key": "v", "abc": 1])
        let value = MenuSnapshot(isReachable: true, health: nil, userInfo: ["key": "w", "abc": 1])
        #expect(StatusBarAppDelegate.menuSignature(base) != StatusBarAppDelegate.menuSignature(reach))
        #expect(StatusBarAppDelegate.menuSignature(base) != StatusBarAppDelegate.menuSignature(value))
    }

    @Test("a single missed /health poll doesn't flip reachability (debounced)")
    func debounceRidesOutTransientMisses() {
        let delegate = makeDelegate()   // default 5 s interval → threshold 3
        #expect(delegate.debouncedReachability(probeSucceeded: true) == true)   // reachable
        #expect(delegate.debouncedReachability(probeSucceeded: false) == true)  // 1 miss — still up
        #expect(delegate.debouncedReachability(probeSucceeded: false) == true)  // 2 misses — still up
        #expect(delegate.debouncedReachability(probeSucceeded: false) == false) // 3rd = threshold — down
    }

    @Test("any success resets the debounce counter")
    func successResetsDebounce() {
        let delegate = makeDelegate()
        _ = delegate.debouncedReachability(probeSucceeded: true)
        _ = delegate.debouncedReachability(probeSucceeded: false)               // 1 miss
        _ = delegate.debouncedReachability(probeSucceeded: false)               // 2 misses
        #expect(delegate.debouncedReachability(probeSucceeded: true) == true)   // success resets
        #expect(delegate.debouncedReachability(probeSucceeded: false) == true)  // back to 1 miss — still up
    }

    @Test("before the first success a miss is unreachable at once (no false 'up' at cold start)")
    func coldStartMissIsUnreachable() {
        let delegate = makeDelegate()
        // Daemon down when the app launches: never been reachable → don't debounce.
        #expect(delegate.debouncedReachability(probeSucceeded: false) == false)
    }

    @Test("debounce window scales with the poll interval (time budget, not a fixed count)")
    func thresholdScalesWithInterval() {
        // interval 15 s, ~15 s grace → threshold 1: a single miss after a success flips.
        let delegate = StatusBarAppDelegate(
            healthProbe: { nil },
            composer: MenuComposer(sections: []),
            refreshInterval: 15
        )
        #expect(delegate.debouncedReachability(probeSucceeded: true) == true)
        #expect(delegate.debouncedReachability(probeSucceeded: false) == false)  // ~15 s at this interval
    }
}

// MARK: - Poll context (MenuPoll)

/// Records every `MenuPoll` a `pollingUserInfoProvider` is handed.
private final class PollLog: @unchecked Sendable {
    private let lock = NSLock()
    private var _polls: [MenuPoll] = []
    private var _plainCalls = 0
    var polls: [MenuPoll] { lock.withLock { _polls } }
    var plainCalls: Int { lock.withLock { _plainCalls } }
    func record(_ poll: MenuPoll) { lock.withLock { _polls.append(poll) } }
    func recordPlain() { lock.withLock { _plainCalls += 1 } }
}

@Suite("StatusBarAppDelegate poll context", .serialized)
@MainActor
struct StatusBarPollContextTests {
    private func makeDelegate(answers: Bool, log: PollLog) -> StatusBarAppDelegate {
        StatusBarAppDelegate(
            healthProbe: { answers ? Data(#"{"status":"ok"}"#.utf8) : nil },
            composer: MenuComposer(sections: []),
            refreshInterval: 60,
            userInfoProvider: { log.recordPlain(); return [:] },
            pollingUserInfoProvider: { poll in log.record(poll); return [:] }
        )
    }

    /// Waits (bounded) until the provider has been asked `count` times.
    private func waitForPolls(_ log: PollLog, count: Int) async throws {
        let deadline = Date.now.addingTimeInterval(10)
        while log.polls.count < count {
            guard Date.now < deadline else {
                Issue.record("only \(log.polls.count) of \(count) polls arrived in 10 s")
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    @Test("a refresh whose /health failed says so, and a closed menu says so")
    func failedProbeClosedMenu() async throws {
        let log = PollLog()
        let delegate = makeDelegate(answers: false, log: log)
        delegate.refresh()
        try await waitForPolls(log, count: 1)
        #expect(log.polls.first == MenuPoll(probeSucceeded: false, menuIsOpen: false))
        // The polling provider replaces the plain one; the host is never asked twice.
        #expect(log.plainCalls == 0)
    }

    @Test("a refresh whose /health answered says so")
    func succeededProbe() async throws {
        let log = PollLog()
        let delegate = makeDelegate(answers: true, log: log)
        delegate.refresh()
        try await waitForPolls(log, count: 1)
        #expect(log.polls.first == MenuPoll(probeSucceeded: true, menuIsOpen: false))
    }

    @Test("opening the menu refreshes at once with menuIsOpen, and closing it clears it")
    func menuOpenAndClose() async throws {
        let log = PollLog()
        let delegate = makeDelegate(answers: false, log: log)
        let menu = NSMenu()
        delegate.menuWillOpen(menu)                 // refreshes by itself
        try await waitForPolls(log, count: 1)
        #expect(log.polls.last?.menuIsOpen == true)

        delegate.menuDidClose(menu)
        delegate.refresh()
        try await waitForPolls(log, count: 2)
        #expect(log.polls.last?.menuIsOpen == false)
    }

    @Test("a menu built while the menu is open moves its items into the open menu")
    func moveItemsIntoOpenMenu() {
        let open = NSMenu()
        open.addItem(NSMenuItem(title: "stale", action: nil, keyEquivalent: ""))
        let built = MenuComposer(sections: [TitleSection(title: "A"), TitleSection(title: "B")])
            .build(snapshot: snapshot())
        StatusBarAppDelegate.moveItems(from: built, into: open)
        #expect(open.items.map(\.title) == ["A", "", "B"])
        #expect(built.items.isEmpty)
        #expect(open.autoenablesItems == false)
    }
}

// MARK: - Count badge

@Suite("Count badge", .serialized)
@MainActor
struct CountBadgeTests {

    // The badge must be a pre-rendered image in an NSImageView — never a live
    // text view. On macOS 26 an NSTextField inside NSStatusBarButton re-dirties
    // itself during the replicant snapshot render (multi-display menu bars),
    // locking AppKit into an endless re-snapshot loop that pins most of a core.
    @Test("badge renders as a fixed-height, non-template image")
    func badgeIsPreRenderedImage() {
        let image = StatusBarAppDelegate.countBadgeImage(count: 2)
        #expect(image.size.height == 10)
        #expect(image.size.width >= 10)
        #expect(!image.isTemplate)   // colored badge must not invert with the menu bar
    }

    @Test("the status badge is a non-template disc ringed in white")
    func statusBadgeStandsOut() throws {
        let image = StatusBarAppDelegate.statusBadgeImage(tint: .systemRed, accessibility: "errors")
        #expect(image.size == NSSize(width: 12, height: 12))
        #expect(!image.isTemplate)   // its colours must survive any base image
        let rep = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 24, pixelsHigh: 24, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: 24, height: 24))
        NSGraphicsContext.restoreGraphicsState()
        // The ring: the top edge of the disc is opaque white.
        let ring = try #require(rep.colorAt(x: 12, y: 0)?.usingColorSpace(.deviceRGB))
        #expect(ring.alphaComponent > 0.9 && ring.redComponent > 0.9 && ring.blueComponent > 0.9)
        // Inside, left of the mark: the tint.
        let fill = try #require(rep.colorAt(x: 6, y: 12)?.usingColorSpace(.deviceRGB))
        #expect(fill.redComponent > 0.7 && fill.blueComponent < 0.5)
    }

    @Test("badge widens for multi-digit counts")
    func badgeWidensWithCount() {
        let narrow = StatusBarAppDelegate.countBadgeImage(count: 2)
        let wide = StatusBarAppDelegate.countBadgeImage(count: 120)
        #expect(wide.size.width > narrow.size.width)
    }
}

// MARK: - Health report

@Suite("DaemonHealthReport")
struct DaemonHealthReportTests {

    @Test("decodes a DaemonKit /health body, children optional")
    func decodesWireFormat() throws {
        let body = #"""
        {"status":"ok","version":"2.1.0","uptimeSeconds":90,
         "strategy":{"name":"root","kind":"composite","workUnits":[],
           "children":[{"name":"jobs","kind":"timing","workUnits":[
             {"name":"sync","state":"idle","nextActivation":"2026-01-01T00:00:00Z",
              "consecutiveFailures":2,"isBlocklisted":false}]}]}}
        """#
        let report = try #require(DaemonHealthReport.decode(Data(body.utf8)))
        #expect(report.version == "2.1.0")
        let timing = try #require(report.strategy.first(ofKind: DaemonStrategyReport.timingKind))
        #expect(timing.children.isEmpty)
        #expect(timing.workUnits.first?.state == .idle)
        #expect(timing.workUnits.first?.consecutiveFailures == 2)
        #expect(timing.workUnits.first?.nextActivation != nil)
    }

    @Test("a body in another schema decodes to nil")
    func otherSchemaIsNil() {
        #expect(DaemonHealthReport.decode(Data(#"{"status":"ok"}"#.utf8)) == nil)
    }
}

// MARK: - Badge corners

@Suite("Badge corners", .serialized)
@MainActor
struct BadgeCornerTests {

    private func frame(of corner: MenuBarBadgeCorner, inset: CGFloat) -> NSRect {
        let button = NSView(frame: NSRect(x: 0, y: 0, width: 40, height: 22))
        let badge = NSView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 10),
            badge.heightAnchor.constraint(equalToConstant: 10)
        ] + StatusBarAppDelegate.cornerConstraints(for: badge, in: button, corner: corner, inset: inset))
        button.layoutSubtreeIfNeeded()
        return badge.frame
    }

    @Test("each corner pins the badge to that corner, inset inward")
    func cornersPinInward() {
        // NSView is not flipped: y grows upward, so "top" is the high y.
        #expect(frame(of: .bottomLeading, inset: 1) == NSRect(x: 1, y: 1, width: 10, height: 10))
        #expect(frame(of: .bottomTrailing, inset: 1) == NSRect(x: 29, y: 1, width: 10, height: 10))
        #expect(frame(of: .topLeading, inset: 1) == NSRect(x: 1, y: 11, width: 10, height: 10))
        #expect(frame(of: .topTrailing, inset: 1) == NSRect(x: 29, y: 11, width: 10, height: 10))
    }

    @Test("a negative inset overhangs the corner, as the count badge does")
    func negativeInsetOverhangs() {
        #expect(frame(of: .topTrailing, inset: -1) == NSRect(x: 31, y: 13, width: 10, height: 10))
    }

    @Test("the standard layout keeps the count top right and the status bottom right")
    func standardLayout() {
        #expect(MenuBarBadgeLayout.standard == MenuBarBadgeLayout(count: .topTrailing, status: .bottomTrailing))
        let delegate = StatusBarAppDelegate(healthProbe: { nil }, composer: MenuComposer(sections: []))
        #expect(delegate.badgeLayout == .standard)
    }

    @Test("changing the layout redraws at the state already applied; the same layout does not")
    func layoutChangeRedraws() {
        let delegate = StatusBarAppDelegate(healthProbe: { nil }, composer: MenuComposer(sections: []))
        let state = StatusBarAppDelegate.IconState(isReachable: true, hasAlert: true, count: 2)
        delegate.applyIconState(state)
        #expect(delegate.iconRedraws == 1)

        delegate.badgeLayout = MenuBarBadgeLayout(count: .topLeading, status: .bottomLeading)
        #expect(delegate.iconRedraws == 2)

        delegate.badgeLayout = MenuBarBadgeLayout(count: .topLeading, status: .bottomLeading)
        #expect(delegate.iconRedraws == 2)

        delegate.applyIconState(state)
        #expect(delegate.iconRedraws == 2)
    }

    @Test("every corner has its own display name, in reading order")
    func displayNames() {
        #expect(MenuBarBadgeCorner.allCases.map(\.displayName)
                == ["Top Left", "Top Right", "Bottom Left", "Bottom Right"])
    }

    @Test("a status badge sharing the count's corner is drawn above or below it")
    func collidingStatusMoves() {
        for corner in MenuBarBadgeCorner.allCases {
            let layout = MenuBarBadgeLayout(count: corner, status: corner)
            #expect(layout.drawnStatusCorner == corner.verticalNeighbor)
            #expect(layout.drawnStatusCorner.isLeading == corner.isLeading)
        }
        #expect(MenuBarBadgeLayout.standard.drawnStatusCorner == .bottomTrailing)
    }

    @Test("moving one badge onto the other's corner swaps them")
    func separatedSwaps() {
        let previous = MenuBarBadgeLayout.standard  // count top right, status bottom right
        let countMoved = MenuBarBadgeLayout(count: .bottomTrailing, status: .bottomTrailing)
        #expect(countMoved.separated(from: previous)
                == MenuBarBadgeLayout(count: .bottomTrailing, status: .topTrailing))
        let statusMoved = MenuBarBadgeLayout(count: .topTrailing, status: .topTrailing)
        #expect(statusMoved.separated(from: previous)
                == MenuBarBadgeLayout(count: .bottomTrailing, status: .topTrailing))
        let apart = MenuBarBadgeLayout(count: .topLeading, status: .bottomTrailing)
        #expect(apart.separated(from: previous) == apart)
    }

    @Test("separating never leaves the two badges in one corner")
    func separatedIsAlwaysApart() {
        let corners = MenuBarBadgeCorner.allCases
        for previousCount in corners {
            for previousStatus in corners {
                for next in corners {
                    let previous = MenuBarBadgeLayout(count: previousCount, status: previousStatus)
                    let result = MenuBarBadgeLayout(count: next, status: next).separated(from: previous)
                    #expect(result.count != result.status)
                }
            }
        }
    }

    @Test("changing the layout before anything is applied redraws nothing")
    func layoutChangeBeforeLaunchIsInert() {
        let delegate = StatusBarAppDelegate(healthProbe: { nil }, composer: MenuComposer(sections: []))
        delegate.badgeLayout = MenuBarBadgeLayout(count: .bottomLeading, status: .topLeading)
        #expect(delegate.iconRedraws == 0)
    }
}
