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

/// The one line the privacy strip shows: whether the pane's events are
/// active or paused, what the agent may do, which kinds of event are
/// disabled, and what else is kept from the page, built from the pane's
/// effective settings and its pause state.
@MainActor
enum BrowserPrivacyStatus {

    static func text(settings: SettingsStore, isPaused: Bool, isAgentPrivacyOn: Bool) -> String {
        var sections: [String] = []
        let agentPaused = isPaused && settings.get(UserSettings.browserPrivacyAgentWhilePaused) == .paused
        if isPaused {
            sections.append("Paused: all events blocked")
        } else {
            sections.append("Active")
        }
        let access = settings.get(UserSettings.browserPrivacyAgentAccess)
        sections.append("Agent: " + (agentPaused ? "Paused" : access.menuTitle))
        if !isPaused {
            let disabled = disabledEvents(settings: settings)
            if !disabled.isEmpty { sections.append("Disabled: " + disabled.joined(separator: ", ")) }
        }
        var other: [String] = []
        switch settings.get(UserSettings.browserPrivacyThirdPartyContent) {
        case .allow: break
        case .blockScripts: other.append("No third-party scripts")
        case .blockAll: other.append("No third-party content")
        }
        if isAgentPrivacyOn { other.append("Privacy words on") }
        sections += other
        return sections.joined(separator: "  ·  ")
    }

    /// The kinds of event the page is kept from, in the settings' order.
    static func disabledEvents(settings: SettingsStore) -> [String] {
        var disabled: [String] = []
        if settings.get(UserSettings.browserPrivacyKeyboard) == .block { disabled.append("Keyboard") }
        if settings.get(UserSettings.browserPrivacyMouse) == .block { disabled.append("Mouse Events") }
        if settings.get(UserSettings.browserPrivacyPointerTracking) != .always { disabled.append("Mouse Tracking") }
        if !settings.get(UserSettings.browserPrivacyDragAndDrop) { disabled.append("Drag and Drop") }
        if settings.get(UserSettings.browserPrivacyHideActivation) { disabled.append("Activation") }
        return disabled
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
