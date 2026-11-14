import AppKit
import Testing
@testable import AgenticDeveloperHubSDKMacOS

/// `perform command … with arguments {…}`: the `type="any"` parameter reaches the
/// command undecoded, and the command must still be handed plain strings.
@Suite("perform command arguments")
struct PerformAppCommandArgumentsTests {

    @Test("no arguments is an empty list")
    func none() {
        #expect(PerformAppCommandCommand.arguments(from: nil).isEmpty)
    }

    @Test("a list descriptor becomes its items, text as strings")
    func listDescriptor() {
        let list = NSAppleEventDescriptor.list()
        list.insert(NSAppleEventDescriptor(string: "/tmp/repo"), at: 1)
        list.insert(NSAppleEventDescriptor(string: "second"), at: 2)

        let arguments = PerformAppCommandCommand.arguments(from: list)

        #expect(arguments.compactMap { $0 as? String } == ["/tmp/repo", "second"])
    }

    @Test("an empty list descriptor is an empty list")
    func emptyListDescriptor() {
        #expect(PerformAppCommandCommand.arguments(from: NSAppleEventDescriptor.list()).isEmpty)
    }

    @Test("a single text descriptor is one string")
    func singleDescriptor() {
        let arguments = PerformAppCommandCommand.arguments(from: NSAppleEventDescriptor(string: "/tmp/repo"))
        #expect(arguments.compactMap { $0 as? String } == ["/tmp/repo"])
    }

    @Test("decoded values pass through, a single one as a one-element list")
    func decodedValues() {
        #expect(PerformAppCommandCommand.arguments(from: ["a", "b"]).compactMap { $0 as? String } == ["a", "b"])
        #expect(PerformAppCommandCommand.arguments(from: "a").compactMap { $0 as? String } == ["a"])
    }
}
