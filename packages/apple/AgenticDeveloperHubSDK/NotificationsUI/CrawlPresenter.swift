import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// Crawl: a thin strip along the edge the rules name on each selected screen,
/// its notices scrolling across it one after another, right to left unless the
/// rules say otherwise. The rules' crawl settings (speed, text size,
/// background, item opacity) style it; `rulesDidChange()` restyles live
/// strips. Hovering holds the strip (and the notices'
/// countdowns) still; clicking a notice acts on it. A strip goes away once it
/// has nothing left to show.
@MainActor
public final class CrawlPresenter: NoticePresenter {

    /// Which edge of the screen a strip runs along: the crawl setting's.
    typealias Edge = CrawlSettings.Edge

    struct StripKey: Hashable {
        let displayID: UInt32
        let edge: Edge
    }

    private struct Item {
        var notice: Notice
        var actions: NoticeCardActions
        let countdown: DismissCountdown
        var layer: NoticeProfile.Layer
    }

    private final class Strip {
        let panel: NoticePanel
        let view: CrawlStripView
        var elapsed: TimeInterval = 0
        /// Read from the rules when the content changes or the rules do, not
        /// on every frame.
        var leftToRight = false
        var speed: CGFloat = 80

        init(panel: NoticePanel, view: CrawlStripView) {
            self.panel = panel
            self.view = view
        }
    }

    /// The strip's height: the text plus 14 points, never under 28.
    nonisolated static func stripHeight(textSize: CGFloat) -> CGFloat {
        max(28, textSize + 14)
    }

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

    /// Draws `profiles[0]` only: one crawl item per notice. Edge, speed and
    /// look come from the rules' crawl settings, not from the item.
    public func show(_ notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        items.removeValue(forKey: notice.id)?.countdown.stop()
        guard let profile = profiles.first else { return }
        let (keys, frames) = placement()
        guard !keys.isEmpty else {
            apply(model.remove(notice.id), layer: profile.layer, frames: frames)
            return
        }
        let countdown = DismissCountdown()
        items[notice.id] = Item(notice: notice, actions: actions, countdown: countdown, layer: profile.layer)
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
        let (keys, frames) = placement()
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
        item.layer = profile.layer
        items[notice.id] = item
        apply(model.replace(oldID, with: notice.id, on: keys), layer: profile.layer, frames: frames)
        item.countdown.start(after: profile.autoDismiss) { [weak self] in self?.items[notice.id]?.actions.close() }
    }

    // MARK: Strips

    /// The strips a profile runs on now, with the visible frame of each.
    private func placement() -> ([StripKey], [StripKey: CGRect]) {
        let edge = rules().crawl.edge
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
        let view = CrawlStripView(settings: rules().crawl)
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
            panel.setFrame(
                Self.stripFrame(in: visibleFrame, edge: key.edge, height: Self.stripHeight(textSize: view.textSize)),
                display: false)
        }
        windowing.present(panel)
    }

    /// New content: redraw it and start its pass over.
    private func refresh(_ key: StripKey) {
        guard let strip = strips[key] else { return }
        strip.view.setNotices(model.ids(on: key).compactMap { items[$0]?.notice })
        strip.elapsed = 0
        let crawl = rules().crawl
        strip.leftToRight = crawl.leftToRight
        strip.speed = CGFloat(crawl.speed)
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
            elapsed: strip.elapsed, speed: strip.speed, contentWidth: strip.view.contentWidth,
            stripWidth: strip.view.bounds.width, leftToRight: strip.leftToRight))
    }

    /// Refits every strip to its screen after a display was added, removed
    /// or rearranged.
    func screensDidChange() {
        restyleStrips()
    }

    /// The crawl settings (or the rules around them) changed: strips whose
    /// edge or screens changed move, and every live strip restyles in place,
    /// keeping its place in the pass.
    public func rulesDidChange() {
        for id in model.order {
            guard let item = items[id] else { continue }
            let (keys, frames) = placement()
            guard Set(keys) != Set(model.keys(of: id)) else { continue }
            apply(model.replace(id, with: id, on: keys), layer: item.layer, frames: frames)
        }
        restyleStrips()
    }

    private func restyleStrips() {
        let visible = Dictionary(
            screens(.all).map { ($0.displayID, $0.visibleFrame) }, uniquingKeysWith: { first, _ in first })
        let crawl = rules().crawl
        for (key, strip) in strips {
            strip.view.apply(crawl)
            strip.leftToRight = crawl.leftToRight
            strip.speed = CGFloat(crawl.speed)
            if let frame = visible[key.displayID] {
                strip.panel.setFrame(
                    Self.stripFrame(in: frame, edge: key.edge, height: Self.stripHeight(textSize: strip.view.textSize)),
                    display: true)
            }
            place(strip)
        }
    }

    // MARK: Test hooks

    /// Whether the frame timer is running.
    var isAnimating: Bool { timer != nil }

    func elapsed(of key: StripKey) -> TimeInterval? { strips[key]?.elapsed }

    func leftToRight(of key: StripKey) -> Bool? { strips[key]?.leftToRight }

    func stripView(of key: StripKey) -> CrawlStripView? { strips[key]?.view }
}

/// One strip: a bar with the notices in a row that slides across it, styled
/// by the crawl settings and the live theme.
@MainActor
final class CrawlStripView: NSView {

    var onHoverChange: ((Bool) -> Void)?
    /// The index of the notice clicked, in the order last set.
    var onClick: ((Int) -> Void)?
    private(set) var isHovered = false

    let background = NSView()
    private let row = NSStackView()
    private var labels: [NSTextField] = []
    private var bullets: [NSTextField] = []
    private var notices: [Notice] = []
    private var settings: CrawlSettings
    private var palette: SemanticPalette = ThemePaletteObserver.currentPalette
    private var observer: ThemePaletteObserver?

    var textSize: CGFloat { CGFloat(settings.textSize) }
    /// How opaque the notices are, from the setting.
    var itemAlpha: CGFloat { row.alphaValue }
    /// The point sizes of the notices' text, in order.
    var labelFontSizes: [CGFloat] { labels.compactMap { $0.font?.pointSize } }
    /// Where the content's leading edge sits in the strip.
    var contentOriginX: CGFloat { row.frame.origin.x }

    init(settings: CrawlSettings) {
        self.settings = settings
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = true
        background.wantsLayer = true
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
        // Paints now, then follows the live theme.
        observer = ThemePaletteObserver(host: self) { [weak self] palette in
            self?.palette = palette
            self?.restyle()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// New settings: the notices keep their order, only the look changes.
    func apply(_ settings: CrawlSettings) {
        self.settings = settings
        restyle()
    }

    private func restyle() {
        background.isHidden = !settings.showsBackground
        // System is a dynamic color: resolve it under this view's appearance,
        // and again when the appearance changes (`viewDidChangeEffectiveAppearance`).
        effectiveAppearance.performAsCurrentDrawingAppearance {
            let color = settings.background.resolved(
                system: .windowBackgroundColor, themeRole: .elevatedSurface, palette: palette)
            background.layer?.backgroundColor = color.withAlphaComponent(settings.backgroundOpacity).cgColor
        }
        row.alphaValue = settings.itemOpacity
        let base = palette.font(.body, weight: .semibold)
        let font = NSFont(descriptor: base.fontDescriptor, size: textSize) ?? base
        for label in labels {
            label.font = font
            label.textColor = palette.nsColor(.primaryText)
        }
        for bullet in bullets {
            bullet.font = font
            bullet.textColor = palette.nsColor(.secondaryText)
        }
        refit()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        restyle()
    }

    private func refit() {
        row.layoutSubtreeIfNeeded()
        row.frame.size = row.fittingSize
    }

    var contentWidth: CGFloat { row.frame.width }

    func setNotices(_ notices: [Notice]) {
        self.notices = notices
        for view in row.arrangedSubviews {
            row.removeView(view)
        }
        labels = notices.map { notice in
            let label = NSTextField(labelWithString: [notice.title, notice.body].compactMap { $0 }
                .filter { !$0.isEmpty }.joined(separator: " — "))
            label.lineBreakMode = .byClipping
            return label
        }
        bullets = []
        for (index, label) in labels.enumerated() {
            if index > 0 {
                let bullet = NSTextField(labelWithString: "•")
                bullets.append(bullet)
                row.addArrangedSubview(bullet)
            }
            row.addArrangedSubview(label)
        }
        restyle()
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
