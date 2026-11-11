//
//  SafariExtensionDetailsView.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import AgenticDeveloperHubSDKCore

/// One Safari extension's details page, as Chrome's extension details page
/// lays it out: on or off; what it is, its version, size and source; what it
/// may access; which sites it runs on; whether it is pinned, runs in private
/// browsing and reads `file://` pages; and its options, store page and
/// removal. Shown in place of the list by `SafariExtensionsTopicPanel`.
///
/// Built once per extension and updated in place when the host changes, so a
/// switch flipped here does not scroll the page back to the top; it is
/// rebuilt only when a row has to appear or go (the site list, file access).
@available(macOS 15.4, *)
@MainActor
final class SafariExtensionDetailsView: NSView {

    let extensionID: String
    private let host: SafariExtensionHost
    private let prefix: String

    /// Back to the list.
    var onBack: (() -> Void)?
    /// Opens a page: its options, its store listing.
    var onOpen: ((URL) -> Void)?
    /// Asks to remove it (the panel confirms).
    var onRemove: ((String) -> Void)?
    /// A change failed.
    var onError: ((Error) -> Void)?

    private let scroll = ComposableSettings.PanelScrollView()
    private var layoutKey: LayoutKey?
    private var size: Int64?

    private let iconView = NSImageView()
    private let nameLabel = ComposableSettings.makeRowLabel("")
    private let enabledSwitch = NSSwitch()
    private let summaryView = ComposableSettings.ExplanationView(withText: "")
    private let versionRow = ComposableSettings.ValueRowView(title: "Version")
    private let sizeRow = ComposableSettings.ValueRowView(title: "Size")
    private let sourceRow = ComposableSettings.ValueRowView(title: "Source")
    private let permissionsView = ComposableSettings.ExplanationView(withText: "")
    private let requestedSitesView = ComposableSettings.ExplanationView(withText: "")
    private let siteAccessPopup = NSPopUpButton()
    private let sitesField = NSTextField()
    private let pinSwitch = NSSwitch()
    private let privateSwitch = NSSwitch()
    private let fileSwitch = NSSwitch()
    private let optionsButton = NSButton(title: "Options", target: nil, action: nil)
    private let storeButton = NSButton(title: "", target: nil, action: nil)
    private let removeButton = NSButton(title: "Remove Extension…", target: nil, action: nil)
    private var details: SafariExtensionHost.Details?

    /// What decides which rows the page has.
    private struct LayoutKey: Equatable {
        var specificSites: Bool
        var offersFileAccess: Bool
    }

    init(extensionID: String, host: SafariExtensionHost, accessibilityPrefix: String) {
        self.extensionID = extensionID
        self.host = host
        self.prefix = "\(accessibilityPrefix).details"
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setAccessibilityIdentifier(prefix)
        addSubview(scroll)
        NSView.pinToEdges(scroll, of: self)
        configureControls()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    /// Shows the extension as the host has it now; false when it is no longer
    /// installed.
    @discardableResult
    func reload() -> Bool {
        guard let details = host.details(of: extensionID) else { return false }
        self.details = details
        let key = LayoutKey(
            specificSites: details.siteAccess == .specificSites, offersFileAccess: details.offersFileAccess)
        if key != layoutKey {
            layoutKey = key
            scroll.setContent(makeContent(key))
        }
        update(details)
        if size == nil { measureSize() }
        return true
    }

    // MARK: - Building

    private func configureControls() {
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32)
        ])
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.setAccessibilityIdentifier("\(prefix).name")

        configure(enabledSwitch, "enabled", #selector(toggleEnabled))
        configure(pinSwitch, "pinned", #selector(togglePinned))
        configure(privateSwitch, "private", #selector(togglePrivate))
        configure(fileSwitch, "file-access", #selector(toggleFileAccess))

        siteAccessPopup.addItems(withTitles: SafariExtensionSiteAccess.allCases.map(\.title))
        siteAccessPopup.target = self
        siteAccessPopup.action = #selector(siteAccessChosen)
        siteAccessPopup.setAccessibilityIdentifier("\(prefix).site-access")

        sitesField.placeholderString = "example.com, *.example.org"
        sitesField.target = self
        sitesField.action = #selector(sitesEntered)
        sitesField.setAccessibilityIdentifier("\(prefix).sites")
        sitesField.setAccessibilityLabel("Sites")
        sitesField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        sitesField.widthAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true

        for (button, id, action) in [
            (optionsButton, "options", #selector(openOptions)),
            (storeButton, "store", #selector(openStore)),
            (removeButton, "remove", #selector(removeClicked))
        ] {
            button.bezelStyle = .push
            button.target = self
            button.action = action
            button.setAccessibilityIdentifier("\(prefix).\(id)")
        }
        removeButton.hasDestructiveAction = true

        sizeRow.value = "…"
        summaryView.label.setAccessibilityIdentifier("\(prefix).summary")
        permissionsView.label.setAccessibilityIdentifier("\(prefix).permissions")
        requestedSitesView.label.setAccessibilityIdentifier("\(prefix).requested-sites")
    }

    private func configure(_ toggle: NSSwitch, _ id: String, _ action: Selector) {
        toggle.target = self
        toggle.action = action
        toggle.setAccessibilityIdentifier("\(prefix).\(id)")
    }

    private func makeContent(_ key: LayoutKey) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        let inset = ComposableSettings.SettingsLayout.default[.panelInset]
        stack.edgeInsets = NSEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)

        let back = NSButton(
            image: NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back") ?? NSImage(),
            target: self, action: #selector(backClicked))
        back.bezelStyle = .accessoryBarAction
        back.isBordered = false
        back.toolTip = "All extensions"
        back.setAccessibilityIdentifier("\(prefix).back")
        let header = NSStackView(views: [back, iconView, nameLabel])
        header.orientation = .horizontal
        header.spacing = 10
        stack.addArrangedSubview(header)

        let status = ComposableSettings.GroupView(withTitle: "")
        status.addSettingSubview(row("On", enabledSwitch))
        add(status, to: stack)

        let about = ComposableSettings.GroupView(withTitle: "About")
        about.addSettingSubview(titled("Description", summaryView))
        about.addSettingSubview(versionRow)
        about.addSettingSubview(sizeRow)
        about.addSettingSubview(sourceRow)
        about.addSettingSubview(titled("Permissions", permissionsView))
        about.addSettingSubview(titled("Sites It Asks For", requestedSitesView))
        add(about, to: stack)

        let access = ComposableSettings.GroupView(withTitle: "Access")
        access.addSettingSubview(row("Site access", siteAccessPopup))
        if key.specificSites { access.addSettingSubview(row("Sites", sitesField)) }
        access.addSettingSubview(row("Pin to toolbar", pinSwitch))
        access.addSettingSubview(row("Allow in private browsing", privateSwitch))
        if key.offersFileAccess { access.addSettingSubview(row("Allow access to file URLs", fileSwitch)) }
        add(access, to: stack)

        let actions = NSStackView(views: [optionsButton, storeButton, NSView(), removeButton])
        actions.orientation = .horizontal
        actions.spacing = 8
        add(actions, to: stack)

        // The scroll view stretches its content to fill the page, and a stack
        // spreads that slack between its rows; held at the top of a plain
        // view instead, the slack falls below the last row.
        let container = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
        return container
    }

    private func add(_ view: NSView, to stack: NSStackView) {
        stack.addArrangedSubview(view)
        view.widthAnchor.constraint(
            equalTo: stack.widthAnchor, constant: -(stack.edgeInsets.left + stack.edgeInsets.right)
        ).isActive = true
    }

    private func row(_ title: String, _ control: NSView) -> NSView {
        let label = ComposableSettings.makeRowLabel(title)
        control.setAccessibilityLabel(title)
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let row = NSView.makeSettingsRow([label, control])
        container.addSubview(row)
        NSView.pinToEdges(row, of: container)
        return container
    }

    /// A row whose value is a block of text under its name.
    private func titled(_ title: String, _ body: NSView) -> NSView {
        let stack = NSStackView(views: [ComposableSettings.makeRowLabel(title), body])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        body.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        return stack
    }

    // MARK: - Updating

    private func update(_ details: SafariExtensionHost.Details) {
        iconView.image = details.iconPNG.flatMap(NSImage.init(data:))
            ?? NSImage(systemSymbolName: "puzzlepiece.extension", accessibilityDescription: nil)
        nameLabel.stringValue = details.name
        enabledSwitch.state = details.isEnabled ? .on : .off
        enabledSwitch.isEnabled = !details.isSourceMissing
        summaryView.text = details.summary.isEmpty ? "—" : details.summary
        versionRow.value = details.version
        sourceRow.value = Self.source(of: details)
        permissionsView.text = details.permissions.isEmpty
            ? "None"
            : details.permissions.map(SafariExtensionSettings.describe(permission:)).joined(separator: "\n")
        var described: [String] = []
        for origin in details.requestedOrigins.map(SafariExtensionSettings.describe(origin:))
        where !described.contains(origin) { described.append(origin) }
        requestedSitesView.text = described.isEmpty ? "None" : described.joined(separator: "\n")

        siteAccessPopup.selectItem(at: SafariExtensionSiteAccess.allCases.firstIndex(of: details.siteAccess) ?? 0)
        if sitesField.currentEditor() == nil {
            sitesField.stringValue = details.sites.map(Self.typed(pattern:)).joined(separator: ", ")
        }
        pinSwitch.state = details.isPinned ? .on : .off
        privateSwitch.state = details.allowsPrivateBrowsing ? .on : .off
        fileSwitch.state = details.allowsFileAccess ? .on : .off

        optionsButton.isEnabled = details.optionsURL != nil
        storeButton.title = details.isFromWebStore ? "View in Chrome Web Store" : "Show in Finder"
    }

    private static func source(of details: SafariExtensionHost.Details) -> String {
        if details.isFromWebStore { return "Chrome Web Store" }
        if let app = details.appSource {
            return details.isSourceMissing ? "\(app.appName) (app deleted)" : "\(app.appName) (App Store)"
        }
        return "Files"
    }

    /// A granted site as the person typed it: `*://example.com/*` back to
    /// `example.com`; anything more particular as its pattern.
    static func typed(pattern: String) -> String {
        if pattern.hasPrefix("*://"), pattern.hasSuffix("/*") {
            return String(pattern.dropFirst(4).dropLast(2))
        }
        return pattern
    }

    private func measureSize() {
        let id = extensionID
        Task { [weak self, host] in
            let bytes = await host.diskSize(of: id)
            guard let self else { return }
            self.size = bytes
            self.sizeRow.value = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        }
    }

    // MARK: - Actions

    private func attempt(_ change: () throws -> Void) {
        do { try change() } catch { onError?(error) }
        reload()
    }

    @objc private func backClicked() { onBack?() }

    @objc private func toggleEnabled() {
        attempt { try host.setEnabled(extensionID, enabledSwitch.state == .on) }
    }

    @objc private func togglePinned() {
        attempt { try host.setPinned(extensionID, pinSwitch.state == .on) }
    }

    @objc private func togglePrivate() {
        attempt { try host.setPrivateAccess(extensionID, privateSwitch.state == .on) }
    }

    @objc private func toggleFileAccess() {
        attempt { try host.setFileAccess(extensionID, fileSwitch.state == .on) }
    }

    @objc private func siteAccessChosen() {
        let index = siteAccessPopup.indexOfSelectedItem
        guard SafariExtensionSiteAccess.allCases.indices.contains(index) else { return }
        attempt { try host.setSiteAccess(extensionID, SafariExtensionSiteAccess.allCases[index]) }
    }

    @objc private func sitesEntered() {
        let (patterns, invalid) = SafariExtensionSettings.sitePatterns(from: sitesField.stringValue)
        if !invalid.isEmpty {
            onError?(NSError(domain: "SafariExtensionDetails", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "These do not name a site: " + invalid.joined(separator: ", ")
            ]))
        }
        attempt { try host.setSiteAccess(extensionID, .specificSites, sites: patterns) }
        sitesField.stringValue = patterns.map(Self.typed(pattern:)).joined(separator: ", ")
    }

    @objc private func openOptions() {
        guard let url = details?.optionsURL else { return }
        onOpen?(url)
    }

    @objc private func openStore() {
        guard let details else { return }
        if details.isFromWebStore, let url = URL(string: "https://chromewebstore.google.com/detail/\(details.id)") {
            onOpen?(url)
        } else if let app = details.appSource, !details.isSourceMissing {
            let appex = URL(fileURLWithPath: app.appexPath)
            let target = SafariAppExtension.appURL(containing: appex) ?? appex
            NSWorkspace.shared.activateFileViewerSelecting([target])
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([details.directory])
        }
    }

    @objc private func removeClicked() { onRemove?(extensionID) }
}
