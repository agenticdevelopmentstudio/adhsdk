import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKNotifications

/// The sheet that edits one item of a style set. Works on a draft: Done hands
/// the draft to `onDone`, Cancel hands back nothing.
///
/// Which controls show follows the style (spec §NoticeProfile): position for
/// toast and alert, layer for everything but full screen and Notification
/// Center, the backdrop controls for full screen only.
@MainActor
final class NotificationItemEditor: NSViewController {

    typealias Styles = NotificationStylesSettingsPanel

    private(set) var draft: NoticeProfile
    private let controls: NoticeRulesControls
    private let onDone: (NoticeProfile) -> Void
    private let onCancel: () -> Void

    private(set) var stylePopup = NSPopUpButton()
    private(set) var positionPopup = NSPopUpButton()
    private(set) var layerPopup = NSPopUpButton()
    private(set) var blurSlider = NSSlider()
    private(set) var opacitySlider = NSSlider()
    private(set) var colorPopup = NSPopUpButton()
    private(set) var colorWell = NSColorWell()
    let doneButton: NSButton
    let cancelButton: NSButton

    private var positionRow = NSView()
    private var layerRow = NSView()
    private var fullScreenRows: [NSView] = []
    private let stack = NSStackView()

    /// The window the editor sits in while it is a sheet.
    private(set) weak var sheetWindow: NSWindow?
    private weak var parentWindow: NSWindow?

    init(
        item: NoticeProfile,
        store: SettingsStore,
        onDone: @escaping (NoticeProfile) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.draft = item
        // Its own controls: their targets live and die with this editor.
        self.controls = NoticeRulesControls(store: store)
        self.onDone = onDone
        self.onCancel = onCancel
        self.doneButton = NSButton(title: "Done", target: nil, action: nil)
        self.cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
        super.init(nibName: nil, bundle: nil)
        doneButton.target = self
        doneButton.action = #selector(donePressed)
        doneButton.keyEquivalent = "\r"
        cancelButton.target = self
        cancelButton.action = #selector(cancelPressed)
        cancelButton.keyEquivalent = "\u{1b}"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let root = NSView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            root.widthAnchor.constraint(greaterThanOrEqualToConstant: 380)
        ])
        buildRows()
        view = root
        refreshVisibility()
    }

    private func buildRows() {
        let styles = NoticeProfile.Style.allCases
        let styleRow = controls.row("Style", controls.popup(
            styles, selected: draft.style, title: Styles.styleTitle,
            onChange: { [weak self] style in
                self?.draft.style = style
                self?.refreshVisibility()
            }))
        stylePopup = Self.popup(in: styleRow)
        positionRow = controls.row("Position", controls.popup(
            NoticeProfile.Position.allCases, selected: draft.position, title: Styles.positionTitle,
            onChange: { [weak self] in self?.draft.position = $0 }))
        positionPopup = Self.popup(in: positionRow)
        layerRow = controls.row("Layer", controls.popup(
            NoticeProfile.Layer.allCases, selected: draft.layer, title: Styles.layerTitle,
            onChange: { [weak self] in self?.draft.layer = $0 }))
        layerPopup = Self.popup(in: layerRow)

        let blurRow = controls.slider(
            title: "Blur", range: 0...100, format: { "\(Int($0.rounded())) %" },
            get: { draft.fullScreen.blur * 100 },
            set: { [weak self] in self?.draft.fullScreen.blur = $0 / 100 })
        blurSlider = Self.slider(in: blurRow)
        let colorRow = controls.colorChoice(
            title: "Color", get: { draft.fullScreen.color },
            set: { [weak self] in self?.draft.fullScreen.color = $0 })
        colorPopup = Self.popup(in: colorRow)
        colorWell = Self.colorWell(in: colorRow)
        let opacityRow = controls.slider(
            title: "Opacity", range: 0...100, format: { "\(Int($0.rounded())) %" },
            get: { draft.fullScreen.opacity * 100 },
            set: { [weak self] in self?.draft.fullScreen.opacity = $0 / 100 })
        opacitySlider = Self.slider(in: opacityRow)
        fullScreenRows = [blurRow, colorRow, opacityRow]

        let buttons = NSStackView(views: [cancelButton, doneButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8

        for row in [styleRow, positionRow, layerRow] + fullScreenRows + [buttons] {
            stack.addArrangedSubview(row)
        }
        for row in [styleRow, positionRow, layerRow] + fullScreenRows {
            row.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        }
        // Each slider fills from the end of its own label, and "Blur" is
        // narrower than "Opacity"; start both at the same x so they read as
        // one column. The row spacer takes up the difference.
        opacitySlider.leadingAnchor.constraint(equalTo: blurSlider.leadingAnchor).isActive = true
        stack.setCustomSpacing(20, after: fullScreenRows[2])
        buttons.setHuggingPriority(.defaultLow, for: .horizontal)
    }

    /// Shows the rows the draft's style uses.
    private func refreshVisibility() {
        let style = draft.style
        positionRow.isHidden = !(style == .toast || style == .alert)
        layerRow.isHidden = style == .fullScreen || style == .system
        for row in fullScreenRows { row.isHidden = style != .fullScreen }
        fitWindowToRows()
    }

    /// A window only grows to fit required content; it never gives height
    /// back. So once rows hide, set its height to what is left, or the taller
    /// style's height stays as empty space under the buttons.
    private func fitWindowToRows() {
        guard let window = view.window else { return }
        let height = view.fittingSize.height
        let size = window.contentLayoutRect.size
        guard abs(size.height - height) > 0.5 else { return }
        window.setContentSize(NSSize(width: size.width, height: height))
    }

    // MARK: Sheet

    /// Presents the editor as a sheet on `window`.
    func present(on window: NSWindow) {
        let sheet = NSWindow(contentViewController: self)
        sheet.styleMask = [.titled]
        sheet.defaultButtonCell = doneButton.cell as? NSButtonCell
        sheetWindow = sheet
        parentWindow = window
        window.beginSheet(sheet)
    }

    @objc func donePressed() {
        onDone(draft)
        close()
    }

    @objc func cancelPressed() {
        onCancel()
        close()
    }

    private func close() {
        if let sheetWindow, let parentWindow { parentWindow.endSheet(sheetWindow) }
    }

    // MARK: Finding controls in a row

    private static func popup(in row: NSView) -> NSPopUpButton {
        descendants(of: row).compactMap { $0 as? NSPopUpButton }.first ?? NSPopUpButton()
    }

    private static func slider(in row: NSView) -> NSSlider {
        descendants(of: row).compactMap { $0 as? NSSlider }.first ?? NSSlider()
    }

    private static func colorWell(in row: NSView) -> NSColorWell {
        descendants(of: row).compactMap { $0 as? NSColorWell }.first ?? NSColorWell()
    }

    private static func descendants(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }
}
