import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

private final class DisclosureCardThemeStorage: ThemeStorage {
    var customThemes: [ColorTheme] = []
    var activeThemeID: String?
    var onExternalChange: (() -> Void)?
}

/// Pins the rules a stack of folding cards lives by: the arithmetic of the
/// remembered set (`CardFoldMemory`); the one that a fold is a change of HEIGHT
/// — a card is exactly as wide shut as it is open, so a window that hugs its
/// content cannot jump sideways when the reader clicks a disclosure triangle;
/// and where a card's standing goes now that it is a corner badge rather than a
/// reserved slot on the masthead.
@MainActor
final class DisclosureCardTests: XCTestCase {

    // MARK: - The remembered set

    func testFoldingACardRecordsItAndUnfoldingForgetsIt() {
        var keys = CardFoldMemory.toggling([], key: "usage", collapsed: true)
        XCTAssertEqual(keys, ["usage"])

        keys = CardFoldMemory.toggling(keys, key: "usage", collapsed: false)
        XCTAssertEqual(keys, [], "open is ABSENT, not stored as false")
    }

    func testFoldingTwiceDoesNotStoreTheCardTwice() {
        let once = CardFoldMemory.toggling(["a"], key: "usage", collapsed: true)
        let twice = CardFoldMemory.toggling(once, key: "usage", collapsed: true)
        XCTAssertEqual(twice, ["a", "usage"])
    }

    func testUnfoldingOneCardLeavesTheOthersFolded() {
        XCTAssertEqual(
            CardFoldMemory.toggling(["a", "usage", "b"], key: "usage", collapsed: false),
            ["a", "b"]
        )
    }

    func testAMemoryReadsAndWritesTheHostsStore() {
        var stored: [String] = []
        var rebuilds = 0
        let memory = CardFoldMemory(
            read: { stored },
            write: { stored = $0 },
            rebuild: { rebuilds += 1 }
        )
        XCTAssertFalse(memory.isCollapsed("a"))

        memory.setCollapsed(true, key: "a")
        XCTAssertEqual(stored, ["a"])
        XCTAssertTrue(memory.isCollapsed("a"))
        // The rebuild is deferred to the next turn of the runloop on purpose:
        // it tears down the very button that is still dispatching the click.
        XCTAssertEqual(rebuilds, 0, "a rebuild must not run inside the toggle's own action")
    }

    func testACardBuiltThroughTheMemoryOpensInTheRememberedState() {
        let memory = CardFoldMemory(read: { ["shut"] }, write: { _ in }, rebuild: {})

        XCTAssertTrue(memory.card(key: "shut", title: "Shut", scaledSize: 13).isCollapsed)
        XCTAssertFalse(memory.card(key: "open", title: "Open", scaledSize: 13).isCollapsed)
    }

    // MARK: - Folding is a change of height, never of width

    private func card(isCollapsed: Bool) -> DisclosureCardView {
        let card = DisclosureCardView(
            title: "mike@example.com",
            titleIsAccent: true,
            summary: [
                .init(name: "5H", value: "23%", colorName: "blue"),
                .init(name: "7D", value: "12%", colorName: "green")
            ],
            status: .init(
                symbolName: "octagon.fill", colorName: "red", accessibilityLabel: "Spent"
            ),
            isCollapsed: isCollapsed,
            scaledSize: 13
        )
        let wide = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 60))
        wide.widthAnchor.constraint(equalToConstant: 600).isActive = true
        // A height as well as a width: the folded card writes its summary on a
        // row of its own, so a card whose content measures zero points tall is
        // TALLER shut than open, and correctly so. What the fold is for is
        // putting away content, and content has a size.
        wide.heightAnchor.constraint(equalToConstant: 60).isActive = true
        card.addContent(wide)
        // Hosted rather than merely measured: a card that was never given a
        // size lays its subviews out against a frame nothing set, so anything
        // about WHERE a subview lands has to be read off a laid-out card.
        host(card, width: 700)
        return card
    }

    /// Puts a card in a view of a known width and lays it out, returning the
    /// host so a test can compare the two.
    @discardableResult
    private func host(_ card: DisclosureCardView, width: CGFloat) -> NSView {
        card.translatesAutoresizingMaskIntoConstraints = false
        let host = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 400))
        host.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            card.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        host.layoutSubtreeIfNeeded()
        return host
    }

    func testAFoldedCardIsExactlyAsWideAsAnOpenOne() {
        // The bug this pins: a folded card that dropped its content asked for a
        // narrower window, so every disclosure click moved the window sideways.
        XCTAssertEqual(card(isCollapsed: true).fittingSize.width,
                       card(isCollapsed: false).fittingSize.width,
                       accuracy: 0.5)
    }

    func testAFoldedCardIsShorterThanAnOpenOne() {
        // …and the fold still does the one thing it is for.
        XCTAssertLessThan(card(isCollapsed: true).fittingSize.height,
                          card(isCollapsed: false).fittingSize.height)
    }

    func testACardIsNeverNarrowerThanTheContentItIsHiding() {
        let card = card(isCollapsed: true)
        XCTAssertGreaterThanOrEqual(card.fittingSize.width, 600,
                                    "the hidden content still sets the card's width floor")
    }

    func testAFoldedCardIsAsWideAsAnOpenOneEvenWhenItsSummaryIsWiderThanItsContent() {
        // The other half of the same rule, and the one the masthead floor is
        // for: with the summary's row out of the OPEN card's layout, the width
        // it will want on folding has to be reserved somewhere that does not
        // depend on which state the card is in.
        func narrow(isCollapsed: Bool) -> DisclosureCardView {
            let card = DisclosureCardView(
                title: "me@x.com",
                titleIsAccent: true,
                summary: [
                    .init(name: "5H", value: "23%", colorName: "blue"),
                    .init(name: "7D", value: "12%", colorName: "green")
                ],
                isCollapsed: isCollapsed,
                scaledSize: 13
            )
            let tiny = NSView()
            tiny.translatesAutoresizingMaskIntoConstraints = false
            tiny.widthAnchor.constraint(equalToConstant: 40).isActive = true
            tiny.heightAnchor.constraint(equalToConstant: 20).isActive = true
            card.addContent(tiny)
            card.layoutSubtreeIfNeeded()
            return card
        }
        XCTAssertEqual(narrow(isCollapsed: true).fittingSize.width,
                       narrow(isCollapsed: false).fittingSize.width,
                       accuracy: 0.5)
    }

    // MARK: - The masthead is a bar, not the first row of the content

    /// The bar itself, found by position rather than by outlet: it is the one
    /// thing inside the surface, and the surface is the one thing under the card
    /// (the badge and the stack are added after it).
    private func titlebar(of card: DisclosureCardView) -> NSView? {
        card.subviews.first?.subviews.first
    }

    /// A card carrying whatever a test needs and nothing it doesn't, hosted and
    /// laid out. `card(isCollapsed:)` above always has a summary, a standing and
    /// content, and what the bar does when one of those is ABSENT is most of
    /// what these tests are about.
    private func bare(
        isCollapsed: Bool,
        summary: [DisclosureCardView.SummaryPart] = [],
        titleAccessory: NSView? = nil,
        titleTrailingStatus: DisclosureCardView.StatusSymbol? = nil
    ) -> DisclosureCardView {
        let card = DisclosureCardView(
            title: "mike@example.com",
            titleIsAccent: true,
            titleAccessory: titleAccessory,
            titleTrailingStatus: titleTrailingStatus,
            summary: summary,
            status: .init(
                symbolName: "octagon.fill", colorName: "red", accessibilityLabel: "Spent"
            ),
            isCollapsed: isCollapsed,
            scaledSize: 13
        )
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 120))
        content.widthAnchor.constraint(equalToConstant: 600).isActive = true
        content.heightAnchor.constraint(equalToConstant: 120).isActive = true
        card.addContent(content)
        host(card, width: 700)
        return card
    }

    func testTheBarCapsTheCardRatherThanFillingIt() {
        let card = bare(isCollapsed: false)
        guard let bar = titlebar(of: card), let name = field("mike@example.com", in: card) else {
            return XCTFail("every card has a titlebar and a name on it")
        }

        // Edge to edge and starting at the very top: the bar is the card's own
        // cap, which is what lets the surface's rounded corners clip it.
        XCTAssertEqual(bar.frame.width, card.frame.width, accuracy: 0.5)
        XCTAssertEqual(bar.frame.maxY, card.frame.height, accuracy: 0.5)
        // The name it carries is ON it — a bar the title had outgrown would be
        // a stripe behind nothing.
        let line = card.convert(name.bounds, from: name)
        XCTAssertGreaterThanOrEqual(line.minY, bar.frame.minY - 0.5)
        XCTAssertLessThanOrEqual(line.maxY, bar.frame.maxY + 0.5)
        // And it stops well short of the content, so it reads as a strip
        // capping the card rather than as the card's own background.
        XCTAssertLessThan(bar.frame.height, card.frame.height / 2)
    }

    func testAFoldedCardWithNothingToSayIsExactlyItsOwnTitlebar() {
        // The body leaves the layout entirely rather than standing there as an
        // empty stack between two insets — otherwise such a card ends in a
        // sliver of bare surface under the bar, which reads as a rendering bug.
        let card = bare(isCollapsed: true)
        guard let bar = titlebar(of: card) else { return XCTFail("no titlebar") }

        XCTAssertEqual(bar.frame.height, card.frame.height, accuracy: 0.5)
    }

    func testAFoldedCardWithASummaryStillKeepsABodyUnderItsBar() {
        // The summary IS the body in that case, so the bar is not the whole
        // card — the distinction the rule above turns on, and the reason it is
        // stated as "nothing to say" rather than "folded".
        let card = bare(
            isCollapsed: true,
            summary: [.init(name: "5H", value: "23%", colorName: "blue")]
        )
        guard let bar = titlebar(of: card) else { return XCTFail("no titlebar") }

        XCTAssertLessThan(bar.frame.height, card.frame.height - 1)
    }

    /// A mark of the host's own — a view the card is handed and does not own.
    private func mark() -> NSView {
        let view = NSImageView()
        view.image = NSImage(systemSymbolName: "person.crop.circle",
                             accessibilityDescription: nil)
        view.setAccessibilityElement(false)
        return view
    }

    func testTheHostsMarkInFrontOfTheNameMovesNeitherTheBadgeNorTheToggle() {
        // The mark is nested inside the masthead's leading end, so the badge is
        // still the card's own subview and the toggle is still pinned to the
        // trailing edge. A mark that shifted either would have moved the one
        // thing a stack of cards is scanned by.
        let plain = bare(isCollapsed: false)
        let marked = bare(isCollapsed: false, titleAccessory: mark())
        guard let plainBadge = badge(of: plain), let markedBadge = badge(of: marked),
              let plainToggle = toggle(of: plain), let markedToggle = toggle(of: marked) else {
            return XCTFail("both cards draw a standing and a toggle")
        }

        XCTAssertEqual(markedBadge.frame.origin.x, plainBadge.frame.origin.x, accuracy: 0.5)
        XCTAssertEqual(markedBadge.frame.origin.y, plainBadge.frame.origin.y, accuracy: 0.5)
        XCTAssertEqual(marked.convert(markedToggle.bounds, from: markedToggle).maxX,
                       plain.convert(plainToggle.bounds, from: plainToggle).maxX,
                       accuracy: 0.5)
    }

    func testTheHostsMarkStandsInFrontOfTheNameExactlyAsHanded() {
        let given = mark()
        let card = bare(isCollapsed: false, titleAccessory: given)
        guard let name = field("mike@example.com", in: card), let line = name.superview else {
            return XCTFail("a card sets its name on a line of its own")
        }

        XCTAssertTrue(line.subviews.contains(given), "the mark goes on the title's own line")
        XCTAssertFalse(given.isHidden, "a card given a mark draws it")
        XCTAssertLessThanOrEqual(given.frame.maxX, name.frame.minX + 0.5)
        // The card paints nothing of the host's mark — not its colours, and not
        // its place in the accessibility tree. A host that hands over a view
        // has already decided both.
        XCTAssertFalse(given.isAccessibilityElement())
    }

    /// A symbol a host puts after the name: the seal a stack of accounts
    /// awards the one to spend next.
    private static let seal = DisclosureCardView.StatusSymbol(
        symbolName: "checkmark.seal.fill", colorName: "green", accessibilityLabel: "Best"
    )

    /// The image the card draws after the name, found on the name's own line —
    /// the corner badge is the card's own subview, never on that line, so the
    /// two cannot be mistaken for each other.
    private func titleStatus(
        of card: DisclosureCardView, title: String = "mike@example.com"
    ) -> NSImageView? {
        field(title, in: card)?.superview?.subviews.compactMap { $0 as? NSImageView }.first
    }

    func testDisclosureCard047_theSymbolAfterTheNameStandsRightAgainstIt() {
        // Against the name, not out at the line's far end by the toggle: it is
        // something said about the name, so it has to read as part of it.
        let card = bare(isCollapsed: false, titleTrailingStatus: Self.seal)
        guard let name = field("mike@example.com", in: card), let seal = titleStatus(of: card)
        else { return XCTFail("a symbol after the name goes on the name's own line") }

        XCTAssertGreaterThanOrEqual(seal.frame.minX, name.frame.maxX - 0.5)
        XCTAssertLessThan(seal.frame.minX - name.frame.maxX, 12,
                          "the symbol drifted away from the name it is about")
    }

    func testDisclosureCard048_theSymbolAfterTheNameIsSpokenAndTintedFromTheLivePalette() {
        // Drawn the way the corner badge is: its own accessibility element, its
        // label as the tooltip, and its colour asked of the palette rather than
        // fixed when the card was built.
        let symbol = DisclosureCardView.StatusSymbol(
            symbolName: "xmark.seal.fill", accessibilityLabel: "Out of quota",
            color: { _ in .systemPurple }
        )
        let card = bare(isCollapsed: false, titleTrailingStatus: symbol)
        guard let seal = titleStatus(of: card) else { return XCTFail("no symbol after the name") }

        XCTAssertEqual(seal.alphaValue, 1)
        XCTAssertTrue(seal.isAccessibilityElement())
        XCTAssertEqual(seal.accessibilityLabel(), "Out of quota")
        XCTAssertEqual(seal.toolTip, "Out of quota",
                       "a symbol is not self-explaining, so its word stays reachable")
        XCTAssertEqual(seal.contentTintColor, .systemPurple)
    }

    func testDisclosureCard049_aPlaceholderHoldsTheSymbolsRoomAndSaysNothing() {
        // A stack that marks only some of its cards hands the rest a
        // placeholder. The room is identical, so a mark moving from one card to
        // another cannot widen or narrow a window that hugs its content — and
        // with nothing drawn, there is nothing to say or to explain.
        func card(_ symbol: DisclosureCardView.StatusSymbol) -> DisclosureCardView {
            let card = DisclosureCardView(
                title: Self.longAddress, titleIsAccent: true, titleTrailingStatus: symbol,
                isCollapsed: false, scaledSize: 13
            )
            let tiny = NSView()
            tiny.translatesAutoresizingMaskIntoConstraints = false
            tiny.widthAnchor.constraint(equalToConstant: 40).isActive = true
            tiny.heightAnchor.constraint(equalToConstant: 20).isActive = true
            card.addContent(tiny)
            host(card, width: card.fittingSize.width)
            return card
        }
        let marked = card(Self.seal)
        let unmarked = card(.placeholder(sizedLike: Self.seal.symbolName))
        guard let seal = titleStatus(of: marked, title: Self.longAddress),
              let room = titleStatus(of: unmarked, title: Self.longAddress) else {
            return XCTFail("both cards keep the symbol's place after the name")
        }

        XCTAssertEqual(unmarked.fittingSize.width, marked.fittingSize.width, accuracy: 0.5,
                       "a card without the mark asks for the width of one with it")
        XCTAssertEqual(room.frame.width, seal.frame.width, accuracy: 0.5)
        XCTAssertFalse(room.isHidden, "a stack gives a hidden view no room at all")
        XCTAssertEqual(room.alphaValue, 0)
        XCTAssertFalse(room.isAccessibilityElement(), "room is not a statement")
        XCTAssertNil(room.toolTip)
    }

    func testACardWithNoMarkLeavesNoGapWhereOneWouldHaveStood() {
        // Absent, not standing there empty: an arranged subview of zero width
        // still costs the stack its spacing, so a card with no mark would be
        // indented a few points further than one with — off the mark's own
        // leading edge, which is the alignment a stack of cards is read by.
        let plain = bare(isCollapsed: false)
        guard let name = field("mike@example.com", in: plain), let line = name.superview else {
            return XCTFail("a card sets its name on a line of its own")
        }

        XCTAssertEqual(line.subviews.count, 1, "the name is the whole of an unmarked title line")
        // Measured on the label's ALIGNMENT rect, not its frame: a text field's
        // frame overhangs its own text by a couple of points on each side, and
        // a stack lays out the alignment rects, so it is the alignment rect
        // that sits flush against the line's leading edge. Against the frame
        // this reads as a two-point negative indent that no card actually has.
        XCTAssertEqual(name.alignmentRect(forFrame: name.frame).minX, 0, accuracy: 0.5)
    }

    func testTheNameSitsNearerTheCardsBorderThanTheReadingsItCaps() {
        // The masthead is a heading, so it runs at a tighter gutter than the
        // rows under it — the same halving its vertical inset already takes.
        // The content keeps the gutter it always had, which is what lets this
        // move the name alone and leave every reading where it was.
        let card = DisclosureCardView(
            title: "mike@example.com", titleIsAccent: true, scaledSize: 13
        )
        let row = NSView()
        row.heightAnchor.constraint(equalToConstant: 40).isActive = true
        card.addContent(row)
        host(card, width: 700)

        guard let name = field("mike@example.com", in: card), let line = name.superview else {
            return XCTFail("a card sets its name on a line of its own")
        }
        let titleX = card.convert(line.bounds, from: line).minX
        let rowX = card.convert(row.bounds, from: row).minX

        XCTAssertLessThan(titleX, rowX, "the name reaches nearer the border than the rows do")
        XCTAssertGreaterThan(titleX, 0, "and never touches it")
    }

    // MARK: - The standing is a corner badge

    /// The badge and the toggle, found by kind rather than by outlet — the card
    /// keeps both private, and what these tests are about is where they land.
    private func badge(of card: DisclosureCardView) -> NSImageView? {
        card.subviews.compactMap { $0 as? NSImageView }.first
    }

    private func toggle(of card: DisclosureCardView) -> NSButton? {
        func find(_ view: NSView) -> NSButton? {
            if let button = view as? NSButton { return button }
            for child in view.subviews {
                if let found = find(child) { return found }
            }
            return nil
        }
        return find(card)
    }

    private func field(_ text: String, in card: DisclosureCardView) -> NSTextField? {
        func find(_ view: NSView) -> NSTextField? {
            if let label = view as? NSTextField, label.stringValue == text { return label }
            for child in view.subviews {
                if let found = find(child) { return found }
            }
            return nil
        }
        return find(card)
    }

    func testTheStandingSitsOnTheCardsTopRightCornerAndNeverOverTheToggle() {
        let card = card(isCollapsed: false)
        guard let badge = badge(of: card), let toggle = toggle(of: card) else {
            return XCTFail("a card with a standing draws a badge, and every card has a toggle")
        }
        XCTAssertFalse(badge.isHidden)
        // Centred on the corner the card actually DRAWS — the peak of its
        // rounded corner, a couple of points down and in from the square corner
        // of the frame, where there is no ink at all. Half the badge hangs off
        // the card from there. Measured on the ALIGNMENT rect, which is what the
        // constraints place — an SF Symbol carries alignment insets, so its
        // frame spills a point or two past the box the engine positioned.
        let peak = DisclosureCardView.cornerPeakInset
        XCTAssertGreaterThan(peak, 0, "a rounded corner peaks inside its frame")
        let box = badge.alignmentRect(forFrame: badge.frame)
        XCTAssertEqual(box.midX, card.bounds.maxX - peak, accuracy: 0.5)
        XCTAssertEqual(box.midY, card.bounds.maxY - peak, accuracy: 0.5)
        XCTAssertEqual(box.width, DisclosureCardView.cornerBadgeDiameter(scaledSize: 13),
                       accuracy: 0.5)
        // …and clear of the triangle, which is the whole constraint on where the
        // corner may be: the badge lives in the gutter to the RIGHT of it.
        let triangle = toggle.convert(toggle.bounds, to: card)
        XCTAssertFalse(badge.frame.intersects(triangle),
                       "the badge must not cover the disclosure toggle")
        XCTAssertGreaterThanOrEqual(badge.frame.minX, triangle.maxX)
    }

    /// A `CALayer` paints its own border above its sublayers, so a card that
    /// drew its own border would draw a hairline across the badge stamped on its
    /// corner. The border belongs to a subview under the badge instead — and the
    /// badge is the last subview, so it is drawn over it.
    func testTheBorderIsDrawnUnderTheBadgeRatherThanAcrossIt() {
        let card = card(isCollapsed: false)
        card.layoutSubtreeIfNeeded()
        XCTAssertEqual(card.layer?.borderWidth ?? 0, 0,
                       "the card itself must not draw a border over its own subviews")
        guard let surface = card.subviews.first else { return XCTFail("a card draws a surface") }
        XCTAssertGreaterThan(surface.layer?.borderWidth ?? 0, 0)
        XCTAssertNotNil(surface.layer?.backgroundColor)
        XCTAssertEqual(surface.frame, card.bounds, "the surface is the whole card")
        XCTAssertTrue(card.subviews.last === badge(of: card),
                      "the badge is drawn last, and so above the border")
    }

    func testACardWithNothingToReportDrawsNothing() {
        // No reserved slot any more: a card with no standing pays nothing for
        // the cards that have one.
        let card = DisclosureCardView(title: "Quiet", titleIsAccent: false, scaledSize: 13)
        card.layoutSubtreeIfNeeded()
        XCTAssertEqual(badge(of: card)?.isHidden, true)
    }

    func testTheStandingIsSpokenSinceItShareItsLineWithNothing() {
        let card = card(isCollapsed: true)
        XCTAssertEqual(badge(of: card)?.accessibilityLabel(), "Spent")
        XCTAssertEqual(badge(of: card)?.toolTip, "Spent")
    }

    // MARK: - The title gets the room the summary is not using

    func testWhenTheWindowCannotGrowItIsTheTitleThatYields() {
        // The card asks for room for both, but a window can refuse. Held to a
        // width neither fits in, it is the address that goes short: a truncated
        // address is still recognisable, and a truncated percentage is a lie.
        let title = "a-very-long-address@some-organisation.example.com"
        let card = DisclosureCardView(
            title: title,
            titleIsAccent: true,
            summary: [
                .init(name: "5H", value: "23%", colorName: "blue"),
                .init(name: "7D", value: "12%", colorName: "green")
            ],
            isCollapsed: true,
            scaledSize: 13
        )
        card.translatesAutoresizingMaskIntoConstraints = false
        let host = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))
        host.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            card.topAnchor.constraint(equalTo: host.topAnchor),
            // Required, so it beats the card's own width floor the way a window
            // the reader has dragged narrow does.
            card.widthAnchor.constraint(equalToConstant: 300)
        ])
        host.layoutSubtreeIfNeeded()

        guard let label = field(title, in: card) else { return XCTFail("no title") }
        XCTAssertLessThan(label.frame.width, label.fittingSize.width,
                          "there was no room for the whole address, so it must have gone short")
        XCTAssertGreaterThan(label.frame.width, 0)
    }

    func testACardAsksForTheRoomToWriteItsTitleWhole() {
        // The other half: the width a folded card asks for counts its title at
        // full length. Truncation is what a title does when the window can be
        // no wider — not what it does while the card is free to ask for another
        // forty points.
        let title = "a-very-long-address@some-organisation.example.com"
        let card = DisclosureCardView(
            title: title,
            titleIsAccent: true,
            summary: [
                .init(name: "5H", value: "23%", colorName: "blue"),
                .init(name: "7D", value: "12%", colorName: "green")
            ],
            isCollapsed: true,
            scaledSize: 13
        )
        let tiny = NSView()
        tiny.translatesAutoresizingMaskIntoConstraints = false
        tiny.widthAnchor.constraint(equalToConstant: 40).isActive = true
        tiny.heightAnchor.constraint(equalToConstant: 20).isActive = true
        card.addContent(tiny)

        // At exactly the width the card asks for — a window that hugs its
        // content gives it that and no more.
        host(card, width: card.fittingSize.width)
        guard let label = field(title, in: card) else { return XCTFail("no title") }
        XCTAssertGreaterThanOrEqual(label.frame.width, label.fittingSize.width - 0.5,
                                    "the address was squeezed by a card that could have grown")
    }

    func testDisclosureCard050_aCardWithNoSummaryStillAsksForItsTitleWhole() {
        // A card with nothing to summarise is still a card whose name is its
        // handle: the window grows for it rather than cutting it short.
        let title = "a-very-long-address@some-organisation.example.com"
        let card = DisclosureCardView(
            title: title, titleIsAccent: true, titleTrailingStatus: Self.seal,
            isCollapsed: false, scaledSize: 13
        )
        let tiny = NSView()
        tiny.translatesAutoresizingMaskIntoConstraints = false
        tiny.widthAnchor.constraint(equalToConstant: 40).isActive = true
        tiny.heightAnchor.constraint(equalToConstant: 20).isActive = true
        card.addContent(tiny)

        host(card, width: card.fittingSize.width)
        guard let label = field(title, in: card) else { return XCTFail("no title") }
        XCTAssertGreaterThanOrEqual(label.frame.width, label.fittingSize.width - 0.5,
                                    "the address was squeezed by a card that could have grown")
    }

    func testAStackOfCardsIsAsWideAsItsLongestTitle() {
        // The Usage window's shape: marked cards with summaries and content
        // narrower than their names, in a `.width` stack that the window sizes
        // to its fitting width. The longest name must come out whole.
        let long = "mike@agenticdevelopmentstudio.com"
        func account(_ title: String) -> DisclosureCardView {
            let logo = NSButton(title: "", target: nil, action: nil)
            logo.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: nil)
            logo.isBordered = false
            logo.imagePosition = .imageOnly
            let card = DisclosureCardView(
                title: title, titleIsAccent: true, titleAccessory: logo,
                summary: Self.readings, isCollapsed: false, scaledSize: 16
            )
            let gauges = NSView()
            gauges.translatesAutoresizingMaskIntoConstraints = false
            gauges.widthAnchor.constraint(equalToConstant: 280).isActive = true
            gauges.heightAnchor.constraint(equalToConstant: 100).isActive = true
            card.addContent(gauges)
            return card
        }
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .width
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        let cards = [account("mike@example.com"), account(long)]
        for card in cards { stack.addArrangedSubview(card) }

        let width = stack.fittingSize.width
        let host = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 800))
        host.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            stack.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        host.layoutSubtreeIfNeeded()
        guard let label = field(long, in: cards[1]) else { return XCTFail("no title") }
        XCTAssertGreaterThanOrEqual(label.frame.width, label.fittingSize.width - 0.5,
                                    "stack \(width) cut the name short")
        // And the name stops well short of the toggle, not flush against it.
        func buttons(_ view: NSView) -> [NSButton] {
            view.subviews.flatMap { ($0 as? NSButton).map { [$0] } ?? buttons($0) }
        }
        guard let toggle = buttons(cards[1]).first(where: { $0.bezelStyle == .disclosure })
        else { return XCTFail("no toggle") }
        // Both edges by their alignment rects — what the layout pins, and where
        // the glyphs and the triangle are drawn; each frame carries a couple of
        // points of padding the eye never sees.
        func visible(_ view: NSView) -> NSRect {
            view.superview?.convert(view.alignmentRect(forFrame: view.frame), to: cards[1]) ?? .zero
        }
        XCTAssertGreaterThanOrEqual(
            visible(toggle).minX - visible(label).maxX,
            DisclosureCardView.mastheadGapFor(scaledSize: 16) - 0.5,
            "the longest name runs up against the toggle"
        )
    }

    // MARK: - The summary is a row of its own

    /// A folded card carrying the long address and the two readings.
    private func stacked(summary: [DisclosureCardView.SummaryPart]) -> DisclosureCardView {
        let card = DisclosureCardView(
            title: Self.longAddress,
            titleIsAccent: true,
            summary: summary,
            isCollapsed: true,
            scaledSize: 13
        )
        let tiny = NSView()
        tiny.translatesAutoresizingMaskIntoConstraints = false
        tiny.widthAnchor.constraint(equalToConstant: 40).isActive = true
        tiny.heightAnchor.constraint(equalToConstant: 20).isActive = true
        card.addContent(tiny)
        return card
    }

    private static let longAddress = "a-very-long-address@some-organisation.example.com"

    private static let readings: [DisclosureCardView.SummaryPart] = [
        .init(name: "5H", value: "23%", colorName: "blue"),
        .init(name: "7D", value: "12%", colorName: "green")
    ]

    func testTheSummaryIsWrittenUnderTheTitleRatherThanBesideIt() {
        let card = stacked(summary: Self.readings)
        host(card, width: card.fittingSize.width)

        guard let title = field(Self.longAddress, in: card) else { return XCTFail("no title") }
        guard let summary = field("5H: 23%  |  7D: 12%", in: card) else {
            return XCTFail("no summary")
        }
        guard let toggle = toggle(of: card) else { return XCTFail("no toggle") }
        let titleRect = card.convert(title.bounds, from: title)
        let summaryRect = card.convert(summary.bounds, from: summary)
        // The toggle's ALIGNMENT rect, not its frame: it draws an SF Symbol,
        // which carries insets, so the edge the engine lined the summary up
        // with is a point or two inside the image's box.
        let triangle = card.convert(toggle.alignmentRect(forFrame: toggle.bounds), from: toggle)
        XCTAssertLessThanOrEqual(summaryRect.maxY, titleRect.minY + 0.5,
                                 "the summary shares no line with the title")
        // And it is right-aligned across the WHOLE masthead — past where the
        // title's line stops to leave the toggle its corner, out to the same
        // edge the toggle ends on. That is what makes a stack of folded cards
        // read as a column of readings under one right edge.
        XCTAssertGreaterThan(summaryRect.maxX, titleRect.maxX)
        XCTAssertGreaterThanOrEqual(summaryRect.maxX, triangle.maxX,
                                    "out to the same edge the toggle ends on")
        XCTAssertLessThan(summaryRect.maxX, card.bounds.maxX,
                          "and inside the card's own padding")
    }

    func testALongerSummaryDoesNotWidenACardWhoseTitleIsWider() {
        // What stacking is FOR. Beside the title, every reading added its own
        // width plus a gap to a card that was already as wide as an address; on
        // a row of its own it costs nothing until it is wider than the address
        // itself, because the masthead needs the WIDER of its two rows and not
        // their sum. Two readings and one, against a title longer than either.
        XCTAssertEqual(stacked(summary: Self.readings).fittingSize.width,
                       stacked(summary: [Self.readings[0]]).fittingSize.width,
                       accuracy: 0.5)
    }

    // MARK: - Conformance vectors disclosure-card-001 ... 051

    private var palette: SemanticPalette { ThemePaletteObserver.currentPalette }

    private func makeCard(
        title: String = "mike@example.com",
        titleIsAccent: Bool = true,
        titleAccessory: NSView? = nil,
        titlebarAccessory: NSView? = nil,
        subtitle: String? = nil,
        summary: [DisclosureCardView.SummaryPart] = [],
        status: DisclosureCardView.StatusSymbol? = nil,
        isCollapsed: Bool = false,
        isDimmed: Bool = false,
        scaledSize: CGFloat = 13,
        onToggle: ((Bool) -> Void)? = nil
    ) -> DisclosureCardView {
        DisclosureCardView(
            title: title, titleIsAccent: titleIsAccent, titleAccessory: titleAccessory,
            titlebarAccessory: titlebarAccessory, subtitle: subtitle, summary: summary,
            status: status, isCollapsed: isCollapsed, isDimmed: isDimmed,
            scaledSize: scaledSize, onToggle: onToggle
        )
    }

    private func descendants(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }

    private func surface(of card: DisclosureCardView) throws -> NSView {
        try XCTUnwrap(card.subviews.first)
    }

    private func disclosure(of card: DisclosureCardView) throws -> NSButton {
        try XCTUnwrap(descendants(of: card).compactMap { $0 as? NSButton }.first { $0.bezelStyle == .disclosure })
    }

    private func titleLine(of card: DisclosureCardView, title: String = "mike@example.com") throws -> NSStackView {
        try XCTUnwrap(field(title, in: card)?.superview as? NSStackView)
    }

    private func trailingLine(of card: DisclosureCardView) throws -> NSStackView {
        try XCTUnwrap(try disclosure(of: card).superview as? NSStackView)
    }

    private func summaryField(of card: DisclosureCardView) throws -> NSTextField {
        try XCTUnwrap(descendants(of: card).compactMap { $0 as? NSTextField }.first {
            $0.alignment == .right && $0.lineBreakMode == .byClipping
        })
    }

    private func subtitleField(of card: DisclosureCardView) throws -> NSTextField {
        try XCTUnwrap(descendants(of: card).compactMap { $0 as? NSTextField }.first {
            $0.lineBreakMode == .byTruncatingTail && !($0 is WholePointLabel)
        })
    }

    /// The stack the card's content is added to, and the body stack that holds it.
    private func contentStack(holding view: NSView) throws -> NSStackView {
        try XCTUnwrap(view.superview as? NSStackView)
    }

    private func bodyStack(holding view: NSView) throws -> NSStackView {
        try XCTUnwrap(try contentStack(holding: view).superview as? NSStackView)
    }

    private func swatch(width: CGFloat = 40, height: CGFloat = 20) -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    private func floorConstraint(of card: DisclosureCardView) throws -> NSLayoutConstraint {
        try XCTUnwrap(card.constraints.first {
            $0.firstItem === card && $0.firstAttribute == .width && $0.relation == .greaterThanOrEqual
                && $0.priority.rawValue == 999
        })
    }

    private func stackConstraint(_ attribute: NSLayoutConstraint.Attribute, in card: DisclosureCardView) throws
        -> NSLayoutConstraint {
        try XCTUnwrap(card.constraints.first {
            $0.firstItem is NSStackView && $0.secondItem === card && $0.firstAttribute == attribute
        })
    }

    private func scaled(_ inset: CGFloat, _ size: CGFloat) -> CGFloat {
        ceil(inset * size / CGFloat(NSFont.systemFontSize))
    }

    func testDisclosureCard001_surfaceIsARoundedBorderedCard() throws {
        let card = makeCard()
        let layer = try XCTUnwrap(try surface(of: card).layer)
        XCTAssertEqual(layer.cornerRadius, 10)
        XCTAssertEqual(layer.borderWidth, 1)
        XCTAssertEqual(layer.backgroundColor, palette.surfaceColor.cgColor)
        XCTAssertEqual(layer.borderColor, palette.outlineColor.cgColor)
    }

    func testDisclosureCard002_surfaceClipsTheTitlebarToTheCardCorners() throws {
        XCTAssertEqual(try surface(of: makeCard()).layer?.masksToBounds, true)
    }

    func testDisclosureCard003_titlebarIsAnElevatedStrip() throws {
        let bar = try XCTUnwrap(titlebar(of: makeCard()))
        XCTAssertEqual(bar.layer?.backgroundColor, palette.elevatedSurfaceColor.cgColor)
    }

    func testDisclosureCard004_titlebarRuleIsADividerAcrossTheBar() throws {
        let card = makeCard()
        host(card, width: 400)
        let bar = try XCTUnwrap(titlebar(of: card))
        let rule = try XCTUnwrap(bar.subviews.first)
        XCTAssertEqual(rule.layer?.backgroundColor, palette.dividerColor.cgColor)
        XCTAssertEqual(rule.frame.height, 1, accuracy: 0.01)
        XCTAssertEqual(rule.frame.width, bar.frame.width, accuracy: 0.5)
        // A size constraint names one view, so AppKit installs it on that view.
        XCTAssertTrue(rule.constraints.contains { $0.firstItem === rule && $0.firstAttribute == .height
            && $0.constant == 1 })
    }

    func testDisclosureCard005_titlebarIsTheHeaderPlusItsInsets() throws {
        let card = makeCard()
        host(card, width: 400)
        let bar = try XCTUnwrap(titlebar(of: card))
        let header = try XCTUnwrap(try titleLine(of: card).superview)
        // The bar starts at the card's top and ends `padTitleY` under the header,
        // and the header itself starts `padTitleY` under the top: two insets.
        XCTAssertEqual(bar.frame.height, header.frame.height + 2 * scaled(6, 13), accuracy: 0.5)
    }

    func testDisclosureCard006_badgeIsDrawnAboveTheSurfaceBorder() throws {
        let card = makeCard(status: .init(symbolName: "exclamationmark.triangle.fill", colorName: "yellow",
                                          accessibilityLabel: "Warning"))
        let surface = try surface(of: card)
        let badge = try XCTUnwrap(card.subviews.compactMap { $0 as? NSImageView }.first)
        let surfaceIndex = try XCTUnwrap(card.subviews.firstIndex(of: surface))
        let badgeIndex = try XCTUnwrap(card.subviews.firstIndex(of: badge))
        XCTAssertGreaterThan(badgeIndex, surfaceIndex)
        // The border belongs to the surface's layer, which the badge is not inside,
        // so nothing the surface draws lands on top of the badge.
        XCTAssertEqual(card.layer?.borderWidth ?? 0, 0)
        XCTAssertFalse(badge.isDescendant(of: surface))
    }

    func testDisclosureCard007_cardDoesNotClipItsOwnContents() {
        XCTAssertFalse(makeCard().clipsToBounds)
    }

    func testDisclosureCard008_displaysTheTitleText() {
        XCTAssertNotNil(field("mike@example.com", in: makeCard(title: "mike@example.com")))
    }

    func testDisclosureCard009_truncatesTheTitleInTheMiddle() throws {
        let title = try XCTUnwrap(field("mike@example.com", in: makeCard()))
        XCTAssertEqual(title.lineBreakMode, .byTruncatingMiddle)
    }

    func testDisclosureCard010_theTitleYieldsFirstAndTheTrailingRowHolds() throws {
        let card = makeCard()
        let title = try XCTUnwrap(field("mike@example.com", in: card))
        let line = try titleLine(of: card)
        let trailing = try trailingLine(of: card)
        for view in [title, line] {
            XCTAssertEqual(view.contentCompressionResistancePriority(for: .horizontal), .defaultLow)
            XCTAssertEqual(view.contentHuggingPriority(for: .horizontal), .defaultLow)
        }
        XCTAssertEqual(trailing.contentCompressionResistancePriority(for: .horizontal), .required)
        XCTAssertEqual(trailing.contentHuggingPriority(for: .horizontal), .required)
    }

    func testDisclosureCard011_titleColorFollowsTheAccentFlag() throws {
        let accent = makeCard(titleIsAccent: true)
        let plain = makeCard(titleIsAccent: false)
        XCTAssertEqual(field("mike@example.com", in: accent)?.textColor, palette.accentColor)
        XCTAssertEqual(field("mike@example.com", in: plain)?.textColor, palette.primaryTextColor)
    }

    func testDisclosureCard012_titleFontIsSemiboldBody() throws {
        let card = makeCard(scaledSize: 16)
        var style = palette.theme.typography.style(.body)
        style.weight = .semibold
        XCTAssertEqual(field("mike@example.com", in: card)?.font, style.nsFont(scaledSize: 16))
    }

    func testDisclosureCard013_titleAccessoryLeadsTheTitle() throws {
        let accessory = NSImageView()
        let card = makeCard(titleAccessory: accessory)
        let title = try XCTUnwrap(field("mike@example.com", in: card))
        let line = try titleLine(of: card)
        XCTAssertEqual(line.arrangedSubviews, [accessory, title])
        XCTAssertEqual(line.spacing, 6)
        XCTAssertEqual(accessory.contentCompressionResistancePriority(for: .horizontal), .required)
    }

    func testDisclosureCard014_titlebarAccessorySitsBeforeTheDisclosure() throws {
        let accessory = NSImageView()
        let card = makeCard(titlebarAccessory: accessory)
        let line = try trailingLine(of: card)
        XCTAssertEqual(line.arrangedSubviews, [accessory, try disclosure(of: card)])
        XCTAssertEqual(line.spacing, 6)
    }

    func testDisclosureCard015_trailingLineNeverShrinksOrGrows() throws {
        let line = try trailingLine(of: makeCard())
        XCTAssertEqual(line.contentCompressionResistancePriority(for: .horizontal), .required)
        XCTAssertEqual(line.contentHuggingPriority(for: .horizontal), .required)
    }

    func testDisclosureCard016_keepsTheMinimumGapBetweenTitleAndTrailingRows() throws {
        try XCTSkipUnless(NSFont.systemFontSize == 13, "the vector assumes a 13pt system font")
        let card = makeCard(title: Self.longAddress, summary: Self.readings, isCollapsed: true, scaledSize: 16)
        card.addContent(swatch())
        card.translatesAutoresizingMaskIntoConstraints = false
        let hosting = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 200))
        hosting.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: hosting.leadingAnchor),
            card.topAnchor.constraint(equalTo: hosting.topAnchor),
            card.widthAnchor.constraint(equalToConstant: 260)
        ])
        hosting.layoutSubtreeIfNeeded()
        let title = try titleLine(of: card, title: Self.longAddress)
        let trailing = try trailingLine(of: card)
        XCTAssertEqual(DisclosureCardView.mastheadGapFor(scaledSize: 16), 30)
        XCTAssertGreaterThanOrEqual(trailing.frame.minX - title.frame.maxX, 30 - 0.5)
        XCTAssertEqual(title.frame.midY, trailing.frame.midY, accuracy: 0.5)
    }

    func testDisclosureCard017_usesTheNativeDisclosureControl() throws {
        let button = try disclosure(of: makeCard())
        XCTAssertEqual(button.bezelStyle, .disclosure)
    }

    func testDisclosureCard018_disclosureStartsInTheCardsFoldState() throws {
        XCTAssertEqual(try disclosure(of: makeCard(isCollapsed: true)).state, .off)
        XCTAssertEqual(try disclosure(of: makeCard(isCollapsed: false)).state, .on)
    }

    func testDisclosureCard019_disclosureIsLabelledForItsAction() throws {
        let folded = try disclosure(of: makeCard(isCollapsed: true))
        let open = try disclosure(of: makeCard(isCollapsed: false))
        XCTAssertEqual(folded.toolTip, "Show details")
        XCTAssertEqual(folded.accessibilityLabel(), "Show details")
        XCTAssertEqual(open.toolTip, "Hide details")
        XCTAssertEqual(open.accessibilityLabel(), "Hide details")
    }

    func testDisclosureCard020_activatingTheDisclosureForwardsTheNewFoldState() throws {
        var received: [Bool] = []
        let card = makeCard(isCollapsed: false, onToggle: { received.append($0) })
        let button = try disclosure(of: card)
        button.performClick(nil)
        XCTAssertEqual(received, [true])
        XCTAssertEqual(button.state, .off)
    }

    func testDisclosureCard021_theCardDoesNotMutateItselfOnToggle() throws {
        let card = makeCard(subtitle: "note", summary: Self.readings, isCollapsed: false)
        let view = swatch()
        card.addContent(view)
        let content = try contentStack(holding: view)
        let body = try bodyStack(holding: view)
        let subtitle = try subtitleField(of: card)
        let button = try disclosure(of: card)
        let before = (content.isHidden, body.isHidden, subtitle.isHidden, button.toolTip)
        button.performClick(nil)
        XCTAssertEqual(content.isHidden, before.0)
        XCTAssertEqual(body.isHidden, before.1)
        XCTAssertEqual(subtitle.isHidden, before.2)
        XCTAssertEqual(button.toolTip, before.3)
    }

    func testDisclosureCard022_contentIsHiddenWhenCollapsed() throws {
        for collapsed in [true, false] {
            let card = makeCard(isCollapsed: collapsed)
            let view = swatch()
            card.addContent(view)
            XCTAssertEqual(try contentStack(holding: view).isHidden, collapsed)
        }
    }

    func testDisclosureCard023_contentIsBuiltEvenWhileFolded() throws {
        let card = makeCard(isCollapsed: true)
        let view = swatch()
        card.addContent(view)
        let content = try contentStack(holding: view)
        XCTAssertTrue(content.arrangedSubviews.contains(view))
        XCTAssertTrue(content.isHidden)
    }

    func testDisclosureCard024_subtitleIsHiddenWhenCollapsed() throws {
        XCTAssertTrue(try subtitleField(of: makeCard(subtitle: "note", isCollapsed: true)).isHidden)
    }

    func testDisclosureCard025_subtitleIsHiddenWhenAbsent() throws {
        XCTAssertTrue(try subtitleField(of: makeCard(subtitle: nil, isCollapsed: false)).isHidden)
    }

    func testDisclosureCard026_anEmptyBodyIsDetached() throws {
        let card = makeCard(subtitle: nil, summary: [], isCollapsed: true)
        let view = swatch()
        card.addContent(view)
        XCTAssertTrue(try bodyStack(holding: view).isHidden)
    }

    func testDisclosureCard027_bottomInsetMatchesAnEmptyBody() throws {
        let empty = makeCard(subtitle: nil, summary: [], isCollapsed: true)
        XCTAssertEqual(try stackConstraint(.bottom, in: empty).constant, -scaled(6, 13))
        let full = makeCard(subtitle: nil, summary: Self.readings, isCollapsed: true)
        XCTAssertEqual(try stackConstraint(.bottom, in: full).constant, -scaled(12, 13))
    }

    func testDisclosureCard028_summaryShowsOnlyWhenCollapsedAndPresent() throws {
        for collapsed in [true, false] {
            for present in [true, false] {
                let card = makeCard(summary: present ? Self.readings : [], isCollapsed: collapsed)
                XCTAssertEqual(try summaryField(of: card).isHidden, !(collapsed && present),
                               "collapsed \(collapsed), summary present \(present)")
            }
        }
    }

    func testDisclosureCard029_summaryIsRightAlignedAndClips() throws {
        let field = try summaryField(of: makeCard(summary: Self.readings, isCollapsed: true))
        XCTAssertEqual(field.alignment, .right)
        XCTAssertEqual(field.lineBreakMode, .byClipping)
        XCTAssertEqual(field.contentCompressionResistancePriority(for: .horizontal), .required)
    }

    func testDisclosureCard030_summaryPartsAreStyledNameThenValue() throws {
        let card = makeCard(summary: [.init(name: "5H", value: "23%", colorName: "red")], isCollapsed: true)
        let text = try summaryField(of: card).attributedStringValue
        XCTAssertEqual(text.string, "5H: 23%")
        let typography = palette.theme.typography
        let nameAttributes = text.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(nameAttributes[.font] as? NSFont, typography.style(.caption).nsFont(scaledSize: 13 * 0.85))
        XCTAssertEqual(nameAttributes[.foregroundColor] as? NSColor, palette.tertiaryTextColor)
        let valueAttributes = text.attributes(at: 4, effectiveRange: nil)
        XCTAssertEqual(valueAttributes[.font] as? NSFont, typography.style(.code).nsFont(scaledSize: 13 * 0.85))
        XCTAssertEqual(valueAttributes[.foregroundColor] as? NSColor, palette.dangerColor)
    }

    func testDisclosureCard031_summaryPartsAreSeparatedByOneRun() throws {
        let card = makeCard(summary: Self.readings, isCollapsed: true)
        let text = try summaryField(of: card).attributedStringValue
        XCTAssertEqual(text.string, "5H: 23%  |  7D: 12%")
        XCTAssertEqual(text.string.components(separatedBy: "  |  ").count, 2)
        let range = (text.string as NSString).range(of: "  |  ")
        let attributes = text.attributes(at: range.location, effectiveRange: nil)
        XCTAssertEqual(attributes[.foregroundColor] as? NSColor, palette.tertiaryTextColor)
        XCTAssertEqual(attributes[.font] as? NSFont,
                       palette.theme.typography.style(.caption).nsFont(scaledSize: 13 * 0.85))
    }

    private static let warning = DisclosureCardView.StatusSymbol(
        symbolName: "exclamationmark.triangle.fill", colorName: "yellow", accessibilityLabel: "Warning"
    )

    private func badgeView(of card: DisclosureCardView) throws -> NSImageView {
        try XCTUnwrap(card.subviews.compactMap { $0 as? NSImageView }.first)
    }

    func testDisclosureCard032_statusBadgeIsHiddenWhenAbsent() throws {
        XCTAssertTrue(try badgeView(of: makeCard(status: nil)).isHidden)
    }

    func testDisclosureCard033_statusIsASemiboldSymbolIcon() throws {
        let card = makeCard(status: Self.warning)
        let badge = try badgeView(of: card)
        let named = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)
        XCTAssertNotNil(named)
        XCTAssertEqual(badge.image?.tiffRepresentation, named?.tiffRepresentation)
        let diameter = DisclosureCardView.cornerBadgeDiameter(scaledSize: 13)
        XCTAssertEqual(badge.symbolConfiguration, NSImage.SymbolConfiguration(pointSize: diameter, weight: .semibold))
    }

    func testDisclosureCard034_statusIsItsOwnAccessibilityElement() throws {
        let badge = try badgeView(of: makeCard(status: Self.warning))
        XCTAssertTrue(badge.isAccessibilityElement())
        XCTAssertEqual(badge.accessibilityRole(), .image)
        XCTAssertEqual(badge.accessibilityLabel(), "Warning")
        XCTAssertEqual(badge.toolTip, "Warning")
    }

    func testDisclosureCard035_statusTintComesFromThePalette() throws {
        let plain = DisclosureCardView.StatusSymbol(symbolName: "circle.fill", colorName: nil, accessibilityLabel: "x")
        let blue = DisclosureCardView.StatusSymbol(symbolName: "circle.fill", colorName: "blue",
                                                   accessibilityLabel: "x")
        XCTAssertEqual(try badgeView(of: makeCard(status: plain)).contentTintColor, palette.secondaryTextColor)
        XCTAssertEqual(try badgeView(of: makeCard(status: blue)).contentTintColor, palette.accentColor)
    }

    func testDisclosureCard036_badgeSitsOnTheVisibleCorner() throws {
        let card = makeCard(status: Self.warning)
        card.addContent(swatch())
        host(card, width: 400)
        let badge = try badgeView(of: card)
        let box = badge.alignmentRect(forFrame: badge.frame)
        let peak = DisclosureCardView.cornerPeakInset
        XCTAssertEqual(peak, 10 - 10 / 2.0.squareRoot(), accuracy: 0.001)
        XCTAssertEqual(box.midX, card.bounds.maxX - peak, accuracy: 0.5)
        XCTAssertEqual(box.midY, card.bounds.maxY - peak, accuracy: 0.5)
    }

    func testDisclosureCard037_badgeDiameterIsBoundedByTheGutter() throws {
        let card = makeCard(status: Self.warning, scaledSize: 13)
        let badge = try badgeView(of: card)
        let expected = min(ceil(13 * 1.3), scaled(14, 13) * 1.5)
        XCTAssertEqual(DisclosureCardView.cornerBadgeDiameter(scaledSize: 13), expected)
        for attribute in [NSLayoutConstraint.Attribute.width, .height] {
            let size = try XCTUnwrap(badge.constraints.first {
                $0.firstItem === badge && $0.firstAttribute == attribute
            })
            XCTAssertEqual(size.constant, expected)
        }
    }

    func testDisclosureCard038_dimmingFadesTheWholeCard() {
        XCTAssertEqual(makeCard(isDimmed: true).alphaValue, 0.55, accuracy: 0.001)
        XCTAssertEqual(makeCard(isDimmed: false).alphaValue, 1.0, accuracy: 0.001)
    }

    func testDisclosureCard039_insetsScaleWithTextSize() throws {
        try XCTSkipUnless(NSFont.systemFontSize == 13, "the vector assumes a 13pt system font")
        let card = makeCard(summary: Self.readings, isCollapsed: false, scaledSize: 26)
        card.addContent(swatch())
        XCTAssertEqual(try stackConstraint(.leading, in: card).constant, 14, "padMastheadX")
        XCTAssertEqual(try stackConstraint(.trailing, in: card).constant, -28, "padX")
        XCTAssertEqual(try stackConstraint(.top, in: card).constant, 12, "padTitleY")
        XCTAssertEqual(try stackConstraint(.bottom, in: card).constant, -24, "padY")
        XCTAssertEqual(DisclosureCardView.mastheadGapFor(scaledSize: 26), 48, "mastheadGap")
    }

    func testDisclosureCard040_widthFloorIsTheSameFoldedOrOpen() throws {
        func floorConstant(collapsed: Bool) throws -> (CGFloat, CGFloat) {
            let card = makeCard(summary: Self.readings, isCollapsed: collapsed)
            let wide = swatch(width: 600, height: 60)
            card.addContent(wide)
            host(card, width: 700)
            let content = try contentStack(holding: wide)
            return (try floorConstraint(of: card).constant, ceil(content.fittingSize.width))
        }
        let folded = try floorConstant(collapsed: true)
        let open = try floorConstant(collapsed: false)
        XCTAssertEqual(folded.0, open.0, accuracy: 0.5)
        // Content is the wider row here, so the floor is it plus both gutters.
        XCTAssertEqual(open.0, open.1 + scaled(7, 13) + scaled(14, 13), accuracy: 0.5)
    }

    func testDisclosureCard040b_aWiderMastheadSetsTheFloorInsteadOfTheContent() throws {
        let card = makeCard(title: Self.longAddress, summary: Self.readings, isCollapsed: false)
        card.addContent(swatch())
        host(card, width: 700)
        let title = try titleLine(of: card, title: Self.longAddress)
        let trailing = try trailingLine(of: card)
        let titleRow = ceil(title.fittingSize.width) + DisclosureCardView.mastheadGapFor(scaledSize: 13)
            + ceil(trailing.fittingSize.width)
        XCTAssertEqual(try floorConstraint(of: card).constant, titleRow + scaled(7, 13) + scaled(14, 13),
                       accuracy: 0.5)
    }

    func testDisclosureCard041_widthFloorSitsJustUnderRequired() throws {
        XCTAssertEqual(try floorConstraint(of: makeCard()).priority.rawValue, 999)
    }

    func testDisclosureCard042_widthFloorIsRemeasuredOnLayout() throws {
        let card = makeCard(isCollapsed: true)
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        let width = content.widthAnchor.constraint(equalToConstant: 300)
        width.isActive = true
        content.heightAnchor.constraint(equalToConstant: 20).isActive = true
        card.addContent(content)
        let hosting = host(card, width: 700)
        let before = try floorConstraint(of: card).constant

        width.constant = 900
        card.needsLayout = true
        hosting.layoutSubtreeIfNeeded()
        let stack = try contentStack(holding: content)
        let after = try floorConstraint(of: card).constant
        XCTAssertGreaterThan(after, before)
        XCTAssertEqual(after, ceil(stack.fittingSize.width) + scaled(7, 13) + scaled(14, 13), accuracy: 0.5)

        card.needsLayout = true
        hosting.layoutSubtreeIfNeeded()
        XCTAssertEqual(try floorConstraint(of: card).constant, after, accuracy: 0.5)
    }

    func testDisclosureCard043_themeIsAppliedAtConstructionAndOnChange() throws {
        let manager = ThemeManager(storage: DisclosureCardThemeStorage(), appearanceDriver: nil)
        let card = makeCard()
        let layer = try XCTUnwrap(try surface(of: card).layer)
        let first = manager.currentPalette.surfaceColor.cgColor
        XCTAssertEqual(layer.backgroundColor, first)

        manager.selectTheme(id: BuiltInThemes.nord.id)

        let second = manager.currentPalette.surfaceColor.cgColor
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(layer.backgroundColor, second)
        withExtendedLifetime(manager) {}
    }

    func testDisclosureCard046_contentSpacingIsExposedAndRemeasured() throws {
        let card = makeCard(isCollapsed: false)
        let view = swatch(width: 300, height: 20)
        card.addContent(view)
        card.addContent(swatch(width: 300, height: 20))
        card.contentSpacing = 20
        let content = try contentStack(holding: view)
        XCTAssertEqual(content.spacing, 20)
        XCTAssertEqual(card.contentSpacing, 20)
        XCTAssertEqual(try floorConstraint(of: card).constant,
                       max(ceil(content.fittingSize.width), 0) + scaled(7, 13) + scaled(14, 13), accuracy: 0.5)
    }

    func testDisclosureCard051_confinementToTheUIThread() throws {
        throw XCTSkip("DisclosureCardView is @MainActor, so off-thread use is rejected at build time; "
            + "no test can express it")
    }
}
