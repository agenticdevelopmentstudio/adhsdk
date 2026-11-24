import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Records every batch a loader's provider is asked for.
private actor BatchRecorder {
    private(set) var batches: [[String]] = []
    func record(_ batch: [String]) { batches.append(batch) }
}

/// `GitShaBatchLoader`, the debounced, coalesced, cached per-sha loader the history's
/// signatures run through (ruling R1), with ruling R6's replacement.
@MainActor
@Suite("GitShaBatchLoader")
struct GitShaBatchLoaderTests {
    private func loader(_ recorder: BatchRecorder, answers: Set<String>? = nil,
                        onLoad: @escaping @MainActor () -> Void = {}) -> GitShaBatchLoader<String> {
        GitShaBatchLoader<String>(delay: .milliseconds(20), provider: { batch in
            await recorder.record(batch)
            var values: [String: String] = [:]
            for sha in batch where answers?.contains(sha) ?? true { values[sha] = "value-\(sha)" }
            return values
        }, onLoad: onLoad)
    }

    private func settle(_ loader: GitShaBatchLoader<String>) async {
        await loader.queueTask?.value
        await loader.loadTask?.value
    }

    @Test("two requests in one debounce window run one batch, the newer replacing the queued one")
    func coalesces() async {
        let recorder = BatchRecorder()
        var loads = 0
        let loader = loader(recorder) { loads += 1 }
        loader.request(["a1", "b2"])
        loader.request(["b2", "c3"])
        await settle(loader)

        #expect(await recorder.batches == [["b2", "c3"]])
        #expect(loader.batchCount == 1)
        #expect(loads == 1)
        #expect(loader.value(for: "b2") == "value-b2")
        #expect(loader.value(for: "c3") == "value-c3")
        #expect(loader.value(for: "a1") == nil)
    }

    @Test("cached shas are never asked for again, and a request of only cached shas runs nothing")
    func cached() async {
        let recorder = BatchRecorder()
        let loader = loader(recorder)
        loader.request(["a1"])
        await settle(loader)
        loader.request(["a1", "b2"])
        await settle(loader)
        loader.request(["a1", "b2"])
        await settle(loader)

        #expect(await recorder.batches == [["a1"], ["b2"]])
        #expect(loader.queueTask == nil)
    }

    @Test("a single-sha request outside the list joins the queued batch instead of replacing it")
    func addsWithoutReplacing() async {
        let recorder = BatchRecorder()
        let loader = loader(recorder)
        loader.request(["a1", "b2"])
        loader.request(["c3"], replacingQueued: false)
        await settle(loader)
        #expect(await recorder.batches == [["c3", "a1", "b2"]])
    }

    @Test("a list request never drops a queued single sha, even when every listed row is cached")
    func replacementKeepsSingleSha() async {
        let recorder = BatchRecorder()
        let loader = loader(recorder)
        loader.request(["a1", "b2"])
        await settle(loader)
        loader.request(["c3"], replacingQueued: false)
        loader.request(["a1", "b2"])
        await settle(loader)
        loader.request(["d4"], replacingQueued: false)
        loader.request(["e5"])
        await settle(loader)

        #expect(await recorder.batches == [["a1", "b2"], ["c3"], ["d4", "e5"]])
        #expect(loader.value(for: "c3") == "value-c3")
        #expect(loader.value(for: "d4") == "value-d4")
    }

    @Test("a failed batch's shas are left alone for the cooldown, then asked for again")
    func failureCooldown() async {
        let recorder = BatchRecorder()
        var failures = 0
        let loader = GitShaBatchLoader<String>(delay: .milliseconds(20), provider: { batch in
            await recorder.record(batch)
            throw CancellationError()
        }, onLoad: {}, onFailure: { _ in failures += 1 })
        loader.request(["a1", "b2"])
        await settle(loader)
        loader.request(["a1", "b2"])
        await settle(loader)
        #expect(await recorder.batches == [["a1", "b2"]])
        #expect(failures == 1)
        #expect(loader.queueTask == nil)

        loader.failureCooldown = .zero
        loader.request(["a1", "b2"])
        await settle(loader)
        #expect(await recorder.batches == [["a1", "b2"], ["a1", "b2"]])
        #expect(failures == 2)
    }

    @Test("a sha the batch did not answer is not asked for again, and no answer posts no load")
    func unanswered() async {
        let recorder = BatchRecorder()
        var loads = 0
        let loader = loader(recorder, answers: []) { loads += 1 }
        loader.request(["a1"])
        await settle(loader)
        loader.request(["a1"])
        await settle(loader)
        #expect(await recorder.batches == [["a1"]])
        #expect(loads == 0)
    }

    @Test("a batch due while another runs waits for it to land, so one batch runs at a time")
    func oneBatchAtATime() async {
        let recorder = BatchRecorder()
        let (gate, release) = AsyncStream<Void>.makeStream()
        let loader = GitShaBatchLoader<String>(delay: .milliseconds(20), provider: { batch in
            await recorder.record(batch)
            if batch == ["a1"] {
                for await _ in gate { break }
            }
            return Dictionary(uniqueKeysWithValues: batch.map { ($0, "value-\($0)") })
        }, onLoad: {})
        loader.request(["a1"])
        await loader.queueTask?.value
        let first = loader.loadTask
        loader.request(["b2"])
        await loader.queueTask?.value
        #expect(loader.batchCount == 1)
        #expect(loader.loadTask == first)

        release.yield()
        await first?.value
        await loader.loadTask?.value
        #expect(await recorder.batches == [["a1"], ["b2"]])
        #expect(loader.batchCount == 2)
        #expect(loader.value(for: "b2") == "value-b2")
    }
}
