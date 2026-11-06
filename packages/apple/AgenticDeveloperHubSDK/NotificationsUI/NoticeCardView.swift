import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// One notice as a card: a level stripe, the app icon, the title with an
/// urgency badge, the subtitle, up to three lines of details (all of them on
/// hover, or always in an alert), the action buttons, and snooze, archive and
/// close controls.
///
/// Clicking anywhere that is not a control acts on the notice. Hovering pauses
/// the auto-dismiss countdown; when it runs out the card calls `close`, which
/// marks the notice read.
@MainActor
public final class NoticeCardView: NSView, Themeable {

    public enum Style: Sendable {
        /// A compact card: two action buttons, details clamped until hovered.
        case toast
        /// A larger card: every action, full details.
        case alert

        var width: CGFloat { self == .toast ? 360 : 440 }
        var maxActions: Int { self == .toast ? 2 : .max }
        var detailLines: Int { self == .toast ? 3 : 0 }
    }

    public let style: Style
    public private(set) var notice: Notice
    private(set) var actions: NoticeCardActions

    let titleLabel = ThemedLabel(role: .primaryText, textRole: .body, weight: .semibold)
    let subtitleLabel = ThemedLabel(role: .secondaryText, textRole: .caption)
    let detailsLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let urgencyBadge = ThemedLabel(role: .warning, textRole: .caption, weight: .bold)
    private(set) var actionButtons: [ThemedActionButton] = []
    let snoozeButton = CardControlButton(symbol: "clock", label: "Snooze")
    let archiveButton = CardControlButton(symbol: "archivebox", label: "Archive")
    let closeButton = CardControlButton(symbol: "xmark", label: "Close")

    /// Called when the pointer enters or leaves, after the card has resized
    /// its details, so a presenter can lay its stack out again.
    var onHoverChange: ((Bool) -> Void)?

    private let background = ThemedBox(fill: .elevatedSurface, stroke: .outline, cornerRadius: 10)
    private let stripe = NSView()
    private let iconView = NSImageView()
    private let actionRow = NSStackView()
    private var actionIDs: [String] = []
    private var observer: ThemePaletteObserver?
    private var dismissTimer: Timer?
    private var remainingDismiss: TimeInterval?
    private(set) var isHovered = false

    public init(notice: Notice, actions: NoticeCardActions, style: Style) {
        self.notice = notice
        self.actions = actions
        self.style = style
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildLayout()
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
        update(notice: notice, actions: actions)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    // MARK: Content

    public func update(notice: Notice, actions: NoticeCardActions) {
        self.notice = notice
        self.actions = actions
        titleLabel.stringValue = notice.title
        subtitleLabel.stringValue = notice.subtitle ?? ""
        subtitleLabel.isHidden = (notice.subtitle ?? "").isEmpty
        detailsLabel.stringValue = notice.body ?? ""
        detailsLabel.isHidden = (notice.body ?? "").isEmpty
        urgencyBadge.stringValue = notice.urgency.rawValue.uppercased()
        urgencyBadge.isHidden = notice.urgency.rank < Notice.Urgency.soon.rank
        urgencyBadge.role = notice.urgency.rank >= Notice.Urgency.now.rank ? .danger : .warning
        iconView.image = Self.icon(for: notice)
        snoozeButton.isHidden = actions.snooze == nil
        archiveButton.isHidden = actions.archive == nil
        rebuildActionButtons()
        updateDetailLines()
        setAccessibilityLabel([notice.title, notice.subtitle, notice.body].compactMap { $0 }.joined(separator: ". "))
        applyTheme(resolvedThemeScope.palette)
    }

    public func applyTheme(_ palette: SemanticPalette) {
        stripe.layer?.backgroundColor = palette.nsColor(notice.level.themeRole).cgColor
        iconView.contentTintColor = palette.nsColor(.secondaryText)
        for button in [snoozeButton, archiveButton, closeButton] {
            button.contentTintColor = palette.nsColor(.secondaryText)
        }
    }

    /// Hook for the reply field, which arrives with the reply action.
    func focusReply() {}

    private func rebuildActionButtons() {
        for button in actionButtons {
            actionRow.removeView(button)
        }
        // Reply actions get a text field, not a button; that field is not
        // part of this card yet.
        let shown = notice.actions
            .filter { if case .reply = $0.kind { false } else { true } }
            .prefix(style.maxActions)
        actionIDs = shown.map(\.id)
        actionButtons = shown.enumerated().map { index, action in
            let button = ThemedActionButton(
                title: action.label, style: index == 0 ? .primary : .secondary,
                target: self, action: #selector(actionButtonClicked(_:)))
            button.tag = index
            return button
        }
        for button in actionButtons {
            actionRow.addArrangedSubview(button)
        }
        actionRow.isHidden = actionButtons.isEmpty
    }

    private func updateDetailLines() {
        detailsLabel.maximumNumberOfLines = isHovered ? 0 : style.detailLines
    }

    private static func icon(for notice: Notice) -> NSImage? {
        for candidate in [notice.app, notice.source].compactMap({ $0 }) {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: candidate) {
                return NSWorkspace.shared.icon(forFile: url.path)
            }
        }
        return NSImage(systemSymbolName: "bell.badge", accessibilityDescription: nil)
    }

    // MARK: Auto-dismiss

    /// Starts the countdown, if the profile has one. Paused while hovered.
    func startAutoDismiss(after seconds: TimeInterval?) {
        stop()
        remainingDismiss = seconds
        if !isHovered {
            resumeAutoDismiss()
        }
    }

    /// Cancels any countdown. A presenter calls this when it removes the card.
    func stop() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        remainingDismiss = nil
    }

    private func pauseAutoDismiss() {
        guard let timer = dismissTimer else { return }
        remainingDismiss = max(1, timer.fireDate.timeIntervalSinceNow)
        timer.invalidate()
        dismissTimer = nil
    }

    private func resumeAutoDismiss() {
        guard let remaining = remainingDismiss, dismissTimer == nil else { return }
        let timer = Timer(timeInterval: remaining, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.dismissTimer = nil
                self.remainingDismiss = nil
                self.actions.close()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        dismissTimer = timer
    }

    // MARK: Events

    @objc private func actionButtonClicked(_ sender: NSButton) {
        guard actionIDs.indices.contains(sender.tag) else { return }
        actions.respond(actionIDs[sender.tag], nil)
    }

    @objc private func snoozeClicked(_ sender: NSButton) {
        guard let snooze = actions.snooze else { return }
        let menu = SnoozeMenu.make { option in snooze(option) }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }

    @objc private func archiveClicked(_ sender: NSButton) {
        actions.archive?()
    }

    @objc private func closeClicked(_ sender: NSButton) {
        actions.close()
    }

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Everything but a control belongs to the card, so a click on a label
    /// acts on the notice rather than landing in the label.
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point) else { return nil }
        return hit is NSControl && !(hit is NSTextField) ? hit : self
    }

    public override func mouseDown(with event: NSEvent) {}

    public override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        actions.act()
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil))
    }

    public override func mouseEntered(with event: NSEvent) {
        setHovered(true)
    }

    public override func mouseExited(with event: NSEvent) {
        setHovered(false)
    }

    private func setHovered(_ hovered: Bool) {
        guard hovered != isHovered else { return }
        isHovered = hovered
        if hovered {
            pauseAutoDismiss()
        } else {
            resumeAutoDismiss()
        }
        updateDetailLines()
        onHoverChange?(hovered)
    }

    // MARK: Layout

    private func buildLayout() {
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)

        stripe.wantsLayer = true
        stripe.layer?.cornerRadius = 2
        stripe.translatesAutoresizingMaskIntoConstraints = false

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        urgencyBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        urgencyBadge.setContentHuggingPriority(.required, for: .horizontal)
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        detailsLabel.cell?.wraps = true
        detailsLabel.cell?.usesSingleLineMode = false
        detailsLabel.cell?.truncatesLastVisibleLine = true
        detailsLabel.lineBreakMode = .byWordWrapping
        detailsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        snoozeButton.target = self
        snoozeButton.action = #selector(snoozeClicked(_:))
        archiveButton.target = self
        archiveButton.action = #selector(archiveClicked(_:))
        closeButton.target = self
        closeButton.action = #selector(closeClicked(_:))

        let controls = NSStackView(views: [snoozeButton, archiveButton, closeButton])
        controls.spacing = 2
        controls.setHuggingPriority(.required, for: .horizontal)
        let titleRow = NSStackView(views: [titleLabel, urgencyBadge, controls])
        titleRow.spacing = 6
        titleRow.alignment = .firstBaseline

        actionRow.orientation = .horizontal
        actionRow.spacing = 8

        let column = NSStackView(views: [titleRow, subtitleLabel, detailsLabel, actionRow])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 4
        column.setCustomSpacing(10, after: detailsLabel)
        column.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stripe)
        addSubview(iconView)
        addSubview(column)

        let textWidth = style.width - 12 - 4 - 10 - 28 - 10 - 12
        detailsLabel.preferredMaxLayoutWidth = textWidth
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: style.width),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),

            stripe.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stripe.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stripe.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stripe.widthAnchor.constraint(equalToConstant: 4),

            iconView.leadingAnchor.constraint(equalTo: stripe.trailingAnchor, constant: 10),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            column.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            column.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            column.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            column.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 52),

            titleRow.widthAnchor.constraint(equalTo: column.widthAnchor),
            detailsLabel.widthAnchor.constraint(equalTo: column.widthAnchor)
        ])
    }
}

/// A borderless symbol button that works on the first click into an inactive
/// panel, which a non-activating notice panel always is.
final class CardControlButton: NSButton {

    init(symbol: String, label: String) {
        super.init(frame: .zero)
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        imagePosition = .imageOnly
        isBordered = false
        bezelStyle = .accessoryBarAction
        toolTip = label
        setAccessibilityLabel(label)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 18),
            heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

extension Notice.Level {
    /// The theme color a level is drawn in.
    var themeRole: ThemeRole {
        switch self {
        case .info: .info
        case .success: .success
        case .warning: .warning
        case .error: .danger
        }
    }
}
