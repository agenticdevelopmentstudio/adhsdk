import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// Crawl: a thin strip along the top or bottom of each selected screen, its
/// notices scrolling across it one after another, right to left unless the
/// rules say otherwise. Hovering holds the strip (and the notices'
/// countdowns) still; clicking a notice acts on it. A strip goes away once it
/// has nothing left to show.
@MainActor
public final class CrawlPresenter: NoticePresenter {

    /// Which edge of the screen a strip runs along. The top positions crawl
    /// along the top; every other position along the bottom.
    enum Edge: Hashable {
        case top, bottom

        init(_ position: NoticeProfile.Position) {
            switch position {
            case .topLeft, .topCenter: self = .top
            case .center, .bottomLeft, .bottomCenter, .bottomRight: self = .bottom
            }
        }
    }

    struct StripKey: Hashable {
        let displayID: UInt32
        let edge: Edge
    }

    private struct Item {
        var notice: Notice
        var actions: NoticeCardActions
        let countdown: DismissCountdown
    }

    private final class Strip {
        let panel: NoticePanel
        let view: CrawlStripView
        var elapsed: TimeInterval = 0
        /// Read from the rules when the content changes, not on every frame.
        var leftToRight = false

        init(panel: NoticePanel, view: CrawlStripView) {
            self.panel = panel
            self.view = view
        }
    }

    static let stripHeight: CGFloat = 28
    /// Points per second.
    static let speed: CGFloat = 80
    private static let frameInterval: TimeInterval = 1.0 / 30

    private let rules: @MainActor () -> NoticeRoutingRules
    private let windowing: NoticeWindowing
    private let screens: NoticeScreenProvider
    private var model = CrawlModel()
    private var items: [String: Item] = [:]
    private var strips: [StripKey: Strip] = [:]
    private var timer: Timer?
    private var screenObserver: NSObjectProtocol?

    public var shownIDs: [String] { model.order }

    public convenience init(rules: @escaping @MainActor () -> NoticeRoutingRules) {
        self.init(rules: rules, windowing: LiveNoticeWindowing(), screens: ScreenSelector.noticeScreens)
    }

    /// With the windows and screens injected, so tests put nothing on screen.
    init(
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        windowing: NoticeWindowing,
        screens: @escaping NoticeScreenProvider
    ) {
        self.rules = rules
        self.windowing = windowing
        self.screens = screens
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensDidChange() }
        }
    }

    isolated deinit {
        timer?.invalidate()
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    // MARK: Geometry

    /// Where the content's leading edge sits, in strip coordinates, after
    /// `elapsed` seconds. Right to left it enters at the strip's right edge
    /// and leaves past its left; left to right is the mirror image. Once the
    /// content has fully left, it starts over.
    nonisolated static func offset(
        elapsed: TimeInterval, speed: CGFloat, contentWidth: CGFloat, stripWidth: CGFloat, leftToRight: Bool
    ) -> CGFloat {
        let pass = stripWidth + contentWidth
        guard speed > 0, pass > 0 else { return leftToRight ? -contentWidth : stripWidth }
        let traveled = (CGFloat(elapsed) * speed).truncatingRemainder(dividingBy: pass)
        return leftToRight ? -contentWidth + traveled : stripWidth - traveled
    }

    /// The strip's frame: the full width of `visible`, hugging one edge.
    nonisolated static func stripFrame(in visible: CGRect, edge: Edge, height: CGFloat) -> CGRect {
        let originY = edge == .top ? visible.maxY - height : visible.minY
        return CGRect(x: visible.minX, y: originY, width: visible.width, height: height)
    }

    // MARK: NoticePresenter

    /// Draws `profiles[0]` only: one crawl item per notice.
    public func show(_ notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        items.removeValue(forKey: notice.id)?.countdown.stop()
        guard let profile = profiles.first else { return }
        let (keys, frames) = placement(for: profile)
        guard !keys.isEmpty else {
            apply(model.remove(notice.id), layer: profile.layer, frames: frames)
            return
        }
        let countdown = DismissCountdown()
        items[notice.id] = Item(notice: notice, actions: actions, countdown: countdown)
        apply(model.show(notice.id, on: keys), layer: profile.layer, frames: frames)
        if keys.contains(where: { strips[$0]?.view.isHovered == true }) {
            countdown.setPaused(true, for: .hover)
        }
        countdown.start(after: profile.autoDismiss) { [weak self] in self?.items[notice.id]?.actions.close() }
    }

    public func remove(id: String) {
        guard let item = items.removeValue(forKey: id) else { return }
        item.countdown.stop()
        apply(model.remove(id), layer: .floating, frames: [:])
    }

    /// In place where it can be: strips the old and new notice share keep
    /// its slot; a change of edge or of screens moves it, closing any strip
    /// left empty.
    public func replace(oldID: String, with notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        guard var item = items[oldID], let profile = profiles.first else {
            remove(id: oldID)
            show(notice, profiles: profiles, actions: actions)
            return
        }
        let (keys, frames) = placement(for: profile)
        guard !keys.isEmpty else {
            remove(id: oldID)
            return
        }
        if oldID != notice.id {
            items.removeValue(forKey: notice.id)?.countdown.stop()
        }
        items[oldID] = nil
        item.notice = notice
        item.actions = actions
        items[notice.id] = item
        apply(model.replace(oldID, with: notice.id, on: keys), layer: profile.layer, frames: frames)
        item.countdown.start(after: profile.autoDismiss) { [weak self] in self?.items[notice.id]?.actions.close() }
    }

    // MARK: Strips

    /// The strips a profile runs on now, with the visible frame of each.
    private func placement(for profile: NoticeProfile) -> ([StripKey], [StripKey: CGRect]) {
        let edge = Edge(profile.position)
        var frames: [StripKey: CGRect] = [:]
        let keys = screens(rules().screens).map { screen in
            let key = StripKey(displayID: screen.displayID, edge: edge)
            frames[key] = screen.visibleFrame
            return key
        }
        return (keys, frames)
    }

    private func apply(_ change: CrawlModel.Change, layer: NoticeProfile.Layer, frames: [StripKey: CGRect]) {
        for key in change.closed {
            if let strip = strips.removeValue(forKey: key) {
                windowing.dismiss(strip.panel)
            }
        }
        for key in change.opened {
            makeStrip(key, layer: layer, visibleFrame: frames[key])
        }
        for key in change.opened.union(change.refreshed) {
            refresh(key)
        }
        if strips.isEmpty {
            timer?.invalidate()
            timer = nil
        } else {
            startTimerIfNeeded()
        }
    }

    private func makeStrip(_ key: StripKey, layer: NoticeProfile.Layer, visibleFrame: CGRect?) {
        let panel = NoticePanel(layer: layer, hideFromSharing: rules().hideFromScreenSharing)
        let view = CrawlStripView()
        panel.contentView = view
        let strip = Strip(panel: panel, view: view)
        view.onHoverChange = { [weak self] hovered in
            guard let self else { return }
            for id in self.model.ids(on: key) {
                self.items[id]?.countdown.setPaused(hovered, for: .hover)
            }
        }
        view.onClick = { [weak self] index in
            guard let self else { return }
            let ids = self.model.ids(on: key)
            guard ids.indices.contains(index) else { return }
            self.items[ids[index]]?.actions.act()
        }
        strips[key] = strip
        if let visibleFrame {
            panel.setFrame(Self.stripFrame(in: visibleFrame, edge: key.edge, height: Self.stripHeight), display: false)
        }
        windowing.present(panel)
    }

    /// New content: redraw it and start its pass over.
    private func refresh(_ key: StripKey) {
        guard let strip = strips[key] else { return }
        strip.view.setNotices(model.ids(on: key).compactMap { items[$0]?.notice })
        strip.elapsed = 0
        strip.leftToRight = rules().crawl.leftToRight
        place(strip)
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: Self.frameInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advance(by: Self.frameInterval) }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// One frame. The timer calls this; tests call it directly.
    func advance(by interval: TimeInterval) {
        for strip in strips.values where !strip.view.isHovered {
            strip.elapsed += interval
            place(strip)
        }
    }

    private func place(_ strip: Strip) {
        strip.view.setContentX(Self.offset(
            elapsed: strip.elapsed, speed: Self.speed, contentWidth: strip.view.contentWidth,
            stripWidth: strip.view.bounds.width, leftToRight: strip.leftToRight))
    }

    /// Refits every strip to its screen after a display was added, removed
    /// or rearranged.
    func screensDidChange() {
        let visible = Dictionary(
            screens(.all).map { ($0.displayID, $0.visibleFrame) }, uniquingKeysWith: { first, _ in first })
        for (key, strip) in strips {
            guard let frame = visible[key.displayID] else { continue }
            strip.panel.setFrame(Self.stripFrame(in: frame, edge: key.edge, height: Self.stripHeight), display: true)
            place(strip)
        }
    }

    // MARK: Test hooks

    /// Whether the frame timer is running.
    var isAnimating: Bool { timer != nil }

    func elapsed(of key: StripKey) -> TimeInterval? { strips[key]?.elapsed }

    func leftToRight(of key: StripKey) -> Bool? { strips[key]?.leftToRight }
}

/// One strip: a themed bar with the notices in a row that slides across it.
@MainActor
final class CrawlStripView: NSView {

    var onHoverChange: ((Bool) -> Void)?
    /// The index of the notice clicked, in the order last set.
    var onClick: ((Int) -> Void)?
    private(set) var isHovered = false

    private let background = ThemedBox(fill: .elevatedSurface, stroke: .outline, cornerRadius: 0)
    private let row = NSStackView()
    private var labels: [NSTextField] = []

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = true
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)
        row.orientation = .horizontal
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = true
        addSubview(row)
        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    var contentWidth: CGFloat { row.frame.width }

    func setNotices(_ notices: [Notice]) {
        for view in row.arrangedSubviews {
            row.removeView(view)
        }
        labels = notices.map { notice in
            let label = ThemedLabel(role: .primaryText, textRole: .body, weight: .semibold)
            label.stringValue = [notice.title, notice.body].compactMap { $0 }.filter { !$0.isEmpty }
                .joined(separator: " — ")
            label.lineBreakMode = .byClipping
            return label
        }
        for (index, label) in labels.enumerated() {
            if index > 0 {
                let bullet = ThemedLabel(role: .secondaryText, textRole: .body)
                bullet.stringValue = "•"
                row.addArrangedSubview(bullet)
            }
            row.addArrangedSubview(label)
        }
        row.layoutSubtreeIfNeeded()
        let size = row.fittingSize
        row.frame.size = size
        setAccessibilityLabel(labels.map(\.stringValue).joined(separator: ". "))
    }

    func setContentX(_ originX: CGFloat) {
        row.setFrameOrigin(NSPoint(x: originX, y: ((bounds.height - row.frame.height) / 2).rounded()))
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) == nil ? nil : self
    }

    override func mouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard bounds.contains(point) else { return }
        // The nearest notice to the click, so a click on a bullet or in a gap
        // still means the notice beside it.
        let inRow = row.convert(point, from: self)
        let nearest = labels.enumerated().min { lhs, rhs in
            Self.distance(inRow.x, to: lhs.element.frame) < Self.distance(inRow.x, to: rhs.element.frame)
        }
        if let nearest, Self.distance(inRow.x, to: nearest.element.frame) <= row.spacing {
            onClick?(nearest.offset)
        }
    }

    private static func distance(_ originX: CGFloat, to frame: CGRect) -> CGFloat {
        if originX < frame.minX { return frame.minX - originX }
        if originX > frame.maxX { return originX - frame.maxX }
        return 0
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { setHovered(true) }

    override func mouseExited(with event: NSEvent) { setHovered(false) }

    private func setHovered(_ hovered: Bool) {
        guard hovered != isHovered else { return }
        isHovered = hovered
        onHoverChange?(hovered)
    }
}
