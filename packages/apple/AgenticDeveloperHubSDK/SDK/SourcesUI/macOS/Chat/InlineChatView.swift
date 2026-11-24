import AppKit
import AgenticDeveloperHubSDK

/// An inline chat surface bound to `any ChatViewModel`: a scrolling
/// transcript of `MessageBubbleView`s (committed messages plus any live
/// `activeDrafts`, both rendered through the same bubble view), a
/// `ThinkingIndicatorView` while someone is typing, and a single-line
/// composer that submits on Return.
///
/// `localParticipantID` — not anything on `viewModel` itself, since
/// `ChatViewModel` has no notion of "me" — decides which side each bubble
/// renders on; see `MessageBubbleView`'s doc for why.
///
/// Command activity renders as a row of `ToolCallPillView`s below the
/// transcript.
///
/// Kept structurally minimal on purpose: no participant rail, no permission
/// prompts, no widgets. Task 8 seams are called out inline below, at the
/// point each attaches.
@MainActor
public final class InlineChatView: NSView, ChatStateObserver, Themeable, NSTextFieldDelegate,
                                   ThemeScopeProviding {

    public let viewModel: any ChatViewModel
    public let localParticipantID: String

    /// This chat's own type size, separate from every other chat's.
    ///
    /// Declared here rather than on the window because it is the *chat* that
    /// the size belongs to: everything inside resolves its palette by walking
    /// up to this view, so one slider reaches the transcript, the status line
    /// and the composer, and reaches nothing outside. Left at `1` it is
    /// indistinguishable from having no scope — see `ThemeScope`.
    public let themeScope = ThemeScope()

    /// How much of the surface to take away, `0`–`100`.
    ///
    /// Only the surface: the fill this view paints under everything else. The
    /// text, the prompt, the send glyph and the window's gear stay fully
    /// opaque at every setting, which is the difference between a chat you can
    /// see through and a chat that has been faded out. (The window's own
    /// `alphaValue` would do the second — it composites the whole window,
    /// chrome and all.)
    public var surfaceTransparency: Double = 0 {
        didSet {
            guard surfaceTransparency != oldValue else { return }
            applyTheme(resolvedThemeScope.palette)
        }
    }

    /// Something to draw behind the conversation — a field of falling glyphs,
    /// a gradient, a starfield.
    ///
    /// It goes above the surface fill and below everything else, pinned to all
    /// four edges and click-through, so a host supplies a view and nothing
    /// else. `nil`, the default, is a plain chat. A backdrop that also
    /// conforms to `AnimatedBackdrop` is started and stopped with
    /// `showsBackdrop`, so a hidden one costs no frames.
    public var backdrop: NSView? {
        didSet {
            oldValue?.removeFromSuperview()
            (oldValue as? any AnimatedBackdrop)?.stopAnimating()
            guard let backdrop else { return }
            backdrop.translatesAutoresizingMaskIntoConstraints = false
            addSubview(backdrop, positioned: .below, relativeTo: subviews.first)
            NSLayoutConstraint.activate([
                backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
                backdrop.trailingAnchor.constraint(equalTo: trailingAnchor),
                backdrop.topAnchor.constraint(equalTo: topAnchor),
                backdrop.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            applyBackdropVisibility()
        }
    }

    /// Whether the backdrop is drawn. A host surfaces it as a switch (the
    /// window gear does); with no backdrop set it means nothing.
    public var showsBackdrop: Bool = true {
        didSet {
            guard showsBackdrop != oldValue else { return }
            applyBackdropVisibility()
        }
    }

    private func applyBackdropVisibility() {
        guard let backdrop else { return }
        backdrop.isHidden = !showsBackdrop
        guard let animated = backdrop as? any AnimatedBackdrop else { return }
        if showsBackdrop { animated.startAnimating() } else { animated.stopAnimating() }
    }

    /// Fires on ⌘+, ⌘− and ⌘0 with `+1`, `-1` and `0`. A host wires it to
    /// whatever owns the saved text size — `ChatWindowAppearanceController`
    /// does — because the view knows the gesture and not where the number
    /// lives.
    public var onTextScaleNudge: ((Int) -> Void)?

    /// How the box resizes between its active (engaged) and inactive
    /// states. Defaulted so every existing call site is unchanged: with no
    /// `inactive` configured, `resolve(engaged:)` never tracks engagement,
    /// so `applySizing()` always applies `active` and reproduces today's
    /// fixed `>= 200` height exactly — see `InlineChatSizing`'s doc.
    public var sizing: InlineChatSizing = InlineChatSizing() { didSet { applySizing() } }

    /// Whether the box is currently "engaged" — focused, or otherwise the
    /// thing the user is interacting with. Internal rather than public: it
    /// exists so tests can drive and assert on engagement transitions
    /// directly (`InlineChatViewSizingTests`) without synthesizing real
    /// AppKit focus/click events, and a host reads `sizing`/`applySizing()`
    /// results instead of this flag.
    var engaged: Bool = false {
        didSet {
            guard engaged != oldValue else { return }
            applySizing()
        }
    }

    /// The status line, held for the life of the view rather than rebuilt
    /// with the transcript.
    ///
    /// Public because its vocabulary is the host's to author: a host calls
    /// `thinkingIndicator.configure(_:)` with its own `ChatStatusWordPair`s,
    /// glyph frames and idle phrase, exactly as web passes `labels` and
    /// `glyph` as props to `TypingIndicator`. Left unconfigured it draws the
    /// three pulsing dots, which is the documented fallback.
    ///
    /// It used to be built fresh inside `rebuildTranscript()` and thrown away
    /// on the next rebuild. That is why no phase ever advanced and no elapsed
    /// time ever accumulated: `ThinkingPhase.Machine` has to outlive a single
    /// message arriving, and a view rebuilt on every `ChatUpdate` cannot.
    public let thinkingIndicator = ThinkingIndicatorView()

    /// Presentation a `ColorTheme` cannot carry — the send affordance's glyph,
    /// whether the composer is fenced off by a rule, the composer's corner
    /// radius, the placeholder. Defaulted to today's appearance, so an
    /// existing call site is unchanged.
    public var chrome: InlineChatChrome = InlineChatChrome() { didSet { applyChrome() } }

    /// Whether the composer's block caret blinks or parks solid.
    ///
    /// Separate from `chrome` because it is not the theme's opinion but the
    /// reader's: `chrome.usesBlockCaret` says a terminal theme wants a block
    /// at all, and this says whether that block should keep moving in the
    /// corner of someone's eye. A host surfaces it as a switch (Olylo's window
    /// gear does); with no host saying otherwise it blinks, which is what web
    /// does unconditionally.
    public var blinksCaret: Bool = true {
        didSet { inputField.caretBlinks = blinksCaret }
    }

    let transcriptScroll = ThemedScrollView()
    private let transcriptStack = NSStackView()
    /// Internal, like `transcriptScroll` above: the composer's look is now
    /// `chrome`'s to decide, and a test that cannot see the field cannot tell
    /// whether the chrome reached it.
    let inputField = ChatInputField()
    /// Web's `❯` before the composer — the input row's `::before`, not part of
    /// the field, so it never enters what the user is typing.
    let promptLabel = NSTextField(labelWithString: "")

    /// Holds the prompt's baseline below the composer's by whatever it takes
    /// to centre the glyph on the typed line. Re-derived on every theme change
    /// and every text-scale change, because both fonts move.
    private var promptBaselineDrop: NSLayoutConstraint?
    private let sendButton = NSButton()
    private let divider = ThemedSeparatorView()
    private let statusRow = NSView()

    private var themeObserver: ThemePaletteObserver?
    private var isAtBottom = true
    private var lastTranscriptWidth: CGFloat = 0

    /// The transcript's height constraint currently in effect, carrying the
    /// resolved height: a floor for `.fixed`, a cap for `.contentHugging`,
    /// an exact zero for `.minimal`.
    ///
    /// Rebuilt by `applySizing()` rather than mutated, because those three
    /// behaviours need three different *relations* and
    /// `NSLayoutConstraint.relation` is immutable after creation — writing a
    /// cap into a `>=` constraint would turn a maximum into a minimum.
    /// Internal rather than private so `InlineChatViewSizingTests` can assert
    /// on both its constant and its relation.
    private(set) var transcriptHeightConstraint: NSLayoutConstraint!

    /// The companion constraint that makes `.contentHugging` actually hug:
    /// the scroll view has no intrinsic content size, so its height is tied
    /// to the document stack's at `.defaultHigh`, leaving the required cap in
    /// `transcriptHeightConstraint` free to win when content overflows it.
    /// `nil` for every other behaviour.
    private var transcriptHugConstraint: NSLayoutConstraint?

    /// Watches for a click outside the view while engaged — the AppKit
    /// reading of the web hook's `pointerdown` half of its
    /// `focusin`/`pointerdown`/`Escape` engagement triad. Removed in
    /// `deinit` via a direct `NSEvent.removeMonitor` call, which — like the
    /// existing `NotificationCenter.default.removeObserver(self)` below —
    /// is safe to call from a nonisolated `deinit`. `nonisolated(unsafe)`
    /// because it is mutated only on the main actor while the view lives,
    /// and `deinit` reads it only once no other reference remains.
    nonisolated(unsafe) private var clickOutsideMonitor: Any?

    private static let maxBubbleWidthFraction: CGFloat = 0.75
    private static let minBubbleWidth: CGFloat = 200
    private static let bubbleSideInset: CGFloat = 16
    private static let defaultTranscriptHeight: CGFloat = 200

    /// The narrowest width at which this view is still a chat: one minimum
    /// bubble plus the transcript's side insets. Every horizontal constraint
    /// in `setupViews()` pins a subview to *this* view's edges, so without
    /// this floor the view's `fittingSize.width` is 0 — and a host that lets
    /// auto layout size its container (an `NSWindow` whose `contentView` this
    /// becomes, most of all) collapses to a zero-width window that renders
    /// nothing and cannot be dragged back open.
    private static let minContentWidth: CGFloat = minBubbleWidth + bubbleSideInset * 2

    public init(viewModel: any ChatViewModel, localParticipantID: String) {
        self.viewModel = viewModel
        self.localParticipantID = localParticipantID
        super.init(frame: .zero)
        setupViews()
        viewModel.addObserver(self)
        themeObserver = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
        applyChrome()
        rebuildTranscript()
        refreshStatus()
        clickOutsideMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.disengageIfClickOutside(event)
            return event
        }
        applySizing()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        // No `viewModel.removeObserver(self)` here. `deinit` is nonisolated
        // and `ChatStateObserver` is `@MainActor`, so the call would be
        // unsound — and a view's last reference can be released off the main
        // thread, which makes `MainActor.assumeIsolated` a trap rather than a
        // fix. It is also unnecessary: `ObservableChatViewModel` holds its
        // observers in an `NSHashTable.weakObjects()`, so this entry zeroes
        // itself out and a later `notify` skips it.
        NotificationCenter.default.removeObserver(self)
        if let clickOutsideMonitor {
            NSEvent.removeMonitor(clickOutsideMonitor)
        }
    }

    private func setupViews() {
        transcriptStack.orientation = .vertical
        transcriptStack.spacing = 12
        transcriptStack.alignment = .leading
        transcriptStack.edgeInsets = NSEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        transcriptStack.translatesAutoresizingMaskIntoConstraints = false

        transcriptScroll.documentView = transcriptStack
        transcriptScroll.hasVerticalScroller = true
        transcriptScroll.drawsBackground = false
        transcriptScroll.translatesAutoresizingMaskIntoConstraints = false
        transcriptScroll.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(transcriptDidScroll),
            name: NSView.boundsDidChangeNotification, object: transcriptScroll.contentView)

        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.image = NSImage(systemSymbolName: "arrow.up.circle.fill", accessibilityDescription: "Send")
        sendButton.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        sendButton.isBordered = false
        sendButton.target = self
        sendButton.action = #selector(sendTapped)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        promptLabel.setContentHuggingPriority(.required, for: .horizontal)
        promptLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // No gap between the prompt and the field: web's `.pc-input-area` gap
        // applies between the flex children, and the `\u{276F}` is a `::before` on
        // the row \u{2014} it sits against the text it introduces, the way a shell
        // prompt does. The field's own 8pt cell inset is the whole gap.
        //
        // A plain container rather than a stack, because the prompt's vertical
        // placement is neither of the two things a stack can do. Centres are
        // wrong: the two are not in the same typeface (VT323 has no `\u{276F}`, nor
        // `\u{21B5}`, `\u{2731}` or `\u{2299}` \u{2014} 568 glyphs, none of them these), so
        // centring two differently-proportioned boxes puts their glyphs at two
        // different heights. Bare baselines are wrong too, for the same reason
        // read the other way: a shared baseline left the substituted `\u{276F}`
        // riding ~2 points above the middle of the typed line. So: a baseline
        // constraint with a font-derived drop on it \u{2014} see
        // `PromptGlyphAlignment` \u{2014} which is the one arrangement that puts the
        // glyph's ink centre on the text's centre and keeps it there at every
        // text scale.
        let promptedField = NSView()
        promptedField.translatesAutoresizingMaskIntoConstraints = false
        promptedField.addSubview(promptLabel)
        promptedField.addSubview(inputField)
        let promptBaseline = promptLabel.firstBaselineAnchor.constraint(
            equalTo: inputField.firstBaselineAnchor)
        promptBaselineDrop = promptBaseline
        NSLayoutConstraint.activate([
            promptLabel.leadingAnchor.constraint(equalTo: promptedField.leadingAnchor),
            inputField.leadingAnchor.constraint(equalTo: promptLabel.trailingAnchor),
            inputField.trailingAnchor.constraint(equalTo: promptedField.trailingAnchor),
            inputField.topAnchor.constraint(equalTo: promptedField.topAnchor),
            inputField.bottomAnchor.constraint(equalTo: promptedField.bottomAnchor),
            promptBaseline
        ])

        // The send button stays out of it, in an outer `.centerY` row: it
        // carries an image, not a line of text, so it has no baseline that
        // means anything. Aligning a glyph-in-a-circle on the text baseline
        // would hang most of it below the line.
        let inputRow = NSStackView(views: [promptedField, sendButton])
        inputRow.orientation = .horizontal
        inputRow.alignment = .centerY
        inputRow.spacing = 10
        inputRow.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        inputRow.translatesAutoresizingMaskIntoConstraints = false

        // Its own row between the transcript and the composer, outside the
        // scroll view — web's `.pc-typing`, which is a sibling of
        // `.pc-transcript` and not a child of it. Inside the transcript the
        // line scrolled away with the history and could be missed entirely on
        // a long conversation; here it is always where the eye already is,
        // just above where the user types.
        statusRow.translatesAutoresizingMaskIntoConstraints = false
        thinkingIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusRow.addSubview(thinkingIndicator)

        addSubview(transcriptScroll)
        addSubview(statusRow)
        addSubview(divider)
        addSubview(inputRow)

        // A floor on this view's own width. Required, unlike the transcript
        // height `applySizing()` owns: that one yields to a host that pins a
        // height because a shorter transcript is still a chat, while yielding
        // on width produced a zero-width window — `NSWindow` sizes a content
        // view whose width nothing else determines down to its fitting width,
        // and at priority 999 this floor did not raise it off 0.
        let minWidth = widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minContentWidth)

        // No height constraint here: `applySizing()` — called at the end of
        // `init`, right after this — owns it, and owns which relation it has.
        NSLayoutConstraint.activate([
            minWidth,

            transcriptScroll.topAnchor.constraint(equalTo: topAnchor),
            transcriptScroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            transcriptScroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            transcriptStack.widthAnchor.constraint(equalTo: transcriptScroll.widthAnchor),

            statusRow.topAnchor.constraint(equalTo: transcriptScroll.bottomAnchor),
            statusRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            thinkingIndicator.leadingAnchor.constraint(equalTo: statusRow.leadingAnchor, constant: 12),
            thinkingIndicator.trailingAnchor.constraint(lessThanOrEqualTo: statusRow.trailingAnchor, constant: -12),
            thinkingIndicator.topAnchor.constraint(equalTo: statusRow.topAnchor),
            thinkingIndicator.bottomAnchor.constraint(equalTo: statusRow.bottomAnchor),

            divider.topAnchor.constraint(equalTo: statusRow.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),

            inputRow.topAnchor.constraint(equalTo: divider.bottomAnchor),
            inputRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            inputRow.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    /// The chat surface is drawn exactly once, here, and nothing inside the
    /// chat repaints it.
    ///
    /// That is web's structure, not a simplification of it: `.persona-chat`
    /// carries `--pc-surface` and `.pc-transcript`, `.pc-typing` and
    /// `.pc-input-area` declare no `background` at all. The port had each of
    /// those paint the surface again for itself, which is invisible while the
    /// surface is opaque and obvious the moment it is not — `old-school-terminal`
    /// sets `rgba(5, 8, 5, 0.8)`, and stacking three copies of an 80% fill
    /// gave the transcript a near-solid black while the status row and
    /// composer stayed visibly lighter. One surface at the theme's own alpha
    /// is also what lets a translucent theme blend with the windows behind it:
    /// the host clears the window's own fill, and this layer is then the only
    /// thing between the chat and the desktop.
    public func applyTheme(_ palette: SemanticPalette) {
        wantsLayer = true
        // The theme's own alpha, thinned by the window's transparency setting.
        // Multiplied rather than replaced: `old-school-terminal` already asks
        // for `rgba(5, 8, 5, 0.8)`, and a setting that overwrote that would
        // make 0% transparency *more* opaque than the theme designed.
        let surface = palette.nsColor(.chatSurface)
        layer?.backgroundColor = surface
            .withAlphaComponent(surface.alphaComponent * CGFloat(1 - surfaceTransparency / 100))
            .cgColor
        // Not `.windowBackground` (the AppKit default, which would hide the
        // surface behind an opaque system fill) and not `chatSurface` either
        // — the transcript *is* the surface, so it draws nothing and lets the
        // one above show through.
        transcriptScroll.drawsBackground = false
        transcriptScroll.contentView.drawsBackground = false
        statusRow.wantsLayer = true
        statusRow.layer?.backgroundColor = NSColor.clear.cgColor
        // The prompt is the composer's own ink, not the send affordance's:
        // web colours `.pc-input-area::before` with the input's text colour.
        promptLabel.textColor = palette.nsColor(.userText)
        promptLabel.font = palette.font(.body)
        alignPrompt(palette: palette)
        sendButton.contentTintColor = palette.nsColor(.sendButton)
        if let glyph = chrome.sendGlyph {
            sendButton.attributedTitle = NSAttributedString(string: glyph, attributes: [
                .foregroundColor: palette.nsColor(.sendButton),
                .font: palette.font(.title)
            ])
        }
    }

    /// Drops the prompt's baseline far enough that the glyph's ink sits on the
    /// middle of the typed line. Both fonts are read fresh: the composer's
    /// face and its size both come from the palette, and the text-size slider
    /// changes them under a window that is already open.
    private func alignPrompt(palette: SemanticPalette) {
        let font = palette.font(.body)
        promptBaselineDrop?.constant = PromptGlyphAlignment.baselineDrop(
            for: promptLabel.stringValue, in: font, centeredOn: font)
    }

    /// Applies the parts of the look that live on `chrome` rather than in the
    /// palette. Idempotent, and safe to call before the first layout.
    private func applyChrome() {
        divider.isHidden = !chrome.showsDivider
        inputField.cornerRadius = chrome.inputCornerRadius
        inputField.showsBorder = chrome.showsInputBorder
        inputField.usesBlockCaret = chrome.usesBlockCaret
        inputField.placeholderString = chrome.inputPlaceholder
        promptLabel.isHidden = chrome.promptGlyph == nil
        promptLabel.stringValue = chrome.promptGlyph ?? ""
        // Which glyph is in the prompt decides how far its baseline drops, so
        // the alignment is redone here as well as on a theme change. (The
        // `applyTheme` call at the end of this method would do it too; doing
        // it here keeps the reason next to the change that causes it.)
        alignPrompt(palette: resolvedThemeScope.palette)
        if let glyph = chrome.sendGlyph {
            sendButton.image = nil
            sendButton.title = glyph
        } else {
            sendButton.title = ""
            sendButton.image = NSImage(
                systemSymbolName: "arrow.up.circle.fill", accessibilityDescription: "Send")
        }
        applyTheme(resolvedThemeScope.palette)
    }

    /// ⌘+ / ⌘− / ⌘0 on the chat's own type size.
    ///
    /// Here rather than in a menu item because a chat window may have no menu
    /// of its own — Olylo's is a status-bar app — and because a menu item would
    /// aim at whichever window was key, where this is dispatched down *this*
    /// window's view tree and so can only ever resize this chat.
    ///
    /// Only while the composer accepts typing: a chat that cannot be typed
    /// into is a transcript someone is watching, and the shortcuts belong to
    /// whatever else is on screen.
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // `contains`, not `==`: an equality test rejects every event carrying
        // any *other* flag, and three of them ride along routinely. ⇧ is on the
        // `+` key itself, so `case "+"` was unreachable; Caps Lock and the
        // numeric keypad set their own bits and would silently kill all three
        // shortcuts. What must be absent is only what would make this a
        // different chord — ⌃ and ⌥.
        //
        // And a nudge nobody is listening for is not this view's key to take:
        // returning true without a handler swallows the host application's own
        // ⌘0 / ⌘− menu items for as long as a chat is in the responder chain.
        guard let onTextScaleNudge,
              inputField.isEnabled,
              flags.contains(.command),
              flags.isDisjoint(with: [.control, .option]),
              let nudge = Self.textScaleNudge(for: event.charactersIgnoringModifiers)
        else { return super.performKeyEquivalent(with: event) }
        onTextScaleNudge(nudge)
        return true
    }

    /// `=` as well as `+` because ⌘+ is typed without the shift on every
    /// keyboard layout that puts them on one key, and AppKit reports what was
    /// actually typed.
    private static func textScaleNudge(for characters: String?) -> Int? {
        switch characters {
        case "+", "=": return 1
        case "-": return -1
        case "0": return 0
        default: return nil
        }
    }

    public override func layout() {
        super.layout()
        updateContainerOffsetCapIfNeeded()
        let width = transcriptScroll.contentView.bounds.width
        if width > 0, abs(width - lastTranscriptWidth) > 1 {
            lastTranscriptWidth = width
            rebuildTranscript()
        }
    }

    // MARK: ChatStateObserver

    public func chatDidUpdate(_ update: ChatUpdate) {
        switch update {
        case .messagesChanged, .activeDraftsChanged, .commandActivityChanged:
            rebuildTranscript()
        case .typingChanged:
            rebuildTranscript()
            refreshStatus()
        case .statusChanged:
            // Deliberately *not* a transcript rebuild: a status is not a
            // message, and rebuilding the whole stack four times a turn to
            // repaint one line is what made the old transient indicator
            // impossible to animate.
            refreshStatus()
        case .participantsChanged, .readMarkersChanged, .pendingPermissionsChanged,
             .pendingWidgetsChanged, .displayConfigChanged, .error:
            // Task 8 seams: a participant rail, unread badges from
            // `readMarkers`, permission prompts, inline widgets, and
            // surfaced transport errors all attach here.
            break
        }
    }

    // MARK: Transcript

    private func rebuildTranscript() {
        transcriptStack.arrangedSubviews.forEach {
            transcriptStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let scrollWidth = transcriptScroll.contentView.bounds.width
        let maxBubbleWidth = max(scrollWidth * Self.maxBubbleWidthFraction, Self.minBubbleWidth)

        for message in viewModel.messages {
            addBubbleRow(for: message, isLocalUser: message.senderID == localParticipantID, maxBubbleWidth: maxBubbleWidth)
        }
        for draft in viewModel.activeDrafts where !draft.text.isEmpty {
            let adapter = DraftMessageAdapter(draft: draft)
            addBubbleRow(for: adapter, isLocalUser: draft.participantID == localParticipantID, maxBubbleWidth: maxBubbleWidth)
        }

        // Pills sit below the transcript rather than interleaved with it:
        // `CommandActivity` carries no position in the message stream (only
        // `invocation.requestedAt`), so anchoring a pill between two bubbles
        // would be a guess. They stay in invocation order, above the
        // thinking indicator that is usually spinning because of them.
        for activity in viewModel.commandActivity {
            transcriptStack.addArrangedSubview(ToolCallPillView(activity: activity))
        }

        // Everything above was built before it was inserted, so every one of
        // those views resolved its scope to `.app` and painted at 100%. Now
        // that they are in the tree, tell the scope to say its piece again —
        // otherwise a transcript rebuilt at 150% comes back at 100% while the
        // composer beside it stays where the reader put it.
        themeScope.refresh()

        if isAtBottom {
            DispatchQueue.main.async { [weak self] in self?.scrollToBottom() }
        }
    }

    /// Pushes the current remote status into the persistent status line.
    ///
    /// The local participant is skipped: a status is what someone *else* is
    /// doing, and echoing the user's own back at them is not something web
    /// does either. With several remote participants the map has no ordering,
    /// so the ids are sorted — an arbitrary but stable pick beats a line that
    /// flickers between two personas as the dictionary rehashes.
    ///
    /// `typingParticipants` stays as a fallback rather than the driver it used
    /// to be: a backend that reports typing but emits no `statusChanged` still
    /// gets a spinning line, while one that emits real statuses gets its own
    /// authored words instead of a synthesised "think".
    private func refreshStatus() {
        let remote = viewModel.statuses
            .filter { $0.key != localParticipantID }
            .sorted { $0.key < $1.key }
        if let status = remote.first?.value {
            thinkingIndicator.update(status: status)
        } else if viewModel.typingParticipants.contains(where: { $0 != localParticipantID }) {
            thinkingIndicator.update(status: ChatStatus(kind: .think))
        } else {
            thinkingIndicator.update(status: nil)
        }
    }

    /// Lays a single bubble into the transcript, aligned right (with a
    /// leading spacer) for the local user and left otherwise — the same
    /// side-alignment structure AgenticDeveloperHubSDK's `ChatView` uses, keyed here
    /// off `isLocalUser` rather than a message role.
    private func addBubbleRow(for message: any Message, isLocalUser: Bool, maxBubbleWidth: CGFloat) {
        let bubble = MessageBubbleView(message: message, maxWidth: maxBubbleWidth, isLocalUser: isLocalUser)
        bubble.setContentHuggingPriority(.required, for: .horizontal)

        if isLocalUser {
            let spacer = NSView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            let row = NSStackView(views: [spacer, bubble])
            row.orientation = .horizontal
            row.alignment = .top
            row.spacing = 0
            row.translatesAutoresizingMaskIntoConstraints = false
            transcriptStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: transcriptStack.widthAnchor, constant: -Self.bubbleSideInset * 2).isActive = true
        } else {
            transcriptStack.addArrangedSubview(bubble)
        }
    }

    @objc private func transcriptDidScroll() {
        let contentView = transcriptScroll.contentView
        let visibleMaxY = contentView.bounds.origin.y + contentView.bounds.height
        let documentHeight = transcriptScroll.documentView?.frame.height ?? 0
        isAtBottom = documentHeight - visibleMaxY < 40
    }

    private func scrollToBottom() {
        guard let documentView = transcriptScroll.documentView else { return }
        let targetY = max(documentView.frame.height - transcriptScroll.contentView.bounds.height, 0)
        transcriptScroll.contentView.scroll(to: NSPoint(x: 0, y: targetY))
        transcriptScroll.reflectScrolledClipView(transcriptScroll.contentView)
    }

    // MARK: Composer

    @objc private func sendTapped() {
        let text = inputField.stringValue
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        inputField.stringValue = ""
        let viewModel = viewModel
        Task { @MainActor in
            do {
                _ = try await viewModel.submitMessage(text: text, attachments: [])
            } catch {
                // Task 7/8 seam: surface send failures in the composer
                // (inline error text, retry affordance) rather than dropping
                // them silently.
            }
        }
    }

    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Escape disengages regardless of which control is reporting it —
        // the third leg of the web hook's `focusin`/`pointerdown`/`Escape`
        // engagement triad is about the view's engagement state, not about
        // which field first-respondered the key event.
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            engaged = false
            return true
        }
        guard control === inputField, commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
        sendTapped()
        return true
    }

    // MARK: Sizing & engagement

    public func controlTextDidBeginEditing(_ obj: Notification) {
        engaged = true
        inputField.isFocused = true
    }

    public func controlTextDidEndEditing(_ obj: Notification) {
        inputField.isFocused = false
        guard !shouldStayEngaged(afterFocusMovingTo: window?.firstResponder) else { return }
        engaged = false
    }

    /// Disengages when `event` (a `.leftMouseDown`) lands outside this
    /// view's bounds. Internal rather than private so
    /// `InlineChatViewSizingTests` can drive it directly with a synthesized
    /// `NSEvent` — a local event monitor is not reliably triggerable from a
    /// headless unit test.
    func disengageIfClickOutside(_ event: NSEvent) {
        guard engaged, let window else { return }
        guard event.window === window else {
            engaged = false
            return
        }
        let locationInView = convert(event.locationInWindow, from: nil)
        if !bounds.contains(locationInView) {
            engaged = false
        }
    }

    /// Applies `sizing.resolve(engaged:)` to the transcript: hides it when
    /// `collapsed`, sizes its height constraint from the resolved
    /// behaviour, and wraps the change in `NSAnimationContext.runAnimationGroup`
    /// when `animates`. Called once at the end of `init` (after
    /// `setupViews()`) and on every `sizing`/`engaged` change, so a freshly
    /// constructed view with the default `InlineChatSizing()` already
    /// reflects it — reproducing today's fixed `>= 200` height exactly,
    /// since `resolve(engaged:)` with no `inactive` configured never
    /// tracks engagement.
    private func applySizing() {
        let resolved = sizing.resolve(engaged: engaged)

        let heightConstraint: NSLayoutConstraint
        var hugConstraint: NSLayoutConstraint?
        switch resolved.behavior {
        case .minimal:
            // An exact zero, not a floor of zero: `isHidden` alone leaves an
            // AppKit view's constraints in force, so the transcript would
            // keep its old height behind a hidden view.
            heightConstraint = transcriptScroll.heightAnchor.constraint(equalToConstant: 0)
        case .behavior(.fixed):
            heightConstraint = transcriptScroll.heightAnchor.constraint(
                greaterThanOrEqualToConstant: Self.defaultTranscriptHeight)
        case .behavior(.contentHugging(let cap)):
            heightConstraint = transcriptScroll.heightAnchor.constraint(
                lessThanOrEqualToConstant: capHeight(cap))
            let hug = transcriptScroll.heightAnchor.constraint(equalTo: transcriptStack.heightAnchor)
            hug.priority = .defaultHigh
            hugConstraint = hug
        }

        // Just below required. The transcript's height is also pinned by the
        // top/divider/composer chain to whatever frame the host gives this
        // view, so a host that hard-pins its height would otherwise make the
        // cap — or `.minimal`'s exact zero — unsatisfiable. Yielding to the
        // host is the honest outcome: it asked for that height, and it can
        // collapse the box by giving the view a smaller frame.
        heightConstraint.priority = .required - 1

        let apply = {
            self.transcriptScroll.isHidden = resolved.collapsed
            self.transcriptHeightConstraint?.isActive = false
            self.transcriptHugConstraint?.isActive = false
            self.transcriptHeightConstraint = heightConstraint
            self.transcriptHugConstraint = hugConstraint
            heightConstraint.isActive = true
            hugConstraint?.isActive = true
            self.layoutSubtreeIfNeeded()
        }
        if resolved.animates {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.allowsImplicitAnimation = true
                apply()
            }
        } else {
            apply()
        }
    }

    /// The cap in points. `.containerOffset` is measured against the view's
    /// own height, which is why `layout()` re-reads it: at `init` — the first
    /// `applySizing()` — `bounds` is still `.zero`, so a cap computed there
    /// and never revisited would pin the transcript at 0 forever.
    private func capHeight(_ cap: ChatSizeCap) -> CGFloat {
        switch cap {
        case .points(let value):
            return value
        case .containerOffset(let topInset):
            return max(bounds.height - topInset, 0)
        }
    }

    /// Keeps a `.containerOffset` cap current as the view resizes. Only the
    /// constant changes — the relation is already the `<=` `applySizing()`
    /// installed — so this cannot loop: the pass this triggers finds the
    /// constant already correct and stops.
    private func updateContainerOffsetCapIfNeeded() {
        guard case .behavior(.contentHugging(.containerOffset(let topInset))) =
            sizing.resolve(engaged: engaged).behavior else { return }
        let cap = max(bounds.height - topInset, 0)
        if abs(transcriptHeightConstraint.constant - cap) > 0.5 {
            transcriptHeightConstraint.constant = cap
        }
    }

    /// Whether focus leaving the composer should leave the box engaged.
    /// Web's triad disengages on a `pointerdown` *outside*, so a click that
    /// lands on the transcript — which on AppKit takes first responder away
    /// from the field — must not collapse the box out from under it.
    ///
    /// Deliberately scoped to `transcriptScroll` rather than the whole view:
    /// while the composer is editing, the window's first responder is its
    /// field editor, itself a descendant of `self`, so a `self`-wide test
    /// would answer "inside" for the very transition it is meant to judge.
    /// Internal so `InlineChatViewSizingTests` can pass a responder directly
    /// instead of driving real AppKit focus.
    func shouldStayEngaged(afterFocusMovingTo responder: NSResponder?) -> Bool {
        guard let view = responder as? NSView else { return false }
        return view === transcriptScroll || view.isDescendant(of: transcriptScroll)
    }
}

/// Adapts an in-progress `ActiveDraft` to `Message` so `InlineChatView` can
/// render a streaming draft through the same `MessageBubbleView` it uses for
/// committed messages, rather than a second bubble implementation.
private struct DraftMessageAdapter: Message {
    let draft: any ActiveDraft

    var id: String? { nil }
    var localID: String { draft.participantID }
    var senderID: String { draft.participantID }
    var text: String { draft.text }
    var timestamp: Date? { nil }
    var attachments: [any Attachment] { draft.attachments }
    var deliveryStatus: MessageDeliveryStatus { .composing }
}
