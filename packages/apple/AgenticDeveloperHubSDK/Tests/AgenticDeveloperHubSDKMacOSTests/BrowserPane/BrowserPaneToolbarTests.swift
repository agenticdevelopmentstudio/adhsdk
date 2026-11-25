import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKDatabase

/// An engine with a toolbar of its own (Chrome's) takes the navigation
/// controls' place, so the pane's bar keeps only its badges.
@MainActor
final class BrowserPaneToolbarTests: XCTestCase {

    private func makePane(ownToolbar: Bool) -> WebBrowserPaneViewController {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog, providesOwnToolbar: ownToolbar) },
            engineKind: ownToolbar ? .chrome : .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: settings, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        return pane
    }

    /// The bar's navigation controls. The address field sits inside
    /// `addressBox`, and it is the box the bar holds and hides.
    private func navigation(_ pane: WebBrowserPaneViewController) -> [NSView] {
        [pane.addressBox, pane.backButton, pane.forwardButton, pane.reloadButton]
    }

    func test_ownToolbarEngineHidesKitchenNavigation() throws {
        let pane = makePane(ownToolbar: true)
        XCTAssertTrue(navigation(pane).allSatisfy(\.isHidden))
        XCTAssertTrue(pane.addressField.isDescendant(of: pane.addressBox), "the field is hidden with its box")
        let bar = try XCTUnwrap(pane.addressBar)
        XCTAssertTrue(bar.arrangedSubviews.contains(pane.addressBox))
        XCTAssertTrue(bar.arrangedSubviews.contains(pane.drivenBadge))
        XCTAssertTrue(bar.arrangedSubviews.contains(pane.installedBar))
        XCTAssertTrue(bar.arrangedSubviews.contains(pane.menuButton))
    }

    /// What the bar shows: its arranged views that are not hidden, in order.
    private func shown(in bar: NSStackView) -> [NSView] {
        bar.arrangedSubviews.filter { !$0.isHidden }
    }

    /// Chrome's toolbar replaces the navigation controls, so the bar shows
    /// the installed buttons and the menu, and the driven badge only while
    /// it is up. A pause adds nothing to the bar: the privacy button turns
    /// green instead, as it does for any protection in force.
    func test_ownToolbarBarShowsOnlyShownBadges() throws {
        let pane = makePane(ownToolbar: true)
        let bar = try XCTUnwrap(pane.addressBar)
        XCTAssertTrue(pane.drivenBadge.isHidden)
        XCTAssertEqual(shown(in: bar), [pane.installedBar, pane.menuButton])

        pane.setEventsPaused(true)
        XCTAssertEqual(shown(in: bar), [pane.installedBar, pane.menuButton])
        XCTAssertEqual(pane.privacyButton.contentTintColor, .systemGreen)
        XCTAssertEqual(pane.privacyButton.accessibilityValue() as? String, "paused")
        pane.setEventsPaused(false)
        XCTAssertNil(pane.privacyButton.contentTintColor)
        XCTAssertEqual(pane.privacyButton.accessibilityValue() as? String, "active")
    }

    /// The + is the pane's own (its tabs are Kitchen tabs), and it leads the
    /// tab row rather than the bar, whichever engine the pane runs.
    func test_newTabButtonLeadsTheTabRow() {
        for ownToolbar in [true, false] {
            let pane = makePane(ownToolbar: ownToolbar)
            let row = pane.newTabButton.superview as? TabBarView
            XCTAssertEqual(row?.edge, .top)
            XCTAssertFalse(pane.addressBar?.arrangedSubviews.contains(pane.newTabButton) ?? true)
        }
    }

    /// Tabs, then the address bar, then the page, top to bottom — the bar sits
    /// in the tab strip's slot below its tabs rather than above the strip.
    func test_addressBarSitsBetweenTheTabRowAndThePage() throws {
        let pane = makePane(ownToolbar: false)
        pane.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        pane.view.layoutSubtreeIfNeeded()
        let bar = try XCTUnwrap(pane.addressBar)
        let row = try XCTUnwrap(pane.newTabButton.superview as? TabBarView)
        // The pane's root is not flipped: a greater y is higher on screen.
        let rowFrame = pane.view.convert(row.bounds, from: row)
        let barFrame = pane.view.convert(bar.bounds, from: bar)
        let pageFrame = pane.view.convert(pane.engine.view.bounds, from: pane.engine.view)

        XCTAssertGreaterThan(barFrame.height, 0)
        XCTAssertLessThanOrEqual(barFrame.maxY, rowFrame.minY + 0.5, "the bar is under the tab row")
        XCTAssertLessThanOrEqual(pageFrame.maxY, barFrame.minY + 0.5, "the page is under the bar")
    }

    /// The refusal shows in the bar ahead of the installed buttons and the
    /// menu, which an own-toolbar bar always shows, and goes at the next
    /// navigation.
    func test_refusalShowsInBarUntilNextNavigation() throws {
        let pane = makePane(ownToolbar: true)
        let bar = try XCTUnwrap(pane.addressBar)
        let engine = pane.engine
        let sentence = "Chrome settings are managed in Settings > Web Browser."

        pane.browserEngine(engine, didFailNavigationWith: ChromeNavigationPolicy.refusalError(
            sentence, address: "chrome://settings"))
        XCTAssertFalse(pane.refusalNotice.isHidden)
        XCTAssertEqual(pane.refusalNotice.stringValue, sentence)
        XCTAssertEqual(shown(in: bar), [pane.refusalNotice, pane.installedBar, pane.menuButton])

        pane.browserEngineDidStartNavigation(engine)
        XCTAssertTrue(pane.refusalNotice.isHidden)
        XCTAssertEqual(shown(in: bar), [pane.installedBar, pane.menuButton])
    }

    /// Only the front tab moves the bar: a refusal reported by a tab behind
    /// it is not shown over the page in front.
    func test_refusalFromTabBehindIsNotShown() {
        let pane = makePane(ownToolbar: true)
        let behind = pane.engine
        pane.newTab(nil)
        XCTAssertFalse(pane.engine === behind, "the new tab is in front")
        let refusal = ChromeNavigationPolicy.refusalError(
            "Chrome settings are managed in Settings > Web Browser.", address: "chrome://settings")

        pane.browserEngine(behind, didFailNavigationWith: refusal)
        XCTAssertTrue(pane.refusalNotice.isHidden)

        pane.browserEngine(pane.engine, didFailNavigationWith: refusal)
        XCTAssertFalse(pane.refusalNotice.isHidden, "the front tab's refusal is shown")
    }

    func test_ordinaryLoadFailureShowsNoNotice() {
        let pane = makePane(ownToolbar: true)
        pane.browserEngine(pane.engine, didFailNavigationWith: URLError(.notConnectedToInternet))
        XCTAssertTrue(pane.refusalNotice.isHidden)
    }

    /// One colour rule for every strip item: green while the thing its title
    /// names is on, red while it is off. At the defaults the page gets
    /// everything, so the only items off are the two protections nobody
    /// turned on, and each reads as exactly that ("Hide Images: Off").
    func test_privacyStatusItemIsOnWhileTheNamedThingIsOn() {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        func item(_ title: String) -> BrowserPrivacyStatus.Item? {
            BrowserPrivacyStatus.items(settings: settings, isPaused: false, agentPrivacy: .off)
                .first { $0.title == title }
        }
        let defaults = BrowserPrivacyStatus.items(settings: settings, isPaused: false, agentPrivacy: .off)
        XCTAssertEqual(defaults.filter { !$0.isOn }.map(\.title), ["Hide Images", "Read Only", "Privacy Words"])
        XCTAssertEqual(defaults.filter(\.isProtecting).map(\.title), [], "nothing protects by default")
        XCTAssertEqual(item("Hide Images")?.text, "Hide Images: Off")

        settings.set(true, for: UserSettings.browserPrivacyHideImages)
        settings.set(BrowserInputPolicy.block, for: UserSettings.browserPrivacyKeyboard)
        XCTAssertEqual(item("Hide Images")?.isOn, true, "images hidden: Hide Images is on")
        XCTAssertEqual(item("Hide Images")?.isProtecting, true, "and red")
        XCTAssertEqual(item("Keyboard")?.isOn, false, "keyboard withheld: Keyboard is off")
        XCTAssertEqual(item("Keyboard")?.isProtecting, true, "and red")
    }

    /// The items come in the toolbar's three groups, in order.
    func test_privacyStatusItemsComeInTheirGroups() {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        let items = BrowserPrivacyStatus.items(settings: settings, isPaused: false, agentPrivacy: .off)
        XCTAssertEqual(items.map(\.title), [
            "Third-Party", "Cookies", "Hide Images",
            "All Events", "Keyboard", "Mouse", "Tracking", "Drag and Drop", "Activation",
            "Agent", "Read Only", "Privacy Words"
        ])
        XCTAssertEqual(items.map(\.group), items.map(\.group).sorted { $0.rawValue < $1.rawValue })
    }

    /// All Events disabled shows every event item Off and disabled, keeping
    /// the settings, so enabling it again brings back the same set.
    func test_allEventsDisabledShowsEveryEventOff() {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        settings.set(BrowserInputPolicy.block, for: UserSettings.browserPrivacyMouse)
        let paused = BrowserPrivacyStatus.items(settings: settings, isPaused: true, agentPrivacy: .off)
        let all = paused.first { $0.kind == .allEvents }
        XCTAssertEqual(all?.text, "All Events: Disabled")
        XCTAssertEqual(all?.isProtecting, true)
        for item in paused where item.group == .events && item.kind != .allEvents {
            XCTAssertEqual(item.state, "Off", item.title)
            XCTAssertFalse(item.isEnabled, item.title)
        }
        let live = BrowserPrivacyStatus.items(settings: settings, isPaused: false, agentPrivacy: .off)
        XCTAssertEqual(live.first { $0.kind == .keyboard }?.state, "On")
        XCTAssertEqual(live.first { $0.kind == .mouse }?.state, "Off")
    }

    /// Toggling flips the setting an item names; Read Only only narrows
    /// access that is on, and Agent turns full access on and off.
    func test_toggleFlipsTheNamedSetting() {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        XCTAssertTrue(BrowserPrivacyStatus.toggle(.hideImages, in: settings))
        XCTAssertTrue(settings.get(UserSettings.browserPrivacyHideImages))
        XCTAssertTrue(BrowserPrivacyStatus.toggle(.readOnly, in: settings))
        XCTAssertEqual(settings.get(UserSettings.browserPrivacyAgentAccess), .readOnly)
        XCTAssertTrue(BrowserPrivacyStatus.toggle(.agentAccess, in: settings))
        XCTAssertEqual(settings.get(UserSettings.browserPrivacyAgentAccess), .hidden)
        let readOnly = BrowserPrivacyStatus.items(settings: settings, isPaused: false, agentPrivacy: .off)
            .first { $0.kind == .readOnly }
        XCTAssertEqual(readOnly?.isEnabled, false, "Read Only needs access on")
        XCTAssertTrue(BrowserPrivacyStatus.toggle(.agentAccess, in: settings))
        XCTAssertEqual(settings.get(UserSettings.browserPrivacyAgentAccess), .full)
        XCTAssertFalse(BrowserPrivacyStatus.toggle(.allEvents, in: settings), "All Events is the pane's pause")
        BrowserPrivacyStatus.choose(BrowserPointerTracking.whenFocused.rawValue, for: .tracking, in: settings)
        XCTAssertEqual(settings.get(UserSettings.browserPrivacyPointerTracking), .whenFocused)
    }

    /// Privacy Words is on only while the words are applied: the switch on
    /// with no words to apply (no vault, a keychain that would prompt) or
    /// words that conflict leaves it off, saying why.
    func test_privacyWordsIsOnOnlyWhileTheWordsAreApplied() {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        func words(_ privacy: BrowserAgentPrivacy) -> BrowserPrivacyStatus.Item? {
            BrowserPrivacyStatus.items(settings: settings, isPaused: false, agentPrivacy: privacy)
                .first { $0.title == "Privacy Words" }
        }
        XCTAssertEqual(words(.off)?.isOn, false)
        XCTAssertEqual(words(.unavailable)?.isOn, false)
        XCTAssertEqual(words(.unavailable)?.text, "Privacy Words: Unavailable")
        XCTAssertEqual(words(.conflicting)?.isOn, false)
        XCTAssertEqual(words(.conflicting)?.text, "Privacy Words: Conflicting")
        let enabled = BrowserAgentPrivacy.checking(TextSubstitutionFilter(pairs: [.init(alias: "Bob", real: "Alice")]))
        XCTAssertEqual(words(enabled)?.isOn, true)
        XCTAssertEqual(words(enabled)?.text, "Privacy Words: On")
    }

    /// A pane with Agent Privacy on and no vault (the Safari-extensions
    /// window) draws its page unconcealed, so its strip says so.
    func test_paneWithoutAVaultShowsPrivacyWordsUnavailable() {
        let pane = makePane(ownToolbar: false)
        pane.settings.set(true, for: UserSettings.browserPrivacyShowToolbar)
        pane.settings.set(true, for: UserSettings.browserAgentPrivacy)
        pane.refreshAddressRowControls()
        let item = pane.privacyStrip.arrangedSubviews.flatMap { ($0 as? NSStackView)?.arrangedSubviews ?? [] }
            .first { $0.accessibilityIdentifier() == "browser.privacy-strip.privacy words" }
        XCTAssertEqual(item?.accessibilityValue() as? String, "off")
        XCTAssertEqual(item?.accessibilityLabel(), "Privacy Words: Unavailable")
    }

    /// Agent access reads as two toggles, like Settings: Agent On or Off,
    /// and Read Only On only while access is read only.
    func test_agentItemsSplitAccessIntoOnAndReadOnly() {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        for access in BrowserAgentAccess.allCases {
            settings.set(access, for: UserSettings.browserPrivacyAgentAccess)
            let items = BrowserPrivacyStatus.items(settings: settings, isPaused: false, agentPrivacy: .off)
            XCTAssertEqual(items.first { $0.title == "Agent" }?.text, "Agent: \(access == .hidden ? "Off" : "On")")
            XCTAssertEqual(items.first { $0.title == "Read Only" }?.text,
                           "Read Only: \(access == .readOnly ? "On" : "Off")")
        }
    }

    /// A hidden strip is not rebuilt, and a shown one only when its items
    /// change: a `browser.` setting the strip does not show leaves its views
    /// as they were.
    /// The toolbar's labels give way before the window does: each item holds
    /// its full width below `windowSizeStayPut` and truncates, down to a
    /// floor that keeps its symbol. At `defaultHigh` the toolbar made its
    /// project window wider than a 1920-point screen.
    func test_stripItemsTruncateRatherThanGrowTheWindow() {
        let pane = makePane(ownToolbar: false)
        pane.settings.set(true, for: UserSettings.browserPrivacyShowToolbar)
        pane.refreshAddressRowControls()
        let buttons = pane.privacyStrip.arrangedSubviews
            .flatMap { ($0 as? NSStackView)?.arrangedSubviews ?? [] }
            .compactMap { $0 as? NSButton }
        XCTAssertFalse(buttons.isEmpty)
        for button in buttons {
            XCTAssertLessThan(
                button.contentCompressionResistancePriority(for: .horizontal).rawValue,
                NSLayoutConstraint.Priority.windowSizeStayPut.rawValue, button.title)
            XCTAssertEqual(button.cell?.lineBreakMode, .byTruncatingTail, button.title)
            XCTAssertTrue(button.constraints.contains {
                $0.firstAttribute == .width && $0.relation == .greaterThanOrEqual
                    && $0.constant == BrowserPrivacyStripStyle.minimumWidth
            }, button.title)
        }
    }

    func test_stripRebuildsOnlyWhenShownAndChanged() {
        let pane = makePane(ownToolbar: false)
        XCTAssertTrue(pane.privacyStrip.arrangedSubviews.isEmpty, "hidden by default, so never built")
        pane.settings.set(true, for: UserSettings.browserPrivacyShowToolbar)
        pane.refreshAddressRowControls()
        let built = pane.privacyStrip.arrangedSubviews
        XCTAssertFalse(built.isEmpty)
        pane.refreshAddressRowControls()
        XCTAssertEqual(pane.privacyStrip.arrangedSubviews, built, "same items, same views")
        XCTAssertFalse(BrowserPrivacyStatus.settingNames.contains(UserSettings.browserPrivacyConsoleCapture.name))
        pane.settings.set(false, for: UserSettings.browserPrivacyDragAndDrop)
        pane.refreshAddressRowControls()
        XCTAssertNotEqual(pane.privacyStrip.arrangedSubviews, built, "a changed item rebuilds the strip")
    }

    /// Tracking only while the page has focus is on part of the time: red,
    /// and saying which part, rather than a plain Off.
    func test_trackingWhenFocusedSaysFocusedOnly() {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        settings.set(BrowserPointerTracking.whenFocused, for: UserSettings.browserPrivacyPointerTracking)
        let item = BrowserPrivacyStatus.items(settings: settings, isPaused: false, agentPrivacy: .off)
            .first { $0.title == "Tracking" }
        XCTAssertEqual(item?.isOn, false)
        XCTAssertEqual(item?.text, "Tracking: Focused Only")
    }

    func test_safariKeepsKitchenNavigation() {
        let pane = makePane(ownToolbar: false)
        XCTAssertFalse(navigation(pane).contains(where: \.isHidden))
    }

    // MARK: - Tooltips

    /// Every button under `view`, however deep: a stack view's hidden views
    /// are detached, so what this finds is what the pane is showing.
    private func buttons(in view: NSView) -> [NSButton] {
        view.subviews.flatMap { subview -> [NSButton] in
            ((subview as? NSButton).map { [$0] } ?? []) + buttons(in: subview)
        }
    }

    /// How a failure names the button: its identifier, else its
    /// accessibility label, else its title.
    private func describe(_ button: NSButton) -> String {
        let identifier = button.accessibilityIdentifier()
        if !identifier.isEmpty { return identifier }
        if let label = button.accessibilityLabel(), !label.isEmpty { return label }
        return button.title.isEmpty ? String(describing: button) : button.title
    }

    /// The owner's rule: every toolbar button in a browser pane has a
    /// tooltip naming its action. Walked over the real pane, both engines,
    /// with the privacy toolbar off and on (the privacy button moves between
    /// the two rows) and with several tabs, so the tabs' close buttons are in
    /// the walk.
    func test_everyToolbarButtonHasTooltip() {
        for ownToolbar in [false, true] {
            let pane = makePane(ownToolbar: ownToolbar)
            pane.newTab(nil)
            pane.newTab(nil)
            pane.view.frame = NSRect(x: 0, y: 0, width: 1000, height: 600)
            for showsStrip in [false, true] {
                pane.settings.set(showsStrip, for: UserSettings.browserPrivacyShowToolbar)
                pane.refreshAddressRowControls()
                pane.view.layoutSubtreeIfNeeded()
                let context = "(own toolbar \(ownToolbar), privacy toolbar \(showsStrip))"

                let found = buttons(in: pane.view)
                for button in found {
                    XCTAssertFalse((button.toolTip ?? "").isEmpty, "\(describe(button)) has no tooltip \(context)")
                }
                var expected: [NSButton] = [pane.newTabButton, pane.privacyButton, pane.menuButton]
                if !ownToolbar { expected += [pane.backButton, pane.forwardButton, pane.reloadButton] }
                for button in expected {
                    XCTAssertTrue(found.contains { $0 === button }, "the walk missed \(describe(button)) \(context)")
                }
                XCTAssertTrue(
                    found.contains { $0.accessibilityIdentifier().hasPrefix("tab-bar.close.") },
                    "the walk found no tab's close button \(context)")
            }
        }
    }

    /// The tooltips name the action, not the symbol, and the identifiers UI
    /// tests address stay put.
    func test_toolbarTooltipsNameTheirAction() {
        let pane = makePane(ownToolbar: false)
        XCTAssertEqual(pane.backButton.toolTip, "Go Back")
        XCTAssertEqual(pane.forwardButton.toolTip, "Go Forward")
        XCTAssertEqual(pane.reloadButton.toolTip, "Reload Page")
        XCTAssertEqual(pane.newTabButton.toolTip, "Open a New Tab")
        XCTAssertEqual(pane.privacyButton.toolTip, "Show This Tab's Privacy Settings")
        XCTAssertEqual(pane.menuButton.toolTip, "Show Browser Menu")
        XCTAssertEqual(pane.reloadButton.accessibilityIdentifier(), "browser.reload")
        XCTAssertEqual(pane.newTabButton.accessibilityIdentifier(), "browser.newtab")
        XCTAssertEqual(pane.privacyButton.accessibilityIdentifier(), "browser.privacy")
        XCTAssertEqual(pane.menuButton.accessibilityIdentifier(), "browser.menu")
    }

    /// A Safari pane's extension toolbar: Add Extension and the extensions
    /// menu have tooltips, and an extension's button always has one, falling
    /// back from its action's label to its name to a generic one. A host over
    /// a scratch library, never the person's.
    func test_safariExtensionToolbarButtonsHaveTooltips() throws {
        guard #available(macOS 15.4, *) else { throw XCTSkip("Safari extensions need macOS 15.4") }
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserPaneToolbarTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let host = SafariExtensionHost(
            profile: .global,
            library: SafariExtensionLibrary(
                catalog: LocalSafariExtensionCatalog(root: root.appendingPathComponent("Library")), scope: .global))
        let pane = makePane(ownToolbar: false)
        let window = SafariExtensionWindow(pane: pane, host: host)
        let toolbar = SafariExtensionToolbar(window: window, host: host)
        pane.addToolbarAccessory(toolbar)

        XCTAssertEqual(toolbar.addButton.toolTip, "Add This Extension from the Chrome Web Store")
        XCTAssertEqual(toolbar.overflowButton.toolTip, "Show More Extensions")

        XCTAssertEqual(SafariExtensionToolbar.actionToolTip(label: "Block Ads", displayName: "uBlock"), "Block Ads")
        XCTAssertEqual(SafariExtensionToolbar.actionToolTip(label: "", displayName: "uBlock"), "uBlock")
        XCTAssertEqual(SafariExtensionToolbar.actionToolTip(label: "", displayName: ""), "Run Extension")
        XCTAssertEqual(SafariExtensionToolbar.actionToolTip(label: "", displayName: nil), "Run Extension")
    }
}
