import AppKit
import Combine

/// The Desktop's own settings: color, photo, icon arrangement, menu style. Hosted by the app's Settings window.
@MainActor
public final class DesktopSettingsViewController: NSViewController {
    private let settings: DesktopSettings
    private var subscription: AnyCancellable?
    private let appearance: DesktopAppearanceControls
    private let menuStyle: DesktopMenuStyleControl

    var colorWell: NSColorWell { appearance.colorWell }
    var removePhotoButton: NSButton { appearance.removePhotoButton }
    var menuStylePopUp: NSPopUpButton { menuStyle.popUp }
    /// Photo loads performed, for tests.
    var photoLoadCount: Int { appearance.photoLoadCount }
    let arrangePopUp = NSPopUpButton()
    let keepArrangedCheckbox = NSButton(checkboxWithTitle: "Keep arranged", target: nil, action: nil)

    private static let arrangements: [(title: String, value: DesktopIconArrangement)] = [
        ("Large Icons", .largeIcons), ("Small Icons", .smallIcons), ("List", .list)
    ]

    public init(settings: DesktopSettings = .shared) {
        self.settings = settings
        appearance = DesktopAppearanceControls(settings: settings)
        menuStyle = DesktopMenuStyleControl(settings: settings)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func loadView() {
        appearance.sheetWindow = { [weak self] in self?.view.window }
        for entry in Self.arrangements {
            arrangePopUp.addItem(withTitle: entry.title)
        }
        arrangePopUp.target = self
        arrangePopUp.action = #selector(arrangementChanged(_:))
        keepArrangedCheckbox.target = self
        keepArrangedCheckbox.action = #selector(keepArrangedChanged(_:))

        let rows = [
            row("Desktop color:", appearance.colorWell),
            row("Desktop photo:", appearance.photoColumn),
            row("Arrange by:", arrangePopUp),
            row("", keepArrangedCheckbox),
            row("Menu style:", menuStyle.popUp)
        ]
        view = DesktopSettingsRows.formView(rows)
        refreshControls()
        // Read-only: refreshing controls never writes.
        subscription = settings.changes.sink { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshControls() }
        }
    }

    // MARK: Layout

    private func row(_ title: String, _ control: NSView) -> NSView {
        DesktopSettingsRows.labeledRow(title, control, labelWidth: 110)
    }

    // MARK: Reflecting settings into controls (never writes)

    private func refreshControls() {
        appearance.refresh()
        menuStyle.refresh()
        let arrangement = settings.iconArrangement
        if let index = Self.arrangements.firstIndex(where: { $0.value == arrangement }) {
            arrangePopUp.selectItem(at: index)
        }
        keepArrangedCheckbox.state = settings.keepArranged ? .on : .off
        keepArrangedCheckbox.isEnabled = arrangement != .list
    }

    // MARK: Actions

    @objc private func arrangementChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard Self.arrangements.indices.contains(index) else { return }
        settings.iconArrangement = Self.arrangements[index].value
        refreshControls()
    }

    @objc private func keepArrangedChanged(_ sender: NSButton) {
        settings.keepArranged = sender.state == .on
    }

    /// The open-panel completion path.
    func applyChosenPhoto(url: URL) {
        appearance.applyChosenPhoto(url: url)
    }
}
