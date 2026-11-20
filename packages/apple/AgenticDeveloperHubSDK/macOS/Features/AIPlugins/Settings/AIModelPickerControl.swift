import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import AIPluginKit

/// One "which model?" row: `<label> ⌄ : <model name>`.
///
/// The caret is a borderless `chevron.down` button and the name a borderless,
/// link-styled button; either opens ``ModelChooser`` in a popover anchored to
/// the caret. The name is the resolved one the caller supplies, else
/// ``chooseModelText``.
///
/// Everything it shows and does comes in through closures (dependency
/// injection, no globals), so the same row serves a settings panel bound to a
/// per-config preference, a daemon-backed panel and the AI Providers editor.
@MainActor
public final class AIModelPickerControl: NSView, SettingsViewProtocol {

    /// What the name reads when there is no model to show.
    public static let chooseModelText = "Choose a Model"

    private let titleLabel: NSTextField
    private let caretButton = NSButton()
    private let colonLabel = NSTextField(labelWithString: ":")
    private let nameButton = NSButton()

    private let displayName: @MainActor () -> String?
    private let context: @MainActor () -> ModelChooserContext?
    private let onChoose: @MainActor (String) -> Void
    /// The context `refresh()` last built. Building one resolves the
    /// provider's field values, which reads its API key from the Keychain, so
    /// the label reuses it until ``invalidateContext()``; only the chooser
    /// itself always builds a fresh one.
    private var cachedContext: ModelChooserContext?
    private var contextIsCurrent = false
    /// Redraws the name when any model list lands, so an alias or id shown raw
    /// on a cold cache takes its display name once the list is in.
    private var modelCacheObserver: UserSettingObserver<[String: ProviderModelList]>?

    /// - Parameters:
    ///   - label: the row's label, "AI Model" unless the caller names it.
    ///   - displayName: the model name to show; nil or empty reads ``chooseModelText``.
    ///   - context: what the chooser lists; nil leaves the row disabled.
    ///   - onChoose: called with every model chosen in the popover.
    public init(
        label: String = "AI Model",
        displayName: @escaping @MainActor () -> String?,
        context: @escaping @MainActor () -> ModelChooserContext?,
        onChoose: @escaping @MainActor (String) -> Void
    ) {
        self.titleLabel = NSTextField(labelWithString: label)
        self.displayName = displayName
        self.context = context
        self.onChoose = onChoose
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildLayout()
        observeTheme { view, palette in view.applyTheme(palette) }
        modelCacheObserver = UserSettingObserver(ProviderModelCache.setting) { [weak self] _ in
            self?.refresh()
        }
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Public surface

    /// The row's label, settable after construction.
    public var label: String {
        get { titleLabel.stringValue }
        set { titleLabel.stringValue = newValue }
    }

    /// Whether the caller allows choosing at all. A row is enabled only when
    /// this is true *and* there is a context to choose from.
    public var isChoosingAllowed = true { didSet { refresh() } }

    /// Whether the row can open the chooser now.
    public var isEnabled: Bool { nameButton.isEnabled }

    /// The text the name currently reads (a model name, or ``chooseModelText``).
    public var nameText: String { nameButton.title }

    /// The caret, which the popover points at; exposed for tests and hosts
    /// that align other rows to it.
    public var caret: NSButton { caretButton }

    /// Drops the cached context, so the next ``refresh()`` builds a new one.
    /// Call it when what the context describes changes: another provider, or
    /// its connection settings edited.
    public func invalidateContext() {
        contextIsCurrent = false
    }

    /// The cached context, built on first use after an invalidation.
    private func currentContext() -> ModelChooserContext? {
        if !contextIsCurrent {
            cachedContext = context()
            contextIsCurrent = true
        }
        return cachedContext
    }

    /// Re-reads the name and whether there is anything to choose from.
    public func refresh() {
        let model = displayName() ?? ""
        let context = currentContext()
        // Shown by its display name when the provider's manager knows it.
        let name = context?.displayName(for: model) ?? model
        nameButton.title = name.isEmpty ? Self.chooseModelText : name
        let enabled = isChoosingAllowed && context != nil
        caretButton.isEnabled = enabled
        nameButton.isEnabled = enabled
        applyTheme(resolvedThemeScope.palette)
    }

    /// Opens the chooser, as a click on the caret or the name does.
    public func openChooser() {
        guard isChoosingAllowed, let context = context() else { return }
        cachedContext = context
        contextIsCurrent = true
        ModelChooser.present(relativeTo: caretButton, context: context) { [weak self] model in
            self?.onChoose(model)
            self?.refresh()
        }
    }

    // MARK: - Layout

    private func buildLayout() {
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        colonLabel.setContentHuggingPriority(.required, for: .horizontal)

        caretButton.isBordered = false
        caretButton.bezelStyle = .inline
        caretButton.imagePosition = .imageOnly
        caretButton.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Choose a model")
        caretButton.imageScaling = .scaleProportionallyDown
        caretButton.setContentHuggingPriority(.required, for: .horizontal)
        caretButton.target = self
        caretButton.action = #selector(controlClicked)
        caretButton.setAccessibilityIdentifier("ai-model-picker.caret")

        nameButton.isBordered = false
        nameButton.bezelStyle = .inline
        nameButton.setButtonType(.momentaryChange)
        nameButton.lineBreakMode = .byTruncatingMiddle
        nameButton.alignment = .left
        nameButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameButton.target = self
        nameButton.action = #selector(controlClicked)
        nameButton.setAccessibilityIdentifier("ai-model-picker.name")
        nameButton.setAccessibilityTitleUIElement(titleLabel)

        let row = NSStackView(views: [titleLabel, caretButton, colonLabel, nameButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 4
        row.setCustomSpacing(8, after: colonLabel)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func applyTheme(_ palette: SemanticPalette) {
        let font = palette.font(.button)
        titleLabel.font = font
        colonLabel.font = font
        titleLabel.textColor = palette.primaryTextColor
        colonLabel.textColor = palette.primaryTextColor
        caretButton.contentTintColor = nameButton.isEnabled ? palette.accentColor : palette.tertiaryTextColor
        // A link: the accent colour, underlined, while it can be clicked.
        let enabled = nameButton.isEnabled
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: enabled ? palette.accentColor : palette.secondaryTextColor
        ]
        if enabled { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
        nameButton.attributedTitle = NSAttributedString(string: nameButton.title, attributes: attributes)
    }

    @objc private func controlClicked() { openChooser() }

    public override func resetCursorRects() {
        super.resetCursorRects()
        if nameButton.isEnabled {
            addCursorRect(convert(nameButton.bounds, from: nameButton), cursor: .pointingHand)
        }
    }
}
