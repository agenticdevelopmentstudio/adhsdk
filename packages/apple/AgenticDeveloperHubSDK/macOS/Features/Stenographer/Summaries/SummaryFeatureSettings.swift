import Foundation
import AgenticDeveloperHubSDKCore

/// One feature's AI summaries settings (``SummaryFeature``): the switch, the
/// provider and model, the prompt and the tuning knobs.
///
/// Sessions' are the original `stenographer_ai_summar…` settings, so an
/// existing store reads unchanged. AI Conversations and Coding Projects each
/// keep a set of their own under `stenographer_<feature>_ai_summar…`, because
/// the three summarize for different readers and may want different providers,
/// prompts and schedules. `StenographerSummaryPrefsPush` pushes every set to
/// the daemon with its feature named.
@MainActor
public struct SummaryFeatureSettings {
    public let feature: SummaryFeature
    public let enabled: UserSetting<Bool>
    /// The daemon provider configuration, by id; "" is the zero-config Claude CLI.
    public let providerConfigId: UserSetting<String>
    /// Overrides the configuration's model; "" keeps it.
    public let model: UserSetting<String>
    public let prompt: UserSetting<String>
    public let maxWords: UserSetting<Int>
    public let activityLines: UserSetting<Int>
    public let detailChars: UserSetting<Int>
    public let intervalMinutes: UserSetting<Int>
    public let maxPerRun: UserSetting<Int>
    public let timeoutSeconds: UserSetting<Int>
    /// Whether this set has been filled once: from the daemon for Sessions,
    /// from Sessions' own values for the others.
    public let seeded: UserSetting<Bool>

    /// The set for `feature`. Each is built once, so every observer and every
    /// panel binds the same `UserSetting` objects.
    public static func `for`(_ feature: SummaryFeature) -> SummaryFeatureSettings {
        switch feature {
        case .sessions: sessions
        case .conversations: conversations
        case .projects: projects
        }
    }

    public static let all: [SummaryFeatureSettings] = SummaryFeature.allCases.map { Self.for($0) }

    private static let sessions = SummaryFeatureSettings(
        feature: .sessions,
        enabled: UserSettings.stenographerAISummariesEnabled,
        providerConfigId: UserSettings.stenographerAISummariesProviderConfigId,
        model: UserSettings.stenographerAISummariesModel,
        prompt: UserSettings.stenographerAISummaryPrompt,
        maxWords: UserSettings.stenographerAISummaryMaxWords,
        activityLines: UserSettings.stenographerAISummaryActivityLines,
        detailChars: UserSettings.stenographerAISummaryDetailChars,
        intervalMinutes: UserSettings.stenographerAISummaryIntervalMinutes,
        maxPerRun: UserSettings.stenographerAISummaryMaxPerRun,
        timeoutSeconds: UserSettings.stenographerAISummaryTimeoutSeconds,
        seeded: UserSettings.stenographerAISummariesSeededFromDaemon)

    private static let conversations = keyed(.conversations)
    private static let projects = keyed(.projects)

    /// A set under `stenographer_<feature>_…`. Off until seeded or switched on:
    /// a feature nobody asked to summarize must not start spending tokens.
    private static func keyed(_ feature: SummaryFeature) -> SummaryFeatureSettings {
        let prefix = "stenographer_\(feature.rawValue)_"
        return SummaryFeatureSettings(
            feature: feature,
            enabled: UserSetting(prefix + "ai_summaries_enabled", default: false),
            providerConfigId: UserSetting(prefix + "ai_summaries_provider_config_id", default: ""),
            model: UserSetting(prefix + "ai_summaries_model", default: ""),
            prompt: UserSetting(prefix + "ai_summary_prompt", default: SummaryDefaults.prompt),
            maxWords: UserSetting(prefix + "ai_summary_max_words", default: SummaryDefaults.maxWords),
            activityLines: UserSetting(prefix + "ai_summary_activity_lines", default: SummaryDefaults.activityLines),
            detailChars: UserSetting(prefix + "ai_summary_detail_chars", default: SummaryDefaults.detailChars),
            intervalMinutes: UserSetting(
                prefix + "ai_summary_interval_minutes", default: SummaryDefaults.intervalMinutes),
            maxPerRun: UserSetting(prefix + "ai_summary_max_per_run", default: SummaryDefaults.maxPerRun),
            timeoutSeconds: UserSetting(
                prefix + "ai_summary_timeout_seconds", default: SummaryDefaults.timeoutSeconds),
            seeded: UserSetting(prefix + "ai_summaries_seeded", default: false))
    }

    /// Returns the prompt and tuning knobs to their defaults; the switch, the
    /// provider and the model stay as set. Removes rather than re-writes, so a
    /// later release's defaults still reach this store.
    public func resetTuning() {
        prompt.remove()
        maxWords.remove()
        activityLines.remove()
        detailChars.remove()
        intervalMinutes.remove()
        maxPerRun.remove()
        timeoutSeconds.remove()
    }

    /// Copies every value of `source` into this set once (marker ``seeded``), so a
    /// feature that gains summaries of its own starts as a copy of Sessions'.
    /// A prompt left at the default stays unstored, as in `source`.
    public func seed(from source: SummaryFeatureSettings) {
        guard !seeded.value else { return }
        enabled.value = source.enabled.value
        providerConfigId.value = source.providerConfigId.value
        model.value = source.model.value
        if source.prompt.value == SummaryDefaults.prompt {
            prompt.remove()
        } else {
            prompt.value = source.prompt.value
        }
        maxWords.value = source.maxWords.value
        activityLines.value = source.activityLines.value
        detailChars.value = source.detailChars.value
        intervalMinutes.value = source.intervalMinutes.value
        maxPerRun.value = source.maxPerRun.value
        timeoutSeconds.value = source.timeoutSeconds.value
        seeded.value = true
    }
}
