import Testing
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// Conformance vectors toolbar-001 to toolbar-023 for the `editor-toolbar` recipe.
///
/// The toolbar keeps its controls private, so each test reaches them the way a
/// user does: by walking the view tree for the real segmented control and the
/// buttons titled `?` and `Open…`. Only the lookups and the "user taps" calls
/// differ by platform and sit behind `#if`; the suite compiles into both bundles.
@MainActor
@Suite("MarkdownEditorToolbar conformance")
struct MarkdownEditorToolbarConformanceTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }

    // MARK: Mode selector

    @Test("toolbar-001: three modes render three labeled segments in a visible control")
    func threeModesRenderThreeSegments() {
        let toolbar = MarkdownEditorToolbar()
        toolbar.availableModes = [.edit, .preview, .split]

        let probe = ToolbarProbe(toolbar)
        #expect(probe.segmentTitles == ["Edit", "Preview", "Split"])
        #expect(probe.modeControl.isHidden == false)
    }

    @Test("toolbar-002: a single mode hides the segmented control")
    func singleModeHidesTheControl() {
        let toolbar = MarkdownEditorToolbar()
        toolbar.availableModes = [.split]

        #expect(ToolbarProbe(toolbar).modeControl.isHidden)
    }

    @Test("toolbar-003: an empty mode list leaves a hidden control with no segments and no selection")
    func emptyModeListLeavesNoSegments() {
        let toolbar = MarkdownEditorToolbar()
        toolbar.availableModes = []

        let probe = ToolbarProbe(toolbar)
        #expect(probe.segmentTitles.isEmpty)
        #expect(probe.modeControl.isHidden)
        #expect(probe.selectedIndex == -1)
    }

    // MARK: Buttons

    @Test("toolbar-004: the help button is visible by default")
    func helpButtonVisibleByDefault() throws {
        let probe = ToolbarProbe(MarkdownEditorToolbar())
        #expect(try probe.button(titled: "?").isHidden == false)
    }

    @Test("toolbar-005: showsHelpButton = false hides the help button")
    func helpButtonHiddenWhenTurnedOff() throws {
        let toolbar = MarkdownEditorToolbar()
        toolbar.showsHelpButton = false

        #expect(try ToolbarProbe(toolbar).button(titled: "?").isHidden)
    }

    @Test("toolbar-006: the help button hides then reappears when toggled false then true")
    func helpButtonTogglesBack() throws {
        let toolbar = MarkdownEditorToolbar()
        let probe = ToolbarProbe(toolbar)
        toolbar.showsHelpButton = false
        #expect(try probe.button(titled: "?").isHidden)
        toolbar.showsHelpButton = true
        #expect(try probe.button(titled: "?").isHidden == false)
    }

    @Test("toolbar-007: the import button is visible by default")
    func importButtonVisibleByDefault() throws {
        let probe = ToolbarProbe(MarkdownEditorToolbar())
        #expect(try probe.button(titled: "Open…").isHidden == false)
    }

    @Test("toolbar-008: showsImportButton = false hides the import button")
    func importButtonHiddenWhenTurnedOff() throws {
        let toolbar = MarkdownEditorToolbar()
        toolbar.showsImportButton = false

        #expect(try ToolbarProbe(toolbar).button(titled: "Open…").isHidden)
    }

    @Test("toolbar-009: the import button hides then reappears when toggled false then true")
    func importButtonTogglesBack() throws {
        let toolbar = MarkdownEditorToolbar()
        let probe = ToolbarProbe(toolbar)
        toolbar.showsImportButton = false
        #expect(try probe.button(titled: "Open…").isHidden)
        toolbar.showsImportButton = true
        #expect(try probe.button(titled: "Open…").isHidden == false)
    }

    // MARK: Callbacks

    @Test("toolbar-010: choosing a different segment fires onModeChange with the new mode")
    func choosingAnotherSegmentFiresTheCallback() {
        let toolbar = MarkdownEditorToolbar()
        toolbar.mode = .split
        var received: [MarkdownEditorMode] = []
        toolbar.onModeChange = { received.append($0) }

        ToolbarProbe(toolbar).tapSegment(0)

        #expect(received == [.edit])
        #expect(toolbar.mode == .edit)
    }

    #if os(macOS)
    @Test("toolbar-011: macOS: a click on the already-selected segment fires onModeChange again")
    func reselectingFiresAgainOnMacOS() {
        let toolbar = MarkdownEditorToolbar()
        toolbar.mode = .split
        var received: [MarkdownEditorMode] = []
        toolbar.onModeChange = { received.append($0) }

        ToolbarProbe(toolbar).tapSegment(2)

        #expect(received == [.split])
    }
    #else
    @Test("toolbar-023: iOS: a tap on the already-selected segment does not fire onModeChange",
          .disabled("UIKit suppresses .valueChanged on a re-tap; a unit test can only call sendActions"))
    func reselectingDoesNotFireOniOS() {}
    #endif

    @Test("toolbar-012: setting mode programmatically does not fire onModeChange")
    func programmaticModeDoesNotFire() {
        let toolbar = MarkdownEditorToolbar()
        var fired = false
        toolbar.onModeChange = { _ in fired = true }

        toolbar.mode = .preview

        #expect(fired == false)
    }

    @Test("toolbar-013: setting mode programmatically moves the selected segment")
    func programmaticModeMovesTheSelection() {
        let toolbar = MarkdownEditorToolbar()
        toolbar.mode = .edit
        toolbar.mode = .split

        #expect(ToolbarProbe(toolbar).selectedIndex == 2)
    }

    @Test("toolbar-014: a mode missing from availableModes leaves no segment selected")
    func modeOutsideAvailableModesSelectsNothing() {
        let toolbar = MarkdownEditorToolbar()
        toolbar.availableModes = [.edit, .preview]
        toolbar.mode = .split

        #expect(ToolbarProbe(toolbar).selectedIndex == -1)
    }

    @Test("toolbar-015: tapping the help button fires onSyntaxHelpRequested")
    func helpButtonFiresItsCallback() throws {
        let toolbar = MarkdownEditorToolbar()
        var count = 0
        toolbar.onSyntaxHelpRequested = { count += 1 }

        try ToolbarProbe(toolbar).tapButton(titled: "?")

        #expect(count == 1)
    }

    @Test("toolbar-016: tapping the import button fires onImport")
    func importButtonFiresItsCallback() throws {
        let toolbar = MarkdownEditorToolbar()
        var count = 0
        toolbar.onImport = { count += 1 }

        try ToolbarProbe(toolbar).tapButton(titled: "Open…")

        #expect(count == 1)
    }

    // MARK: Theme

    @Test("toolbar-017: applyTheme paints the background with the palette's elevatedSurface")
    func applyThemeSetsTheBackground() {
        let toolbar = MarkdownEditorToolbar()
        toolbar.applyTheme(palette)

        #if os(macOS)
        #expect(toolbar.layer?.backgroundColor == palette.nsColor(.elevatedSurface).cgColor)
        #else
        #expect(toolbar.backgroundColor == palette.uiColor(.elevatedSurface))
        #endif
    }

    #if os(iOS)
    @Test("toolbar-018: iOS: applyTheme tints the help and import buttons with the palette accent")
    func applyThemeTintsTheButtons() throws {
        let toolbar = MarkdownEditorToolbar()
        toolbar.applyTheme(palette)

        let probe = ToolbarProbe(toolbar)
        #expect(try probe.button(titled: "?").tintColor == palette.uiColor(.accent))
        #expect(try probe.button(titled: "Open…").tintColor == palette.uiColor(.accent))
    }
    #endif

    // MARK: Accessibility

    #if os(macOS)
    @Test("toolbar-019: macOS: the mode control is labeled Editor Mode with its identifier")
    func modeControlAccessibility() {
        let control = ToolbarProbe(MarkdownEditorToolbar()).modeControl
        #expect(control.accessibilityLabel() == "Editor Mode")
        #expect(control.accessibilityIdentifier() == "markdown-editor.mode")
    }

    @Test("toolbar-020: macOS: the help button is labeled Markdown Syntax Help with its identifier")
    func helpButtonAccessibility() throws {
        let button = try ToolbarProbe(MarkdownEditorToolbar()).button(titled: "?")
        #expect(button.accessibilityLabel() == "Markdown Syntax Help")
        #expect(button.accessibilityIdentifier() == "markdown-editor.help")
    }

    @Test("toolbar-021: macOS: the import button is labeled Open Markdown File with its identifier")
    func importButtonAccessibility() throws {
        let button = try ToolbarProbe(MarkdownEditorToolbar()).button(titled: "Open…")
        #expect(button.accessibilityLabel() == "Open Markdown File")
        #expect(button.accessibilityIdentifier() == "markdown-editor.import")
    }
    #endif

    @Test("toolbar-022: the platform control announces selection changes; the toolbar posts nothing itself",
          .disabled("What VoiceOver or UIAccessibility announces is not observable from a unit test"))
    func selectionAnnouncementComesFromThePlatformControl() {}
}

/// Reaches into the toolbar's private controls through the view tree.
@MainActor
private struct ToolbarProbe {
    struct MissingButton: Error { let title: String }

    let toolbar: MarkdownEditorToolbar

    init(_ toolbar: MarkdownEditorToolbar) { self.toolbar = toolbar }

    private var descendants: [PlatformView] { Self.descendants(of: toolbar) }

    private static func descendants(of view: PlatformView) -> [PlatformView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }

    #if os(macOS)
    var modeControl: NSSegmentedControl {
        descendants.compactMap { $0 as? NSSegmentedControl }.first ?? NSSegmentedControl()
    }

    var segmentTitles: [String] {
        (0..<modeControl.segmentCount).map { modeControl.label(forSegment: $0) ?? "" }
    }

    var selectedIndex: Int { modeControl.selectedSegment }

    func button(titled title: String) throws -> NSButton {
        guard let found = descendants.compactMap({ $0 as? NSButton }).first(where: { $0.title == title })
        else { throw MissingButton(title: title) }
        return found
    }

    func tapSegment(_ index: Int) {
        let control = modeControl
        control.selectedSegment = index
        _ = control.sendAction(control.action, to: control.target)
    }

    func tapButton(titled title: String) throws {
        try button(titled: title).performClick(nil)
    }
    #else
    var modeControl: UISegmentedControl {
        descendants.compactMap { $0 as? UISegmentedControl }.first ?? UISegmentedControl()
    }

    var segmentTitles: [String] {
        (0..<modeControl.numberOfSegments).map { modeControl.titleForSegment(at: $0) ?? "" }
    }

    var selectedIndex: Int { modeControl.selectedSegmentIndex }

    func button(titled title: String) throws -> UIButton {
        guard let found = descendants.compactMap({ $0 as? UIButton }).first(where: { $0.title(for: .normal) == title })
        else { throw MissingButton(title: title) }
        return found
    }

    func tapSegment(_ index: Int) {
        let control = modeControl
        control.selectedSegmentIndex = index
        Self.deliver(.valueChanged, from: control)
    }

    func tapButton(titled title: String) throws {
        Self.deliver(.touchUpInside, from: try button(titled: title))
    }

    /// Calls each target-action pair the control registered for `event`, as
    /// UIKit's dispatch would. `sendActions(for:)` routes through
    /// `UIApplication.shared`, which a hostless unit-test bundle does not
    /// have, so there it reaches no target at all and the callback never fires.
    private static func deliver(_ event: UIControl.Event, from control: UIControl) {
        for target in control.allTargets {
            for name in control.actions(forTarget: target, forControlEvent: event) ?? [] {
                _ = (target as NSObject).perform(NSSelectorFromString(name), with: control)
            }
        }
    }
    #endif
}
