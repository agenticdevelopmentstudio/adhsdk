import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Partner step template conformance") struct PartnerStepTemplateConformanceTests {
    @Test("V7: shellQuoted of the empty string is two quotes") func v7EmptyIsQuoted() {
        #expect(PartnerStepTemplate.shellQuoted("") == "''")
    }
    @Test("V8: only word-character keys are placeholders") func v8PlaceholderSyntax() {
        #expect(PartnerStepTemplate.fill("{} {a b} {c}", values: ["c": "x"]) == "{} {a b} x")
    }
    @Test("V9: steps keep their other fields") func v9StepsKeepFields() {
        let step = PartnerJobStep(name: "open", environment: .terminal, command: "echo {x}", condition: "when-idle")
        let filled = PartnerStepTemplate.fill([step], values: ["x": "1"])
        #expect(filled.count == 1)
        #expect(filled[0].name == "open" && filled[0].environment == .terminal)
        #expect(filled[0].condition == "when-idle" && filled[0].command == "echo 1")
    }
    @Test("V10: text between placeholders is preserved") func v10TextBetweenPreserved() {
        #expect(PartnerStepTemplate.fill("a {x} b {x} c", values: ["x": "1"]) == "a 1 b 1 c")
    }
    @Test("V11: non-ASCII word characters form a key") func v11UnicodeKey() {
        #expect(PartnerStepTemplate.fill("{café}", values: ["café": "x"]) == "x")
    }
    @Test("V12: a leading tilde is quoted") func v12TildeQuoted() {
        #expect(PartnerStepTemplate.shellQuoted("~/x") == "'~/x'")
    }
    @Test("V13: terminal and Claude steps in one list") func v13MixedSteps() {
        let steps = [
            PartnerJobStep(name: "t", environment: .terminal, command: "echo {v}", condition: ""),
            PartnerJobStep(name: "c", environment: .claude, command: "say {v}", condition: "")
        ]
        #expect(PartnerStepTemplate.fill(steps, values: ["v": "a b"]).map(\.command) == ["echo 'a b'", "say a b"])
    }
    @Test("V14: empty values leave the command unchanged") func v14EmptyValues() {
        #expect(PartnerStepTemplate.fill("x {a} {b}", values: [:]) == "x {a} {b}")
    }
}
