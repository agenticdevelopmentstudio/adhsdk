import AppKit
import UniformTypeIdentifiers

/// The Desktop color well and Desktop picture picker, shared by every form that edits them.
/// `refresh()` reflects the settings into the controls and never writes.
@MainActor
final class DesktopAppearanceControls: NSObject {
    private let settings: DesktopSettings

    let colorWell = NSColorWell()
    let removePhotoButton = NSButton(title: "Remove", target: nil, action: nil)
    let chooseButton = NSButton(title: "Choose…", target: nil, action: nil)
    let thumbnail = NSImageView()
    /// The thumbnail with Choose… and Remove under it.
    let photoColumn: NSStackView
    /// Photo loads performed, for tests.
    private(set) var photoLoadCount = 0
    private var loadedPhotoPath: String?
    private var thumbnailLoaded = false
    /// The window an open panel attaches to as a sheet; nil runs it modally.
    var sheetWindow: () -> NSWindow? = { nil }

    init(settings: DesktopSettings, thumbnailSize: CGSize = CGSize(width: 120, height: 75)) {
        self.settings = settings
        thumbnail.imageScaling = .scaleProportionallyUpOrDown
        thumbnail.wantsLayer = true
        thumbnail.layer?.borderWidth = 1
        thumbnail.layer?.cornerRadius = 4
        thumbnail.layer?.borderColor = NSColor.separatorColor.cgColor
        thumbnail.widthAnchor.constraint(equalToConstant: thumbnailSize.width).isActive = true
        thumbnail.heightAnchor.constraint(equalToConstant: thumbnailSize.height).isActive = true
        let buttons = NSStackView(views: [chooseButton, removePhotoButton])
        buttons.spacing = 8
        photoColumn = NSStackView(views: [thumbnail, buttons])
        photoColumn.orientation = .vertical
        photoColumn.alignment = .leading
        photoColumn.spacing = 8
        super.init()
        colorWell.target = self
        colorWell.action = #selector(colorChanged(_:))
        colorWell.widthAnchor.constraint(equalToConstant: 44).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 24).isActive = true
        chooseButton.target = self
        chooseButton.action = #selector(choosePhoto(_:))
        removePhotoButton.target = self
        removePhotoButton.action = #selector(removePhoto(_:))
    }

    func refresh() {
        let color = NSColor(desktopHex: settings.backgroundColorHex) ?? .windowBackgroundColor
        if colorWell.color.desktopHex != color.desktopHex { colorWell.color = color }
        let path = settings.backgroundImagePath
        removePhotoButton.isEnabled = path != nil
        // Reload only when the path changes; refreshes are frequent.
        if !thumbnailLoaded || loadedPhotoPath != path {
            loadedPhotoPath = path
            thumbnailLoaded = true
            photoLoadCount += path == nil ? 0 : 1
            thumbnail.image = path.flatMap { NSImage(contentsOfFile: $0) }
        }
    }

    /// The open-panel completion path.
    func applyChosenPhoto(url: URL) {
        settings.backgroundImagePath = url.path
        refresh()
    }

    @objc private func colorChanged(_ sender: NSColorWell) {
        settings.backgroundColorHex = sender.color.desktopHex
    }

    @objc private func choosePhoto(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard let window = sheetWindow() else {
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
        refresh()
    }
}

/// The Menu Style pop-up, shared by every form that edits it.
@MainActor
final class DesktopMenuStyleControl: NSObject {
    private let settings: DesktopSettings
    let popUp = NSPopUpButton()

    static let styles: [(title: String, value: DesktopMenuStyle)] = [("macOS", .macOS), ("Windows", .windows)]

    init(settings: DesktopSettings) {
        self.settings = settings
        super.init()
        for entry in Self.styles { popUp.addItem(withTitle: entry.title) }
        popUp.target = self
        popUp.action = #selector(styleChanged(_:))
    }

    func refresh() {
        if let index = Self.styles.firstIndex(where: { $0.value == settings.menuStyle }),
           popUp.indexOfSelectedItem != index {
            popUp.selectItem(at: index)
        }
    }

    @objc private func styleChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard Self.styles.indices.contains(index) else { return }
        settings.menuStyle = Self.styles[index].value
    }
}
