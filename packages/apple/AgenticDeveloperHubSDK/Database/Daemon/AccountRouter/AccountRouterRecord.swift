#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB

/// One `account_router_exchange` row. Never a header value, token or body.
struct AccountRouterExchange: Sendable, Equatable {
    var startedAt: Date
    var durationMs: Int
    var sessionId: String?
    var method: String
    /// Without the query.
    var path: String
    /// Final status relayed; nil when the client went away first.
    var status: Int?
    /// Item key that served it; nil for verbatim.
    var account: String?
    /// nil when routing was off.
    var routingRule: String?
    var fiveHourUtilization: Double?
    var sevenDayUtilization: Double?
    var fiveHourStatus: String?
    var sevenDayStatus: String?
    var organizationId: String?
    /// Already scrubbed (`AccountRouterLog.scrub`).
    var error: String?
    // Model routing (migration 050). Model ids and counts only, never a body.
    var requestedModel: String?
    /// Set only when the body sent upstream named another model.
    var routedModel: String?
    /// The model the response named.
    var servedModel: String?
    /// nil when model routing was off.
    var modelRule: String?
    var provider: String?
    /// `Sessions.ModelThreadKind` raw value.
    var threadKind: String?
    var writes: Bool?
    var inputTokens: Int?
    var outputTokens: Int?
    var cacheReadTokens: Int?
    var cacheCreationTokens: Int?
    var stopReason: String?
}

extension DaemonDatabase {

    /// `error` is scrubbed again here, whatever the caller did: this is the
    /// one write path into the table, so it is the last place a secret can
    /// be stopped. (`scrub` is idempotent.) The model ids, provider and stop
    /// reason come from the client or upstream, so only their visible
    /// characters are kept: a stored row never carries a terminal escape.
    func insertRouterExchange(_ row: AccountRouterExchange) throws {
        let error = row.error.map { AccountRouterLog.scrub($0) }
        let visible = { (text: String?) in text.map(Sessions.VisibleText.visible) }
        let params: [any Sendable] = [
            Self.routerTimestamp(row.startedAt), row.durationMs, row.sessionId, row.method, row.path,
            row.status, row.account, row.routingRule, row.fiveHourUtilization, row.sevenDayUtilization,
            row.fiveHourStatus, row.sevenDayStatus, row.organizationId, error,
            visible(row.requestedModel), visible(row.routedModel), visible(row.servedModel), row.modelRule,
            visible(row.provider), row.threadKind,
            row.writes.map { $0 ? 1 : 0 }, row.inputTokens, row.outputTokens, row.cacheReadTokens,
            row.cacheCreationTokens, visible(row.stopReason)
        ]
        let placeholders = Array(repeating: "?", count: params.count).joined(separator: ", ")
        try execute("""
            INSERT INTO account_router_exchange (
                started_at, duration_ms, session_id, method, path, status, account, routing_rule,
                five_hour_utilization, seven_day_utilization, five_hour_status, seven_day_status,
                organization_id, error, \(Self.routerModelColumnList)
            ) VALUES (\(placeholders))
            """, params: params)
    }

    /// Newest first.
    func routerExchanges(limit: Int) throws -> [AccountRouterExchange] {
        var rows: [AccountRouterExchange] = []
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try query("""
            SELECT started_at, duration_ms, session_id, method, path, status, account, routing_rule,
                   five_hour_utilization, seven_day_utilization, five_hour_status, seven_day_status,
                   organization_id, error, \(Self.routerModelColumnList)
            FROM account_router_exchange ORDER BY id DESC LIMIT ?
            """, params: [limit]) { row in
            let started: String = row["started_at"] ?? ""
            rows.append(AccountRouterExchange(
                startedAt: parser.date(from: started) ?? .distantPast,
                durationMs: row["duration_ms"] ?? 0,
                sessionId: row["session_id"], method: row["method"] ?? "", path: row["path"] ?? "",
                status: row["status"], account: row["account"], routingRule: row["routing_rule"],
                fiveHourUtilization: row["five_hour_utilization"],
                sevenDayUtilization: row["seven_day_utilization"],
                fiveHourStatus: row["five_hour_status"], sevenDayStatus: row["seven_day_status"],
                organizationId: row["organization_id"], error: row["error"],
                requestedModel: row["requested_model"], routedModel: row["routed_model"],
                servedModel: row["served_model"], modelRule: row["model_rule"], provider: row["provider"],
                threadKind: row["thread_kind"], writes: row["writes"], inputTokens: row["input_tokens"],
                outputTokens: row["output_tokens"], cacheReadTokens: row["cache_read_tokens"],
                cacheCreationTokens: row["cache_creation_tokens"], stopReason: row["stop_reason"]))
        }
        return rows
    }

    /// The `routing_rule` condition for a rule filter. Fixed SQL only: the
    /// patterns are literals here, never built from caller input.
    static func routerRuleCondition(_ rule: Sessions.AccountRouterRuleFilter) -> String {
        switch rule {
        case .sticky: "routing_rule LIKE 'sticky%'"
        case .ranked: "routing_rule LIKE 'ranked%'"
        case .switched: "routing_rule LIKE 'switched:%'"
        case .allIneligible: "routing_rule LIKE 'all-ineligible%'"
        case .passthrough: "routing_rule LIKE 'passthrough:%'"
        case .retried: "routing_rule LIKE '%(retry after %'"
        case .off: "routing_rule IS NULL"
        }
    }

    /// One page of the routing log, newest first by `id`. `limit` is clamped
    /// to 1…1000 (nil is 200); `sinceHours` nil or ≤ 0 is all time, and is
    /// clamped to `AccountRouterServer.maxReportHours`; account `"-"` is the rows
    /// forwarded verbatim. Every caller value is a bound parameter.
    func routerExchangePage(
        _ request: Sessions.AccountRouterExchangeQueryDTO, now: Date = Date()
    ) throws -> [Sessions.AccountRouterExchangeDTO] {
        var conditions: [String] = []
        var params: [any Sendable] = []
        if let afterId = request.afterId {
            conditions.append("id > ?")
            params.append(afterId)
        }
        if let beforeId = request.beforeId {
            conditions.append("id < ?")
            params.append(beforeId)
        }
        if let account = request.account {
            if account == Sessions.AccountRouterExchangeQueryDTO.verbatimAccount {
                conditions.append("account IS NULL")
            } else {
                conditions.append("account = ?")
                params.append(account)
            }
        }
        if let rule = request.rule {
            conditions.append(Self.routerRuleCondition(rule))
        }
        if let hours = request.sinceHours, hours > 0 {
            let clamped = min(hours, AccountRouterServer.maxReportHours)
            conditions.append("started_at >= ?")
            params.append(Self.routerTimestamp(now.addingTimeInterval(-Double(clamped) * 3600)))
        }
        params.append(request.effectiveLimit)
        let filter = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
        var rows: [Sessions.AccountRouterExchangeDTO] = []
        try query("""
            SELECT id, started_at, duration_ms, session_id, method, path, status, account, routing_rule,
                   five_hour_utilization, seven_day_utilization, five_hour_status, seven_day_status,
                   organization_id, error, \(Self.routerModelColumnList)
            FROM account_router_exchange \(filter) ORDER BY id DESC LIMIT ?
            """, params: params) { row in
            rows.append(Sessions.AccountRouterExchangeDTO(
                id: row["id"] ?? 0, startedAt: row["started_at"] ?? "", durationMs: row["duration_ms"] ?? 0,
                sessionId: row["session_id"], method: row["method"] ?? "", path: row["path"] ?? "",
                status: row["status"], account: row["account"], routingRule: row["routing_rule"],
                fiveHourUtilization: row["five_hour_utilization"],
                sevenDayUtilization: row["seven_day_utilization"],
                fiveHourStatus: row["five_hour_status"], sevenDayStatus: row["seven_day_status"],
                organizationId: row["organization_id"], error: row["error"],
                requestedModel: row["requested_model"], routedModel: row["routed_model"],
                servedModel: row["served_model"], modelRule: row["model_rule"], provider: row["provider"],
                threadKind: row["thread_kind"], writes: row["writes"], inputTokens: row["input_tokens"],
                outputTokens: row["output_tokens"], cacheReadTokens: row["cache_read_tokens"],
                cacheCreationTokens: row["cache_creation_tokens"], stopReason: row["stop_reason"]))
        }
        return rows
    }

    /// Per account: requests, 429s (relayed, plus those a retry hid, parsed out
    /// of `routing_rule` as model-router's report did), peak utilizations, and
    /// organization ids. `sinceHours <= 0` is all time.
    func routerReport(sinceHours: Int, now: Date = Date()) throws -> Sessions.AccountRouterReportDTO {
        let cutoff = sinceHours > 0
            ? Self.routerTimestamp(now.addingTimeInterval(-Double(sinceHours) * 3600))
            : ""
        var rows: [String?: Sessions.AccountRouterReportRowDTO] = [:]
        var order: [String?] = []
        var total = 0
        try query("""
            SELECT account, COUNT(*) AS requests,
                   SUM(CASE WHEN status = 429 THEN 1 ELSE 0 END) AS limited,
                   MAX(five_hour_utilization) AS peak5, MAX(seven_day_utilization) AS peak7,
                   GROUP_CONCAT(DISTINCT organization_id) AS orgs
            FROM account_router_exchange WHERE started_at >= ?
            GROUP BY account ORDER BY account
            """, params: [cutoff]) { row in
            let account: String? = row["account"]
            let requests: Int = row["requests"] ?? 0
            let orgs: String = row["orgs"] ?? ""
            total += requests
            order.append(account)
            rows[account] = Sessions.AccountRouterReportRowDTO(
                account: account, requests: requests, rateLimited: row["limited"] ?? 0,
                peakFiveHour: row["peak5"], peakSevenDay: row["peak7"],
                organizationIds: orgs.split(separator: ",").map(String.init).sorted())
        }
        try query("""
            SELECT routing_rule FROM account_router_exchange
            WHERE started_at >= ? AND routing_rule LIKE '%(retry after %'
            """, params: [cutoff]) { row in
            let rule: String = row["routing_rule"] ?? ""
            guard let retried = Sessions.AccountRouterReportDTO.retriedAccount(in: rule, status: 429) else { return }
            let existing = rows[retried] ?? Sessions.AccountRouterReportRowDTO(
                account: retried, requests: 0, rateLimited: 0, peakFiveHour: nil, peakSevenDay: nil,
                organizationIds: [])
            if rows[retried] == nil { order.append(retried) }
            rows[retried] = Sessions.AccountRouterReportRowDTO(
                account: existing.account, requests: existing.requests, rateLimited: existing.rateLimited + 1,
                peakFiveHour: existing.peakFiveHour, peakSevenDay: existing.peakSevenDay,
                organizationIds: existing.organizationIds)
        }
        return Sessions.AccountRouterReportDTO(
            sinceHours: max(0, sinceHours), total: total, rows: order.compactMap { rows[$0] },
            models: try routerModelUsage(cutoff: cutoff))
    }

    /// Requests and tokens per (requested, served, provider) since `cutoff`;
    /// only rows model routing touched (a requested or served model is set).
    func routerModelUsage(cutoff: String) throws -> [Sessions.ModelUsageRowDTO] {
        var result: [Sessions.ModelUsageRowDTO] = []
        try query("""
            SELECT requested_model, served_model, provider, COUNT(*) AS requests,
                   COALESCE(SUM(input_tokens), 0) AS input_tokens,
                   COALESCE(SUM(output_tokens), 0) AS output_tokens,
                   COALESCE(SUM(cache_read_tokens), 0) AS cache_read_tokens,
                   COALESCE(SUM(cache_creation_tokens), 0) AS cache_creation_tokens
            FROM account_router_exchange
            WHERE started_at >= ? AND (requested_model IS NOT NULL OR served_model IS NOT NULL)
            GROUP BY requested_model, served_model, provider
            ORDER BY requests DESC, requested_model, served_model, provider
            """, params: [cutoff]) { row in
            result.append(Sessions.ModelUsageRowDTO(
                requestedModel: row["requested_model"], servedModel: row["served_model"],
                provider: row["provider"], requests: row["requests"] ?? 0,
                inputTokens: row["input_tokens"] ?? 0, outputTokens: row["output_tokens"] ?? 0,
                cacheReadTokens: row["cache_read_tokens"] ?? 0, cacheCreationTokens: row["cache_creation_tokens"] ?? 0))
        }
        return result
    }
}
#endif
