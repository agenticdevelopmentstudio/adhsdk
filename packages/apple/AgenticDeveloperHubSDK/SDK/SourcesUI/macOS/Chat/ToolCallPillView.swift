import AppKit
import AgenticDeveloperHubSDK

/// One `CommandActivity` as a bordered pill in the transcript: the command's
/// name, tinted `.info` while it runs, `.success` when its result says `ok`,
/// and `.danger` otherwise.
///
/// A pill is built per activity and thrown away on the next transcript
/// rebuild — the same lifecycle `MessageBubbleView` has — so it holds no
/// update path of its own. What it does hold is a `ThemePaletteObserver`, so
/// a pill already on screen recolors on a live theme change rather than
/// waiting for the next chat event to rebuild it.
@MainActor
public final class ToolCallPillView: NSView, Themeable {

    public let activity: CommandActivity

    private let label = NSTextField(labelWithString: "")
    private var themeObserver: ThemePaletteObserver?

    private static let horizontalPadding: CGFloat = 10
    private static let verticalPadding: CGFloat = 4
    private static let borderWidth: CGFloat = 1

    /// The rendered label text and color. Internal rather than public: they
    /// exist so tests can assert on what was painted without screenshotting,
    /// and a host has `activity` for everything else.
    var titleText: String { label.stringValue }
    var titleColor: NSColor? { label.textColor }

    /// The palette role this activity reads as. `.info` while running is the
    /// deliberate part: a running command is neither good news nor bad, and
    /// coloring it `.warning` would cry wolf on every tool call.
    var statusRole: ThemeRole {
        guard let result = activity.result else { return .info }
        return result.ok ? .success : .danger
    }

    public init(activity: CommandActivity) {
        self.activity = activity
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 9
        translatesAutoresizingMaskIntoConstraints = false

        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        addSubview(label)

        let hPad = Self.horizontalPadding
        let vPad = Self.verticalPadding
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hPad),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -hPad)
        ])

        themeObserver = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func applyTheme(_ palette: SemanticPalette) {
        let color = palette.nsColor(statusRole)
        label.stringValue = Self.title(for: activity)
        label.font = palette.font(.caption)
        label.textColor = color
        layer?.borderWidth = Self.borderWidth
        layer?.borderColor = color.cgColor
        layer?.backgroundColor = palette.nsColor(.elevatedSurface).cgColor
    }

    /// The command's name, plus the error message when one failed. A red pill
    /// with no words is a color the user has to decode; the message is what
    /// makes the failure legible — the same trade `MessageBubbleView` makes
    /// for a failed delivery.
    private static func title(for activity: CommandActivity) -> String {
        let name = activity.invocation.commandName
        guard let result = activity.result, !result.ok else { return name }
        guard let message = result.errorMessage, !message.isEmpty else { return name }
        return "\(name) — \(message)"
    }
}
