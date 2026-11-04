import Foundation
import AgenticToolkitCore

/// The Coding Partner's preferences. Keys are namespaced `partner.`.
@MainActor
extension UserSettings {

    /// Whether the partner runs at all.
    public static let partnerEnabled = UserSetting<Bool>("partner.enabled", default: false)

    /// The legacy free-text model passed to `claude --model`; "" = Claude Code's own default. Read only as
    /// the fallback when ``partnerProvider`` is "".
    public static let partnerModel = UserSetting<String>("partner.model", default: "")

    /// The partner's provider: "" for the default Claude Code, or an ``AIProviderConfiguration`` id (a UUID string).
    public static let partnerProvider = UserSetting<String>("partner.provider", default: "")

    /// The model for the provider configuration `config`; "" = that provider's own default.
    public static func partnerModel(config: UUID) -> UserSetting<String> {
        UserSetting<String>("partner.model.\(config.uuidString)", default: "")
    }

    /// The `--permission-mode` the partner's Claude Code runs under.
    public static let partnerPermissionMode = UserSetting<String>("partner.permission_mode", default: "dontAsk")

    /// The `--allowedTools` entries: the partner's MCP tools plus read-only git and Read.
    ///
    /// No `git branch` entry: `Bash(git branch *)` also matches `-D`, `-f` and `-m`, which delete and move
    /// the owner's branches, and `partner_projects_list` already gives each repo's branch.
    public static let partnerAllowedToolsList = UserSetting<[String]>(
        "partner.allowed_tools_list",
        default: ["mcp__adkitchen", "Bash(git log *)", "Bash(git show *)", "Bash(git diff *)",
                  "Bash(git status *)", "Read"]
    )

    /// The old space-separated key, read once by ``migratePartnerAllowedToolsToList(in:)``.
    static let partnerAllowedToolsLegacy = UserSetting<String>("partner.allowed_tools", default: "")

    /// Both space-separated defaults the old key shipped with; a stored value equal to either was never chosen.
    static let partnerAllowedToolsLegacyDefaults = [
        "mcp__adkitchen Bash(git log *) Bash(git show *) Bash(git diff *) Bash(git status *) Read",
        "mcp__adkitchen Bash(git log *) Bash(git show *) Bash(git diff *) Bash(git status *) Bash(git branch *) Read"
    ]

    /// Moves a stored space-separated `partner.allowed_tools` to ``partnerAllowedToolsList`` and removes the old
    /// key. A value equal to an old default writes nothing, so the current default applies.
    public static func migratePartnerAllowedToolsToList(in settings: SettingsStore) {
        guard settings.contains(partnerAllowedToolsLegacy) else { return }
        let old = settings.get(partnerAllowedToolsLegacy)
        if !partnerAllowedToolsLegacyDefaults.contains(old) {
            settings.set(splitAllowedTools(old), for: partnerAllowedToolsList)
        }
        settings.remove(partnerAllowedToolsLegacy)
    }

    /// Splits on whitespace outside parentheses, so `Bash(git log *)` stays one entry.
    public static func splitAllowedTools(_ setting: String) -> [String] {
        var tools: [String] = []
        var current = ""
        var depth = 0
        for character in setting {
            switch character {
            case "(": depth += 1; current.append(character)
            case ")": depth = max(depth - 1, 0); current.append(character)
            case _ where character.isWhitespace && depth == 0:
                if !current.isEmpty { tools.append(current) }
                current = ""
            default: current.append(character)
            }
        }
        if !current.isEmpty { tools.append(current) }
        return tools
    }

    /// How long a session's output must be quiet before the partner is told it went idle.
    public static let partnerIdleSettleSeconds = UserSetting<Int>("partner.idle_settle_seconds", default: 60)

    /// How long one partner turn may run before it is timed out.
    public static let partnerTurnTimeoutMinutes = UserSetting<Int>("partner.turn_timeout_minutes", default: 15)

    /// Whether the partner window floats above other windows.
    public static let partnerAlwaysOnTop = UserSetting<Bool>("partner.window_always_on_top", default: false)

    /// Where the Notifications pane sits beside the Partner pane: `left`, `right`, `above` or `below`.
    /// Arrange mode's Move changes it.
    public static let partnerNotificationsSide = UserSetting<String>(
        "partner.window_notifications_side", default: "right")

    /// How many days done attention items stay in the window.
    public static let partnerAttentionRetentionDays = UserSetting<Int>("partner.attention_retention_days", default: 7)

    /// The attention kinds that also post a macOS notification.
    public static let partnerNotifyKinds = UserSetting<Set<String>>(
        "partner.notify_kinds",
        default: ["question", "blocked", "notification"]
    )

    // MARK: - Code reviews

    /// How far back, in hours, the crawl looks for commits to review.
    public static let partnerReviewsWindowHours = UserSetting<Int>("partner.reviews_window_hours", default: 24)

    /// How often, in minutes, the code-reviews job crawls for new commits.
    public static let partnerReviewsCrawlIntervalMinutes = UserSetting<Int>(
        "partner.reviews_crawl_interval_minutes", default: 30)

    /// How many reviews may run at once (never more than one per repo).
    public static let partnerReviewsConcurrency = UserSetting<Int>("partner.reviews_concurrency", default: 1)

    /// Whether the crawl covers every local branch, not only the default one.
    public static let partnerReviewsIncludeOtherBranches = UserSetting<Bool>(
        "partner.reviews_include_other_branches", default: false)

    /// The model the reviewer's Claude Code runs (`{model}`); "" = Claude Code's own default.
    public static let partnerReviewsReviewerModel = UserSetting<String>("partner.reviews_reviewer_model", default: "")

    /// The branch each repo's review worktree commits its fixes on.
    public static let partnerReviewsFixBranch = UserSetting<String>(
        "partner.reviews_fix_branch", default: "partner/review-fixes")
}
