import Foundation

/// What a participant is currently doing, for the status line above the
/// composer.
///
/// **Open, not closed, and deliberately so.** The toolkit owns the status
/// *channel*; the consuming application owns the status *vocabulary*. Web draws
/// the same line: `TypingIndicator` takes only words and never sees a kind,
/// because "the data layer's status resolver strips [tags] before handing words
/// to this component" — the kinds live in a consumer's persona data layer, one
/// import away from its persona editor. Modelling them as a closed Swift enum
/// here would pull a consumer's vocabulary into the toolkit and force every new
/// word an application invents to ship as an ADT release.
///
/// So this is a `RawRepresentable` wrapper, not an `enum`: ADT declares the
/// three kinds it actually *produces*, and `ChatStatusKind("harvesting")` is a
/// first-class kind an application can mint without touching the toolkit.
public struct ChatStatusKind: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }

    /// The three the coordinator emits. Everything else is a consumer's to name.
    public static let think = ChatStatusKind("think")
    public static let respond = ChatStatusKind("respond")
    public static let retry = ChatStatusKind("retry")
}

extension ChatStatusKind {
    /// The turn phases the coordinator already reports, as status kinds.
    public init(_ status: TurnStatus) {
        switch status {
        case .thinking: self = .think
        case .responding: self = .respond
        case .retrying: self = .retry
        }
    }
}

/// One action word in both the forms the status line needs: `present` while the
/// turn runs ("zeeping"), `past` once it settles ("zeeped for 12s").
///
/// **Both are authored; neither is derived.** No rule turns "thinking" into
/// "thought", and a rule that turns it into "thinked" is worse than no rule.
/// This mirrors `StatusWordPair` in `components/TypingIndicator.tsx` verbatim,
/// including the absence of any `tags` field — tagging words by kind is the
/// consumer's data layer's job, and its resolver strips the tags before the
/// words reach a renderer.
public struct ChatStatusWordPair: Sendable, Equatable {
    public let present: String
    public let past: String

    public init(present: String, past: String) {
        self.present = present
        self.past = past
    }
}

/// A status line: what kind of work, and optionally the exact words to show.
/// When `words` is nil the UI draws from the persona's vocabulary for `kind`.
public struct ChatStatus: Sendable, Equatable {
    public let kind: ChatStatusKind
    public let words: ChatStatusWordPair?

    public init(kind: ChatStatusKind, words: ChatStatusWordPair? = nil) {
        self.kind = kind
        self.words = words
    }
}

/// Draws elements in a shuffled order, exhausting the set before repeating,
/// and never returning the same element twice in a row across a refill.
/// The thinking line rotates words every 1.8s; plain random selection visibly
/// repeats, which reads as a stuck spinner rather than a working one.
///
/// **Stronger than web's bag, on purpose.** `backends/ShuffleBag.ts` reshuffles
/// on empty and can draw the same element twice across the seam between passes.
/// Closing that seam is the whole point at a 1.8s cadence. Also: web throws on
/// an empty bag; this returns `nil`, because a toolkit should not trap a host
/// that configured no vocabulary.
public struct ShuffleBag<Element: Equatable>: Sendable where Element: Sendable {
    private let source: [Element]
    private var remaining: [Element] = []
    private var lastDrawn: Element?

    public init(_ elements: [Element]) {
        source = elements
    }

    public mutating func next() -> Element? {
        guard !source.isEmpty else { return nil }
        guard source.count > 1 else { return source[0] }
        if remaining.isEmpty {
            remaining = source.shuffled()
            // A refill can put the previous element first; swap it away so the
            // no-repeat guarantee holds across the seam, not just within a bag.
            if remaining.first == lastDrawn, remaining.count > 1 {
                remaining.swapAt(0, 1)
            }
        }
        let drawn = remaining.removeFirst()
        lastDrawn = drawn
        return drawn
    }
}
