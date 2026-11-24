import XCTest
@testable import AgenticDeveloperHubSDKCore

final class OversightActionDTOsConformanceTests: XCTestCase {

    private func makeTarget(
        actionable: Bool = true, reason: String = "", termSessionId: String = "w0t0p0:ABC"
    ) -> OversightActionTargetDTO {
        OversightActionTargetDTO(
            findingId: 7, actionable: actionable, reason: reason, sessionId: "s1",
            termProgram: "iTerm.app", termSessionId: termSessionId, pid: 42, injectText: "/compact")
    }

    func testV001_blockedTargetCarriesOnlyReason() {
        let target = OversightActionTargetDTO.blocked(findingId: 7, reason: "session is mid-response")
        XCTAssertEqual(target.findingId, 7)
        XCTAssertFalse(target.actionable)
        XCTAssertEqual(target.reason, "session is mid-response")
        XCTAssertEqual(target.sessionId, "")
        XCTAssertEqual(target.termProgram, "")
        XCTAssertEqual(target.termSessionId, "")
        XCTAssertEqual(target.injectText, "")
        XCTAssertEqual(target.pid, 0)
    }

    func testV002_targetFieldsReadBack() {
        let target = makeTarget()
        XCTAssertEqual(target.findingId, 7)
        XCTAssertTrue(target.actionable)
        XCTAssertEqual(target.reason, "")
        XCTAssertEqual(target.sessionId, "s1")
        XCTAssertEqual(target.termProgram, "iTerm.app")
        XCTAssertEqual(target.termSessionId, "w0t0p0:ABC")
        XCTAssertEqual(target.pid, 42)
        XCTAssertEqual(target.injectText, "/compact")
    }

    func testV003_emptyTermSessionIdConstructs() {
        XCTAssertEqual(makeTarget(termSessionId: "").termSessionId, "")
    }

    func testV004_consumerDoesNotInjectWhenNotActionable() throws {
        throw XCTSkip("The consumer that gates injection on `actionable` is app code, not part of these DTOs")
    }

    func testV005_controlStaysDisabledForUnsupportedTerminal() throws {
        throw XCTSkip("The injector's terminal-support check is app code, not part of these DTOs")
    }

    func testV006_resultSucceededReadsBack() {
        let result = OversightActResultDTO(findingId: 7, succeeded: true, status: "acted", reason: "")
        XCTAssertEqual(result.findingId, 7)
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.status, "acted")
        XCTAssertEqual(result.reason, "")
    }

    func testV007_resultAlreadyResolvedKeepsStatusAndReason() {
        let result = OversightActResultDTO(
            findingId: 7, succeeded: false, status: "resolved", reason: "already resolved")
        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.status, "resolved")
        XCTAssertFalse(result.reason.isEmpty)
    }

    func testV008_resultNotFoundHasEmptyStatus() {
        let result = OversightActResultDTO(findingId: 9, succeeded: false, status: "", reason: "not found")
        XCTAssertEqual(result.status, "")
        XCTAssertEqual(result.reason, "not found")
    }

    func testV009_identicalTargetsAreEqual() {
        XCTAssertEqual(makeTarget(), makeTarget())
        XCTAssertNotEqual(makeTarget(), makeTarget(actionable: false))
    }

    func testV010_codableRoundTrip() throws {
        let target = makeTarget()
        let result = OversightActResultDTO(findingId: 7, succeeded: false, status: "resolved", reason: "r")
        let encoder = StenographerWire.encoder()
        let decoder = StenographerWire.decoder()
        XCTAssertEqual(try decoder.decode(OversightActionTargetDTO.self, from: encoder.encode(target)), target)
        XCTAssertEqual(try decoder.decode(OversightActResultDTO.self, from: encoder.encode(result)), result)
    }

    func testV011_initializersDoNotValidate() {
        let target = OversightActionTargetDTO(
            findingId: 1, actionable: true, reason: "x", sessionId: "", termProgram: "",
            termSessionId: "", pid: -1, injectText: "")
        XCTAssertTrue(target.actionable)
        XCTAssertEqual(target.reason, "x")
        let result = OversightActResultDTO(findingId: 1, succeeded: false, status: "", reason: "")
        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.reason, "")
    }
}
