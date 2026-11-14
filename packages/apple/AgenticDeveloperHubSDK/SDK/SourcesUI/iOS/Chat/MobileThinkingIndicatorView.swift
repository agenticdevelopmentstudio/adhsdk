import UIKit
import AgenticDeveloperHubSDK

/// A lightweight configuration for `MobileThinkingIndicatorView` — the
/// mobile twin of macOS's `ThinkingIndicatorConfiguration`, deliberately
/// smaller. Task 8's amendment says to keep the new UIKit views thin: the
/// indicator drives the same shared `ThinkingPhase.Machine` and shows the
/// same two rendering paths (dots, or glyph+word), without reproducing every
/// desktop knob — `colorful`/`tint`/`idlePhrase` are cosmetic embellishments
/// left for a follow-up rather than carried here.
public struct MobileThinkingIndicatorConfiguration: Sendable {
    /// "Thinking" word pairs to cycle through while a turn is in flight.
    /// Empty (the default) is the documented fallback: the three pulsing
    /// dots, no phase machine running at all — mirrors the macOS default.
    public var words: [ChatStatusWordPair] = []
    public var frames: [String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    public var doneGlyph: String = "✱"
    public var frameInterval: Duration = .milliseconds(260)
    public var wordInterval: Duration = .milliseconds(1800)

    public init() {}
}

/// The iOS twin of `ThinkingIndicatorView`: a "someone is composing"
/// indicator, themed from the active `SemanticPalette` and repainting live
/// on theme change, driving the shared `ThinkingPhase.Machine` exactly as
/// the macOS view does.
///
/// **Two rendering paths, chosen by `configuration.words`,** mirroring the
/// macOS view: empty (the default `MobileThinkingIndicatorConfiguration()`)
/// draws the plain three-dot pulse; a non-empty vocabulary switches to the
/// phase-driven line — an animating braille glyph plus a rotating status
/// word while thinking, settling to a frozen "✱ thought for Ns" once the
/// status clears.
@MainActor
public final class MobileThinkingIndicatorView: UIView, Themeable {

    private let dots: [UIView] = (0..<3).map { _ in
        let dot = UIView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        return dot
    }
    private var dotsStack: UIStackView!

    private var timer: Timer?
    private var step = 0
    private var themeObserver: ThemePaletteObserver?

    // MARK: Phase-driven line

    let label = UILabel()

    private(set) var configuration = MobileThinkingIndicatorConfiguration()
    private var machine = ThinkingPhase.Machine()
    private var wordBag: ShuffleBag<ChatStatusWordPair>?
    private var currentWord: ChatStatusWordPair?
    private var currentUtterance: String?
    private var lastRenderedWordIndex = -1
    private var phaseTimer: Timer?

    /// `nil` while the words-empty dot fallback is in effect — the phase
    /// machine never runs in that mode. Test-only visibility (`@testable`);
    /// not part of the public surface.
    var currentPhase: ThinkingPhase? {
        configuration.words.isEmpty ? nil : machine.phase
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    isolated deinit {
        timer?.invalidate()
        phaseTimer?.invalidate()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: dots)
        stack.axis = .horizontal
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        dotsStack = stack

        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.lineBreakMode = .byTruncatingTail
        addSubview(label)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 48),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 28)
        ])
        for dot in dots {
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 7),
                dot.heightAnchor.constraint(equalToConstant: 7)
            ])
            dot.layer.cornerRadius = 3.5
            dot.alpha = 0.3
        }

        themeObserver = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    /// Draws no fill of its own — see the macOS `ThinkingIndicatorView` for
    /// why: web's `.pc-typing` declares neither a `background` nor a
    /// `border-radius`, and repainting the surface here stacks a second copy
    /// of it over the one the chat view already draws.
    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = .clear
        for dot in dots {
            dot.backgroundColor = palette.uiColor(.secondaryText)
        }
        render(palette: palette)
    }

    // MARK: Dot pulse (words-empty fallback)

    /// Starts the pulse from the beginning. Idempotent — calling it again
    /// simply restarts the cycle.
    public func startAnimating() {
        for dot in dots { dot.alpha = 0.3 }
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
        UIView.animate(withDuration: 0.2) {
            for (index, dot) in self.dots.enumerated() {
                dot.alpha = (index == active) ? 1.0 : 0.3
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
    public func configure(_ configuration: MobileThinkingIndicatorConfiguration) {
        self.configuration = configuration
        machine = ThinkingPhase.Machine(
            frameInterval: configuration.frameInterval.timeIntervalValue,
            wordInterval: configuration.wordInterval.timeIntervalValue
        )
        wordBag = configuration.words.isEmpty ? nil : ShuffleBag(configuration.words)
        currentWord = nil
        currentUtterance = nil
        lastRenderedWordIndex = -1
        stopPhaseTimer()

        let usesPhaseMachine = !configuration.words.isEmpty
        dotsStack.isHidden = usesPhaseMachine
        label.isHidden = !usesPhaseMachine
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
            // A fresh think: forget any word left over from a previous turn,
            // mirroring web's false→true edge.
            lastRenderedWordIndex = -1
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
            label.text = ""
        case .thinking:
            drainWordBagIfNeeded()
            label.attributedText = activeLine(
                glyph: currentGlyph(), text: (currentWord?.present ?? "") + "…", palette: palette
            )
        case .utterance:
            label.attributedText = activeLine(
                glyph: currentGlyph(), text: currentUtterance ?? "", palette: palette
            )
        case .done:
            let word = currentWord?.past ?? ""
            label.attributedText = settledLine(
                glyph: configuration.doneGlyph, text: "\(word) for \(machine.elapsedSeconds)s", palette: palette
            )
        }
    }

    /// The running line's colour: `.personaName`, mirroring the macOS view's
    /// untinted default (this trimmed configuration carries no `tint`).
    private func activeLine(glyph: String, text: String, palette: SemanticPalette) -> NSAttributedString {
        let color = palette.uiColor(.personaName)
        let font = palette.font(.caption)
        let result = NSMutableAttributedString(string: glyph, attributes: [.foregroundColor: color, .font: font])
        result.append(NSAttributedString(string: " " + text, attributes: [.foregroundColor: color, .font: font]))
        return result
    }

    /// The settled line's colour: `.thinkingDoneText`, always — web's
    /// `--pc-thinking-done-color`.
    private func settledLine(glyph: String, text: String, palette: SemanticPalette) -> NSAttributedString {
        let color = palette.uiColor(.thinkingDoneText)
        let font = palette.font(.caption)
        let result = NSMutableAttributedString(string: glyph, attributes: [.foregroundColor: color, .font: font])
        result.append(NSAttributedString(string: " " + text, attributes: [.foregroundColor: color, .font: font]))
        return result
    }

    private func postAccessibilityAnnouncement(_ text: String) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}

private extension Duration {
    var timeIntervalValue: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) * 1e-18
    }
}
