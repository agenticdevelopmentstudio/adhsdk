import Foundation

extension Sessions {

    /// Wire types for the stenographer `/insights/*` HTTP endpoints.
    /// Snake-case JSON on the wire; camelCase Swift on this side.

    /// Summary card values at the top of the Insights dashboard.
    public struct InsightsSummaryDTO: Codable, Sendable {
        public let activeSessionCount: Int
        public let totalEventCount: Int
        public let mostUsedTool: String?
        public let longestSessionMinutes: Int

        public init(
            activeSessionCount: Int,
            totalEventCount: Int,
            mostUsedTool: String?,
            longestSessionMinutes: Int
        ) {
            self.activeSessionCount = activeSessionCount
            self.totalEventCount = totalEventCount
            self.mostUsedTool = mostUsedTool
            self.longestSessionMinutes = longestSessionMinutes
        }
    }

    /// One row of the events-per-day stacked bar chart. `byType` maps each
    /// event type present that day to its count.
    public struct EventsPerDayDTO: Codable, Sendable {
        public let day: String             // YYYY-MM-DD
        public let byType: [String: Int]

        public init(day: String, byType: [String: Int]) {
            self.day = day
            self.byType = byType
        }
    }

    /// One row of the tool usage bar chart. Top-N tools by `PreToolUse` count.
    public struct ToolUsageDTO: Codable, Sendable {
        public let toolName: String
        public let count: Int

        public init(toolName: String, count: Int) {
            self.toolName = toolName
            self.count = count
        }
    }

    /// One row of the top-projects bar chart. `project` is the last path
    /// component of `cwd` (same heuristic the menu bar already uses).
    public struct ProjectActivityDTO: Codable, Sendable {
        public let project: String
        public let eventCount: Int
        public let sessionCount: Int

        public init(project: String, eventCount: Int, sessionCount: Int) {
            self.project = project
            self.eventCount = eventCount
            self.sessionCount = sessionCount
        }
    }

    /// One row of the sessions-per-day line chart.
    public struct SessionsPerDayDTO: Codable, Sendable {
        public let day: String             // YYYY-MM-DD
        public let newSessions: Int

        public init(day: String, newSessions: Int) {
            self.day = day
            self.newSessions = newSessions
        }
    }

    /// One rolled-up daily statistic from the `daily_metric` table. `count` and
    /// `valueSum` are additive (sum across days/dimensions); averages are
    /// `valueSum / count`. `valueSum` is 0 on every metric but `project`, where
    /// it is the day's distinct sessions in that project (`count` is its
    /// events); summed across days it counts a session once per day it ran.
    public struct DailyMetricDTO: Codable, Sendable {
        public let day: String             // YYYY-MM-DD (UTC)
        public let metric: String          // e.g. "tool_use", "subagent_run"
        public let dimension: String       // breakdown value, e.g. tool name
        public let count: Int
        public let valueSum: Double

        public init(day: String, metric: String, dimension: String, count: Int, valueSum: Double) {
            self.day = day
            self.metric = metric
            self.dimension = dimension
            self.count = count
            self.valueSum = valueSum
        }
    }

    // MARK: - Cache misses

    /// One row of the cache-miss cause histogram. `cause` is a key Anthropic emits
    /// in `prompt_cache.miss_causes` — `ttl_expired_1h`, `messages_rewritten`,
    /// `system_prompt_changed`, `betas_changed`, `likely_server_side`,
    /// `auto_mode_changed`, `cache_scope_or_ttl_changed`, `model_changed`, … The set
    /// grows without notice, which is why it is stored opaquely (see
    /// `DynamicSchema.opaquePayloadSubtrees`) and reported here as whatever was
    /// observed rather than as a fixed enum.
    ///
    /// **These counts sum to *less* than ``CacheMissesDTO/misses``, not more.** A
    /// single miss can name several causes, but the tallies are read from
    /// `prompt_cache.miss_causes`, which the status line only started emitting
    /// partway through the capture and does not populate for every miss — and a
    /// cause first seen on a session's very first tick has no predecessor to
    /// difference against, so it is not counted. Read the histogram as the shape of
    /// what caused misses, never as a partition of the total.
    public struct CacheMissCauseDTO: Codable, Sendable {
        public let cause: String
        public let occurrences: Int

        public init(cause: String, occurrences: Int) {
            self.cause = cause
            self.occurrences = occurrences
        }
    }

    /// Cache-miss totals for one (model, TTL) pair — the grain at which a miss can
    /// actually be priced, since the cache-write premium depends on the TTL (1.25×
    /// at 5m, 2× at 1h) and the base rate on the model.
    public struct CacheMissModelDTO: Codable, Sendable {
        public let model: String
        public let ttl: String             // "5m" / "1h" ("" when unreported)
        /// Whether ``ttl`` is a spelling `TranscriptPricing` knows how to price.
        /// `false` means ``estimatedCostUsd`` used the API-default 1.25× write
        /// premium as a *fallback*, not as a measured rate — a 1-hour entry under a
        /// spelling this build has never seen is understated by 37.5%, and only
        /// this flag distinguishes that from a genuine 5-minute write.
        public let ttlKnown: Bool
        public let misses: Int
        public let requests: Int
        public let recacheTokens: Int
        public let estimatedCostUsd: Double

        public init(
            model: String,
            ttl: String,
            ttlKnown: Bool,
            misses: Int,
            requests: Int,
            recacheTokens: Int,
            estimatedCostUsd: Double
        ) {
            self.model = model
            self.ttl = ttl
            self.ttlKnown = ttlKnown
            self.misses = misses
            self.requests = requests
            self.recacheTokens = recacheTokens
            self.estimatedCostUsd = estimatedCostUsd
        }
    }

    /// How many characters the system prompt moved on a `system_prompt_changed`
    /// miss. A repeating ± pair (`+53` against `-53`, say) is the signature of a
    /// block that toggles between two renderings — the cheapest class of miss to
    /// fix, because the content is oscillating rather than growing.
    ///
    /// Best-effort, and **counted per tick, not per miss**: the delta is only
    /// reported for the *latest* miss of a tick, so ``occurrences`` is the number of
    /// ticks whose miss counter advanced while reporting this size — never a share
    /// of the `system_prompt_changed` count above. A tick that advanced by three
    /// misses still contributes one observation, because only one of those three
    /// misses was measured.
    public struct SystemPromptDeltaDTO: Codable, Sendable {
        public let chars: Int
        public let occurrences: Int

        public init(chars: Int, occurrences: Int) {
            self.chars = chars
            self.occurrences = occurrences
        }
    }

    /// What prompt-cache misses cost, and why they happened.
    ///
    /// **Counting.** The status line reports `prompt_cache.*` as counters that are
    /// cumulative within a cache epoch and reset to zero when the prefix is rebuilt
    /// cold, and it re-renders those same values on every tick — so a row count is
    /// not a miss count. Everything here is the sum of *observed increases* between
    /// consecutive ticks of one session, which is why `misses` lands two orders of
    /// magnitude below the number of rows that mention a miss.
    ///
    /// The first tick of a session contributes nothing: its counters describe misses
    /// that happened before this daemon was watching, so counting them would import
    /// history no later tick can corroborate.
    public struct CacheMissesDTO: Codable, Sendable {
        /// The lower bound actually applied, echoed back ("" = whole history).
        public let since: String
        /// The oldest status-line tick still on disk, or "" when there are none.
        ///
        /// This report differences raw `status_line_events`; there is no frozen
        /// daily rollup behind it, so retention (opt-in, off by default) deleting
        /// old events silently narrows what any window can answer for. A
        /// `coverageStart` later than ``since`` means exactly that: the totals below
        /// begin here, not at the bound that was asked for.
        public let coverageStart: String
        public let misses: Int
        public let requests: Int
        /// `misses / requests`, or 0 when no request was observed.
        public let missRate: Double
        /// Tokens the misses forced back through the cache.
        public let recacheTokens: Int
        /// `recacheTokens` priced per (model, TTL) via `TranscriptPricing`. Covers
        /// only the attributable part: ``unattributedRecacheTokens`` is excluded,
        /// so this is a floor on real spend, not an estimate of it.
        public let estimatedCostUsd: Double
        /// The part of ``misses`` observed across a model or TTL *change*, and so
        /// attributable to neither side. The status line reports counters, not
        /// events: when the model changes between two ticks, the counter advance
        /// happened somewhere in between, at a base rate and a write premium that
        /// are both unknown. These are still counted in ``misses``, ``requests``
        /// and ``recacheTokens`` — dropping them would understate the miss rate —
        /// but never priced, because pricing them at the arriving model's rate
        /// overstated cost by ~8× on the capture DB.
        public let unattributedMisses: Int
        /// The ``requests`` share of the same straddling deltas.
        public let unattributedRequests: Int
        /// The ``recacheTokens`` share of the same straddling deltas — ~4.5% of the
        /// capture DB's total. A large value here means ``estimatedCostUsd`` is
        /// missing a correspondingly large slice of real spend.
        public let unattributedRecacheTokens: Int
        public let causes: [CacheMissCauseDTO]
        /// Attributable (model, TTL) groups only, highest recache first, capped at
        /// the caller's `limit`. The totals above are summed over *every* group, so
        /// they stay whole even when this list is truncated.
        public let models: [CacheMissModelDTO]
        public let systemPromptDeltas: [SystemPromptDeltaDTO]

        public init(
            since: String,
            coverageStart: String,
            misses: Int,
            requests: Int,
            missRate: Double,
            recacheTokens: Int,
            estimatedCostUsd: Double,
            unattributedMisses: Int,
            unattributedRequests: Int,
            unattributedRecacheTokens: Int,
            causes: [CacheMissCauseDTO],
            models: [CacheMissModelDTO],
            systemPromptDeltas: [SystemPromptDeltaDTO]
        ) {
            self.since = since
            self.coverageStart = coverageStart
            self.misses = misses
            self.requests = requests
            self.missRate = missRate
            self.recacheTokens = recacheTokens
            self.estimatedCostUsd = estimatedCostUsd
            self.unattributedMisses = unattributedMisses
            self.unattributedRequests = unattributedRequests
            self.unattributedRecacheTokens = unattributedRecacheTokens
            self.causes = causes
            self.models = models
            self.systemPromptDeltas = systemPromptDeltas
        }
    }
}
