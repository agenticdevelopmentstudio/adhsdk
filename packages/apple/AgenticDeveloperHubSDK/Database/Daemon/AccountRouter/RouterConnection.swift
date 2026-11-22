#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation
import Network

/// Everything a connection needs, shared by all of them.
struct RouterContext: Sendable {
    let planner: any ExchangePlanning
    /// Chooses the body (the model); asked once per request, after `planner`.
    let modelPlanner: any ModelPlanning
    let session: URLSession
    let upstream: URL
    let limits: RouterLimits
    /// Shared by every connection built from this context.
    let admission: RouterAdmission
    let record: @Sendable (AccountRouterExchange) -> Void

    init(
        planner: any ExchangePlanning, modelPlanner: any ModelPlanning = PassModelPlanner(),
        session: URLSession, upstream: URL, limits: RouterLimits = .standard,
        record: @escaping @Sendable (AccountRouterExchange) -> Void
    ) {
        self.planner = planner
        self.modelPlanner = modelPlanner
        self.session = session
        self.upstream = upstream
        self.limits = limits
        self.admission = RouterAdmission(limits)
        self.record = record
    }
}

/// One client connection: wait for a slot, read one request, plan the account
/// and the model, attempt (at most ``maxAttempts`` sends: a provider attempt
/// and its Anthropic fallback, one account retry, one model revert), relay,
/// record, close.
final class RouterConnection: @unchecked Sendable {
    /// The 502 body. Constant: the reason goes to the row's error column only.
    static let unreachableBody = Data(
        #"{"type":"error","error":{"type":"api_error","message":"the router could not reach the upstream API"}}"#
            .utf8)
    private static let retryStatuses: Set<Int> = [401, 429]
    /// Answers to a rewritten body that send the original instead.
    private static let revertStatuses: Set<Int> = [400, 404, 413]
    /// Every upstream send of one request counts, whatever the reason.
    static let maxAttempts = 3
    /// The most one receive reads.
    private static let receiveMax = 256 * 1024
    /// A chunked body's reservation grows in steps of this.
    static let growthStep = 1024 * 1024

    private struct Outcome {
        var status: Int?
        var error: String?
        var quota = RouterHeaders.QuotaColumns()
        /// What the response said about itself; all nil when nothing was read.
        var servedModel: String?
        var inputTokens: Int?
        var outputTokens: Int?
        var cacheReadTokens: Int?
        var cacheCreationTokens: Int?
        var stopReason: String?

        /// Ends `reader` and copies what it found.
        mutating func absorb(_ reader: AnthropicResponseReader) {
            reader.finish()
            servedModel = reader.model
            inputTokens = reader.inputTokens
            outputTokens = reader.outputTokens
            cacheReadTokens = reader.cacheReadTokens
            cacheCreationTokens = reader.cacheCreationTokens
            stopReason = reader.stopReason
        }
    }

    /// Why one more upstream send is made, before anything is relayed.
    private enum Resend {
        /// A routed 401/429: another account, same body.
        case account(String)
        /// The rewritten body was refused: the original, same account.
        case revertModel
        /// The provider attempt failed before anything was relayed (`provider
        /// 401`, `provider unreachable`, …): Anthropic, original bytes, the
        /// account plan. Always the first send, so it never meets the cap and
        /// leaves the account retry for the Anthropic attempt.
        case provider(String)
    }

    private typealias Read = (Data?, Bool, NWError?)

    /// What the hang-up watch read while the request waited for body budget.
    /// The chunks are the request's own bytes, handed to the reader in order
    /// once the wait ends, so watching never loses data.
    private struct EarlyReads {
        var chunks: [Read] = []
        var bytes = 0
        /// A watch receive is issued and has not completed.
        var outstanding = false
        /// The wait is still on, so the watch may read again.
        var watching = false
        /// The reader, parked on the outstanding receive.
        var reader: CheckedContinuation<Read, Never>?
        /// The request is complete and the hang-up watch waits on the
        /// outstanding receive instead of issuing its own.
        var handOff = false
    }

    /// How the reader gets its next read.
    private enum NextRead {
        case ready(Read)
        case parked
        case fresh
    }

    /// Where a completed watch receive goes.
    private enum WatchStep {
        case toReader(CheckedContinuation<Read, Never>)
        case toHangUpWatch
        case hungUp
        case again
        case stop
    }

    /// How a provider's 2xx went.
    private enum ProviderResult {
        case relayed(Outcome)
        /// Nothing reached the client yet: fall back to Anthropic.
        case fallBack(String)
    }

    private let connection: NWConnection
    private let context: RouterContext
    private let queue = DispatchQueue(label: "account-router.connection")
    private let lock = NSLock()
    private var clientGone = false
    private var current: UpstreamCall?
    private var idleTimer: DispatchWorkItem?
    private var deadlineTimer: DispatchWorkItem?
    private var task: Task<Void, Never>?
    /// Reads taken while the request waited for body budget; under `lock`.
    private var early = EarlyReads()
    /// Body budget this connection holds; touched only by its own task.
    private var bodyHeld = 0
    /// Hands the accept back to the listener once everything is released.
    private let ended: @Sendable () -> Void

    init(connection: NWConnection, context: RouterContext, ended: @escaping @Sendable () -> Void = {}) {
        self.connection = connection
        self.context = context
        self.ended = ended
    }

    /// Waits for a connection slot before reading a byte. Until then the
    /// connection is accepted but not started, so the client's request waits
    /// in the kernel's socket buffer rather than being refused: fail-open.
    func start() {
        let admission = context.admission
        let task = Task {
            let served = await Self.holdingSlot(admission.connections) {
                self.connection.start(queue: self.queue)
                await self.run()
                admission.bodyBytes.release(self.bodyHeld)
                self.bodyHeld = 0
            }
            if !served { self.connection.cancel() }
            self.ended()
        }
        lock.withLock { self.task = task }
    }

    /// Runs `serve` holding one slot of `connections` and gives back exactly
    /// what was taken. A task cancelled while it waits takes nothing, gives
    /// nothing back and serves nothing: false.
    static func holdingSlot(_ connections: AsyncAllowance, _ serve: () async -> Void) async -> Bool {
        let got = await connections.acquire(1)
        defer { connections.release(got) }
        guard got > 0 else { return false }
        await serve()
        return true
    }

    private func run() async {
        guard let (head, body) = await readRequest() else {
            await close()
            return
        }
        let started = Date()
        let initial = context.planner.plan(head)
        let modelPlan = context.modelPlanner.plan(head, body: body)
        watchForHangUp()
        let (plan, model, outcome) = await forward(head, plan: initial, model: modelPlan)
        record(head: head, plan: plan, model: model, outcome: outcome, started: started)
        await close()
    }

    // MARK: - Request

    /// The request, or nil once the connection is answered or gone. Two clocks
    /// run: the idle timer (silence between reads) and the overall arrival
    /// deadline, so a client trickling a byte at a time is still dropped.
    private func readRequest() async -> (RouterRequestHead, Data)? {
        var parser = RouterRequestParser()
        var remaining = context.limits.requestDeadline
        var armedAt = Date()
        armDeadline(remaining)
        defer { disarmDeadline() }
        while true {
            if parser.growsBody, !(await growReservation(for: parser)) { return nil }
            armIdleTimer()
            let (data, isComplete, error) = await receive()
            disarmIdleTimer()
            if let data, !data.isEmpty {
                do {
                    for event in try parser.feed(data) {
                        switch event {
                        case .head(let head):
                            // Waiting for body budget is the router's delay, not
                            // the client's: the deadline stops while it lasts.
                            disarmDeadline()
                            remaining -= Date().timeIntervalSince(armedAt)
                            let budget = context.admission.bodyBytes
                            if let now = budget.tryAcquire(parser.bodyReservation) {
                                bodyHeld = now
                            } else {
                                watchWhileWaiting()
                                bodyHeld = await budget.acquire(parser.bodyReservation)
                                stopWatchingWhileWaiting()
                                // Only a hang-up during the wait cancels it.
                                if Task.isCancelled { return nil }
                            }
                            armedAt = Date()
                            armDeadline(remaining)
                            // RFC 9110 §10.1.1: never a 100 to an HTTP/1.0 client.
                            if head.expectsContinue && head.version != "HTTP/1.0" {
                                _ = await send(Data("HTTP/1.1 100 Continue\r\n\r\n".utf8))
                            }
                        case let .complete(head, body):
                            // A chunked body grew in steps; keep only what it used.
                            let used = min(bodyHeld, body.count)
                            context.admission.bodyBytes.release(bodyHeld - used)
                            bodyHeld = used
                            return (head, body)
                        }
                    }
                } catch {
                    await reject(error as? RequestRejection ?? .badRequest("unparseable"))
                    return nil
                }
            }
            if isComplete || error != nil { return nil }
        }
    }

    /// Before each read of a chunked body, reserve room for what is held plus
    /// one more read, in ``growthStep``s: the reservation tracks the body as
    /// it arrives instead of claiming the 64 MiB cap up front, so a client
    /// that sends a chunked head and then trickles holds almost nothing.
    ///
    /// This wait holds budget while it waits, so two growing bodies could wait
    /// on each other; the request deadline keeps running here (unlike the wait
    /// at the head) and breaks any such cycle. Claude Code sends
    /// `Content-Length`, which reserves once at the head and never grows.
    /// false when the connection was dropped while waiting.
    private func growReservation(for parser: RouterRequestParser) async -> Bool {
        let capacity = context.admission.bodyBytes.capacity
        let need = min(parser.bytesHeld, parser.maxBody) + Self.receiveMax
        guard need > bodyHeld, bodyHeld < capacity else { return true }
        let steps = (need + Self.growthStep - 1) / Self.growthStep
        let target = min(steps * Self.growthStep, parser.maxBody + Self.receiveMax, capacity)
        let got = await context.admission.bodyBytes.acquire(target - bodyHeld)
        bodyHeld += got
        return !Task.isCancelled
    }

    private func reject(_ rejection: RequestRejection) async {
        let body = Data((rejection.reason + "\n").utf8)
        let head = "HTTP/1.1 \(rejection.status) \(rejection.reason)\r\nContent-Type: text/plain; charset=utf-8\r\n"
            + "Content-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        _ = await send(Data(head.utf8) + body)
    }

    // MARK: - Upstream

    /// Sends until an answer is relayed. A head that earns a resend (see
    /// ``resend(after:plan:model:accountRetried:)``) is dropped unrelayed;
    /// after ``maxAttempts`` sends, whatever came is relayed.
    private func forward(
        _ head: RouterRequestHead, plan initial: ExchangePlan, model initialModel: ModelPlan
    ) async -> (ExchangePlan, ModelPlan, Outcome) {
        var plan = initial
        var model = initialModel
        var attempts = 0
        var accountRetried = false
        while true {
            let route = model.providerRoute
            let request: URLRequest
            if let route {
                request = ProviderExchange.request(route, head: head, body: model.body, streams: model.providerStreams)
            } else {
                let fields = RouterHeaders.upstreamFields(head, bearer: plan.bearer)
                guard let built = UpstreamCall.request(
                    base: context.upstream, head: head, fields: fields, body: model.body
                ) else {
                    await reject(.badRequest("target"))
                    return (plan, model, Outcome(status: 400, error: "target cannot be forwarded upstream"))
                }
                request = built
            }
            let call = UpstreamCall(session: context.session, request: request)
            // A task never resumed stays in the session, holding its delegate.
            guard begin(call) else {
                call.cancel()
                return (plan, model, gone(Outcome()))
            }
            call.start()
            attempts += 1
            // A provider that accepts and never answers falls back as unreachable.
            let headDeadline = model.providerStreams
                ? context.limits.providerHeadDeadline : context.limits.providerUnstreamedHeadDeadline
            let headTimer = route == nil ? nil
                : Self.watchdog(call, seconds: headDeadline, reason: "provider head timeout")
            let firstEvent = await call.next()
            headTimer?.cancel()
            guard let first = firstEvent else { return (plan, model, gone(Outcome())) }
            switch first {
            case .head(let upstreamHead):
                let status = upstreamHead.status
                let reason: Resend
                if let route {
                    // A provider's head says nothing about any account: never observed.
                    guard (200..<300).contains(status) else {
                        call.cancel()
                        apply(.provider("provider \(status)"), status: status, head: head, plan: &plan,
                              model: &model, accountRetried: &accountRetried)
                        continue
                    }
                    switch await relayProvider(call, head: upstreamHead, request: head, route: route,
                                               streams: model.providerStreams,
                                               canFallBack: attempts < Self.maxAttempts) {
                    case .relayed(let outcome):
                        return (plan, model, outcome)
                    case .fallBack(let why):
                        call.cancel()
                        reason = .provider(why)
                    }
                } else {
                    context.planner.observe(plan, head: upstreamHead)
                    guard attempts < Self.maxAttempts,
                          let again = resend(after: status, plan: plan, model: model, accountRetried: accountRetried)
                    else { return (plan, model, await relay(call, head: upstreamHead, request: head)) }
                    call.cancel()
                    reason = again
                }
                apply(reason, status: status, head: head, plan: &plan, model: &model, accountRetried: &accountRetried)
                continue
            case .failed(let why):
                if isClientGone { return (plan, model, gone(Outcome())) }
                if let route {
                    call.cancel()
                    let reason = AccountRouterLog.scrub(why, secrets: [route.apiKey])
                    AccountRouterLog.logger.info("provider unreachable: \(reason, privacy: .public)")
                    apply(.provider("provider unreachable"), status: nil, head: head, plan: &plan, model: &model,
                          accountRetried: &accountRetried)
                    continue
                }
                await sendUnreachable()
                AccountRouterLog.logger.warning(
                    "upstream unreachable: \(AccountRouterLog.scrub(why), privacy: .public)")
                return (plan, model,
                        Outcome(status: 502, error: AccountRouterLog.scrub("upstream unreachable: \(why)")))
            case .body, .finished:
                call.cancel()
                if route != nil {
                    apply(.provider("provider unreachable"), status: nil, head: head, plan: &plan, model: &model,
                          accountRetried: &accountRetried)
                    continue
                }
                await sendUnreachable()
                return (plan, model, Outcome(status: 502, error: "upstream sent no response head"))
            }
        }
    }

    /// Changes the plans for the next send. `status` is the answer that
    /// earned it; nil when there was none (an unreachable provider).
    private func apply(
        _ reason: Resend, status: Int?, head: RouterRequestHead, plan: inout ExchangePlan, model: inout ModelPlan,
        accountRetried: inout Bool
    ) {
        switch reason {
        case .account(let account):
            let who = AccountRouterLog.scrub(account)
            let code = status ?? 0
            AccountRouterLog.logger.info("retrying after \(who, privacy: .public) answered \(code, privacy: .public)")
            plan = context.planner.replan(head, after: account, status: code)
            accountRetried = true
        case .revertModel:
            let code = status ?? 0
            context.modelPlanner.reverted(model, status: code)
            model = model.reverted(after: code)
        case .provider(let why):
            let line = AccountRouterLog.scrub(
                "provider \(model.providerRoute?.name ?? "-"): \(why); falling back to Anthropic",
                secrets: [model.providerRoute?.apiKey])
            AccountRouterLog.logger.info("\(line, privacy: .public)")
            // The thread stays on Anthropic, as after a revert, and new threads
            // skip the provider for its cool-down: a failing or hung provider
            // is not tried again on every request.
            context.modelPlanner.fellBack(model)
            model = model.fellBack(why)
        }
    }

    /// A provider's 2xx. The Anthropic wire relays like Anthropic; the chat
    /// wire is translated, and only the translated bytes reach the client and
    /// the reader. A non-streamed reply is read whole first, so a reply that
    /// cannot be translated still falls back (when `canFallBack`).
    private func relayProvider(
        _ call: UpstreamCall, head upstreamHead: UpstreamHead, request: RouterRequestHead, route: ProviderRoute,
        streams: Bool, canFallBack: Bool
    ) async -> ProviderResult {
        guard case .chatCompletions = route.wire else {
            return .relayed(await relay(call, head: upstreamHead, request: request))
        }
        // While a fallback is still possible, a provider that goes quiet is
        // given up on: nothing has reached the client yet.
        let idleTimer = canFallBack ? idleWatchdog(call) : nil
        defer { idleTimer?.cancel() }
        call.allowBody()
        if streams {
            return await relayTranslatedStream(call, request: request, route: route, canFallBack: canFallBack,
                                               idleTimer: idleTimer)
        }
        var reply = Data()
        collecting: while true {
            guard let event = await call.next() else { return .relayed(gone(Outcome())) }
            switch event {
            case .body(let data):
                reply.append(data)
                if reply.count > ProviderExchange.replyLimit { break collecting }
            case .finished:
                break collecting
            case .failed(let why):
                if isClientGone { return .relayed(gone(Outcome())) }
                if canFallBack { return .fallBack(why == Self.idleReason ? why : "provider reply failed") }
                reply = Data()
                break collecting
            case .head:
                continue
            }
        }
        guard reply.count <= ProviderExchange.replyLimit,
              let translated = ProviderExchange.message(fromChatCompletion: reply, route: route) else {
            if canFallBack { return .fallBack("provider reply untranslatable") }
            call.cancel()
            await sendUnreachable()
            return .relayed(Outcome(status: 502, error: "provider reply untranslatable"))
        }
        let reader = AnthropicResponseReader(streaming: false)
        let head = ProviderExchange.clientHead(streams: false, chunked: false, length: translated.count)
        guard await send(head + translated) else { return .relayed(gone(Outcome())) }
        reader.consume(translated)
        var outcome = Outcome(status: 200)
        outcome.absorb(reader)
        return .relayed(outcome)
    }

    /// Chat Completions SSE in, Anthropic SSE out. Nothing reaches the client
    /// until the first content block: a stream that fails, errors, ends empty
    /// or is not SSE before then falls back (when `canFallBack`). After that, a
    /// stream that breaks ends with one `error` event; the row gets the
    /// reason, never body bytes. `idleTimer` is stopped at the commit: once the
    /// client has content, a pause (a model thinking) is never cut.
    private func relayTranslatedStream(
        _ call: UpstreamCall, request: RouterRequestHead, route: ProviderRoute, canFallBack: Bool,
        idleTimer: Task<Void, Never>?
    ) async -> ProviderResult {
        let chunked = request.version != "HTTP/1.0"
        let reader = AnthropicResponseReader(streaming: true)
        let translator = ChatCompletionsStreamTranslator(model: route.model)
        var outcome = Outcome()
        /// Translated bytes held back until the first content block.
        var held: Data? = Data()
        var rawBeforeContent = 0

        /// Sends the head and everything held; false when the client is gone.
        func commit() async -> Bool {
            guard let pending = held else { return true }
            held = nil
            idleTimer?.cancel()
            guard await send(ProviderExchange.clientHead(streams: true, chunked: chunked, length: nil)) else {
                return false
            }
            return await emit(pending, chunked: chunked, reader: reader)
        }
        /// Holds or sends `data`; false when the client is gone.
        func pass(_ data: Data) async -> Bool {
            if Self.hasEvent("error", in: data) { outcome.error = outcome.error ?? "provider stream error" }
            guard held != nil else { return await emit(data, chunked: chunked, reader: reader) }
            held?.append(data)
            guard Self.hasEvent("content_block_start", in: data) || !canFallBack else { return true }
            return await commit()
        }

        while true {
            guard let event = await call.next() else {
                outcome.absorb(reader)
                return .relayed(gone(outcome))
            }
            switch event {
            case .body(let data):
                let translated = translator.consume(data)
                if held != nil, canFallBack {
                    rawBeforeContent += data.count
                    if Self.hasEvent("error", in: translated) { return .fallBack("provider stream error") }
                    if rawBeforeContent > ProviderExchange.replyLimit {
                        return .fallBack("provider stream had no content")
                    }
                }
                guard await pass(translated) else {
                    call.cancel()
                    outcome.absorb(reader)
                    return .relayed(gone(outcome))
                }
            case .finished:
                let tail = translator.finish()
                if held != nil, canFallBack {
                    if Self.hasEvent("error", in: tail) { return .fallBack("provider stream error") }
                    if !Self.hasEvent("content_block_start", in: tail) {
                        return .fallBack("provider stream had no content")
                    }
                }
                var delivered = await pass(tail)
                if delivered { delivered = await commit() }
                if delivered, chunked { delivered = await send(Data("0\r\n\r\n".utf8)) }
                guard delivered else {
                    outcome.absorb(reader)
                    return .relayed(gone(outcome))
                }
                outcome.status = 200
                outcome.absorb(reader)
                return .relayed(outcome)
            case .failed(let reason):
                if isClientGone {
                    outcome.absorb(reader)
                    return .relayed(gone(outcome))
                }
                if held != nil, canFallBack {
                    return .fallBack(reason == Self.idleReason ? reason : "provider stream failed")
                }
                if await commit(), await emit(ProviderExchange.streamFailedEvent, chunked: chunked, reader: reader),
                   chunked {
                    _ = await send(Data("0\r\n\r\n".utf8))
                }
                outcome.status = 200
                outcome.error = AccountRouterLog.scrub("provider stream failed: \(reason)", secrets: [route.apiKey])
                outcome.absorb(reader)
                return .relayed(outcome)
            case .head:
                continue
            }
        }
    }

    /// The reason a provider that stops sending before any content falls back with.
    private static let idleReason = "provider idle timeout"

    private func idleWatchdog(_ call: UpstreamCall) -> Task<Void, Never> {
        Self.watchdog(call, seconds: context.limits.providerIdleDeadline, reason: Self.idleReason)
    }

    /// Fails `call` with `reason` once `seconds` pass with no event from it;
    /// every event re-arms the deadline. Cancel the task to stop watching.
    private static func watchdog(_ call: UpstreamCall, seconds: TimeInterval, reason: String) -> Task<Void, Never> {
        Task {
            let allowance = Duration.seconds(max(0, seconds))
            while !Task.isCancelled {
                let progress = call.progress
                let deadline = progress.at + allowance
                guard ContinuousClock.now >= deadline else {
                    try? await Task.sleep(until: deadline, clock: .continuous)
                    continue
                }
                call.fail(reason, unlessProgressSince: progress.count)
                return
            }
        }
    }

    /// Whether translated SSE `data` holds an `event: <name>` line. A JSON
    /// payload cannot hold a raw newline, so only event lines match.
    private static func hasEvent(_ name: String, in data: Data) -> Bool {
        let line = Data("event: \(name)\n".utf8)
        return data.starts(with: line) || data.range(of: Data("\n".utf8) + line) != nil
    }

    /// Sends translated bytes, then shows them to the reader. Nothing to send is success.
    private func emit(_ data: Data, chunked: Bool, reader: AnthropicResponseReader) async -> Bool {
        guard !data.isEmpty else { return true }
        guard await send(chunked ? Self.chunk(data) : data) else { return false }
        reader.consume(data)
        return true
    }

    /// Whether `status` earns one more send, and why; nil relays it. The
    /// model revert comes first: it never consumes the account retry.
    private func resend(after status: Int, plan: ExchangePlan, model: ModelPlan, accountRetried: Bool) -> Resend? {
        if model.routedModel != nil, Self.revertStatuses.contains(status) { return .revertModel }
        if !accountRetried, let account = plan.account, Self.retryStatuses.contains(status),
           context.planner.allowsRetry() {
            return .account(account)
        }
        return nil
    }

    /// An HTTP/1.1 client gets a chunked body; an HTTP/1.0 client, which
    /// cannot read chunked framing, gets the body unframed and delimited by
    /// the close. Either way `Connection: close`: one request per connection.
    private func relay(
        _ call: UpstreamCall, head upstreamHead: UpstreamHead, request: RouterRequestHead
    ) async -> Outcome {
        let streaming = upstreamHead.headers["content-type"]?.lowercased().contains("text/event-stream") == true
        // Passive: it sees exactly the bytes the client is sent, and changes none.
        let reader = AnthropicResponseReader(streaming: streaming)
        var outcome = await stream(call, head: upstreamHead, request: request, reader: reader)
        outcome.absorb(reader)
        return outcome
    }

    private func stream(
        _ call: UpstreamCall, head upstreamHead: UpstreamHead, request: RouterRequestHead,
        reader: AnthropicResponseReader
    ) async -> Outcome {
        var outcome = Outcome(quota: RouterHeaders.quotaColumns(upstreamHead.headers))
        let hasBody = RouterHeaders.hasBody(method: request.method, status: upstreamHead.status)
        let chunked = hasBody && request.version != "HTTP/1.0"
        var text = "HTTP/1.1 \(upstreamHead.status) \(RouterHeaders.reasonPhrase(upstreamHead.status))\r\n"
        for field in RouterHeaders.responseFields(upstreamHead.headers) { text += "\(field.name): \(field.value)\r\n" }
        if chunked { text += "Transfer-Encoding: chunked\r\n" }
        text += "Connection: close\r\n\r\n"
        guard await send(Data(text.utf8)) else {
            call.cancel()
            return gone(outcome)
        }
        call.allowBody()
        while true {
            guard let event = await call.next() else { return gone(outcome) }
            switch event {
            case .body(let data):
                guard hasBody, !data.isEmpty else { continue }
                guard await send(chunked ? Self.chunk(data) : data) else {
                    call.cancel()
                    return gone(outcome)
                }
                // Only what the client was sent.
                reader.consume(data)
            case .finished:
                if chunked, !(await send(Data("0\r\n\r\n".utf8))) { return gone(outcome) }
                outcome.status = upstreamHead.status
                return outcome
            case .failed(let reason):
                if isClientGone { return gone(outcome) }
                outcome.status = upstreamHead.status
                outcome.error = AccountRouterLog.scrub("upstream failed mid-stream: \(reason)")
                return outcome
            case .head:
                continue
            }
        }
    }

    private static func chunk(_ data: Data) -> Data {
        var frame = Data((String(data.count, radix: 16) + "\r\n").utf8)
        frame.append(data)
        frame.append(contentsOf: [13, 10])
        return frame
    }

    private func sendUnreachable() async {
        let head = "HTTP/1.1 502 Bad Gateway\r\nContent-Type: application/json\r\n"
            + "Content-Length: \(Self.unreachableBody.count)\r\nConnection: close\r\n\r\n"
        _ = await send(Data(head.utf8) + Self.unreachableBody)
    }

    private func gone(_ outcome: Outcome) -> Outcome {
        var result = outcome
        result.status = nil
        result.error = "client disconnected"
        return result
    }

    // MARK: - Recording

    private func record(
        head: RouterRequestHead, plan: ExchangePlan, model: ModelPlan, outcome: Outcome, started: Date
    ) {
        // A provider served it (or failed mid-reply): no account spent anything.
        let route = model.providerRoute
        // A provider's headers (even an Anthropic-wire one) say nothing about any account's quota or org.
        let quota = route == nil ? outcome.quota : RouterHeaders.QuotaColumns()
        let row = AccountRouterExchange(
            startedAt: started,
            durationMs: Int(Date().timeIntervalSince(started) * 1000),
            sessionId: head.value(RouterHeaders.sessionHeader),
            method: head.method,
            path: head.path,
            status: outcome.status,
            account: route == nil ? plan.account : nil,
            routingRule: plan.rule,
            fiveHourUtilization: quota.fiveHour,
            sevenDayUtilization: quota.sevenDay,
            fiveHourStatus: quota.fiveHourStatus,
            sevenDayStatus: quota.sevenDayStatus,
            organizationId: quota.organizationId,
            error: outcome.error,
            requestedModel: model.requestedModel,
            routedModel: model.routedModel,
            servedModel: outcome.servedModel,
            modelRule: model.rule,
            provider: route?.name,
            threadKind: model.thread?.rawValue,
            writes: model.writes,
            inputTokens: outcome.inputTokens,
            outputTokens: outcome.outputTokens,
            cacheReadTokens: outcome.cacheReadTokens,
            cacheCreationTokens: outcome.cacheCreationTokens,
            stopReason: outcome.stopReason)
        context.record(row)
    }

    // MARK: - Client side

    private var isClientGone: Bool { lock.withLock { clientGone } }

    /// Makes `call` the one a hang-up cancels; false if the client already left.
    private func begin(_ call: UpstreamCall) -> Bool {
        lock.withLock {
            guard !clientGone else { return false }
            current = call
            return true
        }
    }

    /// One request per connection, so the next thing the client can send is
    /// EOF. A FIN counts as leaving: TCP cannot tell a half-close from a full
    /// close at this point, and the spec requires a client that disconnects to
    /// cancel its upstream call, so half-closing after the request is not
    /// supported. (Claude Code never half-closes.)
    ///
    /// The budget wait's watch may have read the end already, or still have a
    /// receive outstanding: the first counts at once, and the second is
    /// handed this watch's job rather than raced by a second receive.
    private func watchForHangUp() {
        let (alreadyGone, handedOff) = lock.withLock { () -> (Bool, Bool) in
            if early.chunks.contains(where: { $0.1 || $0.2 != nil }) { return (true, false) }
            early.chunks.removeAll()
            if early.outstanding {
                early.handOff = true
                return (false, true)
            }
            return (false, false)
        }
        if alreadyGone { return markClientGone() }
        if handedOff { return }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] _, _, isComplete, error in
            guard let self else { return }
            if isComplete || error != nil {
                self.markClientGone()
            } else {
                self.watchForHangUp()
            }
        }
    }

    /// The client left: no new upstream call begins, and the current one is cancelled.
    private func markClientGone() {
        let call = lock.withLock { () -> UpstreamCall? in
            clientGone = true
            return current
        }
        call?.cancel()
    }

    private func armIdleTimer() {
        let item = dropAfter(context.limits.idleTimeout)
        lock.withLock { idleTimer = item }
    }

    private func disarmIdleTimer() {
        lock.withLock {
            idleTimer?.cancel()
            idleTimer = nil
        }
    }

    private func armDeadline(_ seconds: TimeInterval) {
        let item = dropAfter(max(0, seconds))
        lock.withLock { deadlineTimer = item }
    }

    private func disarmDeadline() {
        lock.withLock {
            deadlineTimer?.cancel()
            deadlineTimer = nil
        }
    }

    /// Drops the exchange after `seconds` unless the returned item is cancelled
    /// first: the connection is cancelled (failing any pending receive or
    /// send) and so is the task (ending any wait for budget), so the slot and
    /// budget are released.
    private func dropAfter(_ seconds: TimeInterval) -> DispatchWorkItem {
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.connection.cancel()
            self.lock.withLock { self.task }?.cancel()
        }
        queue.asyncAfter(deadline: .now() + seconds, execute: item)
        return item
    }

    /// The next read: one the hang-up watch already took, the watch's
    /// outstanding receive, or a fresh one.
    private func receive() async -> Read {
        await withCheckedContinuation { continuation in
            let next = lock.withLock { () -> NextRead in
                if !early.chunks.isEmpty { return .ready(early.chunks.removeFirst()) }
                if early.outstanding {
                    early.reader = continuation
                    return .parked
                }
                return .fresh
            }
            switch next {
            case .ready(let read):
                continuation.resume(returning: read)
            case .parked:
                break
            case .fresh:
                connection.receive(minimumIncompleteLength: 1,
                                   maximumLength: Self.receiveMax) { data, _, isComplete, error in
                    continuation.resume(returning: (data, isComplete, error))
                }
            }
        }
    }

    /// Watches for the client hanging up while the request waits for body
    /// budget, and cancels the wait when it does (the same task cancellation
    /// the deadlines use), so a client that gave up stops holding a slot and
    /// a place in the queue. What it reads is the request's own bytes, kept
    /// for the reader. It reads at most ``receiveMax`` bytes: seeing the
    /// hang-up of a client with more body still unread would mean holding that
    /// body without budget, so such a client is seen leaving only once its
    /// wait ends. A live client is never failed: only an end of stream with
    /// no data, or an error, counts as leaving.
    private func watchWhileWaiting() {
        lock.withLock {
            early.watching = true
            early.outstanding = true
        }
        watchReceive()
    }

    /// One receive of the watch. `early.outstanding` is already set; it is
    /// cleared in the same locked step that hands the read on, and set again
    /// there when the watch reads once more, so the reader never sees a gap.
    private func watchReceive() {
        connection.receive(minimumIncompleteLength: 1,
                           maximumLength: Self.receiveMax) { [weak self] data, _, done, error in
            guard let self else { return }
            let read: Read = (data, done, error)
            let leftEmpty = error != nil || (done && (data?.isEmpty ?? true))
            let step = self.lock.withLock { () -> WatchStep in
                self.early.outstanding = false
                if let reader = self.early.reader {
                    self.early.reader = nil
                    return .toReader(reader)
                }
                if self.early.handOff {
                    self.early.handOff = false
                    return .toHangUpWatch
                }
                self.early.chunks.append(read)
                self.early.bytes += data?.count ?? 0
                if self.early.watching && leftEmpty {
                    self.clientGone = true
                    return .hungUp
                }
                if self.early.watching && !done && error == nil && self.early.bytes < Self.receiveMax {
                    self.early.outstanding = true
                    return .again
                }
                return .stop
            }
            switch step {
            case .toReader(let reader):
                reader.resume(returning: read)
            case .toHangUpWatch:
                // After the request, as `watchForHangUp` reads: a FIN or an
                // error is leaving, and anything else is ignored.
                if done || error != nil { self.markClientGone() } else { self.watchForHangUp() }
            case .hungUp:
                self.lock.withLock { self.task }?.cancel()
            case .again:
                self.watchReceive()
            case .stop:
                break
            }
        }
    }

    /// The wait is over: the watch stops reading, and anything it read or is
    /// still reading goes to the reader.
    private func stopWatchingWhileWaiting() {
        lock.withLock { early.watching = false }
    }

    /// false if the client is gone, or made no progress reading for
    /// `sendStallTimeout` (the exchange is then dropped).
    private func send(_ data: Data) async -> Bool {
        let stall = dropAfter(context.limits.sendStallTimeout)
        defer { stall.cancel() }
        return await withCheckedContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { error in
                continuation.resume(returning: error == nil)
            })
        }
    }

    /// FIN after everything queued, then release the connection. A client
    /// that is not reading cannot hold this open past `sendStallTimeout`.
    private func close() async {
        let stall = dropAfter(context.limits.sendStallTimeout)
        defer { stall.cancel() }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            connection.send(content: nil, contentContext: .finalMessage, isComplete: true,
                            completion: .contentProcessed { _ in continuation.resume() })
        }
        connection.cancel()
    }
}
#endif
