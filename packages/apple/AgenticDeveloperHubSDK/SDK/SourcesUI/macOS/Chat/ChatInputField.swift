import AppKit
import AgenticDeveloperHubSDK

/// The chat composer's text field, painted from the three chat-input roles
/// every theme already carries: `.chatInputBackground`, `.chatInputBorder`,
/// and `.chatInputFocus`.
///
/// A separate type from `ThemedTextField` because the two answer different
/// questions. `ThemedTextField` is a *form* field — a stock rounded bezel over
/// `controlBackgroundColor`, which is what a settings panel wants and what its
/// callers get today. A chat composer is chrome: web's themes style
/// `.pc-input` with their own fill, their own one-pixel rule and their own
/// focus colour, and `old-school-terminal` in particular asks for a
/// transparent fill under a green rule that brightens on focus. A bezel cannot
/// express any of that — AppKit draws the bezel, and `backgroundColor` under
/// it is simply not visible — so this field turns the bezel off and paints its
/// own layer instead.
///
/// Those three roles were populated by all 21 ported themes and read by no
/// view at all before this existed, which is why a themed chat still showed a
/// stock macOS input.
@MainActor
public final class ChatInputField: NSTextField, Themeable {

    /// Squared off for terminal themes, rounded for everything else. Web
    /// carries the same knob as `--pc-radius`, which `old-school-terminal`
    /// sets to `0`.
    public var cornerRadius: CGFloat = 6 {
        didSet { layer?.cornerRadius = cornerRadius }
    }

    /// Whether the field paints its one-pixel rule at all. Off for terminal
    /// themes, whose `.pc-input` says `border: none` — see
    /// `InlineChatChrome.showsInputBorder`.
    public var showsBorder: Bool = true {
        didSet { layer?.borderWidth = showsBorder ? 1 : 0 }
    }

    /// Whether the composer parks a solid character-cell block where the
    /// system would draw its one-pixel bar.
    ///
    /// This is drawn here, as a layer of this field's own, rather than by
    /// widening the field editor's insertion point. The insertion point was
    /// the obvious route and it does not work: `drawInsertionPoint(in:color:
    /// turnedOn:)` is not called for a field editor on a current macOS, so a
    /// subclass overriding it renders nothing at all — which is exactly what
    /// the composer showed. Web reached the same conclusion from the other
    /// side, and its `.pc-input-caret` comment says why: an `<input>` exposes
    /// no caret-shape styling, so the block is a positioned element the chat
    /// moves itself. Two platforms, one answer — draw the caret, don't ask the
    /// text control for it.
    ///
    /// Owning the blink is the other half of the reason. AppKit's caret blinks
    /// on a system-wide cadence nobody can switch off per field, and web's is
    /// `ost-caret-blink 1.06s steps(1)` — hard on/off, no fade, a CRT and not
    /// a macOS text field. `caretBlinks` can only exist because this timer is
    /// ours.
    public var usesBlockCaret: Bool = false {
        didSet {
            guard usesBlockCaret != oldValue else { return }
            updateCaretPresence()
        }
    }

    /// Whether the block caret blinks or parks solid. Surfaced to users as the
    /// window's "Blink caret" switch; web has no such switch, and always blinks.
    public var caretBlinks: Bool = true {
        didSet {
            guard caretBlinks != oldValue else { return }
            updateCaretPresence()
        }
    }

    /// Whether the field currently has the keyboard focus, which selects
    /// between `.chatInputBorder` and `.chatInputFocus`.
    ///
    /// Driven by the *delegate* (`InlineChatView`'s
    /// `controlTextDidBeginEditing`/`controlTextDidEndEditing`) rather than by
    /// overriding `becomeFirstResponder`: an editable `NSTextField` never
    /// becomes the first responder itself — it hands off to the window's
    /// shared field editor — so the override fires at moments that have
    /// nothing to do with whether the user is typing here.
    public var isFocused: Bool = false {
        didSet {
            guard isFocused != oldValue else { return }
            applyTheme(resolvedThemeScope.palette)
        }
    }

    private var observer: ThemePaletteObserver?

    /// The block caret. A layer rather than something drawn in `draw(_:)` so a
    /// blink costs an `isHidden` flip instead of a redraw of the whole field.
    let caretLayer = CALayer()
    // `nonisolated(unsafe)`: mutated only on the main actor while the view
    // lives; the nonisolated `deinit` reads it only once no other reference
    // remains, so the two can never overlap.
    nonisolated(unsafe) private var caretTimer: Timer?
    nonisolated(unsafe) private var selectionObserver: (any NSObjectProtocol)?

    /// The field editor's clip view, watched so the block caret follows the
    /// text when it scrolls rather than only when it changes.
    /// `nonisolated(unsafe)` for the same reason as `selectionObserver`.
    nonisolated(unsafe) private var scrollObserver: (any NSObjectProtocol)?

    /// Web's `ost-caret-blink` is `1.06s steps(1)` with `50% { opacity: 0 }` —
    /// half the period lit, half dark, and no interpolation between them.
    static let caretBlinkHalfPeriod: TimeInterval = 0.53

    public override class var cellClass: AnyClass? {
        get { PaddedTextFieldCell.self }
        set { super.cellClass = newValue }
    }

    public init(string: String = "") {
        super.init(frame: .zero)
        stringValue = string
        isEditable = true
        isBordered = false
        isBezeled = false
        drawsBackground = false
        focusRingType = .none
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.borderWidth = showsBorder ? 1 : 0
        cell?.wraps = false
        cell?.usesSingleLineMode = true
        lineBreakMode = .byTruncatingHead
        caretLayer.isHidden = true
        observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        caretTimer?.invalidate()
        if let selectionObserver { NotificationCenter.default.removeObserver(selectionObserver) }
        if let scrollObserver { NotificationCenter.default.removeObserver(scrollObserver) }
    }

    /// The cell's padding is drawn, not laid out, so auto layout has no idea
    /// it is there — a field asking for exactly its glyph height renders with
    /// its text clipped top and bottom.
    public override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        size.height += PaddedTextFieldCell.inset.height * 2
        return size
    }

    public func applyTheme(_ palette: SemanticPalette) {
        layer?.backgroundColor = palette.nsColor(.chatInputBackground).cgColor
        layer?.borderColor = palette.nsColor(isFocused ? .chatInputFocus : .chatInputBorder).cgColor
        textColor = palette.nsColor(.userText)
        font = palette.font(.body)
        // The field editor is shared by every field in the window and keeps
        // whatever attributes the last editor set, so an already-focused field
        // needs its live text colour and insertion point pushed across
        // directly — repainting the cell alone leaves the theme change
        // invisible until focus moves away and back.
        if let editor = currentEditor() as? NSTextView {
            editor.textColor = palette.nsColor(.userText)
            // Our own block plus the system's bar would be two carets in the
            // same place, so the system's is painted out.
            editor.insertionPointColor = usesBlockCaret ? .clear : palette.nsColor(.chatInputFocus)
            editor.font = palette.font(.body)
        }
        if let placeholder = placeholderString {
            placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: palette.nsColor(.timestampText),
                .font: palette.font(.body)
            ])
        }
        applyCaretTheme(palette)
        positionCaret()
    }

    // MARK: The block caret

    /// The caret's own ink is the input's text colour — web's `.pc-input-caret`
    /// fills with `--ost-green`, the same token `.pc-input` colours its text
    /// with — under the phosphor bloom that rule's `box-shadow: 0 0 6px` puts
    /// around it. The bloom is what keeps a hard-edged rectangle reading as
    /// light coming off a tube rather than as a UI element.
    private func applyCaretTheme(_ palette: SemanticPalette) {
        let ink = palette.nsColor(.userText)
        caretLayer.backgroundColor = ink.cgColor
        caretLayer.shadowColor = ink.cgColor
        caretLayer.shadowOpacity = 0.85
        caretLayer.shadowRadius = 3
        caretLayer.shadowOffset = .zero
    }

    /// Attaches or detaches the caret and its timer to match `usesBlockCaret`
    /// and `caretBlinks`. Idempotent, so both `didSet`s can just call it.
    private func updateCaretPresence() {
        caretTimer?.invalidate()
        caretTimer = nil
        guard usesBlockCaret else {
            caretLayer.removeFromSuperlayer()
            caretLayer.isHidden = true
            return
        }
        if caretLayer.superlayer == nil { layer?.addSublayer(caretLayer) }
        setCaretLit(true)
        applyCaretTheme(resolvedThemeScope.palette)
        positionCaret()
        guard caretBlinks else { return }
        let timer = Timer(timeInterval: Self.caretBlinkHalfPeriod, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.setCaretLit(self.caretLayer.isHidden)
            }
        }
        // `.common`, not `.default`: a caret that stops blinking the moment a
        // menu opens or a slider is dragged is a caret that looks broken.
        RunLoop.main.add(timer, forMode: .common)
        caretTimer = timer
    }

    /// `steps(1)`, not a fade: implicit layer actions would cross-dissolve
    /// every flip and turn the hard CRT blink into a soft pulse.
    private func setCaretLit(_ lit: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        caretLayer.isHidden = !lit
        CATransaction.commit()
    }

    /// Parks the block over the character the insertion point stands on — or,
    /// with the field unfocused, at the end of whatever is typed, which for an
    /// empty composer is the prompt itself. A terminal's cursor is always
    /// somewhere; it does not vanish when the window stops being key.
    func positionCaret() {
        guard usesBlockCaret, caretLayer.superlayer != nil, let font = self.font else { return }
        let editor = currentEditor() as? NSTextView
        let text = (editor?.string ?? stringValue) as NSString
        let caretIndex = editor.map { Swift.min($0.selectedRange().location, text.length) } ?? text.length
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let advance = text.substring(to: caretIndex).size(withAttributes: attributes).width
        // How far the field editor has scrolled its text out to the left. Past
        // a field's width AppKit scrolls the editor rather than shrinking the
        // type, and the caret is a sublayer of the *field*, not of the editor,
        // so an unadjusted advance walks it off the right edge and the field's
        // own clipping erases it — exactly when a terminal chat needs it most.
        let scrolled = (editor?.superview as? NSClipView)?.bounds.origin.x ?? 0
        // The same rect the cell lays its text out in — see
        // `PaddedTextFieldCell.titleRect(forBounds:)`.
        let title = bounds.insetBy(dx: PaddedTextFieldCell.inset.width, dy: PaddedTextFieldCell.inset.height)
        let lineHeight = ceil(font.ascender - font.descender)
        // One character wide, measured from the live font rather than fixed:
        // the terminal themes scale their type, and a caret that did not scale
        // with it would sit under half a glyph.
        let cellWidth = Swift.max(("0" as NSString).size(withAttributes: attributes).width, 1)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Clamped to the text rect: an *unfocused* field has no editor to
        // scroll, so the cell truncates instead, and the block belongs at the
        // edge it truncated at rather than somewhere outside the field.
        let rightmost = Swift.max(title.minX, title.maxX - cellWidth)
        let caretX = Swift.min(Swift.max(title.minX, title.minX + advance - scrolled), rightmost)
        caretLayer.frame = NSRect(
            x: caretX,
            y: title.midY - lineHeight / 2,
            width: cellWidth,
            height: lineHeight)
        CATransaction.commit()
    }

    public override func layout() {
        super.layout()
        positionCaret()
    }

    public override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        // Typing relights the blink, so the block is never dark at the moment
        // the user is looking for it.
        if usesBlockCaret { setCaretLit(true) }
        positionCaret()
    }

    public override func textDidBeginEditing(_ notification: Notification) {
        super.textDidBeginEditing(notification)
        applyTheme(resolvedThemeScope.palette)
        // Arrow keys and clicks move the insertion point without changing the
        // text, so `textDidChange` alone would leave the block a keystroke
        // behind.
        if let editor = currentEditor() as? NSTextView {
            selectionObserver = NotificationCenter.default.addObserver(
                forName: NSTextView.didChangeSelectionNotification, object: editor, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.setCaretLit(true)
                    self?.positionCaret()
                }
            }
            // The scroll that keeps the insertion point visible happens *after*
            // the change that caused it, so the two notifications above would
            // each leave the block one keystroke behind once the text overflows.
            // The clip view is the thing that actually moved; ask it.
            if let clip = editor.superview as? NSClipView {
                clip.postsBoundsChangedNotifications = true
                scrollObserver = NotificationCenter.default.addObserver(
                    forName: NSView.boundsDidChangeNotification, object: clip, queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated { self?.positionCaret() }
                }
            }
        }
        positionCaret()
    }

    public override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        if let selectionObserver { NotificationCenter.default.removeObserver(selectionObserver) }
        selectionObserver = nil
        if let scrollObserver { NotificationCenter.default.removeObserver(scrollObserver) }
        scrollObserver = nil
        positionCaret()
    }
}

/// Insets the text so it is not painted hard against the border this field
/// draws. A bezeled field gets this for free from the bezel; an unbezeled one
/// gets nothing.
private final class PaddedTextFieldCell: NSTextFieldCell {
    static let inset = NSSize(width: 8, height: 5)

    /// The inset is clamped to half the rect it is given, because this is not
    /// only called with the field's real bounds.
    ///
    /// AppKit asks a cell for its baseline by calling this with a probe rect —
    /// measured here as 4×16, narrower than the 8-point horizontal inset. On
    /// that rect a plain `insetBy` produces a *negative* width, and
    /// `NSTextFieldCell.titleRect` answers a degenerate rect with an infinite
    /// origin. That infinity becomes the field's `firstBaselineOffsetFromTop`,
    /// and any `NSStackView` aligning on `.firstBaseline` hands it straight to
    /// the layout engine, which rejects it — `Invalid parameter not satisfying:
    /// isfinite(c)`, and the process is gone. Clamped, the same probe yields a
    /// finite 18, which is exactly the unpadded field's 13 plus this cell's
    /// 5-point vertical inset: the padding shows up in the baseline, which is
    /// what an aligned prompt needs it to do.
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        let dx = Swift.min(Self.inset.width, Swift.max(0, rect.width / 2))
        let dy = Swift.min(Self.inset.height, Swift.max(0, rect.height / 2))
        return super.titleRect(forBounds: rect.insetBy(dx: dx, dy: dy))
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
    }

    override func edit(
        withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText,
        delegate: Any?, event: NSEvent?
    ) {
        super.edit(
            withFrame: titleRect(forBounds: rect), in: controlView, editor: textObj,
            delegate: delegate, event: event)
    }

    override func select(
        withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText,
        delegate: Any?, start: Int, length: Int
    ) {
        super.select(
            withFrame: titleRect(forBounds: rect), in: controlView, editor: textObj,
            delegate: delegate, start: start, length: length)
    }
}
