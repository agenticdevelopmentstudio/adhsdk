import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("RouteTable")
struct RouteTableTests {

    private func request(_ method: String = "GET", _ path: String = "/a") -> RouteRequest {
        RouteRequest(method: method, path: path)
    }

    private func reply(_ status: Int) -> RouteResponse {
        RouteResponse(status: status, body: Data())
    }

    private let decline: RouteTable.Handler = { _ in nil }

    @Test func theFirstNonNilHandlerWins() async {
        let table = RouteTable([
            decline,
            { _ in RouteResponse(status: 201, body: Data()) },
            { _ in RouteResponse(status: 202, body: Data()) }
        ])

        let response = await table.handle(request())

        #expect(response?.status == 201)
    }

    @Test func aTableThatClaimsNothingReturnsNil() async {
        let table = RouteTable([decline, decline])

        #expect(await table.handle(request()) == nil)
        #expect(await RouteTable().handle(request()) == nil)
    }

    @Test func mergingTriesSelfBeforeOther() async {
        let first = RouteTable([{ _ in RouteResponse(status: 201, body: Data()) }])
        let second = RouteTable([{ _ in RouteResponse(status: 202, body: Data()) }])

        #expect(await first.merging(second).handle(request())?.status == 201)
        #expect(await second.merging(first).handle(request())?.status == 202)
    }

    @Test func mergingFallsThroughToOtherWhenSelfDeclines() async {
        let first = RouteTable([decline])
        let second = RouteTable([{ _ in RouteResponse(status: 202, body: Data()) }])

        #expect(await first.merging(second).handle(request())?.status == 202)
    }

    private actor Recorder {
        private(set) var events: [String] = []
        func record(_ event: String) { events.append(event) }
    }

    @Test("V9: the exact method comparison is case sensitive")
    func v9_exactMethodIsCaseSensitive() async {
        let table = RouteTable([
            RouteTable.exact("GET", ["a"]) { _ in RouteResponse(status: 200, body: Data()) }
        ])

        #expect(await table.handle(request("get", "/a")) == nil)
    }

    @Test("V10: the exact handler matches by path components, ignoring empty segments")
    func v10_exactMatchesViaComponents() async {
        let table = RouteTable([
            RouteTable.exact("GET", ["a"]) { _ in RouteResponse(status: 200, body: Data()) }
        ])

        #expect(await table.handle(request("GET", "//a/"))?.status == 200)
    }

    @Test("V11: merging leaves the first operand unchanged")
    func v11_mergingIsNonMutating() async {
        let first = RouteTable([decline])
        let second = RouteTable([{ _ in RouteResponse(status: 202, body: Data()) }])

        #expect(await first.merging(second).handle(request())?.status == 202)
        #expect(await first.handle(request()) == nil)
    }

    @Test("V12: later handlers are not called once one claims")
    func v12_laterHandlersSkipped() async {
        let recorder = Recorder()
        let table = RouteTable([
            { _ in RouteResponse(status: 200, body: Data()) },
            { _ in
                await recorder.record("called")
                return nil
            }
        ])

        _ = await table.handle(request())

        #expect(await recorder.events.isEmpty)
    }

    @Test("V13: handlers run one after another, each awaited before the next")
    func v13_handlersAreSequential() async {
        let recorder = Recorder()
        func tracing(_ label: String) -> RouteTable.Handler {
            { _ in
                await recorder.record("\(label)-start")
                await Task.yield()
                await recorder.record("\(label)-end")
                return nil
            }
        }
        let table = RouteTable([tracing("first"), tracing("second")])

        _ = await table.handle(request())

        #expect(await recorder.events == ["first-start", "first-end", "second-start", "second-end"])
    }

    @Test func exactClaimsOnlyItsMethodAndPath() async {
        let table = RouteTable([
            RouteTable.exact("GET", ["a"]) { _ in RouteResponse(status: 200, body: Data()) }
        ])

        #expect(await table.handle(request("GET", "/a"))?.status == 200)
        #expect(await table.handle(request("POST", "/a")) == nil)
        #expect(await table.handle(request("GET", "/a/b")) == nil)
        #expect(await table.handle(request("GET", "/")) == nil)
    }
}
