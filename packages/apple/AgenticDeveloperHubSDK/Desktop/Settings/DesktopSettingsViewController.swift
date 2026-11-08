import AppKit
import Combine
import UniformTypeIdentifiers

/// The Desktop's own settings: color, photo, icon arrangement. Hosted by the app's Settings window.
@MainActor
public final class DesktopSettingsViewController: NSViewController {
    private let settings: DesktopSettings
    private var subscription: AnyCancellable?

    let colorWell = NSColorWell()
    let arrangePopUp = NSPopUpButton()
    let keepArrangedCheckbox = NSButton(checkboxWithTitle: "Keep arranged", target: nil, action: nil)
    let removePhotoButton = NSButton(title: "Remove", target: nil, action: nil)
    private let thumbnail = NSImageView()
    private let chooseButton = NSButton(title: "Choose…", target: nil, action: nil)

    private static let arrangements: [(title: String, value: DesktopIconArrangement)] = [
        ("Large Icons", .largeIcons), ("Small Icons", .smallIcons), ("List", .list)
    ]

    public init(settings: DesktopSettings = .shared) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func loadView() {
        colorWell.target = self
        colorWell.action = #selector(colorChanged(_:))
        colorWell.widthAnchor.constraint(equalToConstant: 44).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 24).isActive = true

        thumbnail.imageScaling = .scaleProportionallyUpOrDown
        thumbnail.wantsLayer = true
        thumbnail.layer?.borderWidth = 1
        thumbnail.layer?.borderColor = NSColor.separatorColor.cgColor
        thumbnail.widthAnchor.constraint(equalToConstant: 120).isActive = true
        thumbnail.heightAnchor.constraint(equalToConstant: 75).isActive = true
        chooseButton.target = self
        chooseButton.action = #selector(choosePhoto(_:))
        removePhotoButton.target = self
        removePhotoButton.action = #selector(removePhoto(_:))
        let photoButtons = NSStackView(views: [chooseButton, removePhotoButton])
        photoButtons.spacing = 8
        let photoColumn = NSStackView(views: [thumbnail, photoButtons])
        photoColumn.orientation = .vertical
        photoColumn.alignment = .leading
        photoColumn.spacing = 8

        for entry in Self.arrangements {
            arrangePopUp.addItem(withTitle: entry.title)
        }
        arrangePopUp.target = self
        arrangePopUp.action = #selector(arrangementChanged(_:))
        keepArrangedCheckbox.target = self
        keepArrangedCheckbox.action = #selector(keepArrangedChanged(_:))

        let rows = [
            row("Desktop color:", colorWell),
            row("Desktop photo:", photoColumn),
            row("Arrange by:", arrangePopUp),
            row("", keepArrangedCheckbox)
        ]
        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        let root = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor)
        ])
        view = root
        refreshControls()
        // Read-only: refreshing controls never writes.
        subscription = settings.changes.sink { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshControls() }
        }
    }

    // MARK: Layout

    private func row(_ title: String, _ control: NSView) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.alignment = .right
        label.widthAnchor.constraint(equalToConstant: 110).isActive = true
        let row = NSStackView(views: [label, control])
        row.alignment = .firstBaseline
        row.spacing = 12
        return row
    }

    // MARK: Reflecting settings into controls (never writes)

    private func refreshControls() {
        let color = NSColor(desktopHex: settings.backgroundColorHex) ?? .windowBackgroundColor
        if colorWell.color.desktopHex != color.desktopHex { colorWell.color = color }
        let arrangement = settings.iconArrangement
        if let index = Self.arrangements.firstIndex(where: { $0.value == arrangement }) {
            arrangePopUp.selectItem(at: index)
        }
        keepArrangedCheckbox.state = settings.keepArranged ? .on : .off
        keepArrangedCheckbox.isEnabled = arrangement != .list
        let path = settings.backgroundImagePath
        removePhotoButton.isEnabled = path != nil
        thumbnail.image = path.flatMap { NSImage(contentsOfFile: $0) }
    }

    // MARK: Actions

    @objc private func colorChanged(_ sender: NSColorWell) {
        settings.backgroundColorHex = sender.color.desktopHex
    }

    @objc private func arrangementChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard Self.arrangements.indices.contains(index) else { return }
        settings.iconArrangement = Self.arrangements[index].value
        refreshControls()
    }

    @objc private func keepArrangedChanged(_ sender: NSButton) {
        settings.keepArranged = sender.state == .on
    }

    @objc private func choosePhoto(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard let window = view.window else {
            if panel.runModal() == .OK, let url = panel.url { applyChosenPhoto(url: url) }
            return
        }
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            MainActor.assumeIsolated { self?.applyChosenPhoto(url: url) }
        }
    }

    @objc private func removePhoto(_ sender: Any?) {
        settings.backgroundImagePath = nil
        refreshControls()
    }

    /// The open-panel completion path.
    func applyChosenPhoto(url: URL) {
        settings.backgroundImagePath = url.path
        refreshControls()
    }
}
