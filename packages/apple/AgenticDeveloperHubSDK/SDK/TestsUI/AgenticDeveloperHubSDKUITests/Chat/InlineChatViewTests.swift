import Testing
import AppKit
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
@Suite("InlineChatView")
struct InlineChatViewTests {

    private func makeManager(activeThemeID: String) -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: activeThemeID))
    }

    private func makeView(localParticipantID: String = "user-1") -> (InlineChatView, ObservableChatViewModel, FakeBackend) {
        let backend = FakeBackend()
        let viewModel = ObservableChatViewModel(backend: backend, localParticipantID: localParticipantID)
        let view = InlineChatView(viewModel: viewModel, localParticipantID: localParticipantID)
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 500)
        view.layoutSubtreeIfNeeded()
        return (view, viewModel, backend)
    }

    private func transcriptStack(of view: InlineChatView) -> NSStackView? {
        guard let scrollView = view.subviews.compactMap({ $0 as? NSScrollView }).first else { return nil }
        return scrollView.documentView as? NSStackView
    }

    @Test("constructs with an empty transcript and a scroll view hosting it")
    func constructsEmpty() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        let stack = transcriptStack(of: view)
        #expect(stack != nil)
        #expect(stack?.arrangedSubviews.isEmpty == true)
    }

    @Test("adds itself as an observer, so a new message rebuilds the transcript with a bubble")
    func rebuildsOnMessagesChanged() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, viewModel, _) = makeView()
        let stack = transcriptStack(of: view)

        viewModel.handle(.messageReceived(FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "hi there", timestamp: Date())))

        #expect(stack?.arrangedSubviews.count == 1)
        #expect(stack?.arrangedSubviews.first is MessageBubbleView)
    }

    /// The indicator is a permanent fixture of the status row above the
    /// composer, not a transcript entry that appears and disappears.
    ///
    /// It used to be appended to the transcript stack and thrown away on the
    /// next rebuild — which is why the phase machine never advanced past its
    /// first frame, and why nobody ever saw a word change from "fleeping…" to
    /// "flooping…". One long-lived view keeps the phase, the shuffle bag and
    /// the frame timer alive across every update; typing just drives it.
    @Test("typing drives the persistent status line, not a transcript entry")
    func typingDrivesThePersistentStatusLine() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, viewModel, _) = makeView()

        var configuration = ThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "fleeping", past: "fleeped")]
        view.thinkingIndicator.configure(configuration)

        #expect(view.thinkingIndicator.superview != nil)
        #expect(view.thinkingIndicator.currentPhase == .idle)

        viewModel.handle(.typing(participantID: "persona-1", isTyping: true))
        #expect(view.thinkingIndicator.currentPhase == .thinking)
        #expect(view.thinkingIndicator.label.stringValue.contains("fleeping"))
        // Never in the transcript: a status line that scrolled away with the
        // messages would be gone the moment the reply it describes arrives.
        #expect(transcriptStack(of: view)?.arrangedSubviews.contains { $0 is ThinkingIndicatorView } == false)

        viewModel.handle(.typing(participantID: "persona-1", isTyping: false))
        #expect(view.thinkingIndicator.currentPhase == .done)
        #expect(view.thinkingIndicator.label.stringValue.contains("fleeped"))
    }

    @Test("renders an in-progress draft as a bubble")
    func rendersActiveDraftAsBubble() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, viewModel, _) = makeView()
        let stack = transcriptStack(of: view)

        viewModel.handle(.draftUpdated(participantID: "persona-1", text: "Hel", attachments: []))
        #expect(stack?.arrangedSubviews.count == 1)

        // The replace-not-append invariant should also hold end-to-end
        // through the bound view: a second update still renders one bubble.
        viewModel.handle(.draftUpdated(participantID: "persona-1", text: "Hello", attachments: []))
        #expect(stack?.arrangedSubviews.count == 1)
    }

    @Test("an invoked command adds a pill, and its result updates that same pill in place")
    func rendersCommandActivityAsPill() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let (view, viewModel, _) = makeView()
        let stack = transcriptStack(of: view)
        let invocation = FixtureCommandInvocation(id: "inv-1", commandName: "grep", invokerID: "persona-1")

        viewModel.handle(.commandInvoked(participantID: "persona-1", invocation: invocation))
        let pills = { stack?.arrangedSubviews.compactMap { $0 as? ToolCallPillView } ?? [] }
        #expect(pills().count == 1)
        #expect(pills().first?.titleColor == palette.nsColor(.info))

        viewModel.handle(.commandCompleted(
            participantID: "persona-1",
            result: FixtureCommandResult(invocationID: "inv-1", ok: true)))
        #expect(pills().count == 1)
        #expect(pills().first?.titleColor == palette.nsColor(.success))
    }

    @Test("a deallocated view stops observing — a further update does not crash")
    func deallocatedViewStopsObserving() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let backend = FakeBackend()
        let viewModel = ObservableChatViewModel(backend: backend, localParticipantID: "user-1")
        do {
            let view = InlineChatView(viewModel: viewModel, localParticipantID: "user-1")
            view.frame = NSRect(x: 0, y: 0, width: 400, height: 500)
            view.layoutSubtreeIfNeeded()
        }
        // `view` has deallocated without unregistering itself: `deinit` is
        // nonisolated and cannot call the `@MainActor` `removeObserver`. The
        // weak observer table is what makes that safe, so this is the test
        // that the table really is weak -- a strong one would either keep the
        // view alive or leave a dangling entry for `notify` to message.
        viewModel.handle(.messageReceived(FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "hi", timestamp: Date())))
    }

    // MARK: Chrome

    /// The composer is where a theme's terminal-ness is most visible and where
    /// the port had been least faithful: web's `.pc-input` sets
    /// `border: none`, draws a `❯` as the input row's `::before`, and replaces
    /// the native caret with a blinking phosphor block. None of that is a
    /// colour, so all of it lives on `chrome`.
    @Test("terminal chrome unboxes the composer and gives it a prompt")
    func terminalChromeShapesTheComposer() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()

        // The default is the boxed, rounded, prompt-less composer every
        // non-terminal theme wants — asserted so the terminal case below is
        // read as a change and not as the only behaviour.
        #expect(view.inputField.showsBorder)
        #expect(!view.inputField.usesBlockCaret)
        #expect(view.promptLabel.isHidden)

        view.chrome = .terminal
        #expect(!view.inputField.showsBorder)
        #expect(view.inputField.layer?.borderWidth == 0)
        #expect(view.inputField.usesBlockCaret)
        #expect(!view.promptLabel.isHidden)
        #expect(view.promptLabel.stringValue == "\u{276F}")
        #expect(view.inputField.cornerRadius == 0)
    }

    /// `blinksCaret` is the reader's switch, not the theme's, so it has to
    /// survive the thing that carries the theme's opinion. A host writes it
    /// once at launch from a saved default and then whenever someone flips it;
    /// if applying chrome reset it, restoring a window would quietly turn
    /// blinking back on.
    @Test("blinksCaret reaches the composer and is not undone by chrome")
    func blinksCaretReachesTheField() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        #expect(view.blinksCaret)
        #expect(view.inputField.caretBlinks)

        view.blinksCaret = false
        #expect(!view.inputField.caretBlinks)

        view.chrome = .terminal
        #expect(!view.inputField.caretBlinks)

        view.blinksCaret = true
        #expect(view.inputField.caretBlinks)
    }

    // MARK: The prompt's height

    /// Distance from the top of `view` down to `field`'s text baseline, so the
    /// two composer runs can be compared in one coordinate space whichever way
    /// up AppKit is drawing.
    private func baselineDepth(of field: NSTextField, in view: NSView) -> CGFloat {
        let box = field.convert(field.bounds, to: view)
        let top = view.isFlipped ? box.minY : view.bounds.maxY - box.maxY
        return top + field.firstBaselineOffsetFromTop
    }

    /// The operator's report, as an assertion: "the > is still not vertically
    /// aligned with the center point of the entry text". A shared baseline is
    /// not enough, because the composer's face has no `\u{276F}` and the
    /// substituted one has its own metrics.
    /// How far the prompt's ink centre sits from the middle of the typed line,
    /// in points, positive meaning too low. Zero is aligned.
    private func centeringError(in view: InlineChatView, font: NSFont) throws -> CGFloat {
        let glyph = try #require(InlineChatChrome.terminal.promptGlyph)
        let inkCenter = try #require(
            PromptGlyphAlignment.inkCenterAboveBaseline(of: glyph, in: font))
        let textCenter = (font.capHeight + font.descender) / 2
        // Depth grows downward and both centres are measured *up* from their
        // own baseline, hence the subtraction.
        let promptCenter = baselineDepth(of: view.promptLabel, in: view) - inkCenter
        let textMiddle = baselineDepth(of: view.inputField, in: view) - textCenter
        return promptCenter - textMiddle
    }

    @Test("the prompt's ink sits on the middle of the typed line, not on its baseline")
    func promptCentersOnTheInputText() throws {
        let manager = makeManager(activeThemeID: terminalThemeID)
        let (view, _, _) = makeView()
        view.chrome = .terminal
        view.layoutSubtreeIfNeeded()

        // A point of slack because AppKit reports `firstBaselineOffsetFromTop`
        // in whole points: the drop asked for is fractional, the one laid out
        // is rounded, and the rounding is the only gap the eye cannot see.
        #expect(try abs(centeringError(in: view, font: manager.currentPalette.font(.body))) < 1)

        // And the correction is real: aligning the two baselines outright —
        // which is what this used to do — leaves the glyph visibly high.
        let baselineGap = baselineDepth(of: view.promptLabel, in: view)
            - baselineDepth(of: view.inputField, in: view)
        #expect(baselineGap > 0)
        withExtendedLifetime(manager) {}
    }

    @Test("the prompt stays centred after the text-size slider moves")
    func promptRecentersOnTextScale() throws {
        let manager = makeManager(activeThemeID: terminalThemeID)
        let (view, _, _) = makeView()
        view.chrome = .terminal
        view.layoutSubtreeIfNeeded()
        let before = baselineDepth(of: view.promptLabel, in: view)
            - baselineDepth(of: view.inputField, in: view)

        manager.textScale = 1.75
        view.layoutSubtreeIfNeeded()
        let after = baselineDepth(of: view.promptLabel, in: view)
            - baselineDepth(of: view.inputField, in: view)

        // Fails if the drop is ever frozen into a constant: bigger type needs a
        // bigger correction, and the glyph has to land centred at the new size
        // too. The ratio itself is not asserted — at these sizes AppKit's
        // whole-point baselines quantise it beyond what it would prove.
        #expect(after > before)
        #expect(try abs(centeringError(in: view, font: manager.currentPalette.font(.body))) < 1)
        withExtendedLifetime(manager) {}
    }

    /// The prompt is the composer's own ink — web colours it with the input's
    /// text colour — so it has to follow the theme like everything else.
    /// Two points prove the drop is not a constant; the slider has a range,
    /// and the glyph has to land centred everywhere in it. This walks the
    /// whole of `WindowAppearanceDefaults.textScaleRange`.
    @Test("the prompt is centred at every size the slider can reach")
    func promptCentersAcrossTheWholeRange() throws {
        let manager = makeManager(activeThemeID: terminalThemeID)
        let (view, _, _) = makeView()
        view.chrome = .terminal
        view.layoutSubtreeIfNeeded()

        let range = WindowAppearanceDefaults.textScaleRange
        var scale = range.lowerBound
        while scale <= range.upperBound + 0.0001 {
            manager.textScale = scale
            view.layoutSubtreeIfNeeded()
            let error = try centeringError(in: view, font: manager.currentPalette.font(.body))
            #expect(abs(error) < 1, "off by \(error) at scale \(scale)")
            scale += 0.05
        }
        withExtendedLifetime(manager) {}
    }

    @Test("the prompt repaints with the active theme")
    func promptRepaintsOnThemeChange() {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        view.chrome = .terminal

        let before = view.promptLabel.textColor
        manager.selectTheme(id: BuiltInThemes.dracula.id)

        #expect(before != nil)
        #expect(before != view.promptLabel.textColor)
    }

    // MARK: The surface

    /// Web paints `--pc-surface` on `.persona-chat` and nowhere else:
    /// `.pc-transcript`, `.pc-typing` and `.pc-input-area` declare no
    /// `background` at all. The port had each of them repaint it, which costs
    /// nothing while the surface is opaque and is plainly visible the moment
    /// it is not — `old-school-terminal` sets `rgba(5, 8, 5, 0.8)`, and three
    /// stacked copies of an 80% fill drew the transcript nearly solid while
    /// the status row and the composer stayed see-through.
    ///
    /// It is also what makes a translucent theme translucent *as a window*:
    /// the host clears the window's own fill, so whatever alpha survives this
    /// one layer is what the desktop shows through.
    @Test("only the chat view itself paints the surface")
    func theSurfaceIsPaintedExactlyOnce() throws {
        let terminal = try #require(BuiltInThemes.all.first { $0.name == "Old School Terminal" })
        let manager = makeManager(activeThemeID: terminal.id)
        let palette = manager.currentPalette
        let (view, _, _) = makeView()

        // The theme really is translucent — the rest of the test is only
        // interesting because of this.
        #expect(palette.color(.chatSurface).alpha < 1)
        #expect(view.layer?.backgroundColor == palette.nsColor(.chatSurface).cgColor)

        let scroll = try #require(view.subviews.compactMap { $0 as? NSScrollView }.first)
        #expect(!scroll.drawsBackground)
        #expect(!scroll.contentView.drawsBackground)
        #expect(view.thinkingIndicator.layer?.backgroundColor == NSColor.clear.cgColor)
        let statusRow = try #require(view.thinkingIndicator.superview)
        #expect(statusRow.layer?.backgroundColor == NSColor.clear.cgColor)
        withExtendedLifetime(manager) {}
    }

    /// The operator's item: "the transparency should not affect the text or
    /// gear button or controls only the container's background". The surface
    /// is the only thing that thins; everything drawn on top of it keeps the
    /// alpha the theme gave it, at every setting the slider can reach.
    @Test("transparency thins the surface and nothing else")
    func transparencyTouchesOnlyTheSurface() throws {
        let terminal = try #require(BuiltInThemes.all.first { $0.name == "Old School Terminal" })
        let manager = makeManager(activeThemeID: terminal.id)
        let (view, _, _) = makeView()
        view.chrome = .terminal
        view.layoutSubtreeIfNeeded()

        func surfaceAlpha() throws -> CGFloat {
            try #require(view.layer?.backgroundColor?.alpha)
        }
        func inkAlphas() throws -> [CGFloat] {
            [try #require(view.inputField.textColor),
             try #require(view.promptLabel.textColor)]
                .map { $0.usingColorSpace(.sRGB)?.alphaComponent ?? -1 }
        }

        let opaqueInk = try inkAlphas()
        #expect(opaqueInk.allSatisfy { $0 > 0 })

        var previousSurface = try surfaceAlpha()
        for percent in stride(from: 10.0, through: 100.0, by: 10.0) {
            view.surfaceTransparency = percent
            let surface = try surfaceAlpha()
            #expect(surface < previousSurface, "surface did not thin at \(percent)%")
            #expect(try inkAlphas() == opaqueInk, "the text moved at \(percent)%")
            previousSurface = surface
        }
        // The far end really is gone, not merely dim: this is what makes 100
        // a usable setting rather than the end of a fade.
        #expect(previousSurface < 0.001)
        withExtendedLifetime(manager) {}
    }

    @Test("repaints its layer background when the active theme changes")
    func repaintsOnThemeChange() {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()

        let before = view.layer?.backgroundColor
        manager.selectTheme(id: BuiltInThemes.dracula.id)
        let after = view.layer?.backgroundColor

        #expect(before != nil)
        #expect(before != after)
    }

    // MARK: The text-size shortcuts

    private func keyEvent(_ characters: String, _ flags: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
            windowNumber: 0, context: nil, characters: characters,
            charactersIgnoringModifiers: characters, isARepeat: false, keyCode: 0)!
    }

    @Test("plain command with +, - or 0 nudges the text size")
    func commandNudgesTextSize() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        var steps: [Int] = []
        view.onTextScaleNudge = { steps.append($0) }

        #expect(view.performKeyEquivalent(with: keyEvent("+", .command)))
        #expect(view.performKeyEquivalent(with: keyEvent("-", .command)))
        #expect(view.performKeyEquivalent(with: keyEvent("0", .command)))
        #expect(steps == [1, -1, 0])
    }

    /// ⌥⌘- and ⌃⌘0 are somebody else's shortcuts — zoom, a host's own menu —
    /// and swallowing them because the command key happened to be down would
    /// take them away from whoever owns them.
    @Test("command with another modifier is left to whoever owns it")
    func extraModifiersAreNotSwallowed() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        var steps: [Int] = []
        view.onTextScaleNudge = { steps.append($0) }

        #expect(view.performKeyEquivalent(with: keyEvent("-", [.command, .option])) == false)
        #expect(view.performKeyEquivalent(with: keyEvent("0", [.command, .control])) == false)
        #expect(steps.isEmpty)
    }

    @Test("a chat with no host listening passes the shortcut on")
    func noHandlerMeansNoClaim() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        #expect(view.performKeyEquivalent(with: keyEvent("+", .command)) == false)
    }

    // MARK: Rebuilding the transcript

    /// Every bubble is built loose and then inserted, so its own first apply
    /// can only resolve to the app scope. The rebuild is what knows the tree is
    /// complete, so the rebuild is what re-announces the scope — otherwise a
    /// chat at 150% renders each new message at 100%.
    @Test("rebuilding the transcript re-announces the scope for the bubbles it just added")
    func rebuildRefreshesTheScope() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, viewModel, _) = makeView()
        view.themeScope.textScale = 1.5

        var announcements = 0
        let token = NotificationCenter.default.addObserver(
            forName: ThemeScope.didChangeNotification, object: view.themeScope, queue: nil
        ) { _ in announcements += 1 }
        defer { NotificationCenter.default.removeObserver(token) }

        viewModel.handle(.messageReceived(FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "hi there", timestamp: Date())))
        #expect(announcements >= 1)
    }
}
