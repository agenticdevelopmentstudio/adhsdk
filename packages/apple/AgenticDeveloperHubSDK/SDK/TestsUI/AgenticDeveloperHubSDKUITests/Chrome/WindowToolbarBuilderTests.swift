import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The three things every one of our window toolbars has had to get right.
@MainActor
@Suite("WindowToolbarBuilder")
struct WindowToolbarBuilderTests {

    private final class Target: NSObject, NSSearchFieldDelegate {
        @objc func tapped() {}
    }

    /// An NSToolbarItem is a plain NSObject with no accessibility conformance,
    /// so the identifier has to land on the custom view or a UI test cannot
    /// see it at all.
    @Test("the identifier lands on the button, not the item")
    func identifierOnTheView() {
        let target = Target()
        let (item, button) = WindowToolbarBuilder.iconButtonItem(
            identifier: NSToolbarItem.Identifier("project.toolbar.help"),
            symbol: "questionmark.circle",
            label: "Help",
            target: target,
            action: #selector(Target.tapped))

        #expect(button.accessibilityIdentifier() == "project.toolbar.help")
        #expect(item.itemIdentifier.rawValue == "project.toolbar.help")
        #expect(item.view === button)
    }

    @Test("the button carries the label as its tooltip and its action")
    func buttonWiring() {
        let target = Target()
        let (item, button) = WindowToolbarBuilder.iconButtonItem(
            identifier: NSToolbarItem.Identifier("project.toolbar.search"),
            symbol: "magnifyingglass",
            label: "Find",
            target: target,
            action: #selector(Target.tapped))

        #expect(button.toolTip == "Find")
        #expect(button.target === target)
        #expect(button.action == #selector(Target.tapped))
        #expect(button.isBordered == false)
        #expect(button.imagePosition == .imageOnly)
        #expect(item.label == "Find")
        #expect(item.paletteLabel == "Find")
    }

    @Test("search is a real NSSearchToolbarItem, identified and delegated")
    func searchItem() {
        let target = Target()
        let item = WindowToolbarBuilder.searchItem(
            identifier: NSToolbarItem.Identifier("project.toolbar.search"),
            placeholder: "Search",
            delegate: target)

        #expect(item.searchField.placeholderString == "Search")
        #expect(item.searchField.accessibilityIdentifier() == "project.toolbar.search")
        #expect(item.searchField.delegate === target)
    }

    /// The button reports the state as well as toggling it: filled while
    /// disclosed, outlined while closed, with the tooltip that goes with it.
    @Test("disclosure appearance swaps the glyph and the tooltip")
    func disclosureAppearance() {
        let button = NSButton(title: "", target: nil, action: nil)

        WindowToolbarBuilder.applyDisclosureAppearance(
            to: button, disclosed: false,
            outlineSymbol: "questionmark.circle", filledSymbol: "questionmark.circle.fill",
            showTooltip: "Show Help", hideTooltip: "Hide Help")
        #expect(button.toolTip == "Show Help")
        let closedImage = button.image

        WindowToolbarBuilder.applyDisclosureAppearance(
            to: button, disclosed: true,
            outlineSymbol: "questionmark.circle", filledSymbol: "questionmark.circle.fill",
            showTooltip: "Show Help", hideTooltip: "Hide Help")
        #expect(button.toolTip == "Hide Help")
        #expect(button.image !== closedImage)
    }

    /// The image's accessibility description is the control's stable *name*
    /// ("Help", set once by `iconButtonItem` from the item's label) — not the
    /// action of the moment. Regression for a refactor that briefly read
    /// `button.toolTip` here, which would rename the control after the
    /// previous state's tooltip ("Hide Help") on every call but the first.
    @Test("disclosure appearance keeps the button's original accessibility name")
    func disclosureAppearanceKeepsAccessibilityName() {
        let target = Target()
        let (_, button) = WindowToolbarBuilder.iconButtonItem(
            identifier: NSToolbarItem.Identifier("project.toolbar.help"),
            symbol: "questionmark.circle",
            label: "Help",
            target: target,
            action: #selector(Target.tapped))

        WindowToolbarBuilder.applyDisclosureAppearance(
            to: button, disclosed: false,
            outlineSymbol: "questionmark.circle", filledSymbol: "questionmark.circle.fill",
            showTooltip: "Show Help", hideTooltip: "Hide Help")
        #expect(button.image?.accessibilityDescription == "Help")
        #expect(button.toolTip == "Show Help")

        WindowToolbarBuilder.applyDisclosureAppearance(
            to: button, disclosed: true,
            outlineSymbol: "questionmark.circle", filledSymbol: "questionmark.circle.fill",
            showTooltip: "Show Help", hideTooltip: "Hide Help")
        #expect(button.image?.accessibilityDescription == "Help")
        #expect(button.toolTip == "Hide Help")
    }

    @Test("the tint comes from the button's own resolved scope")
    func tintTracksTheScope() {
        let button = NSButton(title: "", target: nil, action: nil)
        WindowToolbarBuilder.applyDisclosureAppearance(
            to: button, disclosed: true,
            outlineSymbol: "questionmark.circle", filledSymbol: "questionmark.circle.fill",
            showTooltip: "Show", hideTooltip: "Hide")
        #expect(button.contentTintColor == button.resolvedThemeScope.palette.accentColor)

        WindowToolbarBuilder.applyDisclosureAppearance(
            to: button, disclosed: false,
            outlineSymbol: "questionmark.circle", filledSymbol: "questionmark.circle.fill",
            showTooltip: "Show", hideTooltip: "Hide")
        #expect(button.contentTintColor == button.resolvedThemeScope.palette.secondaryTextColor)
    }

    // MARK: - The descriptor-driven delegate

    private static let searchID = NSToolbarItem.Identifier("project.toolbar.search")
    private static let helpID = NSToolbarItem.Identifier("project.toolbar.help")

    private func projectDelegate(target: Target) -> WindowToolbarBuilder.Delegate {
        WindowToolbarBuilder.Delegate(
            items: [
                .flexibleSpace,
                .search(identifier: Self.searchID, placeholder: "Search"),
                .button(
                    identifier: Self.helpID,
                    symbol: "questionmark.circle",
                    label: "Help",
                    action: #selector(Target.tapped))
            ],
            target: target,
            searchDelegate: target)
    }

    @Test("the descriptor list is the default and the allowed item order")
    func descriptorOrder() {
        let delegate = projectDelegate(target: Target())
        let toolbar = NSToolbar(identifier: "project.toolbar")
        #expect(delegate.toolbarDefaultItemIdentifiers(toolbar)
            == [.flexibleSpace, Self.searchID, Self.helpID])
        #expect(delegate.toolbarAllowedItemIdentifiers(toolbar)
            == [.flexibleSpace, Self.searchID, Self.helpID])
    }

    @Test("the delegate makes each descriptor's item")
    func descriptorItems() {
        let delegate = projectDelegate(target: Target())
        let toolbar = NSToolbar(identifier: "project.toolbar")

        let search = delegate.toolbar(toolbar, itemForItemIdentifier: Self.searchID, willBeInsertedIntoToolbar: true)
        #expect(search is NSSearchToolbarItem)

        let help = delegate.toolbar(toolbar, itemForItemIdentifier: Self.helpID, willBeInsertedIntoToolbar: true)
        #expect(help?.view?.accessibilityIdentifier() == "project.toolbar.help")
    }

    /// AppKit skips NSToolbarItemValidation for custom views, so the owner has
    /// to reach its buttons to set isEnabled. The delegate keeps them for it.
    @Test("the delegate hands back the button it made, so enablement is possible")
    func buttonsAreReachable() {
        let delegate = projectDelegate(target: Target())
        let toolbar = NSToolbar(identifier: "project.toolbar")
        _ = delegate.toolbar(toolbar, itemForItemIdentifier: Self.helpID, willBeInsertedIntoToolbar: true)

        let button = delegate.button(for: Self.helpID)
        #expect(button != nil)
        button?.isEnabled = false
        #expect(delegate.button(for: Self.helpID)?.isEnabled == false)
        #expect(delegate.button(for: Self.searchID) == nil)
    }

    @Test("the search field is reachable and delegated")
    func searchFieldIsReachable() {
        let target = Target()
        let delegate = projectDelegate(target: target)
        let toolbar = NSToolbar(identifier: "project.toolbar")
        _ = delegate.toolbar(toolbar, itemForItemIdentifier: Self.searchID, willBeInsertedIntoToolbar: true)

        #expect(delegate.searchField?.delegate === target)
        #expect(delegate.searchField?.placeholderString == "Search")
    }

    /// Enablement and placeholder belong to the owner, and AppKit builds the
    /// item whenever it gets round to it — so the owner is told the moment the
    /// field exists rather than having to arrange a refresh that lands after.
    /// A fresh `NSSearchField` is enabled with whatever placeholder it was
    /// given, so an owner that never gets the call leaves the window showing a
    /// live field over a pane that cannot be searched.
    @Test("the owner is handed the search field the moment it is made")
    func searchFieldCreationHook() {
        var handed: [NSSearchField] = []
        let delegate = WindowToolbarBuilder.Delegate(
            items: [.search(identifier: Self.searchID, placeholder: "Search")],
            target: nil,
            onSearchFieldCreated: { handed.append($0) })
        let toolbar = NSToolbar(identifier: "project.toolbar")

        let item = delegate.toolbar(
            toolbar, itemForItemIdentifier: Self.searchID, willBeInsertedIntoToolbar: true)

        #expect(handed.count == 1)
        #expect(handed.first === (item as? NSSearchToolbarItem)?.searchField)
        #expect(handed.first === delegate.searchField)
    }

    /// A toolbar with no `.search` slot has no field to hand over.
    @Test("a toolbar without a search slot never calls the hook")
    func searchFieldCreationHookIsNotCalledWithoutASearchSlot() {
        var calls = 0
        let target = Target()
        let delegate = WindowToolbarBuilder.Delegate(
            items: [.button(
                identifier: Self.helpID,
                symbol: "questionmark.circle",
                label: "Help",
                action: #selector(Target.tapped))],
            target: target,
            onSearchFieldCreated: { _ in calls += 1 })
        let toolbar = NSToolbar(identifier: "project.toolbar")

        _ = delegate.toolbar(toolbar, itemForItemIdentifier: Self.helpID, willBeInsertedIntoToolbar: true)

        #expect(calls == 0)
    }

    /// `NSToolbar.delegate` is weak. A builder that returned a delegate nobody
    /// stored would render an empty toolbar and report nothing.
    @Test("makeToolbar wires the delegate the caller is holding")
    func makeToolbarWiresItself() {
        let delegate = projectDelegate(target: Target())
        let toolbar = delegate.makeToolbar(identifier: "project.toolbar")
        #expect(toolbar.delegate === delegate)
        #expect(toolbar.displayMode == .iconOnly)
    }
}
