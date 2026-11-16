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

    /// "Hide distracting items", at the box's trailing end on every site
    /// (recipe `workspace/browser/element-picker`). The pane sets its target.
    let hideItemsButton = BrowserHideItemsButton()

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
        addSubview(hideItemsButton)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            field.trailingAnchor.constraint(equalTo: hideItemsButton.leadingAnchor, constant: -4),
            field.centerYAnchor.constraint(equalTo: centerYAnchor),
            hideItemsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            hideItemsButton.centerYAnchor.constraint(equalTo: centerYAnchor)
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

/// The address box's trailing "Hide distracting items" button: a borderless
/// symbol, `eye.slash`, that turns into an accent-tinted `stop.circle`
/// ("Stop selecting") while the pane is in selecting mode. It keeps the
/// symbol it shows, which an `NSImage` made from a symbol does not say.
/// The privacy toolbar's "Hide elements from agent" is the same button with
/// its own idle symbol, tooltip and identifier (`BrowserHideFromAgentButton`).
@MainActor
class BrowserHideItemsButton: NSButton {

    static let idleSymbol = "eye.slash"
    static let idleToolTip = "Hide distracting items"
    static let selectingSymbol = "stop.circle"
    static let selectingToolTip = "Stop selecting"

    /// The SF Symbol showing now.
    private(set) var symbolName = BrowserHideItemsButton.idleSymbol
    /// What the button shows while not selecting.
    let idleSymbolName: String
    let idleToolTipText: String

    init(idleSymbol: String = BrowserHideItemsButton.idleSymbol,
         idleToolTip: String = BrowserHideItemsButton.idleToolTip,
         identifier: String = "browser.hide-items") {
        idleSymbolName = idleSymbol
        idleToolTipText = idleToolTip
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isBordered = false
        bezelStyle = .regularSquare
        imagePosition = .imageOnly
        symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        setAccessibilityIdentifier(identifier)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        showSelecting(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// The stop icon while `selecting`, the normal one otherwise; the
    /// tooltip and the accessibility label follow.
    func showSelecting(_ selecting: Bool) {
        let symbol = selecting ? Self.selectingSymbol : idleSymbolName
        let tip = selecting ? Self.selectingToolTip : idleToolTipText
        symbolName = symbol
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: tip)
        toolTip = tip
        setAccessibilityLabel(tip)
        contentTintColor = selecting ? .controlAccentColor : nil
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
        let tracking = settings.get(UserSettings.browserPrivacyPointerTracking)
        return [
            Item(symbol: isPaused ? "pause.circle.fill" : "play.circle", title: "Events", isOn: live,
                 state: isPaused ? "Paused" : "On"),
            Item(symbol: "keyboard", title: "Keyboard",
                 isOn: live && settings.get(UserSettings.browserPrivacyKeyboard) != .block),
            Item(symbol: "computermouse", title: "Mouse",
                 isOn: live && settings.get(UserSettings.browserPrivacyMouse) != .block),
            // `whenFocused` is on only part of the time, so it is off (red),
            // as No Scripts is, and says which part.
            Item(symbol: "cursorarrow.motionlines", title: "Tracking", isOn: live && tracking == .always,
                 state: live && tracking == .whenFocused ? "Focused Only" : nil),
            Item(symbol: "hand.draw", title: "Drag and Drop",
                 isOn: live && settings.get(UserSettings.browserPrivacyDragAndDrop)),
            Item(symbol: "macwindow", title: "Activation",
                 isOn: live && !settings.get(UserSettings.browserPrivacyHideActivation)),
            Item(symbol: agentPaused ? "pause.circle" : access.symbolName, title: "Agent",
                 isOn: !agentPaused && access != .hidden,
                 state: agentPaused ? "Paused" : access.label),
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

    /// The settings `items` reads. A change to any other `browser.` key
    /// leaves the strip as it is, so the pane rebuilds it only for these.
    static let settingNames: Set<String> = [
        UserSettings.browserPrivacyKeyboard.name,
        UserSettings.browserPrivacyMouse.name,
        UserSettings.browserPrivacyPointerTracking.name,
        UserSettings.browserPrivacyDragAndDrop.name,
        UserSettings.browserPrivacyHideActivation.name,
        UserSettings.browserPrivacyAgentAccess.name,
        UserSettings.browserPrivacyAgentWhilePaused.name,
        UserSettings.browserPrivacyThirdPartyContent.name,
        UserSettings.browserAcceptsCookies.name,
        UserSettings.browserAgentPrivacy.name,
        UserSettings.browserPrivacyHideImages.name,
        UserSettings.browserPrivacyShowToolbar.name
    ]
}

extension BrowserAgentAccess {

    /// The SF Symbol the privacy strip's Agent item shows for this access.
    var symbolName: String {
        switch self {
        case .full: "cursorarrow.click.2"
        case .readOnly: "text.magnifyingglass"
        case .hidden: "nosign"
        }
    }
}
