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
