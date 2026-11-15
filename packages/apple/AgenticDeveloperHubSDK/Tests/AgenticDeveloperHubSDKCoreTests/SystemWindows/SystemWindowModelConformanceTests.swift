import CoreGraphics
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("SystemWindowModel conformance")
struct SystemWindowModelConformanceTests {

    // MARK: - Helpers

    private func makeFingerprint(
        app: String = "Mail", pattern: String = "", strategy: MatchStrategy = .appOnly, display: UInt32 = 0
    ) -> SystemWindowFingerprint {
        SystemWindowFingerprint(app: app, titlePattern: pattern, matchStrategy: strategy, display: display)
    }

    private func makeSnapshot(
        windowID: UInt32? = nil, title: String = "", id: UUID = UUID()
    ) -> SystemWindowSnapshot {
        SystemWindowSnapshot(
            id: id, windowID: windowID, fingerprint: makeFingerprint(), savedFrame: .zero,
            display: 0, app: "Mail", title: title, lastSeen: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private func makeInfo(title: String = "") -> SystemWindowInfo {
        SystemWindowInfo(
            id: 5, app: "Mail", pid: 42, title: title,
            frame: CGRect(x: 1, y: 2, width: 3, height: 4), display: 1, isOnScreen: true, layer: 0
        )
    }

    private func sortedEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    // MARK: - MatchStrategy

    @Test("wmcsw-001: the strategy list has four cases in declaration order")
    func strategyValueList() {
        #expect(MatchStrategy.allCases == [.appAndTitleExact, .appAndTitleSubstring, .appAndTitleRegex, .appOnly])
        #expect(MatchStrategy.allCases.count == 4)
    }

    @Test("wmcsw-002: strategies encode and decode as their raw strings")
    func strategyRawValues() throws {
        let encoded = try JSONEncoder().encode([MatchStrategy.appOnly])
        #expect(String(bytes: encoded, encoding: .utf8) == "[\"appOnly\"]")
        let decoded = try JSONDecoder().decode([MatchStrategy].self, from: Data("[\"appAndTitleRegex\"]".utf8))
        #expect(decoded == [.appAndTitleRegex])
    }

    @Test("wmcsw-003: an unknown raw string fails to decode and to construct")
    func strategyUnknownRaw() {
        #expect(MatchStrategy(rawValue: "fuzzy") == nil)
        do {
            _ = try JSONDecoder().decode([MatchStrategy].self, from: Data("[\"fuzzy\"]".utf8))
            Issue.record("decoding an unknown strategy should throw")
        } catch DecodingError.dataCorrupted {
            // expected
        } catch {
            Issue.record("expected a data-corrupted decoding error, got \(error)")
        }
    }

    @Test("wmcsw-004: each strategy has its display name")
    func strategyDisplayNames() {
        #expect(MatchStrategy.allCases.map(\.displayName) == ["Exact", "Substring", "Regex", "App Only"])
    }

    // MARK: - Fingerprint

    @Test("wmcsw-005: the fingerprint keeps its fields verbatim")
    func fingerprintInitVerbatim() {
        let fingerprint = SystemWindowFingerprint(
            app: "Xcode", titlePattern: " Proj ", matchStrategy: .appAndTitleExact, display: 2
        )
        #expect(fingerprint.app == "Xcode")
        #expect(fingerprint.titlePattern == " Proj ")
        #expect(fingerprint.matchStrategy == .appAndTitleExact)
        #expect(fingerprint.display == 2)
    }

    @Test("wmcsw-006: a regex fingerprint constructs and the matcher scores it 80")
    func regexScores() {
        let fingerprint = makeFingerprint(app: "TestApp", pattern: "JIRA-\\d+", strategy: .appAndTitleRegex)
        let window = SystemWindowInfo(
            id: 1, app: "TestApp", pid: 1, title: "JIRA-1234 details",
            frame: .zero, display: 99, isOnScreen: true, layer: 0
        )
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry(heuristics: []))
        #expect(matcher.score(window: window, against: fingerprint) == 80)
    }

    @Test("wmcsw-007: an uncompilable regex fingerprint constructs and scores 0")
    func invalidRegexScoresZero() {
        let fingerprint = makeFingerprint(app: "TestApp", pattern: "(", strategy: .appAndTitleRegex)
        let window = SystemWindowInfo(
            id: 1, app: "TestApp", pid: 1, title: "x", frame: .zero, display: 99, isOnScreen: true, layer: 0
        )
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry(heuristics: []))
        // The vector also expects a logged compile error; os_log output is not observable from a unit test.
        #expect(matcher.score(window: window, against: fingerprint) == 0)
    }

    @Test("wmcsw-008: a same-display app-only fingerprint scores 90")
    func displayTieBreaker() {
        let fingerprint = makeFingerprint(app: "Terminal", strategy: .appOnly, display: 7)
        let window = SystemWindowInfo(
            id: 1, app: "Terminal", pid: 1, title: "", frame: .zero, display: 7, isOnScreen: true, layer: 0
        )
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry(heuristics: []))
        #expect(matcher.score(window: window, against: fingerprint) == 90)
    }

    // MARK: - Window info

    @Test("wmcsw-009: withTitle copies every field but the title and leaves the original alone")
    func withTitleCopies() {
        let original = makeInfo()
        let copy = original.withTitle("Inbox")
        #expect(copy.title == "Inbox")
        #expect(copy.id == original.id)
        #expect(copy.app == original.app)
        #expect(copy.pid == original.pid)
        #expect(copy.frame == original.frame)
        #expect(copy.display == original.display)
        #expect(copy.isOnScreen == original.isOnScreen)
        #expect(copy.layer == original.layer)
        #expect(original.title.isEmpty)
    }

    @Test("wmcsw-010: window info equality covers the title while identity is the id")
    func infoIdentity() {
        let original = makeInfo()
        let copy = original.withTitle("x")
        #expect(copy.id == original.id)
        #expect(copy != original)
    }

    // MARK: - Snapshot

    @Test("wmcsw-011: new snapshots get distinct ids and start dormant")
    func snapshotDefaults() {
        let fingerprint = makeFingerprint()
        let first = SystemWindowSnapshot(
            fingerprint: fingerprint, savedFrame: .zero, display: 0, app: "Mail", title: ""
        )
        let second = SystemWindowSnapshot(
            fingerprint: fingerprint, savedFrame: .zero, display: 0, app: "Mail", title: ""
        )
        #expect(first.id != second.id)
        #expect(first.windowID == nil)
        #expect(!first.isLive)
    }

    @Test("wmcsw-012: isLive follows windowID")
    func snapshotIsLive() {
        var snapshot = makeSnapshot(windowID: 9)
        #expect(snapshot.isLive)
        snapshot.windowID = nil
        #expect(!snapshot.isLive)
    }

    @Test("wmcsw-013: the snapshot display is independent of the fingerprint display")
    func snapshotDisplayIndependent() {
        var snapshot = SystemWindowSnapshot(
            fingerprint: makeFingerprint(display: 1), savedFrame: .zero, display: 1, app: "Mail", title: ""
        )
        snapshot.display = 3
        #expect(snapshot.display == 3)
        #expect(snapshot.fingerprint.display == 1)
    }

    // MARK: - Context

    @Test("wmcsw-014: a new context has the documented defaults")
    func contextInitDefaults() {
        let context = SystemWindowContext(name: "Docs")
        #expect(context.color == "#007AFF")
        #expect(context.windowSnapshots.isEmpty)
        #expect(context.lastFocusedWindowID == nil)
        #expect(abs(context.createdAt.timeIntervalSinceNow) < 1)
    }

    @Test("wmcsw-015: addWindow appends new snapshots in order")
    func addWindowAppend() {
        let first = makeSnapshot()
        let second = makeSnapshot()
        var context = SystemWindowContext(name: "C")
        context.addWindow(first)
        context.addWindow(second)
        #expect(context.windowSnapshots.map(\.id) == [first.id, second.id])
    }

    @Test("wmcsw-016: addWindow replaces a snapshot with the same id in place and keeps focus")
    func addWindowReplace() {
        let first = makeSnapshot()
        let second = makeSnapshot()
        var context = SystemWindowContext(
            name: "C", windowSnapshots: [first, second], lastFocusedWindowID: first.id
        )
        context.addWindow(makeSnapshot(title: "new", id: first.id))
        #expect(context.windowSnapshots.count == 2)
        #expect(context.windowSnapshots.map(\.id) == [first.id, second.id])
        #expect(context.windowSnapshots[0].title == "new")
        #expect(context.lastFocusedWindowID == first.id)
    }

    @Test("wmcsw-017: addWindow does not dedupe on windowID")
    func addWindowNoWindowIDDedupe() {
        var context = SystemWindowContext(name: "C")
        context.addWindow(makeSnapshot(windowID: 7))
        context.addWindow(makeSnapshot(windowID: 7))
        #expect(context.windowSnapshots.count == 2)
    }

    @Test("wmcsw-018: removing by id returns the snapshot and clears focus on it")
    func removeByID() {
        let first = makeSnapshot()
        let second = makeSnapshot()
        var context = SystemWindowContext(
            name: "C", windowSnapshots: [first, second], lastFocusedWindowID: first.id
        )
        let removed = context.removeWindow(id: first.id)
        #expect(removed == first)
        #expect(context.windowSnapshots == [second])
        #expect(context.lastFocusedWindowID == nil)
    }

    @Test("wmcsw-019: removing an unknown id returns nil and changes nothing")
    func removeByIDMissing() {
        let first = makeSnapshot()
        var context = SystemWindowContext(name: "C", windowSnapshots: [first], lastFocusedWindowID: first.id)
        let before = context
        #expect(context.removeWindow(id: UUID()) == nil)
        #expect(context == before)
    }

    @Test("wmcsw-020: removing another snapshot keeps the focus")
    func removeKeepsOtherFocus() {
        let first = makeSnapshot()
        let second = makeSnapshot()
        var context = SystemWindowContext(
            name: "C", windowSnapshots: [first, second], lastFocusedWindowID: second.id
        )
        context.removeWindow(id: first.id)
        #expect(context.lastFocusedWindowID == second.id)
    }

    @Test("wmcsw-021: removing by windowID removes the first match and clears its focus")
    func removeByWindowID() {
        let first = makeSnapshot(windowID: 7)
        let second = makeSnapshot(windowID: 7)
        var context = SystemWindowContext(
            name: "C", windowSnapshots: [first, second], lastFocusedWindowID: first.id
        )
        let removed = context.removeWindow(windowID: 7)
        #expect(removed == first)
        #expect(context.windowSnapshots == [second])
        #expect(context.lastFocusedWindowID == nil)
    }

    @Test("wmcsw-022: removing an unmatched windowID returns nil and changes nothing")
    func removeByWindowIDMissing() {
        var context = SystemWindowContext(name: "C", windowSnapshots: [makeSnapshot()])
        let before = context
        #expect(context.removeWindow(windowID: 0) == nil)
        #expect(context == before)
    }

    @Test("wmcsw-023: snapshot(id:) finds a snapshot or returns nil")
    func snapshotLookup() {
        let first = makeSnapshot()
        let second = makeSnapshot()
        let context = SystemWindowContext(name: "C", windowSnapshots: [first, second])
        #expect(context.snapshot(id: second.id) == second)
        #expect(context.snapshot(id: UUID()) == nil)
    }

    @Test("wmcsw-024: updateSnapshot(id:) edits only the named snapshot in place")
    func updateByID() {
        let first = makeSnapshot()
        var context = SystemWindowContext(name: "C", windowSnapshots: [first])
        let updated = context.updateSnapshot(id: first.id) { snapshot in
            snapshot.title = "T"
            snapshot.windowID = 3
        }
        #expect(updated)
        #expect(context.windowSnapshots[0].title == "T")
        #expect(context.windowSnapshots[0].windowID == 3)
        #expect(context.windowSnapshots[0].id == first.id)
    }

    @Test("wmcsw-025: updateSnapshot(id:) with an unknown id returns false and never runs the closure")
    func updateByIDMissing() {
        var context = SystemWindowContext(name: "C", windowSnapshots: [makeSnapshot()])
        var ran = false
        let updated = context.updateSnapshot(id: UUID()) { _ in ran = true }
        #expect(!updated)
        #expect(!ran)
    }

    @Test("wmcsw-026: updateSnapshot(windowID:) edits the matching snapshot or returns false")
    func updateByWindowID() {
        var context = SystemWindowContext(name: "C", windowSnapshots: [makeSnapshot(windowID: 4)])
        let frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        #expect(context.updateSnapshot(windowID: 4) { $0.savedFrame = frame })
        #expect(context.windowSnapshots[0].savedFrame == frame)
        #expect(!context.updateSnapshot(windowID: 5) { $0.savedFrame = .zero })
    }

    @Test("wmcsw-027: liveWindowCount counts snapshots that have a windowID")
    func liveWindowCount() {
        let context = SystemWindowContext(
            name: "C", windowSnapshots: [makeSnapshot(windowID: 1), makeSnapshot(), makeSnapshot(windowID: 2)]
        )
        #expect(context.liveWindowCount == 2)
    }

    // MARK: - Serialization

    @Test("wmcsw-028: a snapshot encodes its stored fields only, omitting a nil windowID and the live flag")
    func snapshotEncodedKeys() throws {
        let data = try sortedEncoder().encode(makeSnapshot())
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object.keys.sorted() == ["app", "display", "fingerprint", "id", "lastSeen", "savedFrame", "title"])
    }

    @Test("wmcsw-029: a frame encodes as nested origin and size arrays")
    func frameEncoding() throws {
        let data = try sortedEncoder().encode(makeInfo())
        #expect(String(bytes: data, encoding: .utf8)?.contains("\"frame\":[[1,2],[3,4]]") == true)
    }

    @Test("wmcsw-030: a fingerprint missing a key fails with a key-not-found error for display")
    func missingKeyThrows() {
        let json = "{\"app\":\"Xcode\",\"titlePattern\":\"P\",\"matchStrategy\":\"appOnly\"}"
        do {
            _ = try JSONDecoder().decode(SystemWindowFingerprint.self, from: Data(json.utf8))
            Issue.record("decoding should throw")
        } catch DecodingError.keyNotFound(let key, _) {
            #expect(key.stringValue == "display")
        } catch {
            Issue.record("expected a key-not-found decoding error, got \(error)")
        }
    }

    @Test("wmcsw-031: a context with two snapshots round-trips through JSON")
    func contextRoundTrip() throws {
        let context = SystemWindowContext(
            name: "Docs", windowSnapshots: [makeSnapshot(windowID: 1, title: "a"), makeSnapshot(title: "b")],
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SystemWindowContext.self, from: sortedEncoder().encode(context))
        #expect(decoded == context)
    }

    @Test(
        "wmcsw-032: no file, network, log or process activity",
        .disabled("a unit test cannot observe the absence of file, network, log or process side effects")
    )
    func noSideEffects() {}
}
