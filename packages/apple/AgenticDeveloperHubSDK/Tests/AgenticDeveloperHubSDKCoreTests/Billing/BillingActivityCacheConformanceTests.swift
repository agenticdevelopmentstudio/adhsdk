import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for `BillingActivityCache`: the merge rules, the
/// cursor, `forget` and the capacity bound.
final class BillingActivityCacheConformanceTests: XCTestCase {

    // MARK: merging

    func testV001_mergeAppendFastPath() {
        XCTAssertEqual(BillingActivityCache.merging([30, 20], into: [10]), [10, 20, 30])
    }

    func testV002_mergeInterleavesSortedAndUnique() {
        XCTAssertEqual(BillingActivityCache.merging([5, 15, 15], into: [10, 20]), [5, 10, 15, 20])
    }

    func testV003_mergeOfIdenticalValuesKeepsOne() {
        XCTAssertEqual(BillingActivityCache.merging([10, 20], into: [10, 20]), [10, 20])
    }

    func testV004_emptyFreshReturnsSortedUnchanged() {
        XCTAssertEqual(BillingActivityCache.merging([], into: [1, 2]), [1, 2])
    }

    func testV005_unorderedFreshIntoEmptyIsSorted() {
        XCTAssertEqual(BillingActivityCache.merging([3, 1, 2], into: []), [1, 2, 3])
    }

    // MARK: cursor, forget, bound

    func testV006_secondCallReadsAfterTheReturnedLastId() throws {
        let store = StubActivityStore()
        store.next = (seconds: [100, 200], lastId: 40)
        let cache = BillingActivityCache()
        let first = try cache.activitySeconds(sessionId: "s1", database: store)
        XCTAssertEqual(first, [100, 200])
        store.next = (seconds: [300], lastId: 55)
        let second = try cache.activitySeconds(sessionId: "s1", database: store)
        XCTAssertEqual(store.reads.map(\.afterId), [0, 40])
        XCTAssertEqual(second, [100, 200, 300])
    }

    func testV007_forgetMakesTheNextCallReadFromZero() throws {
        let store = StubActivityStore()
        store.next = (seconds: [100], lastId: 40)
        let cache = BillingActivityCache()
        _ = try cache.activitySeconds(sessionId: "s1", database: store)
        cache.forget(sessionId: "s1")
        XCTAssertEqual(cache.count, 0)
        _ = try cache.activitySeconds(sessionId: "s1", database: store)
        XCTAssertEqual(store.reads.map(\.afterId), [0, 0])
    }

    func testV008_boundedToCapacityEvictingTheFirstSession() throws {
        let store = StubActivityStore()
        store.next = (seconds: [1], lastId: 7)
        let cache = BillingActivityCache(capacity: 64)
        XCTAssertEqual(cache.capacity, 64)
        for index in 0..<65 {
            _ = try cache.activitySeconds(sessionId: "session-\(index)", database: store)
        }
        XCTAssertEqual(cache.count, 64)
        let before = store.reads.count
        // The evicted first session costs one full read; a held one reads the tail.
        _ = try cache.activitySeconds(sessionId: "session-64", database: store)
        XCTAssertEqual(store.reads[before].afterId, 7)
        _ = try cache.activitySeconds(sessionId: "session-0", database: store)
        XCTAssertEqual(store.reads[before + 1].afterId, 0)
    }
}

/// Answers only the activity read; every other requirement is unused here.
private final class StubActivityStore: BillingPersistence {
    var next: (seconds: [Int], lastId: Int64) = ([], 0)
    var reads: [(sessionId: String, afterId: Int64)] = []

    func billingActivitySeconds(sessionId: String, afterId: Int64) throws -> (seconds: [Int], lastId: Int64) {
        reads.append((sessionId, afterId))
        return next
    }

    private struct Unused: Error {}

    var billingSettingsKeys: BillingSettingsKeys { BillingSettingsKeys(prefix: "test_") }
    func setting(for key: String) throws -> String? { throw Unused() }
    func setSetting(_ key: String, _ value: String) throws { throw Unused() }
    func transaction<T>(_ body: () throws -> T) throws -> T { throw Unused() }
    func resetBillingDerivationOfDerivedSessions() throws -> Int { throw Unused() }
    func resetBillingDerivation(projectId: String) throws -> Int { throw Unused() }
    func billingClients(includeArchived: Bool) throws -> [BillingClientDTO] { throw Unused() }
    func billingClient(id: String) throws -> BillingClientDTO? { throw Unused() }
    func upsertBillingClient(_ dto: BillingClientDTO) throws { throw Unused() }
    func deleteBillingClient(id: String) throws { throw Unused() }
    func billingLockedEntryCount(clientId: String) throws -> Int { throw Unused() }
    func billingProjects(includeArchived: Bool) throws -> [BillingProjectDTO] { throw Unused() }
    func billingProject(id: String) throws -> BillingProjectDTO? { throw Unused() }
    func upsertBillingProject(_ dto: BillingProjectDTO) throws { throw Unused() }
    func billingEntryCount(projectId: String) throws -> Int { throw Unused() }
    func deleteBillingProject(id: String) throws { throw Unused() }
    func billingRepos(projectId: String?) throws -> [BillingRepoDTO] { throw Unused() }
    func billingRepo(id: String) throws -> BillingRepoDTO? { throw Unused() }
    func upsertBillingRepo(_ dto: BillingRepoDTO) throws { throw Unused() }
    func deleteBillingRepo(id: String) throws { throw Unused() }
    func billingSegment(id: String) throws -> BillingSegmentDTO? { throw Unused() }
    func runningBillingSegments(origin: String?) throws -> [BillingSegmentDTO] { throw Unused() }
    func closeBillingSegment(id: String, endedAt: String, seconds: Int) throws -> Bool { throw Unused() }
    func addBillingSegmentFlag(id: String, flag: String) throws -> Bool { throw Unused() }
    func upsertBillingSegment(_ dto: BillingSegmentDTO) throws { throw Unused() }
    func billingHistoryStart(sessionId: String, sessionStartedAt: String) throws -> String? { throw Unused() }
    func markBillingDerived(sessionId: String, at value: String) throws { throw Unused() }
    func replaceDerivedSegments(
        sessionId: String, runs: [BillingRun], context: BillingSegmentContext, historyStartsAt: String?
    ) throws -> Int { throw Unused() }
    func billingAppSpansNeedingDerivation(limit: Int) throws -> [BillingAppSpanRow] { throw Unused() }
    func billingIdleIntervals(from start: String, to end: String) throws -> [BillingIdleInterval] { throw Unused() }
    func markAppSpanBillingDerived(spanId: String, at value: String) throws { throw Unused() }
    func billingEntries(projectId: String?, status: String?, since: String) throws
        -> [BillingEntryDTO] { throw Unused() }
    func billingEntry(id: String) throws -> BillingEntryDTO? { throw Unused() }
    func upsertBillingEntry(_ dto: BillingEntryDTO, overwrite: BillingEntryOverwrite) throws -> Bool { throw Unused() }
    func deleteBillingEntry(id: String) throws { throw Unused() }
    func billingFrozenSupplementCount(of entryId: String) throws -> Int { throw Unused() }
    func billingEntryForSlot(projectId: String, day: String, groupKey: String) throws
        -> StoredBillingEntry? { throw Unused() }
    func billingOpenSupplement(of entryId: String) throws -> StoredBillingEntry? { throw Unused() }
    func billingEntriesOnDay(projectId: String, day: String) throws -> [StoredBillingEntry] { throw Unused() }
    func billingEntriesOverlapping(projectId: String, from: String, until: String) throws
        -> [StoredBillingEntry] { throw Unused() }
    func billingEntryDays() throws -> [BillingProjectDay] { throw Unused() }
    func billingUnsettledDays() throws -> [BillingProjectDay] { throw Unused() }
    func setBillingEntryBilledRanges(id: String, ranges: String) throws { throw Unused() }
    func deleteEmptyBillingEntry(id: String) throws -> Bool { throw Unused() }
    func markBillingEntryDescriptionEdited(id: String) throws { throw Unused() }
    func setBillingEntryDescription(id: String, description: String, at now: String) throws -> Bool { throw Unused() }
    func billingRollupCandidates(ids: [String]?) throws -> [BillingSegmentDTO] { throw Unused() }
    func billingSegmentsForEntry(id: String) throws -> [BillingSegmentDTO] { throw Unused() }
    func attachSegments(ids: [String], toEntry entryId: String) throws { throw Unused() }
    func appendBillingAudit(
        entryId: String, field: String, oldValue: String, newValue: String, source: String
    ) throws { throw Unused() }
    func billingSessionTitles(sessionIds: [String]) throws -> BillingSessionTitles { throw Unused() }
    func unassignedSegmentIDs(projectRoot: String) throws -> [String] { throw Unused() }
    func assignSegments(ids: [String], toProject projectId: String?) throws -> Int { throw Unused() }
    func billingOverviewBuckets() throws
        -> [(currency: String, buckets: [String: BillingOverviewBucketDTO])] { throw Unused() }
}
