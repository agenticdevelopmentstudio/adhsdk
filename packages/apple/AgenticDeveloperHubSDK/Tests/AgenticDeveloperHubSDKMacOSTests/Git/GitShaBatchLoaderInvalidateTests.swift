import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Answers from a table a test changes between batches, recording every batch asked for.
private actor ChangingAnswers {
    private(set) var batches: [[String]] = []
    var answers: [String: String] = [:]
    func set(_ sha: String, _ value: String?) { answers[sha] = value }
    func answer(_ batch: [String]) -> [String: String] {
        batches.append(batch)
        return answers.filter { batch.contains($0.key) }
    }
}

/// `GitShaBatchLoader.invalidate()`, for values that change after they load (reviews).
@MainActor
@Suite("GitShaBatchLoader invalidate")
struct GitShaBatchLoaderInvalidateTests {
    private func loader(_ answers: ChangingAnswers, onLoad: @escaping @MainActor () -> Void = {})
        -> GitShaBatchLoader<String> {
        GitShaBatchLoader<String>(delay: .milliseconds(20), provider: { batch in
            await answers.answer(batch)
        }, onLoad: onLoad)
    }

    private func settle(_ loader: GitShaBatchLoader<String>) async {
        await loader.queueTask?.value
        await loader.loadTask?.value
    }

    @Test("after invalidate a cached value stays readable, then is replaced by the next batch")
    func replaces() async {
        let answers = ChangingAnswers()
        await answers.set("a1", "queued")
        var loads = 0
        let loader = loader(answers) { loads += 1 }
        loader.request(["a1"])
        await settle(loader)
        #expect(loader.value(for: "a1") == "queued")

        await answers.set("a1", "done")
        loader.invalidate()
        #expect(loader.value(for: "a1") == "queued")
        loader.request(["a1"])
        await settle(loader)
        #expect(loader.value(for: "a1") == "done")
        #expect(await answers.batches == [["a1"], ["a1"]])
        #expect(loads == 2)
    }

    @Test("a stale value the next batch no longer answers is removed, and onLoad still runs")
    func removes() async {
        let answers = ChangingAnswers()
        await answers.set("a1", "done")
        var loads = 0
        let loader = loader(answers) { loads += 1 }
        loader.request(["a1"])
        await settle(loader)
        await answers.set("a1", nil)
        loader.invalidate()
        loader.request(["a1"])
        await settle(loader)
        #expect(loader.value(for: "a1") == nil)
        #expect(loads == 2)
    }

    @Test("after invalidate a re-answer equal to the cached value does not run onLoad")
    func identicalReanswer() async {
        let answers = ChangingAnswers()
        await answers.set("a1", "done")
        var loads = 0
        let loader = loader(answers) { loads += 1 }
        loader.request(["a1"])
        await settle(loader)
        #expect(loads == 1)

        loader.invalidate()
        loader.request(["a1"])
        await settle(loader)
        #expect(await answers.batches == [["a1"], ["a1"]])
        #expect(loader.value(for: "a1") == "done")
        #expect(loads == 1)
    }

    @Test("a sha that was unanswered is asked for again after invalidate")
    func asksUnansweredAgain() async {
        let answers = ChangingAnswers()
        let loader = loader(answers)
        loader.request(["a1"])
        await settle(loader)
        loader.request(["a1"])
        await settle(loader)
        #expect(await answers.batches == [["a1"]])

        await answers.set("a1", "queued")
        loader.invalidate()
        loader.request(["a1"])
        await settle(loader)
        #expect(loader.value(for: "a1") == "queued")
        #expect(await answers.batches == [["a1"], ["a1"]])
    }

    @Test("without invalidate a cached sha is never asked for again")
    func cachedWithoutInvalidate() async {
        let answers = ChangingAnswers()
        await answers.set("a1", "queued")
        let loader = loader(answers)
        loader.request(["a1"])
        await settle(loader)
        await answers.set("a1", "done")
        loader.request(["a1"])
        await settle(loader)
        #expect(loader.value(for: "a1") == "queued")
        #expect(await answers.batches == [["a1"]])
    }
}
