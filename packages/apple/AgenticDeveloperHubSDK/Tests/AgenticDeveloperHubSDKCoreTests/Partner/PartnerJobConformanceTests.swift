import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Partner job conformance") struct PartnerJobConformanceTests {
    private static let stepOpen = PartnerJobStep(name: "open", environment: .terminal, command: "c1", condition: "k1")
    private static let stepReview = PartnerJobStep(name: "review", environment: .claude, command: "c2", condition: "k2")
    private static let stepFix = PartnerJobStep(name: "fix", environment: .claude, command: "c3", condition: "k3")
    private static var threeSteps: [PartnerJobStep] { [stepOpen, stepReview, stepFix] }

    private func job(guidelines: String = "g", steps: [PartnerJobStep] = threeSteps) -> PartnerJob {
        PartnerJob(id: "j", name: "J", isEnabled: true, guidelines: guidelines, steps: steps)
    }

    @Test("V1: job and step fields read back in order")
    func testV1_fieldsAndOrder() {
        let value = job()
        #expect(value.id == "j")
        #expect(value.name == "J")
        #expect(value.isEnabled)
        #expect(value.guidelines == "g")
        #expect(value.steps.map(\.name) == ["open", "review", "fix"])
        #expect(value.steps.count == 3)
        #expect(value.steps[0].environment == .terminal)
        #expect(value.steps[0].command == "c1")
        #expect(value.steps[0].condition == "k1")
    }

    @Test("V2: equal literals make equal jobs")
    func testV2_valueTypes() {
        #expect(job() == job())
        #expect(job().steps == job().steps)
    }

    @Test("V3: initializer defaults")
    func testV3_initializerDefaults() {
        let value = PartnerJob(id: "x", name: "X", isEnabled: true, guidelines: "g", steps: [])
        #expect(value.scheduleSeconds == nil)
        #expect(!value.isBuiltIn)
    }

    @Test("V4: a step encodes its environment and four keys")
    func testV4_stepEncoding() throws {
        let step = PartnerJobStep(name: "n", environment: .claude, command: "c", condition: "k")
        let data = try JSONEncoder().encode(step)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["environment"] as? String == "claude")
        #expect(Set(object.keys) == ["name", "environment", "command", "condition"])
    }

    @Test("V5: an unknown environment fails to decode")
    func testV5_unknownEnvironment() {
        let json = #"{"name":"n","environment":"shell","command":"c","condition":"k"}"#
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(PartnerJobStep.self, from: Data(json.utf8))
        }
    }

    @Test("V6: a missing scheduleSeconds decodes as nil")
    func testV6_missingSchedule() throws {
        let json = #"{"id":"j","name":"J","isEnabled":true,"guidelines":"g","steps":[],"isBuiltIn":false}"#
        let decoded = try JSONDecoder().decode(PartnerJob.self, from: Data(json.utf8))
        #expect(decoded.scheduleSeconds == nil)
    }

    @Test("V7: a missing isBuiltIn fails to decode")
    func testV7_missingIsBuiltIn() {
        let json = #"{"id":"j","name":"J","isEnabled":true,"scheduleSeconds":5,"guidelines":"g","steps":[]}"#
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(PartnerJob.self, from: Data(json.utf8))
        }
    }

    @Test("V8: encode then decode gives an equal job")
    func testV8_roundTrip() throws {
        let original = job(steps: [Self.stepOpen, Self.stepFix])
        let decoded = try JSONDecoder().decode(PartnerJob.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }

    @Test("V9: jobs differing only in guidelines are unequal with the same id")
    func testV9_identity() {
        let first = job(guidelines: "one")
        let second = job(guidelines: "two")
        #expect(first != second)
        #expect(first.id == second.id)
    }

    @Test("V10: step order survives a round trip")
    func testV10_orderRoundTrip() throws {
        let named = { (name: String) in
            PartnerJobStep(name: name, environment: .terminal, command: "c", condition: "k")
        }
        let original = job(steps: [named("b"), named("a")])
        let decoded = try JSONDecoder().decode(PartnerJob.self, from: JSONEncoder().encode(original))
        #expect(decoded.steps.map(\.name) == ["b", "a"])
    }

    @Test("V11: no steps and an empty condition round-trip")
    func testV11_emptyStepsAndCondition() throws {
        let empty = job(steps: [])
        #expect(try JSONDecoder().decode(PartnerJob.self, from: JSONEncoder().encode(empty)) == empty)
        let free = PartnerJobStep(name: "n", environment: .claude, command: "c", condition: "")
        #expect(try JSONDecoder().decode(PartnerJobStep.self, from: JSONEncoder().encode(free)) == free)
    }

    @Test("V12: nothing is validated")
    func testV12_noValidation() {
        let make = {
            PartnerJob(id: "", name: "", isEnabled: false, scheduleSeconds: -5, guidelines: "", steps: [])
        }
        #expect(make().scheduleSeconds == -5)
        #expect(make().id.isEmpty)
        #expect(make() == make())
    }

    @Test("V13: concurrent encodes both succeed")
    func testV13_concurrentEncode() async throws {
        let original = job()
        let outputs = await withTaskGroup(of: Data?.self) { group in
            for _ in 0..<2 { group.addTask { try? JSONEncoder().encode(original) } }
            var collected: [Data?] = []
            for await output in group { collected.append(output) }
            return collected
        }
        #expect(outputs.count == 2)
        for output in outputs {
            let data = try #require(output)
            #expect(try JSONDecoder().decode(PartnerJob.self, from: data) == original)
        }
    }
}
