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
/// the auto-dismiss countdown, and so does being folded out of sight, or being
/// replied to; when it runs out the card calls `close`, which marks the notice
/// read.
///
/// A notice whose actions include a reply gets a reply field. It is the one
/// place a floating card takes typing: clicking into it lets the panel become
/// key, Return sends the reply, and Esc clears it and gives the keyboard back.
@MainActor
public final class NoticeCardView: NSView, Themeable, NSTextFieldDelegate {

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
    /// The reply field, when the notice has a reply action.
    private(set) var replyField: NoticeReplyField?
    private var replyActionID: String?

    /// Called when the pointer enters or leaves, after the card has resized
    /// its details, so a presenter can lay its stack out again.
    var onHoverChange: ((Bool) -> Void)?

    private let background = ThemedBox(fill: .elevatedSurface, stroke: .outline, cornerRadius: 10)
    private let stripe = NSView()
    private let iconView = NSImageView()
    private let actionRow = NSStackView()
    private let column = NSStackView()
    private var actionIDs: [String] = []
    private var observer: ThemePaletteObserver?
    private let countdown: DismissCountdown
    private(set) var isHovered = false

    public convenience init(notice: Notice, actions: NoticeCardActions, style: Style) {
        self.init(notice: notice, actions: actions, style: style,
                  scheduler: TimerCountdownScheduler(), clock: Date.init)
    }

    /// With the countdown's timers and clock injected, so expiry is tested
    /// without waiting.
    init(
        notice: Notice,
        actions: NoticeCardActions,
        style: Style,
        scheduler: CountdownScheduler,
        clock: @escaping () -> Date
    ) {
        self.notice = notice
        self.actions = actions
        self.style = style
        countdown = DismissCountdown(scheduler: scheduler, clock: clock)
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
        rebuildReplyField()
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

    private func rebuildActionButtons() {
        for button in actionButtons {
            actionRow.removeView(button)
        }
        // A reply action gets the reply field, not a button.
        let shown = notice.actions
            .filter { if case .reply = $0.kind { false } else { true } }
            .prefix(style.maxActions)
        actionIDs = shown.map(\.id)
        actionButtons = shown.enumerated().map { index, action in
            let button = ThemedActionButton(
                title: action.label, style: index == 0 ? .primary : .secondary,
                target: self, action: #selector(actionButtonClicked(_:)))
            button.tag = index
            // The panel never becomes key, so a button that waited for
            // activation would need two clicks.
            button.acceptsFirstClick = true
            return button
        }
        for button in actionButtons {
            actionRow.addArrangedSubview(button)
        }
        actionRow.isHidden = actionButtons.isEmpty
    }

    private func rebuildReplyField() {
        let reply = notice.actions.first { if case .reply = $0.kind { true } else { false } }
        guard let reply, case let .reply(placeholder) = reply.kind else {
            if let replyField {
                column.removeView(replyField)
                self.replyField = nil
            }
            replyActionID = nil
            return
        }
        replyActionID = reply.id
        let field = replyField ?? makeReplyField()
        field.placeholderString = placeholder ?? reply.label
        field.setAccessibilityLabel(reply.label)
        field.applyTheme(resolvedThemeScope.palette)
    }

    private func makeReplyField() -> NoticeReplyField {
        let field = NoticeReplyField()
        field.delegate = self
        field.onClick = { [weak self] in self?.beginReply() }
        field.translatesAutoresizingMaskIntoConstraints = false
        column.insertArrangedSubview(field, at: column.arrangedSubviews.firstIndex(of: actionRow) ?? 0)
        column.setCustomSpacing(8, after: field)
        field.widthAnchor.constraint(equalTo: column.widthAnchor).isActive = true
        replyField = field
        return field
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

    // MARK: Reply

    /// The user is about to type a reply: the panel may become key, and the
    /// card holds still until the reply is sent or cancelled.
    func beginReply() {
        guard replyField != nil else { return }
        if let panel = window as? NoticePanel {
            panel.allowKeyForReply = true
            panel.makeKey()
        }
        countdown.setPaused(true, for: .replying)
    }

    /// The reply was cancelled: the field empties, the panel gives up the
    /// keyboard, and the countdown carries on.
    func endReply() {
        replyField?.abortEditing()
        replyField?.stringValue = ""
        if let panel = window as? NoticePanel {
            panel.makeFirstResponder(nil)
            panel.allowKeyForReply = false
        }
        countdown.setPaused(false, for: .replying)
    }

    /// Puts the cursor in the reply field (the card was clicked, or a hotkey
    /// acted on a notice whose primary action is a reply).
    func focusReply() {
        guard let replyField else { return }
        beginReply()
        window?.makeFirstResponder(replyField)
    }

    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let replyField, control === replyField else { return false }
        switch commandSelector {
        case #selector(NSResponder.insertNewline(_:)):
            let text = replyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, let replyActionID else { return true }
            (window as? NoticePanel)?.allowKeyForReply = false
            countdown.setPaused(false, for: .replying)
            actions.respond(replyActionID, text)
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            endReply()
            return true
        default:
            return false
        }
    }

    // MARK: Auto-dismiss

    /// Starts the countdown, if the profile has one. It runs only while the
    /// card is visible and nobody is pointing at it; when it runs out the card
    /// calls `close`, once.
    func startAutoDismiss(after seconds: TimeInterval?) {
        countdown.start(after: seconds) { [weak self] in self?.actions.close() }
    }

    /// Whether the auto-dismiss timer is counting right now.
    var isCountdownRunning: Bool { countdown.isRunning }

    /// Cancels any countdown. A presenter calls this when it removes the card.
    func stop() {
        countdown.stop()
    }

    /// Folded behind the "+N more" pill (or back out of it). A card nobody
    /// can see must not expire unseen.
    func setInOverflow(_ hidden: Bool) {
        countdown.setPaused(hidden, for: .hidden)
    }

    /// The pointer is over another placement of this notice, on another
    /// screen: every copy holds still together.
    func setPeerHovered(_ hovered: Bool) {
        countdown.setPaused(hovered, for: .peerHover)
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
    /// acts on the notice rather than landing in the label. The reply field
    /// is the exception among text fields: a click there, or in the field
    /// editor inside it while editing, goes to the field.
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point) else { return nil }
        if let replyField, hit === replyField || hit.isDescendant(of: replyField) {
            return hit
        }
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

    func setHovered(_ hovered: Bool) {
        guard hovered != isHovered else { return }
        isHovered = hovered
        countdown.setPaused(hovered, for: .hover)
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

        for view in [titleRow, subtitleLabel, detailsLabel, actionRow] {
            column.addArrangedSubview(view)
        }
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

/// The reply field. A click into it tells the card first, so the panel is
/// allowed to become key before the field asks to be first responder.
@MainActor
final class NoticeReplyField: ThemedTextField {

    var onClick: (@MainActor () -> Void)?

    init() {
        super.init(string: "")
        lineBreakMode = .byTruncatingTail
        cell?.usesSingleLineMode = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        onClick?()
        super.mouseDown(with: event)
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
