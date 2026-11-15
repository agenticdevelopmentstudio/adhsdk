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

/// What the privacy toolbar shows: every privacy setting a page or the
/// agent is subject to, always, each with its symbol and whether the thing
/// its title names is on now, given the pane's effective settings and its
/// pause state. The toolbar draws on green and off red, one rule for every
/// item: "Keyboard" is on while the page gets the keyboard, "Hide Images" is
/// on while the images are hidden. So red never means "kept from the page";
/// it means the named thing is off, and the label beside it says so.
@MainActor
enum BrowserPrivacyStatus {

    struct Item: Equatable {
        let symbol: String
        let title: String
        /// Whether the thing `title` names is on: the page's keyboard, the
        /// agent's access, the concealing of the privacy words, the hiding of
        /// images. Green while true, red while false.
        let isOn: Bool
        /// What the item says beside its title: "On", "Off", or a choice's name.
        var state: String?

        var text: String { "\(title): \(state ?? (isOn ? "On" : "Off"))" }
    }

    /// `agentPrivacy` is what Agent Privacy means for the front page now
    /// (`WebBrowserPaneViewController.agentPrivacy()`), not the switch alone:
    /// Privacy Words is on only while the words are being applied, so a pane
    /// with no vault, words the keychain will not give up without a prompt,
    /// or conflicting words shows it off, with the reason as its state.
    static func items(settings: SettingsStore, isPaused: Bool, agentPrivacy: BrowserAgentPrivacy) -> [Item] {
        let live = !isPaused
        let agentPaused = isPaused && settings.get(UserSettings.browserPrivacyAgentWhilePaused) == .paused
        let access = settings.get(UserSettings.browserPrivacyAgentAccess)
        let thirdParty = settings.get(UserSettings.browserPrivacyThirdPartyContent)
        return [
            Item(symbol: isPaused ? "pause.circle.fill" : "play.circle", title: "Events", isOn: live,
                 state: isPaused ? "Paused" : "On"),
            Item(symbol: "keyboard", title: "Keyboard",
                 isOn: live && settings.get(UserSettings.browserPrivacyKeyboard) != .block),
            Item(symbol: "computermouse", title: "Mouse",
                 isOn: live && settings.get(UserSettings.browserPrivacyMouse) != .block),
            Item(symbol: "cursorarrow.motionlines", title: "Tracking",
                 isOn: live && settings.get(UserSettings.browserPrivacyPointerTracking) == .always),
            Item(symbol: "hand.draw", title: "Drag and Drop",
                 isOn: live && settings.get(UserSettings.browserPrivacyDragAndDrop)),
            Item(symbol: "macwindow", title: "Activation",
                 isOn: live && !settings.get(UserSettings.browserPrivacyHideActivation)),
            Item(symbol: agentPaused ? "pause.circle" : access.symbolName, title: "Agent",
                 isOn: !agentPaused && access != .hidden,
                 state: agentPaused ? "Paused" : access.menuTitle),
            Item(symbol: "puzzlepiece.extension", title: "Third-Party", isOn: thirdParty == .allow,
                 state: thirdParty == .allow ? "On" : thirdParty == .blockScripts ? "No Scripts" : "Off"),
            Item(symbol: "circle.hexagongrid", title: "Cookies",
                 isOn: settings.get(UserSettings.browserAcceptsCookies)),
            privacyWordsItem(agentPrivacy),
            Item(symbol: "eye.slash", title: "Hide Images",
                 isOn: settings.get(UserSettings.browserPrivacyHideImages))
        ]
    }

    private static func privacyWordsItem(_ privacy: BrowserAgentPrivacy) -> Item {
        let state: String
        switch privacy {
        case .off: state = "Off"
        case .enabled: state = "On"
        case .unavailable: state = "Unavailable"
        case .conflicting: state = "Conflicting"
        }
        var isApplied = false
        if case .enabled = privacy { isApplied = true }
        return Item(symbol: "text.badge.xmark", title: "Privacy Words", isOn: isApplied, state: state)
    }

    static func text(settings: SettingsStore, isPaused: Bool, agentPrivacy: BrowserAgentPrivacy) -> String {
        items(settings: settings, isPaused: isPaused, agentPrivacy: agentPrivacy)
            .map(\.text).joined(separator: "  ·  ")
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
