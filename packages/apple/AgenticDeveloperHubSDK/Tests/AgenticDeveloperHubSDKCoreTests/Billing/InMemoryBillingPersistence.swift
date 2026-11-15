import Foundation
@testable import AgenticDeveloperHubSDKCore

/// An in-memory ``BillingPersistence`` for the conformance tests of the
/// billing rules (`BillingRollup`, `BillingStore`, `BillingTimer`).
///
/// It models only what those rules read back: rows are kept in insertion
/// order, `transaction` snapshots and restores on a throw (so a failed
/// transaction leaves nothing behind, as the real store does), and the
/// guards the real store applies in SQL (`BillingEntryOverwrite`, the
/// description-edited flag, the empty-entry delete) behave the same way.
final class InMemoryBillingPersistence: BillingPersistence {

    struct Failure: Error {}

    struct DerivedCall {
        let sessionId: String
        let runs: [BillingRun]
        let context: BillingSegmentContext
        let historyStartsAt: String?
    }

    struct Audit: Equatable {
        let entryId: String
        let field: String
        let oldValue: String
        let newValue: String
        let source: String
    }

    private struct State {
        var settings: [String: String] = [:]
        var clients: [BillingClientDTO] = []
        var projects: [BillingProjectDTO] = []
        var repos: [BillingRepoDTO] = []
        var segments: [BillingSegmentDTO] = []
        var entries: [BillingEntryDTO] = []
        var descriptionEdited: Set<String> = []
        var billedRanges: [String: String] = [:]
        var audits: [Audit] = []
        var derivedMarks: [String: String] = [:]
        var derivedCalls: [DerivedCall] = []
    }

    private var state = State()

    /// How many times `transaction` was entered (nested calls count).
    private(set) var transactionCalls = 0
    /// While true, `upsertBillingSegment` throws.
    var failSegmentUpserts = false
    /// Activity instants per session, as epoch seconds.
    var activity: [String: [Int]] = [:]

    var billingSettingsKeys: BillingSettingsKeys { BillingSettingsKeys(prefix: "test.billing.") }

    // MARK: Test access

    var clients: [BillingClientDTO] { state.clients }
    var projects: [BillingProjectDTO] {
        get { state.projects }
        set { state.projects = newValue }
    }
    var repos: [BillingRepoDTO] {
        get { state.repos }
        set { state.repos = newValue }
    }
    var segments: [BillingSegmentDTO] {
        get { state.segments }
        set { state.segments = newValue }
    }
    var entries: [BillingEntryDTO] {
        get { state.entries }
        set { state.entries = newValue }
    }
    var audits: [Audit] { state.audits }
    var derivedMarks: [String: String] { state.derivedMarks }
    var derivedCalls: [DerivedCall] { state.derivedCalls }

    func isDescriptionEdited(_ entryId: String) -> Bool { state.descriptionEdited.contains(entryId) }

    func segment(_ id: String) -> BillingSegmentDTO? { state.segments.first { $0.id == id } }

    // MARK: Settings and transactions

    func setting(for key: String) throws -> String? { state.settings[key] }
    func setSetting(_ key: String, _ value: String) throws { state.settings[key] = value }

    @discardableResult
    func transaction<T>(_ body: () throws -> T) throws -> T {
        transactionCalls += 1
        let before = state
        do {
            return try body()
        } catch {
            state = before
            throw error
        }
    }

    @discardableResult
    func resetBillingDerivationOfDerivedSessions() throws -> Int { 0 }

    @discardableResult
    func resetBillingDerivation(projectId: String) throws -> Int { 0 }

    // MARK: Clients

    func billingClients(includeArchived: Bool) throws -> [BillingClientDTO] {
        state.clients.filter { includeArchived || !$0.archived }
    }

    func billingClient(id: String) throws -> BillingClientDTO? { state.clients.first { $0.id == id } }

    func upsertBillingClient(_ dto: BillingClientDTO) throws {
        if let index = state.clients.firstIndex(where: { $0.id == dto.id }) {
            state.clients[index] = dto
        } else {
            state.clients.append(dto)
        }
    }

    func deleteBillingClient(id: String) throws { state.clients.removeAll { $0.id == id } }

    func billingLockedEntryCount(clientId: String) throws -> Int {
        state.entries.filter { $0.clientId == clientId && $0.locked }.count
    }

    // MARK: Projects

    func billingProjects(includeArchived: Bool) throws -> [BillingProjectDTO] {
        state.projects.filter { includeArchived || !$0.archived }
    }

    func billingProject(id: String) throws -> BillingProjectDTO? { state.projects.first { $0.id == id } }

    func upsertBillingProject(_ dto: BillingProjectDTO) throws {
        if let index = state.projects.firstIndex(where: { $0.id == dto.id }) {
            state.projects[index] = dto
        } else {
            state.projects.append(dto)
        }
    }

    func billingEntryCount(projectId: String) throws -> Int {
        state.entries.filter { $0.projectId == projectId }.count
    }

    func deleteBillingProject(id: String) throws { state.projects.removeAll { $0.id == id } }

    // MARK: Repos

    func billingRepos(projectId: String?) throws -> [BillingRepoDTO] {
        state.repos.filter { projectId == nil || $0.projectId == projectId }
    }

    func billingRepo(id: String) throws -> BillingRepoDTO? { state.repos.first { $0.id == id } }

    func upsertBillingRepo(_ dto: BillingRepoDTO) throws {
        if let index = state.repos.firstIndex(where: { $0.id == dto.id }) {
            state.repos[index] = dto
        } else {
            state.repos.append(dto)
        }
    }

    func deleteBillingRepo(id: String) throws { state.repos.removeAll { $0.id == id } }

    // MARK: Segments

    func billingSegment(id: String) throws -> BillingSegmentDTO? { segment(id) }

    func runningBillingSegments(origin: String?) throws -> [BillingSegmentDTO] {
        state.segments.filter { $0.isRunning && (origin == nil || $0.origin == origin) }
    }

    @discardableResult
    func closeBillingSegment(id: String, endedAt: String, seconds: Int) throws -> Bool {
        guard let index = state.segments.firstIndex(where: { $0.id == id }) else { return false }
        state.segments[index] = Self.copy(state.segments[index], endedAt: endedAt, seconds: seconds)
        return true
    }

    @discardableResult
    func addBillingSegmentFlag(id: String, flag: String) throws -> Bool {
        guard let index = state.segments.firstIndex(where: { $0.id == id }) else { return false }
        let old = state.segments[index]
        let flags = old.flags.split(separator: ",").map(String.init)
        guard !flags.contains(flag) else { return false }
        state.segments[index] = Self.copy(old, flags: (flags + [flag]).joined(separator: ","))
        return true
    }

    func upsertBillingSegment(_ dto: BillingSegmentDTO) throws {
        if failSegmentUpserts { throw Failure() }
        if let index = state.segments.firstIndex(where: { $0.id == dto.id }) {
            state.segments[index] = dto
        } else {
            state.segments.append(dto)
        }
    }

    // MARK: Derivation

    func billingHistoryStart(sessionId: String, sessionStartedAt: String) throws -> String? { nil }

    func billingActivitySeconds(sessionId: String, afterId: Int64) throws -> (seconds: [Int], lastId: Int64) {
        let all = activity[sessionId] ?? []
        return (afterId == 0 ? all : [], Int64(all.count))
    }

    func markBillingDerived(sessionId: String, at value: String) throws { state.derivedMarks[sessionId] = value }

    @discardableResult
    func replaceDerivedSegments(
        sessionId: String, runs: [BillingRun], context: BillingSegmentContext, historyStartsAt: String?
    ) throws -> Int {
        state.derivedCalls.append(DerivedCall(
            sessionId: sessionId, runs: runs, context: context, historyStartsAt: historyStartsAt
        ))
        return runs.count
    }

    // MARK: App-span derivation

    func billingAppSpansNeedingDerivation(limit: Int) throws -> [BillingAppSpanRow] { [] }
    func billingIdleIntervals(from start: String, to end: String) throws -> [BillingIdleInterval] { [] }
    func markAppSpanBillingDerived(spanId: String, at value: String) throws {}

    // MARK: Entries

    func billingEntries(projectId: String?, status: String?, since: String) throws -> [BillingEntryDTO] {
        state.entries.filter {
            (projectId == nil || $0.projectId == projectId) && (status == nil || $0.status == status)
        }
    }

    func billingEntry(id: String) throws -> BillingEntryDTO? { state.entries.first { $0.id == id } }

    @discardableResult
    func upsertBillingEntry(_ dto: BillingEntryDTO, overwrite: BillingEntryOverwrite) throws -> Bool {
        if let index = state.entries.firstIndex(where: { $0.id == dto.id }) {
            let existing = state.entries[index]
            switch overwrite {
            case .any: break
            case .unlocked: if existing.locked { return false }
            case .rollupOwned: if existing.locked || existing.origin != "auto" { return false }
            }
            state.entries[index] = dto
        } else {
            state.entries.append(dto)
        }
        return true
    }

    func deleteBillingEntry(id: String) throws {
        state.entries.removeAll { $0.id == id }
        detachSegments(of: id)
    }

    func billingFrozenSupplementCount(of entryId: String) throws -> Int {
        state.entries.filter {
            $0.supplementsEntryId == entryId
                && ($0.locked || $0.origin == "user" || state.descriptionEdited.contains($0.id))
        }.count
    }

    func billingEntryForSlot(projectId: String, day: String, groupKey: String) throws -> StoredBillingEntry? {
        state.entries.first {
            $0.projectId == projectId && $0.day == day && $0.groupKey == groupKey && $0.supplementsEntryId == nil
        }.map(stored)
    }

    func billingOpenSupplement(of entryId: String) throws -> StoredBillingEntry? {
        state.entries.first { $0.supplementsEntryId == entryId && !$0.locked && $0.origin == "auto" }.map(stored)
    }

    func billingEntriesOnDay(projectId: String, day: String) throws -> [StoredBillingEntry] {
        state.entries.filter { $0.projectId == projectId && $0.day == day }
            .sorted { $0.createdAt < $1.createdAt }.map(stored)
    }

    /// A superset, which the protocol allows: every entry of the project.
    func billingEntriesOverlapping(projectId: String, from: String, until: String) throws -> [StoredBillingEntry] {
        state.entries.filter { $0.projectId == projectId }.map(stored)
    }

    func billingEntryDays() throws -> [BillingProjectDay] {
        var seen: [BillingProjectDay] = []
        for entry in state.entries {
            let day = BillingProjectDay(projectId: entry.projectId, day: entry.day)
            if !seen.contains(day) { seen.append(day) }
        }
        return seen
    }

    func billingUnsettledDays() throws -> [BillingProjectDay] { try billingEntryDays() }

    func setBillingEntryBilledRanges(id: String, ranges: String) throws { state.billedRanges[id] = ranges }

    @discardableResult
    func deleteEmptyBillingEntry(id: String) throws -> Bool {
        guard let entry = state.entries.first(where: { $0.id == id }), !entry.locked, entry.origin == "auto",
              !state.segments.contains(where: { $0.entryId == id }),
              !state.entries.contains(where: { $0.supplementsEntryId == id }),
              !state.descriptionEdited.contains(id) else { return false }
        state.entries.removeAll { $0.id == id }
        return true
    }

    func markBillingEntryDescriptionEdited(id: String) throws { state.descriptionEdited.insert(id) }

    @discardableResult
    func setBillingEntryDescription(id: String, description: String, at now: String) throws -> Bool {
        guard let index = state.entries.firstIndex(where: { $0.id == id }), !state.entries[index].locked else {
            return false
        }
        state.entries[index] = state.entries[index].testCopy(description: description)
        state.descriptionEdited.insert(id)
        return true
    }

    /// Closed, unrolled segments of billing-enabled projects.
    func billingRollupCandidates(ids: [String]?) throws -> [BillingSegmentDTO] {
        state.segments.filter { segment in
            guard !segment.isRunning, segment.entryId == nil, let projectId = segment.projectId,
                  let project = state.projects.first(where: { $0.id == projectId }), project.billingEnabled,
                  !segment.flags.contains("untracked") else { return false }
            return ids == nil || ids?.contains(segment.id) == true
        }
    }

    func billingSegmentsForEntry(id: String) throws -> [BillingSegmentDTO] {
        state.segments.filter { $0.entryId == id }
    }

    func attachSegments(ids: [String], toEntry entryId: String) throws {
        for index in state.segments.indices where ids.contains(state.segments[index].id) {
            state.segments[index] = Self.copy(state.segments[index], entryId: .some(entryId))
        }
    }

    func appendBillingAudit(entryId: String, field: String, oldValue: String, newValue: String, source: String) throws {
        state.audits.append(Audit(
            entryId: entryId, field: field, oldValue: oldValue, newValue: newValue, source: source
        ))
    }

    func billingSessionTitles(sessionIds: [String]) throws -> BillingSessionTitles {
        BillingSessionTitles(titles: [], missing: [])
    }

    // MARK: Assignment and overview

    func unassignedSegmentIDs(projectRoot: String) throws -> [String] {
        state.segments.filter { $0.projectId == nil && $0.projectRoot == projectRoot }.map(\.id)
    }

    func assignSegments(ids: [String], toProject projectId: String?) throws -> Int {
        var moved = 0
        for index in state.segments.indices where ids.contains(state.segments[index].id) {
            state.segments[index] = Self.copy(state.segments[index], projectId: .some(projectId))
            moved += 1
        }
        return moved
    }

    func billingOverviewBuckets() throws -> [(currency: String, buckets: [String: BillingOverviewBucketDTO])] {
        var currencies: [String] = []
        for entry in state.entries where !currencies.contains(entry.currency) { currencies.append(entry.currency) }
        return currencies.map { currency in
            var buckets: [String: BillingOverviewBucketDTO] = [:]
            for entry in state.entries where entry.currency == currency {
                let old = buckets[entry.status] ?? BillingOverviewBucketDTO(seconds: 0, amountCents: 0, entryCount: 0)
                buckets[entry.status] = BillingOverviewBucketDTO(
                    seconds: old.seconds + entry.billedSeconds, amountCents: old.amountCents + entry.amountCents,
                    entryCount: old.entryCount + 1
                )
            }
            return (currency: currency, buckets: buckets)
        }
    }

    // MARK: Helpers

    private func stored(_ entry: BillingEntryDTO) -> StoredBillingEntry {
        StoredBillingEntry(
            entry: entry, descriptionEdited: state.descriptionEdited.contains(entry.id),
            billedRanges: state.billedRanges[entry.id]
        )
    }

    private func detachSegments(of entryId: String) {
        for index in state.segments.indices where state.segments[index].entryId == entryId {
            state.segments[index] = Self.copy(state.segments[index], entryId: .some(nil))
        }
    }

    private static func copy(
        _ old: BillingSegmentDTO, projectId: String?? = nil, entryId: String?? = nil,
        endedAt: String? = nil, seconds: Int? = nil, flags: String? = nil
    ) -> BillingSegmentDTO {
        BillingSegmentDTO(
            id: old.id, sessionId: old.sessionId, origin: old.origin,
            projectId: projectId ?? old.projectId, repoId: old.repoId,
            projectRoot: old.projectRoot, branch: old.branch, startedAt: old.startedAt,
            endedAt: endedAt ?? old.endedAt, tz: old.tz, seconds: seconds ?? old.seconds,
            note: old.note, entryId: entryId ?? old.entryId, flags: flags ?? old.flags,
            createdAt: old.createdAt, updatedAt: old.updatedAt
        )
    }
}

extension BillingEntryDTO {
    /// This entry with some fields replaced; everything else is kept.
    func testCopy(
        rawSeconds: Int? = nil, billedSeconds: Int? = nil, amountCents: Int? = nil,
        status: String? = nil, description: String? = nil, updatedAt: String? = nil
    ) -> BillingEntryDTO {
        BillingEntryDTO(
            id: id, projectId: projectId, clientId: clientId, day: day, groupKey: groupKey,
            startedAt: startedAt, endedAt: endedAt,
            rawSeconds: rawSeconds ?? self.rawSeconds, billedSeconds: billedSeconds ?? self.billedSeconds,
            rateCents: rateCents, currency: currency, amountCents: amountCents ?? self.amountCents,
            roundingMinutes: roundingMinutes, roundingMode: roundingMode,
            status: status ?? self.status, description: description ?? self.description,
            origin: origin, locked: locked, supplementsEntryId: supplementsEntryId,
            createdAt: createdAt, updatedAt: updatedAt ?? self.updatedAt
        )
    }
}
