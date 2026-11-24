import Testing
import Foundation
import CoreGraphics
import AgenticDeveloperHubSDKCore

@Suite("SystemWindowMatcher")
struct SystemWindowMatcherTests {

    // Window and fingerprint defaults use DIFFERENT displays so the +10 same-display
    // bonus is opt-in: a test only sees it when it passes matching `display:` values.
    private func makeWindow(
        id: UInt32 = 1, app: String, title: String, display: UInt32 = 99
    ) -> SystemWindowInfo {
        SystemWindowInfo(
            id: id, app: app, pid: 1, title: title,
            frame: .zero, display: display, isOnScreen: true, layer: 0
        )
    }

    private func makeFingerprint(
        app: String, pattern: String, strategy: MatchStrategy, display: UInt32 = 0
    ) -> SystemWindowFingerprint {
        SystemWindowFingerprint(
            app: app, titlePattern: pattern, matchStrategy: strategy, display: display
        )
    }

    private func makeSnapshot(app: String, fingerprint: SystemWindowFingerprint) -> SystemWindowSnapshot {
        SystemWindowSnapshot(
            windowID: nil, fingerprint: fingerprint, savedFrame: .zero,
            display: 0, app: app, title: ""
        )
    }

    @Test("window-matching-001: app-name mismatch scores 0")
    func appMismatch() {
        let matcher = SystemWindowMatcher()
        let fingerprint = makeFingerprint(app: "Xcode", pattern: "Proj", strategy: .appAndTitleSubstring)
        #expect(matcher.score(window: makeWindow(app: "Other", title: "Proj"), against: fingerprint) == 0)
    }

    @Test("window-matching-002: appOnly matches any same-app window")
    func appOnly() {
        let matcher = SystemWindowMatcher()
        let fingerprint = makeFingerprint(app: "Terminal", pattern: "", strategy: .appOnly)
        #expect(matcher.score(window: makeWindow(app: "Terminal", title: "anything"), against: fingerprint) == 80)
    }

    @Test("window-matching-003: a one-character substring pattern does not over-match")
    func shortSubstringGuarded() {
        let matcher = SystemWindowMatcher()
        let fingerprint = makeFingerprint(app: "TestApp", pattern: "a", strategy: .appAndTitleSubstring)
        // Below the minimum substring length and not an exact match -> no match.
        #expect(matcher.score(window: makeWindow(app: "TestApp", title: "banana"), against: fingerprint) == 0)
    }

    @Test("window-matching-004: a multi-character substring matches at 60")
    func substringMatches() {
        let matcher = SystemWindowMatcher()
        let fingerprint = makeFingerprint(app: "TestApp", pattern: "ban", strategy: .appAndTitleSubstring)
        #expect(matcher.score(window: makeWindow(app: "TestApp", title: "banana"), against: fingerprint) == 60)
    }

    @Test("window-matching-005: regex strategy matches a whole title family")
    func regexFamily() {
        let matcher = SystemWindowMatcher()
        let fingerprint = makeFingerprint(app: "TestApp", pattern: "JIRA-\\d+", strategy: .appAndTitleRegex)
        let hit = makeWindow(app: "TestApp", title: "JIRA-1234 details")
        let miss = makeWindow(app: "TestApp", title: "no ticket")
        #expect(matcher.score(window: hit, against: fingerprint) == 80)
        #expect(matcher.score(window: miss, against: fingerprint) == 0)
    }

    @Test("window-matching-006: display match adds a bonus")
    func displayBonus() {
        let matcher = SystemWindowMatcher()
        let fingerprint = makeFingerprint(app: "Terminal", pattern: "", strategy: .appOnly, display: 7)
        let window = makeWindow(app: "Terminal", title: "x", display: 7)
        #expect(matcher.score(window: window, against: fingerprint) == 90)
    }

    @Test("window-matching-007: sub-threshold matches stay reported, not silently consumed")
    func subThresholdReported() {
        let matcher = SystemWindowMatcher()
        let fingerprint = makeFingerprint(app: "TestApp", pattern: "ban", strategy: .appAndTitleSubstring)
        let context = SystemWindowContext(
            name: "C", windowSnapshots: [makeSnapshot(app: "TestApp", fingerprint: fingerprint)]
        )
        let live = makeWindow(id: 5, app: "TestApp", title: "banana") // scores 60

        // Default threshold (80): the 60-pt pair must not be consumed; both remain reported.
        let result = matcher.matchWindows(contexts: [context], liveWindows: [live])
        #expect(result.matched.isEmpty)
        #expect(result.unmatchedSnapshots.count == 1)
        #expect(result.unassignedWindows.map(\.id) == [5])

        // A lower threshold accepts it.
        let lower = matcher.matchWindows(contexts: [context], liveWindows: [live], threshold: 60)
        #expect(lower.matched.count == 1)
    }

    @Test("window-matching-008: greedy assignment is deterministic for tied scores")
    func deterministicTies() {
        let matcher = SystemWindowMatcher()
        let appOnly = makeFingerprint(app: "Terminal", pattern: "", strategy: .appOnly)
        let ctxA = SystemWindowContext(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "A",
            windowSnapshots: [makeSnapshot(app: "Terminal", fingerprint: appOnly)]
        )
        let ctxB = SystemWindowContext(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "B",
            windowSnapshots: [makeSnapshot(app: "Terminal", fingerprint: appOnly)]
        )
        let windows = [
            makeWindow(id: 10, app: "Terminal", title: "t1"),
            makeWindow(id: 20, app: "Terminal", title: "t2")
        ]

        let first = matcher.matchWindows(contexts: [ctxA, ctxB], liveWindows: windows)
        let second = matcher.matchWindows(contexts: [ctxA, ctxB], liveWindows: windows)
        #expect(first == second)
        #expect(first.matched.count == 2)
    }

    @Test("window-matching-009: MatchResult equality distinguishes different unmatched snapshots")
    func matchResultEquality() {
        let snapA = (contextID: UUID(), snapshotID: UUID())
        let snapB = (contextID: UUID(), snapshotID: UUID())
        let lhs = SystemWindowMatcher.MatchResult(matched: [], unmatchedSnapshots: [snapA], unassignedWindows: [])
        let rhs = SystemWindowMatcher.MatchResult(matched: [], unmatchedSnapshots: [snapB], unassignedWindows: [])
        #expect(lhs != rhs)
        #expect(lhs == lhs)
    }

    // MARK: - Fingerprint fallback and scoring edge cases

    @Test("window-matching-019: an unknown app fingerprints by the full title with the substring strategy")
    func fingerprintFallback() {
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry())
        let window = makeWindow(app: "UnknownApp", title: "Report.pdf", display: 3)
        let fingerprint = matcher.fingerprint(window: window)
        #expect(fingerprint == makeFingerprint(
            app: "UnknownApp", pattern: "Report.pdf", strategy: .appAndTitleSubstring, display: 3
        ))
    }

    @Test("window-matching-020: an empty title fingerprints as app-only with an empty pattern")
    func fingerprintEmptyTitle() {
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry())
        let fingerprint = matcher.fingerprint(window: makeWindow(app: "UnknownApp", title: ""))
        #expect(fingerprint.matchStrategy == .appOnly)
        #expect(fingerprint.titlePattern.isEmpty)
    }

    @Test("window-matching-021: exact strategy matches case-insensitively and rejects extra text")
    func scoreExact() {
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry())
        let fingerprint = makeFingerprint(app: "UnknownApp", pattern: "report", strategy: .appAndTitleExact)
        #expect(matcher.score(window: makeWindow(app: "UnknownApp", title: "REPORT"), against: fingerprint) == 80)
        #expect(matcher.score(window: makeWindow(app: "UnknownApp", title: "report 2"), against: fingerprint) == 0)
    }

    @Test("window-matching-022: a stored pattern longer than the live title does not match")
    func scoreSubstringDirection() {
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry())
        let fingerprint = makeFingerprint(
            app: "UnknownApp", pattern: "project alpha", strategy: .appAndTitleSubstring
        )
        #expect(matcher.score(window: makeWindow(app: "UnknownApp", title: "alpha"), against: fingerprint) == 0)
    }

    @Test("window-matching-023: an invalid stored regex scores 0")
    func scoreRegexInvalid() {
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry())
        let fingerprint = makeFingerprint(app: "TestApp", pattern: "[", strategy: .appAndTitleRegex)
        // The vector also expects one logged error; os_log output is not observable from a unit test.
        #expect(matcher.score(window: makeWindow(app: "TestApp", title: "["), against: fingerprint) == 0)
    }

    @Test("window-matching-024: only dormant snapshots are re-matched and assigned windows are excluded")
    func excludesAssignedWindows() {
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry())
        let appOnly = makeFingerprint(app: "Terminal", pattern: "", strategy: .appOnly)
        let live = SystemWindowSnapshot(
            windowID: 7, fingerprint: appOnly, savedFrame: .zero, display: 0, app: "Terminal", title: ""
        )
        let dormant = makeSnapshot(app: "Terminal", fingerprint: appOnly)
        let context = SystemWindowContext(name: "C", windowSnapshots: [live, dormant])
        let windows = [
            makeWindow(id: 7, app: "Terminal", title: "one"),
            makeWindow(id: 8, app: "Terminal", title: "two")
        ]

        let result = matcher.matchWindows(contexts: [context], liveWindows: windows)
        #expect(result.matched.count == 1)
        #expect(result.matched.first?.snapshotID == dormant.id)
        #expect(result.matched.first?.window.id == 8)
        #expect(!result.unassignedWindows.contains { $0.id == 7 })
    }

    @Test("window-matching-031: a substring match on the same display scores 70 and is not auto-assigned")
    func substringDefaultThreshold() {
        let matcher = SystemWindowMatcher(registry: HeuristicRegistry())
        let fingerprint = makeFingerprint(
            app: "TestApp", pattern: "ban", strategy: .appAndTitleSubstring, display: 1
        )
        let window = makeWindow(id: 5, app: "TestApp", title: "banana", display: 1)
        #expect(matcher.score(window: window, against: fingerprint) == 70)

        let snapshot = makeSnapshot(app: "TestApp", fingerprint: fingerprint)
        let context = SystemWindowContext(name: "C", windowSnapshots: [snapshot])
        let result = matcher.matchWindows(contexts: [context], liveWindows: [window])
        #expect(result.matched.isEmpty)
    }
}
