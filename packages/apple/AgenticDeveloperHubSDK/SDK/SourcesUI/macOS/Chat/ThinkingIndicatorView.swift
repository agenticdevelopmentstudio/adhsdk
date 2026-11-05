import AppKit
import AgenticDeveloperHubSDK

/// One colour and what it colours while a turn runs. The settled
/// "thought for 8s" line is deliberately never tinted: it is the persona's
/// finished work, and the grey is what makes the running line read as active.
public struct ThinkingTint: Sendable, Equatable {
    public enum Applies: Sendable { case words, icons, both }
    public let color: RGBAColor
    public let applies: Applies

    public init(color: RGBAColor, applies: Applies) {
        self.color = color
        self.applies = applies
    }
}

/// Everything the web `TypingIndicator` takes as a prop, as stored properties
/// on one value — a host configures the line rather than subclassing the
/// view. Every default below reproduces today's behaviour exactly.
public struct ThinkingIndicatorConfiguration: Sendable {
    /// "Thinking" word pairs to cycle through while a turn is in flight. Empty
    /// (the default) is the documented fallback, matching web's `labels`
    /// guard: `ThinkingIndicatorView` shows the three pulsing dots that exist
    /// today and runs no phase machine at all.
    public var words: [ChatStatusWordPair] = []
    public var frames: [String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    public var doneGlyph: String = "✱"
    public var frameInterval: Duration = .milliseconds(260)
    public var wordInterval: Duration = .milliseconds(1800)
    /// Flash vivid non-green colours while thinking, settling to grey when done.
    public var colorful: Bool = false
    /// Absent means untinted. Applied to the spans, not the wrapper, so
    /// `applies` can name one of them.
    public var tint: ThinkingTint?
    /// Shown with the animating glyph before anything has been in flight
    /// (e.g. "waiting to zeeble"). Yields to the thinking state on the first
    /// reply and never returns.
    public var idlePhrase: String?

    public init() {}
}

/// A "someone is composing" indicator, themed from the active
/// `SemanticPalette` and repainting live on theme change.
///
/// **Two rendering paths, chosen by `configuration.words`.** Empty (the
/// default `ThinkingIndicatorConfiguration()`) draws the plain three-dot
/// pulse this view has always drawn — no `ThinkingPhase.Machine` runs, and no
/// `ShuffleBag` is built. A non-empty vocabulary switches to the phase-driven
/// line: an animating braille glyph plus a rotating status word while
/// thinking, settling to a frozen "✱ thought for Ns" once the status clears.
/// This mirrors web's `TypingIndicator`, whose top-level `if (!labels ...)`
/// guard returns the classic dots component and never mounts
/// `ThinkingStatus` at all.
@MainActor
public final class ThinkingIndicatorView: NSView, Themeable {

    private let dots: [NSView] = (0..<3).map { _ in
        let dot = NSView()
        dot.wantsLayer = true
        dot.translatesAutoresizingMaskIntoConstraints = false
        return dot
    }
    private var dotsStack: NSStackView!

    private var timer: Timer?
    private var step = 0
    private var themeObserver: ThemePaletteObserver?

    // MARK: Phase-driven line

    /// The words. Split from the glyph rather than one attributed string,
    /// because web's `.pc-thinking-glyph` is a box of its own — see
    /// `glyphLabel`.
    let label = NSTextField(labelWithString: "")

    /// The glyph, in a box whose width does not follow the glyph.
    ///
    /// Web declares `flex: 0 0 1.6ch; min-width: 0; text-align: center` on
    /// `.pc-thinking-glyph` so "a wider frame fattens symmetrically from the
    /// center instead of shoving the word sideways". Concatenating the glyph
    /// and the words into one run — which is what this view used to do — has
    /// no such box, so every braille frame that measured a hair wider than the
    /// last, and every hand-off between `frames` and `doneGlyph`, slid the
    /// sentence back and forth.
    let glyphLabel = NSTextField(labelWithString: "")

    private var statusLine: NSStackView!
    private var glyphWidth: NSLayoutConstraint!

    private(set) var configuration = ThinkingIndicatorConfiguration()
    private var machine = ThinkingPhase.Machine()
    private var wordBag: ShuffleBag<ChatStatusWordPair>?
    private var currentWord: ChatStatusWordPair?
    private var currentUtterance: String?
    private var lastRenderedWordIndex = -1
    private var colorfulColor: RGBAColor?
    private var phaseTimer: Timer?

    /// `nil` while the words-empty dot fallback is in effect — the phase
    /// machine never runs in that mode. Test-only visibility (`@testable`);
    /// not part of the public surface.
    var currentPhase: ThinkingPhase? {
        configuration.words.isEmpty ? nil : machine.phase
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        timer?.invalidate()
        phaseTimer?.invalidate()
    }

    private func setup() {
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: dots)
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        dotsStack = stack

        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.lineBreakMode = .byTruncatingTail

        glyphLabel.translatesAutoresizingMaskIntoConstraints = false
        glyphLabel.isHidden = true
        glyphLabel.alignment = .center
        // The box is the point: nothing about the glyph currently in it may
        // change its width, so it neither hugs nor resists.
        glyphLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        glyphLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Baselines, and a gap — web's `.pc-thinking` is
        // `display: inline-flex; align-items: baseline; gap: 0.45em`. The
        // glyphs fall out of a terminal face the way `\u{276F}` does in the
        // composer (VT323 has no braille, no `\u{2731}`, no `\u{2299}`), so the
        // two runs are in different faces and their baseline is the one line
        // they agree on.
        let line = NSStackView(views: [glyphLabel, label])
        line.orientation = .horizontal
        line.alignment = .firstBaseline
        line.spacing = 0
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        statusLine = line
        glyphWidth = glyphLabel.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            glyphWidth,
            line.centerYAnchor.constraint(equalTo: centerYAnchor),
            line.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            line.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 48),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 28)
        ])
        for dot in dots {
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 7),
                dot.heightAnchor.constraint(equalToConstant: 7)
            ])
            dot.layer?.cornerRadius = 3.5
            dot.alphaValue = 0.3
        }

        themeObserver = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    /// Draws no fill of its own. Web's `.pc-typing` declares no `background`
    /// and no `border-radius` — it is a line of text in the gutter, not a
    /// pill. Repainting `chatSurface` here stacked a second copy of the
    /// surface on top of the one `InlineChatView` already draws, which on a
    /// theme whose surface is translucent (`old-school-terminal` is
    /// `rgba(5, 8, 5, 0.8)`) showed up as a lighter rounded band floating
    /// above the composer.
    public func applyTheme(_ palette: SemanticPalette) {
        layer?.backgroundColor = NSColor.clear.cgColor
        for dot in dots {
            dot.layer?.backgroundColor = palette.nsColor(.secondaryText).cgColor
        }
        resizeGlyphBox(palette: palette)
        render(palette: palette)
    }

    // MARK: Dot pulse (words-empty fallback)

    /// Starts the pulse from the beginning. Idempotent — calling it again
    /// simply restarts the cycle.
    public func startAnimating() {
        for dot in dots { dot.alphaValue = 0.3 }
        step = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
    }

    public func stopAnimating() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let active = step % dots.count
        for (index, dot) in dots.enumerated() {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                dot.animator().alphaValue = (index == active) ? 1.0 : 0.3
            }
        }
        step += 1
    }

    public override func removeFromSuperview() {
        stopAnimating()
        stopPhaseTimer()
        super.removeFromSuperview()
    }

    // MARK: Phase-driven line

    /// Installs a vocabulary (or clears one). Rebuilds the `ShuffleBag` and
    /// the `ThinkingPhase.Machine` from `configuration.frameInterval`/
    /// `wordInterval`, and switches which of the two rendering paths
    /// `update(status:)` drives.
    public func configure(_ configuration: ThinkingIndicatorConfiguration) {
        self.configuration = configuration
        machine = ThinkingPhase.Machine(
            frameInterval: configuration.frameInterval.timeIntervalValue,
            wordInterval: configuration.wordInterval.timeIntervalValue
        )
        wordBag = configuration.words.isEmpty ? nil : ShuffleBag(configuration.words)
        currentWord = nil
        currentUtterance = nil
        lastRenderedWordIndex = -1
        colorfulColor = nil
        stopPhaseTimer()

        let usesPhaseMachine = !configuration.words.isEmpty
        dotsStack.isHidden = usesPhaseMachine
        label.isHidden = !usesPhaseMachine
        glyphLabel.isHidden = !usesPhaseMachine
        resizeGlyphBox(palette: resolvedThemeScope.palette)
        render(palette: resolvedThemeScope.palette)
    }

    /// Drives the indicator from a live status. With no vocabulary configured
    /// this is exactly `status != nil ? startAnimating() : stopAnimating()` —
    /// the documented fallback, and no `ThinkingPhase.Machine` is touched.
    public func update(status: ChatStatus?) {
        guard !configuration.words.isEmpty else {
            if status != nil { startAnimating() } else { stopAnimating() }
            return
        }
        let now = Date().timeIntervalSinceReferenceDate
        let wasThinking = machine.phase == .thinking
        machine.apply(status, at: now)
        if machine.phase == .thinking, !wasThinking {
            // A fresh think: forget any word left over from a previous turn
            // and reroll the flash colour, mirroring web's false→true edge.
            lastRenderedWordIndex = -1
            if configuration.colorful { colorfulColor = randomNonGreenColor() }
        }
        if let announcement = machine.takePendingAnnouncement() {
            postAccessibilityAnnouncement(announcement)
        }
        render(palette: resolvedThemeScope.palette)
        machine.isSpinning ? startPhaseTimerIfNeeded() : stopPhaseTimer()
    }

    /// A transient utterance that pre-empts whatever phase was showing. The
    /// caller clears it after a beat with `clearUtterance()`.
    public func say(_ utterance: String) {
        guard !configuration.words.isEmpty else { return }
        let now = Date().timeIntervalSinceReferenceDate
        currentUtterance = utterance
        machine.say(utterance, at: now)
        if configuration.colorful { colorfulColor = randomNonGreenColor() }
        if let announcement = machine.takePendingAnnouncement() {
            postAccessibilityAnnouncement(announcement)
        }
        render(palette: resolvedThemeScope.palette)
        startPhaseTimerIfNeeded()
    }

    /// Resumes whatever phase the utterance pre-empted.
    public func clearUtterance() {
        guard !configuration.words.isEmpty else { return }
        let now = Date().timeIntervalSinceReferenceDate
        machine.clearUtterance(at: now)
        currentUtterance = nil
        render(palette: resolvedThemeScope.palette)
        if !machine.isSpinning { stopPhaseTimer() }
    }

    private func startPhaseTimerIfNeeded() {
        guard phaseTimer == nil else { return }
        phaseTimer = Timer.scheduledTimer(withTimeInterval: configuration.frameInterval.timeIntervalValue, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.phaseTick() }
        }
    }

    private func stopPhaseTimer() {
        phaseTimer?.invalidate()
        phaseTimer = nil
    }

    private func phaseTick() {
        let now = Date().timeIntervalSinceReferenceDate
        machine.tick(at: now)
        // `tick(at:)` never sets a pending announcement (see `ThinkingPhase`'s
        // doc comment) — this drains defensively so a future change to that
        // contract cannot silently start re-announcing every glyph frame.
        _ = machine.takePendingAnnouncement()
        render(palette: resolvedThemeScope.palette)
        if !machine.isSpinning { stopPhaseTimer() }
    }

    private func drainWordBagIfNeeded() {
        guard lastRenderedWordIndex < machine.wordIndex else { return }
        while lastRenderedWordIndex < machine.wordIndex {
            currentWord = wordBag?.next()
            lastRenderedWordIndex += 1
        }
    }

    private func currentGlyph() -> String {
        guard !configuration.frames.isEmpty else { return "" }
        return configuration.frames[machine.glyphIndex % configuration.frames.count]
    }

    private func render(palette: SemanticPalette) {
        guard !configuration.words.isEmpty else { return }
        switch machine.phase {
        case .idle:
            if let idlePhrase = configuration.idlePhrase {
                let ink = palette.nsColor(.thinkingIdleText)
                paint(glyph: configuration.doneGlyph, text: idlePhrase + "\u{2026}",
                      glyphColor: ink, wordColor: ink, palette: palette)
            } else {
                paint(glyph: "", text: "", glyphColor: .clear, wordColor: .clear, palette: palette)
            }
        case .thinking:
            drainWordBagIfNeeded()
            let ink = activeInk(palette: palette)
            paint(glyph: currentGlyph(), text: (currentWord?.present ?? "") + "\u{2026}",
                  glyphColor: ink.glyph, wordColor: ink.word, palette: palette)
        case .utterance:
            let ink = activeInk(palette: palette)
            paint(glyph: currentGlyph(), text: currentUtterance ?? "",
                  glyphColor: ink.glyph, wordColor: ink.word, palette: palette)
        case .done:
            // One colour across both spans, and deliberately never tinted, per
            // `ThinkingTint`'s doc comment.
            let word = currentWord?.past ?? ""
            let ink = palette.nsColor(.thinkingDoneText)
            paint(glyph: configuration.doneGlyph, text: "\(word) for \(machine.elapsedSeconds)s",
                  glyphColor: ink, wordColor: ink, palette: palette)
        }
    }

    /// The running line's colours: `.personaName` by default, overridden by
    /// `colorful`'s flashing hue and then by an explicit `tint` \u{2014} never both
    /// spans forced to the same source unless `tint.applies == .both`.
    private func activeInk(palette: SemanticPalette) -> (glyph: NSColor, word: NSColor) {
        let base = palette.nsColor(.personaName)
        var glyphColor = base
        var wordColor = base
        if configuration.colorful, let flashed = colorfulColor {
            let flashedColor = NSColor(flashed)
            glyphColor = flashedColor
            wordColor = flashedColor
        }
        if let tint = configuration.tint {
            let tinted = NSColor(tint.color)
            switch tint.applies {
            case .icons: glyphColor = tinted
            case .words: wordColor = tinted
            case .both: glyphColor = tinted; wordColor = tinted
            }
        }
        return (glyphColor, wordColor)
    }

    /// Paints the two spans. They are two labels rather than two runs of one
    /// attributed string so that the glyph's box can hold its width \u{2014} see
    /// `glyphLabel`.
    private func paint(
        glyph: String, text: String, glyphColor: NSColor, wordColor: NSColor, palette: SemanticPalette
    ) {
        let font = palette.font(.caption)
        glyphLabel.attributedStringValue = NSAttributedString(
            string: glyph, attributes: [.foregroundColor: glyphColor, .font: font])
        label.attributedStringValue = NSAttributedString(
            string: text, attributes: [.foregroundColor: wordColor, .font: font])
    }

    /// Sizes the glyph's box, and sets the gap between it and the words.
    ///
    /// Web's `1.6ch` is the floor here rather than the whole answer. `ch` is
    /// measured in the *line's* font, and on a terminal theme none of these
    /// glyphs are in that font \u{2014} they come from whatever face the system
    /// substitutes, which can be wider than 1.6 of the theme's digits. Web lets
    /// that overflow spill (the box is `min-width: 0` and centred); AppKit
    /// truncates instead, so the box is widened to hold the widest glyph the
    /// configuration can ever show. Still fixed, still centred, still
    /// independent of which glyph is currently up \u{2014} which is the whole point
    /// of the box.
    private func resizeGlyphBox(palette: SemanticPalette) {
        let font = palette.font(.caption)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let ch = ("0" as NSString).size(withAttributes: attributes).width
        let widest = (configuration.frames + [configuration.doneGlyph])
            .map { ($0 as NSString).size(withAttributes: attributes).width }
            .max() ?? 0
        glyphWidth.constant = ceil(Swift.max(ch * 1.6, widest))
        // Web's `gap: 0.45em` on `.pc-thinking`.
        statusLine.spacing = (font.pointSize * 0.45).rounded()
    }

    private func postAccessibilityAnnouncement(_ text: String) {
        NSAccessibility.post(
            element: label,
            notification: .announcementRequested,
            userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.medium.rawValue]
        )
    }
}

private extension Duration {
    var timeIntervalValue: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) * 1e-18
    }
}

/// A vivid hue that is never green — skips the ~75°–165° band. Ported
/// verbatim from web's `randomNonGreen()`
/// (`packages/chat/src/components/TypingIndicator.tsx`): draw `r` in
/// `0..<270`, then jump anything at or past 75° up by 90° so the draw lands
/// clean on the far side of the excluded band rather than clamping into its
/// edge. Degrees, `0..<360`.
func randomNonGreenHue() -> Double {
    let r = Double.random(in: 0..<270)
    return r < 75 ? r : r + 90
}

/// `hue` in degrees (`0..<360`), `saturation`/`lightness` in `0...1`. Standard
/// opaque HSL → RGB conversion.
func rgbaColor(hue: Double, saturation: Double, lightness: Double) -> RGBAColor {
    let c = (1 - abs(2 * lightness - 1)) * saturation
    let hPrime = hue.truncatingRemainder(dividingBy: 360) / 60
    let x = c * (1 - abs(hPrime.truncatingRemainder(dividingBy: 2) - 1))
    let m = lightness - c / 2
    let (r1, g1, b1): (Double, Double, Double)
    switch hPrime {
    case 0..<1: (r1, g1, b1) = (c, x, 0)
    case 1..<2: (r1, g1, b1) = (x, c, 0)
    case 2..<3: (r1, g1, b1) = (0, c, x)
    case 3..<4: (r1, g1, b1) = (0, x, c)
    case 4..<5: (r1, g1, b1) = (x, 0, c)
    default:    (r1, g1, b1) = (c, 0, x)
    }
    return RGBAColor(red: r1 + m, green: g1 + m, blue: b1 + m, alpha: 1)
}

/// `colorful`'s flash colour: a vivid non-green hue at 85% saturation, 62%
/// lightness — web's exact numbers.
func randomNonGreenColor() -> RGBAColor {
    rgbaColor(hue: randomNonGreenHue(), saturation: 0.85, lightness: 0.62)
}
