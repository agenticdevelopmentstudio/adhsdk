import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("InvalidTimestamp")
struct InvalidTimestampTests {

    @Test("invalid-timestamp-001: carries its message")
    func invalidTimestamp001CarriesMessage() {
        #expect(InvalidTimestamp(message: "bad since").message == "bad since")
    }

    @Test("invalid-timestamp-002: description is the message")
    func invalidTimestamp002DescriptionIsMessage() {
        #expect(InvalidTimestamp(message: "bad since").description == "bad since")
    }

    @Test("invalid-timestamp-003: equal messages are equal")
    func invalidTimestamp003EqualMessages() {
        #expect(InvalidTimestamp(message: "a") == InvalidTimestamp(message: "a"))
    }

    @Test("invalid-timestamp-004: different messages are not equal")
    func invalidTimestamp004DifferentMessages() {
        #expect(InvalidTimestamp(message: "a") != InvalidTimestamp(message: "b"))
    }

    @Test("invalid-timestamp-005: empty message is accepted")
    func invalidTimestamp005EmptyMessage() {
        #expect(InvalidTimestamp(message: "").message.isEmpty)
    }

    @Test("invalid-timestamp-006: usable as a Result failure and thrown")
    func invalidTimestamp006ConformsToError() {
        let result: Result<String, InvalidTimestamp> = .failure(InvalidTimestamp(message: "bad"))
        #expect(throws: InvalidTimestamp.self) { try result.get() }
        do {
            throw InvalidTimestamp(message: "bad")
        } catch let caught as InvalidTimestamp {
            #expect(caught.message == "bad")
        } catch {
            Issue.record("caught a different error: \(error)")
        }
    }

    @Test("invalid-timestamp-009: message is immutable",
          .disabled("a compile-failure check; a unit test cannot assert that code fails to compile"))
    func invalidTimestamp009Immutable() {}

    @Test("invalid-timestamp-010: no String Error extension",
          .disabled("a source search check; a unit test cannot search the module's source"))
    func invalidTimestamp010NoStringErrorExtension() {}
}
