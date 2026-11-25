//
//  BrowserPrivacyStrip.swift
//  AgenticDeveloperHubSDK
//
//  Recipe: workspace/browser/browser-settings (the privacy toolbar).
//

import AppKit
import AgenticDeveloperHubSDKCore

/// What the privacy toolbar shows and what its buttons change: every privacy
/// setting a page or the agent is subject to, in the three groups of the
/// Privacy and Security tabs (General, Events, Agents).
///
/// Each item's label says its state ("Mouse: On"). An item is green while its
/// protection is on: Mouse is green while the page is kept from the mouse,
/// Hide Images while the images are hidden, Privacy Words while the words are
/// concealed. So green always means "this privacy setting is in force",
/// whichever way the setting is phrased.
@MainActor
enum BrowserPrivacyStatus {

    /// The toolbar's three groups, in order, matching the settings tabs.
    enum Group: Int, CaseIterable, Sendable {
        case general, events, agents

        var title: String {
            switch self {
            case .general: "General"
            case .events: "Events"
            case .agents: "Agents"
            }
        }
    }

    /// Which setting an item shows and changes.
    enum Kind: String, CaseIterable, Sendable {
        case thirdParty, cookies, hideImages
        case allEvents, keyboard, mouse, tracking, dragAndDrop, activation
        case agentAccess, readOnly, privacyWords

        var group: Group {
            switch self {
            case .thirdParty, .cookies, .hideImages: .general
            case .allEvents, .keyboard, .mouse, .tracking, .dragAndDrop, .activation: .events
            case .agentAccess, .readOnly, .privacyWords: .agents
            }
        }
    }

    /// One value of a multi-value item, for its pop-down menu.
    struct Choice: Equatable, Sendable {
        let title: String
        /// The setting's raw value.
        let value: String
        let isSelected: Bool
    }

    struct Item: Equatable {
        let kind: Kind
        let symbol: String
        let title: String
        /// Whether the thing `title` names is on: the page's keyboard, the
        /// agent's access, the concealing of the privacy words.
        let isOn: Bool
        /// Whether the item's protection is on, so it draws green.
        let isProtecting: Bool
        /// What the item says after its title: "On", "Off", or a choice's name.
        let state: String
        /// Whether a click can change it now.
        var isEnabled = true
        /// The values a click offers in a menu; empty for a plain toggle.
        var choices: [Choice] = []
        /// Why another setting decides this one now, for an item that is
        /// fixed by it rather than off limits: it draws at full strength,
        /// says why in its tooltip, and a click opens the privacy settings
        /// where that other setting is. A disabled button would draw its
        /// state too faintly to read.
        var lockedReason: String?

        var group: Group { kind.group }
        var text: String { "\(title): \(state)" }
        var identifier: String { "browser.privacy-strip.\(title.lowercased())" }
    }

    /// The items, in toolbar order.
    ///
    /// `agentPrivacy` is what Agent Privacy means for the front page now
    /// (`WebBrowserPaneViewController.agentPrivacy()`), not the switch alone:
    /// Privacy Words is on only while the words are being applied, so a pane
    /// with no vault, words the keychain will not give up without a prompt,
    /// or conflicting words shows it off, with the reason as its state.
    /// `cookiesLocked` is true while the pane shares its cookie jar, where
    /// the pane cannot have a cookie setting of its own.
    ///
    /// While every event is disabled, each event item shows Off and takes no
    /// clicks; its setting is kept, so enabling events again brings back
    /// whatever was set.
    static func items(
        settings: SettingsStore, isPaused: Bool, agentPrivacy: BrowserAgentPrivacy, cookiesLocked: Bool = false
    ) -> [Item] {
        let live = !isPaused
        let agentPaused = isPaused && settings.get(UserSettings.browserPrivacyAgentWhilePaused) == .paused
        let access = settings.get(UserSettings.browserPrivacyAgentAccess)
        let thirdParty = settings.get(UserSettings.browserPrivacyThirdPartyContent)
        let tracking = settings.get(UserSettings.browserPrivacyPointerTracking)
        let cookies = settings.get(UserSettings.browserAcceptsCookies)
        let hideImages = settings.get(UserSettings.browserPrivacyHideImages)

        func event(_ kind: Kind, _ symbol: String, _ title: String, _ isOn: Bool) -> Item {
            Item(kind: kind, symbol: symbol, title: title, isOn: live && isOn, isProtecting: !(live && isOn),
                 state: live && isOn ? "On" : "Off", isEnabled: live)
        }
        func toggle(_ kind: Kind, _ symbol: String, _ title: String, isOn: Bool, protectsWhenOn: Bool) -> Item {
            Item(kind: kind, symbol: symbol, title: title, isOn: isOn, isProtecting: isOn == protectsWhenOn,
                 state: isOn ? "On" : "Off")
        }

        var trackingItem = Item(
            kind: .tracking, symbol: "cursorarrow.motionlines", title: "Tracking",
            isOn: live && tracking == .always, isProtecting: !(live && tracking == .always),
            state: !live ? "Off" : trackingState(tracking), isEnabled: live)
        trackingItem.choices = BrowserPointerTracking.allCases.map {
            Choice(title: trackingState($0), value: $0.rawValue, isSelected: $0 == tracking)
        }
        var thirdPartyItem = Item(
            kind: .thirdParty, symbol: "puzzlepiece.extension", title: "Third-Party",
            isOn: thirdParty == .allow, isProtecting: thirdParty != .allow, state: thirdPartyState(thirdParty))
        thirdPartyItem.choices = BrowserThirdPartyContent.allCases.map {
            Choice(title: thirdPartyState($0), value: $0.rawValue, isSelected: $0 == thirdParty)
        }
        var cookiesItem = toggle(.cookies, "circle.hexagongrid", "Cookies", isOn: cookies, protectsWhenOn: false)
        if cookiesLocked {
            cookiesItem.lockedReason = "This tab shares its cookie jar, so the jar's cookie setting applies. "
                + "Set Storage to This Tab in the privacy settings to give it its own."
        }
        let agentOn = !agentPaused && access != .hidden
        var readOnly = toggle(.readOnly, "text.magnifyingglass", "Read Only",
                              isOn: access == .readOnly, protectsWhenOn: true)
        readOnly.isEnabled = access != .hidden

        return [
            thirdPartyItem,
            cookiesItem,
            toggle(.hideImages, "photo", "Hide Images", isOn: hideImages, protectsWhenOn: true),
            Item(kind: .allEvents, symbol: isPaused ? "pause.circle.fill" : "play.circle", title: "All Events",
                 isOn: live, isProtecting: isPaused, state: isPaused ? "Disabled" : "Enabled"),
            event(.keyboard, "keyboard", "Keyboard", settings.get(UserSettings.browserPrivacyKeyboard) != .block),
            event(.mouse, "computermouse", "Mouse", settings.get(UserSettings.browserPrivacyMouse) != .block),
            trackingItem,
            event(.dragAndDrop, "hand.draw", "Drag and Drop", settings.get(UserSettings.browserPrivacyDragAndDrop)),
            event(.activation, "macwindow", "Activation", !settings.get(UserSettings.browserPrivacyHideActivation)),
            Item(kind: .agentAccess, symbol: agentPaused ? "pause.circle" : access.symbolName, title: "Agent",
                 isOn: agentOn, isProtecting: !agentOn, state: agentPaused ? "Paused" : agentOn ? "On" : "Off"),
            readOnly,
            privacyWordsItem(agentPrivacy, isSwitchedOn: settings.get(UserSettings.browserAgentPrivacy))
        ]
    }

    private static func trackingState(_ tracking: BrowserPointerTracking) -> String {
        switch tracking {
        case .always: "On"
        case .whenFocused: "Focused Only"
        case .never: "Off"
        }
    }

    private static func thirdPartyState(_ content: BrowserThirdPartyContent) -> String {
        switch content {
        case .allow: "On"
        case .blockScripts: "No Scripts"
        case .blockAll: "Off"
        }
    }

    /// Whether any item's protection is on, which colours the privacy eye.
    static func isAnyProtecting(_ items: [Item]) -> Bool {
        items.contains(where: \.isProtecting)
    }

    /// Green while the words are concealed, and also while the switch is on
    /// but the words cannot be applied, since that is a protection asked for
    /// and not given, which the state names.
    private static func privacyWordsItem(_ privacy: BrowserAgentPrivacy, isSwitchedOn: Bool) -> Item {
        let state: String
        switch privacy {
        case .off: state = "Off"
        case .enabled: state = "On"
        case .unavailable: state = "Unavailable"
        case .conflicting: state = "Conflicting"
        }
        var isApplied = false
        if case .enabled = privacy { isApplied = true }
        return Item(kind: .privacyWords, symbol: "text.badge.xmark", title: "Privacy Words",
                    isOn: isApplied, isProtecting: isSwitchedOn, state: state)
    }

    /// What a click on a plain toggle `kind` writes to `settings`. All Events
    /// is the pane's own pause state, not a setting, so the pane handles it;
    /// it returns false for that and for a multi-value item.
    @discardableResult
    static func toggle(_ kind: Kind, in settings: SettingsStore) -> Bool {
        switch kind {
        case .keyboard: flip(UserSettings.browserPrivacyKeyboard, in: settings)
        case .mouse: flip(UserSettings.browserPrivacyMouse, in: settings)
        case .dragAndDrop: flip(UserSettings.browserPrivacyDragAndDrop, in: settings)
        case .activation: flip(UserSettings.browserPrivacyHideActivation, in: settings)
        case .cookies: flip(UserSettings.browserAcceptsCookies, in: settings)
        case .hideImages: flip(UserSettings.browserPrivacyHideImages, in: settings)
        case .privacyWords: flip(UserSettings.browserAgentPrivacy, in: settings)
        case .agentAccess:
            let access = settings.get(UserSettings.browserPrivacyAgentAccess)
            settings.set(access == .hidden ? BrowserAgentAccess.full : .hidden,
                         for: UserSettings.browserPrivacyAgentAccess)
        case .readOnly:
            let access = settings.get(UserSettings.browserPrivacyAgentAccess)
            guard access != .hidden else { return false }
            settings.set(access == .readOnly ? BrowserAgentAccess.full : .readOnly,
                         for: UserSettings.browserPrivacyAgentAccess)
        case .allEvents, .tracking, .thirdParty: return false
        }
        return true
    }

    /// Writes the choice `value` of multi-value item `kind` to `settings`.
    static func choose(_ value: String, for kind: Kind, in settings: SettingsStore) {
        switch kind {
        case .tracking:
            if let tracking = BrowserPointerTracking(rawValue: value) {
                settings.set(tracking, for: UserSettings.browserPrivacyPointerTracking)
            }
        case .thirdParty:
            if let content = BrowserThirdPartyContent(rawValue: value) {
                settings.set(content, for: UserSettings.browserPrivacyThirdPartyContent)
            }
        default: break
        }
    }

    private static func flip(_ key: UserSetting<Bool>, in settings: SettingsStore) {
        settings.set(!settings.get(key), for: key)
    }

    private static func flip(_ key: UserSetting<BrowserInputPolicy>, in settings: SettingsStore) {
        settings.set(settings.get(key) == .block ? BrowserInputPolicy.allow : .block, for: key)
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
        UserSettings.browserPrivacyShowToolbar.name,
        UserSettings.browserPrivacyStorageJar.name,
        UserSettings.browserPrivateBrowsing.name
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

/// The look every privacy toolbar button shares, the item buttons and Hide
/// from Agent alike: a symbol and a "Title: State" label, green while the
/// protection is on, on a bezel that always shows, so the row reads as a
/// toolbar of buttons rather than a line of text.
@MainActor
enum BrowserPrivacyStripStyle {

    static let font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

    /// The colour of a protection that is on: the items, Hide from Agent
    /// while it selects, and the privacy eye while any protection is on.
    static let protectingColor: NSColor = .systemGreen

    static func apply(to button: NSButton, symbol: String, text: String, isProtecting: Bool, hasMenu: Bool) {
        let color: NSColor = isProtecting ? protectingColor : .labelColor
        button.bezelStyle = .accessoryBarAction
        button.isBordered = true
        button.showsBorderOnlyWhileMouseInside = false
        button.controlSize = .small
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        button.contentTintColor = color
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        button.attributedTitle = NSAttributedString(
            string: hasMenu ? "\(text) ▾" : text,
            attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
        (button.cell as? NSButtonCell)?.lineBreakMode = .byTruncatingTail
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(labelCompressionResistance, for: .horizontal)
        if !button.constraints.contains(where: { $0.identifier == minimumWidthIdentifier }) {
            let floor = button.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth)
            floor.identifier = minimumWidthIdentifier
            floor.isActive = true
        }
    }

    /// How hard a label holds its full width: just under
    /// `windowSizeStayPut`, so a row short of room truncates its labels
    /// rather than growing the window. At `defaultHigh` the whole toolbar's
    /// labels outranked the window's size, and on a 1920-point screen a
    /// pane showing it made its project window 3028 points wide, with the
    /// Agent view control off the screen's edge.
    static let labelCompressionResistance = NSLayoutConstraint.Priority.dragThatCannotResizeWindow

    /// The narrowest a button gets: its symbol on its bezel, with the label
    /// truncated away. The tooltip and the accessibility label still carry
    /// the whole "Title: State".
    static let minimumWidth: CGFloat = 30
    private static let minimumWidthIdentifier = "browser.privacy-strip.minimum-width"
}

/// One privacy toolbar item: a button that toggles its setting, or pops up
/// its choices when it has several (`BrowserPrivacyStatus.Item.choices`).
@MainActor
final class BrowserPrivacyStripButton: NSButton {

    let item: BrowserPrivacyStatus.Item

    init(item: BrowserPrivacyStatus.Item, target: AnyObject?, action: Selector?) {
        self.item = item
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setButtonType(.momentaryPushIn)
        BrowserPrivacyStripStyle.apply(
            to: self, symbol: item.symbol, text: item.text, isProtecting: item.isProtecting,
            hasMenu: !item.choices.isEmpty)
        isEnabled = item.isEnabled
        toolTip = item.lockedReason.map { "\(item.text). \($0)" } ?? item.text
        self.target = target
        self.action = action
        setAccessibilityLabel(item.text)
        if let reason = item.lockedReason { setAccessibilityHelp(reason) }
        setAccessibilityValue(item.isOn ? "on" : "off")
        setAccessibilityIdentifier(item.identifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// The item's choices as a menu, each sending `action` to `target` with
    /// its raw value as the represented object, the current one checked.
    func choicesMenu(target: AnyObject, action: Selector) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        for choice in item.choices {
            let menuItem = NSMenuItem(title: choice.title, action: action, keyEquivalent: "")
            menuItem.target = target
            menuItem.representedObject = ChoiceTag(kind: item.kind, value: choice.value)
            menuItem.state = choice.isSelected ? .on : .off
            menuItem.setAccessibilityIdentifier("\(item.identifier).\(choice.value)")
            menu.addItem(menuItem)
        }
        return menu
    }

    /// Pops `menu` up under the button.
    func popUp(_ menu: NSMenu) {
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: bounds.maxY + 4), in: self)
    }

    /// What a choice's menu item carries back to the pane.
    final class ChoiceTag: NSObject {
        let kind: BrowserPrivacyStatus.Kind
        let value: String

        init(kind: BrowserPrivacyStatus.Kind, value: String) {
            self.kind = kind
            self.value = value
        }
    }
}

/// One group of the privacy toolbar: its buttons in a row on a faint rounded
/// ground inside a border, so the three groups read as three.
@MainActor
final class BrowserPrivacyStripGroupView: NSStackView {

    let group: BrowserPrivacyStatus.Group

    init(group: BrowserPrivacyStatus.Group) {
        self.group = group
        super.init(frame: .zero)
        orientation = .horizontal
        alignment = .centerY
        spacing = 2
        edgeInsets = NSEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        setHuggingPriority(.required, for: .horizontal)
        toolTip = group.title
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel(group.title)
        setAccessibilityIdentifier("browser.privacy-strip.\(group.title.lowercased())")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateGround()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateGround()
    }

    private func updateGround() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.08).cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
        }
    }
}
