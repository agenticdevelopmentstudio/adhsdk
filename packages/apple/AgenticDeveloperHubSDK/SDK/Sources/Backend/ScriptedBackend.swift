import Foundation

/// A `Backend` that replays scripted `InboundEvent`s instead of talking to a
/// server — the Swift twin of web's `MockBackend`
/// (`packages/web/packages/chat/src/backends/MockBackend.ts`), built on the
/// same `Backend`/`InboundEvent` contract as `PersonaChatCoordinator` rather
/// than the older `ChatBackend` shape `MockBackend.ts` predates.
///
/// This ships in ADT, not in any one consumer: every customer needs a way to
/// see the chat contract work with no adh endpoint configured, and a scripted
/// replayer changes only when the contract does — the folder it sits beside,
/// not the wire-format churn `PersonaChatCoordinator` absorbs in
/// `Sources/Coordinator/`. What script to replay (the words, the persona) is
/// a consumer's content, not the toolkit's — see `ScriptedBackend.olyloDemo`
/// in Olylo's `OlyloChatConfig.swift` for how a host supplies its own.
///
/// **Two modes.**
///
/// `init(script:start:…)` plays one fixed script start to finish, exactly
/// once, and finishes the stream. It is the mode a test wants: drain
/// `inboundEvents` to completion and assert on what came out.
///
/// `init(opening:turn:…)` is a conversation. An `opening` script replays with
/// nothing typed — a persona's unprompted welcome, which is how the web olylo
/// chat starts — and then every `send` replays whatever `turn` returns for
/// that text. The stream is never finished, because a conversation has no
/// last turn. This is the mode a host showing a chat to a person wants, and
/// it is what the old doc comment here meant by "driving replies from the
/// submitted text … is a real feature this type could grow": web's
/// `olyloMockBackend` drains a scripted intro, then matches seeded patterns,
/// then draws from a shuffle bag, and none of that is expressible as one
/// fixed list of events.
///
/// **Pacing belongs to the script, not to the backend.** A `Beat` carries its
/// own delay, so one turn can think for two seconds and then stream its
/// tokens 80ms apart. A single uniform `delayBetweenEvents` cannot say that,
/// and every host that wants a visible think and a fast stream would have had
/// to pick one and lose the other. `init(script:…)`'s `delayBetweenEvents`
/// still exists and simply builds a uniformly-paced `[Beat]`.
///
/// `setLocalTyping`/`submitWidgetResponse` only record what was called.
///
/// Modeled on `PersonaChatCoordinator`, the toolkit's other `Backend`
/// conformer: a `public actor` whose `inboundEvents` and its
/// `AsyncStream.Continuation` are `nonisolated let`, established in `init`.
/// `Backend` is `Sendable` and not `@MainActor`, so an `@unchecked Sendable`
/// wrapper here would silence the compiler rather than prove the isolation —
/// the actor is what actually holds it.
public actor ScriptedBackend: Backend {

    /// When a fixed script starts replaying.
    ///
    /// The distinction is not cosmetic. A demo host builds its backend when it
    /// builds its chat surface — at launch — so `.immediately` makes the
    /// persona think and answer with nothing typed, then fall silent forever
    /// because the script is spent. `.onFirstSend` is the shape a live
    /// `PersonaChatCoordinator` turn actually has.
    ///
    /// Conversation mode has no equivalent knob, and needs none: its `opening`
    /// is by definition the unprompted part and its `turn` is by definition
    /// the prompted part.
    public enum ScriptStart: Sendable {
        /// Replay from `init`, with no `send` required. For a test that drains
        /// `inboundEvents` to completion without submitting anything.
        case immediately

        /// Replay when `send` is first called; later sends do not replay it
        /// again. For demo hosts, and for any test asserting on the order of
        /// the local echo against the scripted reply.
        case onFirstSend
    }

    /// One scripted event and the pause taken *before* yielding it.
    ///
    /// The delay leads rather than trails so a script reads as a timeline —
    /// "wait two seconds, then think; wait 80ms, then a token" — and so the
    /// first event of a script can be delayed at all, which a trailing delay
    /// could never express.
    public struct Beat: Sendable {
        public let delay: Duration
        public let event: InboundEvent

        public init(_ event: InboundEvent, after delay: Duration = .zero) {
            self.event = event
            self.delay = delay
        }
    }

    public nonisolated let inboundEvents: AsyncStream<InboundEvent>

    private nonisolated let events: AsyncStream<InboundEvent>.Continuation
    private nonisolated let localIDPrefix: String

    /// The fixed script, or (in conversation mode) the opening — already
    /// replayed from `init`, and kept only so `startScriptIfNeeded` has one
    /// thing to reach for in either mode.
    private let script: [Beat]

    /// Builds the beats for one turn from the submitted text and the 1-based
    /// index of that send. `nil` in fixed-script mode, which is exactly what
    /// distinguishes the two modes at runtime.
    private let turn: (@Sendable (_ text: String, _ index: Int) -> [Beat])?

    /// Guards a fixed script against replaying twice. Actor isolation is what
    /// makes the check race-free — two concurrent `send`s serialize here, so
    /// no lock is needed. Already `true` for `.immediately` and for
    /// conversation mode, whose replay started in `init`.
    private var hasStarted: Bool

    /// The tail of the replay chain. Each new turn awaits the previous one
    /// before yielding anything, so two sends in quick succession produce two
    /// turns in order rather than two interleaved ones — a reply's tokens
    /// landing inside another reply's tokens is the one way a scripted
    /// transcript can end up incoherent.
    private var replayChain: Task<Void, Never>?

    private var localIDSequence = 0

    /// Every `send` call, in arrival order. The script never reads this back
    /// — it exists so a test or a demo host can assert on what the local
    /// participant submitted.
    public private(set) var sent: [(localID: String, text: String, attachments: [any Attachment])] = []
    public private(set) var typingCalls: [Bool] = []
    public private(set) var widgetResponses: [any WidgetResponse] = []

    /// A fixed script, replayed once.
    ///
    /// - Parameters:
    ///   - script: Replayed in order onto `inboundEvents`, once, after which
    ///     the stream finishes.
    ///   - start: When replay begins. Defaults to `.immediately` so a test
    ///     that just drains the stream needs no ceremony; a host showing the
    ///     chat to a person wants `.onFirstSend`.
    ///   - delayBetweenEvents: Pause before *each* event, the first included.
    ///     `.zero` (the default) replays the whole script on the next run loop
    ///     turn. Pair `.onFirstSend` with a non-zero delay when ordering
    ///     matters: `ObservableChatViewModel` appends its optimistic local
    ///     echo only after `send` returns, so a zero-delay script can land its
    ///     reply into the transcript ahead of the message being replied to.
    ///   - localIDPrefix: Prefix for the deterministic ids `send` mints:
    ///     `"\(localIDPrefix)-1"`, `"\(localIDPrefix)-2"`, and so on.
    public init(
        script: [InboundEvent],
        start: ScriptStart = .immediately,
        delayBetweenEvents: Duration = .zero,
        localIDPrefix: String = "local"
    ) {
        let beats = script.map { Beat($0, after: delayBetweenEvents) }
        self.localIDPrefix = localIDPrefix
        self.script = beats
        self.turn = nil
        let (stream, continuation) = AsyncStream<InboundEvent>.makeStream(
            of: InboundEvent.self,
            bufferingPolicy: .unbounded
        )
        self.inboundEvents = stream
        self.events = continuation

        switch start {
        case .immediately:
            self.hasStarted = true
            self.replayChain = Self.replay(beats, onto: continuation, thenFinish: true)
        case .onFirstSend:
            self.hasStarted = false
        }
    }

    /// A conversation: an unprompted opening, then a reply per send.
    ///
    /// - Parameters:
    ///   - opening: Replayed from `init` with nothing typed — the persona's
    ///     welcome. Empty for a persona that waits to be spoken to.
    ///   - turn: The beats for one reply, given the submitted text and the
    ///     1-based index of that send. Called on the actor, once per `send`;
    ///     returning `[]` is a persona that ignores you.
    ///   - localIDPrefix: As above.
    public init(
        opening: [Beat] = [],
        turn: @escaping @Sendable (_ text: String, _ index: Int) -> [Beat],
        localIDPrefix: String = "local"
    ) {
        self.localIDPrefix = localIDPrefix
        self.script = opening
        self.turn = turn
        self.hasStarted = true
        let (stream, continuation) = AsyncStream<InboundEvent>.makeStream(
            of: InboundEvent.self,
            bufferingPolicy: .unbounded
        )
        self.inboundEvents = stream
        self.events = continuation
        self.replayChain = Self.replay(opening, onto: continuation, thenFinish: false)
    }

    /// Yields `beats` in order, after `predecessor` has finished, and returns
    /// the task that does it so the next turn can chain onto this one.
    ///
    /// `static`, taking everything it needs as parameters, so neither caller
    /// captures `self`: `init` runs before `self` is fully formed, and `send`
    /// would otherwise extend the actor's lifetime for the length of the
    /// script. `AsyncStream`'s buffering is unbounded, so nothing is lost if
    /// this races ahead of whatever consumes `inboundEvents`.
    @discardableResult
    private static func replay(
        _ beats: [Beat],
        onto continuation: AsyncStream<InboundEvent>.Continuation,
        after predecessor: Task<Void, Never>? = nil,
        thenFinish: Bool
    ) -> Task<Void, Never> {
        Task {
            await predecessor?.value
            for beat in beats {
                if beat.delay > .zero { try? await Task.sleep(for: beat.delay) }
                continuation.yield(beat.event)
            }
            if thenFinish { continuation.finish() }
        }
    }

    public func send(text: String, attachments: [any Attachment]) async throws -> String {
        localIDSequence += 1
        let localID = "\(localIDPrefix)-\(localIDSequence)"
        sent.append((localID: localID, text: text, attachments: attachments))
        if let turn {
            replayChain = Self.replay(
                turn(text, localIDSequence),
                onto: events,
                after: replayChain,
                thenFinish: false
            )
        } else {
            startScriptIfNeeded()
        }
        return localID
    }

    /// Starts a fixed script the first time something is sent. A no-op for
    /// `.immediately`, for conversation mode, and for every send after the
    /// first.
    private func startScriptIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        replayChain = Self.replay(script, onto: events, thenFinish: true)
    }

    /// The script drives everything; there is no local-typing channel to
    /// report on, so this only records the call — and deliberately does not
    /// start the script, which belongs to `send`: a host that reports typing
    /// on every keystroke would otherwise fire the reply before the message
    /// was sent.
    public func setLocalTyping(_ isTyping: Bool) async throws {
        typingCalls.append(isTyping)
    }

    /// The script drives everything; there is no live widget to respond
    /// into, so this only records the call.
    public func submitWidgetResponse(_ response: any WidgetResponse) async throws {
        widgetResponses.append(response)
    }
}
