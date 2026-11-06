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
            case .topLeft, .topCenter, .topRight: self = .top
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
        var strips: [StripKey]
        let countdown: DismissCountdown
    }

    private final class Strip {
        let panel: NoticePanel
        let view: CrawlStripView
        var ids: [String] = []
        var elapsed: TimeInterval = 0

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
    public private(set) var shownIDs: [String] = []
    private var items: [String: Item] = [:]
    private var strips: [StripKey: Strip] = [:]
    private var timer: Timer?

    public init(rules: @escaping @MainActor () -> NoticeRoutingRules) {
        self.rules = rules
    }

    isolated deinit {
        timer?.invalidate()
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

    public func show(_ notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        if items[notice.id] != nil {
            remove(id: notice.id)
        }
        let edge = Edge(profile.position)
        let keys = ScreenSelector.current(for: profile.screens).map {
            StripKey(displayID: $0.noticeDisplayID, edge: edge)
        }
        guard !keys.isEmpty else { return }
        let countdown = DismissCountdown()
        items[notice.id] = Item(notice: notice, actions: actions, strips: keys, countdown: countdown)
        shownIDs.append(notice.id)
        for key in keys {
            let strip = strips[key] ?? makeStrip(key, layer: profile.layer)
            strip.ids.append(notice.id)
            refresh(strip)
            if strip.view.isHovered {
                countdown.setPaused(true, for: .hover)
            }
        }
        countdown.start(after: profile.autoDismiss) { [weak self] in self?.items[notice.id]?.actions.close() }
        startTimerIfNeeded()
    }

    public func remove(id: String) {
        guard let item = items.removeValue(forKey: id) else { return }
        item.countdown.stop()
        shownIDs.removeAll { $0 == id }
        for key in item.strips {
            guard let strip = strips[key] else { continue }
            strip.ids.removeAll { $0 == id }
            if strip.ids.isEmpty {
                close(key)
            } else {
                refresh(strip)
            }
        }
        if strips.isEmpty {
            timer?.invalidate()
            timer = nil
        }
    }

    public func replace(oldID: String, with notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        guard var item = items.removeValue(forKey: oldID), item.strips.allSatisfy({ $0.edge == Edge(profile.position) })
        else {
            remove(id: oldID)
            show(notice, profile: profile, actions: actions)
            return
        }
        if oldID != notice.id {
            remove(id: notice.id)
        }
        item.notice = notice
        item.actions = actions
        items[notice.id] = item
        if let index = shownIDs.firstIndex(of: oldID) {
            shownIDs[index] = notice.id
        }
        item.countdown.start(after: profile.autoDismiss) { [weak self] in self?.items[notice.id]?.actions.close() }
        for key in item.strips {
            guard let strip = strips[key] else { continue }
            strip.ids = strip.ids.map { $0 == oldID ? notice.id : $0 }
            refresh(strip)
        }
    }

    // MARK: Strips

    private func makeStrip(_ key: StripKey, layer: NoticeProfile.Layer) -> Strip {
        let panel = NoticePanel(layer: layer, hideFromSharing: rules().hideFromScreenSharing)
        let view = CrawlStripView()
        panel.contentView = view
        let strip = Strip(panel: panel, view: view)
        view.onHoverChange = { [weak self, weak strip] hovered in
            guard let self, let strip else { return }
            for id in strip.ids {
                self.items[id]?.countdown.setPaused(hovered, for: .hover)
            }
        }
        view.onClick = { [weak self, weak strip] index in
            guard let self, let strip, strip.ids.indices.contains(index) else { return }
            self.items[strip.ids[index]]?.actions.act()
        }
        strips[key] = strip
        if let screen = NSScreen.screens.first(where: { $0.noticeDisplayID == key.displayID }) {
            panel.setFrame(
                Self.stripFrame(in: screen.visibleFrame, edge: key.edge, height: Self.stripHeight), display: false)
        }
        panel.orderFrontRegardless()
        return strip
    }

    private func refresh(_ strip: Strip) {
        let notices = strip.ids.compactMap { items[$0]?.notice }
        strip.view.setNotices(notices)
        place(strip)
    }

    private func close(_ key: StripKey) {
        guard let strip = strips.removeValue(forKey: key) else { return }
        strip.panel.orderOut(nil)
        strip.panel.close()
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: Self.frameInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advance(by: Self.frameInterval) }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func advance(by interval: TimeInterval) {
        for strip in strips.values where !strip.view.isHovered {
            strip.elapsed += interval
            place(strip)
        }
    }

    private func place(_ strip: Strip) {
        strip.view.setContentX(Self.offset(
            elapsed: strip.elapsed, speed: Self.speed, contentWidth: strip.view.contentWidth,
            stripWidth: strip.view.bounds.width, leftToRight: rules().crawlLeftToRight))
    }
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
