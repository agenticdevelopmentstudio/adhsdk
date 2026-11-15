// Tests/AgenticDeveloperHubSDKMacOSTests/ConversationsWindow/ConversationFocusOverlayConformanceTests.swift
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The conversation-focus-overlay recipe's vectors, driven against the overlay
/// built directly rather than through the Conversations feed that opens it.
/// `Chat/ConversationFocusTests` covers the same component from the feed's
/// side; the vectors it has no test for are here.
@MainActor
final class ConversationFocusOverlayConformanceTests: XCTestCase {

    private final class CallCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0
        func bump() { lock.lock(); count += 1; lock.unlock() }
        var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    }

    private var windows: [NSWindow] = []
    private var overlays: [ConversationFocusOverlay] = []

    override func tearDown() async throws {
        overlays.forEach { $0.removeFromSuperview() }
        overlays.removeAll()
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        try await super.tearDown()
    }

    // MARK: - Fixtures

    private func message(_ identifier: String, _ text: String, role: ChatMessage.Role = .assistant) -> ChatMessage {
        ChatMessage(id: identifier, role: role, text: text)
    }

    private func host() -> NSView {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 640),
            styleMask: [.titled], backing: .buffered, defer: false)
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 640))
        window.contentView = content
        windows.append(window)
        return content
    }

    /// A read that never comes back, so only the seed is ever on screen.
    private static let neverLands: FeedChatSession.Loader = {
        try? await Task.sleep(for: .seconds(3600))
        return nil
    }

    private func presented(
        in container: NSView? = nil,
        interval: Duration = .seconds(3600),
        load: @escaping FeedChatSession.Loader = ConversationFocusOverlayConformanceTests.neverLands,
        seed: [ChatMessage] = [],
        lineLimit: Int? = nil,
        send: FeedChatSession.Sender? = nil
    ) -> ConversationFocusOverlay {
        let overlay = ConversationFocusOverlay(
            refreshInterval: interval, load: load, seed: seed, lineLimit: lineLimit, send: send)
        overlay.present(in: container ?? host())
        overlays.append(overlay)
        return overlay
    }

    private func chat(of overlay: ConversationFocusOverlay) throws -> ChatView {
        try XCTUnwrap(overlay.subviews.compactMap { $0 as? ChatView }.first, "the overlay has no chat")
    }

    private func descendants(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }

    /// The bubbles in transcript order: row by row down the transcript's stack.
    /// A plain walk of the view tree is breadth-first, and a user's row nests its
    /// bubble at a different depth from an assistant's, so it would not be.
    private func bubbles(in overlay: ConversationFocusOverlay) -> [AIChatBubbleView] {
        guard let chatView = overlay.subviews.compactMap({ $0 as? ChatView }).first,
              let scroll = chatView.subviews.compactMap({ $0 as? NSScrollView }).first,
              let stack = scroll.documentView as? NSStackView else { return [] }
        return stack.arrangedSubviews.flatMap { row in
            ([row] + descendants(of: row)).compactMap { $0 as? AIChatBubbleView }
        }
    }

    /// Each bubble's message text. The bubble's text view also carries the
    /// inline timestamp it trails the message with (`"  9:41 AM"`), which is
    /// not part of what was said, so it is cut off here.
    private func rowTexts(in overlay: ConversationFocusOverlay) -> [String] {
        bubbles(in: overlay).compactMap { bubble in
            bubble.subviews.compactMap { ($0 as? NSTextView)?.string }.first.map { text in
                guard let stamp = text.range(of: #"  \d{1,2}:\d{2}\s?\S*$"#, options: .regularExpression)
                else { return text }
                return String(text[..<stamp.lowerBound])
            }
        }
    }

    private func key(code: UInt16) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: windows.last?.windowNumber ?? 0, context: nil,
            characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: code)!
    }

    private func press(in view: NSView) -> NSEvent {
        NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: view.convert(NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil),
            modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: view.window?.windowNumber ?? 0, context: nil,
            eventNumber: 0, clickCount: 1, pressure: 1)!
    }

    private func waitUntil(
        _ what: String, file: StaticString = #filePath, line: UInt = #line, _ condition: () -> Bool
    ) async throws {
        for _ in 0..<300 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
            windows.forEach { $0.contentView?.layoutSubtreeIfNeeded() }
        }
        XCTFail("timed out waiting until \(what)", file: file, line: line)
    }

    private func composerParts(
        of overlay: ConversationFocusOverlay
    ) throws -> (field: NSTextField, send: NSButton) {
        let views = descendants(of: try chat(of: overlay))
        let field = try XCTUnwrap(views.compactMap { $0 as? NSTextField }
            .first { $0.accessibilityIdentifier() == "ai-chat.input" })
        let send = try XCTUnwrap(views.compactMap { $0 as? NSButton }
            .first { $0.accessibilityIdentifier() == "ai-chat.send-button" })
        return (field, send)
    }

    // MARK: - Reading

    func testV001_theOverlayShowsOnlyWhatItsLoaderReturns() async throws {
        let seed = [message("seed", "from the feed underneath")]
        let overlay = presented(
            load: { [ChatMessage(id: "a", role: .user, text: "s1 first"),
                     ChatMessage(id: "b", role: .assistant, text: "s1 second")] },
            seed: seed)

        try await waitUntil("the loader's rows replaced the seed") {
            self.rowTexts(in: overlay) == ["s1 first", "s1 second"]
        }
    }

    func testV002_seedRowsAreShownBeforeAnyReadCompletes() throws {
        let overlay = presented(seed: [message("a", "first seeded"), message("b", "second seeded")])

        XCTAssertEqual(rowTexts(in: overlay), ["first seeded", "second seeded"],
                       "the overlay faded in empty and filled itself afterwards")
    }

    func testV003_aLineSentBeforeTheFirstReadKeepsTheSeedRows() async throws {
        let reads = CallCounter()
        let overlay = presented(
            // Nothing readable yet: the seed is all the session has.
            load: { reads.bump(); return nil },
            seed: [message("a", "rebased and pushed"), message("b", "thanks", role: .user)],
            send: { _, _ in nil })
        let composer = try composerParts(of: overlay)
        // The read having been attempted is how the test knows the view is
        // watching; a line sent in the same turn as the overlay was built would
        // publish into a stream nobody has opened yet.
        try await waitUntil("the feed was read") { reads.value >= 1 }

        composer.field.window?.makeFirstResponder(composer.field)
        composer.field.currentEditor()?.insertText("what about the tests?")
        composer.send.performClick(nil)

        try await waitUntil("the pending line joined the transcript") {
            self.rowTexts(in: overlay).count == 3
        }
        XCTAssertEqual(rowTexts(in: overlay), ["rebased and pushed", "thanks", "what about the tests?"],
                       "typing wiped the transcript the overlay was seeded with")
    }

    // MARK: - Refreshing

    func testV004_theLoaderIsCalledOncePerInterval() async throws {
        let calls = CallCounter()
        _ = presented(interval: .milliseconds(40), load: { calls.bump(); return [] })

        try await waitUntil("the loader was called across several intervals") { calls.value >= 4 }
    }

    func testV005_refreshReadsAtOnceWithoutWaitingForTheInterval() async throws {
        let calls = CallCounter()
        let overlay = presented(interval: .seconds(3600), load: { calls.bump(); return [] })
        try await waitUntil("the first read happened") { calls.value == 1 }

        overlay.refresh()

        try await waitUntil("the refresh read at once") { calls.value == 2 }
    }

    func testV006_noReadHappensAfterDismissalBeginsOrAfterTheOverlayIsDiscarded() async throws {
        let calls = CallCounter()
        let overlay = presented(interval: .milliseconds(30), load: { calls.bump(); return [] })
        try await waitUntil("the overlay was polling") { calls.value >= 2 }

        overlay.dismiss()
        XCTAssertTrue(overlay.isDismissing)
        // A read already underway when dismissal began is allowed to land.
        try await Task.sleep(for: .milliseconds(60))
        let afterDismissal = calls.value
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(calls.value, afterDismissal, "the overlay kept reading after dismissal began")

        let discardedCalls = CallCounter()
        weak var discarded: ConversationFocusOverlay?
        do {
            let other = ConversationFocusOverlay(
                refreshInterval: .milliseconds(30), load: { discardedCalls.bump(); return [] }, lineLimit: nil)
            other.present(in: self.host())
            discarded = other
            try await self.waitUntil("the second overlay was polling") { discardedCalls.value >= 2 }
            other.removeFromSuperview()
        }
        try await waitUntil("the second overlay was released") { discarded == nil }
        try await Task.sleep(for: .milliseconds(60))
        let afterDiscard = discardedCalls.value
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(discardedCalls.value, afterDiscard, "a discarded overlay kept reading")
    }

    // MARK: - Layout and style

    func testV007_theOverlayFillsItsHostAndTheTranscriptFillsTheOverlay() throws {
        let container = host()
        let overlay = presented(in: container)

        XCTAssertEqual(overlay.frame, container.bounds)
        XCTAssertEqual(try chat(of: overlay).frame, overlay.bounds)
    }

    func testV008_theTranscriptDrawsNoBackground() throws {
        let chatView = try chat(of: presented())

        XCTAssertFalse(chatView.drawsBackground)
        let fill = chatView.layer?.backgroundColor.flatMap { NSColor(cgColor: $0) }
        XCTAssertEqual(fill?.alphaComponent ?? 0, 0, accuracy: 0.001,
                       "the transcript painted over the blur it is meant to show")
    }

    func testV009_rowsUseTheTerminalBubbleStyle() throws {
        XCTAssertEqual(try chat(of: presented()).bubbleStyle, .terminal)
    }

    func testV010_theLineLimitTruncatesAndNoLimitShowsTheMessageWhole() async throws {
        let long = (1...30).map { "line \($0)" }.joined(separator: "\n")
        // The overlay's feed names its speaker, and the limit belongs to that
        // fuller row; a bare message is drawn as a plain bubble with no limit.
        let said = ChatMessage(
            id: "long", role: .assistant, text: long,
            attribution: ChatMessage.Attribution(
                sourceID: "s", context: ["proj"], name: "a session", iconSymbol: "terminal"))
        let limited = presented(seed: [said], lineLimit: 2)
        let unlimited = presented(seed: [said], lineLimit: nil)

        XCTAssertEqual(try chat(of: limited).bubbleLineLimit, 2)
        XCTAssertNil(try chat(of: unlimited).bubbleLineLimit)
        try await waitUntil("the limited bubble truncated") {
            self.bubbles(in: limited).first?.isTruncated == true
        }
        let whole = try XCTUnwrap(bubbles(in: unlimited).first)
        XCTAssertFalse(whole.isTruncated)
        XCTAssertFalse(whole.isExpandable)
        XCTAssertEqual(rowTexts(in: unlimited), [long], "a message with no limit was not shown whole")
    }

    // MARK: - The composer

    func testV011_theComposerIsEnabledOnlyWithASendHandler() throws {
        let writable = presented(send: { _, _ in nil })
        let readOnly = presented()

        XCTAssertTrue(try chat(of: writable).isComposerEnabled)
        XCTAssertFalse(try chat(of: readOnly).isComposerEnabled)
        let parts = try composerParts(of: readOnly)
        XCTAssertFalse(parts.field.isEnabled, "the composer was removed or left live instead of greyed")
    }

    func testV012_theComposerPromptIsAGreaterThanSign() throws {
        let chatView = try chat(of: presented())

        XCTAssertEqual(chatView.composerPrompt, ">")
        let label = descendants(of: chatView).compactMap { $0 as? NSTextField }
            .first { $0.stringValue == ">" }
        XCTAssertNotNil(label, "no prompt label reads >")
        XCTAssertEqual(label?.isHidden, false)
    }

    func testV013_rowsOfAnOpenOverlayOfferNoActions() throws {
        let chatView = try chat(of: presented(seed: [message("a", "one"), message("b", "two")]))

        XCTAssertFalse(chatView.isRowSelectionEnabled)
        XCTAssertNil(chatView.rowActions.onOpen)
        XCTAssertNil(chatView.rowActions.onJump)
    }

    func testV014_presentingFocusesTheComposerOnlyWhenThereIsASender() throws {
        let writableHost = host()
        let writable = presented(in: writableHost, send: { _, _ in nil })
        XCTAssertTrue(try chat(of: writable).isComposerFocused)

        let readOnlyHost = host()
        let other = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 20))
        readOnlyHost.addSubview(other)
        other.window?.makeFirstResponder(other)
        let readOnly = presented(in: readOnlyHost)
        XCTAssertFalse(try chat(of: readOnly).isComposerFocused)
        XCTAssertTrue(other.window?.firstResponder === other.currentEditor() || other.window?.firstResponder === other,
                      "presenting an overlay with no composer took the focus away")
    }

    // MARK: - Keys and presses

    func testV015_returnAndEnterBelongToAFocusedComposer() throws {
        let overlay = presented(send: { _, _ in nil })
        XCTAssertTrue(try chat(of: overlay).isComposerFocused)

        XCTAssertFalse(overlay.performKeyEquivalent(with: key(code: 36)))
        XCTAssertFalse(overlay.performKeyEquivalent(with: key(code: 76)))
        XCTAssertFalse(overlay.isDismissing, "Return dismissed an overlay whose composer had the focus")
    }

    func testV016_escapeDismissesEvenWithTheComposerFocused() throws {
        let overlay = presented(send: { _, _ in nil })
        XCTAssertTrue(try chat(of: overlay).isComposerFocused)

        XCTAssertTrue(overlay.performKeyEquivalent(with: key(code: 53)))
        XCTAssertTrue(overlay.isDismissing)
    }

    func testV017_dismissalGesturesWithTheComposerUnfocused() throws {
        for code: UInt16 in [53, 36, 76] {
            let overlay = presented()
            XCTAssertTrue(overlay.performKeyEquivalent(with: key(code: code)), "key \(code) was not handled")
            XCTAssertTrue(overlay.isDismissing, "key \(code) did not dismiss")
        }

        let arrow = presented()
        XCTAssertFalse(arrow.performKeyEquivalent(with: key(code: 125)))
        XCTAssertFalse(arrow.isDismissing)

        let unclaimed = presented()
        unclaimed.mouseDown(with: press(in: unclaimed))
        XCTAssertTrue(unclaimed.isDismissing)

        let claimed = presented(seed: [message("a", "a line to press")])
        let bubble = try XCTUnwrap(bubbles(in: claimed).first)
        bubble.mouseDown(with: press(in: bubble))
        XCTAssertFalse(claimed.isDismissing, "a press a bubble claimed still dismissed the overlay")
    }

    // MARK: - Identity and threading

    func testV018_theOverlayExposesItsAccessibilityIdentifier() {
        XCTAssertEqual(presented().accessibilityIdentifier(), "conversation-focus.overlay")
    }

    func testV019_confinesToTheUIThread() throws {
        throw XCTSkip("""
            The overlay is @MainActor, so a use from another thread is rejected at build time; \
            there is no runtime behavior a test could observe.
            """)
    }
}
