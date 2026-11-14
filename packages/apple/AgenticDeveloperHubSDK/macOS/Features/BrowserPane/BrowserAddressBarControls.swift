import AppKit
import AgenticDeveloperHubSDKCore

/// The bordered box the address field sits in, as Chrome and Brave draw
/// theirs: a hairline border and a fill, with corners that follow Settings >
/// Appearance > Rounded corners (`CornerStyle`) as it changes.
@MainActor
final class BrowserAddressBox: NSView {

    /// The box's height; the address row is this plus its insets.
    static let height: CGFloat = 34
    /// The radius while rounded corners are preferred: a pill, half the height.
    static let roundedRadius: CGFloat = height / 2
    /// The radius while they are not: just off square, as a text field's.
    static let squareRadius: CGFloat = 4

    private var cornerObserver: UserSettingObserver<Bool>?

    init(field: NSTextField) {
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        setAccessibilityIdentifier("browser.address-box")
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.translatesAutoresizingMaskIntoConstraints = false
        addSubview(field)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            field.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cornerObserver = UserSettingObserver(UserSettings.preferRoundedCorners) { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        guard let layer else { return }
        layer.cornerRadius = CornerStyle.prefersRounded ? Self.roundedRadius : Self.squareRadius
        layer.borderWidth = 1
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer.borderColor = NSColor.separatorColor.cgColor
            layer.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
    }
}

/// The one line the privacy strip shows: what the pane's page is kept from
/// right now, built from the pane's effective settings and its pause state.
@MainActor
enum BrowserPrivacyStatus {

    static func text(settings: SettingsStore, isPaused: Bool, isAgentPrivacyOn: Bool) -> String {
        if isPaused {
            let agent = settings.get(UserSettings.browserPrivacyAgentWhilePaused) == .paused
                ? ", agent paused" : ""
            return "Paused: all events blocked" + agent
        }
        var parts: [String] = []
        if settings.get(UserSettings.browserPrivacyHideActivation) { parts.append("no activation events") }
        if settings.get(UserSettings.browserPrivacyKeyboard) == .block { parts.append("no keyboard events") }
        if settings.get(UserSettings.browserPrivacyMouse) == .block { parts.append("no mouse events") }
        switch settings.get(UserSettings.browserPrivacyPointerTracking) {
        case .always: break
        case .whenFocused: parts.append("pointer tracked only with focus")
        case .never: parts.append("no pointer tracking")
        }
        if !settings.get(UserSettings.browserPrivacyDragAndDrop) { parts.append("no drag and drop") }
        switch settings.get(UserSettings.browserPrivacyThirdPartyContent) {
        case .allow: break
        case .blockScripts: parts.append("no third-party scripts")
        case .blockAll: parts.append("no third-party content")
        }
        switch settings.get(UserSettings.browserPrivacyAgentAccess) {
        case .full: break
        case .readOnly: parts.append("agent read only")
        case .hidden: parts.append("hidden from the agent")
        }
        if isAgentPrivacyOn { parts.append("global and page privacy words") }
        return "Active: " + (parts.isEmpty ? "all events allowed" : parts.joined(separator: ", "))
    }
}

extension BrowserAgentAccess {

    /// The SF Symbol the agent visibility button shows for this access.
    var symbolName: String {
        switch self {
        case .full: "cursorarrow.click.2"
        case .readOnly: "text.magnifyingglass"
        case .hidden: "nosign"
        }
    }

    /// The button's tooltip and accessibility label.
    var visibilityDescription: String {
        switch self {
        case .full: "Agent can read and drive this page"
        case .readOnly: "Agent can read this page only"
        case .hidden: "This page is hidden from the agent"
        }
    }

    /// The menu item title.
    var menuTitle: String {
        switch self {
        case .full: "Read and Write"
        case .readOnly: "Read Only"
        case .hidden: "None"
        }
    }
}
