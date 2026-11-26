import Foundation
import MCP
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `MCPClient` owns the MCP server process transitively — `SubprocessTransport`
/// spawns and reaps it, and this client is the only thing holding the
/// transport. That makes the client, not the transport, where a
/// connect/disconnect race can strand a process: the transport's own tri-state
/// guard covers the window *inside* `SubprocessTransport.connect()`, and
/// `MCPClient.connect()` opens a wider one above it.
///
/// The probes drive a real child (a shell loop that never answers `initialize`,
/// so a connect stays in flight for as long as the race needs) and find it with
/// `pgrep -f` on a UUID in its `argv`, because in the failing case nothing ever
/// reads its stdout and a pid it printed would never be collected.
///
/// `.serialized` because these count processes by name across the whole
/// machine, and because the failure they look for is timing-shaped.
@Suite("MCPClient connect/disconnect race", .serialized)
struct MCPClientRaceTests {

    private static let markerCommand = "while :; do sleep 0.05; done"

    private func makeClient(marker: String) -> MCPClient {
        MCPClient(
            configuration: MCPServerConfiguration(
                name: "race-probe",
                transport: .stdio(
                    command: "/bin/sh",
                    arguments: ["-c", Self.markerCommand, marker],
                    environment: [:]
                )
            )
        )
    }

    /// The production shape, from `MCPServerRegistry.reconcile`: connect and
    /// disconnect are each started in their own unstructured `Task`, and the
    /// registry drops its reference to the client the moment the disconnect is
    /// queued. Nothing here awaits the connect, for the same reason the
    /// registry does not — which is exactly what makes a stranded child
    /// permanent rather than merely late.
    ///
    /// Two orderings have to come out the same way, and they are closed by
    /// different halves of the fix:
    ///
    /// - The connect is in flight when the disconnect lands. `connectTask` is
    ///   what covers this: `teardown()` cancels it, unwedges it through
    ///   `MCP.Client.disconnect()`, waits for it, and only then reads
    ///   `self.transport` — so the spawn has either happened and is reaped, or
    ///   been ruled out.
    /// - The disconnect runs to completion before `connect()` enters the actor
    ///   at all. There is no task to hold, and `teardown()` correctly finds
    ///   nothing; `isShutDown` is what covers this, by making the connect that
    ///   arrives afterwards throw instead of spawning.
    ///
    /// Iterated because which of the two happens is a scheduling accident, and
    /// the assertion has to hold for both. If this ever flakes, raise the
    /// iteration count — the failure mode is missing an ordering, never
    /// inventing one.
    @Test("a disconnect racing a connect never strands the server process")
    func disconnectRacingConnectStopsTheChild() async throws {
        let batch = "MCPClientRaceProbe-\(UUID().uuidString)"
        var pending: [Task<Void, Never>] = []
        defer { for task in pending { task.cancel() } }

        for iteration in 0..<20 {
            let client = makeClient(marker: "\(batch)-\(iteration)")
            // Deliberately not awaited: see the doc comment. A connect that
            // loses this race is left parked exactly as the registry would
            // leave it.
            pending.append(Task { try? await client.connect() })
            await client.disconnect()
        }

        let survivors = try await Self.survivors(of: batch)
        // Kill before asserting: a failure here means real orphans, and leaving
        // them running would outlive the whole test run.
        for pid in survivors { kill(pid, SIGKILL) }
        #expect(
            survivors.isEmpty,
            "a disconnect racing connect() left MCP servers running (pids \(survivors))"
        )
    }

    /// The sequential half of the same guarantee, and the one that proves the
    /// probe can see a child at all: here the spawn is waited for before the
    /// disconnect, so a surviving process is unambiguous.
    ///
    /// It also pins that `teardown()` can reap a connect that is *parked* —
    /// this server never answers `initialize`, and `MCP.Client.send` waits on a
    /// continuation with no cancellation handler, so cancelling the connect
    /// task cannot free it. Only `MCP.Client.disconnect()` can, which is why
    /// `teardown()` calls it before it waits.
    @Test("a connect that never finishes initializing is still reaped by disconnect")
    func parkedConnectIsStillReapedByDisconnect() async throws {
        let marker = "MCPClientTeardownProbe-\(UUID().uuidString)"
        let client = makeClient(marker: marker)

        let connecting = Task { try? await client.connect() }
        // Matches the three siblings below: `connecting` never finishes on its
        // own, so it needs cancelling on every exit path, including the
        // `#require` below failing before `disconnect()` is ever reached.
        defer { connecting.cancel() }

        do {
            // Wait for the spawn rather than for the connect: the connect cannot
            // finish, because the child never answers `initialize`.
            var spawned = try Self.processesMatching(marker)
            for _ in 0..<50 where spawned.isEmpty {
                try await Task.sleep(for: .milliseconds(50))
                spawned = try Self.processesMatching(marker)
            }
            try #require(!spawned.isEmpty, "the probe server never started")
        } catch {
            // `#require` throws to fail fast, but a real child may already be
            // running by then — `disconnect()` is the only thing that reaps it,
            // so it has to run here too, not just on the success path below.
            await client.disconnect()
            let orphans = (try? await Self.survivors(of: marker)) ?? []
            for pid in orphans { kill(pid, SIGKILL) }
            throw error
        }

        await client.disconnect()
        // Bounded by the disconnect above having already unwedged it.
        await connecting.value

        let survivors = try await Self.survivors(of: marker)
        for pid in survivors { kill(pid, SIGKILL) }
        #expect(
            survivors.isEmpty,
            "disconnect() left an unresponsive MCP server running (pids \(survivors))"
        )
    }

    /// Disconnection is terminal, and the sequential case is the readable
    /// statement of what the racing case relies on: a `connect()` that arrives
    /// after a completed `disconnect()` must not spawn a server, because the
    /// owner that would reap it has already been let go.
    @Test("connect after disconnect throws instead of starting a second server")
    func connectAfterDisconnectThrows() async throws {
        let marker = "MCPClientTerminalProbe-\(UUID().uuidString)"
        let client = makeClient(marker: marker)

        await client.disconnect()
        await #expect(throws: MCPClientError.clientHasBeenDisconnected) {
            try await client.connect()
        }

        let survivors = try Self.processesMatching(marker)
        for pid in survivors { kill(pid, SIGKILL) }
        #expect(
            survivors.isEmpty,
            "connect() after disconnect() started a server anyway (pids \(survivors))"
        )
        let state = await client.state
        #expect(state == .disconnected)
    }

    /// The ordering that `teardown()`'s steps 2 and 3 cannot reach: a connect
    /// suspended between publishing `self.transport` and
    /// `MCP.Client.connect(transport:)`. Step 2 finds that transport still
    /// idle and step 3 a client with no connection, so neither leaves a mark
    /// the connect will notice; the connect then resumes, spawns, and parks on
    /// `initialize`'s bare continuation, with step 3's `Client.disconnect()`
    /// already spent. Unbounded, step 4's wait on that task never returns — so
    /// `disconnect()` never returns, and steps 5 and 6, the lines written to
    /// reap this exact child and to free this exact task, are never reached.
    ///
    /// The seam is what makes the window addressable. It is a single
    /// cross-actor hop, closing in microseconds, and every reproduction of
    /// this defect so far has come from hand-patching a delay into
    /// `MCPClient` — which is not something CI can do.
    ///
    /// Two assertions, because the bug has two halves: a `disconnect()` that
    /// never returns, and a server that outlives the app.
    @Test("disconnect() gives up on a wedged connect rather than hanging, and still reaps its child")
    func teardownAbandonsAWedgedConnectAndStillReapsTheChild() async throws {
        let marker = "MCPClientWedgedConnectProbe-\(UUID().uuidString)"
        let client = makeClient(marker: marker)
        let reachedTheWindow = ConnectWindowGate()
        let leaveTheWindow = ConnectWindowGate()

        await client.setConnectSuspensionHook { point in
            guard case .beforeTransportConnect = point else { return }
            reachedTheWindow.open()
            // Deliberately not `Task.sleep`: `teardown()`'s step 1 cancels
            // this task, and a sleep would then return *immediately*, closing
            // the window this test exists to hold open. A checked continuation
            // ignores cancellation, which is exactly the property needed.
            await leaveTheWindow.wait()
        }

        // Never awaited, and beyond rescue by cancellation: this connect parks
        // on `initialize` for the life of the process, exactly as the registry
        // would leave it.
        let connecting = Task { try? await client.connect() }
        defer { connecting.cancel() }
        await reachedTheWindow.wait()

        let disconnecting = Task { await client.disconnect() }
        // Long enough for steps 1-3 to run to completion, and short enough
        // that the spawn lands well inside the budget step 4 is now spending.
        try await Task.sleep(for: .milliseconds(250))
        leaveTheWindow.open()
        let returned = await Self.completes(disconnecting, within: 8)

        let survivors = try await Self.survivors(of: marker)
        for pid in survivors { kill(pid, SIGKILL) }
        #expect(
            returned,
            "disconnect() never returned — teardown() is waiting on a connect nothing can free"
        )
        #expect(
            survivors.isEmpty,
            "teardown() left the child of an abandoned connect running (pids \(survivors))"
        )
    }

    /// The `connectTask` half of the fix, which nothing else pins. Before this
    /// test existed, deleting both of `teardown()`'s `connectTask` statements
    /// left the whole suite green, so a later simplification could have
    /// dropped them on a clean build.
    ///
    /// Step 1's `cancel()` is synchronous, so a connect task that has not yet
    /// reached its own `Task.checkCancellation()` never builds a transport and
    /// never spawns; step 4 then waits for that to take effect. `isShutDown`
    /// cannot reach this ordering — the connect is already past that guard —
    /// and steps 2, 3 and 5 all find `self.transport` still nil at the moment
    /// they run, while step 6 finds a client with no connection. So with
    /// neither `connectTask` statement present nothing in `teardown()` is left
    /// that could reap what the connect goes on to spawn.
    ///
    /// What this pins is therefore the **pair**, which is the deletion that
    /// strands a child permanently. Removing only the `cancel()` no longer
    /// strands anything — step 4's budget expires and step 5 reaps the child a
    /// second late — but it is not silent either, because `outcome` below pins
    /// it on its own: with step 1's `cancel()` present the connect throws at
    /// `Task.checkCancellation()`, so `outcome` is a `CancellationError`.
    /// Without it, the connect runs on, builds the transport, spawns, and
    /// parks on `initialize`'s bare continuation, and is later freed by step
    /// 6's `pendingRequests` drain with `MCPError.internalError("Client
    /// disconnected")` instead. Two different error *types* is the pin — no
    /// wall clock, no timing threshold. (The timings still move too — 0.30 s
    /// to 1.07 s for this test — but that is no longer the only signal.)
    @Test("a connect cancelled before it builds a transport never spawns a server")
    func connectCancelledBeforeItBuildsATransportNeverSpawns() async throws {
        let marker = "MCPClientCancelledConnectProbe-\(UUID().uuidString)"
        let client = makeClient(marker: marker)
        let reachedTheWindow = ConnectWindowGate()
        let leaveTheWindow = ConnectWindowGate()

        await client.setConnectSuspensionHook { point in
            guard case .beforeCancellationCheck = point else { return }
            reachedTheWindow.open()
            await leaveTheWindow.wait()
        }

        let connecting = Task { () -> (any Error)? in
            do { try await client.connect(); return nil } catch { return error }
        }
        defer { connecting.cancel() }
        await reachedTheWindow.wait()

        let disconnecting = Task { await client.disconnect() }
        // Step 1's `cancel()` lands before `teardown()`'s first suspension, so
        // this only has to be long enough for `disconnect()` to be entered.
        try await Task.sleep(for: .milliseconds(250))
        leaveTheWindow.open()
        let returned = await Self.completes(disconnecting, within: 8)
        let outcome = await Self.outcome(connecting, within: 8)

        let survivors = try await Self.survivors(of: marker)
        for pid in survivors { kill(pid, SIGKILL) }
        #expect(returned, "disconnect() never returned")
        #expect(
            outcome is CancellationError,
            "step 1's cancel() did not stop the connect before it built a transport"
        )
        #expect(
            survivors.isEmpty,
            "a connect cancelled before its transport existed spawned a server anyway (pids \(survivors))"
        )
    }

    /// M2: an abandoned connect must be *freed*, not merely walked away from.
    ///
    /// Same ordering as the test above — step 4 gives up on a connect wedged on
    /// `initialize`'s bare continuation — but what this pins is step 6, not the
    /// budget. Without step 6 the abandoned `MCP.Client` keeps a message-handling
    /// loop whose stream step 5 has already finished, so every iteration of it
    /// returns at once and the `repeat … while true` spins for the life of the
    /// process. Measured with step 6 deleted, the busiest thread spent 1.02
    /// CPU-seconds of a 1.0 s window: one core, pinned.
    ///
    /// Two assertions, because one is the mechanism and one is the symptom.
    /// `freed` is deterministic and carries the weight: step 6 drains
    /// `pendingRequests`, which resumes the wedged `initialize` with `Client
    /// disconnected`, so the connect task completes. Without step 6 nothing in
    /// the process can resume a bare `withCheckedThrowingContinuation`, so it
    /// never completes at any budget — this is a wait-for-completion assertion,
    /// not a timing one.
    ///
    /// `burn` is the symptom: the most CPU any one thread of this process spent
    /// in a 1.0 s window. A spinning loop keeps a thread busy for the whole
    /// window. Whole-process CPU (`RUSAGE_SELF`) cannot tell that apart from
    /// ordinary work, because `.serialized` orders this suite's own tests only:
    /// every other suite in the bundle shares this `xctest` process and runs
    /// alongside it, and inside the full parallel suite their CPU read 0.28
    /// against a 0.25 ceiling with the fix in place. One thread's share is
    /// what a spin changes and concurrent tests do not: they spread across
    /// the pool and finish in milliseconds.
    @Test("an abandoned connect is freed rather than left spinning a core")
    func teardownFreesTheAbandonedConnectRatherThanSpinning() async throws {
        let marker = "MCPClientAbandonedConnectProbe-\(UUID().uuidString)"
        let client = makeClient(marker: marker)
        let reachedTheWindow = ConnectWindowGate()
        let leaveTheWindow = ConnectWindowGate()

        await client.setConnectSuspensionHook { point in
            guard case .beforeTransportConnect = point else { return }
            reachedTheWindow.open()
            await leaveTheWindow.wait()
        }

        let connecting = Task { try? await client.connect() }
        defer { connecting.cancel() }
        await reachedTheWindow.wait()

        let disconnecting = Task { await client.disconnect() }
        try await Task.sleep(for: .milliseconds(250))
        leaveTheWindow.open()
        let returned = await Self.completes(disconnecting, within: 8)

        // Whatever step 6 was supposed to stop is running right now.
        let before = Self.threadCPUSeconds()
        try await Task.sleep(for: .seconds(1))
        let burn = Self.busiestThreadCPUSeconds(since: before)

        let freed = await Self.completes(connecting, within: 5)

        let survivors = try await Self.survivors(of: marker)
        for pid in survivors { kill(pid, SIGKILL) }
        #expect(returned, "disconnect() never returned")
        #expect(
            freed,
            "teardown() left the abandoned connect wedged - nothing resumed initialize"
        )
        #expect(
            burn < Self.abandonedConnectCPUCeiling,
            """
            an abandoned connect is still burning CPU after disconnect() returned \
            (one thread spent \(burn) CPU-seconds of a 1.0 s window; ceiling \(Self.abandonedConnectCPUCeiling))
            """
        )
    }

    /// The most CPU one thread may spend in the test's 1.0 s window. A spin
    /// pins a thread at close to 1.0; with the fix, no thread comes near half.
    private static let abandonedConnectCPUCeiling = 0.5

    /// User+system CPU each live thread of this process has consumed, keyed by
    /// its system-wide thread id, so a pool thread is matched across the two
    /// readings and one that started between them counts from zero.
    private static func threadCPUSeconds() -> [UInt64: Double] {
        var threads: thread_act_array_t?
        var count: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threads, &count) == KERN_SUCCESS, let threads else { return [:] }
        defer {
            for index in 0..<Int(count) { mach_port_deallocate(mach_task_self_, threads[index]) }
            let size = vm_size_t(Int(count) * MemoryLayout<thread_act_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threads)), size)
        }
        var readings: [UInt64: Double] = [:]
        for index in 0..<Int(count) {
            guard let identifier = threadIdentifier(threads[index]),
                  let seconds = threadSeconds(threads[index]) else { continue }
            readings[identifier] = seconds
        }
        return readings
    }

    /// The largest CPU any one thread spent since `before`.
    private static func busiestThreadCPUSeconds(since before: [UInt64: Double]) -> Double {
        threadCPUSeconds().map { identifier, seconds in seconds - (before[identifier] ?? 0) }.max() ?? 0
    }

    private static func threadIdentifier(_ thread: thread_act_t) -> UInt64? {
        var info = thread_identifier_info_data_t()
        var size = mach_msg_type_number_t(
            MemoryLayout<thread_identifier_info_data_t>.size / MemoryLayout<natural_t>.size)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                thread_info(thread, thread_flavor_t(THREAD_IDENTIFIER_INFO), $0, &size)
            }
        }
        return status == KERN_SUCCESS ? info.thread_id : nil
    }

    private static func threadSeconds(_ thread: thread_act_t) -> Double? {
        var info = thread_basic_info_data_t()
        var size = mach_msg_type_number_t(MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<natural_t>.size)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                thread_info(thread, thread_flavor_t(THREAD_BASIC_INFO), $0, &size)
            }
        }
        guard status == KERN_SUCCESS else { return nil }
        let user = Double(info.user_time.seconds) + Double(info.user_time.microseconds) / 1_000_000
        let system = Double(info.system_time.seconds) + Double(info.system_time.microseconds) / 1_000_000
        return user + system
    }

    /// Awaits `task`, giving up after `seconds` rather than hanging the whole
    /// run. `withWallClockBudget` cancels the loser without awaiting it, so a
    /// `disconnect()` that never returns costs this many seconds and no more —
    /// the same property the fix under test relies on.
    ///
    /// Generic over the task's success type because the abandoned connect task
    /// below is `Task<()?, Never>`, not `Task<Void, Never>`.
    private static func completes<S: Sendable>(_ task: Task<S, Never>, within seconds: TimeInterval) async -> Bool {
        do {
            try await withWallClockBudget(seconds) { _ = await task.value }
            return true
        } catch {
            return false
        }
    }

    /// The error `task` ended with, or `nil`, giving up after `seconds`.
    private static func outcome(
        _ task: Task<(any Error)?, Never>,
        within seconds: TimeInterval
    ) async -> (any Error)? {
        do { return try await withWallClockBudget(seconds) { await task.value } } catch { return error }
    }

    /// The pids matching `marker` once they have had a fair chance to exit —
    /// `terminate()` signals a child, it does not reap it synchronously, so a
    /// pid seen immediately after one is not yet evidence of a leak.
    private static func survivors(of marker: String) async throws -> [pid_t] {
        var found = try processesMatching(marker)
        for _ in 0..<50 where !found.isEmpty {
            try await Task.sleep(for: .milliseconds(50))
            found = try processesMatching(marker)
        }
        return found
    }

    /// The pids whose full command line contains `marker`. `pgrep` never
    /// matches itself, so the marker in its own `argv` is not a false hit.
    private static func processesMatching(_ marker: String) throws -> [pid_t] {
        let pgrep = Process()
        pgrep.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        pgrep.arguments = ["-f", marker]
        let output = Pipe()
        pgrep.standardOutput = output
        pgrep.standardError = Pipe()
        try pgrep.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        pgrep.waitUntilExit()
        return (String(bytes: data, encoding: .utf8) ?? "")
            .split(separator: "\n")
            .compactMap { pid_t($0.trimmingCharacters(in: .whitespaces)) }
    }
}

/// A one-shot, **cancellation-proof** gate: `wait()` suspends until `open()`,
/// and an `open()` that arrives first makes the wait return at once.
///
/// Cancellation-proof is the whole point. The tasks these tests hold open are
/// exactly the ones `MCPClient.teardown()` cancels, so anything cancellable —
/// `Task.sleep`, an `AsyncStream` iteration — would spring open the moment
/// step 1 fires and close the very window under test.
/// `withCheckedContinuation` is unaffected by cancellation.
///
/// `@unchecked Sendable` because the lock, not the compiler, is what makes the
/// resume-exactly-once and open-before-wait orderings hold.
private final class ConnectWindowGate: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if isOpen {
                lock.unlock()
                continuation.resume()
                return
            }
            self.continuation = continuation
            lock.unlock()
        }
    }

    func open() {
        lock.lock()
        let waiter = continuation
        continuation = nil
        isOpen = true
        lock.unlock()
        waiter?.resume()
    }
}
