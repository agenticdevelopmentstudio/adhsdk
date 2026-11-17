import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class TabPaneViewControllerTests: XCTestCase {
    private final class StubSource: TabPaneDataSource {
        var agent = "Claude"
        var model: String? = "Fable 5.1"
        var symbols = [TabPaneStatusSymbol.idle]
        var session = "tabs"
        var directory = URL(fileURLWithPath: "/tmp/repo/.claude/worktrees/tabs")
        var branch: String? = "tabs"
        var summary: String?

        func tabPaneAgentName(_ pane: TabPaneViewController) -> String { agent }
        func tabPaneModelName(_ pane: TabPaneViewController) -> String? { model }
        func tabPaneStatusSymbols(_ pane: TabPaneViewController) -> [TabPaneStatusSymbol] { symbols }
        func tabPaneSessionName(_ pane: TabPaneViewController) -> String { session }
        func tabPaneWorkingDirectory(_ pane: TabPaneViewController) -> URL { directory }
        func tabPaneBranch(_ pane: TabPaneViewController) -> String? { branch }
        func tabPaneSummary(_ pane: TabPaneViewController) -> String? { summary }
    }

    /// A `ThemeStorage` with nothing behind it, so a test can spin up a real
    /// `ThemeManager` (and therefore a real, larger `SemanticPalette`) without
    /// touching `UserSettings`/`UserDefaults`.
    private final class StubThemeStorage: ThemeStorage {
        var customThemes: [ColorTheme] = []
        var activeThemeID: String?
        var onExternalChange: (() -> Void)?
    }

    private final class StubDelegate: TabPaneDelegate {
        var menu = NSMenu()
        var asked = 0
        func tabPane(_ pane: TabPaneViewController, contextMenuFor event: NSEvent) -> NSMenu? {
            asked += 1
            return menu
        }
    }

    private func makePane(edge: Edge, source: StubSource) -> TabPaneViewController {
        let pane = TabPaneViewController(edge: edge, tabID: UUID())
        pane.dataSource = source
        pane.loadViewIfNeeded()
        pane.reload()
        return pane
    }

    func testReloadFillsTheLabelsFromTheDataSource() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        XCTAssertEqual(pane.paneView.agentLabel.stringValue, "Claude · Fable 5.1")
        XCTAssertEqual(pane.paneView.sessionLabel.stringValue, "tabs")
        XCTAssertEqual(pane.paneView.branchLabel.stringValue, "tabs")
        XCTAssertTrue(pane.paneView.directoryLabel.stringValue.hasSuffix("worktrees/tabs"))
        XCTAssertTrue(pane.paneView.summaryLabel.isHidden)
    }

    func testAModelOfNilShowsOnlyTheAgent() {
        let source = StubSource()
        source.model = nil
        let pane = makePane(edge: .left, source: source)
        XCTAssertEqual(pane.paneView.agentLabel.stringValue, "Claude")
    }

    /// The user's requirement that a tab look the same on all four edges,
    /// asserted where it is decided: `TabPaneView.contentSize` no longer
    /// switches on the edge, so the same content measures identically
    /// wherever it is hosted. A per-edge arrangement coming back — a taller
    /// stacked card on the vertical bars, say — fails here first.
    func testEveryEdgeMeasuresTheSameCard() {
        let source = StubSource()
        let sizes = Edge.allCases.map { makePane(edge: $0, source: source).preferredContentSize }
        for size in sizes {
            XCTAssertEqual(size, sizes[0])
        }
        // The floors the measurement is built on: never narrower than
        // `minWidth`, never shorter than `minHeight`.
        XCTAssertGreaterThanOrEqual(sizes[0].width, TabPaneView.minWidth)
        XCTAssertGreaterThanOrEqual(sizes[0].height, TabPaneView.minHeight)
    }

    /// Discriminates `max(Self.minWidth, fittingSize.width)`: content that
    /// fits well inside the card still reports exactly `minWidth`, so a
    /// narrow tab never shrinks to its text.
    func testShortContentStillMeasuresTheMinimumWidth() {
        let source = StubSource()
        source.agent = "C"
        source.model = nil
        source.session = "s"
        source.directory = URL(fileURLWithPath: "/a")
        source.branch = "b"
        let pane = makePane(edge: .top, source: source)
        XCTAssertEqual(pane.preferredContentSize.width, TabPaneView.minWidth)
    }

    /// Review C MAJOR-1: `TabPaneView.contentSize`'s `.top`/`.bottom` arm
    /// returned a literal height with no `max` against `fittingSize.height`,
    /// so a pane whose content needed more than that got clipped (and fought a
    /// required constraint pin) instead of the bar growing to fit. This drives
    /// a real
    /// `ThemeManager` with an enlarged `textScale`, the same knob the
    /// review's own "concrete failure" traces to (`ThemeTypography.sizeScale`,
    /// composed into the live palette `ThemedLabel` actually paints with via
    /// `SemanticPalette.scaled(by:)`), so the row's single line of text
    /// genuinely no longer fits in 28pt. `ThemeManager.shared` is weak, so
    /// the locally-owned `manager` reverts it to `nil` — the test-default
    /// fallback every other test in this file already relies on — the
    /// moment this function returns; no explicit teardown is needed.
    func testTopPaneHeightGrowsToFitOversizedContent() {
        let manager = ThemeManager(storage: StubThemeStorage(), appearanceDriver: nil)
        manager.textScale = 3

        let source = StubSource()
        let top = makePane(edge: .top, source: source)

        XCTAssertGreaterThan(top.preferredContentSize.height, TabPaneView.minHeight)
        XCTAssertEqual(top.preferredContentSize.height, top.paneView.fittingSize.height, accuracy: 0.5)
    }

    /// Discriminates `TabPaneView.contentSize`'s
    /// `min(Self.maxWidth, fittingSize.width)` — long enough content that
    /// `fittingSize.width` genuinely exceeds `maxWidth` still reports exactly
    /// `maxWidth`, which only holds while the `min` is there.
    func testPaneWidthIsCappedAtMaxWidth() {
        let source = StubSource()
        source.agent = String(repeating: "Agent Name ", count: 20)
        source.model = String(repeating: "Model Name ", count: 20)
        source.session = String(repeating: "session-name-", count: 20)
        source.branch = String(repeating: "branch-name-", count: 20)
        source.summary = String(repeating: "summary text ", count: 20)
        let top = makePane(edge: .top, source: source)
        XCTAssertEqual(top.preferredContentSize.width, TabPaneView.maxWidth)
    }

    /// Discriminates the `~`-substitution branch of
    /// `TabPaneViewController.abbreviate`, which the other tests never
    /// exercise because their stub path sits outside the home directory.
    func testWorkingDirectoryUnderHomeIsAbbreviatedWithATilde() {
        let source = StubSource()
        // Same API `TabPaneViewController.abbreviate` reads, not
        // `NSHomeDirectory()` — the two are not guaranteed to agree, so a
        // mismatch here could go green against a production path this test
        // never actually exercises.
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        source.directory = URL(fileURLWithPath: home + "/Projects/worktrees/tabs")
        let pane = makePane(edge: .left, source: source)
        XCTAssertEqual(pane.paneView.directoryLabel.stringValue, "~/Projects/worktrees/tabs")
    }

    /// Discriminates `TabPaneViewController.reload()`'s final
    /// `preferredContentSize = paneView.contentSize` line on a *second*
    /// call: the first pass is deliberately short enough to measure the
    /// `minWidth` floor and the second long enough to reach `maxWidth`, so a
    /// second pass that skips recomputing `preferredContentSize` leaves it at
    /// the first call's narrower width.
    func testReloadTwiceFollowsChangedDataSourceValues() {
        let source = StubSource()
        source.agent = "C"
        source.model = nil
        source.session = "s"
        source.directory = URL(fileURLWithPath: "/a")
        source.branch = "b"
        let pane = makePane(edge: .left, source: source)
        XCTAssertEqual(pane.preferredContentSize.width, TabPaneView.minWidth)

        source.agent = "Codex"
        source.session = String(repeating: "renamed-session-", count: 20)
        source.branch = String(repeating: "renamed-branch-", count: 20)
        source.summary = String(repeating: "now has a summary ", count: 20)
        pane.reload()

        XCTAssertEqual(pane.paneView.agentLabel.stringValue, "Codex")
        XCTAssertTrue(pane.paneView.sessionLabel.stringValue.hasPrefix("renamed-session-"))
        XCTAssertTrue(pane.paneView.branchLabel.stringValue.hasPrefix("renamed-branch-"))
        XCTAssertTrue(pane.paneView.summaryLabel.stringValue.hasPrefix("now has a summary "))
        XCTAssertFalse(pane.paneView.summaryLabel.isHidden)
        XCTAssertEqual(pane.preferredContentSize.width, TabPaneView.maxWidth)
    }

    /// Discriminates `TabPaneViewController.reload()`'s
    /// `paneView.branchLabel.isHidden = branch == nil` line specifically on
    /// a *second* call: the first `reload()` in `makePane` already leaves a
    /// non-nil branch visible, so only a genuine second pass that
    /// re-evaluates this line catches a branch that goes nil turning the
    /// label hidden.
    func testReloadTwiceHidesTheBranchLabelWhenBranchGoesNil() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        XCTAssertFalse(pane.paneView.branchLabel.isHidden)

        source.branch = nil
        pane.reload()
        XCTAssertTrue(pane.paneView.branchLabel.isHidden)
    }

    /// Discriminates `TabPaneView.setStatusSymbols`'s
    /// `for view in statusViews { statusStack.removeView(view) }` — without
    /// it, a second call leaves the first call's symbol views parented
    /// alongside the new ones instead of replacing them.
    func testSetStatusSymbolsTwiceDoesNotAccumulateViews() {
        let source = StubSource()
        source.symbols = [TabPaneStatusSymbol.idle]
        let pane = makePane(edge: .left, source: source)
        XCTAssertEqual(pane.paneView.statusStack.arrangedSubviews.count, 1)

        source.symbols = [
            TabPaneStatusSymbol.idle,
            TabPaneStatusSymbol(symbolName: "bolt.fill", accessibilityLabel: "Busy"),
            TabPaneStatusSymbol(symbolName: "checkmark.circle", accessibilityLabel: "Done")
        ]
        pane.reload()
        XCTAssertEqual(pane.paneView.statusStack.arrangedSubviews.count, 3)
    }

    func testAccessibilityIdentifiersCarryTheTabID() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        let id = pane.tabID.uuidString
        XCTAssertEqual(pane.view.accessibilityIdentifier(), "tab-pane.\(id)")
        XCTAssertEqual(pane.paneView.agentLabel.accessibilityIdentifier(), "tab-pane.agent.\(id)")
        XCTAssertEqual(pane.paneView.sessionLabel.accessibilityIdentifier(), "tab-pane.session.\(id)")
        XCTAssertEqual(pane.paneView.branchLabel.accessibilityIdentifier(), "tab-pane.branch.\(id)")
        XCTAssertEqual(pane.paneView.directoryLabel.accessibilityIdentifier(), "tab-pane.directory.\(id)")
        XCTAssertEqual(pane.paneView.summaryLabel.accessibilityIdentifier(), "tab-pane.summary.\(id)")
        XCTAssertEqual(pane.paneView.closeButton.accessibilityIdentifier(), "tab-pane.close.\(id)")
        // tab-pane-052: the tooltip names the action.
        XCTAssertEqual(pane.paneView.closeButton.toolTip, "Close Tab")
        // The icon's description matches the tooltip, as the tab bar's does.
        XCTAssertEqual(pane.paneView.closeButton.image?.accessibilityDescription, "Close Tab")
    }

    /// The close button belongs on the end of the card facing away from the
    /// workspace, so it never sits between the card's text and the pane it
    /// belongs to. On a left bar that is the leading end; everywhere else the
    /// trailing one.
    func testCloseButtonSitsOnTheEndFacingAwayFromTheWorkspace() {
        let source = StubSource()
        for edge in Edge.allCases {
            let pane = makePane(edge: edge, source: source)
            let row = pane.paneView.closeButton.superview as? NSStackView
            let expected = edge == .left ? row?.arrangedSubviews.first : row?.arrangedSubviews.last
            XCTAssertTrue(expected === pane.paneView.closeButton, "wrong end on \(edge)")
        }
    }

    /// A selected tab is not highlighted — it is promoted. Its name goes to the
    /// accent rather than to `.selectionText`, because the card is painting the
    /// workspace's own plane underneath it, not a selection fill.
    func testSelectionPromotesTheTextInsteadOfHighlightingIt() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)

        XCTAssertEqual(pane.paneView.agentLabel.role, .primaryText)

        pane.isHighlighted = true
        XCTAssertEqual(pane.paneView.agentLabel.role, .accent)
        XCTAssertEqual(pane.paneView.sessionLabel.role, .primaryText)
    }

    /// An inactive card is not a dimmed copy of the active one: the two sit on
    /// different planes, and the inactive card's is the one the bar is on.
    func testAnInactiveCardSitsOnTheBarsPlaneAndTheActiveOneOnTheWorkspaces() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        let palette = pane.paneView.resolvedThemeScope.palette

        XCTAssertEqual(pane.paneView.cardFillColor, palette.nsColor(.windowBackground))
        XCTAssertEqual(pane.paneView.cardBorderColor, palette.nsColor(.border))

        pane.isHighlighted = true
        XCTAssertEqual(pane.paneView.cardFillColor, NSColor(palette.projectPaneBackdrop))
        XCTAssertEqual(pane.paneView.cardBorderColor, NSColor(palette.projectPaneOutline))
    }

    /// How far short of the workspace's line a card behind stops on this edge:
    /// one `inactiveInset` step on a horizontal bar, and on a vertical bar the
    /// larger `verticalInactiveShortfall`, so the card in front is plainly the
    /// longest one in the column (6c9f4385b).
    private func behindOverhang(on edge: Edge) -> CGFloat {
        edge.isVertical ? -TabPaneView.verticalInactiveShortfall : -TabPaneView.inactiveInset
    }

    /// The workspace's outline is covered by the one card that is joined to the
    /// workspace, and by nothing else: a card behind stands back from that line
    /// instead, so it runs past whole.
    func testOnlyTheActiveCardReachesOverTheWorkspacesOutline() {
        let source = StubSource()
        for edge in Edge.allCases {
            let pane = makePane(edge: edge, source: source)
            XCTAssertEqual(
                pane.paneView.workspaceOverhang, behindOverhang(on: edge), "inactive card on \(edge)")

            pane.isHighlighted = true
            XCTAssertEqual(
                pane.paneView.workspaceOverhang, TabPaneView.workspaceOverlap, "active card on \(edge)")

            pane.isHighlighted = false
            XCTAssertEqual(
                pane.paneView.workspaceOverhang, behindOverhang(on: edge), "deselected card on \(edge)")
        }
    }

    /// On a vertical bar a card behind is the shorter shape across the bar:
    /// it keeps the card's outer edge and its full height, and stops
    /// `verticalInactiveShortfall` short of the workspace — so the card in
    /// front, which runs from that same outer edge out over the workspace's
    /// line, is plainly the longest (9a9964e21 slid the vertical cards instead
    /// of shrinking them on every side; 6c9f4385b made the front one the
    /// longest).
    func testACardBehindIsPaintedSmallerThanTheCardInFront() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        pane.paneView.frame = NSRect(x: 0, y: 0, width: 260, height: 140)
        pane.paneView.layoutSubtreeIfNeeded()
        let bounds = pane.paneView.bounds
        let behind = pane.paneView.cardPaintFrame
        XCTAssertEqual(
            behind,
            NSRect(x: bounds.minX, y: bounds.minY,
                   width: bounds.width - TabPaneView.verticalInactiveShortfall, height: bounds.height))

        pane.isHighlighted = true
        pane.paneView.layoutSubtreeIfNeeded()
        let front = pane.paneView.cardPaintFrame
        XCTAssertGreaterThan(front.width, behind.width)
        XCTAssertEqual(front.minX, behind.minX, accuracy: 0.01, "the two share the outer edge")
    }

    /// On a vertical bar every card behind stops the same distance short of
    /// the workspace, however far it is from the card in front: the cards are
    /// spaced like a horizontal bar's, no longer fanned as an overlapping deck
    /// that stepped back further per depth (fcdbf39fb).
    func testEveryCardBehindStopsTheSameShortfallShortOfTheWorkspaceOnAVerticalBar() {
        let source = StubSource()
        for edge in Edge.allCases where edge.isVertical {
            let pane = makePane(edge: edge, source: source)
            for depth in 1...(TabPaneView.maxStackDepth + 4) {
                pane.stackDepth = depth
                XCTAssertEqual(
                    pane.paneView.workspaceOverhang,
                    -TabPaneView.verticalInactiveShortfall,
                    "depth \(depth) on \(edge)")
            }
        }
    }

    /// A horizontal bar lays its cards out along their long side, so there is
    /// no column to fan: every card behind stands the same single step back.
    func testEveryCardBehindStandsTheSameStepBackOnAHorizontalBar() {
        let source = StubSource()
        for edge in Edge.allCases where !edge.isVertical {
            let pane = makePane(edge: edge, source: source)
            for depth in 1...(TabPaneView.maxStackDepth + 1) {
                pane.stackDepth = depth
                XCTAssertEqual(
                    pane.paneView.workspaceOverhang, -TabPaneView.inactiveInset, "depth \(depth) on \(edge)")
            }
        }
    }

    /// Every card behind on a vertical bar is painted the same shape, at any
    /// depth: the slot's full height, the slot's outer edge, and its workspace
    /// side pulled in by `verticalInactiveShortfall` — a column of equal cards
    /// spaced down the bar, not a deck shrinking card by card (fcdbf39fb,
    /// 9a9964e21, 6c9f4385b).
    func testEveryCardBehindIsPaintedTheSameShapeOnAVerticalBar() {
        let source = StubSource()
        let shortfall = TabPaneView.verticalInactiveShortfall
        for edge in Edge.allCases where edge.isVertical {
            let pane = makePane(edge: edge, source: source)
            pane.paneView.frame = NSRect(x: 0, y: 0, width: 260, height: 140)
            for depth in 1...TabPaneView.maxStackDepth {
                pane.stackDepth = depth
                pane.paneView.layoutSubtreeIfNeeded()
                let bounds = pane.paneView.bounds
                // The workspace is on the trailing side of a left bar and the
                // leading side of a right one.
                let minX = edge == .left ? bounds.minX : bounds.minX + shortfall
                XCTAssertEqual(
                    pane.paneView.cardPaintFrame,
                    NSRect(x: minX, y: bounds.minY, width: bounds.width - shortfall, height: bounds.height),
                    "depth \(depth) on \(edge)")
            }
        }
    }

    /// The card moves, not the frame drawn around it: a card standing back
    /// takes its text with it, so the words are where the card is rather than
    /// where the card used to be. Along the bar the text is centred in the
    /// slot (9a9964e21).
    func testACardStandingBackTakesItsTextWithIt() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        pane.paneView.frame = NSRect(x: 0, y: 0, width: 260, height: 140)
        for depth in 1...TabPaneView.maxStackDepth {
            pane.stackDepth = depth
            pane.paneView.layoutSubtreeIfNeeded()
            let text = pane.paneView.cardTextFrame
            let paint = pane.paneView.cardPaintFrame
            XCTAssertEqual(text.minX, paint.minX, accuracy: 0.01, "depth \(depth)")
            XCTAssertEqual(text.maxX, paint.maxX, accuracy: 0.01, "depth \(depth)")
            XCTAssertEqual(text.midY, pane.paneView.bounds.midY, accuracy: 0.5, "depth \(depth)")
        }
    }

    /// The card in front is the one place the two part company: its paint
    /// reaches out over the workspace's own line, and its text does not follow
    /// it out there — it spans the card across the bar, centred along it.
    func testTheFrontCardsTextStaysInsideTheCardItsPaintReachesOutOf() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        pane.paneView.frame = NSRect(x: 0, y: 0, width: 260, height: 140)
        pane.isHighlighted = true
        pane.paneView.layoutSubtreeIfNeeded()
        let bounds = pane.paneView.bounds
        let text = pane.paneView.cardTextFrame
        XCTAssertEqual(text.minX, bounds.minX, accuracy: 0.01)
        XCTAssertEqual(text.maxX, bounds.maxX, accuracy: 0.01)
        XCTAssertEqual(text.midY, bounds.midY, accuracy: 0.5)
        XCTAssertEqual(
            pane.paneView.cardPaintFrame.maxX,
            pane.paneView.bounds.maxX + TabPaneView.workspaceOverlap,
            accuracy: 0.01)
    }

    /// A card off screen lands at its new depth rather than moving to it —
    /// there is nothing to watch, and an animated constraint would still read
    /// its old value to whatever measured the card next. Measured on the move
    /// from behind to in front, the one change of depth that moves a vertical
    /// bar's card at all now that every card behind stands the same distance
    /// back (fcdbf39fb).
    func testACardOffScreenTakesItsNewDepthImmediately() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        XCTAssertFalse(pane.paneView.animatesDepthChanges)
        XCTAssertEqual(pane.paneView.workspaceOverhang, -TabPaneView.verticalInactiveShortfall)

        pane.isHighlighted = true
        XCTAssertEqual(pane.paneView.workspaceOverhang, TabPaneView.workspaceOverlap)
    }

    /// On screen it moves instead, so the deck is seen to turn.
    func testACardInAWindowMovesToItsNewDepth() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled], backing: .buffered, defer: true)
        // The bar this card hangs in is layer-backed, so the card is too; an
        // animated layout is what it is in the app, not a bare constant swap.
        window.contentView?.wantsLayer = true
        window.contentView?.addSubview(pane.paneView)
        XCTAssertTrue(pane.paneView.animatesDepthChanges)

        pane.paneView.frame = NSRect(x: 0, y: 0, width: 260, height: 140)
        pane.paneView.layoutSubtreeIfNeeded()
        pane.stackDepth = TabPaneView.maxStackDepth

        // The card is *moving*, not moved: an animation is attached and still
        // running, which is the whole of the difference between a deck seen to
        // turn and one that is suddenly dealt differently. Asserting the
        // constant alone would pass just as well with no animation at all.
        XCTAssertFalse(pane.paneView.runningMoveAnimationKeys.isEmpty)
    }

    /// Selection and depth arrive from the bar as two separate statements, and
    /// the card draws from one number: a card that is not selected is never
    /// drawn as the card in front, whichever order the two arrive in.
    func testADeselectedCardIsNeverTheCardInFrontWhateverDepthItWasTold() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)

        pane.stackDepth = 0
        XCTAssertEqual(pane.paneView.workspaceOverhang, behindOverhang(on: .left))

        pane.isHighlighted = true
        XCTAssertEqual(pane.paneView.workspaceOverhang, TabPaneView.workspaceOverlap)

        pane.isHighlighted = false
        XCTAssertEqual(pane.paneView.workspaceOverhang, behindOverhang(on: .left))
    }

    /// The words are readable whichever card they are on — an inactive tab
    /// recedes by its plane, never by fading its own text out of legibility.
    func testAnInactiveCardsTextStaysAtReadableRoles() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        for role in [pane.paneView.agentLabel.role, pane.paneView.sessionLabel.role,
                     pane.paneView.directoryLabel.role, pane.paneView.branchLabel.role] {
            XCTAssertNotEqual(role, .placeholderText)
        }
    }

    func testClosePressedFiresOnClose() {
        let source = StubSource()
        let pane = makePane(edge: .left, source: source)
        var closed = false
        pane.onClose = { closed = true }
        pane.paneView.closeButton.performClick(nil)
        XCTAssertTrue(closed)
    }

    func testContextMenuComesFromTheDelegate() {
        let source = StubSource()
        let delegate = StubDelegate()
        let pane = makePane(edge: .left, source: source)
        pane.delegate = delegate
        let event = NSEvent.mouseEvent(with: .rightMouseDown, location: .zero, modifierFlags: [], timestamp: 0,
                                       windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
        XCTAssertTrue(pane.paneView.menu(for: event) === delegate.menu)
        XCTAssertEqual(delegate.asked, 1)
    }
}
