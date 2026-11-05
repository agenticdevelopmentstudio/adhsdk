import UIKit
import AgenticDeveloperHubSDK

@MainActor
public final class MarkdownEditorToolbar: UIView {

    public static let height: CGFloat = 44

    private let modeControl = UISegmentedControl()
    private let helpButton = UIButton(type: .system)
    private let importButton = UIButton(type: .system)

    public var onModeChange: ((MarkdownEditorMode) -> Void)?
    public var onImport: (() -> Void)?
    var onSyntaxHelpRequested: (() -> Void)?

    public var availableModes: [MarkdownEditorMode] = MarkdownEditorMode.allCases {
        didSet { rebuildModeControl() }
    }

    public var mode: MarkdownEditorMode = .split {
        didSet { syncSelection() }
    }

    /// Whether the `?` button is in the strip. A host that surfaces markdown
    /// help somewhere of its own — a window toolbar, a slide-out pane — turns
    /// this off rather than showing the same help twice.
    public var showsHelpButton: Bool = true {
        didSet { helpButton.isHidden = !showsHelpButton }
    }

    /// Whether the `Open…` button is in the strip. A host with its own import
    /// command (a File-menu item, say) turns this off.
    public var showsImportButton: Bool = true {
        didSet { importButton.isHidden = !showsImportButton }
    }

    public init() {
        super.init(frame: .zero)

        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        helpButton.setTitle("?", for: .normal)
        helpButton.addTarget(self, action: #selector(helpTapped), for: .touchUpInside)
        importButton.setTitle("Open…", for: .normal)
        importButton.addTarget(self, action: #selector(importTapped), for: .touchUpInside)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [modeControl, spacer, helpButton, importButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        rebuildModeControl()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.uiColor(.elevatedSurface)
        helpButton.tintColor = palette.uiColor(.accent)
        importButton.tintColor = palette.uiColor(.accent)
    }

    public func presentSyntaxHelp(from presenter: PlatformViewController, palette: SemanticPalette) {
        let viewer = MarkdownViewerController(palette: palette)
        viewer.content = MarkdownSyntaxReference.markdown
        viewer.modalPresentationStyle = .formSheet
        presenter.present(viewer, animated: true)
    }

    private func rebuildModeControl() {
        modeControl.removeAllSegments()
        for (index, mode) in availableModes.enumerated() {
            modeControl.insertSegment(withTitle: mode.label, at: index, animated: false)
        }
        modeControl.isHidden = availableModes.count < 2
        syncSelection()
    }

    private func syncSelection() {
        guard let index = availableModes.firstIndex(of: mode) else {
            modeControl.selectedSegmentIndex = UISegmentedControl.noSegment
            return
        }
        modeControl.selectedSegmentIndex = index
    }

    @objc private func modeChanged() {
        let index = modeControl.selectedSegmentIndex
        guard availableModes.indices.contains(index) else { return }
        mode = availableModes[index]
        onModeChange?(mode)
    }

    @objc private func helpTapped() { onSyntaxHelpRequested?() }
    @objc private func importTapped() { onImport?() }
}
