import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

/// Records each backoff the client asks for instead of sleeping.
private actor SleepLog {
    private(set) var slept: [Duration] = []
    func record(_ duration: Duration) { slept.append(duration) }
}

/// A client over a stub session whose sleeps are recorded, not slept.
private struct Subject {
    let api: GmailRESTClient
    let stub: StubURLProtocol.Stub
    let sleeps: SleepLog

    /// The default pacer never holds a call back, so only backoffs reach `sleeps`.
    init(_ replies: [StubURLProtocol.Reply], token: String = "tok",
         pacer: GmailQuotaPacer = GmailQuotaPacer(unitsPerSecond: 1_000_000, burstUnits: 1_000_000)) {
        let stub = StubURLProtocol.stub(replies)
        let sleeps = SleepLog()
        self.stub = stub
        self.sleeps = sleeps
        api = GmailRESTClient(session: stub.session, sleep: { await sleeps.record($0) }, pacer: pacer,
                              accessToken: { token })
    }

    init(status: Int = 200, body: Data, token: String = "tok") {
        self.init([.http(status: status, body: body)], token: token)
    }

    var requests: [URLRequest] { stub.requests }
}

private let profileBody = Data(#"{"emailAddress":"me@x.com","historyId":"7"}"#.utf8)
private let unavailable = StubURLProtocol.Reply.http(
    status: 503, body: Data(#"{"error":{"code":503,"message":"Backend Error"}}"#.utf8))

@Suite struct GmailRESTClientTests {
    @Test func historyNotFoundThrowsCursorExpired() async throws {
        let subject = Subject(status: 404, body: Data(#"{"error":{"code":404,"message":"Not Found"}}"#.utf8))
        defer { subject.stub.unregister() }
        await #expect(throws: GmailCursorExpired.self) {
            _ = try await subject.api.history(startHistoryId: "1", pageToken: nil)
        }
    }

    @Test func errorBodyMessageSurfaces() async throws {
        let body = #"{"error":{"code":403,"message":"Insufficient Permission","status":"PERMISSION_DENIED"}}"#
        let subject = Subject(status: 403, body: Data(body.utf8))
        defer { subject.stub.unregister() }
        await #expect(throws: IntegrationError.gmail(status: 403, message: "Insufficient Permission")) {
            _ = try await subject.api.profile()
        }
        #expect(await subject.sleeps.slept.isEmpty, "a 403 is not retried")
        #expect(subject.requests.count == 1)
    }

    @Test func historyPageCollectsChangedAndDeleted() async throws {
        let subject = Subject(body: try GmailFixture.data("history"))
        defer { subject.stub.unregister() }
        let page = try await subject.api.history(startHistoryId: "100", pageToken: "p1")
        #expect(page.changedIds == ["a", "b"])
        #expect(page.deletedIds == ["c"])
        #expect(page.historyId == "950")
        #expect(page.nextPageToken == "p2")
        let url = try #require(subject.requests.first?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.filter { $0.name == "historyTypes" }.compactMap(\.value)
            == ["messageAdded", "messageDeleted", "labelAdded", "labelRemoved"])
        #expect(items.contains { $0.name == "startHistoryId" && $0.value == "100" })
        #expect(items.contains { $0.name == "pageToken" && $0.value == "p1" })
        #expect(url.path == "/gmail/v1/users/me/history")
    }

    @Test func sendsBearerToken() async throws {
        let subject = Subject(body: profileBody, token: "secret")
        defer { subject.stub.unregister() }
        let profile = try await subject.api.profile()
        #expect(profile.emailAddress == "me@x.com")
        #expect(subject.requests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    }

    @Test func listMessageIdsDedupesAndToleratesEmpty() async throws {
        let subject = Subject(body: Data(#"{"messages":[{"id":"x"},{"id":"y"},{"id":"x"}],"nextPageToken":"n"}"#.utf8))
        defer { subject.stub.unregister() }
        let page = try await subject.api.listMessageIds(query: "q", includeSpamTrash: true, pageToken: nil)
        #expect(page.ids == ["x", "y"])
        #expect(page.nextPageToken == "n")
        let empty = Subject(body: Data("{}".utf8))
        defer { empty.stub.unregister() }
        #expect(try await empty.api.listMessageIds(query: "q", includeSpamTrash: false, pageToken: nil).ids.isEmpty)
    }

    @Test func listMessageIdsSendsItsParameters() async throws {
        let subject = Subject(body: Data("{}".utf8))
        defer { subject.stub.unregister() }
        _ = try await subject.api.listMessageIds(query: "after:1 in:inbox", includeSpamTrash: true, pageToken: "p9")
        _ = try await subject.api.listMessageIds(query: "after:2", includeSpamTrash: false, pageToken: nil)
        let urls = subject.requests.compactMap(\.url)
        #expect(urls.count == 2)
        let first = URLComponents(url: urls[0], resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(urls[0].path == "/gmail/v1/users/me/messages")
        #expect(first.contains { $0.name == "q" && $0.value == "after:1 in:inbox" })
        #expect(first.contains { $0.name == "maxResults" && $0.value == "500" })
        #expect(first.contains { $0.name == "includeSpamTrash" && $0.value == "true" })
        #expect(first.contains { $0.name == "pageToken" && $0.value == "p9" })
        let second = URLComponents(url: urls[1], resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(second.contains { $0.name == "q" && $0.value == "after:2" })
        #expect(!second.contains { $0.name == "includeSpamTrash" })
        #expect(!second.contains { $0.name == "pageToken" })
    }

    @Test func searchSendsTheQueryEachLabelAndThePageSize() async throws {
        let subject = Subject(body: Data(#"{"messages":[{"id":"x"},{"id":"y"}],"nextPageToken":"n"}"#.utf8))
        defer { subject.stub.unregister() }
        let page = try await subject.api.searchMessageIds(
            query: "from:greenhouse", labelIds: ["INBOX", "Label_1"], maxResults: 25, pageToken: "p")
        #expect(page.ids == ["x", "y"])
        #expect(page.nextPageToken == "n")
        let url = try #require(subject.requests.first?.url)
        #expect(url.path == "/gmail/v1/users/me/messages")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.first { $0.name == "q" }?.value == "from:greenhouse")
        #expect(items.filter { $0.name == "labelIds" }.compactMap(\.value) == ["INBOX", "Label_1"])
        #expect(items.first { $0.name == "maxResults" }?.value == "25")
        #expect(items.first { $0.name == "pageToken" }?.value == "p")
    }

    @Test func threadAsksForEveryMessageInFull() async throws {
        let body = #"{"id":"t1","messages":[{"id":"a","threadId":"t1"},{"id":"b","threadId":"t1"}]}"#
        let subject = Subject(body: Data(body.utf8))
        defer { subject.stub.unregister() }
        let thread = try await subject.api.thread(id: "t1")
        #expect(thread.id == "t1")
        #expect(thread.messages.map(\.id) == ["a", "b"])
        let url = try #require(subject.requests.first?.url)
        #expect(url.path == "/gmail/v1/users/me/threads/t1")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.first { $0.name == "format" }?.value == "full")
    }

    @Test func aThreadWithNoMessagesDecodesEmpty() async throws {
        let subject = Subject(body: Data(#"{"id":"t1"}"#.utf8))
        defer { subject.stub.unregister() }
        #expect(try await subject.api.thread(id: "t1").messages.isEmpty)
    }

    @Test func batchModifyPostsBody() async throws {
        let subject = Subject(body: Data())
        defer { subject.stub.unregister() }
        try await subject.api.batchModify(ids: ["a"], add: ["STARRED"], remove: ["INBOX"])
        let request = try #require(subject.requests.first)
        #expect(request.httpMethod == "POST")
        let bodyData = try #require(StubURLProtocol.body(of: request))
        let json = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: [String]])
        #expect(json == ["ids": ["a"], "addLabelIds": ["STARRED"], "removeLabelIds": ["INBOX"]])
    }

    @Test func batchModifyRejectsEmptyAndOversizedListsWithoutCallingGmail() async throws {
        let subject = Subject(body: Data())
        defer { subject.stub.unregister() }
        await #expect(throws: IntegrationError.self) {
            try await subject.api.batchModify(ids: [], add: ["STARRED"], remove: [])
        }
        let tooMany = (0...GmailRESTClient.batchModifyLimit).map { "m\($0)" }
        await #expect(throws: IntegrationError.self) {
            try await subject.api.batchModify(ids: tooMany, add: ["STARRED"], remove: [])
        }
        #expect(subject.requests.isEmpty)
    }

    // MARK: - Retry

    @Test func serviceUnavailableIsRetriedAndSucceeds() async throws {
        let subject = Subject([unavailable, .http(status: 200, body: profileBody)])
        defer { subject.stub.unregister() }
        let profile = try await subject.api.profile()
        #expect(profile.historyId == "7")
        #expect(subject.requests.count == 2)
        #expect(await subject.sleeps.slept == [.seconds(1)])
    }

    @Test func retryAfterIsHonoured() async throws {
        let limited = StubURLProtocol.Reply.http(status: 429, body: Data(), headers: ["Retry-After": "7"])
        let subject = Subject([limited, .http(status: 200, body: profileBody)])
        defer { subject.stub.unregister() }
        _ = try await subject.api.profile()
        #expect(await subject.sleeps.slept == [.seconds(7)])
    }

    @Test func transientNetworkErrorsAreRetried() async throws {
        let subject = Subject([.failure(.timedOut), .failure(.networkConnectionLost),
                               .failure(.notConnectedToInternet), .failure(.cannotConnectToHost),
                               .http(status: 200, body: profileBody)])
        defer { subject.stub.unregister() }
        _ = try await subject.api.profile()
        #expect(await subject.sleeps.slept == [.seconds(1), .seconds(2), .seconds(4), .seconds(8)])
    }

    @Test func retriesStopAfterSixAndTheLastErrorSurfaces() async throws {
        let subject = Subject([unavailable])
        defer { subject.stub.unregister() }
        await #expect(throws: IntegrationError.gmail(status: 503, message: "Backend Error")) {
            _ = try await subject.api.profile()
        }
        #expect(subject.requests.count == 7)
        #expect(await subject.sleeps.slept
            == [.seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(16), .seconds(32)])
    }

    /// The shape of body Gmail sent when the first sync of a real account went over the
    /// per-user quota.
    @Test func aRateLimit403IsRetried() async throws {
        let quota = StubURLProtocol.Reply.http(status: 403, body: Data(#"""
            {"error":{"code":403,"message":"Quota exceeded for quota metric 'Total Query Cost'",
              "errors":[{"message":"Quota exceeded","domain":"usageLimits","reason":"rateLimitExceeded"}],
              "status":"PERMISSION_DENIED","details":[{"@type":"type.googleapis.com/google.rpc.ErrorInfo",
              "reason":"RATE_LIMIT_EXCEEDED"}]}}
            """#.utf8))
        let subject = Subject([quota, .http(status: 200, body: profileBody)])
        defer { subject.stub.unregister() }
        _ = try await subject.api.profile()
        #expect(subject.requests.count == 2)
        #expect(await subject.sleeps.slept == [.seconds(1)])
    }

    @Test func aResourceExhausted403CountsAsRateLimited() {
        let body = Data(#"{"error":{"code":403,"message":"Slow down","status":"RESOURCE_EXHAUSTED"}}"#.utf8)
        #expect(GmailRESTClient.isRateLimited(403, body))
        #expect(!GmailRESTClient.isRateLimited(400, body))
    }

    @Test func aPermission403IsNotRetried() async {
        let denied = StubURLProtocol.Reply.http(status: 403, body: Data(#"""
            {"error":{"code":403,"message":"Insufficient Permission",
              "errors":[{"reason":"insufficientPermissions"}],"status":"PERMISSION_DENIED"}}
            """#.utf8))
        let subject = Subject([denied])
        defer { subject.stub.unregister() }
        await #expect(throws: IntegrationError.gmail(status: 403, message: "Insufficient Permission")) {
            _ = try await subject.api.profile()
        }
        #expect(subject.requests.count == 1)
        #expect(await subject.sleeps.slept.isEmpty)
    }

    // MARK: - Pacing

    @Test func eachCallWaitsForTheQuotaItCosts() async throws {
        let instant = ContinuousClock.now
        // 5 units a second with no burst and a stopped clock: the 1-unit profile call waits
        // 0.2 s, and the 2-unit history call after it 0.2 + 0.4 s.
        let pacer = GmailQuotaPacer(unitsPerSecond: 5, burstUnits: 0, now: { instant })
        let history = Data(#"{"historyId":"9"}"#.utf8)
        let subject = Subject([.http(status: 200, body: profileBody), .http(status: 200, body: history)],
                              pacer: pacer)
        defer { subject.stub.unregister() }
        _ = try await subject.api.profile()
        _ = try await subject.api.history(startHistoryId: "7", pageToken: nil)
        #expect(await subject.sleeps.slept == [.milliseconds(200), .milliseconds(600)])
    }

    @Test func theBurstAllowanceGoesOutWithoutWaiting() async {
        let instant = ContinuousClock.now
        let pacer = GmailQuotaPacer(unitsPerSecond: 10, burstUnits: 10, now: { instant })
        #expect(await pacer.reserve(5) == .zero)
        #expect(await pacer.reserve(5) == .zero)
        #expect(await pacer.reserve(5) == .milliseconds(500))
    }

    @Test func backoffIsCappedAt32Seconds() {
        #expect(GmailRESTClient.backoff(retry: 0, retryAfter: nil) == .seconds(1))
        #expect(GmailRESTClient.backoff(retry: 5, retryAfter: nil) == .seconds(32))
        #expect(GmailRESTClient.backoff(retry: 9, retryAfter: nil) == .seconds(32))
        #expect(GmailRESTClient.backoff(retry: 0, retryAfter: 300) == .seconds(32))
    }

    @Test func nonTransientNetworkErrorsAreNotRetried() async {
        let subject = Subject([.failure(.badURL)])
        defer { subject.stub.unregister() }
        await #expect(throws: URLError.self) { _ = try await subject.api.profile() }
        #expect(await subject.sleeps.slept.isEmpty)
    }
}
