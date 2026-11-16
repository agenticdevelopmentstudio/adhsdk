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
        #expect(await recorder.batches == [["a1", "b2", "c3"]])
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
}
