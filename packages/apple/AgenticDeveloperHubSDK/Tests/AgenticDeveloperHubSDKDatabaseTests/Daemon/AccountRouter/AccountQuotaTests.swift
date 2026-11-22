import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// Unit tests for the per-account quota plumbing: rate-limit header
/// interpretation, the probe store's cache, run-out projection math, and section
/// assembly. No network — the store takes an injected prober, and the header
/// reading under test is pure.
final class AccountQuotaTests: XCTestCase {

    // MARK: - Header interpretation

    func testReadingNormalizesFractionToPercent() {
        // Utilization is always a 0–1 fraction, even over quota — a 27%
        // account sends 0.27, and an over-quota account sends e.g. 1.05
        // (105%). Always multiply by 100; never branch on value <= 1 (that
        // heuristic truncated over-quota fractions down to ~1%).
        let fraction = Sessions.AccountQuotaReadingDTO(account: "a", headers: [
            "anthropic-ratelimit-unified-5h-utilization": "0.18",
            "anthropic-ratelimit-unified-7d-utilization": "0.27"
        ])
        XCTAssertEqual(fraction.fiveHourPct ?? -1, 18.0, accuracy: 0.001)
        XCTAssertEqual(fraction.sevenDayPct ?? -1, 27.0, accuracy: 0.001)
        XCTAssertNil(fraction.errorText)
    }

    func testReadingOverQuotaFractionIsNotTruncated() {
        // EVIDENCE: a 105%-used account's header is "1.05", not "105". The
        // old `value <= 1 ? value * 100 : value` heuristic hit the `else`
        // branch here and rendered "1.0%" instead of "105.0%".
        let over = Sessions.AccountQuotaReadingDTO(account: "a", headers: [
            "anthropic-ratelimit-unified-5h-utilization": "1.05",
            "anthropic-ratelimit-unified-7d-utilization": "1.0"
        ])
        XCTAssertEqual(over.fiveHourPct ?? -1, 105.0, accuracy: 0.001)
        XCTAssertEqual(over.sevenDayPct ?? -1, 100.0, accuracy: 0.001)
    }

    func testReadingNormalizesMillisecondResets() {
        let reading = Sessions.AccountQuotaReadingDTO(account: "a", headers: [
            "anthropic-ratelimit-unified-5h-utilization": "0.5",
            "anthropic-ratelimit-unified-5h-reset": "1750000000000"   // ms epoch
        ])
        XCTAssertEqual(reading.fiveHourResetsAt, 1_750_000_000)
    }

    func testReadingWithoutUsageHeadersCarriesError() {
        let reading = Sessions.AccountQuotaReadingDTO(account: "a", headers: [:])
        XCTAssertNil(reading.fiveHourPct)
        XCTAssertNil(reading.sevenDayPct)
        XCTAssertNotNil(reading.errorText)
    }

    // MARK: - Run-out projection

    func testRunOutBeforeResetProjectsAndColors() {
        let now = 1_000_000
        // 5h window, halfway through (elapsed 9000s), 80% used → burn rate
        // hits 100% in 2250s, well before the reset 9000s out. <1h ⇒ red.
        let runOut = DaemonDatabase.quotaRunOut(
            pct: 80, resetsAt: now + 9000, windowSeconds: 5 * 3600, now: now
        )
        XCTAssertEqual(runOut?.text, "🛑 37m")
        XCTAssertEqual(runOut?.color, "red")
    }

    func testRunOutAfterResetIsNil() {
        let now = 1_000_000
        // Same window, only 10% used → projected run-out lands after the
        // reset, so there is nothing to warn about.
        XCTAssertNil(DaemonDatabase.quotaRunOut(
            pct: 10, resetsAt: now + 9000, windowSeconds: 5 * 3600, now: now
        ))
    }

    func testRunOutYellowWhenHoursAway() {
        let now = 2_000_000
        // 7d window, 2 days in, 50% used → runs out 2 days from now (before
        // the 5-days-out reset). Not imminent ⇒ yellow.
        let runOut = DaemonDatabase.quotaRunOut(
            pct: 50, resetsAt: now + 5 * 86400, windowSeconds: 7 * 86400, now: now
        )
        XCTAssertEqual(runOut?.text, "🛑 2d 0h")
        XCTAssertEqual(runOut?.color, "yellow")
    }

    /// The span the words are written from ships beside them, because the card
    /// warns about ONE window — the soonest — and cannot pick it out of `2d 0h`.
    func testTheProjectionShipsTheSpanItSpelledOut() {
        let now = 1_000_000
        XCTAssertEqual(DaemonDatabase.quotaRunOut(
            pct: 80, resetsAt: now + 9000, windowSeconds: 5 * 3600, now: now
        )?.seconds, 2250)
        // A spent window is no time at all, which is exactly what has to sort
        // it ahead of every projection that still has some left.
        XCTAssertEqual(DaemonDatabase.quotaRunOut(
            pct: 100, resetsAt: now + 1000, windowSeconds: 18000, now: now
        )?.seconds, 0)
    }

    /// The projection waits behind the same 1% the pace under the gauge does,
    /// so a run-out never shows before the pace that explains it.
    func testRunOutWaitsForOnePercentOfTheWindow() {
        let now = 5_000_000
        let week = 7 * 86400
        // 1h into a 7d week (under 1h 41m): nothing projected yet.
        XCTAssertNil(DaemonDatabase.quotaRunOut(
            pct: 5, resetsAt: now + week - 3600, windowSeconds: week, now: now))
        // 2h in, 5% spent: projected, ~38h out.
        XCTAssertNotNil(DaemonDatabase.quotaRunOut(
            pct: 5, resetsAt: now + week - 7200, windowSeconds: week, now: now))
        // A spent window is still "now" however early it is.
        XCTAssertEqual(DaemonDatabase.quotaRunOut(
            pct: 100, resetsAt: now + week - 60, windowSeconds: week, now: now)?.text, "🛑 now")
    }

    func testRunOutEdgeCases() {
        let now = 3_000_000
        // Exhausted quota → "now", red.
        XCTAssertEqual(DaemonDatabase.quotaRunOut(
            pct: 100, resetsAt: now + 1000, windowSeconds: 18000, now: now
        )?.text, "🛑 now")
        // Stale reset (in the past) and zero usage → nothing to project.
        XCTAssertNil(DaemonDatabase.quotaRunOut(
            pct: 50, resetsAt: now - 1, windowSeconds: 18000, now: now
        ))
        XCTAssertNil(DaemonDatabase.quotaRunOut(
            pct: 0, resetsAt: now + 9000, windowSeconds: 18000, now: now
        ))
    }

    // MARK: - Section assembly

    func testBuildAccountSectionsBuildsRows() {
        let now = 4_000_000
        let readings = [
            Sessions.AccountQuotaReadingDTO(
                account: "a@x.com",
                fiveHourPct: 18, fiveHourResetsAt: now + 2 * 3600,
                sevenDayPct: 4, sevenDayResetsAt: now + 4 * 86400
            ),
            Sessions.AccountQuotaReadingDTO(account: "b@x.com", errorText: "token invalid")
        ]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now,
            snapshotFor: { _ in nil },
            fableShareFor: { _, _ in 0.25 }
        )
        XCTAssertEqual(sections.count, 2)

        let first = sections[0]
        XCTAssertEqual(first.accountEmail, "a@x.com")
        // Fable stands AFTER the 7d row it is carved out of, so the two real
        // windows are side by side and the derived figure ends the line: the
        // two share a reset, so the array order is the only thing that decides
        // which of them lands where.
        XCTAssertEqual(first.rows.map(\.label),
                       ["7d quota", Sessions.UsageQuotaRowDTO.fableLabel, "5h quota"])
        XCTAssertEqual(first.rows[0].pctText, "4.0%")
        // A quarter of that 4% week went on Fable — 1 of the week's hundred
        // points — which is 2% of the fifty points Fable is allowed.
        XCTAssertEqual(first.rows[1].pctText, "2.0%")
        // A sub-limit has no clock of its own: it is forgiven when the window
        // it is a slice of resets, and counts down to that same instant.
        XCTAssertEqual(first.rows[0].secondaryText, "-4d 0h 00m")
        XCTAssertEqual(first.rows[1].secondaryText, "-4d 0h 00m")
        XCTAssertEqual(first.rows[2].secondaryText, "-2h 00m")

        let second = sections[1]
        XCTAssertTrue(second.rows.isEmpty)
        XCTAssertEqual(second.errorText, "token invalid")
    }

    func testAccountRowsCarryRawResetEpochForLiveCountdown() {
        // The pre-formatted `secondaryText` is a once-per-refresh snapshot; the
        // raw reset epoch must also ride each row so a client (the Account Usage
        // window) can tick a live countdown from it.
        let now = 4_000_000
        let readings = [Sessions.AccountQuotaReadingDTO(
            account: "a@x.com",
            fiveHourPct: 18, fiveHourResetsAt: now + 2 * 3600,
            sevenDayPct: 4, sevenDayResetsAt: now + 4 * 86400
        )]
        let rows = DaemonDatabase.buildAccountSections(
            readings: readings, now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in nil }
        )[0].rows
        XCTAssertEqual(rows.first { $0.label == "7d quota" }?.resetsAt, now + 4 * 86400)
        XCTAssertEqual(rows.first { $0.label == "5h quota" }?.resetsAt, now + 2 * 3600)
    }

    // MARK: - What the snapshot is allowed to contribute

    private func snapshot(ageSeconds: Int, now: Int,
                          weekly: Double, fiveHour: Double,
                          spendPct: Double = 0, spendResetsAt: Int = 0) -> Sessions.RateLimitSnapshotDTO {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return Sessions.RateLimitSnapshotDTO(
            id: 1,
            timestamp: fmt.string(from: Date(timeIntervalSince1970: Double(now - ageSeconds))),
            sessionId: "s", weekStart: "", elapsedHours: 0, elapsedDay: 0,
            weeklyPct: weekly, dailyAvgPct: 0, fiveHourPct: fiveHour,
            fiveHourResetsAt: now + 600, sevenDayResetsAt: now + 4 * 86400,
            projectedPct: 0, spendPct: spendPct, spendResetsAt: spendResetsAt
        )
    }

    func testNoSnapshotEverReplacesAProbedPercentage() {
        // This used to assert the opposite, and the opposite was the bug: a
        // fresh snapshot's numbers were painted onto the probed card. A
        // snapshot is a reading of whatever credential the session that wrote
        // it was running as, which is not the credential this card names — so
        // with five cards on screen the newest session's 71% was drawn on
        // several of them at once, countdowns and all. The probe is this
        // card's only measurement.
        let now = 5_000_000
        let readings = [Sessions.AccountQuotaReadingDTO(
            account: "a@x.com",
            fiveHourPct: 1, fiveHourResetsAt: now + 600, fiveHourStatus: "rejected",
            sevenDayPct: 20, sevenDayResetsAt: now + 4 * 86400
        )]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now,
            snapshotFor: { _ in self.snapshot(ageSeconds: 120, now: now, weekly: 18, fiveHour: 91) },
            fableShareFor: { _, _ in nil }
        )
        let rows = sections[0].rows
        XCTAssertEqual(rows.first { $0.label == "5h quota" }?.pctText, "1.0%",
            "the probe measured this credential; the snapshot measured another")
        XCTAssertEqual(rows.first { $0.label == "7d quota" }?.pctText, "20.0%")
        // And the probe's own rejected status survives, which the override used
        // to paint over: an over-quota window reading 1% is still over quota.
        XCTAssertEqual(rows.first { $0.label == "5h quota" }?.pctColor, "red")
    }

    func testAProbedWindowKeepsItsOwnStatusAndColor() {
        // The companion case: nothing about snapshot age changes a percentage
        // any more, so what this pins is the probe's own colouring — rejected
        // paints red however small the number, allowed keeps the thresholds.
        let now = 6_000_000
        let readings = [Sessions.AccountQuotaReadingDTO(
            account: "b@x.com",
            fiveHourPct: 7, fiveHourResetsAt: now + 600, fiveHourStatus: "rejected",
            sevenDayPct: 3, sevenDayResetsAt: now + 4 * 86400, sevenDayStatus: "allowed"
        )]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now,
            snapshotFor: { _ in self.snapshot(ageSeconds: 3 * 3600, now: now, weekly: 99, fiveHour: 99) },
            fableShareFor: { _, _ in nil }
        )
        let rows = sections[0].rows
        XCTAssertEqual(rows.first { $0.label == "5h quota" }?.pctText, "7.0%")
        XCTAssertEqual(rows.first { $0.label == "5h quota" }?.pctColor, "red",
            "a rejected probe window is red regardless of its small %")
        XCTAssertNil(rows.first { $0.label == "7d quota" }?.pctColor,
            "allowed window keeps threshold coloring (3% -> none)")
    }

    func testTheSpendRowIsTheOneThingASnapshotStillContributes() {
        // No response header reports a spend window, so this row comes from the
        // account's own fresh snapshot or not at all — the single remaining
        // reason `buildAccountSections` looks a snapshot up.
        let now = 7_000_000
        let readings = [Sessions.AccountQuotaReadingDTO(
            account: "a@x.com", credentialKind: ClaudeCredentialKind.oauth.rawValue,
            sevenDayPct: 20, sevenDayResetsAt: now + 4 * 86400
        )]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now,
            snapshotFor: { _ in self.snapshot(
                ageSeconds: 120, now: now, weekly: 18, fiveHour: 91,
                spendPct: 42, spendResetsAt: now + 3 * 86400) },
            fableShareFor: { _, _ in nil }
        )
        let spend = sections[0].rows.first { $0.label == Sessions.UsageQuotaRowDTO.spendLabel }
        XCTAssertEqual(spend?.pctText, "42.0%")
    }

    func testALongLivedCredentialGetsNoSpendRow() {
        // A snapshot is written by a live Claude Code session, which runs as the
        // logged-in account. A setup token is something to bill against, never
        // something a session runs as — so a spend row on its card would be the
        // login's number under the token's heading.
        let now = 7_000_000
        let readings = [Sessions.AccountQuotaReadingDTO(
            account: "a@x.com", credentialKind: ClaudeCredentialKind.longLived.rawValue,
            sevenDayPct: 20, sevenDayResetsAt: now + 4 * 86400
        )]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now,
            snapshotFor: { _ in self.snapshot(
                ageSeconds: 120, now: now, weekly: 18, fiveHour: 91,
                spendPct: 42, spendResetsAt: now + 3 * 86400) },
            fableShareFor: { _, _ in nil }
        )
        XCTAssertNil(sections[0].rows.first { $0.label == Sessions.UsageQuotaRowDTO.spendLabel })
    }

    func testTwoCredentialsForOneEmailAreTwoSections() {
        // "I just imported and the types were combined, do NOT combine them,
        // they are seperate things": a setup token and the same address's login
        // are metered separately, so one email can read 100% on one and 8% on
        // the other at the same instant. Two readings in, two titled sections
        // out, each with its own identity for the preference that hides it.
        let now = 8_000_000
        let readings = [
            Sessions.AccountQuotaReadingDTO(
                account: "a@x.com", credentialKind: ClaudeCredentialKind.oauth.rawValue,
                sevenDayPct: 8, sevenDayResetsAt: now + 4 * 86400
            ),
            Sessions.AccountQuotaReadingDTO(
                account: "a@x.com", credentialKind: ClaudeCredentialKind.longLived.rawValue,
                sevenDayPct: 100, sevenDayResetsAt: now + 4 * 86400,
                sevenDayStatus: "rejected"
            )
        ]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in nil }
        )
        XCTAssertEqual(sections.map(\.accountEmail), ["a@x.com", "a@x.com"])
        XCTAssertEqual(sections.map(\.identity), ["oauth:a@x.com", "long-lived:a@x.com"])
        XCTAssertEqual(sections[0].rows.first?.pctText, "8.0%")
        XCTAssertEqual(sections[1].rows.first?.pctText, "100.0%")
    }

    // MARK: - The probe store

    func testStoreProbesEveryPushedCredentialAndCachesWhatCameBack() {
        let store = AccountQuotaProbe(prober: { token in
            if token == "t2" { throw URLError(.timedOut) }
            return [
                "anthropic-ratelimit-unified-5h-utilization": "0.25",
                "anthropic-ratelimit-unified-7d-utilization": "0.75"
            ]
        })
        XCTAssertTrue(store.current().isEmpty, "no readings before the first probe")

        store.setCredentials([
            Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "oauth", token: "t1"),
            Sessions.ClaudeCredentialDTO(account: "b@x.com", credentialKind: "oauth", token: "t2")
        ])
        store.refreshNow()

        let readings = store.current()
        XCTAssertEqual(readings.map(\.account), ["a@x.com", "b@x.com"])
        XCTAssertEqual(readings[0].fiveHourPct ?? -1, 25.0, accuracy: 0.001)
        XCTAssertEqual(readings[0].sevenDayPct ?? -1, 75.0, accuracy: 0.001)
        XCTAssertNil(readings[0].errorText)
        // A probe that can't complete is the account's reading too: its card says
        // why instead of drawing a percentage nobody measured.
        XCTAssertNotNil(readings[1].errorText, "a failed probe surfaces as errorText")
        XCTAssertNil(readings[1].fiveHourPct)
    }

    /// The live login is pushed probe-only, and its copy's access token dies
    /// whenever Claude Code sits idle overnight. That 401 is "not refreshed yet",
    /// not a broken account, so the card keeps its last numbers.
    func testTheLiveLoginKeepsItsLastReadingThroughAnExpiredCopy() {
        let rejecting = RejectSwitch()
        let store = AccountQuotaProbe(prober: { _ in
            if rejecting.isOn {
                throw NSError(
                    domain: "AccountQuota", code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "token invalid or expired"])
            }
            return ["anthropic-ratelimit-unified-5h-utilization": "0.40"]
        })
        let refreshable = ClaudeOAuthCredential(accessToken: "t2", refreshToken: "r2")
        store.setCredentials([
            Sessions.ClaudeCredentialDTO(account: "live@x.com", credentialKind: "oauth", token: "t1"),
            Sessions.ClaudeCredentialDTO(
                account: "saved@x.com", credentialKind: "oauth", token: "t2", oauth: refreshable),
            Sessions.ClaudeCredentialDTO(account: "token@x.com", credentialKind: "long-lived", token: "t3")
        ])
        store.refreshNow()
        rejecting.isOn = true
        store.refreshNow()

        let readings = store.current()
        XCTAssertNil(readings[0].errorText, "the probe-only live login keeps its reading")
        XCTAssertEqual(readings[0].fiveHourPct ?? -1, 40.0, accuracy: 0.001)
        XCTAssertNotNil(readings[1].errorText, "a login the daemon can refresh reports the 401")
        XCTAssertNotNil(readings[2].errorText, "a setup token has no Claude Code to refresh it")
    }

    private final class RejectSwitch: @unchecked Sendable {
        private let lock = NSLock()
        private var value = false
        var isOn: Bool {
            get { lock.lock(); defer { lock.unlock() }; return value }
            set { lock.lock(); value = newValue; lock.unlock() }
        }
    }

    func testStoreProbesOnlyWhatTheSetStillHolds() {
        // The app pushes the whole set every time, so an account it no longer has
        // must disappear here — keeping it would serve a deleted account's last
        // reading forever.
        let store = AccountQuotaProbe(prober: { _ in
            ["anthropic-ratelimit-unified-5h-utilization": "0.30"]
        })
        store.setCredentials([
            Sessions.ClaudeCredentialDTO(account: "a@x.com", token: "t1"),
            Sessions.ClaudeCredentialDTO(account: "gone@x.com", token: "t2")
        ])
        store.refreshNow()
        XCTAssertEqual(store.current().map(\.account), ["a@x.com", "gone@x.com"])

        store.setCredentials([Sessions.ClaudeCredentialDTO(account: "a@x.com", token: "t1")])
        store.refreshNow()
        XCTAssertEqual(store.current().map(\.account), ["a@x.com"])
        XCTAssertEqual(store.current()[0].fiveHourPct ?? -1, 30.0, accuracy: 0.001)
    }

    func testAnUnchangedPushCostsNothingAndAChangedOneInvalidatesTheCache() {
        // The app re-pushes on its own timer and on every reconnect, so most
        // pushes say nothing new: answering `true` to one would make the daemon
        // re-probe five accounts every five minutes whether or not anything moved.
        let probes = ProbeCounter()
        let store = AccountQuotaProbe(prober: { _ in
            probes.bump()
            return ["anthropic-ratelimit-unified-5h-utilization": "0.10"]
        })
        let same = [Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "oauth", token: "t1")]
        XCTAssertTrue(store.setCredentials(same), "the first push is a change")
        XCTAssertFalse(store.setCredentials(same), "an identical push is not")

        // `refreshIfStale` hands the probe to its own queue, so the test waits on
        // the probe happening rather than on a guessed interval.
        store.refreshIfStale()
        XCTAssertTrue(wait(until: { probes.value == 1 }), "one probe for the stale cache")
        XCTAssertEqual(store.current().count, 1)

        // Fresh inside the TTL, so nothing re-probes…
        store.refreshIfStale()
        XCTAssertFalse(wait(until: { probes.value > 1 }, timeout: 0.3), "a fresh cache probes nothing")

        // …until a refreshed token arrives, which clears the cache's stamp so the
        // next render measures instead of redrawing a number about a token the API
        // has stopped accepting.
        XCTAssertTrue(store.setCredentials([
            Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "oauth", token: "t2")
        ]))
        store.refreshIfStale()
        XCTAssertTrue(wait(until: { probes.value == 2 }), "the new token is measured")
    }

    func testARoundTheNetworkFailedIsRetriedLongBeforeTheTTL() {
        // Wi-Fi drops, a round fails with "offline", and the network comes back a
        // minute later. Holding that round for the five-minute TTL kept every card
        // saying "offline" over a working connection.
        let offline = RejectSwitch()
        offline.isOn = true
        let probes = ProbeCounter()
        let store = AccountQuotaProbe(prober: { _ in
            probes.bump()
            if offline.isOn { throw URLError(.notConnectedToInternet) }
            return ["anthropic-ratelimit-unified-5h-utilization": "0.10"]
        })
        store.setCredentials([Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "oauth", token: "t1")])
        store.refreshNow()
        XCTAssertNotNil(store.current()[0].errorText)

        offline.isOn = false
        let soon = Date().addingTimeInterval(AccountQuotaProbe.networkRetryTTL + 1)
        XCTAssertLessThan(AccountQuotaProbe.networkRetryTTL, AccountQuotaProbe.defaultTTL)
        store.refreshIfStale(ttl: AccountQuotaProbe.defaultTTL, now: soon)
        XCTAssertTrue(wait(until: { probes.value == 2 }), "a network failure is re-measured soon")
        XCTAssertTrue(wait(until: { store.current().first?.errorText == nil }))
    }

    func testARefusedTokenStillWaitsOutTheWholeTTL() {
        // A 401 is an answer, not a dead network: asking again in thirty seconds
        // would get the same refusal and spend a request on it.
        let probes = ProbeCounter()
        let store = AccountQuotaProbe(prober: { _ in
            probes.bump()
            throw NSError(domain: "AccountQuota", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "token invalid or expired"])
        })
        store.setCredentials([
            Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "long-lived", token: "t1")
        ])
        store.refreshNow()

        store.refreshIfStale(
            ttl: AccountQuotaProbe.defaultTTL, now: Date().addingTimeInterval(AccountQuotaProbe.networkRetryTTL + 1))
        XCTAssertFalse(wait(until: { probes.value > 1 }, timeout: 0.3), "a refusal is not retried early")
    }

    func testRefreshNowLogsTheMissingCredentialsWarningOnlyOnce() {
        // The warning is what makes "no accounts configured" diagnosable, and the
        // probe recurs every five minutes forever — so it must not accumulate.
        let store = AccountQuotaProbe(prober: { _ in [:] })
        XCTAssertFalse(store.hasLoggedMissingCredentials)
        store.refreshNow()
        XCTAssertTrue(store.hasLoggedMissingCredentials)
        store.refreshNow()
        XCTAssertTrue(store.hasLoggedMissingCredentials, "still set, and logged no second time")
        XCTAssertTrue(store.current().isEmpty)
    }

    /// Spins the run loop until `condition` holds, answering whether it did
    /// before `timeout`. Polls the condition rather than sleeping a guessed
    /// interval, so a passing assertion is fast and a failing one is not flaky.
    private func wait(
        until condition: () -> Bool, timeout: TimeInterval = 2
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        return condition()
    }

    // MARK: - The Fable sub-limit

    func testTheSubLimitIsFablesOwnSpendingMeasuredAgainstHalfAWindow() {
        // Fable may spend up to half the week, so the sub-limit is the part of
        // the week Fable took, told against fifty points instead of a hundred:
        // an all-Fable week that is 25% gone is half the allowance gone.
        XCTAssertEqual(DaemonDatabase.fablePct(weekPct: 25, fableShare: 1), 50.0, accuracy: 0.0001)
        // And it can pass 100: the allowance is a limit, not a ceiling on what
        // the arithmetic can report. A week past 50% spent entirely on Fable
        // has spent every point Fable was ever allowed, and then some.
        XCTAssertEqual(DaemonDatabase.fablePct(weekPct: 60, fableShare: 1), 120.0, accuracy: 0.0001)
    }

    func testTheSubLimitRowResetsWithTheWindowItIsCarvedOutOf() {
        let now = 7_000_000
        let row = DaemonDatabase.fableRow(pct: 40, resetsAt: now + 3 * 86400, now: now)

        XCTAssertEqual(row.label, Sessions.UsageQuotaRowDTO.fableLabel)
        XCTAssertEqual(row.pctText, "40.0%")
        XCTAssertEqual(row.resetsAt, now + 3 * 86400)
        XCTAssertEqual(row.secondaryText, "-3d 0h 00m")
    }

    func testTheSubLimitIsListedAfterTheWindowItIsCarvedFrom() {
        // Array order is what stands the sub-limit in the LAST column: it ties
        // the 7d window on width, and `readingOrder` breaks that tie by
        // standing the sub-limit past its parent.
        let now = 8_000_000
        let readings = [Sessions.AccountQuotaReadingDTO(
            account: "a@x.com",
            fiveHourPct: 18, fiveHourResetsAt: now + 2 * 3600,
            sevenDayPct: 40, sevenDayResetsAt: now + 4 * 86400
        )]

        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in 0.5 }
        )

        XCTAssertEqual(sections[0].rows.map(\.label),
                       ["7d quota", Sessions.UsageQuotaRowDTO.fableLabel, "5h quota"])
        // Half of a 40% week is 20 of the week's hundred points — 40% of the
        // fifty Fable is allowed.
        XCTAssertEqual(sections[0].rows[1].pctText, "40.0%")
    }

    // MARK: - What the Fable sub-limit actually measures

    func testFablePctMeasuresFablesOwnSpendingNotTheWholeWeek() {
        // THE BUG. `fablePct` was `weekPct / 50 * 100` — the whole week's
        // consumption held against Fable's allowance, which is only the right
        // answer for an account that spent every token on Fable. A real
        // capture: 7d reading 100%, of which Fable was 2.96% of the week's
        // cost. The old formula drew 200%; Fable has spent 2.96 of the week's
        // hundred points, which is 5.92% of the fifty it may have.
        XCTAssertEqual(DaemonDatabase.fablePct(weekPct: 100, fableShare: 0.0296), 5.92, accuracy: 0.0001)
    }

    func testAWeekSpentEntirelyOnOtherModelsLeavesTheAllowanceUntouched() {
        // The case the old formula got most wrong: 48k Opus turns and no Fable
        // at all used to peg the gauge at 200%.
        XCTAssertEqual(DaemonDatabase.fablePct(weekPct: 100, fableShare: 0), 0, accuracy: 0.0001)
    }

    func testFableTakingHalfTheWeekSpendsExactlyTheWholeAllowance() {
        // The rule this row exists to draw: Fable may consume up to half the
        // weekly quota, so half a fully-spent week IS the whole allowance.
        XCTAssertEqual(DaemonDatabase.fablePct(weekPct: 100, fableShare: 0.5), 100, accuracy: 0.0001)
    }

    func testTheAllowanceIsHalfTheWeekWhateverTheGatewayCallsItsFallback() {
        // `fallback-percentage` is the gateway's model-FALLBACK threshold (it
        // read 0.2 in the wild before Fable existed, and Claude Code never
        // reads it) — not Fable's allowance. The allowance is the stated rule:
        // up to half the week.
        XCTAssertEqual(DaemonDatabase.fableAllowancePct, 50)
        let now = 9_700_000
        let readings = [Sessions.AccountQuotaReadingDTO(account: "a@x.com", headers: [
            "anthropic-ratelimit-unified-7d-utilization": "0.4",
            "anthropic-ratelimit-unified-7d-reset": "\(now + 86400)",
            "anthropic-ratelimit-unified-fallback-percentage": "0.25"
        ])]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in 0.5 }
        )
        // 40% week × half on Fable = 20 points of the 50 allowed → 40%.
        XCTAssertEqual(
            sections[0].rows.first { $0.label == Sessions.UsageQuotaRowDTO.fableLabel }?.pctText,
            "40.0%"
        )
    }

    func testAnUnknownFableShareShowsADashRatherThanDrawingZeroOrVanishing() {
        // Nothing priced landed in the window, so Fable's share is unknown —
        // which is not the same as knowing it to be zero. The row still stands
        // (a column that comes and goes reshuffles the card under the reader),
        // but it states no number.
        let now = 9_000_000
        let readings = [Sessions.AccountQuotaReadingDTO(
            account: "a@x.com",
            fiveHourPct: 18, fiveHourResetsAt: now + 2 * 3600,
            sevenDayPct: 40, sevenDayResetsAt: now + 4 * 86400
        )]

        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in nil }
        )

        XCTAssertEqual(sections[0].rows.map(\.label),
                       ["7d quota", Sessions.UsageQuotaRowDTO.fableLabel, "5h quota"])
        let fable = sections[0].rows[1]
        XCTAssertEqual(fable.pctText, "—")
        XCTAssertNil(fable.pct)
        XCTAssertEqual(fable.resetsAt, now + 4 * 86400)
        XCTAssertEqual(fable.windowSeconds, 7 * 86400)
    }

    func testAnUnspentWeekIsAnUnspentAllowanceWithoutAskingForAShare() {
        // Right after a reset the week is at 0% and nothing has been captured
        // yet — no share exists, but none is needed: Fable cannot have spent
        // more than the week did.
        let now = 9_100_000
        var asked = 0
        let sections = DaemonDatabase.buildAccountSections(
            readings: [Sessions.AccountQuotaReadingDTO(
                account: "a@x.com", sevenDayPct: 0, sevenDayResetsAt: now + 7 * 86400 - 60
            )],
            now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in asked += 1; return nil }
        )
        let fable = sections[0].rows.first { $0.label == Sessions.UsageQuotaRowDTO.fableLabel }
        XCTAssertEqual(fable?.pctText, "0.0%")
        XCTAssertEqual(fable?.pct, 0)
        XCTAssertEqual(asked, 0)
    }

    func testTheShareIsAskedForOverTheWindowTheWeeklyReadingCovers() {
        // The share has to be measured over the same seven days the reading
        // reports, or it is a ratio from one window applied to another. The
        // window starts seven days before the reset the probe named.
        let now = 9_500_000
        let resetsAt = now + 3 * 86400
        var asked: [(String, String?, Int)] = []
        _ = DaemonDatabase.buildAccountSections(
            readings: [Sessions.AccountQuotaReadingDTO(
                account: "a@x.com", credentialKind: ClaudeCredentialKind.longLived.rawValue,
                sevenDayPct: 40, sevenDayResetsAt: resetsAt
            )],
            now: now, snapshotFor: { _ in nil },
            fableShareFor: { reading, since in
                asked.append((reading.account, reading.credentialKind, since))
                return 0.1
            }
        )
        XCTAssertEqual(asked.count, 1)
        XCTAssertEqual(asked.first?.0, "a@x.com")
        // The credential rides along: a setup token and the same address's
        // login are metered separately, so their shares are asked separately.
        XCTAssertEqual(asked.first?.1, ClaudeCredentialKind.longLived.rawValue)
        XCTAssertEqual(asked.first?.2, resetsAt - 7 * 86400)
    }

    func testAResetThatCannotBoundThisWeekFallsBackToTheLastSevenDays() {
        // A reset in the past, or further out than a week (a millisecond
        // epoch the parser missed, a bogus header), anchors no week at all:
        // `reset - 7d` would be a window in 1969, or one that starts after it
        // ends. The share is then asked for over the rolling seven days.
        let now = 9_550_000
        for bad in [now - 60, now + 30 * 86400, 0, Int.max] {
            var since: Int?
            _ = DaemonDatabase.buildAccountSections(
                readings: [Sessions.AccountQuotaReadingDTO(
                    account: "a@x.com", sevenDayPct: 40, sevenDayResetsAt: bad
                )],
                now: now, snapshotFor: { _ in nil },
                fableShareFor: { _, start in since = start; return 0.1 }
            )
            XCTAssertEqual(since, now - 7 * 86400, "reset \(bad)")
        }
        XCTAssertEqual(DaemonDatabase.fableWindowStart(resetsAt: nil, now: now), now - 7 * 86400)
        XCTAssertEqual(
            DaemonDatabase.fableWindowStart(resetsAt: now + 86400, now: now), now + 86400 - 7 * 86400)
    }

    func testTheSubLimitRowStillProjectsNoRunOut() {
        // It can genuinely run out on its own, and still must not project: a
        // card shows ONE run-out warning (the soonest), and an account that
        // has spent its Fable allowance has not run out of anything — it works
        // on every other model against the 7d quota beside it.
        //
        // The inputs are chosen so a projection WOULD fire: 90% gone six days
        // into a seven-day window burns the last 10% in ~16h, before the reset.
        let now = 9_600_000
        let resetsAt = now + 86400
        XCTAssertNotNil(DaemonDatabase.quotaRunOut(
            pct: 90, resetsAt: resetsAt, windowSeconds: 7 * 86400, now: now),
            "precondition: these inputs project a run-out when projection is on")
        let row = DaemonDatabase.fableRow(pct: 90, resetsAt: resetsAt, now: now)
        XCTAssertEqual(row.pctText, "90.0%")
        XCTAssertNil(row.runOutSeconds)
        XCTAssertEqual(row.trailingText, "")
    }

    func testARefusedWeekPaintsTheSubLimitRed() {
        // A rejected 7d window refuses Fable along with everything else, so a
        // modest Fable percentage must not read as headroom.
        let now = 9_650_000
        let sections = DaemonDatabase.buildAccountSections(
            readings: [Sessions.AccountQuotaReadingDTO(
                account: "a@x.com", sevenDayPct: 100, sevenDayResetsAt: now + 86400,
                sevenDayStatus: "rejected"
            )],
            now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in 0.1 }
        )
        let fable = sections[0].rows.first { $0.label == Sessions.UsageQuotaRowDTO.fableLabel }
        XCTAssertEqual(fable?.pctText, "20.0%")
        XCTAssertEqual(fable?.pctColor, "red")
    }

    // MARK: - Anthropic's own Fable bucket (`7d_oi`)

    func testTheReadingCarriesTheFableBucketWhenTheGatewaySendsIt() {
        // Claude Code maps `7d_oi` (seven_day_overage_included) to "Fable
        // limit": a per-model bucket, same 0-1 scale as the others, present
        // only for accounts whose responses carry that window.
        let reading = Sessions.AccountQuotaReadingDTO(account: "a", headers: [
            "anthropic-ratelimit-unified-7d-utilization": "0.4",
            "anthropic-ratelimit-unified-7d_oi-utilization": "0.37",
            "anthropic-ratelimit-unified-7d_oi-reset": "1800000000000",
            "anthropic-ratelimit-unified-7d_oi-status": "allowed"
        ])
        XCTAssertEqual(reading.fableLimitPct ?? -1, 37.0, accuracy: 0.001)
        XCTAssertEqual(reading.fableLimitResetsAt, 1_800_000_000)
        XCTAssertEqual(reading.fableLimitStatus, "allowed")
    }

    func testAReadingWithoutTheFableBucketCarriesNone() {
        let reading = Sessions.AccountQuotaReadingDTO(account: "a", headers: [
            "anthropic-ratelimit-unified-7d-utilization": "0.4"
        ])
        XCTAssertNil(reading.fableLimitPct)
        XCTAssertNil(reading.fableLimitResetsAt)
        XCTAssertNil(reading.fableLimitStatus)
    }

    func testAMeasuredFableBucketReplacesTheEstimate() {
        // When Anthropic reports the bucket, that IS the answer: no share is
        // asked for, and the row shows the gateway's number, its reset and its
        // refusal.
        let now = 9_800_000
        var asked = 0
        let readings = [Sessions.AccountQuotaReadingDTO(account: "a@x.com", headers: [
            "anthropic-ratelimit-unified-7d-utilization": "0.4",
            "anthropic-ratelimit-unified-7d-reset": "\(now + 86400)",
            "anthropic-ratelimit-unified-7d_oi-utilization": "1.02",
            "anthropic-ratelimit-unified-7d_oi-reset": "\(now + 2 * 86400)",
            "anthropic-ratelimit-unified-7d_oi-status": "rejected"
        ])]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in asked += 1; return 0.5 }
        )
        let fable = sections[0].rows.first { $0.label == Sessions.UsageQuotaRowDTO.fableLabel }
        XCTAssertEqual(asked, 0)
        XCTAssertEqual(fable?.pctText, "102.0%")
        XCTAssertEqual(fable?.resetsAt, now + 2 * 86400)
        XCTAssertEqual(fable?.pctColor, "red")
        XCTAssertEqual(sections[0].rows.map(\.label),
                       ["7d quota", Sessions.UsageQuotaRowDTO.fableLabel])
    }

    func testAnAccountWithNoFiveHourLimitHasNoFiveHourRow() {
        // Anthropic removed the five-hour limit from some plans (Ultra, from
        // 2026-10-31): the probe answers with the 7d window and no 5h headers
        // at all. There is no limit to draw, so the card carries no 5h gauge,
        // never a 0% one that reads as headroom on a limit that does not exist.
        let now = 9_800_000
        let readings = [Sessions.AccountQuotaReadingDTO(account: "a@x.com", headers: [
            "anthropic-ratelimit-unified-7d-utilization": "0.39",
            "anthropic-ratelimit-unified-7d-reset": "\(now + 86400)"
        ])]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in nil }
        )
        XCTAssertNil(sections[0].rows.first { $0.label == Sessions.UsageQuotaRowDTO.fiveHourLabel })
        XCTAssertNotNil(sections[0].rows.first { $0.label == "7d quota" })
    }

    func testAProbeThatReadNothingDrawsNoFiveHourRow() {
        let now = 9_800_000
        let readings = [Sessions.AccountQuotaReadingDTO(account: "a@x.com", headers: [:])]
        let sections = DaemonDatabase.buildAccountSections(
            readings: readings, now: now, snapshotFor: { _ in nil },
            fableShareFor: { _, _ in nil }
        )
        XCTAssertNil(sections[0].rows.first { $0.label == Sessions.UsageQuotaRowDTO.fiveHourLabel })
    }

    // MARK: - DTO wire compatibility

    func testUsageRowsDTODecodesPayloadWithoutAccountSections() throws {
        // Payloads from a pre-2.25 daemon carry no account_sections key.
        let json = #"{"available":true,"quotaRows":[],"weekRows":[]}"#
        let dto = try JSONDecoder().decode(Sessions.UsageRowsDTO.self, from: Data(json.utf8))
        XCTAssertTrue(dto.accountSections.isEmpty)
    }

    func testRateLimitSnapshotDTODecodesPayloadWithoutAccountEmail() throws {
        // Older rows / callers may omit account_email entirely; the DTO must
        // decode with the empty-string sentinel rather than throwing keyNotFound.
        let json = """
        {"id":1,"timestamp":"2026-01-01T00:00:00.000Z","sessionId":"s","weekStart":"",
         "elapsedHours":0,"elapsedDay":0,"weeklyPct":0,"dailyAvgPct":0,"fiveHourPct":0,
         "fiveHourResetsAt":0,"sevenDayResetsAt":0,"projectedPct":0}
        """
        let dto = try JSONDecoder().decode(Sessions.RateLimitSnapshotDTO.self, from: Data(json.utf8))
        XCTAssertEqual(dto.accountEmail, "")
    }
}

/// A probe count the injected prober can bump from the store's own queue.
/// Locked because that queue is not the test's thread.
private final class ProbeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return count
    }

    func bump() {
        lock.lock(); defer { lock.unlock() }
        count += 1
    }
}
