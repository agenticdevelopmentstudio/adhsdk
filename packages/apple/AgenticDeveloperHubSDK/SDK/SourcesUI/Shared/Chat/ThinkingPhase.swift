import Foundation
import AgenticDeveloperHubSDK

/// Where the thinking status line currently is.
///
/// - `idle`: nothing has been in flight yet (before the first turn, or after
///   `Machine()` is freshly constructed).
/// - `thinking`: a status is active; the spinner runs and the word rotates.
/// - `done`: the status cleared; the line is settled and frozen — see
///   `Machine.elapsedSeconds`.
/// - `utterance`: a transient "he just said this" line pre-empted whatever
///   phase was showing. The spinner keeps running (`Machine.isSpinning`); the
///   word does not, because there is no word to rotate through.
public enum ThinkingPhase: Sendable, Equatable {
    case idle
    case thinking
    case done
    case utterance
}

extension ThinkingPhase {

    /// The pure state machine behind `ThinkingIndicatorView`.
    ///
    /// **Pure, deliberately.** No AppKit, no `Timer`, no clock of its own —
    /// every method takes the current time as `at:`, so the view supplies real
    /// wall-clock time and a test supplies whatever timeline it likes. This is
    /// what makes the six behaviours below testable without touching AppKit or
    /// sleeping a test thread: `ThinkingPhaseTests` drives the whole machine
    /// through synthetic timestamps.
    ///
    /// Mirrors `ThinkingStatus` in `components/TypingIndicator.tsx`, minus the
    /// vocabulary: web's component owns both the phase transitions *and* the
    /// `ShuffleBag` draws in one hook. Here the split follows the file split —
    /// `Machine` is Foundation-only (`SourcesUI/Shared`, built for iOS too) and
    /// owns only the phase/clock/announcement state; `ThinkingIndicatorView`
    /// (AppKit, `SourcesUI/macOS`) owns the `ShuffleBag<ChatStatusWordPair>`
    /// and glyph-string tables, and reads `glyphIndex`/`wordIndex` from here to
    /// know when to draw a new frame or word.
    public struct Machine: Sendable {

        /// Where the display currently is.
        public private(set) var phase: ThinkingPhase = .idle

        /// Seconds the most recently completed think took. Frozen the instant
        /// the phase settles into `.done` (`apply(nil, at:)`) and untouched by
        /// every `tick(at:)` afterward — see `frozenTimeHolds`.
        public private(set) var elapsedSeconds: Int = 0

        /// Advances by `tick(at:)` at `frameInterval` while `isSpinning`. A
        /// view uses each new value as the cue to draw its next glyph frame.
        public private(set) var glyphIndex: Int = 0

        /// Advances by `tick(at:)` at `wordInterval` while `phase == .thinking`
        /// (never during `.utterance` — there is no vocabulary to rotate
        /// through while he's mid-sentence). A view uses each new value as the
        /// cue to draw its next word from a `ShuffleBag`.
        public private(set) var wordIndex: Int = 0

        /// Whether the glyph should be animating — true in `.thinking` and
        /// `.utterance` (the spinner keeps running while he "speaks", mirroring
        /// web's `phase === 'thinking' || !!utterance`), false once settled or
        /// idle.
        public var isSpinning: Bool { phase == .thinking || phase == .utterance }

        private let frameInterval: TimeInterval
        private let wordInterval: TimeInterval

        /// When the current think began, for `elapsedSeconds`. Seeded only on
        /// the idle/done → thinking edge (see `apply(_:at:)`) so a mid-turn
        /// status *kind* change doesn't restart the clock.
        private var thinkStartedAt: TimeInterval?
        private var lastGlyphTick: TimeInterval?
        private var lastWordTick: TimeInterval?

        /// The phase the machine was in before an utterance pre-empted it, so
        /// `clearUtterance(at:)` can resume rather than guess.
        private var phaseBeforeUtterance: ThinkingPhase?

        /// A string exactly once per transition — see `takePendingAnnouncement()`.
        private var pendingAnnouncement: String?

        public init(frameInterval: TimeInterval = 0.26, wordInterval: TimeInterval = 1.8) {
            self.frameInterval = frameInterval
            self.wordInterval = wordInterval
        }

        /// Moves the phase in response to a status change.
        ///
        /// A non-nil `status` (re-)enters `.thinking`. The clock is seeded only
        /// on the idle/done/utterance → thinking edge — a status whose *kind*
        /// changes mid-turn (`.think` → `.retry`, say) reaches this method too,
        /// but must not restart `thinkStartedAt`, or a 40s turn that changed
        /// kind at 37s would settle to "for 3s".
        ///
        /// `status == nil` clears an in-flight think: settles `.thinking` (or
        /// `.utterance`, which was always layered over a think) into `.done`
        /// and freezes `elapsedSeconds`. Called from `.idle` it is a no-op —
        /// there was nothing running to settle.
        public mutating func apply(_ status: ChatStatus?, at time: TimeInterval) {
            if let status {
                if phase != .thinking {
                    thinkStartedAt = time
                    glyphIndex = 0
                    wordIndex = 0
                    lastGlyphTick = time
                    lastWordTick = time
                }
                phase = .thinking
                phaseBeforeUtterance = nil
                pendingAnnouncement = status.words?.present ?? status.kind.rawValue
            } else if phase == .thinking || phase == .utterance {
                let start = thinkStartedAt ?? time
                elapsedSeconds = max(1, Int((time - start).rounded()))
                phase = .done
                phaseBeforeUtterance = nil
                pendingAnnouncement = "\(elapsedSeconds)s"
            }
            // From `.idle` or `.done`, a nil status is a no-op: nothing was
            // running, so there is nothing to settle or announce.
        }

        /// Advances the glyph and word indices from elapsed time, and returns
        /// early — untouched — once `.done` or `.idle`. Never itself changes
        /// `phase`; only `apply(_:at:)` and `say(_:at:)` do that.
        public mutating func tick(at time: TimeInterval) {
            guard isSpinning else { return }
            if let last = lastGlyphTick, time - last >= frameInterval {
                let steps = Int((time - last) / frameInterval)
                glyphIndex += max(1, steps)
                lastGlyphTick = last + TimeInterval(steps) * frameInterval
            }
            guard phase == .thinking else { return }
            if let last = lastWordTick, time - last >= wordInterval {
                let steps = Int((time - last) / wordInterval)
                wordIndex += max(1, steps)
                lastWordTick = last + TimeInterval(steps) * wordInterval
            }
        }

        /// A transient utterance pre-empts whatever phase was showing — the
        /// spinner keeps running (`isSpinning` stays true) but the word does
        /// not rotate; there is no vocabulary for an utterance, only the text
        /// itself. Mirrors web's `if (utterance) { … }` early return, which
        /// overrides every phase for the utterance's brief lifetime.
        public mutating func say(_ utterance: String, at time: TimeInterval) {
            if phaseBeforeUtterance == nil {
                phaseBeforeUtterance = phase
            }
            phase = .utterance
            if lastGlyphTick == nil { lastGlyphTick = time }
            pendingAnnouncement = utterance
        }

        /// Resumes the phase an utterance pre-empted — `.thinking` if a status
        /// is still active underneath it, `.done`/`.idle` otherwise. A no-op
        /// when not currently in `.utterance`.
        public mutating func clearUtterance(at time: TimeInterval) {
            guard phase == .utterance else { return }
            phase = phaseBeforeUtterance ?? .idle
            phaseBeforeUtterance = nil
        }

        /// Returns the announcement for the most recent transition exactly
        /// once, then `nil` until the next transition — so an accessibility
        /// channel speaks "thinking" / "thought for 8s" / an utterance once
        /// each, and never re-announces on every word or glyph tick.
        public mutating func takePendingAnnouncement() -> String? {
            defer { pendingAnnouncement = nil }
            return pendingAnnouncement
        }
    }
}
